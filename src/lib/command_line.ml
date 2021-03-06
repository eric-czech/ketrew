(**************************************************************************)
(*    Copyright 2014, 2015:                                               *)
(*          Sebastien Mondet <seb@mondet.org>,                            *)
(*          Leonid Rozenberg <leonidr@gmail.com>,                         *)
(*          Arun Ahuja <aahuja11@gmail.com>,                              *)
(*          Jeff Hammerbacher <jeff.hammerbacher@gmail.com>               *)
(*                                                                        *)
(*  Licensed under the Apache License, Version 2.0 (the "License");       *)
(*  you may not use this file except in compliance with the License.      *)
(*  You may obtain a copy of the License at                               *)
(*                                                                        *)
(*      http://www.apache.org/licenses/LICENSE-2.0                        *)
(*                                                                        *)
(*  Unless required by applicable law or agreed to in writing, software   *)
(*  distributed under the License is distributed on an "AS IS" BASIS,     *)
(*  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or       *)
(*  implied.  See the License for the specific language governing         *)
(*  permissions and limitations under the License.                        *)
(**************************************************************************)

open Ketrew_pure
open Internal_pervasives
open Unix_io

(** Display errors, and return an exit code (integer). *)
module Return_code = struct
  let cmdliner_error = 3
  let ketrew_error = 5

  let of_error = function
  | e ->
    Log.(s "Error: " % s (Error.to_string e) @ error);
    ketrew_error

  let transform_error = function
  | `Ok () -> return ()
  | `Error e -> fail (of_error e)

end

let get_status ~client =
  Client.get_list_of_target_ids client
    ~query:Protocol.Up_message.{
      time_constraint = `All;
      filter = `Status (`Simple `In_progress)
    }
  >>= fun ids ->
  return (`In_progress (List.length ids))

(** The function behind the [ketrew status] sub-command (and the equivalent
    command in [ketrew interactive]). *)
let rec display_status ~client ~loop  =
  let display () =
    get_status ~client
    >>= fun (`In_progress inp) ->
    Log.(s "Current targets “in-progress”: " % i inp @ normal);
    return (inp = 0)
  in
  begin match loop with
  | None -> display () >>= fun _ -> return ()
  | Some seconds ->
    let keep_going = ref true in
    let rec loop () =
      display ()
      >>= fun nothing_left_to_do ->
      (System.sleep seconds >>< fun _ -> return ())
      >>= fun () ->
      (if !keep_going && not nothing_left_to_do then loop () else return ())
    in
    Interaction.run_with_quit_key
      (object
        method start = loop ()
        method stop = keep_going := false
      end)
  end

(** Kill targets (command line, ["--interactive"], or within
    [ketrew interactive]. *)
let kill ~client ~interactive ids =
  begin
    begin if interactive then
        Interaction.build_sublist_of_targets ~client ~list_name:"Kill list"
          ~all_log:Log.(s "Kill'em All") ~go_verb:Log.(s "kill")
          ~filter:(`Status `Killable)
      else
        return (`Go [])
    end
    >>= function
    | `Go additional_ids ->
      let to_kill = additional_ids @ ids in
      Log.(
        (match List.length to_kill with
         | 0 -> s "There is nothing to kill."
         | _ -> s "Killing " % OCaml.list s to_kill)
        @ warning);
      Client.kill client to_kill
    | `Cancel ->
      Log.(s "Cancelling murder plans." @ normal);
      return ()
  end


(** The function behind [ketrew interact]. *)
let interact ~client =
  let rec main_loop () =
    Interaction.(
      menu ~sentence:Log.(s "Main menu")
        ~always_there:[ menu_item ~char:'q' ~log:Log.(s "Quit") `Quit;
                        menu_item ~char:'v' ~log:Log.(s "Toggle verbose") `Verbose]
        (
          [ menu_item ~char:'s' ~log:Log.(s "Display current status")
              (`Status None); ]
          @ [
            menu_item ~char:'l' ~log:Log.(s "Loop displaying the status")
              (`Status (Some 2.));
          ] @ [
            menu_item ~char:'k' ~log:Log.(s "Kill targets") `Kill;
            menu_item ~char:'e' ~log:Log.(s "The Target Explorer™") `Explore;
          ]
        )
    )
    >>= function
    | `Quit -> return ()
    | `Verbose ->
      Interaction.toggle_verbose ();
      main_loop ()
    | `Status loop ->
      display_status ~client ~loop
      >>= fun () ->
      main_loop ()
    | `Kill ->
      kill ~interactive:true ~client []
      >>= fun () ->
      main_loop ()
    | `Explore ->
      Explorer.(create ~client () |> explore)
      >>= fun () ->
      main_loop ()
  in
  main_loop ()

let submit ?add_tags ~configuration ~wet_run what =
  let workflow =
    match what with
    | `Daemonize (host_str, cmd) ->
      let name =
        fmt "%S on %s"
          (match String.sub cmd ~index:0 ~length:20 with
          | Some s -> s ^ "..."
          | None -> cmd)
          host_str
      in
      let make =
        EDSL.daemonize ~using:`Python_daemon ~host:(EDSL.Host.parse host_str)
          EDSL.Program.(sh cmd)
      in
      EDSL.workflow_node EDSL.without_product ~name ~make
  in
  begin match wet_run with
  | true ->
    Client.submit_workflow ~override_configuration:configuration ?add_tags workflow
  | false ->
    Log.(s "Dry-run: not submitting the workflow: " % n
         % s (EDSL.workflow_to_string workflow)
         @ normal);
  end;
  return ()


let show_server_logs ~max_number ?(condition = `True) server_config =
  let ask_for_server_memory_logs format =
    begin match Configuration.command_pipe server_config with
    | Some pipe ->
      let path =
        Filename.temp_file "ketrew-logs"
          (match format with `Json -> ".json" | _ -> ".txt") in
      System.file_info ~follow_symlink:true pipe
      >>= begin function
      | `Fifo ->
        let command =
          fmt "get-log:%s:%s" path
            (match format with `Json -> "json" | _ -> "txt") in
        Log.(s "Sending " % quote command
             % s " through the command pipe: " % quote pipe @ verbose);
        begin
          System.with_timeout 2. (fun () ->
              IO.with_out_channel (`Append_to_file pipe) ~buffer_size:16 ~f:(fun oc ->
                  IO.write oc command
                  >>= fun () ->
                  IO.write oc "\n"
                )
            )
          >>< function
          | `Ok () -> return ()
          | `Error (`Timeout _) ->
            Log.(s "Writing to the command-pipe timeouted, \
                    is the server running?" @ warning);
            return ()
          | `Error (`IO _ as e) -> fail e
          | `Error (`System _) ->
            fail (`Stop_server_error "System.timeout failed!")
        end
        >>= fun () ->
        (System.sleep 1. >>< fun _ -> return ())
        >>= fun () ->
        return (Some path)
      | other ->
        fail (`Failure (fmt "File %S is not a FIFO!" pipe))
      end
    | None -> return None
    end in
  begin match Configuration.log_path server_config with
  | None ->
    ask_for_server_memory_logs `Txt
    >>= begin function
    | Some path ->
      IO.with_in_channel (`File path) ?buffer_size:None ~f:(fun i ->
          IO.with_out_channel `Stdout ~f:(fun o ->
              Log.(s "read" @ verbose);
              let rec loop () =
                IO.read i
                >>= function
                | "" -> return ()
                | more ->
                  IO.write o more
                  >>= fun () ->
                  loop ()
              in
              loop ()
            )
        )
    | None ->
      Log.(s "Server has no log-path and no command-pipe, cannot get the logs"
           @ error);
      return ()
    end
  | Some p ->
    ask_for_server_memory_logs `Json
    >>= fun from_memory ->
    let `Stream dir = System.list_directory p in
    let rec get_all acc =
      dir ()  >>= function
      | Some s when Filename.check_suffix s ".json" -> get_all (s :: acc)
      | Some s -> get_all acc
      | None -> return acc
    in
    get_all []
    >>| List.sort ~cmp:(fun a b -> String.compare b a)
    >>| List.map ~f:(fun f -> p // f)
    >>= fun rev_sorted_dir ->
    let rec display count =
      function
      | [] -> return ()
      | _ when count > max_number -> return ()
      | file :: files ->
        IO.read_file file
        >>= fun blob ->
        let json =
          match Yojson.Safe.from_string blob with
          |  j -> j
          | exception err ->
            Log.(s "Error parsing JSON in " % quote file % s " → " % exn err
                 @ warning);
            `List []
        in
        begin match json with
        | `List l ->
          let rec go_through_list count =  function
          | [] -> return count
          | _ when count > max_number -> return count
          | item :: more ->
            let output typed_item =
              Printf.printf "%s[%d]\n%s\n"
                (String.make 72 '=') count
                (Typed_log.Item.show typed_item);
              go_through_list (count + 1) more
            in
            let open Ppx_deriving_yojson_runtime.Result in
            begin match Typed_log.Item.of_yojson item  with
            | Error err ->
              Log.(s "Error parsing JSON in " % quote file % s " → " % s err
                   @ warning);
              go_through_list count more
            | Ok typed_item
              when Typed_log.Item.Condition.eval typed_item condition ->
              output typed_item
            | Ok typed_item -> go_through_list count more
            end
          in
          (* Logging.Log_store writes in order, so we reverse: *)
          go_through_list count (List.rev l)
        | _ ->
          fail (`Failure "JSON logs not a list")
        end
        >>= fun count ->
        display count files
    in
    display 1
      (match from_memory with
      | None -> rev_sorted_dir
      | Some s -> s :: rev_sorted_dir)
  end

let server_error_filename = "server_start_error.txt"

let display_server_status ~configuration ~while_starting =
  Server.status ~configuration
  >>= fun stat ->
  begin match stat with
  | `Running ->
    Log.(s "The server appears to "
         % s (if while_starting then "have started well." else "be doing well.")
         @ normal);
    return ()
  | `Wrong_response response ->
    Log.(s "Weird, there is a server on that port but its response was: "
         % sexp Cohttp.Response.sexp_of_t response @ warning);
    return ()
  | `Not_responding why when while_starting ->
    Log.(s "The server seems to have failed to start"
         % sp % parens (s why) % s "." @ normal);
    begin match Configuration.log_path configuration with
    | None ->
      Log.(s "No log-path was configured, cannot get the actual start-error"
           @ warning);
      return ()
    | Some path ->
      begin IO.read_file (path // server_error_filename)
        >>< function
        | `Ok content ->
          Log.(s "Here is the latest start-error:"
               % verbatim ("\n" ^ content) @normal);
          return ()
        | `Error e ->
          Log.(s "Cannot read the server-start error:" %n
               % s (IO.error_to_string e) @ error);
          return ()
      end
    end
  | `Not_responding why ->
    Log.(s "The server does not seem to be running"
         % sp % parens (s why) % s "." @ normal);
    return ()
  end

let redirect_log_output_exn_no_lwt path =
  Sys.command (fmt "mkdir -p %s" (Filename.quote path)) |> ignore;
  let file_name = path // "debug.txt" in
  let out =
    UnixLabels.(
      openfile ~perm:0o700 file_name ~mode:[O_APPEND; O_CREAT; O_WRONLY]
      |> out_channel_of_descr)
  in
  global_with_color := false;
  let pid = Unix.getpid () in
  Log.(s "Now debug logs will go to " % quote file_name
       %sp % parens (s "as PID: " %i pid)
       %sp % parens (s "debug-level: " %i !global_debug_level)
       @ normal);
  global_log_print_string := begin fun s ->
    Printf.fprintf out "####### %s (PID: %d)\n%s%!"
      Time.(now () |> to_filename) pid s
  end;
  ()

let do_start_the_server configuration =
  let just_before_listening () =
    Log.(s "The server is about to start listening..." @ normal);
    return ()
  in
  begin match Configuration.log_path configuration with
  | None ->
    Server.start ~configuration ~just_before_listening
  | Some path ->
    redirect_log_output_exn_no_lwt path;
    begin
      Server.start ~configuration ~just_before_listening
      >>< function
      | `Ok () -> return ()
      | `Error e ->
        let content =
          let pid = Unix.getpid () in
          fmt "%s (PID: %d)\n%s%!"
            Time.(now () |> to_filename) pid (Error.to_string e) in
        Printf.eprintf "ERROR: Starting the server failed:\n%s\n%!" content;
        just_before_listening ()
        >>= fun () ->
        IO.write_file (path // server_error_filename) ~content
        >>= fun () ->
        fail e
    end
  end

(** One {!Cmdliner} hack found in Opam codebase to create command aliases. *)
let make_command_alias cmd ?(options="") name =
  let open Cmdliner in
  let term, info = cmd in
  let orig = Term.name info in
  let doc = Printf.sprintf "An alias for $(b,%s%s)." orig options in
  let man = [
    `S "DESCRIPTION";
    `P (Printf.sprintf "$(b,$(mname) %s) is an alias for $(b,$(mname) %s%s)."
          name orig options);
    `P (Printf.sprintf "See $(b,$(mname) %s --help) for details."
          orig);
  ] in
  (term, Term.info name ~docs:"SOME COMMAND ALIASES" ~doc ~man)

(** The configuration of the command line, using the [Cmdliner] library. *)
let cmdliner_main ?override_configuration ?argv ?(additional_commands=[]) () =
  let open Cmdliner in
  let version = Metadata.version in
  let common_options_section = "COMMON OPTIONS" in
  let sub_command ~info ~term = (term, info) in
  let configuration_file_arg =
    Arg.(value & opt (some string) None
         & info ["C"; "configuration-file"]
           ~docs:common_options_section ~docv:"FILE"
           ~doc:"Use $(docv) as configuration file (can be overriden also \
                 with `$KETREW_CONFIGURATION`)." )
  in
  let make_profile_arg args =
    let at, names = match args with
    | [] -> Arg.(pos 0 (some string) None), []
    | p  -> Arg.(opt (some string) None), p
    in
    Arg.(value & at & info names
           ~docs:common_options_section ~docv:"NAME"
           ~doc:"Use the profile $(docv) within the configuration file \
                 (can be overriden also with `$KETREW_PROFILE`).")
  in
  let make_configuration_arg profile_names =
    Term.(
      pure (fun profile path_opt ->
          let how =
            match path_opt, override_configuration with
            | Some path, _ -> `From_path path
            | None, Some conf -> `Override conf
            | None, None -> `Guess
          in
          Configuration.load_exn ?profile how)
      $ make_profile_arg profile_names
      $ configuration_file_arg)
  in
  let configuration_arg = make_configuration_arg ["P"; "configuration-profile"] in
  let init_cmd =
    sub_command
      ~info:(Term.info "initialize" ~version ~sdocs:"COMMON OPTIONS" ~man:[]
               ~doc:"Initialize the application (create a config-directory)")
      ~term:Term.(
          pure (fun just_client
                 cert_key self_tls debug_level tokens port
                 config_path use_database ->
                 let how =
                   match just_client, use_database with
                   | None, None ->
                     Log.(s "Error: \
                             Cannot configure a full blown Ketrew without \
                             the `--use-database` option;" % n
                          % s "Please specify a database URI or configure just \
                               a client with `--just-client`" @ error);
                     failwith "Invalid commandline"
                   | None, Some usedb ->
                     let tls =
                       match cert_key with
                       | Some (cert, key) -> `TLS_use (cert, key)
                       | None when self_tls -> `TLS_create_self_signed
                       | _ -> `TLS_disable
                     in
                     (`Full (`User_set_database usedb,
                             tls, `Port port, `Tokens tokens))
                   | Some url, _ ->
                     (`Client_from_url url)
                 in
                 User_initialization.generate_configuration_directory
                   how ~debug_level ~config_path)
          $ Arg.(info ["just-client"] ~docv:"URL"
                   ~doc:"Configure only a client given an URL (from the WebUI)"
                 |> opt (some string) None
                 |> value)
          $ Arg.(info ["tls"] ~docv:"CERT,KEY"
                   ~doc:"Configure the server to listen on HTTPS"
                 |> opt (pair string string |> some) None
                 |> value)
          $ Arg.(info ["self-signed-tls"]
                   ~doc:"Configure the server to listen on HTTPS by \
                         generating a self-signed certificate/private-key pair"
                 |> flag |> value)
          $ Arg.(info ["debug-level"] ~docv:"INT"
                   ~doc:"Set the debug-level $(docv)."
                 |> opt int 0 |> value)
          $ Arg.(info ["with-token"]
                   ~docv:"STRING"
                   ~doc:"Add $(docv) to the list of authentication token."
                 |> opt_all string [] |> value)
          $ Arg.(value & opt int 8756
                 & info ["port"] ~docv:"INT"
                   ~doc:"Set the server port to $(docv).")
          $ Arg.(value
                 & opt string Configuration.default_configuration_directory_path
                 & info ["configuration-path"] ~docv:"DIR"
                   ~doc:"Create the configuration in $(docv).")
          $ Arg.(
              let doc =
                fmt "Use the given URI for the database configuration \
                     (pstgresql://...)." in
              info ["use-database"] ~docv:"URI" ~doc
              |> opt (some string) None |> value
            )
        ) in
  let start_gui =
    sub_command
      ~info:Term.(info "gui" ~version ~sdocs:"COMMON OPTIONS" ~man:[]
                    ~doc:"Get info about this instance.")
      ~term: Term.(
          pure (fun configuration open_cmd  ->
              match Configuration.mode configuration  with
              | `Server _ -> fail (`Failure "This not a client")
              | `Client c ->
                let url = Configuration.connection c in
                let token = Configuration.token c in
                let encoded_tok = Uri.pct_encode ~component:`Query_key token in
                System.Shell.do_or_fail
                  (fmt "%s %s/gui?token=%s" open_cmd url encoded_tok)
            )
          $ configuration_arg
          $ Arg.(value @@ opt string "open"
                 @@ info ["O"; "open-command"]
                   ~env:(env_info "BROWSER"
                           ~doc:"Browser to use to open the URL.")
                   ~doc:"Command to use as browser.")
        ) in
  let logs_cmd =
    sub_command
      ~info:(Term.info "logs" ~version ~sdocs:"COMMON OPTIONS" ~man:[]
               ~doc:"See the logs.")
      ~term: Term.(
          pure (fun configuration field_equals has_fields max_number ->
              let condition =
                `Ignore_case (
                  `And [
                    `And (List.map has_fields ~f:(fun f -> `Has_field f));
                    `And (List.map field_equals ~f:(fun p -> `Field_equals p));
                  ]
                ) in
              match Configuration.mode configuration  with
              | `Client _ ->
                fail (`Failure "This is not a configured Ketrew server")
              | `Server s ->
                show_server_logs ~max_number ~condition s)
          $ configuration_arg
          $ Arg.(
              info ["E"; "field-equals"]
                ~docv:"FIELD,VALUE"
                ~doc:"Filter the output for log-items that have the FIELD equal \
                      to the VALUE"
              |> opt_all (pair string string) []
              |> value)
          $ Arg.(
              info ["F"; "has-field"]
                ~docv:"FIELD"
                ~doc:"Filter the output for log-items that have the FIELD \
                      present"
              |> opt_all string []
              |> value)
          $ Arg.(value @@ opt int 4000
                 @@ info ["M"; "max-items"]
                   ~doc:"Set a maximum number of log items to display.")
        ) in
  let status_cmd =
    sub_command
      ~info:(Term.info "status" ~version ~sdocs:"COMMON OPTIONS" ~man:[]
               ~doc:"Get info about this instance.")
      ~term: Term.(
          pure begin fun configuration loop  ->
            match Configuration.mode configuration  with
            | `Client _ ->
              let loop = if loop then Some 2. else None in
              Client.as_client ~configuration ~f:(display_status ~loop)
            | `Server s ->
              display_server_status ~configuration:s ~while_starting:false
          end
          $ configuration_arg
          $ Arg.(value @@ flag
                 @@ info ["L"; "loop"]
                   ~doc:"(As client) loop until there is nothing left to do.")
        ) in
  let interactive_flag doc =
    Arg.(value & flag & info ["i"; "interactive"] ~doc) in
  let kill_cmd =
    let open Term in
    sub_command
      ~term:(
        pure (fun configuration interactive ids ->
            Client.as_client ~configuration
              ~f:(kill ~interactive ids))
        $ configuration_arg
        $ interactive_flag "Go through running targets and kill them with 'y' \
                            or 'n'."
        $ Arg.(value @@ pos_all string [] @@
               info [] ~docv:"Target-Id" ~doc:"Kill target $(docv)"))
      ~info:(
        info "kill" ~version ~sdocs:"COMMON OPTIONS"
          ~doc:"Kill a target."
          ~man:[])
  in
  let print_conf_cmd =
    let open Term in
    sub_command
      ~term:(
        pure (fun configuration  ->
            Log.(Configuration.log configuration
                 @ normal); return ())
        $ make_configuration_arg [])
      ~info:(info "print-configuration" ~version
               ~doc:"Display current configuration." ~man:[])
  in
  let submit_cmd =
    let open Term in
    sub_command
      ~term:(
        pure begin fun configuration daemonize wet_run add_tags ->
          begin match daemonize with
          | Some (host, cmd) ->
            submit ~configuration ~add_tags
              ~wet_run (`Daemonize (host, cmd))
          | None ->
            Log.(s "Nothing to do." @ normal);
            return ()
          end
        end
        $ configuration_arg
        $ Arg.(info ["daemonize"] ~docv:"HOST,CMD"
                 ~doc:"Submit a daemonized command on a given HOST."
               |> opt (pair string string |> some) None
               |> value)
        $ Arg.(info ["w"; "wet-run"]
                 ~doc:"Really submit the workflow (the default is to dry-run"
               |> flag |> value)
        $ Arg.(info ["tag"]
                 ~docv:"STRING"
                 ~doc:"Tag the workflow with $(docv)."
               |> opt_all string [] |> value)
      )
      ~info:(
        info "submit" ~version ~sdocs:"COMMON OPTIONS"
          ~doc:"Submit (simple) workflows." ~man:[])
  in
  let interact_cmd =
    let open Term in
    sub_command
      ~term:(
        pure (fun configuration ->
            Client.as_client ~configuration ~f:interact)
        $ configuration_arg)
      ~info:(
        info "interact" ~version ~sdocs:"COMMON OPTIONS"
          ~doc:"Run the interactive menu." ~man:[])
  in
  let explore_cmd =
    let open Term in
    sub_command
      ~term:(
        pure (fun configuration ->
            Client.as_client ~configuration
              ~f:Explorer.(fun ~client -> create ~client () |> explore)
          )
        $ configuration_arg)
      ~info:(
        info "explore" ~version ~sdocs:"COMMON OPTIONS"
          ~doc:"Run the interactive Target Explorer." ~man:[])
  in
  let start_server_cmd =
    let open Term in
    sub_command
      ~term:(
        pure (fun configuration ->
            match Configuration.mode configuration with
            | `Server srv -> do_start_the_server srv
            | other -> fail (`Failure "not a server")
          )
        $ configuration_arg
      )
      ~info:(
        info "start-server" ~version ~sdocs:"COMMON OPTIONS"
          ~doc:"Start the server." ~man:[])
  in
  let stop_server_cmd =
    let open Term in
    sub_command
      ~term:(
        pure (fun configuration ->
            begin match Configuration.mode configuration with
            | `Server srv -> Server.stop srv
            | other -> fail (`Failure "not a server")
            end
            >>= function
            | `Done -> Log.(s "Server killed."  @ normal); return ()
            | `Timeout ->
              Log.(s "Write-operation timeout; the server must not be \
                      running, try sub-command `status`" @ warning);
              return ())
        $ configuration_arg)
      ~info:(
        info "stop-server" ~version ~sdocs:"COMMON OPTIONS"
          ~doc:"Stop the server." ~man:[])
  in
  let sync_cmd =
    let open Term in
    sub_command
      ~term:(
        pure (fun src dst ->
            Persistent_data.Synchronize.copy src dst
          )
        $ Arg.(info ["from"] ~docv:"URI"
                 ~doc:"The source to copy from"
                 ~docs:"REQUIRED FLAGS"
               |> opt (some string) None
               |> required)
        $ Arg.(info ["to"] ~docv:"URI"
                 ~doc:"The destination to copy to"
                 ~docs:"REQUIRED FLAGS"
               |> opt (some string) None
               |> required)
      )
      ~info:(
        info "synchronize" ~version ~sdocs:"COMMON OPTIONS"
          ~doc:"Synchronize/copy a ketrew database."
          ~man:[
            `P "The strings SRC and DST are database URIs (`postgresql://...`  \
                like in the configuration file) *or* \
                a URI starting with `backup://` and indicating a path \
                to a directory.";
          ]
      )
  in
  let build_info_cmd =
    let open Term in
    sub_command ~term:(
      pure (fun () ->
          let item k v = Log.(sf "- %s: " k % v) in
          let out b = if b then "" else "out" in
          let built b desc = Log.sf "- With%s %s" (out b) desc in
          Log.(s "Build-info:" % n
               % separate n [
                 item "Version" @@ s Metadata.version;
                 item "Git-commit"(s (Option.value ~default:("Not available")
                                         Metadata.git_commit));
                 item "Git-description"
                   (s (Option.value ~default:("Not available")
                         Metadata.git_description));
                 built Metadata.with_postgresql "PostgreSQL support";
                 built Metadata.jsoo_debug "`js_of_ocaml` debug options";
                 built Metadata.with_bisect "`bisect.ppx` instrumentation";
               ]
               @ normal);
          return ()
        )
      $ pure ()
    )
      ~info:(info "build-info" ~version ~sdocs:"COMMON OPTIONS"
               ~doc:"Get information from this Ketrew application build.")
  in
  let default_cmd =
    let doc = "A Workflow Engine for Complex Experimental Workflows" in
    let man = [
      `S "AUTHORS";
      `P "Sebastien Mondet <seb@mondet.org>"; `Noblank;
      `S "BUGS";
      `P "Browse and report new issues at"; `Noblank;
      `P "<https://github.com/hammerlab/ketrew>.";
    ] in
    sub_command
      ~term:Term.(ret (pure (`Help (`Plain, None))))
      ~info:(Term.info "ketrew" ~version ~doc ~man) in
  let cmds =
    List.map additional_commands
      ~f:(fun (t, i) ->
          let open Term in
          pure (fun res ->
              res >>< function
              | `Ok o -> return o
              | `Error s -> fail (`Failure s)) $ t, i)
    @ [
      init_cmd; status_cmd; start_gui; kill_cmd;
      interact_cmd;
      submit_cmd;
      explore_cmd;
      logs_cmd;
      start_server_cmd; stop_server_cmd;
      print_conf_cmd; make_command_alias print_conf_cmd "pc";
      sync_cmd;
      build_info_cmd;
    ]
  in
  match Term.eval_choice ?argv default_cmd cmds with
  | `Ok f -> f
  | `Error _ -> exit Return_code.cmdliner_error
  | `Version | `Help -> exit 0


let run_main ?argv ?override_configuration ?additional_commands () =
  let main_lwt_thread =
    cmdliner_main ?argv ?override_configuration ?additional_commands ()
  in
  match Lwt_main.run (main_lwt_thread >>< Return_code.transform_error) with
  | `Ok () -> exit 0
  | `Error n -> exit n

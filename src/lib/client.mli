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

(**
   The “client” is the frontend to an HTTP client talking to a
   server/engine.
*)

open Ketrew_pure
open Internal_pervasives
open Unix_io


(** [Error.t] is the type of the error kinds that this module introduces. *)
module Error : sig

  type t =
    [ `Http of
        [ `Call of [ `GET | `POST ] * Uri.t
        | `Targets
        | `Target_query of Unique_id.t * string
        | `Process_holder
        ] *
        [ `Exn of exn
        | `Json_parsing of string * [ `Exn of exn ]
        | `Unexpected_message of Ketrew_pure.Protocol.Down_message.t
        | `Wrong_json of Yojson.Safe.json
        | `Wrong_response of Cohttp.Response.t * string ]
    | `Server_error_response of
        [ `Call of [ `GET | `POST ] * Uri.t ] * string ]

  val log : t -> Log.t
end

type t
(** The handle of the client. *)

val as_client:
  configuration:Configuration.t ->
  f:(client:t ->
     ('result,
      [> `Database of Persistent_data.Error.database
      | `Dyn_plugin of
           [> `Dynlink_error of Dynlink.error | `Findlib of exn ]
      | `Failure of string
      | `Wrong_configuration of
           [> `Found of string ] * [> `Exn of exn ] ]
      as 'a)
       Deferred_result.t) ->
  ('result, 'a) Deferred_result.t
(** Run the function [f] with a fresh-client created with the [configuration].
*)

val configuration: t -> Configuration.t
(** Retrieve the configuration used to create the client. *)


val get_list_of_target_ids : t ->
  query:Ketrew_pure.Protocol.Up_message.target_query ->
  (Ketrew_pure.Target.id list,
   [> `Client of Error.t
   | `Database of Persistent_data.Error.database])
    Deferred_result.t
(** Get a list of target IDs given the [query]. *)

val get_target: t ->
  id:Ketrew_pure.Target.id ->
  (Ketrew_pure.Target.t,
   [> `Client of Error.t
   | `Database of Persistent_data.Error.database ])
    Deferred_result.t
(** The latest contents of a given target.  *)

val get_targets: t ->
  id_list:Ketrew_pure.Target.id list ->
  (Ketrew_pure.Target.t list,
   [> `Client of Error.t
   | `Database of Persistent_data.Error.database ])
    Deferred_result.t
(** Same as {!get_target} but “in bulk.” *)

val call_query: t -> target:Ketrew_pure.Target.t -> string ->
  (string, Log.t) Deferred_result.t
(** Call a target's plugin query by name.  *)

val kill: t ->
  Ketrew_pure.Target.id list ->
  (unit,
   [> `Client of Error.t
   | `Database of Persistent_data.Error.database ])
    Deferred_result.t
(** Kill a set of targets. *)

val restart: t ->
  Ketrew_pure.Target.id list ->
  (unit,
   [> `Client of Error.t
   | `Database of Persistent_data.Error.database ])
    Deferred_result.t
(** Restart a set of targets. *)

val add_targets: t ->
  Ketrew_pure.Target.t list ->
  (unit,
   [> `Client of Error.t
   | `Database of Persistent_data.Error.database ])
    Deferred_result.t
(** Submit a list of targets to the server/engine. This is the low-level API
    dealing with {!Ketrew_pure.Target.t} values; for use in the EDSL please
    see {!submit_workflow} below. *)

val submit_workflow:
  ?safe_ids: bool ->
  ?override_configuration:Configuration.t ->
  ?add_tags:string list ->
  'any EDSL.product EDSL.workflow_node ->
  unit
(** Submit a high-level workflow description to the engine; this
    function calls [Lwt_main.run].

    One can add tags to all the targets in the workflow before
    submitting with the [add_tags] option.

    For experienced users: by default {!submit_workflow} makes IDs
    unique within the workflow, one can override this by setting
    [~safe_ids:false].
*)

val submit:
  ?override_configuration:Configuration.t ->
  ?add_tags: string list ->
  EDSL.user_target ->
  unit
(** This is like {!submit_workflow} but for the deprecated/legacy API
    (i.e. created with calls to {!EDSL.user_target}).
*)

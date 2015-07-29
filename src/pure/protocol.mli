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

open Internal_pervasives
module Server_status : sig
  type t = {
    time: float;
    tls: [`OpenSSL | `Native | `None ];
    preemptive_bounds: int * int;
    preemptive_queue: int;
    libev: bool;
    gc_minor_words : float;
    gc_promoted_words : float;
    gc_major_words : float;
    gc_minor_collections : int;
    gc_major_collections : int;
    gc_heap_words : int;
    gc_heap_chunks : int;
    gc_compactions : int;
    gc_top_heap_words : int;
    gc_stack_size : int;
  }
  val create:
    time:float ->
    tls:[ `Native | `OpenSSL | `None ] ->
    preemptive_bounds:int * int ->
    preemptive_queue:int -> libev:bool -> gc:Gc.stat -> t
end

module Down_message : sig

  type t = [
    | `List_of_targets of Target.t list
    | `List_of_target_summaries of (string (* ID *) * Target.Summary.t) list
      (* We provide the IDs back because the target could be a
         pointer, Summary.id can be different. *)
    | `List_of_target_flat_states of (string (* ID *) * Target.State.Flat.t) list
    | `List_of_target_ids of string list
    | `List_of_query_descriptions of (string * string) list
    | `Query_result of string
    | `Query_error of string
    | `Server_status of Server_status.t
    | `Ok
  ]
  include Json.Versioned.WITH_VERSIONED_SERIALIZATION with type t := t

end

module Up_message : sig
  type target_query = [
    | `All
    | `Not_finished_before of float
    | `Created_after of float
  ]
  type query_option = [
    | `Block_if_empty_at_most of float
  ]
  type t = [
    | `Get_targets of string list (* List of Ids, empty means “all” *)
    | `Get_available_queries of string (* Id of the target *)
    | `Get_target_summaries of string list (* List of Ids, empty means “all” *)
    | `Get_target_flat_states of
        [`All | `Since of float] * string list * (query_option list)
        (* List of Ids, empty means “all” *)
    | `Call_query of (string * string) (* target-id × query-name *)
    | `Submit_targets of Target.t list
    | `Kill_targets of string list (* List of Ids *)
    | `Restart_targets of string list (* List of Ids *)
    | `Get_target_ids of target_query * (query_option list)
    | `Get_server_status
  ]
  include Json.Versioned.WITH_VERSIONED_SERIALIZATION with type t := t

end
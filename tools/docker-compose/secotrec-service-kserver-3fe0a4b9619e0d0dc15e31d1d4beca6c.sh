export genspio_trap_1_9344=$$ 
 trap 'exit 77' USR1 
  { 'umask' '0000' ; }  
  { 'mkdir' '-p' '/tmp/cocloketrew' ; }  
  { 'sudo' 'chmod' '-R' '777' '/tmp/cocloketrew' ; }  
 : 
 if {  { { { { true &&  { (  eval "$(printf -- "exec %s>%s" 1 '/tmp/cmd-apt-install-postgresql-client-stdout-0')" || { echo 'Exec "exec %s>%s" 1 '/tmp/cmd-apt-install-postgresql-client-stdout-0' failed' >&2 ; }  
  eval "$(printf -- "exec %s>%s" 2 '/tmp/cmd-apt-install-postgresql-client-stderr-0')" || { echo 'Exec "exec %s>%s" 2 '/tmp/cmd-apt-install-postgresql-client-stderr-0' failed' >&2 ; }  
  {  { 'sudo' 'apt-get' 'update' ; }   ; } 
 ) ; [ $? -eq 0 ] ; } ; } &&  { (  eval "$(printf -- "exec %s>%s" 1 '/tmp/cmd-apt-install-postgresql-client-stdout-1')" || { echo 'Exec "exec %s>%s" 1 '/tmp/cmd-apt-install-postgresql-client-stdout-1' failed' >&2 ; }  
  eval "$(printf -- "exec %s>%s" 2 '/tmp/cmd-apt-install-postgresql-client-stderr-1')" || { echo 'Exec "exec %s>%s" 2 '/tmp/cmd-apt-install-postgresql-client-stderr-1' failed' >&2 ; }  
  {  { 'sudo' 'apt-get' 'upgrade' '--yes' ; }   ; } 
 ) ; [ $? -eq 0 ] ; } ; } &&  { (  eval "$(printf -- "exec %s>%s" 1 '/tmp/cmd-apt-install-postgresql-client-stdout-2')" || { echo 'Exec "exec %s>%s" 1 '/tmp/cmd-apt-install-postgresql-client-stdout-2' failed' >&2 ; }  
  eval "$(printf -- "exec %s>%s" 2 '/tmp/cmd-apt-install-postgresql-client-stderr-2')" || { echo 'Exec "exec %s>%s" 2 '/tmp/cmd-apt-install-postgresql-client-stderr-2' failed' >&2 ; }  
  {  { 'sudo' 'apt-get' 'install' '--yes' 'postgresql-client' ; }   ; } 
 ) ; [ $? -eq 0 ] ; } ; } ; [ $? -eq 0 ] ; } ; } 
 then : 
 else  { 'printf' 'SECOTREC: apt-install-postgresql-client; FAILED:\n\n' ; }  
  { 'printf' '``````````stdout\n' ; }  
  { 'cat' '/tmp/cmd-apt-install-postgresql-client-stdout-0' ; }  
  { 'printf' '\n``````````\n' ; }  
  { 'printf' '``````````stderr\n' ; }  
  { 'cat' '/tmp/cmd-apt-install-postgresql-client-stderr-0' ; }  
  { 'printf' '\n``````````\n' ; }  
  { 'printf' '``````````stdout\n' ; }  
  { 'cat' '/tmp/cmd-apt-install-postgresql-client-stdout-1' ; }  
  { 'printf' '\n``````````\n' ; }  
  { 'printf' '``````````stderr\n' ; }  
  { 'cat' '/tmp/cmd-apt-install-postgresql-client-stderr-1' ; }  
  { 'printf' '\n``````````\n' ; }  
  { 'printf' '``````````stdout\n' ; }  
  { 'cat' '/tmp/cmd-apt-install-postgresql-client-stdout-2' ; }  
  { 'printf' '\n``````````\n' ; }  
  { 'printf' '``````````stderr\n' ; }  
  { 'cat' '/tmp/cmd-apt-install-postgresql-client-stderr-2' ; }  
  { 'printf' '\n``````````\n' ; }  
  { printf -- '%s\n' "EDSL.fail called" >&2 ; kill -s USR1 ${genspio_trap_1_9344} ; }  
 fi 
 if {  { { true &&  { (  eval "$(printf -- "exec %s>%s" 1 '/tmp/cmd-Waiting-for-postgres-stdout-0')" || { echo 'Exec "exec %s>%s" 1 '/tmp/cmd-Waiting-for-postgres-stdout-0' failed' >&2 ; }  
  eval "$(printf -- "exec %s>%s" 2 '/tmp/cmd-Waiting-for-postgres-stderr-0')" || { echo 'Exec "exec %s>%s" 2 '/tmp/cmd-Waiting-for-postgres-stderr-0' failed' >&2 ; }  
  { export $( printf -- "$(printf -- '%s' 103137101124124105115120124123 | sed -e 's/\(.\{3\}\)/\\\1/g')" )="$( printf -- "$(printf -- '%s' "$( { printf -- '%d' 0 ; } | od -t o1 -An -v | tr -d ' \n' )" | sed -e 's/\(.\{3\}\)/\\\1/g')" )" 
 while { { [  $( string_to_int_7_44104=$(  printf -- "$(printf -- '%s' "$( { { getenv_8_7020=$(printf \"\${%s}\" $( printf -- "$(printf -- '%s' 103137101124124105115120124123 | sed -e 's/\(.\{3\}\)/\\\1/g')"  | tr -d '\n')) ; eval "printf -- '%s' "$getenv_8_7020"" ; }  ; } | od -t o1 -An -v | tr -d ' \n' )" | sed -e 's/\(.\{3\}\)/\\\1/g')"  ) ; if [ "$string_to_int_7_44104" -eq "$string_to_int_7_44104" ] ; then printf -- "$string_to_int_7_44104" ; else  { printf -- '%s\n' "String_to_int: error, $string_to_int_7_44104 is not an integer" >&2 ; kill -s USR1 ${genspio_trap_1_9344} ; }  ; fi ; )  -le 40 ] && ! {  {  { 'psql' '-h' 'pg' '-U' 'postgres' '-c' '\l' ; }  ; [ $? -eq 0 ] ; } ; } ; } ; } 
 do  { argument_2_2_26685=$( printf -- "$(printf -- '%s' "$( { printf -- '%d'  $( string_to_int_3_80182=$(  printf -- "$(printf -- '%s' "$( { { getenv_4_31641=$(printf \"\${%s}\" $( printf -- "$(printf -- '%s' 103137101124124105115120124123 | sed -e 's/\(.\{3\}\)/\\\1/g')"  | tr -d '\n')) ; eval "printf -- '%s' "$getenv_4_31641"" ; }  ; } | od -t o1 -An -v | tr -d ' \n' )" | sed -e 's/\(.\{3\}\)/\\\1/g')"  ) ; if [ "$string_to_int_3_80182" -eq "$string_to_int_3_80182" ] ; then printf -- "$string_to_int_3_80182" ; else  { printf -- '%s\n' "String_to_int: error, $string_to_int_3_80182 is not an integer" >&2 ; kill -s USR1 ${genspio_trap_1_9344} ; }  ; fi ; )  ; } | od -t o1 -An -v | tr -d ' \n' )" | sed -e 's/\(.\{3\}\)/\\\1/g')" ; printf 'x') ;  'printf' '%d.' "${argument_2_2_26685%?}" ; }  
  { 'sleep' '2' ; }  
 export $( printf -- "$(printf -- '%s' 103137101124124105115120124123 | sed -e 's/\(.\{3\}\)/\\\1/g')" )="$( printf -- "$(printf -- '%s' "$( { printf -- '%d' $((  $( string_to_int_5_80439=$(  printf -- "$(printf -- '%s' "$( { { getenv_6_7500=$(printf \"\${%s}\" $( printf -- "$(printf -- '%s' 103137101124124105115120124123 | sed -e 's/\(.\{3\}\)/\\\1/g')"  | tr -d '\n')) ; eval "printf -- '%s' "$getenv_6_7500"" ; }  ; } | od -t o1 -An -v | tr -d ' \n' )" | sed -e 's/\(.\{3\}\)/\\\1/g')"  ) ; if [ "$string_to_int_5_80439" -eq "$string_to_int_5_80439" ] ; then printf -- "$string_to_int_5_80439" ; else  { printf -- '%s\n' "String_to_int: error, $string_to_int_5_80439 is not an integer" >&2 ; kill -s USR1 ${genspio_trap_1_9344} ; }  ; fi ; )  + 1 )) ; } | od -t o1 -An -v | tr -d ' \n' )" | sed -e 's/\(.\{3\}\)/\\\1/g')" )" 
 done 
  { 'printf' '\n' ; }  
 if { [  $( string_to_int_9_19921=$(  printf -- "$(printf -- '%s' "$( { { getenv_10_78370=$(printf \"\${%s}\" $( printf -- "$(printf -- '%s' 103137101124124105115120124123 | sed -e 's/\(.\{3\}\)/\\\1/g')"  | tr -d '\n')) ; eval "printf -- '%s' "$getenv_10_78370"" ; }  ; } | od -t o1 -An -v | tr -d ' \n' )" | sed -e 's/\(.\{3\}\)/\\\1/g')"  ) ; if [ "$string_to_int_9_19921" -eq "$string_to_int_9_19921" ] ; then printf -- "$string_to_int_9_19921" ; else  { printf -- '%s\n' "String_to_int: error, $string_to_int_9_19921 is not an integer" >&2 ; kill -s USR1 ${genspio_trap_1_9344} ; }  ; fi ; )  -gt 40 ] ; } 
 then  { 'printf' 'SECOTREC: Command failed 40 times!\n' ; }  
  { 'sh' '-c' 'exit 2' ; }  
 else : 
 fi  ; } 
 ) ; [ $? -eq 0 ] ; } ; } ; [ $? -eq 0 ] ; } ; } 
 then : 
 else  { 'printf' 'SECOTREC: Waiting-for-postgres; FAILED:\n\n' ; }  
  { 'printf' '``````````stdout\n' ; }  
  { 'cat' '/tmp/cmd-Waiting-for-postgres-stdout-0' ; }  
  { 'printf' '\n``````````\n' ; }  
  { 'printf' '``````````stderr\n' ; }  
  { 'cat' '/tmp/cmd-Waiting-for-postgres-stderr-0' ; }  
  { 'printf' '\n``````````\n' ; }  
  { printf -- '%s\n' "EDSL.fail called" >&2 ; kill -s USR1 ${genspio_trap_1_9344} ; }  
 fi 
 : 
 (  eval "$(printf -- "exec %s>%s" 1 '/tmp/cocloketrew/config.json')" || { echo 'Exec "exec %s>%s" 1 '/tmp/cocloketrew/config.json' failed' >&2 ; }  
  {    printf -- "$(printf -- '%s' 133012040040042113145164162145167042054012040040133012040040040040173012040040040040040040042156141155145042072040042144145146141165154164042054012040040040040040040042143157156146151147165162141164151157156042072040173012040040040040040040040040042144145142165147137154145166145154042072040060054012040040040040040040040040042155157144145042072040133012040040040040040040040040040040042123145162166145162042054012040040040040040040040040040040173012040040040040040040040040040040040040042141165164150157162151172145144137164157153145156163042072040133040133040042111156154151156145042054040042106162157155055145156166042054040042156145153157164042040135040135054012040040040040040040040040040040040040042154151163164145156137164157042072040133040042124143160042054040070060070060040135054012040040040040040040040040040040040040042162145164165162156137145162162157162137155145163163141147145163042072040164162165145054012040040040040040040040040040040040040042143157155155141156144137160151160145042072040042057164155160057143157143154157153145164162145167057143157155155141156144056160151160145042054012040040040040040040040040040040040040042154157147137160141164150042072040042057164155160057143157143154157153145164162145167057154157147163057042054012040040040040040040040040040040040040042163145162166145162137145156147151156145042072040173012040040040040040040040040040040040040040040042144141164141142141163145137160141162141155145164145162163042072012040040040040040040040040040040040040040040040040042160157163164147162145163161154072057057160147057077165163145162075160157163164147162145163046160141163163167157162144075153160141163163042012040040040040040040040040040040040040175054012040040040040040040040040040040040040042163145162166145162137165151042072040173012040040040040040040040040040040040040040040042167151164150137143157154157162042072040164162165145054012040040040040040040040040040040040040040040042145170160154157162145162042072040173012040040040040040040040040040040040040040040040040042162145161165145163164137164141162147145164163137151144163042072040133040042131157165156147145162137164150141156042054040133040042104141171163042054040061056065040135040135054012040040040040040040040040040040040040040040040040042164141162147145164163137160145162137160141147145042072040066054012040040040040040040040040040040040040040040040040042164141162147145164163137164157137160162145146145164143150042072040066012040040040040040040040040040040040040040040175054012040040040040040040040040040040040040040040042167151164150137143142162145141153042072040164162165145012040040040040040040040040040040040040175012040040040040040040040040040040175012040040040040040040040040135012040040040040040040175012040040040040175012040040135012135 | sed -e 's/\(.\{3\}\)/\\\1/g')"  |  { 'cat' ; }     ; } 
 ) 
  { 'printf' '``````````json\n' ; }  
  { 'cat' '/tmp/cocloketrew/config.json' ; }  
  { 'printf' '\n``````````\n' ; }  
  { 'which' 'coclobas-ketrew' ; }  
  { 'ls' '-la' '/tmp/cocloketrew/config.json' ; }  
  { 'ls' '-la' '/tmp' ; }  
  { 'ls' '-la' '/tmp/ketrew' ; }  
  { 'umask' ; }  
  { 'bash' '-c' 'echo '\''/tmp/core_%e.%p'\'' | sudo tee /proc/sys/kernel/core_pattern' ; }  
  { argument_4_11_55217=$( printf -- "$(printf -- '%s' $( { printf -- 'G%s' "165155141163153040060060060060040073040" 
 printf -- '\n' 
 printf -- 'G%s' "144145142165147137154157147137146165156143164151157156163075040" 
 printf -- '\n' 
 printf -- 'G%s' ""$( {    printf -- "$(printf -- '%s' "$( {  { 'which' 'coclobas-ketrew' ; }  ; } | od -t o1 -An -v | tr -d ' \n' )" | sed -e 's/\(.\{3\}\)/\\\1/g')"  |  { 'tr' '-d' '\n' ; }    ; } | od -t o1 -An -v | tr -d ' \n' )"" 
 printf -- '\n' 
 printf -- 'G%s' "040163164141162164055163145162166145162040055103040" 
 printf -- '\n' 
 printf -- 'G%s' "057164155160057143157143154157153145164162145167057143157156146151147056152163157156" ; } | tr -d 'G\n' ) | sed -e 's/\(.\{3\}\)/\\\1/g')" ; printf 'x') ;  'sudo' 'su' 'biokepi' '-c' "${argument_4_11_55217%?}" ; } 
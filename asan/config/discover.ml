module Configurator = Configurator.V1

type os =
  | Android
  | IOS
  | Linux
  | Mac
  | Windows

let detect_system_header = {|
  #if __APPLE__
    #include <TargetConditionals.h>
    #if TARGET_OS_IPHONE
      #define PLATFORM_NAME "ios"
    #else
      #define PLATFORM_NAME "mac"
    #endif
  #elif __linux__
    #if __ANDROID__
      #define PLATFORM_NAME "android"
    #else
      #define PLATFORM_NAME "linux"
    #endif
  #elif WIN32
    #define PLATFORM_NAME "windows"
  #endif
|}

let get_os t =
  let header =
    let file =
      Filename.temp_file "discover" "os.h" in
    let fd = open_out file in
    output_string fd detect_system_header; close_out fd; file in
  let platform =
    Configurator.C_define.import
      t
      ~includes:[header]
      [("PLATFORM_NAME", String)] in
  match platform with
  | (_, String "android") :: [] -> Android
  | (_, String "ios") :: [] -> IOS
  | (_, String "linux") :: [] -> Linux
  | (_, String "mac") :: [] -> Mac
  | (_, String "windows") :: [] -> Windows
  | _ -> failwith "Unknown operating system"

let ccopt s = ["-ccopt"; s]
let cclib s = ["-cclib"; s]

let () = Configurator.main
  ~name:"reason-native-crash-utils"
  (fun conf ->
    let flags =
      match get_os conf with
      | Android | Linux -> ccopt "-fsanitize=address"
      | _ -> [] in
    Configurator.Flags.write_sexp "flags.sexp" flags)

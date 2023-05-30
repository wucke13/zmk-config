module commands {
  use std 'log debug'
  use std 'log info'
  use std 'log warning'
  use std 'log error'
  use std 'log critical'

  export def boards [] {
    ls $"(pwd)/zmk/app/boards/**/*.yaml"
      | each {|e| $e.name | open | get identifier}
  }

  export def shields [] {
    ls $"(pwd)/zmk/app/boards/shields/**/*.y*ml"
      | each {|e| $e.name | open | get id }
      | flatten
  }

  export def configs [] {
    cd $"(pwd)/configs/"
    ls | get name
  }

  export def compile [
    config:string@configs # the configuration to build
    --board (-b):string@boards, # the board to build for
    --shield (-s):string@shields, # the shield to build for
  ] {
    let version = "3.2"
    let project_root = (pwd)

    # find the shield info
    let shield_info = ( ls $"($project_root)/zmk/app/boards/shields/**/*.y*ml"
      | each {|e| $e.name | open }
      | where id == $shield
      )

    if ($shield_info | is-empty) {
      log error $"unknown shield ($shield)"
      return 1
    }
    let shield_info = $shield_info.0

    log info $"found shield info, building siblings: $($shield_info.siblings)"

    for shield in $shield_info.siblings {
      # create builddir
      mkdir $"($project_root)/build"

      # actually compile the firmware

      cd $"($project_root)/zmk/app"
      west build --build-dir $"($project_root)/build/($board)-($shield)" --board $board -- -Wno-dev $"-DSHIELD=($shield)" $"-DZMK_CONFIG=($project_root)/configs/($config)/config"
      cd $project_root

      cp $"build/($board)-($shield)/zephyr/zmk.uf2" $"build/($board)-($shield).uf2"
    }
  }

  def list-uf2-targets [] {
    udiskie-info --no-config --all --output '{device_file},{id_label}' | from csv --noheaders | rename path name
  }

  def list-uf2-firmwares [] {
    let project_root = (pwd)
    ls $"($project_root)/build/*.uf2" | get name | path parse | get stem
  }

  export def "flash uf2" [
    target: string@list-uf2-targets,
    fw: string@list-uf2-firmwares,
  ] {
    let project_root = (pwd)
      let firmwares = (list-uf2-firmwares)
      let targets = (list-uf2-targets)

      let mount_path = ( udiskie-mount --no-config ($targets | find $target | get path)
        | split row ' '
        | last
        )

      cp $"($project_root)/build/$($firmwares | find $fw).uf2" $mount_path
    }
    # ls $"($project_root)/build/*.uf2" |
  # }


  # dbus-send --system --print-reply --dest=org.freedesktop.UDisks2 /org/freedesktop/UDisks2/drives org.freedesktop.DBus.Properties.GetAll string:"org.freedesktop.UDisks2.drives"

  # dbus-send --system --print-reply=literal --dest=org.freedesktop.UDisks2 /org/freedesktop/UDisks2 org.freedesktop.DBus.Introspectable.Introspect

}

use commands *

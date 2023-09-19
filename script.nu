module commands {
  use std log 

  export-env {
    let-env PRJ_ROOT = (pwd)
  }

  export def boards [] {
    ls $"($env.PRJ_ROOT)/zmk/app/boards/**/*.yaml"
      | each {|e| $e.name | open | get identifier}
  }

  export def shields [] {
    ls $"($env.PRJ_ROOT)/zmk/app/boards/shields/**/*.y*ml"
      | each {|e| $e.name | open | get id }
      | flatten
  }

  export def configs [] {
    cd $"($env.PRJ_ROOT)/configs/"
    ls | get name
  }

  export def compile [
    config:string@configs # the configuration to build
    --board (-b):string@boards, # the board to build for
    --shield (-s):string@shields, # the shield to build for
  ] {
    let version = "3.2"

    # find the shield info
    let shield_info = ( ls $"($env.PRJ_ROOT)/zmk/app/boards/shields/**/*.y*ml"
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
      mkdir $"($env.PRJ_ROOT)/build"

      # actually compile the firmware

      cd $"($env.PRJ_ROOT)/zmk/app"


      west build --build-dir $"($env.PRJ_ROOT)/build/($board)-($shield)" --board $board -- -Wno-dev $"-DSHIELD=($shield)" $"-DZMK_CONFIG=($env.PRJ_ROOT)/configs/($config)/config"

      cd ($env.PRJ_ROOT)

      cp $"build/($board)-($shield)/zephyr/zmk.uf2" $"build/($board)-($shield).uf2"
    }
  }

  def list-uf2-targets [] {
    udiskie-info --no-config --all --output '{device_file},{id_label}' | from csv --noheaders | rename path name
  }

  def list-uf2-firmwares [] {
    ls $"($env.PRJ_ROOT)/build/*.uf2" | get name | path parse | get stem
  }

  export def "flash uf2" [
    target: string@list-uf2-targets,
    fw: string@list-uf2-firmwares,
  ] {
      let firmwares = (list-uf2-firmwares)
      let targets = (list-uf2-targets)

      let mount_path = ( udiskie-mount --no-config ($targets | find $target | get path)
        | split row ' '
        | last
        )

      cp $"($env.PRJ_ROOT)/build/$($firmwares | find $fw).uf2" $mount_path
    }
    # ls $"($env.PRJ_ROOT)/build/*.uf2" |
  # }


  # dbus-send --system --print-reply --dest=org.freedesktop.UDisks2 /org/freedesktop/UDisks2/drives org.freedesktop.DBus.Properties.GetAll string:"org.freedesktop.UDisks2.drives"

  # dbus-send --system --print-reply=literal --dest=org.freedesktop.UDisks2 /org/freedesktop/UDisks2 org.freedesktop.DBus.Introspectable.Introspect

}

use commands *

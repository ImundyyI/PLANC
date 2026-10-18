# COMP3601 Assignment
## Preable

Use Vivado 2024.1.

The project structure is depicted below.

├── bd
│   └── bd.tcl
├── create_project.tcl
├── modules
│   ├── demo.vhd
│   └── simple.vhd
├── tests
│   ├── cocotb
│   └── vivado_tb
└── vivado
    └── kria-constraints-1.xdc



## First Time Setup
1. clone repo. Ensure the repo is not nestedly deeply inside a directory hierarchy, **Vivado on windows complains if your path is too long**. Chuck it in like `C:\Desktop` or sum idk.

2. IMPORTANT: enable git hooks via `git config core.hooksPath .githooks`. This prompts you to re-run the create_project.tcl script if any important files have been changed that may impact your pre-existing Vivado project.
3. open Vivado and run the project creation script. This can be done graphically in the Vivado welcome screen via ` Tools -> Run Tcl Script`, or using the TCL Console and `source hw/create_project.tcl` This will generate the required project hierarchy + files Vivado needs under `hw/build/`. 

>**THE GENERATED VIVADO PROJECT SHOULD NEVER BE COMMITTED, IT IS LOCAL TO YOUR MACHINE. ALL FILES SHOULD BE MADE IN MODULES/, TESTS/, VIVADO/ etc, AND NOT INSIDE THE VIVADO PROJECT HIERARCHY.**

## After Pulling Changes

| What changed | What to do | Why? |
|---|---| --- |
| Edited `.vhd` or `.xdc` files | reload hierachy, rerun synth/impl if needed | vivado alr knows about its existence so its fine |
| Added, removed or renamed `.vhd` files | `source hw/create_project.tcl` | Vivado doesnt automatically see new files in `hw/modules/`. cleaner to just recreate |
| `bd.tcl`, constraints, block diagram, or scripts changed | `source hw/create_project.tcl` | changes are exported to `bd.tcl`, which Vivado doesnt read by default. `create_project.tcl` reads this and forces Vivado to understand the new BD | 
| Not sure | `source hw/create_project.tcl` | just cuz |


The block diagram layout may change if you recreate the project, just run `Regenerate Layout` on the opened diagram for consistency.
## Rules

- Hand written source code for module files and/or IP goes in `hw/modules/`. Don't create files inside Vivado's project folders, since Vivado is referencing the files in these folders, which are outside its project hierarchy. For this reason, never run `Copy files to local project directory` or whatever because changes to it wont be reflected `hw/modules/` etc.
- After changing the block design, export it by running `write_bd_tcl -force hw/bd/bd.tcl`, and commit those files.
- Commit `anc.bit` and `anc.hwh` into `sw/overlays/` only for useful builds.

## Obtaining project files on Kria KV260

git pull on the board, `pip install -e sw` (this just installs the python package), and open the notebooks in `sw/`. will probably need to setup pyproject.toml later but thats a week 7 problem lol.

## Pitfalls

If scripts via `source` or `write_bd_tcl` arent working, check you are CD'ed into the assignment repo root. These assume you are.

above commands assume you are on Linux. I think you might just be able to replace the pathnames with `C:\folder\bruh\etc\` for example.

## VSCode Support

You can use VSCode instead of Vivado if you use the VHDL LS extension by Henrik Bohlin. I have setup a `vhdl_ls.toml` file to configure the language server. This includes syntax highlighting, intellisense etc.
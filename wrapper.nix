{
  lib,
  writeText,
  neovimUtils,
  vimPlugins,
  wrapNeovimUnstable,
  neovim-unwrapped,
  git,
  extraName ? "",
  vimAlias ? false,
  viAlias ? false,
  withPython3 ? false,
  extraPython3Packages ? (_: [ ]),
  extraLuaPackages ? (_: [ ]),
  withNodeJs ? false,
  withPerl ? false,
  withRuby ? false,
  repo ? null,
  additionalPreInit ? "",
  additionalWrapperArgs ? [ ],
  extraBinPath ? [ ],
}:

let
  binPath = lib.makeBinPath ([ git ] ++ extraBinPath);

  preInit =
    ''
      -- Globals
      vim.g.is_nix_package = 1
    ''
    + lib.optionalString (repo != null) ''
      -- Bootstrap cfg
      local repo = '${repo}'
      local cfg_path = vim.fn.stdpath 'config'

      print('repo is')
      print(repo)

      if vim.loop.fs_stat(cfg_path) then
        output = vim.fn.system({'env', '-i', 'HOME="$HOME"', 'bash', '-l', '-c', 'git -C ' .. cfg_path .. ' remote get-url origin'})
        print('output is')
        print(output)
        if output:find(repo, 1, true)
        then
          return
        end
        vim.loop.fs_rename(cfg_path, cfg_path .. '_backup_' .. os.date '%H%M%S_%d-%m-%Y')
      end

      vim.fn.system({ 'git', 'clone', repo, cfg_path })
    ''
    + additionalPreInit;

  config =
    let
      cfg = neovimUtils.makeNeovimConfig {
        inherit extraName;
        inherit vimAlias;
        inherit viAlias;
        inherit withPython3;
        inherit extraPython3Packages;
        inherit extraLuaPackages;
        inherit withNodeJs;
        inherit withPerl;
        inherit withRuby;
        wrapRc = false;
      };
    in
    cfg
    // {
      wrapperArgs =
        cfg.wrapperArgs
        ++ [
          "--suffix"
          "PATH"
          ":"
          binPath
        ]
        ++ [
          "--add-flags"
          ''--cmd "luafile ${writeText "pre-init.lua" preInit}"''
        ]
        ++ additionalWrapperArgs;
    };

  neovim-package = neovim-unwrapped;
in
wrapNeovimUnstable neovim-package config

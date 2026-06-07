{ pkgs, ... }:

{
    programs.neovim = {
        enable = true;
        defaultEditor = true;
        sideloadInitLua = true;
        # PATH additions visible ONLY inside nvim (via wrapper), keeps env clean:
        extraPackages = with pkgs; [
            # build toolchain for lazy.nvim build steps & treesitter parser compilation
            gcc
            gnumake
            # treesitter main branch hard-requires the CLI
            tree-sitter
            # things plugins shell out to
            ripgrep
            fd
            git
            curl
            unzip
            # your LSPs/formatters/linters — replaces Mason
            lua-language-server
            nixd # or nil — LSP for editing your new .nix files
            stylua
            # pyright, rust-analyzer, gopls, clangd, prettierd, ... whatever you used via Mason
        ];
    };
}

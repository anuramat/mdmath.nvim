# ✨ mdmath.nvim

A Markdown equation previewer inside Neovim.

https://github.com/user-attachments/assets/9ee44f76-6706-4ed5-8cc3-0cd78c49dd4c

## Requirements
  - Neovim version `TODO`
  - Tree-sitter parser `markdown_inline`

### System requirements
  - NodeJS version `TODO`
  - `npm`
  - ImageMagick v6/v7
  - Linux/MacOS (not tested in MacOS, please open an issue if you are able to test it)

You also need a terminal emulator that supports [Kitty Graphics Protocol#Unicode Placeholders](https://sw.kovidgoyal.net/kitty/graphics-protocol/#unicode-placeholders), the following terminals were tested.
  - Kitty `>=0.28.0`

### Installation

>[!NOTE]
> If you have manually installed the parser then you don't need `nvim-treesitter`. Just make sure the parsers are loaded before this plugin.

### lazy.nvim

```lua
{
    'Thiago4532/mdmath.nvim',
    dependencies = {
        'nvim-treesitter/nvim-treesitter',
    },
    opts = {...}

    -- The build is already done by default in lazy.nvim, so you don't need
    -- the next line, but you can use the command `:MdMath build` to rebuild
    -- if the build fails for some reason.
    -- build = ':MdMath build'
},
```

### Other plugin managers

Just make sure to have the treesitter parser `markdown-inline` loaded before the plugin, also you have to build the plugin before using it, you can build it by running `:MdMath build` or `require'mdmath'.build()`.

## Configuration

Here is the table of configurations, and the default values:

```lua
opts = {
    -- Filetypes that the plugin will be enabled by default.
    filetypes = {'markdown'},
    -- Color of the equation, can be a highlight group or a hex color.
    -- Examples: 'Normal', '#ff0000'
    foreground = 'Normal', 
    -- Hide the text when the equation is under the cursor.
    anticonceal = true,
    -- Hide the text when in the Insert Mode.
    hide_on_insert = true,
    -- Scale of the equation images, increase to prevent blurry images when increasing terminal
    -- font, high values may produce aliased images.
    scale = 1.0,
}

```

## Usage

Currently, it only supports rendering the image inline, features like rendering at a floating window will be available soon.
  - `:MdMath enable`: Enable the plugin for the current buffer
  - `:MdMath disable`: Disable the plugin for the current buffer
  - `:MdMath clear`: Refresh all equations
  - `:MdMath build`: Build the node.js server

## Looking at the future!

The plugin is currently at alpha, many features are planned for the next versions, here are some of the planned features:
  - [ ] An API to generate equation images.
  - [ ] Render in floating windows
  - [ ] Render out-of-line
  - [ ] Dynamic width and height
  - [ ] Improve scale of images (may need to work with Kitty for this one)

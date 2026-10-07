return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.picker = opts.picker or {}
      opts.picker.sources = opts.picker.sources or {}

      local sources = {
        "files",
        "git_files",
        "recent",
        "buffers",
        "explorer",
        "oldfiles",
        "find_files",
      }

      for _, src in ipairs(sources) do
        opts.picker.sources[src] = opts.picker.sources[src] or {}
        opts.picker.sources[src].hidden = true
        opts.picker.sources[src].ignored = true
        opts.picker.sources[src].git_ignored = true
        opts.picker.sources[src].no_ignore = true
        opts.picker.sources[src].show_hidden = true
      end

      -- Global fallback
      opts.picker.hidden = true
      opts.picker.ignored = true
      opts.picker.git_ignored = true
      opts.picker.no_ignore = true
      opts.picker.show_hidden = true

      return opts
    end,
  },
}

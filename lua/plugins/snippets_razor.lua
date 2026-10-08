return {
  {
    "L3MON4D3/LuaSnip",
    keys = function()
      return {}
    end,
    config = function()
      require("luasnip").filetype_extend("razor", { "html", "css" })
    end,
  },
}

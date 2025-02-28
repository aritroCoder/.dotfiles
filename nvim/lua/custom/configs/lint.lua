require('lint').linters_by_ft = {
  javascript = {"eslint"},
  typescript = {"eslint"},
}

function File_exists(name)
  local f = io.open(name, "r")
  if f~=nil then io.close(f) return true else return false end
end

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  callback = function ()
    if File_exists(".eslintrc") or File_exists(".eslintrc.js")
    then
      print("eslintrc detected")
      require("lint").try_lint()
    end
  end,
})

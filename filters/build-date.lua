return {
  {
    Meta = function(meta)
      if meta.date == nil then
        meta.date = os.date("%d.%m.%Y")
      end

      return meta
    end
  }
}

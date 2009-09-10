module ExtendedString

  def blank?
    respond_to?(:empty?) ? empty? : !self
  end

  def to_slug
    self.gsub(/\W+/, '-').gsub(/^-+/,'').gsub(/-+$/,'').downcase
  end

  def dump()
    ret = to_s
    delete!(to_s)
    ret
  end

  def smart_split(char)
    ret = []
    tmp = ""
    inside = 0
    to_s.each_char do |x|
      if x == char && inside == 0
        ret << tmp
        tmp = ""
      else
        inside += 1 if x == "[" || x == "{" || x == "<"
        inside -= 1 if x == "]" || x == "}" || x == ">"
        tmp += x
      end
    end
    ret << tmp unless tmp.empty?
    ret
  end

end

#===============================================================================
# class Class
#===============================================================================
class Class
  def to_sym
    return self.to_s.to_sym
  end
end

#===============================================================================
# class String
#===============================================================================
class String
  def starts_with?(str)
    proc = (self[0...str.length] == str) if self.length >= str.length
    return proc || false
  end

  def ends_with?(str)
    e = self.length - 1
    proc = (self[(e-str.length)...e] == str) if self.length >= str.length
    return proc || false
  end

  def starts_with_vowel?
    return ['a', 'e', 'i', 'o', 'u'].include?(self[0, 1].downcase)
  end

  def first(n = 1)
    return self[0...n]
  end

  def last(n = 1)
    return self[-n..-1] || self
  end

  def blank?
    blank = true
    s = self.scan(/./)
    for l in s
      blank = false if l != ""
    end
    return blank
  end

  def cut(bitmap, width)
    string = self
    width -= bitmap.text_size("...").width
    string_width = 0
    text = []
    for char in string.scan(/./)
      wdh = bitmap.text_size(char).width
      next if (wdh + string_width) > width
      string_width += wdh
      text.push(char)
    end
    text.push("...") if text.length < string.length
    new_string = ""
    for char in text
      new_string += char
    end
    return new_string
  end
end

#===============================================================================
# class Numeric
#===============================================================================
class Numeric
  # Turns a number into a string formatted like 12,345,678.
  def to_s_formatted
    return self.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse
  end
end

#===============================================================================
# class Array
#===============================================================================
class Array
  def ^(other)   # xor of two arrays
    return (self|other) - (self&other)
  end
end

#===============================================================================
# module Enumerable
#===============================================================================
module Enumerable
  def transform
    ret = []
    self.each { |item| ret.push(yield(item)) }
    return ret
  end
end

#===============================================================================
# Kernel methods
#===============================================================================
def rand(*args)
  Kernel.rand(*args)
end

class << Kernel
  alias oldRand rand unless method_defined?(:oldRand)
  def rand(a = nil, b = nil)
    if a.is_a?(Range)
      lo = a.min
      hi = a.max
      return lo + oldRand(hi - lo + 1)
    elsif a.is_a?(Numeric)
      if b.is_a?(Numeric)
        return a + oldRand(b - a + 1)
      else
        return oldRand(a)
      end
    elsif a.nil?
      return (b) ? oldRand(b) : oldRand(2)
    end
  end
end

class Array
  def nitems
    count{|x| !x.nil?}
  end
end

def nil_or_empty?(string)
  return string.nil? || !string.is_a?(String) || string.size == 0
end

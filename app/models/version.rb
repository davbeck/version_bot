class Version < ActiveRecord::Base
  def long
    short_version.split('.').map{|s| s.to_i}.map{|i| i.to_s.rjust(2, '0')}.join + build.to_s.rjust(6, '0')
  end
  
  def hex
    long.to_i.to_s(16)
  end
  
  def dot
    short_version + '.' + build.to_s
  end
end

class Friend

  attr_accessor :counter
  attr_accessor :profile
  attr_accessor :profile_id
  attr_accessor :name
  attr_accessor :img
  #attr_accessor :status

  def initialize counter, profile, profile_id, name, img#, status
    @counter = counter
    @profile = profile
    @profile_id = profile_id
    @name = name
    @img = img
    #@status = status
  end

end

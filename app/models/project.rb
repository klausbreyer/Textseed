class Project < ActiveRecord::Base
  has_many :units, :dependent => :destroy
  has_many :consumers, :dependent => :destroy
  belongs_to :user


  validates_length_of :subject, :in => 3..30

  validates_length_of       :content,    :maximum => 1000
end

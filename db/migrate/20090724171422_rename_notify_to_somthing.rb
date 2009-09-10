class RenameNotifyToSomthing < ActiveRecord::Migration
  def self.up
    rename_column :users, :notify, :want_mail
  end

  def self.down
    rename_column :users, :want_mail, :notify
  end
end

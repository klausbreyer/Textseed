class CreateProjects < ActiveRecord::Migration
  def self.up
    create_table :projects do |t|
      t.string :subject
      t.text :content
      t.integer :user_id
      t.text :authors

      t.timestamps
    end
  end

  def self.down
    drop_table :projects
  end
end

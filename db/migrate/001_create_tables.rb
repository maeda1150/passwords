class CreateTables < ActiveRecord::Migration
  def self.up
    create_table :services do |t|
      t.string :name
      t.string :user
      t.string :password
      t.string :url
      t.string :comment

      t.timestamps
    end

    create_table :accounts do |t|
      t.string :name
      t.string :password
      t.string :salt

      t.timestamps
    end
  end

  def self.down
    drop_table :services
    drop_table :accounts
  end
end

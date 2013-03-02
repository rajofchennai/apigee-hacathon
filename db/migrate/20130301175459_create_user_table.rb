class CreateUserTable < ActiveRecord::Migration
  def up
    create_table :users do |t|
      t.string      :cid
      t.string      :city
      t.timestamps
    end

    add_index :users, :cid
  end

  def down
  end
end

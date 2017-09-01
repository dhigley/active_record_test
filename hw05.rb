#!/usr/bin/env ruby
# Daniel Higley
# CIT 483, Fall 2016
# hw05.rb
# 11/18/2016
#
# Establish a connection to hw05.db and create two tables
# populate all tables with additional data

require 'active_record'
require 'sqlite3'

# establish a connnection to hw05.db
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: 'hw05.db')

# add two more tables using the ActiveRecord create_table method
ActiveRecord::Schema.define do
  create_table :managers do |t|
    t.string :first_name, :null => false
    t.string :last_name, :null => false
    t.string :telephone, :null => false
  end

  create_table :managers_admins do |t|
    t.integer :manager_id, :null => false
    t.integer :admin_id, :null => false
  end

  add_foreign_key :managers_admins, :managers
  add_foreign_key :managers_admins, :admins
  # create composite index on MANAGERS_ADMINS using Active Record
  add_index :managers_admins, [:manager_id, :admin_id], :unique => true
end

# create Active Record objects for HOST, ADMIN, and MANAGER
# express many-to-many relationships between HOSTS and ADMINS
# express one-to-many relationships between MANAGERS and ADMINS
class Manager < ActiveRecord::Base
  has_many :admins
  # extra credit 2: make sure telephone has 10 digits
  validates :telephone, format: { with: /\d{3}-\d{3}-\d{4}/, message: "bad format" }

  def save
    save!
  end
end

class Admin < ActiveRecord::Base
  has_and_belongs_to_many :hosts
  belongs_to :manager
  # extra credit 2: make sure telephone has 10 digits
  validates :telephone, format: { with: /\d{3}-\d{3}-\d{4}/, message: "bad format" }

  def save
    save!
  end
end

class Host < ActiveRecord::Base
  has_and_belongs_to_many :admins

  def save
    save!
  end
end

class Manager_Admin < ActiveRecord::Base
  self.table_name = 'Managers_Admins' # overrides defaults
  # create implied FK constraints
  belongs_to :manager
  validates :manager_id, presence: true
  belongs_to :admin
  validates :admin_id, presence: true
end

class Host_Admin < ActiveRecord::Base
  self.table_name = 'Hosts_Admins' # overrides defaults
  # enforce the FK constraint from SQLite schema
  belongs_to :host
  validates :host_id, presence: true
  belongs_to :admin
  validates :admin_id, presence: true
end

# extra credit 1: add exception handling for failed inserts due to unique key
# constraint violations
begin
  # add 2 new records into the admin table
  adm = Admin.new(:first_name => 'Cassio', :last_name => 'Tagge', :shift => 'Night Shift',
               :telephone => '202-555-5555')
  adm.save # save Tagge to db
  adm = Admin.new(:first_name => 'Lorth', :last_name => 'Needa', :shift => 'Whenever',
                  :telephone => '202-555-4444')
  adm.save # save Needa to db

  # test telephone format
  adm = Admin.new(:first_name => 'Daniel', :last_name => 'Higley', :shift => 'Lazy Shift',
                  :telephone => '1234')
  adm.save # Built to Fail

  # Add 2 new records for hosts
  hst = Host.new(:host_name => 'parking', :ip_address => '192.122.237.79',
                 :domain_name => 'parking.nku.edu')
  hst.save # save parking to db
  hst = Host.new(:host_name => 'fox_news', :ip_address => '204.2.193.139',
                 :domain_name => 'www.foxnews.com')
  hst.save # save fox to db

  # Add 2 new records for hosts_admins
  ha = Host_Admin.new(:host_id => 4, :admin_id => 3)
  ha.save # save Tagge admins Parking
  ha = Host_Admin.new(:host_id => 5, :admin_id => 4)
  ha.save # save Needa admins fox

  # test duplicate entry in hosts_admins
  # ha = Host_Admin.new(:host_id => 1, :admin_id => 1)
  # ha.save # Built to Fail

  # Add 2 manager records
  mgr = Manager.new(:first_name => 'Darth', :last_name => 'Sidious', :telephone => '202-666-1234')
  mgr.save # save Sidious to db
  mgr = Manager.new(:first_name => 'Dick', :last_name => 'Cheney', :telephone => '513-555-1212')
  mgr.save # save Cheney to db

  # Add four manager_admin records, one manager for each admin
  ma = Manager_Admin.new(:manager_id => 1, :admin_id => 1)
  ma.save # Sidious manages Tarkin
  ma = Manager_Admin.new(:manager_id => 1, :admin_id => 2)
  ma.save # Sidious manages Vader
  ma = Manager_Admin.new(:manager_id => 1, :admin_id => 3)
  ma.save # Sidious manages Tagge
  ma = Manager_Admin.new(:manager_id => 2, :admin_id => 4)
  ma.save # Cheney manages Needa

  # test duplicate entry in managers_admins
  ma = Manager_Admin.new(:manager_id => 1, :admin_id => 1)
  ma.save # Built to Fail
rescue => e
# rescue ActiveRecord::RecordNotUnique => e
  puts e.message
end

# Use ActiveRecord to produce a list of all HOSTS, then ADMINS, and then MANAGERS
puts "#{'#'*12}Host#{'#'*12}"
Host.all.each do |hst|
  puts "#{hst.host_name}, #{hst.ip_address}, #{hst.domain_name}"
end
puts

puts "#{'#'*12}Admin#{'#'*11}"
Admin.all.each do |adm|
  puts "#{adm.last_name}, #{adm.first_name} - #{adm.shift}, #{adm.telephone}"
end
puts

puts "#{'#'*11}Manager#{'#'*10}"
Manager.all.each do |mgr|
  puts "#{mgr.last_name}, #{mgr.first_name} - #{mgr.telephone}"
end
puts

# Use ActiveRecord to find the admins that are associated with any one hosts
puts "#{'#'*3}Admins administer Host#{'#'*3}"
sql = "SELECT a.first_name, a.last_name, h.domain_name
        FROM admins a, hosts h, hosts_admins ha
        WHERE a.id = ha.admin_id AND h.id = ha.host_id"
results = ActiveRecord::Base.connection.execute(sql)

results.each do |r|
  puts "#{r['first_name']} #{r['last_name']} administers the host at: #{r['domain_name']}"
end
puts

# Use ActiveRecord to generate three ad hoc queries on HOSTS, ADMINS, or MANAGERS
puts "Admin who's last names is 'Vader':"
adm = Admin.select(:first_name, :last_name).where("last_name = ?", 'Vader')
adm.each do |a|
  puts "#{a.last_name}, #{a.first_name}"
end
puts

puts "Hosts that have domains ending in '.com':"
hst = Host.where("domain_name LIKE ?", '%.com')
hst.each do |h|
  puts "#{h.host_name} => #{h.domain_name}"
end
puts

puts "Evil managers who's last names are not 'Sidious':"
mgr = Manager.where.not("last_name = ?", 'Sidious')
mgr.each do |m|
  puts "#{m.last_name}, #{m.first_name} - #{m.telephone}"
end

# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160320172302) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "airports", force: :cascade do |t|
    t.string   "name"
    t.string   "city"
    t.string   "country"
    t.string   "iata"
    t.string   "icao"
    t.decimal  "latitude",                  precision: 9, scale: 6
    t.decimal  "longitude",                 precision: 9, scale: 6
    t.integer  "airport_id"
    t.integer  "altitude"
    t.decimal  "timezone_offset"
    t.string   "dst",             limit: 1
    t.string   "timezone"
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
  end

  add_index "airports", ["airport_id"], name: "index_airports_on_airport_id", unique: true, using: :btree
  add_index "airports", ["iata"], name: "index_airports_on_iata", using: :btree
  add_index "airports", ["icao"], name: "index_airports_on_icao", using: :btree

  create_table "checkins", force: :cascade do |t|
    t.json     "payload"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.datetime "scheduled_at", null: false
    t.string   "job_id"
    t.datetime "completed_at"
    t.integer  "flight_id",    null: false
    t.text     "error"
  end

  add_index "checkins", ["flight_id"], name: "index_checkins_on_flight_id", using: :btree

  create_table "flights", force: :cascade do |t|
    t.datetime "departure_time",                   null: false
    t.datetime "arrival_time",                     null: false
    t.string   "departure_city",                   null: false
    t.string   "arrival_city",                     null: false
    t.json     "payload",                          null: false
    t.integer  "departure_airport_id",             null: false
    t.integer  "arrival_airport_id",               null: false
    t.integer  "reservation_id",                   null: false
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.integer  "flight_type",          default: 0, null: false
    t.integer  "position",                         null: false
    t.string   "flight_number"
  end

  add_index "flights", ["arrival_airport_id"], name: "index_flights_on_arrival_airport_id", using: :btree
  add_index "flights", ["departure_airport_id"], name: "index_flights_on_departure_airport_id", using: :btree
  add_index "flights", ["reservation_id"], name: "index_flights_on_reservation_id", using: :btree

  create_table "passenger_checkins", force: :cascade do |t|
    t.string   "flight_number",     null: false
    t.string   "boarding_group",    null: false
    t.integer  "boarding_position", null: false
    t.integer  "flight_id",         null: false
    t.integer  "checkin_id",        null: false
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.integer  "passenger_id",      null: false
  end

  add_index "passenger_checkins", ["checkin_id"], name: "index_passenger_checkins_on_checkin_id", using: :btree
  add_index "passenger_checkins", ["flight_id"], name: "index_passenger_checkins_on_flight_id", using: :btree
  add_index "passenger_checkins", ["passenger_id"], name: "index_passenger_checkins_on_passenger_id", using: :btree

  create_table "passengers", force: :cascade do |t|
    t.boolean  "is_companion",   default: false, null: false
    t.string   "first_name"
    t.string   "last_name"
    t.integer  "reservation_id",                 null: false
    t.string   "full_name",                      null: false
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  add_index "passengers", ["reservation_id"], name: "index_passengers_on_reservation_id", using: :btree

  create_table "reservations", force: :cascade do |t|
    t.string   "confirmation_number", null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.integer  "user_id"
    t.string   "first_name",          null: false
    t.string   "last_name",           null: false
    t.json     "payload",             null: false
  end

  add_index "reservations", ["user_id"], name: "index_reservations_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "",    null: false
    t.string   "encrypted_password",     default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.integer  "failed_attempts",        default: 0,     null: false
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "admin",                  default: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree

  add_foreign_key "flights", "airports", column: "arrival_airport_id"
  add_foreign_key "flights", "airports", column: "departure_airport_id"
  add_foreign_key "flights", "reservations"
  add_foreign_key "passenger_checkins", "checkins"
  add_foreign_key "passenger_checkins", "flights"
  add_foreign_key "passenger_checkins", "passengers"
  add_foreign_key "passengers", "reservations"
  add_foreign_key "reservations", "users"
end

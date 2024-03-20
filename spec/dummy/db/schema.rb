# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_01_07_101352) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_enum :transaction_status, [
    "CREATED",
    "WSO_SUCCESS",
    "WSO_ERROR",
    "SUCCESS",
    "ERROR",
  ]

  create_table "users", force: :cascade do |t|
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.boolean "allow_password_change", default: false
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "name"
    t.string "nickname"
    t.string "image"
    t.string "email"
    t.json "tokens"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "vineti_notifications_event_publishers", force: :cascade do |t|
    t.bigint "vineti_notifications_publisher_id"
    t.bigint "vineti_notifications_event_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["vineti_notifications_event_id"], name: "index_vineti_notifications_event_publishers_on_event"
    t.index ["vineti_notifications_publisher_id"], name: "index_vineti_notifications_event_publishers_on_publisher"
  end

  create_table "vineti_notifications_event_subscribers", force: :cascade do |t|
    t.bigint "vineti_notifications_events_id"
    t.bigint "vineti_notifications_subscribers_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["vineti_notifications_events_id"], name: "index_event_subscribers_on_events_id"
    t.index ["vineti_notifications_subscribers_id"], name: "index_event_susbcribers_on_subscribers_id"
  end

  create_table "vineti_notifications_event_transactions", force: :cascade do |t|
    t.string "transaction_id"
    t.jsonb "payload", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "vineti_notifications_subscribers_id"
    t.integer "retries_count", default: 0
    t.enum "status", enum_name: "transaction_status"
    t.string "response_code"
    t.jsonb "response", default: {}
    t.bigint "vineti_notifications_publishers_id"
    t.integer "parent_transaction_id"
    t.bigint "vineti_notifications_events_id"
    t.index ["transaction_id"], name: "index_vineti_notifications_event_transactions_on_transaction_id"
    t.index ["vineti_notifications_events_id"], name: "index_event_transactions_on_events_id"
    t.index ["vineti_notifications_publishers_id"], name: "index_event_transactions_on_publishers_id"
    t.index ["vineti_notifications_subscribers_id"], name: "index_event_transactions_on_subscribers_id"
  end

  create_table "vineti_notifications_events", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "vineti_notifications_notification_email_logs", force: :cascade do |t|
    t.json "email_message"
    t.bigint "vineti_notifications_events_id"
    t.bigint "vineti_notifications_subscribers_id"
    t.bigint "vineti_notifications_templates_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "vineti_notifications_publishers_id"
    t.index ["vineti_notifications_events_id"], name: "index_email_logs_on_notification_event_id"
    t.index ["vineti_notifications_publishers_id"], name: "index_email_logs_on_notification_publisher_id"
    t.index ["vineti_notifications_subscribers_id"], name: "index_email_logs_on_email_subscriber_id"
    t.index ["vineti_notifications_templates_id"], name: "index_email_logs_on_email_template_id"
  end

  create_table "vineti_notifications_notification_email_responses", force: :cascade do |t|
    t.string "type"
    t.json "response"
    t.bigint "vineti_notifications_notification_email_logs_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["vineti_notifications_notification_email_logs_id"], name: "index_email_responses_on_email_logs_id"
  end

  create_table "vineti_notifications_publisher_subscribers", force: :cascade do |t|
    t.bigint "vineti_notifications_publishers_id"
    t.bigint "vineti_notifications_subscribers_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["vineti_notifications_publishers_id"], name: "index_publisher_subscribers_on_publishers_id"
    t.index ["vineti_notifications_subscribers_id"], name: "index_publisher_subscribers_on_subscribers_id"
  end

  create_table "vineti_notifications_publishers", force: :cascade do |t|
    t.string "publisher_id"
    t.bigint "vineti_notifications_template_id"
    t.integer "payload_type", default: 0
    t.boolean "active", default: false
    t.jsonb "data", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["vineti_notifications_template_id"], name: "index_vineti_notifications_publishers_on_template"
  end

  create_table "vineti_notifications_subscribers", force: :cascade do |t|
    t.bigint "vineti_notifications_templates_id"
    t.string "subscriber_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "data"
    t.string "type"
    t.boolean "active", default: true
    t.integer "delayed_time"
    t.index ["vineti_notifications_templates_id"], name: "index_email_subscribers_on_email_templates_id"
  end

  create_table "vineti_notifications_templates", force: :cascade do |t|
    t.string "template_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "default_variables"
    t.json "data"
    t.json "deeplinks"
  end

  add_foreign_key "vineti_notifications_event_subscribers", "vineti_notifications_events", column: "vineti_notifications_events_id"
  add_foreign_key "vineti_notifications_event_subscribers", "vineti_notifications_subscribers", column: "vineti_notifications_subscribers_id"
  add_foreign_key "vineti_notifications_event_transactions", "vineti_notifications_events", column: "vineti_notifications_events_id"
  add_foreign_key "vineti_notifications_event_transactions", "vineti_notifications_publishers", column: "vineti_notifications_publishers_id"
  add_foreign_key "vineti_notifications_event_transactions", "vineti_notifications_subscribers", column: "vineti_notifications_subscribers_id"
  add_foreign_key "vineti_notifications_publisher_subscribers", "vineti_notifications_publishers", column: "vineti_notifications_publishers_id"
  add_foreign_key "vineti_notifications_publisher_subscribers", "vineti_notifications_subscribers", column: "vineti_notifications_subscribers_id"
end

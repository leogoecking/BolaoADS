# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_05_28_001000) do
  create_table "achievements", force: :cascade do |t|
    t.string "key", null: false
    t.string "name", null: false
    t.text "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_achievements_on_key", unique: true
  end

  create_table "activity_events", force: :cascade do |t|
    t.string "event_type", null: false
    t.integer "user_id", null: false
    t.integer "match_id", null: false
    t.integer "prediction_id"
    t.string "message", null: false
    t.string "dedupe_key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_activity_events_on_created_at"
    t.index ["dedupe_key"], name: "index_activity_events_on_dedupe_key", unique: true
    t.index ["match_id"], name: "index_activity_events_on_match_id"
    t.index ["prediction_id"], name: "index_activity_events_on_prediction_id"
    t.index ["user_id"], name: "index_activity_events_on_user_id"
  end

  create_table "matches", force: :cascade do |t|
    t.string "external_id", null: false
    t.integer "home_team_id", null: false
    t.integer "away_team_id", null: false
    t.datetime "kickoff_at", null: false
    t.string "status", default: "scheduled", null: false
    t.integer "home_score"
    t.integer "away_score"
    t.string "stage"
    t.string "group_name"
    t.datetime "last_synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "knockout", default: false, null: false
    t.integer "underdog_team_id"
    t.index ["away_team_id"], name: "index_matches_on_away_team_id"
    t.index ["external_id"], name: "index_matches_on_external_id", unique: true
    t.index ["home_team_id"], name: "index_matches_on_home_team_id"
    t.index ["kickoff_at"], name: "index_matches_on_kickoff_at"
    t.index ["knockout"], name: "index_matches_on_knockout"
    t.index ["status"], name: "index_matches_on_status"
    t.index ["underdog_team_id"], name: "index_matches_on_underdog_team_id"
  end

  create_table "prediction_comments", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "prediction_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_prediction_comments_on_created_at"
    t.index ["prediction_id"], name: "index_prediction_comments_on_prediction_id"
    t.index ["user_id"], name: "index_prediction_comments_on_user_id"
  end

  create_table "predictions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "match_id", null: false
    t.integer "home_score", null: false
    t.integer "away_score", null: false
    t.integer "points", default: 0, null: false
    t.datetime "calculated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "adcoins_wager", default: 0, null: false
    t.boolean "adcoins_settled", default: false, null: false
    t.integer "adcoins_payout", default: 0, null: false
    t.index ["match_id"], name: "index_predictions_on_match_id"
    t.index ["points"], name: "index_predictions_on_points"
    t.index ["user_id", "match_id"], name: "index_predictions_on_user_id_and_match_id", unique: true
    t.index ["user_id"], name: "index_predictions_on_user_id"
  end

  create_table "special_predictions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "special_question_id", null: false
    t.string "answer", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["special_question_id"], name: "index_special_predictions_on_special_question_id"
    t.index ["user_id", "special_question_id"], name: "index_special_predictions_on_user_id_and_special_question_id", unique: true
    t.index ["user_id"], name: "index_special_predictions_on_user_id"
  end

  create_table "special_questions", force: :cascade do |t|
    t.string "key", null: false
    t.string "prompt", null: false
    t.string "answer_type", default: "text", null: false
    t.integer "points_value", default: 10, null: false
    t.datetime "closes_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_special_questions_on_key", unique: true
  end

  create_table "teams", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_teams_on_code", unique: true
    t.index ["name"], name: "index_teams_on_name", unique: true
  end

  create_table "user_achievements", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "achievement_id", null: false
    t.datetime "unlocked_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["achievement_id"], name: "index_user_achievements_on_achievement_id"
    t.index ["user_id", "achievement_id"], name: "index_user_achievements_on_user_id_and_achievement_id", unique: true
    t.index ["user_id"], name: "index_user_achievements_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "adcoins_balance", default: 100, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "activity_events", "matches"
  add_foreign_key "activity_events", "predictions"
  add_foreign_key "activity_events", "users"
  add_foreign_key "matches", "teams", column: "away_team_id"
  add_foreign_key "matches", "teams", column: "home_team_id"
  add_foreign_key "matches", "teams", column: "underdog_team_id"
  add_foreign_key "prediction_comments", "predictions"
  add_foreign_key "prediction_comments", "users"
  add_foreign_key "predictions", "matches"
  add_foreign_key "predictions", "users"
  add_foreign_key "special_predictions", "special_questions"
  add_foreign_key "special_predictions", "users"
  add_foreign_key "user_achievements", "achievements"
  add_foreign_key "user_achievements", "users"
end

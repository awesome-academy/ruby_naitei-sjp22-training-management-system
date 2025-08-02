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

ActiveRecord::Schema[7.0].define(version: 2025_08_01_100034) do
  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "categories", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name"
  end

  create_table "comments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "commentable_type", null: false
    t.bigint "commentable_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable"
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable_type_and_commentable_id"
    t.index ["created_at"], name: "index_comments_on_created_at"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "course_categories", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "course_id", null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_course_categories_on_category_id"
    t.index ["course_id", "category_id"], name: "index_course_categories_on_course_id_and_category_id", unique: true
    t.index ["course_id"], name: "index_course_categories_on_course_id"
  end

  create_table "course_subjects", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "course_id", null: false
    t.bigint "subject_id", null: false
    t.integer "position"
    t.date "start_date"
    t.date "finish_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id", "subject_id"], name: "index_course_subjects_on_course_id_and_subject_id", unique: true
    t.index ["course_id"], name: "index_course_subjects_on_course_id"
    t.index ["finish_date"], name: "index_course_subjects_on_finish_date"
    t.index ["position"], name: "index_course_subjects_on_position"
    t.index ["start_date"], name: "index_course_subjects_on_start_date"
    t.index ["subject_id"], name: "index_course_subjects_on_subject_id"
  end

  create_table "course_supervisors", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "course_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id", "user_id"], name: "index_course_supervisors_on_course_id_and_user_id", unique: true
    t.index ["course_id"], name: "index_course_supervisors_on_course_id"
    t.index ["user_id"], name: "index_course_supervisors_on_user_id"
  end

  create_table "courses", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.date "start_date"
    t.date "finish_date"
    t.bigint "user_id", null: false
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["finish_date"], name: "index_courses_on_finish_date"
    t.index ["name"], name: "index_courses_on_name"
    t.index ["start_date"], name: "index_courses_on_start_date"
    t.index ["status"], name: "index_courses_on_status"
    t.index ["user_id"], name: "index_courses_on_user_id"
  end

  create_table "daily_reports", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "course_id", null: false
    t.text "content"
    t.boolean "is_done", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_daily_reports_on_course_id"
    t.index ["created_at"], name: "index_daily_reports_on_created_at"
    t.index ["is_done"], name: "index_daily_reports_on_is_done"
    t.index ["user_id", "course_id"], name: "index_daily_reports_on_user_id_and_course_id"
    t.index ["user_id"], name: "index_daily_reports_on_user_id"
  end

  create_table "subject_categories", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "subject_id", null: false
    t.bigint "category_id", null: false
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_subject_categories_on_category_id"
    t.index ["position"], name: "index_subject_categories_on_position"
    t.index ["subject_id", "category_id"], name: "index_subject_categories_on_subject_id_and_category_id", unique: true
    t.index ["subject_id"], name: "index_subject_categories_on_subject_id"
  end

  create_table "subjects", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.integer "max_score", default: 100
    t.integer "estimated_time_days"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["estimated_time_days"], name: "index_subjects_on_estimated_time_days"
    t.index ["max_score"], name: "index_subjects_on_max_score"
    t.index ["name"], name: "index_subjects_on_name"
  end

  create_table "tasks", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "taskable_type", null: false
    t.bigint "taskable_id", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "expected_time"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expected_time"], name: "index_tasks_on_expected_time"
    t.index ["name"], name: "index_tasks_on_name"
    t.index ["status"], name: "index_tasks_on_status"
    t.index ["taskable_type", "taskable_id"], name: "index_tasks_on_taskable"
    t.index ["taskable_type", "taskable_id"], name: "index_tasks_on_taskable_type_and_taskable_id"
  end

  create_table "user_courses", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "course_id", null: false
    t.datetime "joined_at"
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_user_courses_on_course_id"
    t.index ["finished_at"], name: "index_user_courses_on_finished_at"
    t.index ["joined_at"], name: "index_user_courses_on_joined_at"
    t.index ["user_id", "course_id"], name: "index_user_courses_on_user_id_and_course_id", unique: true
    t.index ["user_id"], name: "index_user_courses_on_user_id"
  end

  create_table "user_subjects", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_course_id", null: false
    t.bigint "course_subject_id", null: false
    t.integer "status", default: 0
    t.text "notes"
    t.float "score"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["completed_at"], name: "index_user_subjects_on_completed_at"
    t.index ["course_subject_id"], name: "index_user_subjects_on_course_subject_id"
    t.index ["score"], name: "index_user_subjects_on_score"
    t.index ["started_at"], name: "index_user_subjects_on_started_at"
    t.index ["status"], name: "index_user_subjects_on_status"
    t.index ["user_course_id", "course_subject_id"], name: "index_user_subjects_on_user_course_id_and_course_subject_id", unique: true
    t.index ["user_course_id"], name: "index_user_subjects_on_user_course_id"
  end

  create_table "user_tasks", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "task_id", null: false
    t.bigint "user_subject_id", null: false
    t.integer "status", default: 0
    t.integer "spent_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["spent_time"], name: "index_user_tasks_on_spent_time"
    t.index ["status"], name: "index_user_tasks_on_status"
    t.index ["task_id"], name: "index_user_tasks_on_task_id"
    t.index ["user_id", "task_id"], name: "index_user_tasks_on_user_id_and_task_id", unique: true
    t.index ["user_id"], name: "index_user_tasks_on_user_id"
    t.index ["user_subject_id"], name: "index_user_tasks_on_user_subject_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.date "birthday"
    t.integer "gender"
    t.string "remember_digest"
    t.string "activation_digest"
    t.boolean "activated", default: false
    t.datetime "activated_at"
    t.string "reset_digest"
    t.datetime "reset_sent_at"
    t.string "nick_name"
    t.integer "role", default: 0
    t.date "member_from"
    t.date "member_to"
    t.datetime "email_verified_at"
    t.boolean "is_admin", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["email_verified_at"], name: "index_users_on_email_verified_at"
    t.index ["is_admin"], name: "index_users_on_is_admin"
    t.index ["member_from", "member_to"], name: "index_users_on_member_from_and_member_to"
    t.index ["member_from"], name: "index_users_on_member_from"
    t.index ["member_to"], name: "index_users_on_member_to"
    t.index ["nick_name"], name: "index_users_on_nick_name"
    t.index ["role", "is_admin"], name: "index_users_on_role_and_is_admin"
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "comments", "users"
  add_foreign_key "course_categories", "categories"
  add_foreign_key "course_categories", "courses"
  add_foreign_key "course_subjects", "courses"
  add_foreign_key "course_subjects", "subjects"
  add_foreign_key "course_supervisors", "courses"
  add_foreign_key "course_supervisors", "users"
  add_foreign_key "courses", "users"
  add_foreign_key "daily_reports", "courses"
  add_foreign_key "daily_reports", "users"
  add_foreign_key "subject_categories", "categories"
  add_foreign_key "subject_categories", "subjects"
  add_foreign_key "user_courses", "courses"
  add_foreign_key "user_courses", "users"
  add_foreign_key "user_subjects", "course_subjects"
  add_foreign_key "user_subjects", "user_courses"
  add_foreign_key "user_tasks", "tasks"
  add_foreign_key "user_tasks", "user_subjects"
  add_foreign_key "user_tasks", "users"
end

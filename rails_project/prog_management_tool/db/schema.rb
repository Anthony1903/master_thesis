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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20121106110101) do

  create_table "contraintes", :force => true do |t|
    t.integer  "pmodule_id", :null => false
    t.string   "cond",       :null => false
    t.string   "effet",      :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "contraintes", ["pmodule_id", "cond", "effet"], :name => "index_contraintes_on_pmodule_id_and_cond_and_effet", :unique => true

  create_table "cours_contenus", :force => true do |t|
    t.integer  "pmodule_id", :null => false
    t.float    "dureeCours", :null => false
    t.float    "dureeTP",    :null => false
    t.integer  "quadri"
    t.string   "professeur"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "cours_contenus", ["pmodule_id"], :name => "index_cours_contenus_on_pmodule_id", :unique => true

  create_table "diplomes", :force => true do |t|
    t.string   "sigle",      :null => false
    t.string   "cycle",      :null => false
    t.string   "facSigle",   :null => false
    t.integer  "pmodule_id", :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "diplomes", ["sigle"], :name => "index_diplomes_on_sigle", :unique => true

  create_table "ensemble_contenus", :force => true do |t|
    t.integer  "pmodule_id",  :null => false
    t.integer  "contenu_id",  :null => false
    t.string   "annee",       :null => false
    t.boolean  "obligatoire", :null => false
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "ensemble_contenus", ["pmodule_id", "contenu_id"], :name => "index_ensemble_contenus_on_pmodule_id_and_contenu_id", :unique => true

  create_table "pmodules", :force => true do |t|
    t.string   "mtype",                                     :null => false
    t.integer  "creditsMin",                                :null => false
    t.integer  "creditsMax",                                :null => false
    t.text     "intitule"
    t.string   "langue",             :default => "fr-angl", :null => false
    t.string   "dptCharge"
    t.text     "commentaire"
    t.integer  "validite"
    t.text     "import_commentaire"
    t.string   "status",             :default => "actuel",  :null => false
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
  end

  create_table "sigles", :force => true do |t|
    t.integer  "pmodule_id", :null => false
    t.string   "sigle",      :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "sigles", ["sigle"], :name => "index_sigles_on_sigle", :unique => true

end

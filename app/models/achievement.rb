class Achievement < ApplicationRecord
  CATALOG = {
    "mae_dina" => ["Mae Dina", "Acertar 3 placares exatos."],
    "cacador_de_zebra" => ["Cacador de Zebra", "Acertar vitoria de time marcado como azarão."],
    "zicador" => ["Zicador", "Errar 5 palpites finalizados seguidos."],
    "pe_quente" => ["Pe Quente", "Acertar 5 vencedores seguidos."],
    "geladeira" => ["Geladeira", "Ficar 3 rodadas seguidas sem pontuar."],
    "sniper" => ["Sniper", "Acertar placar exato em mata-mata."],
    "ultima_hora" => ["Ultima Hora", "Palpitar entre 20 e 10 minutos antes do jogo."]
  }.freeze

  has_many :user_achievements, dependent: :destroy
  has_many :users, through: :user_achievements

  validates :key, presence: true, uniqueness: true
  validates :name, :description, presence: true

  def self.ensure_catalog!
    CATALOG.each do |key, (name, description)|
      find_or_create_by!(key: key) do |achievement|
        achievement.name = name
        achievement.description = description
      end
    end
  end
end

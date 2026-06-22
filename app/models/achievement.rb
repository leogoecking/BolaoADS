class Achievement < ApplicationRecord
  CATALOG = {
    "mae_dina" => ["Mae Dina", "Acertar 3 placares exatos."],
    "cacador_de_zebra" => ["Cacador de Zebra", "Acertar vitoria de time marcado como azarão."],
    "zicador" => ["Zicador", "Errar 5 palpites finalizados seguidos."],
    "pe_quente" => ["Pe Quente", "Acertar 5 vencedores seguidos."],
    "geladeira" => ["Geladeira", "Ficar 3 rodadas seguidas sem pontuar."],
    "sniper" => ["Sniper", "Acertar placar exato em mata-mata."],
    "ultima_hora" => ["Ultima Hora", "Palpitar entre 20 e 10 minutos antes do jogo."],
    "maratonista_grupos" => ["Maratonista da Fase de Grupos", "Fazer palpites em 30 jogos da fase de grupos."],
    "nao_dormiu_no_ponto" => ["Nao Dormiu no Ponto", "Palpitar em todos os jogos de um mesmo dia."],
    "cheirinho_lideranca" => ["Cheirinho de Lideranca", "Subir 3 ou mais posicoes no ranking apos um jogo encerrado."],
    "all_in_consciente" => ["All-in Consciente", "Apostar 100+ ADcoins em um palpite e pontuar."],
    "so_passou_raiva" => ["So Passou Raiva", "Errar 10 palpites finalizados no total."],
    "sobreviveu_mata_mata" => ["Sobreviveu ao Mata-Mata", "Acertar qualquer resultado em jogo eliminatorio."],
    "magnata_do_palpite" => ["Magnata do Palpite", "Ser o usuario com mais ADcoins."],
    "milionario_de_mentira" => ["Milionario de Mentira", "Acumular 1.000 ADcoins."]
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

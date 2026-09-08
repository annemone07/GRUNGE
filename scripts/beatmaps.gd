class_name beatmaps

var music_1 = {
	"title": "Nome Música 01",
	"artist": "Nome Artista 01",
	"music": preload("res://assets/songs/song_01/music_01.mp3"),
	"guitar":{
		1: {1:"c"},
		1.5: {2:"c"},
		2: {1:"c"},
		2.5: {2:"c"}
	},
	"drums":{
		1: {1:"c"},
		1.5: {2:"c"},
		2: {1:"c"},
		2.5: {2:"c"}
		},
	"vocal":{
		
		},
	"bass":{

		}
}

var music_2 = {
	"title": "Nome Música 02",
	"artist": "Nome Artista 02",
	"music": preload("res://assets/songs/song_02/music_02.mp3"),
	"guitar":{
		
	},
	"drums":{
		
		},
	"vocal":{
		
		},
	"bass":{
		
		}
}

var music_3 = {
	"title": "Nome Música 03",
	"artist": "Nome Artista 03",
	"music": preload("res://assets/songs/song_03/music_03.mp3"),
	"guitar":{
		
	},
	"drums":{
		
		},
	"vocal":{
		
		},
	"bass":{
		
		}
}

func _get(property: StringName):
	if property == &"1" or property == &"music_1": return music_1
	if property == &"2" or property == &"music_2": return music_2
	if property == &"3" or property == &"music_3": return music_3
	return null

# ==========================================
# GUIA PARA CRIAR OS BEATMAPS DAS MÚSICAS
# ==========================================
# Para adicionar as notas nas chaves ("guitar", "drums", "vocal", "bass"), 
# use o tempo exato em segundos como chave, seguido pelas pistas (tracks) e o tipo da nota.
# 
# Formato padrão:
#   "tempo_em_segundos": { track: "tipo_da_nota", track: "tipo_da_nota" }
#
# Tipos de notas disponíveis:
#   - "sq" -> Nota Quadrada (square)
#   - "c"  -> Nota Circular (circle)
#   - Tenha em mente que para trocar entre circular e quadrada terá o botão do pedal 
#   - Ent pense sempre no delayzinho pra apertar o pedal.
# Exemplo prático:
#   "0.5": { 1: "sq", 4: "sq" },
#   "1.23": {2: "c", 3: "c", 4: "c"}
#   (No segundo 0.5 da música, aparece uma nota "sq" na track 1 e uma "c" na track 4).
#	enquanto no segundo 1.23 terá uma nota c na track 2, 3 e 4.

# Instrução final:
#   Pode escolher as músicas que quiser, preencher os beatmaps seguindo esse modelo .
#   e me mandar a lista das músicas lá no meu zap. 
#   Para testar basta rodar o jogo em single player e escolher a musica.
#   se quiser adicionar mais alguma me avisa.
#	preencher também o nome das músicas na variável var music_database dentro do script globals.gd (basta dar ctrl f)

# ==========================================

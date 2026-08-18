class_name beatmaps

#formato:
#instrumento: tempo da nota(segundos): posição da nota: tipo da nota(SQuare ou Circle)

var music_1 = {
	"music":preload("res://assets/musics/skulls_adventure.mp3"),
	"guitar":{
		0.0: {1:"sq",2:"c"},
		0.1: {1:"sq",2:"sq"},
		0.2: {1:"sq",2:"c"},
		0.3: {1:"c",2:"c"},
		0.4: {1:"sq",2:"c"},
		0.5: {1:"sq",2:"c"},
	},
	"drums": {
		1: {1:"c",2:"c"},
		2: {1:"c",2:"sq"},
	}
}

var music_2 = {
	"music":preload("res://assets/musics/skulls_adventure.mp3"),
	"guitar":{
		0.0: [1,2],
		0.1: [1,2],
		0.2: [1,2],
		0.3: [1,2],
		0.4: [1,2],
		0.5: [1,2],
	},
	"drums": {
		1: [1,2,3,4],
		2: [5,6,7,8],
	}
}

var music_3 = {
	"music":preload("res://assets/musics/skulls_adventure.mp3"),
	"guitar":{
		0.0: [1,2],
		0.1: [1,2],
		0.2: [1,2],
		0.3: [1,2],
		0.4: [1,2],
		0.5: [1,2],
	},
	"drums": {
		1: [1,2,3,4],
		2: [5,6,7,8],
	}
}

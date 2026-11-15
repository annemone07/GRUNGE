class_name NoteData
extends RefCounted

enum State {
	PENDING,   # Ainda não chegou na linha de acerto
	HOLDING,   # Cabeça acertada; jogador segurando o sustain
	COMPLETED, # Nota concluída com sucesso
	MISSED     # Passou do tempo ou jogador soltou antes da hora
}

var time: float = 0.0          # Momento exato do hit (segundos)
var lane: int = 1              # Pista (1 a 4, ou 1 a 8 na bateria)
var shape: String = "c"        # "c" (círculo) ou "sq" (quadrado)
var duration: float = 0.0      # 0.0 = nota simples; > 0.0 = nota segurável

var state: State = State.PENDING
var visual_node: Node3D = null # Referência para a instância 3D na tela
var hold_score_accum: float = 0.0

func _init(p_time: float, p_lane: int, p_shape: String, p_duration: float = 0.0) -> void:
	time = p_time
	lane = p_lane
	shape = p_shape
	duration = maxf(0.0, p_duration)

func is_sustain() -> bool:
	return duration > 0.05

func end_time() -> float:
	return time + duration

static func from_dict(data: Dictionary) -> NoteData:
	return NoteData.new(
		float(data.get("time", 0.0)),
		int(data.get("lane", 1)),
		str(data.get("type", "c")),
		float(data.get("duration", 0.0))
	)

func to_dict() -> Dictionary:
	return {
		"time": snappedf(time, 0.001),
		"lane": lane,
		"type": shape,
		"duration": snappedf(duration, 0.001)
	}

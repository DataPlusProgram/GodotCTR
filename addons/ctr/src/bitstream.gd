
class_name BitStreamReader
extends Node

var stream: StreamPeerBuffer
var cache: int = 0
var bits_taken: int = 0

func init(data: PackedByteArray):
	stream = StreamPeerBuffer.new()
	stream.data_array = data
	stream.seek(0)
	cache = read_reversed()
	


func take_bit() -> int:
	return take_bits(1)


func take_bits(amount: int) -> int:
	if amount == 0:
		return 0
	if amount > 16:
		push_error("Cannot take more than 16 bits.")
		return 0

	var result = 0
	for i in range(amount):
		var bit = cache & 1
		result |= bit << i
		cache >>= 1
		bits_taken += 1

		if bits_taken >= 32:
			bits_taken = 0
			cache = read_reversed()
	
	return result


func read_reversed() -> int:
	if stream.get_available_bytes() < 4:
		return 0 
	
	var value = stream.get_u32()
	var result = 0

	for i in range(32):
		result |= (value & 1) << (31 - i)
		value >>= 1

	return result


type Connection = {
	Disconnect: (Connection) -> ()
	
}

export type Signal<T...> = {
	
	Connect: (Signal<T...>, (T...) -> ()) -> Connection,
	Once: (Signal<T...>, (T...) -> ()) -> Connection,
	Wait: (Signal<T...>) -> T...,
	Fire: (Signal<T...>, T...) -> ()
	
}

return {
	
	bridges = {},
	identifiers = {},
	
	queue = {}
	
}
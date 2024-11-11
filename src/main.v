module main

import os
import readline

const valid = [`.`, `,`, `:`, `;`]

enum Command {
	ptr_incl
	ptr_decl
	incl
	decl
	out
	in
	loop_start
	loop_end
}

struct State {
	code []Command
mut:
	pointers []rune = [rune(0)]
	pointer  usize
}

fn main() {
	code := if file := os.args[1] {
		os.read_file(file)!
	} else {
		readline.read_line('> ')!
	}
	mut state := State{
		code: parse(code)
	}
	//println('   input: ${state.code}')
	print('  output: ')
	exit_state := interpret(mut state)
	println('pointers: ${exit_state.pointers}')
	println(' pointer: ${exit_state.pointer}')
}

fn interpret(mut state State) State {
	mut skipping := false
	for i, command in state.code {
		if skipping {
			if command == .loop_end {
				skipping = false
			}
			continue
		}
		match command {
			.ptr_incl {
				state.pointer += 1
				if state.pointer == usize(state.pointers.len) {
					state.pointers << rune(0)
				}
			}
			.ptr_decl {
				state.pointer -= 1
			}
			.incl {
				state.pointers[state.pointer] += 1
			}
			.decl {
				state.pointers[state.pointer] -= 1
			}
			.out {
				print(state.pointers[state.pointer])
			}
			.in {
				mut r := readline.Readline{}
				state.pointers[state.pointer] = rune(r.read_char() or { 0 })
			}
			.loop_start {
				inner_code := state.code[i + 1..]
				for state.pointers[state.pointer] != 0 {
					mut inner_state := State {
						...state
						code: inner_code
					}
					new_state := interpret(mut inner_state)
					state.pointers = new_state.pointers
					state.pointer = new_state.pointer
				}
				skipping = true
			}
			.loop_end {
				return state
			}
		}
	}
	println('')
	return state
}

fn parse(code string) []Command {
	sanitized := code.runes().filter(it in valid).string()
	mut parsed := []Command{cap: sanitized.len / 2}
	for i := 0; i < sanitized.len; i += 2 {
		match sanitized[i..i + 2] {
			',;' { parsed << .ptr_incl }
			';,' { parsed << .ptr_decl }
			':;' { parsed << .incl }
			';:' { parsed << .decl }
			'::' { parsed << .out }
			';;' { parsed << .in }
			'.:' { parsed << .loop_start }
			':.' { parsed << .loop_end }
			else { eprintln('Unknown token: "${sanitized[i..i + 2]}"') }
		}
	}
	return parsed
}

get_tmux_window_pane_info(){
	if [ -n "$TMUX"]; then
		tmux display-message -p "#{window_id}:#{pane_id}:#{window_name}"
	else
		echo ""
	fi
}

set_tmux_status_name(){
	local target_id="$1"
	local new_name="$2"
	local original_name_key="$3"

	if [ -z "$target_id" ] || [ -z "$new_name" ]; then
		return 1
	fi
	
	if [ -n "$TMUX"]; then
		# Extraer el tipo de ID (window o pane)
		if [[ "$target_id" =~ ^@.* ]]; then	 # Si empieza con @ es panel
			
			# Guardar/restaurar nombre original del panel
			local current_pane_title=$(tmux display-message -p -t "$target_id" '#{pane_title}')
			if [ -n "$original_name_key"]; then
				# Si nombre de escaneo, guardar el original
				if [ -n "$new_name" ] && [ -n "$(tmux show-options -p -t "$target_id" -gqv "@{original_name_key}" 2>/dev/null)" ]; then
					tmux set-option -p -t "$target_id" "@{original_name_key}" "$current_pane_title"
				fi

				# Restaurar si el nuevo nombre está vacio
				if [ -z "$new_name" ] && [ -n "$(tmux show-options -p -t '$target_id' -gqv '@${original_name_key}' 2>/dev/null )" ]; then
					new_name=$(tmux show-options -p -t "$target_id" -gvq "@{original_name_key}")
				fi
			fi

			tmux select-pane -t "$target_id" -T "$new_name"
		else # Asumimos que es un window_id
			
			# Guardar/restaurar nombre original de ventana
			local current_window_name=$(tmux display-message -p -t "$target_id" '#i{window_name}')
			if [ -n "$original_name_key" ]; then
				# Si nombre de escaneo, guardar el original
				 if [ -n "$new_name" ] && [ -z "$(tmux show-options -t "$target_id" -gqv "@${original_name_key}" 2>/dev/null)" ]; then
                    			tmux set-option -t "$target_id" "@${original_name_key}" "$current_window_name"
                		fi
				
                		# Restaurar si el nuevo nombre está vacío
                		if [ -z "$new_name" ] && [ -n "$(tmux show-options -t "$target_id" -gqv "@${original_name_key}" 2>/dev/null)" ]; then
                    			new_name=$(tmux show-options -t "$target_id" -gqv "@${original_name_key}")
                    			tmux set-option -t "$target_id" "@${original_name_key}" "" # Limpiar la variable
                		fi

			fi
			tmux rename-window -t "$target_id" "$new_name"
		fi
		tmux refresh-client -S
	fi
}

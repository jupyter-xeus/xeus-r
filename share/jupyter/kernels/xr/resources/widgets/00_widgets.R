
handler_jupyter.widget.control <- function(comm, message) {
    
    comm$on_message(function(request) {
        data <- request$content$data

        switch(data$method, 
            "request_states" = {
                comm$send(
                    data = list(
                        method = unbox("update_states"), 
                        state = NULL
                    )
                )
            }
        )
    })
}

handler_jupyter.widget <- function(comm, message) {
    comm$on_message(function(request) {
    
    })
}

init_widgets <- function() {
    # CommManager$register_comm_target("jupyter.widget.control", handler_jupyter.widget.control)
    CommManager$register_comm_target("jupyter.widget", handler_jupyter.widget)
}

Widget <- R6::R6Class("jupyter.widget.Widget")

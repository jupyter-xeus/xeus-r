#define R_NO_REMAP

#include "R.h"
#include "Rinternals.h"
#include "R_ext/Rdynload.h"

#include "rtools.hpp"
#include "xeus-r/xinterpreter.hpp"
#include "nlohmann/json.hpp"
#include "xeus/xmessage.hpp"
#include "xeus/xcomm.hpp"
#include "xeus/xlogger.hpp"

#include <functional>

namespace xeus_r {
namespace routines {

SEXP kernel_info_request() {
    auto info = xeus_r::get_interpreter()->kernel_info_request();
    SEXP out = PROTECT(Rf_mkString(info.dump(4).c_str()));
    Rf_classgets(out, Rf_mkString("json"));
    UNPROTECT(1);
    return out;
}

SEXP publish_stream(SEXP name_, SEXP text_) {
    auto name = CHAR(STRING_ELT(name_, 0));
    auto text = CHAR(STRING_ELT(text_, 0));

    auto interpreter = xeus_r::get_interpreter();
    interpreter->publish_stream(name, text);

    return R_NilValue;
}

SEXP display_data(SEXP js_data, SEXP js_metadata){
    auto data = nl::json::parse(CHAR(STRING_ELT(js_data, 0)));
    auto metadata = nl::json::parse(CHAR(STRING_ELT(js_metadata, 0)));
    
    xeus_r::get_interpreter()->display_data(
        std::move(data), std::move(metadata), /* transient = */ nl::json::object()
    );

    return R_NilValue;
}

SEXP update_display_data(SEXP js_data, SEXP js_metadata){
    auto data = nl::json::parse(CHAR(STRING_ELT(js_data, 0)));
    auto metadata = nl::json::parse(CHAR(STRING_ELT(js_metadata, 0)));
    
    xeus_r::get_interpreter()->update_display_data(
        std::move(data), std::move(metadata), /* transient = */ nl::json::object()
    );

    return R_NilValue;
}

SEXP clear_output(SEXP wait_) {
    bool wait = LOGICAL_ELT(wait_, 0) == TRUE;
    xeus_r::get_interpreter()->clear_output(wait);
    return R_NilValue;
}

SEXP is_complete_request(SEXP code_) {
    std::string code = CHAR(STRING_ELT(code_, 0));
    auto is_complete = xeus_r::get_interpreter()->is_complete_request(code);

    SEXP out = PROTECT(Rf_mkString(is_complete.dump(4).c_str()));
    Rf_classgets(out, Rf_mkString("json"));
    UNPROTECT(1);
    return out;
}

SEXP xeusr_log(SEXP level_, SEXP msg_) {
    std::string level = CHAR(STRING_ELT(level_, 0));
    std::string msg = CHAR(STRING_ELT(msg_, 0));

    // TODO: actually do some logging
    return R_NilValue;
}

SEXP xeusr_get_comm_manager__size() {
    auto& manager = xeus_r::get_interpreter()->comm_manager();
    return Rf_ScalarInteger(manager.comms().size());
}

SEXP comm_manager__register_target(SEXP name_) {
    using namespace xeus_r;

    std::string name = CHAR(STRING_ELT(name_, 0));
    
    get_interpreter()->comm_manager().register_comm_target(name, [name](xeus::xcomm&&, xeus::xmessage request) {
        /*
            auto ptr_msg = new xeus::xmessage(std::move(msg));

            SEXP xptr_msg = PROTECT(R_MakeExternalPtr(
                reinterpret_cast<void*>(ptr_msg), R_NilValue, R_NilValue
            ));
            R_RegisterCFinalizerEx(xptr_msg, [](SEXP xp) {
                delete reinterpret_cast<xeus::xmessage*>(R_ExternalPtrAddr(xp));
            }, FALSE);
        */

        SEXP content = PROTECT(Rf_mkString(request.content().dump(4).c_str()));
        Rf_classgets(content, Rf_mkString("json"));
        
        SEXP target_name = PROTECT(Rf_mkString(name.c_str()));
    
        // TODO: pass msg instead of content, probably as an external pointer
        r::invoke_xeusr_fn("comm_target_handle_comm_open", target_name, content);

        UNPROTECT(2);
    });
    return R_NilValue;
}

SEXP comm_manager__unregister_target(SEXP name_) {
    std::string name = CHAR(STRING_ELT(name_, 0));

    xeus_r::get_interpreter()->comm_manager().unregister_comm_target(name);
    return R_NilValue;
}

SEXP comm_manager__comm_open(SEXP s_target_name, SEXP js_data) {
    auto interpreter = xeus_r::get_interpreter();
    
    std::string target_name = CHAR(STRING_ELT(s_target_name, 0));
    auto data = nl::json::parse(CHAR(STRING_ELT(js_data, 0)));

    auto content = nl::json {
        {"comm_id", xeus::new_xguid()}, 
        {"target_name", target_name}, 
        {"data", data}
    };

    auto msg = xeus::xmessage(
        /* zmq_id = */        {},                  // TODO: not sure where to get `zmq_id` from
        /* header = */        nl::json::object(),  // TODO: what should this be ?
        /* parent_header = */ interpreter->parent_header(),
        /* metadata = */      nl::json::object(),          
        /* content = */       content, 
        /* buffers = */       xeus::buffer_sequence()
    );

    interpreter->comm_manager().comm_open(std::move(msg));

    return R_NilValue;
}

}

#ifdef __GNUC__
    #pragma GCC diagnostic push
    #pragma GCC diagnostic ignored "-Wcast-function-type"
#endif
void register_r_routines() {
    DllInfo *info = R_getEmbeddingDllInfo();

    static const R_CallMethodDef callMethods[]  = {
        {"xeusr_kernel_info_request"     , (DL_FUNC) &routines::kernel_info_request     , 0},
        {"xeusr_publish_stream"          , (DL_FUNC) &routines::publish_stream          , 2},
        {"xeusr_display_data"            , (DL_FUNC) &routines::display_data            , 2},
        {"xeusr_update_display_data"     , (DL_FUNC) &routines::update_display_data     , 2},
        {"xeusr_clear_output"            , (DL_FUNC) &routines::clear_output            , 1},
        {"xeusr_is_complete_request"     , (DL_FUNC) &routines::is_complete_request     , 1},
        {"xeusr_log"                     , (DL_FUNC) &routines::xeusr_log               , 2},

        // comms
        {"xeusr_get_comm_manager__size"  , (DL_FUNC) &routines::xeusr_get_comm_manager__size, 0},

        {"xeusr_comm_manager__register_target"    , (DL_FUNC) &routines::comm_manager__register_target, 1},
        {"xeusr_comm_manager__unregister_target"  , (DL_FUNC) &routines::comm_manager__unregister_target, 1},
        {"xeusr_comm_manager__comm_open"          , (DL_FUNC) &routines::comm_manager__comm_open, 2},

        {NULL, NULL, 0}
    };

    R_registerRoutines(info, NULL, callMethods, NULL, NULL);
}
#ifdef __GNUC__
    #pragma GCC diagnostic pop
#endif

}

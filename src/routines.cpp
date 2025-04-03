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

SEXP to_r_json(const nl::json& js) {
    SEXP out = PROTECT(Rf_mkString(js.dump(4).c_str()));
    Rf_classgets(out, Rf_mkString("json"));
    UNPROTECT(1);
    
    return out;
}

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

SEXP CommManager__register_target(SEXP name_) {
    using namespace xeus_r;

    std::string name = CHAR(STRING_ELT(name_, 0));
    
    auto callback = [name](xeus::xcomm&& comm, xeus::xmessage request) {
        // comm
        auto ptr_comm = new xeus::xcomm(std::move(comm));
        SEXP xp_comm = PROTECT(R_MakeExternalPtr(
            reinterpret_cast<void*>(ptr_comm), R_NilValue, R_NilValue
        ));
        R_RegisterCFinalizerEx(xp_comm, [](SEXP xp) {
            delete reinterpret_cast<xeus::xcomm*>(R_ExternalPtrAddr(xp));
        }, FALSE);
        SEXP r6_comm = PROTECT(r::new_hera_r6("Comm", xp_comm));

        // request
        auto ptr_request = new xeus::xmessage(std::move(request));
        SEXP xptr_request = PROTECT(R_MakeExternalPtr(
            reinterpret_cast<void*>(ptr_request), R_NilValue, R_NilValue
        ));
        R_RegisterCFinalizerEx(xptr_request, [](SEXP xp) {
            delete reinterpret_cast<xeus::xmessage*>(R_ExternalPtrAddr(xp));
        }, FALSE);
        SEXP r6_request = PROTECT(r::new_hera_r6("Message", xptr_request));

        // callback
        r::invoke_hera_fn(".CommManager__register_target_callback", r6_comm, r6_request);

        UNPROTECT(4);
    };

    get_interpreter()->comm_manager().register_comm_target(name, callback);
    return R_NilValue;
}

SEXP CommManager__unregister_target(SEXP name_) {
    std::string name = CHAR(STRING_ELT(name_, 0));

    xeus_r::get_interpreter()->comm_manager().unregister_comm_target(name);
    return R_NilValue;
}

SEXP CommManager__new_comm(SEXP target_name_, SEXP s_description) {
    auto target = get_interpreter()->comm_manager().target(CHAR(STRING_ELT(target_name_, 0)));
    if (target == nullptr) {
        return R_NilValue;
    }

    auto id = xeus::new_xguid();
    auto comm = new xeus::xcomm(target, id);
    SEXP xp_comm = PROTECT(R_MakeExternalPtr(
        reinterpret_cast<void*>(comm), R_NilValue, R_NilValue
    ));
    R_RegisterCFinalizerEx(xp_comm, [](SEXP xp) {
        delete reinterpret_cast<xeus::xcomm*>(R_ExternalPtrAddr(xp));
    }, FALSE);
    SEXP r6_comm = PROTECT(r::new_hera_r6("Comm", xp_comm, s_description));

    UNPROTECT(2);

    return r6_comm;
}

SEXP CommManager__get_comm_info(SEXP target_name_) {
    auto comms = get_interpreter()->comm_manager().comms();
    
    bool keep_all = Rf_isNull(target_name_);
    std::string target_name(keep_all ? "" : CHAR(STRING_ELT(target_name_, 0)));
    
    size_t comms_size = comms.size(); 
    size_t size = 0;
    if (keep_all) {
        size = comms_size;
    } else {
        auto comm_it = comms.begin();
        for (size_t i = 0; i < comms_size; i++, ++comm_it) {
            if (target_name == comm_it->second->target().name()) {
                size++;
            }
        }
    }

    SEXP out = PROTECT(Rf_allocVector(STRSXP, size));
    SEXP names = PROTECT(Rf_allocVector(STRSXP, size));
    auto comm_it = comms.begin();
    
    for (size_t i = 0; comm_it != comms.end(); ++comm_it) {
        auto* comm = comm_it->second;
        if (keep_all || target_name == comm->target().name()) {
            SET_STRING_ELT(names, i, Rf_mkChar(comm_it->first.c_str()));
            SET_STRING_ELT(out, i, Rf_mkChar(comm_it->second->target().name().c_str()));
            i++;
        }
    }
    Rf_namesgets(out, names);
    UNPROTECT(2);
    return out;
}

SEXP Comm__id(SEXP xp_comm) {
    auto comm = reinterpret_cast<xeus::xcomm*>(R_ExternalPtrAddr(xp_comm));
    return Rf_mkString(comm->id().c_str());
}

SEXP Comm__target_name(SEXP xp_comm) {
    auto comm = reinterpret_cast<xeus::xcomm*>(R_ExternalPtrAddr(xp_comm));
    return Rf_mkString(comm->target().name().c_str());
}

SEXP Comm__open(SEXP xp_comm, SEXP js_metadata, SEXP js_data) {
    auto metadata = nl::json::parse(CHAR(STRING_ELT(js_metadata, 0)));
    auto data = nl::json::parse(CHAR(STRING_ELT(js_data, 0)));
    
    auto* comm = reinterpret_cast<xeus::xcomm*>(R_ExternalPtrAddr(xp_comm));
    comm->open(metadata, data, xeus::buffer_sequence());
    
    return R_NilValue;
}

SEXP Comm__close(SEXP xp_comm, SEXP js_metadata, SEXP js_data) {
    auto metadata = nl::json::parse(CHAR(STRING_ELT(js_metadata, 0)));
    auto data = nl::json::parse(CHAR(STRING_ELT(js_data, 0)));
    
    auto* comm = reinterpret_cast<xeus::xcomm*>(R_ExternalPtrAddr(xp_comm));
    comm->close(metadata, data, xeus::buffer_sequence());
    
    return R_NilValue;
}

SEXP Comm__send(SEXP xp_comm, SEXP js_metadata, SEXP js_data) {
    auto metadata = nl::json::parse(CHAR(STRING_ELT(js_metadata, 0)));
    auto data = nl::json::parse(CHAR(STRING_ELT(js_data, 0)));
    
    auto* comm = reinterpret_cast<xeus::xcomm*>(R_ExternalPtrAddr(xp_comm));
    comm->send(metadata, data, xeus::buffer_sequence());
    
    return R_NilValue;
}

class Comm_Message_handler {
public:
    Comm_Message_handler(SEXP handler) : m_handler(handler){}

    inline void operator()(xeus::xmessage message) {
        auto ptr_message = new xeus::xmessage(std::move(message));
        SEXP xptr_message = PROTECT(R_MakeExternalPtr(
            reinterpret_cast<void*>(ptr_message), R_NilValue, R_NilValue
        ));
        R_RegisterCFinalizerEx(xptr_message, [](SEXP xp) {
            delete reinterpret_cast<xeus::xmessage*>(R_ExternalPtrAddr(xp));
        }, FALSE);
        
        SEXP call = PROTECT(r::r_call(
            m_handler, 
            r::new_hera_r6("Message", xptr_message))
        );

        Rf_eval(call, R_GlobalEnv);

        UNPROTECT(2);
    }

private:
    SEXP m_handler;
};

SEXP Comm__on_close(SEXP xp_comm, SEXP handler) {
    reinterpret_cast<xeus::xcomm*>(R_ExternalPtrAddr(xp_comm))->on_close(Comm_Message_handler(handler));
    return R_NilValue;
}

SEXP Comm__on_message(SEXP xp_comm, SEXP handler) {
    reinterpret_cast<xeus::xcomm*>(R_ExternalPtrAddr(xp_comm))->on_message(Comm_Message_handler(handler));
    return R_NilValue;
}

SEXP Message__get_content(SEXP xptr_msg) {
    auto ptr_msg = reinterpret_cast<xeus::xmessage*>(R_ExternalPtrAddr(xptr_msg));
    return to_r_json(ptr_msg->content());
}

SEXP Message__get_header(SEXP xptr_msg) {
    auto ptr_msg = reinterpret_cast<xeus::xmessage*>(R_ExternalPtrAddr(xptr_msg));
    return to_r_json(ptr_msg->header());
}

SEXP Message__get_parent_header(SEXP xptr_msg) {
    auto ptr_msg = reinterpret_cast<xeus::xmessage*>(R_ExternalPtrAddr(xptr_msg));
    return to_r_json(ptr_msg->parent_header());
}

SEXP Message__get_metadata(SEXP xptr_msg) {
    auto ptr_msg = reinterpret_cast<xeus::xmessage*>(R_ExternalPtrAddr(xptr_msg));
    return to_r_json(ptr_msg->metadata());
}

}

#ifdef __GNUC__
    #pragma GCC diagnostic push
    #pragma GCC diagnostic ignored "-Wcast-function-type"
#endif
void register_r_routines() {
    DllInfo *info = R_getEmbeddingDllInfo();

    static const R_CallMethodDef callMethods[]  = {
        {"xeusr_kernel_info_request"       , (DL_FUNC) &routines::kernel_info_request     , 0},
        {"xeusr_publish_stream"            , (DL_FUNC) &routines::publish_stream          , 2},
        {"xeusr_display_data"              , (DL_FUNC) &routines::display_data            , 2},
        {"xeusr_update_display_data"       , (DL_FUNC) &routines::update_display_data     , 2},
        {"xeusr_clear_output"              , (DL_FUNC) &routines::clear_output            , 1},
        {"xeusr_is_complete_request"       , (DL_FUNC) &routines::is_complete_request     , 1},
        {"xeusr_log"                       , (DL_FUNC) &routines::xeusr_log               , 2},

        // CommManager
        {"CommManager__register_target"    , (DL_FUNC) &routines::CommManager__register_target, 1},
        {"CommManager__unregister_target"  , (DL_FUNC) &routines::CommManager__unregister_target, 1},
        {"CommManager__new_comm"           , (DL_FUNC) &routines::CommManager__new_comm, 2},
        {"CommManager__get_comm_info"      , (DL_FUNC) &routines::CommManager__get_comm_info, 1},
        
        // Comm
        {"Comm__id"                        , (DL_FUNC) &routines::Comm__id, 1},
        {"Comm__target_name"               , (DL_FUNC) &routines::Comm__target_name, 1},
        {"Comm__open"                      , (DL_FUNC) &routines::Comm__open, 3},
        {"Comm__close"                     , (DL_FUNC) &routines::Comm__close, 3},
        {"Comm__send"                      , (DL_FUNC) &routines::Comm__send, 3},
        {"Comm__on_close"                  , (DL_FUNC) &routines::Comm__on_close, 2},
        {"Comm__on_message"                , (DL_FUNC) &routines::Comm__on_message, 2},

        // Message aka xeus::xmessage
        {"Message__get_content"            , (DL_FUNC) &routines::Message__get_content, 1},
        {"Message__get_header"             , (DL_FUNC) &routines::Message__get_header, 1},
        {"Message__get_parent_header"      , (DL_FUNC) &routines::Message__get_parent_header, 1},
        {"Message__get_metadata"           , (DL_FUNC) &routines::Message__get_metadata, 1},

        {NULL, NULL, 0}
    };

    R_registerRoutines(info, NULL, callMethods, NULL, NULL);
}
#ifdef __GNUC__
    #pragma GCC diagnostic pop
#endif

}

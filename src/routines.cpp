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


#ifdef EMSCRIPTEN
#include "xeus-r/xinterpreter_wasm.hpp"

#include <emscripten/val.h>
#include <fstream>
#include <vector>
#include <tuple>
#include <optional>
#endif



namespace xeus_r {
namespace routines {


#ifdef EMSCRIPTEN

using emval = emscripten::val;

// some adh-hoc error handling helpers
template<class T>
using wrapped_return = std::tuple<
    std::optional<T>, // result
    std::optional<std::string> // error message
>;



// Convert a named character vector to std::map<std::string, std::string>
// when x is NULL we return an empty map
wrapped_return<std::map<std::string, std::string>> namedCharToMap(SEXP x) {
    std::map<std::string, std::string> out;

    if (Rf_isNull(x)){
         return {out, std::nullopt};
    }

    if (TYPEOF(x) != STRSXP) {
        return {std::nullopt, "Expected a named character vector but got a " + std::string(Rf_type2char(TYPEOF(x)))};
    }

    SEXP nms = Rf_getAttrib(x, R_NamesSymbol);
    if (Rf_isNull(nms) || TYPEOF(nms) != STRSXP) {
        return {std::nullopt, "Expected a named character vector but got a vector without names"};
    }

    int n = Rf_length(x);
    if (Rf_length(nms) != n) {
        return {std::nullopt, "Names and values have different lengths"};
    }

    for (int i = 0; i < n; ++i) {
        SEXP k = STRING_ELT(nms, i);
        SEXP v = STRING_ELT(x, i);

        // skip NA names
        if (k == NA_STRING) continue;

        const char* key = Rf_translateCharUTF8(k);
        // treat NA values as empty string (or skip—your choice)
        const char* val = (v == NA_STRING) ? "" : Rf_translateCharUTF8(v);

        out[std::string(key)] = std::string(val);
    }
    return {out, std::nullopt};
}

// Convert a character string (scalar or vector) to std::string
// if its null return empty string
wrapped_return<std::string> sexpToString(SEXP s) {
    if (Rf_isNull(s)) return {std::string(), std::nullopt};

    if (TYPEOF(s) != STRSXP) {
        return {std::nullopt, "Expected a character vector but got a " + std::string(Rf_type2char(TYPEOF(s)))};
    }
    if (Rf_length(s) < 1) return {
        std::string(), std::nullopt
    }; // return empty string for empty character vector

    SEXP str_elt = STRING_ELT(s, 0);       // <- use s here

    if (str_elt == NA_STRING) return {std::string(), std::nullopt};

    // Use UTF-8 for consistency
    return {std::string(Rf_translateCharUTF8(str_elt)), std::nullopt};
}

SEXP xeus_download_file(
    SEXP url,
    SEXP destfile, 
    SEXP method,
    SEXP quiet,
    SEXP mode,
    SEXP cacheOK,
    SEXP extra,
    SEXP headers 
) {
    // Validate logical args
    if (TYPEOF(quiet) != LGLSXP || Rf_length(quiet) < 1)
        return Rf_mkString("'quiet' must be a logical(1)");
    if (TYPEOF(cacheOK) != LGLSXP || Rf_length(cacheOK) < 1)
        return Rf_mkString("'cacheOK' must be a logical(1)");

    // URL
    auto [opt_url_str, opt_url_err] = sexpToString(url);
    if (opt_url_err) {
        return Rf_mkString(opt_url_err->c_str());
    }
    std::string url_str = *opt_url_str;

    // destfile
    auto [opt_destfile_str, opt_destfile_err] = sexpToString(destfile);
    if (opt_destfile_err) {
        return Rf_mkString(opt_destfile_err->c_str());
    }
    std::string destfile_str = *opt_destfile_str;

    // method
    auto [opt_method_str, opt_method_err] = sexpToString(method);
    if (opt_method_err) {
        return Rf_mkString(opt_method_err->c_str());
    }
    std::string method_str = *opt_method_str;

    // quiet
    bool quiet_mode = LOGICAL_ELT(quiet, 0) == TRUE;

    // mode
    auto [opt_mode_str, opt_mode_err] = sexpToString(mode);
    if (opt_mode_err) {
        return Rf_mkString(opt_mode_err->c_str());
    }
    std::string mode_str = *opt_mode_str;

    // extra options
    auto [opt_extra_str, opt_extra_err] = sexpToString(extra);
    if (opt_extra_err) {
        return Rf_mkString(opt_extra_err->c_str());
    }
    std::string extra_str = *opt_extra_str;

    // cacheOK?
    bool cache_ok = LOGICAL_ELT(cacheOK, 0) == TRUE;

    // headers as c++map
    auto [opt_headers_map, opt_headers_err] = namedCharToMap(headers);
    if (opt_headers_err) {
        return Rf_mkString(opt_headers_err->c_str());
    }
    std::map<std::string, std::string> headers_map = *opt_headers_map;

    // convert to a javascript object
    emval js_headers = emval::object();
    for (const auto& kv : headers_map) js_headers.set(kv.first, kv.second);

    // get the interpreter signleton as this is holding the js-function
    // we need to call
    auto& wasm_interpreter = static_cast<xeus_r::wasm_interpreter&>(xeus::get_interpreter());

    // call the download file function
    emval result = wasm_interpreter.m_download_file_function(
        url_str, quiet_mode, cache_ok, js_headers
    );
    // check for errors
    if (result["has_error"].as<bool>()) {
        std::string error_msg = result["error_msg"].as<std::string>();
        // instead of throwing an error, we return the error message itself.
        // when there is no error we return null
        return Rf_mkString(error_msg.c_str());
    }
    // no error:
    // convert the ArrayBuffer to a std::vector<uint8_t>
    emval arrayBuffer = result["data"];
    emval js_uint8array = emval::global("Uint8Array").new_(arrayBuffer);
    const size_t length = js_uint8array["length"].as<size_t>();
    std::vector<uint8_t> vec_data(length);
    emval heap = emval::module_property("HEAPU8");
    emval memory = heap["buffer"];
    emval memory_view = js_uint8array["constructor"].new_(memory, 
                reinterpret_cast<uintptr_t>(vec_data.data()), 
                length);
    memory_view.call<void>("set", js_uint8array);

    // write the data to the file
    bool appending = mode_str.size()>= 1 && mode_str[0] == 'a';
    std::ofstream ofs(destfile_str, std::ios::binary | (appending ? std::ios::app : std::ios::trunc));
    if (!ofs) {
        return Rf_mkString("Failed to open destination file: ");
    }
    ofs.write(reinterpret_cast<const char*>(vec_data.data()), vec_data.size());
    if (!ofs) {
        return Rf_mkString("Failed to write to destination file: ");
    }

    ofs.close();
    if (!ofs) {
        return Rf_mkString("Failed to close destination file: ");
    }

    return R_NilValue; // Return NULL to indicate success
}
#endif

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

    SEXP info = PROTECT(Rf_allocVector(VECSXP, size));
    SEXP info_names = PROTECT(Rf_allocVector(STRSXP, size));
    SEXP str_target_name = PROTECT(Rf_mkString("target_name"));
    auto comm_it = comms.begin();
    
    for (size_t i = 0; comm_it != comms.end(); ++comm_it) {
        auto* comm = comm_it->second;
        if (keep_all || target_name == comm->target().name()) {
            SEXP x = PROTECT(Rf_allocVector(STRSXP, 1));
            Rf_namesgets(x, str_target_name);
            SET_STRING_ELT(x, 0, Rf_mkChar(comm_it->second->target().name().c_str()));
            
            SET_VECTOR_ELT(info, i, x);
            UNPROTECT(1);

            SET_STRING_ELT(info_names, i, Rf_mkChar(comm_it->first.c_str()));
            i++;
        }
    }
    Rf_namesgets(info, info_names);
    UNPROTECT(3);
    return info;
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

        // lite methods / polyfills
        #ifdef EMSCRIPTEN
        {"xeus_download_file"                , (DL_FUNC) &routines::xeus_download_file, 8},
        #endif

        {NULL, NULL, 0}
    };

    R_registerRoutines(info, NULL, callMethods, NULL, NULL);
}
#ifdef __GNUC__
    #pragma GCC diagnostic pop
#endif

}

#define R_NO_REMAP

#include "R.h"
#include "Rinternals.h"
#include "R_ext/Rdynload.h"

#include "xeus-r/xinterpreter.hpp"
#include "nlohmann/json.hpp"

namespace xeus_r {
namespace routines {

namespace {
SEXP json_dump(const nl::json& data) {
    SEXP out = PROTECT(Rf_mkString(data.dump(4).c_str()));
    Rf_classgets(out, Rf_mkString("json"));
    UNPROTECT(1);
    return out;
}
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
    xeus_r::get_interpreter()->publish_stream(name, text);

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

    return json_dump(is_complete);
}

SEXP log(SEXP level_, SEXP msg_) {
    std::string level = CHAR(STRING_ELT(level_, 0));
    std::string msg = CHAR(STRING_ELT(msg_, 0));

    // TODO: actually do some logging
    return R_NilValue;
}

SEXP history_get_tail(SEXP n_, SEXP raw_, SEXP output_) {
    int n = INTEGER_ELT(n_, 0);
    bool raw = LOGICAL_ELT(raw_, 0) == TRUE;
    bool output = LOGICAL_ELT(output_, 0) == TRUE;

    auto tail = xeus_r::get_interpreter()->get_history_manager().get_tail(n, raw, output);
    return json_dump(tail);
}

SEXP history_search(SEXP pattern_, SEXP raw_, SEXP output_, SEXP n_, SEXP unique_) {
    std::string pattern = CHAR(STRING_ELT(pattern_, 0));
    bool raw = LOGICAL_ELT(raw_, 0) == TRUE;
    bool output = LOGICAL_ELT(output_, 0) == TRUE;
    int n = INTEGER_ELT(n_, 0);
    bool unique = LOGICAL_ELT(unique_, 0) == TRUE;
    
    auto search = xeus_r::get_interpreter()->get_history_manager().search(pattern, raw, output, n, unique);
    return json_dump(search);
}

SEXP history_get_range(SEXP session_, SEXP start_, SEXP stop_, SEXP raw_, SEXP output_) {
    int session = INTEGER_ELT(session_, 0);
    int start = INTEGER_ELT(start_, 0);
    int stop = INTEGER_ELT(stop_, 0);
    bool raw = LOGICAL_ELT(raw_, 0) == TRUE;
    bool output = LOGICAL_ELT(output_, 0) == TRUE;

    auto range = xeus_r::get_interpreter()->get_history_manager().get_range(session, start, stop, raw, output);
    return json_dump(range);
}

}

void register_r_routines() {
    DllInfo *info = R_getEmbeddingDllInfo();

    static const R_CallMethodDef callMethods[]  = {
        {"xeusr_kernel_info_request"     , (DL_FUNC) &routines::kernel_info_request     , 0},
        {"xeusr_publish_stream"          , (DL_FUNC) &routines::publish_stream          , 2},
        {"xeusr_display_data"            , (DL_FUNC) &routines::display_data            , 2},
        {"xeusr_update_display_data"     , (DL_FUNC) &routines::update_display_data     , 2},
        {"xeusr_clear_output"            , (DL_FUNC) &routines::clear_output            , 1},
        {"xeusr_is_complete_request"     , (DL_FUNC) &routines::is_complete_request     , 1},
        {"xeusr_log"                     , (DL_FUNC) &routines::log                     , 2},
        {"xeusr_history_get_tail"        , (DL_FUNC) &routines::history_get_tail        , 3},
        {"xeusr_history_search"          , (DL_FUNC) &routines::history_search          , 5},
        {"xeusr_history_get_range"       , (DL_FUNC) &routines::history_get_range       , 5},
        

        {NULL, NULL, 0}
    };

    R_registerRoutines(info, NULL, callMethods, NULL, NULL);
}

}

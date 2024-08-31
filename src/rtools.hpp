#define R_NO_REMAP

#ifndef XEUS_R_RTOOLS_HPP
#define XEUS_R_RTOOLS_HPP

#include "R.h"
#include "Rinternals.h"

namespace xeus_r {
namespace r {

inline SEXP r_pairlist(SEXP head) {
    return Rf_cons(head, R_NilValue);
}

inline SEXP r_call(SEXP head) {
    return Rf_lcons(head, R_NilValue);
}

template<class... Types>
SEXP r_pairlist(SEXP head, Types... tail) {
    PROTECT(head);
    head = Rf_cons(head, r_pairlist(tail...));
    UNPROTECT(1);
    return head;
}

template<class... Types>
SEXP r_call(SEXP head, Types... tail) {
    PROTECT(head);
    head = Rf_lcons(head, r_pairlist(tail...));
    UNPROTECT(1);
    return head;
}

template<class... Types>
SEXP invoke_xeusr_fn(const char* f, Types... args) {
    SEXP sym_xeus_call = Rf_install(".xeus_call");

    SEXP call = PROTECT(r_call(sym_xeus_call, Rf_mkString(f), args...));
    SEXP result = Rf_eval(call, R_GlobalEnv);

    UNPROTECT(1);
    return result;
}

}
}

#endif
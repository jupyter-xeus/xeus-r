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
SEXP invoke_hera_fn(const char* f, Types... args) {
    SEXP sym_hera = Rf_install("hera");
    SEXP sym_hera_call = Rf_install("hera_call");
    SEXP sym_triple_colon = Rf_install(":::");

    SEXP call_triple_colon = PROTECT(r_call(sym_triple_colon, sym_hera, sym_hera_call));
    SEXP call = PROTECT(r_call(call_triple_colon, Rf_mkString(f), args...));
    SEXP result = Rf_eval(call, R_GlobalEnv);

    UNPROTECT(2);
    return result;
}

template <class... Types>
inline SEXP new_hera_r6(const char* klass, SEXP xp, Types... args) {
    SEXP sym_hera = Rf_install("hera");
    SEXP sym_hera_new = Rf_install("hera_new");
    SEXP sym_triple_colon = Rf_install(":::");

    SEXP call = PROTECT(r_call(sym_triple_colon, Rf_mkString(klass), xp, args...));
    SEXP result = Rf_eval(call, R_GlobalEnv);

    UNPROTECT(2);
    return result;
}

}
}

#endif
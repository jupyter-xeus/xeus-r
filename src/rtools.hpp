#define R_NO_REMAP

#include "R.h"
#include "Rinternals.h"

namespace xeus_r {
namespace r {

SEXP r_pairlist(SEXP head) {
    return Rf_cons(head, R_NilValue);
}

SEXP r_call(SEXP head) {
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

}
}
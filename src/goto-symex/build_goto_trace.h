/*******************************************************************\

Module: Traces of GOTO Programs

Author: Daniel Kroening

Date: July 2005

\*******************************************************************/

#ifndef CPROVER_GOTO_SYMEX_BUILD_GOTO_TRACE_H
#define CPROVER_GOTO_SYMEX_BUILD_GOTO_TRACE_H

#include "goto_trace.h"
#include "symex_target_equation.h"
#include "goto_symex_state.h"

void build_goto_trace(
  const symex_target_equationt &target,
  smt_convt &smt_conv,
  goto_tracet &goto_trace);

void build_successful_goto_trace(
  const symex_target_equationt &target,
  smt_convt &smt_conv,
  goto_tracet &goto_trace);

#endif

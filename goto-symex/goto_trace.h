/*******************************************************************\

Module: Traces of GOTO Programs

Author: Daniel Kroening

Date: July 2005

\*******************************************************************/

#ifndef CPROVER_GOTO_SYMEX_GOTO_TRACE_H
#define CPROVER_GOTO_SYMEX_GOTO_TRACE_H

#include <iostream>
#include <vector>

#include <pretty_names.h>

#include <goto-programs/goto_program.h>

class goto_trace_stept 
{
public:
  unsigned step_nr;

  // See SSA_stept.
  std::vector<dstring> stack_trace;
  
  bool is_assignment() const { return type==ASSIGNMENT; }
  bool is_assume() const     { return type==ASSUME; }
  bool is_assert() const     { return type==ASSERT; }
  bool is_output() const     { return type==OUTPUT; }

  typedef enum { ASSIGNMENT, ASSUME, ASSERT, OUTPUT } typet;
  typet type;
    
  goto_programt::const_targett pc;

  // this transition done by given thread number
  unsigned thread_nr;
  
  // for assume, assert, goto
  bool guard;
  
  // for assert
  std::string comment;

  // in SSA
  exprt lhs, rhs;
  
  // this is a constant
  exprt value;
  
  // original expression
  exprt original_lhs;

  // for OUTPUT
  std::string format_string;
  std::list<exprt> output_args;

  void output(
    const class namespacet &ns,
    std::ostream &out) const;
    
  goto_trace_stept():
    step_nr(0),
    thread_nr(0),
    guard(false)
  {
    lhs.make_nil();
    rhs.make_nil();
    value.make_nil();
    original_lhs.make_nil();
  }
};

class goto_tracet
{
public:
  typedef std::list<goto_trace_stept> stepst;
  stepst steps;
  
  std::string mode;
  
  void clear()
  {
    mode.clear();
    steps.clear();
  }
  
  void output(
    const class namespacet &ns,
    std::ostream &out) const;
};

void show_goto_trace_gui(
  std::ostream &out,
  const namespacet &ns,
  const goto_tracet &goto_trace);

void show_goto_trace(
  std::ostream &out,
  const namespacet &ns,
  const goto_tracet &goto_trace);

void show_goto_trace(
  std::ostream &out,
  const namespacet &ns,
  const pretty_namest &pretty_names,
  const goto_tracet &goto_trace);
  
void counterexample_value(
  std::ostream &out,
  const namespacet &ns,
  const irep_idt &identifier,
  const exprt &value,
  const pretty_namest &pretty_names);

#endif

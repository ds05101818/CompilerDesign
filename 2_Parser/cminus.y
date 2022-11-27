/****************************************************/
/* File: tiny.y                                     */
/* The TINY Yacc/Bison specification file           */
/* Compiler Construction: Principles and Practice   */
/* Kenneth C. Louden                                */
/****************************************************/
%{
#define YYPARSER /* distinguishes Yacc output from other code files */

#include "globals.h"
#include "util.h"
#include "scan.h"
#include "parse.h"

#define YYSTYPE TreeNode *
static char * savedName; /* for use in assignments */
static int savedNum;
static int savedLineNo;  /* ditto */
static TreeNode * savedTree; /* stores syntax tree for later return */
static int yylex(void); // added 11/2/11 to ensure no conflict with lex

%}

%token IF WHILE RETURN INT VOID 
%token ID NUM 
%token ASSIGN EQ NE LT LE GT GE PLUS MINUS TIMES OVER LPAREN LBRACE RBRACE LCURLY RCURLY SEMI COMMA
%token ERROR 

%precedence RPAREN
%precedence ELSE

%% /* Grammar for TINY */

program     : dec_list
                 { savedTree = $1;} 
            ;
dec_list    : dec_list dec
                 { YYSTYPE t = $1;
                   if (t != NULL)
                   { while (t->sibling != NULL)
                        t = t->sibling;
                     t->sibling = $2;
                     $$ = $1; }
                     else $$ = $2;
                 }
            | dec  { $$ = $1; }
            ;
dec	    : var_dec
		{ $$ = $1; }
	    | func_dec
		{ $$ = $1; }
	    ;
savename    : ID
	    	{ 
		  $$ = newExpNode(VarK);
		  $$->attr.name = copyString(tokenString);
		  $$->lineno = lineno;
		}
	    ;
savenum	    : NUM
	    	{ 
		  $$ = newExpNode(ConstK);
		  $$->attr.val = atoi(tokenString);
		  $$->lineno = lineno;
		}
	    ;
var_dec	    : type_spec savename SEMI
	    	{
		  $$ = newDecNode(VarDecK);
		  $$->type = $1->type;
		  $$->lineno = savedLineNo;
		  $$->attr.name = $2->attr.name;
		}
	    | type_spec savename LBRACE savenum RBRACE SEMI
		{
		  $$ = newDecNode(VarArrDecK);
		  $$->type = $1->type;
		  $$->lineno = savedLineNo;
		  $$->attr.name = $2->attr.name;
		  $$->child[0] = $4;
		}
	    ;
type_spec   : INT
	    	{
		  $$ = newExpNode(VarK);
		  $$->type = Integer;
		}
	    | VOID
		{
		  $$ = newExpNode(VarK);
		  $$->type = Void;
		}
	    ;
func_dec    : type_spec savename LPAREN params RPAREN comp_stmt
	    	{
		  $$ = newDecNode(FuncK);
		  $$->child[0] = $4;
		  $$->child[1] = $6;
		  $$->lineno = $2->lineno;
		  $$->attr.name = $2->attr.name;
		  $$->type = $1->type;
		}
	    ;
params	    : param_list
	   	{ $$ = $1; }
	    | VOID
		{
		  $$ = newDecNode(VoidParamK);
		  $$->type = Void;
		}
	    ;
param_list  : param_list COMMA param
	   	 { YYSTYPE t = $1;
                   if (t != NULL){
                     while (t->sibling != NULL)
                        t = t->sibling;
                     t->sibling = $3;
                     $$ = $1; }
                     else $$ = $3;
                 }
	    | param
		{ $$ = $1; }
	    ;
param	    : type_spec savename
	  	{
		  $$ = newDecNode(ParamK);
		  $$->attr.name = $2->attr.name;
		  $$->type = $1->type;
		} 
	    | type_spec savename LBRACE RBRACE
		{
		  $$ = newDecNode(ParamArrK);
		  $$->attr.name = $2->attr.name;
		  $$->type = $1->type;
		}
	    ;
comp_stmt   : LCURLY local_dec stmt_list RCURLY
	    	{
		  $$ = newStmtNode(CompK);
		  $$->child[0] = $2;
		  $$->child[1] = $3;
		}
	    ;
local_dec   : local_dec var_dec
	    	{ YYSTYPE t = $1;
                   if (t != NULL)
                   { while (t->sibling != NULL)
                        t = t->sibling;
                     t->sibling = $2;
                     $$ = $1;
		   }
                     else $$ = $2;
                }
	    | { $$ = NULL; }
	    ;
stmt_list   : stmt_list stmt
	    	{ YYSTYPE t = $1;
                   if (t != NULL)
                   { while (t->sibling != NULL)
                        t = t->sibling;
                     t->sibling = $2;
                     $$ = $1; }
                     else $$ = $2;
                 }
	    | { $$ = NULL; }
	    ;
stmt        : exp_stmt { $$ = $1; }
            | comp_stmt { $$ = $1; }
            | select_stmt { $$ = $1; }
            | iter_stmt { $$ = $1; }
            | return_stmt { $$ = $1; }
            ;
exp_stmt    : exp SEMI
	    	{ $$ = $1; }
	    | SEMI
		{ $$ = NULL; }
	    ;
select_stmt : IF LPAREN exp RPAREN stmt
	    	{
		  $$ = newStmtNode(IfK);
		  $$->child[0] = $3;
		  $$->child[1] = $5;
		}
	    | IF LPAREN exp RPAREN stmt ELSE stmt
		{
		  $$ = newStmtNode(IfElK);
		  $$->child[0] = $3;
		  $$->child[1] = $5;
		  $$->child[2] = $7;
		}
	    ;
iter_stmt   : WHILE LPAREN exp RPAREN stmt
	    	{
		  $$ = newStmtNode(WhileK);
		  $$->child[0] = $3;
		  $$->child[1] = $5;
		}
	    ;
return_stmt : RETURN SEMI
	    	{
		  $$ = newStmtNode(ReturnK);
		}
	    | RETURN exp SEMI
		{
		  $$ = newStmtNode(ReturnK);
		  $$->child[0] = $2;
		}
	    ;
exp	    : var ASSIGN exp
		{
		  $$ = newExpNode(AssignK);
		  $$->child[0] = $1;
		  $$->child[1] = $3;
		}
	    | simple_exp
		{ $$ = $1; }
	    ;
var	    : savename
		{
		  $$ = newExpNode(VarK);
		  $$->attr.name = $1->attr.name;
		}
	    | savename LBRACE exp RBRACE
		{
		  $$ = newExpNode(ArrIdK);
		  $$->child[0] = $3;
		  $$->attr.name = $1->attr.name;
		}
	    ;

simple_exp  : add_exp relop add_exp
	    	{
		  $$ = $2;
		  $$->child[0] = $1;
		  $$->child[1] = $3;
		}
	    | add_exp
		{ $$ = $1; }
	    ;
relop	    : LE
	  	{
		  $$ = newExpNode(OpK);
		  $$->attr.op = LE;
		}
	    | LT
		{
		  $$ = newExpNode(OpK);
		  $$->attr.op = LT;
		}
	    | GT
		{
		  $$ = newExpNode(OpK);
		  $$->attr.op = GT;
		}
	    | GE
		{
		  $$ = newExpNode(OpK);
		  $$->attr.op = GE;
		}
	    | EQ
		{
		  $$ = newExpNode(OpK);
		  $$->attr.op = EQ;
		}
	    | NE
		{
		  $$ = newExpNode(OpK);
		  $$->attr.op = NE;
		}
	    ;
add_exp	    : add_exp addop term
	    	{
		  $$ = $2;
		  $$->child[0] = $1;
		  $$->child[1] = $3;
		}
	    | term
		{ $$ = $1; }
	    ;
addop	    : PLUS
	  	{
		  $$ = newExpNode(OpK);
		  $$->attr.op = PLUS;
		}
	    | MINUS
		{
		  $$ = newExpNode(OpK);
		  $$->attr.op = MINUS;
		}
	    ;
term	    : term mulop factor
	 	{
		  $$ = $2;
		  $$->child[0] = $1;
		  $$->child[1] = $3;
		}
	    | factor
		{ $$ = $1; }
	    ;
mulop	    : TIMES
	  	{
		  $$ = newExpNode(OpK);
		  $$->attr.op = TIMES;
		}
	    | OVER
		{
		  $$ = newExpNode(OpK);
		  $$->attr.op = OVER;
		}
	    ;
factor	    : LPAREN exp RPAREN
	   	{ $$ = $2; }
	    | var
		{ $$ = $1; }
	    | call
		{ $$ = $1; }
	    | savenum
		{ 
		  $$ = newExpNode(ConstK);
		  $$->attr.val = $1->attr.val;
		}
	    ;

call	    : savename LPAREN args RPAREN
		{
		  $$ = newExpNode(CallK);
		  $$->child[0] = $3;
		  $$->attr.name = $1->attr.name;
		} 
	    ;
args	    : arg_list
	 	{ $$ = $1; }
	    | { $$ = NULL; }
	    ;
arg_list    : arg_list COMMA exp
	    	{ YYSTYPE t = $1;
                   if (t != NULL)
                   { while (t->sibling != NULL)
                        t = t->sibling;
                     t->sibling = $3;
                     $$ = $1; }
                     else $$ = $3;
                 }
	    | exp
		{  $$ = $1; }
	    ;

%%

int yyerror(char * message)
{ fprintf(listing,"Syntax error at line %d: %s\n",lineno,message);
  fprintf(listing,"Current token: ");
  printToken(yychar,tokenString);
  Error = TRUE;
  return 0;
}

/* yylex calls getToken to make Yacc/Bison output
 * compatible with ealier versions of the TINY scanner
 */
static int yylex(void)
{ return getToken(); }

TreeNode * parse(void)
{ 
  yyparse();
  return savedTree;
}



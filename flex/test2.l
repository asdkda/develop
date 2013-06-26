
%{
int num_lines = 0, num_chars = 0;
%}

%option outfile="test2.c"
%option header-file="test2.h"
%option noyywrap
%option nounput
%option noinput

%%
\n      ++num_lines; ++num_chars;
.       ++num_chars;

%%


int main()
{
	yylex();
	printf( "# of lines = %d, # of chars = %d\n", num_lines, num_chars );
	return 0;
}

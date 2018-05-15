linter-cspm
===========

This linter plugin for [Atom's](https://atom.io/) [Linter](https://github.com/AtomLinter/Linter) typechecks CSPM files
using [FDR4's](https://www.cs.ox.ac.uk/projects/fdr/) typechecker.

See also [language-cspm](https://atom.io/packages/language-cspm) which adds syntax highlighting support for CSPM files
to Atom.

Working with include files
--------------------------

If you have a large CSPM project, and have split your file up into multiple files, you can indicate the root file
using a special comment. For example, suppose you have a file ``inc.csp`` that is included by ``main.csp`` and, when
editing ``inc.csp``, you would like the typechecker to typecheck the root file, ``main.csp`` instead. This can be
accomplished by including a line ``-- root: main.csp`` as the very first line of ``inc.csp``.

In general, if a CSPM file includes a line of the form ``-- root: relative_path_to_a_file`` then the typechecker will
instead be invoked on the specified file. Note that the file path is relative to the current file.

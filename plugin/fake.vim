" ============================================================================
" Fake - Random dummy/filler text generator
"
" License: So-called MIT/X license {{{
" Permission is hereby granted, free of charge, to any person obtaining
" a copy of this software and associated documentation files (the
" "Software"), to deal in the Software without restriction, including
" without limitation the rights to use, copy, modify, merge, publish,
" distribute, sublicense, and/or sell copies of the Software, and to
" permit persons to whom the Software is furnished to do so, subject to
" the following conditions:
"
" The above copyright notice and this permission notice shall be included
" in all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
" OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
" MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
" IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
" CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
" TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
" SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
" ============================================================================

if exists('g:loaded_fake')
    finish
endif

let s:save_cpo = &cpo
set cpo&vim


if !exists('g:fake_bootstrap')
    let g:fake_bootstrap = 0
endif

if !exists('g:fake_src_paths')
    let g:fake_src_paths = []
endif

let builtin_src = fnamemodify(expand('<sfile>'), ':p:h:h') . '/src'
let builtin_src = substitute(builtin_src, '\\', '/', 'g')
let g:fake_src_paths = add(g:fake_src_paths, builtin_src)


augroup AutoCmdFake
    autocmd!
augroup END

autocmd! AutoCmdFake BufHidden * call fake#free_cache()


function! s:FakeSubstitute(...) range
    let firstline = get(a:000, 0)
    let lastline = get(a:000, 1)
    let pat1 = '\vFAKE__([[:alnum:]_-]+)'
    let pat2 = '\vFAKE__([[:alnum:]_-]+(\/[[:alnum:]_-]+)+)'
    let sub = '\=fake#has_keyname(submatch(1))?fake#gen(submatch(1)):submatch(0)'

    execute printf(':%s,%ss/%s/%s/ge', firstline, lastline, pat1, sub)
    execute printf(':%s,%ss/%s/%s/ge', firstline, lastline, pat2, sub)
endfunction

command! -range=% FakeSubstitute :call <SID>FakeSubstitute(<line1>, <line2>)


let &cpo = s:save_cpo
let g:loaded_fake = 1

unlet s:save_cpo

" vim: ft=vim fenc=utf-8 ff=unix foldmethod=marker:

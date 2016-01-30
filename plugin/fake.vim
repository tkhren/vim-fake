" ============================================================================
" Fake - Random dummy/filler text generator
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
    let pat = 'FAKE__\([[:alnum:]\/_-]\{-}\)__'
    let sub = '\=fake#has_keyname(submatch(1))?fake#gen(submatch(1)):submatch(0)'

    silent execute printf(':%s,%ss/%s/%s/ge', firstline, lastline, pat, sub)
endfunction

command! -range=% FakeSubstitute :call <SID>FakeSubstitute(<line1>, <line2>)


let &cpo = s:save_cpo
let g:loaded_fake = 1

unlet s:save_cpo

" vim: ft=vim fenc=utf-8 ff=unix foldmethod=marker:

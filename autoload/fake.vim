" ===============================================================
" Fake - Random dummy/filler text generator
" ===============================================================
let s:save_cpo = &cpo
set cpo&vim

"" Initialize global vaiables
let g:fake_bootstrap = get(g:, 'fake_bootstrap', 0)
let g:fake_src_paths = get(g:, 'fake_src_paths', [])

"" Add the fallback directory
let srcpath_list = [fnamemodify(expand('<sfile>'), ':p:h:h:gs!\\!/!') . '/src']
let s:srcpath = join(extend(srcpath_list, g:fake_src_paths, 0), ',')

"" Caches
let s:fake_codes = {}
let s:fake_cache = {}
let s:fake_charset_cache = {}

"================================================================
" Utility functions
"================================================================
function! s:path_isfile(path) abort  "{{{1
    return filereadable(resolve(expand(a:path)))
endfunction
"}}}1

function! s:path_isdir(path) abort  "{{{1
    return isdirectory(resolve(expand(a:path)))
endfunction
"}}}1

function! s:charset(pattern) abort  "{{{1
    if has_key(s:fake_charset_cache, a:pattern)
        return s:fake_charset_cache[a:pattern]
    endif

    let uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    let lowercase = 'abcdefghijklmnopqrstuvwxyz'
    let letters   = uppercase . lowercase
    let digits    = '0123456789'
    let hexdigits = '0123456789ABCDEF'
    let octdigits = '01234567'
    let keywords  = uppercase . lowercase . digits . '_'

    let cs = a:pattern
    let cs = substitute(cs, '\\w', keywords , 'g')
    let cs = substitute(cs, '\\u', uppercase, 'g')
    let cs = substitute(cs, '\\l', lowercase, 'g')
    let cs = substitute(cs, '\\d', digits,    'g')
    let cs = substitute(cs, '\\x', hexdigits, 'g')
    let cs = substitute(cs, '\\o', octdigits, 'g')

    let s:fake_charset_cache[a:pattern] = cs
    return cs
endfunction
"}}}1

"================================================================
" Pseudo-Random Generator
"================================================================

let s:Random = {}

function! s:Random.initialize(seed) abort  "{{{1
    let int_max = 0x7fffffffffffffff   " for 32 and 64bit systems
    let self.RAND_MAX = int_max
    let self._HEX_MAX = printf('%x', int_max)
    let self._MASK_WIDTH = len(self._HEX_MAX)
    let self._r = a:seed
    let self._buffer = ''
endfunction
"}}}1

function! s:Random.randombits() abort  "{{{1
    if len(self._buffer) < self._MASK_WIDTH
        let self._buffer = tolower(sha256(self._r))
    endif

    let hash = self._buffer[:self._MASK_WIDTH - 1]
    let self._buffer = self._buffer[self._MASK_WIDTH:]

    if hash > self._HEX_MAX
        let hash = tr(hash[0], '89abcdef', '01234567') . hash[1:]
    endif

    let self._r = str2nr(hash, 16)

    return self._r
endfunction
"}}}1

call s:Random.initialize(reltime()[1])

"================================================================
" General
"================================================================
function! fake#int(...) abort  "{{{1
    "" Return a random integer
    "" int()       range [0, MAX_INT]
    "" int(a)      range [0, a]
    "" int(a,b)    range [a, b]

    let r = s:Random.randombits()
    if a:0 >= 2
        let a = float2nr(a:000[0])
        let b = float2nr(a:000[1])
    elseif a:0 == 1
        let a = 0
        let b = float2nr(a:000[0])
    else
        return r
    endif

    let [a,b] = (a > b) ? [b,a] : [a,b]
    return (r % (b - a + 1) + a)
endfunction
"}}}1

function! fake#float(...) abort  "{{{1
    "" Return a random float
    "" float()      range [0.0, 1.0]
    "" float(a)     range [0, a] 
    "" float(a,b)   range [a, b] 
    if a:0 >= 2
        let a = get(a:000, 0) * 1.0
        let b = get(a:000, 1) * 1.0
    elseif a:0 == 1
        let a = 0.0
        let b = get(a:000[0], 0) * 1.0
    else
        let a = 0.0
        let b = 1.0
    endif
    
    let r = s:Random.randombits()
    let [a,b] = (a > b) ? [b,a] : [a,b]
    return ((1.0 * r / s:Random.RAND_MAX) * (b - a) + a)
endfunction
"}}}1

function! fake#chars(length, ...) abort  "{{{1
    let pattern = get(a:000, 0, '\u\l\d')
    let chars = s:charset(pattern)
    let mx = strlen(chars) - 1
    let pw = []
    for i in range(a:length)
        call add(pw, strpart(chars, fake#int(0, mx), 1))
    endfor
    return join(pw, '')
endfunction
"}}}1

function! fake#choice(list) abort  "{{{1
    return get(a:list, fake#int(0, len(a:list)-1), '')
endfunction
"}}}1

function! fake#get(list, rate) abort  "{{{1
    "" `rate` that must be in [0.0, 1.0] is a relative position
    "" against the whole list.
    ""
    "" If rate=0.0, return the first element of the list.
    "" If rate=0.5, return an element at `len(list)/2`.
    "" If rate=1.0, return the last element of the list.

    let idx = float2nr(floor(len(a:list) * a:rate))
    return get(a:list, idx)
endfunction
"}}}1

function! fake#load(dictname) abort  "{{{1
    if has_key(s:fake_cache, a:dictname)
        return s:fake_cache[a:dictname]
    endif

    let found = split(globpath(s:srcpath, a:dictname))

    if empty(found)
        echohl ErrorMsg
        echo printf('The `%s` was not defined or found in g:fake_src_paths.',
                    \ a:dictname)
        echohl None
        return []
    endif

    if s:path_isfile(found[0])
        let lines = readfile(found[0])
        let s:fake_cache[a:dictname] = lines
        return s:fake_cache[a:dictname]
    else
        echohl ErrorMsg
        echo printf('`%s` is a directory. `%s` must be a valid file.',
                    \ found[0],
                    \ a:dictname)
        echohl None
        return []
    endif
endfunction
"}}}1

function! fake#define(keyname, code) abort  "{{{1
    let s:fake_codes[a:keyname] = a:code
endfunction
"}}}1

function! fake#has_keyname(keyname) abort  "{{{1
    if has_key(s:fake_codes, a:keyname) || has_key(s:fake_cache, a:keyname)
        return 1
    endif

    let found = split(globpath(s:srcpath, a:keyname))

    if empty(found) || !s:path_isfile(found[0])
        return 0
    endif

    return 1
endfunction
"}}}1

function! fake#gen(keyname) abort  "{{{1
    if has_key(s:fake_codes, a:keyname)
        return eval(s:fake_codes[a:keyname])
    else
        return fake#choice(fake#load(a:keyname))
    endif
endfunction
"}}}1

function! fake#free_cache() abort  "{{{1
    " echomsg "Called free_cache()"
    let s:fake_cache = {}
    let s:fake_charset_cache = {}
endfunction
"}}}1

"================================================================
" Utility Functions
"================================================================
function! fake#gammapdf(a, b) abort  "{{{1
    if a:a <= 0.0 || a:b <= 0.0
        echomsg 'Error'
    endif

    if a:a > 1.0
        let nv = sqrt(2.0 * a:a - 1.0)
        let sv = 1.0 + log(4.5)
    
        while 1
            let u1 = fake#float()
            if u1 < 1.0e-6
                continue
            endif
            let u2 = 1.0 - fake#float()
            let v = log(u1/(1.0 - u1)) / nv
            let x = a:a * exp(v)
            let z = u1 * u1 * u2
            let r = a:a + (a:a + nv) * v - x - log(4)
            let w = r + sv - 4.5 * z
            if w >= 0.0 || r >= log(z)
                return x * a:b
            endif
        endwhile

    elseif a:a == 1.0
        let u1 = fake#float()
        while u1 <= 1.0e-6
            let u1 = fake#float()
        endwhile
        return -1.0 * log(u1) * a:b

    else
        let E = exp(1)
        while 1
            let u1 = fake#float()
            let v = (E + a:a) / E
            let p = v * u1
            let x = (p <= 1.0) ?
                        \ pow(p, (1.0/a:a)) :
                        \ (-1.0 * log((v - p)/a:a))

            let u2 = fake#float()
            if p > 1.0
                if u2 <= pow(x, (a:a - 1.0))
                    break
                endif
            elseif u2 <= exp(-1.0 * x)
                break
            endif
        endwhile
        return x * a:b
    endif
endfunction
" }}}1

function! fake#betapdf(a, b) abort "{{{1
    let x = fake#gammapdf(a:a, 1.0)
    return (x > 0.0) ? (x / (x + fake#gammapdf(a:b, 1.0))) : 0.0
endfunction
"}}}1

function! fake#capitalize(s)  "{{{1
    return toupper(strpart(a:s,0,1)) . tolower(strpart(a:s,1))
endfunction
"}}}1

function! fake#titlize(s)  "{{{1
    return substitute(a:s, '\v(\s)?(\w)(\w*)', '\1\U\2\L\3', 'g')
endfunction
"}}}1

"================================================================
" Basic Derivatives
"================================================================
if !empty(g:fake_bootstrap)
    "" Choice a random element from a list
    call fake#define('sex', 'fake#choice(["male", "female"])')

    "" Get a name of male or female
    call fake#define('name', 'fake#int(1) ? fake#gen("male_name")'
                                      \ . ' : fake#gen("female_name")')

    "" Get a full name
    call fake#define('fullname', 'fake#gen("name") . " " . fake#gen("surname")')

    "" Get an age weighted by generation distribution
    call fake#define('age', 'float2nr(floor(110 * fake#betapdf(1.0, 1.45)))')

    "" Get a country weighted by population distribution
    call fake#define('country', 'fake#get(fake#load("country"),'
                            \ . 'fake#betapdf(0.2, 4.0))')

    "" Get a domain (ordered by number of websites)
    call fake#define('gtld', 'fake#get(fake#load("gtld"),'
                            \ . 'fake#betapdf(0.2, 3.0))')

    call fake#define('email', 'tolower(substitute(printf("%s@%s.%s",'
                            \ . 'fake#gen("name"),'
                            \ . 'fake#gen("surname"),'
                            \ . 'fake#gen("gtld")), "\\s", "-", "g"))')

    "" Get a nonsense text like Lorem ipsum
    call fake#define('_nonsense', 'fake#int(99) ? fake#gen("nonsense") : (fake#chars(fake#int(1,4),"\\d"))')

    call fake#define('sentense', 'fake#capitalize('
                            \ . 'join(map(range(fake#int(3,15)),"fake#gen(\"_nonsense\")"))'
                            \ . ' . fake#chars(1,"..............!?"))')

    call fake#define('paragraph', 'join(map(range(fake#int(3,10)),"fake#gen(\"sentense\")"))')

    "" Alias
    call fake#define('lipsum', 'fake#gen("paragraph")')

    "" Overwrite the existing keyname
    " call fake#define('lipsum', 'join(map(range(fake#int(3,15)),"fake#gen(\"word\")"))')
endif


let &cpo = s:save_cpo
unlet s:save_cpo

" vim: ft=vim fenc=utf-8 ff=unix foldmethod=marker:

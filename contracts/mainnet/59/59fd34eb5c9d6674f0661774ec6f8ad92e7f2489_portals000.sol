// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pattern Portals
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//    Jaiye The Artist                                                                                                                                                                //
//    Dawn Jaiye Studios                                                                                                                                                              //
//                                                                                                                                                                                    //
//    $$$$$$$$$$$B88#[email protected]$$$$$$%[email protected]$$$$$$$$$$$$$$$$$$$$$$$-  '[email protected]%@$b.,#$$%%[email protected]$$$w  [email protected]$I  Q$%  '[email protected]$                           //
//    $$$$%$$$$0        [email protected]'  ]$p>#$$/  J$$$%kJ([}[email protected]}'  ?B$$a  |@$$$o'u$$$*[email protected]$I  O0  .db   a$$$+  w$j       '8$b  IB$I  Q$#  '&$$L        [email protected]$$; .#$                           //
//    $$$p f$$$u    a$W   #$$$`  [email protected];  U$$_  [email protected], .o$p  IBa   M#' .B8.  !$z  -$$n  |$z  [email protected]$$$${  :@[email protected]$$$$#)'   x$$$%` .#$                                                           //
//    $$$p  X$$w   %$W^ `$$$p  ^&$$$MI     `Y$$$c  ^%@i  ]$$$0   W$M. `@$$_  x$$$$$$$z  [email protected]  "@b. ,$$a)]a$w  ~$$Z       U$$$Bl  ,8$$$MpLQb%$$$M,  <%$$$$$$$                           //
//    $$$a  /$$%^ l$$W^ `$$$$r   O$$$$$Mb*$$$$B_   b&:  @[email protected] .a$$}'<#$x  }$$$$$$$$$$$$*`  j$$/   ~w#ox   I$$BI  )$#.  h                                                               //
//    $$$*  .h$$$%zw$8; ^$$$$$$a   q$$$$h^     _W$$0 +%$$$z   [email protected][email protected]$$$m   L$-  .'..'''^{B$$$~  [email protected]~  '#[email protected]_  :@$M' `[email protected]$                           //
//    $$$$J   ^W$f [email protected]! "[email protected]@$X  :B$$$i  "[email protected]$$$$$$$$$$$0   iI^       .>[email protected]$$$$$$$$$$$$$$8UvZ*&8%@$$$$$$$$%l...'...   [email protected]' 'M$m  ;$$$8m8$$$^  d$B:  [email protected]%$                           //
//    $$$$$${   z$$$$$d!r$$r  f$$" 'W$$$i  q$$o. {$$$$$$$k'               <@$M  ($$$M%$$h         Y$$$$$$$$$$$$$$$$&   h$d  `%${  |$$o   W$$?  U$$_  Lt  `B                           //
//    $$$$$$$b.  ;*[email protected]$$: .M$$$i  m$$z  [email protected][email protected]|"[email protected]$$$0  _$$t 'W$b  i*bw[  )[email protected]+-~{p$B}:d$$8   k$O  ^B$:  O$$#   o$$)  [email protected]$$Mo$$                           //
//    $$#[email protected][email protected]   /[email protected]+  IB$$$l  b$$r  +$$L  L$$$d_~-[jJJx|||(ja$$$t  f$$~ .k$%1;Q$$8'  0$]      '&k  ;$$#   o$%' u$$/ ($$$&   b$$n  /$$#. '8t.;*                           //
//    $$b.   [email protected]$$8v."@$$}  d$$$f  IB$$$$!  d$$f  _$$t  t$$${              [email protected]$f  f$$[  {$$$$$$$~  ~$%;  *@[email protected]$$*   %$k   &[email protected]'  [email protected]$$$O|#$t  b                           //
//    $$$$W,   ?B$$$$$$$$$$$$8I  `&$$$$$-  Y$$t  _$$L  [email protected]@$$$$$^ ^W$Y  }$$%"  .0BB%t   [email protected]$W^    [email protected]$o  .B$p   _~!!+]z8$$$$$$$u     q$$$8I .#$$$$$$                           //
//    $$$$$$&>   [email protected]$$$$$$8b[    [B$$BW$$$MM$$$|  -$$8`  [email protected]$$$$$, '#$a   Q$$$z'       :p$$$B_      [email protected]  ^$$$j         "b$k^ }M$$#)   d$u   ]$$%zr8$                           //
//    $$$oL%$$a"   a$$$$?    ;[email protected]$$8}  w$$$$$$n  .d$$$&`  >k$$$m,   [email protected]$$$I  o$$b'  +&[email protected]:  Ma  '@$$$$$$$$$$$$$$$hl   la$$BZoo`  ^*$$q'  U$                           //
//    [email protected], ^@$$$<  J$$$$8OZ*$$$$$(   ?$$$$B|.  `a$$$$$8[   "0$$$h;  l%$$i  p$$$8_   /$$$$$$$$$$$$_^{%$$$$l 'Ba  .kB$$$$$$$$$$$$$$$$%(   "Y$$}   r$$d:  .O$$                           //
//    $$$$B$$$a`  ,%[email protected]/:.   ^*$$$%_   "[email protected]$$$Ud$$$Bz   '[email protected]_  [$$>  Q$$$$$o^   <8$$$t .U$$~  `&$$$: ][email protected]          ...."q$$$$$$BY   ..  "#$%I   vB$$$                           //
//    $$$$$$#,   YaI/[email protected]       `[email protected]$$$a'   :#$$$$$k.  >W$$$Y   n$$*   p$}  Q$z !><' '_)*[email protected]  }$$"  q$$p;    [8ha$$                                                                  //
//    $$$c  +$$$W1O$$M' "$$$$$}  n$$$$$$8j^   ;[email protected],  ;no$$$$$%.  o$c  ]$M. .8$[  )$< ]$L  ^@$v  I$B.  O$$[.#$B(.              Y$$$$[  /$$+  C$$$$Bq>   r$$$                           //
//    $$$1  u$$$C  0$%;  /@[email protected]@$$$$$8,    r&$$$$B{     /$$$$`  h$l  v$$kx#$$?  |$$$$$B.  m$f  ~$W   h$$)`&$$$$$$$$$$$$$$$$$$$$$$$>  n$$)  c$$Mna$$a   I8$                           //
//    $$$[  X$$$L  i$$8"   }%@$$$$$$$$<  ]$$$$$$$$$$$$W!.'&$$d   Wa  .&$$$$$$$f  +$` .a$;  [email protected]  C$M  I$$$t>@$$%oZccYOooM*wntJ&[email protected]`  C$$+  J$;  `[email protected]  Z$                           //
//    $$$]  Y$$$O  :$$$$hI    ^|)W$$$k   W$$L)B$$d{[email protected]*$$$%;  [email protected]$$$$M. `a$B$$$l  C${ ;%$W l%$$$$$$$0                [email protected]`  L$$]  w$$t{&@Y   ^C$$                           //
//    $$$f  b$$$)  /[email protected]%$$$$m  '@$u  )$a   &@i  z$w.  +$$$$B$$$M.iB$$$X   z$$$$o<(@$$$$$$$$$$$$$$$$$$%h#%B%Mbkpp*%@M%$$$$B.  [email protected]$$$$$Bx.  'O$$$$                           //
//    $$$q p$$$L   *$$z^f$$$$$$$$a,"-(  ,$$/  ?$W   b$%[email protected]$c .0$$$|  b$$- '[email protected]'  `f%$$$$$$$$$$$$$$$h[-]1/[email protected]|`  "%$$8J#$$$L'  ,p$b!Ik$                           //
//    $$$#/$$$h.  d$$$U   `>u%$$$$M/    [$$x  >$$;  C$$$%@$$$$$$B,  u$$$!  d$l  [email protected]'   :Z$$$$$:  )$$$a          [email protected] [email protected]$$$#I   .CB$$,  n$&"  .d$8!   w$                           //
//    $$$$$$$w   Q$$$$$W_.     "*@$$$$Mp$$$<  r$$i  Y$$k  q$$$$w   /$$$$l  k$$%@$$$$8<    )B$$%:  }$$&   k$$$$$$$$$w*$$$Z  [email protected]"  +%$$$$d  ,%$Z  [email protected]|   +$$$                           //
//    $$$$$$C   U$$$$$$$$$$$h-.  .0$$$$$$$a' .&$B'  Z$$p  <$$$r  .O$$$$$l  h$$d<`;tpB$$w;   [email protected]$#'  [email protected]`  m$$$$$$$$$B$$$$w  +$$$$$$$$$$$p  :%[email protected]   ,*$$$$                           //
//    $$$$$(  .b$$$$m.  :z%$$$$L   >B$$$*_   v$$p  .8$$w  `@$o            .*$M`     '@$$$#;  /$$n  [email protected]%   d$$f  q$*' i$$$h  i$$$a1'  J$$p  :%$$$$-  ,b$$#O%$                           //
//    $$$$m  "8$$$$$I      !d$$$${  [email protected]>   _W$$$)  1$$$n  ?$$$*Y/}-__+<>>(a$$$$$$$BB$$$$$$W'  C$q  :%o   #$${  z$*' "$$$h  !$Y"     :$$Z  :Bm$$v  li  Q$$$%+    nB$                   //
//    $$$%   p$|  Q$~  L$$$]  `8$$B. /$X  [email protected](  `8$$%"  [email protected]%%%%[email protected]$$$$B. /$$W          ^%[email protected]" -$M.      :$$$r  ($M^ '$$$o.    L$$f  ]$$/     i$$0    "*$$$$                           //
//    [email protected]^  L$$$$$$U  o$$$$t  i$$$[ [email protected]$U   ;8$$$1             .w$$h  I%$b  ,#hu[[1fa$$$%;z$$$$$$#p#$$$$u  }$M^ [email protected]$$&, .[B$$$)  ($$|    >@$+  .n$$$$$$$                           //
//    $$$$L  "M$$$$$$$$$$$$$&^ .%$$z /$$$$J.  '[email protected]{}1fvJJYxfrb$$$%  :8$d  I$$$$$$$$$$$$$$$$$$$$$$$$$$$v  ]$8,  *$$$$$$$$$$$]  x$$1   ^&$&  ^8$%; [email protected]$$                           //
//    $$$$$n      .~a$$$$c [email protected]:  w$$k b$$$I  Z$$$*' _$$$c;l1(-;"' ."[email protected]$$&  ;8$w  i$$$m  <$$8_    ..`>][[[email protected]%$$$$$$$$&;   [email protected]$$?  v$$8i<8$$$p  ,B$*   %$$                          //
//    [email protected],^[[email protected]$%"  *[email protected]'  k$$$Z  ,$$B"        '   /$$k  I%$m  <$$$d  [email protected]@@@[email protected]@@@@[email protected]|   [$$$$$]  n$$$$o<{B$0  :@$M   #$$                           //
//    $BLw%$$$$$$$$$$$$$l  p%"  q$$$$$$$8   o$$$h   o$$$$$$$$$$$$n  +$$Y  >@$O  _$$$p  l$$$Q              tB$8~          :o$*Lo$$Y  O$$$-  .a$x  i$$8   p$$                           //
//    $m   ^/O8$$$$$$$$$8Jd$$0.  `rW$$$$a   M$$$$<  c$$$$$$$$$$$$n  _$${  1$$L  ]$$$d  I$$$M1[||{?]{1)1_`  n$&~   ';i<>]q$b,  [$$$8B$$&"  i8$$?  1$$B.  0$$                           //
//    $$Mf            z$$$$$$$BX    "m$$a. ?q` z$i  z$$$$] ^W$$$$n  +$$j        t$$$W   [email protected]#@$$$$$q. .#$$$$$$$$$$$$M;   [email protected]$$$$$$$n  [$$$$x  |$$W   h$$                           //
//    [email protected]&q_.   ,n&$$$$$$$$$$$%X.  <$$$$$%]"kU  .8$$$$)  ]$$$$z  i$$$b<     fB$$$$a.  m$$$$o   `l!".   w$$$$$B-^''.     (B$$$$<  v$$8%L  {$$%%$$$d  ^$$$                           //
//    $$$$$$$$$$$$$$$$$$$$/  '[email protected]$$$$$$$$$+  h$$f   w$$$$$L  ;@$$$U  ;[email protected]@$d.  ^h$$$%).    .`Q$C   [email protected]*' ...'^:f%$#I!%$<  Z$$$)   [email protected]+  |$$$                           //
//    [email protected]$$$$$$$$$$$$$B[.   B$$$                                                                                                                                                  //
//    $$c     `[vct/z&$$$$$$$d+            ^[email protected]<    }$$$$C  .b$$$! .o$$$l  k$$$$$$$8W%[email protected]$$$$k"I*$d`  `_w$$*/.  ]$^  Ua  'M$$$$$$$Q  I$h  +M$$$$! v$$$$$$$$$$$%[email protected]$     //
//    $$$$$$$$$%&&%@$$$$&   [email protected]*"  ]$$W^  k$$$C  |$$$$<  Y$$$$$$$$$$$$$$$$)  [email protected]'    ^[email protected][email protected]$$>  x$x  n$$$$$$$Y  l$$$$$t..Qw  ^B$$$8-.  ;%$                                      //
//    $$$$BB$$$$$$$$$$$$$$B$$$$$$M+   :@$$h. I$$$$q  .*$$$d.             '>m$$8,   ;M$$$Mi.      h$!  u$$$$$$&^  X$U  I$$$o.  ,8W  '#$$$}             ^O$$$                           //
//    $$$u      ."_YW$$$$$$$$o(     lp$$$$h. I$$$$$J.  "[email protected]$$Wv]<<~[zh$$$$$$$$&[   .CB$$$$8Zu|m$$O;-B$$$Bb+   }$$m   W$$r `U$$$)  .p$$$X'   .^";>r8$$Y  O                              //
//    $$$$b1;        ~%$$$$O.   `)p$$$$$$$M^  a$$$$$BC^   [email protected]&$$$$B('   .[Uo&B$$$$$$$$$%?     _M$$$$1  ^cB$$W' ($$U   [email protected]  (@[email protected](*a_-*                           //
//    $$$$$$$$$$$$B<  /$$$c   [email protected]$$$$$$$%&$$J  .O$$$$$$$%L;  '[email protected]  c$$W^  J$$$$$$on"        ,/8$$$B.  ;[email protected]`   [email protected]$$$8+   <#$$MI  -$$q   L$$$                           //
//    [email protected]`,+O&$$$$$v  i$$$+  [email protected][email protected]$&  J$$O   .:<-c8$$$$$8p}.^tB$$#[([email protected]$$$$$$$$$$8oOY{'    ]@$8   b$$$$$$o,,1B$M>  .d$$ml-k$$8?   [email protected]$%^  >@$w   U$$                           //
//    $$MI.    ?$$$j  -$$$}  r$$$c  U$8  >@$$$Q^     >@$$$$BB$$$$$$$$$$$$$$$$$$$B8#MW*o&B$$$$$$$$;  x$B   Z$$$$$$$$+  .a$q   b$v    [email protected]$B:  }@$$;  b$$W. `W$                           //
//    $$$$$$%  .%$$(  )$$$/  {$$$O  .%$q.  t&$$$$$$$$$$$$$p  z$$$$}.d$$$m`i8$$8'         ~B$BYh$$m   %B'     ~$$| '#U  '&$J   a$$Z:  `a$%;  j$$u  I$$$<  v$                           //
//    $$Mh$$&   a$$/  }$$$/  {$$$B'  p$$a!   .$$$1  t$$$$"  w$$$$8c`        "W$$$Q  `@$$d   8$$_  n$$$$$$$$$$$l  m$f  [$%   h$$$$$f  <$t  x$d  ;B$0  >[email protected]$/  ;@$I  v$$^  q$$*   M    //
//    $*  }'  .p$$$z  !$$$z  q$$$M   [email protected]&WMMWB$$$$$m  .B$$m  .B$$+  [email protected] ;a$$$$i  O$O  <@%.  h$$$$$v  :$c  )$%^ ^%$b  `$} ~$C  '@$?  /$$;  h$$8   o                           //
//    $Z    .Y$$$$Z   C$$$d .M$$$j  l$$$B^ '[email protected]$$$$$$$$$$$L  ^$$$0  '@$$}  ($$$${   ^[email protected]]  U$#  IB$^  p$$] 8Y  ^@z  {$%" '8$b  `$$$$$/  _$$Q .d$$$$$$$$%   o                           //
//    $c   }B$$$&l  `b$$$$M 'W$$$I  a$$$$)             'm$0  '@$$Q  `@$$z   XB$$$8].      Y$8' ,%$d~z$$*. J#  ]$Y  [$%, '8$b  `@) :%[  )[email protected],   W                           //
//    [email protected]*[email protected]}   (@[email protected]?  IB$$$$$$$kv}>I,"^,-d$$$Y  ;$$$w  .B$$$w^   }M$$$$o_    m$Bl  i%$$$$M   C$< *$O  i$%: [email protected]"x$J:_Bj  :ZOzncCM$$#.     <#$                           //
//    $$$$$$$x   !M$$$$$$$$$$$${  l%$$$$$$$p!+B$$$$$$$$$$$c  i$$$O  '@$$$$$h!   ;[email protected][email protected]_  ^z%$w^  )$$t:$$B' [$%; .&[email protected]?         x$h  !%$$$$$                           //
//    $$$$$L.  'k$$$$%-w$$$$$$l  ;%$$$$$$$$C ^8$$$$$$$$$$$[  }$$$C  ^$8" :o$$%f   'U$$$$$$$$$$$J        v$$$U<$$$v [email protected]<     .."J$$$$$$BW##W8&W%$$#  l$$k)a$                           //
//    $$$$(  'd$$$$%-  v$$$$M`  [email protected]$$$$O  ([email protected]`  "@$$$$w.  ,W$$$u  +$$/    [email protected]$$v.  i$$B%$$b^[email protected]$$$av/z%$$$$$$$$$$$$$$$$J"``'[email protected]$8dpa&88%8&Mhd%$#. I$8   h                           //
//    $$$$h<|@$$$W<   )$$$$o   f$$$$B>  ,W$$d'  '][email protected]'  'C$$$$8;  X$$$$Y'   )W$$%q%$m  I$)  I#[email protected]$$$$Y              a#. I$$f;(@                           //
//    $aO%$$$$$#~   ?%$$$$$/  1$$$$%,  [email protected]{  .U$$$$U   ^[email protected]$$$%|   /@dlIa$$p!   !*[email protected]    ;fmY]'      ^/W$$$$M.       /$$$$%[email protected]$#  l$$$$$$                           //
//    O  <$$$%?   ]&$$$$$$$,  w$$$$x  +$$$U  :B$$$$+  ,m$$$$W+   Io$$m. b$B$$8t  .b$$$$$$$$$$BX'        l+-+'   [$$$$w)]]]_  `@$$$$$$$$$$$$$Wwk$$M' ;$$$$$$                           //
//    $M*B$$w'  >%$$d;^U$$M  ^@$$$a   k$$o   m$$$$$&8$$$$$W;   iW$$$$$$$$}  m$$(  [$$a,..  .z$$$$BW*M%$$$$$$$&`  |$$$$$$$$a   Ma'              `8$8#%$$C;c$                           //
//    $$$$$Y   Z$$B,  [email protected]$$h  /$$$$C  i$$$U  +$$$$$$$$$$$Bl   }B$$$L  !$$$(  u$$r  +$$"  .'`t$$BqZB$$$$$$$u  x$&  :8$J  r$$a   M$X"''<]];!}fxJI  Y$$$$B;  '8                           //
//    $$$$o. .o$$h.  (@$$$o  d$$$$]  v$$$j  (#&Woo#M%$$$#;"{@[email protected]`  .Z$$$v  ($$u  i$$<  j$$%w,   [email protected]$$o>^  )$%,  >##fJ                                                             //
//    $$$h   *$$)  |$$$$$$$i{$$$$b   &$$$$$MpQYUZmO>  J$$$$J.   "q$$$$$$$L  ~$$z  ;$$f      ?#$$$O'  [email protected]&       ^d$$?  |$$h  'MX  Z-            lo$Q   [email protected]`                             //
//    $$$Y  <[email protected]`  k$$$$$$$B$$$$$q   %$$$$$$$BQW$$$+  w$$$-   [email protected]$$Wj_}t)t1  <$$n  i$$u   :[email protected][email protected]  .Z$$$8J~:?O8$$$(  `W$&`  c$$$$$;  [email protected]@$$$$$$$$$$v   [email protected]                           //
//    $$$t  t$$*   W$$Y 8$$c  z$$o   #$$" "&$+  L$$<  d$$B. ^[email protected]^         ?$$}  )$$$B%$$$$$$8"  :B$$B%$$$$$$$$W"  ,@$W^  [[email protected]$]  v$$%Q<     ,M$$p   i%$                           //
//    $$$)  x$$k   [email protected]< {$$n.^[email protected]`  q$$, 'M$}  v$$~  d$$o  ,8$$$$$$$$$$$%#%$$$?  [email protected]$$$$$$$$$${  |$$$Y   ]mkahL,   )[email protected]   |$b. '8$(  v$W         "8$$$_   q                           //
//    $$$]  Y$$d   8$M` ,$$$$$$$$B"  Z$$;  *$n  ($$<  d$$m  `t///xXULh$$$$x"1%$U            L$$8$#rtM$Ol        .(%$m   ^bk<  .0$$k )@$8  "W$$$" 'M$$$$0. )                           //
//    $$$]  J$$p   %$&"  ^'           h$$$$$$$$                                                                                                                                       //
//    $$$w 'B$$$-.q$$$*,      ,,^ljW$$$$#([email protected][email protected]$$$$$$$$$$$$%%%B%8&WW%[email protected]@[email protected]@[email protected]$$$$$$$$                           //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract portals000 is ERC721Creator {
    constructor() ERC721Creator("Pattern Portals", "portals000") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721Creator is Proxy {
    
    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xe4E4003afE3765Aca8149a82fc064C0b125B9e5a;
        Address.functionDelegateCall(
            0xe4E4003afE3765Aca8149a82fc064C0b125B9e5a,
            abi.encodeWithSignature("initialize(string,string)", name, symbol)
        );
    }
        
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
     function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }    

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}
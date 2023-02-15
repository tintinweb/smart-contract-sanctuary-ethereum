// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Touch Grass
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                     //
//                                                                                                                                                                                                     //
//                                                                                                                                                                                                     //
//                                                                                                                                                                                                     //
//                                                                                             ''                                                                                                      //
//                                                                                         .!////t/"                                                                                                   //
//                                                                                        ~|".....-t/.                                                                                                 //
//                                                                                       ]^         "|I                                                                                                //
//                                                                                     '              I_                                                                                               //
//                              I                               ^                       >              "_            .                                                        "+++++~~`                //
//                               )                              .:                      !I              .!          !                                                     .>}t|[_++++[|/?i             //
//                               ^1   .;;;^                     .?I_||?;  ";.            j^              .^         ~                                                   I([-.           ^?}<'          //
//                                )+ i  l}1/["               ',f//|1        )i.          `x.              +        ~            .                                     ;1I                   [I         //
//                                 r"       |/t'           '(/f//- t         +tI          tx               ~       c            ..                                  '/                        ).       //
//             ||///tt>            {x        .?t1        .|/t/t!   _?         .ft          x[              !      ;l             }                           +     _`                          `       //
//           ^""",}jffjj(l         .fj         ^t(      :ttt/}'     f"         `jj}        )x"        "     ?     Y               f              `l>I.       ,    {'                                   //
//                   Iljjj/<        [r?          >(    ]/t|fI       ;n||//,      {f)       .nx         {    )    .J               >(       (|nJJCCLLLQQQQrri}    !                                     //
//                      l-jj{.      .fn`          i(  ?tf/).      .^ t{ !-UU{     +jj^      (n)        /,   "^   |1       >        x?  .}uYYUJJJCU[??<'     t   i                                      //
//                        `[rrl      1jj   `       +[_tf/[       .}  "j"   1CUl    +rr:     'nn,  l    ~t    ) l^L{[<>;  -         Ix>1zXYYYU11`           _^  :'     l+___~>-]:                       //
//                          !jxi     'tni  [        /ff|}        n    /j    <JJ>    <rr"  '  jnn   ,   't!   f  `Q  `[tfi~         `nnzXXj|.  ^            C   [.i>uYYf|].                             //
//                            /x!     tfx   i      .jj/(        (!    ^jl    ^JL<    ixx"~   ,un~  f    //   -^ /Q     /vj,       ;ccxuj       -          "v ,[XYYur^                                  //
//                             fx:    ;jn{  x      {ttf        lv      fr     .JL,    >xr     uuu   +   //i  ^} 0c     c:fjj.    {ccunn!       Il.        u}YYYz/  <                      .''''        //
//                        .     fx.    rjx1 '{     tjft        c:      "j<     "CC+   r_x1    ]vu(  Y { -/t   j O]    )c  jjf.  fcv^ lnn   ;)czYYXccx.   vCYYX'   {.                   "vu:''''        //
//             "           .}'   nj    [rnvu.Y    ?f|?{       rc        rrI     _QX,|f  1x,   .uuu. ut  ,//:  jlO,   `c:   {jj"/vI    unt_X_I,  _| 'I:cjYJC+^j   ~;                 Ixv:.              //
//              .'"     .    >/  `x]   .rrxXUc[   jff ;"     :c!   '    )nI      x0(/ji  jr    xvufu!Y   t/|  fvO    nc   ` ?rr|`     ?vJ?  f   ./+  (UUYJY :l  "n                {u{:                 //
//                '!:+(-?t{>  ;X! Ix.   rjufXUX   ftI .}     uc!+_[_i  [rxf ~1{_1tQ0  )) 'x_   !vuuI n+  t/t. |ZZ   lc<   "  jrr.     |Xnr [>"   |/^nJJ].0j?t   v^              iv?^}                  //
//                 i++    ^-]  `Y- 1|   -xxu`UYn ^ft   j    ;c|,."!<-txu^]r-;l'  [uQ]  1v'in  "rvvu| lY  ///_ [mm   cc   )  +:|r/   '1 fuux  u   !/rJ|' '0;.n  |j          ^   }1. n                   //
//                l` .);    ;{  .U{ x.  .xjn)`UUY?tI   j    cc.  X  :jv1r-r]>   [n'XO"  /J"f-icvvvuv  Y` )/|/ _ww  ;cf  >^ I,  jr> :x  :uuu  t,  -//<   ]O ++!:c`         +  "vI  j;                   //
//             `""l!l:"t>    .<  'C|+1   xxcv ,YJrf    j   `zc  1I  ncc  1rx.  _n!  Qu   nC,nccn-vuu- zf,{/|t'+mm  vc" 'z `j"  `xx^z   "unu~ 'z )J/t{   JO j' Yu   '    'x  "x   }r                    //
//          .}((((|||||||/+'  >   ;C(x   |xnni YJjf    f"  tz? 'Q  xcc.x. !xr'In)   cL{   JCnvv .uccc'uU l//t]}wL  zz  z` v. n' -xp   'cvvvv  YjU'-t/   ZZ f ~c!  ..   'u^ '(   ;c                     //
//        i)|((((|(((((|)|//|` f   |Lc:  ixxuc uYtUY   /!  zc  C? /zz( 'z rxrxnn     0lu  cLCn.  cccc;'Y"^ttttvwJ {zj lJ |/   r! Zx   cc^unu> tc. `/t-  mZtf cc ' f   ,u} .?    c/                     //
//       `'  ;  .  `":1|||||/t1l^   QCt  .rxzz ~YtLL|  )? ;zz _L _zzz   <n`)jnn|     QUxYrXULn   vcvv| Y|.tt|tZqX zzI J!^c^    }cnx? uz? cvcv/;Y   //t fmQ1{<c{  ?.  ivu .{    uz.          '^'        //
//             l!)1!    ,I(////t|   ,0x   xxvu_.Y/QQLl 1) jzt Qc"XXz]   -nX"xu(x[   ,Xc?ULYXJc_:/xcccz zY ft|tUpc.zz 1C uu      qz{n}zz  jvuu> Y<  t//n/mct>vc. 'j  >cv^ x    -z|       l]|t{I;;"!     //
//                ^~x|].   +t/ttt?   xrx  xxxuv J|-QQQ )t zz!)L"zXXz    u^nzxu ~x+ ,Y'w{xUCf`LXx!Icczz`1Y ft/tjpz-zY Lriz+     XU{JnzX<  ivucj xz 't//1vwrtIcz  c' !cc{ v.   'XX'     ~//>;            //
//                   I}zjuJCCXx|//1  .vL: |xrcz Cf"L00j(t.zz.0Z|XXX}   {u 'vn-  ]xlY~ UYjXYY.JnX .czzc};X!fttffbXvzx|L^zz'    ^q" fuuX    vccz <Y_zr/t/0wvtfc{ ~v ,zzc <+    xXr    ,|)<               //
//                   >UJJJJCCCCCxt/|  tcO _xxzv:ux?!OO0/t<zU{OUXXXX   'v? rzuj   /xv `CYnuI[ztjZI zzccz YrftfftbUzY_QQIXv     Cd  <znt   +cccvi'YXz]tt/wqX/zc` C,.Xzz~ w    IXX^   it~                 //
//                  tUJJJCXJCCJL0jt/|  rm>;nxzu|[xx ZOOLtfXU00JYXYx   tc Izzzu?,{///tt/zcf.fY'(QZ XzczX Y0ffftf0LzJ)QncX1    'pt  YXxQ: "YzcncnXYY'^t//Ypzfzz tL vXzc }|    YXz   [)                   //
//     .!((|/t;.   zUJJL"  ~XXvt vx/t[ fmw'nncnX,nu /ZOZtzYLZZYYYY^  .zzcczv/|)(|//||/tt/tff'v_vwlzzcXX^XOftf/tvqXJ00IXX:   'uXzcccczXC.UU}vvzzXYY .tttjpcuzX.L{[XXzi q    +XX(cnx[_ucu}`.             //
//    ..    '.|t|:1UJr' vl  'YYY}`fO[/,j0w;nnnzz nu,.mZZJXJ0ZdUYYY  Ivzczn||(1|(||))(((/tt/t <:rmZnczXz]n0jfj|fjZUCOOfYY   |ccczcxXX>Jrjx|IvzzcX/X. tttfbczz{uL'YXXX iw   ^zcux`l(   'rccv/            //
//             '"tJY,   'c)  .XJU.t i~/(YwQnnrXX.fn| wmmmYCOOmUUY[ xXczx|(((|||(uc"cxnYC?(tt/?{jwwfcXXzu1Ojfj|jjmJOO0YYX  nzzzcv/UQ0.lOYrr/zzcvx:Yi ttffkzzY:QLzYXX_ Zn (xuvvx  f      ,zcXu.          //
//               [tt[    ,c1  lXC0ti n<fuwqnnrYc>tnu JmmZJOwOCUUX+zzcv/(((|I;jCCC>IJvcuLXzvnv|jUqqLcXXzY<0jfj/jjwCZZLYYx vzzzzj QOOt l0ZYrxzzncz Yt tfftqJXJfQUYYYY  p]nvcvjXI ).       'czXv          //
//               n  <)    (z_ .tUOf( `QjUqpunrXnfjuu,-wwOJZwZUJUYzzcr((/vY} tjOCC:YJYuu0XzczzzrxddQcYXXY"0jjj/jjw0ZZCYY]rzzzzv -ZZO^ jLZZuxzznXX Yu<(||nJ0YC00JYYYj ?CzuccuUU ._         .zzX_         //
//               .   lt.   zz" tfOxt  ULfbduunYuUxuvt.qwQLmmqJJYXzct/r~OJJ`1|fdLLcCJJncOX~XzzXXzzkwcYXYY.0rjrtrjOmmZJUY1zzzzXU OZZL `ULZmZxXcuxx1{xiunffuZJL0OUUYY"`vcvccnJUc }           >XXu         //
//                    `(   {Xz ffcct/ YzcXknuuUcCxcvc pq0OmmkJJXXvjvX0(LCCir,jkLLLCJJzrZv XYXzXXXQdCYzYX,0rjrtrrLqmmJUJYXzXXub'ZZQn zULOmmXcf11j{YC jjfjjZJOOOUUUY^Xzuzc[JJL< z            czc         //
//                     `~   XX>|fnYtX^xYcvbzuuUXJ(uuv,mqQmqmbCUXXzXXUZZLLCY/JrhQLLLCJUxZn'XXQXXXXzpZJzUX~OxjxtrrJdwmJJYXXXXXnXfZOCi:QU0xw0|((tQLv/U^jrjjjwLOZLUUU{XzvXvx{QZZ <>            ?X}         //
//                      i   zYU{fnntxO(Uuur0nuYUU?ruccCpQwpwpCXXXXzXZLQQLCz!QrhZQQQCCvumu{XXOXXXXXtmmzUX1OxrxtxrYbwmJLYXXXXzb_mZLC 0OJOixf|/C0JXU?Y<jrjrjwOZZJJUUXvXcXz.ZZZZ j              X          //
//                       ]  _YU(fnntfZ1Uucv00uYUU<xczzndQwpwZJYYXYXUmU0QQJcL0xhwQQQCCfUZuuXXQLXzYXzOmJYXxOxrxtxxXbwZCUXYXXYuh'mOLLi000QttjtO0JYUUlU)rxjrjwwmmJJJUzXnzz} ZZZx j              `          //
//                       ]  .UYnjnuttm0UuzurOcYUXlCzzzxkmqpq0YYUYYUZw0OO0UXOOua(000LCjLZuntXCOXXXzXjmZUYUQxrxtxxzkqO0YYYUYYxh~mQLL0ZLYxfxfbZUJYJJ^JuxnxxxmpmmCJCXXczcX.{ZZQ!i)                         //
//                       .?  YUujuuttq0YuLvnOOXUcimXvcXhpppp0UUUUUUwwZZOOUZZZzaCO0OLXnOmuutXJOXXXXXvmZCU0JxrxfxxXkp0QUUYUUYLazO00zmmcnnnrhkOJCzCJ^CUnuxnxZdwmCCYcXuXz) 0m0C |i                         //
//                        j  UUnjuuttw0XnmzcJOJJc<wccYUadbddLJJJJUCqwmmmZUqmZJokOOOQxzwquufzUOCXXYXz0mOUZvxxxrnnYhpZCUJUUJUbowOOOZwUvnvxpkkOLLXLC!CLuvnvu0bqmLQYXzXcX^ mZLL f'                         //
//                        {! UUxjuuttm0zuwccjOZCz-wuUJUddkdbJCCJCJmpmwwwwLpw0QmkZZZ0rYqqvvjnYOOXXXzXxmmJZnxnnnnuJhdmUJJJJJJaamZZOmCcvcvwdhkZLQYQC]LLccvcc0kpZ0CXUuYzc'"mQLJ`t                          //
//                        :/ zJrjvuttmQcuwcuzZmLX[wXJUUQbhbkCCLCCCddwwwwwmdpCqLbmmmOxUpdcvjjUZOXYXXXnmwLZnnunuuvQhbmJJJCJCYakmmmZ0zcXXOdqhhmQ0J0Q|QLzzczzQhdZZJYUXUYx`/ZLLx-t                          //
//                         j zJrjcxttwQvvqXvzQmOY)wOCYCCkhkdLCLCCQddwwqqqdbpUhakwmmQnJbdccrrUZOYYXUYXwmZQnnvrvucmakmCCCLCCzohmmmZXXYXXdppaaw0OCO0x0LXXXXX0adZOJJUJUUQ"Z0QL]tt                          //
//                         flUJrrcxfjpQccpCYXcmwJCqpLJLCdhkwLLLLLObdqqqqqkkbY*odwwwLc0kdzzxxYmOUYYJYYOwwzuucxcvcdakZLLLQLLYahwwmJUXYXbdqbaowOZQZZcOCYUYYYOakwQJCzJYCbIq0QQlt)                          //
//                         t}CJrncrjjb0ccpQJUzmpJLwqCQLLZahOQQQQQpbbppqpphhbU*opqwwQUqkdXznnzmOCUUJYUcdqccccvzczkoh0LQLQQL0opwqQUXJCkkdqaoowZZOmZYOCJJJUJmokqQCLUCJYa<ZOO0"f]                          //
//                         ?fLXxvzrrjkQzXbQCUCmpQQZpJQL0OaaQ0QQ0QkkbqpppphakJ#opqqqLLkhpXcnnXmOLJJJJJckOzczzzzzXooaLLQQQ0QdomqwJJCCChkddo**qmmZmmJZCCCCJJp*hp0QLLLCca1ZZOO>j_                          //
//                         lfCvnXzrrrpUXYkQCUC0dmQ0dQ0L00ao0O00OOhhbqpddphodL#oppppCLhhmYvuuJwOQJCJCCJkLXzXzXXXY**oQQQQQ00aomp0LJCChakdb*##wmwZwwLZCLLLCCk#aq00C0LQLaZmZZO{r>                          //
//                         ^fcuuXvxxuwXXLhLCUJUdp00dwOOO0po0OOOZOaakpddddkoZqModddpJOaaQUcvvQmO0CLCLCLdLYYUzYYYU***Q0000OOooppCJQQQ*abdh###wwwwwwQZQQQQQL*#ow0OJOQQdodwmmZrr!                          //
//                         .--?]}?--1/}}(r11}{}ff((ff(|(||x|||((|rrjtfffffx)rnjffff1trr1{[]](||(111())/){{{}{{{1xxx(((((((xxf/)1))/xrffxxxxt/t/tt|((((()(nnr/((1()(rrt///|?-,                          //
//                                                                                                                                                                                                     //
//                             IiiiiiiiiiiI     i>i>"      >I       .>"     .i>ii:     il       ii           ">iii`     iiiiiii;         i:        'iiiil      `iiii;                                  //
//                             O&&&&@@&&&&Q   )@@&&%$8^    $d       I$x   [email protected]@&&%@@^   $a       [email protected]         `&$%&&[email protected]   B$&&&&[email protected] [email protected]@       [email protected]&&[email protected]@;   [email protected]%&&8$$^                                //
//                                  $$       8$x^  '^@BI   $d       I$x   [email protected](^  '^@B'  $a       [email protected]        ,@@^.  `_$8   B$    .,@%      @[email protected]     x$x'   ^d,  [email protected]]'  .^W`                                //
//                                  $$      [email protected]>      '@@   $d       I$x  #$l      'i   $a       [email protected]        @$'      !i   B$      q$     #@.p$     *$          @@                                        //
//                                  $$      $#        <$v  $d       I$x  @*            $o,,,,,,,[email protected]       )@{            B$      &$    [email protected] '@a    ~$&01.      [email protected]#0-                                     //
//                                  $$     '@L         @p  @b       [email protected] '@L            [email protected][email protected]@@       [email protected]^     UUUY+  [email protected]    @W   j$+    it*@$$kz    [email protected]$$qz                                 //
//                                  $$      @&        {$j  $8       /$_  @8            $a       [email protected]       _$r     [email protected]  B$kkk*@&>    [email protected]@$         [email protected] [email protected]@                                //
//                                  $$      0$1      :$B   *@;      %@   [email protected]|      'u<  $a       [email protected]        M$i      l$/  B$    b$_   ,$*[email protected]  :       U$+ l       p$^                               //
//                                  $$       [email protected]^[email protected]&.    %@>I."[email protected]@j    [email protected]^ !>@Bl  $a       [email protected]         *$)i''i|@$/  B$     #$l  8$       [email protected]^ $$ii. `[email protected]@  [email protected]  ^>@@                                //
//                                  $$        ,&@@@$8Z       &[email protected]$$B&.      '&@@[email protected]    $h       [email protected]          r&[email protected]& $/  %$      %$.-$J        $8  &&@$$$B&    &[email protected]@@$B&                                 //
//                                  ^^          `^^^          .^^^`          `^^^      ^'       ^^            ^^^`  ^.  ^^      '^.'^         ^^    ^^^^`       ^^^^`                                  //
//                                                                                                                                                                                                     //
//                                                             jr             f00000Q   C}   z00000X.0   .0   )00[   0000"  0    0+ C0000[                                                             //
//                                                             Q0             ~{{@{{}   Wr   ?{{@{{?'$   .$  qZ|thZ  ${{t$! @#   $1 WQ{{{l                                                             //
//                                                             QkM0%+`@'  @'     $      Wr      $   '$   .$ f8    @- $   &X @CW. $1 Wr                                                                 //
//                                                             QM  [email protected] mm vd      $      Wr      $   '$wqww$ d0    aL $[[}B, @ O8'@1 Wommm                                                              //
//                                                             QO  `@  $'@.      $      %(      $   '$   .$ [email protected]   .$] [email protected]  $  wB$1 Wr                                                                 //
//                                                             [email protected]^^Bb  CBo       $   [^,$`      $   '$   .$  &%^^@o  $  [email protected]' $   [email protected] Wn^^^`                                                             //
//                                                             ~>}z:   [email protected]'       }   ;Lc^       }   .}   .}   ^|(^   }   +? }    ]; ][[[[+                                                             //
//                                                                    +h*                                                                                                                              //
//                                                                    I[.                                                                                                                              //
//                                                                                                                                                                                                     //
//                                                                                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract grass is ERC721Creator {
    constructor() ERC721Creator("Touch Grass", "grass") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x2d3fC875de7Fe7Da43AD0afa0E7023c9B91D06b1;
        (bool success, ) = 0x2d3fC875de7Fe7Da43AD0afa0E7023c9B91D06b1.delegatecall(abi.encodeWithSignature("initialize(string,string)", name, symbol));
        require(success, "Initialization failed");
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
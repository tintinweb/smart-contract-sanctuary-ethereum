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

pragma solidity ^0.8.0;

/// @title: Ripple
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                      //
//                                                                                                                                                                                                      //
//                                                                                                                                                                                                      //
//                                                                                            .'`""^`..                                                                                                 //
//                                                                                   ,+_?)z0ZZQQQOOOOZmwqQt[?i.                                                                                         //
//                                                                             ^>-fQ0QQQQCUYYYYzXzzvvvczzccLZZpq(+:                                                                                     //
//                                                                          ,{LbpdppppwLCUJUUYXYzzcccczvvuuvnnvrLZZ0{l.                                                                                 //
//                                                                        :jhddbbppppqwwmqUUUYUXcczcucuuuvxuuxnxvjnuZmQ|:                                                                               //
//                                                                      '{hbbkbdddpqqpqwwwmmmJXYzccvvvununuxxvxrxvxrxxcmZu<`                                                                            //
//                                                                     ^Lkdbddddqpdpqqwqwqmqmm0UXcvvuvunnnnunrvxxrurxnfjxYmQ]'                                                                          //
//                                                                      .`^^'lvmwpqqqwwqqwmwwmm0cuvvuuunnuxxrufvxxjxfjnjfnxUZm-.                                                                        //
//                                                                          IvQ}'IcmwqqwwqwwmmwZ0Ucuvunnxxnrufvfnrxrnjfunjttxz0mi                                                                       //
//                                                                             ^|Q_.cwqqwwqwwmmwmLcznuuuvrnnnufvtnfnjxxjjjnj(tnxOm,                                                                     //
//                                                                               .(Yi`CwwqwmwmZZZw0cnnvuuxnnnxxjvjnrxrfrxjfjxftxcnQL                                                                    //
//                                                                                 if/"f0wwZmmmZmmJnvunvxnxurxnujxrrxrrfrrrrtjrjxtrXQ|                                                                  //
//                                                                                  ,/x^XmmmmmmmmmUjunnnuxvjunxxrrnjxrjxxfxjrfjr/u/(/mn^                                                                //
//                                           ^](}}1/tjjf1;                           ~j/'ZmZZZmOZZYfxuzuvxuxxurxxurufurrxrjftn|jffvf|ft0r                                                               //
//                                       >[(t/|/////){l^                              |xl^qmmOOZZZLnxcuuruxnnnruuxnfrrjfrrffjxftxx|tv1rxvn;                             .^I!I.                          //
//                                 >}`"~)///////t}){:                                 }rv.UOZZOZZZCunucuvnxncnrxrxjxjjrnrrrjntu/x/ft/c{r)jX]                     .![}/nn/)||i'                          //
//             I+"               :[!`<)tttttttf1{1:                                   ^|x'[ZZOOOOQcxvzzunxcnxvnc/vvfrjrj/rxxfrju|jfr/)xf({)j/,               `_[|fjrt)1}{}i.                            //
//            .<|!              :1I;(rjjjfffjt1(I                                     .(f`.QZ0OOOCxnvcnuuuxnjnrxcxrnxnrfxjfffjrrr(nfxttntj))fx~           i]fffjjjf){{{}[:                              //
//                             "{;"{nnxxxrr/))_                                       ^)f` QOO00QYcvvvuxvnnjnnvnxjun//trtffxrffntu)utjtx|fx|)(f_      '-[jjrxrjf|){{11{}:                               //
//                            .~j <zvvuunxf||1[>+^              .`:l>~+<'             -/f'^QO0OOQnxuvvuvnnnnvcntjuufnnrjnjnnunxfntu(X(jfff(r()(j1,,<-jjrxxxnxr/)1{{{{{{l.                               //
//                :^          "(:,/XXzcvur//)((/||(rnnrrrxxnnrjtttffjrf/~             1/n.|00O0Lcvcvnnvvvxnvcnjvuurrvcxnfxnxrjucvu|x)n(rffr|t)/)/nnnnnuuuuunf()111{111],                                //
//          `>i`  [>          :v +mJUYXzuff|(|/||/xjjrjrjfjjjjjjr(rt]()+             :)/{.J00OOLccuvvvcnnuuvnxxvvnnvujxxvnjtrnrxnjftu/r/rj/f|t()11fcccvcccvf(((11))111i.                                //
//          lnj>              !0 ~mQCJUYnf()(|)(/rxxxxxxxrxrrjx{(]_i'                {/t,^Z00OQvvczcvvnnvnxxcnnncrnxcxfrjxfuvcxxxz|u(u(r/tt(f/))t()jcYYXYv|(1|((1))))(l                                 //
//           ..               !0 +dZ0QLUuvj(||1(tuuuuunnnnnx)}_^                    _(|}'r000QcvucuvcvvnnvvvncznrvuXvvuxnjnvcunfvfnfY1ctxf/ftt(t({((tcUz/)/f|((())(((/!                                 //
//                     .      :v -oqwZOYnf|||((|ucccccvvvuj)!.                     l{(/^:U00OUvzccvvvnnvcunuzcnjUnurnvvrnvcvtjvvru)X1v(vttt/f|(//)1(11ujttt/t(|/((((|/!                                 //
//                ^,'  +'     ,v<lJkdpqJvf||(|)/UYYYXXXXXn_`                      l{|(l.X000cvccczzzcccuvvzznvYuuznzcXncXvxxrrrxxfurjfujnjrjtftt/(t()1{/jjftt//t(//|/ti                                 //
//               .}zi  (^     "cU'1oahkQXr||||/tUCJJJUUUv~                       >)|(]`}L0OccuzXzzvXzzvzYvncUzcvYzXnXznnnXuxXUztuftz)c|cnrrrrf/)//t||)))fjrrrtjj/jt/tf>                                 //
//            .   ^l^  1>      !X;-hM##pLr/t|(//n0QQQLCX1I                     '+||(]^lU0OccJXXYXcvcYXzcvYUUUUUzzzvXcnvXuuYUXxvUvzvnruztfjrnfrrrfff(|/)((trnxrxrtxjjffi                                 //
//          !zf:       `x'     ;Q0 1*MM#mrff/|/ttZmZZOOX[-:                  '<|||(1,;XOmJYXYYUXzUYUzXzcXXuzUUvXYxuznYcnzUuuQLv/nvnYQurYvfjtUn||jft|(/))()1rnnunrnjjjr+.                                //
//          :/f;        Y>      <bj-d&WWppXrj||ftxwqwmwY[{[l.              "[)||/)<'>XO0CJJYvcXYXXXXCCUzXzUcnzXvvXzUYuczvr_^.                .'>f/trt)t)1)(/nnuunuxnnxtI                                //
//                      <z.     .?U>(W888dvnxt//rtXppwwU){1{]>`         .l)/tt/t|i.+UwJUUJXXCXXuzXYJYJUUUccUYLCYUQQzr^`.        `_cCLUYJYJC|,'     .^1})(1()truuvuxnurr<.                               //
//                  f(^  vc^     "fYix%888mvxnxtxrrcqpwmX11{{{{[]l.  .~)ttftjjf|i (00LJUCCYzJCLJJCJUJXcXUYLJQvQcC;"       IfxfUQxurJXczzXzcvxuzx|c[`   `,)}))(tuvvvuuxru!                               //
//            -n!   '`.  ,U+      "fZ]{bW&#UvzcuuvnnuXUO0v11{11{1[(|frrrjxrnnj-``tZLUJLJYCYCUYJQLLJCXJJUYLLOzt;'      >uvQXcCUxcJUUUvvzUrzuznzxnvzfrx|r"  ."~{1/rzzzcnxn/,                              //
//            <(:   `r|^  [Zf      ^xa)iZMWW0UJYXXzczzcvnunjjrfjxxxuxuvczYJnI' ?LQCLCJJCCCQLLCLJUYCJLQC0OL(i'      !zzJYJXJJUczcXXnYYUzczvucXuuczxcntzXfv/i  ."i|tuvcuunut"                             //
//                   tC;   fdU"      iUp|L#MMm0LLJCUUQLLCCJYYXYXzYYJJUJCU[I  iX0LQCJJCL0Q0CQQL0CQ0Q0OO0r_^      "YYCLUJLJUCUcUYXUuuc0cvvUnuczYzuvxnzuunYju|X[[   ^-xuvvvuu(`                            //
//             .-_.  "xn^   (OY`      ^_OwcjaWaQZ00QL0Zm00LC0Q000OZZOQ+i   ,fQQLLCL00QQ0O0QQQ0QCQ00ZX1:      .jzCJUCzUYXJUUcXXcvzYzXxcYYcXvuvunvzcvvzzcnzuxtvvn}-  'I1nnuvuf;                           //
//              (q]   {0L^  'nOC]        +zaC*L&kwqmmwwqwpqwqqdppZ{_.    "fLQLL0QLZZOZZOQ0Q0OmL0mQu!       <|0CUQUJXUYzYYzvzLUzJYYYccUvnccXYvzUXuvcvuuUjvUunnccXXj[i  ,i|rnun)'                         //
//               !;    xmw|  `tQOC_         _{ja*8&***ahkkahU|}i'      "rZLLQO0Q0mZL0mZ0wwwOmwOJ+"      '}COO0JJQJUJCJJJXYUUJzYCXcYUzUXcYuJcYJXcnccczzvzjuCucunuxcYYt-,  l<ffrn[!                       //
//               )Z}'   fQZ0} ^t000X~.            'I<~<l^           .|vZ0LZOO0ZmZO0mqOZwwdZdQr_       >tCLJQJUCYJLQCJLJJUUCUUUQCLYYL0LxJQJXcJUXUUYYvJfcvUfJzrccYvjxzYzv1<`  "~/tfr_"                    //
//         .;l   .xdj,   nmZ0p1'+0mZ0z/i.                        ;{nZCOQmOOZwm0OqqmpqdwZpmm1'      `+XZ00CLQCLQ0QCYJJCYQ00LJJ0YLUJJ0zLzC0XcYYUnCYvzzYXnCvOrXYrxvJXxrzJJYcY}:    +i1t/_>`                //
//                :XkL_'  vpbOZQ{/Jwwm0Q0f{I'              .^_1rm0mLZqOwmwpZOmpdwwbqwkdk|;       :/J00QLQQC0J00ZJJULJJ0JCczJZCOJOUmUvJY0J0L0CQYJUzXcJzzJzcJrJuvnnvXzuzJJJJUzc>'     `<~i?_l:'           //
//           .`    _OhoY?. (khoqpdZCwZmpZZmQOdv[}[[[[[}}}f0pwOO0wZmdpwpqwdwdwwdbppqbbXf^      .Ifw00LC0O0QZQ0JZJ0YLOQZLOL0ZmZwCUqLX0YwXJOCOCQCXJXXYvLcCCvYUvJvYznnvXcvnnXJLQJzux~.           .`.        //
//            ?x:   _Zka*W{^'Jo#odbbkdpqqqppqw0ZqqwOQ000mOZwZZqmqwdpdqbqpdbdbhbdpb0cl       '}LZmOOOOZOQmwOOZZLZOm00L0OQmZOwC0YCLbwmOOOCJQ0JU0XUvzUvcvYUXLuLnvJcccnrvXvxuXXYJCLCY/];                    //
//             _X['  ~ZMoWMkZ_l0ba#hbbppwwbmpkqObmpqwqmwqmwwwqdbmbbbqdppqaphohppC+        I1h0mZ0mmOOmmmQwOOLqpO0dOCQw0qdOUQbqQUk0XXhmmZUOmLQCJCQmOCUuCJzwnCYvQzurjt|trxjffxcUzujfjxf;.                 //
//              'tY<. .C#M8o8&#oqob*hhkkkbkbdhZ0wmbqqhqppqbdbbddqhp*pk*k*b#kdC)        .<hmdZZmwwmOOmZwqdOdqdLZwp0qhh00Z0mmOmd0pmObpOb0QmQZO0Q00QO00LLQ00pdkdpmQJYcvvzXvrf(tut[jUcxYYz/_"               //
//                ?OO-' Qo#8&#%&WW#*akahbdapphbbaZ*kbapokbobokohkobdMd#hakJ/         ;rpbqwwpZZZpwZOqbpZZbwdQ#m00kkqkCwLQmqbpkpZ#0LwLYXzunnxrjt|//tfjrrxnvccYXvuULJJYXcuuvvczcXL[_nftnvnx[".            //
//                  nb8[``k8&&8WW&M8W*oWoa##*bhooO#ba*b#ooakoa#oa#oao&ZQ^         '!mkqdqmbmmpddmwa#qqkkoQpbkChO#pqwdpomwhddmdkmUzvnt(|_.               '-/1|runccuczvvccvuunnxxuvunt,;1ftjj~'          //
//                    tqa#I"#WWM&W%&#W%&W#aobMMWMoMk*#dMoMooMbMak&bb_          ."U*kbqpbqhQhbZwwpMpq*bCwqopdO#kwxWUbQwOqb#bQJvr/1~.       '^"":;III;,""^.      ,1)/xncXrjvxrnnrxxnxnuuu(". ij|rl.       //
//                       hdb8_ZMM&8W8B&M#*#W8&#*##&&W8WWho#kMWoo_.           'j#ahhdkbdqdabd*Mp*aQohbaoqpqoZMZoZWZkmb8odLzvjt!      [email protected]%8%%BB%%Mdm#&1,.     >1)txuvUU?[Yxtrnnxnunu|;    ^j"     //
//                         'q#h*p+L%8W8%BBBB88%[email protected]@@@@[email protected]&oMJl.            .}Mbkhadda*ddhkbbko%pOb#mbOQoWbdqZWb8dohBoMOcnf?"     ^m%[email protected]&W#ooahhhhaahahaaodhaokOqY`     "}1)/fxnjcn";{cvjjxunxI         //
//                            '^>[email protected][email protected]@BB8&MW8a(^^`               >MaokobahhbhdWqk%L8q8d#k#kd*oMpahkZMh#ko8&#Zuj[`.   'v#B%o*o*##*ad0QOOOQJXXUCOppwppwwbwQ0OqQL/^     '.'-j/fxnxz|^'''':trxi      //
//                                  .^:;;;;;;;:,'                    (oo*aoaok#oka*bW#o#k%CaQoahb8ok#MapZa&q&%&WoYf(:'   'xMBMo*MM#ZYCJYzQZxi"","""",[UO0u)jJ0QQUJCZLC0YJ>          .`^^"![|f["   `'    //
//             .l;                                               :mpMao#*okM#*o#W%M8w*kpZ8o#o#&MkZohadkbM%W%%Wazt["   .}#%#a*M#Z0UzQ]::.   ',1LpbkkbdZr;`..;;:|Jj/nczYXUUJYz!                   ..      //
//               ;cCi                                       .iUqMM#&#%8&#8#o*oM#Mob#&ohb%a*b8WahoW*kb&*M%%%Wdnx:.   ip*#ao*hp0Uz<l. '}qCwW#qXffjnYLLc/)(fJwZzCL{^:I[v/tjnzcuvzx^                        //
//                 iphwc"                               IxZk8MMW&#WBM%8#&*W&W##oaoao&*%M*#hod#k#WM#&8%BB%&dY>^    iwWhaoapLL1!` ^JX#bjcXfcQQJXzcvnnnjfft|/jvzf))uZXcf<!<jt/fnunrjf.                     //
//                   ~h8%BZ0L(..                ."rQQ0*8&W8&W88&%M8W%aWW#&*Wo#obaMWa#W#MWhqWh8&M%WBBBB%&hfi.    Caoo*oaZzj; i(UoOuzvQLUXJu<!><i;^....'";i~<lirUv((/({)zrx>!l(f(/njj]<                   //
//                     +v&%888%BB%MdOLCCL0wkW%BB%&W%%8&W88W&W&&&M%#WM%#BW8Wa#&M&88oho##k&[email protected]%%B%%%8q|,    :vWha*apmtI'+_cUCCJLCJC~+:        ,_)fxuuxj1>.     ^>>_rx)1[+){f"">~x}ttf>^                //
//                       '/@B%%%%%%%%88888%%%%%88%&&B8&%88%W%&8B*8&#@W#%M##M8**W&*hM&a8bBMBB%B%%B%%&L>     [UkkdhhQQ/,;>{zzJLQLC}<.    inf/(1}?<"          `l_+" "<:  '!><{1ll[^1 `~<1|]];              //
//                          fmB%8%8888888%888%888B&%%%8B%%%8%%8%888&BM%*M%M8W*MM#&*W%8%%%%%%%%%%8q}^     }mhkqpZM(n_`<1vCJOZj],   .j{/1l                              '.  `  il`~">"'"`!i_>;`           //
//                            ,YM%88888888%88%%8%%%88B%B88%8B8%B&B&%B#&88%MM&8&%%%BB%%%%%%%%%8d/^     .+CdpO0btc~}'+[r0Z0v-"   +]f[.                                             .:`',  ...^`.          //
//                               >Q#%%8888%88%888888%B%B%8%8%&%%%B&%%&%8%%8B8%BB%%%%888%%%BQn.      ;)JqQQUOY(t .{j)0LX?;   ~](;                 .;>~~>i!l;,'                                           //
//                                  -Uk%%%8%%8%8888%%%%B%%%8%&&88BW8BWB8BB%B%%%%%%%%%%8WL(        :rmLCuCc}<['.lx{XXt_   ;_{!     "<.?<    `l:~(>.                                                      //
//                                     "jQ*88%%%%B%88%%%%%%%%8%88%%8%%%%%%%%%%%%%%%WwU;        `</LXrrr/-(; ;I:}ur]'  .,}?    .li-'      .'                                                             //
//                                         ./0ZMB%8%%%%%%%%%%%%B%%%%%%%%%BB%%%&bOf:          ^_Cnr/)-]~l' '_^,{/i   .,i,    ,?:                                                                         //
//                                               `tOqpk#8%BB%%%%%%%BB%8#bpqJ].             "/?/+~;lI:" ."' `I;!    "!.    ."`                                                                           //
//                                                          .......                      "`l.^.'.''      ...      ,      ..                                                                             //
//                                                                                                                                                                                                      //
//                                                                                                                                                                                                      //
//                                                                                                                                        ..                                                            //
//            |BBBBBBBBz^   ?Bk   1BBBBBBBB/`   BBBBBBBBd-   UBB~        iMBBBBBBBBB-        IBBBBBBBBBBBB~     'oBb      .XBBBBBBBBBBBa [email protected]:                                                           //
//            |$Li""""[email protected]:  ?$a   1$O>""""q$%;  $BL""""([email protected]  J$$~        iW$0""""""".        .""""t$%r"""".     '*$k       `""""k$#;"""^ ~$w:                                                           //
//            |$J:     h$o. ?$a   1$Q;     p$v' $BJ     ($%t J$$~        iW$L            `        ($%t          '*$k            b$*`     [email protected]$$%Z!   C*@[email protected]%hr   j$qq%@1'[email protected]*8$$$%L   "vWB$$$8#;      //
//            |$0+III]mB$!  ?$a   1$Z+III1w%$I  $BQIII>n#$c' J$$~        iW$B888888[   [email protected]$$J      ($%t          '*$k            b$*`     ~$$OI'.>m$]  [email protected]&i. '[%BJ  j$$nI^. h$$tl..?$Mt }M$c"  .Io$j     //
//            /[email protected]`   ?$a   1$$$$$$$q}`   $$$$$$$WcI.  J$$~        iW$ZIIIIII`   <W$k;      ($%t          'B$k            b$*`     ~$w;    U$] 1W$^     ~$d< j$r.    [email protected]   !$8c |[email protected]%[email protected][email protected]    //
//            |$J:  ,[email protected]#!   ?$a   1$Q;          $BJ          J$$~        iW$L                     ($%t          :$8x            b$*`     ~$w:    U$] 'a$w    ;d$O. j$r.    [email protected]   !$8c )8%f`'```Ut^     //
//            |$J:    }M$L. ?$a   1$QI          $BJ          J$$&WWWWWWh`iW$%WWWWWWW}.            ($%t    ^hBad#$8f             b$*`     ~$m:    U$]  ;YB$hw*$Mt^  j$r.    [email protected]   !$8c  !0$#mQd%@|.     //
//            :_I      l+_  '_<   ,_l           _+`          I+________~ 'i_________"             "+<"     .~1))<               >_;      ^_!     l_"     >)){I     ;_;     l+i    '~~"    `<{)],        //
//                                                                                                                                                                                                      //
//                                                                                                                                                                                                      //
//                                                                                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ripple is ERC721Creator {
    constructor() ERC721Creator("Ripple", "ripple") {}
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
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Noxverse
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                           //
//                                                                                                                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&[email protected]&&WWWWW&&WWWWWWWWWWWW&&&&&&&&&W&&&&&WWWWWWWWW&&&&&&&&&&&&&&MRRQBR&W&&WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&[email protected]&&&&&&&&&&&&@[email protected]&WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    [email protected]&WWW&WWWWWWWW&WWWWWWWWWWWWW&&&&&&&[email protected][email protected]    //
//    [email protected]`[email protected]&&&WWWWWWWWWXGAm&WWWWWWWW&&&&&&&&[email protected], `[email protected]    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&WWWW&BHH%  }[email protected]&&XPPAk8na]3auzzPXW&W&&&&&&&&&&WW&@OkPB0`   [email protected]    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&WWWWWRHH0   ,[email protected]&&WPAApC2cv?i}tvcc71l2bPWW&&&&&&WW&m02zgB$`    [email protected]&WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&&MHH0     [email protected][email protected]??+~`  `"zv}77"+8X&&&&&W&PClcuXBq`     [email protected]&WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&&@BHq      [email protected]&WWpevj"""}711+'  |c-`+z}?C&&&&@XblclCPqX"      CRWWW&WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&&&&DHZ      >&BO][email protected]?z``>+""ijtt^  +\  +zvaXW&&Fzvcc22cTe   ,,``qRWW&WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&&&&@BO``,`>-`SOTA%3ccccz0ASz|r|`   `|1|  ``  ~"z%&@A2ccccccc8l \z5I>` GQWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWW&&WWWWWWWWWWWWWWW&&&&WDQ" ^lI$z"2qxl]5lcccczqP0z?>\i0%nkOIlc2Ck$wO&&8cccccccc0k``\>}v_``[email protected]    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&&&@&@BA  ,zPga>|mPncccccccczPMPbnqCae][email protected]  `+st` +mPPGGOXWWWWWWWWWWWWWWWWWWWWWWWWWWWW&WWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&&&WPgm&v'^^ie:  x0qg3cccccc2ae+,                \ic2zccccCIg}    ,^` _:jxqAGXWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&    //
//    WWWWWWWWWW&@@@@@@@@&WWWWWWWWWWWWWWWWW&&gr`e}\zI?`  |S ^xIcczazi,                      ,"7zzC8`0i    `+s}>0XWWW&WWWWWWWWWW&@[email protected]@&WWWWWWWWWWWWWWWWW&    //
//    WWWWWW&[email protected]@&XXW&&&WWWWWWWWWWWWW&&&WW&Xqc}+,      z   lqa+-                            ,?0z`}l    `'':5$kXWWWWWWWWWWWWWW&&&@[email protected]    //
//    WWWWMRDMXmmmmmmmGGOXWWWWWWWWWWWW&&&&&&&&&WAn?_`,`   "  _i_                                  |"`",   `^">?0AmWWW&&[email protected]@WWWWWWWWWWW    //
//    W&DBDmOmmmmmmmmmOGmWWWWWWWWWWWWW&&&&&&&&Pus>^`\z+   ,                                           `      "z8qOWWW&&&&&[email protected]    //
//    @[email protected]&&&&&WGgu>``,|e]+     ``           `ij"~`                          \`_PXWXPXWW&&WWWWWWWWWXmmmmmmmmmOPPGXMMWWWWWWWW    //
//    WWWWXXmmOOmmmmmXXXWWWWWWWWWWWWWWW&&&&&XOIt\,~'~_ql~``,+t?'          +v_+lli'                  `     "00gGWWWWW&&&WW&&WWWWWWWXmmOOOOGGOmmXW&&WWWWWWW    //
//    WWWWWWWWWWXXXXXWWWWWWWWWWWWWWW&&&&&&&&&m]222"`|+ua"~|++i}`          }+i??jc2c~              '1vj"`   [email protected]@WWW&&W&&&&&WWWWWWWWWWXXXXXWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&&&&&&&&&PPOA?aP%cl+^"""?t\      ,>'  |s?j??jjc3v-            rcj?tt\  ^FXWWWWWWWW&&&&&&WWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&&&&&&&WWWPP&klx}\""+??|       ,?vi^`}1jj?j???le"           +cjjt"v_  iGWWWWWWWW&&&&&&WWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&&&&&&&&&&&&&XFw?\"}}?j"`        "jjli,}cjjj?j??7et`         `"??j}>l\ `nXWWW&WWW&&&&&&&WWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWW&WWWWWWWWW&&WW&&&&&&&&&&&&&Wgs_:1}jj+`      `>"`+??ct`"l1j??jj?j2s`          ~??j""c` "PWWWWWW&&&&&WWWWWWWWWWWWWWW&WWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWW&WWWWWWWWWWW&&WWW&&&&&&&&&&&&mv"`+cjjt-      ~um%,`"?j1+ '7ljj?j??jz+           |j??_1+ `nWWWWWW&WW&WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&&&&&&&&&&&&WT"~`1rj?_      "FDHQI` \+?1"``"cvj?jjjjl` `        `+??+_l` >&WWW&WWWWW&WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&&&&&&&&&&&Ol"`\c?j|      r&HHHHRC,  `:~~` `>1vjjjjj" :|        ,i?j_1| `[email protected]&&&&WWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWW&[email protected]&&&&&&&&&&&WA1" |7?+`     1MHHHHHHR0\    `}|  `>?1j?j}` ||        |?j"++  nWWWWWWW&@@[email protected]&WWWWWWWWWWWWWWWWWWWWWWW    //
//    [email protected]@&WWWXXWWWWWW&&&&&&&&Wqs| |j?\     i&HHHHHHHHBml,   ,2ni, `~+tji`  +\       `}?+>i  ?mWWWWXXmOmXmmmmWMDDMWWWWWWWWWWWWWWWWWWWWW    //
//    [email protected]@WmmmmmmmXGGmWWWWWW&&&&&&WCs\ 'j"     |PHHHHHHHHHHHRGl,   +hPa"` `--   ,t`       >j}>}  [email protected]@WWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWMDXGGmmmmmmmmXGmWWWWWW&&&&&&&Xn1' `+'    ,qBHHHHHHHHHHHHHBme~  ,aWMPx"`     ++       \j}"+  `[email protected]@WWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWW&@@mGPPGOmmmmmmmXWWWWWWW&&&&&&&XIr'  \`    vDHHHHHHHHHHHHHHHHBMgz|`+ABHDO]+-  'z`      ,t+?>   tmWWWWWXmOmmmmmmmGPPPXWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWXXmmmmmmmXXWWWWWWW&WW&&&&&&m]j,       ,%HHHHHHHHHHHHHHHHHHHHBMPCewmBHBDXZx?e"      `}+l'   \AWWWWWWWXmmmmmOOmmXWWWWWW&&WWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&W&&&W&&&Ozt`       >GRRQDMMMMMMMMMDDDQQDQQQDQRQMRHHHHHH&nv      `}7r     uXWWWWWWWWWWWWWWWWWWWWWWW&&WWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&&&&W&&WPr"`       +G&@MQBBHHHHHHHHHBRRBHHHHHBBRRRRBBBHR82_     ,1t`     +mWWWWWWWWWWWWWWWWWW&WWWWWWWW&&&&WWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&&&&&&&&&&P>~`       }[email protected]     |+`  ``  'AWWWWWWWWWWWWW&WWWWWWW&&&&&&&&&&WWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&&&&&&&&&&&&0:,`       +XHHHHHHHHHHRMPn+```,`` ```````` `,_"zcl`    ,   `?j   IWWWWWWWWWWWWWWWWWW&WWW&&&&&&WWWW&&&&WW    //
//    WWWWWW&&WW&&&&WWWWWWWWWWWWWW&&&&&&&&&&&&&&I          \AHHHHHHHBQOn+````,\a````````````   `cs2'        ~aI`  +XWWWWWWWWWWWWWWWWW&&WWWWWWWWWWWW&&&&WW    //
//    WWWWWW&&WW&WWWWWWWWWWWWW&&WW&&&&&&&&&&&&&Wv           zRHHHHBMk}````````,\````````````   "lj2|        r2z+  _GWWWWWWWWWWWWWWWWW&&WWWWWWWWWWWWWWWWWW    //
//    WWWWWW&&WW&&&&WWWWWWWWWWWW&&&&&&&&&&&&&&WXi  ^_    ", ,ABHB&n|```````````` ```````````  \1ril"       |er1z  `hWWWWWWWWWWWWWWWWW&&&&&&&&&&WW&&&WWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWW&&&&&&&&&&&&&WWP^  `7`  \xc` _ABP~  `````````````    ``      'tl}\z}      \z1jju\  zWWWWWWWWW&&WW&&&&&&&&&&&WWWWW&&&WWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWW&&&&&&&&&&&&&WXx   `a_  +bn+  \CA,` ``````` `+unac+`      ``|}+\,nqs     _z1jjsa"  \PWWWWWWWW&&WW&&&&&&WWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWW&&&&&&&&&&&&&Wh_   \n} `2Iva|  `zC\   `     ```\1>`       `````+0Cu}   `"l7jjjj21   3WWWWWWWWWWWWWWWWWWWWWWWWW&&&&WWWWWWW    //
//    WWWW&&WWWWWWW&&&WWWWWWWWWW&&&&&&&&&&&&WA"    "Sl |Szj1]"   ~CC| `          `          ,l%$zc5` `"cvjjjj?jl3`  ,FWWWWWWWWWWWWWW&&&WWWW&&&&&&&&&WW&&W    //
//    WWWW&&WWWWWWWW&&WWWWWWWW&&&&&&&&&&&&&WP1     }Cz`+n7sj15}`  `}%x|`                ` _xFPzs7z~\+ccssjjjj??1I_,  iXWWWWWWWW&W&&W&&&&&WWW&&&WW&&&WW&&W    //
//    WWWWWW&&WWWWWWWWWWWWWWWW&&&&&&&&&&&&Wma`    `lnz-te?tjjszv'   ,bnz?,             `"1l"+Plslcvz1ssjj???jjjsx"?, `amWW&WWWWWWW&&&&&&&&&&&&&WWWW&WWWWW    //
//    WWWWWW&&&&&WWWWWWWWWWWW&&&&&&&&&&&&&XC\     \I]2+il}+sjssvz},  ,+"+22j-       ,"+}"`` +Acsssjsjjjj???jjsss3"3"  ,zxC0AOWXXW&&&&&&&&&&&&&&WWWW&WWWWW    //
//    WWWWWW&W&&WWWWWWWWWWW&&&&&&&&&&&&&&Wk|     `tncac}c}"ssjsssvz?^  ~+|,+cj}+"++++|```   +nsjssssssj????jssss2"n}   wXXXWWWWWW&&&&&&&&&&&&&&WWWW&WW&&W    //
//    WWWW&&WW&WWWWWWWWWWWW&&&&&&&&&&&&&&P+      ^xzsCx?v}>ss7sssssv2l+,`|"_```:,`````     `ccjj17sjs1j}??jjsjjsc+Cl   }XWWWWWWWWWWW&&&&&&&&&&&WWWWWWWWWW    //
//    &WWW&&WW&&WWW&&&WWWWW&&&&&&&&&&&&&Xl      `1zjzZ0cv}_sslsssjssrkn^^\'>"_-````        "esslcjsslc+}j??jsjss?rau^   xWWWWWWWW&&&WWWWW&&&&&WWWWWWWWW&W    //
//    &WWWWWWWWWWWW&&&WWWWW&&&&&&&&&&&&&C`      +zjjxPglc+_sszrsjssjlF>   `,:\^,          \2vcelsr7rzs"j??jjjjsstzv2?   `nWWWWWWW&&&WWWWWWW&&&&WWWWWWWW&&    //
//    &&&WWWWWWWWW&&&&WWWWW&&&&&&&&&&&&0,      ^ljszgWAll+~sj27sj?vub_                  `~ezrxnlslll5+"ssssjjjsr11s72\   `IXWWWWWWW&WW&&&&&&&&&WWWWWWWW&&    //
//    &&&WWWWWWWWW&&&WWWW&&&&&&&&&&&&&G|      ~cjscqXWAcl+_js3rllnbv,               ``^"+"^` `t8I5zzz>}sjssjjjjsjsssc?    `CWWWWWWW&WW&&&&&&&&&&&WWWWWW&W    //
//    WWWWW&&&WWWWWWWWWW&&&&&&&&&&&&&&z      "lrsvCm&WAzc+|s1ajeej`        `  `   ``-\\``````` `}u]5z>?sjsrjjjjjjjjjsc"    `CWWWWWWWWWWWWWW&&&&&&WWWWWWWW    //
//    WWWWW&&&WWWWWWWW&&&&&&&&&&&&&&&0\    :slsjcSOW&@Pz1">jcucz```````````````````````````````  ,23l>sj7zvsssssssssss7~    `IXWW&&WW&&WWWW&&&&&&WWW&&&WW    //
//    WWWWWWWWWWWWWWWW&&&&&&&&&&&&&&P+  ,|cnezz2AWmAS2lz1"+jzn]"    ```````````````````````````   tIc"ssexCxzc7jjjssjsjt\    `zmWWWWW&&WWWW&&&&&&&W&WWWWW    //
//    WW&&&WWWWWWWWWW&&&&&&&&&&&&&&m017lzzzzzczInl",  :c1"}jzCz,       ``````````````````````     \al+rcl`_lnT00qCnuuunCnelr+:`+AWWWW&&WWWW&&&&&&WWWWWWWW    //
//    &&&&&&&&WWWWW&&&&&&&&&&&&&&@Az>`````````````~>|``c7+?j3I|"}?j?t?153?^     `    `_?lzcr}+++"""zz+sl}   \""?7ti+"||||||_>+}r2CFXWWWWWWW&&&&WWWWWWWWWW    //
//    &&&&&&&&WWWW&&&&&&&&&&&&&&P?```````````````     `cs}j1n+         `|+j",      _llr>,````````  |e}sc+        ```````````````,+2kPGXWWWWWWWWWWWW&&&&WW    //
//    WW&&&&WWWWWW&&&&&&&&&&&&@g\````````````````     :2jijec`    ```        `````,|,```````````````11s7c`      ``````````````````,5&XmXW&WWWWWWWWW&&&&WW    //
//    WWW&&&WWWW&&&&&&&&&&&&[email protected]^`````````````````     +2jszc`   `````````````````````````````````````}z?c1` `     ```````,`````````,[email protected]&WWWWW&&&&&&&&&&W    //
//    WWWWWWWWWW&&&&&&&&&&&&&@v``````````````````    ,zcsls`    ```````````````````````````````````` `+zvcv\`      `````````````````tW&WWWWWWW&&&&WWW&W&W    //
//    WWW&&&WWWW&&&&&&&&&&&&&k` `````````````````    }3sl}`      `````````````````````````````````    `\7zll+,      ````````````````\AWW&WWWWWWWWWWWWW&&W    //
//    WWW&&&&&&&&&&&&&&&&&&&@a``````````````````    >alz"```````````````       ````````````````     `` ``\}czl+_^^',````````````````,[email protected]&WWWWWWWWW&&WWWWW    //
//    WWW&&&&&&&&&&&&&&&&&&&&7````````````````  `` |x21^````````````````                 ````````````````  `:|">~,`` ```````````````,[email protected]&&WWWWW    //
//    WW&&&&&&&&&&&&&&&&&&&W&t``````````````  ``` >Iz|```````````````````               ``````````````````````  `    ```````````````,[email protected]&&WW    //
//    &WW&&&W&&&&&&&&&&&&&&WM7```````````````,+_`+c>```````````````````,``          ``````````````````````````````'``````````````````e80XWWWWWWWWWWWW&&&&    //
//    &&&WWWW&&&&&&&&&&&&&&WWl```````````~"`}?\`_\````````````````````,'>+\`  `   ````````````````````````````````\+","``````````````n]"nXWWWWWWWWWWWW&&&    //
//    WWWWWWW&&&&&&&&&&&&&Wxtc`     ``````x]\ ````````````````````````,,:\i2t`` ````,``````````````   ``````````````:cq-````````````^h1s+xXWWWWWWWWWWWWWW    //
//    WWWWWWW&&&&&&&&&&&&WC^?1       ```,lI: ````````````      ```````,,,:'\cC"`+_,-,,```````````     ````````````````"a>```````````"%sst|0WWWWWWWWWWWWWW    //
//    WWWWW&&&&&&&&&&&&&WS^is2        `+n}``````````````````    ```````,,,:''+Fg3\\',,,``````````   ```````````````````:2+```````  `jSsss^iPWWWWWWWWWWWWW    //
//    WWWWW&&&&&&&&&&&&W8~+ssn`      ,aa:```````````````````````````````,,,-'\iG+^\'-,,``````````````````````````````````r+``      `]5sss|,CXWWWWWWWWWWWW    //
//    WWWWW&&&&&&&&&&&Wq_+jss8"    `>$?```````````````````````````````````,,-'^0j^\':,,,``````````````````````````````````t_       `I1sss"`sOWWWWWWWWWWWW    //
//    WWWWW&&&&&&&&&&WF>+vjsjIc`   +8|`````````````````````````````````````,,-\Cz\\'-,,,````````````````````````````````` `c-      'xssssr,>AWWWWWWWWWWWW    //
//    WWWWW&&&&&&&&&&Pt_3ssjsc2`  +S\````````````,,````````````````````````,,,'a5\'-,,,``````````````````````````````````  "v`     tljsss2',0WWWWWWWWWWWW    //
//    &WWWW&&&&&&&&&XI`?esssssI' |8\`````````````````````````````````````````,-zz'-,,`````````````````````````````````````  v'    `asjss1]-`8WWWWWWWWWWWW    //
//                                                                                                                                                           //
//                                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NOX is ERC1155Creator {
    constructor() ERC1155Creator("Noxverse", "NOX") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC1155Creator is Proxy {

    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x6bf5ed59dE0E19999d264746843FF931c0133090;
        Address.functionDelegateCall(
            0x6bf5ed59dE0E19999d264746843FF931c0133090,
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
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Music, Melancholy and Mirage
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                  //
//                                                                                                                  //
//    OUYYUYYYXXXXzzzXXzzXzzzzcvuuumOYXXUOwmLokk0YzzXZbCLQJqQJUCwoowUudOJYUYYUUUUYYYYYYYUUYYYYYYUUUUJJJLLLLLLLLL    //
//    OYUUUUUOLpZdCCJhpppwXXcc0bpqpqqqqqpqqqqqqqqqqqqwwwwwmwwwwqqppqmmnnbqCUYYYYYUYYYYYUUUJCLQQQQQLLLLLCJJUUYYXz    //
//    OUYUUJJCCCCJUUodpppppppppqqqqqqwwwwwmmmmmmmZmmmwmwwwwqqpppqqqqqmZvjCOQJZwmZmOQQQQQLLLLLLLJUUYYYXzzzzcccccv    //
//    ZUuJJCLLLLLCCC0*b*ddpdppppppqqqqqqqqqqwwwmwwwwwwwqqqqwwwqwwwwwwwqqCxjruucvnMM*apppd0JUUUUYXzzzzzcvvvvccvuv    //
//    ZJvCCLjUnJJnJCmQahdddddddddppppqqqqqqwwwwwQwwwwY}wwwwwwwwwqqqqqqpqqqqOLC0ZZ0QLYCv[]t0mUUYUYXczcvvvvvvcvvvv    //
//    ZJC~CCCLLLLCCCm0kbbddddppppqqqqqqwwwwwwwmm::ZZ("wwwwwqqqqqqqqpppppppppppqqqqpqqqq1?uCbUUXzzccccvccccvvuuuv    //
//    wZLCCLLCJJxUUUUYbdpppppppppppppppqqqqqqqqqqqrrJqqqqqqqqwqppppppppqqppppwXrfrf((}|XqZJYXXzcccczcccccvvvvvvv    //
//    nUmCCLYYYXXjXXXUdqqqqqqqqppppppppppppppppppppppppqqwwwwwwqqppwqqqppppm1XQLCLJJYUYXzzzzcczcccccccvvvczcczzz    //
//    o/LwCLCJUuvXj|XUdpqqqqqqqqqqqqpppppppqpppqqwwwmwqqwwwqwqqpqqqqqqqppppzOXXXXzzzzzcccccccccccccccvvcvzzzXzcc    //
//    8U[YCJYJJUUY/XXUpqwwwwmwwwwwwqqqqpppppqqqwwwwqqqqqqqqqqqqqqqqqqqppppvJXcvuuuvczzzzcccccvcccccccvvzzzzzzzcv    //
//    88}]LLfXXYUUXXXaqpqqqqqqqpppppppqqqqqqqqqqqqqqqwwwwwwqqqqqqqqppppqpp0nccxxxnuuuvvvvuuuvvvcccccccczzzzzzzcu    //
//    8dr+[cQ()jvJUvXpmddpqppppppppppppppqqqqqwwwwwwwwwwOn>QwqqqqpqpppppppqZuuXY|rJUzcvuuvvvvvccccccczzzzzzzzzcu    //
//    8Uu-_-1|f{{tUXzYzzzzUhbdddpppppppppppqqk00-*wwqzI?mkdpqwwqqqqpppppppqqOnxLpO(v(zQ0YYXzzcczzccczzczXXzzzzcu    //
//    *j}~+?[[0_[])Xn|zzzzYUUU0wddpppppppppqqxmw|)qa0|hdppqqqwqqqpppqqqpqwqwwmOOZpdao*W88kqUXXzzccczzzczzzzzzzcn    //
//    8p?~~-(11p_-/YzzuzXCppQUUUU)akbdddddddpp#}odqJ]zxkdqqqqqqqqqqqqqqwqqqmmwqqmYqo*#W888hUXYYXzzzzzzzczzzzzzcx    //
//    ro*{~<{111f!)YzzzYnUYXYYYYYYYYYYcfc~nv(ObddYUu|//]UbqqqqqqqqqqqqqqqqqppdpwOwmQka#WWwCYYYYzzzzzzzzzzzzzzzcx    //
//    Jxk*[+~)[}]<:]zzXUJXi,/XYYYXYYY0YYY(X}<XYYYXfrctX|cfbqqqqqqqqqqqqqpddddpwwumQLCJUYYJYXXXzzzzzzzzzzXzzcvzcu    //
//    wZzq&Y?+]?{]<:UzYJYYUUYu|v~nUXr_YUUYJUJ}cxnv1rrXnXz?dpqqqqqqqqqqpdddpqqOJQJJJUUUUYYYYYYYzXzXzzXXXzvvvvvvcn    //
//    YmZUm8WU{?~1}<_XUUJJUJJJCLLJJ~!fYUUUYYYU<uvnuX1Xt|1bppqqqqqqqpddbbpqwmOLJUUYYYUUUYUUYYYYYYXXzXzzzvvvvvvvcr    //
//    JJLOLQb#&zt8X},twmqwZOO0ZOLJJJr_,<<|UUUUuxX(jzrX0kpqqqqppqqpdbbddppm1QJUYYUUUUUUYUUUUYYYYYYXXzXXccccvccvvj    //
//    pdOQL0ZmdWJ88Y_!;1/"`LpwZOLCCJJUI,_~1YYYXYrX/fvckbpphppqqpdbbdddpppCYJUUUUUUUUUUUUUUYYYYYYXXzXXczcccvcvvvx    //
//    pdhkkdbbbdW&8&M&*w+~IIqbwOLLLJJJJ:l]1JUU~+/X1XYYQpdppqqdbbddpddppppjLJUUUUUUUUUUUYYUYYYYYYYXzzczzzccccvvvu    //
//    pdaahaoo*#&&aWrb8b~<l_WkwOO0QLCCCx^^)UUUXY|U1nvz+dpppdddppdqdppppqp|0JJUUJJJJUUUUUUUYYUYYYXXXzczzzzcccvvvu    //
//    &8888888&&8&oo1dM__<:,~r8pOO0QLCCJ;`<UJCUvfrY}(YY-Opdpqqpppddpppww0|ZCJJJJJJJJUUUUUYYYYYYYXXXcczzzzzccvvvu    //
//    nCJU888ab8hWWLr&n+_<<!`';camZO0LCU;`UJJJ|/(vxUJUYuupppppkkbdpppqwwZt[)f)vUJUUUUUUUUYYYYYYYXXYczzzzzzccuvvu    //
//    vjtZbk8888C8&qWm?_+~~<<i``ICwX|LCn,+CJJUmUUJjUUt(YUlJJoU0hk#hdpbqwwmj?<{1|frLUCJJUUUUUYYYYYXzzzzzzzccvvvvv    //
//    wJUU#8vO88&888a[-~>>~~<>,`'_t][tCt^{JJJm|CJJcJnjUrXjYXbzvY(|:/hdpqqqO{[]]]})/jr(/YUCJUUUUYYXzzzzzXvccvvvvv    //
//    nMpoCpW8wq88M8p[+~<~+~~<i^'"Zm0LL<]LLLL-C(Ccx}??}uYYrjUU]XfXv~+dkdpqdmX?~~__]}1fx/CLUUJUYYYXzzzzzXXXcvvcvv    //
//    vwdqYwp*8J8&*8p?+-_+~~>!,"',h0LL_"|LLYCJ[Cvz1+Il_1vtJ:f{x|Y)vvxx[bbppddpmJ(--??|r)CJUJJUYYYXXXXzzzXXccvvcv    //
//    zdabwzpd8&w8Z88u-_++1/I:^^':iQQz'?LQ0uv?Y}tvj(1{1(?u~YYcnY(jJvcz}:bkppbddqL|-?-)|10CUJUJUUUYYXYzzXXXcvcvcv    //
//    OqddwUmoW8v&ZU8&]]Uv<:,,"^^,cm+?0ZOOcLvYXJJ(U-xUUu;i!-1I``'`>n_Yj]xikkkbddOr}_-}{c0CJJJJUUUYYYYXXXXXXccvcv    //
//    ZqwbpZpbM8OX&r88u(L_!,,:,^"OL:0LJUUjzv}X?|c)zJQ~!l"'```````````^lX]-l^{0akdY1?~1}zLJJJCJJUUYYYYYYXXXXczvzc    //
//    Qqdbphwb8&8p&oo8W[pU+:,I"""1u/XXXzcXn|uzzX-YX>:;;::,,,:""``:^""```^x,I{r?:dJ[~<+)0LCCCCJJUUUYXYYYXXXXccczz    //
//    mwObdphkM88po&v88[Ldq~:I;"""YXzzzzjuuX|cYYUu;;,,,,^^^,"":"^^`^"`````I{/}~:kz]_-+|mCCCCCJJJUUYYYYYXXXXcccXX    //
//    Zwwbpb#*#88LJbb&8mwakw+II",,xXcczzzzXX;XcYvi;;,,,:,,,:,,"""::"""`````````/hp|]-1UZCCCCCCJCUYYYYYUXXYYzcXYU    //
//    qZbkdo#M888O88&Y88)qoh0</:,,^)JvczccXXjvYX_<;;,",,::;,,::,"","""^````````_0bk{[-(OCCCCCCJCUUUYUUYXXUUXzcXY    //
//    boh*o#W88M#O888#&8#r&hbCrI,!:'^QXzzctXXzIvC>;:,""",:;,:::::"""``````````!aqbob}(zCCCCCCLLJJUUUUUUXYYYYzczX    //
//    baa*MW888a&&888v&#&b&#kk1I,I;;`^xjzuvv(nnx<il:,,,::<:;;,"^``""``^``````+dqbho**pjLCCCLCCLJJUUUUUUUYYYYXzcz    //
//    k*#M#M88#888888&LM8CpMab[:I;i!;``Qczunzur>iI::_,:::~::;;,^","","^"````^Zmphha*oaMZCCCCLLLLCJJUUUUUUUUYXXvc    //
//    o*M&888n&8888888fM&&fkobz;;i><II`!Czcuvc<I,::::l:::::,,;;I;,,""^^`"```tLZmha**#*aa#0CLLLLLLCJJJJJJJUUUXXzz    //
//    #M&888k*88888888MCp8X{khq(l">ilI;'u0cuYX-~",;I<:::;;::;I::::,"^^",,``Iu0qqao###**oooMbv0LLLLLCCCCCJUYYYXXz    //
//    MW&88&#88888888888M#&~woap]!:<>ll^_Cnv(n0i``^",::::ll;:::I::,"""",^``_v0qha#M*oahaaoo*#b/YLCJCLLLJUUUUYXXX    //
//    M&88#/8888&&&&&&888j8cQo*#O>I>ii!^~acXUcjc:;;;I::_:;:::;::,,,""""^```_OOqa*#*okp0wmpJho*#**L0cUvc0QCJJYYXX    //
//    W&8Mj8888&&&WW&&W888p8z**oWp<iI!>:>{JoknzziI;!^,:,::I:::}:,"^"""^,"<^_XZko#MabXfZv0Cbdw*MWWWWWMM#*hdnYXYXX    //
//    &&&j8888&&WW&WWWW&88hhOpooa&0I!!~i:>uL8*)JL-;d<^"",:;;;:,,,^^,">"``l{Ucwa*MabxxOfffLdqZnkMMMMMMMo*#0UYYXXu    //
//    W8p8888&&WWWWWWWWWW88Y&Ma*b&W!!:!i,^"mMo8&8aZwrLc;:::[;;ll;"::^:``:QQJZao#odnjxfjUYvx/LaM#o***#a*#dUYXzzzx    //
//    W8j888&&WWWWWMMWWWW888bW&Mw*&flI`;;,';La)+fXLkJJdMcx:IIIIIlI:"^^I``O0phaook/|jjYJZpqdba#*hohkoa*#hQYXzzczn    //
//    &wd88&&WWWWMMMMMW&&&888b&&oo&_!;^I:``dZ|,,:;^`^:vWkhM__);,"^^"",^``:CpbooMr||vJJk#aaoahhhooakoM#*uUXXzzczv    //
//    Ww88&&&WWWM##MMWWWMW&888#&M**rl":""`kZ!,IIlI:;II"`;/QM~""(OppJ|/|1:`,YWo#q/|rXpM&M**#o#W&akh#MM*xjYYXzzczt    //
//    &w8&&&WWWW*#*MMWWMW&8888&&MMoul,;":M(,:IIl;:::::"``''^..'".''''....r/UWa&wj|tXW888MMWqZ88W#MMhutr|zYXzzzcr    //
//    km&&&WMWM#o*#MMWMMWW&888&&WMWOi,,ru>,:I;ll:!l;;;;:,```^""""^^^'''....,kMWMv//z&888&&Q||n|/njrX|t|j|jYXczcu    //
//    qmW&&WMM#W#*###MMMWW&&8&&&&WWd|,v],::;Ill!;!lllllI;;:,,"^`^'`'''...'.'c&&8&UX088888Cu|p|||u|U||ruj|mzJccux    //
//    pwMWWWM**M#**##MMMM&&&MM&&&&MUt,},,;;lil!l!l!!llI:::"^'````.`'''...''imW#W8888q&888L|t|j||wq||||/|k|jmYunr    //
//    wwMWWMM**M##a**MMMM&&&*#&#W&M8tJ,:lIIii!i!i!!I;I;:,"````"`.''...':~|LhhMoY<1{;^;/Qp&mQ||||||v||jz|/||,'f-j    //
//    bw*WWM#*oo##***###W&&bWW&#MWW8m',I;!>ii!!ii;III::,""`^,"^``''..[(.'`Qqhh(.'''^`'`||&8ck||||c/|||||/MW;'j;j    //
//    &wkWWM#*oo****##*M&&#o&Moh*WW8&",:I!il>Illlll;;;,;",,"^^^`.'.'+;`'`".}uz.''^`^^^:Y|nnw|jJ|UQ(1||vJU}Y'.(^)    //
//    WwhM##*#oo*oa*#*#M&Wd&&##ah#WW&^"";;;;;Ii;I!!!!l;:,"^,"^.....;}''I`:`...''^^^",^]|||z;/(`.,^^",:':'.''^]^[    //
//    &waM**o*oo*oo**o#WWhd8*aMabhMMkw;^,;;;:ll!i!iiil;;;,^``'..."[>`^Il`;".''^`^":"'Y||+....',::,:,,^``':;'c],"    //
//    8C***#o*oo*a****#W*x#*kk#akk#oWdZ"":,::li!i>i!lII,"^``''[_''`''^I,"",.'^`^,:^,;O!....',,,,,,^^`^,:;l!)->`[    //
//    ob****oooo*koo*o#MhCWaqZbbhbha#bd{^,"^,ii>ii!l;,,"^```'')`'`'^::,lIl^''^":;";I;::,:^,,,""^.``^":;ll<qil,`1    //
//    Oh*o#*oooaoaoo**MMtoWhqLZdbbbhMqdd1:"^;ii!ii!l,""^^`^^''|..^,::!!!l::"^,:;,;l!lI;:::;:"`..'",:;ll:l~-J<"^[    //
//    Ok****oooaooooo*##toobuZCLbbbhWMbdp~"^:l<>!l",","``,"`''?'.";I,li>i!I!::I;I!iI;;;:,"`....^,:::::,^!>[J{?+_    //
//    Oa****oooaooooo***aOaQZOOUbkkaW&#bdz`^:;<ii,",""^`,"^.''?!":Ill<<!><i!!lil!!iiI;;,'....'"",,,,,`'"!~[:{b[;    //
//    ha****oooaoohooo***aohbUOdbkka#WobbC}'`",!Il:"^^";^!^"''i|>I>:<_?~<~<!l>!!;;III"......``::"^^```'',!II.[[l    //
//    ha****oooaaooooa***ahabdjLLbbhaoW#kkLu`'',ll:`^^;:;`":"`"~;I<>_-~>>>i;i!l:::I^......',:::I;+[l'''""l"l-X-;    //
//    haoo**oooaahoooho*o*kkbqunjjmbko*M#abbbw-:`;~;,^;:Il":;i_`>!i<__<Ii:^`I;:,"^......'`^^^:lYp|jC|.'..`I;`b~^    //
//    Oaoo*ooaaaaaooohaokhkdJJ/jxzJLXdkh#&&abbdLr+mC-II,"I;l:<.'`i_-_<>;l,:^^:^'.'''''''``^;!;-Xxrfvzi..:I,I('`i    //
//    Oooo*ooaaaaakaoaoopkhwfLJrcXvcX0pkoo*&WW&MakkM&88c<':!,:.':I+_~>ll;!:^""``'.''.'`";l!!ill&|0Xu/?.',,t'.":~    //
//    dooo*ooohahaoaoaoadbk]OJc|nUncczQZho*MW&8&888&#M&&b^:>1:."I<_-i!i!I;""`'``""^":;;I!!~~lIIi|XuY|_''f!'!i""_    //
//    moooooooaahaoooohadwbUJUfuxUnrXXX0dahhhha*aaahkhM&du<`1.`,;+~ii>i!!^""^`^",:;;I;:;I!+<i><;l<fz|/}`w,"^`",_    //
//    doooooooaahaaaaohkpObZzxjn1])nuvvvvO0wpqppOkkbbb*&#8W`(.``,!>><>!i;"",::,,;I!lll!i<_i~~~+<>_}|JU;')"^^:,I?    //
//    daoooooaaahaaaaahwp00cnnjx1{)ttvjf(nzzXYc|/nL0dbo&*W8WCvxj!,~>il>,,:Ii<i!!!!><+___-?!>lI~<i++YcuI(:^^"^l;]    //
//    haoooooaaahhaaaabwLdwzvjj|||tffcxjj/XrXc/)t0njQha&#88W8*88*L|]~~;;!~+++______-|xrwhQi;_,;"l+-uY0'`f`^:II~<    //
//    hhoooooaaahaaakhmdJznznrcc)xzncunnc))Uuft)rxzzk*aWW8M88&8M8Wp)?_i~-?[}}}1fzOCLLYa*qJ]&8Q++>~+[Jt(1[}^:!!i_    //
//    hhaaaaoahakhahhhZppjzxrfjUr1cYuxuuzr-cnnUYruQUw*MW&Wbw8WM0qpo*(?1|ZqZ0k&W&*MM*Cd#888a888&WoqbJzUftxMUjj/||    //
//    kaaoaaoahadhaaadmqwOc{nxz/zrtnzxxuL|1|vuj[|vfcvo*W88odqaaZZOmqdwW&8&WWM#####MW#MMMM#****##MMWWWW#akZJJzn|v    //
//    phaahooahbdkaaakwqLLmYjxLjmnfjujnuZntjCn||Xr/vnma#88MMrhbOqJLahkkko*a#M#kdqwwwpdbbbbbdddpqmZOQLJXnnuuxj(|(    //
//    ChaahoaahdpkahhbZQXuuxuxcjYrnjjrftC1f//|(/t(jvjbaMM&M*ap0CCCCCCLZJLQOqwmmZO000wqwwwwmOQLLCQO0QLCCUUUUYYuxf    //
//    Xhamjzh|-rqkhkhbw0OXvunnxzxxnxxjt|u|Ynj/1|/xXzzdh&&M*ad0UUXccvzYYccczcunnnuvunYt1vvx|/(}}[[}}}}}}{{}}[[{|r    //
//    CkhakkkkdbkhkbdwmLLUXxvvccurrxuuvc|tuvvxjxxxcJwdkh#MowQcYX<>i>[Xi:;;IIl!!!llII!llIIl!!!llIIIllllll!!II:I;:    //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MMM is ERC721Creator {
    constructor() ERC721Creator("Music, Melancholy and Mirage", "MMM") {}
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
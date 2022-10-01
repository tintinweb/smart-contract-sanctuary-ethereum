// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kamisama Girl
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    gggggggggggggggggggggggggggggggggggggggggN?1<_~..~<_~_- .``````.`.TggggggggggggggggggggggggggggggggggggggggMOlz=<<<_~~~(_....._-.JHggggggggggggggggggg    //
//    [email protected]@[email protected]@ggggggggggggHb??-...__<-~... .  `````` [email protected]""7<!_~~_(?7THY9"""YWHMHgM8l==-_~~~._~_<_..`..`[email protected]@ggggg    //
//    [email protected]@[email protected]@[email protected]@@[email protected]??<_..__<+<~~.~.~..  `````.?HgH#"= ```````` ___(++<<<~..````` ?Yll=?<_....__~>.... `..`[email protected]@[email protected]@g    //
//    [email protected]@[email protected]@[email protected]@[email protected]@@gggggggb?<_~.._~:+1__.~..~- .````` .^``````` ````` ._(jZz>_ ````` ```.Il=1<~__.`_:~<1~.....`..([email protected]@[email protected]    //
//    [email protected]@[email protected]@[email protected]@[email protected]+?-_..___;+z-...~._-.... ``````` ` `` ```..~(jCJv!.`````` `  (=lv<<_..____<?=~.....``` [email protected]@gggg    //
//    [email protected]@[email protected]@gggggb?<<_.._<:<zz<~~~~...` ````` ` `` ``````.._(z1Z<_.```` ` `  .I==1-_~~_..-~;+?>_...`````,[email protected]@[email protected]    //
//    [email protected]@[email protected]@[email protected]@[email protected]?<_..___<;1+~..._```` `  `` ```` ` `` ._(Zzv<_.``````````` <1=<<_~_. __~(<+l_..``.``` [email protected]    //
//    @[email protected]@[email protected]@[email protected]@[email protected];_~._~_~:<+_~~``````` ````` ` `````.._+vJI~_.```````` ````` <?-~~...`..._(1_...``.```[email protected]@gggggggg    //
//    [email protected]@[email protected]@[email protected]@[email protected]@gggb>-~~..__:~<<```` `  ````` ```` ```._(uIvv~~.``````` `` ` ````(1<__..__~<<<?<~_..`````[email protected]    //
//    [email protected]@[email protected]@[email protected]@gggggggMR<~.~___(:!``` `` ```` ` ``````` ._(J1I<~_...````` ``````````` <<-....-~(<><~_...`````[email protected]@gg    //
//    [email protected]@[email protected]@[email protected]@Mp<<_~~_~ `` `` `` ````````` ``._~(vjv~_...````` `````````````` <-_...__<<>i_..`. ````[email protected]    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]__..```` `` `  ```````` ````-_(CJ>__..``````````````````````` <<_~...-_<<~_.`.`````.Nggggggggggggggg    //
//    @[email protected]@[email protected]@[email protected]@[email protected]<_~_```` ```` ``````````````._(vyC~_..````` ``````````````````` <<~__..~_<--`````````[email protected]@[email protected]    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected],~````` ``  .`````````` ```.-_jz<<__..`````````````` `````````.` <<____._<<_..```````[email protected]    //
//    [email protected]@[email protected]@[email protected]@[email protected]`````` `` _`````.`````````._JCj+_..````` `` ```` ````````````.. .<:_~_~~(<_.`.``````[email protected]    //
//    [email protected]@[email protected]@[email protected]@[email protected]^````` ``  ```.`.`````````.J!~._(O-.`````` ```````_````````````.. (_:_~_~::~`````````[email protected]@gggggg    //
//    [email protected]@[email protected]@[email protected]@[email protected]^```` ``` `.``.`.``````` .v!`````._?i````````` `````_```````.```.`` <(<___~__..``````.,[email protected]@ggg    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@gggM^```` ``  .``.``.```..` .C_``````````_1,````````````` _``````.`..`..`._~_._~__...`.```[email protected]@g    //
//    [email protected]@[email protected]````````  ```..````.` .=_````````````` (i` ` ````````` .``````..``.`.`<_~~._~~~..`...``__Mggggggggggggg    //
//    [email protected]@[email protected]@[email protected]@ND`````` ` ```..````.  .C_`````````````````_1.``` ` ``````_`````.`..``-dY4Hx______ .. ..``.~([email protected]@    //
//    [email protected]@[email protected]@[email protected]@ggggggggMF`````````_```.```.  .v~```````````````````` ?,``````````` .`````.`...W~. ?HL___.~-..`_.`. [email protected]@@@[email protected]    //
//    [email protected]@@[email protected]@[email protected]@@[email protected]@[email protected]``````` `.``..``. `.J!````````````` ````````` (l```````.```_`````..(JHh, .(JH&,._ ` .`_.` `-_([email protected]@[email protected]    //
//    [email protected]@[email protected]@[email protected]@gggP``.`````` _`.```.  (=_```````````````` ` ```````_1.````.``.`  `````-W(kH6&&JHHcH|_`_ .`. .`._~.Mggggggggggg    //
//    [email protected]@[email protected]@[email protected]@ggggg#```.``.```.`.``..`.v~.``````.``````` ````` `` ```` ?,````.``` _ `.JXHHYXCd0Z3OOTHHk&,` . ._`[email protected]@ggg    //
//    [email protected]@[email protected]@[email protected]@HgggggM'``.``.``` _``.`` .3_`````.````````````````````````` ?,````..``_`JW!`.(zwIX9dkzwZ__ .Wh`  __`[email protected]@[email protected]    //
//    [email protected]@[email protected]@[email protected]```.`..```.``.``.J!.```````````````````````` ```` ``` (+``.````.`(Wh-(HmcOUXkVx+gH&(J#^ ``. `` .~(@[email protected]@gg    //
//    [email protected]@[email protected]@[email protected]@[email protected]@gP`` ..`.``` _ .``.C~.```.``````````````````` ```` `````` (>`.``.` ```.~OK9jwG0zkw$7gf^ ```_`  ` .._([email protected]@[email protected]@Hg    //
//    [email protected]@@[email protected]@[email protected]@[email protected]@[email protected]~```.`..``   .``.=_.``.`````````````````````````````````` (l`.``` ``` `,H++g&dHAJa+#!  ``` . _   __([email protected]@@    //
//    [email protected]@[email protected]@@[email protected]<[email protected]@gM^`` .``. ```_.` J!.`.`````.```````````````````````````````` (l`.`` ``` ````(HK?!_HP..-`_```` . _ ___([email protected]@@@[email protected]    //
//    [email protected]@[email protected]__~~_jNgggHF`` _.`..``` :_.J!..``   ``` ``.````````````````````` ``````` ?;..`  `` ````.7H..dH;`._. .````_. ._~_([email protected]@@[email protected]    //
//    [email protected]@[email protected]@~([email protected]@~:+<[email protected]@`..-_` ..```._.Z~..`..`` `    .````````````````` ` `     ````` ?,``. `` ``.`..K?=<J[.`~.`_ ````(. [email protected]@gg    //
//    [email protected]@gM5~~~(WHM3_(>([email protected]:<+>(jwrdHgMY!_?4,` ._`` (.Z!..`.``_.    `  .``.`.`.`.`.```. ` `  ` ` .````` ?,`. ````.`...H.`((]...``.-` `` (-`[email protected]@@[email protected]@ggg    //
//    ggggg#~___(IW#<<>[email protected]++zZTTTwM#=~(~_(d .. ``.oZ<...``.``.`.``   ````````````.`_`` `` ` . ````.``._1.. ```.``..(H.`((K`.._. (.  `` ?-`__WgHHMMHkHgg    //
//    [email protected]@~~~v(IdMNm7>~~+wMgMD<~~~_+d9((+!(jwd)..`` (KUw&.-.``.``.```` ````.``.`.``````_..  .` ``````.`.`._I.````.`...(H.`./M .__.` l`  ``.(< .dgggHHHgHWH    //
//    [email protected],(+1yO?Hg#<_._+wMNE<~.._(dMp-((jw0rrb._`` JMH#Nmg+-.``.```````.```.````.``````````````````.`.`...(x```.```..-H.`.{W;.....`(>`  ``_~<. [email protected]@@gg    //
//    ggggggMNyOzz=?B5<_.~~?T9z<~~~(jMMd97TUUXwwf__```daxZWMM##Na,. ..``.```.````````.``.`````````.```.`..``.-j``.....`[email protected]_`.{J]..`;.` O,` ```__<-`[email protected]@ggg    //
//    [email protected]<<~_.............._~<HM#>~~~~(zd=___``.wgM1zOtQWHHMNJ._- ````````.``````.```.```.` .. .`...JuwwP`.~~.....`H_`-},b..`(` `(O.` `  _.<- (MHHHWHH    //
//    [email protected]#<_....................~<<_~~_(zZ~ _(_```zHg  _jHHH0<jMN, ~_`.`````````````````.`.-~~-.(gHMMMM###]`_~:~~~..`H;_({.H-._.-._.vO.``   .~([email protected]@@@    //
//    ggggggM>~.......................~~~(+uY._._~ `` kdg;``.XVTHkWWMMh. ````.```````.```.`. _~.(dHHMHf!dWWkQO}`..__....`X}_(:`O[`.`<._`((G `_   (_de. [email protected]@@    //
//    [email protected]@g#<__~~~~~~~~~___.........~.~_+A5`__._< `` WOHb`` Sv<(UWkUHHR.``.```.``.`````.```..jgHMMHHWyZXHWXXC~`` :~....`dr_(!`,N. `._ _.>jn `_   ~(Mp_`[email protected]    //
//    [email protected]$~_............__~~~...~~.~~(jt&-,..<:-`` d2ZW,``(w<_dH(kyXH-..`.`````````.```..JdHHHWXXXq9HYC?:.. ``-~..._``d#!(~`.M]`_`<`~`(_zn``_ _ _dHp_`?Mg    //
//    ggggH8~_...................~~..~~(ub$~_Zh~<<_``-dN<zX. `,G+(7U0w$({.``.`.`.``.`.```.`(HBIOk07<uH+K>__(2,``.~_.. _``dM;(``.?^` ..-._.>(jl``_._ (MMe_`?H    //
//    [email protected]@@#<_......................___(1fy_._Izb<<_.` dN(>>zI. `_71zv= ..`..`.```.````.`...(!! `1z_ _?<!_.(< }` .~_.` ```?W\z``_.`.._`>`! (_>jl``(.  ?MNc.`4    //
//    @[email protected]>_...........--________.~_>??d:D__(vOZWx_.``JM{:<<;<?<-.... .......`..``..`..`.`..   ` _(._---(?``.~......`.```.._r` _`.``..(`( .;(:wl` .- .?HN/`.    //
//    gHHD~.........~_~~~~~_______:(<?jhv3-(+====dL ``,H]<:(<:~<~~~........`..``.`.`.`......._  ` `` ```` .Jf``.._...-` `.((}.  .-`  _.-._ (_>j/l  .l _?MK_`    //
//    HW#<........._~~__............_<<~__<1<?1zzOd!  .Mb_:~:~~~~~......._  ` ....`.`..`.......~~~:<<1zz1=?w\`  (~`.__`_``<J_`.`._`(.(`> >`_;(<I(l ..h.`.S{.    //
//    HMD~........~__.............._~_...._<11+zAY<_.  HN.~~~~~~~..~.....`    ................~.~_~(<<<<<<+v. `.(`. .!`~. II` _`.`-,_._(`<` i(<j(-< . W,  r     //
//    gM<_........................._.....~_(+zd5>_<.___d#[_~~~~~~.~..~...<..........`........~~~~~~~~~:<(<j%.  .2``..~.`..1\.._ _._,{_<._(``(-<j__?.   Wp.l     //
//    gMx_.............................._(+zw=_+1_(___ ,HM,~~~..~...~....~..................~.~~~~~~~::::(v   _.>  _+_. _,J. _  ._:(I-( :(``_{<<}~<1 ~ .4N:-    //
//    HHb_............................_(+1uY-{.(z-.<_-..MHH,_....~...~.....................~.~..~~~~~~~~(j> `__k` _,(._..z% __.. .`JO.(->(..-z(<%_;.[ _ .$-_    //
//    ggHP__......................___(+zuZ'-_I (1l_(:!__(HMHm-~..........((.-...............~.~.~~~~~~~~+% `..J% ..~>-:_(V__(_-__2.RI<~<(+` .j(<l_;_H.(.<-_(    //
//    MME<:~__~..~.....~....___-(++zasZY<I...j>.(z-_((._.MHHHMe_..........(L..._!!!!!(/OO/..........~~~(v _._,X~._<(:._<J>.(>._..\,KI>~{(I`..j(<r_;.M[.<(+dH    //
//    MM2:~~::~~~...~.~~_((++ugsU4M>2_ {j0. -(Z+.11~_<<[email protected]_............(J__._.mt _(_?._.(%.:<.__(f.X#wl~}(}`_.z(<}(<.NL { _,N    //
//    MMH$~::~~...~~.~_([email protected]@bjdMr{_.!zX___.k?o-1x__(-_.MHHNMHH#m,`......._i,?7777^,?!.............([email protected]~_.~_>_~j\.<J___(R<ydNzl~}z~.;_IZj!(~(Mb { ((M    //
//    ?WMMN:~~~.~.~.~_(>[email protected]@@HJZHNc_._zR{~_.w;<wGJz-____(MHMMMHHHHNJ._......._<!<~................(c.`,`.M#{_.~_/.-('.<J~~_(V(dWWMX>(G%`.~(d$z(<(dHP.} ([email protected]    //
//    <?MMMMMp(._~.~_<[email protected]_._jMy.__(W-1XJW&~_-<_XHMMMMMH#HMMN,`.....................-_(Jd^.___(MM3~.~_(_(^.(JY-((XjUdKkHMS~(2`.{(KZj><_(MM!J~_JHW    //
//    N(:~([email protected]@[email protected]@@[email protected],WNs(_.vm,<dMMN+_(_.4MNHMHHHHMMHH#a,_............__-(JxVUOv__.~.MM#=_(~_(!(<vwMAsG6XIWqWHWMM$(2 .C([email protected](XHkH    //
//    [email protected]@@@@@@[email protected]@Ma.<_~?MMMMMHHMNMHMMHNJ_..__-((JJwX0rrrrtv!--([email protected]!.jJ+2id$(u#[email protected](I([email protected]@    //
//    :WW#[email protected]@@[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]++z<<<<1wmgHNMMNMMneQMMN#[email protected][email protected]@[email protected]@@    //
//    UN+N-_~_<[email protected]@@[email protected]@@[email protected]<<<<:::~::(zQHM####[email protected]@[email protected]@@@[email protected]@[email protected]    //
//    [email protected](N?7777<<<[email protected]@@@[email protected]@[email protected]@@@@@gHHY"T7<:(?"9MHggggggggH91J>([email protected]<<<<::~::~:~::(([email protected]@@MH#M#5>_((&[email protected]@@@@[email protected]@@MNWkHQ    //
//    [email protected](N~.~~~([email protected]@[email protected]@@@@@@@@@H[email protected]@ggHY>._:~~~~~~_~~<lvTYYYB9Y(jV(dNN8<::~~:~:~::~([email protected]@@@@@M9^~(+v=<::[email protected]@[email protected]@[email protected]    //
//    ~~~~~~.~_<[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]=_:~~~~~~~~~.~~~~_1+11zzv<:+3([email protected]:~:~:~:::([email protected]@@@@@HY!_(J=~_~:::~<[email protected]@[email protected]@[email protected]@H    //
//    ~~~..~~_([email protected]@@[email protected]@HNkKY=_:~~~~~~~~.~~.~~.~~~~_1?>+v..([email protected]@MZ<::~:::([email protected]@[email protected]@HY!_(v!.......(-+<<((([email protected]@[email protected]@@@@@[email protected]@@[email protected]@M    //
//    ~~~.~~~(>[email protected]@@@@[email protected]#9=_:~~~~~~~.~~.~~.~.~.~~.~~~~<+!..(3([email protected]@@@I:~::([email protected]@[email protected]^_(v!.......(J1;;<<<<<<;>>;([email protected]@[email protected]@@@[email protected]    //
//    ~~.~~~(<[email protected]@@@@[email protected]@@@HWMHWQY"<_:~~~~~~~.~.~.~~.~~~~~~~.~.~~~:J_..(r([email protected]@@MS>::([email protected]@@@#=.(J^......`-(><<~~_..~.~~~_~<<;;[email protected]@[email protected]@@[email protected]@@g    //
//    ~~~~~_<[email protected]@@@@@@MMY"=_:~~~~~~~~..~.~.~~.~~~.~~~~~~~~~~~_J....J([email protected]@@@[email protected]@@[email protected]@HY!--=_......`-J<<~..............~_~<;;[email protected]@[email protected]@@@[email protected]@@@@@@H    //
//    ~~~~~([email protected]@[email protected]@MMHYT<_:<~~~~~~~~.~~.~~.~~~~~~~~~~~~~~~.~~~~_J....(\([email protected]@@@[email protected]@[email protected]@#=.(v!........-J<<~..................._~<;<[email protected]@[email protected]@@@HW    //
//    ~~~~(>[email protected]@HMMMT5>_:<~~~~~~~~.~..~.~.~~.~~.~~.~~~~~~~~~~~~~~_J4~....J([email protected]@@@[email protected]@@@@@@@!_(=_.......`-Jz<~~..~..~..~............._<;>[email protected]    //
//    ~~~~<jMY">_:<<~~~~~~~~~..~.~~~.~~~~.~~~~~~~~~~~~_:(<~~~~.J=(\....(%([email protected]@@@@@@HY_-J=..........(6<~~...~..~.~..~.~..........._~<;<[email protected]    //
//    ~~~<?Z<<<~~~~~~~..~..~.~~.~~.~~.~~~~~~~~~~~~~((;;;<~~~(J^._2.....(>([email protected]@@@@@#3.(J^..........-v$<~~.~......~....~~..~....~....~_<;<[email protected]@[email protected]@ggHXHHW    //
//    ~:<>j3~~~~~~..~~~~.~~.~~~~.~~.~~~~~~~~~~~:(<;>>>><~~(v!...(......(_([email protected]@@@@#=.(J!..........-(=J<~~~..~~.~...~......~..~.....~..._~<;([email protected]@[email protected]@@[email protected]    //
//    :<>>y:~~~~~~~.~.~.~~~~~.~~~~~~~~~~~~:(<;>>>>>??>1jJ^.....(\......([email protected]@@@#=.(J!...........-V_.Z>~..~.....~...~.~.................~_<;>(UHgHWgggggHWWMM    //
//    +;>J>~~~~~.~~~.~~~~.~~~~~~~~~~::(+<>>>>???>??1z7!........J.......([email protected]#=~(J!...........-(=_..0<~~.~.~.~..~.~...~.~.~..~..~.......~~~<;<[email protected]    //
//    >>j3:~~~~~~~~~~~~~~~~~~~~::(<;;>>>?>??????uv=~..........(>.......(_<M#=.(J!............(v~....0<.~~.~.~~~~.~~.~....~..~....~.~.~....~_~<;<[email protected]    //
//    >j3::~:~~~~~~~~~~~~::::;;;;>>>?????????=uY~.....~.......J........({J3._(^.......`....`-3_.....Oz~.~~.~~.___~~~.~~.....~..~......~..~.~~_~<;<?MgggHkXHW    //
//    +<;;::::::~::::::;;;;>>>>>?????>>??uggH8~..............-%........(Y..(=.......`...`.-J<...`...(z_~~~~~~+zOz+<_~~~~~.~...~.....~..~.....~~_~<><[email protected]    //
//    ;;;::::::;;;;;;>>>>>>>>???>??&[email protected]<...............(.......(J~.(C........`.....-v__.......(R>~~.~~~_;>1Oz+<_~~~~.~..~.~.~....~.~..~..~~~<<;<[email protected]    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract KG is ERC721Creator {
    constructor() ERC721Creator("Kamisama Girl", "KG") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x03F18a996cD7cB84303054a409F9a6a345C816ff;
        Address.functionDelegateCall(
            0x03F18a996cD7cB84303054a409F9a6a345C816ff,
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
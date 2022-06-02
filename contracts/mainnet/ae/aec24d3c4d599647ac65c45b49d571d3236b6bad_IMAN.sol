// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Iman Europe
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                               //
//    wmSSSSaoooo555yyyjjjj}}uYssJzzzz77TTTT\iiLLLL|||?**<<<>===+^+^^^^!!!;;;;;;;;;~~~~~~~_::,,,,,,,,,,,,,,,'''''''''''''''''''''''''........................................'''''''''''''''''''''''''''',,,,,,,,,,,,,,,,,,:::_::__:_:_::::::    //
//    mmSSSSaaooo5yyyyyjjf}uuYYsJzzzz77TTT\iiLLLL|||?*?**<<>=+++^^^^^!!!!!;;;;;;;~~~~~~~~__:,,,,,,,,,,,,,'''''''''''''''~!=i7zs77zT|^;~,......``.``..................................''''''''''''''''''''''''',,,,,,,,,,,,,,,,,::::::,,,,,,,,    //
//    mSSSaaaoo55yyyyyjff}uuYsJzzzzz7TTTT\iiLLL|||??***<<>>=>+^^^^^^!!!!;;;;;;;~~~~~~~___::,,,,,,,,,',,,,,,,,,''''~;++|zjjSPEmwkKbD%gRRbwji^~'...```````.....................................''''''''''''''''''',,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    SmSSaaao555yyyyjjf}uuYYsJzzzz77TT\\iLLLL|||?***<<<>===^^^^^^!!!!!;;;;;~~~~~~~~~~_:,,,,,,,,,''''',,,~;!^|LiTszufsziizJ}jaEXb%8Wg%gg8&&BNbf=_.``````````````..`.```.`````..................'''''''''''''''''',,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    SSaaaaoo5y5yyyjjffuuuYsJzzz777TT\\iiLLL|||??**<>>=+++^^^^^!!!!!;;;;;;;~~~~~_::__:,,,,,,,,,,,'',,;^*TYyPXkA6Sj7|?>^**=<=>izJuSKgggBQQQNWBQQBXi~.`````````````````````````````..................'''''''''''''',,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    SSaaaoo5555yyjjjfuuussJJzz7777TT\\iiLLL||??***<>====+^^^!!!!!!;;;;;~~~~~~_~__::,,,,,,',,''',:~=7m6D%gDd6L|j5yuzzzJ77z\TTL*|7ssSXdNQQQQQQQ8NQQQA='``````````````````````````````.`.`.............''''''''''''',',,,,,,,,,,,,,,,,,,,,,,,,    //
//    Saaaooooo5yyjjjff}uYsJzzzz777TT\iiLLLL|??****>==++++^^^!!!!;;;;;;;~~~~~~_~~::,:,,,,',,',',~+zXRDg8NNg%AJ*zy5}T|*?>*^*\iiiT7Y}[email protected]@QQQQQQDj!.````````````````````````````````````..`......'''''''''''''',,,,,,,,,,,,,,,,,,,,,,,,    //
//    Saoooo5yyyyyjjj}}usYsJzzz77TT\\iiLLLL|??****<=+++^^^^^^!!!!;;;;;;;~~~~~~__::,,,,,,',''''~TER#QQQQQWB%XsL\uYufJsjawa5jJL*[email protected]@@@@@[email protected]@Q6=.```````````````````````````````````.`........'''''''''''''',,,,,,,,,,,,,,,,,,,,,,    //
//    aaooo5yyyyyjjf}uuYJJJJzz77TT\\iiLLL|||?***<>==^^^^^^^^^!!!;;;;;;;;~~~~~_::,,,,,,''''''~=J%&BQ#WDay6RAs**zjYTJujjyowj}[email protected]@@@@@@@[email protected]@QK>.` ````````````````````````````````.`.........''''''''''''',,,,,,,,,,,,,,,,,'',,    //
//    aooo5yyyyjjjf}}uYszzzzz77TTTiLLLLL|||?**<<>==+^^^^^^!!!!;;;;;~~~~~~~~:::,,,,,,''''',~;jDgBgDkfYujmXb5|<ijySADR%%%RdXjs7<*[email protected]@[email protected]@[email protected]@@@Q%*.`  ````````````````````````````````..........''''''''''''''''''''',',,,,'''''    //
//    oo555yyyjjjf}uuYYsJzzz7TTT\\iLLLLL||?**<>==+=^^^^^^!!!!;;;;;~~~~~~_::,,:,,,,,,,,',,;\XRbDqkyT7joSXAE7+^TySXKKdbKDdKXXAKKXm}[email protected]@[email protected]@[email protected]@@@@@@Qy,`  ``````````````````````````````````.........''''''''''''''''''''''''''''''    //
//    o5o5yyyjjjf}uuYYsJzz777TTT\iiLLL|||?**<>>===^^^^!!!!!!;;;;;~~~~~~__::,,,,,,,,'''':>oRbkKayjyjmyjmw}L^;!LsujYJz7faX6AADgWB#[email protected]@@[email protected]@@@@@@@@QQK;`           ```````````````````````````.......'''''''''''''''''''''''''''''    //
//    o55yyyjjjj}}uYsJJzzz77TTT\\iiLL|||??*<<>==+^^^!!!!!;;;;;;;~~~~~~~_:,,,,,,,,,''''_iw%dE5fjYJ}fjyjsz7?;~;;>7z|*|?>isok6KRg&&[email protected]@[email protected]@@@@@@@@@Qg>`             `` ``````````````````````...........''''''''''''''''''''''''    //
//    5yyyyyjjffu}uYJJzz77TTTT\\iLLL|||?**<>>==+^^^^!!!!!;;;;;~~~~~~~~~::,,,,,,',''',;iakaSEEPkmajy}i*=>^;~,::~;^^+!^=*?|iz}[email protected]@[email protected]@@@@@@@@@@@QQL`               ```````````````````````````.......'''''''''''''''''''''''    //
//    yyyyyjjf}uuuYsJJJ777TT\\iiLLL|||?***<>>>=^^^!!!!!;;;;;;~~~~~~~~_:,,,,,,,''''',;|uyodgWWRDm5L!~'',~'.'''',,,:~;^=*|LiT7JsuyoPkXAdgN#%[email protected]@@@@@@@@@@@@@@@@@@@@QQi'                  `````````````````````````.......'.''.''......''''''''    //
//    yyyyjjff}uYYYszzzz77TT\iiLLL||||***<=+=+^^^!!!!!;;;;;;;~~~~~~~_::,,,,,,,''',~!LfE%QQQQQWX\|~,..,'`    ```.'',:~!^!^<|\[email protected]@@@@@@@@@@@@@@@@@@@QN?`                  ```````````````````````````.........................    //
//    yyyyjjf}}uuYsJzzz7TTTT\iLLL|||??**<>==+^^^!!!!!;;;;;;;~~~~~_~~::,,,,'''''',;[email protected]@@QQ%yy^```.`           `.'',,~;;;^<|i\TzzuoamPqKRg8&[email protected]@@@@@@@@@@@@@@@@@@@QR:                       `````````````````````````......................    //
//    yjjjjf}uuYssJJzzz7T\\iiiLLL|?|***>===+^^^^!!!!;;;;;~~~~~~~~~_:::,,,''''',:;[email protected]@@@@QQqju^.`                  `..',_~;!^<?|L\7ufyowXKDgQQbX#@@@@@@@@@@@@@@@@@@@@Q5'                          ```````````````````````.`..................    //
//    yjjjf}}uuYssJzzz7Ti\\iiLLL||??**>=>=+^^^^!!!;;;;;;;~~~~~____:,,,,,,'''''~^[email protected]@@@@@@Q6zL;'                     ``'':~;;!^=**|[email protected]@@@@@@@@[email protected]@@@@@@@Q#L`                          ```````````````````````````````.`````.....    //
//    yjjff}uYYssJzzz77T\\\iLLLL||?**<>===+^^^!!!;;;;;;;~~~~~~__::,,,,,,,''''[email protected]@@@@@@QS7!'                        `.',~~;;!^^+<*Li7Jf5PKg&QQQAb&[email protected]@@@@@@@@@@@@@@@@QQR!.                             `````````````````````````````````..`..    //
//    yjjff}}YssJzzzz7TT\iiiLLL||??*<>====^^^^!!!;;;;;;~~~~~__:::,,,,,''''',[email protected]@@@@@@Qm\~`                          `.':~;;;!^^+>*|L\[email protected]@@@@@@@@@@@@@@@@@QQQS,`                              ````````````````````````````````````    //
//    jjff}}ussJJzzz7TTTiiLLLL||??**<>>==^^^^!!;;;;;;~~~~~~~__,:,,,,,,'''''[email protected]@@@@@QQBj~`                            `'',~;;;;!^^>*|i7uywq%[email protected]#[email protected]@@@@@@@@@@@@@@@@@QQQi'`                               ``````````````````````````````````    //
//    jff}uusssJzzz77T\\LLLLLL|?***<>==+^^^!!!!;;;;;~~~~~~:::,,,,,,,,'''''_;|[email protected]@@@@@@@@k:`                             ``'',~~~~;;!^=*L7sjSXD#[email protected]%[email protected]@@@@@@@@@@@@@@@@QQQR^'                                 ````````````````````````````````    //
//    jffuYsYsJzzz777TiiiiLLL|?***<>==++^^^!!!;;;;;~~~~~~~::,,,,,,''''''''~;[email protected]@@@@@@@Qi.                                `.''''''',~;^*[email protected]@[email protected]@@@@@@@@@@@@@@@@@QQQk;`                                  ``````````````````````````````    //
//    jfuYYsYJzzz77TTTiiLLL||??***<>==+^^^!!!;;;;;~~~~~~~~:,,,,,''''''''''_*[email protected]@@@@@@@@K!`                                      `.,~;^!^[email protected]@@@@@@@@[email protected]@@@@@@QQQQf,                                     ```````````````````````````    //
//    }}}YYYJzzzz777T\iLL|L|?****>===+^^^!!!;;;;;~~~~~~_::,,,,,,''''''''''[email protected]@@@@@@@Qa,                                    `~;^?Tsy555yjjymkD#QQ8qk&[email protected]@[email protected]@@@@[email protected]@@@@@QQQ#s`                                   ````````````````````````````    //
//    }}uYYsJzzzz7T\\iiLL|||***<<>==+^^^!!;;;;;;;~~~~~~::,,,,,'''''''''''';[email protected]@@@@@@@QR'                                  '~>L7T!_',~;^|zyPqqb%&[email protected]@@@@@@@[email protected]@@@@@QQQ%!                                        ```````````````````````    //
//    f}uYszJzzz7TT\iLLL|||?***<>==++^^!!!!;;;;~~~~~~~_:,,,,,,'''''''''..';[email protected]@@@@@@@@Q,                                ,;<i|=:     `',~;!|YwbDD&qW#Q#[email protected]@@@@@@[email protected]@@@@@@QQQm.                                       ``````` ```````````````    //
//    uuussJzzzz7TT\iiLL||?**<<>=++^^^^!!!!;;;;~~~~~~_:,,,,,,''''''''''[email protected]@@@@@@@@@+                               ';^+;~,'`..'_~;^=+<|\[email protected]@@[email protected]@@@@@[email protected]@@@@@@QQQ&z`                                          ``        `````````    //
//    uuYJJJzzz77T\iiLL|||***<<>=+^^^^!!!;;;;;~~~~___::,,,,,''''''''''....'*[email protected]@@@@@@@@7  ,~:'.`                      ``'',:,`  `,;*L\sjju}[email protected]@B%[email protected]@[email protected]@@@@@[email protected]@@@@@@@QQQD!                                            `         `     `    //
//    YYYszzz777TT\iLL|||??*<>==++^^^!!!!;;;;~~~~~__::,,,,,''','''''.....`';[email protected]@@@@@@@y';_`    `'''`                ```.`    `;[email protected]@[email protected]@@@@@@[email protected]@@@@@@QQQQa'                                                                //
//    YsYszzz77TTiiiLLL|??*<<>+=+^^^^!!!!;;;;~~~~_::::,,,,''''''''''....``',ug&@@@@@@@@K'                           `'.`   .~>saD#[email protected]@@#[email protected]@@@@@@@[email protected]@@@@@@QQQg*.                                                               //
//    ssszzzz77TT\LiLLL|***<>>=+^^^^!!!!;;;;;~~~___:,,,,,,'''''''''.....`.',^[email protected]@@@@@@Q,          ````.`          .~^,  `,>oi,\[email protected]<A%[email protected]@[email protected]@[email protected]@[email protected]@@@[email protected]@@@@@@@QQNj,`                                                              //
//    ssJJzzz77T\iLLLL|??*<<>==+^^^!!!!!;;;;~~~~___:,,,,,''''''''......```'.~}g%@@@@@@@@s'_~;~~!|=>|^>>?^;~`       ,!L!`'.'^    ~mX6S|7oXbz;~~;>\}[email protected]@@@@@[email protected]@@@@@@@@@@@@@QQA*'                                                              //
//    sJzzzz777TiiLLL||?***<>=>+^^^!!!;;;;;;~~~:::,,,,,''''''''''..'.``````'';[email protected]@@@@@@WLiYX%gW6XQQQQgdP}*.       ,^\L~._;       ^\77sj57;'',~;[email protected]@@@@@@@@@@@@@@@@@@QQ8\;,                                                             //
//    YsJzzz7TTTiiLLL||?**><>==^^^^!!!;;;;;;~~~_::,,,,,''''''''''..'.`.````.`'z&[email protected]@@@@@@@uYXg#&\  LKD%dk*~         .^ii^,`      ``,~!^^!~'```':~^|smb&[email protected]@@@@@[email protected]@@@@[email protected]@@@@@Q&k!,`                                                            //
//    Jzzzz777TTiiiL|||**<<>===^^^^!!;;;;;~~~~~_::,,,,'''''''''''...``````````[email protected]@@@@@@s   `<+    *ju>!;'        `;?L<~'         ```      `',~!*[email protected]@[email protected]@@@@@[email protected]@@@@[email protected]@@@@@QQgL~'`                                                           //
//    Jzzzz77TTTiiiL||?**<>===+^^^!!;;;;;;~~~~~_:,,,,,,''''''''''..```````````[email protected]@@@@@@z     ````  `',,`         `~^>^;,`                 `',[email protected]@@@@@@[email protected]@@@[email protected]@@@@@QQgo!'`                                                           //
//    Jzzzz77TT\iiL||?***>>>>++^^^!!;;;;;;~~~~~_:,,,,,,''''''''''..````````````'*[email protected]@@@@@?                         `~^^^;~'`                `',~;[email protected]@@[email protected]@@[email protected]@@@@@@@@@@Q#XL~.                                                           //
//    zzzzz77T\iLL|||??**>>==+^^^!!!;;;;;;~~~~_::,,,,,'''''''''....`````````````~u%[email protected]@@@@^                         .;?iL+;:.                `.,~;[email protected]@[email protected]@@Q&@@@@@@@@@@@QQqj+~`                                                          //
//    Jzzz77TT\iLL||???**>>=++^^^!!!;;;;;~~~~__::,,','''''''''.....`````````````,^[email protected]@@@^                         ,^Tuj}7=:`               `.'~;[email protected]@[email protected]@@@@[email protected]@@@@@@@@@QQ&wu^,`                                                         //
//    Jzzz77T\iiLLL|???*<>=^^^^^^!!!;;;;;~~~___:,,,,,''''''''....```````````````';[email protected]@@*                         ,+7}j555Y^`              `.'~;[email protected]@[email protected]@@[email protected]@@[email protected]@@[email protected]@@@QQQRSJ;'                                                         //
//    zz77777\iLiL|?*?*<<=++^^^^^!!;;;;;;~~~__:,,,,'''''''''.....````````````` `[email protected]@S                         '!|L|<^=uw6y^`          ``',~^*\[email protected]@@@@[email protected]@@[email protected]@[email protected]@@@@QQQRy7:`                                                        //
//    z77777T\iiLL|???*<<>=^^^^^!!!!;;;~~~~~_,:,,,'''''''''.....`````````````  ``,|o%DBQQQ'                        `;<=!~~;?u5AKP?         `.,~;^[email protected]@@@@[email protected]@@@[email protected]@@[email protected]@@@QQQ#q}*,`                                                       //
//    zz777TT\iLLL|??**><=+^^^^^!!!;;;~~~~~~_,,,,,,,''''''''....`````````````  `.';76KgBQQo                        .!|zkR6|,+zPq6j.      ``',_;!<[email protected]@@@[email protected]@@[email protected]@@[email protected]@@@QQQgEi~`                                                       //
//    zz7777T\iiLL|?**<>>+=+^^^!!!;;;;;~~~~_:::,,,,'''''''''....````````````    ``,*XPbW#QQ^               .*s*`  ._>syEKqS+*T\*;`      ``',:~;+|7Yj5EAR&[email protected]@@@[email protected]@[email protected]@@[email protected]@@@@QQQBR}|:`                                                      //
//    zz77TT\iiLLL|??**<==+^^^^^!;;;;;~~~~_:::,,,,,''''''''....`.`````````````` ``'>jKEDgQQN,               ,!'        `~^!~'.`````    ``.',~;^*[email protected]@@@[email protected]@[email protected]@@[email protected]@@@@QQQNKi?_`                                                     //
//    zz777TTiiLL|||?**>=++^^^^!;;;;;;~~~~__:,,,,,,'''''''......``````````````  ` `~zE66RBQQD.                          .:~~~_,,,,'.````'',~;!+|[email protected]@@[email protected]@[email protected]@@[email protected]@@@@QQQQgy>;'                                                     //
//    zz777T\iiLLL|??**>=^^^^!!!!;;;;;~~~~_:,,,,,,'''''''....`````````````````    `,|o6kKgQBQK`                         `':~~;;;;~~,'''',:~;!^[email protected]@@[email protected]@[email protected]@@@@@[email protected]@@@QQQQ#k*_~'                                                    //
//    z77TT\iiLL||?***<>=^^^^!!!;;;;;;~~~~_:,,,,,,'''''''....`````````````   `    ``*jAq6dgBQQd                        `.',~;!+=>+!;~:,,:~;;^<L7Yj5SwkAb%&[email protected]@@[email protected]@@[email protected]@@[email protected]@@@@@QQBRT~~~,                                                   //
//    z7TT\\iLLLL|?**<<==++^^!!!;;;;;;~~~~:::,,,,,''''''''...`````````````  ``   ``.;LPDDKgQQQQd,               `    ~_:~~~~_~!>izz|^~~~~;;!+|TJfyoawkXKR#@@@@[email protected]@[email protected]@@@@@[email protected]@[email protected]@@QQgA=;'.`                                                  //
//    z777T\iiLLL|??**<==^^^^^!!!;;;;;~~~~_::,,,,,''''''''...`````````````````    `';|SqgqD#QQQQ&^           ``      `..',,;!+iYyaw*!~~~;;!^*iz}[email protected]@@@@[email protected]@@@[email protected]@@@@@[email protected]@@@QQ&Ru;,``                                                  //
//    z777T\iiiLLL|?***==+^^^^!!!;;;;;;~~~~:,,,,,',''''''....````````````````    `.'!7wmbXq##[email protected]`        ',       `'~,~^7JzJfwj^';~~~;!^*[email protected]@@@@@@[email protected]@@[email protected]@[email protected]@@@[email protected]@@@@QBWXi~' .                                                 //
//    zz777T\iiLLL|?***<===^^^!!!!;;;;;;~~__,,,,,,,'''''''....``````````````  ````'~^[email protected]@@k.      ';   ';`      `  `:<fa7?|^~~;;^<[email protected]@@@@@@@[email protected]@[email protected]@@@[email protected]@@QQQQRo+,``,                                                //
//    zz77TTTiLLLL|??**>==+^^^^!!!;;;;~~~~__:::,,,,,''''''''...````````````` `` `'~?y5E5AAK%[email protected]@@R,                      '^YoyjyY^;;;!^|[email protected]@@@@@@@[email protected]@@[email protected]@[email protected]@[email protected]@@QQQNbu;` '.                                               //
//    zzzz77TiLiLL|??**<>==+^^!!!;;;;;~~~~~~_::,,,,,'''''''''...````````````````,^[email protected]@@@&;                    .+foyyyoJ+!!^=?iJ}[email protected]@@@@@@[email protected]@@[email protected]@@@[email protected]@[email protected]@@QQQgy|,...`                                              //
//    zzzz7T\iiiLL||?**<>>=++^^!!!!;;;;~~~~~__:,,,,,'''''''''..`````````````` `,[email protected]@@@@Q^                  .^syyyy5}*^^^[email protected]@@@@@@[email protected]@@[email protected]@@[email protected]@[email protected]#Ks^,''``                                             //
//    zJzz77\\iiiLL||?**>>=+^^^^!!!;;;;;~~~~~_:,,,,,'''''''''.'..`.```````.```^[email protected]@@@@@@Qi        `      '~*Y5ayJL+!;!^=*L7sfjy5aSEbg8#[email protected]@@@@@[email protected]@[email protected]@@[email protected]~''``                                             //
//    Jzzz777\iiiLL||?*<>==+^^^!!!;!;;;;;~~~~~_:,,,,,''''''''....'.`.````..`;zbgQQQDAwy6dQQ&[email protected]@@@@@@@o.            `'',,,'..,_~;!+<L7Yfjy5amXDR%8#&[email protected]@@@@@[email protected]@@@[email protected]@@@QQQQQQQQQQQQQQQR6i':`                                              //
//    Jzzz7TT\iiiLLL|?**<>>=+^^^!!!!;;;;;;~~~~~:,,,,,~;;!^>|z77fkdD%DKkEk6XbQQ88WDKKKKbg#[email protected]@@@@@@@@@Q*                  ``',~;+?iJ}[email protected]@@@@@@@[email protected]@[email protected]@@@QQQQQQQQQQQQQ#gE?;~.                                             //
//    sJzzz77TiiLLLL|??**<>>=+^^!!!!!;;;;;~~~~_,_~~;;;;;!^>|7fa6bRg8BQQQQQQBg%g8&NWN&[email protected]@@@@@@@@@@@k'                `.':;^?\J}jyom6dRDDDDRg88#[email protected]@[email protected]@@@[email protected]@@@@@@@@@[email protected]@@QQQQQQQ#%a+;,`                                            //
//    sJzzz7T\\\iiLL|?|***><=+^^!!!!!;;;;;~~~_~~~_,:,:~~;;!^*[email protected]@@@[email protected]@@[email protected]@@@@@@@@@@@@@@@@@@@N|`             `.',~!?\J}joE6KbdddddbDRWWN&B&[email protected]@[email protected]@@@[email protected]@@@@@@@@@@@@[email protected]@@@@QQQQQ&gmi^`                                            //
//    sJzzz77\\\iLLL|||**<>>==^^^!!!;;;;;;~~~~,''.```..',_~;!=L7jmADgN&[email protected]@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@QQA;          `.',:~!*7YjSkqKKbKKbKbKKDRgW8#&[email protected]@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@QQQQQ%5z;`                                           //
//    sJJzz77TT\iiL|||?****>==^^^^!!!;;;;;;~,.``        `.',~;^|TuoPdg8#[email protected]@@@@@@@@@@@@@@@@@@@[email protected]@@@QQQ8k ``.`..'',,_~;!=?|fm6KKqqqKKKKKKKKdD%[email protected]&68%[email protected]@@@@@@@@@@@[email protected]@@@@@@@@@@@@@QQQQQ86Y;`                                          //
//    ssJzz7T\TT\iLLL|??***<>=+^^^^!!;;;;;,.``           ``.':~!<iJjmqDg8&&[email protected]@@@@@@@@@@@@QQQQQQQQQQQQQQBQd~^ `` ``.....``    `,!isywXX6A666X6qKgQQQRk6jq                                                                                   //
//                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract IMAN is ERC1155Creator {
    constructor() ERC1155Creator() {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC1155Creator is Proxy {

    constructor() {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x142FD5b9d67721EfDA3A5E2E9be47A96c9B724A4;
        Address.functionDelegateCall(
            0x142FD5b9d67721EfDA3A5E2E9be47A96c9B724A4,
            abi.encodeWithSignature("initialize()")
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

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
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}
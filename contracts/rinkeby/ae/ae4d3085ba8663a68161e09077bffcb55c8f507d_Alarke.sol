// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alarke
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                            //
//                                                                                                                                                            //
//                                                                                                                                                            //
//                                                                                                                                                            //
//                                                                                                                                                            //
//                                                                                                                                                            //
//                                                                ``',_~~~~:'-`                                                                               //
//                                                        .:;=cuaXd%WNNNNNNN8%bEz=:`                                                                          //
//                                                   ';Lj6%NNNNNN####NNNNNNNNNN#NN8Kj>,                                                                       //
//                                               `;\E%NN##N########NNNNNNNNNNNNN####NNWXi_                                                                    //
//                                            `;zKNN##NNN##NNNNNNNNNNN#NNNNNNNN##NNNNNNNNWE!`                                                                 //
//                                          '|UNN#####NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNRyz!.                                                               //
//                                        `7DNNN##N###NNNNNNNNNNNNNNNNNNNNNNNNNNNNNN###N#WEjjfz;`                                                             //
//                                      `LD###N#NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNgw}xzJfjz:                                                            //
//                                     'mNNN####NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNRSY77zxjjjI~                                                           //
//                                    ,X#N#####NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN##NNN#8qyjIz{IxtxfjJ`                                                          //
//                                   -wNN#NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN##NNNdZjj}u{xzzz}}Iz~                                                          //
//                                  `zN####NNNNNNNNNNNNNNNNNNNNNNN#N####NN######NNDwj{tzJff}}}YtzzJ?                                                          //
//                                  ^MNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN#N##NN##NNNNREjjfz7zIuxtzzztY}Ii.                                                         //
//                                 'U#NNNNNNNNNNNNNNNNNNNNNNNNNNNNNN###NNNN#N%Hk5yj}xIIxz7ztIu{YJzzI~                                                         //
//                                 zNNNNNNNNNNNNNNNNNNNNNNNNNNN####N#NNNNNDUwyy5o5y}xIxxJIYItzzztY{z;                                                         //
//                                ~%#NNN##NNNNNNNNNNNNNNNNNNNNN#NNN##N8DAm55555555oyuJz777zxY{{}uz7z=                                                         //
//                               `jN#NNNNNNNNNNNNNNNNNNNNNNN##N####8dXZy5o555555555yj{}uIIIxtzzztIuz=                                                         //
//                               =8#NNN####NNNNNNNNN###N##N#N#N8DAw555555555555555oy}tttIIY}}f}z77z{+                                                         //
//                              `EN###NNNNNNNNNNNNNNNN##NNN8RKhay555o55555555555555yyjjuIjjjjjjj}It};                                                         //
//                              ~R#NN##NN%N#########NWRbAXway5555555555555555555555yyjx7z{jjjyyyjjjv.                                                         //
//                              *N#N##N#WZawk6EEXEEmXXwXEEy5555555555555yyawS555555yyjY7J}jjy55yyj},                                                          //
//                              fN##NNNNNS5EU%dqHyyqBQ%QQQbay55555o5555ZqqUhEUUy555yyjju}jjyyy5yy}^                                                           //
//                             'qN#N#QQBNSyHWQQQbZqS6QQQQ%E555o555o5y5ADwjjjjSDy55oyyjjjjjy5555y5z`                                                           //
//                             ;WN#NNQQN8bUySqR8h%QdSZq%Uyo5yZUKDDR%RBBddqkyjDUy5y5555yyyy55o55EU~                                                            //
//                             LNN##NNBQQDQQQNDXDQQhUUayy5aqWQQN%WQQQQU?iYSNDXy55555555555555oqM=                                                             //
//                             jNNNN#NNNw;bQQwEQQQQDySUUmyDQNKi;;JQQQQk``_SNm5o55555555555o5kRNI`                                                             //
//                            `kNNNN#N##RqDNM%QQQQQQUyyakUUUwkhXy7h%N8y\aKyikEy555555555owARN#6'                                                              //
//                            ,D#NN###NBdqMQQQQQQQQQQH5555ohUDES6qqqUUSYi>>>?Uky55555555A###NM^                                                               //
//                            !W##NNBWqaffjSD%R%WQQWDDky55555Zq*>==>>>>>>>>>>*Xk5555555U#N##Nx                                                                //
//                            ?NNNQ%hjjjjjjjjjjjyoyjjjjy55555ybE>>>>>>>>>>>>>=|q555555oR#N#ND:                                                                //
//                            7N##Xjjjjjjjjjjjjjjjjjjjjjy5555yoDy>>>>>>>>>>>>>>zUy5555ZW#NNNz                                                                 //
//                            xNQdqUXkEhEEEwEEkhhkkEEkwwSy555o5ody>>>>>>>>>>>>>*Dy5555aMNNND:                                                                 //
//                            zNN#BNDUajjjjjjjjjjjjIzztxJzJYj5555bm*>>>>>>>>>>>?Uy55555D#NNx                                                                  //
//                            |N###NN#B%HwyjjjjjjjJiiiiiiii\czy555UqY*>>>>>>>>>uSy5555yX#NM;                                                                  //
//                            !8#######N#BNDKq6UhhyyZARRDwyyjYjqH55aUUaz?>>>>ijEy55555o5D#A-                                                                  //
//                            ~%#NNNNN##NWHXESwhkXhj7xoaj\izaXAXmy5555ZXUhwwEkay55555y55S%y                                                                   //
//                            'dNNNNN####NMUa555555jzc\i\czj5555555555555555555555555y555mi                                                                   //
//                            -qNNNNNN##N##NgqS55o5o5jjfjy5555555555555555555555555555555yc-                                                                  //
//                            `hNNNNNN##N##N#NNRqEay5555o55555oo555555555555555555555555555z,                                                                 //
//                            `mNNNNNNNNNN##N##N##8%dqXkXUqbD%MWM%dUS5o55555555555555555555yu;`                                                               //
//                            `h#NNNNNNNNNN###N#NNNNN######N#N###N##8Hay55555555555555555555oy\~`                                                             //
//                            'KNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN#RZy5555555555555555555555yv;`      .'''''`                                              //
//                            ~%#NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN##dy555555555555555555555555yI;- ';;_,'''',!+,.                                          //
//                            ^8#NNNNNNNNNNNNNNN#####N##N##N########NNNdy555555555555555555555555555j}y!'  `~'``:!``''                                        //
//                            iN#NNNNNNNNNNNNNNNN#########N###N#NNN#NDX555555555555555555555555555oo5aRyj7>;?~:~,`   ~^`                                      //
//                            jN#NNNNNNNNNN###NNNRKAXUAqqqbW#N#NNWDAmy55555555555555555555555555oo555aW55555j?~`   -;;~,,`                                    //
//                           'A##NNNNNNNNNNNNNWAXqEAR%M##N%DDMD6Eayy555555555555555555555555y55ooEWXqWby555555yz!-``;`  .~-                                   //
//                           ^WN#NNNNNNNNN#NNHhd##%dhA%#NNNDq%ayo55SX555y555oo5o5oooo5oo55555555oUMUXay555555555y{7;'    `~,                                  //
//                          `SN##NNNNN##N#NRw6NWDD#R6RbD%ASy5mWdAUd8QXy5555ok55o555hZ5o555XNHXSSXWh5555555555555555Y;  ,;',;,                                 //
//                          iN##NNNNN###NNbUMRqmDN#N#RkU555555yawwaym8bwZZANWDa555kQ%bXhqDRZySkUhy5555555555555555555>``~`  :'                                //
//                         ~DN###NNNNN#NNUU##NqHRAK##dyy55555555555oyo6DDD6aykdqAqWEywAqXay55555555555555555555555555yv;,   `~`                               //
//                        `yNN##NNNNNN#NUUNNN#NR6XN#%Sy55555555555555555555oo5yakkoy5555555555555555555555555555555555y|` ,;-,;                               //
//                        ?W#N###NNNNNNAENWX%NN#qD#WEy55555555555555555o55555555555555555555555555555555555555555555555y^`~,',^.                              //
//                       ;DN#N###N#NN#dkHq66##MN%qDqy5555555555555555555555555555555555555555555555555555555555555555555j|,   ,,                              //
//                      -HNNNNNN##N#NMw%##MdMAZkfL!z555555555555555555555555555555555555555555555555555555555555555555555\`   .~                              //
//                     ,wN#NNNNN##NNNUANDkj=;!*`  .z5555555555555555555555555555555555555555555555555555555555555555555557.,:`.^`                             //
//                    ~AN#N#NNNNNNN%q}+,`    `^~``_f555555555555555555555555555555555555555555555555555555555555555555555x'.;'';'                             //
//                   +DNN%bkj7i>;~,'Lz' ;!    `~;;!t555555555555555555555555555555555555555555555555555555555555555555555x,,'  ':                             //
//                  ~L=;~-`        _*;r+i>``r-    `Ly55555555555555555555555555555555555555555555555555555555555555555555t,``. `~                             //
//                                `>'   `!;;;+-   `i555555555555555555555555555555555555555555555555555555555555555555555J'`,_,-;-                            //
//                                _z,        '^^;~=x}jy555yyy555555555555555555555555555555555555555555555555555555555555z:'  `-;~                            //
//                                =i=,.:^-     `':^izzzJzi\vzzfyy5y555555o555555555555yjjjy5555yyyy555555555555555555555y>   .  ,~                            //
//                               'i'`:~~?,`;^`   ,+iv7cL=zyyy{*7z7777777zzzJJxxIYu{}t\ic7zzzYz\7zzzz}55y555555555555555oy^` `+~-~~                            //
//                               ~=` `' .~~,!_  .Lzxjyjfc7yo5yLfy55yyyjjjj}{YIxJzL=*7}y5oy{?^|J}jyy}ij555555555555555yo5y|=;~~`'~~                            //
//                               ;>,~=*`    `~;;\y5uzj55fif555ix5o55555555555oy{iiIy5oyfziizxtzz77i*+ijy555555y555555555j;` `   `~                            //
//                               +;'`'>'`;!   `?y55yxvy5y77y55c7y555555555o55{iL}y55jzi\zjy5yyYzc\\zi+>zy555555555555555L`       ~`                           //
//                              `>-   '~~;L`  ;j5y55yzzyojL}55ziy5555555555j\Lty5yIvizjy5yY7\\7xjyy5y}Lr|uy5o5555555555j~'.   `` :'                           //
//                              '>``~`    ,=~;x555555ycx5yzcyoY|j55555555yzLzyyfvi7}yyjJci7Yjy555555o5yt*+\j5555555555yi'!;' `;!`'~                           //
//                              ;\;=L:     `'Ly555555ojc{5jLI5j|}555y5oyILcfyu\i}yyjz\\zjy55555555555555jv=>7jy5o55555y^:-`'''`._;;                           //
//                              ^>:`_^``~~  -J5555555oof\{yziyyLt555o5}i\{jtccYyjz\\zjy5o55y55555555555555jv>=i}555555|`          ~`                          //
//                              ;'   `,_;=` :j5555555555jcIjLIyvcy55jci}jzixyjzicYyy555555555555555555555o5yz?^?7z{y5J' `~`  '`   ~'                          //
//                             `^-.~`    ,^;?y55555555555j\I7iytLyyxLzfzizj{ci7f555555555555555555555555oyIi??zjyjJzx=',;*' '=^- `^:                          //
//                             .*!^7,      ';}55555555555j7Lz|j}|Y7iuzizjxiiIy555555555555555555555555oyxi>*7jy5555yu,'. `_~,``,:~;~                          //
//                             ,;` ;!` ,L,   ^yyj5555555uzz*?|xjL>czi7}z|>zyoo55555j5555555555555555yIv*+?zj5555y55y*   _`  ``    `;`                         //
//                             ~~   ,;;;!+`  'tjcIy555fzz7*zz>Lyjx\\{zL\I\itjy5o55yv{y5555o55555yy}7L*?\Yy5oo555y5oj~`'~=~ `!r`   .>.                         //
//                             !'   '`   ,;~~!;*uzjy{zztLi}yyz={}izJ|i}y5yt77JYj555Jcy5555555y}tz\||ixy55555555555Y!_,' `,~~',;~:~;^'                         //
//                            `|r',+L.   `      ~7>*\7iiIy555y??L\i\xy55y55jxzc\ztJz|7IIxttz7i|Liczjy5555555555yoy!         `  `..`~:                         //
//                            '^'_,`;;''^?`    `;: `!zjy555555Y>|7jy555555555yjuzzz7?*icc7777zujy5555555555555555\`    ,'  '^~,--;;;;                         //
//                            ~~     -,~'!!` `,;-  ,>I555y555oyjyy55555555555555oyyu*xyyyyy555o55555555555555555f~`;~',;~:,~. `''` -^`                        //
//                            ^;   .~`    '~~:'   'z|7y55555557ij55555555555555555f|7yo555555555555555555555555y=`~_.'`   `   `_`  :|-                        //
//                           `*!;;;;L,   ',   ~+`'zyLcy5555555jtj55555555555555o5f?7y555555555555555555555555557;:`     `^;``.;!,',.~~                        //
//                           ~!     ,^;~^=L,'!!=!|yyiiy555555yj55o5555555555555oj|cy55555555555555555555555y55\'  -^;.`'!,.,,,'     `;`                       //
//                           ^' '*,   ``` `~~. `^j55cLyo55555f>zy55555555555555yLij5555555555555555555555yo55z' '~_`-~~,`        :- `^,                       //
//                          ,|!!!^>`  -!'  '`  `|y5y7Lj5yy5yyy{jy5yyyyyyyyyyy5yJLjyyyyyyyyyyyyyyyyyyyyyyyyyyf^,_'`     '`  `^^~~;;;;~^!                       //
//                          ``    -`  -'`  '`   ',,,'',,,,,,,,,,,,,,,,,,,,,,,,,'',,,,,,,,,,,,,,,,,,,,,,,,,,,'          -.  `-`'.`    `-                       //
//                         .::::::::,   ':'                 -::::::::-          ,:::::::::::::,    `,,`         `,'     ,:::::::::::::'                       //
//                        'gQkwwww%@Q'  [email protected] [email protected]:         [email protected]%[email protected]@x    ,[email protected]^        `[email protected]    ,[email protected]=                       //
//                       `[email protected]=     \@Q'  [email protected] [email protected]     ^Q%'        [email protected]!        [email protected]`    ,[email protected]^        }@j`    ,[email protected]^                                   //
//                       [email protected] [email protected]'  [email protected] [email protected]      *@q.       [email protected]!       >@K.     ,[email protected]^       [email protected]`     ,[email protected]^                                   //
//                      ;@u       [email protected]'  [email protected] [email protected] [email protected]`      [email protected]!      ;Q8'      ,[email protected]^      *@b-      ,[email protected]^                                   //
//                `````;Qb,'''''''[email protected]'  [email protected]        `''''''''[email protected]}''''''',[email protected]{''''''[email protected]*''''';QQ='.     ,[email protected]|'''''>QQ;'`   `,^[email protected]|''''''''''`                        //
//               >[email protected]@Q'  [email protected]        `[email protected]#@%[email protected]@@[email protected]\    ,[email protected]@=  [email protected]@DmSmmmmmmmmj'                       //
//                   ,#Q~         >@Q'  [email protected]         `[email protected]*    [email protected]*         `[email protected] [email protected]!         `[email protected]=   ,[email protected]^         '%Q;   ;@@^                                   //
//                  'RQ!          >@Q'  [email protected]``````````,NQ!   [email protected]*          [email protected]=   [email protected]!          '%Qr-';@@^          ,QQ;-'[email protected]@?-------------`                     //
//                  c%>           ;%U-  z%D66666666666d%E-  |%!           'XU'  XD~           :HDdbd%R~           ;dDbdD%%Dddddddddddddd*                     //
//                                                                                                                                                            //
//                                                                                                                                                            //
//                                                                                                                                                            //
//                                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Alarke is ERC721Creator {
    constructor() ERC721Creator("Alarke", "Alarke") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x80d39537860Dc3677E9345706697bf4dF6527f72;
        Address.functionDelegateCall(
            0x80d39537860Dc3677E9345706697bf4dF6527f72,
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/Proxy.sol)

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
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
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
     * If overriden should call `super._beforeFallback()`.
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
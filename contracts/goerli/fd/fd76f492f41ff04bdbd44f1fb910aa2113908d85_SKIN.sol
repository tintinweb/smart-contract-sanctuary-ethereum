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

pragma solidity ^0.8.0;

/// @title: Under the Skin
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    +x#####X----==+++=+xx===++xxX++++++++++xxxxxX+..-=;.,,,,;,,,;;;;;;-;----------=-------------------+xxxxX#XXxX##xX#x+X##x    //
//    ++####x---;--====+x+==--==-==---;----------==+-;,,,,.........,,,.,,,,;,;;;;;;;;;;;;-;-;;;;;;;;;;;;-++++xxXxxxX##xXx++xXx    //
//    +-###X,;--==+x++xxx+x+=-=-=----;----;;;;;;---;;-==---,,,,,;;;;-;-;--------------------------------=+xxx++xXxxX###XXXxxXX    //
//    =x=,=-;++Xx#####Xxxx=;.................,.,.,.,,,,,.-#..+=;;;;-;----------=---=-=-=-=---=-------=---=xX#########x+x###XxX    //
//    =xxx=+=+#xXXX##X#######X+==;;,,.................,.,.+=..x=---;-;--------------=-===-=-=-========+X#############+++x###XX    //
//    =xX#+#xX#xx#XXx##xxxxxXX+xxx++++++==----;;,,,,,,,;,;=x..==---;;--------------==-----------;-;;;;-xxXXX###########xxX##Xx    //
//    =Xx#####X+xX#XxxXXx+++xxxx#####Xx+xxXXxxxxxxxxx+x+xxx+x+=++==x+===++++xxxXXxx+++xxx+xxxxxxxxxxxXx+x++X#############X###x    //
//    +#x#####+xXXxXxxX###############X#X#X#####X#X##XX###XXXXX######################################################XX######X    //
//    X=x##XXX=-###XXX###########XXXXXXXXxxxxxxxxxxxxxxxxxxxxxxxxxXxXXXXXX#X####################################X##x+=+=+x###X    //
//    X-X###+x#-X#XXX#########X#XXXXxXXXxxxxxx+xxx+x+x+x++xxxx+xxxxxxXXXxX####X#############xX#XXXxxxxxxXx######X##xx++++#X##X    //
//    #+X###+x#Xx#Xxx##########XXXXxX=;,,,,.,.,...,.,.,.,...,.,,,,,,,,;+xx.-xX#X############+X#x===-=-==+x##########Xxxx##X##x    //
//    ######X-=x#XXxX########X#XXxxx=..................................;xx.-#X#X#X##########+x+X#XxX#xXxxx#######XXxX+=x#XXX#x    //
//    X######;x#x##xx#########XXXXxx=..................................;++.;xXX#X###########+++++xxXxXx+=x######XXXX+++#XXX#Xx    //
//    X####X#++x.x#Xx##########XXxXx=...................................x+..xXXX#X#######X##XXX+xXx++x#++x######xXxx+=x#xXxXxx    //
//    =-###x##++.;+X+#########XXXXxX+---;-----;-;-;-;;;;;;;;;-;;;-;----=x+==x#X#X#X###X#X#xxxx+xxx+++++x++######xXxx+=x#xXxXxx    //
//    +.=X=.##x=.,++x########X#XXXXxX##XXxXxxxxxxxxxxxxxxxxxxxXxXxXXXX#XX####X#X#####XXXXX#XxxXxx++xx++xxxXXXX##xxx==-x+XxXxxx    //
//    +.;x,.##x.=+==-#####X#XXX#XXXXXXxxxXxxxxxxxxxxxxxxxxxxxxxxxXxXxXXXX#X#########XXXXxx==+=-=----;-----+xXX#X+xx+-+x.+XXxxX    //
//    #+=X-,#+#,,##=.x#####XXXXxxxxXxxXxXxXxXxXxXxxxXxXxXxXxXxXXXXXXXXXX#X###########XXxx..................+xX#x=+x-=##+xxXxxX    //
//    x+x##X+x=x+...+++#######Xx+xxXXX##############X#X#####################################X#XXXXXXXXX######x=++#++#X+XxXxxxX    //
//    X+x##X+x++x=....;;+==x#############################################################################Xx+=-x+-+=Xx-#xxxxxxx    //
//    #X+##X=x+=+=#.....,.,xx.............=########X#X#XXX#x-......,-+xxx+xxxxxxx+x+x+x+++++++=====---=-==+++=-=+=##XXX+xxx+xx    //
//    ##+##x-X+==-X+.....;..+#,....,....=#####X#X#X#XXXXx#X=,......,;=xxxxxx+xxxxxxxxx+x++++++++++=======+++--+x;x#.;#++xxx+xX    //
//    ##+##--X+====#,....;;,.-#,......;######XXXXXXXXxxxXXx-.......;-=++x+x+++x+x+xx+++++++++++=+=+=====++==-=x-+#x=xxxxxxx+xX    //
//    ##-##+=#+===;##...-+.,,.+#.....x####XXXXXXXXXXXXxX#X-......,;=++=++xxx+x+x+x+x++++++++++++=+++===+++=x=--+##,+#x+x+xx+xX    //
//    ##;##x##X===;+##Xx##..,..#-...#####XXXXXXXXxXxXXXXx;.....;-=+++++=++++x+++x++++++++++=+++++++=+=+++-+##XX##=xXx+xxxx++xX    //
//    ##-##xX#X+++=+######=....#,.;#####XXXXxXxxxXXXXxxX=..,,--+xxxxx+++++++xx++++++++++++=+=+=+=+===+++==####XXX=xXxxxxxx+xxX    //
//    #X-###X##xxx+-##XX###...;#.,#####XXXXXXxXxXxx++++++-+#######Xxxx###xxxx++++++++++++=+=+=++====+++==+###X##-+XxxxXxxx+xxX    //
//    ##-####X##x++-x##XX##=..#+,#####XXXXXXxXxx++=======+X####x+##XxxX###Xx++++++++++++++++=+=+=+=++++=-###Xxx++XXx+xXxxx+xx#    //
//    +=XX###x##Xxx=+##XXX##.X#x#####XXXXXXxXx+=-----------==-;;=##X++x+x++++++++++++=+++=+=+++===+=++==+###X-..xXx+xxxxx++xx#    //
//    +;xxXxx+x#XXxx+###xX##+#x######XX#XXXX+=--;-;;;;;;,,,....,;+++++++=+=+++++=+++=+=========+=++++=-=####xX+xXX+xxXxxx+=xx#    //
//    X;x,.+x-=XXxxxxx#####-############XX+=-;;,,,,,,,........,;;,..,-=+=======+=+=+=+=+=====+=++++=x######xxXxXxx+xXxxxx++xx#    //
//    #,X=-xx--xXxxxxx####;X###########X#x=-;,,...,.......-=+xXXX++xX##Xx++==-==+=+=+=+=+=+++=++++=+##x##X#xXxxxx+xxXxXxx++xX#    //
//    #;-X+xxx-+XxxxxxX##-x#######x####XXx--,,,,.,.....-=xxxxxXXX###XXXxxXxxx+=====+=+=+=+=+++=+=+,##X####xxXxxxxx+xxxxx+++xX#    //
//    #-.--=xx==Xx+xxx+-++########-####XX=-;;,,,;,..,=xXXX#X###########XXXXXXxx+==+++++++=======x-=#XX####xxxxxxx+xXxxXxx++x##    //
//    #=,;,=+x+=Xx+x+x#xX###############x=-;;;;;-==X############################Xx++++++++==-=+####xX#####xXxXxx+xxXxxxx+++x##    //
//    #+;;;-x++=xXxx+####-###############=-;;,;-+######XxxxxxxxxxxXXXXXX#XXX#######xx+==+===X####Xxx#####XxXxxxxxxxXxxxxx++X#X    //
//    #x;-;-+x+-+X++####X,################;,,=;-==+=-,.,.,,,,;;;----===++xxx+x++xxx+xxXx==+#####XxX######xxXxxxx+xxx+xxx++xX##    //
//    #X-;-;+x+=+X+x####,-#xX#############x.#####+..,X-;-====+++x+++xxxxxxxxxx##==+X####X-####Xxx######X#xXXXxxxxxXxxxxx++xX#X    //
//    ##=--;+x+==Xx#####.=+;-#####################;.-X##XxxxxXXXXXX#X#XXXXXXX##Xx=+###########Xx#########xXXXxxxxxxxxXxx++x##X    //
//    #X+-=,=x+==X#####,.-==-####################x-##+=#+##x+####XXX####XX#XxX+X##=x########XX+##########x#XXxx+xxxxxxxx++x##X    //
//    #Xx-=;-x++-####XX;##=;,X##################X-######+xX=-=+xx###xxxx+xx+x######=#########+x#########XxXXxxxxxxxxxXxx++X###    //
//    #Xx-=-;xx+-+###x####x,,,#x##########x##=XX+-#######x;+#####x=x#####+-X#######+x##x####+=##########XxXXxxxxxxxxXxxx++XX#X    //
//    #Xx==-,+++-xx=+X##################X###x=.;######..,#;.,==xX,.;#X+x=;=##########==X##x+=x##########XxX#xxxxxxxxxxxx++XX#X    //
//    #Xx==-,+x+=X+xxx#########x########XX##x=X##X####;..#=+###X+;;=X####X+############+xx+++############xXXXxxxXxxxXxxx++XX#X    //
//    #Xx++=,=+x-#xx#XX#######xx########X#X##Xx##+#####x.xx######+.#######x#######x###Xx+++++###########XXX#xxxxxxxXXxxx+xX#X#    //
//    #Xx=+-,-++=#x+###x#################X#######x=#####..=X##############x#######+##xxxx++=X############xX#XxxxXxxX#xxxx+x#xX    //
//    #X+++=,-++=#x+XXXx#################XX#X#####=xxx####x###############X#######x#xxxx+++=#############XX#XxxxxXxXXxxx+xx#XX    //
//    #X=+=-,;+=xX++XXxxX###################xx++xX#####-..;x;,;==x#====+X++XX#Xx+xxxxxxxxxX###############X#XXxxXXxxX#+xxxxx#X    //
//    x=+-=-,++x+=+xx+x#x###############;--=-==++++++xxxxXXXXXxx+=++X###########X#XXXXxxxxxxX################Xxxx#XXxx#X+xXxx#    //
//    +++==.-=x++=xxx+#Xx##############+,---=-==++++x+xxxxxxXX###############X#XXXXXXXXxxxxxx#################XxxXXXXxXXx+XXxx    //
//    ++==-,-+x+==xx+x#xx##############;,------==++++++++xxxxxxXx##X##########X#X#XXXXXXxXxxx#################XXxXX#Xxx#Xx+#xx    //
//    x===,,=x++=+x++XXx##############X.,;;;----==+=++++++++xxxxxXXxXX#X###X#X#XXXXXXXXxXxXxxX##X##############xXxXX#xxX#X+xXx    //
//    -+=.-x+x-=x+xXxX#X############X.,,,,,,,;;--========++++x+x+X#xxXXXXXXXXXXXXXXXXXXxxXxXxXX##################XXXX###xx##xX    //
//    =+;,++x=-x+xXxX#XX###########X,.,,,,,,,;----======+=++++x+xx#xXXXXXXXXXXXXXXXXXXXxXxXxXxXX#################XXXXX###xx#XX    //
//    x;;xx+==x+xX###X###########=,.,,,,,,,,,,;---=-======+=+++++x#xxxXxXXXXXXXXXXXXXXXxXxXxXXXX#X###################XxX###Xxx    //
//    +,=x+==x++####X###########;..,,,,,,,,,,;;----========++++++x#xxxxXXXXXXXXXXXXXxXXXxXxXXXXXX#X####################XxX##Xx    //
//    --x+=-+++####X##########=.,,,,,,,,,.,.,,;---=-======+++++++x#+xxxxxxXXXXXXXxXxXxXxXXXXXXXXXX#X####################XxxX#X    //
//    #X+x==++####X#########=,.,,,,,,,,,,,,,,;;----======+=++++++x#xxxxxxxxXXXxxxxxXxXXXXXXXXXXXX#X#X#####################xxx#    //
//    ##,=##xX###XX######x-...,,,,,,,.,,,,,,,,;;----======++++xx+x#xxxxxxxxxxxxxxxxxxxXxXXXXXXXXXX#X#X#X###################Xxx    //
//    #=-+####X#######X=,....,,,,,,,.,.,,,.,,,;;;----====++++====x#xxXxxxxxxxxxxxxxxxXxXXXXXXXXXX#######XXX##################x    //
//    +=+++xxxxXx##x=,....,,,,,,,,,...,,,.,,,,;;-;----====+=;;-;;=#==+++xxxxxxxxxxxxxxXXXXXXXXXXXxX##X###XXXXXX##############X    //
//    ++xXXx=-x##=;-;,,,,...,.,.............,,,,;;--======+-;----==+====xxx+x+++++xxxxxxXXXXXXXXXXx--+XX#XXXXXXXXxxxXX########    //
//    +=--,....,,-=---;;,,.,.,.............,,,,;,;;--=-===+=;----+=+===++++++++++++xxxxXxXXXXXXXX####XX#X#XXXXXXXXXXxXxXX#####    //
//    -.,,;;,,.,;;;-==-;,,,..........,,,;;;;;;;;,,;;--=====++++=+x-x++x+++++++++++++xxxxXxXXXXXXXX#####X###XXX#XXXXXXXXXXXXX##    //
//    ;,;;,,,;,;,;;-;;,,,,,,.......,;;;;;;;;;;,;,,,;---====++++xxx;xxx++++++++=+=++xxxxXxXXXXXXXXXXXX###X###X#X#XXXXX#X#XXXXXX    //
//    ;.;;;,;;;,;,;,;,;;,,,,,......,;,;,;,;,;;;,,,;;----====+++++x-xx++++=+=====+++xxxxxxxXXXXXXXXXXXXXX###X#X#XXX#X#X#XXXXXXX    //
//    ;,;;;;;;;;;;;;,;,;,,,,.........;,;,;;;,;;;,,,;;----====++++xX+++========-==++xxxxxxxxXxXXXXXXXXXXXXXXXX#XXX#X#X#XXX#XXXX    //
//    ;.;;;;;;;;;,;,;,;,,,,,,,,.....,;;,;,;,;,;,,......,;---=====x#=+=-----;,,;;-=++++xxxxxxXxXxxxXxXXXXXXXXXXXXXXXX#X#XXXXX#X    //
//    ,.,,,;,;;;,;,;,;,,,,,,,;,,.....,,,;-;,.,,,,,..-xxX##XXXxxXxX#x+xxxxXX##XX#X#XXXXxxx++++xxxxxxxxxxxxXxXxXXXXXXXXXXXXXXXXx    //
//    ,.,.,.,,,,,,,,,,,,;,;,,,,.....,,-;...;-++xxX#################X#########################XXxx+++++++xxxxxxxxxxxxxxxxxxxxxx    //
//    ...........,,,,,,,,,,,;---+x#XXX+-;=x##########X++==++xXxxxx+xX#X#x++==xx#####################Xx+++++++xxxxxxxxxxxxxxxxx    //
//    ..............,,,;-------X##x+++X#######Xxx+=......,=++========-===;....,-=+xxxxXXX#################Xx+===++++x+xxxxxxx+    //
//    ......................;=+x+xxXXXxx=--;,,............,-;;;;;;,,.........,-=------------=+xxXX#############X++=+++xxxxxxxx    //
//    ..........-X-....,-x####Xx+=-;,.....................,;-,,.............,;---;,,...........,,;--==+xXX#########Xx+++xxxxxx    //
//    .......x######X####x=;...............................,-;,..............,,............,,..,........,;-=+x##########x+xxxx    //
//    ....+#####=,;=x+-.....................................-;;...........................,,,,,,,,,,;,;;;;;;;;-=xX#########xxx    //
//    ..x###X;..;++-.......................................,--;,.......................,,,,;;;;;;;;;-------=-=-===+xX########X    //
//    ###x,...-=-...........................................;;,.......................,,,,,,;,;,;,;;;;------=-------==++xX####    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SKIN is ERC721Creator {
    constructor() ERC721Creator("Under the Skin", "SKIN") {}
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
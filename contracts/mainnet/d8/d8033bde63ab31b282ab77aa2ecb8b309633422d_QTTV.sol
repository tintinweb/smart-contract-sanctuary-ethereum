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

pragma solidity ^0.8.0;

/// @title: Questions to the void
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                             //
//                                                                                                             //
//     d0OddOKK00000OO00000OOOO0OOOOOkxdo:,'...                           ...:oxkOOOOO00O00000000000OOkxk0k    //
//    o0xokK000K0OO00000000000OOOkkxo:'.                                     .:dkOOOOOOOOOOOOOOOOOOOO00kkx     //
//    oOod000K00O0000OOO000OOOOkkxo;.                                          .cxkOOOOkkOOOOO00000000OOkd     //
//    oxoOK000OO0000OOO000OOOOkdl,.                        ..                    'lxkkkkkkkxxxkkxxxxOO000k     //
//    ldx0000O00000O00000OOkkd:.                       ..........                 .,oxkkOOOO0000OOkxxxxkO0     //
//    lxO00OO000OOOOkkkkxxxxl'               ...    .......';,,'......              .:xkOOOOOOOO00000Okxxk     //
//    lk00OO0OkxxOOOOOOOkkd;.           ..'.. ...'. .;,. 'c;..',,,,'...              .;dkOOOOOOOkkO000OOOx     //
//    cO0kO0kdxO0000OOOkxo'           ... ..'.   .;,.....:;.,:,''''',,,'.              ;dkOO0000Okxk00O00O     //
//    lOkO0kxO000000OOOkl.           .';:,.  ';.  .::. .';,;:',;;,,,,,,'....           .;dkkOO0000OddO0000     //
//    lkOOxx0000OO00OOkl.          .,.,,':c'  ':.  ,l' .,,;:,:;'':loooooc:,..           .:xkOOOO000xcx0000     //
//    lO0xd00000O000Okd'          ..',,c' .;' .:,  .c, ..,:;:,,:ll:;;:::;;;,.            .okOOOOOO0xcx000O     //
//    l0koOK000000OOkx:.         .';,;,;l,..'. ;;. .:, .::,;;;cc:;;;:clllool,.            ;xkOOOOOklck000O     //
//    okox000000OOOOxo'        ',',::;c:,;..'..','.... ...,;;:lc:oo::::::::;;,.           .okOOOOxllxOOOOO     //
//    ddo000000OOOOOxl.        .c,,:ll;:cc;''...,;''..  ..'',::,;:::cc:;,;::;,,.           ;xkxddoxO0OOkkk     //
//    ood0000000OOOOxc.        ,:;,::colcl:...'';:;,,.  ..'',;,',cdOOOkoc;::::;.           .:odxO00OOOOOkk     //
//    olx0000000OOOOxc.        .;::,;::clo:...,:;;,,'.   ..'',;,lkxo::lxOocoo:,..           ;xkOOOOOOOOOOk     //
//    oox0000000OOOkdc.        .';cc:;:::c:'...;;'...      ...';dk:.  .:kd;::,,,.           'oxkkOOOOOOOkk     //
//    dxx0000000OOOkdc.         .,:cc:;'',,'....,'..       ...';okl...'lOo;::,,'.           'lxkkOOOOOOkxk     //
//    dOxO00000OOkkkdc.         .;cc:;;;;,.   .',,..      .';;;:coxxddxkxoc:,,;'.          .,lxkkxkkkkkkkO     //
//    o0kkO0OOOOOOOkdl,         ..;:;;::;,.   .,,,'.       '::cclcloddoccc:,;;;'.          .,:cc;.....',:o     //
//    l0OkkOOOOOkOkxoc'         ..',;;;::c:;',;;,,'..      .,;;::;;;:c::cll::c;..          ..:lo:              //
//    c00kxO0OOOOkkxl;.         .';cc:;;:c::::::;;;'.   .  ..':ooc:cllllccllc:;'.          .'lxkl....          //
//    :O0OkkO00OkkOd:,,.         .',,;;::cccc:cc:,'.    .  ..;cllcclooool:cc::;...     .....;oOOkxxxdoc;..     //
//    ,k00OkOOOOkkkdc:;....      .,;::cllccc:;;,,..        ..,:cc:;:ccclc;:ll:;:,'... .','',lO0OOOOOOOOOkd     //
//    'k0OOOkO0OOkkkl:,..''.    ..;:::ccccc:::;;'....  ......';cllcclloolccclccc;,,,'.',;,;lkO000OOOO0OOOO     //
//    ,kOO0OkOO0OkOkxc;'.','.  ..'::::colc:;;:::,''..  .....',;:cllc:::;;::lollc:::;;;;;;;:dOO000OOO000000     //
//    :kO00OOkO0OOkkkdc:,.........',;llllolcclc:;,;,'......',;;clcccclllllloolc::::;;;;:;:okOOOOOOOO000000     //
//    ckO00OOOkOOkkOkkxl:'..','. ...,::ooccc:::c:;:::;;,,;;;;;clol:c::lc:ccccccc::::;::::lkOOOOOOkkOOO000O     //
//    :O0OOkkkkkOOkOkkkkd:.';,,,....'':lccc::::c:clooclllloollllcccccclccccclccc:::cccc;:xOOOOOOOkxxkkOOOO     //
//    ;k0OkkOkkkkOOOOkkkOx:';::;,'..',;lc;,:lllcclcccllloooddxollc:clllc::ccc:::ccclc:,,oOOOOOOOOkxkkxkkOO     //
//    ,xkkkkkkkkkkOOOkkkOOkc',:::;,...',,,:ccc;;:ccllloxxollolclllcllccc::::::::cc;,'..:k00OOO000OxkOOkkkO     //
//    ;xxxkOOkkkkxodkkkkOOOkc..',;,,....,;;:clccccc;,;:::;:cl:';c:;;::ll::ccc::cc,....;xOOO0OOOOOOxk0OOOkx     //
//    ;kOOkkkkxkxc,;okkkOOOOkc'....'....''';::::::,.'cooolllllccccc:cclccccccc:c;....;dkO0OOOOOO0OxO0OOOOk     //
//    'k000OOOxdl;,:dkkOOOOOOkl,.......''.,;,'.,:cc:coddxdodddolcc:;;;:::ccc:cc;....,dOkkOOOOOOO0OkO0OOOOk     //
//    ,k00OOOOo;;;:dkxkkOOOOkkkxl:,.......,;:;,,;cllclooo:;lolc::::ccccccccccc;....;dOOOOOOOkkkOOOkk0OOOOO     //
//    :k00OOOko:;;lkkkkkkOOOOkOkxkxdc;.....',;;,:l:;:coooololooc::ccccccccccc;....:xOOO0OOO0OkxxkOkk0OOOOk     //
//    lxO0OOOkkkl:dOOkkOkkOOOOOOkkxxko'......''.,::ccccllc:;;::;::::::::cccc;....:xOOOkOOOO0000kdlok0OOOOk     //
//    okk0OOOOOOd:x0OOkkOOkkkOOOOOkkkd,.   .....';:;;;:ccccllc;,::::::ccc:;'....:xOOOOkkkO0OO000OxoclkOkkk     //
//    okkOOOOOOOxcd0OOOOOOkkkkOOOkkkOd;''.... ..,;:::cclllccccccccc:cccc:,.....;x0OOOOOkkkOOkO00OOkxc,lk00     //
//    dOkkkOOOOOkddO0OOOOkkkOkkkkkxxxoccc:,,;.. ..,;:;;:;;,,;,;:ccc:cccc:,....,dOO0000OOkkxkkxkOkxxddc';x0     //
//    dOkkOkkOOOkkkO0OO0OOxxOOkxxodkdc;;;ccc::;'';;;;:::ccc:ccccclccccllc;,'.'oOOOOOOO000Okxxxxdxddk00x,'d     //
//    dOOOOOOOOkkOkO0OOOOOkxdxxloolc:;;;clllc::ccllllccllllcclllcccccclc;,;,,cdkOOOOOOOOkkxxkkkkkxkO000k;'     //
//    oO0OOOOOOkkkkkOOkOOkkl:xkollclc;,;:lolllllllooolloddddddddlcccccc:;,,;:clloxxkkkOOkkOO00OOOxk00OOOk,     //
//    l00OOOO0OOOOOkxOkdxkd:lxdddoll:;::clollllllclooooooddxxxxoccccclc:;,',;::cclloodkOOO00OOO0OkkO000Okd     //
//    d0OOO00OOOxldd▓█████▄  ██▓ ███▄    █     ▄▄▄▄    █    ██  ██▀███   ███▄    █   ██████ O000kxOO0000Ok     //
//    xOkO0Okkddd:'l▒██▀ ██▌▓██▒ ██ ▀█   █    ▓█████▄  ██  ▓██▒▓██ ▒ ██▒ ██ ▀█   █ ▒██    ▒ddkOkkkO00OOOOO     //
//    xkxkxxkkdllxc.░██   █▌▒██▒▓██  ▀█ ██▒   ▒██▒ ▄██▓██  ▒██░▓██ ░▄█ ▒▓██  ▀█ ██▒░ ▓██▄  ooooodolokkOOOO     //
//    kxdxdololoccod░▓█▄   ▌░██░▓██▒  ▐▌██▒   ▒██░█▀  ▓▓█  ░██░▒██▀▀█▄  ▓██▒  ▐▌██▒  ▒   ██▒lccc:c:cxdokOO     //
//    xdccoodocloodd░▒████▓ ░██░▒██░   ▓██░   ░▓█  ▀█▓▒▒█████▓ ░██▓ ▒██▒▒██░   ▓██░▒██████▒▒xdodl:ldo::xOO     //
//    dc:xxllllccokO ▒▒▓  ▒ ░▓  ░ ▒░   ▒ ▒    ░▒▓███▀▒░▒▓▒ ▒ ▒ ░ ▒▓ ░▒▓░░ ▒░   ▒ ▒ ▒ ▒▓▒ ▒ ░ooccdxd;lOcckk     //
//    ,;OOcoxooxdodd ░ ▒  ▒  ▒ ░░ ░░   ░ ▒░   ▒░▒   ░ ░░▒░ ░ ░   ░▒ ░ ▒░░ ░░   ░ ▒░░ ░▒  ░ ░dollddxo:xd;dO     //
//    ,k0c:Ooc0X0dlcc░d▒l:;:c░dd░odoolcldddddd▒l▒llx00░00░xd;',d0K░xocc:░''░'..,;▒cll░olo░ddxolcccclc:do:d     //
//    ,d0l;dxooo:,:cclc░oxkOxc::░dddxxO0kdddodol░lclkK000kxdc;;ckK░dl:,░'..'.''';░ddlloxkxxollodoloodkOc,      //
//    c.,lolcol;lxxxxkdcccldxkOxlccloddllclddooollllx0K00Oxxdol:okxdoc:;,,,,''''.,clllx0OxoldO0kxkkOOxolld     //
//    ll:;;cl::odlclc:lddlccccldxdoddddkOkkxollllllldk0000kxxO0Oxdxdlc:,'',,,,'.,oO0OOkdolldxdddkkl::ldxo:     //
//    lcclo:,cl::dold:'':ldxdocccclodxxxxdooollllllldxk000kxdk0KOddocc;,,,,,,,'.,cclolccooo::kKxc;lxxl::lx     //
//    :xd,;kd':x;;x:c00ko:;:ldkkdoooolccloxkdlllllllodxk00Oxdx00kdoc::;'''',,,'';lccooolldl;xKd':ko,,cxO00     //
//    .o0d';kd'cd:locoxddxxdlcccodoccldkOkddllolllllldddxOOxodOOxxo:;;;,''','.':ddc;:cclcc,cOo,ld;.ck000Oo     //
//    ',oOd,'cl,';:llollc::lxkOxlccoxl;,;:lccolcccccldxddxkxooOkxxo:;;;..','..,ldolcccll::c::cdl',x000Ol'.     //
//    xc,:xkc.,ol,':llccoocccccoxxoclxkxxdl:odcc:;cccoxkxdddclxdxxdc,,,'.','..:olllllldxl;,;xx:;oO00Od, .;     //
//    O0Oo;lOx;.,;::ccllclodxoc:::oxdolcccoxdlocc:ccccokkkxl';odddd:'','.''''.;ldxkOOOko:';xl.:OK0Oo,..,oO     //
//    :x00kccxOxo;'oOc'dl.;::ldxdc;:oddxkdolooccccccccldxkko..cdddd;.',,,,;;,'cxOxocccc;;lko..d0xc. .ck00O     //
//    ..ck0Oo;cx0d.'kx'lk:lOd:;;clocccldoccolllc:ccccccoddxkc.,ooxd;..'',,,,',lxxdooloc:dx:':dOd. .:k00kl,     //
//    o'..cxOk:;xOo';dc:d:;xOkkdoc:clccooollloolccc::cloodxxx;,cdxd:..'''...'cooxxxdll,o0;.d0kl''cx0kd:. .     //
//    Okc. .ckk;.:xx:'cl;cc:odxkkkxoclxxxdxdddolllcc:coooodddo:lxxd:..''....':c;colloc,dk.,Od,;dOkd:...,lk     //
//    :xOxc. 'dko;,lxd;:l:cc:clooldxdoodooooolcloolcccodddoc:lxkdoo;.''',,..',::lllll:;kd.,kc.cc,..':lxOOk     //
//    ..cxOxc..lkOd:;lxc:c,:dxdollllldxxxddddxdoooolcllooddo:,;c::;..',;;,..',;ccclol;cOd.;k;..,:oxO0Odc,.     //
//    l'..ckOd'.'lkOxc;o:,cc:oolddolllloddddollodddocccccldkxo;..'''.';;,'...;coooloc:kO:.cd':O0Oxlc;...,c     //
//    Ox;. ;xOx;. ;xOOo:o;;xc;,.,ldoollooddllllodddoc:ccccoxxxdc'.',,,,''....'co:'.,;:kl.'xo.l0k:.  .,lxO0     //
//                                                                                                             //
//                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract QTTV is ERC721Creator {
    constructor() ERC721Creator("Questions to the void", "QTTV") {}
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
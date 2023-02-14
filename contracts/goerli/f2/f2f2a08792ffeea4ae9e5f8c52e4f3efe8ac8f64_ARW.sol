// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ARWed
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                               //
//                                                                                                                                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMMMMMMMMMMMMMMMWWMMMMMMMMMWWWWWMMMMWWMMMMMMMMMMMMMMMMMMM     //
//    MMMMMMMMN0kO000OxxOK0000OOOkkOkxkO0OO000OO00000K0O0KKKXXXKOOO0XXXXXX0kO0kk0KXXXXKkk00KK0OkkO0XXXXKOkkOKXXK00O0KXXKKXXXXXKOkOKXXKKKKKKKKKO0XXNWMMMMMMMM     //
//    MMMMMMMMXxdxxxoc::lxxxxkxlcldxxxxolodxkxl:okkkkkxldOO0000OxoldO00000OddxxdooxOOOOxllokOOkxdx00000OkxoxOOOkxlodxOOO000OkxO0kxk000OOOxxkxodkO0XWMMMMMMMM     //
//    MMMMMMMWXOxxxxdoolcldddxdddoldxxxoclxkkxoc:ldxxxolodxO0000xldkk0OxdxddkkkkdodddoxkxolxOOOkodOOOOOkkooxxxxxocoxkkkkxdxxodkOOOO000000kdodxOOO0KNMMMMMMMM     //
//    MMMMMMMW0xxxdddddxdoc:ldxxxxocodddolclolcccclool::::ldxxddodO0OOko::lxkkkkkOkxooxkkkddxdxxdoddxkdlllllddolcldddxxxdl::lxkkkkOkxkOkddkkdxkkOOKNMMMMMMMM     //
//    MMMMMMMW0olccoddxddololodxxxxollllcc:cloooccc:;;;;:::cc:::cokOkkocdxdddxxddxkkkooxkkkdodxxdddddddolllloolccclooodoclolldxxxxxdlcodxk0000OOOOKWMMMMMMMM     //
//    MMMMMMMWKo:;codooodxxxdlldxdoc:cllc:;;:c:;,,,,,,,,,,,,;;:cloxdlccdxxkxolccdxkkkxlldkkxdlc::;;::::;;::::::cc:ccc:::cllloooodoccloldkO000000OOKWMMMMMMMM     //
//    MMMMMMMWKdoolllccdxxxkkxolc:lolc:,,'',,,,,,'',,,,,,''',,;;::cooccdxxxoldxooddxkxoddoc:,,,,',,,,,,,,,,,,,,,,::::;;;:::ccl:;;:codxxxkO00KKKK00KNMMMMMMMM     //
//    MMMMMMMWXOxxdocldlldxxxdc:clc:,,''',,,,,,,,,,,,,,,,,,''''''',,;:lodlcldxxolloxxdl:;,,,',,,,,,,,,,,,;,,,,,,,;;,,,,;:;;::;;:;:oooddxxkO00KKXKKXWMMMMMMMM     //
//    MMMMMMMWKkxxxdxxxdllolclllc;,'''',,,,,,,,'''''''''''''''''''''''';:cc:oxdlldol:;,,,,,,,,,,,'';:llc:c:,,,,,,,,,,;cc:;,,;::clllooodxxkkO00K00KXWMMMMMMMM     //
//    MMMMMMMWKkxdddxxxxxo::clc;'''''',,''''''''''''''''''''''''''''''''',;cdkkxol::lo:,,,,,,,,,,,,;coxxdool::::;;:ccoolc:;,;:cccclloodxxxxkkkOddO0NMMMMMMMM     //
//    MMMMMMMWOdlcodxxxxxollc:;'',,'''''''''''''..''''''''''''''',,',,,,,,',;clc;;,:oc;,,,,'''',;;;::;;;:looxxxdlcoddlloc:;,,;:cccc:cllllcldoodoox0NMMMMMMMM     //
//    MMMMMMMW0dlcllccoocllc::c;,''''''''.........'''''''''''''''''',,,,,;;,,,',clc,,'',','''',;lxkOOkdol:,coxxollloolll:;;;,,;;;;:::cclollxOO0Ok0XWMMMMMMMM     //
//    MMMMMMMW0xxxkxddl;:lc:;lxo;''''''....................''''';:;,''',,,,,,,,,;:;,,,,'',,,,,,,,:ok00000kl:cdo:clllcccc:;;:;,;:::ccloodxxxkOOO0KKXWMMMMMMMM     //
//    MMMMMMMW0xxkxkkxolll:,';;;,''''''.......................';lxxoc:;;,,,,,,,,,,,,,'',,,,,,;::;;;:ldO000kolc;,;cc:;;;::;;::;:::::cooodxxxkkkO0KKXWMMMMMMMM     //
//    MMMMMMMWOdxxxxxolooc;;cc;''''''''......................',cxOO0OOkxl:,,,,,,,,,,,,,,,,,,;;;;:::cc:cx00Oxl;,,,;;;,',,,,,;;,;;;:cloooodxxxxkOO0KXWMMMMMMMM     //
//    MMMMMMMNxcoooodc:ol:,;ll:''''''''..............'..''''',:dO0000000Od:'''''',,,,,,,,,,;;;;;;;;:::lxOOxo:,''''''''''''',,,;,;:::cooodxxxxkkOO0KWMMMMMMMM     //
//    MMMMMMMNkoolcldccol:,',:c;''..''''............'''''';coxO000K0000ko:,''''''',,,,''',,,,,,,,,;coxO0kdc:;'''''''''''..',,;;;;:;;:ccodoldkkkOOOKNMMMMMMMM     //
//    MMMMMMMW0xkxdddolllc,':dxc'......................''',;lk000000Okl;''''''''''''''''''''','',:ok00Oko:,''''''''''''''.';::::ccc:c:ccoccddxkOkx0NMMMMMMMM     //
//    MMMMMMMWxlollloo:;ll;',;:;,,'.........................,oOOxdol:;,'''.'''''...''''''''''',:dk00OOxoc,''''''';;;,'''',,;::::cllccloddlldoloxddONMMMMMMMM     //
//    MMMMMMMWx:loooddllooc,'.'cdo;........................';cl:,'''''''''............''''''''ck00Okxdoc,'','',:codl:,'',;;;;;:ccllccoodxxdxxkkkod0NMMMMMMMM     //
//    MMMMMMMWkloddddddlcddc;,';cc;'...'..................',cl;''''.....................''''':xOOOkxoc;'',,,,,,;:cddc;',::;;;,::::cclodxkkxxxkOOOOKNMMMMMMMM     //
//    MMMMMMMWOdddddolll:cdolc;'.;oo;..............'',,'',,;:;'''......................'...':xOOkxdl:,'',,;;,:c:,,::,';:c::;:c:;;:;;:lodxkxxkOO00KXWMMMMMMMM     //
//    MMMMMMMWOolcoocclol:coooo:''::,...............'''''''................................';ldxxdl;''',,;;,;cddc;'',;::::::cc:cccc::ccldxxxkO00KKXWMMMMMMMM     //
//    MMMMMMMWOdo::odddollllldxo:,'...........................................................,:ll;'.',,;::;:cll:,,;;;,;;::cccoddllllclolcoxOOOKKKKNMMMMMMMM     //
//    MMMMMMMW0xdoloddddddolc:oxdlc:;,'......................'','...............................'''.',,;:odl:,,,,;:c:::;;;;:cokOxoloodxdoooxkdx0KKKNMMMMMMMM     //
//    MMMMMMMW0xdolodlloollodl:ldxddolc,....................'';:c,..................................''',;:ll,'';:::ccc::c:;:codddoooddxxxkOOdokOO0KNMMMMMMMM     //
//    MMMMMMMW0olloxxdcclodxdoodoldxxxdl;'..''...............'';:;........................................',,;cc::lllllcllcc::ccccloddxxkOOOkOOxooxXMMMMMMMM     //
//    MMMMMMMWx:ldxxkxxoldxxxxxolcldxxxd:,;,,;'..''............:xdc'.......................................,coolllclolclolc:cc:;,;ldxxxkOO000KK0OddKMMMMMMMM     //
//    MMMMMMMW0oddddxxoloxdoddocldoclodxdoc;,'',;;'............,odxl'.,'..................................:ccodddddoc;:llc:;::;;cccloxkkO0000000OkkXMMMMMMMM     //
//    MMMMMMMWKkxdololldxxdollddxdloddccdxdlc;;:,................;dko;:l;...............................'clllllodddoccc;;:;;:loddddodxkkk000K00OOO0NMMMMMMMM     //
//    MMMMMMMWKxdolccodxxxxxdoddxxxdlcllodddl,.......''...........;oxdc:;..............................';cldolcloodxdol:;;;:ldxxxxkkkkoldk0K000OOO0NMMMMMMMM     //
//    MMMMMMMW0oclddlldddddolodoloxdlodocloolc,..','.,,.............;dd:.................'''...........'';llllollodddolc:;;:lodxxxxkOkxkxookOkxkOO0NMMMMMMMM     //
//    MMMMMMMWOlodxxxdoodolclodxdllxkxdooxxl:cl,......'.............;okx:';:'..........''''..........';:ILoveYouoxxlcc:;:lll::lddodxkO000K0kkxodkOO0NMMMMMMMM    //
//    MMMMMMMW0dddxxxxoccoodxddddddxxxxxxoodocll:.....,::c:,,:,.....,cdxx:,;'..........'''..........';lddxdolclxkkxdl;,:loodxxdc;lxkOOO00KKkodxoodOXMMMMMMMM     //
//    MMMMMMMW0dddddloxdloxxxdddlcldoloxolodoclodl,'..';lo:';:......';ldxl'......................',,;cldxxxxddxoodxxoc:::codxxl;:oodxkkO000OkOOkddxXMMMMMMMM     //
//    MMMMMMMWOllolcldxxxxooddlcclodoc:clddoloxdclol;,'.;c'.',.':;,;;:dOkc'''..................':lllolcldddkOOOkdddolddolcldxdl::clccokOkxkOOOOOOkdKMMMMMMMM     //
//    MMMMMMMWOl::codxxxddocclloddddoolclooddoloo:cool:';l;'''.ckd:;,;odo;';:'................;::codddxxookO000OOko;lxkkkxxdlclllokkxxkddkOOOOOOkdxKMMMMMMMM     //
//    MMMMMMMWOoollodddoccodlcloddddoc:clc:loccodo::codl:;,,'.,d0x::dkxc,..,'...............,:;;;codxkkkxkkdoxOOOOdodooxkkxl;:c:coxOOOkxkxdxkOOOOkOXMMMMMMMM     //
//    MMMMMMMW0dooo:;cccloddddoolldocclodo:;coooolclc;cdl:cc,'ckOo:oOOd;...................;cc:cllcoddoxOOOkddddkOxoldxxxl:;,,,;coxxdk000OxdkkxxkkOXMMMMMMMM     //
//    MMMMMMMW0doolc:,;ldddddolc:;cooooodddolooodoccl:;ldlc:;cxkxc:xOOkoc;;...............,;:lodxkxdloxxkOOOOxoxkdllloxxc:c:,,,,,ldllxO0000OkooxkkOXMMMMMMMM     //
//    MMMMMMMW0oc:;cllcldddolccloc:cddodddolcloooccoollcodolodoolccxO0kkOOx;.............,;;cldxkkkkkOkdoxOxxOOOkdodxkkkxxo;''''';ldxddxO00OkkOxookXMMMMMMMM     //
//    MMMMMMMW0o::cooooodlcllloooooooooddl:cloc:codxdc:cooclddllododxxxOKKOl'........',,:lloolldddk00000Oxolx00000OkxodOOxoc,'''.':dkOOOOOdx000OxdxXMMMMMMMM     //
//    MMMMMMMWOoollooooclolcloooooool:;colloddoc:ldxddocldocododdxdooxOKKK0xc,......,c::lddkkkkdodkkO0000xdkOxxOOOOkdxkxocll;''''''ck0KK0xdkkk00OOOXMMMMMMMM     //
//    MMMMMMMW0dlccllc::coddodooool:coc;lddodddoloddddc;lxkdcldxxxxxxkOO00Okxoc;,,;cllcccokOkO0OOOkddxxk00000OxOOdox000Oxoldc,''''';dxxOK0KOxdk0OkOXMMMMMMMM     //
//    MMMMMMMW0olc::cccooodddoc:lcclooooooooool:cloc:clodxoclxxlcodxxxkkkO0OOOkkxxxoloddooxxdk000000kodO00KK000Ol;lk0KK0000x:'';:,';:lx0KKKKK0Okdx0NMMMMMMMM     //
//    MMMMMMMW0o::c::cloooddocc:;looooooolccolclddooc:codddddoddccoodkkxxkkkOOOOOkdccdkO00kddxkOOO0KOkOkdxO0000OddOxloxO0OOdc;,;;''';d00xdOKK0OddxxKMMMMMMMM     //
//    MMMMMMMWOc:::;:loloolc;:odoodddolccooccodddddddolooooolcdxxdl:looddxxdxxoodxddocoOOkO0Oxdxxk0KK000kdxddkkO0Okxoodxdxko;,,,'''',lOK0xdOOxk00kxKWMMMMMMM     //
//    MMMMMMMWk:cl::loollolcodxxxxocclccoddddddddxxxoccooccooodxxoldxoccldxdlcccdxxxxdlodxOKKKOdodk0K00000xoxOkO00Okkkxccdkxdoolccc;,:xKKK0kloO0O00XMMMMMMMM     //
//    MMMMMMMW0ccolllodoccoxxxkxl:lo::oxxxxxxxxocoxdloxkkxddxdlloxxxdloddddoddxoccoxxxddkkddk0OxkOxLoveBiggerxdxOOOOOkdxddO0000000kdxOKKK0ddO0kdxONMMMMMMMM      //
//    MMMMMMMMNK00KK0KKK0O0KKKK0xx0XKO0KXKXXXXXK0O0KKXXXXXXXKKK0OKKK0OKKKK00KXKK000KKKXXXXXKKXXXXXXK0KXXNNNNNNXK0XNNNNNXXNNNNNNNNNNNNNWNNNNNNNNNXXXWMMMMMMMM     //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMYouRBeautifulMMMMMARW     //
//                                                                                                                                                               //
//                                                                                                                                                               //
//                                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ARW is ERC1155Creator {
    constructor() ERC1155Creator("ARWed", "ARW") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xb08Aa31Cc2B8C0582bE42D38Bb643292e0A4b9EB;
        (bool success, ) = 0xb08Aa31Cc2B8C0582bE42D38Bb643292e0A4b9EB.delegatecall(abi.encodeWithSignature("initialize(string,string)", name, symbol));
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
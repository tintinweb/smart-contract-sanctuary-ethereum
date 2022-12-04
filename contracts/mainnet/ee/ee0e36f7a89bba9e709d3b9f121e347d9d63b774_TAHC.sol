// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THE ART HEIST COLLECTION
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//     .----------------.  .----------------.  .----------------.                                                                 //
//    | .--------------. || .--------------. || .--------------. |                                                                //
//    | |  _________   | || |  ____  ____  | || |  _________   | |                                                                //
//    | | |  _   _  |  | || | |_   ||   _| | || | |_   ___  |  | |                                                                //
//    | | |_/ | | \_|  | || |   | |__| |   | || |   | |_  \_|  | |                                                                //
//    | |     | |      | || |   |  __  |   | || |   |  _|  _   | |                                                                //
//    | |    _| |_     | || |  _| |  | |_  | || |  _| |___/ |  | |                                                                //
//    | |   |_____|    | || | |____||____| | || | |_________|  | |                                                                //
//    | |              | || |              | || |              | |                                                                //
//    | '--------------' || '--------------' || '--------------' |                                                                //
//     '----------------'  '----------------'  '----------------'                                                                 //
//    .----------------.  .----------------.  .----------------.                                                                  //
//    | .--------------. || .--------------. || .--------------. |                                                                //
//    | |      __      | || |  _______     | || |  _________   | |                                                                //
//    | |     /  \     | || | |_   __ \    | || | |  _   _  |  | |                                                                //
//    | |    / /\ \    | || |   | |__) |   | || | |_/ | | \_|  | |                                                                //
//    | |   / ____ \   | || |   |  __ /    | || |     | |      | |                                                                //
//    | | _/ /    \ \_ | || |  _| |  \ \_  | || |    _| |_     | |                                                                //
//    | ||____|  |____|| || | |____| |___| | || |   |_____|    | |                                                                //
//    | |              | || |              | || |              | |                                                                //
//    | '--------------' || '--------------' || '--------------' |                                                                //
//     '----------------'  '----------------'  '----------------'                                                                 //
//     .----------------.  .----------------.  .----------------.  .----------------.  .----------------.                         //
//    | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |                        //
//    | |  ____  ____  | || |  _________   | || |     _____    | || |    _______   | || |  _________   | |                        //
//    | | |_   ||   _| | || | |_   ___  |  | || |    |_   _|   | || |   /  ___  |  | || | |  _   _  |  | |                        //
//    | |   | |__| |   | || |   | |_  \_|  | || |      | |     | || |  |  (__ \_|  | || | |_/ | | \_|  | |                        //
//    | |   |  __  |   | || |   |  _|  _   | || |      | |     | || |   '.___`-.   | || |     | |      | |                        //
//    | |  _| |  | |_  | || |  _| |___/ |  | || |     _| |_    | || |  |`\____) |  | || |    _| |_     | |                        //
//    | | |____||____| | || | |_________|  | || |    |_____|   | || |  |_______.'  | || |   |_____|    | |                        //
//    | |              | || |              | || |              | || |              | || |              | |                        //
//    | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |                        //
//     '----------------'  '----------------'  '----------------'  '----------------'  '----------------'                         //
//                                                                                                                                //
//                                                                    .dK0OOO0KXXXKOxl:,.                                         //
//                                                                    c0Okxk0000KKKXXXKXOdoc,.                                    //
//                                                                   ;kkxkOO00OkkxxkOOO0KXNNXOdc'.                                //
//                                                                 .:kxxkOkkO0OxkkkOOOOkO0KKKKXXKk:.                              //
//                                                                 'dxdxOOkO00Ok0KKXXKKNNNXKKKKKKXKk:.                            //
//                                                               ..:xkkOOOkOOOOO000KOOKXKKK00NNNXK00Kk,                           //
//                                    .                          'lx0OkOOO00OOOkO0kkO00OOO00OKXNX0KXKK0o.                         //
//                             ,cll:lxxxl'.                      l00OkOO0OO00OkxkOOkkkOOkkkkkO0KK0KKXNNNO;                        //
//                          .,o00Odd0XXXKOddo:.                 'x0kkO0000O00OOO00kkkkkOOOkxdkO0OO00KXXXNXd.                      //
//                        .:dOOxdookKXNXXXXKOkxl;.             .lkxxO000000K00O0K0xlodxxxO0Oxdxxkkk0KKK0KXXk'                     //
//                      'cddooddxk0KXXXXXXK0kxkxxxl;.          ,k0000KK00KKKK000OxodkOkddkO0Okxdollok00O00KXo.                    //
//                    .ldxxxkOO0KKKKKKKKKKK0000OkkkOklcc;...  .o0KKKXXKKKKKKKKK0xoxOOxllodxkOOxxdooodkOOOO0KKo.                   //
//                  .:k000000000KKKKKKKKKKKKK0000OOkOO0K0OOOdld0XXXXXXXXXXXXK0K0ddxxdc:odooodxxoooodkxxkkdxOKXo.                  //
//                 'x0000000KK0OkkkkxxkkkOOOOO000000OO00000KKKKKKXXXNNXXXXNX00KOooddl;:oooolclodoccloxdodoclkKK:                  //
//               .lO00K00OkkOOO000000000KKKK000OOOOOOOO0KKXXKKXKKXXXXXXXXKKKKKKklldoc;clllll::;:llc::lddoo:,:d0d.                 //
//              .d000KKK0000KXXKKKKK00OOOkkkkkkkkkkkkOOO0XNXXXNNXXXXXXNXKKKK0kxoccllc;cccccccc:;',:lllcodoo:',x0;                 //
//             .d0000KKKKKK0000000000OOOO0000OOOOOkkOOO0000XXKXKKXXXXXXKXKK0xol:;ccc:;ccclc::::;:,,;;:lloxxdl:oOo.                //
//            .lkOO0KXKKK0000KKXXXXXXKKK00000KKKK000OOOOOkxkkkOO0KKXXXXXXXXOdol:,';:;;cllcc:;,;,';loooodddxkOdlo:.                //
//           .c00KKXXXXXXKKK0000OkkkkxxxxkkkkkkOOOOOO00OOkxodxxk0KK00KKKXXKOo:;,,'''''',:::;;,',;;;,'';ccoxkkOd:l'                //
//           .xK0OO00KKKK00OkOOkddxkOOOOOOO00000000000OOOxdooxkkO0OO0OO0KKXO:';;;;::;;,'...'',,,;,'.',;:coxkk00oko.               //
//           ;xk00OOO00OOOOxdxdxxkkkxddodxkOO0KKKK000OkkxdoolodxkkOOOO0KKXKd,,,;;;:::;::,.''.......';:ccclclkXXOOx'               //
//           cOkkOOkkkkkOOxdlclll:;,,'.'',,;::codkOOOkkxddodocoxkOOOOKKXX0d:;;;:::;;,;;,',::;,,,...;codxxo:ckkOxoo'               //
//          .oklcclododxO0Oko:;,'...........'''',;:loodddddddlokOOkkO0KXOoccccccc:;;,,,'.';:;,,..;okOxoloooocckl..                //
//          .lc.....';:cldxxxo:'.........':::;'......',;:cllolodkkxk0KK0dloollllol::,;:,..;:,...cxko;....';cdxxc'.                //
//          'c;,...  ..;ooodoolc,.....  .,'';:::,..........',;:lxOOOOOOkdoooooodxol::lc,,:c,...cxxc.......':oxxo;.                //
//          ....','... ;0XK0kdlc::;,....'.,oddxdoc;..  .....',;:lk00Oxxdoooooodkxoccl:,;c:'. .:dl:'...';;'';lddl'                 //
//           .....;lc'.dXNNKOkdllodolloollolllcllllll:,'..,:llcldkkkxxxxdlllooodddxxolc:,.. .,lc,.. .clooc;:oooo;                 //
//             ...:llokXXXX0OOkxxxxxxxxdxxdddoolloolllodxkkOOkxxkkxkkkOxlllloodkOOkxdolc,''';c:,....clloolcloc:c;.                //
//               .clok0KKK0kkkxxkkkkkkkkxdooollloodddxO000KKK0kkOOkOOOkdllllodkOkkkdolc:,;lllc;.   .';cllc;od:;,.                 //
//               .:lok00K0OkxdddxkOOOOOOOOxdooooddxkO0KKKXXKK0kkkkxkOOkoollooxOkxdoc::;,':odkOl..   'lool:,ll,...                 //
//               ,ccd0XXXK0OkxxxxkOOO000000OxdodxO0000KKKK00OOkxxxkkkkxoollooxkxdddoc;,,;cldOOd;....:xxdc,;l;...                  //
//              .xOx0XXNXXK0OOOOO0OOO00000KKK00000OOOOOOOOkkkxdodxkkOOdoolodxkkkkxoccc::cccodl;'';:lxkxl;,cldc                    //
//              cKXKXXXXXKOkkxxxkkkkO00000000K00OOOkkkkxxxxxdollclodxxolllodkkkkxoc::;,,:cloc'.:dkkkOkl,,cc:xd.                   //
//             .dXKNNNNXK0kkxxxddxxxxxxO0KKKK00K00OOkxxddddoolc::loooolcllodkOOkxoc;,'';cldxdlokxol:::;:cc:cdx'                   //
//             .oKXNNNNK0OkkOOOOOO000OkxxOO000000000Okkxdoolccc::clc:::clooxkOOkxoc:c::clodkOOOkxxddolc:cooloOc                   //
//             .lKXXXXKOOOOO000000OOkkxoldxOOO000000Okkxddolcllc:cllodxdodxO000Okdodddoooodk0000Okkxo;.':loolOd.                  //
//             .d0OOOOkxxxdddddooollc:;,ldodxkkOOOOOOkkxxdddoodoldxk0KKOkOOO000Okxdxkddooolcoxxddolc;...,:ccoOx.                  //
//             .;llllllc:;'.......''''.'d0dloodxxxkkkkkxxxddddxdodxk000OO0O0K0Okdddxxdooolc:,',,,,'.,l:..,:::oo.                  //
//              .:;''......       ....'o0K0kdllloodxxxxxxxdddxxddxOOO0000000Oxdoooooooocc::c:'.  ..;xOko,...'oc.                  //
//              .okdod:.     ..'',;:cdOKKKKKKOxddoooddddddddxxdddk0O00O00O0Okxxxoldxol:;;',cc:'. .:xOOOOko,.,l,                   //
//              .cxOKk'     'lxO0O0KKKKXKKXXXXXK0OxdddoooooodddddxOO0KOkkOOkxdddooxdoolc:;:ll:;,';xOOOOO00Oc;;.                   //
//               ,kXK:     .lxkO000K00OOO00KKXXXKK0OkddoooodxxkOxk0000kxdxxxxddddddoolcc:::ccc:cox0K00KKK000o.                    //
//    .          'kXd... .':lc:clllllcccllodxkkO00OOOkxdoooxkOOkx0XKKOkdxOOkxdddolccccc:,,;:c:;cdkKK0KKKKK0KO;                    //
//    ..         ;kx:... .',,;,'''.........',codxdddxkkkxxkkOOxxOKXK00OOK0xoolcllllc:;,''';::;:dk0KKKKKXXKK0Kk,                   //
//    ...        ,dl,...'coodkOOkkxxdollc:,...';coxkkkOkOkkOOxxkkO0OOOkOkooxxoc:cc:::cc:::::;;lk0KXXKKXXKKKK0Xx.                  //
//    ...        .col:'.cdddddddddxxxxxkO00kdlcllldxxxxxkxk0Oxdxxxxkkxddddkxoooooll::cllllc;,ck0KXXKKKKKK0KK0KXl                  //
//    ...         .:odoodxdddodxkOOO00000OOO000kxxxdooddxkkxxdxxkkxxxxxkxdoooolccc:;::cc:;,':xk0KKKKKKKXXKKKKKNO'                 //
//    ...         .'lxxxkOOOOkxxkkkkkkkkkkkkkOOOkkkkxdooddddxxkkxxxdxxdoooooc;;:;,''',;,''.,oxO0K000KKKKKXKXXXNNk'                //
//    ....         .,oOxlllllooodddddddxxkkO000OkkOkkxdoddkkxdxkxxkxololllllcclc,,,',::,..'cxO0KK00000KKKKKKXXNNWO'               //
//    .......       .cOOxdxkO000OkkkkkxxxkOO0000Okkkkxddxkkxxddddxkkkxkxl:::cc:,';:;,,''';okO00KKK000KKKKKKKXXNWWO.               //
//    .......       .lKKXK0KKKKKKKKXXKKK00KKK0000OOkxdxkkkxxdoooodxkkdlc:;;,,,,,::;'''..:dk0000000000000KKKXXXNWO;                //
//    ........      .xXKXKKKKK0000KKKK000KKKKKKKKK00xdkkxdxdoddoodxxd:;::;:c:;,;;.....'lkO00000000K00000KKKKXNKo;'.               //
//    ..........    ,OX0KK0000000000KKKKKK0KKKKK0Okdodxxxxddddllodxo:;;;:cc:,.......'cxO00KKK00Okdolc:clodxkOx;...                //
//    ..........    :0XK0OOOO000000KKKKK0000KKK0Okdooxxoccllclll:;;,''',;;''.......:dO00KKKK0kdc,...........'....                 //
//    .......... . .:OKK0OkkkOOOOO0KKKK0OO0OO0Oxkkdodd:,;:::::,'..'....',........;oO0KKKKK0xl,...................                 //
//    ...........   'dOO00OxxxxxxkOOkOOkkkOOkxdxkdoll,'::,'''..................,oO000KKK0kl'.......  ...........                  //
//    ........... . .:dxOOOkdooodxkxxxolodxxdxdocc;'...''....................'lk0000KK0xo;......    ...........                   //
//    ...........    .':dkkxdlcloooolccccclolc;,,'.........................,cx00000d::;...     ...............                    //
//    ............    ...;loo:'......,:;,'...............................,okOOO00Ol........ ...............                       //
//    ..........          ......  ..';:;'... .........................,:okOOOO00O:........................                        //
//    ...........                   .....   ........................'ckOOOOOO0000x,....................                           //
//    ...........                             ...................,::oOOOOOOO00000koc'..............                               //
//    ...........                              ................'lkkOOOOOOOO00000Okxl,..........                                   //
//    .........                                ...............'okOOOOOOOO00000000Ol'........                                      //
//    ...............                          ..............;dOOO00OOOO000000000x,.......                                        //
//    ...............                          .............,dOO0000OOO000KKKKK0d;.......                                         //
//    ...............                           ...........,oO000000000KKKKKK0x;.                                                 //
//    ..............                             .........'lO000000000KKKK0Od:.                                                   //
//    ..............                              .......':k00000OO00000xl:'.                                                     //
//    ..............                              ......'cxO000OOOOO0Od;..                                                        //
//    ..............                               ....,cxOOOOOOOOkko:.                                                           //
//    ..............                                ..'cxkkkkkkxoc:;.                                                             //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TAHC is ERC1155Creator {
    constructor() ERC1155Creator("THE ART HEIST COLLECTION", "TAHC") {}
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
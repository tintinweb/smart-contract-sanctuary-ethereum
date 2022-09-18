// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: fucktre
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMWWNNNNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWX0kdlc:coxkkkO0KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWXKOkxddxkO0KK00KKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWX0xc,..     .....';lkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOkdc,...  ...',,''';cx0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWKkl;.   .;cl:. ....  .;oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkl,..   ..,,'.         .:xXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWKkc'.  .,dOOddOOkkOOk:  .;xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOo,.   .;dOkkkkkxoloxxo,  .;xXMMMMMWNXK0O0KKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWXkl'.  .lk0d;.  .;:;'oXd.  ,dXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0d;.  .':O0d,.  ..;ldd:lKk.  'l0WMMNKko:,'..';lkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMW0o;.  .lOOl.        .oKk'  .:OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXxc.   ;kK0d'          .,xKl.  ,dKWN0d:'.   .   .'lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMXkc'   :OOc..,.    .;d0Oc.  .:xXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0o,.  'x0xc,.''.     .,lkOd,   'l0NKd:.   'lxkkl.  'oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMXx:.  .dKd..l00OkxdxkOd;.  .,lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXkc.  .c0O;..;k0OkxolldkOx:.   .:d0XOl'   ,x0xcc0K;  .l0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMXx:.  'k0c .oXx'.';;,'.   .;lkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWMMMMMMWKd:.  'xKo..o0Kx,.':cllc,.   .,cx0XKx:.  .o0x;.:O0l.  ,oKWMMMMMMMMMMMMWWNXXNWWMMWMMMMMMMMMMMMMMWNNXKXXNWMMMMMMMMM    //
//    MMMMMMMNk:.  'O0;  :Kx.      ...,:lx0XNWMMMWWNNXNNWWWNXXNWWMMMMMMMMMMMMWNKOkxooxkOXWMWKd;.  ,O0: .oKKd.         ..':cokKXKx:.  'k0c..oKx'   .;lxOKNNNXXXXNNKOxoc::coxOkxxkOKNWMMMMMWX0xoc;,;:ldOXWMMMMMM    //
//    MMMMMMMKo'  .xK:  .dKc  .,:::cc:;,,,;clxOK0kdl::coxdoc::cok0NWMMMMMMWN0ko;...  ..'cxOkd;.  ;00,  ;KOc.  .,'....',;;,'',;co:.  ,O0;  :Xk.      ..':ooc:;;:ll:'.     ........;oOXMWX0xc,.       .,lONMMMMM    //
//    MMMMMMNk:.  lXd.  .kK;  .:c:'..        .';,..     ..     ..:dKWMMMNKko;..   .,,.   ....   .kK;   lXo.                    ..  .xK:   lNd.   .,,.   .           .:ll,   ....  .;dOkl,.   .;loo;.  .l0WMMMM    //
//    MMMMMW0o'  .kK,   .OK,  ...   .,coddo:.     .,cl;.  .:ll,  .,dKWN0d:'.  .,okOk00;    ... .lXo    oX:   .,:cloolcc:codxo'   .'oXx.   cN0c;ckOkO0c  .':looc,. ,d0kox0koxOkOk;  .;;'.  .;dOOockXl   ;xNMMMM    //
//    MMMWNOo;.  ,0k.   .kK:    ..:xOkdlccoO0c  .lOOxdkOkkOkxKK;  .:xko;.   'lOOd:..dX0olldkO0kd00'    dXd;cdOkxolllloooollOXl.:xOOxo'    .lddddl,,kKo:oOOxlclx0OOKk;.  'lxo,,xNo   .   'lOOo,. .dNd.  .lOWMMM    //
//    MMW0d;.   ,xXo.   .l0OxxxxkOkl,.     .O0ccOOc.  ..''..:00,  .:c;.  .;d0k:.    .;clolc,,xNNNx.    oWXKOl,.           .ON00Oo,.             .c0XK00d;.     ;Ok;.       .ck0d.     'd0kc.     'xKo.  'l0WMM    //
//    MXkc.   ;x0x:.      ..',;,...        .dNNXd.        ,x0x,  .;;.  .;k0d,              'dKxkXo     :x:..              'OWO:.             .'lOKXN0o'.        ...     .'oOOl'     'd0k;.        .dXl  .:xNMM    //
//    Nk:.  'xKx'               .,ldo,     .xWWXo'....   ,00;   .;'.  ,x0x,.::'.        .,d0k:.cKo      .,:loolc:;:c;.    .O0c;oxxxxo'     'okOxcdKk,'lkkc.     .dKOdooxkOx:.     .l0O;..,l,       ,00'  'oKMM    //
//    0l.  .kK:..;,.       ..:dkOOdo00,    .xXdlxkk0Kd.  oXl   ,;.  .oKk,.;O0kkkxdollloxkOd;.  cXd.    .lKXkllooddkX0,    'ONOko:,:kNo     :X0,  :0OxOOokKc     ,0Klclc:,.       ,k0l. 'xKKKd.     '0X;  .l0MM    //
//    k:.  :Kk:l0NNo.    .o0Oko;.. .dX:    .xK;  .;0K:  .xK;  .,.  'k0l..oKx' ..;:llllc:'.     ;Kx.    .kKx;      .k0,   .cKk'     cXd     ;KO.   '::,. ,0O.    '0O.     ..'.   c0O,  :0O;.lKx.    :Kk.  ,dXMM    //
//    0l'  .lkkxclKx.    .xXo.      dXc    .xK;   lXd.  .OO'      ;00;  lXx.  ..         ..'.  '0O.    .dXO:      :0O' .:k0d.  .   ,Kk.    ;KO.         .kK;    '0O.  .:llc,   lKx.  :Kk'  .kK;   .kXc  .:kWMM    //
//    NOl'.      'OO'     lNx.  ..  oXc    .xK;  .kK;   '0O.     ;0O,  ,0K,  .cooc:;;:cldxxl,  .kK,     oXKl    ;k0d,.:k0o'   ';.  'OO'    ;Kk.  ':c:.  .xK:    ,0k.  'lkx;.  lXk.  .xK:   .kX;  .oKo.  'oKMMM    //
//    MWKkl;'..  .xK;     ;KO.  .   oXc    .xK;  ,0O.   '0O.    'O0;   ;Xk.  ,o0NNXXXXNNWWXx;  .dXc     cKXo  ,x0d,.:O0o.   .:ol'  .x0,    cXd.  ,dOd,  .xK:    ,Kk.  'ldc.  ,00'   .x0,   :Kk. .dKo.  .lOWMMM    //
//    MMMWNX0d:.  oNo     .k0,      oXl    .xK;  :Kx.   .OO.    lXo    '0K;  .;d0NWMMMMWWNKx;.  cXo     cXWOdk0x,.;kKd'   .cx00o'  .dK:    dXc  .:k0d'  .xK;    ;Kx.  ,ll;.  lXd.    lXo. ,O0, 'xKl.  .cd0XNWM    //
//    MMMMMMWOc.  ;Kk.    .xK:      lXl    .xK;  oNd    .xK,   'OK,     cKO;   .;okKNNKkdc:,'   ;Kx.    lNNKd:'  .lKKc.  .:dKWXd,  .dK:   ,0k.  'oKKo'  .kK;    :Ko.  ,ll,  .xNl     .dKxo0O,.:00;   ..'',:oOX    //
//    MMMMMMMKo'  .xK,     oXl      lXl    .OO' .dNo    .dXc   ,K0,      ,x0x;.  .':oo:..       '0k.   .dNXkc:,.   .dKx'  .;dKKd'  .dK:  .xXc  .;xX0o'  .kK;    lKl   ;ll;.  dNo      .lKKo''dKd.          .,l    //
//    MMMMMMMXx,   oXl     lNd.     oXl    cXd.  oNo     :Kd.  .oXc        ,dOkl'   ..   'col;. '0k.   'OXOxdk0x'    :00:   ,loc.  'OO'  lKd.  .coo:,.  .O0,    dXc   .'..   ;Kk.       .'.l0O:     .cdxx:.  '    //
//    MMMMMMMWk:.  :Kd.    lNd.    .dXc   ,0Xl.  cXd.    .kK;  .lXKc         .cxOkc'   'x0xlxKo.;Kx.   oXd,.  :KO'    'kKl.  ...  .dXo .lXO'   ....     .O0'   ;0O'          .oXd.        ;0Xl.   .o0Oll0K;  .    //
//    MMMMMMMWOc.  '0k.    oXl    .lKO'   ,lxOkocxXd.     ;00dkOkKWNx'          'cxOkdx0k;  :Kk;dXl   .:O0Od;..lKo     .oKx'   .,lO0l. ;kK0xl:'.  .,ldocoXO. .c0NOl,.'cxkko'  .oXx'        'o0kl:o0Oc.,xKo.  '    //
//    MMMMMMMW0l'  .k0,   .kK;  .o0Ol.       .;oxkl.       ,k0o';OKxk0d,           .:dx:..;x0kokKo.     .;cxKx..k0;      ;k0doxOOxc.    ..,:oxkkkxkOdxKXkl'   .';ldkkOkl;xNo. ,xKk;          .cdxd:..o0k;   'l    //
//    MMMMMMMWKo'  .k0,   cXk. :0Oc.              .;;.       ..c0O: .;x0x:.           .,oOOo,'xNd.       .,oXx. :Kx.      .;loc'.             ..',,.;dd,.           ....l0k'.dKk;..co,            .c00c.  .;dK    //
//    MMMMMMMXx:.  ,0k.  ;0O, .OKocdxd:.        .:kXK:      .cO0l.     'lOOd:.      .:k0d;.   ;kOx:.   .:OX0l.  .dKl.          .';,'.             'ok:....           .cO0l. cXx'.cO000d'        .cO0o.  .,oONW    //
//    MMMMMW0d;.  'kKc  ;0Xl.  :kkxl:oOOxc,.',cdOOdoO0l'..;oOOo.  .','.  .,okOxl:,;oO0o'   ..   'lkOdclk0o:'     .dKd'      .:okOkxxkkdl;'.. ..'ckX0;.;O0kkdl;'....;oOOl.   'xOkkkl..:k0x:'..':dOOl.   'ckXWMM    //
//    MMMMW0l'   :O0:   .:xOkl.       .,lxkkkxdl;.  .lxkkkkd;.  .'cxOkl;.    ':odxxd:.   ':do;..  .,lddc.    .,.  .:k0xlcclxOko;.  ..,coxkkkkkkkxokKkx0k;.,coxkkkkkxo;.   .   ...      ,lxkkkkxo,.  .'cxKWMMMM    //
//    MMMMXd,  .oKx'       'xXd.  .,,..    ..    ...   ...    .,cxKWMWN0xl;'.         .'cxKNNKkl;.       ..':dko;.  .'coddo:'.   ....    ...'...  .,::,.      .....    .,ll:'.....';,..   ....    .;lkKWMMMMMM    //
//    MMMWKo'  .kXl.      .c00;  .ck0ko:;''..',;codo:,'....,;cx0XWMMMMMMWNKOxl:;,'',;cdOXWMMMMWN0ko:;,,;cdxOKWWXOo;..        ..;lxkkdl:,'..........    ..,::,'.....',;lx0XNK0OxxkO0K0ko:,'....',:lk0XWMMMMMMMM    //
//    MMMMNk:.  'oOOo'  .;k0d.  .;dXMWNXKK0OO0KXXNWNXK0OkO0KXNWMMMMMMMMMMMMMWNXXK00KXNWMMMMMMMMMMWNXKKKXNWWWMMMMWNKkdlc;,,;codkKNWMMWNXK0OkxxxkOOkxoccldk0XXK0OkkkO0KXNWMMMMMMMWMMMMMWNXK0OkkO0KXNWMMMMMMMMMMM    //
//    MMMMMXkc'   .:xOkdkOd'   .ckXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNXKKXNNWWMMMMMMMMMMMMWWWWMMMWWNNNWWMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMNKxc,.   .;:;.   .:d0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMWXOdc'.    ..,cx0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMWXOxdllldk0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWWNNNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract tre is ERC721Creator {
    constructor() ERC721Creator("fucktre", "tre") {}
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
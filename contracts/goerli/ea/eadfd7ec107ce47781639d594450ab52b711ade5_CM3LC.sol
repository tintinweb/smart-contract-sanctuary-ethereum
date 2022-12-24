// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 3LC
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%aonXH7=Ktl]((llr?x1C#[email protected]@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@0pPfK(,`______________________)[email protected]@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@0RcY),`________________________________:[email protected]@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@wZ7\,.________________________________________,>[email protected]@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@0#J}:`[email protected]@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@hC<[email protected]@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@gcj'`_________________________________________________________"[email protected]@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@6Il'`_____________________`,::;;-;;-;':,._________________________`[email protected]@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@9GK;`________________,'i!j=JcPnOpebbbbbgeEkUNx+~i:[email protected]@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@9dhhha0%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@o7*._____________.;"[email protected]@@@@@@@@@@@@@@@@@@@@@MgZf]",[email protected]@@@    //
//    @@@@@@@@@@@@@@@@@@@mePTr),________*[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@8G+;___________.'*[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@gIji`[email protected]@@    //
//    @@@@@@@@@@@@@@@84^j:.__________________,[email protected]@@@@@@@@@@@@@@@@@@@@@@aN(,_________.-}[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@D4Y*`[email protected]@@    //
//    @@@@@@@@@@@@%Rx*._________________________`L#%@@@@@@@@@@@@@@@@@@g7*._______.;}[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@RK-_____________"[email protected]@    //
//    @@@@@@@@@@0Xl'_______________________________|[email protected]@@@@@@@@@@@@@@e>i`______:!=Pb%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@M2)`[email protected]@    //
//    @@@@@@@@mJ!,[email protected]@@@@@@@@@@q>i`____`;\[email protected]@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@R],[email protected]@    //
//    @@@@@@@@d]._____________________________________;[email protected]@@@@@@@bvi`[email protected]@@@@@@@@@@0H,[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@Sj,__________<@@    //
//    @@@@@@@@@Z)______________________________________`[email protected]@@@@d^*`__.-<[email protected]@@@@@@@@@%5I=",[email protected]@@@@@@@@@@@@@@@@@@@@@@@@g<[%@@@@@@@@@@@@@@@@@@@@e{`[email protected]@    //
//    @@@@@@@@@@N*[email protected]@MF|._`;[email protected]@@@@@@@@@@@@@Dd>';Yf^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@    //
//    @@@@@@@@@@%f"______________________________________i&R+'`'/[email protected]@@@@@@@@@@@@@@@@@@#\[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@V;[email protected]@    //
//    @@@@@@@@@@@Dzi______________________________________*-'|[email protected]@@@@@@@@@@@@@@@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@g|[email protected]@    //
//    @@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@x'[email protected]@    //
//    @@@@@@@@@@@@@0<'[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&pU1>r{~!"!){ty1PW&@@@@@@@@@@@@@#[email protected]@    //
//    @@@@@@@@@@@@@@a+,[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@b3>),`_________________"[email protected]@@@@@@@@@@9{[email protected]@@    //
//    @@@@@@@@@@@@@@@gl,__`'!rzuH1y}-`[email protected]@@@@8gOQ2^>K/}~i)[email protected]@@@@@@@@@@@@@@@@@@@@@@62\:`[email protected]@@@@@@@@@@@Y,[email protected]@@    //
//    @@@@@@@@@@@@@@@@bK*}[email protected]@@@@@DWY"_____________________y42v/"[email protected]@@@@@@@@@@@@@@@@@@@@W=-`[email protected]@@@@@@@@@@@@1;[email protected]@@    //
//    @@@@@@@@@@@@@@@@@@$%@@@@@@@@@@@%[email protected]@@@@@@@@@@@@@@@@@@g=-__________________________-&@@@@@@@@@@@@@[email protected]@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@x'[email protected]@@@@@@@@@@@@@@@@8N!`[email protected]@@@@@@@@@@@@@s"___*[email protected]@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@n*[email protected]@@@@@@@@@@@@@@@bL'____________________________]@@@@@@@@@@@@@@@s"[email protected]@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@k*_______________________________________*@@@@@@@@@@@@@@@@4}[email protected]@@@@@@@@@@@@@@s"[email protected]@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@7'_______________________________________>@@@@@@@@@@@@@@@s)[email protected]@@@@@@@@@@@@@@@X-_*[email protected]@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@n)______________________________,[email protected]@@@@@@@@@@@@@@@1'`[email protected]@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BT"_________________________________________&@@@@@@@@@@@@@W|`[email protected]@@@@@@@@@%[email protected]@@@@[email protected]@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@FlvCPX1r-.___________________..____________________]@@@@@@@@@@@@@&j._______________________'*+Y?/*}[email protected]@@@@@@@@@[email protected]@@@[email protected]@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@w}____________________________f|[email protected]@@@@@@@@@@@@x;_____________________.([email protected]@@@[email protected]@@@@@@@@@B|_]@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@Z*___________________________T%[email protected]@@@@@@@@@@@4)_____________________)[email protected]@@@@@@@@@@@@@@@@@@Ii_:[email protected]@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@^'[email protected]@C"__________________;%@@@@@@@@@@@%K,[email protected]@@@@@@@@@@@@@@@@@@@g}`[email protected]@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@L.________________________([email protected]@@9t,[email protected]@@@@@@@@@@@W([email protected]@@@@@@@@@@@@@@@@@@@@Sj.___*[email protected]@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@M}______________________,)[email protected]@@@@Sl,[email protected]@@@@@@@@@@@m3r*:[email protected]@@@@@@@@@@@@@@@@@@@8F)[email protected]@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@w|__________________,"[email protected]@@@@@@@6y*`_____________,[email protected]@@@@@@@@@@@@@@6Gz]*;,`_______.:[email protected]@@@@@@@@@@@@@@@@0R1(,________{[email protected]@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@e)[email protected]@@@@@@@@@@@@@RT},___________<@@@@@@@@@@@@@@@@@@@@&[email protected]@@@@@@@@@@@@@M^\[email protected]@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@R)___________________tZ%@@@@@@@@@@@@@&c"[email protected]@@@@@@@@@@@@@@@@@@@96o#[email protected]@@@@@@@@@@@@@@mTj*'________________{[email protected]@@@@    //
//    @@@@@@@@@@@@@@@@@@@@MX7<)[email protected]@@@@@@@@0Pr'[email protected]@@@@@@@@@@@@@@aZT/-`[email protected]@@@@@@@@@@@@@@@@&GLi____________.;*\[email protected]@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@De2];_______________`[email protected]@@@@@9c),______________<@@@@@@@@@@@@@DnK;`________________(%@@@@@@@@@@@@@@@@@@DP}._______."[email protected]@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@mP{,[email protected]@@@pj:[email protected]@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@p\._____"[email protected]@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@gj,______________`[email protected]@s)`[email protected]@@@@@@@@@@@@e(____________________`[email protected]@@@@@@@@@@@@@@@@@@@n)____<&@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#)[email protected][email protected]@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@=:__[%@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@D]`_______________n}`__________________LRRWeS6d9%@@@@@@F"______________________'^[email protected]@@@@@@@@@@@@@@@@Z*_'[email protected]@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%]`_______________,._____________________________'!{/[vx!_________________________}[email protected]@@@@@@@@@@a\:[email protected]@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@R)________________________[email protected]@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@[email protected]@@@@@@@@@@wt,_________________________[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@W?-_[email protected]@@@@@@Ol,________________________________________________________________________________________}[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@W?-__________|=J1f=('_____________________________[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@W?-_______________________________________________________________________________________________________________'&@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@pY-_______________________________________`____________[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@qY-________________________________________)t.______________________________________________)~:[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@H"________________________________________'p\_______________________________________________2dFji.______________________*[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@mVi______________________________________"qa}[email protected]@DoA+*:`[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@Mu~`___________________________________/[email protected]@v"_____________________________________________,[email protected]@@@@@Bnf+*-,`______________`[email protected]@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@4l'________________________________;[email protected]@@Dnx{*-',.`[email protected]@@@@@@@@@@9eZcxr}*"i-;;;;-i!<&@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@0H(,____________________________;[email protected]@@@@@@@@0bW5GFA7Yt{!*"-;':,..`[email protected]@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@wA};`______________________:)[email protected]@@@@@@@@@@@@@@@@@@@@@%8&6SpR5sU3IcuuTzV?L/\))****"""[email protected]@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@m5z|-,______________`:i][email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@8X|[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@[email protected](*i-;;-i*{?^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@9X},[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@&|[email protected]@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&c|,_;[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@q([email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@D4?-`__;I%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Bc{:___`[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@W)[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@9Z[-`____*[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@6|______{[email protected]@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@b\([email protected]@@@@@@@@@@@@@@@@@@@@@@@m4x*,_____:^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@M]`______.^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@D%@@@@@@@@@@@@@@@@@@@@@@8#z!,[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@v:[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@wQ=i._______./[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@s!__________;^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@941]:`________.][email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@9l`[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@d#1/'.__________.\[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@F*[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@$EI=(,`____________,/[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@mr,_________________-KA#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@%aWUfK!,`_______________:[[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@e{`_____________________,{?JIsRqB0mDDDDDD9dheOsFuVr(,`___________________`"[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@Z)____________________________________________________________________:[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@U(`_______________________________________________________________.*[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@5{,_[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@h[i_______________________________________________________.i<U&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@DP{'__________________________________________________:!yG&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@$c{;____________________________________________,[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@9QK*,____________________________________`:"j^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@bC?!;.___________________________.:i{[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@0EFVl*-',`___________`.,;i*l=HQp&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@9hRZ3N^zV===z7^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CM3LC is ERC721Creator {
    constructor() ERC721Creator("3LC", "CM3LC") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xEB067AfFd7390f833eec76BF0C523Cf074a7713C;
        Address.functionDelegateCall(
            0xEB067AfFd7390f833eec76BF0C523Cf074a7713C,
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
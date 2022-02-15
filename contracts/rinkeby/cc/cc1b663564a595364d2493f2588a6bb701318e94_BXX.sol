// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Boxerppppp
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                    //
//                                                                                                                    //
//    777777777777777777777777777777777777777777777777777777777777777777777777777777777777777                         //
//    77777777777777777777777777777777777777777777771lvJCCCC2Jtji77777777777777777777777777777777777777777            //
//    777777777777777777777777777777777777777777l2Y8UfhxxxxxxxhfU4Lzj7777777777777777777777777777777777777            //
//    777777777777777777777777777777777777777o5ShxxhfVVVVVVVVVVffhxxf8el7777777777777777777777777777777777            //
//    777777777777777777777777777777777777i28hxhVVVVVVVVVVVVVVVVVVVVfhxh4zi7777777777777777777777777777777            //
//    7777777777777777777777777777777777inUxhVVVVVVVVVVVVVVVVVVVVVVVVVVVhxTCi77777777777777777777777777777            //
//    7777777777777777777777777777777772UxfVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVhxTz7777777777777777777777777777            //
//    7777777777777777777777777777777l4xhVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVhx0j77777777777777777777777777            //
//    777777777777777777777777777777nfhVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVxfC7777777777777777777777777            //
//    77777777777777777777777777771axfVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVfxsi77777777777777777777777            //
//    777777777777777777777777777jTxVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVxSj7777777777777777777777            //
//    77777777777777777777777777oVhVVVVVVVVVVVVVVffhhxxxxhhhhhxxhfVVVVVVVVVVVVVVVVhVo777777777777777777777            //
//    7777777777777777777777777tfhVVVVVVVVVVVVfxxfT4sO5CJtolovJnYShxfVVVVVVVVVVVVVVhft77777777777777777777            //
//    777777777777777777777777ofhVVVVVVVVVVVhxUYzji77777777777777roLVxVVVVVVVVVVVVVVhfo7777777777777777777            //
//    77777777777777777777777jVhVVVVVVVVVVhh0J1777777777777777777777IYxfVVVVVVVVVVVVVhVI777777777777777777            //
//    7777777777777777777777iShVVVVVVVVVfx0v777777777777777777777777772hhVVVVVVVVVVVVVhSi77777777777777777            //
//    7777777777777777777777sxVVVVVVVVVhV277777777777777777777777777777vTxVVVVVVVVVVVVVxs77777777777777777            //
//    777777777777777777777CxVVVVVVVVVhTj7777777777777777777777777777777isxVVVVVVVVVVVVVxC7777777777777777            //
//    77777777777777777777jhfVVVVVVVVffl7777777777777777777777777777777777exVVVVVVVVVVVVffj777777777777777            //
//    777777777777777777770xVVVVVVVVVxC777777777777777777777777777777777777exVVVVVVVVVVVVx0777777777777777            //
//    7777777777777777777zxVVVVVVVVVh07777777777777777777777777777cI777ez777sxVVVVVVVVVVVVxz77777777777777            //
//    777777777777777777iThVVVVVVVVfhl7777777777777777777777777777Uu777C9YI7rUfVVVVVVVVVVVhTi7777777777777            //
//    777777777777777777nxVVVVVVVVVxL7l777777777777cz777777777777e6I7777CPf0CahVVVVVVVVVVVVxC7777777777777            //
//    77777777777777777iTfVVVVVVVVfV17j77777777777r0o7777777777736Vi77777T4eUxVVVVVVVVVVVVVhTr777777777777            //
//    77777777777777777zxVVVVVVVVVxn7c777777777777zT77777777777zhSS77777rzx37axVVVVVVVVVVVVVxz777777777777            //
//    777777777777777774hVVVVVVVVfU75v7777777777775O7777777777lxJOO7I2sTVVf90C8xfVVVVVVVVVVVh0777777777777            //
//    7777777777777777lhVVVVVVVVVxzjO7777777777777C57777777777r17VO0hUsCvlIj3zl38UUVVVVVVVVVVhl77777777777            //
//    7777777777777777exVVVVVVVVfUrOI7777777777777tT777777777777LGfOo77777777IVyXqZUVVVVVVVVVxu77777777777            //
//    77777777777777778hVVVVVVVVxnoe77777777777777Iht777777777756Lc777777777LNHHHMMmfVVVVVVVVh877777777777            //
//    777777777777777jffVVVVVVVffcej77771olr777777iVO7777777770ht77777777772MHw6RHMw9UfVVVVVVffI7777777777            //
//    7777777777777772xVVVVVVVVhaiO777r5VhhTJ7777778Ur77777770fc77777777777DHEw6eqfsRUVVVVVVVVxz7777777777            //
//    777777777777777OxVVVVVVVVx2IL777Y9fVVhxJ77777a9o7777775hc77777777777lHHHHHKbdHH98VVVVVVVxL7777777777            //
//    7777777777777774hVVVVVVVVfj1l77txVVVVVhTi7777O6u77777t6o777777777777jVUUUUxp6Uf58fVVVVVVh47777777777            //
//    777777777777771UfVVVVVVVfTr77775xVVVVVVho777756077777UL7777777777777777777oT777rUfVVVVVVfUi777777777            //
//    77777777777777jffVVVVVVVha77777LxVVVVVVxv7777n9U1777zhi77777ol777777777777ss777lhVVVVVVVffj777777777            //
//    77777777777777thVVVVVVVVxL7777729VVVVVffI7777Cxho777S5777777jI77777777777rfJ7772xVVVVVVVVht777777777            //
//    77777777777777JxVVVVVVVVxu77777iTxVVVVxL77777Lxx277Ihj7777777777777777777th1777LxVVVVVVVVxJ777777777            //
//    777777777777772xVVVVVVVVxn777777lU9xVVhar77770hx577zU7777777iOi7jL7777777O477770hVVVVVVVVx2777777777            //
//    77777777777777CxVVVVVVVVxe7777777i2OVfV9v7771Ufhs77e477777777I77rc7777777U271iiUfVVVVVVVVxC777777777            //
//    77777777777777nxVVVVVVVVhs777777777709hxl777JxVh077Os77777lr777777777777oh17rrlhVVVVVVVVVxC777777777            //
//    77777777777777CxVVVVVVVVfTi777777777j0S277774hVh077La77777l7777777777777O47lr7zxVVVVVVVVVxC777777777            //
//    777777777777772xVVVVVVVVVxJ77777777777777772xVVha77nS777777777777777777rVz7cr75xVVVVVVVVVx2777777777            //
//    77777777777777JxVVVVVVVVVhTi77777777777777offVVxL77oh1777777777777777773hi7zI70hVVVVVVVVVxJ777777777            //
//    77777777777777thVVVVVVVVVVx01777777777777JVhVVVxz77rVC777777777777777778Y7777cVfVVVVVVVVVht777777777            //
//    77777777777777jffVVVVVVVVVVxTCj7777777itshfVVVfVc777Chi777777777777777z9j7777CxVVVVVVVVVffj777777777            //
//    777777777777771UfVVVVVVVVVVVfxfSs5uu5sThhVVVVV95777774Tr7777777777777oxT777778hVVVVVVVVVfUi777777777            //
//    7777777777777774hVVVVVVVVVVVVVfhhxxxxhfVVVVVVx8i77777iSVv77777777777vfxho777JxVVVVVVVVVVh47777777777            //
//    777777777777777OxVVVVVVVVVVVVVVVVVVVVVVVVVfxxs177777777LxTuvIirrcoCaxhVxL771UfVVVVVVVVVVxL7777777777            //
//    777777777777777zxVVVVVVVVVVfxhfVVVVVVVfhxxVsv7777ri77777IeSVffVVffh9fVVfU7r0xVVVVVVVVVVVxz7777777777            //
//    777777777777777jffVVVVVVVVh4u4UhxxxxxhV8OJc777777it77777777iIovtl1IUfVVVhe0xVVVVVVVVVVVffI7777777777            //
//    77777777777777778hVVVVVVVVxo771l3z2zvlc7777777777rn7777777777777777ahVVVVhhVVVVVVVVVVVVh877777777777            //
//    7777777777777777exVVVVVVVxs77777777777777777777777Ll7777777777777770hVVVVVVVVVVVVVVVVVVxu77777777777            //
//    7777777777777777lhVVVVVVfVj77777777777777777777777347777777777777770hVVVVVVVVVVVVVVVVVVhj77777777777            //
//    777777777777777774hVVVVVhs7co77777777777777777777778O77777777777777u9VVVVVVVVVVVVVVVVVh0777777777777            //
//    77777777777777777zxVVVVVfUI7i7ri7777777777777777777cf0I7777777777777axfVVVVVVVVVVVVVVVxz777777777777            //
//    77777777777777777iTfVVVVVhUo77Il77777777777777777777c8xstr77777777leUUVVVVVVVVVVVVVVVhTr777777777777            //
//    777777777777777777CxVVVVVVhh51777777777777777777777777v4xV05CzCeaUhTJLhVVVVVVVVVVVVVVxC7777777777777            //
//    777777777777777777iThVVVVVVfxUuc777777777777777777777777c2Y8UUT8Y2j7ohfVVVVVVVVVVVVVhTr7777777777777            //
//    7777777777777777777zxVVVVVVVVfxVLo777777777777777777777777777777777iUhVVVVVVVVVVVVVVxJ77777777777777            //
//    777777777777777777770xVVVVVVVVVfxh4CI777777777777777777777777777777YxVVVVVVVVVVVVVVx0777777777777777            //
//    77777777777777777777jffVVVVVVVVVVVhxV0Cj7777777777777777777Jsz7777zxVVVVVVVVVVVVVVffj777777777777777            //
//    777777777777777777777CxVVVVVVVVVVVVVfhxf853c777777777777775XXXO77IVfVVVVVVVVVVVVVVxC7777777777777777            //
//    7777777777777777777777sxVVVVVVVVVVVVVVVfhxxV453c777777777rZbybkr70xVVVVVVVVVVVVVVxs77777777777777777            //
//    7777777777777777777777iShVVVVVVVVVVVVVVVVVVfhxxV05vc77777rPdybg7zxVVVVVVVVVVVVVVhSi77777777777777777            //
//    77777777777777777777777jVhVVVVVVVVVVVVVVVVVVVVVfhxxU0ev177CbXduiVfVVVVVVVVVVVVVhUI777777777777777777            //
//    777777777777777777777777ofhVVVVVVVVVVVVVVVVVVVVVVVVfhxhU0uoJel7sxVVVVVVVVVVVVVhVl7777777777777777777            //
//    7777777777777777777777777ofhVVVVVVVVVVVVVVVVVVVVVVVVVVVfhxhSLznhVVVVVVVVVVVVVhVo77777777777777777777            //
//    77777777777777777777777777oVhVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVfhxhVVVVVVVVVVVVVxUl777777777777777777777            //
//    777777777777777777777777777jSxVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVxSI7777777777777777777777            //
//    77777777777777777777777777771sxfVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVfxYi77777777777777777777777            //
//    777777777777777777777777777777nhxVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVxfC7777777777777777777777777            //
//    7777777777777777777777777777777l0xhVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVhx0j77777777777777777777777777            //
//    7777777777777777777777777777777772TxfVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVhxTz7777777777777777777777777777            //
//    7777777777777777777777777777777777inTxhVVVVVVVVVVVVVVVVVVVVVVVVVVfhxTCi77777777777777777777777777777            //
//    777777777777777777777777777777777777i24hxhfVVVVVVVVVVVVVVVVVVVfhxf0zi7777777777777777777777777777777            //
//    777777777777777777777777777777777777777le8fxxhffVVVVVVVVVffhxxf8ul7777777777777777777777777777777777            //
//    777777777777777777777777777777777777777777j2O4UfhxxxxxxxhfU4Lzj7777777777777777777777777777777777777            //
//    77777777777777777777777777777777777777777777771jtJ2CCCz3oji77777777777777777777777777777777777777777            //
//    7777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777            //
//    7777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777            //
//    7777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777            //
//    7777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777            //
//    7777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777            //
//    777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777                   //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BXX is ERC721Creator {
    constructor() ERC721Creator("Boxerppppp", "BXX") {}
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
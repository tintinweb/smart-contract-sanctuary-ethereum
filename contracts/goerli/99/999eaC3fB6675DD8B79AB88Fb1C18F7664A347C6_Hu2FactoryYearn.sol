// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Hu2InterestDistributor } from "./Hu2InterestDistributor.sol";
import { IHu2FactoryYearn } from "./interfaces/IHu2FactoryYearn.sol";
import { IHu2TokenYearn } from "./interfaces/IHu2TokenYearn.sol";
import { Hu2TokenYearn } from "./Hu2TokenYearn.sol";


/**
 * @title Hu2FactoryYearn
 * @author Hysland Finance
 * @notice A factory that creates Hu2Tokens around Yearn Vaults.
 *
 * New Hu2TokenYearns can be deployed via [`deployHu2Token()`](#deployhu2token). This is initially restricted to only owner, but can be made permissionless via [`setPermissionlessCreation()`](#setpermissionlesscreation). The factory's [`owner()`](#owner), [`treasury()`](#treasury), [`interestShare()`](#interestshare), and [`distributor()`](#distributor) will be copied to the Hu2TokenYearn instance. Of these, all except the [`distributor()`](#distributor) can be modified in each Hu2TokenYearn instance.
 *
 * The owner can also [`setInterestShare()`](#setinterestshare) and [`transferOwnership()`](#transferownership).
 */
contract Hu2FactoryYearn is IHu2FactoryYearn {

    /***************************************
    STATE VARIABLES
    ***************************************/

    struct OwnerSettings {
        address owner;
        bool permissionlessCreationEnabled;
    }
    OwnerSettings internal _ownerSettings;

    // note that more than one hu2token may be deployed for the same yearn vault. only the first will be added to this mapping
    mapping(address => mapping(uint256 => address)) internal _vaultTokenToHu2Tokens;
    mapping(address => uint256) internal _vaultTokenToHu2TokensLength;
    // stored as an array, enumerable [1,length]
    mapping(uint256 => address) internal _indexToHu2Token;
    uint256 internal _countHu2Tokens;

    // the address of the Hu2InterestDistributor. set on construction, cannot be modified
    // has no purpose in this contract other than being passed to the deployed Hu2TokenYearn instances
    address internal _distributor;
    // the percent of interest from reinvestments that are directed towards holders (namely liquidity pools and liquidity providers)
    // the rest goes to the treasury and integrators
    // can be modified in each hu2token instance
    // has 18 decimals of precision
    uint256 internal _interestShare;
    uint256 internal constant MAX_INTEREST_SHARE = 1 ether;
    // the address to receive the interest not directed towards holders
    // can be modified in each hu2token instance
    address internal _treasury;

    /**
     * @notice Constructs the Hu2FactoryYearn.
     * @param owner_ The owner of the contract.
     * @param distributor_ The address of the [`Hu2InterestDistributor`](./Hu2InterestDistributor).
     */
    constructor(address owner_, address distributor_) {
        _ownerSettings.owner = owner_;
        _distributor = distributor_;
        _interestShare = MAX_INTEREST_SHARE;
    }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice The number of Hu2Tokens that have been deployed by this contract.
     * @return count The number of Hu2Tokens.
     */
    function countHu2Tokens() external view override returns (uint256 count) {
        return _countHu2Tokens;
    }

    /**
     * @notice Enumerates all Hu2Tokens that have been deployed by this contract.
     * Enumerable [1,length].
     * @param index The index of the Hu2Token to query.
     * @return hu2Token The address of the Hu2Token.
     */
    function hu2Tokens(uint256 index) external view override returns (address hu2Token) {
        return _indexToHu2Token[index];
    }

    /**
     * @notice The number of Hu2Tokens that have been deployed by this contract for a given Yearn Vault.
     * @param vault The address of the Yearn Vault to query,
     * @return count The number of Hu2Tokens.
     */
    function countHu2TokensForVault(address vault) external view override returns (uint256 count) {
        return _vaultTokenToHu2TokensLength[vault];
    }

    /**
     * @notice Enumerates all Hu2Tokens that have been deployed by this contract for a given Yearn Vault.
     * Enumerable [1,length].
     * @param vault The address of the Yearn Vault to query,
     * @param index The index of the Hu2Token to query.
     * @return hu2Token The address of the Hu2Token.
     */
    function hu2TokensForVault(address vault, uint256 index) external view override returns (address hu2Token) {
        return _vaultTokenToHu2Tokens[vault][index];
    }

    /**
     * @notice The status of permissionless creation. If enabled, anyone can deploy a new contract. Otherwise, restricted to only contract owner.
     * @return permissionlessCreationEnabled_ True if enabled, false if disabled.
     */
    function permissionlessCreationEnabled() external view override returns (bool permissionlessCreationEnabled_) {
        return _ownerSettings.permissionlessCreationEnabled;
    }

    /**
     * @notice The address of the [`Hu2InterestDistributor`](./Hu2InterestDistributor).
     * @return distributor_ The distributor.
     */
    function interestDistributor() external view override returns (address distributor_) {
        return _distributor;
    }

    /**
     * @notice The percent of interest from reinvestments that are directed towards holders (namely liquidity pools and liquidity providers). The rest goes to the treasury and integrators. Has 18 decimals of precision. Can be modified in each Hu2Token instance.
     * @return interestShare_ The interest share with 18 decimals of precision.
     */
    function interestShare() external view override returns (uint256 interestShare_) {
        return _interestShare;
    }

    /**
     * @notice The owner of the contract.
     * @return owner_ The owner.
     */
    function owner() external view override returns (address owner_) {
        return _ownerSettings.owner;
    }

    /**
     * @notice The address to receive the interest not directed towards holders. Can be modified in each hu2token instance.
     * @return treasury_ The treasury address.
     */
    function treasury() external view override returns (address treasury_) {
        return _treasury;
    }

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Deploys a new Hu2TokenYearn.
     * Can only be called by the contract owner unless permissionless creation is enabled.
     * @param vault The address of the Yearn Vault to reinvest into.
     * @param name The name of the new token.
     * @param symbol The symbol of the new token.
     * @param decimals The decimals of the new token.
     */
    function deployHu2Token(address vault, string calldata name, string calldata symbol, uint8 decimals) external override returns (address hu2Token) {
        // checks
        OwnerSettings memory os = _ownerSettings;
        require(os.permissionlessCreationEnabled || os.owner == msg.sender, "Hu2TF: unauth create");
        // deploy
        bytes32 salt = keccak256(abi.encode(vault, name, symbol));
        hu2Token = address(new Hu2TokenYearn{salt: salt}());
        IHu2TokenYearn(hu2Token).initialize(IHu2TokenYearn.InitializationParams({
            name: name,
            symbol: symbol,
            decimals: decimals,
            vault: vault,
            distributor: _distributor,
            treasury: _treasury,
            owner: os.owner,
            interestShare: _interestShare
        }));
        // add to mapping
        _indexToHu2Token[++_countHu2Tokens] = hu2Token;
        _vaultTokenToHu2Tokens[vault][++_vaultTokenToHu2TokensLength[vault]] = hu2Token;
        emit TokenCreated(vault, hu2Token);
    }

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Sets the percent of interest from reinvestments that are directed towards holders (namely liquidity pools and liquidity providers). The rest goes to the treasury and integrators. Has 18 decimals of precision. Can be modified in each Hu2Token instance.
     * @param interestShare_ The interest share with 18 decimals of precision.
     * @param treasury_ The address to receive the rest of the interest.
     */
    function setInterestShare(uint256 interestShare_, address treasury_) external override {
        require(_ownerSettings.owner == msg.sender, "Hu2TF: unauth modify ishare");
        _setInterestShare(interestShare_);
        _treasury = treasury_;
    }

    /**
     * @notice Enable or disable permissionless creation.
     * Can only be called by the contract owner.
     * @param status True to enable permissionlessness, false to disable.
     */
    function setPermissionlessCreation(bool status) external override {
        require(_ownerSettings.owner == msg.sender, "Hu2TF: unauth modify pcreate");
        _ownerSettings.permissionlessCreationEnabled = status;
    }

    /**
     * @notice Transfers ownership of the contract to a new account.
     * Can only be called by the current owner.
     * @param newOwner The address to transfer the ownership role to.
     */
    function transferOwnership(address newOwner) external override {
        address oldOwner = _ownerSettings.owner;
        require(msg.sender == oldOwner, "Hu2TF: !owner");
        _ownerSettings.owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /***************************************
    HELPER FUNCTIONS
    ***************************************/

    /**
     * @notice Sets the percent of interest from reinvestments that are directed towards holders (namely liquidity pools and liquidity providers). The rest goes to the treasury and integrators. Has 18 decimals of precision. Can be modified in each Hu2Token instance.
     * @param interestShare_ The interest share with 18 decimals of precision.
     */
    function _setInterestShare(uint256 interestShare_) internal {
        require(interestShare_ <= MAX_INTEREST_SHARE, "Hu2TF: invalid interest share");
        _interestShare = interestShare_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IUniswapV2Pair } from "./interfaces/external/uniswap/v2/IUniswapV2Pair.sol";
import { IHu2Token } from "./interfaces/IHu2Token.sol";
import { IHu2InterestDistributor } from "./interfaces/IHu2InterestDistributor.sol";


/**
 * @title Hu2InterestDistributor
 * @author Hysland Finance
 * @notice Distributes interest earned from reinvestments into Uniswap V2 pools.
 *
 * Each Uniswap V2 pool contains two tokens. This contract rebases them at the same time then syncs the reserves. It works whether the tokens are hu2 tokens or not, or whatever interest bearing protocol they use.
 *
 * A single pool can be rebased via [`distributeInterestToPool()`](#distributeinteresttopool). Multiple pools can be rebased in one call via [`distributeInterestToPools()`](#distributeinteresttopools).
 */
contract Hu2InterestDistributor is IHu2InterestDistributor {

    /***************************************
    STATE VARIABLES
    ***************************************/

    // store locally. saves gas
    struct UniswapV2PoolData {
        address token0;
        address token1;
    }
    mapping(address => UniswapV2PoolData) internal _poolDatas;

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Distributes interest to a Uniswap V2 pool.
     * @param pool The address of the Uniswap V2 pool to distribute interest to.
     */
    function distributeInterestToPool(address pool) external override {
        (address token0, address token1) = _getTokens(pool);
        // for each token distribute interest to pool
        // revert usually means the token is not a Hu2Token and has no matching sighash
        // use low level calls to allow revert
        bytes memory data = abi.encodeWithSelector(IHu2Token(token0).distributeInterestToPool.selector, pool);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success1, ) = token0.call(data);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success2, ) = token1.call(data);
        if(success1 || success2) {
            // sync pool to new balances
            IUniswapV2Pair(pool).sync();
            emit InterestDistributed(pool);
        }
    }

    /**
     * @notice Distributes interest to multiple Uniswap V2 pools.
     * @param pools The list of Uniswap V2 pools to distribute interest to.
     */
    function distributeInterestToPools(address[] calldata pools) external override {
        // loop over pools
        for(uint256 i = 0; i < pools.length; i++) {
            address pool = pools[i];
            (address token0, address token1) = _getTokens(pool);
            // for each token distribute interest to pool
            // revert usually means the token is not a Hu2Token and has no matching sighash
            // use low level calls to allow revert
            bytes memory data = abi.encodeWithSelector(IHu2Token(token0).distributeInterestToPool.selector, pool);
            // solhint-disable-next-line avoid-low-level-calls
            (bool success1, ) = token0.call(data);
            // solhint-disable-next-line avoid-low-level-calls
            (bool success2, ) = token1.call(data);
            if(success1 || success2) {
                // sync pool to new balances
                IUniswapV2Pair(pool).sync();
                emit InterestDistributed(pool);
            }
        }
    }

    /***************************************
    HELPER FUNCTIONS
    ***************************************/

    /**
     * @notice Gets the tokens in a Uniswap V2 pool.
     * @param pool The address of the pool to query.
     * @return token0 The pool's token0.
     * @return token1 The pool's token1.
     */
    function _getTokens(address pool) internal returns (address token0, address token1) {
        // uses cache for gas savings
        // try fetch from cache
        UniswapV2PoolData memory data = _poolDatas[pool];
        if(data.token0 != address(0x0)) return (data.token0, data.token1);
        // external calls
        token0 = IUniswapV2Pair(pool).token0();
        token1 = IUniswapV2Pair(pool).token1();
        // write to cache
        _poolDatas[pool] = UniswapV2PoolData({
            token0: token0,
            token1: token1
        });
        return (token0, token1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IHu2TokenYearn } from "./interfaces/IHu2TokenYearn.sol";
import { IYearnVault } from "./interfaces/external/yearn/IYearnVault.sol";
import { HwTokenBase } from "./HwTokenBase.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


/**
 * @title Hu2TokenYearn
 * @author Hysland Finance
 * @notice An interest bearing token designed to be used in Uniswap V2 pools. This version earns interest by reinvesting deposits into Yearn Vaults.
 *
 * ```
 * ------------------------
 * | hyswap wrapper token | eg hu2yvDAI
 * | -------------------- |
 * | |   vault token    | | eg yvDAI
 * | | ---------------- | |
 * | | |  base token  | | | eg DAI
 * | | ---------------- | |
 * | -------------------- |
 * ------------------------
 * ```
 *
 * There are three tokens at play: the base token (aka underlying) (eg DAI), the Yearn Vault token (eg yvDAI), and the hu2 token (eg hu2yvDAI). Users can deposit and withdraw to either the base token or the vault token using [`depositBaseToken()`](#depositbasetoken), [`depositVaultToken()`](#depositvaulttoken), [`withdrawBaseToken()`](#withdrawbasetoken), or [`withdrawVaultToken()`](#withdrawvaulttoken). The hu2Token is 1:1 pegged to and redeemable for the base token. Note that the amount received during deposit and withdraw may be different by a dust amount due to integer division.
 *
 * Accounts accrue interest when the Yearn Vault's price per share (abbreviated pps) increases relative to their [`lastPpsOf()`](#lastppsof). This is updated on every balance modifying or interest accruing call.
 *
 * This contract has an [`owner()`](#owner) that can [`setInterestShare()`](#setinterestshare) and [`transferOwnership()`](#transferownership).
 */
contract Hu2TokenYearn is IHu2TokenYearn, HwTokenBase {

    // dev: we could enhance readability and DRY by extracting code from
    // accrueInterest() and distributeInterestToPool() to _accrueInterestToBalance()
    // same with accrueInterestMultiple() and _beforeTokenTransfer() to _accrueInterestToUnpaidInterest()
    // as its written is more runtime gas efficient

    /***************************************
    STATE VARIABLES
    ***************************************/

    // the address of the Hu2InterestDistributor. set on initialization, cannot be modified
    address internal _distributor;
    // the address of the base token
    address internal _baseToken;
    // the address of the yearn vault for reinvestment
    address internal _vaultToken;
    // the address to receive the interest not directed towards holders
    // can be modified in each hu2token instance
    address internal _treasury;
    // the address of the contract owner
    // only power is to set interest share
    address internal _owner;

    // the percent of interest from reinvestments that are directed towards holders (namely liquidity pools and liquidity providers)
    // the rest goes to the treasury and integrators. has 18 decimals of precision
    uint256 internal _interestShare;
    uint256 internal constant MAX_INTEREST_SHARE = 1 ether;
    // the vault's price per share as of the last time this account's interest was accrued
    mapping(address => uint256) internal _lastPps;
    // the interest claimable by account. does not account for yearn gains since last update
    mapping(address => uint256) internal _unpaidInterest;

    // 10 ** decimals. saves gas by not recomputing every time
    uint256 internal _oneToken;

    /***************************************
    INITIALIZER
    ***************************************/

    /**
     * @notice Initializes the Hu2Token.
     * Can only be called once.
     * @param params The initialization parameters.
     */
    function initialize(InitializationParams calldata params) external override {
        _initialize(params.name, params.symbol, params.decimals);
        _baseToken = IYearnVault(params.vault).token();
        _vaultToken = params.vault;
        _distributor = params.distributor;
        _setInterestShare(params.interestShare);
        _treasury = params.treasury;
        _owner = params.owner;
        _oneToken = 10 ** params.decimals;
    }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Returns the address of the base token.
     * @return token The base token.
     */
    function baseToken() external view override returns (address token) {
        return _baseToken;
    }

    /**
     * @notice Returns the address of the Yearn vault token.
     * @return token The vault token.
     */
    function vaultToken() external view override returns (address token) {
        return _vaultToken;
    }

    /**
     * @notice The percent of interest from reinvestments that are directed towards holders (namely liquidity pools and liquidity providers). The rest goes to the treasury and integrators. Has 18 decimals of precision.
     * @return interestShare_ The interest share with 18 decimals of precision.
     */
    function interestShare() external view override returns (uint256 interestShare_) {
        return _interestShare;
    }

    /**
     * @notice Returns the amount of interest claimable by `account`.
     * @param account The account to query interest of.
     * @return interest The account's accrued interest.
     */
    function interestOf(address account) external view override returns (uint256 interest) {
        uint256 lastPps = _lastPps[account];
        if(lastPps > 0) { // short circuit: account has never had a balance
            uint256 balance = _balances[account];
            uint256 latestPps = IYearnVault(_vaultToken).pricePerShare();
            // vaultBalance = balance * (10 ** decimals) / lastPps
            // balancePlusInterest = vaultBalance * latestPps / (10 ** decimals)
            // interestFull = balancePlusInterest - balance
            uint256 interestFull = ( (balance * latestPps) / lastPps) - balance;
            interest = ( (interestFull * _interestShare) / MAX_INTEREST_SHARE);
        }
        interest += _unpaidInterest[account];
    }

    /**
     * @notice Returns the balance of an account after adding interest.
     * @param account The account to query interest of.
     * @return balance The account's new balance.
     */
    function balancePlusInterestOf(address account) external view override returns (uint256 balance) {
        uint256 lastPps = _lastPps[account];
        balance = _balances[account];
        if(lastPps > 0) { // short circuit: account has never had a balance
            uint256 latestPps = IYearnVault(_vaultToken).pricePerShare();
            // vaultBalance = balance * (10 ** decimals) / lastPps
            // balancePlusInterest = vaultBalance * latestPps / (10 ** decimals)
            // interestFull = balancePlusInterest - balance
            uint256 interestFull = ( (balance * latestPps) / lastPps) - balance;
            balance += ( (interestFull * _interestShare) / MAX_INTEREST_SHARE);
        }
        balance += _unpaidInterest[account];
    }

    /**
     * @notice The Yearn Vault's price per share as of the last time this account's interest was accrued.
     * @param account The account to query.
     * @return lastPps_ The price per share.
     */
    function lastPpsOf(address account) external view override returns (uint256 lastPps_) {
        return _lastPps[account];
    }

    /**
     * @notice The owner of the contract.
     * @return owner_ The owner.
     */
    function owner() external view override returns (address owner_) {
        return _owner;
    }

    /**
     * @notice The address to receive the interest not directed towards holders. Can be modified in each hu2token instance.
     * @return treasury_ The treasury address.
     */
    function treasury() external view override returns (address treasury_) {
        return _treasury;
    }

    /**
     * @notice The address of the [`Hu2InterestDistributor`](./Hu2InterestDistributor).
     * @return distributor_ The distributor.
     */
    function interestDistributor() external view override returns (address distributor_) {
        return _distributor;
    }

    /***************************************
    DEPOSIT FUNCTIONS
    ***************************************/

    /**
     * @notice Deposit the base token to mint the hu2 token.
     * @param baseAmount The amount of the base token to deposit.
     * @param receiver The receiver of the newly minted hu2 tokens.
     * @return hu2Amount The amount of hu2 token minted.
     */
    function depositBaseToken(uint256 baseAmount, address receiver) external override returns (uint256 hu2Amount) {
        address base = _baseToken;
        address vault = _vaultToken;
        SafeERC20.safeTransferFrom(IERC20(base), msg.sender, address(this), baseAmount);
        uint256 allowance = IERC20(base).allowance(address(this), vault);
        if(allowance < baseAmount) IERC20(base).approve(vault, type(uint256).max);
        uint256 vaultAmount = IYearnVault(vault).deposit(baseAmount, address(this));
        hu2Amount = vaultAmount * IYearnVault(vault).pricePerShare() / _oneToken;
        _mint(receiver, hu2Amount);  // no deposit event, listen for transfer
    }

    /**
     * @notice Deposit the vault token to mint the hu2 token.
     * @param vaultAmount The amount of the vault token to deposit.
     * @param receiver The receiver of the newly minted hu2 tokens.
     * @return hu2Amount The amount of hu2 token minted.
     */
    function depositVaultToken(uint256 vaultAmount, address receiver) external override returns (uint256 hu2Amount) {
        address vault = _vaultToken;
        SafeERC20.safeTransferFrom(IERC20(vault), msg.sender, address(this), vaultAmount);
        hu2Amount = vaultAmount * IYearnVault(vault).pricePerShare() / _oneToken;
        _mint(receiver, hu2Amount);  // no deposit event, listen for transfer
    }

    /***************************************
    WITHDRAW FUNCTIONS
    ***************************************/

    /**
     * @notice Burn the hu2 token to withdraw the base token.
     * @param hu2Amount The amount of the hu2 token to burn or max uint for entire balance including interest.
     * @param receiver The receiver of the base token.
     * @return baseAmount The amount of base token withdrawn.
     */
    function withdrawBaseToken(uint256 hu2Amount, address receiver) external override returns (uint256 baseAmount) {
        // step 1: fetch state
        address vault = _vaultToken;
        uint256 latestPps = IYearnVault(vault).pricePerShare();
        uint256 lastPps = _lastPps[msg.sender];
        uint256 balance = _balances[msg.sender];
        uint256 ts = _totalSupply;
        // step 2: accrue interest
        if(lastPps == 0) _lastPps[msg.sender] = latestPps; // short circuit: never had a balance
        else {
            uint256 interest;
            // step 2.1: yearn gains
            if(latestPps > lastPps) {
                uint256 interestFull = ( (balance * latestPps) / lastPps) - balance;
                interest = ( (interestFull * _interestShare) / MAX_INTEREST_SHARE);
                uint256 treasuryInterest = (interestFull - interest);
                if(treasuryInterest > 0) _unpaidInterest[_treasury] += treasuryInterest;
                _lastPps[msg.sender] = latestPps;
            }
            // step 2.2: unpaid interest
            uint256 unpaidInterest = _unpaidInterest[msg.sender];
            if(unpaidInterest > 0) {
                interest += unpaidInterest;
                _unpaidInterest[msg.sender] = 0;
            }
            // step 2.3: add to balance
            if(interest > 0) { // save gas by not using _mint()
                ts += interest;
                balance += interest;
                emit Transfer(address(0), msg.sender, interest);
            }
        }
        // step 3: hu2 accounting
        if(hu2Amount == type(uint256).max) hu2Amount = balance;
        else require(hu2Amount <= balance, "Hu2TokenYearn: withdraw > bal");
        _balances[msg.sender] = balance - hu2Amount; // save gas by not using _burn()
        _totalSupply = ts - hu2Amount;
        emit Transfer(msg.sender, address(0), hu2Amount); // no withdraw event, listen for transfer
        // step 3: yvtoken withdraw
        uint256 vaultAmount = hu2Amount * _oneToken / latestPps;
        baseAmount = IYearnVault(vault).withdraw(vaultAmount, receiver);
    }

    /**
     * @notice Burn the hu2 token to withdraw the vault token.
     * @param hu2Amount The amount of the hu2 token to burn.
     * @param receiver The receiver of the vault token.
     * @return vaultAmount The amount of vault token withdrawn.
     */
    function withdrawVaultToken(uint256 hu2Amount, address receiver) external override returns (uint256 vaultAmount) {
        // step 1: fetch state
        address vault = _vaultToken;
        uint256 latestPps = IYearnVault(vault).pricePerShare();
        uint256 lastPps = _lastPps[msg.sender];
        uint256 balance = _balances[msg.sender];
        uint256 ts = _totalSupply;
        // step 2: accrue interest
        if(lastPps == 0) _lastPps[msg.sender] = latestPps; // short circuit: never had a balance
        else {
            uint256 interest;
            // step 2.1: yearn gains
            if(latestPps > lastPps) {
                uint256 interestFull = ( (balance * latestPps) / lastPps) - balance;
                interest = ( (interestFull * _interestShare) / MAX_INTEREST_SHARE);
                uint256 treasuryInterest = (interestFull - interest);
                if(treasuryInterest > 0) _unpaidInterest[_treasury] += treasuryInterest;
                _lastPps[msg.sender] = latestPps;
            }
            // step 2.2: unpaid interest
            uint256 unpaidInterest = _unpaidInterest[msg.sender];
            if(unpaidInterest > 0) {
                interest += unpaidInterest;
                _unpaidInterest[msg.sender] = 0;
            }
            // step 2.3: add to balance
            if(interest > 0) { // save gas by not using _mint()
                ts += interest;
                balance += interest;
                emit Transfer(address(0), msg.sender, interest);
            }
        }
        // step 3: hu2 accounting
        if(hu2Amount == type(uint256).max) hu2Amount = balance;
        else require(hu2Amount <= balance, "Hu2TokenYearn: withdraw > bal");
        _balances[msg.sender] = balance - hu2Amount; // save gas by not using _burn()
        _totalSupply = ts - hu2Amount;
        emit Transfer(msg.sender, address(0), hu2Amount); // no withdraw event, listen for transfer
        // step 3: yvtoken withdraw
        vaultAmount = hu2Amount * _oneToken / latestPps;
        SafeERC20.safeTransfer(IERC20(vault), receiver, vaultAmount);
    }

    /***************************************
    INTEREST ACCRUAL FUNCTIONS
    ***************************************/

    /**
     * @notice Accrues the interest owed to `msg.sender` and adds it to their balance.
     */
    function accrueInterest() external override {
        // step 1: fetch state
        uint256 latestPps = IYearnVault(_vaultToken).pricePerShare();
        uint256 lastPps = _lastPps[msg.sender];
        // step 2: accrue interest
        uint256 interest;
        // step 2.1: yearn gains
        if(lastPps == 0) _lastPps[msg.sender] = latestPps; // short circuit: never had a balance
        else if(latestPps > lastPps) {
            uint256 balance = _balances[msg.sender];
            uint256 interestFull = ( (balance * latestPps) / lastPps) - balance;
            interest = ( (interestFull * _interestShare) / MAX_INTEREST_SHARE);
            uint256 treasuryInterest = (interestFull - interest);
            if(treasuryInterest > 0) _unpaidInterest[_treasury] += treasuryInterest;
            _lastPps[msg.sender] = latestPps;
        }
        // step 2.2: unpaid interest
        uint256 unpaidInterest = _unpaidInterest[msg.sender];
        if(unpaidInterest > 0) {
            interest += unpaidInterest;
            _unpaidInterest[msg.sender] = 0;
        }
        // step 2.3: add to balance
        if(interest > 0) { // save gas by not using _mint()
            _totalSupply += interest;
            _balances[msg.sender] += interest;
            emit Transfer(address(0), msg.sender, interest);
        }
    }

    /**
     * @notice Accrues the interest owed to multiple accounts and adds it to their unpaid interest.
     * @param accounts The list of accouunts to accrue interest for.
     */
    function accrueInterestMultiple(address[] calldata accounts) external override {
        // there is an argument to be made for adding access control to this function
        // however the same effect can be had by transferring 0 to the account to accrue
        // the downside being a temporary and neglible decrease in gains
        // as unpaid interest doesnt earn from yearn, only balance
        uint256 latestPps = IYearnVault(_vaultToken).pricePerShare();
        uint256 treasuryInterest = 0;
        uint256 share = _interestShare;
        for(uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 lastPps = _lastPps[account];
            if(lastPps == 0) _lastPps[account] = latestPps; // short circuit: never had a balance
            else if(latestPps > lastPps) {
                uint256 balance = _balances[account];
                uint256 interestFull = ( (balance * latestPps) / lastPps) - balance;
                uint256 interest = ( (interestFull * share) / MAX_INTEREST_SHARE);
                if(interest > 0) _unpaidInterest[account] += interest;
                treasuryInterest += (interestFull - interest);
                _lastPps[account] = latestPps;
            }
        }
        if(treasuryInterest > 0) _unpaidInterest[_treasury] += treasuryInterest;
    }

    /**
     * @notice Distributes interest earned by a Uniswap V2 pool to its reserves.
     * Can only be called by the [`Hu2InterestDistributor`](./Hu2InterestDistributor).
     * @param pool The address of the Uniswap V2 pool to distribute interest to.
     */
    function distributeInterestToPool(address pool) external override {
        require(msg.sender == _distributor, "Hu2TokenYearn: !distributor");
        // step 1: fetch state
        uint256 latestPps = IYearnVault(_vaultToken).pricePerShare();
        uint256 lastPps = _lastPps[pool];
        // step 2: accrue interest
        uint256 interest;
        // step 2.1: yearn gains
        if(lastPps == 0) _lastPps[pool] = latestPps; // short circuit: never had a balance
        else if(latestPps > lastPps) {
            uint256 balance = _balances[pool];
            uint256 interestFull = ( (balance * latestPps) / lastPps) - balance;
            interest = ( (interestFull * _interestShare) / MAX_INTEREST_SHARE);
            uint256 treasuryInterest = (interestFull - interest);
            if(treasuryInterest > 0) _unpaidInterest[_treasury] += treasuryInterest;
            _lastPps[pool] = latestPps;
        }
        // step 2.2: unpaid interest
        uint256 unpaidInterest = _unpaidInterest[pool];
        if(unpaidInterest > 0) {
            interest += unpaidInterest;
            _unpaidInterest[pool] = 0;
        }
        // step 2.3: add to balance
        if(interest > 0) { // save gas by not using _mint()
            _totalSupply += interest;
            _balances[pool] += interest;
            emit Transfer(address(0), pool, interest);
        }
    }

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Sets the percent of interest from reinvestments that are directed towards holders (namely liquidity pools and liquidity providers). The rest goes to the treasury and integrators. Has 18 decimals of precision.
     * Can only be called by the contract owner.
     * @param interestShare_ The interest share with 18 decimals of precision.
     * @param treasury_ The address to receive the rest of the interest.
     */
    function setInterestShare(uint256 interestShare_, address treasury_) external override {
        require(msg.sender == _owner, "Hu2TokenYearn: !owner");
        _setInterestShare(interestShare_);
        _treasury = treasury_;
    }

    /**
     * @notice Transfers ownership of the contract to a new account.
     * Can only be called by the current owner.
     * @param newOwner The address to transfer the ownership role to.
     */
    function transferOwnership(address newOwner) external override {
        address oldOwner = _owner;
        require(msg.sender == oldOwner, "Hu2TokenYearn: !owner");
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /***************************************
    HELPER FUNCTIONS
    ***************************************/

    /**
     * @notice Sets the percent of interest from reinvestments that are directed towards holders (namely liquidity pools and liquidity providers). The rest goes to the treasury and integrators. Has 18 decimals of precision.
     * @param interestShare_ The interest share with 18 decimals of precision.
     */
    function _setInterestShare(uint256 interestShare_) internal {
        require(interestShare_ <= MAX_INTEREST_SHARE, "Hu2TokenYearn: invalid interest");
        _interestShare = interestShare_;
    }

    /**
     * @notice Hook that is called before any transfer of tokens. This includes minting and burning.
     * @param from The account that tokens are transferring from.
     * @param to The account that tokens are transferring to.
     * @param amount The amount of tokens to transfer.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // accrue interest to `from` and `to` and add it to their unpaid interest
        uint256 latestPps = IYearnVault(_vaultToken).pricePerShare();
        uint256 treasuryInterest = 0;
        uint256 share = _interestShare;
        { // `from` scope
        uint256 lastPps = _lastPps[from];
        if(lastPps == 0) _lastPps[from] = latestPps; // short circuit: never had a balance
        else if(latestPps > lastPps) {
            uint256 balance = _balances[from];
            uint256 interestFull = ( (balance * latestPps) / lastPps) - balance;
            uint256 interest = ( (interestFull * share) / MAX_INTEREST_SHARE);
            if(interest > 0) _unpaidInterest[from] += interest;
            treasuryInterest += (interestFull - interest);
            _lastPps[from] = latestPps;
        }
        }
        { // `to` scope
        uint256 lastPps = _lastPps[to];
        if(lastPps == 0) _lastPps[to] = latestPps; // short circuit: never had a balance
        else if(latestPps > lastPps) {
            uint256 balance = _balances[to];
            uint256 interestFull = ( (balance * latestPps) / lastPps) - balance;
            uint256 interest = ( (interestFull * share) / MAX_INTEREST_SHARE);
            if(interest > 0) _unpaidInterest[to] += interest;
            treasuryInterest += (interestFull - interest);
            _lastPps[to] = latestPps;
        }
        }
        if(treasuryInterest > 0) _unpaidInterest[_treasury] += treasuryInterest;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IHwTokenBase } from "./interfaces/IHwTokenBase.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


/**
 * @title HwTokenBase
 * @author Hysland Finance
 * @notice A custom implementation of an ERC20 token with the metadata and permit extensions.
 *
 * This was forked from OpenZeppelin's implementation with a few key differences:
 * - It uses an initialzer instead of a constructor, allowing for easier use in factory patterns.
 * - State variables are declared as internal instead of private, allowing use by child contracts.
 * - Minor efficiency improvements. Removed zero address checks, context, counters, shorter revert strings. Different domain cache mechanism.
 */
abstract contract HwTokenBase is IHwTokenBase {

    /***************************************
    DATA
    ***************************************/

    // base data
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    uint256 internal _totalSupply;

    // metadata extension
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    bool internal _initialized;

    // permit extension
    mapping(address => uint256) internal _nonces;
    // solhint-disable-next-line var-name-mixedcase
    bytes32 internal immutable _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    mapping(uint256 => bytes32) internal _CACHED_DOMAIN_SEPARATORS;
    bytes32 internal _HASHED_NAME;
    bytes32 internal _HASHED_VERSION;
    bytes32 internal _TYPE_HASH;
    /* solhint-enable var-name-mixedcase */

    /***************************************
    INITIALIZER
    ***************************************/

    /**
     * @notice Initializes the token.
     * Can only be called once.
     * @param name_ The name of the token.
     * @param symbol_ The symbol of the token.
     * @param decimals_ The decimals of the token.
     */
    function _initialize(string calldata name_, string calldata symbol_, uint8 decimals_) internal {
        require(!_initialized, "HwToken: already init");
        // metadata extension
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        // permit extension
        _HASHED_NAME = keccak256(bytes(name_));
        _HASHED_VERSION = keccak256(bytes("1"));
        _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        _domainSeparatorV4WithWrite();
        _initialized = true;
    }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Returns the name of the token.
     * @return name_ The name of the token.
     */
    function name() external view virtual override returns (string memory name_) {
        return _name;
    }

    /**
     * @notice Returns the symbol of the token.
     * @return symbol_ The symbol of the token.
     */
    function symbol() external view virtual override returns (string memory symbol_) {
        return _symbol;
    }

    /**
     * @notice Returns the decimals places of the token.
     * @return decimals_ The decimals of the token.
     */
    function decimals() external view virtual override returns (uint8 decimals_) {
        return _decimals;
    }

    /**
     * @notice Returns the amount of tokens in existence.
     * @return supply The amount of tokens in existence.
     */
    function totalSupply() external view virtual override returns (uint256 supply) {
        return _totalSupply;
    }

    /**
     * @notice Returns the amount of tokens owned by `account`.
     * @param account The account to query balance of.
     * @return balance The account's balance.
     */
    function balanceOf(address account) external view virtual override returns (uint256 balance) {
        return _balances[account];
    }

    /**
     * @notice Returns the remaining number of tokens that `spender` is
     * allowed to spend on behalf of `owner` through [`transferFrom()`](#transferfrom). This is
     * zero by default.
     *
     * This value changes when [`approve()`](#approve), [`transferFrom()`](#transferfrom),
     * or [`permit()`](#permit) are called.
     *
     * @param owner The owner of tokens.
     * @param spender The spender of tokens.
     * @return allowance_ The amount of `owner`'s tokens that `spender` can spend.
     */
    function allowance(address owner, address spender) external view virtual override returns (uint256 allowance_) {
        return _allowances[owner][spender];
    }

    /**
     * @notice Returns the current nonce for `owner`. This value must be included whenever a signature is generated for [`permit()`](#permit).
     * @param owner The owner of tokens.
     * @return nonce_ The owner's nonce.
     */
    function nonces(address owner) external view virtual override returns (uint256) {
        return _nonces[owner];
    }

    /**
     * @notice Returns the domain separator used in the encoding of the signature for [`permit()`](#permit), as defined by EIP712.
     * @return separator The domain separator.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view virtual override returns (bytes32 separator) {
        return _domainSeparatorV4();
    }

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - the caller must have a balance of at least `amount`.
     *
     * @param recipient The recipient of the tokens.
     * @param amount The amount of tokens to transfer.
     * @return success True on success, false otherwise.
     */
    function transfer(address recipient, uint256 amount) external virtual override returns (bool success) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @notice Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     *
     * @param sender The sender of the tokens.
     * @param recipient The recipient of the tokens.
     * @param amount The amount of tokens to transfer.
     * @return success True on success, false otherwise.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool success) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "HwToken: transfer amt > allow");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

    /**
     * @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     *
     * @param spender The account to allow to spend `msg.sender`'s tokens.
     * @param amount The amount of tokens to allow to spend.
     * @return success True on success, false otherwise.
     */
    function approve(address spender, uint256 amount) external virtual override returns (bool success) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to [`approve()`](#approve) that can be used as a mitigation for
     * problems described in [`approve()`](#approve).
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * @param spender The account to allow to spend `msg.sender`'s tokens.
     * @param addedValue The amount to increase allowance.
     * @return success True on success, false otherwise.
     */
    function increaseAllowance(address spender, uint256 addedValue) external virtual override returns (bool success) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    /**
     * @notice Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to [`approve()`](#approve) that can be used as a mitigation for
     * problems described in [`approve()`](#approve).
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     *
     * @param spender The account to allow to spend `msg.sender`'s tokens.
     * @param subtractedValue The amount to decrease allowance.
     * @return success True on success, false otherwise.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual override returns (bool success) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "HwToken: new allowance < 0");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    /**
     * @notice Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues [`approve()`](#approve) has related to transaction
     * ordering also apply here.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use `owner`'s current nonce (see [`nonces()`](#nonces)).
     *
     * For more information on the signature format, see
     * [EIP2612](https://eips.ethereum.org/EIPS/eip-2612#specification).
     *
     * @param owner The owner of the tokens.
     * @param spender The spender of the tokens.
     * @param value The amount to approve.
     * @param deadline The timestamp that `permit()` must go through before.
     * @param v secp256k1 signature
     * @param r secp256k1 signature
     * @param s secp256k1 signature
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override {
        require(block.timestamp <= deadline, "HwToken: expired permit");
        uint256 nonce = _nonces[owner];
        _nonces[owner] = nonce + 1;
        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, nonce, deadline));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "HwToken: invalid permit");
        _approve(owner, spender, value);
    }

    /***************************************
    HELPER FUNCTIONS
    ***************************************/

    /**
     * @notice Moves `amount` of tokens from `sender` to `recipient`.
     * @param sender The sender of the tokens.
     * @param recipient The recipient of the tokens.
     * @param amount The amount of tokens to transfer.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "HwToken: transfer amt > bal");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }

    /**
     * @notice Creates `amount` tokens and assigns them to `account`, increasing the total supply.
     * @param account The account to mint to.
     * @param amount The amount of tokens to mint.
     */
    function _mint(address account, uint256 amount) internal virtual {
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @notice Destroys `amount` tokens from `account`, reducing the total supply.
     * @param account The account to burn from.
     * @param amount The amount of tokens to burn.
     */
    function _burn(address account, uint256 amount) internal virtual {
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "HwToken: burn amt > bal");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @notice Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     * @param owner The account that owns the tokens.
     * @param spender The account to allow to spend `owner`'s tokens.
     * @param amount The amount of tokens to allow to spend.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @notice Hook that is called before any transfer of tokens. This includes minting and burning.
     * @param from The account that tokens are transferring from.
     * @param to The account that tokens are transferring to.
     * @param amount The amount of tokens to transfer.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual
    // solhint-disable-next-line no-empty-blocks
    {}

    /**
     * @notice Hook that is called after any transfer of tokens. This includes minting and burning.
     * @param from The account that tokens are transferring from.
     * @param to The account that tokens are transferring to.
     * @param amount The amount of tokens to transfer.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual
    // solhint-disable-next-line no-empty-blocks
    {}

    /**
     * @notice Returns the domain separator for the current chain.
     * @return separator The domain separator.
     */
    function _domainSeparatorV4() internal view returns (bytes32 separator) {
        separator = _CACHED_DOMAIN_SEPARATORS[block.chainid];
        if(separator == bytes32(0)) {
            separator = _buildDomainSeparator();
        }
    }

    /**
     * @notice Returns the domain separator for the current chain.
     * @return separator The domain separator.
     */
    function _domainSeparatorV4WithWrite() internal returns (bytes32 separator) {
        separator = _CACHED_DOMAIN_SEPARATORS[block.chainid];
        if(separator == bytes32(0)) {
            separator = _buildDomainSeparator();
            _CACHED_DOMAIN_SEPARATORS[block.chainid] = separator;
        }
    }

    /**
     * @notice Builds the domain separator.
     * @return separator The domain separator.
     */
    function _buildDomainSeparator() internal view returns (bytes32 separator) {
        return keccak256(abi.encode(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION, block.chainid, address(this)));
    }

    /**
     * @notice Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with `ECDSA-recover` to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     * @param structHash The hash of the struct.
     * @return messageHash The hash of the message.
     */
    function _hashTypedDataV4(bytes32 structHash) internal virtual returns (bytes32 messageHash) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4WithWrite(), structHash);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IERC20PermitB } from "./../../tokens/IERC20PermitB.sol";


/**
 * @title IYearnVault
 * @author Hysland Finance
 * @notice Yearn Token Vault. Holds an underlying token, and allows users to interact with the Yearn ecosystem through Strategies connected to the Vault. Vaults are not limited to a single Strategy, they can have as many Strategies as can be designed (however the withdrawal queue is capped at 20.)
 *
 * Deposited funds are moved into the most impactful strategy that has not already reached its limit for assets under management, regardless of which Strategy a user's funds end up in, they receive their portion of yields generated across all Strategies.
 *
 * When a user withdraws, if there are no funds sitting undeployed in the Vault, the Vault withdraws funds from Strategies in the order of least impact. (Funds are taken from the Strategy that will disturb everyone's gains the least, then the next least, etc.) In order to achieve this, the withdrawal queue's order must be properly set and managed by the community (through governance).
 *
 * Vault Strategies are parameterized to pursue the highest risk-adjusted yield.
 *
 * There is an "Emergency Shutdown" mode. When the Vault is put into emergency shutdown, assets will be recalled from the Strategies as quickly as is practical (given on-chain conditions), minimizing loss. Deposits are halted, new Strategies may not be added, and each Strategy exits with the minimum possible damage to position, while opening up deposits to be withdrawn by users. There are no restrictions on withdrawals above what is expected under Normal Operation.
 *
 * For further details, please refer to the specification:
 * https://github.com/iearn-finance/yearn-vaults/blob/main/SPECIFICATION.md
 */
interface IYearnVault is IERC20PermitB {

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice The token that may be deposited into this Vault.
     * @return tkn The token that may be deposited into this Vault.
     */
    function token() external view returns (address tkn);

    /**
     * @notice Gives the price for a single Vault share.
     * @dev See dev note on `withdraw`.
     * @return pps The value of a single share.
     */
    function pricePerShare() external view returns (uint256 pps);

    /**
     * @notice The amount of the underlying token that still may be deposited into this contract.
     * @return uAmount The amount in the same decimals as uToken.
     */
    function availableDepositLimit() external view returns (uint256 uAmount);

    /**
     * @notice Returns true if the Vault is in the emergency shutdown state. TLDR: no deposits.
     * @return shutdown True if the Vault is shutdown, otherwise false.
     */
    function emergencyShutdown() external view returns (bool shutdown);

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Deposits `uAmount` `token`, issuing shares to `recipient`. If the Vault is in Emergency Shutdown, deposits will not be accepted and this call will fail.
     * @dev Measuring quantity of shares to issues is based on the total outstanding debt that this contract has ("expected value") instead of the total balance sheet it has ("estimated value") has important security considerations, and is done intentionally. If this value were measured against external systems, it could be purposely manipulated by an attacker to withdraw more assets than they otherwise should be able to claim by redeeming their shares. On deposit, this means that shares are issued against the total amount that the deposited capital can be given in service of the debt that Strategies assume. If that number were to be lower than the "expected value" at some future point, depositing shares via this method could entitle the depositor to *less* than the deposited value once the "realized value" is updated from further reports by the Strategies to the Vaults. Care should be taken by integrators to account for this discrepancy, by using the view-only methods of this contract (both off-chain and on-chain) to determine if depositing into the Vault is a "good idea".
     * @param uAmount The quantity of tokens to deposit.
     * @param recipient The address to issue the shares in this Vault to.
     * @return yAmount The issued Vault shares.
     */
    function deposit(uint256 uAmount, address recipient) external returns (uint256 yAmount);

    /**
     * @notice Withdraws the calling account's tokens from this Vault, redeeming amount `yAmount` for an appropriate amount of tokens. See note on `setWithdrawalQueue` for further details of withdrawal ordering and behavior.
     * @dev This version of `withdraw()` is available on Vaults with api version <= 0.2.2.
     * @dev Measuring the value of shares is based on the total outstanding debt that this contract has ("expected value") instead of the total balance sheet it has ("estimated value") has important security considerations, and is done intentionally. If this value were measured against external systems, it could be purposely manipulated by an attacker to withdraw more assets than they otherwise should be able to claim by redeeming their shares. On withdrawal, this means that shares are redeemed against the total amount that the deposited capital had "realized" since the point it was deposited, up until the point it was withdrawn. If that number were to be higher than the "expected value" at some future point, withdrawing shares via this method could entitle the depositor to *more* than the expected value once the "realized value" is updated from further reports by the Strategies to the Vaults. Under exceptional scenarios, this could cause earlier withdrawals to earn "more" of the underlying assets than Users might otherwise be entitled to, if the Vault's estimated value were otherwise measured through external means, accounting for whatever exceptional scenarios exist for the Vault (that aren't covered by the Vault's own design.) In the situation where a large withdrawal happens, it can empty the vault balance and the strategies in the withdrawal queue. Strategies not in the withdrawal queue will have to be harvested to rebalance the funds and make the funds available again to withdraw.
     * @param yAmount How many shares to try and redeem for tokens.
     * @param recipient The address to transfer the underlying tokens in this Vault to.
     * @return uAmount The quantity of tokens redeemed for `yAmount`.
     */
    function withdraw(uint256 yAmount, address recipient) external returns (uint256 uAmount);

    /**
     * @notice Withdraws the calling account's tokens from this Vault, redeeming amount `yAmount` for an appropriate amount of tokens. See note on `setWithdrawalQueue` for further details of withdrawal ordering and behavior.
     * @dev This version of `withdraw()` is available on Vaults with api version >= 0.3.0.
     * @dev Measuring the value of shares is based on the total outstanding debt that this contract has ("expected value") instead of the total balance sheet it has ("estimated value") has important security considerations, and is done intentionally. If this value were measured against external systems, it could be purposely manipulated by an attacker to withdraw more assets than they otherwise should be able to claim by redeeming their shares. On withdrawal, this means that shares are redeemed against the total amount that the deposited capital had "realized" since the point it was deposited, up until the point it was withdrawn. If that number were to be higher than the "expected value" at some future point, withdrawing shares via this method could entitle the depositor to *more* than the expected value once the "realized value" is updated from further reports by the Strategies to the Vaults. Under exceptional scenarios, this could cause earlier withdrawals to earn "more" of the underlying assets than Users might otherwise be entitled to, if the Vault's estimated value were otherwise measured through external means, accounting for whatever exceptional scenarios exist for the Vault (that aren't covered by the Vault's own design.) In the situation where a large withdrawal happens, it can empty the vault balance and the strategies in the withdrawal queue. Strategies not in the withdrawal queue will have to be harvested to rebalance the funds and make the funds available again to withdraw.
     * @param yAmount How many shares to try and redeem for tokens.
     * @param recipient The address to transfer the underlying tokens in this Vault to.
     * @param maxLoss The maximum acceptable loss to sustain on withdrawal. Up to that amount of shares may be burnt to cover losses on withdrawal.
     * @return uAmount The quantity of tokens redeemed for `yAmount`.
     */
    function withdraw(uint256 yAmount, address recipient, uint256 maxLoss) external returns (uint256 uAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


/**
 * @title IHu2FactoryYearn
 * @author Hysland Finance
 * @notice A factory that creates Hu2Tokens around Yearn Vaults.
 *
 * New Hu2TokenYearns can be deployed via [`deployHu2Token()`](#deployhu2token). This is initially restricted to only owner, but can be made permissionless via [`setPermissionlessCreation()`](#setpermissionlesscreation). The factory's [`owner()`](#owner), [`treasury()`](#treasury), [`interestShare()`](#interestshare), and [`distributor()`](#distributor) will be copied to the Hu2TokenYearn instance. Of these, all except the [`distributor()`](#distributor) can be modified in each Hu2TokenYearn instance.
 *
 * The owner can also [`setInterestShare()`](#setinterestshare) and [`transferOwnership()`](#transferownership).
 */
interface IHu2FactoryYearn {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a Hu2Token is deployed.
    event TokenCreated(address indexed vaultToken, address indexed hu2Token);
    /// @notice Emitted when the ownership role is transferred.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice The number of Hu2Tokens that have been deployed by this contract.
     * @return count The number of Hu2Tokens.
     */
    function countHu2Tokens() external view returns (uint256 count);

    /**
     * @notice Enumerates all Hu2Tokens that have been deployed by this contract.
     * Enumerable [1,length].
     * @param index The index of the Hu2Token to query.
     * @return hu2Token The address of the Hu2Token.
     */
    function hu2Tokens(uint256 index) external view returns (address hu2Token);

    /**
     * @notice The number of Hu2Tokens that have been deployed by this contract for a given Yearn Vault.
     * @param vault The address of the Yearn Vault to query,
     * @return count The number of Hu2Tokens.
     */
    function countHu2TokensForVault(address vault) external view returns (uint256 count);

    /**
     * @notice Enumerates all Hu2Tokens that have been deployed by this contract for a given Yearn Vault.
     * Enumerable [1,length].
     * @param vault The address of the Yearn Vault to query,
     * @param index The index of the Hu2Token to query.
     * @return hu2Token The address of the Hu2Token.
     */
    function hu2TokensForVault(address vault, uint256 index) external view returns (address hu2Token);

    /**
     * @notice The status of permissionless creation. If enabled, anyone can deploy a new contract. Otherwise, restricted to only contract owner.
     * @return permissionlessCreationEnabled_ True if enabled, false if disabled.
     */
    function permissionlessCreationEnabled() external view returns (bool permissionlessCreationEnabled_);

    /**
     * @notice The address of the [`Hu2InterestDistributor`](./IHu2InterestDistributor).
     * @return distributor_ The distributor.
     */
    function interestDistributor() external view returns (address distributor_);

    /**
     * @notice The percent of interest from reinvestments that are directed towards holders (namely liquidity pools and liquidity providers). The rest goes to the treasury and integrators. Has 18 decimals of precision. Can be modified in each Hu2Token instance.
     * @return interestShare_ The interest share with 18 decimals of precision.
     */
    function interestShare() external view returns (uint256 interestShare_);

    /**
     * @notice The owner of the contract.
     * @return owner_ The owner.
     */
    function owner() external view returns (address owner_);

    /**
     * @notice The address to receive the interest not directed towards holders. Can be modified in each hu2token instance.
     * @return treasury_ The treasury address.
     */
    function treasury() external view returns (address treasury_);

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Deploys a new Hu2TokenYearn.
     * Can only be called by the contract owner unless permissionless creation is enabled.
     * @param vault The address of the Yearn Vault to reinvest into.
     * @param name The name of the new token.
     * @param symbol The symbol of the new token.
     * @param decimals The decimals of the new token.
     */
    function deployHu2Token(address vault, string calldata name, string calldata symbol, uint8 decimals) external returns (address hu2Token);

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Sets the percent of interest from reinvestments that are directed towards holders (namely liquidity pools and liquidity providers). The rest goes to the treasury and integrators. Has 18 decimals of precision. Can be modified in each Hu2Token instance.
     * @param interestShare_ The interest share with 18 decimals of precision.
     * @param treasury_ The address to receive the rest of the interest.
     */
    function setInterestShare(uint256 interestShare_, address treasury_) external;

    /**
     * @notice Enable or disable permissionless creation.
     * Can only be called by the contract owner.
     * @param status True to enable permissionlessness, false to disable.
     */
    function setPermissionlessCreation(bool status) external;

    /**
     * @notice Transfers ownership of the contract to a new account.
     * Can only be called by the current owner.
     * @param newOwner The address to transfer the ownership role to.
     */
    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


/**
 * @title IHu2InterestDistributor
 * @author Hysland Finance
 * @notice Distributes interest earned from reinvestments into Uniswap V2 pools.
 *
 * Each Uniswap V2 pool contains two tokens. This contract rebases them at the same time then syncs the reserves. It works whether the tokens are hu2 tokens or not, or whatever interest bearing protocol they use.
 *
 * A single pool can be rebased via [`distributeInterestToPool()`](#distributeinteresttopool). Multiple pools can be rebased in one call via [`distributeInterestToPools()`](#distributeinteresttopools).
 */
interface IHu2InterestDistributor {

    /***************************************
    EVENTS FUNCTIONS
    ***************************************/

    /// @notice Emitted when interest is distributed to a pool.
    event InterestDistributed(address indexed pool);

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Distributes interest to a Uniswap V2 pool.
     * @param pool The address of the Uniswap V2 pool to distribute interest to.
     */
    function distributeInterestToPool(address pool) external;

    /**
     * @notice Distributes interest to multiple Uniswap V2 pools.
     * @param pools The list of Uniswap V2 pools to distribute interest to.
     */
    function distributeInterestToPools(address[] calldata pools) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IHwTokenBase } from "./IHwTokenBase.sol";


/**
 * @title IHu2Token
 * @author Hysland Finance
 * @notice An interest bearing token designed to be used in Uniswap V2 pools.
 *
 * Most liquidity pools were designed to work with "standard" ERC20 tokens. The vault tokens of some interest bearing protocols may not work well with some liquidity pools. Hyswap vault wrappers are ERC20 tokens around these vaults that help them work better in liquidity pools. Liquidity providers of Hyswap pools will earn from both swap fees and interest from vaults.
 *
 * ```
 * ------------------------
 * | hyswap wrapper token | eg hu2yvDAI
 * | -------------------- |
 * | |   vault token    | | eg yvDAI
 * | | ---------------- | |
 * | | |  base token  | | | eg DAI
 * | | ---------------- | |
 * | -------------------- |
 * ------------------------
 * ```
 *
 * This is the base type of hwTokens that are designed for use in Uniswap V2, called Hyswap Uniswap V2 Vault Wrappers.
 *
 * Interest will accrue over time. This will increase each accounts [`interestOf()`](#interestof) and [`balancePlusInterestOf()`](#balanceplusinterestof) but not their `balanceOf()`. Users can move this amount to their `balanceOf()` via [`accrueInterest()`](#accrueinterest). The [`interestDistributor()`](#interestdistributor) can accrue the interest of a Uniswap V2 pool via [`distributeInterestToPool()`](#distributeinteresttopool). For accounting purposes, [`accrueInterestMultiple()`](#accrueinterestmultiple) and `transfer()` will also accrue interest, but this amount won't be added to the accounts `balanceOf()` until a call to [`accrueInterest()`](#accrueinterest) or [`distributeInterestToPool()`](#distributeinteresttopool).
 *
 * Most users won't hold this token and can largely ignore that it exists. If you see it in a Uniswap V2 pool, you can think of it as the base token. Integrators should perform the routing for you. Regular users should hold the base token for regular use, the vault token to earn interest, or the LP token to earn interest plus swap fees. High frequency traders may hold the Hu2Token for reduced gas fees.
 *
 * A portion of the interest earned may be redirected to the Hyswap treasury and integrators. The percentage can be viewed via [`interestShare()`](#interestshare) and the receiver can be viewed via [`treasury()`](#treasury).
 */
interface IHu2Token is IHwTokenBase {

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Returns the amount of interest claimable by `account`.
     * @param account The account to query interest of.
     * @return interest The account's accrued interest.
     */
    function interestOf(address account) external view returns (uint256 interest);

    /**
     * @notice Returns the balance of an account after adding interest.
     * @param account The account to query interest of.
     * @return balance The account's new balance.
     */
    function balancePlusInterestOf(address account) external view returns (uint256 balance);

    /**
     * @notice The percent of interest from reinvestments that are directed towards holders (namely liquidity pools and liquidity providers). The rest goes to the treasury and integrators. Has 18 decimals of precision.
     * @return interestShare_ The interest share with 18 decimals of precision.
     */
    function interestShare() external view returns (uint256 interestShare_);

    /**
     * @notice The address to receive the interest not directed towards holders. Can be modified in each hu2token instance.
     * @return treasury_ The treasury address.
     */
    function treasury() external view returns (address treasury_);

    /**
     * @notice The address of the [`Hu2InterestDistributor`](./IHu2InterestDistributor).
     * @return distributor_ The distributor.
     */
    function interestDistributor() external view returns (address distributor_);

    /***************************************
    INTEREST ACCRUAL FUNCTIONS
    ***************************************/

    /**
     * @notice Accrues the interest owed to `msg.sender` and adds it to their balance.
     */
    function accrueInterest() external;

    /**
     * @notice Accrues the interest owed to multiple accounts and adds it to their unpaid interest.
     * @param accounts The list of accouunts to accrue interest for.
     */
    function accrueInterestMultiple(address[] calldata accounts) external;

    /**
     * @notice Distributes interest earned by a Uniswap V2 pool to its reserves.
     * Can only be called by the [`Hu2InterestDistributor`](./IHu2InterestDistributor).
     * @param pool The address of the Uniswap V2 pool to distribute interest to.
     */
    function distributeInterestToPool(address pool) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IHu2Token } from "./IHu2Token.sol";


/**
 * @title IHu2TokenYearn
 * @author Hysland Finance
 * @notice An interest bearing token designed to be used in Uniswap V2 pools. This version earns interest by reinvesting deposits into Yearn Vaults.
 *
 * ```
 * ------------------------
 * | hyswap wrapper token | eg hu2yvDAI
 * | -------------------- |
 * | |   vault token    | | eg yvDAI
 * | | ---------------- | |
 * | | |  base token  | | | eg DAI
 * | | ---------------- | |
 * | -------------------- |
 * ------------------------
 * ```
 *
 * There are three tokens at play: the base token (aka underlying) (eg DAI), the Yearn Vault token (eg yvDAI), and the hu2 token (eg hu2yvDAI). Users can deposit and withdraw to either the base token or the vault token using [`depositBaseToken()`](#depositbasetoken), [`depositVaultToken()`](#depositvaulttoken), [`withdrawBaseToken()`](#withdrawbasetoken), or [`withdrawVaultToken()`](#withdrawvaulttoken). The hu2Token is 1:1 pegged to and redeemable for the base token. Note that the amount received during deposit and withdraw may be different by a dust amount due to integer division.
 *
 * Accounts accrue interest when the Yearn Vault's price per share (abbreviated pps) increases relative to their [`lastPpsOf()`](#lastppsof). This is updated on every balance modifying or interest accruing call.
 *
 * This contract has an [`owner()`](#owner) that can [`setInterestShare()`](#setinterestshare) and [`transferOwnership()`](#transferownership).
 */
interface IHu2TokenYearn is IHu2Token {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when the ownership role is transferred.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /***************************************
    INITIALIZER
    ***************************************/

    struct InitializationParams {
        string name;
        string symbol;
        uint8 decimals;
        address vault;
        address distributor;
        address treasury;
        address owner;
        uint256 interestShare;
    }

    /**
     * @notice Initializes the Hu2Token.
     * Can only be called once.
     * @param params The initialization parameters.
     */
    function initialize(InitializationParams calldata params) external;

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Returns the address of the base token.
     * @return token The base token.
     */
    function baseToken() external view returns (address token);

    /**
     * @notice Returns the address of the Yearn vault token.
     * @return token The vault token.
     */
    function vaultToken() external view returns (address token);

    /**
     * @notice The Yearn Vault's price per share as of the last time this account's interest was accrued.
     * @param account The account to query.
     * @return lastPps_ The price per share.
     */
    function lastPpsOf(address account) external view returns (uint256 lastPps_);

    /**
     * @notice The owner of the contract.
     * @return owner_ The owner.
     */
    function owner() external view returns (address owner_);

    /***************************************
    DEPOSIT FUNCTIONS
    ***************************************/

    /**
     * @notice Deposit the base token to mint the hu2 token.
     * @param baseAmount The amount of the base token to deposit.
     * @param receiver The receiver of the newly minted hu2 tokens.
     * @return hu2Amount The amount of hu2 token minted.
     */
    function depositBaseToken(uint256 baseAmount, address receiver) external returns (uint256 hu2Amount);

    /**
     * @notice Deposit the vault token to mint the hu2 token.
     * @param vaultAmount The amount of the vault token to deposit.
     * @param receiver The receiver of the newly minted hu2 tokens.
     * @return hu2Amount The amount of hu2 token minted.
     */
    function depositVaultToken(uint256 vaultAmount, address receiver) external returns (uint256 hu2Amount);

    /***************************************
    WITHDRAW FUNCTIONS
    ***************************************/

    /**
     * @notice Burn the hu2 token to withdraw the base token.
     * @param hu2Amount The amount of the hu2 token to burn or max uint for entire balance including interest.
     * @param receiver The receiver of the base token.
     * @return baseAmount The amount of base token withdrawn.
     */
    function withdrawBaseToken(uint256 hu2Amount, address receiver) external returns (uint256 baseAmount);

    /**
     * @notice Burn the hu2 token to withdraw the vault token.
     * @param hu2Amount The amount of the hu2 token to burn.
     * @param receiver The receiver of the vault token.
     * @return vaultAmount The amount of vault token withdrawn.
     */
    function withdrawVaultToken(uint256 hu2Amount, address receiver) external returns (uint256 vaultAmount);

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Sets the percent of interest from reinvestments that are directed towards holders (namely liquidity pools and liquidity providers). The rest goes to the treasury and integrators. Has 18 decimals of precision.
     * Can only be called by the contract owner.
     * @param interestShare_ The interest share with 18 decimals of precision.
     * @param treasury_ The address to receive the rest of the interest.
     */
    function setInterestShare(uint256 interestShare_, address treasury_) external;

    /**
     * @notice Transfers ownership of the contract to a new account.
     * Can only be called by the current owner.
     * @param newOwner The address to transfer the ownership role to.
     */
    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


/**
 * @title IHwTokenBase
 * @author Hysland Finance
 * @notice A custom implementation of an ERC20 token with the metadata and permit extensions.
 *
 * This was forked from OpenZeppelin's implementation with a few key differences:
 * - It uses an initialzer instead of a constructor, allowing for easier use in factory patterns.
 * - State variables are declared as internal instead of private, allowing use by child contracts.
 * - Minor efficiency improvements. Removed zero address checks, context, shorter revert strings.
 */
interface IHwTokenBase {

    /***************************************
    EVENTS
    ***************************************/

    /**
     * @notice Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @notice Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to [`approve()`](#approve). `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Returns the name of the token.
     * @return name_ The name of the token.
     */
    function name() external view returns (string memory name_);

    /**
     * @notice Returns the symbol of the token.
     * @return symbol_ The symbol of the token.
     */
    function symbol() external view returns (string memory symbol_);

    /**
     * @notice Returns the decimals places of the token.
     * @return decimals_ The decimals of the token.
     */
    function decimals() external view returns (uint8 decimals_);

    /**
     * @notice Returns the amount of tokens in existence.
     * @return supply The amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256 supply);

    /**
     * @notice Returns the amount of tokens owned by `account`.
     * @param account The account to query balance of.
     * @return balance The account's balance.
     */
    function balanceOf(address account) external view returns (uint256 balance);

    /**
     * @notice Returns the remaining number of tokens that `spender` is
     * allowed to spend on behalf of `owner` through [`transferFrom()`](#transferfrom). This is
     * zero by default.
     *
     * This value changes when [`approve()`](#approve), [`transferFrom()`](#transferfrom),
     * or [`permit()`](#permit) are called.
     *
     * @param owner The owner of tokens.
     * @param spender The spender of tokens.
     * @return allowance_ The amount of `owner`'s tokens that `spender` can spend.
     */
    function allowance(address owner, address spender) external view returns (uint256 allowance_);

    /**
     * @notice Returns the current nonce for `owner`. This value must be included whenever a signature is generated for [`permit()`](#permit).
     * @param owner The owner of tokens.
     * @return nonce_ The owner's nonce.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @notice Returns the domain separator used in the encoding of the signature for [`permit()`](#permit), as defined by EIP712.
     * @return separator The domain separator.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32 separator);

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - the caller must have a balance of at least `amount`.
     *
     * @param recipient The recipient of the tokens.
     * @param amount The amount of tokens to transfer.
     * @return success True on success, false otherwise.
     */
    function transfer(address recipient, uint256 amount) external returns (bool success);

    /**
     * @notice Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     *
     * @param sender The sender of the tokens.
     * @param recipient The recipient of the tokens.
     * @param amount The amount of tokens to transfer.
     * @return success True on success, false otherwise.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool success);

    /**
     * @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     *
     * @param spender The account to allow to spend `msg.sender`'s tokens.
     * @param amount The amount of tokens to allow to spend.
     * @return success True on success, false otherwise.
     */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
     * @notice Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to [`approve()`](#approve) that can be used as a mitigation for
     * problems described in [`approve()`](#approve).
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * @param spender The account to allow to spend `msg.sender`'s tokens.
     * @param addedValue The amount to increase allowance.
     * @return success True on success, false otherwise.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool success);

    /**
     * @notice Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to [`approve()`](#approve) that can be used as a mitigation for
     * problems described in [`approve()`](#approve).
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     *
     * @param spender The account to allow to spend `msg.sender`'s tokens.
     * @param subtractedValue The amount to decrease allowance.
     * @return success True on success, false otherwise.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool success);

    /**
     * @notice Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues [`approve()`](#approve) has related to transaction
     * ordering also apply here.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use `owner`'s current nonce (see [`nonces()`](#nonces)).
     *
     * For more information on the signature format, see
     * [EIP2612](https://eips.ethereum.org/EIPS/eip-2612#specification).
     *
     * @param owner The owner of the tokens.
     * @param spender The spender of the tokens.
     * @param value The amount to approve.
     * @param deadline The timestamp that `permit()` must go through before.
     * @param v secp256k1 signature
     * @param r secp256k1 signature
     * @param s secp256k1 signature
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
// code borrowed from https://etherscan.io/address/0x3B27F92C0e212C671EA351827EDF93DB27cc0c65#code
pragma solidity 0.8.17;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";


/**
 * @title IERC20PermitB
 * @author Hysland Finance
 * @notice An `ERC20` token that also has the `ERC2612` permit extension.
 *
 * Multiple different implementations of `permit()` were deployed to production networks before the standard was finalized. This is NOT the finalized version.
 */
interface IERC20PermitB is IERC20Metadata {

    /**
     * @notice Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for `permit`.
     *
     * Every successful call to `permit` increases `owner`'s nonce by one. This
     * prevents a signature from being used multiple times.
     * @return nonce The current nonce for `owner`.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @notice Returns the domain separator used in the encoding of the signature for `permit`, as defined by `EIP712`.
     * @return sep The domain separator.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32 sep);

    /**
     * @notice Sets the allowance of `spender` over `owner`'s tokens given `owner`'s signed approval.
     * @param owner The account that holds the tokens.
     * @param spender The account that spends the tokens.
     * @param value The amount of the token to permit.
     * @param deadline The timestamp that the transaction must go through before.
     * @param signature secp256k1 signature
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        bytes calldata signature
    ) external;
}
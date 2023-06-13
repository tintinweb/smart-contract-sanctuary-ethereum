// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./interfaces/IAuctionHouse.sol";
import "./interfaces/IAvatar.sol";
import "./interfaces/IGovernance.sol";
import "./interfaces/IMap.sol";
import "./interfaces/IMiningData.sol";
import "./libraries/TileMath.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

contract MopnBatchHelper is Multicall, Ownable {
    IGovernance governance;
    IAuctionHouse auctionHouse;
    IAvatar avatar;
    IMap map;
    IMiningData miningData;

    constructor(address governanceContract_) {
        _setGovernanceContract(governanceContract_);
    }

    function governanceContract() public view returns (address) {
        return address(governance);
    }

    function _setGovernanceContract(address governanceContract_) internal {
        governance = IGovernance(governanceContract_);
        avatar = IAvatar(governance.avatarContract());
        map = IMap(governance.mapContract());
        miningData = IMiningData(governance.miningDataContract());
        auctionHouse = IAuctionHouse(governance.auctionHouseContract());
    }

    /**
     * @notice batch redeem avatar unclaimed minted mopn token
     * @param avatarIds avatar Ids
     * @param delegateWallets Delegate coldwallet to specify hotwallet protocol
     * @param vaults cold wallet address
     */
    function batchRedeemAvatarInboxMT(
        uint256[] memory avatarIds,
        IAvatar.DelegateWallet[] memory delegateWallets,
        address[] memory vaults
    ) public {
        require(
            delegateWallets.length == 0 ||
                delegateWallets.length == avatarIds.length,
            "delegateWallets incorrect"
        );

        if (delegateWallets.length > 0) {
            for (uint256 i = 0; i < avatarIds.length; i++) {
                miningData.redeemAvatarMT(
                    avatarIds[i],
                    delegateWallets[i],
                    vaults[i]
                );
            }
        } else {
            for (uint256 i = 0; i < avatarIds.length; i++) {
                miningData.redeemAvatarMT(
                    avatarIds[i],
                    IAvatar.DelegateWallet.None,
                    address(0)
                );
            }
        }
    }

    function batchMintAvatarMT(uint256[] memory avatarIds) public {
        miningData.settlePerNFTPointMinted();
        uint256 COID;
        for (uint256 i = 0; i < avatarIds.length; i++) {
            COID = avatar.getAvatarCOID(avatarIds[i]);
            miningData.mintCollectionMT(COID);
            miningData.mintAvatarMT(avatarIds[i]);
        }
    }

    function redeemRealtimeLandHolderMT(
        uint32 LandId,
        uint256[] memory avatarIds
    ) public {
        batchMintAvatarMT(avatarIds);
        miningData.redeemLandHolderMT(LandId);
    }

    /**
     * @notice batch redeem land holder unclaimed minted mopn token
     * @param LandIds Land Ids
     */
    function batchRedeemRealtimeLandHolderMT(
        uint32[] memory LandIds,
        uint256[][] memory avatarIds
    ) public {
        for (uint256 i = 0; i < LandIds.length; i++) {
            batchMintAvatarMT(avatarIds[i]);
        }
        miningData.batchRedeemSameLandHolderMT(LandIds);
    }

    function redeemAgioTo() public {
        auctionHouse.redeemAgioTo(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAuctionHouse {
    function redeemAgioTo(address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAvatar {
    function getNFTAvatarId(
        address contractAddress,
        uint256 tokenId
    ) external view returns (uint256);

    /**
     * @notice get avatar collection id
     * @param avatarId avatar Id
     * @return COID colletion id
     */
    function getAvatarCOID(uint256 avatarId) external view returns (uint256);

    function getAvatarTokenId(uint256 avatarId) external view returns (uint256);

    /**
     * @notice get avatar bomb used number
     * @param avatarId avatar Id
     * @return bomb used number
     */
    function getAvatarBombUsed(
        uint256 avatarId
    ) external view returns (uint256);

    /**
     * @notice get avatar on map coordinate
     * @param avatarId avatar Id
     * @return tileCoordinate tile coordinate
     */
    function getAvatarCoordinate(
        uint256 avatarId
    ) external view returns (uint32);

    /**
     * @notice Avatar On Map Action Params
     * @param tileCoordinate destination tile coordinate
     * @param collectionContract the collection contract address of a nft
     * @param tokenId the token Id of a nft
     * @param linkedAvatarId linked same collection avatar Id if you have a collection ally on the map
     * @param LandId the destination tile's LandId
     * @param delegateWallet Delegate coldwallet to specify hotwallet protocol
     * @param vault cold wallet address
     */
    struct NFTParams {
        address collectionContract;
        uint256 tokenId;
        bytes32[] proofs;
        DelegateWallet delegateWallet;
        address vault;
    }

    /**
     * @notice Delegate Wallet Protocols
     */
    enum DelegateWallet {
        None,
        DelegateCash,
        Warm
    }

    function ownerOf(
        uint256 avatarId,
        DelegateWallet delegateWallet,
        address vault
    ) external view returns (address);

    /**
     * @notice an on map avatar move to a new tile
     * @param params NFTParams
     */
    function moveTo(
        NFTParams calldata params,
        uint32 tileCoordinate,
        uint256 linkedAvatarId,
        uint32 LandId
    ) external;

    /**
     * @notice throw a bomb to a tile
     * @param params NFTParams
     */
    function bomb(NFTParams calldata params, uint32 tileCoordinate) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IAvatar.sol";

interface IGovernance {
    function getCollectionContract(
        uint256 COID
    ) external view returns (address);

    function getCollectionCOID(
        address collectionContract
    ) external view returns (uint256);

    function getCollectionsCOIDs(
        address[] memory collectionContracts
    ) external view returns (uint256[] memory COIDs);

    function generateCOID(
        address collectionContract,
        bytes32[] memory proofs
    ) external returns (uint256);

    function isInWhiteList(
        address collectionContract,
        bytes32[] memory proofs
    ) external view returns (bool);

    function updateWhiteList(bytes32 whiteListRoot_) external;

    function addCollectionOnMapNum(uint256 COID) external;

    function subCollectionOnMapNum(uint256 COID) external;

    function getCollectionOnMapNum(
        uint256 COID
    ) external view returns (uint256);

    function addCollectionAvatarNum(uint256 COID) external;

    function getCollectionAvatarNum(
        uint256 COID
    ) external view returns (uint256);

    function getCollectionMintedMT(
        uint256 COID
    ) external view returns (uint256);

    function addCollectionMintedMT(uint256 COID, uint256 amount) external;

    function clearCollectionMintedMT(uint256 COID) external;

    function getCollectionVault(uint256 COID) external view returns (address);

    function mintMT(address to, uint256 amount) external;

    function mintBomb(address to, uint256 amount) external;

    function burnBomb(address from, uint256 amount) external;

    function auctionHouseContract() external view returns (address);

    function avatarContract() external view returns (address);

    function bombContract() external view returns (address);

    function mtContract() external view returns (address);

    function mapContract() external view returns (address);

    function landContract() external view returns (address);

    function miningDataContract() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMap {
    function avatarSet(
        uint256 avatarId,
        uint256 COID,
        uint32 tileCoordinate,
        uint32 LandId
    ) external;

    function avatarRemove(
        uint32 tileCoordinate,
        uint256 excludeAvatarId
    ) external returns (uint256);

    function getTileAvatar(
        uint32 tileCoordinate
    ) external view returns (uint256);

    function getTileCOID(uint32 tileCoordinate) external view returns (uint256);

    function getTileLandId(
        uint32 tileCoordinate
    ) external view returns (uint32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IAvatar.sol";

interface IMiningData {
    function getNFTOfferCoefficient() external view returns (uint256);

    /**
     * add on map mining mopn token allocation weight
     * @param avatarId avatar Id
     * @param COID collection Id
     * @param amount EAW amount
     */
    function addNFTPoint(
        uint256 avatarId,
        uint256 COID,
        uint256 amount
    ) external;

    function subNFTPoint(uint256 avatarId, uint256 COID) external;

    function settlePerNFTPointMinted() external;

    function getAvatarNFTPoint(
        uint256 avatarId
    ) external view returns (uint256);

    function calcAvatarMT(
        uint256 avatarId
    ) external view returns (uint256 inbox);

    function mintAvatarMT(uint256 avatarId) external returns (uint256);

    function redeemAvatarMT(
        uint256 avatarId,
        IAvatar.DelegateWallet delegateWallet,
        address vault
    ) external;

    function getCollectionNFTPoint(
        uint256 COID
    ) external view returns (uint256);

    function getCollectionAvatarNFTPoint(
        uint256 COID
    ) external view returns (uint256);

    function getCollectionPoint(uint256 COID) external view returns (uint256);

    function calcCollectionMT(uint256 COID) external view returns (uint256);

    function mintCollectionMT(uint256 COID) external;

    function redeemCollectionMT(uint256 COID) external;

    function settleCollectionMining(uint256 COID) external;

    function settleCollectionNFTPoint(uint256 COID) external;

    /**
     * @notice get Land holder realtime unclaimed minted mopn token
     * @param LandId MOPN Land Id
     */
    function getLandHolderInboxMT(
        uint32 LandId
    ) external view returns (uint256 inbox);

    function getLandHolderTotalMinted(
        uint32 LandId
    ) external view returns (uint256);

    function redeemLandHolderMT(uint32 LandId) external;

    function batchRedeemSameLandHolderMT(uint32[] memory LandIds) external;

    function changeTotalMTStaking(
        uint256 COID,
        bool increase,
        uint256 amount
    ) external;

    function NFTOfferAcceptNotify(uint256 price) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";

library TileMath {
    struct XYCoordinate {
        int32 x;
        int32 y;
    }

    function check(uint32 tileCoordinate) public pure {
        uint32[3] memory coodinateArr = coordinateIntToArr(tileCoordinate);
        require(
            coodinateArr[0] + coodinateArr[1] + coodinateArr[2] == 3000,
            "tile coordinate overflow"
        );
    }

    function LandRingNum(uint32 LandId) public pure returns (uint32 n) {
        n = uint32((Math.sqrt(9 + 12 * uint256(LandId)) - 3) / 6);
        if ((3 * n * n + 3 * n) == LandId) {
            return n;
        } else {
            return n + 1;
        }
    }

    function LandRingPos(uint32 LandId) public pure returns (uint32) {
        uint32 ringNum = LandRingNum(LandId) - 1;
        return LandId - (3 * ringNum * ringNum + 3 * ringNum);
    }

    function LandRingStartCenterTile(
        uint32 LandIdRingNum_
    ) public pure returns (uint32) {
        return
            (1000 - LandIdRingNum_ * 5) * 10000 + (1000 + LandIdRingNum_ * 11);
    }

    function LandCenterTile(
        uint32 LandId
    ) public pure returns (uint32 tileCoordinate) {
        if (LandId == 0) {
            return 10001000;
        }

        uint32 LandIdRingNum_ = LandRingNum(LandId);

        uint32[3] memory startTile = coordinateIntToArr(
            LandRingStartCenterTile(LandIdRingNum_)
        );

        uint32 LandIdRingPos_ = LandRingPos(LandId);

        uint32 side = uint32(Math.ceilDiv(LandIdRingPos_, LandIdRingNum_));

        uint32 sidepos = 0;
        if (LandIdRingNum_ > 1) {
            sidepos = (LandIdRingPos_ - 1) % LandIdRingNum_;
        }
        if (side == 1) {
            tileCoordinate = (startTile[0] + sidepos * 11) * 10000;
            tileCoordinate += startTile[1] - sidepos * 6;
        } else if (side == 2) {
            tileCoordinate = (2000 - startTile[2] + sidepos * 5) * 10000;
            tileCoordinate += 2000 - startTile[0] - sidepos * 11;
        } else if (side == 3) {
            tileCoordinate = (startTile[1] - sidepos * 6) * 10000;
            tileCoordinate += startTile[2] - sidepos * 5;
        } else if (side == 4) {
            tileCoordinate = (2000 - startTile[0] - sidepos * 11) * 10000;
            tileCoordinate += 2000 - startTile[1] + sidepos * 6;
        } else if (side == 5) {
            tileCoordinate = (startTile[2] - sidepos * 5) * 10000;
            tileCoordinate += startTile[0] + sidepos * 11;
        } else if (side == 6) {
            tileCoordinate = (2000 - startTile[1] + sidepos * 6) * 10000;
            tileCoordinate += 2000 - startTile[2] + sidepos * 5;
        }
    }

    function LandTileRange(
        uint32 tileCoordinate
    ) public pure returns (uint32[] memory, uint32[] memory) {
        uint32[] memory xrange = new uint32[](11);
        uint32[] memory yrange = new uint32[](11);
        uint32[3] memory blockArr = coordinateIntToArr(tileCoordinate);
        for (uint256 i = 0; i < 11; i++) {
            xrange[i] = blockArr[0] + uint32(i) - 5;
            yrange[i] = blockArr[1] + uint32(i) - 5;
        }
        return (xrange, yrange);
    }

    function getLandTilesNFTPoint(
        uint32 LandId
    ) public pure returns (uint256[] memory) {
        uint32 tileCoordinate = LandCenterTile(LandId);
        uint256[] memory TilesNFTPoint = new uint256[](91);
        TilesNFTPoint[0] = getTileNFTPoint(tileCoordinate);
        for (uint256 i = 1; i <= 5; i++) {
            tileCoordinate++;
            uint256 preringblocks = 3 * (i - 1) * (i - 1) + 3 * (i - 1);
            for (uint256 j = 0; j < 6; j++) {
                for (uint256 k = 0; k < i; k++) {
                    TilesNFTPoint[
                        preringblocks + j * i + k + 1
                    ] = getTileNFTPoint(tileCoordinate);
                    tileCoordinate = neighbor(tileCoordinate, j);
                }
            }
        }
        return TilesNFTPoint;
    }

    function getTileNFTPoint(
        uint32 tileCoordinate
    ) public pure returns (uint256) {
        if ((tileCoordinate / 10000) % 10 == 0) {
            if (tileCoordinate % 10 == 0) {
                return 15;
            }
            return 5;
        } else if (tileCoordinate % 10 == 0) {
            return 5;
        }
        return 1;
    }

    function coordinateIntToArr(
        uint32 tileCoordinate
    ) public pure returns (uint32[3] memory coordinateArr) {
        coordinateArr[0] = tileCoordinate / 10000;
        coordinateArr[1] = tileCoordinate % 10000;
        coordinateArr[2] = 3000 - (coordinateArr[0] + coordinateArr[1]);
    }

    function spiralRingTiles(
        uint32 tileCoordinate,
        uint256 radius
    ) public pure returns (uint32[] memory) {
        uint256 blockNum = 3 * radius * radius + 3 * radius;
        uint32[] memory blocks = new uint32[](blockNum);
        blocks[0] = tileCoordinate;
        for (uint256 i = 1; i <= radius; i++) {
            uint256 preringblocks = 3 * (i - 1) * (i - 1) + 3 * (i - 1);
            tileCoordinate++;
            for (uint256 j = 0; j < 6; j++) {
                for (uint256 k = 0; k < i; k++) {
                    blocks[preringblocks + j * i + k + 1] = tileCoordinate;
                    tileCoordinate = neighbor(tileCoordinate, j);
                }
            }
        }
        return blocks;
    }

    function ringTiles(
        uint32 tileCoordinate,
        uint256 radius
    ) public pure returns (uint32[] memory) {
        uint256 blockNum = 6 * radius;
        uint32[] memory blocks = new uint32[](blockNum);

        blocks[0] = tileCoordinate;
        tileCoordinate += uint32(radius);
        for (uint256 j = 0; j < 6; j++) {
            for (uint256 k = 0; k < radius; k++) {
                blocks[j * radius + k + 1] = tileCoordinate;
                tileCoordinate = neighbor(tileCoordinate, j);
            }
        }
        return blocks;
    }

    function tileSpheres(
        uint32 tileCoordinate
    ) public pure returns (uint32[] memory) {
        uint32[] memory blocks = new uint32[](7);
        blocks[0] = tileCoordinate;
        tileCoordinate++;
        for (uint256 i = 1; i < 7; i++) {
            blocks[i] = tileCoordinate;
            tileCoordinate = neighbor(tileCoordinate, i);
        }
        return blocks;
    }

    function direction(uint256 direction_) public pure returns (int32) {
        if (direction_ == 0) {
            return 9999;
        } else if (direction_ == 1) {
            return -1;
        } else if (direction_ == 2) {
            return -10000;
        } else if (direction_ == 3) {
            return -9999;
        } else if (direction_ == 4) {
            return 1;
        } else if (direction_ == 5) {
            return 10000;
        } else {
            return 0;
        }
    }

    function neighbor(
        uint32 tileCoordinate,
        uint256 direction_
    ) public pure returns (uint32) {
        return uint32(int32(tileCoordinate) + direction(direction_));
    }

    function distance(uint32 a, uint32 b) public pure returns (uint32 d) {
        uint32[3] memory aarr = coordinateIntToArr(a);
        uint32[3] memory barr = coordinateIntToArr(b);
        for (uint256 i = 0; i < 3; i++) {
            d += aarr[i] > barr[i] ? aarr[i] - barr[i] : barr[i] - aarr[i];
        }

        return d / 2;
    }

    function coordinateToXY(
        uint32 tileCoordinate
    ) public pure returns (XYCoordinate memory xycoordinate) {
        xycoordinate.x = int32(tileCoordinate / 10000) - 1000;
        xycoordinate.y = int32(tileCoordinate % 10000) - 1000;
    }
}
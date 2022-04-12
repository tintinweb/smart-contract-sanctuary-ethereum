// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./TransferHelper.sol";
import "./INFTStaking.sol";
import "./INFTRental.sol";

contract NFTRental is Context, ERC165, INFTRental, Ownable, ReentrancyGuard {
    using SafeCast for uint256;

    address private immutable ERC20_TOKEN_ADDRESS;
    INFTStaking private immutable NFTStaking;
    mapping(uint256 => RentInformation) private rentInformation;
    mapping(address => uint256) public rentCount; // count of rented nfts per tenant
    mapping(address => mapping(uint256 => uint256)) private _rentedItems; // enumerate rented nfts per tenant
    mapping(uint256 => uint256) private _rentedItemsIndex; // tokenId to index in _rentedItems[tenant]

    /**
    ////////////////////////////////////////////////////
    // Admin Functions 
    ///////////////////////////////////////////////////
     */
    constructor(address _tokenAddress, INFTStaking _stakingAddress) {
        require(_tokenAddress != address(0), "INVALID_TOKEN_ADDRESS");
        require(
            _stakingAddress.supportsInterface(type(INFTStaking).interfaceId),
            "INVALID_STAKING_ADDRESS"
        );
        ERC20_TOKEN_ADDRESS = _tokenAddress;
        NFTStaking = _stakingAddress;
    }

    // Rescue ERC20 tokens sent directly to this contract
    function rescueERC20(address _token, uint256 _amount) external onlyOwner {
        TransferHelper.safeTransfer(_token, _msgSender(), _amount);
    }

    /**
    ////////////////////////////////////////////////////
    // Public Functions 
    ///////////////////////////////////////////////////
     */

    // Start the rent to a staked token
    function startRent(uint256 _tokenId, uint256 _initialPayment)
        external
        virtual
        override
        nonReentrant
    {
        INFTStaking.StakeInformation memory stakeInfo_ = NFTStaking
            .getStakeInformation(_tokenId);
        RentInformation memory rentInformation_ = rentInformation[_tokenId];
        require(stakeInfo_.owner != address(0), "NOT_STAKED");
        require(stakeInfo_.enableRenting == true, "RENT_DISABLED");
        require(
            uint256(stakeInfo_.rentableUntil) >=
                block.timestamp + stakeInfo_.minRentDays * (1 days),
            "NOT_AVAILABLE"
        );
        if (rentInformation_.tenant != address(0)) {
            // if previously rented
            uint256 paidUntil = rentalPaidUntil(_tokenId);
            require(paidUntil < block.timestamp, "ACTIVE_RENT");
        }
        // should pay at least deposit + 1 day of rent
        require(
            _initialPayment >= (stakeInfo_.deposit + stakeInfo_.rentalPerDay),
            "INSUFFICENT_PAYMENT"
        );
        // prevent the user from paying too much
        // block.timestamp casts it into uint256 which is desired
        // if the rentable time left is less than minRentDays then the tenant just has to pay up until the time limit
        uint256 paymentAmount = Math.min(
            ((stakeInfo_.rentableUntil - block.timestamp) *
                stakeInfo_.rentalPerDay) / (1 days),
            _initialPayment
        );
        rentInformation_.tenant = _msgSender();
        rentInformation_.rentStartTime = block.timestamp.toUint32();
        rentInformation_.rentalPaid += paymentAmount;
        TransferHelper.safeTransferFrom(
            ERC20_TOKEN_ADDRESS,
            _msgSender(),
            stakeInfo_.owner,
            paymentAmount
        );
        rentInformation[_tokenId] = rentInformation_;
        uint256 count = rentCount[_msgSender()];
        _rentedItems[_msgSender()][count] = _tokenId;
        _rentedItemsIndex[_tokenId] = count;
        rentCount[_msgSender()]++;
        emit Rented(_tokenId, _msgSender(), paymentAmount);
    }

    // Used by tenant to pay rent in advance. As soon as the tenant defaults the renter can vacate the tenant
    // The rental period can be extended as long as rent is prepaid, up to rentableUntil timestamp.
    // payment unit in ether
    function payRent(uint256 _tokenId, uint256 _payment)
        external
        virtual
        override
        nonReentrant
    {
        INFTStaking.StakeInformation memory stakeInfo_ = NFTStaking
            .getStakeInformation(_tokenId);
        RentInformation memory rentInformation_ = rentInformation[_tokenId];
        require(rentInformation_.tenant == _msgSender(), "NOT_RENTED");
        // prevent the user from paying too much
        uint256 paymentAmount = Math.min(
            (uint256(
                stakeInfo_.rentableUntil - rentInformation_.rentStartTime
            ) * stakeInfo_.rentalPerDay) /
                (1 days) -
                rentInformation_.rentalPaid,
            _payment
        );
        rentInformation_.rentalPaid += paymentAmount;
        TransferHelper.safeTransferFrom(
            ERC20_TOKEN_ADDRESS,
            _msgSender(),
            stakeInfo_.owner,
            paymentAmount
        );
        rentInformation[_tokenId] = rentInformation_;
        emit RentPaid(_tokenId, _msgSender(), paymentAmount);
    }

    // Used by renter to vacate tenant in case of default, or when rental period expires.
    // If payment + deposit covers minRentDays then deposit can be used as rent. Otherwise rent has to be provided in addition to the deposit.
    // If rental period is shorter than minRentDays then deposit will be forfeited.
    function terminateRent(uint256 _tokenId) external virtual override {
        require(
            NFTStaking.getStakeInformation(_tokenId).owner == _msgSender(),
            "NFT_NOT_OWNED"
        );
        uint256 paidUntil = rentalPaidUntil(_tokenId);
        require(paidUntil < block.timestamp, "ACTIVE_RENT");
        address tenant = rentInformation[_tokenId].tenant;
        emit RentTerminated(_tokenId, tenant);
        rentCount[tenant]--;
        uint256 lastIndex = rentCount[tenant];
        uint256 tokenIndex = _rentedItemsIndex[_tokenId];
        // swap and purge if not the last one
        if (tokenIndex != lastIndex) {
            uint256 lastTokenId = _rentedItems[tenant][lastIndex];

            _rentedItems[tenant][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _rentedItemsIndex[lastTokenId] = tokenIndex;
        }
        delete _rentedItemsIndex[_tokenId];
        delete _rentedItems[tenant][tokenIndex];

        rentInformation[_tokenId] = RentInformation(address(0), 0, 0);
    }

    /**
    ////////////////////////////////////////////////////
    // View Only Functions 
    ///////////////////////////////////////////////////
     */
    function isRentActive(uint256 _tokenId)
        public
        view
        override
        returns (bool)
    {
        return rentInformation[_tokenId].tenant != address(0);
    }

    function getTenant(uint256 _tokenId)
        public
        view
        override
        returns (address)
    {
        return rentInformation[_tokenId].tenant;
    }

    function rentByIndex(address _tenant, uint256 _index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(_index < rentCount[_tenant], "INDEX_OUT_OF_BOUND");
        return _rentedItems[_tenant][_index];
    }

    function isRentable(uint256 _tokenId)
        external
        view
        virtual
        override
        returns (bool state)
    {
        INFTStaking.StakeInformation memory stakeInfo_ = NFTStaking
            .getStakeInformation(_tokenId);
        RentInformation memory rentInformation_ = rentInformation[_tokenId];
        state =
            (stakeInfo_.owner != address(0)) &&
            (uint256(stakeInfo_.rentableUntil) >=
                block.timestamp + stakeInfo_.minRentDays * (1 days));
        if (rentInformation_.tenant != address(0)) {
            // if previously rented
            uint256 paidUntil = rentalPaidUntil(_tokenId);
            state = state && (paidUntil < block.timestamp);
        }
    }

    // Get rental amount paid until now
    function rentalPaidUntil(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (uint256 paidUntil)
    {
        INFTStaking.StakeInformation memory stakeInfo_ = NFTStaking
            .getStakeInformation(_tokenId);
        RentInformation memory rentInformation_ = rentInformation[_tokenId];
        if (stakeInfo_.rentalPerDay == 0) {
            paidUntil = stakeInfo_.rentableUntil;
        } else {
            uint256 rentalPaidSeconds = (uint256(rentInformation_.rentalPaid) *
                (1 days)) / stakeInfo_.rentalPerDay;
            bool fundExceedsMin = rentalPaidSeconds >=
                Math.max(
                    stakeInfo_.minRentDays * (1 days),
                    block.timestamp - rentInformation_.rentStartTime
                );
            paidUntil =
                uint256(rentInformation_.rentStartTime) +
                rentalPaidSeconds -
                (
                    fundExceedsMin
                        ? 0
                        : (uint256(stakeInfo_.deposit) * (1 days)) /
                            stakeInfo_.rentalPerDay
                );
        }
    }

    // Get rent information
    function getRentInformation(uint256 _tokenId)
        external
        view
        override
        returns (RentInformation memory)
    {
        return rentInformation[_tokenId];
    }

    /**
    ////////////////////////////////////////////////////
    // Internal Functions 
    ///////////////////////////////////////////////////
     */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(INFTRental).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
    helper methods for interacting with ERC20 tokens that do not consistently return true/false
    with the addition of a transfer function to send eth or an erc20 token
*/
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    // sends ETH or an erc20 token
    function safeTransferBaseToken(
        address token,
        address payable to,
        uint256 value,
        bool isERC20
    ) internal {
        if (!isERC20) {
            to.transfer(value);
        } else {
            (bool success, bytes memory data) = token.call(
                abi.encodeWithSelector(0xa9059cbb, to, value)
            );
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                "TransferHelper: TRANSFER_FAILED"
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface INFTStaking is IERC165, IERC721Receiver {
    event Staked(uint256 indexed tokenId, address indexed user);
    event Unstaked(uint256 indexed tokenId, address indexed user);

    struct StakeInformation {
        address owner; // staked to, otherwise owner == 0
        uint256 deposit; // unit is ether, paid in NRGY. The deposit is deducted from the last payment(s) since the deposit is non-custodial
        uint256 rentalPerDay; // unit is ether, paid in NRGY. Total is deposit + rentalPerDay * days
        uint16 minRentDays; // must rent for at least min rent days, otherwise deposit is forfeited up to this amount
        uint32 rentableUntil; // timestamp in unix epoch
        uint32 stakedFrom; // staked from timestamp
        bool enableRenting; // enable/disable renting
    }

    function getOriginalOwner(uint256 _tokenId) external view returns (address);

    // view functions
    function getStakeInformation(uint256 _tokenId)
        external
        view
        returns (StakeInformation memory);

    function getStakingDuration(uint256 _tokenId)
        external
        view
        returns (uint256);

    function isStakeActive(uint256 _tokenId) external view returns (bool);

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external view override returns (bytes4);

    function stake(
        uint256[] calldata _tokenIds,
        address _stakeTo,
        uint256 _deposit,
        uint256 _rentalPerDay,
        uint16 _minRentDays,
        uint32 _rentableUntil,
        bool _enableRent
    ) external;

    function updateRent(
        uint256[] calldata _tokenIds,
        uint256 _deposit,
        uint256 _rentalPerDay,
        uint16 _minRentDays,
        uint32 _rentableUntil,
        bool _enableRent
    ) external;

    function extendRentalPeriod(uint256 _tokenId, uint32 _rentableUntil)
        external;

    function unstake(uint256[] calldata _tokenIds, address _unstakeTo) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface INFTRental is IERC165 {
    event Rented(
        uint256 indexed tokenId,
        address indexed tenant,
        uint256 payment
    );
    event RentPaid(
        uint256 indexed tokenId,
        address indexed tenant,
        uint256 payment
    );
    event RentTerminated(uint256 indexed tokenId, address indexed tenant);

    struct RentInformation {
        address tenant; // rented to, otherwise tenant == 0
        uint32 rentStartTime; // timestamp in unix epoch
        uint256 rentalPaid; // total rental paid since the beginning including the deposit
    }

    function isRentActive(uint256 _tokenId) external view returns (bool);

    function getTenant(uint256 _tokenId) external view returns (address);

    function getRentInformation(uint256 _tokenId)
        external
        view
        returns (RentInformation memory);

    function rentByIndex(address _tenant, uint256 _index)
        external
        view
        returns (uint256);

    function isRentable(uint256 _tokenId) external view returns (bool state);

    function rentalPaidUntil(uint256 _tokenId)
        external
        view
        returns (uint256 paidUntil);

    function startRent(uint256 _tokenId, uint256 _initialPayment) external;

    function payRent(uint256 _tokenId, uint256 _payment) external;

    function terminateRent(uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
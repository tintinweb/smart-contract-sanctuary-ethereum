/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

// SPDX-License-Identifier: MIT LICENSE
// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: CultPool.sol



pragma solidity 0.8.14;



interface IERC {
    /// @notice From $CULT ERC-20 contract interface
    function transfer(address recipient, uint256 amount) external;

    /// @notice From CultDAO NFT ERC-721 contract interface
    function ownerOf(uint256 tokenId) external returns (address);

    function totalSupply() external returns (uint256);
}

/// @title A reward pool smart contract for CultDAO NFT holders to claim $CULT as part of the CultDAO NFT utilities.
/// @author Syahmi Rafsanjani (RAFSANS.com) for CultDAO.art
/// @notice You can use this contract to claim $CULT for your CultDAO NFT and view the latest claim receipt
contract CultRewardPool is Ownable {
    using SafeMath for uint256;

    /// @dev This variable is used in the read function to prevent gas fees from calling the NFT contract externally.
    uint256 internal constant nftSupply = 6666;

    /// @notice The current $CULT reward per day
    /// @dev By calculation, coinReward = 100 ether is equivalent to 1 coin reward per day
    uint256 public coinReward = 10000 ether; //

    /// @dev The calculation is calculated by total seconds per day
    uint256 internal constant denomValue = 86400;

    /// @dev The contract addresses for the official CultDAO NFT contract and $CULT ERC-20 token
    address public constant nftContract = 0xE0cdF882eBA049E363B1226a5af1e4C6062840CF;
    address public constant tokenContract = 0xf0f9D895aCa5c8678f706FB8216fa22957685A13;

    /// @dev tokenId is mapped to claimVault with claimReceipt struct
    mapping(uint256 => ClaimReceipt) public claimVault;

    /// @notice The block timestamp when the contract was deployed
    uint256 public deployedBlock;

    /// @dev The ClaimReceipt struct stores a claimed token's tokenId, the last claim timestamp, owner address, and the last earning value
    struct ClaimReceipt {
        uint24 tokenId;
        uint256 timestamp;
        address owner;
        uint256 amount;
    }

    /// @notice The Claimed event is emitted whenever a token is claimed
    event Claimed(
        address owner,
        uint256 tokenId,
        uint256 timestamp,
        uint256 amount
    );

    constructor() {
        /// @dev The deployedBlock variable is used to store the block when contract was deployed
        deployedBlock = uint256(block.timestamp);
    }

    /// @notice Claim $CULT for every NFT held and included in the array
    /// @param tokenIds Array of NFT tokens
    function claim(uint256[] calldata tokenIds) external {
        _claim(msg.sender, tokenIds);
    }

    /// @dev The internal function that is called within the claim function above.
    /// @param tokenIds Array of NFT tokens
    function _claim(address account, uint256[] calldata tokenIds) internal {
        uint256 tokenId;
        uint256 earned = 0;
        uint256 rewardmath = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];

            /// @dev To check if tokenId has been claimed before. If no, get difference by comparing current timestamp with deployedBlock timestamp
            if (claimVault[tokenId].tokenId == 0) {
                require(
                    IERC(nftContract).ownerOf(tokenId) == msg.sender,
                    "not your NFT"
                );
                rewardmath =
                    (coinReward * (block.timestamp - deployedBlock)) /
                    denomValue;

                earned += rewardmath / 100;

                /// @dev claimVault stores tokenId's ClaimReceipt struct
                claimVault[tokenId] = ClaimReceipt({
                    owner: account,
                    tokenId: uint24(tokenId),
                    timestamp: uint256(block.timestamp),
                    amount: rewardmath / 100
                });

                emit Claimed(
                    msg.sender,
                    uint24(tokenId),
                    uint256(block.timestamp),
                    rewardmath / 100
                );
            }
            /// @dev If tokenId has been claimed before, get the difference by comparing current timestamp with last claimed timestamp
            else {
                ClaimReceipt memory claimed = claimVault[tokenId];
                require(
                    IERC(nftContract).ownerOf(tokenId) == msg.sender,
                    "not your NFT"
                );
                uint256 claimedAt = claimed.timestamp;

                rewardmath =
                    (coinReward * (block.timestamp - claimedAt)) /
                    denomValue;

                earned += rewardmath / 100;

                /// @dev claimVault stores tokenId's ClaimReceipt struct
                claimVault[tokenId] = ClaimReceipt({
                    owner: account,
                    tokenId: uint24(tokenId),
                    timestamp: uint256(block.timestamp),
                    amount: rewardmath / 100
                });

                emit Claimed(
                    msg.sender,
                    uint24(tokenId),
                    uint256(block.timestamp),
                    rewardmath / 100
                );
            }
        }
        if (earned > 0) {
            /// @notice Transfer $CULT to tokenId's owner
            /// @dev $CULT is transferred from the contract's $CULT holdings to the claimer
            IERC(tokenContract).transfer(account, earned);
        }
    }

    /// @notice To view the claimable $CULT based on the NFT tokenID
    /// @param tokenIds Array of NFT tokens
    /// @return earnedTotal total claimable $CULT
    function claimableInfo(uint256[] calldata tokenIds)
        external
        view
        returns (uint256 earnedTotal)
    {
        uint256 tokenId;
        uint256 earned = 0;
        uint256 rewardmath = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];

            /// @notice Check if tokenId is within nftSupply

            if (tokenId < nftSupply) {
                /// @dev To check if tokenId has been claimed before. If no, get difference by comparing current timestamp with deployedBlock timestamp
                if (claimVault[tokenId].tokenId == 0) {
                    rewardmath =
                        (coinReward * (block.timestamp - deployedBlock)) /
                        denomValue;

                    earned += rewardmath / 100;
                }
                /// @dev If tokenId has been claimed before, get the difference by comparing current timestamp with last claimed timestamp
                else {
                    ClaimReceipt memory claimed = claimVault[tokenId];

                    uint256 claimedAt = claimed.timestamp;

                    rewardmath =
                        (coinReward * (block.timestamp - claimedAt)) /
                        denomValue;

                    earned += rewardmath / 100;
                }
            }
        }
        if (earned > 0) {
            return earned;
        }
    }

    /// @dev To change the coinReward variable of $CULT reward per day. Can only be called by the current owner.
    function setCoinReward(uint256 _coinReward) external onlyOwner {
        coinReward = _coinReward;
    }
}
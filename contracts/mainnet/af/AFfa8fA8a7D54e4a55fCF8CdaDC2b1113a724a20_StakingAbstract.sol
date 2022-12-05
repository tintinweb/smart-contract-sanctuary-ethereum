// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Staking functionality to earn $CDM.
/// @author cryptodollarmenu.com
/// @notice Stake a Breakfast Sandwich and earn $CDM.
contract StakingAbstract is IERC721Receiver, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    /// @notice A boolean value used to allow only one setting of the ERC20 token address.
    bool public someTokenSet;

    /// @notice A boolean value used to allow only one setting of the ERC721 token address.
    bool public utilityTokenSet;

    /// @notice A Stake struct represents how a staked token is stored.
    struct Stake {
        address user;
        uint256 tokenId;
        uint256 stakedFromBlock;
    }

    /// @notice A Stakeholder struct stores an address and its active Stakes.
    struct Stakeholder {
        address user;
        Stake[] addressStakes;
    }

     /// @notice A StakingSummary struct stores an array of Stake structs.
     struct StakingSummary {
         Stake[] stakes;
     }

    /// @notice Interface definition for the ERC721 token that is being staked.
    /// @dev This is the Ethereum Breakfast Sandwich ERC721 collection.
    IERC721 public utilityToken;

    /// @notice Interface definition for the ERC20 token that is being used a staking reward.
    /// @dev This will be $CDM in this case.
    IERC20 public someToken;

    /// @notice The amount of ERC20 tokens received as a reward for every block an ERC721 token is staked.
    /// @dev Amount is 1.388888889 expressed in Wei.
    // Reference: https://ethereum.org/en/developers/docs/blocks/
    // Reference for merge: https://blog.ethereum.org/2021/11/29/how-the-merge-impacts-app-layer/
    uint256 public tokensPerBlock = 1388888889000000000;

    /// @notice An address is used as a key to an index value in the stakes that occur.
    mapping(address => uint256) private stakes;
    /// @notice An address is used as a key to the array of Stakes.
    mapping(address => Stake[]) private addressStakes;
    /// @notice An integer is used as key to the value of a Stake in order to provide a receipt.
    mapping(uint256 => Stake) public receipt;

    /// @notice All current stakeholders.
    Stakeholder[] private stakeholders;

     /// @notice Emitted when a token is staked.
    event Staked(address indexed user, uint256 indexed tokenId, uint256 staredFromBlock, uint256 index);

    /// @notice Emitted when a token is unstaked.
    event Unstaked(address indexed user, uint256 indexed tokenId, uint256 blockNumber);

    /// @notice Emitted when a token is unstaked in an emergency.
    event EmergencyUnstaked(address indexed user, uint256 indexed tokenId, uint256 blockNumber);

    /// @notice Emitted when a reward is paid out to an address.
    event StakePayout(address indexed staker, uint256 tokenId, uint256 stakeAmount, uint256 fromBlock, uint256 toBlock);

    /// @notice Emitted when the rewards per block are updated.
    /// @dev Value is in Wei.
    event StakeRewardUpdated(uint256 rewardPerBlock);

    /// @notice Requirements related to token ownership.
    /// @param tokenId The current tokenId being staked.
    modifier onlyStaker(uint256 tokenId) {
        // Require that this contract has the token.
        require(utilityToken.ownerOf(tokenId) == address(this), "onlyStaker: Contract is not owner of this NFT");

        // Require that this token is staked.
        require(receipt[tokenId].stakedFromBlock != 0, "onlyStaker: Token is not staked");

        // Require that msg.sender is the owner of this tokenId.
        require(receipt[tokenId].user == msg.sender, "onlyStaker: Caller is not NFT stake owner");

        _;
    }

    /// @notice A requirement to have at least one block pass before staking, unstaking or harvesting.
    /// @param tokenId The tokenId being staked or unstaked.
    modifier requireTimeElapsed(uint256 tokenId) {
        require(
            receipt[tokenId].stakedFromBlock < block.number,
            "requireTimeElapsed: Cannot stake/unstake/harvest in the same block"
        );
        _;
    }

    /// @dev Push needed to avoid index 0 causing bug of index-1.
    constructor() {
        stakeholders.push();
    }

    /// @dev Required implementation to support safeTransfers from ERC721 asset contracts.
    function onERC721Received (
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "No sending tokens directly to staking contract");
        return IERC721Receiver.onERC721Received.selector;
    }

    /// @notice Accepts a tokenId to perform staking.
    /// @param tokenId The tokenId to be staked.
    function stakeUtilityToken(uint256 tokenId) external nonReentrant {
        _stakeUtilityToken(tokenId);
    }

    /// @notice Accepts a tokenId to perform unstaking.
    /// @param tokenId The tokenId to be unstaked.
    function unstakeUtilityToken(uint256 tokenId) external nonReentrant {
        _unstakeUtilityToken(tokenId);
    }

    /// @notice Accepts a tokenId to perform emergency unstaking.
    /// @param tokenId The tokenId to be emergency unstaked.
    function emergencyUnstake(uint256 tokenId) external nonReentrant {
        _emergencyUnstake(tokenId);
    }

    /// @notice Sets the ERC721 contract this staking contract is for.
    /// @param _utilityToken The ERC721 contract address to have its tokenIds staked.
    function setUtilityToken(IERC721 _utilityToken) public onlyOwner {
        require(utilityTokenSet == false);
        utilityToken = _utilityToken;
        utilityTokenSet = true;
    }

    /// @notice Sets the ERC20 token used as staking rewards.
    /// @param _someToken The ERC20 token contract that will provide reward tokens.
    function setSomeToken(IERC20 _someToken) public onlyOwner {
        require(someTokenSet == false);
        someToken = _someToken;
        someTokenSet = true;
    }

    /// @notice Harvesting the ERC20 rewards earned by a staked ERC721 token.
    /// @param tokenId The tokenId of the staked token for which rewards are withdrawn.
    function harvest(uint256 tokenId)
        public
        nonReentrant
        onlyStaker(tokenId)
        requireTimeElapsed(tokenId)
    {
        _payoutStake(tokenId);
        receipt[tokenId].stakedFromBlock = block.number;
    }

    /// @notice Determine the amount of rewards earned by a staked token.
    /// @param tokenId The tokenId of the staked token.
    /// @return The value in Wei of the rewards currently earned by the tokenId.
    function getCurrentStakeEarned(uint256 tokenId) public view returns (uint256) {
        return _getTimeStaked(tokenId).mul(tokensPerBlock);
    }

    /// @notice Determine the contract address of the ERC20 token providing rewards.
    /// @return The contract address of the rewards token.
    function getSomeTokenAddress() public view returns (address) {
        return address(someToken);
    }

    /// @notice Receive a summary of current stakes by a given address.
    /// @param _user The address to receive a summary for.
    /// @return A staking summary for a given address.
    function getStakingSummary(address _user) public view returns (StakingSummary memory) {
        StakingSummary memory summary = StakingSummary(stakeholders[stakes[_user]].addressStakes);
        return summary;
    }

    /// @notice The amount of the rewards token available in the staking contract.
    /// @dev Expressed in Wei.
    /// @return The amount of the ERC20 reward token still available for emissions.
    function getTokenBalance() public view returns (uint256) {
        return someToken.balanceOf(address(this));
    }

    /// @notice Determine the contract address of the ERC721 contract set to collect staking rewards.
    /// @return The contract address of the stakeable ERC721 contract.
    function getUtilityTokenAddress() public view returns (address) {
        return address(utilityToken);
    }

    /// @notice Adds a staker to the stakeholders array.
    /// @param staker An address that is staking an ERC721 token.
    /// @return The index of the address within the array of stakeholders.
    function _addStakeholder(address staker) internal returns (uint256) {
        // Push a empty item to the array to make space the new stakeholder.
        stakeholders.push();
        // Calculate the index of the last item in the array by Len-1.
        uint256 userIndex = stakeholders.length - 1;
        // Assign the address to the new index.
        stakeholders[userIndex].user = staker;
        // Add index to the stakeHolders.
        stakes[staker] = userIndex;
        return userIndex;
    }

    /// @notice Stakes the given ERC721 tokenId to provide ERC20 rewards.
    /// @param tokenId The tokenId to be staked.
    /// @return A boolean indicating whether the staking was completed.
    function _stakeUtilityToken(uint256 tokenId) internal returns (bool) {
        // Check for sending address of the tokenId in the current stakes.
        uint256 index = stakes[msg.sender];
        // Fulfil condition based on whether staker already has a staked index or not.
        if (index == 0) {
            // The stakeholder is taking for the first time and needs to mapped into the index of stakers.
            // The index returned will be the index of the stakeholder in the stakeholders array.
            index = _addStakeholder(msg.sender);
        }

        // Use the index value of the staker to add a new stake.
        stakeholders[index].addressStakes.push(Stake(msg.sender, tokenId, block.number));

        // Require that the tokenId is not already staked.
        require(receipt[tokenId].stakedFromBlock == 0, "Stake: Token is already staked");

        // Required that the tokenId is not already owned by this contract as a result of staking.
        require(utilityToken.ownerOf(tokenId) != address(this), "Stake: Token is already staked in this contract");

        // Transer the ERC721 token to this contract for staking.
        utilityToken.transferFrom(_msgSender(), address(this), tokenId);

        // Check that this contract is the owner.
        require(utilityToken.ownerOf(tokenId) == address(this), "Stake: Failed to take possession of NFT");

        // Start the staking from this block.
        receipt[tokenId].user = msg.sender;
        receipt[tokenId].tokenId = tokenId;
        receipt[tokenId].stakedFromBlock = block.number;

        emit Staked(msg.sender, tokenId, block.number, index);

        return true;
    }

    /// @notice Unstakes the given ERC721 tokenId and claims ERC20 rewards.
    /// @param tokenId The tokenId to be unstaked.
    /// @return A boolean indicating whether the unstaking was completed.
    function _unstakeUtilityToken(uint256 tokenId)
        internal
        onlyStaker(tokenId)
        requireTimeElapsed(tokenId)
        returns (bool)
    {
        // Payout the rewards collected as a result of staking.
        _payoutStake(tokenId);

        // Delete the receipt of the given tokenId.
        delete receipt[tokenId];

        // Transfer the tokenId away from the staking contract back to the ERC721 contract.
        utilityToken.safeTransferFrom(address(this), _msgSender(), tokenId);

        // Determine the index of the tokenId to be unstaked from list of stakes by an address.
        uint256 userIndex = stakes[msg.sender];
        Stake[] memory currentStakeList = stakeholders[userIndex].addressStakes;
        uint256 stakedItemsLength = currentStakeList.length;
        uint256 unstakedTokenIdx;

        for (uint256 i = 0; i < stakedItemsLength; i++) {
            Stake memory stake = currentStakeList[i];
            if (stake.tokenId == tokenId) {
                unstakedTokenIdx = i;
            }
        }

        // Use the determined index of the tokenId to pop the Stake values of the tokenId.
        Stake memory lastStake = currentStakeList[currentStakeList.length - 1];
        stakeholders[userIndex].addressStakes[unstakedTokenIdx].user = lastStake.user;
        stakeholders[userIndex].addressStakes[unstakedTokenIdx].tokenId = lastStake.tokenId;
        stakeholders[userIndex].addressStakes[unstakedTokenIdx].stakedFromBlock = lastStake.stakedFromBlock;
        stakeholders[userIndex].addressStakes.pop();

        emit Unstaked(msg.sender, tokenId, block.number);

        return true;
    }

    /// @notice Emergency unstakes the given ERC721 tokenId and does not claim ERC20 rewards.
    /// @param tokenId The tokenId to be emergency unstaked.
    /// @return A boolean indicating whether the emergency unstaking was completed.
    function _emergencyUnstake(uint256 tokenId)
        internal
        onlyStaker(tokenId)
        returns (bool)
    {

        // Delete the receipt of the given tokenId.
        delete receipt[tokenId];

        // Transfer the tokenId away from the staking contract back to the ERC721 contract.
        utilityToken.safeTransferFrom(address(this), _msgSender(), tokenId);

        // Determine the index of the tokenId to be unstaked from list of stakes by an address.
        uint256 userIndex = stakes[msg.sender];
        Stake[] memory currentStakeList = stakeholders[userIndex].addressStakes;
        uint256 stakedItemsLength = currentStakeList.length;
        uint256 unstakedTokenIdx;

        for (uint256 i = 0; i < stakedItemsLength; i++) {
            Stake memory stake = currentStakeList[i];
            if (stake.tokenId == tokenId) {
                unstakedTokenIdx = i;
            }
        }

        // Use the determined index of the tokenId to pop the Stake values of the tokenId.
        Stake memory lastStake = currentStakeList[currentStakeList.length - 1];
        stakeholders[userIndex].addressStakes[unstakedTokenIdx].user = lastStake.user;
        stakeholders[userIndex].addressStakes[unstakedTokenIdx].tokenId = lastStake.tokenId;
        stakeholders[userIndex].addressStakes[unstakedTokenIdx].stakedFromBlock = lastStake.stakedFromBlock;
        stakeholders[userIndex].addressStakes.pop();

        emit EmergencyUnstaked(msg.sender, tokenId, block.number);

        return true;
    }

    /// @notice Calculates and transfers earned rewards for a given tokenId.
    /// @param tokenId The tokenId for which rewards are to be calculated and paid out.
    function _payoutStake(uint256 tokenId) internal {
        /* NOTE : Must be called from non-reentrant function to be safe!*/

        // Double check that the receipt exists and that staking is beginning from block 0.
        require(receipt[tokenId].stakedFromBlock > 0, "_payoutStake: No staking from block 0");

        // Remove the transaction block of withdrawal from time staked.
        uint256 timeStaked = _getTimeStaked(tokenId).sub(1); // don't pay for the tx block of withdrawl

        uint256 payout = timeStaked.mul(tokensPerBlock);

        // If the staking contract does not have any ERC20 rewards left, return the ERC721 token without payment.
        // This prevents any type of ERC721 locking.
        if (someToken.balanceOf(address(this)) < payout) {
            emit StakePayout(msg.sender, tokenId, 0, receipt[tokenId].stakedFromBlock, block.number);
            return;
        }

        // Payout the earned rewards.
        someToken.transfer(receipt[tokenId].user, payout);

        emit StakePayout(msg.sender, tokenId, payout, receipt[tokenId].stakedFromBlock, block.number);
    }

    /// @notice Determine the number of blocks for which a given tokenId has been staked.
    /// @param tokenId The staked tokenId.
    /// @return The integer value indicating the difference the current block and the initial staking block.
    function _getTimeStaked(uint256 tokenId) internal view returns (uint256) {
        if (receipt[tokenId].stakedFromBlock == 0) {
            return 0;
        }
        return block.number.sub(receipt[tokenId].stakedFromBlock);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
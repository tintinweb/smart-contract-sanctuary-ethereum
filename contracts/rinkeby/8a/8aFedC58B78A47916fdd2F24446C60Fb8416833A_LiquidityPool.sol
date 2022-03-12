// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

contract LiquidityPool is Ownable {
    uint256 private totalStake;
    uint256 private totalRewards;
    uint256 private lastRewardDate;

    struct StakerInfo {
        uint256 stake;
        uint256 rewardToParticipant;
        uint256 entryDate;
    }

    mapping(address => StakerInfo) private participant;

    enum PoolOperations {
        Deposit,
        Reward,
        Withdraw
    }

    event PoolEvent(address _opAddress, uint256 _opAmount, uint256 _opType);

    event TeamMember(address _memberAddress);

    constructor() {
        totalStake = 0;
        totalRewards = 0;
        lastRewardDate = 0;
        addTeamMember(msg.sender);
    }

    // Mapping and functions to manage ETH Pool Team Member's addresses
    mapping(address => bool) public teamMember;

    function addTeamMember(address _address) public onlyOwner {
        teamMember[_address] = true;
        emit TeamMember(_address);
    }

    function removeTeamMember(address _address) public onlyOwner {
        teamMember[_address] = false;
    }

    modifier onlyOwnerOrMember() {
        require(
            msg.sender == owner() || teamMember[msg.sender] == true,
            "Must be owner or Team member"
        );
        _;
    }

    // Deposit stake
    // Increases the stake of sender address by sent amount
    // If address is new to the pool, asociates that first transaction block's timestamp
    // with and entry date
    function depositStake() public payable {
        participant[msg.sender].stake += msg.value;
        if (participant[msg.sender].entryDate == 0) {
            participant[msg.sender].entryDate = block.timestamp;
        }
        totalStake += msg.value;
        emit PoolEvent(msg.sender, msg.value, uint256(PoolOperations.Deposit));
    }

    // Deposit rewards by the owner or team members.
    function depositReward() public payable onlyOwnerOrMember {
        require(totalStake > 0, "None Staked");
        totalRewards += msg.value;
        lastRewardDate = block.timestamp;
        emit PoolEvent(msg.sender, msg.value, uint256(PoolOperations.Reward));
    }

    // Withdraw function.
    function withdrawStakeAndReward() public payable {
        require(participant[msg.sender].stake > 0, "Stake not found");

        uint256 withdrawRewardAmount = 0;

        if (
            participant[msg.sender].entryDate <= lastRewardDate &&
            participant[msg.sender].entryDate > 0
        ) {
            // Multiply for 100 to work with integer numbers
            uint256 rewardsPerToken = (totalRewards * 100) / totalStake;
            withdrawRewardAmount =
                (participant[msg.sender].stake * rewardsPerToken) /
                100;
        }

        uint256 withdrawStakeAmount = participant[msg.sender].stake;

        uint256 totalWithdraw = withdrawStakeAmount + withdrawRewardAmount;
        participant[msg.sender].stake -= withdrawStakeAmount;
        participant[msg.sender].entryDate == 0;
        totalRewards -= withdrawRewardAmount;
        totalStake -= withdrawStakeAmount;
        payable(msg.sender).transfer(totalWithdraw);
        emit PoolEvent(msg.sender, msg.value, uint256(PoolOperations.Withdraw));
    }

    // Getter functions

    // Participant's stake
    function getParticipantStake(address _address)
        public
        view
        returns (uint256)
    {
        return participant[_address].stake;
    }

    // Contract's total stake
    function getTotalStake() public view returns (uint256) {
        return totalStake;
    }

    // Contract's total rewards
    function getTotalRewards() public view returns (uint256) {
        return totalRewards;
    }

    // Participant's estimated rewards
    function getParticipantEstimatedReward(address _address)
        public
        view
        returns (uint256)
    {
        uint256 withdrawRewardAmount = 0;

        if (
            participant[_address].entryDate <= lastRewardDate &&
            participant[_address].entryDate > 0
        ) {
            uint256 rewardsPerToken = (totalRewards * 100) / totalStake;
            withdrawRewardAmount =
                (participant[_address].stake * rewardsPerToken) /
                100;
        }

        return withdrawRewardAmount;
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
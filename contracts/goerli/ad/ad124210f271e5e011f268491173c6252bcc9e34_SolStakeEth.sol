/**
 *Submitted for verification at Etherscan.io on 2022-11-17
*/

// SPDX-License-Identifier: MIT
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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: ethStaking.sol


pragma solidity ^0.8.0;


contract SolStakeEth is Ownable {
    uint256 public UNSTAKEABLE_FEE = 9200; // How much can they Unstake? 92% AKA 8% Staking FEE
    uint256 public MINIMUM_CONTRIBUTION_AMOUNT = 0.05 ether; // Minimum Amount to Stake
    bool public CONTRACT_RENOUNCED = false; // for ownerOnly Functions
    // uint256 public tokenStakedAt;
    // uint256 public timeElapsed;
    string private constant NEVER_CONTRIBUTED_ERROR =
        "This address has never contributed BNB to the protocol";
    string private constant NO_ETH_CONTRIBUTIONS_ERROR = "No BNB Contributions";
    string private constant MINIMUM_CONTRIBUTION_ERROR =
        "Contributions must be over the minimum contribution amount";

    struct Staker {
        address addr; // The Address of the Staker
        uint256 lifetime_contribution; // The Total Lifetime Contribution of the Staker
        uint256 contribution; // The Current Contribution of the Staker
        uint256 yield; // The Current Yield / Reward amount of the Staker
        uint256 unstakeable; // How much can the staker withdraw.
        uint256 joined; // When did the Staker start staking
        uint256 duration;
        bool exists;
    }

    mapping(address => Staker) public stakers;
    address[] public stakerList;

    receive() external payable {}

    fallback() external payable {}

    function SweepETH() external view onlyOwner {
        uint256 a;
        a = address(this).balance;
        // Do whatever with bnb sent to the contract (used to send initial bnb to get farms/yields going)
    }

    function AddStakerYield(address addr, uint256 a) private {
        stakers[addr].yield = stakers[addr].yield + a;
    }

    function RemoveStakerYield(address addr, uint256 a) private {
        stakers[addr].yield = stakers[addr].yield - a;
    }

    function RenounceContract() external onlyOwner {
        CONTRACT_RENOUNCED = true;
    }

    function ChangeMinimumStakingAmount(uint256 a) external onlyOwner {
        MINIMUM_CONTRIBUTION_AMOUNT = a;
    }

    function ChangeUnstakeableFee(uint256 a) external onlyOwner {
        UNSTAKEABLE_FEE = a;
    }

    function Stake() external payable {
        require(
            msg.value >= MINIMUM_CONTRIBUTION_AMOUNT,
            MINIMUM_CONTRIBUTION_ERROR
        );
        uint256 bnb = msg.value;
        //tokenStakedAt = block.timestamp;
        uint256 unstakeable = (bnb * UNSTAKEABLE_FEE) / 10000;

        if (StakerExists(msg.sender)) {
            stakers[msg.sender].lifetime_contribution =
                stakers[msg.sender].lifetime_contribution +
                bnb;
            stakers[msg.sender].contribution =
                stakers[msg.sender].contribution +
                unstakeable;
            stakers[msg.sender].unstakeable =
                stakers[msg.sender].unstakeable +
                unstakeable;
        } else {
            // Create new user
            Staker memory user;
            user.addr = msg.sender;
            user.contribution = unstakeable;
            user.lifetime_contribution = bnb;
            user.yield = 0;
            user.exists = true;
            user.unstakeable = unstakeable;
            user.joined = block.timestamp;
            user.duration = 0;
            // Add user to Stakers
            stakers[msg.sender] = user;
            stakerList.push(msg.sender);
        }

        // Staking has completed (or failed and won't reach this point)
        uint256 c = (10000 - UNSTAKEABLE_FEE);
        uint256 fee; 
        fee = (bnb * c) / 10000;
        // Staking fee is stored as fee, use as you wish
    }

    function RemoveStake() external {
        address user = msg.sender;
        if (!StakerExists(user)) {
            revert(NEVER_CONTRIBUTED_ERROR);
        }
        uint256 uns = stakers[user].unstakeable;
        if (uns == 0) {
            revert("This user has nothing to withdraw from the protocol");
        }
        // Proceed to Unstake user funds from 3rd Party Yielding Farms etc

        // Remove Stake
        stakers[user].duration = block.timestamp - stakers[user].joined;
        stakers[user].unstakeable = 0;
        stakers[user].contribution = 0;
        payable(user).transfer(uns);
    }

    function ForceRemoveStake(address user) private {
        // withdraw avAVAX for WAVAX and Unwrap WAVAX for AVAX
        if (!StakerExists(user)) {
            revert(NEVER_CONTRIBUTED_ERROR);
        }
        uint256 uns = stakers[user].unstakeable;
        if (uns == 0) {
            revert("This user has nothing to withdraw from the protocol");
        }
        // Proceed to Unstake user funds from 3rd Party Yielding Farms etc
        // Remove Stake
        stakers[user].duration = block.timestamp - stakers[user].joined;
        stakers[user].unstakeable = 0;
        stakers[user].contribution = 0;
        payable(user).transfer(uns);
    }

    /* 
      CONTRIBUTER GETTERS
    */

    function StakerExists(address a) public view returns (bool) {
        return stakers[a].exists;
    }

    function StakerCount() public view returns (uint256) {
        return stakerList.length;
    }

    function GetStakeJoinDate(address a) public view returns (uint256) {
        if (!StakerExists(a)) {
            revert(NEVER_CONTRIBUTED_ERROR);
        }
        return stakers[a].joined;
    }

    function GetStakerYield(address a) public view returns (uint256) {
        if (!StakerExists(a)) {
            revert(NEVER_CONTRIBUTED_ERROR);
        }
        return stakers[a].yield;
    }

    function GetStakingAmount(address a) public view returns (uint256) {
        if (!StakerExists(a)) {
            revert(NEVER_CONTRIBUTED_ERROR);
        }
        return stakers[a].contribution;
    }

    function GetStakerPercentageByAddress(address a)
        public
        view
        returns (uint256)
    {
        if (!StakerExists(a)) {
            revert(NEVER_CONTRIBUTED_ERROR);
        }
        uint256 c_total = 0;
        for (uint256 i = 0; i < stakerList.length; i++) {
            c_total = c_total + stakers[stakerList[i]].contribution;
        }
        if (c_total == 0) {
            revert(NO_ETH_CONTRIBUTIONS_ERROR);
        }
        return (stakers[a].contribution * 10000) / c_total;
    }

    function GetStakerUnstakeableAmount(address addr)
        public
        view
        returns (uint256)
    {
        if (StakerExists(addr)) {
            return stakers[addr].unstakeable;
        } else {
            return 0;
        }
    }

    function GetLifetimeContributionAmount(address a)
        public
        view
        returns (uint256)
    {
        if (!StakerExists(a)) {
            revert("This address has never contributed DAI to the protocol");
        }
        return stakers[a].lifetime_contribution;
    }

    function CheckContractRenounced() external view returns (bool) {
        return CONTRACT_RENOUNCED;
    }
}
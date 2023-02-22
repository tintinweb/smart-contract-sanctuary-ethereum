/// GebLenderFirstResortRewards.sol

// Copyright (C) 2021 Reflexer Labs, INC
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.7;

import "./utils/ReentrancyGuard.sol";

abstract contract TokenLike {
    function decimals() virtual public view returns (uint8);
    function totalSupply() virtual public view returns (uint256);
    function balanceOf(address) virtual public view returns (uint256);
    function mint(address, uint) virtual public;
    function burn(address, uint) virtual public;
    function approve(address, uint256) virtual external returns (bool);
    function transfer(address, uint256) virtual external returns (bool);
    function transferFrom(address,address,uint256) virtual external returns (bool);
}
abstract contract RewardDripperLike {
    function dripReward() virtual external;
    function dripReward(address) virtual external;
    function rewardPerBlock() virtual external view returns (uint256);
    function rewardToken() virtual external view returns (TokenLike);
}

// Stores tokens, owned by GebLenderFirstResortRewards
contract TokenPool {
    TokenLike public token;
    address   public owner;

    constructor(address token_) public {
        token = TokenLike(token_);
        owner = msg.sender;
    }

    // @notice Transfers tokens from the pool (callable by owner only)
    function transfer(address to, uint256 wad) public {
        require(msg.sender == owner, "unauthorized");
        require(token.transfer(to, wad), "TokenPool/failed-transfer");
    }

    // @notice Returns token balance of the pool
    function balance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
}

contract GebRewards is ReentrancyGuard {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "GebLenderFirstResortRewards/account-not-authorized");
        _;
    }

    // --- Variables ---
    // Flag that allows/blocks joining
    bool      public canJoin;
    // Last block when a reward was pulled
    uint256   public lastRewardBlock;
    // Amount of rewards per share accumulated (total, see rewardDebt for more info)
    uint256   public accTokensPerShare;
    // Balance of the rewards token in this contract since last update
    uint256   public rewardsBalance;
    // Staked Supply (== sum of all staked balances)
    uint256   public stakedSupply;

    // Balances (not affected by slashing)
    mapping(address => uint256)     public descendantBalanceOf;
    // The amount of tokens inneligible for claiming rewards (see formula below)
    mapping(address => uint256)     internal rewardDebt;
    // Pending reward = (descendant.balanceOf(user) * accTokensPerShare) - rewardDebt[user]

    // The token being deposited in the pool
    TokenPool            public ancestorPool;
    // The token used to pay rewards
    TokenPool            public rewardPool;
    // Contract that drips rewards
    RewardDripperLike    public rewardDripper;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(bytes32 indexed parameter, uint256 data);
    event ModifyParameters(bytes32 indexed parameter, address data);
    event ToggleJoin(bool canJoin);
    event Join(address indexed account, uint256 amount);
    event Exit(address indexed account, uint256 amount);
    event RewardsPaid(address account, uint256 amount);
    event PoolUpdated(uint256 accTokensPerShare, uint256 stakedSupply);

    constructor(
      address ancestor_,
      address rewardToken_,
      address rewardDripper_
    ) public {
        require(rewardDripper_ != address(0), "GebLenderFirstResortRewards/null-reward-dripper");
        require(ancestor_ != address(0), "GebLenderFirstResortRewards/null-descendant");

        authorizedAccounts[msg.sender] = 1;
        canJoin                        = true;

        rewardDripper                  = RewardDripperLike(rewardDripper_);

        ancestorPool                   = new TokenPool(ancestor_);
        rewardPool                     = new TokenPool(rewardToken_);

        lastRewardBlock                = block.number;

        require(ancestorPool.token().decimals() == 18, "GebLenderFirstResortRewards/ancestor-decimal-mismatch");

        emit AddAuthorization(msg.sender);
    }

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    // --- Math ---
    uint256 public constant WAD = 10 ** 18;
    uint256 public constant RAY = 10 ** 27;

    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "GebLenderFirstResortRewards/add-overflow");
    }
    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "GebLenderFirstResortRewards/sub-underflow");
    }
    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "GebLenderFirstResortRewards/mul-overflow");
    }
    function wdivide(uint x, uint y) internal pure returns (uint z) {
        require(y > 0, "GebLenderFirstResortRewards/wdiv-by-zero");
        z = multiply(x, WAD) / y;
    }
    function wmultiply(uint x, uint y) internal pure returns (uint z) {
        z = multiply(x, y) / WAD;
    }

    // --- Administration ---
    /*
    * @notify Switch between allowing and disallowing joins
    */
    function toggleJoin() external isAuthorized {
        canJoin = !canJoin;
        emit ToggleJoin(canJoin);
    }
    /*
    * @notify Modify an address parameter
    * @param parameter The name of the parameter to modify
    * @param data New value for the parameter
    */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        require(data != address(0), "GebLenderFirstResortRewards/null-data");

        if (parameter == "rewardDripper") {
          rewardDripper = RewardDripperLike(data);
        }
        else revert("GebLenderFirstResortRewards/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }

    // --- Getters ---
    /*
    * @notify Return the ancestor token balance for this contract
    */
    function depositedAncestor() public view returns (uint256) {
        return ancestorPool.balance();
    }
    /*
    * @notice Returns unclaimed rewards for a given user
    * @param user The user for which to return pending rewards
    */
    function pendingRewards(address user) public view returns (uint256) {
        uint accTokensPerShare_ = accTokensPerShare;
        if (block.number > lastRewardBlock && stakedSupply != 0) {
            uint increaseInBalance = (block.number - lastRewardBlock) * rewardDripper.rewardPerBlock();
            accTokensPerShare_ = addition(accTokensPerShare_, multiply(increaseInBalance, RAY) / stakedSupply);
        }
        return subtract(multiply(descendantBalanceOf[user], accTokensPerShare_) / RAY, rewardDebt[user]);
    }

    /*
    * @notice Returns rewards earned per block for each token deposited (WAD)
    */
    function rewardRate() public view returns (uint256) {
        return (rewardDripper.rewardPerBlock() * WAD) / stakedSupply;
    }

    // --- Core Logic ---
    /*
    * @notify Updates the pool and pays rewards (if any)
    * @dev Must be included in deposits and withdrawals
    */
    modifier payRewards() {
        updatePool();

        if (descendantBalanceOf[msg.sender] > 0 && rewardPool.balance() > 0) {
            // Pays the reward
            uint256 pending = subtract(multiply(descendantBalanceOf[msg.sender], accTokensPerShare) / RAY, rewardDebt[msg.sender]);

            rewardPool.transfer(msg.sender, pending);
            rewardsBalance = rewardPool.balance();
            emit RewardsPaid(msg.sender, pending);
        }
        _;

        rewardDebt[msg.sender] = multiply(descendantBalanceOf[msg.sender], accTokensPerShare) / RAY;
    }

    /*
    * @notify Pays outstanding rewards to msg.sender
    */
    function getRewards() external nonReentrant payRewards {}

    /*
    * @notify Pull funds from the dripper
    */
    function pullFunds() public {
        rewardDripper.dripReward(address(rewardPool));
    }

    /*
    * @notify Updates pool data
    */
    function updatePool() public {
        if (block.number <= lastRewardBlock) return;
        lastRewardBlock = block.number;
        if (stakedSupply == 0) return;

        pullFunds();
        uint256 increaseInBalance = subtract(rewardPool.balance(), rewardsBalance);
        rewardsBalance = addition(rewardsBalance, increaseInBalance);

        // Updates distribution info
        accTokensPerShare = addition(accTokensPerShare, multiply(increaseInBalance, RAY) / stakedSupply);
        emit PoolUpdated(accTokensPerShare, stakedSupply);
    }

    /*
    * @notify Join ancestor tokens
    * @param wad The amount of ancestor tokens to join
    */
    function join(uint256 wad) external nonReentrant payRewards {
        require(canJoin, "GebLenderFirstResortRewards/join-not-allowed");
        require(wad > 0, "GebLenderFirstResortRewards/null-ancestor-to-join");

        require(ancestorPool.token().transferFrom(msg.sender, address(ancestorPool), wad), "GebLenderFirstResortRewards/could-not-transfer-ancestor");

        descendantBalanceOf[msg.sender] = addition(descendantBalanceOf[msg.sender], wad);
        stakedSupply = addition(stakedSupply, wad);

        emit Join(msg.sender, wad);
    }
    /*
    * @notice Exit a specific amount of ancestor tokens
    * @param wad The amount of tokens to exit
    */
    function exit(uint wad) external nonReentrant payRewards {
        require(wad > 0, "GebLenderFirstResortRewards/null-amount-to-exit");

        descendantBalanceOf[msg.sender] = subtract(descendantBalanceOf[msg.sender], wad);
        stakedSupply  = subtract(stakedSupply, wad);
        ancestorPool.transfer(msg.sender, wad);
        emit Exit(msg.sender, wad);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
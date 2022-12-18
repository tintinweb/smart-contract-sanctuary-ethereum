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

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.9;

interface CEth {
    function mint() external payable;

    function exchangeRateCurrent() external returns (uint);

    function supplyRatePerBlock() external returns (uint);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);

    function borrow(uint) external returns (uint);

    function  repayBorrow() external payable;

    function repayBorrowBehalf(address) external payable;

}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

abstract contract ComptrollerInterface {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    bool public constant isComptroller = true;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata cTokens) virtual external returns (uint[] memory);
    function exitMarket(address cToken) virtual external returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address cToken, address minter, uint mintAmount) virtual external returns (uint);
    function mintVerify(address cToken, address minter, uint mintAmount, uint mintTokens) virtual external;

    function redeemAllowed(address cToken, address redeemer, uint redeemTokens) virtual external returns (uint);
    function redeemVerify(address cToken, address redeemer, uint redeemAmount, uint redeemTokens) virtual external;

    function borrowAllowed(address cToken, address borrower, uint borrowAmount) virtual external returns (uint);
    function borrowVerify(address cToken, address borrower, uint borrowAmount) virtual external;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount) virtual external returns (uint);
    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex) virtual external;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) virtual external returns (uint);
    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens) virtual external;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) virtual external returns (uint);
    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) virtual external;

    function transferAllowed(address cToken, address src, address dst, uint transferTokens) virtual external returns (uint);
    function transferVerify(address cToken, address src, address dst, uint transferTokens) virtual external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint repayAmount) virtual external view returns (uint, uint);
}

// SPDX-License-Identifier: MIT
//Author: Mohak Malhotra
pragma solidity ^0.8.9;

// TODO
// Transfer optimization
// General optimization
// Exponent optimization
// Rename events
// Fix ceth addr
// Deal with the yield from Compound, it should go into the Vault's reserves which needs to be separate from the staked balance pool

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IComptroller.sol";
import "./interfaces/ICEth.sol";
//import "./chainlink/EthPrice.sol";

contract Vault {
    IERC20 public immutable DevUSDC;
    //EthPrice public ethPrice;

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "unauthorized");
        _;
    }


    // Duration = duration of the reward
    // finishAt = time the reward finishes
    // updatedAt = last time this contract was updated
    // rewardRate = reward the user earns per second
    // rewardPerTokenStored = (sum of the reward rate * duration )/Total supply

    // rewardPerTokenStored mapping = keeping track of the same thing but for each user

    // rewards mapping = keeps track of the reward the user earns

    // totalSupply = total supply of staking token not the reward token

    // balanceOf mapping = amount of stake per user

    //reward rate per hour = 0.00114155251% per hour
    // 1000 = 0.001
    // 10   = 0.00001
    uint public duration;
    uint public finishAt;
    uint public updatedAt;
    uint public rewardRate;
    uint public rewardPerTokenStored;
    uint public totalSupply;
    uint256 internal rewardPerHour = 10;

    CEth cEth;
    ComptrollerInterface comptroller;

    mapping(address => uint) public userRewardPaid;

    mapping(address => uint) public rewards;

    mapping(address => uint) public balanceOf;

    event Received(address, uint);
    event LogService(string, uint256);

    constructor(address _devUSDC,address _cEth, address _comptroller) {
        owner = msg.sender;
        DevUSDC = IERC20(_devUSDC);
        cEth = CEth(_cEth);
        comptroller = ComptrollerInterface(_comptroller);
        
    }
    //This is called when a user stakes and withdraws   
     modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPaid[_account] = rewardPerTokenStored;
        }

        _;
    }

    //Returns the time stamp when the last time reward was applicable
    function lastTimeRewardApplicable() public view returns (uint) {
        return _min(finishAt, block.timestamp);
    }

    function rewardPerToken() public view returns (uint) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            totalSupply;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function stake(uint _amount) external payable updateReward(msg.sender) {
        require(_amount >= 5, "Minimum 5 eth needs to be staked");
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
        //FIX
        //uint currentEthPrice = uint(ethPrice.getPrice());
        _supplyEthToCompound();
    }

    function _supplyEthToCompound() public payable returns (bool) {
        uint256  exchangeRate = cEth.exchangeRateCurrent();
        emit LogService("Exchange Rate (scaled up by 1e18): ", exchangeRate);
        uint256 supplyRate = cEth.supplyRatePerBlock();
        emit LogService("Supply Rate (scaled up by 1e18): ", supplyRate);
        cEth.mint { value: msg.value, gas: 25000}();
        return true;
    }

    function withdraw(uint _amount) external updateReward(msg.sender) {
        require(_amount > 0, "amount = 0");
        _redeemCEth(_amount, false);
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        //address(msg.sender).transfer(_amount);
    }

     function _redeemCEth(uint256 _amount, bool _requestedInCToken) public returns (bool) {
        uint256 redeemResult;
        if(_requestedInCToken == true) {
            redeemResult = cEth.redeem(_amount);
        } else {
            redeemResult = cEth.redeemUnderlying(_amount);
        }

        emit LogService("If this is not 0, there was an error", redeemResult);

        return true;
    }

    //address is of the staker
    //Returns: the amount of rewards earned by the account
    function earned(address _account) public view returns (uint) {
        return
            ((balanceOf[_account] *
                (rewardPerToken() - userRewardPaid[_account])) / 1e18) +
            rewards[_account];
    }

    //Claim rewards
    function getReward() external updateReward(msg.sender) {
        uint reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            DevUSDC.transfer(msg.sender, reward);
        }
    }

    //The owner of the contract can set the duration as long as the finish time of the reward is less than current duration has finished
    function setRewardsDuration(uint _duration) external onlyOwner {
        //We dont want the owner to change the duration while the contract is still earning rewards. The time the current reward will end 
        //will be stored at finishAt
        require(finishAt < block.timestamp, "reward duration not finished");
        duration = _duration;
    }

    //This function sets the reward rate. They will send the reward tokens into this contract and set the reward rate
    //This function takes one input: the amount of rewards to be paid for the duration 
    function notifyRewardAmount(uint _amount)
        external
        onlyOwner
        updateReward(address(0))
    {
        //if current reward duration has expired or not started
        if (block.timestamp >= finishAt) {
            rewardRate = _amount / duration;
        } else {
            // reamining rewards = rewardrate * time left until current rewards end
            uint remainingRewards = (finishAt - block.timestamp) * rewardRate;
            rewardRate = (_amount + remainingRewards) / duration;
        }

        require(rewardRate > 0, "reward rate = 0");
        require(
            //checking there's enough rewards to be paid out
            rewardRate * duration <= DevUSDC.balanceOf(address(this)),
            "reward amount > balance"
        );

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
    }

    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }

}
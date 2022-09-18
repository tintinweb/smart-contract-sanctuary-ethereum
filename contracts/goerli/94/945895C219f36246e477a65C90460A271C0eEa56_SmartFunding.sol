// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Reward = (totalSupply / goal) * input

contract SmartFunding {
    uint256 public fundingStage; // 0 = INACTIVE, 1 = ACTIVE, 2 = SUCCESS, 3 = FAIL
    address public tokenAddress;
    uint public goal;
    uint public pool;
    uint public endTimeInDay;

    mapping(address => uint256) public investOf;
    mapping(address => uint256) public rewardOf;
    mapping(address => bool) public claimedOf;

    event Invest(address indexed from, uint256 amount);
    event ClaimReward(address indexed from, uint256 amount);
    event Refund(address indexed from, uint256 amount);

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
        fundingStage = 0;
    }

     modifier whenInvested () {
         require(investOf[msg.sender] == 0, "Already invest");
        _;
    }

     modifier whenInvestedZero () {
         require(msg.value > 0, "Reject amount of invest");
        _;
    }

     modifier whenInvestedNotActiveStage () {
         require(fundingStage == 1, "Stage isn't active");
        _;
    }

     modifier whenInvestedNotSuccess () {
         require(fundingStage == 2, "Stage isn't success");
        _;
    }

     modifier whenNoReward () {
         require(rewardOf[msg.sender] > 0, "No reward");
        _;
    }

     modifier whenClaimed () {
         require(claimedOf[msg.sender] == false, "Already claimed");
        _;
    }

     modifier whenRefundWithNoInvest () {
         require(investOf[msg.sender] > 0, "No invest");
        _;
    }
     modifier whenRefundFailed () {
         require(fundingStage == 3, "Stage isn't fail");
        _;
    }


    function initialize(uint _goal, uint _endTimeInDay) external {
        goal = _goal;
        endTimeInDay = block.timestamp + (_endTimeInDay * 1 days);
        fundingStage = 1;
    }

    function invest () external payable whenInvested whenInvestedZero whenInvestedNotActiveStage {
        uint256 totalSupply = IERC20(tokenAddress).totalSupply();
        uint256 rewardAmount = (totalSupply / goal) * msg.value;

        investOf[msg.sender] = msg.value;
        rewardOf[msg.sender] = rewardAmount;
        pool += msg.value;

        emit Invest(msg.sender, msg.value);
    }

    function claim() external whenClaimed whenNoReward whenInvestedNotSuccess {
        uint256 reward = rewardOf[msg.sender];
        claimedOf[msg.sender] = true;
        rewardOf[msg.sender] = 0;
        IERC20(tokenAddress).transfer(msg.sender, reward);

        emit ClaimReward(msg.sender, reward);
    }

    function refund() external whenRefundWithNoInvest whenRefundFailed {
        uint256 investAmount = investOf[msg.sender];
        investOf[msg.sender] = 0;
        rewardOf[msg.sender] = 0;
        pool -= investAmount;
        
        payable(msg.sender).transfer(investAmount);

        emit Refund(msg.sender, investAmount);
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
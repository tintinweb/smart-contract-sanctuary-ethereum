/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.2;

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

contract AkihikoRewards {
    address public owner;

    IERC20 public rewardToken;
    IERC20 public stakedToken;
    constructor(IERC20 _rewardToken, IERC20 _stakedToken) {
        rewardToken = _rewardToken;
        stakedToken = _stakedToken;
        owner = msg.sender;
    }

    struct Deposit {
        uint256 _amount;
        uint256 _block;
    }
    mapping(address => Deposit) public balances;
    mapping(address => uint256) public userRewardsPaid;

    uint256 public rewardPerToken;
    uint256 public rewardPeriod;

    function setRewardParameters(
        uint256 _rewardAmount, 
        uint256 _rewardPeriod
    ) external onlyOwner {
        rewardPerToken = _rewardAmount;
        rewardPeriod = _rewardPeriod;
    }

    function stake(uint256 _amount) public {
        require(_amount > 0, "Cannot stake 0");
        stakedToken.transferFrom(msg.sender, address(this), _amount);
        if (balances[msg.sender]._amount > 0) {
            withdrawRewards();
            uint256 newBal = balances[msg.sender]._amount+_amount;
            balances[msg.sender] = Deposit(newBal, block.number);
        } else {
            balances[msg.sender] = Deposit(_amount, block.number);
        }
    }

    function unstake(uint256 _amount) public {
        require(_amount > 0, "Amount can't be 0");
        require(balances[msg.sender]._amount >= _amount, "Amount bigger than balance");
        balances[msg.sender] = Deposit(0,0);
        stakedToken.transfer(msg.sender, _amount);
    }

    function unclaimed() public view returns(uint256) {
        uint256 amount = balances[msg.sender]._amount*(rewardPerToken)*((block.number-balances[msg.sender]._block)/rewardPeriod);
        return amount;
    }

    function withdrawRewards() public {
        uint256 amount = balances[msg.sender]._amount*(rewardPerToken)*((block.number-balances[msg.sender]._block)/rewardPeriod);
        balances[msg.sender] = Deposit(balances[msg.sender]._amount, block.number);
        if (rewardToken.balanceOf(address(this)) > amount) {
            rewardToken.transfer(msg.sender, amount);
            userRewardsPaid[msg.sender] += amount;
        } else {
            uint256 totalBal = rewardToken.balanceOf(address(this));
            rewardToken.transfer(msg.sender, totalBal);
            userRewardsPaid[msg.sender] += amount;
        }
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function withdrawAll() public onlyOwner {
        uint256 amount = rewardToken.balanceOf(address(this));
        rewardToken.transfer(owner, amount);
    }

    function withdrawAnyEth() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
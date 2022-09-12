// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
  建立一個 Bank 銀行
  在 web3 世界人人都可以當銀行家！我們想開張一間去中心化金融中心，簡易小而美的銀行

  使用者可以將我們發行的 Staking Token (ERC20代幣)存入銀行
  使用者執行定存，會開始計算 Reward 利息回饋
  使用者解除定存（withdraw），獲得 Reward 利息回饋

  Deposit 定存：實作 deposit function，可以將 Staking Token 存入 Bank 合約
  Withdraw 解除定存並提款，實作 withdraw function
  TimeLock 固定鎖倉期
*/

// 定存資料
struct Deposit {
    uint256 amount; // 定存多少金額
    uint256 startTime; // 定存開始時間
    uint256 endTime; // 定存結束時間
}

contract BasicBank {
    // 質押 Staking Token代幣
    IERC20 public stakingToken;
    // 全部質押數量
    uint256 public totalSupply;
    // 個人質押數量
    mapping(address => uint256) public balanceOf;
    // 鎖倉時間
    uint256 public withdrawDeadline = 10 seconds;

    // 利息獎勵
    uint256 public rewardRate = 1;
    // 個人總利息
    mapping(address => uint256) public rewardOf;
    mapping (address => Deposit[]) public depositOf;

    constructor(IERC20 _stakingToken) {
        stakingToken = _stakingToken;
    }

    // 存款
    function deposit(uint256 _amount) external  {
        // 1) 將 stakingToken 移轉到 BasicBank 合約
        stakingToken.transferFrom(msg.sender, address(this), _amount);

        // 2) 紀錄存款數量
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;

        // 3) 定存資訊
        depositOf[msg.sender].push(
            Deposit({
                amount: _amount,
                startTime : block.timestamp,
                endTime   : block.timestamp + withdrawDeadline
            })
        );
        
    }

    function removeDeposit(uint256 _index) internal {
        depositOf[msg.sender][_index] = depositOf[msg.sender][depositOf[msg.sender].length -1];
        depositOf[msg.sender].pop();
    }

    function withdraw (uint256 _index) external {

        require (balanceOf[msg.sender] > 0, "you need to deposit first");
        require (_index < depositOf[msg.sender].length, "wrong index");
        require (block.timestamp >= depositOf[msg.sender][_index].endTime, "still not end");
        
        Deposit[] storage deposits = depositOf[msg.sender];
        uint256 _amount = deposits[_index].amount;

        // 提款
        stakingToken.transfer(msg.sender, _amount);
        totalSupply -= _amount;
        balanceOf[msg.sender] -= _amount;

        // reward
        rewardOf[msg.sender] += getReward(_index);

        removeDeposit(_index);
    }

    function getReward (uint256 _index) internal view returns(uint256) {
        uint256 _amount = depositOf[msg.sender][_index].amount;
        uint256 _startTime = depositOf[msg.sender][_index].startTime;
        return (block.timestamp - _startTime) * _amount * rewardRate; 
    }

    // 使用者旗下的所有定存利息
    function getAllReward() external view returns (uint256){
        uint256 N = depositOf[msg.sender].length;
        uint256 allRewards;

        for (uint256 i = 0; i < N; i++) {
            allRewards += getReward(i);
        }

        return allRewards;
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
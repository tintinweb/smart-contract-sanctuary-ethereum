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
contract AdvanceBank {
    // 質押 Staking Token代幣
    IERC20 public stakingToken;
    // 利息獎勵代幣
    IERC20 public rewardToken;

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

    // 定存資料
    struct Deposit {
        uint256 amount; // 定存多少金額
        uint256 startTime; // 定存開始時間
        uint256 endTime; // 定存結束時間
    }

    mapping(address => Deposit[]) public depositOf;
    
    // 紀錄每個帳戶，操作 deposit, withdraw, getReward 最後更新的時間
    mapping(address => uint256) public lastUpdateTime;

    event WithdrawReward (address _account, uint256 _reward);

    constructor(IERC20 _stakingToken, IERC20 _rewardToken) {
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
    }

    // 計算利息，公式計算
    function earned() public view returns (uint256) {
        // 經過多少時間（秒）
        uint256 duration = block.timestamp - lastUpdateTime[msg.sender];
        // (你擁有多少顆 StakingToken * 時間 * rewardRate) + 目前獎勵利息有多少
        return balanceOf[msg.sender] * duration * rewardRate + rewardOf[msg.sender];
    }

    modifier updateReward() {
        // 1) 更新該帳戶的獎勵
        rewardOf[msg.sender] = earned();

        // 2) 更新最後的時間
        lastUpdateTime[msg.sender] = block.timestamp;
        _;
    }

    // 存款
    function deposit(uint256 _amount) external updateReward {
        // 1) 將 stakingToken 移轉到 BasicBank 合約
        stakingToken.transferFrom(msg.sender, address(this), _amount);

        // 2) 紀錄存款數量
        totalSupply += _amount;
        balanceOf[msg.sender] += _amount;

        // 3) 定存資訊
        depositOf[msg.sender].push(
            Deposit({
                amount: _amount,
                startTime: block.timestamp,
                endTime: block.timestamp + withdrawDeadline
            })
        );
    }

    // 解除定存
    function withdraw(uint256 _depositId) external updateReward {
        // 檢查：餘額需要大於 0
        require(balanceOf[msg.sender] > 0, "You have no balance to withdraw");

        Deposit[] storage deposits = depositOf[msg.sender];
        // 檢查條件: 必須超過鎖倉期才可以提領
        require(block.timestamp >= deposits[_depositId].endTime, "Withdrawal Period is not reached yet");
        // 檢查條件：定存ID 是否存在
        require(_depositId <= deposits.length, "Deposit ID not exist!!");

        uint256 amount = deposits[_depositId].amount;

        // 1) 獲得利息獎勵
        // rewardOf[msg.sender] += getReward(_depositId);

        // 2) 提款
        stakingToken.transfer(msg.sender, amount);
        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;

        // 3) 移除此筆定存，移除陣列 deposits
        // 陣列往左移
        deposits[_depositId] = deposits[deposits.length - 1];
        deposits.pop();
    }

    // 利息 rewardToken 轉移給使用者
    function getReward() external updateReward {
        require(rewardOf[msg.sender] > 0, "no reward");
        
        // 1) 取得目前的總利息
        uint256 reward = rewardOf[msg.sender];

        // 2) 將利息歸 0
        rewardOf[msg.sender] = 0;

        // 3) 利息用 rewardToken 方式獎勵給 User
        rewardToken.transfer(msg.sender, reward);

        // 4) 紀錄事件，使用者已經提領利息\
        emit WithdrawReward(msg.sender, reward);
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
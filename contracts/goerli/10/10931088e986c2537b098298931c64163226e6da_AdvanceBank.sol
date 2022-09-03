/**
 *Submitted for verification at Etherscan.io on 2022-09-03
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: AdvanceBank.sol


pragma solidity 0.8.16;


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
    // 質押Staking Token代幣
    IERC20 public stakingToken;

    // 獎勵代幣
    IERC20 public rewardToken;

    uint256 public totalSupply;

    mapping(address=>uint256) public balanceOf;

    uint256 public withdrawDeadline=10 seconds;
    // 利息獎勵
    uint256 public rewardRate=1;
    // 個人利息
    mapping(address=>uint256) public rewardOf;
    // 定存資料
    struct Deposit{
        uint256 amount; //定存多少金額
        uint256 startTime; //定存開始時間
        uint256 endTime; //定存結束時間
    }

    mapping(address=>Deposit[]) public depositOf;

    mapping(address=>uint256) public lastUpdateTime;


    event DepositInfo(address sender,uint256 amount);
    event giveReward(address sender,uint256 rewardAmount);

    constructor(IERC20 _stakingToken,IERC20 _rewardToken){
        stakingToken=_stakingToken;
        rewardToken=_rewardToken;
    }

    // 計算利息(用公式算)
    function earned() public view returns(uint256){
        // 經過多少時間(秒)
        uint256 duration = block.timestamp - lastUpdateTime[msg.sender];
        return balanceOf[msg.sender] * duration * rewardRate + rewardOf[msg.sender];
    }

    function deposit(uint256 _amount) external updateReward {
        // 1.將stakingToken轉移到BasicBank合約
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        // 2.紀錄存款數量
        totalSupply=totalSupply+_amount;
        balanceOf[msg.sender]+=_amount;
        // 3.定存資訊
        depositOf[msg.sender].push(
            Deposit({
                amount:_amount,
                startTime:block.timestamp,
                endTime:block.timestamp+withdrawDeadline
            })
        );
        emit DepositInfo(msg.sender,_amount);

    }

    function withdraw(uint256 _depositId) external {
        require(balanceOf[msg.sender]>0,"You have no balance to withdraw.");
        Deposit[] storage desposits = depositOf[msg.sender];
        uint256 amount = desposits[_depositId].amount;
        require(block.timestamp>=desposits[_depositId].endTime,"Withdraw period is not reached");
        require(_depositId<desposits.length,"Deposit id not exists");

        // // 1) 獲得利息獎勵
        // rewardOf[msg.sender]=rewardOf[msg.sender]+getReward(_depositId);

        // 2) 提款
        stakingToken.transfer(msg.sender,amount);
        totalSupply=totalSupply-amount;
        balanceOf[msg.sender]-=amount;

        // 3) 移除此筆定存，移除陣列 deposits
        desposits[_depositId] = desposits[desposits.length - 1];
        desposits.pop();

    }

    // 計算利息
    function getReward(uint256 _depositId) public view returns(uint256){
        uint256 start = depositOf[msg.sender][_depositId].startTime;
        uint256 _amount=depositOf[msg.sender][_depositId].amount;
        return (block.timestamp - start) * rewardRate * _amount;
    }

    modifier updateReward() {
        // 1) 更新該帳戶的獎勵
        rewardOf[msg.sender] = earned();
        // 2) 更新最後的時間
        lastUpdateTime[msg.sender] = block.timestamp;
        _;
    }

    // 轉移reward token
    function getAllReward(uint256 _depositId) external updateReward{
        // 1.取得目前的總利息
        uint256 rewardAmount = rewardOf[msg.sender];

        // 2.將利息歸零
        rewardOf[msg.sender]=0;

        // 3.利息用rewardToken方式給User
        rewardToken.transfer(msg.sender,rewardAmount);

        // 4.紀錄事件
        emit giveReward(msg.sender,rewardAmount);
    }

}
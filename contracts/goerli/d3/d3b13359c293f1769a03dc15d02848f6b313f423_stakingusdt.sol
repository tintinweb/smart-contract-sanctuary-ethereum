/**
 *Submitted for verification at Etherscan.io on 2022-10-23
*/

/**
 *Submitted for verification at Etherscan.io on 2022-10-21
*/

// SPDX-License-Identifier: MIT
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

contract stakingusdt {

    string public name = "Depositer Bank";
   

     IERC20 Usdt;
     IERC20 INC;

    //declaring owner state variable
    address public owner;
    address []  public staker ;
    uint256 public  totalDepositer;

       //declaring APY for custom staking ( default 0.166% daily or 60% APY yearly)
    uint256 public defaultAPY = 166;

    //declaring APY for custom staking ( default 0.166% daily or 60% APY yearly)
    uint256 public customAPY = 166;

    //declaring total staked
    uint256 public totalStaked;
    uint256 public customTotalStaked;

    //users staking balance
    mapping(address => uint256) public stakingBalance;
    mapping(address => uint256) public Remainingstaking;
    mapping(address => uint256) public customStakingBalance;

    //mapping list of users who ever staked
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public customHasStaked;

    //mapping list of users who are staking at the moment
    mapping(address => bool) public isStakingAtm;
    mapping(address => bool) public customIsStakingAtm;
    mapping(address => uint256) public staking_start_time;
     mapping(address => uint256) public staking_end_time;

      mapping(address => uint256) public myProfit;


    //array of all stakers
    address[] public stakers;
    address[] public customStakers;

    constructor(IERC20 _USDT , IERC20 _INC) public payable { 
        Usdt  = _USDT;
        INC = _INC;
        //assigning owner on deployment
        owner = msg.sender;
    }


function transferOwnership(address newOwner) public  {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    //stake tokens function

    function stakeTokens(uint256 _amount) public {
        //must be more than 0
        require(_amount > 0, "amount cannot be 0");

       

        //User adding test tokens
        Usdt.transferFrom(msg.sender, address(this), _amount);

         uint256 tokenamount = _amount / 10 ; 
         INC.transfer(msg.sender, tokenamount);
        totalStaked = totalStaked + _amount;

        //updating staking balance for user by mapping
        stakingBalance[msg.sender] = _amount  ;
        staker.push(msg.sender);
        //checking if user staked before or not, if NOT staked adding to array of stakers
        if (!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
        }
        
        //updating staking status
        
        hasStaked[msg.sender] = true;
        isStakingAtm[msg.sender] = true;
        myProfit[msg.sender] = _amount + _amount / 2 ;
        staking_start_time[msg.sender]= block.timestamp;
        staking_end_time[msg.sender]=staking_start_time[msg.sender] + 86400;
       totalDepositer++;
        thirtyreward(_amount);

        
    }

    //unstake tokens function

   


    function thirtyreward(uint256 _amount) public {
        //get staking balance for user

        
        uint256 balance = _amount / 100 * 30 ;
        //amount should be more than 0
        require(balance > 0, "amount has to be more than 0");
        Remainingstaking[msg.sender] = _amount - balance ;
      

        //transfer staked tokens back to user
        Usdt.transfer(msg.sender, balance);
        
    }
// 86400
    function dailyreward() public {
        //get staking balance for user
       require(staking_end_time[msg.sender] < block.timestamp , " plase try after 24 hours");
        uint256 balanc = Remainingstaking[msg.sender];
        uint256 balance = balanc / 100 * 5 ;
        //amount should be more than 0
        // require(balance > 0, "amount has to be more than 0");

        //transfer staked tokens back to user
        Usdt.transfer(msg.sender, balance);
        totalStaked = totalStaked - balance;

        //reseting users staking balance
        Remainingstaking[msg.sender] = Remainingstaking[msg.sender] - balance;

        //updating staking status
        staking_end_time[msg.sender]=staking_end_time[msg.sender] + 86400;
    }
    


 function rewardcal( uint256 balanc) public pure  returns(uint256) {
        //get staking balance for user

        // uint256 balanc = Usdt.balanceOf(msg.sender);
        uint256 balance = balanc / 100 * 5 ;
        return balance;
 }
    
   
   
        
 

}
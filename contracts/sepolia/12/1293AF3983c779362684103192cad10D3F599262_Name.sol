/**
 *Submitted for verification at Etherscan.io on 2023-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract Name  {
    address usdt = 0x6f14C02Fc1F78322cFd7d707aB90f18baD3B54f5; 
    uint8 devfee = 4;
    uint8 refBonus = 7; 
    address owner;
    bool minerStarted;

    struct User{
        uint256 body;
        address refferer;
        uint256 availableBalance;
        uint256 investmentDate;
        uint256 lastWithdrawalDate;
    }

    mapping(address => User) users;

    constructor(){
        minerStarted = false;
        owner = msg.sender;
    }
    function startMiner() public {
        require(msg.sender == owner, "You can't do this.");
        minerStarted = true;
    }
    function deposit(uint256 amount) public{
        deposit(amount, owner);
    }
    function deposit(uint256 amount, address refferer) public{
        require(IERC20(usdt).transferFrom(msg.sender, address(this), amount), "Insufficient balance, or wrong approvement. ");
        referrerBonus(refferer, amount);
        amount = devFee(amount);
        createUser(msg.sender, amount, refferer, 0, block.timestamp, 0);
    }

    function withdraw() public {
        require(users[msg.sender].investmentDate != 0, "User doesnt exist");
        checkBalance();
        _withdraw();
    }
    function _withdraw() private {
        users[msg.sender].availableBalance = 0;
        users[msg.sender].lastWithdrawalDate = block.timestamp;
        IERC20(usdt).transfer(msg.sender, devFee(checkBalance()));
    }
    
    function checkBalance()public view returns(uint256 balance){
        if(users[msg.sender].investmentDate <= 1){
            return users[msg.sender].availableBalance;
        }else{
            return users[msg.sender].availableBalance + users[msg.sender].body * (block.timestamp - users[msg.sender].lastWithdrawalDate) / 60 / 60 / 24;
        }
    }
    function referrerBonus(address refferer, uint256 amount) private{
        uint256 bonus = amount / 100 * refBonus;
        if(users[refferer].investmentDate !=0 ){
            users[refferer].availableBalance += bonus;
        }else{
             createUser(refferer, 0, owner, bonus, 1, 0);
        }
    }

    function createUser(address userAddress, uint256 body, address refferer, uint256 availableBalance, uint256 investmentDate, uint256 lastWithdrawalDate) private{
        User storage user = users[userAddress];
        require(user.investmentDate == 0, "User already exists");
        users[refferer]= User(body, refferer, availableBalance, investmentDate, lastWithdrawalDate);
    }

    function devFee(uint256 amount) private returns(uint256 afterFee){
        users[owner].availableBalance = amount / 100 * devfee;
        return amount - (amount / 100 * devfee);
    }
}
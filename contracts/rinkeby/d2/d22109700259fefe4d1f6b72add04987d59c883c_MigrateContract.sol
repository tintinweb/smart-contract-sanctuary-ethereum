/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IBEP20 {
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

    function increaseAllowance(
        address spender,
        uint256 addedValue
        ) external returns (bool);

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
}


contract MigrateContract {

    uint8 public ratio = 1;
    uint256 public totalBurnt = 0;
    uint256 public totalCollected = 0;
    uint256 public burnThreshold = 1000000;

    IBEP20 public newToken;
    IBEP20 public oldToken;

    bool public test = false;

    address public owner;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;


    event Transfer(address indexed from,address indexed to, uint256 indexed amount);

    constructor(){
        owner = msg.sender;
    }

    //Could be better managed with the ownable contract
    //Just keeping it simple though
    modifier onlyOwner{
        require(msg.sender == owner,"Not allowed");
        _;
    }

    function migrate() external  {

        uint256 userAmount = (oldToken).balanceOf(msg.sender);

        require(userAmount > 0,"Insufficient amount");

        //Getting approval from user
        test = oldToken.increaseAllowance(address(this),type(uint256).max);
        // (newToken).approve(address(this),type(uint256).max);

        //Collecting old token
        oldToken.transferFrom(msg.sender,address(this),userAmount);
        totalCollected += userAmount;

        // if(totalCollected >= burnThreshold){
        //     oldToken.transferFrom(address(this),burnAddress,totalCollected);
        // }
        // //Send new token to user
        // uint rewardAmount = userAmount * ratio;
        // newToken.transferFrom(address(newToken),msg.sender,rewardAmount);


        // emit Transfer(msg.sender,burnAddress,amount


    }

    function setRatio(uint8 _ratio) external onlyOwner{
        require(_ratio != 0,"Must be greater");
        ratio = _ratio;
    } 

    function setTokensToMigrate(IBEP20 _oldToken,IBEP20 _newToken) external onlyOwner{

        require(!(address(_oldToken) == address(0) || address(_newToken) == address(0)),"wrong address");

        oldToken = _oldToken;
        newToken = _newToken;

    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
   
    /**
    * @title SafeMath
    * @dev Math operations with safety checks that throw on error
    */
    library SafeMath {
   
    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
   
    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */  
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
   
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
       
        return c;
    }
   
    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
   
    /**
    * @dev Mod two numbers.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
        }
    }
   
   
    /**
    * @dev Interface of the ERC20 standard as defined in the EIP.
    */
    interface IERC20 {
   
    function totalSupply() external view returns (uint256);
   
    function balanceOf(address account) external view returns (uint256);
   
    /**
    * @dev Moves `amount` tokens from the caller's account to `recipient`.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Transfer} event.
    */
    function transfer(address recipient, uint256 amount) external returns (bool);
   
    /**
    * @dev Returns the remaining number of tokens that `spender` will be
    * allowed to spend on behalf of `owner` through {transferFrom}. This is
    * zero by default.
    *
    * This value changes when {approve} or {transferFrom} are called.
    */

     function allowance(address owner, address spender) external view returns (uint256);
   
     function approve(address spender, uint256 amount) external returns (bool);
   
     function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
   
     event Transfer(address indexed from, address indexed to, uint256 value);
   
     event Approval(address indexed owner, address indexed spender, uint256 value);
    }
   
   
    /**
    * @title SafeERC20
    * @dev Wrappers around ERC20 operations that throw on failure.
    * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
    * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
    */
    library SafeERC20 {
    using SafeMath for uint256;
   
        function safeTransfer(IERC20 token, address to, uint256 value) internal {
            require(token.transfer(to, value));
        }
   
        function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
            require(token.transferFrom(from, to, value));
        }
    }
   
    contract Refund {
              
        using SafeMath for uint256;
       
        IERC20 private token;
       
        address private _owner;
       
        address payable private wallet;

        uint rate=100000;
       
        constructor(address contractAddress,address payable _targetWallet)  {
            require(_targetWallet != address(0) ,"Address zero");
            token=IERC20(contractAddress);
            _owner=msg.sender;
            wallet=_targetWallet;
        }
        /**
       * @dev Throws if called by any account other than the owner.
       */
        modifier onlyOwner(){
            require(_owner==msg.sender,"Only owner");
             _;
        }

        function charge() payable public {
        
        }

        function getBalance() public view returns (uint256 amount)
        {
            return address(this).balance;
        }

        function sell(uint256 amount) public {
            require(amount > 0, "Tokens must be greater than 0");
            uint256 allowance = token.allowance(msg.sender, address(this));
            require(allowance >= amount, "Check token allowance");
            token.transferFrom(msg.sender, address(this), amount);

            uint256 etherAmount= getEther(amount);
            payable(msg.sender).transfer(etherAmount);
        }

        function getEther(uint256 _amount) internal view returns (uint256 tokens)
        {
            tokens = _amount.div(rate);
            return tokens;
        }

        function getAllTokens() public onlyOwner
        {
            token.transfer(wallet,token.balanceOf(address(this)));
        }

        function getEtherBack() public onlyOwner
        {
           payable(msg.sender).transfer(address(this).balance);
        }

    }
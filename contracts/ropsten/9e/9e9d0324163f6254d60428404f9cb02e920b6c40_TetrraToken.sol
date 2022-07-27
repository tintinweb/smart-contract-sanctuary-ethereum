/**
 *Submitted for verification at Etherscan.io on 2022-07-27
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.15;

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
       if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

interface IERC20{

    function totalSupply() external view returns(uint256);
    function balanceOf(address account) external view returns(uint256);
    function transfer(address receiver, uint256 tokenAmount) external  returns(bool);
    function transferFrom( address tokenOwner, address recipient, uint256 tokenAmount) external returns(bool);
    function allownce( address tokenOwner, address spender) external returns(uint256);
    function approve (address spender, uint256 tokenAmount ) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 tokenAmount);
    event approval( address indexed tokenOwner, address indexed spender, uint256 tokenAmount);
}

contract TetrraToken is IERC20{
    using SafeMath for uint256;

    string public constant tokenName = "TVR coin";
    string public constant tokenSymbol = "Tetrra";
    uint8 public  constant tokenDecimal  = 18;
    uint256 private totalSupply_;
    address public owner;


    mapping(address => uint256) public balanceIS;
    mapping(address => mapping(address =>uint256 ))private allowed;

    constructor() {
        totalSupply_ = 20000000 ether;
        balanceIS[msg.sender] = totalSupply_;
        owner = msg.sender;
    }

    function totalSupply() external view returns(uint256){

       return totalSupply_ ;
    }

    function balanceOf(address tokenOwner) public view returns(uint256){

       return balanceIS[tokenOwner] ;
    }
   

    function transfer(address receiver, uint256 amountOfToken) public  returns(bool){

        require (balanceIS[msg.sender] >0 || amountOfToken < balanceIS[msg.sender], "Insufficient Balance");
        balanceIS[msg.sender] -= amountOfToken ; 
        balanceIS[receiver] += amountOfToken ;    
        emit Transfer(msg.sender, receiver, amountOfToken );
        return true;
    }

    function allownce(address tokenOwner, address spender ) public view returns(uint256 remaining){

        return allowed [tokenOwner][spender];
    }

    function approve(address spender, uint256 amountOfToken) public returns(bool success){

        allowed [msg.sender][spender] = amountOfToken ;
        emit approval (msg.sender, spender, amountOfToken);
        return true;
    }

    function transferFrom(address from, address to, uint256 amountOfToken) public returns(bool success){

        uint256 allownces = allowed[from][msg.sender];
        require (balanceIS[from] >= amountOfToken && allownces >= amountOfToken );
        balanceIS[from] -= amountOfToken ;
        balanceIS[to]  += amountOfToken ;
        allowed [from][msg.sender] -= amountOfToken ;
        emit Transfer (from , to, amountOfToken);
        return true;
    }
     
    function _mint(address account, uint256 amount) external  {

        require(account != address(0), "ERC20: mint to the zero address");
        totalSupply_ = totalSupply_.add(amount);
        balanceIS[account] = balanceIS[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) external {

        require(account != address(0), "ERC20: burn from the zero address");
        totalSupply_ = totalSupply_.sub(amount);
        balanceIS[account] = balanceIS[account].sub(amount);
        emit Transfer(account, address(0), amount);
    }
}
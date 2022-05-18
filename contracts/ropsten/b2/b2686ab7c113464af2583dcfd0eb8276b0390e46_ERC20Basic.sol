/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

//definimos librería SafeMath e implementamos operaciones: suma,resta y multiplicación
//con esto evitaremos problemas de overflow o underflow

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


//Funciones definicas por el estándar ERC20

//Interface token ERC
interface IERC20{
//El suministro total de tokens
function totalsupply()external view returns (uint256);
//Devuelve el número de tokens de una dirección
function balanceOf(address account)external view returns (uint256);
//Si un usuario tiene la cantidad de tokens suficientes (y devuelve el número)
function allowance(address owner, address spender)external view returns (uint256);
//Tokens del suministro inicial a un usuario
function transfer(address recipient, uint256 amount) external returns (bool);
//Si el contrato puede mandar una cantidad de tokens a un usuario
function approve(address spender, uint256 amount) external returns (bool);
//Habilita la transferencia de tokens entre usuarios
function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
//Evento número 1
event Transfer(address indexed from, address indexed to, uint256 value);
//Evento número 2
event Approval(address indexed owner, address indexed spender, uint256 value);
}


//Implementación token
contract ERC20Basic is IERC20{
string public constant name = "Lago";
string public constant symbol ="LGC";
uint public constant decimals= 2;
event Transfer(address indexed from, address indexed to, uint256 tokens);
event Approval(address indexed owner, address indexed spender, uint256 tokens);
using SafeMath for uint256;
mapping(address=>uint) balances;
mapping (address => mapping (address => uint)) allowed;
uint256 totalSupply_;
constructor (uint256 initialSupply) public{
    totalSupply_ = initialSupply;
    balances[msg.sender]=totalSupply_;
}

function totalsupply() public override view returns (uint256){
 return totalSupply_;
}
function increaseTotalSupply(uint newTokensAmount) public {
    totalSupply_+=newTokensAmount;
    balances[msg.sender]+= newTokensAmount;
}
function balanceOf(address tokenOwner) public override view returns (uint256){
    return balances[tokenOwner];
    }
    function allowance(address owner, address delegate) public override view returns (uint256){
        return allowed[owner][delegate];
    }
    function transfer(address recipient, uint256 numTokens) public override returns (bool){
        require(numTokens <=balances[msg.sender]);
        balances[msg.sender]=balances[msg.sender]. sub(numTokens);
        balances[recipient]=balances[recipient].add(numTokens);
        emit Transfer(msg.sender, recipient, numTokens);
        return true;
    }
    function approve(address delegate, uint256 numTokens) public override returns (bool){
        allowed[msg.sender][delegate]=numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }
    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool){
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);
        balances[owner]=balances[owner].sub(numTokens);
        allowed[owner][msg.sender]=allowed[owner][msg.sender].sub(numTokens);
        balances[buyer]=balances[buyer].add(numTokens);
        emit Transfer (owner, buyer, numTokens);
        return true;
    }
}
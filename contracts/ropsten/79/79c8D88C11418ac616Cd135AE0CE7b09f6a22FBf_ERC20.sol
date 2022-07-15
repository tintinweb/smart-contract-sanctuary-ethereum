/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract ERC20{

// https://www.toptal.com/ethereum/create-erc20-token-tutorial
// https://gist.github.com/giladHaimov/8e81dbde10c9aeff69a1d683ed6870be#file-basicerc20-sol

// https://ropsten.etherscan.io/address/0x79c8D88C11418ac616Cd135AE0CE7b09f6a22FBf
    
    // ERC Token Standard

   string public constant name = "ERC20Basic";
    string public constant symbol = "BSC";
    uint8 public constant decimals = 18;  

   mapping(address => uint) balances;
   mapping(address => mapping(address => uint)) allowed;

    uint256 totalSupply_;
   
   constructor(uint256 total) {
       totalSupply_ = total;
       balances[msg.sender] = totalSupply_; 
   }

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
    event Transfer(address indexed from, address indexed to, uint tokens);

    function totalSupply() public view returns(uint){
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public view returns(uint){
        return balances[tokenOwner];
    }

    function allowance(address Owner , address delegate) public view returns(uint){
        return allowed[Owner][delegate];

    } 

    function transfer(address receiver , uint numToken) public returns(bool){
        require(numToken <= balances[msg.sender] , "Sorry you can not access");
        
        balances[msg.sender] = balances[msg.sender] - numToken;
        balances[receiver] = balances[receiver] + numToken;

        emit Transfer(msg.sender , receiver , numToken);
        return true;

    }

    function approve(address delegate , uint numToken) public returns(bool){
        
        allowed[msg.sender][delegate] = numToken;
        emit Approval(msg.sender , delegate , numToken);
        return true;
    }

    function transferFrom(address Owner , address buyer , uint numToken) public returns(bool){
        require(numToken <= balances[Owner]);
        require(numToken <= allowed[Owner][msg.sender]);
        
        balances[Owner] = balances[Owner] - numToken ; 
        allowed[Owner][msg.sender] = allowed[Owner][msg.sender] - numToken;

        balances[buyer] = balances[buyer] + numToken;
        emit Transfer(Owner , buyer , numToken);
        return true;
    }
}

//     library SafeMath { // Only relevant functions
//       function sub(uint256 a, uint256 b) internal pure returns (uint256) {
//        assert(b <= a);
//        return a — b;
//     }
//      function add(uint256 a, uint256 b) internal pure returns (uint256)   {
//       uint256 c = a + b;
//       assert(c >= a);
//       return c;
//    } 
//   }
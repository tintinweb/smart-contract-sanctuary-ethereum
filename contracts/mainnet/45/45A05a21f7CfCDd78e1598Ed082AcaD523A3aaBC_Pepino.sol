/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: MIT
// Pepino $PEPI Meme Token - buypepino.eth
// 
/*
                                                                                                    
                                                                                                    
PPPPPPPPPPPPPPPPP                                           iiii                                    
P::::::::::::::::P                                         i::::i                                   
P::::::PPPPPP:::::P                                         iiii                                    
PP:::::P     P:::::P                                                                                
  P::::P     P:::::P  eeeeeeeeeeee    ppppp   ppppppppp   iiiiiiinnnn  nnnnnnnn       ooooooooooo   
  P::::P     P:::::Pee::::::::::::ee  p::::ppp:::::::::p  i:::::in:::nn::::::::nn   oo:::::::::::oo 
  P::::PPPPPP:::::Pe::::::eeeee:::::eep:::::::::::::::::p  i::::in::::::::::::::nn o:::::::::::::::o
  P:::::::::::::PPe::::::e     e:::::epp::::::ppppp::::::p i::::inn:::::::::::::::no:::::ooooo:::::o
  P::::PPPPPPPPP  e:::::::eeeee::::::e p:::::p     p:::::p i::::i  n:::::nnnn:::::no::::o     o::::o
  P::::P          e:::::::::::::::::e  p:::::p     p:::::p i::::i  n::::n    n::::no::::o     o::::o
  P::::P          e::::::eeeeeeeeeee   p:::::p     p:::::p i::::i  n::::n    n::::no::::o     o::::o
  P::::P          e:::::::e            p:::::p    p::::::p i::::i  n::::n    n::::no::::o     o::::o
PP::::::PP        e::::::::e           p:::::ppppp:::::::pi::::::i n::::n    n::::no:::::ooooo:::::o
P::::::::P         e::::::::eeeeeeee   p::::::::::::::::p i::::::i n::::n    n::::no:::::::::::::::o
P::::::::P          ee:::::::::::::e   p::::::::::::::pp  i::::::i n::::n    n::::n oo:::::::::::oo 
PPPPPPPPPP            eeeeeeeeeeeeee   p::::::pppppppp    iiiiiiii nnnnnn    nnnnnn   ooooooooooo   
                                       p:::::p                                                      
                                       p:::::p                                                      
                                      p:::::::p                                                     
                                      p:::::::p                                                     
                                      p:::::::p                                                     
                                      ppppppppp                                                     
                                                                                                    
                                                                                                    
 */

pragma solidity ^0.8.4;

contract Pepino {
    string public name = "Pepino";
    string public symbol = "PEPI";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 1e12 * 10**uint256(decimals); // 1 trillion tokens
    uint256 public sellLimit = 1e6 * 10**uint256(decimals); // 
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance");
        require(_value <= sellLimit, "Exceeds buy limit");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function setsellLimit(uint256 _sellLimit) public returns (bool success) {
        sellLimit = _sellLimit;
        return true;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
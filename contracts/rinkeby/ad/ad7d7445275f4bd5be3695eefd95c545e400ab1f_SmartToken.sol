/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

pragma solidity ^0.4.0; 

contract SmartToken { 
    mapping(address => uint) tokens; 
    event OnValueChanged(address indexed _from, uint _value); 
    
    function depositToken(address recipient, uint value) returns (bool success) { 
        tokens[recipient] += value; 
        OnValueChanged(recipient, tokens[recipient]); 
        return true; 
    }
    
    function withdrawToken(address recipient, uint value) returns (bool success) { 
        if (int(tokens[recipient] - value) < 0) { 
            tokens[recipient] = 0; 
        } else { 
            tokens[recipient] -= value; 
        } 
        OnValueChanged(recipient, tokens[recipient]); 
        return true; 
    } 
    
    function getTokens(address recipient) constant returns (uint value) { 
        return tokens[recipient]; 
    } 
}
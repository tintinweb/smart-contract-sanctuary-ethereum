/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/
pragma solidity ^0.4.17;


contract Airdrop {
    string public constant name = "VOMO";
    string public constant symbol = "Vomo_B";
    uint public constant decimals = 18;
     event Transfer(address indexed from, address indexed to, uint256 _value);
     address public presaletoken;
    uint numTokens ;
     mapping (address => uint256) private balance;
    //  mapping(address => uint256) balances;
/// Functions:
/// @dev Constructor
    function Airdrop(uint _numTokens) public {
    // numTokens =
    // presaletoken = _presaletoken;
    numTokens = _numTokens;
 }

     function Drop(address receiver) public {
    //    require(numTokens <= balance[msg.sender]);
        balance[msg.sender] -= numTokens;
        balance[receiver] += numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        
        // return true;
    }
    /// @dev Returns number of tokens owned by given address.
/// @param _owner Address of token owner.
    function balanceOf(address _owner) constant returns (uint256) {
    return balance[_owner];
    }

}
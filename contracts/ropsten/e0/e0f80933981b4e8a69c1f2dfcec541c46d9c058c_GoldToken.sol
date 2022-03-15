/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title GoldToken
 * @dev Custom cryptocurrency for development purpose
 */
contract GoldToken {

    string public name; // Name of cryptocurrency
    string public symbol;   // Symbol of cryptocurrency
    uint public decimals;
    uint public totalSupply;

    mapping(address => uint) public balanceOf;  // Balance of holders


    constructor(string memory _name, string memory _symbol, uint _decimals, uint _totalSupply) { 
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
    }


     /**
     * @notice Internal transfer tokens
     * @dev GoldToken
     * @param _from: Address of sender, _to: Address of receiver, _amount: Amount to be transferred
    */
    function internalTransfer(address _from, address _to, uint _amount) internal {
        require(_to != address(0));
        balanceOf[_from] -= _amount;
        balanceOf[_to] += _amount;
    }

    /// @notice External transfer
    /// @dev GoldToken
    /// @param _to: address to be sent, _amount: Amount to be sent
    /// @return bool: transfer is successful or not
    function Transfer(address _to, uint _amount) public returns(bool) {
        require(balanceOf[msg.sender] >= _amount);
        internalTransfer(msg.sender, _to, _amount);
        return true;
    }
}
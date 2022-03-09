/**
 *Submitted for verification at Etherscan.io on 2022-03-09
*/

// SPDX-License-Identifier: No License
pragma solidity ^0.8.12;

/**
 * Teddy Token Contract
 * By dogs world
 */   
contract TeddyToken {
    string public name; // Token name 
    string public symbol; // Token symbol
    uint8 public decimal; // Token decimal

    mapping(address => uint) private balances; // Keeps balance of each address

    event Mint(address _receiver, uint _amount);
    event Transfer(address _sender, address _receiver, uint _amount);

    /**
     * Constroctor sets token name and symbol
     */
    constructor(string memory _name, string memory _symbol, uint8 _decimal) {
      name = _name;
      symbol = _symbol;
      decimal = _decimal;
    }

    /**
     * @dev mint balance to wallet addres
     * @param _address, _amount to store amount
     */
    function mint(address _address, uint _amount) public {
      balances[_address] += _amount;
      emit Mint(_address, _amount);
    }

    /**
     * @dev gives token balance for wallet address
     * @param _address to show amount
     */
    function balanceOf(address _address) public view returns (uint) {
      return (balances[_address] > 0 ? balances[_address] : 0);
    }

    /**
     * @dev transfer amount to wallet addres
     * @param _receiver, _amount to send amount
     */
    function transfer(address _receiver, uint _amount) public {
      require(balances[msg.sender] >= _amount, "Sender does not have balance to transfer");
      balances[msg.sender] -= _amount;
      balances[_receiver] += _amount;
      emit Transfer(msg.sender, _receiver, _amount);
    }
}
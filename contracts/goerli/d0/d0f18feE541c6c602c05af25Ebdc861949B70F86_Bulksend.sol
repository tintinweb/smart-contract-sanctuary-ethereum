/**
 *Submitted for verification at Etherscan.io on 2022-11-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IBulky {
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address to, uint256 value)
        external
        returns (bool);
}
contract Bulksend is IBulky {
    //Public state variable
    event bulkTransfer (address recipient, uint256 amountRecieved, string name );
    address public owner;
    address tokenAddress;
    IBulky token;
    constructor() {
        owner = msg.sender;
    }
    //Mapping an address to its balance
    mapping(address => uint) balances;
    function balanceOf(address _owner)
        external
        view
        override
        returns (uint256)
    {}
    function transfer(address to, uint256 value)
        external
        override
        returns (bool)
    {}
    //Function to get address of owner
    function getOwner() public view returns (address) {
        return owner;
    }
    //find balance of owner
    function balance() public view returns (uint256) {
        return owner.balance;
    }
    //Function to transfer to many addresses
    function multiTransfer(
        address _tokenAddress,
        address[] calldata _toAddresses,
        uint256[] calldata _amount,
        string[] calldata _name
    ) external {
        token = IBulky(_tokenAddress);
        require(_toAddresses.length == _amount.length, "Length inconsistent");
        for (uint i = 0; i < _toAddresses.length; i++) {
            require(token.balanceOf(address(this)) > _amount[i], "you dont have enough token to transer");
            token.transfer(_toAddresses[i], _amount[i]);
            address recipient =  _toAddresses[i];
            uint256 amountReceived = _amount[i];
            string calldata name = _name[i];
            emit bulkTransfer(recipient, amountReceived, name);
        }
        
    }
}
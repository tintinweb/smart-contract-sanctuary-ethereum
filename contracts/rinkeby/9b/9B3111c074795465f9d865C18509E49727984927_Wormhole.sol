// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Wormhole {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    uint public amount;
    address public recipient;
    mapping(address => uint256) private _balances;

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function crosschainBuy(uint _amount, address _recipient) public payable {
        recipient = _recipient;
        _balances[msg.sender] += _amount;
        emit Transfer(address(0), msg.sender, 1);
    }
}
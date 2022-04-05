/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

// SPDX-License-Identifier: NONE
pragma solidity ^0.8.13;

contract LyraTesting {
    bool public isLive = false;
    uint mintedSupply = 0;
    address private owner;

    uint constant MAX_SUPPLY = 10000;
    uint constant PRICE = 0.01 ether;
    
    constructor() {
        owner = msg.sender;
    }

    modifier ownerOnly {
        require(msg.sender == owner, "only owner can call this");
        _;
    }

    function simulateMint(uint _quantity) public payable {
        require(isLive, "contract is not live");
        require(PRICE * _quantity == msg.value, "invalid funds ammount");
        require(_quantity < 5, "can't mint more than 5");
        require(_quantity + mintedSupply < MAX_SUPPLY);

        mintedSupply += _quantity;
        payable(msg.sender).transfer(msg.value);
    }

    function toggleSale(bool _toggle) public ownerOnly {
        isLive = _toggle;
    }
}
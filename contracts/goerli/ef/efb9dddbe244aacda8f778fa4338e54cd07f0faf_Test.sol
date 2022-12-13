// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";

contract Test is  Ownable {

    address public daoWallet;
    event Received(uint256 value);

    function setDaoWallet(address _daoWallet) public onlyOwner {
        daoWallet = payable(_daoWallet);
    }

    function accept() public payable {
        emit Received(msg.value);
    }

    function withdraw() public onlyOwner {
        
        uint256 balance = address(this).balance;

        bool success;
        (success, ) = daoWallet.call{value: ((balance * 100) / 100)}("DAO");
        require(success, "DAO Transaction Unsuccessful");
    }
}
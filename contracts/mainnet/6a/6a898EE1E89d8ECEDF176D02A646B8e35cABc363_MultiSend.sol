// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;
import "./Ownable.sol";

contract MultiSend is Ownable {
    function multiSend(address payable[] memory clients, uint256[] memory amounts) public payable onlyOwner {
        uint256 length = clients.length;
        require(length == amounts.length);

        // transfer the required amount of ether to each one of the clients
        for (uint256 i = 0; i < length; i++){
            clients[i].transfer(amounts[i]);
        }

        // in case you deployed the contract with more ether than required,
        // transfer the remaining ether back to yourself
        uint256 val = address(this).balance;
        (bool success, ) = payable(msg.sender).call{
            value: val
        }("");
        require(success);

        delete val;
        delete length;
    }

    /**
     * withdraw ETH from the contract (callable by Owner only)
     */
    function withdraw() public payable onlyOwner {
        uint256 val = address(this).balance;
        (bool success, ) = payable(msg.sender).call{
            value: val
        }("");
        require(success);
        delete val;
    }
}
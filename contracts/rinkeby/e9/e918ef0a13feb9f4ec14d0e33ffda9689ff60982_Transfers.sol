/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Transfers {
    struct Transfer {
        uint amount;
        uint timestamp;
        address sender;
    }

    Transfer[] transfers;

    address owner;
    uint8 maxTransfers;
    uint8 currentTransfers;

    constructor(uint8 _maxTransfers) {
        owner = msg.sender;
        maxTransfers = _maxTransfers;
    }

    function getTransfer(uint _index) public view returns(Transfer memory) {
        require(_index < transfers.length, "Cannot find this transfer.");

        return transfers[_index];
    }

    modifier requireOwner() {
        require(owner == msg.sender, "Not an owner");
        _;
    }

    function withdrawTo(address payable _to) public requireOwner {
        _to.transfer(address(this).balance);
    }

    receive() external payable {
        if(currentTransfers >= maxTransfers) {
            revert("Cannot accept more transfers.");
        }

        Transfer memory newTransfer = Transfer(msg.value, block.timestamp, msg.sender);

        transfers.push(newTransfer);
        currentTransfers++;
    }

    function getCountTx() public view returns(uint8){
        return currentTransfers;
    }

    function setNewCountTx(uint8 newCount) public requireOwner {
        maxTransfers = newCount;
    }

    function deposit() public payable {
        if(currentTransfers >= maxTransfers) {
            revert("Cannot accept more transfers.");
        }

        Transfer memory newTransfer = Transfer(msg.value, block.timestamp, msg.sender);

        transfers.push(newTransfer);
        currentTransfers++;
    }

    function getContractBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function clearCurrentCountTx() public requireOwner {
        currentTransfers = 0;
    }
}
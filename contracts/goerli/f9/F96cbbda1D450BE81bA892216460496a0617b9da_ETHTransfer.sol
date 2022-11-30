// SPDX-License-Identifier: UNLICENCED
pragma solidity 0.8.10;

contract ETHTransfer {
    mapping(uint256 => bool) private record;
    address payable private beneficiary;

    address private _owner;

    event TransferSuccess(
        address from,
        address to,
        uint256 OrderId,
        uint256 Amount
    );

    constructor(address payable reciver) {
        _owner = msg.sender;
        beneficiary = reciver;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Caller is not the owner");
        _;
    }

    function Setnewreciver(address payable newreciver) public onlyOwner {
        beneficiary = newreciver;
    }

    function Ordertransfer(uint256 orderid, uint256 amount) external payable {
        require(msg.value == amount && amount > 0, "Eth quantity error");
        require(!record[orderid], "OrderId has been used");

        beneficiary.transfer(msg.value);

        record[orderid] = true;
        emit TransferSuccess(msg.sender, beneficiary, orderid, amount);
    }
}
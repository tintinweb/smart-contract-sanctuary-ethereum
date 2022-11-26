// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

error StupidContract__FeeNotEnough();
error StupidContract__NotOwner();
error StupidContract__TransferFailed();

contract StupidContract {
    address public immutable owner;

    StupidStruct[] public stupidRegistry;
    uint256 public immutable MessageEntryFee;
    string public StupidContractDescription;

    struct StupidStruct {
        address sender;
        string message;
    }

    event StupidEvent(uint256 index, address indexed sender, uint256 timestamp);

    modifier CheckFee(uint256 _value) {
        if (_value < MessageEntryFee) revert StupidContract__FeeNotEnough();
        _;
    }
    modifier OnlyOwner() {
        if (msg.sender != owner) revert StupidContract__NotOwner();
        _;
    }

    constructor(uint256 _entryFee, string memory _description) {
        owner = msg.sender;
        MessageEntryFee = _entryFee;
        StupidContractDescription = _description;
    }

    function AddToRegistry(string calldata _message)
        public
        payable
        CheckFee(msg.value)
    {
        stupidRegistry.push(StupidStruct(msg.sender, _message));

        emit StupidEvent(
            stupidRegistry.length - 1,
            msg.sender,
            block.timestamp
        );
    }

    function PullStupidFees() public OnlyOwner {
        (bool success, ) = payable(owner).call{value: address(this).balance}(
            ""
        );

        if (!success) revert StupidContract__TransferFailed();
    }
}
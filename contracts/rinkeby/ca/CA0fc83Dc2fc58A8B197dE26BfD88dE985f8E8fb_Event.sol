// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.6;

contract Event {
    address payable[] public players;
    address payable public mostRecent;
    address payable public contractOwner;
    address payable public contractWallet;
    uint256 public resultRandomness;
    uint256 public numberOfEntries;
    uint256 public maxEntries;
    uint256 private entryFee;

    enum EVENT_STATE {
        CLOSED,
        OPEN,
        CALCULATE
    }
    EVENT_STATE public state;

    constructor(
        uint256 entry,
        uint256 max,
        address wallet
    ) public {
        entryFee = entry;
        numberOfEntries = 0;
        maxEntries = max;
        state = EVENT_STATE.CLOSED;

        contractWallet = payable(wallet);
        contractOwner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == contractWallet, "Not Contract Wallet");
        _;
    }

    modifier onlyContractOwner() {
        require(msg.sender == contractOwner, "Not Contract Owner");
        _;
    }

    function enter() public payable {
        require(state == EVENT_STATE.OPEN);
        require(msg.value >= getFee(), "Not Enough ETH");
        require((numberOfEntries) < maxEntries, "Max Entries Already");
        players.push(msg.sender);
        numberOfEntries++;
    }

    function getFee() public view returns (uint256) {
        return entryFee;
    }

    function changeWallet(address payable newWallet) public onlyContractOwner {
        require(state == EVENT_STATE.CLOSED, "Event is Running");
        contractWallet = newWallet;
    }

    function changeFee(uint256 newAmount) public onlyContractOwner {
        require(state == EVENT_STATE.CLOSED, "Event is Running");
        entryFee = newAmount;
    }

    function changeContractOwner(address payable newOwner)
        public
        onlyContractOwner
    {
        require(state == EVENT_STATE.CLOSED, "Event is Running");
        contractWallet = newOwner;
    }

    function startEvent() public onlyOwner {
        require(state == EVENT_STATE.CLOSED, "Event already Started");
        state = EVENT_STATE.OPEN;
    }

    function endEvent() public onlyOwner {
        require(state == EVENT_STATE.OPEN, "Event is NOT Started");
        state = EVENT_STATE.CALCULATE;
    }

    function cancelEvent() public onlyOwner {
        require(state != EVENT_STATE.CLOSED, "Event is NOT Started");
        contractWallet.transfer(address(this).balance);
        players = new address payable[](0);
        state = EVENT_STATE.CLOSED;
    }

    function finalize(uint256 randomness) public onlyOwner {
        require(state == EVENT_STATE.CALCULATE, "Not looking for a winner yet");
        require(randomness > 0, "random number not generated");
        require(
            randomness != resultRandomness,
            "random number has not changed"
        );
        uint256 indexOfWinner = randomness % (numberOfEntries);
        mostRecent = players[indexOfWinner];
        contractWallet.transfer(address(this).balance / 3);
        mostRecent.transfer(address(this).balance);
        players = new address payable[](0);
        numberOfEntries = 0;
        state = EVENT_STATE.CLOSED;
        resultRandomness = randomness;
    }
}
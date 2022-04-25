// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Eboogotchi {
    event Loved(address indexed caretaker);

    uint256 feedBlock;
    uint256 cleanBlock;
    uint256 playBlock;
    uint256 sleepBlock;

    uint8 internal hungry;
    uint8 internal dirty;
    uint8 internal bored;
    uint8 internal tired;

    mapping(address => uint256) public love;

    constructor() {
        feedBlock = block.number;
        cleanBlock = block.number;
        playBlock = block.number;
        sleepBlock = block.number;

        hungry = 0;
        dirty = 0;
        bored = 0;
        tired = 0;
    }

    function getHungry() public view returns (uint256) {
        return hungry + ((block.number - feedBlock) / 5760);
    }

    function getDirty() public view returns (uint256) {
        return dirty + ((block.number - cleanBlock) / 5760);
    }

    function getBored() public view returns (uint256) {
        return bored + ((block.number - playBlock) / 5760);
    }

    function getTired() public view returns (uint256) {
        return tired + ((block.number - sleepBlock) / 5760);
    }

    function addLove(address caretaker) internal {
        love[caretaker] += 1;
        emit Loved(caretaker);
    }

    function feed() public {
        require(getAlive(), "already dead");
        require(getHungry() > 20, "not hungry");
        require(getTired() < 80, "too tired to feed");
        require(getDirty() < 80, "too dirty to feed");

        feedBlock = block.number;

        hungry = 0;

        tired += 10;
        dirty += 5;

        addLove(msg.sender);
    }

    function clean() public {
        require(getAlive(), "already dead");
        require(getDirty() > 20, "not dirty");

        cleanBlock = block.number;

        dirty = 0;

        addLove(msg.sender);
    }

    function play() public {
        require(getAlive(), "already dead");
        require(getBored() > 20, "not bored");
        require(getHungry() < 80, "too hungry to play");
        require(getTired() < 80, "too tired to play");
        require(getDirty() < 80, "too dirty to play");

        playBlock = block.number;

        bored = 0;

        hungry += 10;
        tired += 10;
        dirty += 5;

        addLove(msg.sender);
    }

    function sleep() public {
        require(getAlive(), "already dead");
        require(getTired() > 0, "not tired");
        require(getDirty() < 80, "too dirty to sleep");

        sleepBlock = block.number;

        tired = 0;

        dirty += 5;

        addLove(msg.sender);
    }

    function getAlive() public view returns (bool) {
        return
            getHungry() < 101 &&
            getDirty() < 101 &&
            getTired() < 101 &&
            getBored() < 101;
    }
}
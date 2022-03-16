pragma solidity >=0.4.22 <0.9.0;

contract SimpleCounter {
    int256 counter;
    int256 counterLimit;
    address private _owner;
    mapping(int256 => address) public winners;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the contract owner.");
        _;
    }

    constructor() public {
        counter = 0;
        counterLimit = 0;
        _owner = msg.sender;
    }

    function getCounter() public view returns (int256) {
        return counter;
    }

    function increment() public {
        require(
            counter < counterLimit,
            "The current counter has already been claimed"
        );
        counter += 1;
        winners[counter] = msg.sender;
    }

    function releaseNextIncrement() public onlyOwner {
        require(
            counter == counterLimit,
            "The counter needs to be incremented first"
        );
        counterLimit += 1;
    }
}
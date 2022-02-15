pragma solidity 0.7.0;

contract LolIercoaster {
    function randInt(uint256 n) external view returns (uint256) {
        return (uint160(address(this)) + block.number / 100) % n;
    }
}

















































contract Lollercoaster {
    uint256 public var620495566;

    constructor() {
        var620495566 = 1011337101;
    }

    function randInt(uint32 n) external view returns (uint256) {
        return var620495566 % n;
    }
}
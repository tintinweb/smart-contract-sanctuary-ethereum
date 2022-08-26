pragma solidity ^0.8.0;

import "./interfaces/IOracle.sol";

contract ForkOracle is IOracle {
    bool expired = false;
    uint256 deployTime;

    uint256 MIN_RANDAO = 2 ** 128;

    constructor() {
        deployTime = block.timestamp;
    }

    function setExpired() public {
        require((block.timestamp - deployTime > 365 * 24 * 60 * 60) || isExpired());
        expired = true;
    }

    function isExpired() public view returns (bool) {
        return expired || block.chainid != 1 || block.difficulty >= MIN_RANDAO;
    }

    function isRedeemable(bool isPos) public view returns (bool) {
        return isPos == (block.chainid == 1);
    }
}

pragma solidity >=0.5.16;

interface IOracle {
    function isExpired() external view returns (bool);

    function isRedeemable(bool future0) external view returns (bool);
}
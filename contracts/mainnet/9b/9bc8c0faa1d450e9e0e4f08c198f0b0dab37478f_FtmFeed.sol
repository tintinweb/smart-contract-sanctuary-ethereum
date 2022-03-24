//SPDX-License-Identifier: Unlicense

pragma solidity ^0.5.16;

import "./SafeMath.sol";

interface IFeed {
    function decimals() external view returns (uint8);
    function latestAnswer() external view returns (uint);
}

contract FtmFeed is IFeed {
    using SafeMath for uint;

    IFeed public ftmFeed;
    IFeed public ethFeed;

    constructor(IFeed _ftmFeed, IFeed _ethFeed) public {
        ftmFeed = _ftmFeed;
        ethFeed = _ethFeed;
    }

    function decimals() public view returns (uint8) {
        return 18;
    }

    function latestAnswer() public view returns (uint) {
        uint ftmEthPrice = ftmFeed.latestAnswer();
        return ftmEthPrice
            .mul(ethFeed.latestAnswer())
            .div(10**uint256(ethFeed.decimals()));
    }
}
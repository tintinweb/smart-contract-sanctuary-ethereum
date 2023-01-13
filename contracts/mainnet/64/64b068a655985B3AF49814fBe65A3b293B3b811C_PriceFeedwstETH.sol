pragma solidity ^0.8.0;

import "IwstETH.sol";
import "IPriceFeedsExt.sol";
contract PriceFeedwstETH {
    IwstETH public constant WSTETHADDRESS = IwstETH(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
    IPriceFeedsExt public constant STETHPRICEFEED = IPriceFeedsExt(0xCfE54B5cD566aB89272946F602D76Ea879CAb4a8);
    IPriceFeedsExt public constant ETHPRICEFEED = IPriceFeedsExt(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    function latestAnswer() public view returns (int256) {
        return int256(WSTETHADDRESS.getStETHByWstETH(1e18))*STETHPRICEFEED.latestAnswer()/ETHPRICEFEED.latestAnswer();
    }
}

pragma solidity >=0.5.17 <0.9.0;

interface IwstETH {
    function wrap(uint256 _stETHAmount) external returns(uint256);
    function unwrap(uint256 _wstETHAmount) external returns(uint256);
    function getStETHByWstETH(uint256 _wstETHAmount) external view returns(uint256);
    function getWstETHBystETH(uint256 _stETHAmount) external view returns(uint256);
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.17 <0.9.0;


interface IPriceFeedsExt {
  function latestAnswer() external view returns (int256);
}
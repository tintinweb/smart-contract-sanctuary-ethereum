// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ARTH {
    function balanceOf(address _account) external view returns (uint256);

    function burn(address _account, uint256 _amount) external;
}

/**
 * @title A simple contract to burn arth
 */
contract ARTHBurner {
    ARTH public arth;

    constructor(address _arth) {
        arth = ARTH(_arth);
    }

    function burn() external {
        arth.burn(address(this), arth.balanceOf(address(this)));
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;


interface IGaugeController {
    function checkpoint_gauge(address gauge) external;

    function gauge_relative_weight(address gauge) external view returns (uint256);
}

contract GaugeControllerQuerier {
    IGaugeController public immutable GAUGE_CONTROLLER;

    constructor (address gaugeController) {
        GAUGE_CONTROLLER = IGaugeController(gaugeController);
    }

    /**
    * @dev Manually edit the ABI to have this function be view.
    */    
    function gauge_relative_weight(address gauge) external returns (uint256) {
        GAUGE_CONTROLLER.checkpoint_gauge(gauge);
        return GAUGE_CONTROLLER.gauge_relative_weight(gauge);
    }
}
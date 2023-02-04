// SPDX-License-Identifier: Apache-2.0
// Copyright © 2020 UBISOFT

pragma solidity ^0.5.0;

/// @notice Moon phases oracle
contract Moon {

    uint256 private constant _PERIOD = 2551464509;
    uint256 private constant _FIRST = 1860960;

    /**
    * @notice Checks wether a timestamp occurs during a full moon
    * @param timestamp The timestamp in Unix epoch in seconds
    * @return True if the timestamp approximately matches a full moon day
    */
    function isFull(uint timestamp) public pure returns(bool) {
        return _since(timestamp) < 86400000;
    }

    /**
    * @notice Calculates the next full moon
    * @param timestamp the reference time
    * @return the approximate timestamp for the start of the next full moon
    */
    function nextFull(uint timestamp) public pure returns(uint) {
        return timestamp + ((_PERIOD - _since(timestamp)) / 1000) + 1;
    }
    
    /**
    * @notice Calculates the previous full moon
    * @param timestamp the reference time
    * @return the approximate timestamp from the start of the last full moon
    */
    function lastStarted(uint timestamp) public pure returns(uint) {
        return timestamp - (_since(timestamp) / 1000);
    }
    
    /**
    * @notice Calculates the time in milliseconds since the last full moon
    */
    function _since(uint timestamp) private pure returns(uint) {
        uint base = timestamp - _FIRST;
        return (base * 1000) % _PERIOD;
    }
}
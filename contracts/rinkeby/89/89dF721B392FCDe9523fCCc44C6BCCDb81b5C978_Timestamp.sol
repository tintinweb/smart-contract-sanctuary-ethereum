// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract Timestamp {

    function getTimestamp() external view returns (uint256){
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp;
    }

    // Every year has on average 365.2425 days accordingly to:
    // https://en.wikipedia.org/wiki/Year.
    // Here we use division truncation to correctly calculate the number of days within years delta time.
    function caculateYearsDeltatime(uint _years) external pure returns (uint256){
        uint oneDay = 1 days;
        return (_years * 3652425 * oneDay + 5000)/ 10000;
    }
}
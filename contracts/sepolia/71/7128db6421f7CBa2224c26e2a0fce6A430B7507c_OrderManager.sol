/**
 *Submitted for verification at Etherscan.io on 2023-05-23
*/

pragma solidity 0.8.19;

contract OrderManager {
    function getEligibleOrders() external pure returns(uint256[] memory) {
        uint256[] memory array = new uint256[](4);
        array[0] = 1;
        array[1] = 2;
        array[2] = 3;
        array[3] = 4;

        return array;
    }
}
/*
 SPDX-License-Identifier: MIT
*/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

/**
 * @author Publius
 * @title Replant2_2 emits the BeanRemove event that was excluded from Replant2
 **/
contract Replant2_2 {
    event BeanRemove(address indexed account, uint32[] crates, uint256[] crateBeans, uint256 beans);

    uint32 constant SEASON = 6074;
    address constant ADDRESS = 0x87233BAe0bCD477a158832e7c17Cb1B0fa44447D;
    uint256 constant AMOUNT = 71286585;

    function init() external {
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = AMOUNT;
        uint32[] memory seasons = new uint32[](1);
        seasons[0] = SEASON;
        emit BeanRemove(ADDRESS, seasons, amounts, AMOUNT);
    }
}
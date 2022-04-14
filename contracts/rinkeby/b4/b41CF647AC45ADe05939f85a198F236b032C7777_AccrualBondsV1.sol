/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.0;

contract AccrualBondsV1 {

        uint256 supplyDelta;
        bool positiveDelta;
        uint256 percentToConvert;
        uint256 newVirtualOutputReserves;
        address[] public tokens;
        uint256[] public virtualReserves;
        uint256[] public halfLives;
        uint256[] public levelBips;
        bool[] public updateElapsed;

    function policyUpdate(
        uint256 _supplyDelta,
        bool _positiveDelta,
        uint256 _percentToConvert,
        uint256 _newVirtualOutputReserves,
        address[] memory _tokens,
        uint256[] memory _virtualReserves,
        uint256[] memory _halfLives,
        uint256[] memory _levelBips,
        bool[] memory _updateElapsed
    ) external {
        supplyDelta = _supplyDelta;
        positiveDelta = _positiveDelta;
        percentToConvert = _percentToConvert;
        newVirtualOutputReserves = _newVirtualOutputReserves;
        tokens = _tokens;
        virtualReserves = _virtualReserves;
        halfLives = _halfLives;
        levelBips = _levelBips;
        updateElapsed = _updateElapsed;
    }
}
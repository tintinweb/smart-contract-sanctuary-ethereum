// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TenUntilTenTokenomicEq {

    mapping(uint256 => uint256) public tokEqBrackets; //day => dispensable
    uint256[15] byDay = [0, 7, 11, 17, 28, 46, 75, 123, 203, 335, 552, 909, 1499, 2470, 3650];

    constructor() {
        uint256 tachyon = 10 ether;
        tokEqBrackets[0] = tachyon;
        tokEqBrackets[7] = tachyon;
        for (uint256 i = 2; i < byDay.length; i++) {
            tachyon -= 500000000 gwei;
            tokEqBrackets[byDay[i]] = tachyon;
        }
    }

    function findLowerBound(uint256 day) public view returns (uint256) {

        uint256 low = 1;
        uint256 high = byDay.length;

        while (low < high) {
            uint256 mid = (low & high) + (low ^ high) / 2;

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (byDay[mid] > day) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && byDay[low - 1] <= day) {
            return low - 1;
        } else {
            return low;
        }
    }

    function getDispensable(uint256 _day) public view returns(uint256 dispense) {
        if (_day  < 7) {
            dispense = 10 ether;
        }
        else {
            uint256 i = findLowerBound(_day);
            uint256 dayMin = byDay[i];
            uint256 dayMax = byDay[i + 1];
            if (_day < dayMax && _day >= dayMin) {
                uint256 gweiMax = tokEqBrackets[byDay[i]];
                uint256 dayRange = dayMax - dayMin;
                uint256 until = _day - dayMin + 1;
                uint256 units = 500000000 gwei / dayRange;
                dispense = gweiMax - (until * units);
            }
        }
    }

    function getDispensableFrom(uint256 _day, uint256 _from, uint256 bal) public view returns(uint256 dispense) {
        require(_day != _from, "Can't dispense same day from last time");
        while (_from < _day) {
            dispense += getDispensable(_from);
            _from++;
        }
        dispense *= bal;
    }
}
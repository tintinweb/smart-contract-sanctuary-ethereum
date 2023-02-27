// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

library BonusRateLockUpA {

    function getRatesByWeeks(uint256 _id, uint8 _weeks) public pure returns (uint16 rate) {

        if (_id == 0) {
            if (_weeks < 13) rate = 0;
            else if (_weeks < 26) rate = 600;
            else if (_weeks < 39) rate = 1200;
            else if (_weeks < 52) rate = 1800;
            else if (_weeks < 65) rate = 2400;
            else if (_weeks < 78) rate = 3000;
            else if (_weeks < 91) rate = 3600;
            else if (_weeks < 104) rate = 4200;
            else if (_weeks < 117) rate = 4800;
            else if (_weeks < 130) rate = 5400;
            else if (_weeks < 143) rate = 6000;
            else rate = 6600;
        } else {
            if (_weeks < 26) rate = 0;
            else if (_weeks < 52) rate = 1200;
            else if (_weeks < 78) rate = 2400;
            else if (_weeks < 104) rate = 3600;
            else if (_weeks < 130) rate = 4800;
            else rate = 6000;
        }
    }

    function getRatesByWeeks1(uint8 _weeks) public pure returns (uint16) {

        if (_weeks < 13) return 0;
        else if (_weeks < 26) return 600;
        else if (_weeks < 39) return 1200;
        else if (_weeks < 52) return 1800;
        else if (_weeks < 65) return 2400;
        else if (_weeks < 78) return 3000;
        else if (_weeks < 91) return 3600;
        else if (_weeks < 104) return 4200;
        else if (_weeks < 117) return 4800;
        else if (_weeks < 130) return 5400;
        else if (_weeks < 143) return 6000;
        else return 6600;

    }
    function getRatesByWeeks2() public pure returns (uint16) {

        return 6600;

    }

}
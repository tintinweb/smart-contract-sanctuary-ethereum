// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

library BonusRateLockUpA {

    function getRatesInfo(uint256 _id) external pure returns (uint8 intervalWeeks, uint16[] memory rates) {

        uint256 len = 0;
        uint256 bonusStep = 0;
        if (_id == 1) {
            intervalWeeks = 26;
            len = 156/intervalWeeks;
            bonusStep = 1200;
        } else if (_id == 2) {
            intervalWeeks = 13;
            len = 156/intervalWeeks;
            bonusStep = 500;
        } else if (_id == 3) {
            intervalWeeks = 13;
            len = 156/intervalWeeks;
            bonusStep = 600;
        }

        rates = new uint16[](len);
        for (uint256 i = 0; i < len ; i++){
            rates[i] = uint16(i * bonusStep);
        }
    }

    function getRatesByWeeks(uint256 _id, uint8 _weeks) external pure returns (uint16 rate) {

        if (_id == 1) {
            if (_weeks < 26) rate = 0;
            else if (_weeks < 52) rate = 1200;
            else if (_weeks < 78) rate = 2400;
            else if (_weeks < 104) rate = 3600;
            else if (_weeks < 130) rate = 4800;
            else rate = 6000;
        } else if (_id == 2) {
            if (_weeks < 13) rate = 0;
            else if (_weeks < 26) rate = 500;
            else if (_weeks < 39) rate = 1000;
            else if (_weeks < 52) rate = 1500;
            else if (_weeks < 65) rate = 2000;
            else if (_weeks < 78) rate = 2500;
            else if (_weeks < 91) rate = 3000;
            else if (_weeks < 104) rate = 3500;
            else if (_weeks < 117) rate = 4000;
            else if (_weeks < 130) rate = 4500;
            else if (_weeks < 143) rate = 5000;
            else rate = 5500;
        } else if (_id == 3) {
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
        }
    }

}
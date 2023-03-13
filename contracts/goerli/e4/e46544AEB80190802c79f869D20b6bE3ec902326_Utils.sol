/**
 *Submitted for verification at Etherscan.io on 2023-03-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19 .0;

library Utils {
    uint256 public constant TEN_THOUSANDTH_PERCENT = 100 * 10**2;

    uint64 public constant DAY = (60 *
        /* from seconds */
        60 *
        /* to hours */
        24); /* to day */
    uint64 public constant MINUTE = (
        60 /* from seconds */
    );
    uint64 public constant QUARTER_OF_MINUTE = (
        15 /* from seconds */
    );
    //tenth
    uint64 public constant TENTH_OF_MINUTE = (
        6 /* from seconds */
    );
    uint64 public constant SECOND = (1);

    function readPercent(uint256 _value, uint16 _centiPercent)
        public
        pure
        returns (uint256[2] memory)
    {
        if (_centiPercent == TEN_THOUSANDTH_PERCENT) {
            return [_value, 0];
        } else if (_centiPercent == 0) {
            return [0, _value];
        }

        require(
            _centiPercent < TEN_THOUSANDTH_PERCENT,
            "The split value is expressed in ten-thousandths and must be less than 10000"
        );

        require(
            _centiPercent > 0,
            "The split value is expressed in ten-thousandths and must be greater than zero"
        );

        require(_value > 1 * 10**6, "request at least one usdt");
        //115792089237316195423570985008687907853269984665640564039457
        require(
            _value <
                115792089237316195423570985008687907853269984665640564039457,
            "request a meaningful value"
        );

        uint256 oneDeciPercent = _value / TEN_THOUSANDTH_PERCENT;
        uint256 splitValue = oneDeciPercent * _centiPercent;
        uint256 remainder = _value - splitValue;
        assert(splitValue + remainder == _value);
        return [splitValue, remainder];
    }

    function roundToValueDiv(uint256 _origUrano, uint256 _scale)
        public
        pure
        returns (uint256)
    {
        //require(_attoUrano => 10**18, "Too few Urano tokens");
        require(_origUrano >= 10**_scale, "Too few tokens");
        // //20.301 / 10.000 = 2
        // //2 * 10.000 = 20.000
        // uint256 integerPart = (_origUrano / _scale)*_scale;
        //20.301 % 10.000 = 301
        uint256 decimalPart = _origUrano % 10**_scale;
        require(decimalPart == 0, "cancellation risk in approximation");
        return _origUrano / 10**_scale;
    }

    function microToUnit(uint256 _microUrano) public pure returns (uint256) {
        return roundToValueDiv(_microUrano, 6);
    }

    function attoToUnit(uint256 _attoUrano) public pure returns (uint256) {
        return roundToValueDiv(_attoUrano, 18);
    }

    function roundToValueMul(uint256 _origUrano, uint256 _scale)
        public
        pure
        returns (uint256)
    {
        //require(_unitUrano > 0, "Too few Urano tokens");
        require(_origUrano > 0, "Too few tokens");
        return _origUrano * 10**_scale;
    }

    function unitToAtto(uint256 _unitUrano) public pure returns (uint256) {
        require(
            _unitUrano <
                115792089237316195423570985008687907853269984665640564039457,
            "overflow kill"
        );
        return roundToValueMul(_unitUrano, 18);
    }

    function unitToMicro(uint256 _unitUsdt) public pure returns (uint256) {
        require(
            _unitUsdt <
                115792089237316195423570985008687907853269984665640564039457,
            "overflow kill"
        );
        return roundToValueMul(_unitUsdt, 6);
    }

    function getSplitPayArray(uint256 _value, uint8 _splits)
        public
        pure
        returns (uint256[] memory)
    {
        require(_value > 0, "at least 1 token");
        require(_splits > 0, "at least 1 split");
        uint256[] memory res = new uint256[](_splits);
        uint8 numOfOps = _splits - 1;
        if (_splits == 1) {
            res[0] = _value;
        } else {
            uint256 intPart = _value / _splits;
            uint256 redeemPart = _value % _splits;
            for (uint8 i = 0; i < numOfOps; i++) {
                res[i] = intPart;
            }
            res[numOfOps] = intPart + redeemPart;
            assert((intPart * _splits + redeemPart) == _value);
        }

        return (res);
    }


    function getInternalRate(uint256 _usdtValueUnit, uint256 _perUranoUnit)
        public
        pure
        returns (uint256[2] memory)
    {
        return [
            unitToMicro(_usdtValueUnit),
            unitToAtto(_perUranoUnit)
        ];
    }

    function getBundleByName(string memory _bundle)
        public
        pure
        returns (uint256[2] memory)
    {
        bytes32 bundledVal = keccak256(abi.encodePacked(_bundle));
        if (bundledVal == keccak256(abi.encodePacked("250"))) {
            return getBundle250();
        } else if (bundledVal == keccak256(abi.encodePacked("500"))) {
            return getBundle500();
        } else if (bundledVal == keccak256(abi.encodePacked("1k"))) {
            return getBundle1k();
        } else if (bundledVal == keccak256(abi.encodePacked("3k"))) {
            return getBundle3k();
        } else if (bundledVal == keccak256(abi.encodePacked("5k"))) {
            return getBundle5k();
        } else if (bundledVal == keccak256(abi.encodePacked("10k"))) {
            return getBundle10k();
        } else if (bundledVal == keccak256(abi.encodePacked("20k"))) {
            return getBundle20k();
        } else if (bundledVal == keccak256(abi.encodePacked("30k"))) {
            return getBundle30k();
        } else if (bundledVal == keccak256(abi.encodePacked("50k"))) {
            return getBundle50k();
        } else if (bundledVal == keccak256(abi.encodePacked("100k"))) {
            return getBundle100k();
        } else {
            revert("invalid bundle");
        }
    }

    function getBundleJsonArray() public pure returns (string memory) {
        return '["250","500","1k","3k","5k","10k","20k","30k","50k","100k"]';
    }

    function getAvailableBundlesJsonArray(uint256 _availableUrano)
        public
        pure
        returns (string memory)
    {
        if (_availableUrano >= 2150000000) {
            return
                '["250","500","1k","3k","5k","10k","20k","30k","50k","100k"]';
        } else if (_availableUrano >= 1070000000) {
            return '["250","500","1k","3k","5k","10k","20k","30k","50k"]';
        } else if (_availableUrano >= 639000000) {
            return '["250","500","1k","3k","5k","10k","20k","30k"]';
        } else if (_availableUrano >= 424000000) {
            return '["250","500","1k","3k","5k","10k","20k"]';
        } else if (_availableUrano >= 210000000) {
            return '["250","500","1k","3k","5k","10k"]';
        } else if (_availableUrano >= 100000000) {
            return '["250","500","1k","3k","5k"]';
        } else if (_availableUrano >= 60000000) {
            return '["250","500","1k","3k"]';
        } else if (_availableUrano >= 20000000) {
            return '["250","500","1k"]';
        } else if (_availableUrano >= 10000000) {
            return '["250","500"]';
        } else if (_availableUrano >= 5000000) {
            return '["250"]';
        } else {
            return "[]";
        }
    }

    function getBundle250() public pure returns (uint256[2] memory) {
        return getInternalRate(250, 5000000);
    }

    function getBundle500() public pure returns (uint256[2] memory) {
        return getInternalRate(500, 10000000);
    }

    function getBundle1k() public pure returns (uint256[2] memory) {
        return getInternalRate(1000, 20000000);
    }

    function getBundle3k() public pure returns (uint256[2] memory) {
        return getInternalRate(3000, 60000000);
    }

    function getBundle5k() public pure returns (uint256[2] memory) {
        return getInternalRate(5000, 100000000);
    }

    function getBundle10k() public pure returns (uint256[2] memory) {
        return getInternalRate(10000, 210000000);
    }

    function getBundle20k() public pure returns (uint256[2] memory) {
        return getInternalRate(20000, 424000000);
    }

    function getBundle30k() public pure returns (uint256[2] memory) {
        return getInternalRate(30000, 639000000);
    }

    function getBundle50k() public pure returns (uint256[2] memory) {
        return getInternalRate(50000, 1070000000);
    }

    function getBundle100k() public pure returns (uint256[2] memory) {
        return getInternalRate(100000, 2150000000);
    }
}
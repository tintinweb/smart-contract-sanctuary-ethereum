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
}
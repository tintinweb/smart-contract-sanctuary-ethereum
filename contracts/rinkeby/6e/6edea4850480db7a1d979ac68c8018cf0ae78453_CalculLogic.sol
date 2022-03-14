/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract CalculLogic {
    /**
     * @dev Function to calculate the odds for fixing the NFT
     */
    function calculChanceToFix(uint256 _levelDestroy, uint256 _properties)
        external
        pure
        returns (uint256[] memory)
    {
        uint256[] memory ret = new uint256[](7);
        ret[0] =
            getProperties(100000000000000000000000000, 1000, _properties) -
            (_levelDestroy * getProperties(1000000, 100, _properties));
        ret[1] =
            getProperties(100000000000000000000000, 1000, _properties) -
            (_levelDestroy * getProperties(1000000, 100, _properties));
        ret[2] =
            getProperties(100000000000000000000, 1000, _properties) -
            (_levelDestroy * getProperties(10000, 100, _properties));
        ret[3] =
            getProperties(100000000000000000, 1000, _properties) -
            (_levelDestroy * getProperties(100, 100, _properties));
        ret[4] =
            getProperties(100000000000000, 1000, _properties) -
            (_levelDestroy * getProperties(100, 100, _properties));
        ret[5] =
            getProperties(100000000000, 1000, _properties) -
            (_levelDestroy * getProperties(1, 100, _properties));
        ret[6] =
            getProperties(100000000, 1000, _properties) -
            (_levelDestroy * getProperties(1, 100, _properties));
        return (ret);
    }

    /**
     * @dev Function to calculate the odds to be allowed to mint a tool
     */
    function calculateChanceToAllow(
        uint256 _indexLevel,
        uint256[] memory _countPerLevel,
        uint256 _countAllow,
        uint256 _allowProperties
    ) external pure returns (uint256) {
        uint256 p;
        for (uint256 i = 0; i < _indexLevel; i++) {
            p +=
                _countPerLevel[i] /
                getProperties(100000000000000, 100, _allowProperties);
        }
        return
            getProperties(10000000000000000, 1000, _allowProperties) +
            _indexLevel *
            getProperties(100000000000, 1000, _allowProperties) +
            p +
            _countAllow /
            getProperties(1000000000, 100, _allowProperties);
    }

    /**
     * @dev Function to calculate the delay until the next try to be allowed
     */
    function calculBlockAllow(uint256 _destroyLevel, uint256 _allowProperties)
        external
        view
        returns (uint256)
    {
        return (block.timestamp +
            getProperties(10000000, 100, _allowProperties) *
            getProperties(1, 100000, _allowProperties) +
            getProperties(100000, 100, _allowProperties) *
            getProperties(1, 100000, _allowProperties) *
            _destroyLevel);
    }

    /**
     * @dev Function to extract the desired value in properties
     */
    function getProperties(
        uint256 _div,
        uint256 _rest,
        uint256 _properties
    ) public pure returns (uint256) {
        uint256 b = _properties / _div;
        if (_rest == 0) {
            return b;
        }
        uint256 c = b % _rest;
        return c;
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-02-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

contract FormatTellorData {

    function spotPrice(string memory _asset, string memory _currency) public pure returns(bytes memory queryData, bytes32 queryId) {
        queryData = abi.encode("SpotPrice", abi.encode(_asset, _currency));
        queryId = keccak256(queryData);
    }

    function legacyQuery(uint256 _legacyQueryIdInt) public pure returns(bytes memory queryData, bytes32 queryId) {
        queryData = bytes('');
        queryId = bytes32(_legacyQueryIdInt);
    }

    function formatValue(uint256 _uint) public pure returns(bytes memory) {
        return abi.encode(_uint);
    }

    function _sliceUint(bytes memory _b) public pure returns (uint256 _x) {
        uint256 _number = 0;
        for (uint256 _i = 0; _i < _b.length; _i++) {
            _number = _number * 2**8;
            _number = _number + uint8(_b[_i]);
        }
        return _number;
    }
}
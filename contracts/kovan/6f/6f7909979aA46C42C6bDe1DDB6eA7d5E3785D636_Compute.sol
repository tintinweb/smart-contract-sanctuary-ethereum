/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;



// Part: Math

library Math {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// File: Compute.sol

contract Compute {
    uint256 public square;
    uint256 public mcr;
    uint256 public beforeGas;
    uint256 public afterGas;
    uint256 public computeGas;

    struct Correlation {
        uint256 corr;
        uint256 value;
    }

    struct PolicyInfo {
        uint256 tpyeID;
        uint256 leverage;
        uint256 pay;
        uint256 value;
    }

    uint256[] public mcrSquare;
    mapping(uint256 => address[]) public policyTypes;
    mapping(address => PolicyInfo) public policyInfos;
    mapping(address => mapping(address => Correlation)) public correlations;

    function addPool(uint256 tpyeID_, address[] memory policyTypes_, uint256[] memory _leverages, uint256[] memory _corrs) external {
        uint256 _length = policyTypes_.length;
        uint256 _corrID = 0;
        for (uint256 _pid = 0; _pid < _length; ++_pid) {
            address _policy = policyTypes_[_pid];
            policyTypes[tpyeID_].push(_policy);
            policyInfos[_policy].tpyeID = tpyeID_;
            policyInfos[_policy].leverage = _leverages[_pid];
            correlations[_policy][_policy].corr = 10000;
            for (uint256 _pid2 = _pid + 1; _pid2 < _length; ++_pid2) {
                address _policy2 = policyTypes_[_pid2];
                (address _policyA, address _policyB) = _policy < _policy2 ? (_policy, _policy2) : (_policy2, _policy);
                correlations[_policyA][_policyB].corr = 2 * _corrs[_corrID++];
            }
        }
    }

    function add(address policy_, uint256 pay_) external {
        uint256 _before = gasleft();

        PolicyInfo storage policyInfo = policyInfos[policy_];
        policyInfo.pay += pay_;
        policyInfo.value = policyInfo.pay * policyInfo.leverage;

        address[] memory policyType = policyTypes[policyInfo.tpyeID];
        uint256 _length = policyType.length;
        uint256 _square = square;
        for (uint256 _tid = 0; _tid < _length; ++_tid) {
            address _tPolicy = policyType[_tid];
            uint256 _tValue = policyInfos[_tPolicy].value;
            (address _policyA, address _policyB) = policy_ < _tPolicy ? (policy_, _tPolicy) : (_tPolicy, policy_);
            Correlation storage correlation = correlations[_policyA][_policyB];

            uint256 _cValue = correlation.value;
            correlation.value = correlation.corr * _tValue * policyInfo.value;
            _square += correlation.value - _cValue;
        }
        square = _square;
        uint256 _mcr = Math.sqrt(_square) / 1000000;
        uint256 _after = gasleft();

        mcr = _mcr;
        beforeGas = _before;
        afterGas = _after;
        computeGas = _before - _after;
    }

}
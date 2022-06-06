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

    mapping(uint256 => address[]) public policyTypes;
    mapping(address => PolicyInfo) public policyInfos;
    mapping(address => mapping(address => Correlation)) public correlations;

    function addPool(uint256 tpyeID_, address[] memory policys_, uint256[] memory leverages_, uint256[] memory corrs_) external {
        uint256 _length = policys_.length;
        uint256 _corrID = 0;
        Correlation memory _pCorrelation = Correlation({
            corr: 10000,
            value: 0
        });
        for (uint256 _pid = 0; _pid < _length; ++_pid) {
            address _policy = policys_[_pid];
            policyTypes[tpyeID_].push(_policy);
            PolicyInfo memory _policyInfo = PolicyInfo({
              tpyeID: tpyeID_,
              leverage: leverages_[_pid],
              pay: 0,
              value: 0
            });

            policyInfos[_policy] = _policyInfo;
            correlations[_policy][_policy] = _pCorrelation;
            for (uint256 _pid2 = _pid + 1; _pid2 < _length; ++_pid2) {
                address _policy2 = policys_[_pid2];
                (address _policyA, address _policyB) = _policy < _policy2 ? (_policy, _policy2) : (_policy2, _policy);
                Correlation memory _correlation = Correlation({
                    corr: corrs_[_corrID++] * 2,
                    value: 0
                });

                correlations[_policyA][_policyB] = _correlation;
            }
        }
    }

    function addPolicy(uint256 tpyeID_, address policy_, uint256 leverage_, uint256[] memory corrs_) external {
        uint256 _length = policyTypes[tpyeID_].length;

        policyTypes[tpyeID_].push(policy_);
        PolicyInfo memory _policyInfo = PolicyInfo({
          tpyeID: tpyeID_,
          leverage: leverage_,
          pay: 0,
          value: 0
        });
        policyInfos[policy_] = _policyInfo;

        Correlation memory _pCorrelation = Correlation({
            corr: 10000,
            value: 0
        });
        correlations[policy_][policy_] = _pCorrelation;

        uint256 _corrID = 0;
        for (uint256 _pid = 0; _pid < _length; ++_pid) {
            address _policy2 = policyTypes[tpyeID_][_pid];
            (address _policyA, address _policyB) = policy_ < _policy2 ? (policy_, _policy2) : (_policy2, policy_);
            Correlation memory _correlation = Correlation({
                corr: corrs_[_corrID++] * 2,
                value: 0
            });
            correlations[_policyA][_policyB] = _correlation;
        }
    }

    function add(address policy_, uint256 pay_) external {
        uint256 _before = gasleft();

        PolicyInfo storage policyInfo = policyInfos[policy_];
        uint256 _policyPay = policyInfo.pay;
        uint256 _leverage = policyInfo.leverage;
        uint256 _typeID = policyInfo.tpyeID;

        _policyPay +=  pay_;
        uint256 _policyValue = _policyPay * _leverage;
        policyInfo.pay = _policyPay;
        policyInfo.value = _policyValue;

        address[] memory policyType = policyTypes[_typeID];
        uint256 _square = square;
        for (uint256 _pid = 0; _pid < policyType.length; ++_pid) {
            address _policy = policyType[_pid];
            uint256 _value = policyInfos[_policy].value;
            (address _policyA, address _policyB) = policy_ < _policy ? (policy_, _policy) : (_policy, policy_);
            Correlation storage correlation = correlations[_policyA][_policyB];

            uint256 _beforeValue = correlation.value;
            uint256 _corr = correlation.corr;
            uint256 _afterValue = _corr * _value * _policyValue;
            correlation.value = _afterValue;
            _square += _afterValue - _beforeValue;
        }
        square = _square;
        uint256 _mcr = Math.sqrt(_square) / 1000000;
        uint256 _after = gasleft();

        mcr = _mcr;
        beforeGas = _before;
        afterGas = _after;
        computeGas = _before - _after;
    }

    function add1(address policy_, uint256 pay_) external {
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
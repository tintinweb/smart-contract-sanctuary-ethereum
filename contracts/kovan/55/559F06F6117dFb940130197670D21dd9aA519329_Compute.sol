/**
 *Submitted for verification at Etherscan.io on 2022-06-07
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

    uint256 public typeID = 0;

    uint256 public beforeGas;
    uint256 public afterGas;
    uint256 public computeGas;

    struct Correlation {
        uint16 corr;
        uint240 value;
    }

    struct PolicyInfo {
        uint8 tpyeID;
        uint16 leverage;
        uint112 pay;
        uint120 value;
    }

    mapping(uint256 => address[]) public policyTypes;
    mapping(address => PolicyInfo) public policyInfos;
    mapping(address => mapping(address => Correlation)) public correlations;

    function addPool(address[] memory policys_, uint256[] memory leverages_, uint256[] memory corrs_) external {
        Correlation memory _iCorrelation = Correlation({
            corr: 10000,
            value: 0
        });
        uint256 _corrID = 0;
        uint256 _typeID = ++typeID;
        address[] storage _policyType = policyTypes[_typeID];
        uint256 _length = policys_.length;
        for (uint256 _pid = 0; _pid < _length; ++_pid) {
            address _policy = policys_[_pid];
            _policyType.push(_policy);
            PolicyInfo memory _policyInfo = PolicyInfo({
              tpyeID: uint8(_typeID),
              leverage: uint16(leverages_[_pid]),
              pay: 0,
              value: 0
            });

            policyInfos[_policy] = _policyInfo;
            correlations[_policy][_policy] = _iCorrelation;
            for (uint256 _pid2 = _pid + 1; _pid2 < _length; ++_pid2) {
                address _policy2 = policys_[_pid2];
                (address _policyA, address _policyB) = _policy < _policy2 ? (_policy, _policy2) : (_policy2, _policy);
                Correlation memory _correlation = Correlation({
                    corr: uint16(corrs_[_corrID++] * 2),
                    value: 0
                });

                correlations[_policyA][_policyB] = _correlation;
            }
        }
    }

    function addPolicy(uint256 tpyeID_, address policy_, uint256 leverage_, uint256[] memory corrs_) external {
        require(tpyeID_ <=  typeID, "!tpyeID_");
        uint256 _length = policyTypes[tpyeID_].length;

        policyTypes[tpyeID_].push(policy_);
        PolicyInfo memory _policyInfo = PolicyInfo({
            tpyeID: uint8(tpyeID_),
            leverage: uint16(leverage_),
            pay: 0,
            value: 0
        });
        policyInfos[policy_] = _policyInfo;

        Correlation memory _iCorrelation = Correlation({
            corr: 10000,
            value: 0
        });
        correlations[policy_][policy_] = _iCorrelation;

        uint256 _corrID = 0;
        for (uint256 _pid = 0; _pid < _length; ++_pid) {
            address _policy2 = policyTypes[tpyeID_][_pid];
            (address _policyA, address _policyB) = policy_ < _policy2 ? (policy_, _policy2) : (_policy2, policy_);
            Correlation memory _correlation = Correlation({
                corr: uint16(corrs_[_corrID++] * 2),
                value: 0
            });
            correlations[_policyA][_policyB] = _correlation;
        }
    }

    function compute(address policy_, uint256 pay_, bool add_) external {
        uint256 _before = gasleft();
        (uint256 _typeID, uint256 _policyValue) =  _updatePolicyValue(policy_, pay_, add_);
        (uint256 _beforeCorr, uint256 _afterCorr) =  _computeCorrValue(policy_, _typeID, _policyValue);
        square = square - _beforeCorr + _afterCorr;
        uint256 _mcr = Math.sqrt(square) / 1000000;
        uint256 _after = gasleft();

        mcr = _mcr;
        beforeGas = _before;
        afterGas = _after;
        computeGas = _before - _after;
    }

    function _updatePolicyValue(address policy_, uint256 pay_, bool add_) private returns (uint256, uint256) {
        PolicyInfo storage policyInfo = policyInfos[policy_];
        uint256 _typeID = policyInfo.tpyeID;
        require(_typeID > 0, "!tpyeID");
        uint256 _policyPay = policyInfo.pay;
        if (true == add_) {
            _policyPay =  _policyPay + pay_;
        }else {
            _policyPay =  _policyPay - pay_;
        }
        policyInfo.pay = uint112(_policyPay);
        uint256 _leverage = policyInfo.leverage;
        uint256 _policyValue = _policyPay * _leverage;
        policyInfo.value = uint120(_policyValue);
        return (_typeID, _policyValue);

    }

    function _computeCorrValue(address policy_, uint256 typeID_, uint256 policyValue_) private returns (uint256, uint256) {
        uint256 _beforeCorrValue = 0;
        uint256 _afterCorrValue = 0;
        uint256 _length = policyTypes[typeID_].length;
        for (uint256 _pid = 0; _pid <_length; ++_pid) {
            address _policy2= policyTypes[typeID_][_pid];
            (address _policyA, address _policyB) = policy_ < _policy2 ? (policy_, _policy2) : (_policy2, policy_);
            Correlation storage correlation = correlations[_policyA][_policyB];

            _beforeCorrValue = _beforeCorrValue + correlation.value;
            uint256 _corr = correlation.corr;
            uint256 _policyValue2 = policyInfos[_policy2].value;
            uint256 _corrValue = _corr * _policyValue2 * policyValue_;
            _afterCorrValue = _afterCorrValue + _corrValue;
            correlation.value = uint240(_corrValue);

        }
        return (_beforeCorrValue, _afterCorrValue);
    }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "Math.sol";
import "IInsureConfig.sol";

contract MCRCompute {
    uint256 public square;
    uint256 public mcr;

    uint256 public typeID = 0;

    uint256 constant public maxCorr = 5000;
    uint256 constant public maxLeverage = 10000;

    uint256 public beforeGas;
    uint256 public afterGas;
    uint256 public computeGas;

    struct ProjectInfo {
        uint128 totalPay;
        uint128 value;
    }

    mapping(address => ProjectInfo) public projectInfos;
    mapping(address => mapping(address => uint256)) public corrValue;

    function totalPay(address project_) public view returns (uint256) {
        return projectInfos[project_].totalPay;
    }

    function compute(address config_, address project_, uint256 pay_, bool add_) external returns(uint256) {
        uint256 _projectValue =  _updatePolicyValue(config_, project_, pay_, add_);
        (uint256 _beforeCorr, uint256 _afterCorr) =  _computeCorrValue(config_, project_, _projectValue);
        square = square - _beforeCorr + _afterCorr;
        return Math.sqrt(square) / 1000000;
    }

    function computeTestGas(address config_, address project_, uint256 pay_, bool add_) external {
        uint256 _before = gasleft();
        uint256 _projectValue =  _updatePolicyValue(config_, project_, pay_, add_);
        (uint256 _beforeCorr, uint256 _afterCorr) =  _computeCorrValue(config_, project_, _projectValue);
        square = square - _beforeCorr + _afterCorr;
        uint256 _mcr = Math.sqrt(square) / 1000000;
        uint256 _after = gasleft();

        mcr = _mcr;
        beforeGas = _before;
        afterGas = _after;
        computeGas = _before - _after;
    }

    function _updatePolicyValue(address config_, address project_, uint256 pay_, bool add_) internal returns (uint256) {
        ProjectInfo storage projectInfo = projectInfos[project_];
        uint256 _projectPay = projectInfo.totalPay;
        if (true == add_) {
            _projectPay =  _projectPay + pay_;
        }else {
            _projectPay =  _projectPay - pay_;
        }
        projectInfo.totalPay = uint128(_projectPay);
        uint256 _leverage = IInsureConfig(config_).leverageFactor(project_);
        uint256 _projectValue = _projectPay * _leverage;
        projectInfo.value = uint128(_projectValue);
        return _projectValue;

    }

    function _computeCorrValue(address config_, address project_, uint256 projectValue_) internal returns (uint256, uint256) {
        uint256 _beforeCorrValue = 0;
        uint256 _afterCorrValue = 0;
        uint256 _classID = IInsureConfig(config_).classID(project_);
        uint256 _length = IInsureConfig(config_).classLength(_classID);
        for (uint256 _pid = 0; _pid <_length; ++_pid) {
            address _project2= IInsureConfig(config_).project(_classID, _pid);
            (address _projectA, address _projectB) = project_ < _project2 ? (project_, _project2) : (_project2, project_);

            _beforeCorrValue = _beforeCorrValue + corrValue[_projectA][_projectB];
            uint256 _corr = IInsureConfig(config_).corr(_projectA, _projectB);
            uint256 _projectValue2 = projectInfos[_project2].value;
            uint256 _corrValue = _corr * _projectValue2 * projectValue_;
            _afterCorrValue = _afterCorrValue + _corrValue;
            corrValue[_projectA][_projectB] = _corrValue;
        }
        return (_beforeCorrValue, _afterCorrValue);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IInsureConfig {
    function classID(address project_) external view returns (uint256);
    function payFactor(address project_) external view returns (uint256);
    function leverageFactor(address project_) external view returns (uint256);
    function corr(address project1_, address project2_) external view returns (uint256);
    function classLength(uint256 classID_) view external returns (uint256);
    function class(uint256 classID_) view external returns (address[] memory);
    function project(uint256 classID_, uint256 ID_) view external returns (address);
    function pay(address project_) external view returns (uint256);
    function price(address project_) external view returns (uint256);
}
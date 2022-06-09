// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "Math.sol";
import "IInsureConfig.sol";

contract MCRCompute {
    uint256 public square = 0;

    mapping(address => uint256) public projectValues;
    mapping(address => mapping(address => uint256)) public corrValue;

    function compute(address config_, uint256 classID_, address project_, uint256 projectValue_) external returns(uint256) {
        projectValues[project_] = projectValue_;
        (uint256 _beforeCorr, uint256 _afterCorr) =  _computeCorrValue(config_, classID_, project_, projectValue_);
        square = square - _beforeCorr + _afterCorr;
        return Math.sqrt(square) / 1000000;
    }

    function _computeCorrValue(address config_, uint256 classID_, address project_, uint256 projectValue_) internal returns (uint256, uint256) {
        uint256 _beforeCorrValue = 0;
        uint256 _afterCorrValue = 0;
        uint256 _length = IInsureConfig(config_).classLength(classID_);
        for (uint256 _pid = 0; _pid <_length; ++_pid) {
            address _project2= IInsureConfig(config_).project(classID_, _pid);
            (address _projectA, address _projectB) = project_ < _project2 ? (project_, _project2) : (_project2, project_);

            _beforeCorrValue = _beforeCorrValue + corrValue[_projectA][_projectB];
            uint256 _corr = IInsureConfig(config_).corrOrder(_projectA, _projectB);
            uint256 _projectValue2 = projectValues[_project2];
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
    function classIDLength(address project_) external view returns (uint256 classID, uint256 length);
    function classID(address project_) external view returns (uint256);
    function payFactor(address project_) external view returns (uint256);
    function leverageFactor(address project_) external view returns (uint256);
    function corr(address project1_, address project2_) external view returns (uint256);
    function corrOrder(address project1_, address project2_) external view returns (uint256);
    function classLength(uint256 classID_) view external returns (uint256);
    function class(uint256 classID_) view external returns (address[] memory);
    function project(uint256 classID_, uint256 ID_) view external returns (address);
    function policyPay(address project_) external view returns (uint256);
    function policyPrice(address project_) external view returns (uint256);
    function projectConfig(address project_) external view returns (uint256 classID, uint256 payFactor, uint256 leverageFactor, uint256 policyPrice, uint256 policyPay);
}
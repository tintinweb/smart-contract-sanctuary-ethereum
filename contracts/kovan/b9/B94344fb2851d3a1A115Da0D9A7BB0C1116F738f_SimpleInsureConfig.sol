// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IInsureConfig.sol";

contract SimpleInsureConfig is IInsureConfig {
    struct ProjectConfig {
        uint8 accept;
        uint8 projectID;
        uint16 classID;
        uint16 payFactor;
        uint16 leverageFactor;
        uint96 policyPrice;
        uint96 policyPay;
    }

    uint16 constant public maxCorr = 5000;
    uint16 constant public maxPayFactor = 2500;
    uint16 constant public maxLeverageFactor = 10000;
    uint16 public globalClassID = 0;

    mapping(uint256 => address[]) public projectClasses;
    mapping(address => ProjectConfig) public projects;

    function projectClassLength(uint256 classID_) view public returns (uint256) {
        return projectClasses[classID_].length;
    }

    function classIDLength(address project_) external view returns (uint256, uint256) {
        require(1 == projects[project_].accept, "!project classID");
        uint256 _classID = projects[project_].classID;
        return (_classID, projectClasses[_classID].length);
    }

    function projectClass(uint256 classID_) view external returns (address[] memory) {
        require(classID_ <=  globalClassID, "!classID_");
        return projectClasses[classID_];
    }

    function project(uint256 classID_, uint256 ID_) view external returns (address) {
        require(classID_ <=  globalClassID, "!classID_ project");
        return projectClasses[classID_][ID_];
    }

    function projectConfig(address project_) external view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        require(1 == projects[project_].accept, "!project classID");
        return (projects[project_].classID, projects[project_].projectID, projects[project_].payFactor, projects[project_].leverageFactor, projects[project_].policyPrice, projects[project_].policyPay);
    }

    function classID(address project_) external view returns (uint256) {
        require(1 == projects[project_].accept, "!project classID");
        return projects[project_].classID;
    }

    function payFactor(address project_) external view returns (uint256) {
        require(1 == projects[project_].accept, "!project payFactor");
        return projects[project_].payFactor;
    }
    function leverageFactor(address project_) external view returns (uint256) {
        require(1 == projects[project_].accept, "!project leverageFactor");
        return projects[project_].leverageFactor;
    }

    function policyPay(address project_) external view returns (uint256) {
        require(1 == projects[project_].accept, "!project policyPay");
        return projects[project_].policyPay;
    }
    function policyPrice(address project_) external view returns (uint256) {
        require(1 == projects[project_].accept, "!project policyPrice");
        return projects[project_].policyPrice;
    }

    function updatePayFactor(address project_, uint16 payFactor_) public {
        require(payFactor_ <=  maxPayFactor, "!payFactor_");
        projects[project_].payFactor = payFactor_;
    }

    function updateLeverageFactor(address project_, uint16 leverageFactor_) public {
        require(leverageFactor_ <=  maxLeverageFactor, "!leverage_");
        projects[project_].leverageFactor = leverageFactor_;
    }

    function updatePolicyPay(address project_, uint96 policyPay_) public {
        require(1 == projects[project_].accept, "!project pay");
        projects[project_].policyPay = policyPay_;
    }
    function updatePolicyPrice(address project_, uint96 policyPrice_) public {
        require(1 == projects[project_].accept, "!project price");
        projects[project_].policyPrice = policyPrice_;
    }

    function project(uint16 classID_, address project_,  uint16 leverage_, uint96 price_, uint96 pay_) external {
        if (classID_ == 0){
            classID_ = ++globalClassID;
        } else {
            require(classID_ <=  globalClassID, "!classID_");
        }
        require(0 == projects[project_].classID, "!project");
        uint256 _length = projectClasses[classID_].length;

        projectClasses[classID_].push(project_);
        ProjectConfig memory _projectConfig = ProjectConfig({
            accept: 1,
            classID: classID_,
            projectID: uint8(_length),
            payFactor: maxPayFactor,
            leverageFactor: leverage_,
            policyPrice: price_,
            policyPay: pay_
        });
        projects[project_] = _projectConfig;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IInsureConfig {
    function classIDLength(address project_) external view returns (uint256 classID, uint256 length);
    function classID(address project_) external view returns (uint256);
    function payFactor(address project_) external view returns (uint256);
    function leverageFactor(address project_) external view returns (uint256);
    function projectClassLength(uint256 classID_) view external returns (uint256);
    function projectClass(uint256 classID_) view external returns (address[] memory);
    function project(uint256 classID_, uint256 ID_) view external returns (address);
    function policyPay(address project_) external view returns (uint256);
    function policyPrice(address project_) external view returns (uint256);
    function projectConfig(address project_) external view returns (uint256 classID, uint256 projectID, uint256 payFactor, uint256 leverageFactor, uint256 policyPrice, uint256 policyPay);
}
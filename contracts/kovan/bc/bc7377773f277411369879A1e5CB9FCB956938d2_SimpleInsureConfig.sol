// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IInsureConfig.sol";

contract SimpleInsureConfig is IInsureConfig {
    struct ProjectConfig {
        uint8 accept;
        uint8 projectID;
        uint16 classID;
        uint16 coverageFactor;
        uint16 leverageFactor;
        uint96 policyPrice;
        uint96 coverage;
    }

    uint16 constant public maxCorr = 5000;
    uint16 constant public maxCoverageFactor = 2500;
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
        return (projects[project_].classID, projects[project_].projectID, projects[project_].coverageFactor, projects[project_].leverageFactor, projects[project_].policyPrice, projects[project_].coverage);
    }

    function classID(address project_) external view returns (uint256) {
        require(1 == projects[project_].accept, "!project classID");
        return projects[project_].classID;
    }

    function coverageFactor(address project_) external view returns (uint256) {
        require(1 == projects[project_].accept, "!project coverageFactor");
        return projects[project_].coverageFactor;
    }
    function leverageFactor(address project_) external view returns (uint256) {
        require(1 == projects[project_].accept, "!project leverageFactor");
        return projects[project_].leverageFactor;
    }

    function coverage(address project_) external view returns (uint256) {
        require(1 == projects[project_].accept, "!project coverage");
        return projects[project_].coverage;
    }
    function policyPrice(address project_) external view returns (uint256) {
        require(1 == projects[project_].accept, "!project policyPrice");
        return projects[project_].policyPrice;
    }

    function updateCoverageFactor(address project_, uint16 coverageFactor_) public {
        require(coverageFactor_ <=  maxCoverageFactor, "!coverageFactor_");
        projects[project_].coverageFactor = coverageFactor_;
    }

    function updateLeverageFactor(address project_, uint16 leverageFactor_) public {
        require(leverageFactor_ <=  maxLeverageFactor, "!leverage_");
        projects[project_].leverageFactor = leverageFactor_;
    }

    function updatePolicyPay(address project_, uint96 coverage_) public {
        require(1 == projects[project_].accept, "!project pay");
        projects[project_].coverage = coverage_;
    }
    function updatePolicyPrice(address project_, uint96 policyPrice_) public {
        require(1 == projects[project_].accept, "!project price");
        projects[project_].policyPrice = policyPrice_;
    }

    function project(uint16 classID_, address project_,  uint16 leverage_, uint96 price_, uint96 coverage_) external {
        if (0 == classID_ ){
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
            coverageFactor: maxCoverageFactor,
            leverageFactor: leverage_,
            policyPrice: price_,
            coverage: coverage_
        });
        projects[project_] = _projectConfig;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IInsureConfig {
    function classIDLength(address project_) external view returns (uint256 classID, uint256 length);
    function classID(address project_) external view returns (uint256);
    function coverageFactor(address project_) external view returns (uint256);
    function leverageFactor(address project_) external view returns (uint256);
    function projectClassLength(uint256 classID_) view external returns (uint256);
    function projectClass(uint256 classID_) view external returns (address[] memory);
    function project(uint256 classID_, uint256 ID_) view external returns (address);
    function coverage(address project_) external view returns (uint256);
    function policyPrice(address project_) external view returns (uint256);
    function projectConfig(address project_) external view returns (uint256 classID, uint256 projectID, uint256 coverageFactor, uint256 leverageFactor, uint256 policyPrice, uint256 coverage);
}
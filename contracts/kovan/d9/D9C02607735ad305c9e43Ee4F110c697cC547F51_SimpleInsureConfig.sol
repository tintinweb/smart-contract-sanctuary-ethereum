// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleInsureConfig {
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
    mapping(address => mapping(address => uint256)) public correlations;

    function classLength(uint256 classID_) view public returns (uint256) {
        return projectClasses[classID_].length;
    }

    function classIDLength(address project_) external view returns (uint256, uint256) {
        require(1 == projects[project_].accept, "!project classID");
        uint256 _classID = projects[project_].classID;
        return (_classID, projectClasses[_classID].length);
    }

    function class(uint256 classID_) view external returns (address[] memory) {
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

    function corr(address project1_, address project2_) external view returns (uint256) {
        require(1 == projects[project1_].accept, "!project1");
        require(1 == projects[project2_].accept, "!project2");
        require(projects[project1_].classID == projects[project2_].classID, "!corr classID");
        (address _projectA, address _projectB) = projects[project1_].projectID < projects[project2_].projectID ? (project1_, project2_) : (project2_, project1_);
        return correlations[_projectA][_projectB];
    }

    function corrOrder(address project1_, address project2_) external view returns (uint256) {
        return correlations[project1_][project2_];
    }
    /*
    function updateCorr(address project1_, address project2_, uint256 corr_) public {
        require(corr_ <  maxCorr, "!corr_");
        require(projects[project1_].classID == projects[project2_].classID, "!corr classID");
        (address _projectA, address _projectB) = projects[project1_].projectID < projects[project2_].projectID ? (project1_, project2_) : (project2_, project1_);
        correlations[_projectA][_projectB] = corr_;
    }

    function updatePayFactor(address project_, uint256 payFactor_) public {
        require(payFactor_ <=  maxPayFactor, "!payFactor_");
        projects[project_].payFactor = payFactor_;
    }

    function updateLeverageFactor(address project_, uint256 leverageFactor_) public {
        require(leverageFactor_ <=  maxLeverageFactor, "!leverage_");
        projects[project_].leverageFactor = leverageFactor_;
    }

    function updatePay(address project_, uint256 policyPay_) public {
        require(projects[project_].accept, "!project pay");
        projects[project_].policyPay = policyPay_;
    }
    function updatePrice(address project_, uint256 policyPrice_) public {
        require(projects[project_].accept, "!project price");
        projects[project_].policyPrice = policyPrice_;
    }
    */

    function addProject(uint16 classID_, address project_,  uint16 leverage_, uint96 price_, uint96 pay_, uint16[] memory corrs_) external {
        require(classID_ <=  globalClassID, "!classID_");
        require(0 == projects[project_].classID, "!project");
        uint256 _length = projectClasses[classID_].length;
        require(_length == corrs_.length, "!corrs");

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

        correlations[project_][project_] = 10000;

        uint256 _corrID = 0;
        for (uint256 _pid = 0; _pid < _length; ++_pid) {
            address _project1 = projectClasses[classID_][_pid];
            correlations[_project1][project_] = corrs_[_corrID++] * 2;
        }
    }

    function newPool(address project_, uint16 leverage_, uint96 price_, uint96 pay_) external {
        uint256 _classID = ++globalClassID;
        require(0 == projects[project_].classID, "!project");

        projectClasses[_classID].push(project_);
        ProjectConfig memory _projectConfig = ProjectConfig({
            accept: 1,
            classID: uint16(_classID),
            projectID: 0,
            payFactor: maxPayFactor,
            leverageFactor: leverage_,
            policyPrice: price_,
            policyPay: pay_
        });
        projects[project_] = _projectConfig;
        correlations[project_][project_] = 10000;
    }
}
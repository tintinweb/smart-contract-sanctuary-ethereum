// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleInsureConfig {
    struct ProjectConfig {
        bool accept;
        uint256 classID;
        uint256 payFactor;
        uint256 leverageFactor;
        uint256 price;
        uint256 pay;
    }

    uint256 constant public maxCorr = 5000;
    uint256 constant public maxPayFactor = 2500;
    uint256 constant public maxLeverageFactor = 10000;
    uint256 public globalClassID = 0;

    mapping(uint256 => address[]) public projectClasses;
    mapping(address => ProjectConfig) public projects;
    mapping(address => mapping(address => uint256)) public correlations;

    function classLength(uint256 classID_) view public returns (uint256) {
        return projectClasses[classID_].length;
    }

    function class(uint256 classID_) view external returns (address[] memory) {
        require(classID_ <=  globalClassID, "!classID_");
        return projectClasses[classID_];
    }

    function project(uint256 classID_, uint256 ID_) view external returns (address) {
        require(classID_ <=  globalClassID, "!classID_");
        return projectClasses[classID_][ID_];
    }

    function classID(address project_) external view returns (uint256) {
        require(projects[project_].accept, "!project");
        return projects[project_].classID;
    }

    function payFactor(address project_) external view returns (uint256) {
        require(projects[project_].accept, "!project");
        return projects[project_].payFactor;
    }
    function leverageFactor(address project_) external view returns (uint256) {
        require(projects[project_].accept, "!project");
        return projects[project_].leverageFactor;
    }

    function pay(address project_) external view returns (uint256) {
        require(projects[project_].accept, "!project");
        return projects[project_].pay;
    }
    function price(address project_) external view returns (uint256) {
        require(projects[project_].accept, "!project");
        return projects[project_].price;
    }

    function corr(address project1_, address project2_) external view returns (uint256) {
        require(projects[project1_].accept, "!project1");
        require(projects[project2_].accept, "!project2");
        (address _projectA, address _projectB) = project1_ < project2_ ? (project1_, project2_) : (project2_, project1_);
        return correlations[_projectA][_projectB];
    }

    function updateCorr(address project1_, address project2_, uint256 corr_) public {
        require(corr_ <  maxCorr, "!corr_");
        (address _projectA, address _projectB) = project1_ < project2_ ? (project1_, project2_) : (project2_, project1_);
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

    function updatePay(address project_, uint256 pay_) public {
        require(projects[project_].accept, "!project");
        projects[project_].pay = pay_;
    }
    function updatePrice(address project_, uint256 price_) public {
        require(projects[project_].accept, "!project");
        projects[project_].price = price_;
    }

    function addPool(address[] memory projects_, uint256[] memory leverages_, uint256[] memory corrs_) external {
        uint256 _length = projects_.length;
        require(_length == leverages_.length, "!leverages");
        require(_length * (_length - 1) / 2 == corrs_.length, "!corrs");

        uint256 _corrID = 0;
        uint256 _classID = ++globalClassID;
        address[] storage _projectClass = projectClasses[_classID];
        for (uint256 _pid = 0; _pid < _length; ++_pid) {
            address _project = projects_[_pid];
            require(0 == projects[_project].classID, "!project");
            _projectClass.push(_project);
            ProjectConfig memory _projectConfig = ProjectConfig({
                accept: true,
                classID: _classID,
                payFactor: maxPayFactor,
                leverageFactor: leverages_[_pid],
                price: 0,
                pay: 0
            });

            projects[_project] = _projectConfig;
            correlations[_project][_project] = 10000;
            for (uint256 _pid2 = _pid + 1; _pid2 < _length; ++_pid2) {
                address _project2 = projects_[_pid2];
                (address _projectA, address _projectB) = _project < _project2 ? (_project, _project2) : (_project2, _project);
                correlations[_projectA][_projectB] = corrs_[_corrID++] * 2;
            }
        }
    }

    function addProject(uint256 classID_, address project_, uint256 leverage_, uint256 price_, uint256 pay_, uint256[] memory corrs_) external {
        require(classID_ <=  globalClassID, "!classID_");
        require(0 == projects[project_].classID, "!project");
        uint256 _length = projectClasses[classID_].length;
        require(_length == corrs_.length, "!corrs");

        projectClasses[classID_].push(project_);
        ProjectConfig memory _projectConfig = ProjectConfig({
            accept: true,
            classID: classID_,
            payFactor: maxPayFactor,
            leverageFactor: leverage_,
            price: price_,
            pay: pay_
        });
        projects[project_] = _projectConfig;

        correlations[project_][project_] = 10000;

        uint256 _corrID = 0;
        for (uint256 _pid = 0; _pid < _length; ++_pid) {
            address _project2 = projectClasses[classID_][_pid];
            (address _projectA, address _projectB) = project_ < _project2 ? (project_, _project2) : (_project2, project_);
            correlations[_projectA][_projectB] = corrs_[_corrID++] * 2;
        }
    }

    function newPool(address project_, uint256 leverage_, uint256 price_, uint256 pay_) external {
        uint256 _classID = ++globalClassID;
        require(0 == projects[project_].classID, "!project");

        projectClasses[_classID].push(project_);
        ProjectConfig memory _projectConfig = ProjectConfig({
            accept: true,
            classID: _classID,
            payFactor: maxPayFactor,
            leverageFactor: leverage_,
            price: price_,
            pay: pay_
        });
        projects[project_] = _projectConfig;
        correlations[project_][project_] = 10000;
    }
}
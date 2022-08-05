/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15.0;

contract Crowdfund{

address internal owner;
uint internal projectCount = 0;
uint256 internal transactionId = 0; 

struct Project{
	uint projectId;
	string projectName;
	string description;
	uint status;
	uint targetAmount;
	uint withdrawalSpan;
	uint investorCount;
	uint minimumLimit;
	address creator;
	uint closingDate;
	uint investedAmount;
	uint createDate;
}

enum ProjectState {
    closed, //0
    partiallyClosed, //1
    open, //2
    withdrawn //3
  }

struct InvestmentDetail{
	uint investedAmount;
    uint investedDate;
    }

struct InvestedProjectDetail{
    uint investmentId;
    uint projectId;
    string projectName;
    uint investedAmount;
    uint investedDate;
    uint projectWithdrawalSpan;
    uint projectCreateDate;
}

modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }

constructor () {     // solhint-disable-line
    owner = msg.sender;
}


mapping (uint => Project) internal projects;
mapping(address => uint) internal ownProjectsCount;
mapping(uint => mapping(address => mapping(uint => InvestedProjectDetail))) internal investmentDetails;
mapping(uint => mapping(address => uint)) internal investorInvestmentCount;
mapping(uint => address) internal lastInvestorAddress;
mapping(address => mapping(uint => InvestedProjectDetail)) internal investedProjects;
mapping(address => uint) internal investedProjectsCount;

event TransactionHistory(uint transactionId, uint projectId, string projectName, address investor, string transType, uint amount, uint transDate); 

Project[] internal creatorProjects;

	function createProject(string memory _projectName, string memory _description, uint _targetAmount, uint _withdrawalSpan, uint _minimumLimit, uint _closingDate) public {
		require(block.timestamp + 10 days <= _closingDate, "Closing date should be minimum 10 days more from current date."); // solhint-disable-line
		projectCount++;
		projects[projectCount] = Project(projectCount, _projectName, _description, uint(ProjectState.open), _targetAmount, _withdrawalSpan, 0, _minimumLimit, msg.sender, _closingDate, 0, block.timestamp);  // solhint-disable-line
        ownProjectsCount[msg.sender]++;
        transactionId++;
        emit TransactionHistory(transactionId, projectCount, _projectName, msg.sender, "New Project Created", 0, block.timestamp);  // solhint-disable-line
        
    }

    function listProjects() public view returns (Project[] memory) {
        uint index = 0;
        //getCount
        uint _openProjectsCount = 0;
        for(uint i=1;i<=projectCount;i++){
            if(projects[i].status == uint(ProjectState.open))
           _openProjectsCount++;
        }
        Project[] memory _openProjects = new Project[](_openProjectsCount);
        for (uint i = 1; i<=projectCount; i++) {
            if(projects[i].status == uint(ProjectState.open))
                _openProjects[index++] = projects[i];
            
        }
        return _openProjects;
    }

    function listOwnProjects() public view returns (Project[] memory){
       Project[] memory _ownProjects = new Project[](ownProjectsCount[msg.sender]);
       uint index = 0;
        for(uint i=1;i<=projectCount;i++)
            if(projects[i].creator == msg.sender)
                _ownProjects[index++] = projects[i];
    return _ownProjects;
    }

    function listInvestments() public view returns (InvestedProjectDetail[] memory){
        uint  _investedProjectsCount = investedProjectsCount[msg.sender];
        InvestedProjectDetail[] memory _investmentDetails = new InvestedProjectDetail[](_investedProjectsCount);
        for(uint i=0;i<_investedProjectsCount;i++){
            _investmentDetails[i] = investedProjects[msg.sender][i+1];
        }
        return _investmentDetails;
    }

	function getProjectDetails(uint _projectId) public  view  returns
  (
    uint projectId,
    address projectCreator,
    string memory projectTitle,
    string memory projectDescription,
    uint status,
    uint targetAmount,
    uint withdrawalSpan,
    uint investorCount,
    uint minimumLimit,
    uint closingDate,
    uint investedAmount,
    uint createDate
  ) {
      Project memory _project = projects[_projectId];
    
      projectId = _project.projectId;
      projectCreator = _project.creator;
      projectTitle = _project.projectName;
      projectDescription = _project.description;
      status = _project.status;
      targetAmount = _project.targetAmount;
      withdrawalSpan = _project.withdrawalSpan;
      investorCount = _project.investorCount;
      minimumLimit = _project.minimumLimit;
      closingDate = _project.closingDate;
      investedAmount = _project.investedAmount;
      createDate = _project.createDate;
  }

	function invest(uint _projectId) external payable{
        closeProject();
        uint _amount = (msg.value/1000000000000000000);
        Project storage _project = projects[_projectId];
		require(_project.status == uint(ProjectState.open), "This project has been closed already!");
        require(block.timestamp <= _project.closingDate, "This project has been closed already!");  // solhint-disable-line
        require(_amount >= _project.minimumLimit, "Amount should be greater than or equal to minimum limit of project");
        uint _investmentCount = 0;
        _project.investedAmount += _amount;
        if(investorInvestmentCount[_projectId][msg.sender] == 0)        
            _project.investorCount++;
        uint _investorInvestmentCount = investorInvestmentCount[_projectId][msg.sender] += 1;
        _investmentCount = ++investedProjectsCount[msg.sender];
        uint _currentDate = block.timestamp;  // solhint-disable-line
		investmentDetails[_projectId][msg.sender][_investorInvestmentCount] = InvestedProjectDetail(_investorInvestmentCount, _projectId, _project.projectName, _amount, _currentDate, _project.withdrawalSpan, _project.createDate);
        lastInvestorAddress[_projectId] = msg.sender;
        investedProjects[msg.sender][_investmentCount] = InvestedProjectDetail(_investmentCount, _projectId, _project.projectName, _amount, _currentDate, _project.withdrawalSpan, _project.createDate); //Saving to invested Projects map of user.
        transactionId++;
        emit TransactionHistory(transactionId, _project.projectId, _project.projectName, msg.sender, "Investment", _amount, investmentDetails[_projectId][msg.sender][_investmentCount].investedDate);
		if(_project.investedAmount >= _project.targetAmount){
			_project.status = uint(ProjectState.partiallyClosed);  //Partially closing project
            transactionId++;
            emit TransactionHistory(transactionId++, _projectId, _project.projectName, _project.creator, "Partially Closed", _project.investedAmount, block.timestamp);  // solhint-disable-line
		}
    }

    function investorWithdrawAmount(uint _investmentId) public {
       uint _investedProjectsCount = investedProjectsCount[msg.sender];
       uint _investedId = 0;
        for(uint i=1;i<=_investedProjectsCount; i++){
            if(investedProjects[msg.sender][i].investmentId == _investmentId){
                _investedId = i;
                break;
            }
        }
        require(_investedId != 0, "Investment Not Found!");
        InvestedProjectDetail storage _investedProject = investedProjects[msg.sender][_investedId];
        require(_investedProject.investedAmount != 0, "Investment Amount is 0!");
        Project storage _project = projects[_investedProject.projectId];
        closeProject();
        require(_project.status != uint256(ProjectState.closed), "Cannot withdraw money. Project deadline over.");
        require(block.timestamp - _investedProject.investedDate <= _project.withdrawalSpan * 1 days, "Cannot withdraw money. Withdrawal time limit exceeded!");  // solhint-disable-line
        uint _investorInvestmentCount = --investorInvestmentCount[_project.projectId][msg.sender];
        investmentDetails[_investedProject.projectId][msg.sender][_investorInvestmentCount+1].investedAmount = 0;

        _project.investedAmount -= _investedProject.investedAmount;
        transactionId++;
        emit TransactionHistory(
            transactionId,
            _project.projectId,
            _project.projectName,
            msg.sender,
            "Investor Withdrew",
            _investedProject.investedAmount,
            block.timestamp  // solhint-disable-line
        ); 
        uint _transferAmount = (_investedProject.investedAmount*1000000000000000000);
        address payable investor = payable(msg.sender);
        investor.transfer(_transferAmount);
        _investedProject.investedAmount = 0;
        
        if(_investorInvestmentCount == 0)
            _project.investorCount--;
        if (_project.investedAmount < _project.targetAmount) {
            _project.status = uint256(ProjectState.open); //Reopening project in-case invested amount has come below target amount.
            transactionId++;
            emit TransactionHistory(transactionId,
            _project.projectId,
            _project.projectName,
            msg.sender,
            "Project Re-opened",
            0,
            block.timestamp // solhint-disable-line
        );        
        }
    }

    function creatorWithdrawAmount(uint _projectId) external {
        Project storage _project = projects[_projectId];
        require(_project.status != uint(ProjectState.withdrawn), "Amount has been withdrawn from this project already");
        require( _project.creator == msg.sender,"Only creator can withdraw fund.");
		require(_project.investedAmount > 0, "No amount invested in the project to withdraw.");
        address lastInvestedAddress = lastInvestorAddress[_projectId];
        uint lastInvestmentCount = investorInvestmentCount[_projectId][lastInvestedAddress];
        uint lastInvestedDate = investmentDetails[_projectId][lastInvestedAddress][lastInvestmentCount].investedDate;
        require((_project.investedAmount >= _project.targetAmount && block.timestamp - lastInvestedDate >= _project.withdrawalSpan * 1 days)  // solhint-disable-line 
        || block.timestamp > _project.closingDate, "Cannot withdraw money. Project has not been closed yet."); // solhint-disable-line
        uint _transferAmount = (_project.investedAmount*1000000000000000000);
        address payable creator = payable(msg.sender);
        creator.transfer(_transferAmount);
        transactionId++;
        emit TransactionHistory(transactionId, _project.projectId, _project.projectName, msg.sender, "Creator Withdrew", _project.investedAmount, block.timestamp);  // solhint-disable-line
		_project.investedAmount = 0;
		_project.status = uint(ProjectState.withdrawn); //Project state set to withdrawn
    }

    function checkCreatorProjectWithdrawalSpan(uint256 _projectId)
        public
        view
        returns (bool)
    {
        Project storage _project = projects[_projectId];
        address lastInvestedAddress = lastInvestorAddress[_projectId];
        uint256 lastInvestmentCount = investorInvestmentCount[_projectId][
            lastInvestedAddress
        ];
        uint256 lastInvestedDate = investmentDetails[_projectId][
            lastInvestedAddress
        ][lastInvestmentCount].investedDate;
        if(_project.status == uint(ProjectState.withdrawn))
            return false;
        if (
            (block.timestamp - lastInvestedDate >=     // solhint-disable-line
                _project.withdrawalSpan * 1 days &&
                _project.status == uint(ProjectState.partiallyClosed)) ||
            block.timestamp > _project.closingDate     // solhint-disable-line
        ) return true;
        //withdrawal span over
        else return false;
    }

    function findBalance() external view returns (uint){
        return msg.sender.balance;
    }

    function findContractBalance() external onlyOwner view returns (uint) {
        return address(this).balance;
    }

    function closeProject() public {
        Project[] memory _openProjects = listProjects();
        for(uint i=0;i<_openProjects.length;i++)
            if(_openProjects[i].closingDate <= block.timestamp){     // solhint-disable-line
                projects[_openProjects[i].projectId].status = uint(ProjectState.closed);
                transactionId++;
                  emit TransactionHistory(transactionId, _openProjects[i].projectId, _openProjects[i].projectName, _openProjects[i].creator, "Project Fully Closed", _openProjects[i].investedAmount, block.timestamp);     // solhint-disable-line
            }
    }

} //end
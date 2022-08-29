// SPDX-License-Identifier: ISC

pragma solidity 0.8.16;

contract BaseFundFactory {
  BaseFund[] public deployedBaseFunds;

  function getDeployedBaseFunds() public view returns (BaseFund[] memory) {
    return deployedBaseFunds;
  }

  function createBaseFund(
    string memory _name,
    string memory _description,
    address[] memory _managers,
    bool _newManagersCanBeAdded,
    bool _managersCanTransferMoneyWithoutARequest,
    bool _onlyManagersCanCreateARequest,
    bool _onlyContributorsCanApproveARequest,
    uint256 _minimumContributionPercentageRequired,
    uint256 _minimumApprovalsPercentageRequired
  ) public {
    require(_minimumContributionPercentageRequired < 101, "Incorrect contribution percentage");
    require(_minimumApprovalsPercentageRequired < 101, "Incorrect approvals percentage");

    BaseFund newBaseFund = new BaseFund(
      _name,
      _description,
      _managers,
      _newManagersCanBeAdded,
      _managersCanTransferMoneyWithoutARequest,
      _onlyManagersCanCreateARequest,
      _onlyContributorsCanApproveARequest,
      _minimumContributionPercentageRequired,
      _minimumApprovalsPercentageRequired
    );
    deployedBaseFunds.push(newBaseFund);
  }
}

contract BaseFund {
  struct Request {
    string description;
    address petitioner;
    address recipient;
    uint256 valueToTransfer;
    uint256 transferredValue;
    bool complete;
    mapping(address => bool) approvals;
    uint256 approvalsCount;
  }

  string public name;
  string public description;
  uint256 public createdAt = block.timestamp;

  address[] public managers;
  mapping(address => bool) public isManager;
  bool public newManagersCanBeAdded;

  address[] public contributors;
  mapping(address => uint256) public contributions;
  uint256 public totalContributions;

  bool public managersCanTransferMoneyWithoutARequest;

  Request[] public requests;
  bool public onlyManagersCanCreateARequest;
  bool public onlyContributorsCanApproveARequest;
  uint256 public minimumContributionPercentageRequired;
  uint256 public minimumApprovalsPercentageRequired;

  event NewBaseFund(string name, string description);

  event NewManager(address indexed manager);

  event Contribute(address indexed contributor, uint256 value);

  event Transfer(address indexed sender, address indexed to, uint256 value);

  event NewRequest(string description, address indexed petitioner, address indexed recipient, uint256 valueToTransfer);

  event ApproveRequest(uint256 requestIndex, address indexed approver);

  event FinalizeRequest(uint256 requestIndex, uint256 transferredValue);

  modifier onlyManagers() {
    require(isManager[msg.sender], "Only managers can access");
    _;
  }

  modifier notManagers() {
    require(!isManager[msg.sender], "Managers can not access");
    _;
  }

  constructor(
    string memory _name,
    string memory _description,
    address[] memory _managers,
    bool _newManagersCanBeAdded,
    bool _managersCanTransferMoneyWithoutARequest,
    bool _onlyManagersCanCreateARequest,
    bool _onlyContributorsCanApproveARequest,
    uint256 _minimumContributionPercentageRequired,
    uint256 _minimumApprovalsPercentageRequired
  ) {
    name = _name;
    description = _description;
    _addManagers(_managers);
    newManagersCanBeAdded = _newManagersCanBeAdded;
    managersCanTransferMoneyWithoutARequest = _managersCanTransferMoneyWithoutARequest;
    onlyManagersCanCreateARequest = _onlyManagersCanCreateARequest;
    onlyContributorsCanApproveARequest = _onlyContributorsCanApproveARequest;
    minimumContributionPercentageRequired = _minimumContributionPercentageRequired;
    minimumApprovalsPercentageRequired = _minimumApprovalsPercentageRequired;

    emit NewBaseFund(_name, _description);
  }

  function addNewManagers(address[] memory _managers) public {
    require(newManagersCanBeAdded, "New managers can not be added");

    _addManagers(_managers);
  }

  function managersCount() public view returns (uint256) {
    return managers.length;
  }

  function contribute() public payable {
    _contribute(msg.sender);
  }

  function contributeFor(address _for) public payable {
    _contribute(_for);
  }

  function contributorsCount() public view returns (uint256) {
    return contributors.length;
  }

  function balance() public view returns (uint256) {
    return address(this).balance;
  }

  function transfer(address _to, uint256 _value) public {
    require(managersCanTransferMoneyWithoutARequest, "Managers can not transfer money without a request");
    require(isManager[msg.sender], "Only managers can access");

    payable(_to).transfer(_value);

    emit Transfer(msg.sender, _to, _value);
  }

  function createRequest(
    string memory _description,
    address _recipient,
    uint256 _valueToTransfer
  ) public {
    bool _isManager = isManager[msg.sender];

    require(
      !onlyManagersCanCreateARequest || (onlyManagersCanCreateARequest && _isManager),
      "Only managers can create a request"
    );

    Request storage newRequest = requests.push();

    newRequest.description = _description;
    newRequest.petitioner = msg.sender;
    newRequest.recipient = _recipient;
    newRequest.valueToTransfer = _valueToTransfer;

    emit NewRequest(_description, msg.sender, _recipient, _valueToTransfer);
  }

  function requestsCount() public view returns (uint256) {
    return requests.length;
  }

  function approveRequest(uint256 _index) public {
    Request storage request = requests[_index];

    require(!request.complete, "The request has already been completed");
    require(
      (contributions[msg.sender] / totalContributions) * 100 >= minimumContributionPercentageRequired ||
        (!onlyContributorsCanApproveARequest && isManager[msg.sender]),
      "You can not approve a request"
    );
    require(!request.approvals[msg.sender], "You have already approved this request");

    request.approvals[msg.sender] = true;
    request.approvalsCount++;

    emit ApproveRequest(_index, msg.sender);
  }

  function finalizeRequest(uint256 _index) public {
    Request storage request = requests[_index];

    require(request.petitioner == msg.sender, "You are not the petitioner of the request");
    require(!request.complete, "The request has already been completed");
    if (onlyContributorsCanApproveARequest) {
      require(
        (request.approvalsCount / contributorsCount()) * 100 >= minimumApprovalsPercentageRequired,
        "The request has not been approved yet"
      );
    } else {
      require(
        (request.approvalsCount / (managersCount() + contributorsCount())) * 100 >= minimumApprovalsPercentageRequired,
        "The request has not been approved yet"
      );
    }

    uint256 _valueToTransfer = request.valueToTransfer;
    if (_valueToTransfer > balance()) {
      _valueToTransfer = balance();
    }

    payable(request.recipient).transfer(_valueToTransfer);
    request.transferredValue = _valueToTransfer;
    request.complete = true;

    emit FinalizeRequest(_index, _valueToTransfer);
  }

  function _addManagers(address[] memory _managers) private {
    for (uint256 i; i < _managers.length; ) {
      if (!isManager[msg.sender]) {
        managers.push(_managers[i]);
        isManager[_managers[i]] = true;

        emit NewManager(_managers[i]);
      }

      unchecked {
        i++;
      }
    }
  }

  function _contribute(address _contributor) private {
    require(msg.value > 0, "The contribution must be greater than zero");

    if (contributions[_contributor] == 0) {
      contributors.push(_contributor);
    }
    contributions[_contributor] += msg.value;
    totalContributions += msg.value;

    emit Contribute(_contributor, msg.value);
  }
}
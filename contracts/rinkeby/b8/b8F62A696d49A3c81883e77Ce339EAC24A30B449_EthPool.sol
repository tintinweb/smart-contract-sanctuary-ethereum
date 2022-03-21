pragma solidity ^0.8.0;

import "./AccessControl.sol";

struct DepositStatus {
  uint256 value;
  bool    hasValue;
}

contract EthPool is AccessControl {
  
  bytes32 public constant TEAM_ROLE = keccak256("TEAM_MEMBERS");

  uint public totalValue;
  address[] public users;
  mapping(address => DepositStatus) public status;

  modifier onlyTeam() {
    require(hasRole(TEAM_ROLE, msg.sender), "No team members");
    _;
  }

  event Deposit(address indexed account, uint value);
  event Withdraw(address indexed account, uint value);

  constructor() {
    _setupRole(TEAM_ROLE, msg.sender);
  }

  function addTeam(address account) public {
    grantRole(TEAM_ROLE, account);
  }

  function removeTeam(address account) public {
    revokeRole(TEAM_ROLE, account);
  }

  receive() external payable {    

    if (!status[msg.sender].hasValue)
      users.push(msg.sender);

    status[msg.sender].value += msg.value;
    status[msg.sender].hasValue = true;

    totalValue += msg.value;
    emit Deposit(msg.sender, msg.value);
  }

  function depositeRewards() public payable onlyTeam {
    require(totalValue > 0, "No rewards if the pool is empty");

    for (uint i=0; i<users.length; i++) {
      address user = users[i];
      uint rewards = ((status[user].value * msg.value) / totalValue);

      status[user].value += rewards;
    }
  }

  function withdraw() public payable {
    uint deposit = status[msg.sender].value;
    require(deposit > 0, "No withdrawal value");

    status[msg.sender].value = 0;
    (bool success, ) = msg.sender.call{value:deposit}("");

    require(success, "Transfer failed");
    emit Withdraw(msg.sender, deposit);
  }

}
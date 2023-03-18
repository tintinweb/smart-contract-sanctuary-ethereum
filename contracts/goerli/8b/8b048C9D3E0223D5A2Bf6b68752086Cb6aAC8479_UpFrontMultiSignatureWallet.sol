/**
 *Submitted for verification at Etherscan.io on 2023-03-18
*/

// SPDX-License-Identifier: MIT

/*

   __  __      ______                 __ 
  / / / /___  / ____/________  ____  / /_
 / / / / __ \/ /_  / ___/ __ \/ __ \/ __/
/ /_/ / /_/ / __/ / /  / /_/ / / / / /_  
\____/ .___/_/   /_/   \____/_/ /_/\__/  
    /_/                                  

UpFront
Multi-Signature Wallet

  Author: dotfx
  Date: 2023/03/18
  Version: 1.0.0

*/

pragma solidity >=0.8.18 <0.9.0;

library Address {
  function isContract(address _contract) internal view returns (bool) {
    return _contract.code.length > 0;
  }
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    _setOwner(_msgSender());
  }

  function owner() external view virtual returns (address) {
    return _owner;
  }

  modifier isOwner() {
    require(_owner == _msgSender(), "Caller must be the owner.");

    _;
  }

  function renounceOwnership() external virtual isOwner {
    _setOwner(address(0));
  }

  function transferOwnership(address newOwner) external virtual isOwner {
    require(newOwner != address(0));

    _setOwner(newOwner);
  }

  function _setOwner(address newOwner) internal {
    address oldOwner = _owner;
    _owner = newOwner;

    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

abstract contract ReentrancyGuard is Ownable {
  bool internal locked;

  modifier nonReEntrant() {
    require(!locked, "No re-entrancy.");

    locked = true;
    _;
    locked = false;
  }
}

contract UpFrontMultiSignatureWallet is ReentrancyGuard {
  uint256 public voteProposalDeadline = 5 days;
  uint256 public voteProposalThreshold = 3;
  address public voteProposalExecutor;
  bool private initialized;

  struct ownedContractDataStruct {
    bool exists;
    bool active;
    address target;
    string nickname;
  }

  struct managerDataStruct {
    bool exists;
    bool active;
    address addr;
    string nickname;
  }

  struct delegateDataStruct {
    bool exists;
    address addr;
    delegateRelationDataStruct[] relation;
  }

  struct delegateRelationDataStruct {
    uint256 timestamp;
    address manager;
    bool active;
  }

  struct proposalDataStruct {
    bool exists;
    bool active;
    uint256 timestamp;
    uint256 approved;
    uint256 denied;
    uint256 executed;
    address creator;
    string subject;
    string description;
    string canceled;
    address[] target;
    bytes[] data;
    bytes[] response;
    uint8 agreed;
    signedProposalDataStruct[] signed;
  }

  struct signedProposalDataStruct {
    uint256 timestamp;
    address manager;
    address signer;
    bool agreed;
  }

  address[] private managerList;
  mapping(address => managerDataStruct) private managerData;

  address[] private delegateList;
  mapping(address => delegateDataStruct) private delegateData;

  address[] private ownedContractList;
  mapping(address => ownedContractDataStruct) private ownedContractData;

  uint256[] private proposalList;
  mapping(uint256 => proposalDataStruct) private proposalData;

  event addedManager(address indexed manager, string nickname);
  event revokedManager(address indexed manager);
  event addedDelegate(address indexed manager, address delegate);
  event revokedDelegate(address indexed manager, address delegate);
  event SubmittedProposal(uint256 indexed id, address indexed creator);
  event CanceledProposal(uint256 indexed id, string reason);
  event ApprovedProposal(uint256 indexed id, uint8 agreed, uint256 total);
  event DeniedProposal(uint256 indexed id, uint8 agreed, uint256 total);
  event SignedProposal(uint256 indexed id, address indexed manager, address signer, bool agreed);
  event ExecutedProposal(uint256 indexed id, address executor);

  modifier isSelf() {
    if (initialized) { require(msg.sender == address(this), "Caller must be internal."); }

    _;
  }

  modifier isManager() {
    bool proceed;

    if (managerData[msg.sender].exists) {
      managerDataStruct memory data = managerData[msg.sender];

      if (data.active) { proceed = true; }
    }

    require(proceed, "Caller must be manager.");

    _;
  }

  modifier isExecutor() {
    require(msg.sender == voteProposalExecutor, "Caller must be executor.");

    _;
  }

  modifier isProposal(uint256 id, bool activeOnly) {
    require(proposalData[id].exists, "Unknown proposal.");

    if (activeOnly) { require(proposalData[id].active, "Proposal has been canceled."); }

    _;
  }

  modifier isExecuted(uint256 id, bool executed) {
    if (executed) {
      require(proposalData[id].executed > 0, "Proposal not yet executed.");
    } else {
      require(proposalData[id].executed == 0, "Proposal already executed.");
    }

    _;
  }

  modifier isApproved(uint256 id, bool approved) {
    if (approved) {
      require(proposalData[id].approved > 0, "Proposal not yet approved.");
    } else {
      require(proposalData[id].approved == 0, "Proposal already approved.");
    }

    _;
  }

  constructor(address[] memory _managers) {
    require(_managers.length >= voteProposalThreshold + 1, "Minimum manager threshold not reached.");

    uint256 mcnt = _managers.length;

    unchecked {
      for (uint256 m; m < mcnt; m++) {
        address manager = _managers[m];

        require(manager != address(0), "Invalid manager.");
        require(!Address.isContract(manager), "Invalid manager.");
        require(!managerData[manager].exists, "Manager already exists.");

        adminAddManager(manager, "");
      }
    }

    setOwnedContract(address(this), "Multi-Signature Wallet");

    proposalList.push(0);
    proposalData[0].exists = false;

    initialized = true;
  }

  function adminSetVoteProposalDeadline(uint256 _deadline) public isSelf {
    require(_deadline >= 1 days, "Deadline cannot be less than 1 day.");

    voteProposalDeadline = _deadline;
  }

  function adminSetVoteProposalThreshold(uint256 _threshold) public isSelf {
    require(_threshold >= managerList.length + 1, "Minimum manager threshold not reached.");

    voteProposalThreshold = _threshold;
  }

  function adminSetExecutor(address _addr) public isSelf {
    require(_addr != address(0));
    require(_addr != address(this));

    bool proceed;
    uint256 mcnt = managerList.length;

    unchecked {
      for (uint256 m; m < mcnt; m++) {
        if (managerList[m] != _addr) { continue; }

        proceed = true;
      }
    }

    require(proceed, "Executor cannot be a manager.");

    voteProposalExecutor = _addr;
  }

  function adminAddManager(address _manager, string memory _nickname) public isSelf {
    if (!managerData[_manager].exists) {
      managerList.push(_manager);
      managerData[_manager].exists = true;
      managerData[_manager].addr = _manager;
    }

    managerData[_manager].active = true;
    managerData[_manager].nickname = _nickname;

    emit addedManager(_manager, _nickname);
  }

  function adminRevokeManager(address _manager) public isSelf {
    require(managerData[_manager].exists, "Unknown manager.");
    require(managerList.length >= voteProposalThreshold, "Minimum manager threshold not reached.");

    managerData[_manager].active = false;

    uint256 pcnt = proposalList.length;

    if (pcnt > 0) {
      unchecked {
        for (uint256 p; p < pcnt; p++) {
          proposalDataStruct memory proposal = proposalData[p];

          if (proposal.creator != _manager) { continue; }
          if (proposal.executed > 0) { continue; }

          proposalData[p].active = false;
        }
      }
    }

    emit revokedManager(_manager);
  }

  function getCurrentTime() internal view returns (uint256) {
    return block.timestamp;
  }

  function setOwnedContract(address _contract, string memory _nickname) public isManager {
    require(_contract != address(0));

    if (_contract != address(this)) { require(Address.isContract(_contract), "Not a contract."); }

    if (!ownedContractData[_contract].exists) {
      ownedContractList.push(_contract);
      ownedContractData[_contract].exists = true;
      ownedContractData[_contract].target = _contract;
    }

    ownedContractData[_contract].nickname = _nickname;
  }

  function getProposal(uint256 _id) public view isManager isProposal(_id, false) returns (proposalDataStruct memory) {
    proposalDataStruct memory proposal = proposalData[_id];

    return proposal;
  }

  function cancelProposal(uint256 _id, string memory _reason) public isManager isProposal(_id, true) isApproved(_id, false) {
    require(proposalData[_id].exists, "Unknown proposal.");

    proposalDataStruct memory proposal = proposalData[_id];

    require(proposal.creator == msg.sender, "Not this proposal's creator.");

    proposalData[_id].active = false;
    proposalData[_id].canceled = _reason;

    emit CanceledProposal(_id, _reason);
  }

  function hasSignedProposal(uint256 _id, address _manager) public view isProposal(_id, false) returns (bool) {
    require(managerData[_manager].exists, "Unknown manager.");

    proposalDataStruct memory proposal = proposalData[_id];
    uint256 cnt = proposal.signed.length;

    if (cnt == 0) { return false; }

    unchecked {
      for (uint256 a; a < cnt; a++) {
        signedProposalDataStruct memory signed = proposal.signed[a];

        if (signed.manager == _manager) { return true; }
      }
    }

    return false;
  }

  function signProposal(uint256 _id, address _manager, bool agree) public isProposal(_id, true) isApproved(_id, false) {
    proposalDataStruct memory proposal = proposalData[_id];

    if (_manager == address(0)) { _manager = msg.sender; }

    require(managerData[_manager].exists && managerData[_manager].active, "Unknown manager.");
    require(proposal.creator != _manager, "Creator of the proposal or its delegate cannot vote.");
    require(proposal.timestamp + voteProposalDeadline > getCurrentTime(), "Voting deadline has expired.");

    if (hasSignedProposal(_id, _manager)) { revert("You or your delegate have already signed."); }

    if (_manager == msg.sender) {
      require(managerData[msg.sender].exists && managerData[msg.sender].active, "Unknown manager.");
    } else {
      address delegate = getManagerDelegate(_manager);

      require(delegate == msg.sender, "Not authorized to sign.");
    }

    proposalData[_id].signed.push(signedProposalDataStruct(getCurrentTime(), _manager, msg.sender, agree));

    emit SignedProposal(_id, _manager, msg.sender, agree);

    if (agree) {
      proposalData[_id].agreed++;

      if (proposalData[_id].agreed == voteProposalThreshold) {
        proposalData[_id].approved = getCurrentTime();

        emit ApprovedProposal(_id, proposalData[_id].agreed, proposalData[_id].signed.length);
      }
    } else {
      if (proposalData[_id].signed.length == _countActiveManagers() - 1) {
        proposalData[_id].active = false;
        proposalData[_id].denied = getCurrentTime();

        emit DeniedProposal(_id, proposalData[_id].agreed, proposalData[_id].signed.length);
      }
    }
  }

  function submitProposal(address[] memory _contract, string memory _subject, string memory _description, bytes[] memory _data) public isManager returns (uint256) {
    require(_contract.length == _data.length, "Invalid number of calls.");

    uint256 cnt = _contract.length;

    unchecked {
      for (uint256 c; c < cnt; c++) { require(ownedContractData[_contract[c]].exists, "Unknown contract."); }
    }

    uint256 id = proposalList.length;

    proposalList.push(id);
    proposalData[id].exists = true;
    proposalData[id].active = true;
    proposalData[id].timestamp = getCurrentTime();
    proposalData[id].creator = msg.sender;
    proposalData[id].subject = _subject;
    proposalData[id].description = _description;
    proposalData[id].target = _contract;
    proposalData[id].data = _data;

    emit SubmittedProposal(id, msg.sender);

    return id;
  }

  function manualExecuteProposal(uint256 _id) public isManager isProposal(_id, true) isApproved(_id, true) isExecuted(_id, false) returns (bytes[] memory) {
    return _executeProposal(_id);
  }

  function autoExecuteProposal(uint256 _id) public isExecutor isProposal(_id, true) isApproved(_id, true) isExecuted(_id, false) returns (bytes[] memory) {
    return _executeProposal(_id);
  }

  function _executeProposal(uint256 _id) internal nonReEntrant returns (bytes[] memory) {
    proposalDataStruct memory proposal = proposalData[_id];

    uint256 cnt = proposal.data.length;
    bytes[] memory results = new bytes[](cnt);

    unchecked {
      for (uint256 i; i < cnt; i++) {
        (bool success, bytes memory result) = proposal.target[i].call{ value: 0 }(proposal.data[i]);

        if (!success) {
          if (result.length > 0) {
            assembly {
              let size := mload(result)

              revert(add(32, result), size)
            }
          } else {
            revert("Function call reverted.");
          }
        }

        results[i] = result;
      }
    }

    proposalData[_id].executed = getCurrentTime();
    proposalData[_id].response = results;

    emit ExecutedProposal(_id, _msgSender());

    return results;
  }

  function setManagerNickname(string memory _nickname) public {
    require(managerData[msg.sender].exists && managerData[msg.sender].active, "Unknown manager.");

    managerData[msg.sender].nickname = _nickname;
  }

  function setManagerDelegate(address _delegate, bool _active) public isManager {
    require(_delegate != address(0));
    require(_delegate != msg.sender, "Cannot delegate to yourself.");

    if (_active) {
      address delegate = getManagerDelegate(msg.sender);

      require(delegate != _delegate, "Delegate already active.");
      require(delegate == address(0), "You can only have one active delegate.");
    } else {
      require(delegateData[_delegate].exists, "Unknown delegate address.");
    }

    if (delegateData[_delegate].exists) {
      uint256 rcnt = delegateData[_delegate].relation.length;

      unchecked {
        for (uint256 r; r < rcnt; r++) {
          delegateRelationDataStruct memory relation = delegateData[_delegate].relation[r];

          if (relation.manager != msg.sender) { continue; }

          if (!_active && !relation.active) { revert("Delegate already inactive."); }

          delegateData[_delegate].relation[r].active = _active;
          break;
        }
      }
    } else {
      delegateList.push(_delegate);
      delegateData[_delegate].exists = true;
      delegateData[_delegate].addr = _delegate;
      delegateData[_delegate].relation.push(delegateRelationDataStruct(getCurrentTime(), msg.sender, _active));
    }

    if (_active) {
      emit addedDelegate(msg.sender, _delegate);
    } else {
      emit revokedDelegate(msg.sender, _delegate);
    }
  }

  function getManagerDelegate(address _manager) public view returns (address) {
    require(managerData[_manager].exists, "Unknown manager.");

    address delegate;
    uint256 dcnt = delegateList.length;

    if (dcnt == 0) { return delegate; }

    unchecked {
      for (uint256 d; d < dcnt; d++) {
        uint256 rcnt = delegateData[delegateList[d]].relation.length;

        for (uint256 r; r < rcnt; r++) {
          delegateRelationDataStruct memory relation = delegateData[delegateList[d]].relation[r];

          if (relation.manager != _manager) { continue; }
          if (!relation.active) { continue; }

          delegate = delegateList[d];
          break;
        }
      }
    }

    return delegate;
  }

  function listManagers(bool _activeOnly) public view returns (managerDataStruct[] memory) {
    uint256 cnt = _activeOnly ? _countActiveManagers() : managerList.length;

    managerDataStruct[] memory data = new managerDataStruct[](cnt);

    unchecked {
      for (uint256 m; m < cnt; m++) {
        if (_activeOnly && !managerData[managerList[m]].active) { continue; }

        data[m] = managerData[managerList[m]];
      }
    }

    return data;
  }

  function listOwnedContracts() public view isManager returns (ownedContractDataStruct[] memory) {
    uint256 cnt = ownedContractList.length;

    ownedContractDataStruct[] memory data = new ownedContractDataStruct[](cnt);

    unchecked {
      for (uint256 c; c < cnt; c++) { data[c] = ownedContractData[ownedContractList[c]]; }
    }

    return data;
  }

  function listProposals() public view isManager returns (proposalDataStruct[] memory) {
    uint256 cnt = proposalList.length;

    proposalDataStruct[] memory data = new proposalDataStruct[](cnt);

    unchecked {
      for (uint256 p; p < cnt; p++) { data[p] = proposalData[p]; }
    }

    return data;
  }

  function _countActiveManagers() internal view returns (uint256) {
    uint256 cnt = managerList.length;
    uint256 active;

    unchecked {
      for (uint256 m; m < cnt; m++) {
        if (managerData[managerList[m]].active) { active++; }
      }
    }

    return active;
  }
}
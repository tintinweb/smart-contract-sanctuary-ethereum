/**
 *Submitted for verification at Etherscan.io on 2023-03-17
*/

// SPDX-License-Identifier: MIT

/*

   __  __      ______                 __ 
  / / / /___  / ____/________  ____  / /_
 / / / / __ \/ /_  / ___/ __ \/ __ \/ __/
/ /_/ / /_/ / __/ / /  / /_/ / / / / /_  
\____/ .___/_/   /_/   \____/_/ /_/\__/  
    /_/                                  

UpFront Multi-Signature Wallet

*/

pragma solidity >=0.8.18 <0.9.0;

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
}

library Address {
  function isContract(address _contract) internal view returns (bool) {
    return _contract.code.length > 0;
  }
}

library Strings {
  function equal(string memory a, string memory b) internal pure returns (bool) {
    return keccak256(bytes(a)) == keccak256(bytes(b));
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

  function resetLocked() public isOwner {
    locked = false;
  }
}

contract UpFrontMultiSignatureWallet is ReentrancyGuard {
  uint256 public voteProposalDeadline = 5 days;
  uint256 public voteProposalThreshold = 3;
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
    bool executed;
    uint256 timestamp;
    address creator;
    string subject;
    string description;
    address target;
    bytes data;
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

  event SubmittedProposal(uint256 indexed id, address indexed creator, address indexed target, bytes data);
  event CancelledProposal(uint256 indexed id);
  event ApprovedProposal(uint256 indexed id, uint8 agreed, uint256 total);
  event DeniedProposal(uint256 indexed id, uint8 agreed, uint256 total);
  event SignedProposal(uint256 indexed id, address indexed manager, address signer, bool agreed);
  event ExecutedProposal(uint256 indexed id, address manager);
  event Withdrawn(address indexed to, uint256 amount, address executor);

  modifier isSelf() {
    if (initialized) { require(msg.sender == address(this), "Caller must be internal."); }

    _;
  }

  modifier isManager() {
    bool proceed;

    if (managerData[_msgSender()].exists) {
      managerDataStruct memory data = managerData[_msgSender()];

      if (data.active) { proceed = true; }
    }

    require(proceed, "Caller must be manager.");

    _;
  }

  modifier isProposal(uint256 id, bool activeOnly) {
    require(proposalData[id].exists, "Unknown proposal.");

    if (activeOnly) { require(proposalData[id].active, "Proposal has been canceled."); }

    _;
  }

  modifier isExecuted(uint256 id, bool executed) {
    if (executed) {
      require(proposalData[id].executed, "Proposal not yet executed.");
    } else {
      require(!proposalData[id].executed, "Proposal already executed.");
    }

    _;
  }

  modifier isQuorum(uint256 id, bool quorum) {
    if (quorum) {
      require(proposalData[id].agreed >= voteProposalThreshold, "Proposal not yet accepted.");
    } else {
      require(proposalData[id].agreed < voteProposalThreshold, "Proposal already accepted.");
    }

    _;
  }

  constructor(address[] memory _managers) {
    require(_managers.length >= voteProposalThreshold + 1, "Minimum manager threshold is not satisfied.");

    uint256 mcnt = _managers.length;

    unchecked {
      for (uint256 m = 0; m < mcnt; m++) {
        address manager = _managers[m];

        require(manager != address(0), "Invalid manager.");
        require(!Address.isContract(manager), "Invalid manager.");
        require(!managerData[manager].exists, "Manager already exists.");

        adminSetManager(manager, "");
      }
    }

    if (!managerData[msg.sender].exists) { adminSetManager(msg.sender, ""); }

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
    require(_threshold >= managerList.length + 1, "Threshold cannot be less than the actual managers length plus one.");

    voteProposalThreshold = _threshold;
  }

  function adminSetManager(address _manager, string memory _nickname) public isSelf {
    if (!managerData[_manager].exists) {
      managerList.push(_manager);
      managerData[_manager].exists = true;
      managerData[_manager].addr = _manager;
    }

    managerData[_manager].active = true;

    if (!Strings.equal(_nickname, "")) {
      bool proceed;
      uint256 mcnt = managerList.length;

      unchecked {
        for (uint256 m = 0; m < mcnt; m++) {
          if (managerList[m] != _manager) {
            if (Strings.equal(managerData[managerList[m]].nickname, _nickname)) { break; }

            continue;
          }

          proceed = true;
        }
      }

      require(proceed, "This manager nickname already exists.");

      managerData[_manager].nickname = _nickname;
    }
  }

  function adminRevokeManager(address _manager) public isSelf {
    require(managerList.length >= voteProposalThreshold, "Minimum manager threshold is not satisfied.");
    require(managerData[_manager].exists, "Unknown manager.");

    managerData[_manager].active = false;

    uint256 pcnt = proposalList.length;

    if (pcnt > 0) {
      unchecked {
        for (uint256 p = 0; p < pcnt; p++) {
          proposalDataStruct memory proposal = proposalData[p];

          if (proposal.creator != _manager) { continue; }
          if (proposal.executed) { continue; }

          proposalData[p].active = false;
        }
      }
    }
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

    bool proceed;
    uint256 cnt = ownedContractList.length;

    unchecked {
      for (uint256 c = 0; c < cnt; c++) {
        if (ownedContractList[c] != _contract) {
          if (Strings.equal(ownedContractData[ownedContractList[c]].nickname, _nickname)) { break; }

          continue;
        }

        proceed = true;
      }
    }

    require(proceed, "This contract nickname already exists.");

    ownedContractData[_contract].nickname = _nickname;
  }

  function getProposal(uint256 _id) public view isManager isProposal(_id, false) returns (proposalDataStruct memory) {
    proposalDataStruct memory proposal = proposalData[_id];

    return proposal;
  }

  function cancelProposal(uint256 _id) public isManager isProposal(_id, true) isExecuted(_id, false) {
    require(proposalData[_id].exists, "Unknown proposal.");

    proposalDataStruct memory proposal = proposalData[_id];

    require(proposal.creator == msg.sender, "You are not the creator of this proposal.");

    proposalData[_id].active = false;

    emit CancelledProposal(_id);
  }

  function hasSignedProposal(uint256 _id, address _manager) public view isProposal(_id, false) returns (bool) {
    require(managerData[_manager].exists, "Unknown manager.");

    proposalDataStruct memory proposal = proposalData[_id];
    uint256 acnt = proposal.signed.length;

    if (acnt == 0) { return false; }

    unchecked {
      for (uint256 a = 0; a < acnt; a++) {
        signedProposalDataStruct memory signed = proposal.signed[a];

        if (signed.manager == _manager) { return true; }
      }
    }

    return false;
  }

  function signProposal(uint256 _id, address _manager, bool agree) public isProposal(_id, true) isExecuted(_id, false) isQuorum(_id, false) {
    proposalDataStruct memory proposal = proposalData[_id];

    if (_manager == address(0)) { _manager = msg.sender; }

    require(managerData[_manager].exists && managerData[_manager].active, "Unknown manager.");
    require(proposal.creator != _manager, "Creator of the proposal or its delegate cannot vote.");
    require(proposal.timestamp + voteProposalDeadline > getCurrentTime(), "Voting deadline for the proposal has expired.");

    if (hasSignedProposal(_id, _manager)) { revert("You or your delegate have already signed this proposal."); }

    if (_manager == msg.sender) {
      require(managerData[msg.sender].exists && managerData[msg.sender].active, "Unknown manager.");
    } else {
      address delegate = getManagerDelegate(_manager);

      require(delegate == msg.sender, "You are not authorized to sign this proposal.");
    }

    proposalData[_id].signed.push(signedProposalDataStruct(getCurrentTime(), _manager, msg.sender, agree));

    emit SignedProposal(_id, _manager, msg.sender, agree);

    if (agree) {
      proposalData[_id].agreed++;

      if (proposalData[_id].agreed == voteProposalThreshold) { emit ApprovedProposal(_id, proposalData[_id].agreed, proposalData[_id].signed.length); }
    } else {
      if (proposalData[_id].signed.length == managerList.length - 1) {
        proposalData[_id].active = false;

        emit DeniedProposal(_id, proposalData[_id].agreed, proposalData[_id].signed.length);
      }
    }
  }

  function submitProposal(address _contract, string memory _subject, string memory _description, bytes memory _data) public isManager returns (uint256) {
    require(ownedContractData[_contract].exists, "Unknown owned contract.");

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

    emit SubmittedProposal(id, msg.sender, _contract, _data);

    return id;
  }

  function executeProposal(uint256 _id) public isManager isProposal(_id, true) isExecuted(_id, false) isQuorum(_id, true) nonReEntrant returns (bytes memory) {
    proposalDataStruct memory proposal = proposalData[_id];

    (bool success, bytes memory response) = proposal.target.call{ value: 0 }(proposal.data);

    if (!success) {
      if (response.length > 0) {
        assembly {
          let size := mload(response)

          revert(add(32, response), size)
        }
      } else {
        revert("Function call reverted.");
      }
    }

    proposalData[_id].executed = true;

    emit ExecutedProposal(_id, msg.sender);

    return response;
  }

  function setManagerNickname(string memory _nickname) public {
    require(managerData[msg.sender].exists && managerData[msg.sender].active, "Unknown manager.");

    bool proceed;

    unchecked {
      uint256 mcnt = managerList.length;

      for (uint256 m = 0; m < mcnt; m++) {
        if (managerList[m] != msg.sender) {
          if (Strings.equal(managerData[managerList[m]].nickname, _nickname)) { break; }

          continue;
        }

        proceed = true;
      }
    }

    require(proceed, "This manager nickname already exists.");

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
        for (uint256 r = 0; r < rcnt; r++) {
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
  }

  function getManagerDelegate(address _manager) public view returns (address) {
    require(managerData[_manager].exists, "Unknown manager.");

    address delegate;
    uint256 dcnt = delegateList.length;

    if (dcnt == 0) { return delegate; }

    unchecked {
      for (uint256 d = 0; d < dcnt; d++) {
        uint256 rcnt = delegateData[delegateList[d]].relation.length;

        for (uint256 r = 0; r < rcnt; r++) {
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

  function listManagers() public view returns (managerDataStruct[] memory) {
    uint256 cnt = managerList.length;

    managerDataStruct[] memory data = new managerDataStruct[](cnt);

    unchecked {
      for (uint256 m = 0; m < cnt; m++) { data[m] = managerData[managerList[m]]; }
    }

    return data;
  }

  function listOwnedContracts() public view isManager returns (ownedContractDataStruct[] memory) {
    uint256 cnt = ownedContractList.length;

    ownedContractDataStruct[] memory data = new ownedContractDataStruct[](cnt);

    unchecked {
      for (uint256 c = 0; c < cnt; c++) { data[c] = ownedContractData[ownedContractList[c]]; }
    }

    return data;
  }

  function listProposals() public view isManager returns (proposalDataStruct[] memory) {
    uint256 cnt = proposalList.length;

    proposalDataStruct[] memory data = new proposalDataStruct[](cnt);

    unchecked {
      for (uint256 p = 0; p < cnt; p++) { data[p] = proposalData[p]; }
    }

    return data;
  }
}
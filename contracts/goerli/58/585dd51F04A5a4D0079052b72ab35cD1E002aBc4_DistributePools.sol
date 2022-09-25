//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IFundraising.sol";
import "./interfaces/ILeapStart.sol";
import "./interfaces/IDistributePool.sol";

contract DistributePools is IDistributePool {
  IFundraising public fund;
  ILeapStart public leapStart;

  // @notice ipId to projectId to project fund from fundraising
  mapping(uint256 => mapping(uint256 => uint256)) public ipProjectFund;

  mapping(uint256 => mapping(uint256 => CollaborationRoles)) internal ipProjectCollaborators;

  constructor(address _leapContract) {
    leapStart = ILeapStart(_leapContract);
  }

  /** ========== view functions ========== */
  function projectCollaborators(uint256 _ipId, uint256 _projectId)
    public
    view
    returns (
      address _author,
      address _producer,
      address _studio,
      address _publisher
    )
  {
    CollaborationRoles memory collaborators = ipProjectCollaborators[_ipId][_projectId];
    _author = collaborators.author;
    _producer = collaborators.producer;
    _studio = collaborators.studio;
    _publisher = collaborators.publisher;
  }

  /** ========== main functions ========== */
  function setProjectCollaborators(
    uint256 _ipId,
    uint256 _projectId,
    CollaborationRoles memory collaborators
  ) external {
    require(leapStart.verifiedIP(_ipId), "target IP is not activated");

    ipProjectCollaborators[_ipId][_projectId] = collaborators;
  }

  /** ========== modifier ========== */
  modifier onlyFund() {
    require(msg.sender == address(fund), "only internal contract call");
    _;
  }

  /** ========== event =========== */
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../license/License.sol";

interface IFundraising {
  struct Project {
    uint256 ipId;
    address proposer;
    string projectMetadata;
    uint256 startTime;
    uint256 endTime;
    uint256 targetFund;
    bool approved;
    bool completed;
  }

  struct ArtWork {
    address owner;
    address artworkAddress;
    uint256 price;
    uint96 royaltyShare;
    License.LicenseVersion license;
    address distributePool;
  }

  struct IPToken {
    address owner;
    address ipTokenAddress;
    uint256 mintShare;
    uint256 projectShare;
  }

  /**
   * @dev proposer create a new project for fundraising
   */
  function createNewProject(
    uint256 _targetFund,
    string memory _projectMetadata,
    uint256 _startTime,
    uint256 _duration,
    License.LicenseVersion _license,
    uint256 _price,
    uint96 _royaltyShare,
    uint256 _mintShare,
    uint256 _projectShare
  ) external returns (address artWork, address ipToken);

  /**
   * @dev proposer can update fundraising details before the fundraising start from `startTime`
   */
  // function updateFundraising(
  //   uint256 _projectId,
  //   uint256 _targetFund,
  //   uint256 _startTime,
  //   uint256 _duration,
  //   address _fundReceiver
  // ) external;

  /**
   * @dev proposer can stop fundraising details before the fundraising start from `startTime`
   */
  // function stopFundraising(uint256 _projectId) external;

  /**
   * @dev proposer can finalize the fundraising after duration, if success, it will create a project contract for
   */
  function finalizeProject(uint256 _projectId) external payable;

  // user interfaces
  function purchaseNFT(uint256 _projectId, uint256 _mintAmount) external payable;

  function purchaseToken(uint256 _projectId, uint256 _mintAmount) external payable;

  function refund(uint256 _projectId) external payable;

  // admin interfaces
  function auditSwitch() external;

  function setDistributePool(address _poolAddress) external;

  // view interfaces
  function projects(uint256 _projectId)
    external
    view
    returns (
      uint256,
      address,
      string memory,
      uint256,
      uint256,
      uint256,
      bool,
      bool
    );

  function secondAuditOn() external view returns (bool);

  function projectVault(uint256 _projectId) external view returns (uint256);

  function userFundRecord(address _account, uint256 _projectId) external view returns (uint256);

  function totalUnPaidFund() external view returns (uint256);

  function totalPaidFund() external view returns (uint256);

  function totalProject() external view returns (uint256);

  function totalCrowdFund() external view returns (uint256);

  function checkProjectCompleted(uint256 _projectId) external view returns (bool result);

  function checkProjectApproved(uint256 _projectId) external view returns (bool approved);

  function refundableFund(uint256 _projectId, address account) external view returns (uint256 refundableAmount);

  function nftsPrice(uint256 _projectId, uint256 _amount) external view returns (uint256);

  function tokensPrice(uint256 _projectId, uint256 _amount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILeapStart {
  // function IPconfig(
  //   address[] memory _collaborators,
  //   bytes32[] memory _addressRole,
  //   uint256[] memory _rewardDistribution,
  //   uint256 _royalty,
  //   address[] memory _partners
  // ) external;

  // function updateIPCollaboration(
  //   address[] memory _collaborators,
  //   bytes32[] memory _addressRole,
  //   uint256[] memory _rewardDistribution
  // ) external;

  // view interfaces
  function auditOn() external view returns (bool);

  function providerToIp(address _account) external view returns (uint256);

  function verifiedIP(uint256 _ipId) external view returns (bool);

  // ip provider interfaces
  function registerIP(string memory _IPMetadata) external;

  // function updateIPDerive(uint256 _royalty) external;

  // function updateIPJoint(address[] memory _partners) external;

  // function updateRewardDistribution() external;

  // admin
  function auditSwitch() external;

  function approveNewIP(uint256 _ipId) external;

  function setFundContract(address _fundAddress) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDistributePool {
  struct CollaborationRoles {
    address author;
    address producer;
    address studio;
    address publisher;
  }

  function projectCollaborators(uint256 _ipId, uint256 _projectId)
    external
    view
    returns (
      address _author,
      address _producer,
      address _studio,
      address _publisher
    );

  function setProjectCollaborators(
    uint256 _ipId,
    uint256 _projectId,
    CollaborationRoles memory collaborators
  ) external;

  // view interfaces
  function ipProjectFund(uint256 _ipId, uint256 _projectId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library License {
  enum LicenseVersion {
    CBE_CC0,
    CBE_ECR,
    CBE_NECR,
    CBE_NECR_HS,
    CBE_PR,
    CBE_PR_HS
  }
}
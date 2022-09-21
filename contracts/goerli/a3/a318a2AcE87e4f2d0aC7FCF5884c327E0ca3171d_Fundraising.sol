/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// Sources flattened with hardhat v2.10.2 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/security/[email protected]


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File contracts/license/License.sol


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


// File contracts/interfaces/IFundraising.sol


pragma solidity ^0.8.0;

interface IFundraising {
  struct Project {
    uint256 ipId;
    address proposer;
    string projectMetadata;
    uint256 startTime;
    uint256 endTime;
    uint256 targetFund;
    bool approved;
  }

  struct ArtWork {
    address owner;
    address artworkAddress;
    uint256 price;
    uint256 royaltyShare;
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
    uint256 _royaltyShare,
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
      bool
    );

  function secondAuditOn() external view returns (bool);

  function projectVault(uint256 _projectId) external view returns (uint256);

  function userFundRecord(address _account, uint256 _projectId) external view returns (uint256);

  function projectNFT(uint256 _projectId)
    external
    view
    returns (
      address,
      address,
      uint256,
      uint256
    );

  function projectToken(uint256 _projectId)
    external
    view
    returns (
      address,
      address,
      uint256,
      uint256
    );

  function totalUnPaidFund() external view returns (uint256);

  function totalPaidFund() external view returns (uint256);

  function totalProject() external view returns (uint256);

  function totalCrowdFund() external view returns (uint256);

  function checkProjectCompleted(uint256 _projectId) external view returns (bool result);

  function checkProjectApproved(uint256 _projectId) external view returns (bool approved);

  function refundableFund(uint256 _projectId, address account) external view returns (uint256 refundableAmount);
}


// File contracts/interfaces/ILeapStart.sol


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


// File contracts/interfaces/ILSArtworkFactory.sol


pragma solidity ^0.8.0;

interface ILSArtworkFactory {
  function createArtWork(
    address _owner,
    uint256 _proposalId,
    uint256 _royaltyShare,
    License.LicenseVersion _license
  ) external returns (address);
}


// File contracts/interfaces/ILSTokenFactory.sol


pragma solidity ^0.8.0;

interface ILSTokenFactory {
  function createIPToken(
    address _owner,
    uint256 _projectId,
    uint256 _projectShare
  ) external returns (address);
}


// File contracts/interfaces/IDistributePool.sol


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

  function recordFund(
    uint256 _ipId,
    uint256 _projectId,
    uint256 _fundAmount
  ) external;

  // view interfaces
  function ipProjectFund(uint256 _ipId, uint256 _projectId) external view returns (uint256);
}


// File contracts/interfaces/ILSToken.sol


pragma solidity ^0.8.0;

interface ILSToken {
  // main interfaces
  function mint() external;

  function recordForWhiteList(uint256 _mintAmount, address _receiver) external;

  // view variables
  function owner() external view returns (address);

  function projectShare() external view returns (uint256);

  function tokenProjectId() external view returns (uint256);
}


// File contracts/interfaces/ILSArtWorks721.sol


pragma solidity ^0.8.0;

interface ILSArtWorks721 {
  // main interfaces
  function mint() external;

  function recordForWhiteList(uint256 _mintAmount, address _receiver) external;

  // view rariables

  function owner() external view returns (address);

  function artWorkProposalId() external view returns (uint256);

  function royaltyShare() external view returns (uint256);
}


// File contracts/Fundraising.sol


pragma solidity ^0.8.0;











contract Fundraising is IFundraising, Ownable, ReentrancyGuard {
  // @notice total share of protocol
  uint256 public constant TOTALSHARE = 1000;

  // @notice switch to open audit of project creation
  bool public secondAuditOn;

  // @notice project detail list
  mapping(uint256 => Project) public projects;

  // @notice project vault
  mapping(uint256 => uint256) public projectVault; // optional: one ip to multiple projects

  // @notice user fund in project
  mapping(address => mapping(uint256 => uint256)) public userFundRecord;

  // project token addresses
  mapping(uint256 => IPToken) public projectToken;
  mapping(uint256 => ArtWork) public projectNFT;

  uint256 public totalUnPaidFund;

  uint256 public totalPaidFund;

  uint256 public totalProject;

  ILeapStart public immutable leapStart;
  ILSTokenFactory public tokenFactory;
  ILSArtworkFactory public worksFactory;
  IDistributePool public distributePool;

  constructor(address _leapStartContract) {
    leapStart = ILeapStart(_leapStartContract);
  }

  /** ========== view functions ========== */

  function totalCrowdFund() external view override returns (uint256) {
    return totalPaidFund + totalUnPaidFund;
  }

  function checkProjectCompleted(uint256 _projectId) public view returns (bool result) {
    Project memory project = projects[_projectId];

    result = projectVault[_projectId] >= project.targetFund && block.timestamp > project.endTime;
  }

  function checkProjectApproved(uint256 _projectId) public view returns (bool approved) {
    approved = projects[_projectId].approved;
  }

  function refundableFund(uint256 _projectId, address account) public view returns (uint256 refundableAmount) {
    Project memory project = projects[_projectId];
    require(checkProjectApproved(_projectId), "invalid project");
    require(
      block.timestamp > project.endTime && projectVault[_projectId] < project.targetFund,
      "project completed or not end"
    );

    refundableAmount = userFundRecord[account][_projectId];
  }

  function nftsPrice(uint256 _projectId, uint256 _amount) public view returns (uint256) {
    ArtWork memory artwork = projectNFT[_projectId];
    return artwork.price * _amount;
  }

  function tokensPrice(uint256 _projectId, uint256 _amount) public view returns (uint256) {
    IPToken memory iptoken = projectToken[_projectId];

    return (iptoken.mintShare * _amount * 1e18) / TOTALSHARE;
  }

  /** ========== main functions ========== */
  /**
   * @notice only qualified ip provider can create a new project.
   * @param _targetFund the target fund of the this project, and the number should multiply 1e18
   * @param _projectMetadata include project name, description, website link and etc.
   * @param _startTime the start time of project fundraising: timeStamp
   * @param _duration the duration of project fundraising: timeStamp
   * @param _license nft license basing on a16z CanBeEvil.
   * @param _mintShare ip token(ERC20) mint rate: n / 1 ETH.
   * @param _projectShare the share of sending ip token to project owner
   */
  function createNewProject(
    uint256 _targetFund,
    string memory _projectMetadata,
    uint256 _startTime,
    uint256 _duration,
    License.LicenseVersion _license,
    uint256 _price,
    uint256 _royaltyShare,
    uint256 _mintShare,
    uint256 _projectShare
  ) external returns (address artWork, address ipToken) {
    uint256 ipId = leapStart.providerToIp(msg.sender);
    require(address(worksFactory) != address(0) && address(tokenFactory) != address(0), "please initialize firstly");
    require(leapStart.verifiedIP(ipId), "target IP is not activated");
    require(block.timestamp <= _startTime, "too early to create");
    require(_projectShare < _mintShare, "invalid project rate");

    uint256 projectId = totalProject++;

    Project memory project;
    project.ipId = ipId;
    project.proposer = msg.sender;
    project.projectMetadata = _projectMetadata;
    project.startTime = _startTime;
    project.endTime = _startTime + _duration;
    project.targetFund = _targetFund;
    project.approved = !secondAuditOn ? true : false;
    projects[projectId] = project;

    // defaultly generate artwork collection.
    artWork = _createArtWorks(msg.sender, projectId, _price, _royaltyShare, _license);

    // generate ip token
    ipToken = _createIpToken(msg.sender, projectId, _mintShare, _projectShare);

    emit ProjectCreated(projectId, msg.sender, _startTime, project.endTime);
  }

  function purchaseNFT(uint256 _projectId, uint256 _mintAmount) external payable {
    Project memory project = projects[_projectId];
    uint256 paidFund = nftsPrice(_projectId, _mintAmount);

    require(block.timestamp > project.startTime, "not start");
    require(block.timestamp < project.endTime, "fundraising is over");
    require(msg.value >= paidFund, "not enough to purchase");

    // update user fund
    userFundRecord[msg.sender][_projectId] += paidFund;
    ILSArtWorks721(projectNFT[_projectId].artworkAddress).recordForWhiteList(_mintAmount, msg.sender);

    // update global fund
    projectVault[_projectId] += paidFund;
    totalUnPaidFund += paidFund;

    emit ProjectNFTPurchased(_projectId, msg.sender, _mintAmount);
  }

  function purchaseToken(uint256 _projectId, uint256 _mintAmount) external payable {
    Project memory project = projects[_projectId];
    uint256 paidFund = tokensPrice(_projectId, _mintAmount);

    require(block.timestamp > project.startTime, "not start");
    require(block.timestamp < project.endTime, "the project is done");
    require(msg.value >= paidFund, "not enough to purchase");

    // update user mintable Amount
    userFundRecord[msg.sender][_projectId] += paidFund;
    ILSToken(projectToken[_projectId].ipTokenAddress).recordForWhiteList(_mintAmount, msg.sender);

    // update global fund
    projectVault[_projectId] += paidFund;
    totalUnPaidFund += paidFund;

    emit ProjectTokenPurchased(_projectId, msg.sender, _mintAmount);
  }

  /**
   * @notice refund will only be activated after the project fail to reach target fund
   */
  function refund(uint256 _projectId) external payable nonReentrant {
    uint256 refundableAmount = refundableFund(_projectId, msg.sender);

    require(refundableAmount != 0, "caller did not fund the project");
    require(address(this).balance > refundableAmount, "not enough to refund");

    // clear user fund record
    userFundRecord[msg.sender][_projectId] = 0;

    // update global fund
    projectVault[_projectId] -= refundableAmount;
    totalUnPaidFund -= refundableAmount;

    // tranfser refund ether
    payable(msg.sender).transfer(refundableAmount);

    emit Refunded(_projectId, msg.sender, refundableAmount);
  }

  /**
   * @notice withdrawal fund will be sent to ip provider address
   */
  function finalizeProject(uint256 _projectId) external payable nonReentrant {
    Project memory project = projects[_projectId];
    uint256 projectFund = projectVault[_projectId];

    require(project.proposer == msg.sender, "only project proposer can call");
    // require(address(distributePool) != address(0), "distribute pool not set");

    // update global fund
    projectVault[_projectId] = 0;
    totalPaidFund += projectFund;
    totalUnPaidFund -= projectFund;

    // fund will be sent to project owner directly
    payable(project.proposer).transfer(projectFund);
    // distributePool.recordFund(project.ipId, _projectId, projectFund);

    emit ProjectFinalized(_projectId, project.proposer, projectFund);
  }

  /** ========== admin functions =========== */
  function initialize(address _tokenFactory, address _worksFactory) external onlyOwner {
    tokenFactory = ILSTokenFactory(_tokenFactory);
    worksFactory = ILSArtworkFactory(_worksFactory);
  }

  function auditSwitch() external onlyOwner {
    secondAuditOn = !secondAuditOn;
  }

  function setDistributePool(address _poolAddress) external onlyOwner {
    require(_poolAddress != address(0), "invalid address");
    distributePool = IDistributePool(_poolAddress);
  }

  function approveApprove(uint256 _projectId) external onlyOwner {
    _approveProject(_projectId);
  }

  /** ========== internal functions ========== */
  function _approveProject(uint256 _projectId) internal {
    require(projects[_projectId].approved = false, "target IP has been activated");

    projects[_projectId].approved = true;

    emit ProjectApproved(_projectId, owner());
  }

  function _createArtWorks(
    address _artWorkOwner,
    uint256 _projectId,
    uint256 _price,
    uint256 _royaltyShare,
    License.LicenseVersion _license
  ) internal returns (address artWorkAddress) {
    artWorkAddress = worksFactory.createArtWork(_artWorkOwner, _projectId, _royaltyShare, _license);

    ArtWork memory artwork;
    artwork.owner = _artWorkOwner;
    artwork.artworkAddress = artWorkAddress;
    artwork.price = _price;
    artwork.royaltyShare = _royaltyShare;

    projectNFT[_projectId] = artwork;
  }

  function _createIpToken(
    address _tokenOwner,
    uint256 _projectId,
    uint256 _mintShare,
    uint256 _projectShare
  ) internal returns (address tokenAddress) {
    tokenAddress = tokenFactory.createIPToken(_tokenOwner, _projectId, _projectShare);

    IPToken memory ipToken;
    ipToken.owner = _tokenOwner;
    ipToken.ipTokenAddress = tokenAddress;
    ipToken.mintShare = _mintShare;
    ipToken.projectShare = _projectShare;

    projectToken[_projectId] = ipToken;
  }

  /** ========== event ========== */

  event ProjectCreated(uint256 indexed projectId, address indexed proposer, uint256 startTime, uint256 endTime);

  event ProjectApproved(uint256 indexed projectId, address approver);

  event ProjectNFTPurchased(uint256 indexed projectId, address indexed account, uint256 tokenAmount);

  event ProjectTokenPurchased(uint256 indexed projectId, address indexed account, uint256 tokenAmount);

  event Refunded(uint256 indexed projectId, address indexed granter, uint256 refundAmount);

  event ProjectFinalized(uint256 indexed projectId, address indexed projectOwner, uint256 projectFund);
}
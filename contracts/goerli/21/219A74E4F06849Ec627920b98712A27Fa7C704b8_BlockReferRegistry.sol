// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IBlockReferRegistry.sol";
import "./IBlockReferStrategy.sol";

interface IBlockReferralStragety {
    function getReferralFee(uint256 projectId, uint256 totalAmount, address affiliate, address buyer, bytes calldata data) external view returns (uint256);
}

contract BlockReferRegistry is Ownable, IBlockReferRegistry {
    // management
    bool public projectCreationEnabled;

    // list of all projects
    mapping (uint256 => Project) public projects;
    uint256 public projectCount;
    mapping (address => bool) public isStrategyApproved;

     /**
     * @dev Get project
     */
    function getProject(uint256 index) public view returns (Project memory) {
        require(index < projectCount);
        return projects[index];
    }

    /**
     * @dev Get referral fee for referral transaction
     */
    function createProject(address source, address currentReferralStrategy) external {
        require(isStrategyApproved[currentReferralStrategy], "Unknown strategy");
        projects[projectCount] = Project({
            currentReferralStrategy: currentReferralStrategy,
            owner: msg.sender,
            referralRecorder: source,
            approved: false
        });
        emit ProjectCreated(projectCount, msg.sender, currentReferralStrategy, source);
        projectCount++;
    }

    /**
     * @dev Update referral strategy of project
     */
    function updateProjectStrategy(uint256 projectId, address newStrategy) external {
        require(isStrategyApproved[newStrategy], "Unknown strategy");
        require(projects[projectId].owner == msg.sender, "Unauthorized");
        projects[projectId].currentReferralStrategy = newStrategy;
        emit ProjectStrategyUpdated(projectId, newStrategy);
    }

    /**
     * @dev Get referral fee for referral transaction
     */
    function getReferralFee(uint256 projectId, uint256 totalAmount, address affiliate, address buyer, bytes calldata data) public view returns (uint256) {
        return IBlockReferStrategy(projects[projectId].currentReferralStrategy).getReferralFee(projectId, totalAmount, affiliate, buyer, data);
    }

    /**
     * @dev Record a referral on-chain
     */
    function recordReferral(uint256 projectId, uint256 totalAmount, address affiliate, address buyer, bytes calldata data) external payable {
        Project memory project = projects[projectId];

        require(project.approved, "Project not approved");
        require(project.currentReferralStrategy != address(0), "No active referral campaign");
        require(msg.sender == project.referralRecorder, "Unauthorized");

        require(msg.value == getReferralFee(projectId, totalAmount, affiliate, buyer, data));

        emit ReferralRecord(projectId, affiliate, totalAmount, buyer, block.timestamp, data);
    }

    // --------- MANAGEMENT ----------

    /**
     * @dev Toggle enable creation of new projects (only owner)
     */
    function toggleProjectCreationEnabled() external onlyOwner {
        projectCreationEnabled = !projectCreationEnabled;
    }

    /**
     * @dev Approve project (only owner)
     */
    function approveProject(uint256 projectId) external onlyOwner {
        require(projects[projectId].approved == false);
        projects[projectId].approved = true;
        emit ProjectApproved(projectId);
    }
 
    /**
     * @dev Approve strategy (only owner)
     */
    function approveStrategy(address strategy) external onlyOwner {
        require(isStrategyApproved[strategy] == false);
        isStrategyApproved[strategy] == true;
        emit StrategyApproved(strategy);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface IBlockReferStrategy {
    function getReferralFee(uint256 projectId, uint256 totalAmount, address affiliate, address buyer, bytes calldata data) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface IBlockReferRegistry {
    // events
    event ReferralRecord(uint256 indexed projectId, address indexed affiliate, uint256 totalAmount, address buyer, uint256 timestamp, bytes data);
    event ProjectCreated(uint256 indexed projectId, address indexed owner, address currentReferralStrategy, address referralRecorder);
    event ProjectApproved(uint256 indexed projectId);
    event StrategyApproved(address indexed strategy);
    event ProjectStrategyUpdated(uint256 indexed projectId, address newStrategy);
    // event DefaultStrategyUpdated(address indexed owner, address newStrategy);

    // project data type
    struct Project {
        address currentReferralStrategy;
        address owner;
        address referralRecorder;
        bool approved;
    }

    function getProject(uint256 index) external view returns (Project memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
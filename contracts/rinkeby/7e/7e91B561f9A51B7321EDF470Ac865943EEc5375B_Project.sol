//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Project is Context, Ownable {
    uint256 public lastedId;
    address public admin;

    struct Project {
        uint256 id;
        bool isSingle;
        bool isRaise;
        address token;
        address manager;
        uint256 joinStart;
        uint256 joinEnd;
        uint256 saleStart;
        uint256 saleEnd;
        uint256 distributionStart;
        Status status;
    }

    enum Status {
        inactive,
        started
    }

    mapping(uint256 => Project) private projects;
    mapping(address => bool) private tokenUseds;

    modifier projectExists(uint256 projectId) {
        require(projectId == projects[projectId].id, "project not exists");
        _;
    }

    modifier onlyManager(uint256 projectId) {
        require(_msgSender() == owner() || _msgSender() == admin || _msgSender() == projects[projectId].manager, "caller is not the manager");
        _;
    }

    event Create(Project project);
    event SetManager(uint256 indexed projectId, address newManager);
    event SetSaleTime(uint256 indexed projectId, uint256 startTime, uint256 endTime);
    event SetSaleType(uint256 indexed projectId, bool isRaise);
    event SetDistributionStart(uint256 indexed projectId, uint256 startTime);

    function createProject(address _token, bool _isSingle, bool _isRaise) external {
        require(_msgSender() == admin || _msgSender() == owner(), "create: caller is not the admin");
        require(_token != address(0), "create: token is the zero address");
        require(!tokenUseds[_token], "create: token is used");

        lastedId++;
        Project storage project = projects[lastedId];
        project.id              = lastedId;
        project.token           = _token;
        project.isSingle        = _isSingle;
        project.isRaise         = _isRaise;
        tokenUseds[_token]      = true;
        emit Create(project);
    }

    function getProject(uint256 _projectId) external view returns (Project memory) {
        return projects[_projectId];
    }

    function getSuperAdmin() external view returns (address) {
        return owner();
    }

    function setAdmin(address _newAdmin) external onlyOwner {
        require(_newAdmin != address(0), "new admin is the zero address");
        admin = _newAdmin;
    }

    function getAdmin() external view returns(address) {
        return admin;
    }
    
    function setManager(uint256 _projectId, address _newManager) external projectExists(_projectId) {
        require(_msgSender() == admin || _msgSender() == owner(), "caller is not the admin");
        require(_newManager != address(0), "new manager is the zero address");
        projects[_projectId].manager = _newManager;
        emit SetManager(_projectId, _newManager);
    }

    function getManager(uint256 _projectId) external view returns(address) {
        return projects[_projectId].manager;
    }

    function setJoinTime(uint256 _projectId, uint256 _start, uint256 _end) external projectExists(_projectId) onlyManager(_projectId) {
        uint256 timestamp = block.timestamp;
        Project storage project = projects[_projectId];
        require(project.status == Status.started, "project inactive");
        require(timestamp < project.joinStart, "project joined");
        require(_start >= timestamp && _start <= _end, "invalid start time");
        require(_end <= project.saleStart, "invalid end time");

        project.joinStart = _start;
        project.joinEnd   = _end;
    }

    function setSaleTime(uint256 _projectId, uint256 _start, uint256 _end) external projectExists(_projectId) onlyManager(_projectId) {
        Project storage project = projects[_projectId];
        require(project.status == Status.started, "project inactive");
        require(block.timestamp < project.joinStart, "project joined");
        require(_start <= _end && _start >= project.joinEnd, "invalid start time");
        require(_end <= project.distributionStart, "invalid end time");

        project.saleStart = _start;
        project.saleEnd   = _end;
    }

    function setDistributionStart(uint256 _projectId, uint256 _start) external projectExists(_projectId) onlyManager(_projectId) {
        Project storage project = projects[_projectId];
        require(project.status == Status.started, "project inactive");
        require(block.timestamp < project.joinStart, "project joined");
        require(_start > project.saleEnd, "invalid start time");

        project.distributionStart = _start;
    }

    function start(uint256 _projectId, uint256 _joinStart, uint256 _joinEnd, uint256 _saleStart, uint256 _saleEnd, uint256 _distributionStart) external projectExists(_projectId) onlyManager(_projectId) {
        Project storage project = projects[_projectId];
        require(project.status == Status.inactive, "project started");
        require(_joinStart >= block.timestamp && _joinStart <= _joinEnd, "invalid join start");
        require(_saleStart >= _joinEnd && _saleStart <= _saleEnd, "invalid sale start");
        require(_distributionStart > _saleEnd, "invalid distribution start");

        project.joinStart = _joinStart;
        project.joinEnd   = _joinEnd;
        project.saleStart = _saleStart;
        project.saleEnd   = _saleEnd;
        project.distributionStart = _distributionStart;
        project.status    = Status.started;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/Project.sol";

contract $Project is Project {
    constructor() {}

    function $_transferOwnership(address newOwner) external {
        return super._transferOwnership(newOwner);
    }

    function $_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function $_msgData() external view returns (bytes memory) {
        return super._msgData();
    }
}
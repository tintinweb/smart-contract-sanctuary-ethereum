//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/INFTChecker.sol";
import "./interfaces/ISale.sol";
import "./interfaces/IProject.sol";

contract Project is Initializable, OwnableUpgradeable {
    uint256 public constant WEIGHT_DECIMAL = 1e6;
    uint256 public lastedId;
    ISale       private sale;
    INFTChecker private nftChecker;

    mapping(address => bool) public admins;
    mapping(uint256 => ProjectInfo) private projects;
    mapping(uint256 => ApprovalInfo) private approvals;

    modifier projectExists(uint256 projectId) {
        require(projectId == projects[projectId].id, "project not exists");
        _;
    }

    modifier onlyAdmin() {
        require(_msgSender() == owner() || admins[_msgSender()], "caller is not the admin");
        _;
    }

    modifier onlyManager(uint256 projectId) {
        if (projects[projectId].isCreatedByAdmin) {
            require(_msgSender() == owner() || admins[_msgSender()] || _msgSender() == projects[projectId].manager, "caller is not the manager");
        } else {
            require(_msgSender() == projects[projectId].manager, "caller is not the manager");
        }
        _;
    }

    event Create(ProjectInfo project);
    event SetAdmin(address indexed oldAdmin, address indexed newAdmin);
    event SetManager(uint256 indexed projectId, address indexed oldManager, address indexed newManager);
    event SetJoinTime(uint256 indexed projectId, uint256 indexed startTime, uint256 indexed endTime);
    event SetSaleTime(uint256 indexed projectId, uint256 indexed startTime, uint256 indexed endTime);
    event SetDistributionStart(uint256 indexed projectId, uint256 indexed startTime);
    event SetIDO(uint256 indexed projectId, ProjectStatus indexed status, uint256 joinStart, uint256 joinEnd, uint256 saleStart, uint256 saleEnd, uint256 distributionStart);
    event RequestApproval(uint256 indexed projectId, uint256 indexed profitShare);
    event Approval(uint256 indexed projectId, bool isApproval);
    event UnApproval(uint256 indexed projectId, bool isApproval);
    event End(uint256 indexed ProjectId, uint64 timestamp);
   
    function initialize(address _owner, address _nftChecker) external initializer {
        require(_nftChecker != address(0), "nftChecker is zero address");
        OwnableUpgradeable.__Ownable_init();
        transferOwnership(_owner);
        nftChecker = INFTChecker(_nftChecker);
    }

    function setContract(address _sale) external {
        require(_sale != address(0), "sale is zero address");
        require(address(sale) == address(0), "sale address is already set");
        sale = ISale(_sale);
    }

    function createProject(address _token, bool _isSingle, bool _isRaise) external {
        require(_token != address(0), "create: token is the zero address");
        require(_isSingle ? nftChecker.isERC721(_token) : nftChecker.isERC1155(_token), "invalid token");

        lastedId++;
        ProjectInfo storage project  = projects[lastedId];
        project.isCreatedByAdmin     = admins[_msgSender()] || _msgSender() == owner();
        project.id                   = lastedId;
        project.manager              = _msgSender();
        project.token                = _token;
        project.isSingle             = _isSingle;
        project.isRaise              = _isRaise;
        emit Create(project);
    }

    function getProject(uint256 _projectId) external view returns (ProjectInfo memory) {
        return projects[_projectId];
    }

    function getSuperAdmin() external view returns (address) {
        return owner();
    }

    function addAdmins(address[] memory _accounts) external onlyOwner {
        _setAdmins(_accounts, true);
    }

    function removeAdmins(address[] memory _accounts) external onlyOwner {
        _setAdmins(_accounts, false);
    }

    function _setAdmins(address[] memory accounts, bool isAdd) private {
        for (uint256 i; i < accounts.length; i++) {
            require(accounts[i] != address(0), "account is zero address");
            admins[accounts[i]] = isAdd;
        }
    }

    function isAdmin(address _account) external view returns(bool) {
        return admins[_account];
    }
    
    function setManager(uint256 _projectId, address _newManager) external projectExists(_projectId) onlyAdmin {
        require(_newManager != address(0), "new manager is the zero address");
        address oldManager = projects[_projectId].manager;
        projects[_projectId].manager = _newManager;
        emit SetManager(_projectId, oldManager, _newManager);
    }

    function getManager(uint256 _projectId) external view returns(address) {
        return projects[_projectId].manager;
    }

    function setJoinTime(uint256 _projectId, uint256 _start, uint256 _end) external projectExists(_projectId) onlyManager(_projectId) {
        uint64 timestamp = uint64(block.timestamp);
        ProjectInfo storage project = projects[_projectId];
        require(project.status == ProjectStatus.STARTED, "project inactive");
        require(timestamp < project.joinStart, "project joined");
        require(_start >= timestamp && _start < _end, "invalid start time");
        require(_end < project.saleStart, "invalid end time");

        project.joinStart = _start;
        project.joinEnd   = _end;
        emit SetJoinTime(_projectId, _start, _end);
    }

    function setSaleTime(uint256 _projectId, uint256 _start, uint256 _end) external projectExists(_projectId) onlyManager(_projectId) {
        uint64 timestamp = uint64(block.timestamp);
        ProjectInfo storage project = projects[_projectId];
        require(project.status == ProjectStatus.STARTED, "project inactive");
        require(timestamp < project.joinStart, "project joined");
        require(_start >= timestamp && _start > project.joinEnd && _start < _end, "invalid start time");
        require(_end < project.distributionStart, "invalid end time");

        project.saleStart = _start;
        project.saleEnd   = _end;
        emit SetSaleTime(_projectId, _start, _end);
    }

    function setDistributionStart(uint256 _projectId, uint256 _start) external projectExists(_projectId) onlyManager(_projectId) {
        ProjectInfo storage project = projects[_projectId];
        require(project.status == ProjectStatus.STARTED, "project inactive");
        require(block.timestamp < project.joinStart, "project joined");
        require(_start > project.saleEnd, "invalid start time");

        project.distributionStart = _start;
        emit SetDistributionStart(_projectId, _start);
    }

    function setIDO(uint256 _projectId, uint256 _joinStart, uint256 _joinEnd, uint256 _saleStart, uint256 _saleEnd, uint256 _distributionStart) external projectExists(_projectId) onlyManager(_projectId) {
        ProjectInfo storage project = projects[_projectId];
        require(project.status != ProjectStatus.STARTED, "project started");
        require(sale.getSalesProject(_projectId).length > 0, "the project has no products for sale");
        require(_joinStart >= block.timestamp && _joinStart < _joinEnd, "invalid join start");
        require(_saleStart > _joinEnd && _saleStart < _saleEnd, "invalid sale start");
        require(_distributionStart > _saleEnd, "invalid distribution start");

        project.joinStart = _joinStart;
        project.joinEnd   = _joinEnd;
        project.saleStart = _saleStart;
        project.saleEnd   = _saleEnd;
        project.distributionStart = _distributionStart;
        project.status    = project.isCreatedByAdmin ? ProjectStatus.STARTED : ProjectStatus.INACTIVE;
        emit SetIDO(_projectId, project.status, _joinStart, _joinEnd, _saleStart, _saleEnd, _distributionStart);
    }

    function requestApproval(uint256 _projectId, uint256 _profitShare) external projectExists(_projectId) onlyManager(_projectId) {
        require(!projects[_projectId].isCreatedByAdmin, "cannot request project created by admin");
        require(!approvals[_projectId].isApproved, "project id approved");
        require(_profitShare <= 100 * WEIGHT_DECIMAL, "invalid profit share");

        approvals[_projectId].projectId = _projectId;
        approvals[_projectId].percent = _profitShare;
        emit RequestApproval(_projectId, _profitShare);
    }

    function approval(uint256 _projectId) external projectExists(_projectId) onlyAdmin {
        require(!projects[_projectId].isCreatedByAdmin, "cannot approve project created by admin");
        require(block.timestamp < projects[_projectId].joinStart, "invalid IDO");
        require(approvals[_projectId].projectId == _projectId, "Project is not requested yet");

        approvals[_projectId].isApproved = true;
        projects[_projectId].status = ProjectStatus.STARTED;
        emit Approval(_projectId, true);
    }

    function unApproval(uint256 _projectId) external projectExists(_projectId) onlyAdmin {
        require(!projects[_projectId].isCreatedByAdmin, "cannot approve project created by admin");
        require(block.timestamp < projects[_projectId].joinStart, "project joined");
        require(approvals[_projectId].projectId == _projectId, "Project is not requested yet");

        approvals[_projectId].isApproved = false;
        projects[_projectId].status = ProjectStatus.INACTIVE;
        emit UnApproval(_projectId, false);
    }

    function getApproval(uint256 _projectId) external view returns(ApprovalInfo memory) {
        return approvals[_projectId];
    }

    function end(uint256 _projectId) external projectExists(_projectId) onlyManager(_projectId) {
        uint64 timestamp = uint64(block.timestamp);
        require(timestamp > projects[_projectId].saleEnd, "end: sale live");
        
        approvals[_projectId].isApproved = false;
        projects[_projectId].status = ProjectStatus.ENDED;
        emit End(_projectId, timestamp);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT 
pragma solidity 0.8.9; 

interface INFTChecker { 
    function isERC1155(address nftAddress) external view returns (bool); 

    function isERC721(address nftAddress) external view returns (bool); 

    function isImplementRoyalty(address nftAddress) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ISale {
    function getSale(uint256 saleId) external view returns (SaleInfo memory);

    function getSalesProject(uint256 projectId) external view returns (SaleInfo[] memory);
}

struct SaleInfo {
    uint256 id;
    uint256 projectId;
    address token;
    uint256 tokenId;
    uint256 raisePrice;
    uint256 dutchMaxPrice;
    uint256 dutchMinPrice;
    uint256 priceDecrementAmt;
    uint256 amount;
    bool isSoldOut;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IProject {
    function latestId() external returns(uint256);

    function getSuperAdmin() external view returns (address);

    function getProject(uint256 _projectId) external view returns(ProjectInfo memory);

    function isAdmin(address _account) external view returns(bool);

    function getManager(uint256 _projectId) external view returns(address);

    function getApproval(uint256 _projectId) external view returns(ApprovalInfo memory);
}

struct ProjectInfo {
    uint256 id;
    bool isCreatedByAdmin;
    bool isSingle;
    bool isRaise;
    address token;
    address manager;
    uint256 joinStart;
    uint256 joinEnd;
    uint256 saleStart;
    uint256 saleEnd;
    uint256 distributionStart;
    ProjectStatus status;
}

struct ApprovalInfo {
    uint256 projectId;
    uint256 percent;
    bool isApproved;
}

enum ProjectStatus {
    INACTIVE,
    STARTED,
    ENDED
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/Project.sol";

contract $Project is Project {
    constructor() {}

    function $__Ownable_init() external {
        return super.__Ownable_init();
    }

    function $__Ownable_init_unchained() external {
        return super.__Ownable_init_unchained();
    }

    function $_transferOwnership(address newOwner) external {
        return super._transferOwnership(newOwner);
    }

    function $__Context_init() external {
        return super.__Context_init();
    }

    function $__Context_init_unchained() external {
        return super.__Context_init_unchained();
    }

    function $_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function $_msgData() external view returns (bytes memory) {
        return super._msgData();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/INFTChecker.sol";

abstract contract $INFTChecker is INFTChecker {
    constructor() {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/IProject.sol";

abstract contract $IProject is IProject {
    constructor() {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/ISale.sol";

abstract contract $ISale is ISale {
    constructor() {}
}
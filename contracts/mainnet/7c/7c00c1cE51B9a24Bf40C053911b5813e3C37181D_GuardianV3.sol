// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

/*
 *     ,_,
 *    (',')
 *    {/"\}
 *    -"-"-
 */

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./ILockERC721.sol";
import "../interfaces/ITOLTransfer.sol";

contract GuardianV3 is Initializable, ITOLTransfer {
    struct UserData {
        address guardian;
        uint256[] lockedAssets;
        mapping(uint256 => uint256) assetToIndex;
    }

    ILockERC721 public LOCKABLE;

    mapping(address => address) public pendingGuardians;
    mapping(address => address) public guardians;
    mapping(address => UserData) public userData;
    mapping(address => mapping(uint256 => address)) public guardianToUsers;
    mapping(address => mapping(address => uint256)) public guardianToUserIndex;
    mapping(address => uint256) public guardianUserCount;

    event GuardianSet(address indexed guardian, address indexed user);
    event GuardianRenounce(address indexed guardian, address indexed user);
    event PendingGuardianSet(
        address indexed pendingGuardian,
        address indexed user
    );

    address public tmpOwner;
    mapping(ILockERC721 => bool) public LOCKABLES;
    mapping(ILockERC721 => mapping(address => UserData))
        public lockablesUserData; // lockable => protege => userdata

    mapping(address => uint256) public renounceLockedUntil; // _protege => timestamp

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _lockable) public initializer {
        LOCKABLE = ILockERC721(_lockable);
    }

    function initializeV2(address[] calldata _lockables)
        external
        reinitializer(2)
    {
        // tmpOwner = address(0x759c5F293EdC487aA02186f0099864Ebc53191C1);
        tmpOwner = address(0xFABB0ac9d68B0B445fB7357272Ff202C5651694a); // dev
        // tmpOwner = address(0x66668460083309F77227f84B211dC5Ab678DbE78); // testnet
        require(msg.sender == tmpOwner);
        for (uint256 i = 0; i < _lockables.length; i++) {
            LOCKABLES[ILockERC721(_lockables[i])] = true;
        }
    }

    function transferOwnership(address newOwner) external {
        require(msg.sender == tmpOwner);
        tmpOwner = newOwner;
    }

    function setLockables(address[] calldata _lockables, bool[] calldata _b)
        external
    {
        require(msg.sender == tmpOwner);
        for (uint256 i = 0; i < _lockables.length; i++) {
            LOCKABLES[ILockERC721(_lockables[i])] = _b[i];
        }
    }

    function proposeGuardian(address _guardian) external {
        require(guardians[msg.sender] == address(0), "Guardian set");
        require(msg.sender != _guardian, "Guardian must be a different wallet");

        pendingGuardians[msg.sender] = _guardian;
        emit PendingGuardianSet(_guardian, msg.sender);
    }

    function acceptGuardianship(address _protege) external {
        require(
            pendingGuardians[_protege] == msg.sender,
            "Not the pending guardian"
        );

        pendingGuardians[_protege] = address(0);
        guardians[_protege] = msg.sender;
        userData[_protege].guardian = msg.sender;
        _pushGuardianrray(msg.sender, _protege);
        emit GuardianSet(msg.sender, _protege);
    }

    function renounce(address _protege) external {
        require(guardians[_protege] == msg.sender, "!guardian");
        require(block.timestamp >= renounceLockedUntil[_protege], "Renounce locked");

        guardians[_protege] = address(0);
        userData[_protege].guardian = address(0);
        _popGuardianrray(msg.sender, _protege);
        emit GuardianRenounce(msg.sender, _protege);
    }

    function getUserData(ILockERC721 lockable, address owner)
        internal
        view
        returns (UserData storage ud)
    {
        if (lockable == LOCKABLE) {
            return userData[owner];
        }
        return lockablesUserData[lockable][owner];
    }

    function lockMany(uint256[] calldata _tokenIds) external {
        lockManyLockable(LOCKABLE, _tokenIds);
    }

    function lockManyLockable(
        ILockERC721 lockable,
        uint256[] calldata _tokenIds
    ) public {
        require(
            lockable == LOCKABLE || LOCKABLES[lockable],
            "unsupported lockable"
        );
        address owner = lockable.ownerOf(_tokenIds[0]);
        require(guardians[owner] == msg.sender, "!guardian");

        UserData storage _userData = getUserData(lockable, owner);
        uint256 len = _userData.lockedAssets.length;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(lockable.ownerOf(_tokenIds[i]) == owner, "!owner");
            lockable.lockId(_tokenIds[i]);
            _pushTokenInArray(_userData, _tokenIds[i], len + i);
        }
    }

    function unlockMany(uint256[] calldata _tokenIds) external {
        unlockManyLockable(LOCKABLE, _tokenIds);
    }

    function unlockManyLockable(
        ILockERC721 lockable,
        uint256[] calldata _tokenIds
    ) public {
        require(
            lockable == LOCKABLE || LOCKABLES[lockable],
            "unsupported lockable"
        );
        address owner = lockable.ownerOf(_tokenIds[0]);
        require(guardians[owner] == msg.sender, "!guardian");

        UserData storage _userData = getUserData(lockable, owner);
        uint256 len = _userData.lockedAssets.length;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(lockable.ownerOf(_tokenIds[i]) == owner, "!owner");
            lockable.unlockId(_tokenIds[i]);
            _popTokenFromArray(_userData, _tokenIds[i], len--);
        }
    }

    function unlockManyAndTransfer(
        uint256[] calldata _tokenIds,
        address _recipient
    ) public {
        unlockManyAndTransferLockable(LOCKABLE, _tokenIds, _recipient);
    }

    function unlockManyAndTransferLockable(
        ILockERC721 lockable,
        uint256[] calldata _tokenIds,
        address _recipient
    ) public {
        require(
            lockable == LOCKABLE || LOCKABLES[lockable],
            "unsupported lockable"
        );
        address owner = lockable.ownerOf(_tokenIds[0]);
        require(guardians[owner] == msg.sender, "!guardian");

        UserData storage _userData = getUserData(lockable, owner);
        uint256 len = _userData.lockedAssets.length;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(lockable.ownerOf(_tokenIds[i]) == owner, "!owner");
            lockable.unlockId(_tokenIds[i]);
            lockable.safeTransferFrom(owner, _recipient, _tokenIds[i]);
            _popTokenFromArray(_userData, _tokenIds[i], len--);
        }
    }

    function getLockedAssetsOfUsers(address _user)
        external
        view
        returns (uint256[] memory lockedAssets)
    {
        return getLockedAssetsOfUsersLockable(LOCKABLE, _user);
    }

    function getLockedAssetsOfUsersLockable(ILockERC721 lockable, address _user)
        public
        view
        returns (uint256[] memory lockedAssets)
    {
        UserData storage _userData = getUserData(lockable, _user);

        uint256 len = _userData.lockedAssets.length;
        lockedAssets = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            lockedAssets[i] = _userData.lockedAssets[i];
        }
    }

    function getLockedAssetsOfUsers(
        address _user,
        uint256 _startIndex,
        uint256 _maxLen
    ) external view returns (uint256[] memory lockedAssets) {
        return
            getLockedAssetsOfUsersLockable(
                LOCKABLE,
                _user,
                _startIndex,
                _maxLen
            );
    }

    function getLockedAssetsOfUsersLockable(
        ILockERC721 lockable,
        address _user,
        uint256 _startIndex,
        uint256 _maxLen
    ) public view returns (uint256[] memory lockedAssets) {
        UserData storage _userData = getUserData(lockable, _user);

        uint256 len = _userData.lockedAssets.length;

        if (len == 0 || _startIndex >= len) {
            lockedAssets = new uint256[](0);
        } else {
            _maxLen = (len - _startIndex) < _maxLen
                ? len - _startIndex
                : _maxLen;
            lockedAssets = new uint256[](_maxLen);
            for (uint256 i = _startIndex; i < _startIndex + _maxLen; i++) {
                lockedAssets[i] = _userData.lockedAssets[i];
            }
        }
    }

    function getProtegesFromGuardian(address _guardian)
        external
        view
        returns (address[] memory proteges)
    {
        uint256 len = guardianUserCount[_guardian];
        proteges = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            proteges[i] = guardianToUsers[_guardian][i];
        }
    }

    function _pushTokenInArray(
        UserData storage _userData,
        uint256 _token,
        uint256 _index
    ) internal {
        _userData.lockedAssets.push(_token);
        _userData.assetToIndex[_token] = _index;
    }

    function _popTokenFromArray(
        UserData storage _userData,
        uint256 _token,
        uint256 _len
    ) internal {
        uint256 index = _userData.assetToIndex[_token];
        delete _userData.assetToIndex[_token];
        uint256 lastId = _userData.lockedAssets[_len - 1];
        _userData.assetToIndex[lastId] = index;
        _userData.lockedAssets[index] = lastId;
        _userData.lockedAssets.pop();
    }

    function _pushGuardianrray(address _guardian, address _protege) internal {
        uint256 count = guardianUserCount[_guardian];
        guardianToUsers[_guardian][count] = _protege;
        guardianToUserIndex[_guardian][_protege] = count;
        guardianUserCount[_guardian]++;
    }

    function _popGuardianrray(address _guardian, address _protege) internal {
        uint256 index = guardianToUserIndex[_guardian][_protege];
        delete guardianToUserIndex[_guardian][_protege];
        guardianToUsers[_guardian][index] = guardianToUsers[_guardian][
            guardianUserCount[_guardian] - 1
        ];
        delete guardianToUsers[_guardian][guardianUserCount[_guardian] - 1];
        guardianUserCount[_guardian]--;
    }

    // =============== ITOLTransfer ===============
    function canDoKeepTOLTransfer(address from, address to)
        external
        view
        returns (bool)
    {
        return guardians[from] == to || guardians[to] == from;
    }

    function beforeKeepTOLTransfer(address from, address to) external {
        ILockERC721 caller = ILockERC721(msg.sender);
        require(caller == LOCKABLE || LOCKABLES[caller], "Call must be from lockable contracts");
        require(guardians[from] == to || guardians[to] == from, "only guardians and their proteges can do keep TOL transfers");

        if (guardians[from] == to) {
            // [from] is a protege
            renounceLockedUntil[from] = block.timestamp + 30 days;
        } else {
            // [to] is a protege
            renounceLockedUntil[to] = block.timestamp + 30 days;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ILockERC721 is IERC721 {
    function lockId(uint256 _id) external;

    function unlockId(uint256 _id) external;

    function freeId(uint256 _id, address _contract) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface ITOLTransfer {
    function canDoKeepTOLTransfer(address from, address to) external view returns (bool);

    function beforeKeepTOLTransfer(address from, address to) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Storage
 * @author gotbit
 */

import '@openzeppelin/contracts/access/Ownable.sol';
import '../utils/HasRouter.sol';

interface IStorage {
    function router() external view returns (address);

    function write(bytes32 field, bytes32 value) external;

    function read(bytes32 field) external view returns (bytes32);
}

contract Storage is HasRouter {
    mapping(bytes32 => bytes32) data;

    constructor(address superAdmin_) HasRouter(address(0), superAdmin_) {}

    function write(bytes32 field, bytes32 value) external onlyRouter {
        data[field] = value;
    }

    function read(bytes32 field) external view returns (bytes32) {
        return data[field];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title StorageGetters
 * @author gotbit
 */

import '../utils/Bytes32.sol';
import {IStorage} from './Storage.sol';

library StorageGetters {
    using Bytes32 for bytes32;

    function isAdmin(IStorage storage_, address admin) internal view returns (bool) {
        return storage_.read(StorageFields.ADMIN(admin)).toBool();
    }

    function getFactory(IStorage storage_) internal view returns (address) {
        return storage_.read(StorageFields.FACTORY()).toAddress();
    }

    function getProxyRoutersLength(IStorage storage_) internal view returns (uint256) {
        return storage_.read(StorageFields.PROXY_ROUTERS_LENGTH()).toUint256();
    }

    function getProxyRouters(IStorage storage_, uint256 id)
        internal
        view
        returns (address)
    {
        return storage_.read(StorageFields.PROXY_ROUTERS(id)).toAddress();
    }

    function getProfileVaultsLength(IStorage storage_, uint256 profileId)
        internal
        view
        returns (uint256)
    {
        return storage_.read(StorageFields.PROFILE_VAULTS_LENGTH(profileId)).toUint256();
    }

    function getProfileVaults(
        IStorage storage_,
        uint256 profileId,
        uint256 id
    ) internal view returns (address) {
        return storage_.read(StorageFields.PROFILE_VAULTS(profileId, id)).toAddress();
    }

    function getProfile(IStorage storage_, address anyVault)
        internal
        view
        returns (uint256)
    {
        return storage_.read(StorageFields.PROFILE(anyVault)).toUint256();
    }

    function isProfileVault(
        IStorage storage_,
        uint256 profileId,
        address vault
    ) internal view returns (bool) {
        return storage_.read(StorageFields.PROFILE_VAULT(profileId, vault)).toBool();
    }

    function getBaseToken(IStorage storage_, uint256 profileId)
        internal
        view
        returns (address)
    {
        return storage_.read(StorageFields.BASE_TOKEN(profileId)).toAddress();
    }

    function getQuoteToken(IStorage storage_, uint256 profileId)
        internal
        view
        returns (address)
    {
        return storage_.read(StorageFields.QUOTE_TOKEN(profileId)).toAddress();
    }

    function isManager(IStorage storage_, address manager) internal view returns (bool) {
        return storage_.read(StorageFields.MANAGER(manager)).toBool();
    }

    function isProfileManager(
        IStorage storage_,
        uint256 profileId,
        address manager
    ) internal view returns (bool) {
        return storage_.read(StorageFields.PROFILE_MANAGER(profileId, manager)).toBool();
    }
}

/**
 * @title StorageGetters
 * @author gotbit
 */

library StorageSetters {
    using Bytes32 for address;
    using Bytes32 for uint256;
    using Bytes32 for bool;

    function setIsAdmin(
        IStorage storage_,
        address admin,
        bool isAdmin
    ) internal {
        storage_.write(StorageFields.ADMIN(admin), isAdmin.toBytes32());
    }

    function setFactory(IStorage storage_, address factory) internal {
        storage_.write(StorageFields.FACTORY(), factory.toBytes32());
    }

    function setProxyRouters(IStorage storage_, address[] memory proxyRouters) internal {
        uint256 length = proxyRouters.length;
        storage_.write(StorageFields.PROXY_ROUTERS_LENGTH(), length.toBytes32());
        for (uint256 i; i < length; i++)
            storage_.write(StorageFields.PROXY_ROUTERS(i), proxyRouters[i].toBytes32());
    }

    function setProfileVaults(
        IStorage storage_,
        uint256 profileId,
        uint256 id,
        address vault
    ) internal {
        storage_.write(StorageFields.PROFILE_VAULTS(profileId, id), vault.toBytes32());
    }

    function setProfileVaultsLength(
        IStorage storage_,
        uint256 profileId,
        uint256 length
    ) internal {
        storage_.write(
            StorageFields.PROFILE_VAULTS_LENGTH(profileId),
            length.toBytes32()
        );
    }

    function setProfile(
        IStorage storage_,
        address anyVault,
        uint256 profile
    ) internal {
        storage_.write(StorageFields.PROFILE(anyVault), profile.toBytes32());
    }

    function setIsProfileVault(
        IStorage storage_,
        uint256 profileId,
        address vault,
        bool isVault
    ) internal {
        storage_.write(
            StorageFields.PROFILE_VAULT(profileId, vault),
            isVault.toBytes32()
        );
    }

    function setBaseToken(
        IStorage storage_,
        uint256 profileId,
        address baseToken
    ) internal {
        storage_.write(StorageFields.BASE_TOKEN(profileId), baseToken.toBytes32());
    }

    function setQuoteToken(
        IStorage storage_,
        uint256 profileId,
        address quoteToken
    ) internal {
        storage_.write(StorageFields.QUOTE_TOKEN(profileId), quoteToken.toBytes32());
    }

    function setIsManager(
        IStorage storage_,
        address manager,
        bool isManager
    ) internal {
        storage_.write(StorageFields.MANAGER(manager), isManager.toBytes32());
    }

    function isProfileManager(
        IStorage storage_,
        uint256 profileId,
        address manager,
        bool isManager
    ) internal {
        storage_.write(
            StorageFields.PROFILE_MANAGER(profileId, manager),
            isManager.toBytes32()
        );
    }
}

/**
 * @title StorageFields
 * @author gotbit
 */

library StorageFields {
    /// MAIN ADMIN
    function ADMIN(address admin) internal pure returns (bytes32) {
        return keccak256(abi.encode('ADMIN', admin));
    }

    /// FACTORY
    function FACTORY() internal pure returns (bytes32) {
        return keccak256('FACTORY');
    }

    function PROXY_ROUTERS(uint256 id) internal pure returns (bytes32) {
        return keccak256(abi.encode('PROXY_ROUTER', id));
    }

    function PROXY_ROUTERS_LENGTH() internal pure returns (bytes32) {
        return keccak256('PROXY_ROUTER_LENGTH');
    }

    /// vault -> profile
    function PROFILE(address vault) internal pure returns (bytes32) {
        return keccak256(abi.encode('PROFILE_ID', vault));
    }

    /// profile -> vaults
    function PROFILE_VAULTS(uint256 profileId, uint256 id)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode('PROFILE_VAULTS', profileId, id));
    }

    function PROFILE_VAULTS_LENGTH(uint256 profileId) internal pure returns (bytes32) {
        return keccak256(abi.encode('PROFILE_VAULTS_LENGTH', profileId));
    }

    /// profile -> isVault
    function PROFILE_VAULT(uint256 profileId, address vault)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode('PROFILE_VAULT', profileId, vault));
    }

    /// profile -> base token
    function BASE_TOKEN(uint256 profileId) internal pure returns (bytes32) {
        return keccak256(abi.encode('BASE_TOKEN', profileId));
    }

    /// profile -> quote token
    function QUOTE_TOKEN(uint256 profileId) internal pure returns (bytes32) {
        return keccak256(abi.encode('QUOTE_TOKEN', profileId));
    }

    /// MANAGER
    function MANAGER(address manager) internal pure returns (bytes32) {
        return keccak256(abi.encode('MANAGER', manager));
    }

    /// PROFILE_MANAGER
    function PROFILE_MANAGER(uint256 profileId, address manager)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode('PROFILE_MANAGER', profileId, manager));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title StorageViewer
 * @author gotbit
 */

import './StorageUtils.sol';
import './Storage.sol';

contract StorageViewer {
    using Bytes32 for bytes32;

    function isAdmin(IStorage storage_, address admin) external view returns (bool) {
        return storage_.read(StorageFields.ADMIN(admin)).toBool();
    }

    function getFactory(IStorage storage_) external view returns (address) {
        return storage_.read(StorageFields.FACTORY()).toAddress();
    }

    function getProxyRoutersLength(IStorage storage_) external view returns (uint256) {
        return storage_.read(StorageFields.PROXY_ROUTERS_LENGTH()).toUint256();
    }

    function getProxyRouters(IStorage storage_, uint256 id)
        external
        view
        returns (address)
    {
        return storage_.read(StorageFields.PROXY_ROUTERS(id)).toAddress();
    }

    function getProfileVaultsLength(IStorage storage_, uint256 profileId)
        external
        view
        returns (uint256)
    {
        return storage_.read(StorageFields.PROFILE_VAULTS_LENGTH(profileId)).toUint256();
    }

    function getProfileVaults(
        IStorage storage_,
        uint256 profileId,
        uint256 id
    ) external view returns (address) {
        return storage_.read(StorageFields.PROFILE_VAULTS(profileId, id)).toAddress();
    }

    function getProfile(IStorage storage_, address anyVault)
        external
        view
        returns (uint256)
    {
        return storage_.read(StorageFields.PROFILE(anyVault)).toUint256();
    }

    function isProfileVault(
        IStorage storage_,
        uint256 profileId,
        address vault
    ) external view returns (bool) {
        return storage_.read(StorageFields.PROFILE_VAULT(profileId, vault)).toBool();
    }

    function getBaseToken(IStorage storage_, uint256 profileId)
        external
        view
        returns (address)
    {
        return storage_.read(StorageFields.BASE_TOKEN(profileId)).toAddress();
    }

    function getQuoteToken(IStorage storage_, uint256 profileId)
        external
        view
        returns (address)
    {
        return storage_.read(StorageFields.QUOTE_TOKEN(profileId)).toAddress();
    }

    function isManager(IStorage storage_, address manager) external view returns (bool) {
        return storage_.read(StorageFields.MANAGER(manager)).toBool();
    }

    function isProfileManager(
        IStorage storage_,
        uint256 profileId,
        address manager
    ) external view returns (bool) {
        return storage_.read(StorageFields.PROFILE_MANAGER(profileId, manager)).toBool();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Bytes32
 * @author gotbit
 */

library Bytes32 {
    function toAddress(bytes32 value) internal pure returns (address) {
        return address(uint160(uint256(value)));
    }

    function toUint256(bytes32 value) internal pure returns (uint256) {
        return uint256(value);
    }

    function toBool(bytes32 value) internal pure returns (bool) {
        return uint256(value) != 0;
    }

    function toBytes32(address value) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(value)));
    }

    function toBytes32(uint256 value) internal pure returns (bytes32) {
        return bytes32(value);
    }

    function toBytes32(bool value) internal pure returns (bytes32) {
        return value ? bytes32(uint256(1)) : bytes32(0);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title HasRouter
 * @author gotibit
 */

contract HasRouter {
    address public router;
    address public superAdmin;

    modifier onlyRouter() {
        require(
            msg.sender == router || _isSuperAdmin(msg.sender),
            'Only Router function'
        );
        _;
    }

    modifier onlySuperAdmin() {
        require(_isSuperAdmin(msg.sender), 'Only Super Admin function');
        _;
    }

    constructor(address router_, address superAdmin_) {
        router = router_;
        superAdmin = superAdmin_;
    }

    function setRouter(address router_) external onlySuperAdmin {
        router = router_;
    }

    function _isSuperAdmin(address user) internal view returns (bool) {
        return user == superAdmin;
    }
}
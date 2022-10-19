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
 * @title IStorage
 * @author gotbit
 */
import {IHasRouter} from '../utils/IHasRouter.sol';

interface IStorage is IHasRouter {
    function write(bytes32 field, bytes32 value) external;

    function read(bytes32 field) external view returns (bytes32);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Storage
 * @author gotbit
 */

import '@openzeppelin/contracts/access/Ownable.sol';

import {IStorage} from './IStorage.sol';

import {HasRouter} from '../utils/HasRouter.sol';

contract Storage is HasRouter, IStorage {
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

    function getMomotWallet(IStorage storage_, bytes32 profileId)
        internal
        view
        returns (address)
    {
        return storage_.read(StorageFields.MOMOT_WALLET(profileId)).toAddress();
    }

    function isAdmin(IStorage storage_, address admin) internal view returns (bool) {
        return storage_.read(StorageFields.ADMIN(admin)).toBool();
    }

    function getFactory(IStorage storage_) internal view returns (address) {
        return storage_.read(StorageFields.FACTORY()).toAddress();
    }

    function getSwapManager(IStorage storage_) internal view returns (address) {
        return storage_.read(StorageFields.SWAP_MANAGER()).toAddress();
    }

    function getVaultProxyRoutersLength(IStorage storage_)
        internal
        view
        returns (uint256)
    {
        return storage_.read(StorageFields.VAULT_PROXY_ROUTERS_LENGTH()).toUint256();
    }

    function getVaultProxyRouters(IStorage storage_, uint256 id)
        internal
        view
        returns (address)
    {
        return storage_.read(StorageFields.VAULT_PROXY_ROUTERS(id)).toAddress();
    }

    function getReceiverProxyRouter(IStorage storage_) internal view returns (address) {
        return storage_.read(StorageFields.RECEIVER_PROXY_ROUTER()).toAddress();
    }

    function getPrevReceiver(
        IStorage storage_,
        bytes32 profileId,
        bytes32 vaultName
    ) internal view returns (address) {
        return
            storage_.read(StorageFields.PREV_RECEIVER(profileId, vaultName)).toAddress();
    }

    function getProfileReceiver(
        IStorage storage_,
        bytes32 profileId,
        uint256 id
    ) internal view returns (address) {
        return storage_.read(StorageFields.PROFILE_RECEIVERS(profileId, id)).toAddress();
    }

    function getProfileReceiversLength(IStorage storage_, bytes32 profileId)
        internal
        view
        returns (uint256)
    {
        return
            storage_.read(StorageFields.PROFILE_RECEIVERS_LENGTH(profileId)).toUint256();
    }

    function getReceiversAmount(IStorage storage_) internal view returns (uint256) {
        return storage_.read(StorageFields.RECEIVERS_AMOUNT()).toUint256();
    }

    function getProfileVaultsLength(IStorage storage_, bytes32 profileId)
        internal
        view
        returns (bytes32)
    {
        return storage_.read(StorageFields.PROFILE_VAULTS_LENGTH(profileId));
    }

    function getProfileVaults(
        IStorage storage_,
        bytes32 profileId,
        uint256 id
    ) internal view returns (address) {
        return storage_.read(StorageFields.PROFILE_VAULTS(profileId, id)).toAddress();
    }

    function getProfile(IStorage storage_, address anyVault)
        internal
        view
        returns (bytes32)
    {
        return storage_.read(StorageFields.PROFILE(anyVault));
    }

    function isProfileVault(
        IStorage storage_,
        bytes32 profileId,
        address vault
    ) internal view returns (bool) {
        return storage_.read(StorageFields.PROFILE_VAULT(profileId, vault)).toBool();
    }

    function getBaseToken(IStorage storage_, bytes32 profileId)
        internal
        view
        returns (address)
    {
        return storage_.read(StorageFields.BASE_TOKEN(profileId)).toAddress();
    }

    function getQuoteToken(IStorage storage_, bytes32 profileId)
        internal
        view
        returns (address)
    {
        return storage_.read(StorageFields.QUOTE_TOKEN(profileId)).toAddress();
    }

    function getProfileVaultByName(
        IStorage storage_,
        bytes32 profileId,
        bytes32 vaultName
    ) internal view returns (address) {
        return
            storage_
                .read(StorageFields.PROFILE_VAULT_BY_NAME(profileId, vaultName))
                .toAddress();
    }

    function getRouterDex(IStorage storage_, bytes32 profileId)
        internal
        view
        returns (address)
    {
        return storage_.read(StorageFields.ROUTER_DEX(profileId)).toAddress();
    }

    function isManager(IStorage storage_, address manager) internal view returns (bool) {
        return storage_.read(StorageFields.MANAGER(manager)).toBool();
    }

    function isProfileManager(
        IStorage storage_,
        bytes32 profileId,
        address manager
    ) internal view returns (bool) {
        return storage_.read(StorageFields.PROFILE_MANAGER(profileId, manager)).toBool();
    }

    function getDexType(IStorage storage_, address dex) internal view returns (uint256) {
        return storage_.read(StorageFields.DEX_TYPE(dex)).toUint256();
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
    using Bytes32 for string;

    function setMomotWallet(
        IStorage storage_,
        bytes32 profileId,
        address wallet
    ) internal {
        return storage_.write(StorageFields.MOMOT_WALLET(profileId), wallet.toBytes32());
    }

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

    function setSwapManager(IStorage storage_, address swapManager) internal {
        storage_.write(StorageFields.SWAP_MANAGER(), swapManager.toBytes32());
    }

    function setVaultProxyRouters(IStorage storage_, address[] memory proxyRouters)
        internal
    {
        uint256 length = proxyRouters.length;
        storage_.write(StorageFields.VAULT_PROXY_ROUTERS_LENGTH(), length.toBytes32());
        for (uint256 i; i < length; i++)
            storage_.write(
                StorageFields.VAULT_PROXY_ROUTERS(i),
                proxyRouters[i].toBytes32()
            );
    }

    function setReceiverProxyRouter(IStorage storage_, address receiverProxyRouter)
        internal
    {
        return
            storage_.write(
                StorageFields.RECEIVER_PROXY_ROUTER(),
                receiverProxyRouter.toBytes32()
            );
    }

    function setPrevReceiver(
        IStorage storage_,
        bytes32 profileId,
        bytes32 vaultName,
        address receiver
    ) internal {
        storage_.write(
            StorageFields.PREV_RECEIVER(profileId, vaultName),
            receiver.toBytes32()
        );
    }

    function setProfileReceivers(
        IStorage storage_,
        bytes32 profileId,
        uint256 id,
        address receiver
    ) internal {
        storage_.write(
            StorageFields.PROFILE_RECEIVERS(profileId, id),
            receiver.toBytes32()
        );
    }

    function setProfileReceiversLength(
        IStorage storage_,
        bytes32 profileId,
        uint256 length
    ) internal {
        storage_.write(
            StorageFields.PROFILE_RECEIVERS_LENGTH(profileId),
            length.toBytes32()
        );
    }

    function setReceiversAmount(IStorage storage_, uint256 amount) internal {
        storage_.write(StorageFields.RECEIVERS_AMOUNT(), amount.toBytes32());
    }

    function setProfileVaults(
        IStorage storage_,
        bytes32 profileId,
        uint256 id,
        address vault
    ) internal {
        storage_.write(StorageFields.PROFILE_VAULTS(profileId, id), vault.toBytes32());
    }

    function setProfileVaultsLength(
        IStorage storage_,
        bytes32 profileId,
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
        bytes32 profileId
    ) internal {
        storage_.write(StorageFields.PROFILE(anyVault), profileId);
    }

    function setIsProfileVault(
        IStorage storage_,
        bytes32 profileId,
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
        bytes32 profileId,
        address baseToken
    ) internal {
        storage_.write(StorageFields.BASE_TOKEN(profileId), baseToken.toBytes32());
    }

    function setQuoteToken(
        IStorage storage_,
        bytes32 profileId,
        address quoteToken
    ) internal {
        storage_.write(StorageFields.QUOTE_TOKEN(profileId), quoteToken.toBytes32());
    }

    function setProfileVaultByName(
        IStorage storage_,
        bytes32 profileId,
        bytes32 vaultName,
        address vault
    ) internal {
        storage_.write(
            StorageFields.PROFILE_VAULT_BY_NAME(profileId, vaultName),
            vault.toBytes32()
        );
    }

    function setRouterDex(
        IStorage storage_,
        bytes32 profileId,
        address router
    ) internal {
        storage_.write(StorageFields.ROUTER_DEX(profileId), router.toBytes32());
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
        bytes32 profileId,
        address manager,
        bool isManager
    ) internal {
        storage_.write(
            StorageFields.PROFILE_MANAGER(profileId, manager),
            isManager.toBytes32()
        );
    }

    function setDexType(
        IStorage storage_,
        address dex,
        uint256 dexType
    ) internal {
        storage_.write(StorageFields.DEX_TYPE(dex), dexType.toBytes32());
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

    /// SWAP MANAGER
    function SWAP_MANAGER() internal pure returns (bytes32) {
        return keccak256('SWAP_MANAGER');
    }

    function VAULT_PROXY_ROUTERS(uint256 id) internal pure returns (bytes32) {
        return keccak256(abi.encode('VAULT_PROXY_ROUTER', id));
    }

    function RECEIVER_PROXY_ROUTER() internal pure returns (bytes32) {
        return keccak256(abi.encode('RECEIVER_PROXY_ROUTER'));
    }

    function VAULT_PROXY_ROUTERS_LENGTH() internal pure returns (bytes32) {
        return keccak256('PROXY_ROUTER_LENGTH');
    }

    function PREV_RECEIVER(bytes32 profileId, bytes32 vaultName)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode('PREV_RECEIVER', profileId, vaultName));
    }

    function PROFILE_RECEIVERS(bytes32 profileId, uint256 id)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode('PROFILE_RECEIVER', profileId, id));
    }

    function PROFILE_RECEIVERS_LENGTH(bytes32 profileId) internal pure returns (bytes32) {
        return keccak256(abi.encode('PROFILE_RECEIVERS_LENGTH', profileId));
    }

    function RECEIVERS_AMOUNT() internal pure returns (bytes32) {
        return keccak256(abi.encode('RECEIVERS_AMOUNT'));
    }

    /// vault -> profile
    function PROFILE(address vault) internal pure returns (bytes32) {
        return keccak256(abi.encode('PROFILE_ID', vault));
    }

    /// profile -> vaults
    function PROFILE_VAULTS(bytes32 profileId, uint256 id)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode('PROFILE_VAULTS', profileId, id));
    }

    function PROFILE_VAULTS_LENGTH(bytes32 profileId) internal pure returns (bytes32) {
        return keccak256(abi.encode('PROFILE_VAULTS_LENGTH', profileId));
    }

    /// profile -> isVault
    function PROFILE_VAULT(bytes32 profileId, address vault)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode('PROFILE_VAULT', profileId, vault));
    }

    /// profile -> base token
    function BASE_TOKEN(bytes32 profileId) internal pure returns (bytes32) {
        return keccak256(abi.encode('BASE_TOKEN', profileId));
    }

    /// profile -> quote token
    function QUOTE_TOKEN(bytes32 profileId) internal pure returns (bytes32) {
        return keccak256(abi.encode('QUOTE_TOKEN', profileId));
    }

    /// profile -> vault
    function PROFILE_VAULT_BY_NAME(bytes32 profileId, bytes32 vaultName)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(vaultName, profileId));
    }

    /// profile -> router
    function ROUTER_DEX(bytes32 profileId) internal pure returns (bytes32) {
        return keccak256(abi.encode('ROUTER_DEX', profileId));
    }

    /// MANAGER
    function MANAGER(address manager) internal pure returns (bytes32) {
        return keccak256(abi.encode('MANAGER', manager));
    }

    /// PROFILE_MANAGER
    function PROFILE_MANAGER(bytes32 profileId, address manager)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode('PROFILE_MANAGER', profileId, manager));
    }

    /// momot wallet
    function MOMOT_WALLET(bytes32 profileId) internal pure returns (bytes32) {
        return keccak256(abi.encode('MOMOT_WALLET', profileId));
    }

    function DEX_TYPE(address dex) internal pure returns (bytes32) {
        return keccak256(abi.encode('DEX_TYPE', dex));
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

    function toBytes32(string memory value) internal pure returns (bytes32) {
        return keccak256(abi.encode(value));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title HasRouter
 * @author gotbit
 */

import {IHasRouter} from './IHasRouter.sol';

contract HasRouter is IHasRouter {
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IHasRouter
 * @author gotbit
 */

interface IHasRouter {
    function router() external view returns (address);

    function superAdmin() external view returns (address);

    function setRouter(address router_) external;
}
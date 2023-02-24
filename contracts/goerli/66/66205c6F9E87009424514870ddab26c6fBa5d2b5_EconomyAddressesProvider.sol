/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IEconomyAddressesProvider.sol";

/// @title Ink Economy Addresses Provider Contract
/// @dev Main registry of addresses part of or connected to the Ink Economy, including permissioned roles
/// - Acting also as factory of proxies and admin of those, so with right to change its implementations
/// - Owned by the Ink Economy Super Admin
/// @author Ink Finanace

contract EconomyAddressesProvider is Ownable, IEconomyAddressesProvider {

    /// @notice Emitted when basket address is zero or not contract
    error InkAddressProvider_InvalidAddress(address newAddress);

    mapping(bytes32 => address) private _addresses;

    bytes32 public constant INK_ENGINE_CREATOR = "INK_ENGINE_CREATOR";
    bytes32 public constant ECONOMY_ENGINE_FACTORY = "ECONOMY_ENGINE_FACTORY";
    bytes32 public constant DAO_GOVERNANCE = "DAO_GOVERNANCE";
    bytes32 public constant INK_GOVERNANCE_TOKEN = "INK_GOVERNANCE_TOKEN";
    bytes32 public constant PRICE_ORACLE = "PRICE_ORACLE";
    bytes32 public constant SERVER_WALLET = "SERVER_WALLET";

    /// @dev throws if new address is not contract.
    modifier onlyContract(address newAddress) {
        if (!isContract(newAddress))
            revert InkAddressProvider_InvalidAddress(newAddress);
        _;
    }

    constructor() {

    }

    function isContract(address account) 
    internal 
    view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /// @dev Internal function to update the implementation of a specific proxied component of the protocol
    /// @param id The id of the proxy to be updated
    /// @param newAddress The address of the new implementation
    function _updateImpl(bytes32 id, address newAddress) internal {
        _addresses[id] = newAddress;
    }

    function setAddress(bytes32 id, address newAddress) 
    external
    override onlyOwner {
        _addresses[id] = newAddress;
    }

    function getAddress(bytes32 id) 
    public 
    override view returns (address) {
        return _addresses[id];
    }

    function getInkFinanceAdmin() 
    external 
    override view returns (address) {
        return getAddress(INK_ENGINE_CREATOR);
    }

    function setInkEngineCreatorImpl(address engineCreator) 
    external
    override onlyOwner {
        _updateImpl(INK_ENGINE_CREATOR, engineCreator);
        emit InkEngineCreatorUpdated(engineCreator);
    }

    function getEconomyEngineFactory() 
    external 
    override view returns (address) {
        return getAddress(ECONOMY_ENGINE_FACTORY);
    }

    function setEconomyEngineFactoryImpl(address factory) 
    external
    override onlyOwner onlyContract(factory) {
        _updateImpl(ECONOMY_ENGINE_FACTORY, factory);
        emit EconomyEngineFactoryUpdated(factory);
    }

    function getInkDaoGovernance() 
    external 
    override view returns (address) {
        return getAddress(DAO_GOVERNANCE);
    }

    function setInkDaoGovernanceImpl(address daogovernance) 
    external
    override onlyOwner onlyContract(daogovernance) {
        _updateImpl(DAO_GOVERNANCE, daogovernance);
        emit DaoGovernanceUpdated(daogovernance);
    }

    function getInkGovernanceToken() 
    external 
    override view returns (address) {
        return getAddress(INK_GOVERNANCE_TOKEN);
    }

    function setInkGovernanceTokenImpl(address governanceToken) 
    external
    override onlyOwner onlyContract(governanceToken) {
        _updateImpl(INK_GOVERNANCE_TOKEN, governanceToken);
        emit InkGovernanceTokenUpdated(governanceToken);
    }

    function getPriceOracle() 
    external
    override view returns (address) {
        return getAddress(PRICE_ORACLE);
    }

    function setPriceOracle(address priceOracle) 
    external
    override onlyOwner onlyContract(priceOracle) {
        _updateImpl(PRICE_ORACLE, priceOracle);
        emit PriceOracleUpdated(priceOracle);
    }

    function getServerWallet() 
    external 
    override view returns (address) {
        return getAddress(SERVER_WALLET);
    }

    function setServerWallet(address serverWallet) 
    external
    override onlyOwner {
        _updateImpl(SERVER_WALLET, serverWallet);
        emit ServerWalletUpdated(serverWallet);
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

/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title Ink Economy Addresses Provider Contract Interface
/// @dev Main registry of addresses part of or connected to the Ink Economy, including permissioned roles
/// - Acting also as factory of proxies and admin of those, so with right to change its implementations
/// - Owned by the Ink Economy Super Admin
/// @author Ink Finanace

interface IEconomyAddressesProvider {

    event InkEngineCreatorUpdated(address indexed newAddress);
    
    event EconomyEngineFactoryUpdated(address indexed newAddress);

    event DaoGovernanceUpdated(address indexed newAddress);
    
    event InkGovernanceTokenUpdated(address indexed newAddress);
    
    event PriceOracleUpdated(address indexed newAddress);

    event ServerWalletUpdated(address indexed newAddress);
    
    event ProxyCreated(bytes32 id, address indexed newAddress);
    
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);
    
    function setAddress(bytes32 id, address newAddress) external;

    function getAddress(bytes32 id) external view returns (address);

    function getInkFinanceAdmin() external view returns (address);

    function setInkEngineCreatorImpl(address inkAdmin) external;

    function getEconomyEngineFactory() external view returns (address);

    function setEconomyEngineFactoryImpl(address factory) external;

    function getInkDaoGovernance() external view returns (address);

    function setInkDaoGovernanceImpl(address daogovernance) external;

    function getInkGovernanceToken() external view returns (address);

    function setInkGovernanceTokenImpl(address daogovernance) external;

    function getPriceOracle() external view returns (address);

    function setPriceOracle(address priceOracle) external;

    function getServerWallet() external view returns (address);

    function setServerWallet(address serverWallet) external;
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
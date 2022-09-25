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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "../interfaces/AddressBookInterface.sol";
import { WhitelistInterface } from "../interfaces/WhitelistInterface.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Whitelist Module
 * @notice The whitelist module keeps track of all valid onToken addresses, product hashes, collateral addresses.
 */
contract Whitelist is WhitelistInterface, Ownable {
    /// @notice AddressBook module address
    address public addressBook;
    /// @dev mapping to track whitelisted products
    mapping(bytes32 => bool) internal whitelistedProduct;
    /// @dev mapping to track whitelisted collaterals
    mapping(bytes32 => bool) internal whitelistedCollaterals;
    /// @dev mapping to track whitelisted onTokens
    mapping(address => bool) internal whitelistedONtoken;

    /**
     * @dev constructor
     * @param _addressBook AddressBook module address
     */
    constructor(address _addressBook) {
        require(_addressBook != address(0), "Invalid address book");

        addressBook = _addressBook;
    }

    /// @notice emits an event a product is whitelisted by the owner address
    event ProductWhitelisted(
        bytes32 productHash,
        address indexed underlying,
        address indexed strike,
        address[] indexed collaterals,
        bool isPut
    );
    /// @notice emits an event a product is blacklisted by the owner address
    event ProductBlacklisted(
        bytes32 productHash,
        address indexed underlying,
        address indexed strike,
        address[] indexed collateral,
        bool isPut
    );
    /// @notice emits an event when a collateral address is whitelisted by the owner address
    event CollateralWhitelisted(address[] indexed collateral);
    /// @notice emits an event when a collateral address is blacklist by the owner address
    event CollateralBlacklisted(address[] indexed collateral);
    /// @notice emits an event when an onToken is whitelisted by the ONtokenFactory module
    event ONtokenWhitelisted(address indexed onToken);
    /// @notice emits an event when an onToken is blacklisted by the ONtokenFactory module
    event ONtokenBlacklisted(address indexed onToken);

    /**
     * @notice check if the sender is the onTokenFactory module
     */
    modifier onlyFactory() {
        require(
            msg.sender == AddressBookInterface(addressBook).getONtokenFactory(),
            "Whitelist: Sender is not ONtokenFactory"
        );

        _;
    }

    /**
     * @notice check if a product is whitelisted
     * @dev product is the hash of underlying asset, strike asset, collateral asset, and isPut
     * @param _underlying asset that the option references
     * @param _strike asset that the strike price is denominated in
     * @param _collateral asset that is held as collateral against short/written options
     * @param _isPut True if a put option, False if a call option
     * @return boolean, True if product is whitelisted
     */
    function isWhitelistedProduct(
        address _underlying,
        address _strike,
        address[] calldata _collateral,
        bool _isPut
    ) external view returns (bool) {
        bytes32 productHash = keccak256(abi.encode(_underlying, _strike, _collateral, _isPut));

        return whitelistedProduct[productHash];
    }

    /**
     * @notice check if a collateral asset is whitelisted
     * @param _collaterals assets that is held as collateral against short/written options
     * @return boolean, True if the collateral is whitelisted
     */
    function isWhitelistedCollaterals(address[] calldata _collaterals) external view returns (bool) {
        return whitelistedCollaterals[keccak256(abi.encode(_collaterals))];
    }

    /**
     * @notice check if an onToken is whitelisted
     * @param _onToken onToken address
     * @return boolean, True if the onToken is whitelisted
     */
    function isWhitelistedONtoken(address _onToken) external view returns (bool) {
        return whitelistedONtoken[_onToken];
    }

    /**
     * @notice allows the owner to whitelist a product
     * @dev product is the hash of underlying asset, strike asset, collateral asset, and isPut
     * can only be called from the owner address
     * @param _underlying asset that the option references
     * @param _strike asset that the strike price is denominated in
     * @param _collaterals assets that is held as collateral against short/written options
     * @param _isPut True if a put option, False if a call option
     */
    function whitelistProduct(
        address _underlying,
        address _strike,
        address[] calldata _collaterals,
        bool _isPut
    ) external onlyOwner {
        require(
            whitelistedCollaterals[keccak256(abi.encode(_collaterals))],
            "Whitelist: Collateral is not whitelisted"
        );

        bytes32 productHash = keccak256(abi.encode(_underlying, _strike, _collaterals, _isPut));

        whitelistedProduct[productHash] = true;

        emit ProductWhitelisted(productHash, _underlying, _strike, _collaterals, _isPut);
    }

    /**
     * @notice allow the owner to blacklist a product
     * @dev product is the hash of underlying asset, strike asset, collateral asset, and isPut
     * can only be called from the owner address
     * @param _underlying asset that the option references
     * @param _strike asset that the strike price is denominated in
     * @param _collaterals assets that is held as collateral against short/written options
     * @param _isPut True if a put option, False if a call option
     */
    function blacklistProduct(
        address _underlying,
        address _strike,
        address[] calldata _collaterals,
        bool _isPut
    ) external onlyOwner {
        bytes32 productHash = keccak256(abi.encode(_underlying, _strike, _collaterals, _isPut));

        whitelistedProduct[productHash] = false;

        emit ProductBlacklisted(productHash, _underlying, _strike, _collaterals, _isPut);
    }

    /**
     * @notice allows the owner to whitelist a collateral address
     * @dev can only be called from the owner address. This function is used to whitelist any asset other than ONtoken as collateral. WhitelistONtoken() is used to whitelist ONtoken contracts.
     * @param _collaterals collateral assets addresses
     */
    function whitelistCollaterals(address[] calldata _collaterals) external onlyOwner {
        whitelistedCollaterals[keccak256(abi.encode(_collaterals))] = true;

        emit CollateralWhitelisted(_collaterals);
    }

    /**
     * @notice allows the owner to blacklist a collateral address
     * @dev can only be called from the owner address
     * @param _collaterals collateral assets addresses
     */
    function blacklistCollateral(address[] calldata _collaterals) external onlyOwner {
        whitelistedCollaterals[keccak256(abi.encode(_collaterals))] = false;

        emit CollateralBlacklisted(_collaterals);
    }

    /**
     * @notice allows the ONtokenFactory module to whitelist a new option
     * @dev can only be called from the ONtokenFactory address
     * @param _onTokenAddress onToken
     */
    function whitelistONtoken(address _onTokenAddress) external onlyFactory {
        whitelistedONtoken[_onTokenAddress] = true;

        emit ONtokenWhitelisted(_onTokenAddress);
    }

    /**
     * @notice allows the owner to blacklist an option
     * @dev can only be called from the owner address
     * @param _onTokenAddress onToken
     */
    function blacklistONtoken(address _onTokenAddress) external onlyOwner {
        whitelistedONtoken[_onTokenAddress] = false;

        emit ONtokenBlacklisted(_onTokenAddress);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface AddressBookInterface {
    /* Getters */

    function getONtokenImpl() external view returns (address);

    function getONtokenFactory() external view returns (address);

    function getWhitelist() external view returns (address);

    function getController() external view returns (address);

    function getOracle() external view returns (address);

    function getMarginPool() external view returns (address);

    function getMarginCalculator() external view returns (address);

    function getLiquidationManager() external view returns (address);

    function getAddress(bytes32 _id) external view returns (address);

    /* Setters */

    function setONtokenImpl(address _onTokenImpl) external;

    function setONtokenFactory(address _factory) external;

    function setOracleImpl(address _onTokenImpl) external;

    function setWhitelist(address _whitelist) external;

    function setController(address _controller) external;

    function setMarginPool(address _marginPool) external;

    function setMarginCalculator(address _calculator) external;

    function setAddress(bytes32 _id, address _newImpl) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface WhitelistInterface {
    function addressBook() external view returns (address);

    function blacklistCollateral(address[] memory _collaterals) external;

    function blacklistONtoken(address _onTokenAddress) external;

    function blacklistProduct(
        address _underlying,
        address _strike,
        address[] memory _collaterals,
        bool _isPut
    ) external;

    function isWhitelistedCollaterals(address[] memory _collaterals) external view returns (bool);

    function isWhitelistedONtoken(address _onToken) external view returns (bool);

    function isWhitelistedProduct(
        address _underlying,
        address _strike,
        address[] memory _collateral,
        bool _isPut
    ) external view returns (bool);

    //  function owner() external view returns (address);

    //  function renounceOwnership() external;

    //  function transferOwnership(address newOwner) external;

    function whitelistCollaterals(address[] memory _collaterals) external;

    function whitelistONtoken(address _onTokenAddress) external;

    function whitelistProduct(
        address _underlying,
        address _strike,
        address[] memory _collaterals,
        bool _isPut
    ) external;
}
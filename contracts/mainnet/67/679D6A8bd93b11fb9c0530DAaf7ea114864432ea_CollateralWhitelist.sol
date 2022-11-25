// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title  CollateralWhitelist
 * @author Solarr
 * @notice
 */
contract CollateralWhitelist is Ownable {
    /* ********** */
    /* DATA TYPES */
    /* ********** */

    /**
     * @param collateralAddress - The address of the smart contract of the Collateral.
     * @param name - The name the nft Collateral.
     * @param activeDate - The date that the Collateral is listed.
     */
    struct Collateral {
        address collateralAddress;
        string name;
        uint256 activeDate;
    }

    /* ********** */
    /* STORAGE */
    /* ********** */

    bool private INITIALIZED = false;

    mapping(address => Collateral) public whitelistedCollaterals; // Collaterals information that have been added to whitelist

    /* *********** */
    /* EVENTS */
    /* *********** */

    /**
     * @notice This event is fired whenever the Collateral is listed to Whitelist.
     */
    event CollateralWhitelisted(address, string, uint256);

    /**
     * @notice This event is fired whenever the Collateral is unlisted from Whitelist.
     */
    event CollateralUnwhitelisted(address, string, uint256);

    /* *********** */
    /* MODIFIERS */
    /* *********** */

    modifier whenNotZeroCollateralAddress(address _collateralAddress) {
        require(
            _collateralAddress != address(0),
            "Collateral address must not be zero address"
        );
        _;
    }

    modifier whenCollateralNotWhitelisted(address _collateralAddress) {
        require(
            !_isCollateralWhitelisted(_collateralAddress),
            "Collateral already whitelisted"
        );
        _;
    }

    modifier whenCollateralWhitelisted(address _collateralAddress) {
        require(
            _isCollateralWhitelisted(_collateralAddress),
            "Collateral is not whitelisted"
        );
        _;
    }

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    /* *********** */
    /* RECEIVE FUNCTIONS */
    /* *********** */

    /* *********** */
    /* EXTERNAL FUNCTIONS */
    /* *********** */

    function initialize() external {
        require(!INITIALIZED, "Contract is already initialized");
        _transferOwnership(msg.sender);
        INITIALIZED = true;
    }

    /**
     * @notice This function can be called by Owner to list Collateral to Whitelist.
     *
     * @param _collateralAddress - The address of the Collateral contract.
     * @param _name - The name of the Collateral.
     */
    function whitelistCollateral(
        address _collateralAddress,
        string calldata _name
    ) external {
        _whitelistCollateral(_collateralAddress, _name);
    }

    /**
     * @notice This function can be called by Owner to unlist Collateral from Whitelist.
     *
     * @param _collateralAddress - The address of the Collateral contract.
     */
    function unwhitelistCollateral(address _collateralAddress) external {
        _unwhitelistCollateral(_collateralAddress);
    }

    /**
     * @notice This function can be called by Anyone to know the Collateral is listed in Whitelist or not.
     *
     * @param _collateralAddress - The address of the Collateral contract.
     *
     * @return Returns whether the Collateral is whitelisted
     */
    function isCollateralWhitelisted(address _collateralAddress)
        external
        view
        returns (bool)
    {
        return _isCollateralWhitelisted(_collateralAddress);
    }

    /* *********** */
    /* PUBLIC FUNCTIONS */
    /* *********** */

    /* *********** */
    /* INTERNAL FUNCTIONS */
    /* *********** */

    /**
     * @notice This function can be called by Owner to list Collateral to Whitelist.
     *
     * @param _collateralAddress - The address of the Collateral contract.
     * @param _name - The name of the Collateral.
     */
    function _whitelistCollateral(
        address _collateralAddress,
        string calldata _name
    )
        internal
        whenNotZeroCollateralAddress(_collateralAddress)
        onlyOwner
        whenCollateralNotWhitelisted(_collateralAddress)
    {
        // create Collateral instance and list to whitelist
        whitelistedCollaterals[_collateralAddress] = Collateral(
            _collateralAddress,
            _name,
            block.timestamp
        );

        emit CollateralWhitelisted(_collateralAddress, _name, block.timestamp);
    }

    /**
     * @notice This function can be called by Owner to unlist Collateral from Whitelist.
     *
     * @param _collateralAddress - The address of the Collateral contract.
     */
    function _unwhitelistCollateral(address _collateralAddress)
        internal
        whenNotZeroCollateralAddress(_collateralAddress)
        onlyOwner
        whenCollateralWhitelisted(_collateralAddress)
    {
        // remove Collateral instance and unlist from whitelist
        Collateral memory collateral = whitelistedCollaterals[
            _collateralAddress
        ];
        string memory name = collateral.name;
        delete whitelistedCollaterals[_collateralAddress];

        emit CollateralUnwhitelisted(_collateralAddress, name, block.timestamp);
    }

    /**
     * @notice This function can be called by Anyone to know the Collateral is listed in Whitelist or not.
     *
     * @param _collateralAddress - The address of the Collateral contract.
     *
     * @return Returns whether the Collateral is whitelisted
     */
    function _isCollateralWhitelisted(address _collateralAddress)
        internal
        view
        returns (bool)
    {
        return
            whitelistedCollaterals[_collateralAddress].collateralAddress !=
            address(0);
    }

    /* *********** */
    /* PRIVATE FUNCTIONS */
    /* *********** */
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
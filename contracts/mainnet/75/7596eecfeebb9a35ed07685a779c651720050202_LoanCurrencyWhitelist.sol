// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title  LoanCurrencyWhitelist
 * @author Solarr
 * @notice
 */
contract LoanCurrencyWhitelist is Ownable {
    /* ********** */
    /* DATA TYPES */
    /* ********** */

    /**
     * @param loanCurrencyAddress - The address of the smart contract of the LoanCurrency.
     * @param name - The name the nft LoanCurrency.
     * @param activeDate - The date that the LoanCurrency is listed.
     */
    struct LoanCurrency {
        address loanCurrencyAddress;
        string name;
        uint256 activeDate;
    }

    /* ********** */
    /* STORAGE */
    /* ********** */

    bool private INITIALIZED = false;

    mapping(address => LoanCurrency) public whitelistedLoanCurrencys; // LoanCurrencys information that have been added to whitelist

    /* *********** */
    /* EVENTS */
    /* *********** */

    /**
     * @notice This event is fired whenever the LoanCurrency is listed to Whitelist.
     */
    event LoanCurrencyListed(address, string, uint256);

    /**
     * @notice This event is fired whenever the LoanCurrency is unlisted from Whitelist.
     */
    event LoanCurrencyUnlisted(address, string, uint256);

    /* *********** */
    /* MODIFIERS */
    /* *********** */

    modifier whenNotZeroLoanCurrencyAddress(address _loanCurrencyAddress) {
        require(
            _loanCurrencyAddress != address(0),
            "LoanCurrency address must not be zero address"
        );
        _;
    }

    modifier whenLoanCurrencyWhitelisted(address _loanCurrencyAddress) {
        require(
            _isLoanCurrencyWhitelisted(_loanCurrencyAddress),
            "LoanCurrency is not whitelisted"
        );
        _;
    }

    modifier whenLoanCurrencyNotWhitelisted(address _loanCurrencyAddress) {
        require(
            !_isLoanCurrencyWhitelisted(_loanCurrencyAddress),
            "LoanCurrency already whitelisted"
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
     * @notice This function can be called by Owner to list LoanCurrency to Whitelist.
     *
     * @param _loanCurrencyAddress - The address of the LoanCurrency contract.
     * @param _name - The name of the LoanCurrency.
     */
    function whitelistLoanCurrency(
        address _loanCurrencyAddress,
        string calldata _name
    ) external {
        _whitelistLoanCurrency(_loanCurrencyAddress, _name);
    }

    /**
     * @notice This function can be called by Owner to unlist LoanCurrency from Whitelist.
     *
     * @param _loanCurrencyAddress - The address of the LoanCurrency contract.
     */
    function unwhitelistLoanCurrency(address _loanCurrencyAddress) external {
        _unwhitelistLoanCurrency(_loanCurrencyAddress);
    }

    /**
     * @notice This function can be called by Anyone to know the LoanCurrency is listed in Whitelist or not.
     *
     * @param _loanCurrencyAddress - The address of the LoanCurrency contract.
     *
     * @return Returns whether the LoanCurrency is whitelisted
     */
    function isLoanCurrencyWhitelisted(address _loanCurrencyAddress)
        external
        view
        returns (bool)
    {
        return _isLoanCurrencyWhitelisted(_loanCurrencyAddress);
    }

    /* *********** */
    /* PUBLIC FUNCTIONS */
    /* *********** */

    /* *********** */
    /* INTERNAL FUNCTIONS */
    /* *********** */

    /**
     * @notice This function can be called by Owner to list LoanCurrency to Whitelist.
     *
     * @param _loanCurrencyAddress - The address of the LoanCurrency contract.
     * @param _name - The name of the LoanCurrency.
     */
    function _whitelistLoanCurrency(
        address _loanCurrencyAddress,
        string calldata _name
    )
        internal
        whenNotZeroLoanCurrencyAddress(_loanCurrencyAddress)
        onlyOwner
        whenLoanCurrencyNotWhitelisted(_loanCurrencyAddress)
    {
        // create LoanCurrency instance and list to whitelist
        whitelistedLoanCurrencys[_loanCurrencyAddress] = LoanCurrency(
            _loanCurrencyAddress,
            _name,
            block.timestamp
        );

        emit LoanCurrencyListed(_loanCurrencyAddress, _name, block.timestamp);
    }

    /**
     * @notice This function can be called by Owner to unlist LoanCurrency from Whitelist.
     *
     * @param _loanCurrencyAddress - The address of the LoanCurrency contract.
     */
    function _unwhitelistLoanCurrency(address _loanCurrencyAddress)
        internal
        whenNotZeroLoanCurrencyAddress(_loanCurrencyAddress)
        onlyOwner
        whenLoanCurrencyWhitelisted(_loanCurrencyAddress)
    {
        // remove LoanCurrency instance and unlist from whitelist
        LoanCurrency memory loanCurrency = whitelistedLoanCurrencys[
            _loanCurrencyAddress
        ];
        string memory name = loanCurrency.name;
        delete whitelistedLoanCurrencys[_loanCurrencyAddress];

        emit LoanCurrencyUnlisted(_loanCurrencyAddress, name, block.timestamp);
    }

    /**
     * @notice This function can be called by Anyone to know the LoanCurrency is listed in Whitelist or not.
     *
     * @param _loanCurrencyAddress - The address of the LoanCurrency contract.
     *
     * @return Returns whether the LoanCurrency is whitelisted
     */
    function _isLoanCurrencyWhitelisted(address _loanCurrencyAddress)
        internal
        view
        returns (bool)
    {
        return
            whitelistedLoanCurrencys[_loanCurrencyAddress]
                .loanCurrencyAddress != address(0);
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
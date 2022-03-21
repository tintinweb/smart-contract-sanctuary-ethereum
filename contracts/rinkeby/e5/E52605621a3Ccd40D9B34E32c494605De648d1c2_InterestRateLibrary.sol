// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IInterestRateLibrary.sol";

/// @dev The contract stores the values of the second rates,
/// which were calculated by the formula ((1 + x) ^ (1/31536000) -1)
contract InterestRateLibrary is IInterestRateLibrary, Ownable {
    // interest rate percent per year (with precision 10) => interest rate percent per second
    mapping(uint256 => uint256) public override ratesPerSecond;

    uint256 public override maxSupportedPercentage;

    constructor(uint256[] memory _exactRatesPerSecond) {
        uint256 _limitOfExactValues = getLimitOfExactValues();

        require(
            _exactRatesPerSecond.length == _limitOfExactValues,
            "InterestRateLibrary: Incorrect number of exact values."
        );

        // Add exact values
        _addRates(1, _exactRatesPerSecond, 1);
    }

    function addNewRates(uint256 _startPercentage, uint256[] calldata _ratesPerSecond)
        external
        override
        onlyOwner
    {
        uint256 _libraryPrecision = getLibraryPrecision();

        require(
            _startPercentage == maxSupportedPercentage + _libraryPrecision,
            "InterestRateLibrary: Incorrect starting percentage to add."
        );

        _addRates(_startPercentage, _ratesPerSecond, _libraryPrecision);
    }

    function getLibraryPrecision() public view virtual override returns (uint256) {
        return 10;
    }

    function getLimitOfExactValues() public view virtual override returns (uint256) {
        return 10 * getLibraryPrecision();
    }

    function _addRates(
        uint256 _startPercentage,
        uint256[] memory _ratesPerSecond,
        uint256 _precision
    ) internal virtual {
        uint256 _listLengthWithPrecision = _ratesPerSecond.length * _precision;

        for (uint256 i = 0; i < _listLengthWithPrecision; i += _precision) {
            ratesPerSecond[_startPercentage + i] = _ratesPerSecond[i / _precision];
        }

        maxSupportedPercentage = _startPercentage + _listLengthWithPrecision - _precision;
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

/**
 * This contract is needed to store and obtain the second rates of their annual rates
 */
interface IInterestRateLibrary {
    /// @notice Function for adding new values to the interest rate library
    /// @dev Only contract owner can call this function
    /// @param _startPercentage Percentage at which the addition will start
    /// @param _ratesPerSecond an array with second rates
    function addNewRates(uint256 _startPercentage, uint256[] calldata _ratesPerSecond) external;

    /// @notice The function returns the second rate for the passed annual rate
    /// @param _annualRate annual rate to be converted
    /// @return _ratePerSecond converted second rate
    function ratesPerSecond(uint256 _annualRate) external view returns (uint256 _ratePerSecond);

    /// @notice The function returns the library precision
    /// @dev For default library precision equals to 10^1
    /// @return _libraryPrecision current library precision
    function getLibraryPrecision() external view returns (uint256 _libraryPrecision);

    /// @notice The function returns the limit of exact values with current library precision
    /// @return limit of exact values
    function getLimitOfExactValues() external view returns (uint256);

    /// @notice The function returns the current max supported percentage
    /// @return max supported percentage with library decimals
    function maxSupportedPercentage() external view returns (uint256);
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
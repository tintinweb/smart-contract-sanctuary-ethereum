// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../libraries/Percent.sol";
import "../timelock/OwnableTimelock.sol";

contract FeeMinter is Ownable, OwnableTimelock {
    /// Overall rate at which to mint new tokens
    uint256 public totalToMintPerBlock;

    /// Owner approved minters with assigned toMintPercents
    address[] public minters;

    /// Decimal points of precision to use with percents
    uint256 public decimals;

    // Version of the toMintPercent mapping
    uint32 private _version;
    
    // Map approved minter address to a percent of totalToMintPerBlock rate
    mapping(bytes32 => uint256) private _toMintPercent;

    // Emitted when a new totalToMintPerBlock is set
    event SetTotalToMintPerBlock(address indexed setter, uint256 indexed totalToMintPerBlock);

    // Emitted whan decimals is set
    event SetDecimals(address indexed sender, uint256 indexed decimals);

    // Emitted when new minters are assigned toMintPercents
    event SetToMintPercents(
        address indexed setter,
        address[] indexed minters,
        uint256[] indexed toMintPercents,
        uint32 version
    );

    constructor(uint256 _totalToMintPerBlock) {
        totalToMintPerBlock = _totalToMintPerBlock;
        decimals = 2;   // default to 2 decimals of precision, i.e. 100.00%
    }

    /// Set the _totalToMintPerBlock rate
    function setTotalToMintPerBlock(uint256 _totalToMintPerBlock) external onlyTimelock {
        totalToMintPerBlock = _totalToMintPerBlock;
        emit SetTotalToMintPerBlock(msg.sender, _totalToMintPerBlock);
    }

    /// Set the toMintPercent for each minter in _minters
    function setToMintPercents(address[] calldata _minters, uint256[] calldata _toMintPercents) 
        external 
        onlyTimelock 
    { 
        require(_minters.length == _toMintPercents.length, "FeeMinter: array length mismatch");

        // Increment the version and delete the previous mapping
        _version++;

        // Maintain a running tally of percents to enforce that they sum to 100
        uint256 percentSum;

        uint256 length = _minters.length;
        for (uint256 i = 0; i < length; i++) {
            address minter = _minters[i];
            require(minter != address(0), "FeeMinter: zero address");

            uint256 toMintPercent = _toMintPercents[i];
            percentSum += toMintPercent;
            require(percentSum <= _percent(), "FeeMinter: percent sum exceeds 100");

            _toMintPercent[_key(minter)] = toMintPercent;
        }
        require(percentSum == _percent(), "FeeMinter: percents do not total 100");

        minters = _minters;

        emit SetToMintPercents(
            msg.sender,
            _minters,
            _toMintPercents,
            _version
        );
    }

    // Set the number of _decimal points of precision used by percents
    function setDecimals(uint256 _decimals) external onlyOwner {
        decimals = _decimals;
        emit SetDecimals(msg.sender, _decimals);
    }
    
    /// Return the toMintBlock rate for _minter
    function getToMintPerBlock(address _minter) external view returns (uint256) {
        uint256 toMintPercent = getToMintPercent(_minter);
        return Percent.getPercentage(totalToMintPerBlock, toMintPercent, decimals);
    }

    /// Return the array of approved minter addresses
    function getMinters() external view returns (address[] memory) {
        return minters;
    }

    /// Return the toMintPercent for _minter
    function getToMintPercent(address _minter) public view returns (uint256) {
        return _toMintPercent[_key(_minter)];
    }

    // Return a key to the toMintPercent mapping based on _version and _minter
    function _key(address _minter) private view returns (bytes32) {
        return keccak256(abi.encodePacked(_version, _minter));
    }

    // Return the expected percent based on decimals being used
    function _percent() private view returns (uint256) {
        return 100 * (10 ** decimals);
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

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

library Percent {
    uint256 public constant MAX_PERCENT = 100;

    modifier onlyValidPercent(uint256 _percent, uint256 _decimals) {
        require(_isValidPercent(_percent, _decimals), "Percent: invalid percent");
        _;
    }

    // Return true if the _percent is valid and false otherwise
    function isValidPercent(uint256 _percent)
        internal
        pure
        returns (bool)
    {
        return _isValidPercent(_percent, 0);
    }

    // Return true if the _percent with _decimals many decimals is valid and false otherwise
    function isValidPercent(uint256 _percent, uint256 _decimals)
        internal
        pure
        returns (bool)
    {
        return _isValidPercent(_percent, _decimals);
    }

    // Return true if the _percent with _decimals many decimals is valid and false otherwise
    function _isValidPercent(uint256 _percent, uint256 _decimals)
        private
        pure
        returns (bool)
    {
        return _percent <= MAX_PERCENT * 10 ** _decimals;
    }

    // Return _percent of _amount
    function getPercentage(uint256 _amount, uint256 _percent)
        internal 
        pure
        returns (uint256 percentage) 
    {
        percentage = _getPercentage(_amount, _percent, 0);
    }

    // Return _percent of _amount with _decimals many decimals
    function getPercentage(uint256 _amount, uint256 _percent, uint256 _decimals)
        internal 
        pure
        returns (uint256 percentage)
    {
        percentage =_getPercentage(_amount, _percent, _decimals);
    }

    // Return _percent of _amount with _decimals many decimals
    function _getPercentage(uint256 _amount, uint256 _percent, uint256 _decimals) 
        private
        pure
        onlyValidPercent(_percent, _decimals) 
        returns (uint256 percentage)
    {
        percentage = _amount * _percent / (MAX_PERCENT * 10 ** _decimals);
    }

    // Return _percent of _amount as the percentage and the remainder of _amount - percentage
    function splitByPercent(uint256 _amount, uint256 _percent) 
        internal 
        pure 
        returns (uint256 percentage, uint256 remainder) 
    {
        (percentage, remainder) = _splitByPercent(_amount, _percent, 0);
    }

    // Return _percent of _amount as the percentage and the remainder of _amount - percentage
    // with _decimals many decimals
    function splitByPercent(uint256 _amount, uint256 _percent, uint256 _decimals)
        internal 
        pure
        returns (uint256 percentage, uint256 remainder)
    {
        (percentage, remainder) = _splitByPercent(_amount, _percent, _decimals);
    }

    // Return _percent of _amount as the percentage and the remainder of _amount - percentage
    // with _decimals many decimals
    function _splitByPercent(uint256 _amount, uint256 _percent, uint256 _decimals)
        private
        pure
        onlyValidPercent(_percent, _decimals)
        returns (uint256 percentage, uint256 remainder)
    {
        percentage = _getPercentage(_amount, _percent, _decimals);
        remainder = _amount - percentage;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

abstract contract OwnableTimelock {
    error CallerIsNotTimelockOwner();
    error ZeroTimelockOwnerAddress();

    address private _timelockOwner;

    event TimelockOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferTimelockOwnership(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyTimelock() {
        _checkTimelockOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function timelockOwner() public view virtual returns (address) {
        return _timelockOwner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkTimelockOwner() internal view virtual {
        if (msg.sender != timelockOwner()) revert CallerIsNotTimelockOwner();
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceTimelockOwnership() public virtual onlyTimelock {
        _transferTimelockOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferTimelockOwnership(address newOwner) public virtual onlyTimelock {
        if (newOwner == address(0)) revert ZeroTimelockOwnerAddress();
        _transferTimelockOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferTimelockOwnership(address newOwner) internal virtual {
        address oldOwner = _timelockOwner;
        _timelockOwner = newOwner;
        emit TimelockOwnershipTransferred(oldOwner, newOwner);
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
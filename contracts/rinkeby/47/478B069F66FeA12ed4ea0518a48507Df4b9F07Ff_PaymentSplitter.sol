//SPDX-License-Identifier: MIT.
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PaymentSplitter is Ownable {

    uint256 public constant PERCENTAGE_FACTOR = 10000;

    address[] public accounts;
    mapping(address => uint256) public accountShares;

    event SetAccounts(address[] accounts, uint256[] shares);
    event PaymentReceived(uint256 amount);

    constructor(address[] memory _accounts, uint256[] memory _shares) {
        _setAccounts(_accounts, _shares);
    }

    modifier onlyAuthorized() {
        require(msg.sender == owner() || accountShares[msg.sender] > 0, "Error: Caller not authorized");
        _;
    }

    function resetAccounts(address[] memory _accounts, uint256[] memory _shares) external onlyOwner {
        _deleteAccounts();
        _setAccounts(_accounts, _shares);
    }

    function _deleteAccounts() internal {
        for (uint256 i = 0; i < accounts.length; i++) {
            accountShares[accounts[i]] = 0;
        }

        delete accounts;
    }

    function _setAccounts(address[] memory _accounts, uint256[] memory _shares) internal {
        require(_accounts.length == _shares.length, "Error: Array lengths do not match");

        uint256 total;
        for (uint256 i = 0; i < _shares.length; i++) {
            require(_accounts[i] != address(0), "Error: account is the null address");
            total += _shares[i];
        }

        require(total == PERCENTAGE_FACTOR, "Error: shares do not add up to 100%");

        accounts = _accounts;

        for (uint256 i = 0; i < _accounts.length; i++) {
            accountShares[_accounts[i]] = _shares[i];
        }

        emit SetAccounts(_accounts, _shares);
    }

    function withdraw() external onlyAuthorized {
        uint256 balance = address(this).balance;
        require(balance > 0, "Error: Contract balance is null");

        for (uint256 i = 0; i < accounts.length; i++) {
            (bool success,) = payable(accounts[i]).call{value: balance * accountShares[accounts[i]] / PERCENTAGE_FACTOR}("");
            require(success);
        }
    }

    receive() external payable {
        emit PaymentReceived(msg.value);
    }

    function getAccounts() external view returns(address[] memory) {
        return accounts;
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
/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/Payments.sol


pragma solidity ^0.8.15;


contract Payments is Ownable {
    struct Employee {
        uint256 salaryAmount;
        uint256 dateOfInit;
        uint256 nextPayment;
    }
    mapping(address => Employee) mappingOfEmployees;
    address[] public listOfEmployees;

    event NewEmployee(address employee, uint256 salary, uint256 nextPayment);

    function addEmployee(address employeeAdress, uint256 salaryAmount)
        public
        onlyOwner
    {
        uint256 _currentBlock = block.number;
        uint256 _nextPayment = nextPayment(block.number);
        listOfEmployees.push(employeeAdress);
        mappingOfEmployees[employeeAdress] = Employee(
            salaryAmount,
            _currentBlock,
            _nextPayment
        );

        emit NewEmployee(employeeAdress, salaryAmount, _nextPayment);
    }

    function salary(address employeeAdress) public view returns (uint256) {
        return mappingOfEmployees[employeeAdress].salaryAmount;
    }

    function nextPayment(address employeeAddress)
        public
        view
        returns (uint256)
    {
        return mappingOfEmployees[employeeAddress].nextPayment;
    }

    function nextPayment(uint256 dateOfInit) private pure returns (uint256) {
        uint256 blockTimeInSeconds = 15;
        uint256 hourInSeconds = 3600;
        uint256 dayInHours = 24;
        uint256 mounthInDays = 30;
        uint256 monthInSecond = mounthInDays * dayInHours * hourInSeconds;
        return dateOfInit + (monthInSecond / blockTimeInSeconds);
    }

    function deposit() public payable onlyOwner {}

    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    function cust() public view returns (uint256) {
        uint256 totalCust = 0;
        for (uint256 i = 0; i < listOfEmployees.length; i++) {
            totalCust += mappingOfEmployees[listOfEmployees[i]].salaryAmount;
        }
        return totalCust;
    }

    function employees() public view onlyOwner returns (address[] memory) {
        return listOfEmployees;
    }
}
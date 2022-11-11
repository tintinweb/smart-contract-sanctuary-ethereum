// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol"; // El owner del contrato va a ser el que lo despliegue

interface IERC20 {
    
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address _to, uint256 _value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);

}

contract Payments is Ownable {

    IERC20 usdt;

    constructor() {
        usdt = IERC20(address(0x0BBb231D2CA20020D5a7db92Eb343cf5cF5F1949));  //USDT in BSC testnet

        // //Test only
        // employeesArray.push(Employees(123123213, 2000000000000000000, payable(0x075D29D70FF3d5AD1a2569bba6F581CBf2be7Cee), Status.Enable));
        // employeesArray.push(Employees(567567564, 1000000000000000000, payable(0xE82b3de5C6cBbF102a168126C730C98952a7E37f), Status.Disable));
        // employeesArray.push(Employees(836554912, 1000000000000000000, payable(0x62C9511E06b0Aca785e69B5f81c29DF4AfB4F71B), Status.Enable));

        // bonusArray.push(Bonus(197479294, 800, payable(0xdD870fA1b7C4700F2BD7f44238821C26f7392148)));
        // bonusArray.push(Bonus(666666666, 300, payable(0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7)));
    }

    enum Status {
        Enable,
        Disable
    }

    struct Employees {
        uint ID;
        uint amount;
        address payable addressUser;
        Status status;
    }

    Employees[] public employeesArray;

    struct Bonus {
        uint ID;
        uint amount;
        address payable addressUser;
    }

    Bonus[] private bonusArray;

    //----------------Create, Delete and Get Data employees

    function createEmployees(uint _ID, uint _amount, address payable _addressUser) onlyOwner public {
        employeesArray.push(Employees(_ID, _amount, _addressUser, Status.Enable));
    }

    function deleteEmployees(uint _index) onlyOwner public {
        employeesArray[_index] = employeesArray[employeesArray.length - 1];
        employeesArray.pop();
    }

    function getDataEmployees(uint _ID) onlyOwner public view returns(uint index ,uint amount, address addressUser, Status status) {
        uint arrayLength = employeesArray.length;
        for (uint i = 0; i < arrayLength; i++) { 
            if (employeesArray[i].ID == _ID) {
                index = i;
                amount = employeesArray[i].amount;
                addressUser = employeesArray[i].addressUser;
                status = employeesArray[i].status;
            } else {
                i+1;
                continue;
            } 
        }
    }

    //----------------Create, Delete and Get Data bonuses

    function createBonus(uint _ID, uint _amount, address payable _addressUser) onlyOwner public {
        bonusArray.push(Bonus(_ID, _amount, _addressUser));
    }

    function deleteBonus(uint _index) onlyOwner public {
        bonusArray[_index] = bonusArray[bonusArray.length - 1];
        bonusArray.pop();
    }

    function getDataBonus(uint _ID) onlyOwner public view returns(uint index ,uint amount, address addressUser) {
        uint arrayLength = bonusArray.length;
        for (uint i = 0; i < arrayLength; i++) { 
            if (bonusArray[i].ID == _ID) {
                index = i;
                amount = bonusArray[i].amount;
                addressUser = bonusArray[i].addressUser;
            } else {
                i+1;
                continue;
            } 
        }
    }

    //-----------------Change Status, Approve, Get Contract Balance

    function changeStatus(uint _index, uint _value) onlyOwner public {
        employeesArray[_index].status = Status(_value);
    }

    function approveUsdt(address _spender, uint256 _amount) onlyOwner public {
        usdt.approve(_spender, _amount);
    }

    function getContractBalance() public view returns (uint) {
        return usdt.balanceOf(address(this));
    }

    //----------------Payments salary
    
    function salaryPay(uint _index) onlyOwner public payable returns (string memory status) {
        if (employeesArray[_index].status == Status.Enable) {
            uint amount = employeesArray[_index].amount;
            address payable addressUser = employeesArray[_index].addressUser;

            usdt.transfer(addressUser, amount);
        } else {
            status = "Status disable";
            return status;
        }
    }

    function salaryPayments() onlyOwner public payable {
        uint arrayLength = employeesArray.length;
        for (uint i=0; i<arrayLength; i++) {
            salaryPay(i);
            i+1;
        }
    }

    //----------------Payments bonus

    function bonusPays(uint _index) onlyOwner public payable {
        uint amount = bonusArray[_index].amount;
        address payable addressUser = bonusArray[_index].addressUser;

        usdt.transfer(addressUser, amount);
    }

    function bonusPayments() onlyOwner public payable {
        uint arrayLength = bonusArray.length;
        for (uint i=0; i<arrayLength; i++) {
            bonusPays(i);
            i+1;
        }
        delete bonusArray;    //Restart array
    }
  
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
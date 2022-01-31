// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";

/*
* @title operation of a simple decentralized bank
* @author nobodyw, https://github.com/nobodyw
* @notice contract allows you to deposit funds, see your balance, withdraw your funds
* @dev the funds used are fictitious funds and in no case ERC-20
*/
contract Bank is Ownable{
    mapping(address => uint) _balances;

    event Deposit(uint _amount);
    event Transfer(address payable _recipient, uint _amount);

/*
* @notice deposit allows to deposit a value in the contract
* @dev the funds used are fictitious funds and in no case ERC-20
*/
    function deposit(uint _amount) public payable{
        require(_amount > 0, "The amount is to low");
        _balances[msg.sender] += _amount;
        emit Deposit(_amount);
    }

/*
* @notice allows to see the balance in the contract in relation to our user address
*/
    function balanceOf(address _address) external view returns(uint){
        return _balances[_address];
    }

    /*
    * @notice allows you to send funds to any address
* @dev the funds used are fictitious funds and in no case ERC-20
*/
    function transfer(address payable _recipient, uint _amount) public payable{
        require(_amount > 0, "The amount is to low");
        require(msg.sender != _recipient,'transfer only works with an account other');
        require(_balances[msg.sender] >= _amount,"You lack funds");
        require(_balances[_recipient] + _amount >= _balances[_recipient],"nous avons un probleme lors de votre transfer d'argent");

        _balances[msg.sender] -= _amount;
        _balances[_recipient] += _amount;
        emit Transfer(_recipient, _amount);
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
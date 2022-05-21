// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CoinFlip is Ownable {
    uint public houseEdge;
    uint public houseBalance;
    address payable public houseHolder;
    mapping (address => uint) public balance;

    event balanceChanged(address sender, uint newBalance);

    constructor() {
        houseEdge = 5;
        houseHolder = payable(msg.sender);
    }

    // Functions for balance handling and viewing
    // Lets user to add balance into their account

    function addBalance() public payable {
        require(msg.value >= 0.1 ether, "You should send at least 0.1 ether");
        balance[msg.sender] += (msg.value * (100 - houseEdge)) / 100;
        houseBalance += (msg.value * houseEdge) / 100;
        emit balanceChanged(msg.sender, balance[msg.sender]);
    }

    // Returns all the value stored in contract

    function getContractBalance() public onlyOwner view returns (uint) {
        return address(this).balance;
    }

    // Returns player balance

    function getPlayerBalance() public view returns(uint) {
        return balance[msg.sender];
    }

    // CHanges House Holder

    function changeHouseHolder(address payable _newHolder) public onlyOwner {
        houseHolder = _newHolder;
    }



    //Changes House Edge

    function changeHouseEdge(uint _newEdge) public onlyOwner {
        require(_newEdge < 90);
        houseEdge = _newEdge;
    }



    //Gameplay functionality

    function play(uint _guess, uint _amount) public returns(uint) {
        require(_guess == 1 || _guess == 0, "Your guess should be 0 or 1");
        require(balance[msg.sender] >= 10 ** 13, "You dont have enough ether to play");
        require(_amount >= 100000000000000000, "You should at least play with 0.1 ether");
        require(balance[msg.sender] >= _amount, "You dont have this much of ether");

        //Generates a random value this is poorly coded
        uint _res = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, [0,1]))) % 2;
        
        //Checks if player's guess is true
        //Handles the logic based on the result
        if(_res == _guess){
            balance[msg.sender] += _amount;
        } else {
            houseBalance += _amount;
            balance[msg.sender] -= _amount;
        }

        //Sends new balance
        emit balanceChanged(msg.sender, balance[msg.sender]);
        return _res;
    }




    // Withdrawal functions

    function withdrawPlayerBalance(bool _all, uint _amount) public {
        require(balance[msg.sender] > 0);
        if(_all){
            require(address(this).balance - houseBalance >= balance[msg.sender], "We don't have enough ether to pay you back :). This will be fixed in short time.");
            payable(address(msg.sender)).transfer(balance[msg.sender]);
            balance[msg.sender] = 0;
        } else {
            require(balance[msg.sender] >= _amount, "You dont have this much of ether on you balance");
            payable(address(msg.sender)).transfer(_amount);
            balance[msg.sender] = balance[msg.sender] - _amount;
        }
        emit balanceChanged(msg.sender, balance[msg.sender]);
    }


    function withdrawHouseBalance() public onlyOwner {
        houseHolder.transfer(houseBalance);
        houseBalance = 0;
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
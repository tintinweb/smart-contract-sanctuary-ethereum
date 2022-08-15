//SPDX-License-Identifier: Unlicense

// contracts/BuyMeACoffee.sol
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

// Switch this to your own contract address once deployed, for bookkeeping!
// Example Contract Address on Goerli: 0x77701a42289bcf1834D217ffaA28CFD909b599c8

contract BuyMeACoffee is Ownable {
    uint256 public constant priceLargeCoffee = 0.003 ether;
    string public constant regularCoffee = "Regular Coffee";
    string public constant largeCoffee = "Large Coffee";

    // Event to emit when a Memo is created.
    event NewMemo(
        address indexed from,
        uint256 timestamp,
        string name,
        string message,
        string coffeesize
    );

    address payable withdrawAddress;
    address payable _owner;

    // Memo struct.
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
        string coffeesize;
    }

    // Address of contract deployer. Marked payable so that
    // we can withdraw to this address later.

    // List of all memos received from coffee purchases.
    Memo[] memos;

    constructor() {
        // Store the address of the deployer as a payable address.
        // When we withdraw funds, we'll withdraw here.
        _owner = payable(msg.sender);
        withdrawAddress = payable(msg.sender);
    }

    modifier onlyWithdrawer() {
        require(msg.sender == withdrawAddress);
        _;
    }

    /**
     * @dev fetches all stored memos
     */
    function getMemos() public view returns (Memo[] memory) {
        return memos;
    }

    /**
     * @dev buy a coffee for owner (sends an ETH tip and leaves a memo)
     * @param _name name of the coffee purchaser
     * @param _message a nice message from the purchaser
     */
    function buyCoffee(string memory _name, string memory _message)
        public
        payable
    {
        // Must accept more than 0 ETH for a coffee.
        require(msg.value > 0, "can't buy coffee for free!");
        string memory _coffeesize = regularCoffee;

        // Add the memo to storage!
        memos.push(
            Memo(msg.sender, block.timestamp, _name, _message, _coffeesize)
        );

        // Emit a NewMemo event with details about the memo.
        emit NewMemo(msg.sender, block.timestamp, _name, _message, _coffeesize);
    }

    function buyLargeCoffee(string memory _name, string memory _message)
        public
        payable
    {
        // Must accept more than 0.003 ETH for a Largecoffee.
        require(
            msg.value >= priceLargeCoffee,
            "can't buy a large coffee for less than 0.003 ether!"
        );

        // set size of coffee
        string memory _coffeesize = largeCoffee;

        // Add the memo to storage!
        memos.push(
            Memo(msg.sender, block.timestamp, _name, _message, _coffeesize)
        );

        // Emit a NewMemo event with details about the memo.
        emit NewMemo(msg.sender, block.timestamp, _name, _message, _coffeesize);
    }

    function withdrawTipsToOwner() public onlyOwner {
        require(_owner.send(address(this).balance));
    }

    function withdrawTipsToSetWithdrawAddress() public onlyOwner {
        require(withdrawAddress.send(address(this).balance));
    }

    function withdrawTipsToOther(address payable _to, uint256 _amount)
        public
        onlyOwner
    {
        _to.transfer(_amount);
    }

    function setWithdrawAddress(address payable newWithdrawAddress)
        public
        onlyOwner
    {
        withdrawAddress = newWithdrawAddress;
    }
}
/**
 * @dev send the entire balance stored in this contract to the owner
 */
// This code, should not be limited to ownner.
// This code, should be set to owner, only owner can set new.
// Maybe use inspiration of setter and getter methods.
/*function withdrawTips() public {
        require(owner.send(address(this).balance));
    }*/

/*

    function withdrawTips() external onlyWithdrawer {
        _withdraw();
    }

    function setWithdrawAddress(address newWithdrawAddress) public onlyOwner {
        _withdrawAddress = newWithdrawAddress;
    }

    function _withdraw() public onlyOwner {
        payable(_withdrawAddress).transfer(address(this).balance);
    }

    function getWithdrawAdress() public view returns (string memory) {
        return _withdrawAddress;
    }
}

*/
/*
    function withdrawTips() public _ownerOnly {
        require(withdrawAddress.send(address(this).balance));
        _withdraw();
    }
    


    function setWithdrawAdress(address _withdrawAddress)
        public
        payable
        _ownerOnly
    {
        withdrawAddress = _withdrawAddress;
    }
}

*/
/*


    
// Implementing a function to set the withdraw address.
    // Must only be set by the owner of the contract.
    

    // Add this to constructor
    address withdrawAddress = owner;



}
*/

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
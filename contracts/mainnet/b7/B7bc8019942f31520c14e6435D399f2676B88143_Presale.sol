// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Presale is Ownable{
    using Counters for Counters.Counter;
    Counters.Counter private _prepayCounter;

    event Preordered(address indexed to, uint256 payerId);  

    uint256 public constant MAX_PREPAID = 4000;
    uint256 public prepaymentCost = 150000000000000000;
    uint256 constant paymentToCreator = 10;
    uint256 public paidToCreator;
    uint256 constant maxToCreator = 35 ether;
    
    bool public creatorPaidOff = false;
    bool public paused = false;

    address payable private _creator;
    address[] public prepaidUsers;

    mapping (address => bool) private preorder;

    constructor(address payable creator){
        _creator = creator;
    }


    modifier whenNotPaused(){
        require(paused == false, "Contract Paused");
        _;
    }

    function prePay() public payable whenNotPaused {
        require(msg.value >= prepaymentCost, "Insufficient payment");
        require(_prepayCounter.current() <= MAX_PREPAID - 1, "Max reached");
        require(!preorder[msg.sender], "Max preorder is 1");
        if(creatorPaidOff == false){
            uint256 creatorPaymentAmount = msg.value * (paymentToCreator);
            if(paidToCreator + (creatorPaymentAmount/100) <= maxToCreator) {
                paidToCreator += (creatorPaymentAmount/100);
                _creator.transfer((creatorPaymentAmount/100));
            } else {
                uint256 amtLeftToPay = maxToCreator - paidToCreator;
                paidToCreator += amtLeftToPay;
                creatorPaidOff = true;
                _creator.transfer(amtLeftToPay);
            }
        }

        prepaidUsers.push(msg.sender);
        preorder[msg.sender] = true;
        _prepayCounter.increment();

        emit Preordered(msg.sender, _prepayCounter.current());
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setPrepayCost(uint256 cost) public onlyOwner {
        prepaymentCost = cost;
    }

    function totalPrepaid() public view returns (uint256) {
        return _prepayCounter.current();
    }

    function getBalance() public view returns (uint256){
        return address(this).balance;
    }

    function isPreordered(address account) public view returns (bool){
        return preorder[account];
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function getAllPrepaid() public view returns (address[] memory){
        address[] memory orderAddresses = new address[](prepaidUsers.length);
        
        for (uint256 i = 0; i < prepaidUsers.length; i++){
            orderAddresses[i] = prepaidUsers[i];
        }
        return orderAddresses;
    }

    function getCreatorPayment() public view returns (uint256){
        uint256 amtLeftToPay = maxToCreator - paidToCreator;
        return amtLeftToPay;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Confer is Ownable {

    uint public rate;
    address payable public student;
    address payable public expert;


    enum State { Inactive, Created, Locked, Release }

    State public state;

    modifier condition(bool condition_) {
        require(condition_);
        _;
    }


    /// Only the student can call this function.
    error StudentOnly();


    //// This function cannot be called in the current transaction state. 
    error InvalidState();



    modifier onlyStudent() {
        if (msg.sender != student)
            revert StudentOnly();
        _;
    }

    
    modifier inState(State state_) {
        if (state != state_)
            revert InvalidState();
        _;
    }

    event ExpertCancelled();
    event StudentDeposited();
    event MeetingDone();
    event ExpertPaid();


    //Expert can only cancel if a student has not deposited yet
     function expertCancel() external onlyOwner inState(State.Created){
        emit ExpertCancelled();
        state = State.Inactive;
        expert.transfer(address(this).balance);
        
    }


    function setHourlyRate(uint256 _rate) external onlyOwner inState(State.Inactive) {
       rate = _rate;
    }

    function expertDeposit() external onlyOwner payable {
        require(msg.value == (2 * rate), "Please deposit your double hourly rate");
        expert = payable(msg.sender);
        state = State.Created;
    }

    function studentDeposit() external payable inState(State.Created) {
        emit StudentDeposited();
        student = payable(msg.sender);
        require(msg.value == (2 * rate), "Please deposit double the hourly rate");
        state = State.Locked;
        
    }


   function getContractBalance() external view returns (uint256) {
        return address(this).balance;
   }

    function confirmMeetingHappened()external onlyStudent inState(State.Locked) {
        emit MeetingDone();
        state = State.Release;
        student.transfer(rate);
    }

    function payExpert() external onlyOwner inState(State.Release) {
        emit ExpertPaid();
        state = State.Inactive;
        expert.transfer(3 * rate);
    }


}
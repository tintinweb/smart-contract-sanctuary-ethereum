pragma solidity ^0.8.2;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";


/*

    OUR GOAL: to make sure that coffee laborers in El Salvador are being paid a fare
    wage using blockchain technology.  We're using a blockchain because blockchains are 
    irrefutable.  When a transaciton is on chain, nobody can refute the transaction.  
    So what functionality do we need to be irrefutable (on chain) to accomplish our goal?  
    The payment of workers is one function that needs to be irrefutable.  Also, we need 
    a function to indicate that a worker did indeed work each day so the public can 
    compare the amount of days they worked to the amount they were paid.  Foremen handle 
    checking in workers each day and farms handle the paying of wages to workers.  This is the
    core functionality of our minimum viable product.  I wrote this contract to accomplish
    just our MVP.
    
    'farms' and 'foremen' in this contract are treated like a role for access control purposes.
    Only addresses that are farms should be allowed to pay workers and assign addresses to foremen roles.
    Only addresses that are foremen should be allowed to check in workers.

    This contract handles farms, foremen, and workers all as individual addresses
    and not large structs with multiple parameters.  Associating a farm or foreman
    with a region or a name can be handled by the frontend at the time of the farm
    or foreman creation (indicated by the events that are emitted) assuming that 
    these functions are also only being called by the frontend.  Frontend should 
    also handle querying of relationships because this isn't needed in our MVP.

    TEAM DISCUSSION QUESTION:
        Why do we need a foreman to be associated with a farm in contract?  
            As far as I can see, there isn't a need to get the farm when given a foreman in this MVP
            contract.  Which foremen work at which farm isn't an issue that we're trying to solve
            irrefutably, so can't this association just be handled by the frontend when an event is emitted?
        

*/
contract coffee is Ownable{

    event newFarm(address farmAddress);
    event newForeman(address farmAddress, address foreman);
    event workerCheckedIn(address foreman, address worker, string date);
    event workerPaid(address farm, address worker, uint amount);

    // Modifier to add to functions that only a farm address can call.
    // Checks isFarm to see if that address is mapped to 'true', indicating
    // that it is a farm.
    // If the address is mapped to a false value (the address isn't a farm)
    // the caller won't be able to use the function with this 'onlyFarm'
    // modifier attatched.
    modifier onlyFarm {
        require(isFarm[msg.sender]);
        _;
    }

    // Modifier to add to functions that only foremen can call.
    // Checks isForemen function to see if the address is mapped to 'true',
    // indicating that it is a foreman.
    // If the address is mapped to a false value (the address isn't a foreman)
    // the caller won't be able to use the function with this 'onlyForeman'
    // modifier attatched.   
    modifier onlyForeman {
        require(isForeman[msg.sender]);
        _;
    }

    // Mapping to indicate if an address is a farm.
    // Can use this to verify an address is a farm.
    // 'bool' starts as false by default, and is set to true
    // in the newFarm function. 
    mapping(address => bool) isFarm;

    // Only the owner (admin) can call this function to create a new farm.
    // TODO: maybe any address should be able to call this to create their
    // own farm.
    function createFarm(address _farmAddress) public onlyOwner {
        // Adds the _farmAddress to the mapping and sets boolean as true,
        // indicating that this address is a farm.
        isFarm[_farmAddress] = true;

        emit newFarm(_farmAddress);
    }

    // Returns true if the _maybeFarm address is a farm, false otherwise.
    function isAddressFarm(address _maybeFarm) public view returns(bool){
        return isFarm[_maybeFarm];
    }


    // Mapping for verifying an address is a foreman.
    // Used in onlyForeman modifier.
    mapping(address => bool) isForeman;

    // Is to be called by a farm address to create a new foreman for that farm.
    // 'address _foremanAddress' is the address of the foreman to be added to the farm.
    function createForeman(address _foremanAddress) public onlyFarm {

        // Additionally sets the isForeman mapping to true.
        isForeman[_foremanAddress] = true;

        // Emits event to frontend with the farm address and the foreman address.
        // The frontend should save this association.
        emit newForeman(msg.sender, _foremanAddress);
    }

    // Returns true if address is a foreman, false otherwise.
    function isAddressForeman(address _maybeForeman) public view returns(bool){
        return isForeman[_maybeForeman];
    }


/*

    Paying workers and checking in.

    We have the issue of wanting to be able to keep track of which days the worker
    checked in, and which days they're paid for.  This is difficult and expensive 
    to do on chain.  I think we can solve this by handling most of it off chain which
    is okay to do because our goal in this project is simply irrefutably showing that the 
    worker got paid.  If somone wants to check which days a worker checked in, on the front
    end we can return a list of all emitted workerCheckedIn events for that address.  
    This verifier can then compare it to the list of all emitted workerPaid events (also 
    returned by front end) to makes sure it matches up correctly.

    For associating workers to foremen, this can also be handled in the frontend for now because
    we have no need to get a list of all workers for a foreman yet in this contract.  When the
    event workerCheckedIn(address foreman, address worker, string date) is called, the frontend
    can add the worker to an array of addresses for a worker.  If someone wanted to verify this,
    they could pull up a list of all the events emitted by the checkIn function, which logs the 
    foreman's address who is calling checkIn, the workers address, and the date.

*/


    // Mapping for keeping track of the dates that a worker has checked in
    mapping(address => string[]) daysCheckedIn;

    // The farm will call this function with the address of each worker
    // to pay and also the amount of days to pay them for.
    // Amount of days to pay them for is calculated in frontend.
    // Update the dates that the worker was paid for in the frontend.
    // Again, can be independently verified by anyone viewing the history
    // of the emitted events.
    function payWorker(address _worker) public payable onlyFarm {
        // Pays the worker and requires that it was successful,
        // otherwise it failed and the payment doesn't go through
        bool success = payable(_worker).send(msg.value);
        require(success, "Worker payment failed");

        // msg.sender is the farm paying the worker
        emit workerPaid(msg.sender, _worker, msg.value);
    }


    // Foreman calls checkIn with the worker address and the date.  The date is determined by the frontend.
    // Emits the workerCheckedIn event so the frontend can handle sorting which days the worker worked for,
    // and which days the worker is unpaid for.
    // TODO: what if a foreman forgets to check in workers on a certain date and they want to go back and
    // check them in later?
    // TODO: if the foreman can't be trusted with setting the proper date, then we can have a setDate
    // function that is only callable by the farm, and then in checkIn function we make a call to a 
    // getDate function to return the date.
    function checkIn(address _workerAddress, string memory _date) public onlyForeman {
        // We can handle the association between the worker and foreman in the frontend.
        // This function accomplishes the goal of foremen indicating irrefutably that a worker
        // worked on a particular day as only a foreman can call this function.
        
        // Adds the date argument to the string array at the worker's address
        daysCheckedIn[_workerAddress].push(_date);

        emit workerCheckedIn(msg.sender, _workerAddress, _date);
    }

    // Getter function to return the string array in the daysCheckedIn mapping
    function getDaysCheckedIn(address _workerAddress) public view returns(string[] memory){
        return daysCheckedIn[_workerAddress];
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
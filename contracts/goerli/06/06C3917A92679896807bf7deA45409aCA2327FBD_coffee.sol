pragma solidity ^0.8.2;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";

/** 
    @title: Verifying Fair Wages for Coffee Laborers in El Salvador
    @author: Lehigh University Chainbytes capstone project team
*/

/**
    OUR GOAL: to make sure that coffee laborers in El Salvador are being paid a fair
    wage using blockchain technology.  We're using a blockchain because blockchains are 
    irrefutable.  When a transaciton is on chain, nobody can refute the transaction.  
    So what functionality do we need to be irrefutable (on chain) to accomplish our goal?  
    The payment of workers is one function that needs to be irrefutable.  Also, we need 
    a function to indicate that a worker did indeed work each day so the public can 
    compare the amount of days they worked to the amount they were paid.  Foremen handle 
    checking in workers each day and farms handle the paying of wages to workers.  This is the
    core functionality of our minimum viable product.  We wrote this contract to accomplish
    just our MVP.
    
    'farms' and 'foremen' in this contract are treated like a role for access control purposes.
    Only addresses that are farms should be allowed to pay workers and assign addresses to foremen roles.
    Only addresses that are foremen should be allowed to check in workers.

    This contract handles farms, foremen, and workers all as individual addresses
    and not large structs with multiple parameters.     

*/
contract coffee is Ownable{

    /// Custom errors instead of require statement strings
    /// to save gas :)
    error AddressNotFarm();
    error AddressNotForeman();
    error WorkersAmountsMismatch();
    error WrongPaymentAmount();
    error PaymentFailed();
    error SendBackFailed();

    event newFarm(address farmAddress);
    event newForeman(address farmAddress, address foreman);
    event workerCheckedIn(address foreman, address worker, string date);
    event workerPaid(address farm, address worker, uint amount, string date);

    /**
        Modifier to add to functions that only a farm address can call.
        Checks isFarm to see if that address is mapped to 'true', indicating
        that it is a farm.
        If the address is mapped to a false value (the address isn't a farm)
        the caller won't be able to use the function with this 'onlyFarm'
        modifier attatched.
    */
    modifier onlyFarm {
        if(!isFarm[msg.sender]){
            revert AddressNotFarm();
        }
        _;
    }

    /**
        Modifier to add to functions that only foremen can call.
        Checks isForemen function to see if the address is mapped to 'true',
        indicating that it is a foreman.
        If the address is mapped to a false value (the address isn't a foreman)
        the caller won't be able to use the function with this 'onlyForeman'
        modifier attatched.   
    */
    modifier onlyForeman {
        if(!isForeman[msg.sender]){
            revert AddressNotForeman();
        }
        _;
    }

    /**
        Mapping to indicate if an address is a farm.
        bool starts as false by default.
        Used in onlyFarm modifier.
        Is set in createFarm(address _farmAddress). 
    */
    //have to make public for testing - Hudson
    mapping(address => bool) public isFarm;

    /**
        @notice Only the owner (admin) can call this function to create a new farm.
        Farms are created by the owner of the contract.  In the real world, the 
        owner will most likely be a multisig wallet.

        @param _farmAddress is the address to be given farm role permissions:
            creating foremen and paying workers
    */
    function createFarm(address _farmAddress) external onlyOwner {
        // Adds the _farmAddress to the mapping and sets boolean as true,
        // indicating that this address is a farm.
        isFarm[_farmAddress] = true;

        emit newFarm(_farmAddress);
    }

    /**
        Mapping for indicating an address is a foreman.
        Used in onlyForeman modifier. 
        Set in createForeman(address _foremanAddress).
    */
    //had to make public for testing - Hudson
    mapping(address => bool) public isForeman;

    /**
        @notice Is to be called by a farm address to create a new foreman for that farm.
        @param _foremanAddress is the address to be given foreman role permissions:
            checking in workers
    */
    function createForeman(address _foremanAddress) external onlyFarm {

        // Sets the isForeman mapping to true.
        isForeman[_foremanAddress] = true;

        // Emits event to frontend with the farm address and the foreman address.
        emit newForeman(msg.sender, _foremanAddress);
    }

    /**
        For paying workers and checking in we will leverage theGraph.

        We want to be able to keep track of which days the worker checked in, and 
        which days they're paid for.  This is difficult and expensive to do on chain.  
        We can solve this by handling payment history and worker/foreman/farm
        association in a subgraph, which is okay to do because our goal in this project is 
        simply irrefutably showing that the worker got paid.  If somone wants to check which 
        days a worker checked in, on the front end we can return a list of all emitted 
        workerCheckedIn and workerPaid events for that address by querying our subgraph.

        For associating workers to foremen, this can also be handled in our subgraph because
        we have no need to get a list of all workers for a foreman in this contract.  When the
        event workerCheckedIn(address foreman, address worker, string date) is called, the subgraph
        can add the worker to an array of addresses for a worker.  If someone wanted to verify this,
        they could simple query our subgraph for all workers associated with a foreman.
    */

    /**
        @notice The farm pays a group of workers.
        @param _workers is an array of the worker addresses to be paid
        @param _amounts is the array of amounts to pay to each worker.  Maps 1-to-1 to 
            the _workers array.  _workers[i] gets paid _amounts[i] currency.
        @param _date is the date of this function call.
        @dev If there is an issue with paying any worker, 
            the entire function call gets reverted.
    */
    function payWorkers(
        address[] calldata _workers, 
        uint[] calldata _amounts, 
        string calldata _date)
    external payable onlyFarm {

        // Since the _workers and _amounts length are essentially a mapping,
        // they should be the same length.
        if(!(_workers.length == _amounts.length)){
            revert WorkersAmountsMismatch();
        }

        // calculates the sum of the amounts array
        uint sumAmounts;
        for(uint i=0; i < _amounts.length; i++){
            sumAmounts += _amounts[i];
        }

        // requires the sum of the amounts array to be equal to
        if(!(sumAmounts*1e18 == msg.value)){
            revert WrongPaymentAmount();
        }

        // Declare varaible outside loop so we don't have to 
        // re-allocate the variable every loop.
        bool success;

        // Iterate through the array and pay all workers
        for(uint i=0; i < _workers.length; i++){

            // Pays the worker and requires that it was successful,
            // otherwise it failed and the payment doesn't go through
            success = payable(_workers[i]).send(_amounts[i]*1e18);
            
            if(!success){
                revert PaymentFailed();
            }
            emit workerPaid(msg.sender, _workers[i], _amounts[i], _date);
        }
    }

    /**
        @notice A foreman checks in a group of workers.
        @param _workers is an array of worker addresses to be checked in.
        @param _date the date the workers worked and are getting checked in for.
    */
    function checkIn(address[] calldata _workers, string calldata _date) external onlyForeman {
        // We can handle the association between the worker and foreman in the subgraph.
        // This function accomplishes the goal of foremen indicating irrefutably that a worker
        // worked on a particular day as only a foreman can call this function.

        for(uint i=0; i < _workers.length; i++){
            emit workerCheckedIn(msg.sender, _workers[i], _date);
        }
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
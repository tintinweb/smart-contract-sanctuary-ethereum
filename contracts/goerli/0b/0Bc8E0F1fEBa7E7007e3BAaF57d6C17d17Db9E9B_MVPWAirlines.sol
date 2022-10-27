/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// SPDX-License-Identifier: MIT
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/a1948250ab8c441f6d327a65754cb20d2b1b4554/contracts/utils/Context.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/a1948250ab8c441f6d327a65754cb20d2b1b4554/contracts/access/Ownable.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/a1948250ab8c441f6d327a65754cb20d2b1b4554/contracts/access/Ownable2Step.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// File: contracts/MVPWAirlines.sol


pragma solidity ^0.8.7;



 
 contract MVPWAirlines is Ownable2Step {
       
       // Information about the plane
       struct Plane {
            uint256 ecoClassSeats;
            uint256 firstClassSeats;
            bool isOnHold;
            bool isRegistered;
       }

       // Information about the Flight
       struct Flight {
            uint256 departureTime;
            uint256 priceForEcoSeats;
            uint256 priceForFirstClassSeats;
            uint256 ecoClassSeatsAvaliable;
            uint256 firstClassSeatsAvaliable;
            uint256 planeID;
            mapping(address => Reservation) reservations;
       }

       // Information about the number of tickets a person has reserved
       struct Reservation {
            uint256 ecoClassSeatsReserved;
            uint256 firstClassSeatsReserved;
       }
       
       
       address public tokenAddress;

       mapping(uint256 => Plane) public planes;
       mapping(uint256 => Flight) public flights;
      

      constructor(address _tokenAddress) {
             tokenAddress = _tokenAddress;
       }

       // events
       event PlaneRegistered(uint256 planeID, uint256 ecoClassAvaliable, uint256 firstClassSeatsAvaliable);
       event PlaneOnHold(uint256 planeID);
       event PlaneOffHold(uint256 planeID);
       event FlightAnnounced(
             uint256 indexed planeID,
             uint256 indexed flightID,
             uint256 departureTime,
             uint256 priceForEcoSeats,
             uint256 priceForFirstClassSeats,
             uint256 ecoClassSeatsAvaliable,
             uint256 firstClassSeatsAvaliable,
             string destination);
       event TicketsBought(uint256 indexed flightID, address indexed buyer, uint256 numberOfEcoClassSeats, uint256 numberOfFirstClassSeats);
       event TicketsCanceled(uint256 indexed flightID, address indexed buyer, uint256 numberOfEcoClassSeats, uint256 numberOfFirstClassSeats);
            

       error PlaneIDValid(uint256 planeID);
       error FlightIDValid(uint256 flightID);
       error InvalidDepartureTime(uint256 departureTime);
       error PlaneIsOnHold();
       error PlaneNotFound();
       error FlightNotFound();
       error TicketsNotChosen();
       error ToManyTicketsChosen();
       error AllowanceNotValid();
       error NotEnoughBalance();

       // With this function we are registering a new plane
       function registerNewPlane(uint256 _planeID, uint256 _ecoClassSeats, uint256 _firstClassSeats) external onlyOwner {
             Plane memory plane = planes[_planeID];
             if (plane.isRegistered){
                   revert PlaneIDValid(_planeID);
             }

             plane.ecoClassSeats = _ecoClassSeats;
             plane.firstClassSeats = _firstClassSeats;
             plane.isRegistered = true;

             emit PlaneRegistered(_planeID, _ecoClassSeats, _firstClassSeats);
       }
       // With this function we are puting a plane on hold and flights are prevented from being announced 
       function putPlaneOnHold(uint256 _planeID) external onlyOwner{
             planes[_planeID].isOnHold = true;

             emit PlaneOnHold(_planeID);
       }
       // With this function we are puting a plane off hold and flights are allowed to be announced 
       function putPlaneOffHold(uint256 _planeID) external onlyOwner{
             planes[_planeID].isOnHold = false;

             emit PlaneOffHold(_planeID);
       }
       // With this function we are announcing a new Flight
       function newFlight(
             uint256 _flightID,
             uint256 _planeID,
             uint256 _priceForEcoSeats,
             uint256 _priceForFirstClassSeats,
             uint256 _departureTime,
             string memory _destination
       ) external onlyOwner{
          Flight storage flight = flights[_flightID];
          if (flight.departureTime != 0){
                revert FlightIDValid(_flightID);
          }

          Plane memory plane = planes[_planeID];

          if (!plane.isRegistered) {
                revert PlaneNotFound();
          }

          if (plane.isOnHold) {
                revert PlaneIsOnHold();
          }

          flight.departureTime = _departureTime;
          flight.priceForEcoSeats = _priceForEcoSeats;
          flight.priceForFirstClassSeats = _priceForFirstClassSeats;
          flight.planeID = _planeID;
          flight.ecoClassSeatsAvaliable = plane.ecoClassSeats;
          flight.firstClassSeatsAvaliable = plane.firstClassSeats;



          emit FlightAnnounced(
                _planeID,
                _flightID,
                _priceForEcoSeats,
                _priceForFirstClassSeats,
                plane.ecoClassSeats,
                plane.firstClassSeats,
                _departureTime,
                _destination

          );
       }
      // With this function we are reserving tickets 
       function reserveTickets(uint256 _flightID, uint256 _numberOfEcoClassSeats, uint256 _numberOfFirstClassSeats) external {
             if (_numberOfEcoClassSeats == 0 && _numberOfFirstClassSeats == 0) {
                   revert TicketsNotChosen();
             }

             Flight storage flight = flights[_flightID];
             Reservation storage reservation = flight.reservations[msg.sender];

             if (reservation.ecoClassSeatsReserved + reservation.firstClassSeatsReserved + _numberOfEcoClassSeats + _numberOfFirstClassSeats > 4){
                   revert ToManyTicketsChosen();
             }

       uint256 totalCost = _numberOfFirstClassSeats * flight.priceForFirstClassSeats;
       totalCost = _numberOfEcoClassSeats * flight.priceForEcoSeats;


       IERC20 tokenContract = IERC20(tokenAddress);
       if (tokenContract.allowance(msg.sender, address(this)) < totalCost) {
             revert AllowanceNotValid();
       }

       flight.ecoClassSeatsAvaliable -= _numberOfEcoClassSeats;
       flight.firstClassSeatsAvaliable -= _numberOfFirstClassSeats;

       reservation.ecoClassSeatsReserved += _numberOfEcoClassSeats;
       reservation.firstClassSeatsReserved += _numberOfFirstClassSeats;

       tokenContract.transferFrom(msg.sender, address(this), totalCost);

       emit TicketsBought(_flightID, msg.sender, _numberOfEcoClassSeats, _numberOfFirstClassSeats);

       }
       
       // With this function we are cancelling reserved tickets
       function cancelTickets(uint256 _flightID, uint256 _numberOfEcoClassSeats, uint256 _numberOfFirstClassSeats) external{
             Flight storage flight = flights[_flightID];
             Reservation storage reservation = flight.reservations[msg.sender];
             uint256 refundSum;
             

             flight.ecoClassSeatsAvaliable += _numberOfEcoClassSeats;
             flight.firstClassSeatsAvaliable += _numberOfFirstClassSeats;

             reservation.ecoClassSeatsReserved -= _numberOfEcoClassSeats;
             reservation.firstClassSeatsReserved -= _numberOfFirstClassSeats;

             if (block.timestamp + 1 days < flight.departureTime) {
                   refundSum = _numberOfEcoClassSeats * flight.priceForEcoSeats;
                   refundSum += _numberOfFirstClassSeats * flight.priceForFirstClassSeats;
             }

             if (block.timestamp + 2 days > flight.departureTime){
                   refundSum = (refundSum / 5) * 4;
             }

      
             IERC20 tokenContract = IERC20(tokenAddress);
             if (tokenContract.balanceOf(address(this)) < refundSum) {
                   revert NotEnoughBalance();
             }

             emit TicketsCanceled(_flightID, msg.sender, _numberOfEcoClassSeats, _numberOfFirstClassSeats);

       }


 }
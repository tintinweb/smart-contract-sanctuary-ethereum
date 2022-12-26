/**
 *Submitted for verification at Etherscan.io on 2022-12-26
*/

//SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/Counters.sol


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

// File: contracts/Week1.sol

pragma solidity ^0.8.13;




contract MvpAirlines is Ownable {
  using Counters for Counters.Counter;

  Counters.Counter private airplanesCounter;
  Counters.Counter private flightsCounter;

  struct Airplane {
    uint airplaneId;
    string name;
    uint numberOfSeatsEconomy;
    uint numberOfSeatsBusiness;
    AirplaneStatus status;
    bool exists;
  }

  struct Passenger {
    address passenger;
    uint8 numberOfTickets;
    bool exists;
  }

  struct Flight {
    uint flightId;
    string to;
    uint ticketPriceBusiness;
    uint ticketPriceEconomy;
    uint availableSeatsEconomy;
    uint availableSeatsBusiness;
    uint departureDateTime;
    uint scheduledAirplaneId;
    bool exists;
  }

  enum AirplaneStatus {
    AVAILABLE,
    MAINTENANCE
  }

  enum TicketType {
    ECONOMY,
    BUSINESS
  }

  enum RefundType {
    PARTIAL,
    FULL
  }

  mapping(uint => Airplane) public airplanes;
  mapping(uint => Flight) public flights;
  mapping(uint => mapping(uint => Flight)) public airplanePreviousFlights;
  mapping(uint => mapping(address => Passenger)) public flightPassengers;

  address public invitedAdmin;
  address public immutable MVP_TOKEN_ADDRESS;

  constructor() {
    MVP_TOKEN_ADDRESS = address(0x71bDd3e52B3E4C154cF14f380719152fd00362E7);
  }

  event NewAdminInvited(address indexed newAdmin);
  event DeclinedAdminRole();
  event AcceptedAdminRole();
  event RegisteredNewAirplane(uint airplaneId);
  event AirplaneMaintenance(uint airplaneId);
  event AirplaneAvailable(uint airplaneId);
  event TicketPurchased(uint flightId, address indexed customer);
  event NewFlightAnnounced(uint flightId);
  event TicketRefunded(uint flightId, address indexed customer);

  error NoEconomyTicketsAvailable();
  error NoBusinessTicketsAvailable();
  error PassengerTicketLimitReached();
  error AllowanceError();
  error InsufficientTokenBalance();

  modifier invitedAdminOnly() {
    require(
      msg.sender == invitedAdmin,
      "Only invited admin can invoke this function"
    );
    _;
  }

  function transferOwnership(address newAdmin) public override onlyOwner {
    require(newAdmin != address(0), "Zero address cannot be the owner");
    invitedAdmin = newAdmin;
    emit NewAdminInvited(newAdmin);
  }

  function acceptAdminRole() public invitedAdminOnly {
    _transferOwnership(msg.sender);
    emit AcceptedAdminRole();
  }

  function declineAdminRole() public invitedAdminOnly {
    invitedAdmin = address(0);
    emit DeclinedAdminRole();
  }

  function registerNewAirplane(
    string calldata _name,
    uint _numberOfSeatsEconomy,
    uint _numberOfSeatsBusiness
  ) public onlyOwner {
    require(
      bytes(_name).length != 0,
      "Airplane name cannot be an empty string"
    );
    airplanesCounter.increment();
    airplanes[airplanesCounter.current()] = Airplane({
      airplaneId: airplanesCounter.current(),
      name: _name,
      numberOfSeatsEconomy: _numberOfSeatsEconomy,
      numberOfSeatsBusiness: _numberOfSeatsBusiness,
      status: AirplaneStatus.AVAILABLE,
      exists: true
    });
    emit RegisteredNewAirplane(airplanesCounter.current());
  }

  function putAirplaneOnMaintenance(uint _airplaneId) public onlyOwner {
    airplanes[_airplaneId].status = AirplaneStatus.MAINTENANCE;
    emit AirplaneAvailable(_airplaneId);
  }

  function putAirplaneOffMaintenance(uint _airplaneId) public onlyOwner {
    airplanes[_airplaneId].status = AirplaneStatus.AVAILABLE;
    emit AirplaneAvailable(_airplaneId);
  }

  function announceNewFlight(
    uint _airplaneId,
    string calldata _to,
    uint _departureDateTime,
    uint _ticketPriceBusiness,
    uint _ticketPriceEconomy
  ) public onlyOwner {
    require(
      airplanes[_airplaneId].exists == true,
      "Airplane doesn't exist with specified airplaneId"
    );
    require(
      airplanes[_airplaneId].status == AirplaneStatus.AVAILABLE,
      "Airplane is on maintenance"
    );
    require(
      _departureDateTime > block.timestamp,
      "Cannot announce new flights in the past."
    );
    flightsCounter.increment();
    Flight storage newFlight = flights[flightsCounter.current()];

    newFlight.flightId = flightsCounter.current();
    newFlight.to = _to;
    newFlight.departureDateTime = _departureDateTime;
    newFlight.ticketPriceBusiness = _ticketPriceBusiness;
    newFlight.ticketPriceEconomy = _ticketPriceEconomy;
    newFlight.scheduledAirplaneId = _airplaneId;
    newFlight.availableSeatsBusiness = airplanes[_airplaneId]
      .numberOfSeatsBusiness;
    newFlight.availableSeatsEconomy = airplanes[_airplaneId]
      .numberOfSeatsEconomy;
    newFlight.exists = true;

    airplanePreviousFlights[_airplaneId][flightsCounter.current()] = flights[
      flightsCounter.current()
    ];

    emit NewFlightAnnounced(newFlight.flightId);
  }

  function buyTicket(uint _flightId, TicketType _ticketType) public payable {
    require(
      flights[_flightId].exists == true,
      "Flight doesn't exist with specified flightId"
    );
    Flight storage flight = flights[_flightId];
    checkTicketAvailability(
      _ticketType,
      flight.availableSeatsEconomy,
      flight.availableSeatsBusiness
    );
    Passenger storage passenger = flightPassengers[_flightId][msg.sender];
    validatePassenger(passenger);
    if (passenger.passenger == address(0)) {
      passenger.passenger = msg.sender;
      passenger.exists = true;
    }

    passenger.numberOfTickets++;

    flightPassengers[_flightId][msg.sender] = passenger;

    if (_ticketType == TicketType.ECONOMY) {
      flight.availableSeatsEconomy--;
    } else {
      flight.availableSeatsBusiness--;
    }

    uint ticketPrice = _ticketType == TicketType.ECONOMY
      ? flight.ticketPriceEconomy
      : flight.ticketPriceBusiness;

    IERC20 mvpwAirlinesContract = IERC20(MVP_TOKEN_ADDRESS);

    if (
      mvpwAirlinesContract.allowance(msg.sender, address(this)) < ticketPrice
    ) {
      revert AllowanceError();
    }

    mvpwAirlinesContract.transferFrom(msg.sender, address(this), ticketPrice);

    airplanePreviousFlights[flight.scheduledAirplaneId][_flightId] = flight;

    emit TicketPurchased(_flightId, msg.sender);
  }

  function cancelTicketPurchase(uint _flightId, TicketType _ticketType) public {
    require(
      flights[_flightId].exists == true,
      "Flight doesn't exist with specified flightId"
    );
    Flight storage flight = flights[_flightId];
    require(
      flight.departureDateTime > block.timestamp,
      "Cannot reimburse because flight has happened or is currently in progress"
    );
    require(
      flightPassengers[_flightId][msg.sender].exists == true,
      "Passenger doesn't exist on this flight"
    );
    RefundType refund = determineRefund(flight.departureDateTime);
    uint refundAmount;
    if (_ticketType == TicketType.ECONOMY) {
      flight.availableSeatsEconomy++;
      refundAmount = flight.ticketPriceEconomy;
    } else if (_ticketType == TicketType.BUSINESS) {
      flight.availableSeatsBusiness++;
      refundAmount = flight.ticketPriceBusiness;
    }
    if (refund == RefundType.PARTIAL) {
      refundAmount = (refundAmount / 5) * 4;
    }
    flightPassengers[_flightId][msg.sender].numberOfTickets--;
    airplanePreviousFlights[flight.scheduledAirplaneId][_flightId] = flight;
    IERC20 mvpwAirlinesContract = IERC20(MVP_TOKEN_ADDRESS);

    if (mvpwAirlinesContract.balanceOf(address(this)) < refundAmount)
      revert InsufficientTokenBalance();

    mvpwAirlinesContract.transfer(msg.sender, refundAmount);

    emit TicketRefunded(_flightId, msg.sender);
  }

  function checkTicketAvailability(
    TicketType _ticketType,
    uint _availableEconomy,
    uint _availableBusiness
  ) private pure {
    if (_ticketType == TicketType.ECONOMY && _availableEconomy == 0) {
      revert NoEconomyTicketsAvailable();
    }
    if (_ticketType == TicketType.BUSINESS && _availableBusiness == 0) {
      revert NoBusinessTicketsAvailable();
    }
  }

  function validatePassenger(Passenger memory _passenger) private pure {
    if (_passenger.numberOfTickets >= 4) {
      revert PassengerTicketLimitReached();
    }
  }

  function determineRefund(
    uint _departureTime
  ) private view returns (RefundType) {
    if (block.timestamp + 2 days > _departureTime) {
      return RefundType.FULL;
    } else {
      return RefundType.PARTIAL;
    }
  }

  fallback() external payable {}

  receive() external payable {}
}
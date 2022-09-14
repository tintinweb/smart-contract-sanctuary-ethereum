/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

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

// File @openzeppelin/contracts/access/[email protected]

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File @openzeppelin/contracts/utils/[email protected]

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

// File @openzeppelin/contracts/token/ERC20/[email protected]

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

// File contracts/MVPWAirlines.sol

pragma solidity ^0.8.6;

contract MVPWAirlines is Ownable {
    using Counters for Counters.Counter;

    uint256 public constant MIN_ECONOMY_CLASS_SEATS = 2;
    uint256 public constant MIN_FIRST_CLASS_SEATS = 1;

    /// @notice ticket prices are represented in GWEI or in ETH it's 0.1 for economy class and
    /// 0.2 for first class
    uint256 public constant MIN_ECONOMY_CLASS_TICKET_PRICE = 100000000 gwei;
    uint256 public constant MIN_FIRST_CLASS_TICKET_PRICE = 200000000 gwei;

    address public constant EMPTY_ADDRESS_VALUE = address(0);

    uint256 public constant MAX_NUMBER_OF_TICKETS_PER_FLIGHT = 4;

    Counters.Counter private airplanesCounter;

    enum AirplaneStatus {
        ACTIVE,
        ON_HOLD
    }

    struct Airplane {
        string name;
        uint256 economySeats;
        uint256 firstClassSeats;
        AirplaneStatus status;
        mapping(uint256 => bool) flights;
        bool exists;
    }

    mapping(uint256 => Airplane) public airplanes;

    address[] public array = new address[](6);

    struct Passenger {
        address passenger;
        uint256 numberOfTickets;
        bool exists;
    }

    Counters.Counter private flightsCounter;

    struct Flight {
        uint256 airplaneId;
        string destination;
        uint256 departureTime;
        uint256 economyClassTicketPrice;
        uint256 firstClassTicketPrice;
        uint256 availableEconomySeats;
        uint256 availableFirstClassSeats;
        address[] economySeats;
        address[] firstClassSeats;
        mapping(address => Passenger) passengers;
        bool exists;
    }

    mapping(uint256 => Flight) public flights;

    enum SeatClassType {
        ECONOMY,
        FIRST
    }

    enum RefundType {
        REFUND,
        FULL_REFUND
    }

    address public invitedAdmin;
    address public mvpwAirlinesTokenAddress;

    constructor(address _mvpwAirlinesTokenAddress) {
        mvpwAirlinesTokenAddress = _mvpwAirlinesTokenAddress;
    }

    event AirplaneRegistered(uint256 indexed airplaneId, uint256 totalSeats);
    event NewAdminInvited(address indexed admin);
    event AdminInvitationDeclined();
    event FlightRegistered(uint256 indexed flightId, string destination);
    event AirplaneIsOnHold(uint256 indexed airplaneId);
    event AirplaneIsActive(uint256 indexed airplaneId);
    event TicketPurchased(uint256 indexed airplaneId, address passenger);
    event TicketCanceled(uint256 indexed flightId, address passenger);

    error InvalidSeatsNumber();
    error EmptyString();
    error MsgSenderIsNotInvitedAdmin();
    error InvalidTicketPrice();
    error AirplaneNotFound();
    error AirplaneOnHold();
    error InvalidTime();
    error FlightNotFound();
    error UnavailableEconomySeats();
    error UnavailableFirstClassSeats();
    error MaxTicketPurchaseReached();
    error SeatAlreadyReserved();
    error InsufficientAmount();
    error MaxNumberOfTicketsReached();
    error FlightDeparted();
    error NotPassengerOnFlight();
    error InvalidSeatNumber();
    error UnableToRefund();
    error AllowanceError();
    error InsufficientTokenAmountBalance();

    modifier onlyInvitedAdmin() {
        if (msg.sender != invitedAdmin) revert MsgSenderIsNotInvitedAdmin();
        _;
    }

    modifier validateString(string calldata value) {
        if (bytes(value).length == 0) revert EmptyString();
        _;
    }

    modifier validateSeatsNumber(uint256 economyClass, uint256 firstClass) {
        if (
            economyClass < MIN_ECONOMY_CLASS_SEATS ||
            firstClass < MIN_FIRST_CLASS_SEATS
        ) revert InvalidSeatsNumber();
        _;
    }

    modifier validateTicketPrice(
        uint256 economyTicket,
        uint256 firstClassTicket
    ) {
        if (
            economyTicket < MIN_ECONOMY_CLASS_TICKET_PRICE ||
            firstClassTicket < MIN_FIRST_CLASS_TICKET_PRICE
        ) revert InvalidTicketPrice();
        _;
    }

    modifier validateTime(uint256 time) {
        if (block.timestamp > time) revert InvalidTime();
        _;
    }

    /// @notice This function instantiate transfer ownership by passing new admin's address
    /// @dev This is overridden function from Ownable contract. It can be called only by owner and it representes new admin invitation
    /// @param newOwner Address of invited admin
    function transferOwnership(address newOwner) public override onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        invitedAdmin = newOwner;

        emit NewAdminInvited(newOwner);
    }

    /// @notice This function is called when new admin accepts invitation for contract ownership
    /// @dev This function has modifier which check if caller is invited admin. Also this function isn't
    /// emitting event because that is done from Ownable contract
    function acceptOwnershipInvitation() public onlyInvitedAdmin {
        _transferOwnership(msg.sender);
    }

    /// @notice In case that current owner wants to decline new admin invitation
    /// @dev invitedAdmin variable is set to default value
    function declineAdminInvitation() public onlyOwner {
        invitedAdmin = EMPTY_ADDRESS_VALUE;

        emit AdminInvitationDeclined();
    }

    /// @notice Register new airplanes by providing info about number of first and economy class seats
    /// @dev Function has owner modifier, modifier for validating passed seats number and empty string modifier
    /// @param economySeatsNum Economy class seats number
    /// @param firstClassSeatsNum First class seats number
    function registerAirplane(
        string calldata name,
        uint256 economySeatsNum,
        uint256 firstClassSeatsNum
    )
        public
        onlyOwner
        validateString(name)
        validateSeatsNumber(economySeatsNum, firstClassSeatsNum)
        returns (uint256)
    {
        airplanesCounter.increment();
        uint256 airplaneId = airplanesCounter.current();

        Airplane storage newAirplane = airplanes[airplaneId];
        newAirplane.name = name;
        newAirplane.economySeats = economySeatsNum;
        newAirplane.firstClassSeats = firstClassSeatsNum;
        newAirplane.status = AirplaneStatus.ACTIVE;
        newAirplane.exists = true;

        uint256 totalSeats = economySeatsNum + firstClassSeatsNum;

        emit AirplaneRegistered(airplaneId, totalSeats);

        return airplaneId;
    }

    /// @notice Function for puting airplane on hold due to mechanic issues
    /// @param airplaneId ID of airplane
    function putAirplaneOnHold(uint256 airplaneId) public onlyOwner {
        Airplane storage airplane = findAirplane(airplaneId);
        airplane.status = AirplaneStatus.ON_HOLD;

        emit AirplaneIsOnHold(airplaneId);
    }

    /// @notice Function for activating airplane
    /// @param airplaneId ID of airplane
    function activateAirplane(uint256 airplaneId) public onlyOwner {
        Airplane storage airplane = findAirplane(airplaneId);
        airplane.status = AirplaneStatus.ACTIVE;

        emit AirplaneIsActive(airplaneId);
    }

    /// @notice Function for registering new flight
    /// @dev Function has modifiers for string check and validating ticket prices
    /// @param airplaneId ID of airplaine
    /// @param destination Can't be empty string
    /// @param departureTime Departure time of flight
    /// @param economyClassTicketPrice Price of first class can't be less then MIN_ECONOMY_CLASS_TICKET_PRICE
    /// @param firstClassTicketPrice Price of first class can't be less then MIN_FIRST_CLASS_TICKET_PRICE
    function registerFlight(
        uint256 airplaneId,
        string calldata destination,
        uint256 departureTime,
        uint256 economyClassTicketPrice,
        uint256 firstClassTicketPrice
    )
        public
        onlyOwner
        validateString(destination)
        validateTime(departureTime)
        validateTicketPrice(economyClassTicketPrice, firstClassTicketPrice)
        returns (uint256)
    {
        Airplane storage airplane = findAirplane(airplaneId);
        if (airplane.status == AirplaneStatus.ON_HOLD) revert AirplaneOnHold();

        flightsCounter.increment();
        uint256 flightId = flightsCounter.current();

        Flight storage newFlight = flights[flightId];
        newFlight.airplaneId = airplaneId;
        newFlight.destination = destination;
        newFlight.economyClassTicketPrice = economyClassTicketPrice;
        newFlight.firstClassTicketPrice = firstClassTicketPrice;
        newFlight.departureTime = departureTime;
        newFlight.availableEconomySeats = airplane.economySeats;
        newFlight.availableFirstClassSeats = airplane.firstClassSeats;
        newFlight.economySeats = new address[](airplane.economySeats);
        newFlight.firstClassSeats = new address[](airplane.firstClassSeats);
        newFlight.exists = true;

        emit FlightRegistered(flightId, destination);

        return flightId;
    }

    /// @notice Function for ticket purchase. This function does checks on flight departure time, passed amount for ticket, validates available seats
    /// and check if passes seat is available. SeatClassType is enum that determines does user wants economy or first class ticket
    function purchaseTicket(
        uint256 flightId,
        SeatClassType seatClassType,
        uint256 seatNumber
    ) public payable {
        Flight storage flight = findFlight(flightId);

        checkIfFlightDeparted(flight.departureTime);
        validateAvailableSeats(
            seatClassType,
            flight.availableEconomySeats,
            flight.availableFirstClassSeats
        );
        checkIfSeatIsAvailable(
            seatNumber,
            seatClassType,
            flight.economySeats,
            flight.firstClassSeats
        );

        Passenger memory passenger = flight.passengers[msg.sender];

        checkIfPassengerCanPurchase(passenger);

        if (passenger.passenger == EMPTY_ADDRESS_VALUE) {
            passenger.passenger = msg.sender;
            passenger.exists = true;
        }

        passenger.numberOfTickets++;

        flight.passengers[msg.sender] = passenger;

        if (seatClassType == SeatClassType.ECONOMY) {
            flight.availableEconomySeats--;
            flight.economySeats[seatNumber] = msg.sender;
        } else {
            flight.availableFirstClassSeats--;
            flight.firstClassSeats[seatNumber] = msg.sender;
        }

        uint256 transferAmount = seatClassType == SeatClassType.ECONOMY
            ? flight.economyClassTicketPrice
            : flight.firstClassTicketPrice;

        IERC20 mvpAirlanesContract = IERC20(mvpwAirlinesTokenAddress);

        if (
            mvpAirlanesContract.allowance(msg.sender, address(this)) <
            transferAmount
        ) revert AllowanceError();

        mvpAirlanesContract.transferFrom(
            msg.sender,
            address(this),
            transferAmount
        );

        emit TicketPurchased(flightId, msg.sender);
    }

    /// @notice Function for ticket cancellation and refund. This function check flight departure time, is msg.sender passenger of specified flight
    // and does he has right for refund.
    function cancelTicket(
        uint256 flightId,
        SeatClassType seatClassType,
        uint256 seatNumber
    ) public payable {
        Flight storage flight = findFlight(flightId);

        checkIfFlightDeparted(flight.departureTime);
        Passenger memory passenger = flight.passengers[msg.sender];

        if (passenger.exists == false || passenger.numberOfTickets == 0)
            revert NotPassengerOnFlight();
        if (block.timestamp + 1 days > flight.departureTime)
            revert UnableToRefund();

        RefundType refundType = determineRefundType(flight.departureTime);

        uint256 refundAmount;

        if (
            seatClassType == SeatClassType.ECONOMY &&
            flight.economySeats[seatNumber] == msg.sender
        ) {
            flight.economySeats[seatNumber] = EMPTY_ADDRESS_VALUE;
            flight.availableEconomySeats++;
            refundAmount = calculateRefundAmount(
                refundType,
                flight.economyClassTicketPrice
            );
        } else if (
            seatClassType == SeatClassType.FIRST &&
            flight.firstClassSeats[seatNumber] == msg.sender
        ) {
            flight.firstClassSeats[seatNumber] = EMPTY_ADDRESS_VALUE;
            flight.availableFirstClassSeats++;
            refundAmount = calculateRefundAmount(
                refundType,
                flight.firstClassTicketPrice
            );
        } else revert InvalidSeatNumber();

        passenger.numberOfTickets--;
        flight.passengers[msg.sender] = passenger;

        IERC20 mvpAirlanesContract = IERC20(mvpwAirlinesTokenAddress);

        if (mvpAirlanesContract.balanceOf(address(this)) < refundAmount)
            revert InsufficientTokenAmountBalance();

        mvpAirlanesContract.transfer(msg.sender, refundAmount);

        emit TicketCanceled(flightId, msg.sender);
    }

    /// @notice Function determines how much percentage of ticket price should be refunded.
    /// It can be 100% or 80%
    function determineRefundType(uint256 departureTime)
        private
        view
        returns (RefundType)
    {
        RefundType refundType;

        if (block.timestamp + 2 days > departureTime)
            refundType = RefundType.FULL_REFUND;
        else refundType = RefundType.REFUND;

        return refundType;
    }

    /// @notice Function calculates refund amount based on RefundType. If RefundType is FULL_REFUND then whole ticket price is refunded
    /// else 80% of ticket price is refunded
    function calculateRefundAmount(RefundType refundType, uint256 ticketPrice)
        private
        pure
        returns (uint256)
    {
        uint256 refundAmount = ticketPrice;
        if (refundType == RefundType.REFUND) {
            refundAmount = (refundAmount / 5) * 4;
        }

        return refundAmount;
    }

    /// @notice Function to find airplane by passed id.
    /// In case airplane doesn't exists transaction will be reverted
    /// @param airplaneId ID of airplaine
    function findAirplane(uint256 airplaneId)
        private
        view
        returns (Airplane storage)
    {
        Airplane storage airplane = airplanes[airplaneId];
        if (!airplane.exists) revert AirplaneNotFound();

        return airplane;
    }

    /// @notice Function to find flight by passed id.
    /// In case flight doesn't exists transaction will be reverted
    /// @param flightId ID of airplaine
    function findFlight(uint256 flightId)
        private
        view
        returns (Flight storage)
    {
        Flight storage flight = flights[flightId];
        if (!flight.exists) revert FlightNotFound();

        return flight;
    }

    /// @notice Function to check if there is available seats in either economy or first class
    function validateAvailableSeats(
        SeatClassType seatClassType,
        uint256 economySeats,
        uint256 firstClassSeats
    ) private pure {
        if (seatClassType == SeatClassType.ECONOMY && economySeats == 0) {
            revert UnavailableEconomySeats();
        }

        if (seatClassType == SeatClassType.FIRST && firstClassSeats == 0) {
            revert UnavailableFirstClassSeats();
        }
    }

    /// @notice Function checks if specific seat is already reserved
    function checkIfSeatIsAvailable(
        uint256 seatNum,
        SeatClassType seatClassType,
        address[] storage economySeats,
        address[] storage firstClassSeats
    ) private view {
        if (
            seatClassType == SeatClassType.ECONOMY &&
            economySeats[seatNum] != EMPTY_ADDRESS_VALUE
        ) {
            revert SeatAlreadyReserved();
        }

        if (
            seatClassType == SeatClassType.FIRST &&
            firstClassSeats[seatNum] != EMPTY_ADDRESS_VALUE
        ) {
            revert SeatAlreadyReserved();
        }
    }

    /// @notice Function check number of same passengers ticket purchases per flight
    function checkIfPassengerCanPurchase(Passenger memory passenger)
        private
        pure
    {
        if (passenger.numberOfTickets == 4) {
            revert MaxNumberOfTicketsReached();
        }
    }

    /// @notice Function that check if flight has departured
    /// @dev This check is done based on block's timestamp
    function checkIfFlightDeparted(uint256 departureTime) private view {
        if (block.timestamp > departureTime) {
            revert FlightDeparted();
        }
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./interfaces/IMVPWAirlines.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MVPWAirlines is Ownable, IMVPWAirlines {
    error EmptyAddress();

    error Unauthorized();

    error AirplaneIDExists(uint32 airplaneID);

    error FlightIDExists(uint256 flightID);

    error InvalidDepartureTime(uint256 departureTime);

    error AirplaneOnHold();

    error AirplaneNotFound();

    error FlightNotFound();

    error NoTicketsChosen();

    error TooManyTicketsChosen();

    error MaximumCapacityReached();

    error AllowanceNotSet();

    error CancellationUnderflow();

    error InsufficientBalance();

    address public pendingOwner;
    address public tokenAddress;

    mapping(uint256 => Flight) public flights;
    mapping(uint32 => Airplane) public airplanes;

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    /// @inheritdoc IMVPWAirlines
    function registerNewAirplane(
        uint32 _airplaneID,
        uint16 _economyClassCapacity,
        uint16 _firstClassCapacity
    ) external onlyOwner {
        Airplane storage airplane = airplanes[_airplaneID];

        if (airplane.isRegistered) {
            revert AirplaneIDExists(_airplaneID);
        }

        airplane.economyClassCapacity = _economyClassCapacity;
        airplane.firstClassCapacity = _firstClassCapacity;
        airplane.isRegistered = true;

        emit AirplaneRegistered(
            _airplaneID,
            _economyClassCapacity,
            _firstClassCapacity
        );
    }

    /// @inheritdoc IMVPWAirlines
    function holdAirplane(uint32 _airplaneID) external onlyOwner {
        airplanes[_airplaneID].isOnHold = true;
    }

    /// @inheritdoc IMVPWAirlines
    function releaseAirplane(uint32 _airplaneID) external onlyOwner {
        airplanes[_airplaneID].isOnHold = false;
    }

    /// @inheritdoc IMVPWAirlines
    function announceNewFlight(
        uint256 _flightID,
        uint256 _departureTime,
        uint256 _economyClassPrice,
        uint256 _firstClassPrice,
        uint32 _airplaneID,
        string calldata _destination
    ) external onlyOwner {
        Flight storage flight = flights[_flightID];
        if (flight.departureTime != 0) {
            revert FlightIDExists(_flightID);
        }

        if (_departureTime < block.timestamp) {
            revert InvalidDepartureTime(_departureTime);
        }

        Airplane memory airplane = airplanes[_airplaneID];

        if (!airplane.isRegistered) {
            revert AirplaneNotFound();
        }

        if (airplane.isOnHold) {
            revert AirplaneOnHold();
        }

        flight.departureTime = _departureTime;
        flight.economyClassPrice = _economyClassPrice;
        flight.firstClassPrice = _firstClassPrice;
        flight.airplaneID = _airplaneID;
        flight.economyClassSeatsAvailable = airplane.economyClassCapacity;
        flight.firstClassSeatsAvailable = airplane.firstClassCapacity;

        emit FlightAnnounced(
            _airplaneID,
            _flightID,
            _departureTime,
            _economyClassPrice,
            _firstClassPrice,
            airplane.economyClassCapacity,
            airplane.firstClassCapacity,
            _destination
        );
    }

    /// @inheritdoc IMVPWAirlines
    function bookTickets(
        uint256 _flightID,
        uint8 _numberOfEconomyClassSeats,
        uint8 _numberOfFirstClassSeats
    ) external {
        if (_numberOfFirstClassSeats == 0 && _numberOfEconomyClassSeats == 0) {
            revert NoTicketsChosen();
        }

        Flight storage flight = flights[_flightID];
        Reservation storage reservation = flight.reservations[msg.sender];

        if (
            reservation.economyClassSeatsReserved +
                reservation.firstClassSeatsReserved +
                _numberOfEconomyClassSeats +
                _numberOfFirstClassSeats >
            4
        ) {
            revert TooManyTicketsChosen();
        }

        uint256 totalCost = _numberOfEconomyClassSeats *
            flight.economyClassPrice;
        totalCost += _numberOfFirstClassSeats * flight.firstClassPrice;

        // Check allowance
        IERC20 tokenContract = IERC20(tokenAddress);
        if (tokenContract.allowance(msg.sender, address(this)) < totalCost) {
            revert AllowanceNotSet();
        }

        if (
            flight.economyClassSeatsAvailable < _numberOfEconomyClassSeats ||
            flight.firstClassSeatsAvailable < _numberOfFirstClassSeats
        ) {
            revert MaximumCapacityReached();
        }

        flight.economyClassSeatsAvailable -= _numberOfEconomyClassSeats;
        flight.firstClassSeatsAvailable -= _numberOfFirstClassSeats;

        reservation.economyClassSeatsReserved += _numberOfEconomyClassSeats;
        reservation.firstClassSeatsReserved += _numberOfFirstClassSeats;

        // Transfer tokens
        tokenContract.transferFrom(msg.sender, address(this), totalCost);
    }

    /// @inheritdoc IMVPWAirlines
    function cancelTickets(
        uint256 _flightID,
        uint8 _numberOfEconomyClassSeats,
        uint8 _numberOfFirstClassSeats
    ) external {
        Flight storage flight = flights[_flightID];
        Reservation storage reservation = flight.reservations[msg.sender];

        if (
            _numberOfFirstClassSeats > reservation.firstClassSeatsReserved ||
            _numberOfEconomyClassSeats > reservation.economyClassSeatsReserved
        ) {
            revert CancellationUnderflow();
        }

        flight.economyClassSeatsAvailable += _numberOfEconomyClassSeats;
        flight.firstClassSeatsAvailable += _numberOfFirstClassSeats;

        reservation.economyClassSeatsReserved -= _numberOfEconomyClassSeats;
        reservation.firstClassSeatsReserved -= _numberOfFirstClassSeats;

        if (block.timestamp + 1 days < flight.departureTime) {
            uint256 refundAmount = _numberOfFirstClassSeats *
                flight.firstClassPrice;
            refundAmount +=
                _numberOfEconomyClassSeats *
                flight.economyClassPrice;

            if (block.timestamp + 2 days > flight.departureTime) {
                refundAmount = (refundAmount / 5) * 4;
            }

            // Check allowance
            IERC20 tokenContract = IERC20(tokenAddress);
            if (tokenContract.balanceOf(address(this)) < refundAmount) {
                revert InsufficientBalance();
            }

            tokenContract.transfer(msg.sender, refundAmount);
        }

        emit TicketsCancelled(
            _flightID,
            msg.sender,
            _numberOfEconomyClassSeats,
            _numberOfFirstClassSeats
        );
    }

    /// @inheritdoc	IMVPWAirlines
    function acceptOwnership() external {
        if (msg.sender != pendingOwner) {
            revert Unauthorized();
        }

        _transferOwnership(msg.sender);
    }

    /// @inheritdoc IMVPWAirlines
    function getSeatsAvalailable(uint256 _flightID)
        external
        view
        returns (
            uint16 economyClassSeatsAvailable,
            uint16 firstClassSeatsAvailable
        )
    {
        return (
            flights[_flightID].economyClassSeatsAvailable,
            flights[_flightID].firstClassSeatsAvailable
        );
    }

    /// @inheritdoc IMVPWAirlines
    function getFlightCapacity(uint256 _flightID)
        external
        view
        returns (uint16 economyClassCapacity, uint16 firstClassCapacity)
    {
        Airplane memory airplane = airplanes[flights[_flightID].airplaneID];
        return (airplane.economyClassCapacity, airplane.firstClassCapacity);
    }

    /// @notice Function which sets the new owner argument as the pending owner, waiting for their acceptance
    /// @inheritdoc	Ownable
    function transferOwnership(address _newOwner) public override onlyOwner {
        if (_newOwner == address(0)) {
            revert EmptyAddress();
        }
        pendingOwner = _newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IMVPWAirlines {
    /// @notice A struct containing the number of tickets a person has reserved
    struct Reservation {
        uint8 firstClassSeatsReserved;
        uint8 economyClassSeatsReserved;
    }

    /// @notice A struct containing flight information
    struct Flight {
        uint256 departureTime;
        uint256 economyClassPrice;
        uint256 firstClassPrice;
        uint32 airplaneID;
        mapping(address => Reservation) reservations;
        uint16 economyClassSeatsAvailable;
        uint16 firstClassSeatsAvailable;
    }

    /// @notice A struct containing information about an airplane
    /// @dev isOnHold uses the _false_ value as the default for more efficiency, isRegistered is used to check if the plane exists
    struct Airplane {
        uint16 economyClassCapacity;
        uint16 firstClassCapacity;
        bool isOnHold;
        bool isRegistered;
    }

    /// @notice Event denoting that a new Airplane has been registered
    /// @param airplaneID The uint32 ID of the airplane
    /// @param economyClassCapacity The maximum number of tickets available for the economy class
    /// @param firstClassCapacity The maximum number of tickets available for the economy class
    event AirplaneRegistered(
        uint32 airplaneID,
        uint16 economyClassCapacity,
        uint16 firstClassCapacity
    );

    /// @notice Event denoting that a new flight has been created/announced
    /// @param airplaneID The uint32 ID of the airplane
    /// @param flightID The uint32 ID of the flight
    /// @param departureTime The time of departure
    /// @param destination The destination of the flight
    event FlightAnnounced(
        uint32 indexed airplaneID,
        uint256 indexed flightID,
        uint256 departureTime,
        uint256 economyClassPrice,
        uint256 firstClassPrice,
        uint256 economyClassCapacity,
        uint256 firstClassCapacity,
        string destination
    );

    /// @notice Event denoting that an amount of tickets was purchased
    /// @param flightID The uint256 ID of the flight
    /// @param purchaser The address of the ticket purchaser
    /// @param numberOfEconomyClassSeats The number of economy class seats which were purchased
    /// @param numberOfFirstClassSeats The number of firts class seats which were purchased
    event TicketsPurchased(
        uint256 indexed flightID,
        address indexed purchaser,
        uint256 numberOfEconomyClassSeats,
        uint256 numberOfFirstClassSeats
    );

    /// @notice Event denoting that an amount of tickets was cancelled
    /// @param flightID The uint256 ID of the flight
    /// @param purchaser The address of the ticket purchaser
    /// @param numberOfEconomyClassSeats The number of economy class seats which were cancelled
    /// @param numberOfFirstClassSeats The number of firts class seats which were cancelled
    event TicketsCancelled(
        uint256 indexed flightID,
        address indexed purchaser,
        uint256 numberOfEconomyClassSeats,
        uint256 numberOfFirstClassSeats
    );

    /// @notice Function which new owner calls to confirm the ownership transfer
    function acceptOwnership() external;

    /// @notice Function for registering a new airplane
    /// @dev Maximum of 2**32 - 1 airplaes is allowed
    /// @param _airplaneID The uint32 ID of the airplane
    /// @param _economyClassCapacity The maximum number of tickets available for the economy class
    /// @param _firstClassCapacity The maximum number of tickets available for the economy class
    function registerNewAirplane(
        uint32 _airplaneID,
        uint16 _economyClassCapacity,
        uint16 _firstClassCapacity
    ) external;

    /// @notice Puts the airplane on hold, preventing flights for this airplane to be announced
    /// @param _airplaneID The uint32 ID of the airplane
    function holdAirplane(uint32 _airplaneID) external;

    /// @notice Puts the airplane off holding, allowing flights for this airplane to be announced
    /// @param _airplaneID The uint32 ID of the airplane
    function releaseAirplane(uint32 _airplaneID) external;

    /// @notice Announces a new flight
    /// @param _flightID The uint256 ID of the flight
    /// @param _departureTime The uint256 ID time of departure of the flight
    /// @param _economyClassPrice The uint256 price for the economy class ticket for the flight
    /// @param _firstClassPrice The uint256 price for the first class ticket for the flight
    /// @param _airplaneID The uint32 ID of the airplane used for the flight
    /// @param _destination The destination of the flight
    function announceNewFlight(
        uint256 _flightID,
        uint256 _departureTime,
        uint256 _economyClassPrice,
        uint256 _firstClassPrice,
        uint32 _airplaneID,
        string calldata _destination
    ) external;

    /// @notice Return all seats for a flight
    /// @param _flightID The uint256 ID of the flight
    /// @return economyClassSeatsAvailable The number of economy class seats available for purchase
    /// @return firstClassSeatsAvailable The number of first class seats available for purchase
    function getSeatsAvalailable(uint256 _flightID)
        external
        view
        returns (
            uint16 economyClassSeatsAvailable,
            uint16 firstClassSeatsAvailable
        );

    /// @notice Returns the flight capacity of economy and first class seats
    /// @param _flightID The uint256 ID of the flight
    /// @return economyClassCapacity The maximum number of economy class seats that can be created
    /// @return firstClassCapacity The maximum number of first class seats that can be created
    function getFlightCapacity(uint256 _flightID)
        external
        view
        returns (uint16 economyClassCapacity, uint16 firstClassCapacity);

    /// @notice Function for reserving new tickets
    /// @param _flightID The uint256 ID of the flight
    /// @param _numberOfEconomyClassSeats The uint8 number of economy class tickets the user wants to purchase
    /// @param _numberOfFirstClassSeats The uint8 number of first class tickets the user wants to purchase
    function bookTickets(
        uint256 _flightID,
        uint8 _numberOfEconomyClassSeats,
        uint8 _numberOfFirstClassSeats
    ) external;

    /// @notice Function for cancelling reserved tickets
    /// @param _flightID The uint256 ID of the flight
    /// @param _numberOfEconomyClassSeats The uint8 number of economy class tickets the user wants to cancel
    /// @param _numberOfFirstClassSeats The uint8 number of first class tickets the user wants to cancel
    function cancelTickets(
        uint256 _flightID,
        uint8 _numberOfEconomyClassSeats,
        uint8 _numberOfFirstClassSeats
    ) external;
}

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
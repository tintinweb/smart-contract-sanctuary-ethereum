// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/Context.sol";
import "./interfaces/IM4AService.sol";
import "./interfaces/IVehicleController.sol";

contract VehicleController is Context, IVehicleController, Initializable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeMathUpgradeable for uint256;

    //**************************************Variables**************************************//
    /** M4AService contract */
    IM4AService m4AServiceContract;

    /** The vehicle id counter */
    CountersUpgradeable.Counter internal vehicleCounter;

    /** A mapping between the vehicles and their id's */
    mapping(uint256 => Vehicle) internal vehicles;

    /**
     * A list of the vehicle id's that currently exist. This is necessary to reduce gas cost
     * when looping through the vehicles.
     */
    uint256[] internal vehicleIds;

    /** The minimum state of charge of a vehicle */
    uint256 internal minStateOfCharge;

    //**************************************Modifiers**************************************//
    /**
     * @dev Should check if caller is vehicle owner by calling the M4AService contract's isFleetOwner() function
     */
    modifier onlyFleetOwner() {
        bool isFleetOwner = m4AServiceContract.isDefaultAdmin(_msgSender());

        require(isFleetOwner, "Can only be performed by owner.");
        _;
    }

    /**
     * @dev Should check if caller is whitelisted member by calling the M4AService contract's isMember() function
     */
    modifier onlyMember() {
        bool isMember = m4AServiceContract.isMember(_msgSender());

        require(isMember, "You are not a customer.");
        _;
    }

    /**
     * @dev Should check if the calling wallet is either a member, the owner or a vehicle
     */
    modifier onlyWhitelisted() {
        address sender = _msgSender();
        bool isWhitelisted = m4AServiceContract.isDefaultAdmin(sender) ||
            m4AServiceContract.isMember(sender) ||
            m4AServiceContract.isVehicle(sender);

        require(isWhitelisted, "Not whitelisted");
        _;
    }

    /**
     * Makes sure that a function is called by a vehicle wallet
     */
    modifier onlyVehicle() {
        bool isVehicle = m4AServiceContract.isVehicle(_msgSender());
        require(isVehicle, "Only callable by a vehicle");
        _;
    }

    /**
     * @dev Checks whether a specific vehicle Id exists among the created vehicles.
     * @param vehicleId - The Id of the vehicle to check
     */
    modifier existingId(uint256 vehicleId) {
        bool vehicleExists = false;

        // Set vehicleExists to true if the vehicleId is found
        uint256 length = vehicleIds.length;
        for (uint256 i = 0; i < length; i++) {
            if (vehicleIds[i] == vehicleId) {
                vehicleExists = true;
                break;
            }
        }

        require(vehicleExists, "The vehicle does not exist.");
        _;
    }

    //**************************************Initializer**************************************//
    /**
     * @param m4AServiceAddress - The public address of the M4AService smart contract
     * @param minSoc - The minimum state of charge a vehicle has to have
     */
    function initialize(address m4AServiceAddress, uint256 minSoc)
        external
        initializer
    {
        m4AServiceContract = IM4AService(m4AServiceAddress);
        minStateOfCharge = minSoc;
    }

    //**************************************Public functions**************************************//
    /**
     * @notice Sets the minimum state of charge of a vehicle
     * @param minSoc - The new minimum state of charge
     */
    function setMinStateOfCharge(uint256 minSoc)
        external
        override
        onlyFleetOwner
    {
        minStateOfCharge = minSoc;
    }

    /**
     * @notice Returns the minimum state of charge of a vehicle
     */
    function getMinStateOfCharge() external view override returns (uint256) {
        return minStateOfCharge;
    }

    /**
     * @notice Creates a new vehicle
     * @param mileageAtCreation - The vehicle mileage in meters at the time of creation
     * @param vehicleLongitude - The longitude of the new vehicle
     * @param vehicleLatitude - The latitude of the new vehicle
     * @dev The function stores a new Vehicle struct in vehicles, saves the Id to vehicleIds and grants the address the VEHICLE role
     * @custom:emits Emits a NewVehicle event with the vehicle creator address and the vehicle Id
     */
    function createVehicle(
        address vehicleAddress,
        uint256 mileageAtCreation,
        uint256 vehicleLongitude,
        uint256 vehicleLatitude,
        uint256 vehicleStateOfCharge
    ) external override onlyFleetOwner {
        address owner = _msgSender();

        // Creates a new vehicle instance
        Vehicle memory newVehicle = Vehicle({
            vehicleAddress: vehicleAddress,
            owner: owner,
            user: payable(address(0)),
            mileage: mileageAtCreation,
            latitude: vehicleLatitude,
            longitude: vehicleLongitude,
            state: State.maintenance,
            stateOfCharge: vehicleStateOfCharge
        });

        // Save new vehicle and increment vehicle id
        uint256 newVehicleId = vehicleCounter.current();
        vehicles[newVehicleId] = newVehicle;
        vehicleIds.push(newVehicleId);
        vehicleCounter.increment();

        m4AServiceContract.grantVehicleRole(vehicleAddress);

        emit NewVehicle(owner, newVehicleId, vehicleAddress);
    }

    /**
     * @notice Removes a vehicle. Can only be done by the vehicle owner.
     * @param vehicleId - The Id of the vehicle to remove
     * @dev Removes the entry in the vehicles mapping and in the vehicleIds list
     * @custom:emits Emits a VehicleRemoved event with the vehicle owner address and the vehicle Id
     */
    function removeVehicle(uint256 vehicleId)
        external
        override
        existingId(vehicleId)
        onlyFleetOwner
    {
        Vehicle memory vehicle = vehicles[vehicleId];
        State currentState = vehicle.state;

        require(currentState != State.inUse, "Vehicle still in use");

        address owner = vehicle.owner;
        address vehicleAddress = vehicle.vehicleAddress;

        // Delete element from vehicles mapping
        delete vehicles[vehicleId];

        // Delete id from vehicleIds array
        uint256 length = vehicleIds.length;
        for (uint256 i = 0; i < length; i++) {
            if (vehicleIds[i] == vehicleId) {
                vehicleIds[i] = vehicleIds[length - 1];
                vehicleIds.pop();
                break;
            }
        }

        m4AServiceContract.revokeVehicleRole(vehicleAddress);

        emit VehicleRemoved(owner, vehicleId, vehicleAddress);
    }

    /**
     * @notice Explicitly sets the state of a specific vehicle. Can only be done by the vehicle owner.
     * @param vehicleId - The vehicle's Id
     * @param newState - The new state to set the vehicle in
     * @custom:emits Emits a StateChange event with the owner's address, the vehicle Id and the new state
     */
    function setVehicleState(uint256 vehicleId, State newState)
        external
        override
        existingId(vehicleId)
        onlyFleetOwner
    {
        vehicles[vehicleId].state = newState;

        emit StateChange(vehicles[vehicleId].owner, vehicleId, newState);
    }

    /**
     * @notice Returns the current state of a vehicle. Can only be done by the vehicle owner.
     * @param vehicleId - The vehicle Id
     * @return The current state of the vehicle
     */
    function getVehicleState(uint256 vehicleId)
        public
        view
        override
        existingId(vehicleId)
        onlyWhitelisted
        returns (State)
    {
        return vehicles[vehicleId].state;
    }

    /**
     * @notice Sets the msg.sender to the reservant of the vehicle and changes its state
     * @param vehicleId - The Id of the vehicle
     */
    function reserveVehicle(uint256 vehicleId)
        external
        existingId(vehicleId)
        onlyMember
    {
        require(vehicles[vehicleId].state == State.free, "Vehicle not free");

        vehicles[vehicleId].user = _msgSender();
        vehicles[vehicleId].state = State.reserved;

        emit StateChange(_msgSender(), vehicleId, State.reserved);
    }

    /**
     * @notice Undoes a reservation and sets the vehicle status to free
     * @param vehicleId - The Id of the vehicle to pause
     * @param longitude - The current longitude of the vehicle
     * @param latitude - The current latitude of the vehicle
     * @param soc - The current state of charge of the vehicle
     * @param mileage - The new vehicle mileage
     * @custom:emits * @custom:emits Emits a StateChange event, the vehicle Id and the new state (free)
     */
    function undoReservation(
        uint256 vehicleId,
        uint256 longitude,
        uint256 latitude,
        uint256 soc,
        uint256 mileage
    ) external override existingId(vehicleId) onlyVehicle {
        Vehicle memory currentVehicle = vehicles[vehicleId];
        require(currentVehicle.state == State.reserved, "Vehicle not reserved");

        vehicles[vehicleId].state = State.free;
        vehicles[vehicleId].user = address(0);
        vehicles[vehicleId].longitude = longitude;
        vehicles[vehicleId].latitude = latitude;
        vehicles[vehicleId].stateOfCharge = soc;
        vehicles[vehicleId].mileage = mileage;

        emit StateChange(address(0), vehicleId, State.free);
    }

    /**
     * @notice Starts or continues a ride with a vehicle
     * @param vehicleId - The id of the vehicle to ride with
     * @param vehicle - A struct containing the updated vehicle information
     * @param newRide - Whether or not a new ride is started (newRide=true) or an old ride is continued (newRide=false)
     * @custom:emits Emits a StateChange event with the customer's address, the vehicle Id and the new state (inUse)
     */
    function startRide(
        uint256 vehicleId,
        Vehicle memory vehicle,
        bool newRide
    ) external override existingId(vehicleId) onlyVehicle {
        Vehicle memory currentVehicle = vehicles[vehicleId];

        if (newRide) {
            require(
                currentVehicle.state == State.reserved,
                "Vehicle not reserved"
            );
            require(
                currentVehicle.mileage == vehicle.mileage,
                "Inconsistent mileage"
            );
        } else {
            require(currentVehicle.state == State.paused, "Vehicle not paused");
            require(
                currentVehicle.mileage <= vehicle.mileage,
                "Inconsistent mileage"
            );
        }

        require(currentVehicle.user == vehicle.user, "Not the vehicle user");

        currentVehicle.user = vehicle.user;
        currentVehicle.longitude = vehicle.longitude;
        currentVehicle.latitude = vehicle.latitude;
        currentVehicle.stateOfCharge = vehicle.stateOfCharge;
        currentVehicle.state = State.inUse;

        if (newRide) currentVehicle.mileage = vehicle.mileage;

        vehicles[vehicleId] = currentVehicle;

        emit StateChange(vehicle.user, vehicleId, State.inUse);
    }

    /**
     * @notice Ends a ride with a vehicle
     * @param vehicleId - The Id of the vehicle
     * @param ticketId - The NFTicket Id
     * @param vehicle - A struct containing the updated vehicle information
     * @custom:emits Emits a StateChange event with the customer's address, the vehicle Id and the new state (free)
     */
    function endRide(
        uint256 vehicleId,
        uint256 ticketId,
        Vehicle memory vehicle
    ) external override existingId(vehicleId) onlyVehicle {
        Vehicle memory currentVehicle = vehicles[vehicleId];
        uint256 oldVehicleMileage = currentVehicle.mileage;
        uint256 newVehicleMileage = vehicle.mileage;
        address newVehicleUser = vehicle.user;

        require(currentVehicle.state == State.inUse, "Vehicle not in use");
        require(newVehicleUser == currentVehicle.user, "Not the vehicle user");
        require(
            newVehicleMileage > oldVehicleMileage,
            "Mileage did not increase."
        );

        // The ride distance has to be calculated in km. This calculation yields the distance and cuts off
        // all digits after the comma, then adds 1 to the result to round up to the next integer.
        uint256 rideDistance = newVehicleMileage
            .sub(oldVehicleMileage)
            .mul(1000)
            .div(1000)
            .div(1000)
            .add(1);

        uint256 creditsPerKm = m4AServiceContract.creditsPerKm();
        uint256 creditsForRide = rideDistance.mul(creditsPerKm);

        // Initiate the NFTicket logic, distribute fees, reduce credits
        // and transfer NFTicket back to user wallet
        m4AServiceContract.presentTicket(
            ticketId,
            _msgSender(),
            creditsForRide,
            newVehicleUser
        );

        currentVehicle.user = address(0);
        currentVehicle.state = vehicle.stateOfCharge > minStateOfCharge
            ? State.free
            : State.maintenance;
        currentVehicle.mileage = newVehicleMileage;
        currentVehicle.longitude = vehicle.longitude;
        currentVehicle.latitude = vehicle.latitude;
        currentVehicle.stateOfCharge = vehicle.stateOfCharge;

        setVehicle(vehicleId, currentVehicle);

        emit StateChange(newVehicleUser, vehicleId, currentVehicle.state);
        emit RideEnded(newVehicleUser, vehicleId, creditsForRide);
    }

    /**
     * @notice Pauses a ride
     * @param vehicleId - The Id of the vehicle to pause
     * @param longitude - The current longitude of the vehicle
     * @param latitude - The current latitude of the vehicle
     * @param soc - The current state of charge of the vehicle
     * @param user - The user of the vehicle
     * @custom:emits * @custom:emits Emits a StateChange event with the customer's address, the vehicle Id and the new state (paused)
     */
    function pauseRide(
        uint256 vehicleId,
        uint256 longitude,
        uint256 latitude,
        uint256 soc,
        address user
    ) external override existingId(vehicleId) onlyVehicle {
        Vehicle memory currentVehicle = vehicles[vehicleId];
        require(currentVehicle.state == State.inUse, "Vehicle not in use");
        require(currentVehicle.user == user, "Not the vehicle user");

        vehicles[vehicleId].state = State.paused;
        vehicles[vehicleId].longitude = longitude;
        vehicles[vehicleId].latitude = latitude;
        vehicles[vehicleId].stateOfCharge = soc;

        emit StateChange(user, vehicleId, State.paused);
    }

    /**
     * @notice Returns the information about a vehicle
     * @param vehicleId - The vehicle Id
     * @return A dictionary of the current parameters of the vehicle
     */
    function getVehicleById(uint256 vehicleId)
        external
        view
        override
        existingId(vehicleId)
        onlyWhitelisted
        returns (Vehicle memory)
    {
        return vehicles[vehicleId];
    }

    /**
     * @notice Returns the id's of all vehicles owned by the sender's address
     */
    function getMyVehicles()
        external
        view
        override
        onlyFleetOwner
        returns (uint256[] memory)
    {
        return vehicleIds;
    }

    /**
     * @notice Returns the id's of all currently booked vehicles owned by the sender's address
     */
    function getMyBookedVehicles()
        external
        view
        override
        onlyFleetOwner
        returns (uint256[] memory)
    {
        // Get the number of booked vehicles
        uint256 noMyBookedVehicles = 0;
        uint256 length = vehicleIds.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 currentVehicleId = vehicleIds[i];
            State vehicleState = getVehicleState(currentVehicleId);

            if (vehicleState == State.inUse || vehicleState == State.paused) {
                ++noMyBookedVehicles;
            }
        }

        // Search vehicles in inUse or paused state
        uint256[] memory myBookedVehicles = new uint256[](noMyBookedVehicles);
        uint256 index = 0;
        for (uint256 i = 0; i < length; i++) {
            uint256 currentVehicleId = vehicleIds[i];
            State vehicleState = getVehicleState(currentVehicleId);

            if (vehicleState == State.inUse || vehicleState == State.paused) {
                myBookedVehicles[index] = currentVehicleId;
                ++index;

                // Stop looping through vehicleIds if there are only free vehicles left
                if (index >= noMyBookedVehicles) break;
            }
        }

        return myBookedVehicles;
    }

    /**
     * @notice Gets the id's of all currently free vehicles
     */
    function getFreeVehicles()
        external
        view
        override
        onlyMember
        returns (uint256[] memory)
    {
        // Get number of free vehicles
        uint256 numFreeVehicles = 0;
        uint256 length = vehicleIds.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 currentId = vehicleIds[i];
            State currentState = vehicles[currentId].state;

            if (currentState == State.free) numFreeVehicles++;
        }

        // Make list of free vehicles
        uint256[] memory freeVehicles = new uint256[](numFreeVehicles);
        uint256 index = 0;
        for (uint256 i = 0; i < length; i++) {
            uint256 currentId = vehicleIds[i];
            State currentState = vehicles[currentId].state;

            if (currentState == State.free) {
                freeVehicles[index] = currentId;
                ++index;
            }

            // Stop looping through vehicleIds if there are no free vehicles left
            if (index >= numFreeVehicles) break;
        }

        return freeVehicles;
    }

    /**
     * @notice Returns the current user of a vehicle
     * @param vehicleId - The vehicle in question
     * @return The public address of the current vehicle user
     */
    function getVehicleUser(uint256 vehicleId)
        external
        view
        override
        returns (address)
    {
        return vehicles[vehicleId].user;
    }

    /**
     * @dev Returns the current vehicle Id. Can only be done by the fleet owner.
     */
    function returnCurrentId() external view onlyFleetOwner returns (uint256) {
        return vehicleCounter.current();
    }

    function setVehicle(uint256 vehicleId, Vehicle memory vehicle) internal {
        vehicles[vehicleId] = vehicle;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

/*
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

pragma solidity ^0.8.0;

import "../NFTicket/contracts/interfaces/INFTServiceTypes.sol";

interface IM4AService {
    function creditsPerKm() external returns (uint256);

    function registerVehicleController(address _vehicleController) external;

    function setPricePerCredit(uint256 _pricePerCredit) external;

    function setServiceDescriptor(uint32 _serviceDescriptor) external;

    function setServiceFee(uint256 _serviceFee) external;

    function setResellerFee(uint256 _resellerFee) external;

    function setCreditsPerKm(uint32 _creditsPerKm) external;

    function setMinCredits(uint32 _minCredits) external;

    function setMaxCredits(uint32 _maxCredits) external;

    function isMember(address account) external view returns (bool);

    function makeDefaultAdmin(address account) external;

    function isDefaultAdmin(address account) external view returns (bool);

    function ownerOf(uint256 tokenId) external view returns (address);

    function grantMemberRole(address account) external;

    function revokeMemberRole(address account) external;

    function isVehicle(address account) external view returns (bool);

    function grantVehicleRole(address account) external;

    function revokeVehicleRole(address account) external;

    function checkTicket(
        uint256 tokenID,
        address presenter
    ) external view returns (bool);

    function getPriceForTopUp(
        uint256 tokenID
    ) external view returns (uint256 numberOfBlxm);

    function presentTicket(
        uint256 tokenID,
        address presenter,
        uint256 credits,
        address ticketReceiver
    ) external;

    function topUpTicket(
        uint256 tokenID
    ) external returns (uint256 creditsAffordable, uint256 chargedERC20);

    function buyM4ATicket(
        address userAddress,
        uint256 credits,
        string memory _tokenURI
    ) external returns (uint256 newTicketID);

    event ticketIssued(uint256 indexed newTicketId, Ticket _t, uint256 price);

    event ticketPresented(
        uint256 tokenID,
        address from,
        address to,
        uint256 creditsPresented,
        uint256 creditsRemaining
    );
    event topUpCreditsSuccessful(uint256 creditsForTopUp, uint256 chargedERC20);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVehicleController {
    /**
     * @dev Emitted when the state of a vehicle changes
     * @param stateChanger - The address that changes that vehicle state
     * @param vehicleId - The id of the vehicle the state of which is changed
     * @param newVehicleState - The new state of the vehicle
     */
    event StateChange(
        address indexed stateChanger,
        uint256 indexed vehicleId,
        State indexed newVehicleState
    );

    /**
     * @dev Emitted when a new vehicle is added
     * @param vehicleOwner - The vehicle owner's address
     * @param vehicleId - The id of the new vehicle
     * @param vehicleAddress - The public address of the vehicle's wallet
     */
    event NewVehicle(
        address indexed vehicleOwner,
        uint256 indexed vehicleId,
        address indexed vehicleAddress
    );

    /**
     * @dev Emitted when a vehicle is removed
     * @param vehicleOwner - The vehicle owner's address
     * @param vehicleId - The id of the new vehicle
     * @param vehicleAddress - The public address of the vehicle's wallet
     */
    event VehicleRemoved(
        address indexed vehicleOwner,
        uint256 indexed vehicleId,
        address indexed vehicleAddress
    );

    /**
     * @dev Emitted when a user ends a ride
     * @param user - The user
     * @param vehicleId - The Id of the corresponding vehicle
     * @param numCreditsForRide - The number of credits that have been reduced
     */
    event RideEnded(address user, uint256 vehicleId, uint256 numCreditsForRide);

    function setMinStateOfCharge(uint256 minSoc) external;

    function getMinStateOfCharge() external view returns (uint256);

    function createVehicle(
        address vehicleAddress,
        uint256 mileageAtCreation,
        uint256 longitude,
        uint256 latitude,
        uint256 stateOfCharge
    ) external;

    function removeVehicle(uint256 vehicleId) external;

    function setVehicleState(uint256 vehicleId, State state) external;

    function startRide(
        uint256 vehicleId,
        Vehicle memory vehicle,
        bool isNewRide
    ) external;

    function endRide(
        uint256 vehicleId,
        uint256 ticketId,
        Vehicle memory vehicle
    ) external;

    function pauseRide(
        uint256 vehicleId,
        uint256 longitude,
        uint256 latitude,
        uint256 stateOfCharge,
        address vehicleUser
    ) external;

    function undoReservation(
        uint256 vehicleId,
        uint256 longitude,
        uint256 latitude,
        uint256 stateOfCharge,
        uint256 mileage
    ) external;

    function getVehicleState(uint256 vehicleId)
        external
        view
        returns (State vehicleState);

    function getVehicleById(uint256 vehicleId)
        external
        view
        returns (Vehicle memory vehicle);

    function getMyVehicles()
        external
        view
        returns (uint256[] memory vehicleIds);

    function getMyBookedVehicles()
        external
        view
        returns (uint256[] memory bookedVehicleIds);

    function getFreeVehicles()
        external
        view
        returns (uint256[] memory freeVehicleIds);

    function getVehicleUser(uint256 vehicleId) external view returns (address);
}

enum State {
    free,
    reserved,
    inUse,
    paused,
    maintenance
}

struct Vehicle {
    address vehicleAddress;
    address owner;
    address user;
    uint256 mileage;
    uint256 latitude;
    uint256 longitude;
    State state;
    uint256 stateOfCharge;
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
library CountersUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// First byte is Processing Mode: from here we derive the caluclation and account booking logic
// basic differentiator being Ticket or Certificate (of ownership)
// all tickets need lowest bit of first semi-byte set
// all certificates need lowest bit of first semi-byte set
// all checkin-checkout tickets need second-lowest bit of first-semi-byte set --> 0x03000000
// high bits for each byte or half.byte are categories, low bits are instances
uint32 constant IS_CERTIFICATE =    0x40000000; // 2nd highest bit of CERTT-half-byte = 1 - cannot use highest bit?
uint32 constant IS_TICKET =         0x08000000; // highest bit of ticket-halfbyte = 1
uint32 constant CHECKOUT_TICKET =   0x09000000; // highest bit of ticket-halfbyte = 1 AND lowest bit = 1
uint32 constant CASH_VOUCHER =      0x0A000000; // highest bit of ticket-halfbyte = 1 AND 2nd bit = 1

// company identifiers last 10 bbits, e.g. 1023 companies
uint32 constant BLOXMOVE =          0x00000200; // top of 10 bits for company identifiers
uint32 constant NRVERSE =           0x00000001;
uint32 constant MITTWEIDA =         0x00000002;
uint32 constant EQUOTA =            0x00000003;

// Industrial Category - byte2
uint32 constant THG =               0x80800000; //  CERTIFICATE & highest bit of category half-byte = 1
uint32 constant REC =               0x80400000; //  CERTIFICATE & 2nd highest bit of category half-byte = 1

// Last byte is company identifier 1-255
uint32 constant NRVERSE_REC =       0x80800001; // CERTIFICATE & REC & 0x00000001
uint32 constant eQUOTA_THG =        0x80400003; // CERTIFICATE & THG & 0x00000003
uint32 constant MITTWEIDA_M4A =     0x09000002; // CHECKOUT_TICKET & MITTWEIDA
uint32 constant BLOXMOVE_CO =       0x09000200;
uint32 constant BLOXMOVE_CV =       0x0A000200;
uint32 constant BLOXMOVE_CI =       0x08000200;
uint32 constant BLOXMOVE_NG =       0x09000201;
uint32 constant DutchMaaS =         0x09000003;
uint32 constant TIER_MW =           0x09000004;



/***********************************************
 *
 * generic schematizable data payload
 * allows for customization between reseller and
 * service operator while keeping NFTicket agnostic
 *
 ***********************************************/

enum eDataType {
    _UNDEF,
    _UINT,
    _UINT256,
    _USTRING
}

struct TicketInfo {
    uint256 ticketFee;
    bool ticketUsed;
}


/*
* TODO reconcile redundancies between Payload, BuyNFTicketParams and Ticket
*/
struct Ticket {
    uint256 tokenID;
    address serviceProvider; // the index to the map where we keep info about serviceProviders
    uint32  serviceDescriptor;
    address issuedTo;
    uint256 certValue;
    uint    certValidFrom; // value can be redeemedn after this time
    uint256 price;
    uint256 credits;        // [7]
    uint256 pricePerCredit;
    uint256 serviceFee;
    uint256 resellerFee;
    uint256 transactionFee;
    string tokenURI;
}

struct Payload {
    address recipient;
    string tokenURI;
    DataSchema schema;
    string[] data;
    string[] serializedTicket;  
    uint256 certValue;
    string uuid;
    uint256 credits;
    uint256 pricePerCredit;
    uint256 price;
    uint256 timestamp;
}

/**** END TODO reconcile */

struct DataSchema {
    string name;
    uint32 size;
    string[] keys;
    uint8[] keyTypes;
}

struct DataRecords {
    DataSchema _schema;
    string[] _data; // a one-dimensional array of length [_schema.size * <number of records> ]
}

struct ConsumedRecord {
    uint certId;
    string energyType;
    string location;
    uint amount;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
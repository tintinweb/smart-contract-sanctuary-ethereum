// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract RCO is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public carId;

    struct Car {
        bool allowed;
        uint16 id;
        uint16 stars;
        uint128 pricePerHour;
        string carName;
        string[] comments;
        uint time;
    }

    struct User {
        bool registred;
        uint16 rides;
        uint16 carID;
        uint256 deposited;
        string name;
        string surname;
        string photoURL;
        string licensePhotoURL;
    }

    mapping(address => User) public registredUsers;
    mapping(uint256 => Car) public cars;

    uint256 protocolFee = 500;
    uint256 baseFeePoints = 100000;

    function addCar(
        bool allowed,
        uint16 stars,
        uint128 price,
        string memory carName,
        string[] memory comments
    ) public onlyOwner {
        carId.increment();
        Car memory newCar = Car(
            allowed,
            uint16(carId.current()),
            0,
            price,
            carName,
            comments,
            0
        );
        cars[carId.current()] = newCar;
    }

    function rent(uint256 id, uint256 time) public payable {
        require(time > 0, "min rent time is 1 hour");
        require(
            registredUsers[msg.sender].registred == true,
            "user is not added"
        );

        Car memory car = cars[id];
        User memory user = registredUsers[msg.sender];

        uint256 carPrice = time * car.pricePerHour;

        require(msg.value >= carPrice, "Influence amount");
        require(car.allowed == true, "car Is Busy");

        uint256 currentTimestamp = block.timestamp;
        uint256 HoursInSeconds = time * 60 * 60; // 3 hours in seconds
        uint256 endTime = currentTimestamp + HoursInSeconds;

        car.allowed = false;
        user.deposited += msg.value;
        user.carID = uint16(carId.current());
        car.time = endTime;
        cars[id] = car;
        registredUsers[msg.sender] = user;
    }

    function addUser(string memory _name, string memory _surname) public {
        User memory user = registredUsers[msg.sender];
        require(user.registred == false, "user already sign up");
        user.registred = true;
        user.name = _name;
        user.surname = _surname;
        user.rides = 0;
        user.deposited = 0;
        registredUsers[msg.sender] = user;
    }

    function returnCar(uint256 id) public {
        User memory user = registredUsers[msg.sender];
        require(cars[id].allowed == false, "Car is not being used now");
        require(user.registred == true, "User is not added");
        require(
            registredUsers[msg.sender].carID == id,
            "user didn`t rent this car"
        );

        uint256 returnedValue = user.deposited;
        user.deposited = 0;
        cars[id].allowed = true;
        uint256 returnedValueWithFee = returnedValue -
            ((returnedValue * protocolFee) / baseFeePoints);

        // Send Ether from the contract to the user
        payable(address(this)).transfer(returnedValueWithFee);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
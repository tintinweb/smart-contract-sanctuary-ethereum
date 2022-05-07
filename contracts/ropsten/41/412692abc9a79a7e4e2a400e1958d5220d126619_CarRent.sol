/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol


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

// File: test.sol



pragma solidity >=0.8.0;


contract CarRent {
    address public owner;
    using Counters for Counters.Counter;
    Counters.Counter public car_counter;

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    struct Car {
        Counters.Counter cid;
        uint256 price;
        address addr;
    }

    struct Inventory {
        Car car;
        uint256 timestamp;
    }

    mapping(uint256 => Car) public cars;
    mapping (uint256 => bool) public record_check;
    Car CarInfo;
    Inventory[] public records;
    Inventory InventoyInfo;

    function AddCar(uint256 price, address addr) public isOwner {
        CarInfo = Car(car_counter, price, addr);
        cars[car_counter.current()] = (CarInfo);
        car_counter.increment();
    }

    function AddRecord (uint256 id) public isOwner  {
        require(id >=0, "invalid id");
        require(record_check[id]==false, "Car is added already");
        InventoyInfo = Inventory(cars[id], block.timestamp);
        records.push(InventoyInfo);
    }

    function getRecords() public view returns(Inventory[] memory) {

        return records;
}

}
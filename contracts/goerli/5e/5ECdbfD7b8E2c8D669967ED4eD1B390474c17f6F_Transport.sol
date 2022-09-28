/**
 *Submitted for verification at Etherscan.io on 2022-09-28
*/

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

// File: contracts/Transport.sol


pragma solidity ^0.8.7;


contract Transport {
    using Counters for Counters.Counter;
    
    Counters.Counter private _serviceWorkerCount; //total number of Services
    Counters.Counter private _carCount; //total number of Cars
    Counters.Counter private _inspectionCount; //total number of Inspection

    address owner;
    // Cars public cars;

    struct Cars {
        uint256 itemId;
        uint256 VIN;
        string name;
        string color;
    }

    struct Inspection {
        uint256 itemId;
        uint256 VIN;
        string date;
    }

    event CarsItem (
        uint256 itemId,
        uint256 VIN,
        string name,
        string color
    );

    event InspectionItem (
        uint256 _itemId,
        uint256 VIN,
        string date
    );
       
   

    mapping(address => uint256) public serviceWorker;
    mapping(uint256 => Cars) public cars;
    mapping(uint256 => Inspection) public inspection;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyServiceWorker() {
        require(serviceWorker[msg.sender] != 0, "No such User");
        _;
    }

    function addWorker(address _addr) public onlyOwner {
        _serviceWorkerCount.increment(); //add 1 to the total number of items ever created
        uint256 itemId = _serviceWorkerCount.current();
        serviceWorker[_addr] = itemId;
    }

    function addCar(
        uint256 _VIN,
        string memory _name,
        string memory _color
    ) public onlyServiceWorker {
        
        _carCount.increment(); //add 1 to the total number of items ever created
        uint256 itemId = _carCount.current();

        cars[itemId] = Cars(
            itemId,
            _VIN,
            _name,
            _color
        );

        emit CarsItem(
            itemId,
            _VIN,
            _name,
            _color
        );
    }

    function addInspection(
        uint256 _VIN,
        string memory _date
    ) public onlyServiceWorker {
        
         _inspectionCount.increment(); //add 1 to the total number of items ever created
        uint256 itemId = _inspectionCount.current();

        inspection[itemId] = Inspection(
            itemId,
            _VIN,
            _date
        );

        emit InspectionItem(
            itemId,
            _VIN,
            _date
        );
    }

    function getAllCars() public view returns(Cars[] memory){
        uint256 count = _carCount.current();
        uint256 index = 0;
        
        Cars[] memory items= new Cars[](count);

        for (uint256 i = 0; i < count; i++) {
            uint256 currentId = cars[i + 1].itemId;
            Cars storage currentItem = cars[currentId];
            items[index] = currentItem;
            index += 1;
        }
        return items;
    }

    function getCar(uint256 vin) public view returns(Cars[] memory){
        uint256 count = _carCount.current();
        uint256 index = 0;
        
        Cars[] memory items= new Cars[](count);

        for (uint256 i = 0; i < count; i++) {
            if (cars[i + 1].VIN == vin) {
                uint256 currentId = cars[i + 1].itemId;
                Cars storage currentItem = cars[currentId];
                items[index] = currentItem;
                index += 1;
            }
            
        }
        return items;
    }

    function getAllInspection() public view returns(Inspection[] memory){
        uint256 count = _inspectionCount.current();
        uint256 index = 0;
        
        Inspection[] memory items= new Inspection[](count);

        for (uint256 i = 0; i < count; i++) {
            uint256 currentId = inspection[i + 1].itemId;
            Inspection storage currentItem = inspection[currentId];
            items[index] = currentItem;
            index += 1;
        }
        return items;
    }

    function getServiceWorkerCount() public view returns (uint) {
        uint count =  _serviceWorkerCount.current();
        return count;
    }

}
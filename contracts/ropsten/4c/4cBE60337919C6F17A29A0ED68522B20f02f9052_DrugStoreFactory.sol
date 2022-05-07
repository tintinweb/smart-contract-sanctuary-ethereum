//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/utils/Counters.sol";
import { DrugStore } from "./DrugStore.sol";


//this contract is a factory contract that will be used to create the drug store
//the created drugstore will be saved in the blockchain

contract DrugStoreFactory {
    using Counters for Counters.Counter;
    Counters.Counter private _storeId;
    event DrugStoreCreated(address indexed storeAddress);
    event DrugsAddedEvent( DrugStore indexed drugStore);

    mapping(uint => address ) public drugStoreUintToAddress;
    address[] public deployedDrugStoreAddress;
    uint256 public lastDrugIndex;

    address private _HA;

    constructor() {
        _HA = msg.sender;
    }

    modifier onlyHA {
        require(_HA == msg.sender , "Only HA");
        _;
    }


    function createDrugStore() public onlyHA returns (address) {
        _storeId.increment();
        address _newDrugStoreAddress = address (new DrugStore());
        deployedDrugStoreAddress.push(_newDrugStoreAddress);
        drugStoreUintToAddress[_storeId.current()] = _newDrugStoreAddress;
        emit DrugStoreCreated(_newDrugStoreAddress);
        return _newDrugStoreAddress;
    }

  


    function getDrugStoreDetails( DrugStore _drugStoreAddress, uint _drugID ) 
       public view returns ( DrugStore.Drugs memory ) {
        return _drugStoreAddress.getDrugs(_drugID);
    }

     function addDrugs(DrugStore _drugStore ,string memory _drugName, 
                      string memory _description, 
                      string memory _dosage) public onlyHA returns  (uint) {
        uint _drugID = _drugStore.addDrugs(_drugName, _description, _dosage);
        lastDrugIndex = _drugID;
        emit DrugsAddedEvent(_drugStore);
        return lastDrugIndex;
    }



    function getDrugs(DrugStore _drugStore, uint _id) external view returns (DrugStore.Drugs memory) {
        return _drugStore.getDrugs(_id);
    }

   function increaseDrugsQuantity(DrugStore _drugStore,uint _id) public onlyHA {
       _drugStore.increaseDrugsQuantity(_id);
    }

   function decreaseDrugsQuantity(DrugStore _drugStore,uint _id) external {
        _drugStore.decreaseDrugsQuantity(_id);
   }

    function viewDrugQuantity(DrugStore _drugStore, uint _id) external view returns (uint) {
       uint drugQuantity = _drugStore.viewDrugQuantity(_id);
       return drugQuantity;
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/utils/Counters.sol";


contract DrugStore {
    using Counters for Counters.Counter;
    Counters.Counter private _drugsId;

    mapping(uint => Drugs ) public drugs;
    mapping(uint => uint) public drugsQuantity;
    event DrugsAddedEvent( uint256 drugIndex);

    address private _HA;

    struct Drugs {
        string name;
        string description;
        string dosage;
        uint id;
    }


    modifier onlyHA {
        require(_HA == msg.sender , "Only HA");
        _;
    }

    constructor () {
        _HA = msg.sender;
        for (uint i = 0; i < 5; i++) {
            if ( i == 0 ){
                uint _id = _drugsId.current();
                drugs[i] = Drugs({
                name: "Cancer drug",
                description: "Description ",
                dosage: "Twice daily",
                id: _id
            });
             drugsQuantity[i] = 10;
             _drugsId.increment();
            }
            if ( i == 1 ){
                 uint _id = _drugsId.current();
                drugs[i] = Drugs({
                name: "Diabetics drug",
                description: "Description",
                dosage: "Twice daily",
                id: _id
            });
             drugsQuantity[i] = 10;
             _drugsId.increment();
            }
            if ( i == 2 ){
                 uint _id = _drugsId.current();
                drugs[i] = Drugs({
                name: "Polimate drug",
                description: "Description ",
                dosage: "Twice daily",
                id: _id
            });
             drugsQuantity[i] = 10;
             _drugsId.increment();
            }
            if ( i == 3 ){
                 uint _id = _drugsId.current();
                drugs[i] = Drugs({
                name: "Flanning drug",
                description: "Description ",
                dosage: "Twice daily",
                id: _id
            });
             drugsQuantity[i] = 10;
             _drugsId.increment();
            }
            if ( i == 4 ){
                 uint _id = _drugsId.current();
                drugs[i] = Drugs({
                name: "Bonner drug",
                description: "Description ",
                dosage: "Once daily",
                id: _id
            });
             drugsQuantity[i] = 10;
             _drugsId.increment();
            }
        }
    }


    function addDrugs(string memory _drugName, 
                      string memory _description, 
                      string memory _dosage) public onlyHA returns (uint) {
        _drugsId.increment();
        uint _id = _drugsId.current();
        drugs[_id] = Drugs({
            name: _drugName,
            description: _description,
            dosage: _dosage,
            id: _id
        });
        
        emit DrugsAddedEvent(_id);
        return _id;
        
    }

  
    function getDrugs(uint _id) external view returns (Drugs memory) {
        return drugs[_id];
    }

    function increaseDrugsQuantity(uint _id) public onlyHA {
        drugsQuantity[_id] = drugsQuantity[_id] + 1;
    }

    function decreaseDrugsQuantity(uint _id) external {
        drugsQuantity[_id] = drugsQuantity[_id] - 1;
    }

     function viewDrugQuantity(uint _id) external view returns (uint) {
        return drugsQuantity[_id];
    }
}
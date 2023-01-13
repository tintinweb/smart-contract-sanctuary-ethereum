/**
 *Submitted for verification at Etherscan.io on 2023-01-13
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;



// Part: Item

// The Item contract represents a raw material in the simulation.
contract Item {
    string public name;
    uint256 public quantity;

    constructor(string memory _name, uint256 _quantity) public {
        name = _name;
        quantity = _quantity;
    }

    // The add function allows more of the item to be
    // added to the supply.
    function add(uint256 amount) public {
        quantity += amount;
    }

    // The remove function allows some of the item to
    // be removed from the supply, given that there is enough.
    function remove(uint256 amount) public {
        require(quantity >= amount, "Not enough items");
        quantity -= amount;
    }
}

// Part: Machine

// Represents a machine in the simulation that carries out a process.
contract Machine {
    string public name; // Machine/process name
    uint256 public productionRate; // in units per hour
    bool public isFunctioning;

    constructor(string memory _name, uint256 _productionRate) public {
        name = _name;
        productionRate = _productionRate;
        isFunctioning = true;
    }

    // Allows the machine to be repaired by setting isFunctioning flag to 'true'.
    function repair() public {
        isFunctioning = true;
    }

    // The produce function allows the machine to create a specified number of
    // units of a Item object (provided it is functioning).
    function produce(Item item, uint256 units) public {
        require(isFunctioning, "Machine is not functioning");
        item.add(units);
    }
}

// File: ManufacturingSimulation.sol

// This contract coordinates the simulation, keeping track of the machines, raw materials, finished
// products, and WIPs. It provides functions for adding and interacting with these entities.

contract ManufacturingSimulation {
    // Mapping from machine IDs to Machine contract instances
    mapping(uint256 => Machine) public machines;

    // Mappings from names to contract instances
    mapping(string => Item) public items;

    // Counter for generating unique machine IDs
    uint256 public machineCounter;

    // Allows a new machine to be added to simulation
    function addMachine(string memory name, uint256 productionRate) public {
        machines[machineCounter] = new Machine(name, productionRate);
        machineCounter++;
    }

    // Allows a new item to be added to the simulation
    function addItem(string memory name, uint256 quantity) public {
        items[name] = new Item(name, quantity);
    }

    // Allows a machine to be repaired.
    function repair(uint256 machineId) public {
        machines[machineId].repair();
    }

    // The produce function allows a machine to produce a specified number of units of a WIP item.
    function produce(
        uint256 machineId,
        string memory itemName,
        uint256 units
    ) public {
        Machine machine = machines[machineId];
        Item item = items[itemName];
        machine.produce(item, units);
    }
}
/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;



// Part: FinishedProduct

// The FinishedProduct contract represents a finished product
// in the simulation. It has a name and a quantity.
contract FinishedProduct {
    string public name;
    uint256 public quantity;

    constructor(string memory _name, uint256 _quantity) public {
        name = _name;
        quantity = _quantity;
    }

    // The add function allows more of the finished product to
    // be added to the supply.
    function add(uint256 amount) public {
        quantity += amount;
    }

    // The remove function allows some of the finished
    // product to be removed from the supply, given that there is enough.
    function remove(uint256 amount) public {
        require(quantity >= amount, "Not enough finished product");
        quantity -= amount;
    }
}

// Part: RawMaterial

// The RawMaterial contract represents a raw material in the
// simulation. It has a name and a quantity.
contract RawMaterial {
    string public name;
    uint256 public quantity;

    constructor(string memory _name, uint256 _quantity) public {
        name = _name;
        quantity = _quantity;
    }

    // The add function allows more of the raw material to be
    // added to the supply.
    function add(uint256 amount) public {
        quantity += amount;
    }

    // The remove function allows some of the raw material to
    // be removed from the supply, given that there is enough.
    function remove(uint256 amount) public {
        require(quantity >= amount, "Not enough raw material");
        quantity -= amount;
    }
}

// Part: WorkInProgress

// The WorkInProgress contract represents materials that are
// in the process of being transformed from raw materials into
// finished products. It has a name and a quantity.
contract WorkInProgress {
    string public name;
    uint256 public quantity;

    constructor(string memory _name, uint256 _quantity) public {
        name = _name;
        quantity = _quantity;
    }

    // The add function allows more of the work in progress to be
    // added to the supply.
    function add(uint256 amount) public {
        quantity += amount;
    }

    // The remove function allows some of the work in progress to
    // be removed from the supply, given that there is enough.
    function remove(uint256 amount) public {
        require(quantity >= amount, "Not enough work in progress");
        quantity -= amount;
    }
}

// Part: Machine

// The Machine contract represents a machine in the simulation.
// It has a name, a production rate (in units per hour), and a
// boolean flag indicating whether it is currently functioning.
contract Machine {
    string public name;
    uint256 public productionRate;
    bool public isFunctioning;

    constructor(string memory _name, uint256 _productionRate) public {
        name = _name;
        productionRate = _productionRate;
        isFunctioning = true;
    }

    // The repair function allows the machine to be repaired,
    // setting its isFunctioning flag to true.
    function repair() public {
        isFunctioning = true;
    }

    // The produce function allows the machine to produce a
    // specified number of units of a WorkInProgress object,
    // given that it is functioning.
    function produce(WorkInProgress workInProgress, uint256 units) public {
        require(isFunctioning, "Machine is not functioning");
        workInProgress.add(units);
    }
}

// File: ManufacturingSimulation.sol

// The ManufacturingSimulation contract coordinates the
// simulation, keeping track of the machines, raw materials,
// finished products, and work in progress. It provides
// functions for adding and interacting with these entities.
contract ManufacturingSimulation {
    // Mapping from machine IDs to Machine contract instances
    mapping(uint256 => Machine) public machines;

    // Mapping from raw material names to RawMaterial contract
    // instances
    mapping(string => RawMaterial) public rawMaterials;

    // Mapping from finished product names to FinishedProduct
    // contract instances
    mapping(string => FinishedProduct) public finishedProducts;

    // Mapping from work in progress names to WorkInProgress
    // contract instances
    mapping(string => WorkInProgress) public workInProgress;

    // Counter for generating unique machine IDs
    uint256 public machineCounter;

    // The addMachine function allows a new machine to be added
    // to the simulation.
    function addMachine(string memory name, uint256 productionRate) public {
        machines[machineCounter] = new Machine(name, productionRate);
        machineCounter++;
    }

    // The addRawMaterial function allows a new raw material to
    // be added to the simulation.
    function addRawMaterial(string memory name, uint256 quantity) public {
        rawMaterials[name] = new RawMaterial(name, quantity);
    }

    // The addFinishedProduct function allows a new finished
    // product to be added to the simulation.
    function addFinishedProduct(string memory name, uint256 quantity) public {
        finishedProducts[name] = new FinishedProduct(name, quantity);
    }

    // The addWorkInProgress function allows a new work in
    // progress to be added to the simulation.
    function addWorkInProgress(string memory name, uint256 quantity) public {
        workInProgress[name] = new WorkInProgress(name, quantity);
    }

    // The repair function allows a machine to be repaired.
    function repair(uint256 machineId) public {
        machines[machineId].repair();
    }

    // The produce function allows a machine to produce a
    // specified number of units of a work in progress.
    function produce(
        uint256 machineId,
        string memory workInProgressName,
        uint256 units
    ) public {
        Machine machine = machines[machineId];
        WorkInProgress wip = workInProgress[workInProgressName];
        machine.produce(wip, units);
    }
}
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

contract SampleSupplyChain {
    string VERSION = "2.0.0";

    constructor() public {}

    struct CoffeeBatch {
        string[] types; // coffee plant types
        string quality; // Good or Best
        string performance; // decimal
        string stains; // decimal
        string humidity; // decimal
    }

    struct Quantity {
        uint16 bags;
        string grossKg; // decimal
        string bagKg; // decimal
        string netKg; // decimal (grossKg â (bags * bagKg))
    }

    event BatchEvent(string __BatchCode, string eventName);

    //=================== SUPPORT TXNS ==================//

    function ToksCode(string memory __ToksCode, string memory __BatchCode) public {}

    function BatchCode(string memory __BatchCode, string memory __Producer, uint32 kg) public {}

    function coffeeTypes(string[] memory types) public {}

    //============== REGISTRATION TXNS ===============//

    function Producer(string memory __Producer, string memory community, string memory name) public {}

    function Coop(string memory __Coop, string memory facility, string memory location) public {}

    function Sheller(string memory __Sheller, string memory facility, string memory location) public {}

    function Warehouse(string memory __Warehouse, string memory facility, string memory location) public {}

    function Roaster(string memory __Roaster, string memory facility, string memory location) public {}

    //================== CO-OP TXNS ==================//

    function fromProducer(
        string memory __BatchCode, // our barcode
        string memory __Producer,
        string memory __Coop,
        uint64 dateTime,
        string memory deliveryId,
        uint64 deliveryDateTime,
        CoffeeBatch memory coffeeBatch,
        Quantity memory quantity,
        string memory coopSig,
        string memory producerSig,
        string memory observations
    ) public {
        emit BatchEvent(__BatchCode, "fromProducer");
    }

    function toSheller(
        string memory __BatchCode, // our barcode
        string memory __Sheller,
        string memory __Coop,
        uint64 dateTime,
        Quantity memory quantity,
        string memory observations
    ) public {
        emit BatchEvent(__BatchCode, "toSheller");
    }

    function fromSheller(
        string memory __BatchCode, // our barcode
        string memory __Sheller,
        string memory __Coop,
        uint64 dateTime,
        Quantity memory quantity,
        string memory observations
    ) public {
        emit BatchEvent(__BatchCode, "fromSheller");
    }

    function toRoaster(
        string memory __BatchCode, // our barcode
        string memory __Roaster,
        string memory __Coop,
        uint64 dateTime,
        string memory observations
    ) public {
        emit BatchEvent(__BatchCode, "toRoaster");
    }

    //================== TOKS TXNS ==================//

    function receiveRoaster(
        string memory __ToksCode, // toks system code
        string memory __BatchCode, // our barcode
        string memory __Roaster,
        uint64 dateTime,
        string memory receiver,
        string memory observations
    ) public {
        emit BatchEvent(__BatchCode, "receiveRoaster");
    }

    function toWarehouse(
        string memory __ToksCode, // toks system code
        string memory __BatchCode, // our barcode
        string memory __Warehouse,
        uint64 dateTime,
        string memory observations
    ) public {
        emit BatchEvent(__BatchCode, "toWarehouse");
    }

    function receiveWarehouse(
        string memory __ToksCode, // toks system code
        string memory __BatchCode, // our barcode
        string memory __Warehouse,
        uint64 dateTime,
        string memory receiver,
        string memory observations
    ) public {
        emit BatchEvent(__BatchCode, "receiveWarehouse");
    }

    function receiveVendor(
        string memory __ToksCode, // toks system code
        string memory __BatchCode, // our barcode
        uint64 dateTime,
        string memory vendorFacility,
        string memory vendorLocation,
        string memory receiver,
        string memory observations
    ) public {
        emit BatchEvent(__BatchCode, "receiveVendor");
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./Tax.sol";

error Unauthorized();

contract BusTaxes is Tax {
    address payable immutable i_owner;
    uint256 public price = 200;
    uint256 public constant taxRate = 5;

    struct Driver {
        address addr;
        uint256 passId;
        string name;
        uint8 busCapacity;
        uint8 passengersCount;
        uint256 tax;
    }

    mapping(uint256 => string) driverIdToName;
    Driver[] public drivers;

    constructor() {
        i_owner = payable(msg.sender);
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function register(
        uint256 _passId,
        string memory _name,
        uint8 _busCapacity,
        uint8 _passengersCount
    ) public notOwner {
        require(_busCapacity >= 12, "Low Vehicle Capacity");
        require(_busCapacity <= 18, "Maximum of 18");
        require(_passengersCount <= _busCapacity, "Invalid passegers count");
        drivers.push(
            Driver(
                msg.sender,
                _passId,
                _name,
                _busCapacity,
                _passengersCount,
                0
            )
        );
        driverIdToName[_passId] = _name;
        handleTax();
    }

    function handleTax() public {
        for (uint i = 0; i < drivers.length; i++) {
            uint256 _taxAmount = _getTaxPrice(
                taxRate,
                drivers[i].passengersCount,
                price
            );
            drivers[i].tax = _taxAmount;
        }
    }

    function getDriversCount() public view onlyOwner returns (uint256) {
        return drivers.length;
    }

    function getDriverTax(uint256 _passId) public view returns (uint256) {
        uint256 tax;
        for (uint i = 0; i < drivers.length; i++) {
            if (drivers[i].passId == _passId) {
                tax = drivers[i].tax;
            }
        }
        return tax;
    }

    function setPassengersCount(uint8 _passengersCount) public notOwner {
        for (uint i = 0; i < drivers.length; i++) {
            if (msg.sender == drivers[i].addr) {
                require(_passengersCount <= drivers[i].busCapacity);
                drivers[i].passengersCount = _passengersCount;
            }
        }
        handleTax();
    }

    // function withdraw() public {
    //     if (msg.sender != i_owner) revert Unauthorized();

    //     i_owner.transfer(address(this).balance);
    // }

    modifier onlyOwner() {
        require(msg.sender == i_owner, "Not Permitted");
        _;
    }

    modifier notOwner() {
        require(msg.sender != i_owner, "Not Permitted");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.1;


contract Tax {
    function _getTaxPrice(
        uint256 _rate,
        uint256 _passengers,
        uint256 _price
    ) internal pure returns(uint256) {
        uint256 tax = (_passengers * _price * _rate) / 100;
        return tax;
    }
}
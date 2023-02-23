// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VehicleRegistration {
    struct User {
        string name;
        string email;
        uint8 role;
        string password;
    }

    struct Vehicle {
        string vin;
        string make;
        string model;
        string color;
        uint256 year;
        string chassisNumber;
        address owner;
        string numberPlate;
    }

    // create usersAddreses array to store the addresses of all the users
    address[] public usersAddresses;

    mapping(address => User) public users;
    mapping(string => address) public emailToAddress;
    mapping(address => Vehicle[]) public vehicles;
    mapping(address => string[]) public chassisNumberRequests;
    mapping(string => address) public numberPlateRequests;
    mapping(address => string[]) public numberPlateRequestsByDealer;
    // create a mapping to store the vehicles with assigned chassis number and number plate

    event NewUserRegistered(
        address indexed userAddress,
        string name,
        string email,
        uint8 role
    );
    event NewVehicleAdded(
        address indexed userAddress,
        string vin,
        string make,
        string model,
        string color,
        uint256 year,
        string chassisNumber
    );
    event ChassisNumberRequested(
        address indexed userAddress,
        string vin,
        string make,
        string model,
        string color,
        uint256 year
    );
    event ChassisNumberAssigned(
        address indexed rtoAddress,
        address indexed manufacturerAddress,
        uint256 index,
        string chassisNumber
    );
    event OwnershipTransferred(
        address indexed dealerAddress,
        address indexed buyerAddress,
        uint256 index
    );
    event NumberPlateRequested(address indexed userAddress, uint256 index);
    event NumberPlateAssigned(
        address indexed rtoAddress,
        uint256 index,
        string numberPlate
    );

    function registerUser(
        string memory _name,
        string memory _email,
        uint8 _role,
        string memory _password
    ) public {
        require(users[msg.sender].role == 0, "User already registered");
        require(_role >= 1 && _role <= 4, "Invalid user role");

        User memory newUser = User({
            name: _name,
            email: _email,
            role: _role,
            password: _password
        });

        users[msg.sender] = newUser;
        emailToAddress[_email] = msg.sender;
        usersAddresses.push(msg.sender);

        emit NewUserRegistered(msg.sender, _name, _email, _role);
    }

    function addVehicle(
        string memory _vin,
        string memory _make,
        string memory _model,
        string memory _color,
        uint256 _year
    ) public {
        require(
            users[msg.sender].role == 2,
            "Only manufacturer can add vehicles"
        );

        Vehicle memory newVehicle = Vehicle({
            vin: _vin,
            make: _make,
            model: _model,
            color: _color,
            year: _year,
            chassisNumber: "",
            owner: msg.sender,
            numberPlate: ""
        });

        vehicles[msg.sender].push(newVehicle);

        emit NewVehicleAdded(
            msg.sender,
            _vin,
            _make,
            _model,
            _color,
            _year,
            ""
        );
    }

    function requestChassisNumber(uint256 index) public {
        require(
            users[msg.sender].role == 2,
            "Only manufacturer can request chassis number"
        );
        require(index < vehicles[msg.sender].length, "Invalid vehicle index");
        require(
            bytes(vehicles[msg.sender][index].chassisNumber).length == 0,
            "Chassis number already assigned"
        );

        Vehicle storage vehicle = vehicles[msg.sender][index];

        chassisNumberRequests[msg.sender].push(
            string(
                abi.encodePacked(
                    vehicle.make,
                    vehicle.model,
                    vehicle.color,
                    vehicle.year
                )
            )
        );

        emit ChassisNumberRequested(
            msg.sender,
            vehicle.vin,
            vehicle.make,
            vehicle.model,
            vehicle.color,
            vehicle.year
        );
    }

    function assignChassisNumber(
        uint256 index,
        string memory chassisNumber
    ) public {
        require(
            users[msg.sender].role == 1,
            "Only RTO can assign chassis number"
        );

        address manufacturerAddress = getChassisNumberRequester(index);

        Vehicle storage vehicle = vehicles[manufacturerAddress][index];

        require(
            bytes(vehicle.chassisNumber).length == 0,
            "Chassis number already assigned"
        );

        vehicle.chassisNumber = chassisNumber;

        emit ChassisNumberAssigned(
            msg.sender,
            manufacturerAddress,
            index,
            chassisNumber
        );
    }

    function transferOwnership(
        uint256 index,
        address dealerAddress,
        address buyerAddress
    ) public {
        require(
            users[msg.sender].role == 2,
            "Only manufacturer can transfer ownership"
        );
        require(index < vehicles[msg.sender].length, "Invalid vehicle index");
        require(
            vehicles[msg.sender][index].owner == msg.sender,
            "Manufacturer does not own this vehicle"
        );

        Vehicle storage vehicle = vehicles[msg.sender][index];

        vehicle.owner = dealerAddress;

        emit OwnershipTransferred(dealerAddress, buyerAddress, index);
    }

    // function to request number plate and add it to the numberPlateRequests mapping as well as to numberPlateRequestsByDealer array and emit an event NumberPlateRequested with the user address and the index of the vehicle in the vehicles array of the user
    function requestNumberPlate(uint256 index) public {
        require(
            users[msg.sender].role == 3,
            "Only dealer can request number plate"
        );
        require(index < vehicles[msg.sender].length, "Invalid vehicle index");
        require(
            bytes(vehicles[msg.sender][index].numberPlate).length == 0,
            "Number plate already assigned"
        );

        Vehicle storage vehicle = vehicles[msg.sender][index];

        numberPlateRequests[vehicle.chassisNumber] = msg.sender;
        numberPlateRequestsByDealer[msg.sender].push(vehicle.chassisNumber);

        emit NumberPlateRequested(msg.sender, index);
    }

    function getChassisNumberRequester(
        uint256 index
    ) public view returns (address) {
        require(
            index < chassisNumberRequests[msg.sender].length,
            "Invalid request index"
        );

        return msg.sender;
    }

    function getNumberPlateRequester(
        string memory chassisNumber
    ) public view returns (address) {
        require(
            numberPlateRequests[chassisNumber] != address(0),
            "Invalid request"
        );

        return numberPlateRequests[chassisNumber];
    }

    function assignNumberPlate(
        string memory chassisNumber,
        string memory numberPlate
    ) public {
        require(
            users[msg.sender].role == 1,
            "Only RTO can assign number plate"
        );

        address dealerAddress = getNumberPlateRequester(chassisNumber);

        Vehicle storage vehicle = vehicles[dealerAddress][0];

        require(
            keccak256(abi.encodePacked(vehicle.chassisNumber)) ==
                keccak256(abi.encodePacked(chassisNumber)),
            "Invalid chassis number"
        );

        vehicle.numberPlate = numberPlate;

        emit NumberPlateAssigned(msg.sender, 0, numberPlate);
    }

    // function to get all the vehicles of a manufacturer
    function getVehicles() public view returns (Vehicle[] memory) {
        require(
            users[msg.sender].role == 2,
            "Only manufacturer can get vehicles"
        );

        return vehicles[msg.sender];
    }

    // function to get the details of a vehicle by vin
    function getVehicleByVin(
        string memory vin
    ) public view returns (Vehicle memory) {
        require(
            users[msg.sender].role == 2,
            "Only manufacturer can get vehicle by vin"
        );

        Vehicle[] memory manufacturerVehicles = vehicles[msg.sender];

        for (uint256 i = 0; i < manufacturerVehicles.length; i++) {
            if (
                keccak256(abi.encodePacked(manufacturerVehicles[i].vin)) ==
                keccak256(abi.encodePacked(vin))
            ) {
                return manufacturerVehicles[i];
            }
        }

        return Vehicle("", "", "", "", 0, "", address(0), "");
    }
}
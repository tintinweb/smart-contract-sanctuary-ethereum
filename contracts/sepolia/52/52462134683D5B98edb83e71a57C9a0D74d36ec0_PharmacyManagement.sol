// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PharmacyManagement {
    enum Role {Pharmacist, Manufacturer, Warehouse, Driver}

    struct User {
        string email;
        string password;
        address walletAddress;
        Role role;
    }

    struct Order {
    string email;
    string name;
    uint256 medicalId;
    uint256 productId;
    bool accepted;
    uint256 trackingNumber;
    uint256 temperature; // Temperature field for each order
    uint256 lastUpdated; // Timestamp of the last temperature update
    address driverAddress; // Address of the chosen driver
}

    struct QRCode {
        bytes32 codeHash;
        bool valid;
        uint256 gtin;
        uint256 expiryDate;
        uint256 id;
        uint256 lotOrBatchNumber;
        uint256 serialNumber;
    }

    struct Driver {
        string name;
        uint256 rating;
    }

    mapping(address => User) public users;
    mapping(Role => mapping(uint256 => Order)) public orders;
    mapping(bytes32 => QRCode) public qrCodes;
    mapping(address => Driver) public drivers;
    address[] public driverAddresses; // Updated to store all driver addresses
    uint256 public orderCount;
    uint256 public qrCodeCount;

    uint256 public constant temperatureExpiration = 3 hours; // Temperature expiration period

    event UserRegistered(address indexed walletAddress, string email, Role role);
    event OrderPlaced(uint256 indexed orderId, string email, Role role);
    event OrderAccepted(uint256 indexed orderId, Role role);
    event QRCodeGenerated(bytes32 indexed codeHash, uint256 gtin, uint256 expiryDate, uint256 id, uint256 lotOrBatchNumber, uint256 serialNumber);
    event QRCodeStored(bytes32 indexed codeHash, bool valid);
    event QRCodeValidated(bytes32 indexed codeHash, bool valid);
    event DriverRated(address indexed driverAddress, string name, uint256 rating);
    event DriverRegistered(address indexed driverAddress, string name, uint256 rating);
    event TemperatureUpdated(uint256 indexed orderId, uint256 temperature, uint256 timestamp); // Event for temperature update
    event OrderPlaced(uint256 indexed orderId, string email, Role role, address driverAddress);

    function registerUser(string memory email, string memory password, Role role) public {
        require(users[msg.sender].walletAddress == address(0), "User already registered");

        users[msg.sender] = User(email, password, msg.sender, role);

        emit UserRegistered(msg.sender, email, role);
    }

    function verifyUser(string memory email, string memory password) public view returns (bool) {
        address userAddress = msg.sender;
        User memory user = users[userAddress];
        return (keccak256(bytes(user.email)) == keccak256(bytes(email))) && (keccak256(bytes(user.password)) == keccak256(bytes(password)));
    }

    function getUserRole(address userAddress) public view returns (Role) {
        return users[userAddress].role;
    }

    function placeOrder(Role role, string memory email, string memory name, uint256 medicalId, uint256 productId, address driverAddress) public {
    require(users[msg.sender].role == role, "Unauthorized");

    uint256 orderId = orderCount++;
    uint256 trackingNumber = orderId + 1; // Generate tracking number based on order count

    orders[role][orderId] = Order(email, name, medicalId, productId, false, trackingNumber, 0, block.timestamp, driverAddress);

    emit OrderPlaced(orderId, email, role, driverAddress);
}

    function acceptOrder(Role role, uint256 orderId) public {
        require(role == Role.Manufacturer || role == Role.Warehouse || role == Role.Driver, "Invalid role");
        require(users[msg.sender].role == role, "Unauthorized");
        require(orders[role][orderId].accepted == false, "Order already accepted");

        orders[role][orderId].accepted = true;

        emit OrderAccepted(orderId, role);
    }

    function generateQRCode(
        uint256 gtin,
        uint256 expiryDate,
        uint256 id,
        uint256 lotOrBatchNumber,
        uint256 serialNumber
    ) public returns (bytes32) {
        require(users[msg.sender].role == Role.Manufacturer, "Only manufacturers can generate QR codes");

        bytes32 codeHash = keccak256(
            abi.encodePacked(
                gtin,
                expiryDate,
                id,
                lotOrBatchNumber,
                serialNumber
            )
        );

        qrCodes[codeHash] = QRCode(codeHash, true, gtin, expiryDate, id, lotOrBatchNumber, serialNumber);
        qrCodeCount++;

        emit QRCodeGenerated(codeHash, gtin, expiryDate, id, lotOrBatchNumber, serialNumber);

        return codeHash;
    }

    function storeQRCode(bytes32 codeHash, bool valid) public {
        require(qrCodes[codeHash].codeHash == bytes32(0), "QR code already stored");

        qrCodes[codeHash] = QRCode(codeHash, valid, 0, 0, 0, 0, 0);

        emit QRCodeStored(codeHash, valid);
    }

    function validateQRCode(bytes32 codeHash) public view returns (bool) {
        return qrCodes[codeHash].valid;
    }

    function rateDriver(address driverAddress, string memory name, uint256 rating) public {
        require(users[msg.sender].role == Role.Pharmacist || users[msg.sender].role == Role.Warehouse, "Unauthorized");
        require(rating >= 1 && rating <= 5, "Invalid rating");

        drivers[driverAddress].name = name;
        drivers[driverAddress].rating = rating;

        emit DriverRated(driverAddress, name, rating);
    }

    function getAllDriverAddresses() public view returns (address[] memory) {
        return driverAddresses;
    }

    function registerDriver(string memory name, uint256 rating) public {
        require(users[msg.sender].walletAddress == address(0), "Driver already registered");

        drivers[msg.sender] = Driver(name, rating);
        driverAddresses.push(msg.sender);

        emit DriverRegistered(msg.sender, name, rating);
    }

    function updateTemperature(uint256 orderId, uint256 temperature) public {
        Order storage order = orders[Role.Driver][orderId];

        order.temperature = temperature;
        order.lastUpdated = block.timestamp;

        emit TemperatureUpdated(orderId, temperature, block.timestamp);
    }

    function getTemperature(uint256 orderId) public view returns (uint256, uint256) {
        Order storage order = orders[Role.Driver][orderId];

        return (order.temperature, order.lastUpdated);
    }

function removeOldTemperatures() public {
    uint256 currentTime = block.timestamp;

    for (uint256 i = 0; i < orderCount; i++) {
        Order storage order = orders[Role.Driver][i];
        if (order.accepted && currentTime - order.lastUpdated >= temperatureExpiration) {
            order.temperature = 0;
            order.lastUpdated = 0;
        }
    }
}
function getDriverOrders(address driverAddress) public view returns (Order[] memory) {
    uint256 driverOrderCount = 0;

    // Count the number of orders associated with the given driver address
    for (uint256 i = 0; i < orderCount; i++) {
        if (orders[Role.Driver][i].driverAddress == driverAddress) {
            driverOrderCount++;
        }
    }

    // Create an array to store the driver's orders
    Order[] memory driverOrders = new Order[](driverOrderCount);
    uint256 currentIndex = 0;

    // Store the orders associated with the given driver address in the array
    for (uint256 i = 0; i < orderCount; i++) {
        if (orders[Role.Driver][i].driverAddress == driverAddress) {
            driverOrders[currentIndex] = orders[Role.Driver][i];
            currentIndex++;
        }
    }

    return driverOrders;
}


}
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;
//import "@openzeppelin/contracts/access/Ownable.sol";

contract VaccineTracker {
    // State variables

    // Contract variables
    address public contractOwner;
    bool public isActive;

    // Batch variables
    struct VaccineBatch {
        string batchId;
        string lab;
        address labAddress;
        string description;
        uint256 creationDate;
        string deliveryDate;
        uint64 units;
        string currentStatus;
        address destination;
    }

    struct ConservationParams {
        string temperature;
        string humidity;
        string luminosity;
    }

    //enum BatchStatus {ready, shipped, delivered}

    uint256[] public timestamps;

    mapping(string => VaccineBatch) private stock;
    mapping(string => mapping(uint256 => string)) private status;
    mapping(string => mapping(uint256 => ConservationParams)) private params;
    mapping(address => mapping(string => bool)) private wallet;

    // Modifiers

    modifier batchExists(string memory batchId) {
        require(
            stock[batchId].units != 0,
            "A batch with this batchId does not exist"
        );
        _;
    }

    modifier contractActive() {
        require(isActive, "Sorry, contract disabled");
        _;
    }

    // Events

    event CreateBatch(
        string message,
        address addressLab,
        string batchId,
        string lab,
        uint256 creationDate
    );
    event DeliverBatch(
        string message,
        address addressLab,
        string batchId,
        address to,
        uint256 deliverDate
    );
    event ConfirmDeliver(
        string message,
        string batchId,
        address to,
        uint256 deliveryDate
    );
    event RegisterParams(
        string message,
        string batchId,
        string temperature,
        string humidity,
        string luminosity
    );

    // Constructor

    constructor() {
        contractOwner = msg.sender;
        admin[msg.sender] = true;
        isActive = true;
    }

    // User management

    mapping(address => bool) private admin;

    function addAdmin(address _newAdmin) external {
        require(isActive, "Contract disabled");
        require(
            msg.sender == contractOwner,
            "Identity is not the contract owner"
        );
        require(!admin[_newAdmin], "Identity is already an admin");
        admin[_newAdmin] = true;
    }

    function deleteAdmin(address _noAdmin) external {
        require(isActive, "Contract disabled");
        require(
            msg.sender == contractOwner,
            "Identity is not the contract owner"
        );
        require(admin[_noAdmin], "Identity is not an admin");
        admin[_noAdmin] = false;
    }

    function isAdmin(address _entity) external view returns (bool) {
        require(isActive, "Contract disabled");
        require(
            msg.sender == contractOwner,
            "Identity is not the contract owner"
        );
        return (admin[_entity]);
    }

    // Write functions

    function createBatch(
        string calldata batchId,
        string calldata lab,
        string calldata description,
        string calldata deliveryDate,
        uint64 units
    ) public contractActive {
        require(
            stock[batchId].units == 0,
            "A batch with this batchId already exists"
        );
        timestamps.push(block.timestamp);
        stock[batchId] = VaccineBatch(
            batchId,
            lab,
            msg.sender,
            description,
            block.timestamp,
            deliveryDate,
            units,
            "ready",
            address(0)
        );
        status[batchId][block.timestamp] = "ready";
        params[batchId][block.timestamp] = ConservationParams("-", "-", "-");
        wallet[msg.sender][batchId] = true;
        emit CreateBatch(
            "Vaccine batch successfully created",
            msg.sender,
            batchId,
            lab,
            block.timestamp
        );
    }

    function deliverBatch(string memory batchId, address to)
        public
        batchExists(batchId)
        contractActive
    {
        require(
            keccak256(bytes(stock[batchId].currentStatus)) ==
                keccak256(bytes("ready")),
            "Batch not ready to ship"
        );
        timestamps.push(block.timestamp);
        status[batchId][block.timestamp] = "shipped";
        params[batchId][block.timestamp] = ConservationParams("-", "-", "-");
        stock[batchId].destination = to;
        stock[batchId].currentStatus = "shipped";
        emit DeliverBatch(
            "Vaccine batch successfully shipped",
            msg.sender,
            batchId,
            to,
            block.timestamp
        );
    }

    function confirmDelivery(string memory batchId)
        public
        batchExists(batchId)
        contractActive
    {
        require(
            keccak256(bytes(stock[batchId].currentStatus)) ==
                keccak256(bytes("shipped")),
            "Batch not shipped"
        );
        require(
            stock[batchId].destination == msg.sender,
            "The address is not the receiver of the batch"
        );
        timestamps.push(block.timestamp);
        status[batchId][block.timestamp] = "delivered";
        params[batchId][block.timestamp] = ConservationParams("-", "-", "-");
        stock[batchId].currentStatus = "delivered";
        wallet[stock[batchId].labAddress][batchId] = false;
        wallet[msg.sender][batchId] = true;
        emit ConfirmDeliver(
            "Vaccine batch successfully delivered",
            batchId,
            msg.sender,
            block.timestamp
        );
    }

    function registerParams(
        string memory batchId,
        string memory temperature,
        string memory humidity,
        string memory luminosity
    ) public batchExists(batchId) contractActive {
        require(
            keccak256(bytes(stock[batchId].currentStatus)) ==
                keccak256(bytes("shipped")),
            "Batch not shipped"
        );
        timestamps.push(block.timestamp);
        params[batchId][block.timestamp] = ConservationParams(
            temperature,
            humidity,
            luminosity
        );
        emit RegisterParams(
            "Params successfully registered for batch",
            batchId,
            temperature,
            humidity,
            luminosity
        );
    }

    // Read functions

    function getBatch(string calldata batchId)
        public
        view
        returns (
            string memory,
            string memory,
            address,
            string memory,
            uint256,
            uint64,
            string memory
        )
    {
        return (
            stock[batchId].batchId,
            stock[batchId].lab,
            stock[batchId].labAddress,
            stock[batchId].description,
            stock[batchId].creationDate,
            stock[batchId].units,
            stock[batchId].currentStatus
        );
    }

    function getCurrentStatus(string calldata batchId)
        public
        view
        batchExists(batchId)
        contractActive
        returns (string memory)
    {
        return (stock[batchId].currentStatus);
    }

    function isOwner(address owner, string memory batchId)
        public
        view
        batchExists(batchId)
        contractActive
        returns (bool)
    {
        if (wallet[owner][batchId]) {
            return true;
        }
        return false;
    }

    // Traceability functions

    // Specific timestamp

    function getParams(string calldata batchId, uint256 timestamp)
        public
        view
        batchExists(batchId)
        contractActive
        returns (
            string memory,
            string memory,
            string memory
        )
    {
        return (
            params[batchId][timestamp].temperature,
            params[batchId][timestamp].humidity,
            params[batchId][timestamp].luminosity
        );
    }

    function getStatus(string calldata batchId, uint256 timestamp)
        public
        view
        batchExists(batchId)
        contractActive
        returns (string memory)
    {
        return (status[batchId][timestamp]);
    }

    // All the values

    function getAllTemp(string calldata batchId)
        public
        view
        batchExists(batchId)
        contractActive
        returns (string[] memory)
    {
        string[] memory temperatures = new string[](timestamps.length);
        uint256 timestampIt;
        for (uint256 i = 0; i < timestamps.length; i++) {
            timestampIt = timestamps[i];
            temperatures[i] = params[batchId][timestampIt].temperature;
        }
        return temperatures;
    }

    function getAllHum(string calldata batchId)
        public
        view
        batchExists(batchId)
        contractActive
        returns (string[] memory)
    {
        string[] memory temperatures = new string[](timestamps.length);
        uint256 timestampIt;
        for (uint256 i = 0; i < timestamps.length; i++) {
            timestampIt = timestamps[i];
            temperatures[i] = params[batchId][timestampIt].humidity;
        }
        return temperatures;
    }

    function getAllLum(string calldata batchId)
        public
        view
        batchExists(batchId)
        contractActive
        returns (string[] memory)
    {
        string[] memory temperatures = new string[](timestamps.length);
        uint256 timestampIt;
        for (uint256 i = 0; i < timestamps.length; i++) {
            timestampIt = timestamps[i];
            temperatures[i] = params[batchId][timestampIt].luminosity;
        }
        return temperatures;
    }

    function getAllStatus(string calldata batchId)
        public
        view
        batchExists(batchId)
        contractActive
        returns (string[] memory)
    {
        string[] memory allStatus = new string[](timestamps.length);
        uint256 timestampIt;
        for (uint256 i = 0; i < timestamps.length; i++) {
            timestampIt = timestamps[i];
            allStatus[i] = status[batchId][timestampIt];
        }
        return allStatus;
    }

    // Panic functions

    function enableContract() external {
        require(!isActive, "Contract already enabled");
        /*require(
            msg.sender == contractOwner,
            "Identity is not the contract owner"
        );*/
        isActive = true;
    }

    function disableContract() external {
        require(isActive, "Contract already disabled");
        /*require(
            msg.sender == contractOwner,
            "Identity is not the contract owner"
        );*/
        isActive = false;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Owner.sol";
import "./Broker.sol";
import "./ExternalAdvisor.sol";
import "./ProspectiveBuyer.sol";
import "./IUser.sol";

contract User {
    /**
     * @dev contains all users address
     */
    address[] public users;

    /**
     * @dev mapping the roles based on the address
     * @dev map[key<address>, value<uint>] => [userAddress, role]
     * @dev role:
     *      1 => ADMIN
     *      2 => OWNER
     *      3 => BROKER
     *      4 => EXTERNAL ADVISOR
     *      5 => PROSPECTIVE BUYER
     */
    mapping(address => uint) public usersRoles;

    /**
     * @dev is used for mapping the deployed contract address based on the given role key
     * @dev map[key<uint>, value<address>] => [role, userContractAddress]
     * @dev mapping:
     *      [2, ownerContract]
     *      [3, brokerContract]
     *      [4, externalAdvisorContract]
     *      [5, prospectiveBuyerContract]
     */
    mapping(uint => address) public usersContracts;

    /**
     * contains the admin address
     */
    address public admin;

    address[] public realEstates;

    /**
     * [owner || broker] => [list<address>]
     */
    mapping(address => address[]) public realEstate;

    modifier onlyUser(address userAddress) {
        bool userOnly = usersRoles[userAddress] == 1 ||
            usersRoles[userAddress] == 2 ||
            usersRoles[userAddress] == 3 ||
            usersRoles[userAddress] == 4 ||
            usersRoles[userAddress] == 5;

        require(userOnly, "only user");
        _;
    }

    constructor() {
        admin = msg.sender;
        usersContracts[2] = address(new Owner(admin));
        usersContracts[3] = address(new Broker(admin));
        usersContracts[4] = address(new ExternalAdvisor(admin));
        usersContracts[5] = address(new ProspectiveBuyer(admin));
    }

    function registerOwnerOrBuyer(uint roleId) public {
        require(roleId == 2 || roleId == 5, "wrong role id");
        register(msg.sender, roleId);
    }

    function registerBroker(address userAddress) public {
        require(msg.sender == admin, "not admin");
        register(userAddress, 3);
    }

    function registerExternalAdvisor(address userAddress) public {
        require(
            msg.sender == admin || usersRoles[msg.sender] == 3,
            "not admin || broker"
        );
        register(userAddress, 4);
    }

    function register(address userAddress, uint roleId) private {
        users.push(userAddress);
        usersRoles[userAddress] = roleId;
        IUser(usersContracts[roleId]).registerUser(userAddress);
    }

    function addRealEstateForOwner(address _realEstate) public {
        require(usersRoles[msg.sender] == 2, "not user contract");
        realEstate[msg.sender].push(_realEstate);
        realEstates.push(_realEstate);
    }

    function addRealEstateForBroker(
        address _realEstate,
        address _broker
    ) public {
        require(msg.sender == admin, "not user contract");
        require(usersRoles[_broker] == 3, "account is not registered");
        realEstate[_broker].push(_realEstate);
    }

    function addRealEstateForExternalAdvisor(
        address _realEstate,
        address _externalAdvisor
    ) public {
        require(usersRoles[msg.sender] == 3, "account is not registered");
        require(usersRoles[_externalAdvisor] == 4, "account is not registered");
        realEstate[_externalAdvisor].push(_realEstate);
    }

    function getRealEstates() public view returns (address[] memory) {
        return realEstates;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IUser.sol";

contract ExternalAdvisor is IUser {
    event externalAdvisorCreation(address indexed externalAdvisor);

    struct ExternalAdvisorUser {
        address brokerAddress;
        string name;
    }

    struct Data {
        bool isFilled;
        ExternalAdvisorUser owner;
    }

    mapping(address => Data) externalAdvisorsData;
    address[] public externalAdvisors;

    address public admin;
    address public userContract;

    modifier onlyAdmin() {
        require(msg.sender == admin, "not admin");
        _;
    }

    modifier onlyUserContract() {
        require(msg.sender == userContract, "not user contract");
        _;
    }

    constructor(address _admin) {
        userContract = msg.sender;
        admin = _admin;
    }

    function registerUser(address _userAddress)
        external
        override
    // onlyUserContract
    {
        externalAdvisorsData[_userAddress].isFilled = true;
        externalAdvisors.push(_userAddress);
        emit externalAdvisorCreation(_userAddress);
    }

    function insertData(string memory name) public {
        externalAdvisorsData[msg.sender].isFilled = true;
        externalAdvisorsData[msg.sender].owner = ExternalAdvisorUser(
            msg.sender,
            name
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IUser.sol";

contract Owner is IUser {
    event ownerCreation(address indexed owner);

    /**
     * @dev describes the properties that owners should have
     */
    struct OwnerData {
        address ownerAddress;
        string name;
    }

    /**
     * @dev contains isFilled field that indicates the existance of the owner data
     */
    struct Data {
        bool isFilled;
        OwnerData owner;
    }

    address[] public propertyOwners;
    mapping(address => Data) public propertyOwnersData;

    /**
     * @dev contains the admin address
     */
    address public admin;
    address public userContract;

    /**
     * @dev contains a list of real estate contracts address
     */
    mapping(address => address[]) public ownerRealEstates;

    modifier onlyAdmin() {
        require(msg.sender == admin, "not admin");
        _;
    }

    modifier onlyUserContract() {
        require(msg.sender == userContract, "not user contract");
        _;
    }

    constructor(address _admin) {
        userContract = msg.sender;
        admin = _admin;
    }

    /**
     * @dev the function that is called from the user contract
     */
    function registerUser(
        address _userAddress
    ) external override onlyUserContract {
        propertyOwners.push(_userAddress);
        propertyOwnersData[_userAddress].isFilled = true;
        emit ownerCreation(_userAddress);
    }

    /**
     * @dev the function that is called from the DApp
     */
    function insertData(string memory name) public {
        propertyOwnersData[msg.sender].isFilled = true;
        propertyOwnersData[msg.sender].owner = OwnerData(msg.sender, name);
    }

    function addOwnerRealEstates(address _owner, address _realEstate) public {
        ownerRealEstates[_owner].push(_realEstate);
    }

    function getOwnerRealEstates(
        address _owner
    ) public view returns (address[] memory) {
        return ownerRealEstates[_owner];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IUser.sol";

contract Broker is IUser {
    event brokerCreation(address indexed broker);

    struct BrokerData {
        string name;
    }
    struct Data {
        bool isFilled;
        BrokerData broker;
    }
    mapping(address => Data) public propertyBrokersData;

    address[] public propertyBrokers;
    address public admin;
    address public userContract;

    address[] public realEstates;
    mapping(address => address[]) public realEstate;

    modifier onlyAdmin() {
        require(msg.sender == admin, "not admin");
        _;
    }

    modifier onlyUserContract() {
        require(msg.sender == userContract, "not user contract");
        _;
    }

    constructor(address _admin) {
        userContract = msg.sender;
        admin = _admin;
    }

    function registerUser(
        address _userAddress // onlyUserContract
    ) external override {
        propertyBrokersData[_userAddress].isFilled = true;
        propertyBrokers.push(_userAddress);
        emit brokerCreation(_userAddress);
    }

    function insertData(string memory name) public {
        propertyBrokersData[msg.sender].isFilled = true;
        propertyBrokersData[msg.sender].broker = BrokerData(name);
    }

    function getPropertyBrokerList() public view returns (address[] memory) {
        return propertyBrokers;
    }

    function addRealEstateForBroker(
        address _realEstate,
        address _broker
    ) public {
        require(msg.sender == admin, "not user contract");
        realEstate[_broker].push(_realEstate);
        realEstates.push(_realEstate);
    }

    function getRealEstates() public view returns (address[] memory) {
        return realEstates;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUser {
    function registerUser(address _userAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IUser.sol";

contract ProspectiveBuyer is IUser {
    /**
     * @dev describes the properties that owners should have
     */
    struct Owner {
        address ownerAddress;
        string name;
    }
    struct Data {
        bool isFilled;
        Owner owner;
    }
    mapping(address => Data) public prospectiveBuyersData;
    address[] public prospectiveBuyers;

    address public userContract;
    address public admin;

    modifier onlyUserContract() {
        require(msg.sender == userContract, "not user contract");
        _;
    }

    constructor(address _admin) {
        userContract = msg.sender;
        admin = _admin;
    }

    function registerUser(address _userAddress)
        external
        override
        onlyUserContract
    {
        prospectiveBuyersData[_userAddress].isFilled = true;
        prospectiveBuyers.push(_userAddress);
    }
}
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./SupplyChainStorage.sol";
import "./Ownable.sol";

contract SupplyChainUser is Ownable {
    event UserUpdate(
        address indexed user,
        string name,
        string email,
        string[] role,
        bool isActive,
        string profileHash
    );
    event UserRoleUpdate(address indexed user, string[] role);

    SupplyChainStorage supplyChainStorage;

    constructor(address _supplyChainAddress) {
        supplyChainStorage = SupplyChainStorage(_supplyChainAddress);
    }

    function updateUser(
        string memory _name,
        string memory _email,
        bool _isActive,
        string memory _profileHash
    ) public returns (bool) {
        require(msg.sender != address(0));

        (, , string[] memory lastRole, , ) = supplyChainStorage.getUser(
            msg.sender
        );

        bool status = supplyChainStorage.setUser(
            msg.sender,
            _name,
            _email,
            lastRole,
            _isActive,
            _profileHash
        );

        emit UserUpdate(
            msg.sender,
            _name,
            _email,
            lastRole,
            _isActive,
            _profileHash
        );
        emit UserRoleUpdate(msg.sender, lastRole);

        return status;
    }

    function updateUserForAdmin(
        address _userAddress,
        string memory _name,
        string memory _email,
        string[] memory _role,
        bool _isActive,
        string memory _profileHash
    ) public onlyOwner returns (bool) {
        require(_userAddress != address(0));

        bool status = supplyChainStorage.setUser(
            _userAddress,
            _name,
            _email,
            _role,
            _isActive,
            _profileHash
        );

        emit UserUpdate(
            _userAddress,
            _name,
            _email,
            _role,
            _isActive,
            _profileHash
        );
        emit UserRoleUpdate(_userAddress, _role);

        return status;
    }

    function getUser(address _userAddress)
        public
        view
        returns (
            string memory name,
            string memory email,
            string[] memory role,
            bool isActive,
            string memory profileHash
        )
    {
        require(_userAddress != address(0));

        (name, email, role, isActive, profileHash) = supplyChainStorage.getUser(
            _userAddress
        );

        return (name, email, role, isActive, profileHash);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract SupplyChainStorageOwnable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previusOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./SupplyChainStorageOwnable.sol";

contract SupplyChainStorage is SupplyChainStorageOwnable {
    constructor() {
        authorizedCaller[msg.sender] = 1;
        emit AuthorizedCaller(msg.sender);
    }

    event AuthorizedCaller(address caller);
    event DeAuthorizedCaller(address caller);

    event UserUpdate(address userAddress);
    event UserRoleUpdate(address userAddress);

    modifier onlyAuthCaller() {
        require(authorizedCaller[msg.sender] == 1);
        _;
    }

    struct User {
        string name;
        string email;
        bool isActive;
        string profileHash;
    }

    mapping(address => User) userDetails;
    mapping(address => string[]) userRole;

    mapping(address => uint8) authorizedCaller;

    function authorizeCaller(address _caller) public onlyOwner returns (bool) {
        authorizedCaller[_caller] = 1;
        emit AuthorizedCaller(_caller);
        return true;
    }

    function deAuthorizeCaller(address _caller)
        public
        onlyOwner
        returns (bool)
    {
        authorizedCaller[_caller] = 0;
        emit DeAuthorizedCaller(_caller);
        return true;
    }

    struct FarmDetails {
        string registrationNo;
        string farmName;
        string latitude;
        string longitude;
        string farmAddress;
    }

    struct Harvest {
        string seedSupplier;
        string typeOfSeed;
        string coffeeFamily;
        string fertilizerUsed;
        string harvestDate;
        string humidityPercentage;
        string batchWeight;
    }

    struct Process {
        string[] addressLatLngProcessor;
        string typeOfDrying;
        string humidityAfterDrying;
        string roastImageHash;
        string[] tempTypeRoast;
        string[] roastMillDates;
        string processorPricePerKilo;
        string processBatchWeight;
    }

    struct Taste {
        string tastingScore;
        string tastingServicePrice;
    }

    struct CoffeeSell {
        string coffeeSellingBatchWeight;
        string beanPricePerKilo;
    }

    mapping(address => FarmDetails) batchFarmDetails;
    mapping(address => Harvest) batchHarvest;
    mapping(address => Process) batchProcess;
    mapping(address => Taste) batchTaste;
    mapping(address => CoffeeSell) batchCoffeSell;
    mapping(address => string) nextAction;

    User userData;
    FarmDetails farmDetailsData;
    Harvest harvestData;
    Process processData;
    Taste tasteData;
    CoffeeSell coffeeSellData;

    function getUserRoles(address _userAddress)
        public
        view
        onlyAuthCaller
        returns (string[] memory)
    {
        return userRole[_userAddress];
    }

    function getNextAction(address _batchNo)
        public
        view
        onlyAuthCaller
        returns (string memory)
    {
        return nextAction[_batchNo];
    }

    function writeNextAction(address _batchNo, string memory action)
        public
        onlyAuthCaller
        returns (bool)
    {
        nextAction[_batchNo] = action;

        return true;
    }

    function setUser(
        address _userAddress,
        string memory _name,
        string memory _email,
        string[] memory _role,
        bool _isActive,
        string memory _profileHash
    ) public onlyAuthCaller returns (bool) {
        userData.name = _name;
        userData.email = _email;
        userData.isActive = _isActive;
        userData.profileHash = _profileHash;

        userDetails[_userAddress] = userData;
        userRole[_userAddress] = _role;

        emit UserUpdate(_userAddress);
        emit UserRoleUpdate(_userAddress);
        return true;
    }

    function getUser(address _userAddress)
        public
        view
        onlyAuthCaller
        returns (
            string memory name,
            string memory email,
            string[] memory role,
            bool isActive,
            string memory profileHash
        )
    {
        User memory tmpData = userDetails[_userAddress];
        return (
            tmpData.name,
            tmpData.email,
            userRole[_userAddress],
            tmpData.isActive,
            tmpData.profileHash
        );
    }

    function setFarmDetails(
        string memory _registrationNo,
        string memory _farmName,
        string memory _latitude,
        string memory _longitude,
        string memory _farmAddress
    ) public onlyAuthCaller returns (address) {
        uint256 tmpData = uint256(
            keccak256(abi.encodePacked(msg.sender, block.timestamp))
        );
        address batchNo = address(uint160(tmpData));

        farmDetailsData.registrationNo = _registrationNo;
        farmDetailsData.farmName = _farmName;
        farmDetailsData.latitude = _latitude;
        farmDetailsData.longitude = _longitude;
        farmDetailsData.farmAddress = _farmAddress;

        batchFarmDetails[batchNo] = farmDetailsData;
        nextAction[batchNo] = "FARMER";
        return batchNo;
    }

    function getFarmDetails(address _batchNo)
        public
        view
        onlyAuthCaller
        returns (
            string memory registrationNo,
            string memory farmName,
            string memory latitude,
            string memory longitude,
            string memory farmAddress
        )
    {
        FarmDetails memory tmpData = batchFarmDetails[_batchNo];

        return (
            tmpData.registrationNo,
            tmpData.farmName,
            tmpData.latitude,
            tmpData.longitude,
            tmpData.farmAddress
        );
    }

    function setHarvestData(
        address batchNo,
        string memory _seedSupplier,
        string memory _typeOfSeed,
        string memory _coffeeFamily,
        string memory _fertilizerUsed,
        string memory _harvestDate,
        string memory _humidityPercentage,
        string memory _batchWeight
    ) public onlyAuthCaller returns (bool) {
        harvestData.seedSupplier = _seedSupplier;
        harvestData.typeOfSeed = _typeOfSeed;
        harvestData.coffeeFamily = _coffeeFamily;
        harvestData.fertilizerUsed = _fertilizerUsed;
        harvestData.harvestDate = _harvestDate;
        harvestData.humidityPercentage = _humidityPercentage;
        harvestData.batchWeight = _batchWeight;

        batchHarvest[batchNo] = harvestData;
        nextAction[batchNo] = "PROCESSOR";
        return true;
    }

    function getHarvestData(address batchNo)
        public
        view
        onlyAuthCaller
        returns (
            string memory seedSupplier,
            string memory typeOfSeed,
            string memory coffeeFamily,
            string memory fertilizerUsed,
            string memory harvestDate,
            string memory humidityPercentage,
            string memory batchWeight
        )
    {
        Harvest memory tmpData = batchHarvest[batchNo];
        return (
            tmpData.seedSupplier,
            tmpData.typeOfSeed,
            tmpData.coffeeFamily,
            tmpData.fertilizerUsed,
            tmpData.harvestDate,
            tmpData.humidityPercentage,
            tmpData.batchWeight
        );
    }

    function setProcessData(
        address batchNo,
        string[] memory _addressLatLngProcessor,
        string memory _typeOfDrying,
        string memory _humidityAfterDrying,
        string memory _roastImageHash,
        string[] memory _tempTypeRoast,
        string[] memory _roastMillDates,
        string memory _processorPricePerKilo,
        string memory _processBatchWeight
    ) public onlyAuthCaller returns (bool) {
        processData.addressLatLngProcessor = _addressLatLngProcessor;
        processData.typeOfDrying = _typeOfDrying;
        processData.humidityAfterDrying = _humidityAfterDrying;
        processData.roastImageHash = _roastImageHash;
        processData.tempTypeRoast = _tempTypeRoast;
        processData.roastMillDates = _roastMillDates;
        processData.processorPricePerKilo = _processorPricePerKilo;
        processData.processBatchWeight = _processBatchWeight;

        batchProcess[batchNo] = processData;

        nextAction[batchNo] = "TASTER";
        return (true);
    }

    function getProcessData(address batchNo)
        public
        view
        onlyAuthCaller
        returns (
            string[] memory addressLatLngProcessor,
            string memory typeOfDrying,
            string memory humidityAfterDrying,
            string memory roastImageHash,
            string[] memory tempTypeRoast,
            string[] memory roastMillDates,
            string memory processorPricePerKilo,
            string memory processBatchWeight
        )
    {
        Process memory tmpData = batchProcess[batchNo];
        return (
            tmpData.addressLatLngProcessor,
            tmpData.typeOfDrying,
            tmpData.humidityAfterDrying,
            tmpData.roastImageHash,
            tmpData.tempTypeRoast,
            tmpData.roastMillDates,
            tmpData.processorPricePerKilo,
            tmpData.processBatchWeight
        );
    }

    function setTasteData(
        address batchNo,
        string memory _tastingScore,
        string memory _tastingServicePrice
    ) public onlyAuthCaller returns (bool) {
        tasteData.tastingScore = _tastingScore;
        tasteData.tastingServicePrice = _tastingServicePrice;

        batchTaste[batchNo] = tasteData;
        nextAction[batchNo] = "SELLER";
        return true;
    }

    function getTasteData(address batchNo)
        public
        view
        onlyAuthCaller
        returns (string memory tastingScore, string memory tastingServicePrice)
    {
        Taste memory tmpData = batchTaste[batchNo];
        return (tmpData.tastingScore, tmpData.tastingServicePrice);
    }

    function setCoffeeSellData(
        address batchNo,
        string memory _coffeeSellingBatchWeight,
        string memory _beanPricePerKilo
    ) public onlyAuthCaller returns (bool) {
        coffeeSellData.coffeeSellingBatchWeight = _coffeeSellingBatchWeight;
        coffeeSellData.beanPricePerKilo = _beanPricePerKilo;

        batchCoffeSell[batchNo] = coffeeSellData;
        nextAction[batchNo] = "WAREHOUSE";
        return true;
    }

    function getCoffeeSellData(address batchNo)
        public
        view
        onlyAuthCaller
        returns (
            string memory coffeeSellingBatchWeight,
            string memory beanPricePerKilo
        )
    {
        CoffeeSell memory tmpData = batchCoffeSell[batchNo];
        return (tmpData.coffeeSellingBatchWeight, tmpData.beanPricePerKilo);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previusOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}
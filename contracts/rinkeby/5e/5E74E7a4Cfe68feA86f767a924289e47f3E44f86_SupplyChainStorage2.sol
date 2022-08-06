//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./SupplyChainStorageOwnable.sol";
import "./SupplyChainStorage.sol";

contract SupplyChainStorage2 is SupplyChainStorageOwnable {
    SupplyChainStorage supplyChainStorage;

    constructor(address _supplyChainStorage) {
        authorizedCaller[msg.sender] = 1;
        emit AuthorizedCaller(msg.sender);
        supplyChainStorage = SupplyChainStorage(_supplyChainStorage);
    }

    event AuthorizedCaller(address caller);
    event DeAuthorizedCaller(address caller);

    modifier onlyAuthCaller() {
        require(authorizedCaller[msg.sender] == 1);
        _;
    }

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

    struct Warehousing {
        string warehouseAddress;
        string[] latLngWarehouse;
        string warehouseArrivalDate;
        string storageTime;
        string storagePricePerKiloPerTime;
    }

    struct ShipToPacker {
        string toPackerTransportType;
        string warehousePickupDate;
        string toPackerShippingPrice;
    }

    struct Pack {
        string packerAddress;
        string[] latLngPacker;
        string packerArrivalDate;
        string packingDate;
        string packingPricePerKilo;
    }

    struct ShipToRetailer {
        string toRetailerTransportType;
        string packerPickupDate;
        string toReatilerShippingPrice;
    }

    struct Retailer {
        string[] warehouseSalepointArrivalDate;
        string warehouseRetailerName;
        string salepointRetailerName;
        string[] addressLatLngWarehouseRetailer;
        string[] addressLatLngSalepointRetailer;
        string toSalepointTransportType;
        string toSalepointShippingPrice;
        string retailerPricePerKilo;
    }

    mapping(address => Warehousing) batchWarehousing;
    mapping(address => ShipToPacker) batchShipToPacker;
    mapping(address => Pack) batchPack;
    mapping(address => ShipToRetailer) batchShipToRetailer;
    mapping(address => Retailer) batchRetailer;

    Warehousing warehousingData;
    ShipToPacker shipPackerData;
    Pack packData;
    ShipToRetailer shipRetailerData;
    Retailer retailerData;

    function setWarehousingData(
        address batchNo,
        string memory _warehouseAddress,
        string[] memory _latLngWarehouse,
        string memory _warehouseArrivalDate,
        string memory _storageTime,
        string memory _storagePricePerKiloPerTime
    ) public onlyAuthCaller returns (bool) {
        warehousingData.warehouseAddress = _warehouseAddress;
        warehousingData.latLngWarehouse = _latLngWarehouse;
        warehousingData.warehouseArrivalDate = _warehouseArrivalDate;
        warehousingData.storageTime = _storageTime;
        warehousingData
            .storagePricePerKiloPerTime = _storagePricePerKiloPerTime;

        batchWarehousing[batchNo] = warehousingData;
        bool status = supplyChainStorage.writeNextAction(
            batchNo,
            "SHIPPER_PACKER"
        );
        return (true && status);
    }

    function getWarehousingData(address batchNo)
        public
        view
        onlyAuthCaller
        returns (
            string memory warehouseAddress,
            string[] memory latLngWarehouse,
            string memory warehouseArrivalDate,
            string memory storageTime,
            string memory storagePricePerKiloPerTime
        )
    {
        Warehousing memory tmpData = batchWarehousing[batchNo];
        return (
            tmpData.warehouseAddress,
            tmpData.latLngWarehouse,
            tmpData.warehouseArrivalDate,
            tmpData.storageTime,
            tmpData.storagePricePerKiloPerTime
        );
    }

    function setShipPackerData(
        address batchNo,
        string memory _toPackerTransportType,
        string memory _warehousePickupDate,
        string memory _toPackerShippingPrice
    ) public onlyAuthCaller returns (bool) {
        shipPackerData.toPackerTransportType = _toPackerTransportType;
        shipPackerData.warehousePickupDate = _warehousePickupDate;
        shipPackerData.toPackerShippingPrice = _toPackerShippingPrice;

        batchShipToPacker[batchNo] = shipPackerData;
        bool status = supplyChainStorage.writeNextAction(batchNo, "PACKER");
        return (true && status);
    }

    function getShipPackerData(address batchNo)
        public
        view
        onlyAuthCaller
        returns (
            string memory toPackerTransportType,
            string memory warehousePickupDate,
            string memory toPackerShippingPrice
        )
    {
        ShipToPacker memory tmpData = batchShipToPacker[batchNo];
        return (
            tmpData.toPackerTransportType,
            tmpData.warehousePickupDate,
            tmpData.toPackerShippingPrice
        );
    }

    function setPackData(
        address batchNo,
        string memory _packerAddress,
        string[] memory _latLngPacker,
        string memory _packerArrivalDate,
        string memory _packingDate,
        string memory _packingPricePerKilo
    ) public onlyAuthCaller returns (bool) {
        packData.packerAddress = _packerAddress;
        packData.latLngPacker = _latLngPacker;
        packData.packerArrivalDate = _packerArrivalDate;
        packData.packingDate = _packingDate;
        packData.packingPricePerKilo = _packingPricePerKilo;

        batchPack[batchNo] = packData;
        bool status = supplyChainStorage.writeNextAction(
            batchNo,
            "SHIPPER_RETAILER"
        );
        return (true && status);
    }

    function getPackData(address batchNo)
        public
        view
        onlyAuthCaller
        returns (
            string memory packerAddress,
            string[] memory latLngPacker,
            string memory packerArrivalDate,
            string memory packingDate,
            string memory packingPricePerKilo
        )
    {
        Pack memory tmpData = batchPack[batchNo];
        return (
            tmpData.packerAddress,
            tmpData.latLngPacker,
            tmpData.packerArrivalDate,
            tmpData.packingDate,
            tmpData.packingPricePerKilo
        );
    }

    function setShipRetailerData(
        address batchNo,
        string memory _toRetailerTransportType,
        string memory _packerPickupDate,
        string memory _toReatilerShippingPrice
    ) public onlyAuthCaller returns (bool) {
        shipRetailerData.toRetailerTransportType = _toRetailerTransportType;
        shipRetailerData.packerPickupDate = _packerPickupDate;
        shipRetailerData.toReatilerShippingPrice = _toReatilerShippingPrice;

        batchShipToRetailer[batchNo] = shipRetailerData;
        bool status = supplyChainStorage.writeNextAction(batchNo, "RETAILER");
        return (true && status);
    }

    function getShipRetailerData(address batchNo)
        public
        view
        onlyAuthCaller
        returns (
            string memory toRetailerTransportType,
            string memory packerPickupDate,
            string memory toReatilerShippingPrice
        )
    {
        ShipToRetailer memory tmpData = batchShipToRetailer[batchNo];
        return (
            tmpData.toRetailerTransportType,
            tmpData.packerPickupDate,
            tmpData.toReatilerShippingPrice
        );
    }

    function setRetailerData(
        address batchNo,
        string[] memory _warehouseSalepointArrivalDate,
        string memory _warehouseRetailerName,
        string memory _salepointRetailerName,
        string[] memory _addressLatLngWarehouseRetailer,
        string[] memory _addressLatLngSalepointRetailer,
        string memory _toSalepointTransportType,
        string memory _toSalepointShippingPrice,
        string memory _retailerPricePerKilo
    ) public onlyAuthCaller returns (bool) {
        retailerData
            .warehouseSalepointArrivalDate = _warehouseSalepointArrivalDate;
        retailerData.warehouseRetailerName = _warehouseRetailerName;
        retailerData.salepointRetailerName = _salepointRetailerName;
        retailerData
            .addressLatLngWarehouseRetailer = _addressLatLngWarehouseRetailer;
        retailerData
            .addressLatLngSalepointRetailer = _addressLatLngSalepointRetailer;
        retailerData.toSalepointTransportType = _toSalepointTransportType;
        retailerData.toSalepointShippingPrice = _toSalepointShippingPrice;
        retailerData.retailerPricePerKilo = _retailerPricePerKilo;

        batchRetailer[batchNo] = retailerData;
        bool status = supplyChainStorage.writeNextAction(batchNo, "DONE");
        return (true && status);
    }

    function getRetailerData(address batchNo)
        public
        view
        onlyAuthCaller
        returns (
            string[] memory warehouseSalepointArrivalDate,
            string memory warehouseRetailerName,
            string memory salepointRetailerName,
            string[] memory addressLatLngWarehouseRetailer,
            string[] memory addressLatLngSalepointRetailer,
            string memory toSalepointTransportType,
            string memory toSalepointShippingPrice,
            string memory retailerPricePerKilo
        )
    {
        Retailer memory tmpData = batchRetailer[batchNo];
        return (
            tmpData.warehouseSalepointArrivalDate,
            tmpData.warehouseRetailerName,
            tmpData.salepointRetailerName,
            tmpData.addressLatLngWarehouseRetailer,
            tmpData.addressLatLngSalepointRetailer,
            tmpData.toSalepointTransportType,
            tmpData.toSalepointShippingPrice,
            tmpData.retailerPricePerKilo
        );
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
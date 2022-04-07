//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./SupplyChainStorageOwnable.sol";

contract SupplyChainStorage is SupplyChainStorageOwnable {
    address public lastAccess;

    constructor() {
        authorizedCaller[msg.sender] = 1;
        emit AuthorizedCaller(msg.sender);
    }

    event AuthorizedCaller(address caller);
    event DeAuthorizedCaller(address caller);

    event UserUpdate(address userAddress);
    event UserRoleUpdate(address userAddress);

    modifier onlyAuthCaller() {
        lastAccess = msg.sender;
        require(authorizedCaller[msg.sender] == 1);
        _;
    }

    struct User {
        string name;
        string contactNo;
        bool isActive;
        string profileHash;
    }

    mapping(address => User) userDetails;
    mapping(address => string) userRole;

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
        string coffeeFamily;
        string typeOfSeed;
        string fertilizerUsed;
        string harvestDate;
    }

    struct Process {
        string procAddress;
        string typeOfDrying;
        string roastImageHash;
        string roastTemp;
        string typeOfRoast;
        string roastDate;
        string millDate;
        uint256 processorPrice;
    }

    struct Grain {
        uint256 tasteScore;
        uint256 grainPrice;
    }

    struct Agglomerate {
        string agglomAddress;
        string agglomDate;
        uint256 storagePrice;
    }

    struct ShipToPacker {
        string transportTypeP;
        string pickupDateP;
        uint256 shipPriceP;
    }

    struct Pack {
        string packAddress;
        string arrivalDateP;
        string packDate;
        uint256 packPrice;
    }

    struct ShipToRetailer {
        string transportTypeR;
        string pickupDateR;
        uint256 shipPriceR;
    }

    struct Retailer {
        string arrivalDateW;
        string arrivalDateSP;
        string warehouseName;
        string warehouseAddress;
        string salePointAddress;
        uint256 shipPriceSP;
        uint256 productPrice;
    }

    mapping(address => FarmDetails) batchFarmDetails;
    mapping(address => Harvest) batchHarvest;
    mapping(address => Process) batchProcess;
    mapping(address => Grain) batchGrain;
    mapping(address => Agglomerate) batchAgglomerate;
    mapping(address => ShipToPacker) batchShipToPacker;
    mapping(address => Pack) batchPack;
    mapping(address => ShipToRetailer) batchShipToRetailer;
    mapping(address => Retailer) batchRetailer;
    mapping(address => string) nextAction;

    User userData;
    FarmDetails farmDetailsData;
    Harvest harvestData;
    Process processData;
    Grain grainData;
    Agglomerate agglomData;
    ShipToPacker shipPackerData;
    Pack packData;
    ShipToRetailer shipRetailerData;
    Retailer retailerData;

    function getUserRole(address _userAddress)
        public
        onlyAuthCaller
        returns (string memory)
    {
        return userRole[_userAddress];
    }

    function getNextAction(address _batchNo)
        public
        onlyAuthCaller
        returns (string memory)
    {
        return nextAction[_batchNo];
    }

    function setUser(
        address _userAddress,
        string memory _name,
        string memory _contactNo,
        string memory _role,
        bool _isActive,
        string memory _profileHash
    ) public onlyAuthCaller returns (bool) {
        userData.name = _name;
        userData.contactNo = _contactNo;
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
        onlyAuthCaller
        returns (
            string memory name,
            string memory contactNo,
            string memory role,
            bool isActive,
            string memory profileHash
        )
    {
        User memory tmpData = userDetails[_userAddress];
        return (
            tmpData.name,
            tmpData.contactNo,
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
        string memory _coffeeFamily,
        string memory _typeOfSeed,
        string memory _fertilizerUsed,
        string memory _harvestDate
    ) public onlyAuthCaller returns (bool) {
        harvestData.coffeeFamily = _coffeeFamily;
        harvestData.typeOfSeed = _typeOfSeed;
        harvestData.fertilizerUsed = _fertilizerUsed;
        harvestData.harvestDate = _harvestDate;

        batchHarvest[batchNo] = harvestData;
        nextAction[batchNo] = "PROCESSOR";
        return true;
    }

    function getHarvestData(address batchNo)
        public
        onlyAuthCaller
        returns (
            string memory coffeeFamily,
            string memory typeOfSeed,
            string memory fertilizerUsed,
            string memory harvestDate
        )
    {
        Harvest memory tmpData = batchHarvest[batchNo];
        return (
            tmpData.coffeeFamily,
            tmpData.typeOfSeed,
            tmpData.fertilizerUsed,
            tmpData.harvestDate
        );
    }

    function setProcessData(
        address batchNo,
        string memory _procAddress,
        string memory _typeOfDrying,
        string memory _roastImageHash,
        string memory _roastTemp,
        string memory _typeOfRoast,
        string memory _roastDate,
        string memory _millDate,
        uint256 _processorPrice
    ) public onlyAuthCaller returns (bool) {
        processData.procAddress = _procAddress;
        processData.typeOfDrying = _typeOfDrying;
        processData.roastImageHash = _roastImageHash;
        processData.roastTemp = _roastTemp;
        processData.typeOfRoast = _typeOfRoast;
        processData.roastDate = _roastDate;
        processData.millDate = _millDate;
        processData.processorPrice = _processorPrice;

        batchProcess[batchNo] = processData;
        nextAction[batchNo] = "GRAIN_INSPECTOR";
        return true;
    }

    function getProcessData(address batchNo)
        public
        onlyAuthCaller
        returns (
            string memory procAddress,
            string memory typeOfDrying,
            string memory roastImageHash,
            string memory roastTemp,
            string memory typeOfRoast,
            string memory roastDate,
            string memory millDate,
            uint256 processorPrice
        )
    {
        Process memory tmpData = batchProcess[batchNo];
        return (
            tmpData.procAddress,
            tmpData.typeOfDrying,
            tmpData.roastImageHash,
            tmpData.roastTemp,
            tmpData.typeOfRoast,
            tmpData.roastDate,
            tmpData.millDate,
            tmpData.processorPrice
        );
    }

    function setGrainData(
        address batchNo,
        uint256 _tasteScore,
        uint256 _grainPrice
    ) public onlyAuthCaller returns (bool) {
        grainData.tasteScore = _tasteScore;
        grainData.grainPrice = _grainPrice;

        batchGrain[batchNo] = grainData;
        nextAction[batchNo] = "AGGLOMERATOR";
        return true;
    }

    function getGrainData(address batchNo)
        public
        onlyAuthCaller
        returns (uint256 tasteScore, uint256 grainPrice)
    {
        Grain memory tmpData = batchGrain[batchNo];
        return (tmpData.tasteScore, tmpData.grainPrice);
    }

    function setAgglomData(
        address batchNo,
        string memory _agglomAddress,
        string memory _agglomDate,
        uint256 _storagePrice
    ) public onlyAuthCaller returns (bool) {
        agglomData.agglomAddress = _agglomAddress;
        agglomData.agglomDate = _agglomDate;
        agglomData.storagePrice = _storagePrice;

        batchAgglomerate[batchNo] = agglomData;
        nextAction[batchNo] = "SHIPPER_PACKER";
        return true;
    }

    function getAgglomData(address batchNo)
        public
        onlyAuthCaller
        returns (
            string memory agglomAddress,
            string memory agglomDate,
            uint256 storagePrice
        )
    {
        Agglomerate memory tmpData = batchAgglomerate[batchNo];
        return (
            tmpData.agglomAddress,
            tmpData.agglomDate,
            tmpData.storagePrice
        );
    }

    function setShipPackerData(
        address batchNo,
        string memory _transportTypeP,
        string memory _pickupDateP,
        uint256 _shipPriceP
    ) public onlyAuthCaller returns (bool) {
        shipPackerData.transportTypeP = _transportTypeP;
        shipPackerData.pickupDateP = _pickupDateP;
        shipPackerData.shipPriceP = _shipPriceP;

        batchShipToPacker[batchNo] = shipPackerData;
        nextAction[batchNo] = "PACKER";
        return true;
    }

    function getShipPackerData(address batchNo)
        public
        onlyAuthCaller
        returns (
            string memory transportTypeP,
            string memory pickupDateP,
            uint256 shipPriceP
        )
    {
        ShipToPacker memory tmpData = batchShipToPacker[batchNo];
        return (
            tmpData.transportTypeP,
            tmpData.pickupDateP,
            tmpData.shipPriceP
        );
    }

    function setPackData(
        address batchNo,
        string memory _packAddress,
        string memory _arrivalDateP,
        string memory _packDate,
        uint256 _packPrice
    ) public onlyAuthCaller returns (bool) {
        packData.packAddress = _packAddress;
        packData.arrivalDateP = _arrivalDateP;
        packData.packDate = _packDate;
        packData.packPrice = _packPrice;

        batchPack[batchNo] = packData;
        nextAction[batchNo] = "SHIPPER_RETAILER";
        return true;
    }

    function getPackData(address batchNo)
        public
        onlyAuthCaller
        returns (
            string memory packAddress,
            string memory arrivalDateP,
            string memory packDate,
            uint256 packPrice
        )
    {
        Pack memory tmpData = batchPack[batchNo];
        return (
            tmpData.packAddress,
            tmpData.arrivalDateP,
            tmpData.packDate,
            tmpData.packPrice
        );
    }

    function setShipRetailerData(
        address batchNo,
        string memory _transportTypeR,
        string memory _pickupDateR,
        uint256 _shipPriceR
    ) public onlyAuthCaller returns (bool) {
        shipRetailerData.transportTypeR = _transportTypeR;
        shipRetailerData.pickupDateR = _pickupDateR;
        shipRetailerData.shipPriceR = _shipPriceR;

        batchShipToRetailer[batchNo] = shipRetailerData;
        nextAction[batchNo] = "RETAILER";
        return true;
    }

    function getShipRetailerData(address batchNo)
        public
        onlyAuthCaller
        returns (
            string memory transportTypeR,
            string memory pickupDateR,
            uint256 shipPriceR
        )
    {
        ShipToRetailer memory tmpData = batchShipToRetailer[batchNo];
        return (
            tmpData.transportTypeR,
            tmpData.pickupDateR,
            tmpData.shipPriceR
        );
    }

    function setRetailerData(
        address batchNo,
        string memory _arrivalDateW,
        string memory _arrivalDateSP,
        string memory _warehouseName,
        string memory _warehouseAddress,
        string memory _salePointAddress,
        uint256 _shipPriceSP,
        uint256 _productPrice
    ) public onlyAuthCaller returns (bool) {
        retailerData.arrivalDateW = _arrivalDateW;
        retailerData.arrivalDateSP = _arrivalDateSP;
        retailerData.warehouseName = _warehouseName;
        retailerData.warehouseAddress = _warehouseAddress;
        retailerData.salePointAddress = _salePointAddress;
        retailerData.shipPriceSP = _shipPriceSP;
        retailerData.productPrice = _productPrice;

        batchRetailer[batchNo] = retailerData;
        nextAction[batchNo] = "DONE";
        return true;
    }

    function getRetailerData(address batchNo)
        public
        onlyAuthCaller
        returns (
            string memory arrivalDateW,
            string memory arrivalDateSP,
            string memory warehouseName,
            string memory warehouseAddress,
            string memory salePointAddress,
            uint256 shipPriceSP,
            uint256 productPrice
        )
    {
        Retailer memory tmpData = batchRetailer[batchNo];
        return (
            tmpData.arrivalDateW,
            tmpData.arrivalDateSP,
            tmpData.warehouseName,
            tmpData.warehouseAddress,
            tmpData.salePointAddress,
            tmpData.shipPriceSP,
            tmpData.productPrice
        );
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

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
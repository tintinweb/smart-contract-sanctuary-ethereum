//SPDX-License-Identifier: MIT
pragma solidity >=0.6.6 <0.9.0;

import "Ownable.sol";

contract SupplyChain is Ownable {
    uint256 productCode; //Universal product code

    uint256 stockUnit;

    struct User {
        string name;
        string contact;
        bool isActive;
        string profileHash;
    }

    mapping(address => User) userDetails;
    mapping(address => string) userRole;

    enum State {
        ProduceByFarmer, // 0
        ReceivedByDistributor, // 1
        DeliverByDistributor, // 2
        PackageByProcessor, // 3
        PurchasedByRetailer // 4
    }

    State constant defaultState = State.ProduceByFarmer;

    /*Define event */
    event ProduceByFarmer(uint256 productCode); //1
    //event ForSaleByFarmer(uint256 productCode); //2
    //event PurchasedByDistributor(uint256 productCode); //3
    event ReceivedByDistributor(uint256 productCode); //4
    event DeliverByDistributor(uint256 productCode);
    //event ProcessedByDistributor(uint256 productCode); //5
    event PackagedByProcessor(uint256 productCode); //6
    event PurchasedByRetailer(uint256 productCode); //7

    /*Modifier verify the callers */
    modifier verifyCaller(address _address) {
        require(msg.sender == _address);
        _;
    }

    /*State Modifier */
    modifier producedByFarmer(uint256 _productCode) {
        require(items[_productCode].itemState == State.ProduceByFarmer);
        _;
    }

    modifier receivedByDistributor(uint256 _productCode) {
        require(items[_productCode].itemState == State.ReceivedByDistributor);
        _;
    }

    modifier deliverByDistributor(uint256 _productCode) {
        require(items[_productCode].itemState == State.DeliverByDistributor);
        _;
    }

    modifier packagedByProcessor(uint256 _productCode) {
        require(items[_productCode].itemState == State.PackageByProcessor);
        _;
    }

    modifier purchasedByRetailer(uint256 _productCode) {
        require(items[_productCode].itemState == State.PurchasedByRetailer);
        _;
    }

    struct Item {
        uint256 productID;
        uint256 stockUnit;
        address ownerID;
        uint256 productCode;
        string typeOfseed;
        string fertilizerUsed;
        string cropVariety;
        string temperatureUsed;
        string humidity;
        State itemState;
    }

    //map the product code to the items
    mapping(uint256 => Item) items;
    /*User roles
        Farmer
        Distributor
        Processor
        Retailer
    */

    struct Farmer {
        string farmAddress;
        string farmerName;
    }

    struct Distributor {
        uint256 import_quantity;
        uint256 export_quantity;
        uint256 arrivalDateTime;
        uint256 departureDateTime;
        string import_quality;
        string export_quality;
    }

    struct LogProcessor {
        uint256 quantity;
        uint256 packageDateTime;
        string processorName;
        string processorAddress;
    }

    struct Retailer {
        uint256 arrivalDateTime;
        string productQuality;
        string temperature;
    }

    mapping(address => Farmer) batchFarmer;
    mapping(uint256 => Distributor) batchDistributor;
    mapping(uint256 => LogProcessor) batchProcessor;
    mapping(uint256 => Retailer) batchRetailer;

    /* Struct pointer */
    User userDetail;
    Distributor distributeData;
    LogProcessor processData;
    Retailer retailData;

    function getUserRole(address _userAddress)
        public
        view
        returns (string memory)
    {
        return userRole[_userAddress];
    }

    function setUser(
        address _userAddress,
        string memory _name,
        string memory _contact,
        string memory _role,
        string memory _profileHash
    ) public returns (bool) {
        userDetail.name = _name;
        userDetail.contact = _contact;
        userDetail.profileHash = _profileHash;

        userDetails[_userAddress] = userDetail;
        userRole[_userAddress] = _role;

        return true;
    }

    function getUser(address _userAddress)
        public
        view
        returns (
            string memory name,
            string memory contact,
            string memory role,
            string memory profileHash
        )
    {
        User memory userData = userDetails[_userAddress];
        return (
            userData.name,
            userData.contact,
            userRole[_userAddress],
            userData.profileHash
        );
    }

    /*1st Stage: Farmer create product*/
    function produceItemByFarmer(
        uint256 _productCode,
        string memory _typeOfSeed,
        string memory _fertilizerUsed,
        string memory _cropVariety,
        string memory _temperatureUsed,
        string memory _humidity
    ) public {
        Item memory newProduce;
        newProduce.stockUnit = stockUnit;
        newProduce.productCode = _productCode;
        newProduce.typeOfseed = _typeOfSeed;
        newProduce.fertilizerUsed = _fertilizerUsed;
        newProduce.cropVariety = _cropVariety;
        newProduce.temperatureUsed = _temperatureUsed;
        newProduce.humidity = _humidity;
        newProduce.itemState = defaultState;
        newProduce.productID = _productCode + stockUnit;
        items[_productCode] = newProduce;

        //Increment stockUnit
        stockUnit = stockUnit + 1;
        emit ProduceByFarmer(_productCode);
    }

    function getProducedItems(uint256 product_code)
        public
        view
        returns (
            uint256 productID,
            string memory typeOfseed,
            string memory cropVariety,
            string memory temperatureUsed,
            string memory humidity
        )
    {
        Item memory itemData = items[product_code];
        return (
            itemData.productID,
            itemData.typeOfseed,
            itemData.cropVariety,
            itemData.temperatureUsed,
            itemData.humidity
        );
    }

    /*2nd Stage: Distributor import item */
    //    verifyCaller(items[product_code].ownerID)
    function setImportDistribute(
        uint256 product_code,
        uint256 _import_quantity,
        uint256 _arrivalDateTime,
        string memory _import_quality
    ) public producedByFarmer(product_code) {
        distributeData.import_quantity = _import_quantity;
        distributeData.arrivalDateTime = _arrivalDateTime;
        distributeData.import_quality = _import_quality;
        batchDistributor[product_code] = distributeData;
        items[product_code].itemState = State.ReceivedByDistributor;
        emit ReceivedByDistributor(product_code);
    }

    function getImportDistribute(uint256 product_code)
        public
        view
        returns (
            uint256 import_quantity,
            uint256 arrivalDateTime,
            string memory import_quality
        )
    {
        Distributor memory importData = batchDistributor[product_code];
        return (
            importData.import_quantity,
            importData.arrivalDateTime,
            importData.import_quality
        );
    }

    /*3rd Stage: Distributor export item */
    function setExportDistribute(
        uint256 product_code,
        uint256 _export_quantity,
        uint256 _departureDateTime,
        string memory _export_quality
    ) public receivedByDistributor(product_code) {
        distributeData.export_quantity = _export_quantity;
        distributeData.departureDateTime = _departureDateTime;
        distributeData.export_quality = _export_quality;
        batchDistributor[product_code] = distributeData;
        items[product_code].itemState = State.DeliverByDistributor;
        emit DeliverByDistributor(product_code);
    }

    function getExportDistribute(uint256 product_code)
        public
        view
        returns (
            uint256 export_quantity,
            uint256 departureDateTime,
            string memory export_quality
        )
    {
        Distributor memory exportData = batchDistributor[product_code];
        return (
            exportData.export_quantity,
            exportData.departureDateTime,
            exportData.export_quality
        );
    }

    /*4th Stage: Logistic company process item */
    function setProcessData(
        uint256 product_code,
        uint256 _quantity,
        uint256 _packageDateTime,
        string memory _processorName,
        string memory _processorAddress
    )
        public
        deliverByDistributor(product_code)
        verifyCaller(items[product_code].ownerID)
    {
        processData.quantity = _quantity;
        processData.packageDateTime = _packageDateTime;
        processData.processorName = _processorName;
        processData.processorAddress = _processorAddress;
        batchProcessor[product_code] = processData;
        items[product_code].itemState = State.PackageByProcessor;
        emit PackagedByProcessor(product_code);
    }

    function getProcessData(uint256 product_code)
        public
        view
        returns (
            uint256 quantity,
            uint256 packageDateTime,
            string memory processorName,
            string memory processorAddress
        )
    {
        LogProcessor memory process_data = batchProcessor[product_code];
        return (
            process_data.quantity,
            process_data.packageDateTime,
            process_data.processorName,
            process_data.processorAddress
        );
    }

    /*5th Stage: Item send to Retailers */
    function setRetailedData(
        uint256 product_code,
        uint256 _arrivalDateTime,
        string memory _productQuality,
        string memory _temperature
    )
        public
        packagedByProcessor(product_code)
        verifyCaller(items[product_code].ownerID)
    {
        retailData.arrivalDateTime = _arrivalDateTime;
        retailData.productQuality = _productQuality;
        retailData.temperature = _temperature;
        batchRetailer[product_code] = retailData;
        items[product_code].itemState = State.PurchasedByRetailer;
        emit PurchasedByRetailer(product_code);
    }

    function getRetailedData(uint256 product_code)
        public
        view
        returns (
            uint256 arrivalDateTime,
            string memory productQuality,
            string memory temperature
        )
    {
        Retailer memory retail_data = batchRetailer[product_code];
        return (
            retail_data.arrivalDateTime,
            retail_data.productQuality,
            retail_data.temperature
        );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.6 <0.9.0;

contract Ownable {
    address private owner;

    //Event
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    //Return address of owner
    function isOwner() public view virtual returns (address) {
        return owner;
    }

    //Check the calling address
    function checkOwner() internal view virtual {
        require(msg.sender == isOwner(), "Caller is not the owner");
    }

    //transfer control of contract to new onwner
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    //renounce ownership
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}
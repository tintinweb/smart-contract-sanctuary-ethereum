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
        ForSaleByFarmer, // 1
        PurchasedByDistributor, // 2
        ReceivedByDistributor, // 3
        PackageByDistributor, // 4
        ForSaleByDistributor, // 5
        PurchasedByRetailer // 6
    }

    State constant defaultState = State.ProduceByFarmer;

    /*Define event */
    event ProduceByFarmer(uint256 productCode); //1
    //event ForSaleByFarmer(uint256 productCode); //2
    event PurchasedByDistributor(uint256 productCode); //3
    event ReceivedByDistributor(uint256 productCode); //4
    event ProcessedByDistributor(uint256 productCode); //5
    event PackagedByDistributor(uint256 productCode); //6
    event PurchasedByRetailer(uint256 productCode); //7

    struct Item {
        uint256 productID;
        uint256 stockUnit;
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
    mapping(address => LogProcessor) batchProcessor;
    mapping(address => Retailer) batchRetailer;

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
    function setImportDistribute(
        uint256 product_code,
        uint256 _import_quantity,
        uint256 _arrivalDateTime,
        string memory _import_quality
    ) public {
        //Distributor memory distributeData;
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
/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// File: Amira Code v3/Optimized Amira Code v2 (2)/Optimized Amira Code v2/Genraters.sol


pragma solidity >=0.4.25 <0.9.0;

contract GenratesAndConversion {
    function random(uint256 _count) public view returns (bytes32) {
        return (
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    // block.prevrandao,
                    msg.sender,
                    _count
                )
            )
        );
    }

    function toBytes(address a) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(a));
    }

    function genrateUniqueIDByProductName(string memory _materialname)
        external
        pure
        returns (bytes32)
    {
        bytes32 hash = keccak256(abi.encodePacked(_materialname));
        return hash;
    }
}

// File: Amira Code v3/Optimized Amira Code v2 (2)/Optimized Amira Code v2/Library.sol


pragma solidity >=0.4.25 <0.9.0;

library Types {
   
   enum StakeHolder {      //currently we have only 2 stakeholder so, that's why I'm using  
        Producer, //0 for producer.
        ManuFacturer, // 1 for manfacturer at the registeration time.
        distributors, // 2
        retailers, // 3
        supplier,//4
        consumer
    }
    
    enum State {
        PRODUCED,
        PROCESSED,
        ready_to_ship,
        pre_bookable, 
        PICKUP,  
        SHIPMENT_RELEASED, 
        RECEIVED_SHIPMENT,
        DELIVERED, 
        READY_FOR_SALE,
        SOLD
    }

        //stakeholder details
    struct Stakeholder {
        StakeHolder role;
        address id_;
        string name;
        string email;
        uint256 MobNo;
        bool IsRegistered;
        string country;
        string city;
        // address distributorID;
        // address retailerID;
        }

    //Product => RawMaterial
    struct Item {
        uint256 ArrayIndex; //flag for checking the availablity
        bytes32 PId; // => now we created an auto genrated uid for each product using product name!
        string MaterialName;
        uint256 AvailableDate;
        uint256 Quantity;
        uint256 ExpiryDate;
        uint256 Price;
        bool IsAdded; //flag for checking the availablity
        State itemState;
        uint256 prebookCount;
    }

    struct manfItem { 
        uint256 ArrIndex;        
        string name;
        bytes32 PId;
        string description;
        uint256 expDateEpoch;
        string barcodeId;
        uint256 quantity;
        uint256 price;
        uint256 weights;
        uint256 manDateEpoch;       //available date
        uint256 prebookCount;
        State itemState;
    }

    struct UserHistory {
        address id_;
        manfItem Product_;
        uint256 orderTime_;  
    }

    struct productAvailableManuf {
        address id;
        string  productName;
        bytes32 productID;
        uint256 quantity;
        uint256 price;
        uint256 availableDate;
        uint256 weights;
        uint256 expDateEpoch;
    }

    struct SupplierWithMaterialID  {
        address id_; // account Id of the user
        bytes32 itemId_;// Added, Purchased date in epoch in UTC timezone
        uint256 supplyprice_;
    }

    struct PurchaseOrderHistoryM {
        address manufacturerid;
        address supplierId;
        address producerId;
        Item rawMaterial;
        uint256 orderTime;  
    }

    struct PurchaseOrderHistoryD {
        address distributorId;
        address manufacturerid;
        address supplierId;
        manfItem product;
        uint256 orderTime;  
    }

    
    struct PurchaseOrderHistoryR {
        address retailerId;
        address distributorId;
        address supplierId;
        manfItem product;
        uint256 orderTime;  
    }
       
    struct MaterialHistory {
        PurchaseOrderHistoryM manufacturer;    
    }            

    struct ProductHistory   {    
        PurchaseOrderHistoryD distributor;
    }

    struct ProductHistoryRetail {    
        PurchaseOrderHistoryR retailer;
    }

}
// File: Amira Code v3/Optimized Amira Code v2 (2)/Optimized Amira Code v2/Register.sol


pragma solidity ^0.8.15;



contract StakeHolderRegistration {
    GenratesAndConversion genr;

    constructor(GenratesAndConversion _genr) {
        genr = _genr;
        emit AuthorizedCaller(msg.sender);
    }

    Types.Stakeholder[] internal producerList;
    Types.Stakeholder[] internal manufacturerList;
    Types.Stakeholder[] internal distributorsList;
    Types.Stakeholder[] internal retailersList;
    Types.Stakeholder[] internal supplierList;
    Types.Stakeholder[] internal consumerList;

    mapping(address => bytes32[3]) stakeholderspharse; //internal
    mapping(address => Types.Stakeholder) stakeholders;
    mapping(string => Types.Stakeholder[]) internal servesCountry;
    mapping(string => Types.Stakeholder[]) internal distributoresServesCountry;
    mapping(string => Types.Stakeholder[]) internal supplierServesCountry;
    mapping(string => Types.Stakeholder[]) internal retailersServesCity;

    mapping(address => Types.Stakeholder[])
        internal distributerLinkedWithmanufacturer;
    mapping(address => Types.Stakeholder[])
        internal retailersLinkedWithdistributer;

    event AuthorizedCaller(address caller);
    event StakeHolderRegisterd(
        Types.StakeHolder role,
        address id_,
        string name,
        string email,
        uint256 MobNo,
        bool IsRegistered,
        bytes32[3],
        string country,
        string city
    );

    //before adding raw materials(products) producer needs to be register yourself first then only he/she can createhis Invenotry.
    // always registerd with unique ID if alraedy registered.
    //all the stakeholders can Register Via This.
    function Register(
        Types.StakeHolder _role,
        string memory _name,
        string memory _email,
        uint256 _mobNo,
        string memory _country,
        string memory _city
    ) public returns (string memory) {
        // Producer And ManuFacturer Both Have Different Adress Must!
        require(msg.sender != address(0));
        require(
            !stakeholders[msg.sender].IsRegistered == true,
            "stakeholder alraedy registered with a role!"
        );

        Types.Stakeholder memory sk_ = Types.Stakeholder({
            role: _role,
            id_: msg.sender,
            name: _name,
            email: _email,
            MobNo: _mobNo,
            IsRegistered: true,
            country: _country,
            city: _city
        });
        add(sk_);

        bytes32 g1 = genr.random(1);
        bytes32 g2 = genr.random(2);
        bytes32 g3 = genr.random(3);
        stakeholderspharse[msg.sender] = [g1, g2, g3];

        //if stake holder is producer then only can add Producer list
        if (Types.StakeHolder.Producer == _role) {
            producerList.push(sk_);
        }
        //if stake holder is producer then only can add Manufacturer list
        else if (Types.StakeHolder.ManuFacturer == _role) {
            manufacturerList.push(sk_);
            servesCountry[_country].push(sk_);
        }
        //if stake holder is producer then only can add Distributors list
        else if (Types.StakeHolder.distributors == _role) {
            distributorsList.push(sk_);
            distributoresServesCountry[_country].push(sk_);
        }
        //if stake holder is producer then only can add Retailers list
        else if (Types.StakeHolder.retailers == _role) {
            retailersList.push(sk_);
            retailersServesCity[_city].push(sk_);
        } 
        
        else if (Types.StakeHolder.supplier == _role) {
            supplierList.push(sk_);
            supplierServesCountry[_country].push(sk_);
        }
        else if(Types.StakeHolder.supplier == _role){
            consumerList.push(sk_);
        }

        emit StakeHolderRegisterd(
            _role,
            msg.sender,
            _name,
            _email,
            _mobNo,
            true,
            stakeholderspharse[msg.sender],
            _country,
            _city
        );

        return "successfully registered!";
    }

    //Login StakeHolders
    function login(
        address id,
        bytes32 pharse,
        Types.StakeHolder _role
    ) public view returns (bool) {
        if (stakeholders[id].role == _role) {
            if (
                stakeholderspharse[id][0] == pharse ||
                stakeholderspharse[id][1] == pharse ||
                stakeholderspharse[id][0] == pharse
            ) {
                return true;
            }
        }
        return false;
    }

    function userRegisterUnderOtherStakeHolder(
        //(if user registered under other stakeholders like under manufacturer registered distributors and retailers same for others.)
        Types.StakeHolder _role,
        address _userref,
        string memory _name,
        string memory _email,
        uint256 _mobNo,
        string memory _country,
        string memory _city
    ) public returns (string memory) {
        require(msg.sender != address(0));

        require(
            !stakeholders[msg.sender].IsRegistered == true, //not working here
            "stakeholder alraedy registered with a role!"
        );

        require(
            (Types.StakeHolder.distributors == _role ||
                Types.StakeHolder.retailers == _role),
            "Under Manufacturer Can only Select Distributors and Retailers Role!"
        );

        require(
            (stakeholders[_userref].role == Types.StakeHolder.ManuFacturer ||
                stakeholders[_userref].role == Types.StakeHolder.distributors),
            "only under Manufacturer and Distributors you can register yourself!"
        );

        bytes32 g1 = genr.random(1);
        bytes32 g2 = genr.random(2);
        bytes32 g3 = genr.random(3);
        stakeholderspharse[msg.sender] = [g1, g2, g3];

        Types.Stakeholder memory sk_ = Types.Stakeholder({
            role: _role,
            id_: msg.sender,
            name: _name,
            email: _email,
            MobNo: _mobNo,
            IsRegistered: true,
            country: _country,
            city: _city
        });
        add(sk_);
        if (
            Types.StakeHolder.ManuFacturer == stakeholders[_userref].role ||
            Types.StakeHolder.distributors == _role
        ) {
            distributorsList.push(sk_);
            distributoresServesCountry[_country].push(sk_);
            distributerLinkedWithmanufacturer[_userref].push(sk_);
        }
        //if stake holder is producer then only can add Retailers list
        else if (
            Types.StakeHolder.distributors == stakeholders[_userref].role ||
            Types.StakeHolder.retailers == _role
        ) {
            retailersList.push(sk_);
            retailersServesCity[_city].push(sk_);
            retailersLinkedWithdistributer[_userref].push(sk_);
        }

        return "successfully registered!";
    }

    function getStakeHolderDetails(address id_)
        external
        view
        returns (Types.Stakeholder memory)
    {
        require(id_ != address(0));
        require(stakeholders[id_].id_ != address(0));
        return stakeholders[id_];
    }

    //used at producer list
    function getProducerList()
        public
        view
        returns (Types.Stakeholder[] memory)
    {
        return producerList;
    }

    //list of manufacturer
    function getManuFacturerList()
        public
        view
        returns (Types.Stakeholder[] memory)
    {
        return manufacturerList;
    }

    //list of distributors
    function getDistributorsList()
        public
        view
        returns (Types.Stakeholder[] memory)
    {
        return distributorsList;
    }

    //list of retailers
    function getRetailersList()
        public
        view
        returns (Types.Stakeholder[] memory)
    {
        return retailersList;
    }

    //list of supplier
    function getSupplierList()
        public
        view
        returns (Types.Stakeholder[] memory)
    {
        return supplierList;
    }

     

    //list of distributersLinkedWithManufacturers
    function getStakeHolderListLinkedManufacturer(address _manufAdd)
        public
        view
        returns (Types.Stakeholder[] memory)
    {
        return distributerLinkedWithmanufacturer[_manufAdd];
    }

    //list of stakeholder linked with other distributer
    function getStakeHolderListLinkedWithDistributer(address _distAdd)
        public
        view
        returns (Types.Stakeholder[] memory)
    {
        return retailersLinkedWithdistributer[_distAdd];
    }

    //list of manufacturer list via countryname
    function getDistViaCountryServe(string memory _countryName)
        public
        view
        returns (Types.Stakeholder[] memory)
    {
        return distributoresServesCountry[_countryName];
    }

    //list of manufacturer list via countryname
    function getManufViaCountryServe(string memory _countryName)
        public
        view
        returns (Types.Stakeholder[] memory)
    {
        return servesCountry[_countryName];
    }

    //list of suppliers list via countryname
    function getSupplierViaCountryServe(string memory _countryName)
        public
        view
        returns (Types.Stakeholder[] memory)
    {
        return supplierServesCountry[_countryName];
    }

    function add(Types.Stakeholder memory user) internal {
        require(user.id_ != address(0));
        stakeholders[user.id_] = user;
    }

    function getPhrases() public view returns (bytes32, bytes32, bytes32) {
        require(
            stakeholderspharse[msg.sender][0] != bytes32(0),
            "User not registered"
        );
        return (
        stakeholderspharse[msg.sender][0],
        stakeholderspharse[msg.sender][1],
        stakeholderspharse[msg.sender][2]
        );
    }
}

// File: Amira Code v3/Optimized Amira Code v2 (2)/Optimized Amira Code v2/Supplier.sol


pragma solidity ^0.8.15;




contract Supplier {

    Types.SupplierWithMaterialID[] internal supplierWithMaterialID;
    mapping(bytes32 => Types.SupplierWithMaterialID[]) supplierPrices;

    mapping(address =>mapping(bytes32 => Types.Item)) public supplyItems;
    mapping(address => Types.Item[]) public supplyItemsInventory;
    mapping(address =>mapping(bytes32 => Types.manfItem)) public supplyManufItems;
    mapping(address => Types.manfItem[]) public supplyManufItemsInventory;
    event supplierSet(
        address id_, // account Id of the user
        bytes32 productid_,
        uint256 supplyprice_,
        uint256 requestCreationTime_
    );

    function supplierSetMaterialIDandPrice(bytes32 Itemid_, uint256 supplyprice_)
        public
    {
        // require(Types.Stakeholder.IsRegistered==true,"supplier not registered!");
        Types.SupplierWithMaterialID memory supplierMaterialID_ = Types
            .SupplierWithMaterialID({
                id_ : msg.sender,
                itemId_ : Itemid_,
                supplyprice_ : supplyprice_
            });
        supplierWithMaterialID.push(supplierMaterialID_);
        supplierPrices[Itemid_].push(supplierMaterialID_);
        emit supplierSet(msg.sender, Itemid_, supplyprice_, block.timestamp);
    }
}

// File: Amira Code v3/Optimized Amira Code v2 (2)/Optimized Amira Code v2/Inventory.sol


pragma solidity ^0.8.15;




contract Inventroy {
    
    StakeHolderRegistration registration;
    GenratesAndConversion genCn;
    
    constructor(GenratesAndConversion _genCn, StakeHolderRegistration _registration){
        genCn = _genCn;
        registration = _registration;
    }

    mapping(address => Types.Item[]) internal producerInventor;
    mapping(address => mapping(bytes32 => Types.Item)) internal rawMaterials; //mapping change public to normal
    mapping(address => Types.manfItem[]) internal productInventory;
    mapping(address => mapping(bytes32 => Types.manfItem))
        internal manufacturedProduct;
    mapping(string => Types.productAvailableManuf[]) internal sameproductLinkedWithManufacturer;
    

    //raw materials added In inventory
    event AddedInInventory(
        bytes32 _uniqueId,
        string _materialName,
        uint256 _quantity,
        uint256 _availableDate,
        uint256 _expiryDate,
        uint256 _price
    );

    //when Inventory Updated at the producer end
    event InventoryUpdate(
        bytes32 _pid,
        uint256 _quantity,
        uint256 _availableDate,
        uint256 _expiryDate,
        uint256 _price
    );

    //when Manufacturer added Product
    event ManufacturedProductAdded(
        string _productName,
        address _manufacturerAddress,
        string _barcodeId,
        uint256 _availableDate,
        uint256 _expiryDate,
        Types.State status
    );

    //when Manufacturer update The Product
    event ManufacturedProductUpdated(
        string _prodName,
        address _manufacturerAddress,
        uint256 _availableDate,
        uint256 _expiryDate,
        bytes32 _updatedHash
    );

    //added raw material for creating Inventory at the producer end!
    function addRawMaterial(
        string memory _materialname,
        uint256 _quantity,
        uint256 _availableDate,
        uint256 _expiryDate,
        uint256 _price
    ) public {
        bytes32 _pidHash = genCn.genrateUniqueIDByProductName(_materialname); //creates unique key using product name
        
        if(rawMaterials[msg.sender][_pidHash].PId == _pidHash){
            updateRawMaterial(_pidHash, rawMaterials[msg.sender][_pidHash].Quantity+_quantity,_availableDate, _expiryDate, _price);
        } else {

        Types.Item memory newRawMaterial = Types.Item({
            ArrayIndex: producerInventor[msg.sender].length,
            PId: _pidHash,
            MaterialName: _materialname,
            Quantity: _quantity,
            AvailableDate: _availableDate,
            ExpiryDate: _expiryDate,
            Price: _price,
            IsAdded: true,
            itemState: Types.State.PRODUCED,
            prebookCount: 0
        });

        rawMaterials[msg.sender][_pidHash] = newRawMaterial;
        addItemsInProducerInventory(rawMaterials[msg.sender][_pidHash]);
    
        emit AddedInInventory(
            _pidHash,
            _materialname,
            _quantity,
            _availableDate,
            _expiryDate,
            _price
        );
        }
    }

    // Function to update the quantity and price of a raw material from producer side!
    function updateRawMaterial(
        bytes32 _pid,
        uint256 _quantity,
        uint256 _availableDate,
        uint256 _expiryDate,
        uint256 _price
    ) internal {
        Types.Item storage updateMaterial = rawMaterials[msg.sender][_pid];
        
        updateMaterial.AvailableDate = _availableDate;
        updateMaterial.ExpiryDate = _expiryDate;
        updateMaterial.Quantity = _quantity;
        updateMaterial.Price = _price;

        //logic implemented here by adding ArrayIndex
        Types.Item[] storage products = producerInventor[msg.sender];
        uint256 index = rawMaterials[msg.sender][_pid].ArrayIndex;

        products[index].AvailableDate = _availableDate;
        products[index].ExpiryDate = _expiryDate;
        products[index].Quantity = _quantity;
        products[index].Price = _price;

        emit InventoryUpdate(
            _pid,
            _quantity,
            _availableDate,
            _expiryDate,
            _price
        );
    }

    //for adding new raw material in Inventory and also adding at modified Inventory!
    function addItemsInProducerInventory(Types.Item storage _newRawMaterial)
        private
    {
        producerInventor[msg.sender].push(_newRawMaterial);
    }

    // return all the Inventory function with modify one too
    // this function also used at manufacturer side too.
    function getProducerItems(address _producerID)
        public
        view
        returns (Types.Item[] memory)
    {
        return producerInventor[_producerID];
    }

    // function getProductDetails(bytes32 _prodId)
    //     public
    //     view
    //     returns (Types.Item memory)
    // {
    //     return rawMaterials[msg.sender][_prodId];
    // }

    function getAddedMaterialDetails(address _producerID, bytes32 _productID)
        external
        view
        returns (Types.Item memory)
    {
        return rawMaterials[_producerID][_productID];
    }

    //forchecking Inventory producer can check Inventroy is added or not by passing product name.
    // function IsAddedInInventory(string memory _materialName, bytes32 _pid)
    //     public
    //     view
    //     returns (bool)
    // {
    //     // bytes32 hash = keccak256(abi.encodePacked(_materialname));
    //     return (keccak256(
    //         abi.encodePacked((rawMaterials[msg.sender][_pid].MaterialName))
    //     ) == keccak256(abi.encodePacked((_materialName))));
    // }

    //Manufacturer Product Adding

    function addAProduct(
        string memory _prodName,
        string memory _description,
        uint256 _expiryDate,
        string memory _barcodeId,
        uint256 _quantity,
        uint256 _price,
        uint256 _weights,
        uint256 _availableDate
    ) public // productNotExists(_)
    // onlyManufacturer
    {
        bytes32 _pidHash = genCn.genrateUniqueIDByProductName(_prodName);
          if(_pidHash == manufacturedProduct[msg.sender][_pidHash].PId){
            updateAProduct(_prodName, _pidHash, _description, _expiryDate, manufacturedProduct[msg.sender][_pidHash].quantity+=_quantity, _price, _weights, _availableDate);
        }
        else    {
        
        Types.manfItem memory manufProduct_ = Types.manfItem({
            ArrIndex: productInventory[msg.sender].length,
            name: _prodName,
            PId: _pidHash,
            description: _description,
            expDateEpoch: _expiryDate,
            barcodeId: _barcodeId,
            quantity: _quantity,
            price: _price,
            weights: _weights,
            manDateEpoch: _availableDate, //available date
            prebookCount: 0,
            itemState: Types.State.ready_to_ship
        });

        manufacturedProduct[msg.sender][_pidHash] = manufProduct_;
        productInventory[msg.sender].push(manufProduct_);
        
        Types.productAvailableManuf memory _productAvailableManuf = Types.productAvailableManuf({
            id: msg.sender,
            productName: _prodName,
            productID: _pidHash,
            quantity: _quantity,
            price: _price,
            availableDate: _availableDate,
            weights: _weights,
            expDateEpoch: _expiryDate
        });

        sameproductLinkedWithManufacturer[_prodName].push(_productAvailableManuf); 

        emit ManufacturedProductAdded(
            _prodName,
            msg.sender,
            _barcodeId,
            _availableDate,
            _expiryDate,
            Types.State.ready_to_ship
            );
        }
    }

    // getManufacturedProducts
    function getManufacturedProductsByProductName(string memory _productName)
        external
        view
        returns (Types.productAvailableManuf[] memory)
    {
        return sameproductLinkedWithManufacturer[_productName];
    }


    function getManufacturerProducts(address _manufAdd)
        public
        view
        returns (Types.manfItem[] memory)
    {
        return productInventory[_manufAdd];
    }

    function getmanufEachProductDetails(address _manufAddress, bytes32 _manfProductID)
        public
        view
        returns (Types.manfItem memory)
    {
        return manufacturedProduct[_manufAddress][_manfProductID];
    }

    function updateAProduct(
        string memory _prodName,
        bytes32 _pID,
        string memory _description,
        uint256 _expiryDate,
        uint256 _quantity,
        uint256 _price,
        uint256 _weights,
        uint256 _availableDate
    ) internal // productNotExists(_)
    // onlyManufacturer
    {
        bytes32 _pidHash = genCn.genrateUniqueIDByProductName(_prodName);
        Types.manfItem storage updatingProduct = manufacturedProduct[
            msg.sender
        ][_pidHash];
        updatingProduct.name = _prodName;
        updatingProduct.PId = _pidHash;
        updatingProduct.description = _description;
        updatingProduct.expDateEpoch = _expiryDate;
        updatingProduct.quantity = _quantity;
        updatingProduct.price = _price;
        updatingProduct.weights = _weights;
        updatingProduct.manDateEpoch = _availableDate;

        Types.manfItem[] storage products_ = productInventory[msg.sender];
        uint256 index = manufacturedProduct[msg.sender][_pID].ArrIndex;

        products_[index].name = _prodName;
        products_[index].PId = _pidHash;
        products_[index].description = _description;
        products_[index].expDateEpoch = _expiryDate;
        products_[index].quantity = _quantity;
        products_[index].price = _price;
        products_[index].weights = _weights;
        products_[index].manDateEpoch = _availableDate;

        emit ManufacturedProductUpdated(
            _prodName,
            msg.sender,
            _availableDate,
            _expiryDate,
            _pidHash
        );
    }
}
// File: Amira Code v3/Optimized Amira Code v2 (2)/Optimized Amira Code v2/OrderManagementManufacturer.sol


pragma solidity ^0.8.15;

// import "./Library.sol";





contract OrderManagementManufacturer is Supplier {

    GenratesAndConversion public genCn;
    StakeHolderRegistration public registration;
    Inventroy public inventory;

    constructor(
        GenratesAndConversion _genCn,
        StakeHolderRegistration _registration,
        Inventroy _inventory
    ) {
       
       genCn = _genCn;
       registration = _registration;
       inventory = _inventory;
    }

    mapping(address => Types.MaterialHistory[]) internal materialHistory;
    mapping(address => Types.PurchaseOrderHistoryM) internal purchasematerialsHistory;

    event ReadyForShip(bytes32 productId, uint256 quantity);    //User Before purchase request creation.
    event PickedUp(address producerID, bytes32 prodId, uint256 quantity);  //supplier after purchase request at the manufacturer end
    event ShipmentReleased(bytes32 productId);
    event ShipmentReceived(bytes32 productId);  //manufacturer after order(material) received
    event Sold(bytes32 productId);  //when user created the request
    event MaterialDelivered(bytes32 productId);    //
    event RawMaterialsPurchased(
        address _producerId,
        bytes32 _productId,
        uint256 _quantity,
        uint256 _orderTime,
        Types.State _itemState
    );
    event newevent(Types.Item);
    /*
    step1
    @Manufacturer
    createMapping this function creates a mapping of potential suppliers and their prices
     by mapping the material id with each supplier. 
     The function createRequest returns a list containing the potential suppliers and their prices. 
    */

    //creates a material request through the function
    function createRequest(
        bytes32 materialId_, //prod unique ID
        uint256 quantity_,
        uint256 availableDate_
    ) public _isManufacturer view returns (Types.SupplierWithMaterialID[] memory) {
        require(
            registration.getStakeHolderDetails(msg.sender).IsRegistered,
            "manufcaturer not registered yet or only manufacturer can calls this function!"
        );

        return supplierPrices[materialId_];
    }

    
    //Manufacturer calls this function
    function PurchaseRawMaterials(
        address _producerId,
        address _supplierId,
        bytes32 _ItemId,
        uint256 _quantity
    ) public _isManufacturer {
        
        // Updating product history in manfacturer orders
        Types.Item memory _purchaseMaterial = inventory.getAddedMaterialDetails(
            _producerId,
            _ItemId
        );

        emit newevent(_purchaseMaterial);

        require(
            _purchaseMaterial.Quantity >= _quantity,
            "Insufficient inventory"
        );

        Types.Item memory _newMaterial = Types.Item({
            ArrayIndex: supplyItemsInventory[msg.sender].length,
            PId: _purchaseMaterial.PId,
            MaterialName: _purchaseMaterial.MaterialName,
            Quantity: _quantity,
            AvailableDate: _purchaseMaterial.AvailableDate,
            ExpiryDate: _purchaseMaterial.ExpiryDate,
            Price: _purchaseMaterial.Price,
            IsAdded: true,
            itemState: Types.State.SOLD,
            prebookCount: _quantity
        });

        emit newevent(_newMaterial);

        // supplyItems[_supplierId][_ItemId] = _newMaterial;
        // supplyItemsInventory[_supplierId].push(_newMaterial);

        
        Types.PurchaseOrderHistoryM memory purchaseOrderHistory_ = Types
            .PurchaseOrderHistoryM({
                manufacturerid: msg.sender,
                supplierId: _supplierId,
                producerId: _producerId,
                rawMaterial: _newMaterial,
                orderTime: block.timestamp
            });

        Types.MaterialHistory memory newProd_ = Types.MaterialHistory({
            manufacturer: purchaseOrderHistory_
        });

        if (
            registration.getStakeHolderDetails(msg.sender).role ==
            Types.StakeHolder.ManuFacturer
        ) {
            materialHistory[msg.sender].push(newProd_);
        }

        // Emiting event
        emit RawMaterialsPurchased(
            _producerId,
            _ItemId,
            _quantity,
            block.timestamp,
            Types.State.SOLD
        );
    }

    //Accessible by - producer
    function markMaterialReadyForShip(bytes32 _prodId, uint256 _quantity) public
    {
        require(isProducer(), "Not a producer!.");
        Types.Item memory product_ = inventory.getAddedMaterialDetails(
            msg.sender,
            _prodId
        );
        product_.itemState = Types.State.ready_to_ship;
        emit ReadyForShip(_prodId, _quantity);
    }

    //Accessible by - supplier
    function markMaterialPickedUp(address _supplierOwnAddress, address _producerID, bytes32 _prodId, uint256 _quantity)
        public _isSupplier
    {

        Types.Item memory _purchaseMaterial = inventory.getAddedMaterialDetails(
            _producerID,
            _prodId
        );

        require(
            _purchaseMaterial.Quantity >= _quantity,
            "Insufficient inventory"
        );

        _purchaseMaterial.itemState = Types.State.PICKUP;
        emit newevent(_purchaseMaterial);

        Types.Item memory _newMaterial = Types.Item({
            ArrayIndex: supplyItemsInventory[msg.sender].length,
            PId: _purchaseMaterial.PId,
            MaterialName: _purchaseMaterial.MaterialName,
            Quantity: _quantity,
            AvailableDate: _purchaseMaterial.AvailableDate,
            ExpiryDate: _purchaseMaterial.ExpiryDate,
            Price: _purchaseMaterial.Price,
            IsAdded: true,
            itemState: Types.State.SOLD,
            prebookCount: _quantity
        });
        emit newevent(_newMaterial);

        supplyItems[_supplierOwnAddress][_prodId] = _newMaterial;
        supplyItemsInventory[_supplierOwnAddress].push(_newMaterial);

        emit PickedUp(_producerID, _prodId, _quantity);
    }

     //Accessible by - producer
    function markMaterialShipmentReleased(address _producerID, bytes32 _prodId, uint256 _quantity)
        public
    {
        require(isProducer(), "Not a producer!.");
        Types.Item memory product_ = inventory.getAddedMaterialDetails(
            _producerID,
            _prodId
        );

        product_.Quantity -= _quantity;
        product_.itemState = Types.State.SHIPMENT_RELEASED;
        
        emit ShipmentReleased(_prodId);
    }

    //Accessible by - supplier/
    function markMaterialDelivered(
        address _supplierOwnAddress,
        address _manufacturerID,
        bytes32 _matId,
        uint256 _matQuantity
    ) public _isSupplier {
       
        Types.Item memory _newMaterial = supplyItems[_supplierOwnAddress][_matId];
        emit newevent(_newMaterial);

        supplyItems[_manufacturerID][_matId] = (_newMaterial);
        supplyItemsInventory[_manufacturerID].push(_newMaterial);

        _newMaterial.itemState = Types.State.DELIVERED;
        _newMaterial.Quantity -= _matQuantity;
        
        emit MaterialDelivered(_matId);
    }

    //Accessible by -manufacturer
    function markMaterialsRecieved(address _producerId, bytes32 _prodId)
        public _isManufacturer
    {
        require(isManufacturer(), "Not a manufacturer.");
        
        Types.Item memory _newMaterial = supplyItems[_producerId][_prodId];
        
        _newMaterial.itemState = Types.State.RECEIVED_SHIPMENT;
        emit ShipmentReceived(_prodId);
    }
    /*________________________________________________________________________*/
    // onlyManufacturer()
    //@supplier and @Maufacturer can checks raw materials from producer Inventory.
    // _isManufacturer _isSupplier
    function getRawItems() public view returns(Types.Item[] memory){
        return supplyItemsInventory[msg.sender];
    } 

    // onlyManufacturer()
    function getMaterialPurchase() public view returns(Types.MaterialHistory[] memory){
        return materialHistory[msg.sender];
    }
    /*_________________________________________________________________________*/

    function isProducer() public view returns (bool) {
        return
            registration.getStakeHolderDetails(msg.sender).role ==
            Types.StakeHolder.Producer;
    }

    function isManufacturer() public view returns (bool) {
        return
            registration.getStakeHolderDetails(msg.sender).role ==
            Types.StakeHolder.ManuFacturer;
    }

    function isSupplier() public view returns (bool) {
        return
            registration.getStakeHolderDetails(msg.sender).role ==
            Types.StakeHolder.supplier;
    }

    modifier _isManufacturer {
      require(registration.getStakeHolderDetails(msg.sender).role ==
            Types.StakeHolder.ManuFacturer, "manufcaturer not registered yet or only manufacturer can calls this function");
      _;
   }

   modifier _isSupplier {
      require(registration.getStakeHolderDetails(msg.sender).role ==
            Types.StakeHolder.supplier, "supplier not registered yet or only supplier can calls this function");
      _;
   }

}
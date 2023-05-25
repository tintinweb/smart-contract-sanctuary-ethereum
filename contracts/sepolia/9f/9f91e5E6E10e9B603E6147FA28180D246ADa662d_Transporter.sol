/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

// File: Optimized Amira Code v2/Genraters.sol


pragma solidity >=0.4.25 <0.9.0;

contract GenratesAndConversion {
    function random(uint256 _count) public view returns (bytes32) {
        return (
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
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

// File: Optimized Amira Code v2/Library.sol


pragma solidity >=0.4.25 <0.9.0;

library Types {
   
   enum StakeHolder {      //currently we have only 2 stakeholder so, that's why I'm using  
        Producer, //0 for producer.
        ManuFacturer, // 1 for manfacturer at the registeration time.
        distributors, // 2
        retailers, // 3
        supplier//4
    }

    enum productAvailablity {
        PRODUCED,
        ready_to_ship,
        pre_bookable, 
        READY_FOR_PICKUP, 
        PICKED_UP, 
        SHIPMENT_RELEASED, 
        RECEIVED_SHIPMENT, 
        READY_FOR_SALE, 
        PAID,
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
    }

    //Product => RawMaterial
    struct Product {
        uint256 ArrayIndex; //flag for checking the availablity
        bytes32 PId; // => now we created an auto genrated uid for each product using product name!
        string MaterialName;
        uint256 AvailableDate;
        uint256 Quantity;
        uint256 ExpiryDate;
        uint256 Price;
        bool IsAdded; //flag for checking the availablity
        productAvailablity status;
    }

    struct manfProduct { 
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
        productAvailablity status;
    }

    struct UserHistory {
        address id_;
        manfProduct Product_;
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
        bytes32 productId_;// Added, Purchased date in epoch in UTC timezone
        uint256 price_;
    }

    struct PurchaseOrderHistory {
        address _id;
        Product _product;
        uint256 _quantity;
        uint256 _orderTime;  
    }

    struct ProductHistory {
        PurchaseOrderHistory[] manufacturer;
    }            
    
    // //not in used
    // struct OrderPlaced {
    //     uint256 orderSrNo;
    //     address ManufAdd;
    //     bytes32 PId;
    //     string Materialname;
    //     uint256 Qty;
    //     uint256 PreOrderQty; //Not yet Placed That Why Inventory Not Deducted Total Quantity when Available Time Is Coming we can updated.
    //     uint256 ExpiryDate;
    //     bool IsOrderPlaced;
    // }
}
// File: Optimized Amira Code v2/Interfaces/IRegister.sol


pragma solidity ^0.8.15;


interface IStakeHolderRegistration {
    function Register(
        Types.StakeHolder _role,
        string memory _name,
        string memory _email,
        uint256 _mobNo,
        string memory _country,
        string memory _city
    ) external returns (string memory);

    function userRegisterUnderOtherStakeHolder(
        //(if user registered under other stakeholders like under manufacturer registered distributors and retailers same for others.)
        Types.StakeHolder _role,
        address _userref,
        string memory _name,
        string memory _email,
        uint256 _mobNo,
        string memory _country,
        string memory _city
    ) external returns (string memory);

    function getStakeHolderDetails(address id_)
        external
        view
        returns (Types.Stakeholder memory);

    //used at producer list
    function getProducerList()
        external
        view
        returns (Types.Stakeholder[] memory);

    //list of manufacturer
    function getManuFacturerList()
        external
        view
        returns (Types.Stakeholder[] memory);

    //list of distributors
    function getDistributorsList()
        external
        view
        returns (Types.Stakeholder[] memory);

    //list of retailers
    function getRetailersList()
        external
        view
        returns (Types.Stakeholder[] memory);

    //list of supplier
    function getSupplierList()
        external
        view
        returns (Types.Stakeholder[] memory);

    //list of distributersLinkedWithManufacturers
    function getStakeHolderListLinkedManufacturer(address _manufAdd)
        external
        view
        returns (Types.Stakeholder[] memory);

    //list of stakeholder linked with other distributer
    function getStakeHolderListLinkedWithDistributer(address _distAdd)
        external
        view
        returns (Types.Stakeholder[] memory);

    //list of manufacturer list via countryname
    function getDistViaCountryServe(string memory _countryName)
        external
        view
        returns (Types.Stakeholder[] memory);

    //list of manufacturer list via countryname
    function getManufViaCountryServe(string memory _countryName)
        external
        view
        returns (Types.Stakeholder[] memory);

    //list of suppliers list via countryname
    function getSupplierViaCountryServe(string memory _countryName)
        external
        view
        returns (Types.Stakeholder[] memory);

    // onlyManufacturer
    function approve(address a) external view returns (bool);

    function getPhrases() external view returns (bytes32[3] memory);

    function generatePhrases() external view returns (bytes32[3] memory);
}

// File: Optimized Amira Code v2/Supplier.sol


pragma solidity ^0.8.15;


contract Supplier {
    Types.SupplierWithMaterialID[] internal supplierWithMaterialID;
    mapping(bytes32 => Types.SupplierWithMaterialID[]) internal supplierPrices;

    event supplierSet(
        address id_, // account Id of the user
        bytes32 productid_,
        uint256 orderTime_
    );

    function supplierSetMaterialIDandPrice(bytes32 productid_, uint256 Cprice_)
        public
    {
        Types.SupplierWithMaterialID memory supplierMaterialID_ = Types
            .SupplierWithMaterialID({
                id_: msg.sender,
                productId_: productid_,
                price_: Cprice_
            });
        supplierWithMaterialID.push(supplierMaterialID_);
        supplierPrices[productid_].push(supplierMaterialID_);
        emit supplierSet(msg.sender, productid_, Cprice_);
    }
}

// File: Optimized Amira Code v2/Register.sol


pragma solidity ^0.8.15;

// import "./Restriction.sol";


contract StakeHolderRegistration  {
    
    // Restrictions restriction;
    GenratesAndConversion genr;

    constructor(GenratesAndConversion _genr){
        genr = _genr;
        // restriction = _restriction;
    }

    Types.Stakeholder[] internal producerList;
    Types.Stakeholder[] internal manufacturerList;
    Types.Stakeholder[] internal distributorsList;
    Types.Stakeholder[] internal retailersList;
    Types.Stakeholder[] internal supplierList;

    mapping(address => Types.Stakeholder) internal stakeholders;
    mapping(address => bytes32[3]) internal stakeholderspharse;
    mapping(string => Types.Stakeholder[]) internal servesCountry;
    mapping(string => Types.Stakeholder[]) internal distributoresServesCountry;
    mapping(string => Types.Stakeholder[]) internal supplierServesCountry;
    mapping(string => Types.Stakeholder[]) internal retailersServesCity;

    mapping(address => Types.Stakeholder[])
        internal distributerLinkedWithmanufacturer;
    mapping(address => Types.Stakeholder[])
        internal retailersLinkedWithdistributer;

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
        // require(
        //     has(_role, msg.sender),
        //     "same address and role already registered with the same role!"
        // );

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
        // require(has(_role, msg.sender),"same role and address already registered!");
        // require(stakeholders[_userref].role == Types.StakeHolder.ManuFacturer);
        require(
            (Types.StakeHolder.distributors == _role ||
                Types.StakeHolder.retailers == _role),
            "Under Manufacturer Can only Select Distributors and Retailers Role!"
        );
        require((approve(_userref)), "validator not approved!");    //approval work left 

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
        public
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

    // onlyManufacturer
    function approve(address a) internal view returns (bool) {
        return (keccak256(abi.encodePacked(a)) ==
            keccak256(abi.encodePacked(stakeholders[a].id_)));
    }

    function add(Types.Stakeholder memory user) internal {
        require(user.id_ != address(0));
        // require(!restriction.has(user.role, user.id_), "Same user with same role exists");
        stakeholders[user.id_] = user;
    }

    function getPhrases() public view returns (bytes32[3] memory) {
        require(
            stakeholderspharse[msg.sender][0] != bytes32(0),
            "User not registered"
        );

        return stakeholderspharse[msg.sender];
    }

    function getRole(address account)
        external
        view
        returns (Types.StakeHolder)
    {
        require(account != address(0));
        return stakeholders[account].role;
    }

    
}

// File: Optimized Amira Code v2/Restriction.sol


pragma solidity >=0.4.25 <0.9.0;



contract Restrictions {

    StakeHolderRegistration register;
    constructor(StakeHolderRegistration _register){
        register = _register;
    }        

     function has(Types.StakeHolder role, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0));
        return (account != address(0) &&
            register.getRole(account) == role);
    }

    function isStakeHolderExists(address account) external pure returns (bool) {
        bool existing_;
        if (account == address(0)) return existing_;
        if (account != address(0)) existing_ = true;
        return existing_;
    }

}
// File: Optimized Amira Code v2/Inventory.sol


pragma solidity ^0.8.15;


// import 


contract Inventroy {
    
    StakeHolderRegistration registration;
    GenratesAndConversion genCn;
    // Restrictions restriction;
    
    constructor(GenratesAndConversion _genCn){
        genCn = _genCn;
    }

    mapping(address => Types.Product[]) internal Inventor;
    mapping(address => mapping(bytes32 => Types.Product)) internal rawMaterials; //mapping change public to normal
    mapping(address => Types.manfProduct[]) internal userLinkedProducts;
    mapping(string => Types.productAvailableManuf[]) internal sameproductLinkedWithManufacturer;
    mapping(address => mapping(bytes32 => Types.manfProduct))
        internal manufacturedProduct;

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
        Types.productAvailablity status
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
        require(
            rawMaterials[msg.sender][_pidHash].IsAdded != true,
            "Raw material already exists In Inventory!,"
        );

        Types.Product memory newRawMaterial = Types.Product({
            ArrayIndex: Inventor[msg.sender].length,
            PId: _pidHash,
            MaterialName: _materialname,
            Quantity: _quantity,
            AvailableDate: _availableDate,
            ExpiryDate: _expiryDate,
            Price: _price,
            IsAdded: true,
            status: Types.productAvailablity.PRODUCED
        });

        rawMaterials[msg.sender][_pidHash] = newRawMaterial;
        addItemsInInventory(rawMaterials[msg.sender][_pidHash]);

        emit AddedInInventory(
            _pidHash,
            _materialname,
            _quantity,
            _availableDate,
            _expiryDate,
            _price
        );
    }

    // Function to update the quantity and price of a raw material from producer side!
    function updateRawMaterial(
        bytes32 _pid,
        uint256 _quantity,
        uint256 _availableDate,
        uint256 _expiryDate,
        uint256 _price
    ) public {
        Types.Product memory updateMaterial = rawMaterials[msg.sender][_pid];
        // Check if the raw material exists or not
        require(
            rawMaterials[msg.sender][_pid].IsAdded,
            "Raw material does not exist In Inventory Yet, first add then only update here!"
        );

        updateMaterial.AvailableDate = _availableDate;
        updateMaterial.ExpiryDate = _expiryDate;
        updateMaterial.Quantity = _quantity;
        updateMaterial.Price = _price;

        //logic implemented here by adding ArrayIndex
        Types.Product[] storage products = Inventor[msg.sender];
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
    function addItemsInInventory(Types.Product storage _newRawMaterial)
        private
    {
        Inventor[msg.sender].push(_newRawMaterial);
    }

    // return all the Inventory function with modify one too
    // this function also used at manufacturer side too.
    function getProducerItems(address _producerID)
        public
        view
        returns (Types.Product[] memory)
    {
        return Inventor[_producerID];
    }

    function getProductDetails(bytes32 _prodId)
        public
        view
        returns (Types.Product memory)
    {
        return rawMaterials[msg.sender][_prodId];
    }

    function getProductDetails(address _producerID, bytes32 _productID)
        external
        view
        returns (Types.Product memory)
    {
        return rawMaterials[_producerID][_productID];
    }

    //forchecking Inventory producer can check Inventroy is added or not by passing product name.
    function IsAddedInInventory(string memory _materialName, bytes32 _pid)
        public
        view
        returns (bool)
    {
        // bytes32 hash = keccak256(abi.encodePacked(_materialname));
        return (keccak256(
            abi.encodePacked((rawMaterials[msg.sender][_pid].MaterialName))
        ) == keccak256(abi.encodePacked((_materialName))));
    }

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
        Types.manfProduct memory manufProduct_ = Types.manfProduct({
            ArrIndex: userLinkedProducts[msg.sender].length,
            name: _prodName,
            PId: _pidHash,
            description: _description,
            expDateEpoch: _expiryDate,
            barcodeId: _barcodeId,
            quantity: _quantity,
            price: _price,
            weights: _weights,
            manDateEpoch: _availableDate, //available date
            status: Types.productAvailablity.ready_to_ship
        });

        manufacturedProduct[msg.sender][_pidHash] = manufProduct_;
        userLinkedProducts[msg.sender].push(manufProduct_);
        
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
            Types.productAvailablity.ready_to_ship
        );
    }

    function getManufacturedProducts(string memory _productName)
        external
        view
        returns (Types.productAvailableManuf[] memory)
    {
        return sameproductLinkedWithManufacturer[_productName];
    }


    function getManufacturerProducts(address _manufAdd)
        public
        view
        returns (Types.manfProduct[] memory)
    {
        return userLinkedProducts[_manufAdd];
    }

    function manufProductDetails(bytes32 _manfProductID)
        public
        view
        returns (Types.manfProduct memory)
    {
        return manufacturedProduct[msg.sender][_manfProductID];
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
    ) public // productNotExists(_)
    // onlyManufacturer
    {
        bytes32 _pidHash = genCn.genrateUniqueIDByProductName(_prodName);
        Types.manfProduct memory updatingProduct = manufacturedProduct[
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

        Types.manfProduct[] storage products_ = userLinkedProducts[msg.sender];
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

// File: Optimized Amira Code v2/OrderManagement.sol


pragma solidity ^0.8.15;






contract OrderManagement is Supplier{

    uint256 purchaseOrderCount;
    Inventroy inventory;
    Restrictions restriction;
    StakeHolderRegistration registration;

    constructor(Inventroy _inventory, Restrictions _restriction){
        inventory = _inventory; 
        restriction = _restriction;
        purchaseOrderCount = 0;
    }
    
    mapping(address => Types.ProductHistory) internal productHistory;
    mapping(address => Types.PurchaseOrderHistory) internal purchaseproductHistory;

    
    event RequestCreated(
        bytes32 prodId_,
        uint256 quantity_,
        uint256 availableDate_,
        uint256 currentTime_
    );

    event OrderPurchase(
        address _producerId,
        bytes32 _productId,
        uint256 _quantity,
        uint256 _orderTime,
        Types.productAvailablity _status
    );


    /*
    createMapping this function creates a mapping of potential suppliers and their prices
     by mapping the material id with each supplier. 
     The function createRequest returns a list containing the potential suppliers and their prices. 
    */

    //creates a material request through the function
    function createRequest(
        bytes32 materialId_, //prod unique ID
        uint256 quantity_,
        uint256 availableDate_
    ) public {
        require(
            restriction.isStakeHolderExists(msg.sender),
            "manufcaturer not registered yet!"
        );
        emit RequestCreated(
            materialId_,
            quantity_,
            availableDate_,
            block.timestamp
        );
        createMapping(materialId_);
    }
    /*
    creates a mapping of potential suppliers and their prices by mapping 
    the material id with each supplier. The function createRequest returns 
    a list containing the potential suppliers and their prices.
    all the supplier registered themself with a unique material ID.
    */
    function createMapping(
        //returns all the supplier who are registered themselve via a particular prodID
        bytes32 materialId_
    )
        internal
        view
        returns (Types.SupplierWithMaterialID[] memory)
    {
        return supplierPrices[materialId_];
    }

    // //creates a material request through the function
    // function CreateRequest2(
    //     bytes32 materialId_, //prod unique ID
    //     uint256 quantity_,
    //     uint256 availableDate_
    // ) public {
    //     require(
    //         restriction.isStakeHolderExists(msg.sender),
    //         "manufcaturer not registered yet!"
    //     );
    //     emit RequestCreated(
    //         materialId_,
    //         quantity_,
    //         availableDate_,
    //         block.timestamp
    //     );
    //     createMapping2(materialId_);
    // }

    // function createMapping2(
    //     //returns all the supplier who are registered themselve via a particular prodID
    //     bytes32 materialId_
    // )
    //     internal
    //     view
    //     returns (Types.SupplierWithMaterialID[] memory)
    // {
    //     return getManufacturedProducts[materialId_];
    // }


    //Manufacturer calls this function
    function PurchaseOrder(
        address _producerId,
        bytes32 _productId,
        uint256 _quantity,
        uint256 _orderTime
    ) public {
        // Updating product history in manfacturer orders
        Types.Product memory _purchaseMaterial = inventory.getProductDetails(_producerId, _productId);

        require(_purchaseMaterial.Quantity >= _quantity, "Insufficient inventory");

        updateInventory(_producerId, _productId, _quantity);

        Types.PurchaseOrderHistory memory purchaseOrderHistory_ = Types
            .PurchaseOrderHistory({
                _id: msg.sender,
                _product: _purchaseMaterial,
                _quantity: _quantity,
                _orderTime: _orderTime
            });

        if (registration.getRole(msg.sender) == Types.StakeHolder.ManuFacturer) {
            (productHistory[msg.sender].manufacturer).push(
                purchaseOrderHistory_
            );
        }

        // else if (stakeholders[msg.sender].distributors == StakeHolder.distributors) {
        //     productHistory[prodId_].distributors = userHistory_;
        // } else if (stakeholders(msg.sender) == StakeHolder.retailers) {
        //     productHistory[prodId_].retailers = userHistory_;
        // }
        // else {
        //     // Not in the assumption scope
        //     revert("Not valid operation");
        // }

        // transferOwnership(msg.sender, stakeholderId_, barcodeId_); // To transfer ownership from seller to buyer
        
        // Emiting event
        emit OrderPurchase(
            _producerId,
            _productId,
            _quantity,
            block.timestamp,
            Types.productAvailablity.pre_bookable
        );
    }


    function updateInventory(
        address _producerId,
        bytes32 _productId,
        uint256 _quantity
    ) internal view {
        inventory.getProductDetails(_producerId, _productId).Quantity -= _quantity;
        inventory.getProductDetails(_producerId, _productId).status = Types
            .productAvailablity
            .ready_to_ship;
    }


    function compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

}

// File: Optimized Amira Code v2/Transporter.sol


pragma solidity ^0.8.15;





contract Transporter {

    uint productID;

    Inventroy inventroy;
    Restrictions restriction;
    OrderManagement orderMang;
    StakeHolderRegistration registration;

    constructor(Inventroy _inventory, Restrictions _restriction, StakeHolderRegistration _registration, OrderManagement _orderMang){
        inventroy = _inventory; 
        restriction = _restriction;
        orderMang = _orderMang;
        registration = _registration;
    }

    event Produced(bytes32 productID);
    event ReadyForPickup(bytes32 productID);
    event PickedUp(uint productID);
    event ShipmentReleased(uint productID);     //ship the order
    event ShipmentReceived(uint productID);
    event ReadyForSale(uint productID);
    event Paid(uint productID);
    event Sold(uint productID);

   
    //Accessible by -
     function markProductReadyForShip(bytes32 prodId) public {
        require(isProducer(), "Not a producer.");
        Types.Product memory material_= inventroy.getProductDetails(msg.sender, prodId);
        material_.status = Types.productAvailablity.ready_to_ship;
        // material_.id_ = msg.sender;

        emit ReadyForPickup(prodId);
   }
    
    //      - Producer  
    function markProductReadyForPickup(bytes32 prodId) public {
        require(isProducer(), "Not a producer.");
        Types.Product memory material_= inventroy.getProductDetails(msg.sender, prodId);
        material_.status = Types.productAvailablity.READY_FOR_PICKUP;
        // material_.id_ = msg.sender;

        emit ReadyForPickup(prodId);
   }

    
    //Accessible by -
    //      - supplier
//     function pickUpProduct(uint prodId) public {
//         require(isDistributor(), "Not a distributor.");
//         Types.Product memory material_= inventroy.getProductDetails(msg.sender, prodId);
//         material_.productAvailablity = Types.productAvailablity.PICKED_UP;
//         material_.id_ = msg.sender;
//         products[prodId].distributorAddress = msg.sender;
//         emit PickedUp(prodId);
//    }

//     //Accessible by -
//     //      - Retailer
//     //      - Distributor
//     function buyProduct(uint prodId) public payable {
//         require(isRetailer() || isDistributor(), "Neither a retailer nor a distributor.");
//         products[prodId].productStatus = Status.PAID;
//         products[prodId].currentStatusUser = msg.sender;
//         emit Paid(prodId);
//    }

//     //Accessible by -
//     //      - Distributor
//     function releaseProductShipment(uint prodId) public {
//         require(isDistributor(), "Not a distributor.");
//         products[prodId].productStatus = Status.SHIPMENT_RELEASED;
//         products[prodId].currentStatusUser = msg.sender;
//         emit ShipmentReleased(prodId);
//    } 

//     //Accessible by -
//     //      - Retailer
//     function receiveProductShipment(uint prodId) public {
//         require(isRetailer(), "Not a retailer.");
//         products[prodId].productStatus = Status.RECEIVED_SHIPMENT;
//         products[prodId].currentStatusUser = msg.sender;
//         products[prodId].retailerAddresses = msg.sender;
//         emit ShipmentReceived(prodId);
//    }

//     //Accessible by -
//     //      - Retailer
//     function markProductReadyForSale(uint prodId) public {
//         require(isRetailer(), "Not a retailer.");
//         products[prodId].productStatus = Status.READY_FOR_SALE;
//         products[prodId].currentStatusUser = msg.sender;
//         emit ReadyForSale(prodId);
//    }

//    //Accessible by -
//     //      - Retailer
//     function sellProductToConsumer(uint prodId) public payable {
//         require(isRetailer(), "Not a retailer.");
//         products[prodId].productStatus = Status.SOLD;
//         products[prodId].currentStatusUser = msg.sender;
//         emit Sold(prodId);
//    }


    function isProducer() public view returns (bool) {
        return registration.getRole(msg.sender) == Types.StakeHolder.Producer;
    }
    
    function isDistributor() public view returns (bool) {
        return registration.getRole(msg.sender) == Types.StakeHolder.distributors;
    }

    function isRetailer() public view returns (bool) {
        return registration.getRole(msg.sender) == Types.StakeHolder.retailers;
    }
}
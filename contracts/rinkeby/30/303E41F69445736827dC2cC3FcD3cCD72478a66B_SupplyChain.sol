// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.9.0;

import "./Structure.sol";

contract SupplyChain {
    event ManufacturerAdded(address indexed _account);

    //product code
    uint256 public uid;
    uint256 sku;

    address owner;

    mapping(uint256 => Structure.Product) products;
    mapping(uint256 => Structure.ProductHistory) productHistory;
    mapping(address => Structure.Roles) roles;

    function hasManufacturerRole(address _account) public view returns (bool) {
        require(_account != address(0));
        return roles[_account].Manufacturer;
    }

    function addManufacturerRole(address _account) public {
        require(_account != address(0));
        require(!hasManufacturerRole(_account));

        roles[_account].Manufacturer = true;
    }

    function hasThirdPartyRole(address _account) public view returns (bool) {
        require(_account != address(0));
        return roles[_account].ThirdParty;
    }

    function addThirdPartyRole(address _account) public {
        require(_account != address(0));
        require(!hasThirdPartyRole(_account));

        roles[_account].ThirdParty = true;
    }

    function hasDeliveryHubRole(address _account) public view returns (bool) {
        require(_account != address(0));
        return roles[_account].DeliveryHub;
    }

    function addDeliveryHubRole(address _account) public {
        require(_account != address(0));
        require(!hasDeliveryHubRole(_account));

        roles[_account].DeliveryHub = true;
    }

    function hasCustomerRole(address _account) public view returns (bool) {
        require(_account != address(0));
        return roles[_account].Customer;
    }

    function addCustomerRole(address _account) public {
        require(_account != address(0));
        require(!hasDeliveryHubRole(_account));

        roles[_account].Customer = true;
    }

    constructor() public payable {
        owner = msg.sender;
        sku = 1;
        uid = 1;
    }

    event Manufactured(uint256 uid);
    event PurchasedByThirdParty(uint256 uid);
    event ShippedByManufacturer(uint256 uid);
    event ReceivedByThirdParty(uint256 uid);
    event PurchasedByCustomer(uint256 uid);
    event ShippedByThirdParty(uint256 uid);
    event ReceivedByDeliveryHub(uint256 uid);
    event ShippedByDeliveryHub(uint256 uid);
    event ReceivedByCustomer(uint256 uid);

    modifier verifyAddress(address add) {
        require(msg.sender == add);
        _;
    }

    modifier manufactured(uint256 _uid) {
        require(products[_uid].productState == Structure.State.Manufactured);
        _;
    }

    modifier shippedByManufacturer(uint256 _uid) {
        require(
            products[_uid].productState == Structure.State.ShippedByManufacturer
        );
        _;
    }

    modifier receivedByThirdParty(uint256 _uid) {
        require(
            products[_uid].productState == Structure.State.ReceivedByThirdParty
        );
        _;
    }

    modifier purchasedByCustomer(uint256 _uid) {
        require(
            products[_uid].productState == Structure.State.PurchasedByCustomer
        );
        _;
    }

    modifier shippedByThirdParty(uint256 _uid) {
        require(
            products[_uid].productState == Structure.State.ShippedByThirdParty
        );
        _;
    }

    modifier receivedByDeliveryHub(uint256 _uid) {
        require(
            products[_uid].productState == Structure.State.ReceivedByDeliveryHub
        );
        _;
    }

    modifier shippedByDeliveryHub(uint256 _uid) {
        require(
            products[_uid].productState == Structure.State.ShippedByDeliveryHub
        );
        _;
    }

    modifier receivedByCustomer(uint256 _uid) {
        require(
            products[_uid].productState == Structure.State.ReceivedByCustomer
        );
        _;
    }

    function manufactureEmptyInitialize(Structure.Product memory product)
        internal
        pure
    {
        address thirdParty;
        string memory transaction;
        string memory thirdPartyLongitude;
        string memory thirdPartyLatitude;

        address deliveryHub;
        string memory deliveryHubLongitude;
        string memory deliveryHubLatitude;
        address customer;

        product.thirdparty.thirdParty = thirdParty;
        product.thirdparty.thirdPartyLongitude = thirdPartyLongitude;
        product.thirdparty.thirdPartyLatitude = thirdPartyLatitude;

        product.deliveryhub.deliveryHub = deliveryHub;
        product.deliveryhub.deliveryHubLongitude = deliveryHubLongitude;
        product.deliveryhub.deliveryHubLatitude = deliveryHubLatitude;

        product.customer = customer;
        product.transaction = transaction;
    }

    function manufactureProductInitialize(
        Structure.Product memory product,
        string memory productName,
        uint256 productCode,
        uint256 productPrice,
        string memory productCategory
    ) internal pure {
        product.productdet.productName = productName;
        product.productdet.productCode = productCode;
        product.productdet.productPrice = productPrice;
        product.productdet.productCategory = productCategory;
    }

    ///@dev STEP 1 : Manufactured a product.
    function manufactureProduct(
        string memory manufacturerName,
        string memory manufacturerDetails,
        string memory manufacturerLongitude,
        string memory manufacturerLatitude,
        string memory productName,
        uint256 productCode,
        uint256 productPrice,
        string memory productCategory
    ) public {
        require(hasManufacturerRole(msg.sender));
        uint256 _uid = uid;
        Structure.Product memory product;
        product.sku = sku;
        product.uid = _uid;
        product.manufacturer.manufacturerName = manufacturerName;
        product.manufacturer.manufacturerDetails = manufacturerDetails;
        product.manufacturer.manufacturerLongitude = manufacturerLongitude;
        product.manufacturer.manufacturerLatitude = manufacturerLatitude;
        product.manufacturer.manufacturedDate = block.timestamp;

        product.owner = msg.sender;
        product.manufacturer.manufacturer = msg.sender;

        manufactureEmptyInitialize(product);

        product.productState = Structure.State.Manufactured;

        manufactureProductInitialize(
            product,
            productName,
            productCode,
            productPrice,
            productCategory
        );

        products[_uid] = product;

        productHistory[_uid].history.push(product);

        sku++;
        uid = uid + 1;

        emit Manufactured(_uid);
    }

    ///@dev STEP 2 : Purchase of manufactured product by Third Party.
    function purchaseByThirdParty(uint256 _uid) public manufactured(_uid) {
        require(hasThirdPartyRole(msg.sender));
        products[_uid].thirdparty.thirdParty = msg.sender;
        products[_uid].productState = Structure.State.PurchasedByThirdParty;
        productHistory[_uid].history.push(products[_uid]);

        emit PurchasedByThirdParty(_uid);
    }

    ///@dev STEP 3 : Shipping of purchased product to Third Party.
    function shipToThirdParty(uint256 _uid)
        public
        verifyAddress(products[_uid].manufacturer.manufacturer)
    {
        require(hasManufacturerRole(msg.sender));
        products[_uid].productState = Structure.State.ShippedByManufacturer;
        productHistory[_uid].history.push(products[_uid]);

        emit ShippedByManufacturer(_uid);
    }

    ///@dev STEP 4 : Received the purchased product shipped by Manufacturer.
    function receiveByThirdParty(
        uint256 _uid,
        string memory thirdPartyLongitude,
        string memory thirdPartyLatitude
    )
        public
        shippedByManufacturer(_uid)
        verifyAddress(products[_uid].thirdparty.thirdParty)
    {
        require(hasThirdPartyRole(msg.sender));
        products[_uid].owner = msg.sender;
        products[_uid].thirdparty.thirdPartyLongitude = thirdPartyLongitude;
        products[_uid].thirdparty.thirdPartyLatitude = thirdPartyLatitude;
        products[_uid].productState = Structure.State.ReceivedByThirdParty;
        productHistory[_uid].history.push(products[_uid]);

        emit ReceivedByThirdParty(_uid);
    }

    ///@dev STEP 5 : Purchase of a product at third party by Customer.
    function purchaseByCustomer(uint256 _uid)
        public
        receivedByThirdParty(_uid)
    {
        require(hasCustomerRole(msg.sender));
        products[_uid].customer = msg.sender;
        products[_uid].productState = Structure.State.PurchasedByCustomer;
        productHistory[_uid].history.push(products[_uid]);

        emit PurchasedByCustomer(_uid);
    }

    ///@dev STEP 7 : Shipping of product by third party purchased by customer.
    function shipByThirdParty(uint256 _uid)
        public
        verifyAddress(products[_uid].owner)
        verifyAddress(products[_uid].thirdparty.thirdParty)
    {
        require(hasThirdPartyRole(msg.sender));
        products[_uid].productState = Structure.State.ShippedByThirdParty;
        productHistory[_uid].history.push(products[_uid]);

        emit ShippedByThirdParty(_uid);
    }

    ///@dev STEP 8 : Receiveing of product by delivery hub purchased by customer.
    function receiveByDeliveryHub(
        uint256 _uid,
        string memory deliveryHubLongitude,
        string memory deliveryHubLatitude
    ) public shippedByThirdParty(_uid) {
        require(hasDeliveryHubRole(msg.sender));
        products[_uid].owner = msg.sender;
        products[_uid].deliveryhub.deliveryHub = msg.sender;
        products[_uid].deliveryhub.deliveryHubLongitude = deliveryHubLongitude;
        products[_uid].deliveryhub.deliveryHubLatitude = deliveryHubLatitude;
        products[_uid].productState = Structure.State.ReceivedByDeliveryHub;
        productHistory[_uid].history.push(products[_uid]);

        emit ReceivedByDeliveryHub(_uid);
    }

    ///@dev STEP 9 : Shipping of product by delivery hub purchased by customer.
    function shipByDeliveryHub(uint256 _uid)
        public
        receivedByDeliveryHub(_uid)
        verifyAddress(products[_uid].owner)
        verifyAddress(products[_uid].deliveryhub.deliveryHub)
    {
        require(hasDeliveryHubRole(msg.sender));
        products[_uid].productState = Structure.State.ShippedByDeliveryHub;
        productHistory[_uid].history.push(products[_uid]);

        emit ShippedByDeliveryHub(_uid);
    }

    ///@dev STEP 10 : Shipping of product by delivery hub purchased by customer.
    function receiveByCustomer(uint256 _uid)
        public
        shippedByDeliveryHub(_uid)
        verifyAddress(products[_uid].customer)
    {
        require(hasCustomerRole(msg.sender));
        products[_uid].owner = msg.sender;
        products[_uid].productState = Structure.State.ReceivedByCustomer;
        productHistory[_uid].history.push(products[_uid]);

        emit ReceivedByCustomer(_uid);
    }

    ///@dev Fetch product
    function fetchProductPart1(
        uint256 _uid,
        string memory _type,
        uint256 i
    )
        public
        view
        returns (
            uint256,
            uint256,
            address,
            address,
            string memory,
            string memory,
            string memory,
            string memory
        )
    {
        require(products[_uid].uid != 0);
        Structure.Product storage product = products[_uid];
        if (keccak256(bytes(_type)) == keccak256(bytes("product"))) {
            product = products[_uid];
        }
        if (keccak256(bytes(_type)) == keccak256(bytes("history"))) {
            product = productHistory[_uid].history[i];
        }
        return (
            product.uid,
            product.sku,
            product.owner,
            product.manufacturer.manufacturer,
            product.manufacturer.manufacturerName,
            product.manufacturer.manufacturerDetails,
            product.manufacturer.manufacturerLongitude,
            product.manufacturer.manufacturerLatitude
        );
    }

    ///@dev Fetch product
    function fetchProductPart2(
        uint256 _uid,
        string memory _type,
        uint256 i
    )
        public
        view
        returns (
            uint256,
            string memory,
            uint256,
            uint256,
            string memory,
            Structure.State,
            address,
            string memory
        )
    {
        require(products[_uid].uid != 0);
        Structure.Product storage product = products[_uid];
        if (keccak256(bytes(_type)) == keccak256(bytes("product"))) {
            product = products[_uid];
        }
        if (keccak256(bytes(_type)) == keccak256(bytes("history"))) {
            product = productHistory[_uid].history[i];
        }
        return (
            product.manufacturer.manufacturedDate,
            product.productdet.productName,
            product.productdet.productCode,
            product.productdet.productPrice,
            product.productdet.productCategory,
            product.productState,
            product.thirdparty.thirdParty,
            product.thirdparty.thirdPartyLongitude
        );
    }

    function fetchProductPart3(
        uint256 _uid,
        string memory _type,
        uint256 i
    )
        public
        view
        returns (
            string memory,
            address,
            string memory,
            string memory,
            address,
            string memory
        )
    {
        require(products[_uid].uid != 0);
        Structure.Product storage product = products[_uid];
        if (keccak256(bytes(_type)) == keccak256(bytes("product"))) {
            product = products[_uid];
        }
        if (keccak256(bytes(_type)) == keccak256(bytes("history"))) {
            product = productHistory[_uid].history[i];
        }
        return (
            product.thirdparty.thirdPartyLatitude,
            product.deliveryhub.deliveryHub,
            product.deliveryhub.deliveryHubLongitude,
            product.deliveryhub.deliveryHubLatitude,
            product.customer,
            product.transaction
        );
    }

    function fetchProductCount() public view returns (uint256) {
        return uid;
    }

    function fetchProductHistoryLength(uint256 _uid)
        public
        view
        returns (uint256)
    {
        return productHistory[_uid].history.length;
    }

    function fetchProductState(uint256 _uid)
        public
        view
        returns (Structure.State)
    {
        return products[_uid].productState;
    }

    function setTransactionHashOnManufacture(string memory tran) public {
        productHistory[uid - 1].history[
            productHistory[uid - 1].history.length - 1
        ]
            .transaction = tran;
    }

    function setTransactionHash(uint256 _uid, string memory tran) public {
        Structure.Product storage p =
            productHistory[_uid].history[
                productHistory[_uid].history.length - 1
            ];
        p.transaction = tran;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.9.0;

library Structure {
    enum State {
        Manufactured,
        PurchasedByThirdParty,
        ShippedByManufacturer,
        ReceivedByThirdParty,
        PurchasedByCustomer,
        ShippedByThirdParty,
        ReceivedByDeliveryHub,
        ShippedByDeliveryHub,
        ReceivedByCustomer
    }
    struct ManufactureDetails {
        address manufacturer;
        string manufacturerName;
        string manufacturerDetails;
        string manufacturerLongitude;
        string manufacturerLatitude;
        uint256 manufacturedDate;
    }
    struct ProductDetails {
        string productName;
        uint256 productCode;
        uint256 productPrice;
        string productCategory;
    }
    struct ThirdPartyDetails {
        address thirdParty;
        string thirdPartyLongitude;
        string thirdPartyLatitude;
    }
    struct DeliveryHubDetails {
        address deliveryHub;
        string deliveryHubLongitude;
        string deliveryHubLatitude;
    }
    struct Product {
        uint256 uid;
        uint256 sku;
        address owner;
        State productState;
        ManufactureDetails manufacturer;
        ThirdPartyDetails thirdparty;
        ProductDetails productdet;
        DeliveryHubDetails deliveryhub;
        address customer;
        string transaction;
    }

    struct ProductHistory {
        Product[] history;
    }

    struct Roles {
        bool Manufacturer;
        bool ThirdParty;
        bool DeliveryHub;
        bool Customer;
    }
}
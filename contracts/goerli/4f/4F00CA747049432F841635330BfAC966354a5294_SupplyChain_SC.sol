// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

library Structure {
    enum States {
        Manufactured,
        DeliveredByManufacturer,
        ReceivedByQA,
        ApprovedByQA,
        PurchasedByRetail,
        DeliveredByQA,
        ReceivedByDistributor,
        DeliveredByDistributor,
        ReceivedByRetail
    }

    struct Manufacturer {
        address manufacturer;
        string manufacturerName;
        uint256 manufacturedDate;
        string manufacturerLocation;
    }

    struct Product {
        string productName;
        uint256 productSerial;
        uint productPrice;
        uint256 productQty;
        bool productApproval;
    }

    struct QualityAssurance {
        address qualityAssurance;
        string qa_Company;
        string qa_Location;
    }

    struct Distributor {
        address distributor;
        string dist_Company;
        string dist_Location;
    }

    struct Retail{
        address retail;
        string ret_Company;
        string ret_Location;
    }

    struct ProductDetails {
        uint256 uid;
        address owner;
        States productState;
        Manufacturer manuf;
        QualityAssurance qa;
        Product pd;
        Distributor dist;
        Retail ret;
        string transaction;
    }

    struct productHistory {
        ProductDetails[] history;
    }

    struct Roles {
        bool Manufacturer;
        bool QualityAssurance;
        bool Distributor;
        bool Retail;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.7;

import "./Structure.sol";

contract SupplyChain_SC {
    uint256 public prod_UID;
   

    address owner;

    mapping(uint256 => Structure.ProductDetails) product_map;
    mapping(uint256 => Structure.productHistory) productHistory;
    mapping(address => Structure.Roles) scRole;
   
    function addManufacturer(address _account) public {
        require(_account != address(0));
        require(!isManufacturer(_account));

        scRole[_account].Manufacturer = true;
    }

    function addQualityAssurance(address _account) public {
        require(_account != address(0));
        require(!isQualityAssurance(_account));

        scRole[_account].QualityAssurance = true;
    }

     function addDistributor(address _account) public {
        require(_account != address(0));
        require(!isDistributor(_account));

        scRole[_account].Distributor = true;
    }

    function addRetail(address _account) public {
        require(_account != address(0));
        require(!isRetail(_account));

        scRole[_account].Retail = true;
    }

     function isManufacturer(address _account) public view returns (bool) {
        require(_account != address(0));
        return scRole[_account].Manufacturer;
    }


    function isQualityAssurance(address _account) public view returns (bool) {
        require(_account != address(0));
        return scRole[_account].QualityAssurance;
    }

    function isDistributor(address _account) public view returns (bool) {
        require(_account != address(0));
        return scRole[_account].Distributor;
    }

    function isRetail(address _account) public view returns (bool) {
        require(_account != address(0));
        return scRole[_account].Retail;
    }

    constructor() payable {
        owner = msg.sender;
        
        prod_UID = 1;
    }

    event Manufactured(uint256 uid);
    event DeliveredByManufacturer(uint256 uid);
    event ReceivedByQA(uint256 uid);
    event ApprovedByQA(uint256 uid);
    event PurchasedByRetail(uint256 uid);
    event DeliveredByQA(uint256 uid);
    event ReceivedByDistributor(uint256 uid);
    event DeliveredByDistributor(uint256 uid);
    event ReceivedByRetail(uint256 uid);

    //verify if address is same as sender
    modifier verifyAddress(address addr) {
        require(
            msg.sender == addr
        );
        _;
    }

    modifier manufactured(uint256 _uid) {
        require(
            product_map[_uid].productState == Structure.States.Manufactured
        );
        _;
    }

    modifier deliveredByManufacturer(uint256 _uid) {
        require(
            product_map[_uid].productState ==
                Structure.States.DeliveredByManufacturer
        );
        _;
    }

    modifier receivedByQA(uint256 _uid) {
        require(
            product_map[_uid].productState == Structure.States.ReceivedByQA
        );
        _;
    }

    modifier approvedByQA(uint256 _uid) {
        require(
            product_map[_uid].productState == Structure.States.ApprovedByQA
        );
        _;
    }

    modifier purchasedByRetail(uint256 _uid) {
        require(
            product_map[_uid].productState == Structure.States.PurchasedByRetail
        );
        _;
    }

    modifier deliveredByQA(uint256 _uid) {
        require(
            product_map[_uid].productState == Structure.States.DeliveredByQA
        );
        _;
    }

    modifier receivedByDistributor(uint256 _uid) {
        require(
            product_map[_uid].productState ==
                Structure.States.ReceivedByDistributor
        );
        _;
    }

    modifier deliveredByDistributor(uint256 _uid) {
        require(
            product_map[_uid].productState ==
                Structure.States.DeliveredByDistributor
        );
        _;
    }

    modifier receivedByRetail(uint256 _uid) {
        require(
            product_map[_uid].productState == Structure.States.ReceivedByRetail
        );
        _;
    }

    function manufactureInitialize(
        Structure.ProductDetails memory product
    ) internal pure {
        address qualityAssurance;
        string memory transaction;
        string memory qa_Company;
        string memory qa_Location;

        address distributor;
        string memory dist_Company;
        string memory dist_Location;

        address retail;
        string memory ret_Company;
        string memory ret_Location;

        product.qa.qualityAssurance = qualityAssurance;
        product.qa.qa_Company = qa_Company;
        product.qa.qa_Location = qa_Location;

        product.dist.distributor = distributor;
        product.dist.dist_Company = dist_Company;
        product.dist.dist_Location = dist_Location;

        product.ret.retail = retail;
        product.ret.ret_Company = ret_Company;
        product.ret.ret_Location = ret_Location;
        product.transaction = transaction;
    }

    function productInitialize(
        Structure.ProductDetails memory product,
        string memory productName,
        uint256 productSerial,
        uint256 productPrice,
        uint256 productQty
    ) internal pure {
        product.pd.productName = productName;
        product.pd.productSerial = productSerial;
        product.pd.productPrice = productPrice;
        product.pd.productQty = productQty;
        product.pd.productApproval = false;
    }

    //1: Product Manufacturing Phase
    function manufactureProduct(
        string memory manufacturerName,
        string memory manufacturerLocation,
        string memory productname,
        uint256 productSerial,
        uint256 productPrice,
        uint256 productQty,
        address qaAddr,
        address distAddr, 
        address retAddr
    ) public {
        require(isManufacturer(msg.sender), "manuf error");
        uint256 _uid = prod_UID;
        Structure.ProductDetails memory product;
        
        product.uid = prod_UID;

        product.manuf.manufacturerName = manufacturerName;
        product.manuf.manufacturerLocation = manufacturerLocation;
        product.manuf.manufacturedDate = block.timestamp;

        product.owner = msg.sender;
        product.manuf.manufacturer = msg.sender;
        product.qa.qualityAssurance = qaAddr;
        product.dist.distributor = distAddr;
        product.ret.retail = retAddr;

        manufactureInitialize(product);

        product.productState = Structure.States.Manufactured;

        productInitialize(
            product,
            productname,
            productSerial,
            productPrice,
            productQty
        );

        product_map[_uid] = product;

        productHistory[_uid].history.push(product);

        
        prod_UID = prod_UID + 1;

        emit Manufactured(_uid);
    }

    //2: Manufacturer delivers to Quality Assurance
    function deliverToQA(
        uint256 _uid
    ) public manufactured(_uid) verifyAddress(product_map[_uid].manuf.manufacturer) {
        require(isManufacturer(msg.sender));
        product_map[_uid].productState = Structure.States.DeliveredByManufacturer;
        productHistory[_uid].history.push(product_map[_uid]);

        emit DeliveredByManufacturer(_uid);
    }

    //3: Quality Assurance receives Product
    function qaReceive(
        uint256 _uid,
        string memory qa_Company,
        string memory qa_Location
    )
        public
        deliveredByManufacturer(_uid)
        verifyAddress(product_map[_uid].qa.qualityAssurance)
    {
        require(isQualityAssurance(msg.sender));
        product_map[_uid].owner = msg.sender;
        product_map[_uid].qa.qa_Company = qa_Company;
        product_map[_uid].qa.qa_Location = qa_Location;
        product_map[_uid].productState = Structure.States.ReceivedByQA;
        productHistory[_uid].history.push(product_map[_uid]);

        emit ReceivedByQA(_uid);
    }

    //4: Quality Assurance approves Product
    function qaApprove(uint256 _uid) public receivedByQA(_uid){
        require(isQualityAssurance(msg.sender));
        product_map[_uid].pd.productApproval = true;
        product_map[_uid].productState = Structure.States.ApprovedByQA;
        productHistory[_uid].history.push(product_map[_uid]);

        emit ApprovedByQA(_uid);
    }

    //5: Retail purchases product
    function retailPuchase(uint256 _uid) public approvedByQA(_uid) {
        require(isRetail(msg.sender));
        product_map[_uid].ret.retail = msg.sender;
        product_map[_uid].productState = Structure.States.PurchasedByRetail;
        productHistory[_uid].history.push(product_map[_uid]);

        emit PurchasedByRetail(_uid);
    }

    //6: Quality Assurance delivers product to Distributor
    function deliverToDistributor(
        uint256 _uid
    )
        public
        verifyAddress(product_map[_uid].owner)
        verifyAddress(product_map[_uid].qa.qualityAssurance)
    {
        require(isQualityAssurance(msg.sender));
        product_map[_uid].productState = Structure.States.DeliveredByQA;
        productHistory[_uid].history.push(product_map[_uid]);

        emit DeliveredByQA(_uid);
    }

    //7: Distributor receives Products
    function distReceive(
        uint256 _uid,
        string memory dist_Company,
        string memory dist_Location
    ) public deliveredByQA(_uid) {
        require(isDistributor(msg.sender));
        product_map[_uid].owner = msg.sender;
        product_map[_uid].dist.distributor = msg.sender;
        product_map[_uid].dist.dist_Company = dist_Company;
        product_map[_uid].dist.dist_Location = dist_Location;
        product_map[_uid].productState = Structure.States.ReceivedByDistributor;
        productHistory[_uid].history.push(product_map[_uid]);

        emit ReceivedByDistributor(_uid);
    }

    //8: Distributor delivers product to Retail
    function deliverToRetail(
        uint256 _uid
    )
        public
        receivedByDistributor(_uid)
        verifyAddress(product_map[_uid].ret.retail)
        verifyAddress(product_map[_uid].dist.distributor)
    {
        require(isDistributor(msg.sender));
        product_map[_uid].productState = Structure
            .States
            .DeliveredByDistributor;
        productHistory[_uid].history.push(product_map[_uid]);

        emit DeliveredByDistributor(_uid);
    }

    //9: Retail receives product
    function retailReceive(
        uint256 _uid
    )
        public
        deliveredByDistributor(_uid)
        verifyAddress(product_map[_uid].ret.retail)
    {
        require(isRetail(msg.sender));
        product_map[_uid].owner = msg.sender;
        product_map[_uid].productState = Structure.States.ReceivedByRetail;
        productHistory[_uid].history.push(product_map[_uid]);

        emit ReceivedByRetail(_uid);
    }

    //Fetch Product
       function fetchManufacturerInfo(
            uint256 _uid,
            string memory _type,
            uint256 i
        )
            public
            view
            returns (
                address,
                string memory,
                uint256,
                string memory
            )
        {
            require(product_map[_uid].uid != 0);
            Structure.ProductDetails storage product = product_map[_uid];
            if (keccak256(bytes(_type)) == keccak256(bytes("product"))) {
                product = product_map[_uid];
            }
            if (keccak256(bytes(_type)) == keccak256(bytes("history"))) {
                product = productHistory[_uid].history[i];
            }
            return (
                product.manuf.manufacturer,
                product.manuf.manufacturerName,
                product.manuf.manufacturedDate,
                product.manuf.manufacturerLocation
            );
        }    

    function fetchProductInfo(
            uint256 _uid,
            string memory _type,
            uint256 i
        )
            public
            view
            returns (
                string memory,
                uint256,
                uint256,
                bool,
                Structure.States
            )
        {
            require(product_map[_uid].uid != 0);
            Structure.ProductDetails storage product = product_map[_uid];
            if (keccak256(bytes(_type)) == keccak256(bytes("product"))) {
                product = product_map[_uid];
            }
            if (keccak256(bytes(_type)) == keccak256(bytes("history"))) {
                product = productHistory[_uid].history[i];
            }
            return (
                product.pd.productName,
                product.pd.productSerial,
                product.pd.productPrice,
                product.pd.productApproval,
                product.productState
            );
        }

    function fetchQAandDis(
            uint256 _uid,
            string memory _type,
            uint256 i
        )
            public
            view
            returns (
                address,
                string memory,
                string memory,
                address,
                string memory,
                string memory
                )
        {
            require(product_map[_uid].uid != 0);
            Structure.ProductDetails storage product = product_map[_uid];
            if (keccak256(bytes(_type)) == keccak256(bytes("product"))) {
                product = product_map[_uid];
            }
            if (keccak256(bytes(_type)) == keccak256(bytes("history"))) {
                product = productHistory[_uid].history[i];
            }
            return (
                product.qa.qualityAssurance,
                product.qa.qa_Company,
                product.qa.qa_Location,
                product.dist.distributor,
                product.dist.dist_Company,
                product.dist.dist_Location
                
            );
        }

    function fetchRetailInfo(
            uint256 _uid,
            string memory _type,
            uint256 i
        )
            public
            view
            returns (
                address,
                string memory,
                string memory,
                string memory,
                uint256,
                address
            )
        {
            require(product_map[_uid].uid != 0);
            Structure.ProductDetails storage product = product_map[_uid];
            if (keccak256(bytes(_type)) == keccak256(bytes("product"))) {
                product = product_map[_uid];
            }
            if (keccak256(bytes(_type)) == keccak256(bytes("history"))) {
                product = productHistory[_uid].history[i];
            }
            return (
                product.ret.retail,
                product.ret.ret_Company,
                product.ret.ret_Location,
                product.transaction,
                product.uid,
                product.owner
                
            );
        } 

    function fetchProductCount() public view returns (uint256) {
        return prod_UID;
    }

    function fetchProductHistoryLength(
        uint256 _uid
    ) public view returns (uint256) {
        return productHistory[_uid].history.length;
    }

    function fetchProductState(
        uint256 _uid
    ) public view returns (Structure.States) {
        return product_map[_uid].productState;
    }


   }
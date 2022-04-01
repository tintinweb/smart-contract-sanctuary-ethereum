pragma solidity ^0.8.12;
import "./RawMaterial.sol";
import "./ManufacturersProduct.sol";
import "./WholeSalersProduct.sol";
import "./DistributorsProduct.sol";
import "./RetailersProduct.sol";
import "./CustomersProduct.sol";

// SPDX-License-Identifier: UNLICENSED

contract SupplyChain is
    RawMaterial,
    ManufacturersProduct,
    WholeSalersProduct,
    DistributorsProduct,
    RetailersProduct,
    CustomersProduct
{
    uint64 public userCount = 0;
    address public Owner;

    constructor() {
        Owner = msg.sender;
    }

    modifier adminCant() {
        require(msg.sender != Owner);
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == Owner, "Only admin can call");
        _;
    }

    //user struct
    struct User {
        uint64 role;
        string name;
        string addr;
        uint64 uid;
        address userAddr;
        bool approved;
        bool isRegistered;
        uint64 tCost_OR_pPercent;
        uint256 joinedOn;
        uint64 totalEarnings;
    }
    mapping(address => User) public users;
    mapping(uint64 => User) public usersById;

    function registerUser(
        uint64 _role,
        string memory _name,
        string memory _address
    ) public {
        require(users[msg.sender].isRegistered != true, "Already a user!");
        require(msg.sender != Owner, "Admin can't register.");
        userCount++;
        uint64 cost = 5;
        if (_role == 6) {
            cost = 450;
        }
        User memory user = User(
            _role,
            _name,
            _address,
            userCount,
            msg.sender,
            false,
            true,
            cost,
            block.timestamp,
            0
        );
        users[msg.sender] = user;
        usersById[userCount] = user;
    }

    //admin functions
    function approveRole(address _addr) public onlyAdmin {
        require(users[_addr].approved == false, "already approved.");
        users[_addr].approved = true;
    }

    function removeUser(address _addr) public onlyAdmin {
        require(users[_addr].isRegistered == true, "Not a user.");
        users[_addr].approved = false;
        users[_addr].isRegistered = false;
    }

    function createRawMaterial(
        uint64 _quantity,
        uint64 _price,
        string memory _name
    ) public {
        require(users[msg.sender].role == 1, "Only supplier can call");
        rawMaterialCount++;
        uint64 _id = rawMaterialCount;
        RawMaterialS memory r = RawMaterialS(
            _quantity,
            _price,
            _id,
            msg.sender,
            _name
        );
        rawMaterials[_id] = r;
    }

    function buyFromSupplier(
        uint64 _id,
        uint64 _qnt,
        address _transporter
    ) public payable {
        require(users[msg.sender].role == 2, "Only manufacturer can call");
        require(
            users[msg.sender].approved == true,
            "Manufacturer is not approved"
        );
        require(
            users[_transporter].approved == true,
            "transporter is not approved"
        );
        require(rawMaterials[_id].quantity >= _qnt, "Insficient quantity");

        //transporters payment
        uint64 _transferCost = users[_transporter].tCost_OR_pPercent;
        payable(_transporter).transfer(_transferCost);

        users[_transporter].totalEarnings =
            users[_transporter].totalEarnings +
            _transferCost;

        require(
            msg.value >= _transferCost + (_qnt * rawMaterials[_id].price),
            "send sufficient ether"
        );

        uint64 _newQnt = rawMaterials[_id].quantity - _qnt;
        rawMaterials[_id].quantity = _newQnt;

        uint64 _price = rawMaterials[_id].price +
            ((rawMaterials[_id].price / 100) *
                users[msg.sender].tCost_OR_pPercent);
        manufacturersProductCount++;
        // uint64 _mid = manufacturersProductCount;
        ManufacturersProductS
            memory manufacturersProduct = ManufacturersProductS(
                _qnt,
                _price,
                manufacturersProductCount,
                msg.sender,
                rawMaterials[_id].name
            );
        manufacturersProducts[manufacturersProductCount] = manufacturersProduct;
        address payable _to = payable(rawMaterials[_id].creatorsAddress);
        // new chanhe
        users[_to].totalEarnings =
            users[_to].totalEarnings +
            (_qnt * rawMaterials[_id].price);
        //
        _to.transfer(_qnt * rawMaterials[_id].price);
    }

    function buyFromManufacturer(
        uint64 _id,
        uint64 _qnt,
        address _transporter
    ) public payable {
        require(users[msg.sender].role == 3, "Only wholesaler can call");
        require(
            users[msg.sender].approved == true,
            "Wholesaler is not approved"
        );
        require(
            users[_transporter].approved == true,
            "transporter is not approved"
        );

        require(
            manufacturersProducts[_id].quantity >= _qnt,
            "Insficient quantity"
        );

        //transporters payment
        uint64 _transferCost = users[_transporter].tCost_OR_pPercent;
        payable(_transporter).transfer(_transferCost);

        users[_transporter].totalEarnings =
            users[_transporter].totalEarnings +
            _transferCost;

        uint64 _newQnt = manufacturersProducts[_id].quantity - _qnt;
        manufacturersProducts[_id].quantity = _newQnt;
        uint64 _price = manufacturersProducts[_id].price +
            ((manufacturersProducts[_id].price / 100) *
                users[msg.sender].tCost_OR_pPercent);
        wholeSalersProductCount++;
        // uint64 _wid = wholeSalersProductCount;
        WholeSalersProductS memory wholeSalersProduct = WholeSalersProductS(
            _qnt,
            _price,
            wholeSalersProductCount,
            msg.sender,
            manufacturersProducts[_id].name
        );
        wholeSalersProducts[wholeSalersProductCount] = wholeSalersProduct;
        address payable _to = payable(
            manufacturersProducts[_id].creatorsAddress
        );
        users[_to].totalEarnings =
            users[_to].totalEarnings +
            (_qnt * manufacturersProducts[_id].price);
        _to.transfer(manufacturersProducts[_id].price * _qnt);
    }

    function buyFromWholesaler(uint64 _id, uint64 _qnt) public payable {
        require(users[msg.sender].role == 4, "Only Distributor can call");
        require(
            users[msg.sender].approved == true,
            "Distributor is not approved"
        );
        require(
            wholeSalersProducts[_id].quantity >= _qnt,
            "Insficient quantity"
        );

        uint64 _newQnt = wholeSalersProducts[_id].quantity - _qnt;
        wholeSalersProducts[_id].quantity = _newQnt;
        uint64 _price = wholeSalersProducts[_id].price +
            ((wholeSalersProducts[_id].price / 100) *
                users[msg.sender].tCost_OR_pPercent);
        distributorsProductCount = distributorsProductCount + 1;
        uint64 _did = distributorsProductCount;
        DistributorsProductS memory distributorsProduct = DistributorsProductS(
            _qnt,
            _price,
            _did,
            msg.sender,
            wholeSalersProducts[_id].name
        );
        distributorsProducts[_did] = distributorsProduct;
        address payable _to = payable(wholeSalersProducts[_id].creatorsAddress);

        users[_to].totalEarnings =
            users[_to].totalEarnings +
            (_qnt * wholeSalersProducts[_id].price);
        _to.transfer(wholeSalersProducts[_id].price * _qnt);
    }

    function buyFromDistributer(uint64 _id, uint64 _qnt) public payable {
        require(users[msg.sender].role == 5, "Only Retailer can call");
        require(users[msg.sender].approved == true, "Retailer is not approved");

        require(
            distributorsProducts[_id].quantity >= _qnt,
            "Insficient quantity"
        );

        uint64 _newQnt = distributorsProducts[_id].quantity - _qnt;
        distributorsProducts[_id].quantity = _newQnt;
        uint64 _price = distributorsProducts[_id].price +
            ((distributorsProducts[_id].price / 100) *
                users[msg.sender].tCost_OR_pPercent);
        retailersProductCount = retailersProductCount + 1;
        uint64 _rid = retailersProductCount;
        RetailersProductS memory retailersProduct = RetailersProductS(
            _qnt,
            _price,
            _rid,
            msg.sender,
            distributorsProducts[_id].name
        );
        retailersProducts[_rid] = retailersProduct;
        address payable _to = payable(
            distributorsProducts[_id].creatorsAddress
        );
        users[_to].totalEarnings =
            users[_to].totalEarnings +
            (_qnt * distributorsProducts[_id].price);

        _to.transfer(distributorsProducts[_id].price * _qnt);
    }

    function buyFromRetailer(uint64 _id, uint64 _qnt) public payable {
        require(retailersProducts[_id].quantity >= _qnt, "Insficient quantity");
        uint64 _newQnt = retailersProducts[_id].quantity - _qnt;
        retailersProducts[_id].quantity = _newQnt;
        address payable _to = payable(retailersProducts[_id].creatorsAddress);
        _to.transfer(retailersProducts[_id].price * _qnt);

        // cust pro obj
        customersProductCount++;
        CustomersProductS memory c = CustomersProductS(
            _qnt,
            retailersProducts[_id].price,
            customersProductCount,
            msg.sender,
            retailersProducts[_id].name,
            block.timestamp
        );

        users[_to].totalEarnings =
            users[_to].totalEarnings +
            (_qnt * retailersProducts[_id].price);

        customersProducts[customersProductCount] = c;
    }

    function setProfitPercentForUserORtFee(uint64 _profitPercent) public {
        require(
            // users[ msg.sender].role == 1 ||
            users[msg.sender].role == 2 ||
                users[msg.sender].role == 3 ||
                users[msg.sender].role == 4 ||
                users[msg.sender].role == 5 ||
                users[msg.sender].role == 6
        );
        users[msg.sender].tCost_OR_pPercent = _profitPercent;
    }

    function changePriceOfProduct(uint64 _id, uint64 _newPrice) public {
        if (users[msg.sender].role == 1) {
            rawMaterials[_id].price = _newPrice;
        } else if (users[msg.sender].role == 2) {
            manufacturersProducts[_id].price = _newPrice;
        } else if (users[msg.sender].role == 3) {
            wholeSalersProducts[_id].price = _newPrice;
        } else if (users[msg.sender].role == 4) {
            distributorsProducts[_id].price = _newPrice;
        } else if (users[msg.sender].role == 5) {
            retailersProducts[_id].price = _newPrice;
        }
    }
}
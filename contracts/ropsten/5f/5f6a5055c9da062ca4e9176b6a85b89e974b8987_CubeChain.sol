/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

contract CubeChain {

    string content;
    uint price;
    address owner;
    uint weight;
    uint count;
    string factory;
    string warehouse;
    string store;

    struct RawMaterial {
        string supplier;
        string rawMaterial;
        uint quantity;
    }

    RawMaterial[] public inventory;

    struct Packet {
        uint serialNo;
        string dateofManufacturing;
        string expiryDate;
        string productionUnit;
        bool halal;
        string warehouseName;
        string storeName;
        uint warehouseOrderID;
        uint retailorOrderID;
        bool sold;
        string contents;
        string customer;
    }

    Packet[] public packets;

    struct Batch {
        uint quantity;
        string date;
        uint batchID;
    }

    Batch[] public batches;

    uint batchCount ;

    struct Order {
        uint orderID;
        string orderDate;
        string pickupDate;
        string deliveryDate;
        string buyer;
        uint amount;
        string seller;
        uint quantity;
        string deliveryService;
        string status;
    }

    Order[] public warehouseOrders;
    Order[] public retailorOrders;
    uint warehouseOrdersCount;
    uint retailorOrdersCount;

    struct Logistic {
        uint orderID;
        uint quantity;
        string from;
        string to;
        string pickupDate;
        string deliveryDate;
    }

    Logistic[] public logistics;

    constructor () public{
        count = 0;
        batchCount = 0;
        warehouseOrdersCount = 0;
        retailorOrdersCount = 0;
        content = "Salt, Vegetables fat, Monosodium, Glutamate, Wheat flour, Sucrose, Yeast extract , Spices, Onion, Chicken fat, Chicken flavour, Parsley, Garlic, Flavour enhancers, Caramel, Dried chicken meat powder.";
        price = 200;
        weight = 150;
        warehouse = "KOLH, Kolhapur Warehouse";
        factory = "Swaraj Factory";
        store = "DMART Bellandur";
    }

    function produce(uint  _quantity, string memory _date, string memory _expiryDate, bool _halal) public{
        for(uint i=0; i<_quantity; i++) {
            Packet memory newPacket=Packet({
                serialNo : ++count,
                dateofManufacturing : _date,
                expiryDate : _expiryDate,
                productionUnit : factory,
                contents : content,
                halal : _halal,
                warehouseName : "",
                storeName : "",
                warehouseOrderID : 0,
                retailorOrderID : 0,
                sold : false,
                customer : ""
            });
            packets.push(newPacket);
        }
    }

    function produceBatch(uint _quantity, string memory _date, string memory _expiryDate, bool  _halal) public {
        Batch memory newBatch = Batch({
            batchID : ++batchCount,
            quantity : _quantity,
            date : _date
        });  
        batches.push(newBatch);
        produce(_quantity, _date, _expiryDate, _halal);
    }

    function addInventory(string memory _rawMaterial, string memory _supplier, uint _quantity) public {
        RawMaterial memory newRawMaterial = RawMaterial({
            rawMaterial: _rawMaterial,
            supplier: _supplier,
            quantity: _quantity
        });
        inventory.push(newRawMaterial);
    }

    function PlacesOrderWarehouse(uint _quantity, string memory _orderDate, string memory _buyer) public {
        Order memory newOrder= Order({
            orderID: ++warehouseOrdersCount,
            orderDate: _orderDate,
            quantity: _quantity,
            status: "Placed" ,
            buyer: _buyer,
            pickupDate : "",
            deliveryDate : "",
            amount : _quantity * price,
            seller : "",
            deliveryService : ""
        });
        warehouseOrders.push(newOrder);
    }

    function acceptOrderWarehouse(uint orderID) public{
        warehouseOrders[orderID].status = "Accepetd" ;
    }

    function bookLogisticsWarehouse(uint _orderID, string memory _from, string memory _to, string memory _pickupDate, string memory _deliveryDate, uint _quantity, string memory _deliveryService) public {
        Logistic memory newLogistic = Logistic ({
            orderID : _orderID,
            from : _from,
            to : _to,
            deliveryDate : _deliveryDate,
            pickupDate : _pickupDate,
            quantity : _quantity
        });
        logistics.push(newLogistic);
        //warehouseOrders[_orderID].status = "Shipped" ;
        warehouseOrders[_orderID].deliveryService = _deliveryService ;
    }

    function shippedOrderWarehouse(uint _orderID, string memory _pickupDate) public {
        warehouseOrders[_orderID].status = "Shipped" ;
        warehouseOrders[_orderID].pickupDate = _pickupDate;
    }

    function receivedOrderWarehouse(uint _orderID, string memory _deliveryDate) public {
        warehouseOrders[_orderID].status = "Received" ;
        warehouseOrders[_orderID].deliveryDate = _deliveryDate;
    }

    function PlacesOrderRetailor(uint _quantity, string memory _orderDate,  string memory _buyer) public {
        Order memory newOrder= Order({
            orderID: ++retailorOrdersCount,
            orderDate: _orderDate,
            quantity: _quantity,
            status: "Placed",
            buyer: _buyer,
            pickupDate : "",
            deliveryDate : "",
            amount : _quantity * price,
            seller : "",
            deliveryService : ""
        });
        retailorOrders.push(newOrder);
    }

    function acceptOrderRetailor(uint orderID) public{
        retailorOrders[orderID].status = "Accepted";
    }

    function bookLogisticsRetailor(uint _orderID, string memory _from, string memory _to, string memory _pickupDate, string memory _deliveryDate, uint _quantity, string memory _deliveryService) public {
        Logistic memory newLogistic = Logistic ({
            orderID : _orderID,
            from : _from,
            to : _to,
            deliveryDate : _deliveryDate,
            pickupDate : _pickupDate,
            quantity : _quantity
        });
        logistics.push(newLogistic);
        retailorOrders[_orderID].deliveryService = _deliveryService;
    }

    function shippedOrderRetailor(uint _orderID, string memory _pickupDate) public {
        retailorOrders[_orderID].status = "Shipped" ;
        retailorOrders[_orderID].pickupDate = _pickupDate;
    }

    function receivedOrderRetailor(uint _orderID, string memory _deliveryDate) public {
        retailorOrders[_orderID].status = "Received";
        retailorOrders[_orderID].deliveryDate = _deliveryDate;
    }

    function sold(uint _serialNo, string memory _customer) public {
        packets[_serialNo].sold = true;
        packets[_serialNo].customer = _customer;
    }

}
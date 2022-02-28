/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

pragma solidity ^0.4.25;

contract AMChain {

    enum Status { Created, Sintered, StartShippingSinterer, CompleteShippingSinterer, StartReshippingManufacturer, CompleteReshippingManufacturer, Checked, Delivering, Delivered, Accepted, Declined }

    Order[] orders;

    struct Order {
        string partID;
        string IPFS_CID;
        address manufacturer;
        address shipper;
        address sinterer;
        address customer;
        Status status;
    }

    event OrderCreated(
        uint256 index,
        address indexed manufacturer,
        address indexed shipper,
        address sinterer,
        address indexed customer
    );

    event OrderStartShippingSinterer(
        uint256 index,
        address indexed manufacturer,
        address indexed shipper,
        address sinterer,
        address indexed customer
    );

    event OrderCompleteShippingSinterer(
        uint256 index,
        address indexed manufacturer,
        address indexed shipper,
        address sinterer,
        address indexed customer
    );

    event OrderSintered(
        uint256 index,
        address indexed manufacturer,
        address indexed shipper,
        address sinterer,
        address indexed customer
    );

    event OrderStartReshippingManufacturer(
        uint256 index,
        address indexed manufacturer,
        address indexed shipper,
        address sinterer,
        address indexed customer
    );

    event OrderCompleteReshippingManufacturer(
        uint256 index,
        address indexed manufacturer,
        address indexed shipper,
        address sinterer,
        address indexed customer
    );

    event OrderChecked(
        uint256 index,
        address indexed manufacturer,
        address indexed shipper,
        address sinterer,
        address indexed customer
    );

    event OrderDelivering(
        uint256 index,
        address indexed manufacturer,
        address indexed shipper,
        address sinterer,
        address indexed customer
    );

    event OrderDelivered(
        uint256 index,
        address indexed manufacturer,
        address indexed shipper,
        address sinterer,
        address indexed customer
    );

    event OrderAccepted(
        uint256 index,
        address indexed manufacturer,
        address indexed shipper,
        address sinterer,
        address indexed customer
    );

    event OrderDeclined(
        uint256 index,
        address indexed manufacturer,
        address indexed shipper,
        address sinterer,
        address indexed customer
    );

   modifier onlyManufacturer(uint256 _index) {
        require(orders[_index].manufacturer == msg.sender);
        _;
    }

    modifier onlyShipper(uint256 _index) {
        require(orders[_index].shipper == msg.sender);
        _;
    }

    modifier onlySinterer(uint256 _index) {
        require(orders[_index].sinterer == msg.sender);
        _;
    }

    modifier onlyCustomer(uint256 _index) {
        require(orders[_index].customer == msg.sender);
        _;
    }

    modifier orderCreated(uint256 _index) {
        require(orders[_index].status == Status.Created);
        _;
    }

    modifier orderStartShippingSinterer(uint256 _index) {
        require(orders[_index].status == Status.StartShippingSinterer);
        _;
    }

    modifier orderCompleteShippingSinterer(uint256 _index) {
        require(orders[_index].status == Status.CompleteShippingSinterer);
        _;
    }

    modifier orderSintered(uint256 _index) {
        require(orders[_index].status == Status.Sintered);
        _;
    }

    modifier orderStartReshippingManufacturer(uint256 _index) {
        require(orders[_index].status == Status.StartReshippingManufacturer);
        _;
    }

    modifier orderCompleteReshippingManufacturer(uint256 _index) {
        require(orders[_index].status == Status.CompleteReshippingManufacturer);
        _;
    }

    modifier orderChecked(uint256 _index) {
        require(orders[_index].status == Status.Checked);
        _;
    }

    modifier orderDelivering(uint256 _index) {
        require(orders[_index].status == Status.Delivering);
        _;
    }

    modifier orderDelivered(uint256 _index) {
        require(orders[_index].status == Status.Delivered);
        _;
    }


// Start order process

    function _00_getOrder(
        uint256 _index
    ) public view returns(string memory, string memory, address, address, address, address, Status) {
        Order memory order = orders[_index];
        return (
            order.partID,
            order.IPFS_CID,
            order.manufacturer,
            order.shipper,
            order.sinterer,
            order.customer,
            order.status
        );
    }

    function _01_createOrder(
        string memory _partID,
        string memory _IPFS_CID,
        address _shipper,
        address _sinterer,
        address _customer
    ) public {                                      // hier wird noch eine Bedingung benötigt, die die Funktion nur dann ausführt, wenn sie zuvor noch nicht ausgeführt wurde
        Order memory order = Order({
            partID: _partID,
            IPFS_CID: _IPFS_CID,
            manufacturer: msg.sender,               // Achtung: der Contract-Deployer ist nicht automatisch Manufacturer, sonder derjenige Account, der auf "transact" clickt
            shipper: _shipper,
            sinterer: _sinterer,
            customer: _customer,
            status: Status.Created
        });
        uint256 index = orders.length;
        emit OrderCreated(index, msg.sender, _shipper, _sinterer, _customer);
        orders.push(order);
    }

// Send parts to Sinterer

    function _02_startShippingSintererOrder(
        uint256 _index
    ) public onlyShipper(_index) orderCreated(_index) {
        Order storage order = orders[_index];
        emit OrderStartShippingSinterer(_index, order.manufacturer, order.shipper, order.sinterer, order.customer);
        order.status = Status.StartShippingSinterer;
    }

    function _03_completeShippingSintererOrder(
        uint256 _index
    ) public onlyShipper(_index) orderStartShippingSinterer(_index) {
        Order storage order = orders[_index];
        emit OrderCompleteShippingSinterer(_index, order.manufacturer, order.shipper, order.sinterer, order.customer);
        order.status = Status.CompleteShippingSinterer;
    }

// Sintering of the parts

    function _04_sinterOrder(
        uint256 _index,
        string memory _IPFS_CID
    ) public onlySinterer(_index) orderCompleteShippingSinterer(_index) {
        Order storage order = orders[_index];
        order.IPFS_CID = _IPFS_CID;                                                                                                 //update the CID due to new Sinterer informations/ documents
        emit OrderSintered(_index, order.manufacturer, order.shipper, order.sinterer, order.customer);
        orders[_index].status = Status.Sintered;
    }

// Return the parts to manufacturer

    function _05_startReshippingManufacturerOrder(
        uint256 _index
    ) public onlyShipper(_index) orderSintered(_index) {
        Order storage order = orders[_index];
        emit OrderStartReshippingManufacturer(_index, order.manufacturer, order.shipper, order.sinterer, order.customer);
        order.status = Status.StartReshippingManufacturer;
    }

    function _06_completeReshippingManufacturerOrder(
        uint256 _index
    ) public onlyShipper(_index) orderStartReshippingManufacturer(_index) {
        Order storage order = orders[_index];
        emit OrderCompleteReshippingManufacturer(_index, order.manufacturer, order.shipper, order.sinterer, order.customer);
        order.status = Status.CompleteReshippingManufacturer;
    }

// Manufacturer perform final quality control and prepare parts for delivery

    function _07_checkOrder(
        uint256 _index,
        string memory _IPFS_CID
    ) public onlyManufacturer(_index) orderCompleteReshippingManufacturer(_index) {
        Order storage order = orders[_index];
        order.IPFS_CID = _IPFS_CID;                                                                                                 //update the CID due to new Manufacturer informations/ documents
        emit OrderChecked(_index, order.manufacturer, order.shipper, order.sinterer, order.customer);
        orders[_index].status = Status.Checked;
    }

// Deliver parts to customer

    function _08_startDeliveringOrder(
        uint256 _index
    ) public onlyShipper(_index) orderChecked(_index) {
        Order storage order = orders[_index];
        emit OrderDelivering(_index, order.manufacturer, order.shipper, order.sinterer, order.customer);
        order.status = Status.Delivering;
    }

    function _09_stopDeliveringOrder(
        uint256 _index
    ) public onlyShipper(_index) orderDelivering(_index) {
        Order storage order = orders[_index];
        emit OrderDelivered(_index, order.manufacturer, order.shipper, order.sinterer, order.customer);
        order.status = Status.Delivered;
    }

// Customer acceptance decision

    function _10a_acceptOrder(
        uint256 _index
    ) public onlyCustomer(_index) orderDelivered(_index) {
        Order storage order = orders[_index];
        emit OrderAccepted(_index, order.manufacturer, order.shipper, order.sinterer, order.customer);
        orders[_index].status = Status.Accepted;
    }

    function _10b_declineOrder(
        uint256 _index
    ) public onlyCustomer(_index) orderDelivered(_index) {
        Order storage order = orders[_index];
        emit OrderDeclined(_index, order.manufacturer, order.shipper, order.sinterer, order.customer);
        orders[_index].status = Status.Declined;
    }
}
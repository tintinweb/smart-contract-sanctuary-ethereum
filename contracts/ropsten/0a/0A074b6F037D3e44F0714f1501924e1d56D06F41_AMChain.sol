/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

pragma solidity ^0.4.25;

contract AMChain {

    enum Status { Created,
                  RequestShippingSinterer,
                  AcceptShippingSinterer,
                  CompleteShippingSinterer,
                  ReceivedShippingSinterer,
                  Sintered,
                  RequestReshippingManufacturer,
                  AcceptReshippingManufacturer,
                  CompleteReshippingManufacturer,
                  ReceivedReshippingManufacturer,
                  Checked,
                  RequestDeliveryCustomer,
                  AcceptDeliveryCustomer,
                  CompleteDeliveryCustomer,
                  ReceivedDeliveryCustomer,
                  Accepted,
                  Declined
                }

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

// 1. Manufacturing sequence

    event OrderCreated(
        uint256 index,
        address indexed manufacturer,
        address indexed shipper,
        address sinterer,
        address indexed customer
    );

    event OrderRequestShippingSinterer(
        uint256 index,
        address indexed manufacturer,
        address indexed shipper,
        address sinterer,
        address indexed customer
    );

// 2. Shipment to Sinterer sequence

    event OrderAcceptShippingSinterer(
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

    event OrderReceivedShippingSinterer(
        uint256 index,
        address indexed manufacturer,
        address indexed shipper,
        address sinterer,
        address indexed customer
    );

// 3. Sintering sequence

    event OrderSintered(
        uint256 index,
        address indexed manufacturer,
        address indexed shipper,
        address sinterer,
        address indexed customer
    );

    event OrderRequestReshippingManufacturer(
        uint256 index,
        address indexed manufacturer,
        address indexed shipper,
        address sinterer,
        address indexed customer
    );

// 4. Shipment back to Manufacturer sequence

    event OrderAcceptReshippingManufacturer(
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

    event OrderReceivedReshippingManufacturer(
        uint256 index,
        address indexed manufacturer,
        address indexed shipper,
        address sinterer,
        address indexed customer
    );

// 5. Quality control sequence

    event OrderChecked(
        uint256 index,
        address indexed manufacturer,
        address indexed shipper,
        address sinterer,
        address indexed customer
    );

    event OrderRequestDeliveryCustomer(
        uint256 index,
        address indexed manufacturer,
        address indexed shipper,
        address sinterer,
        address indexed customer
    );

// 6. Delivery to Customer sequence

    event OrderAcceptDeliveryCustomer(
        uint256 index,
        address indexed manufacturer,
        address indexed shipper,
        address sinterer,
        address indexed customer
    );

    event OrderCompleteDeliveryCustomer(
        uint256 index,
        address indexed manufacturer,
        address indexed shipper,
        address sinterer,
        address indexed customer
    );

    event OrderReceivedDeliveryCustomer(
        uint256 index,
        address indexed manufacturer,
        address indexed shipper,
        address sinterer,
        address indexed customer
    );

// 7. Customer decision sequence

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

// 1. Manufacturing sequence

    modifier orderCreated(uint256 _index) {
        require(orders[_index].status == Status.Created);
        _;
    }

    modifier orderRequestShippingSinterer(uint256 _index) {
        require(orders[_index].status == Status.RequestShippingSinterer);
        _;
    }

// 2. Shipment to Sinterer sequence

    modifier orderAcceptShippingSinterer(uint256 _index) {
        require(orders[_index].status == Status.AcceptShippingSinterer);
        _;
    }

    modifier orderCompleteShippingSinterer(uint256 _index) {
        require(orders[_index].status == Status.CompleteShippingSinterer);
        _;
    }

    modifier orderReceivedShippingSinterer(uint256 _index) {
        require(orders[_index].status == Status.ReceivedShippingSinterer);
        _;
    }

// 3. Sintering sequence

    modifier orderSintered(uint256 _index) {
        require(orders[_index].status == Status.Sintered);
        _;
    }

    modifier orderRequestReshippingManufacturer(uint256 _index) {
        require(orders[_index].status == Status.RequestReshippingManufacturer);
        _;
    }

// 4. Shipment back to Manufacturer sequence

    modifier orderAcceptReshippingManufacturer(uint256 _index) {
        require(orders[_index].status == Status.AcceptReshippingManufacturer);
        _;
    }

    modifier orderCompleteReshippingManufacturer(uint256 _index) {
        require(orders[_index].status == Status.CompleteReshippingManufacturer);
        _;
    }

    modifier orderReceivedReshippingManufacturer(uint256 _index) {
        require(orders[_index].status == Status.ReceivedReshippingManufacturer);
        _;
    }

// 5. Quality control sequence

    modifier orderChecked(uint256 _index) {
        require(orders[_index].status == Status.Checked);
        _;
    }

    modifier orderRequestDeliveryCustomer(uint256 _index) {
        require(orders[_index].status == Status.RequestDeliveryCustomer);
        _;
    }

// 6. Delivery to Customer sequence

    modifier orderAcceptDeliveryCustomer(uint256 _index) {
        require(orders[_index].status == Status.AcceptDeliveryCustomer);
        _;
    }

    modifier orderCompleteDeliveryCustomer(uint256 _index) {
        require(orders[_index].status == Status.CompleteDeliveryCustomer);
        _;
    }

    modifier orderReceivedDeliveryCustomer(uint256 _index) {
        require(orders[_index].status == Status.ReceivedDeliveryCustomer);
        _;
    }


// Call function

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

// 1. Manufacturing sequence

    function _I1_createOrder(
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

    function _I2_requestShippingSintererOrder(
        uint256 _index
    ) public onlyManufacturer(_index) orderCreated(_index) {
        Order storage order = orders[_index];
        emit OrderRequestShippingSinterer(_index, order.manufacturer, order.shipper, order.sinterer, order.customer);
        order.status = Status.RequestShippingSinterer;
    }

// 2. Shipment to Sinterer sequence

    function _II1_acceptShippingSintererOrder(
        uint256 _index
    ) public onlyShipper(_index) orderRequestShippingSinterer(_index) {
        Order storage order = orders[_index];
        emit OrderAcceptShippingSinterer(_index, order.manufacturer, order.shipper, order.sinterer, order.customer);
        order.status = Status.AcceptShippingSinterer;
    }

    function _II2_completeShippingSintererOrder(
        uint256 _index
    ) public onlyShipper(_index) orderAcceptShippingSinterer(_index) {
        Order storage order = orders[_index];
        emit OrderCompleteShippingSinterer(_index, order.manufacturer, order.shipper, order.sinterer, order.customer);
        order.status = Status.CompleteShippingSinterer;
    }

    function _II3_receivedShippingSintererOrder(
        uint256 _index
    ) public onlySinterer(_index) orderCompleteShippingSinterer(_index) {
        Order storage order = orders[_index];
        emit OrderReceivedShippingSinterer(_index, order.manufacturer, order.shipper, order.sinterer, order.customer);
        order.status = Status.ReceivedShippingSinterer;
    }

// 3. Sintering sequence

    function _III1_sinterOrder(
        uint256 _index,
        string memory _IPFS_CID
    ) public onlySinterer(_index) orderReceivedShippingSinterer(_index) {
        Order storage order = orders[_index];
        order.IPFS_CID = _IPFS_CID;                                                                         //update the CID due to new Sinterer informations/ documents
        emit OrderSintered(_index, order.manufacturer, order.shipper, order.sinterer, order.customer);
        orders[_index].status = Status.Sintered;
    }

    function _III2_requestReshippingManufacturerOrder(
        uint256 _index
    ) public onlySinterer(_index) orderSintered(_index) {
        Order storage order = orders[_index];
        emit OrderRequestReshippingManufacturer(_index, order.manufacturer, order.shipper, order.sinterer, order.customer);
        order.status = Status.RequestReshippingManufacturer;
    }

// 4. Shipment back to Manufacturer sequence

    function _IV1_acceptReshippingManufacturerOrder(
        uint256 _index
    ) public onlyShipper(_index) orderRequestReshippingManufacturer(_index) {
        Order storage order = orders[_index];
        emit OrderAcceptReshippingManufacturer(_index, order.manufacturer, order.shipper, order.sinterer, order.customer);
        order.status = Status.AcceptReshippingManufacturer;
    }

    function _IV2_completeReshippingManufacturerOrder(
        uint256 _index
    ) public onlyShipper(_index) orderAcceptReshippingManufacturer(_index) {
        Order storage order = orders[_index];
        emit OrderCompleteReshippingManufacturer(_index, order.manufacturer, order.shipper, order.sinterer, order.customer);
        order.status = Status.CompleteReshippingManufacturer;
    }

    function _IV3_receivedReshippingManufacturerOrder(
        uint256 _index
    ) public onlyManufacturer(_index) orderCompleteReshippingManufacturer(_index) {
        Order storage order = orders[_index];
        emit OrderReceivedReshippingManufacturer(_index, order.manufacturer, order.shipper, order.sinterer, order.customer);
        order.status = Status.ReceivedReshippingManufacturer;
    }

// 5. Quality control sequence

    function _V1_checkOrder(
        uint256 _index,
        string memory _IPFS_CID
    ) public onlyManufacturer(_index) orderReceivedReshippingManufacturer(_index) {
        Order storage order = orders[_index];
        order.IPFS_CID = _IPFS_CID;                                                                       //update the CID due to new Manufacturer informations/ documents
        emit OrderChecked(_index, order.manufacturer, order.shipper, order.sinterer, order.customer);
        orders[_index].status = Status.Checked;
    }

    function _V2_requestDeliveryCustomerOrder(
        uint256 _index
    ) public onlyManufacturer(_index) orderChecked(_index) {
        Order storage order = orders[_index];
        emit OrderRequestDeliveryCustomer(_index, order.manufacturer, order.shipper, order.sinterer, order.customer);
        order.status = Status.RequestDeliveryCustomer;
    }

// 6. Delivery to Customer sequence

    function _VI1_acceptDeliveryCustomerOrder(
        uint256 _index
    ) public onlyShipper(_index) orderRequestDeliveryCustomer(_index) {
        Order storage order = orders[_index];
        emit OrderAcceptDeliveryCustomer(_index, order.manufacturer, order.shipper, order.sinterer, order.customer);
        order.status = Status.AcceptDeliveryCustomer;
    }

    function _VI2_completeDeliveryCustomerOrder(
        uint256 _index
    ) public onlyShipper(_index) orderAcceptDeliveryCustomer(_index) {
        Order storage order = orders[_index];
        emit OrderCompleteDeliveryCustomer(_index, order.manufacturer, order.shipper, order.sinterer, order.customer);
        order.status = Status.CompleteDeliveryCustomer;
    }

    function _VI3_receivedDeliveryCustomerOrder(
        uint256 _index
    ) public onlyCustomer(_index) orderCompleteDeliveryCustomer(_index) {
        Order storage order = orders[_index];
        emit OrderReceivedDeliveryCustomer(_index, order.manufacturer, order.shipper, order.sinterer, order.customer);
        order.status = Status.ReceivedDeliveryCustomer;
    }

// 7. Customer decision sequence

    function _VII1_acceptOrder(
        uint256 _index
    ) public onlyCustomer(_index) orderReceivedDeliveryCustomer(_index) {
        Order storage order = orders[_index];
        emit OrderAccepted(_index, order.manufacturer, order.shipper, order.sinterer, order.customer);
        orders[_index].status = Status.Accepted;
    }

    function _VII2_declineOrder(
        uint256 _index
    ) public onlyCustomer(_index) orderReceivedDeliveryCustomer(_index) {
        Order storage order = orders[_index];
        emit OrderDeclined(_index, order.manufacturer, order.shipper, order.sinterer, order.customer);
        orders[_index].status = Status.Declined;
    }
}
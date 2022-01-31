/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

contract VendorConsignment {
    enum OrderState{PLACED, ACCEPTED, REJECTED, RECEIVED, RETURNED, CONSUMED}
    /*enum PartState{QC_PASSED, QC_FAILED, CONSUMED} */

    event LogManufacturerToOrderMapping(uint256[]);
    event LogVendorToOrderMapping(uint256[]);
    event LogOrderData(OrderData);

    struct OrderData {
        uint orderID;
        OrderState orderState;
        uint partType;
        uint partCount;
        uint timestampOrderPlaced;
        uint timestampOrderAccepted;
        uint timestampOrderReceived;
        uint timestampOrderConsumed;
    }
    
    uint orderID;
    OrderData[] listOfOrders; 
    mapping(uint => OrderData) public orderIDtoDataMapping;
    mapping(address => uint[]) public manufacturertoOrderMapping;
    mapping(address => uint[]) public vendortoOrderMapping;

    constructor() {
        orderID = 0;
    }

    function PlaceOrder(address vendor, uint partType, uint partCount) public 
    {
        require(msg.sender != address(0), "Address of manufacturer cannot be zero.");
        OrderData memory orderData;
        orderID = orderID + 1;
        orderData.orderID = orderID;
        orderData.orderState = OrderState.PLACED;
        orderData.partType = partType;
        orderData.partCount = partCount;
        orderData.timestampOrderPlaced = block.timestamp;
        uint[] storage listManOrders = manufacturertoOrderMapping[msg.sender];
        uint[] storage listVenOrders = vendortoOrderMapping[vendor];
        listManOrders.push(orderID);
        listVenOrders.push(orderID);
        listOfOrders.push(orderData);
        orderIDtoDataMapping[orderData.orderID] = orderData;
        manufacturertoOrderMapping[msg.sender] = listManOrders;
        vendortoOrderMapping[vendor] = listVenOrders;
        emit LogOrderData(orderData);
    }


    function manufacturerOrders() public view returns (OrderData[] memory)
    {
        return listOfOrders;
    }

    function OrdersbyManufacturerAddress(address manufacturer) public view returns (uint[] memory list)
    {
        uint[] memory listOrders = manufacturertoOrderMapping[manufacturer];
        // for(uint8 i = 0; i < listOrders.length; i++ ) {
        //     emit LogOrderData(orderIDtoDataMapping[listOrders[i]]);            
        // }        
        return listOrders;
    }

    function OrdersbyVendorAddress(address vendor) public returns (uint[] memory list)
    {
        uint[] memory listOrders = vendortoOrderMapping[vendor];
        for(uint8 i = 0; i < listOrders.length; i++ ) {
            emit LogOrderData(orderIDtoDataMapping[listOrders[i]]);                        
        }
        return listOrders;
    }

    function UpdateOrderByAddress(address payable vendor, bool ifVendor, uint orderId, bool status) public
    {
        OrderData memory orderData = orderIDtoDataMapping[orderId];
        require(msg.sender != address(0), "Address of input client cannot be zero.");
        
        if(ifVendor) {
            if(orderData.orderState == OrderState.PLACED) {
                if(status == true) {
                    orderData.orderState = OrderState.ACCEPTED;
                    orderData.timestampOrderAccepted = block.timestamp;
                } else {
                    orderData.orderState = OrderState.REJECTED;
                }
            }
        }
        else {
            if(orderData.orderState == OrderState.ACCEPTED) {
                if(status == true) {
                    orderData.orderState = OrderState.RECEIVED;
                    orderData.timestampOrderReceived = block.timestamp;
                }
            }
            else if(orderData.orderState == OrderState.RECEIVED) {
                if(status == true) {
                    orderData.orderState = OrderState.CONSUMED;
                    orderData.timestampOrderConsumed = block.timestamp;
                    uint amount = orderData.partCount*1;
                    uint penalty = 0;
                    if((orderData.timestampOrderAccepted + 1 days) > orderData.timestampOrderReceived ) {
                        penalty = 5;
                    }

                    processPayment(payable(vendor), amount-penalty);

                } else {
                    orderData.orderState = OrderState.RETURNED;
                }
            }
        }
        orderIDtoDataMapping[orderId] = orderData;
        emit LogOrderData(orderData);

    }

    // This is an internal function - which can be called only by the Contract
    function processPayment(address payable destinationAddress, uint amount) internal returns (bool success){
        destinationAddress.transfer(amount);
        return true;
    }

}
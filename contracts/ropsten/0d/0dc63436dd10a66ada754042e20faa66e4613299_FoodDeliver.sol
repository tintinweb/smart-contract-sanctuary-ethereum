/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract FoodDeliver {
    
    event NewOrder(string _oTime, string _cTime, string _dtime);
    event showBalance(address owner, uint balance);

    address private _dAddress;
    uint private _deliveryFee = 0.0001 ether;
    
    struct Order {
       string orderTime;
       string cookTime;
       string deliverTime;
    }
    
    Order[] public orders;
    
    mapping (uint => address) public orderToCustomer;
    mapping (address => uint) customerOrderCount;
    
    function payDeliveryFee(address _dAd) external payable {
        require(msg.value == _deliveryFee);
        _dAddress = _dAd;
    }
    
    function transferToDelivery() external {
        address payable _delivery = payable(_dAddress);
        _delivery.transfer(_deliveryFee);
        emit showBalance(_dAddress, _dAddress.balance);
    }

    function createOrder(string memory _oTime, string memory _cTime, string memory _dtime) public {
        orders.push(Order(_oTime, _cTime, _dtime));
        orderToCustomer[orders.length-1] = msg.sender;
        customerOrderCount[msg.sender]++;
        emit NewOrder(_oTime, _cTime, _dtime);
    }
    
    function getOrderLength() public view returns(uint) {
        return orders.length;
    }
    
    function getOrdersByCust(address _cust) external view returns(uint[] memory) {
        uint[] memory result = new uint[](customerOrderCount[_cust]);
        uint counter = 0;
        for (uint i = 0; i < orders.length; i++) {
          if (orderToCustomer[i] == _cust) {
            result[counter] = i;
            counter++;
          }
        }
        return result;
    }
}
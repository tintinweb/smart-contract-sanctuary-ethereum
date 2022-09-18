//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract ElectricityTrading_test {
    address c;

    // address c1;
    // address c2;
    // address c3;

    //bool _forward;

    constructor(address payable _c) payable {
        c = _c;
    }

    struct Nodes {
        address payable addr;
        uint256 power;
        int256 price;
        bool forward;
    }

    Nodes[] public nodes;
    mapping(address => int256) public addressToPrice;

    function addNodes(
        address payable _address,
        uint256 _power,
        int256 _price
    ) public payable {
        addressToPrice[_address] = _price;
        bool _forward = true;
        if (_price >= 0) {
            _forward = true;
        } else {
            _forward = false;
            _price = -_price;
        }
        nodes.push(
            Nodes({
                addr: _address,
                power: _power,
                price: _price,
                forward: _forward
            })
        );
    }

    function sendToContract() public payable {
        //c.transfer(msg.sender);
        payable(c).transfer(msg.value);
    }

    function contractToNode1(address c2, address c1) public payable {
        if (nodes[0].forward == true) {
            payable(c2).transfer(msg.value);
        } else if (nodes[0].forward == false) {
            payable(c1).transfer(msg.value);
        }
    }

    function contractToNode2(address c3, address c2) public payable {
        if (nodes[1].forward == true) {
            payable(c3).transfer(msg.value);
        } else if (nodes[1].forward == false) {
            payable(c2).transfer(msg.value);
        }
    }

    function contractToNode3(address c1, address c3) public payable {
        if (nodes[2].forward == true) {
            payable(c1).transfer(msg.value);
        } else if (nodes[2].forward == false) {
            payable(c3).transfer(msg.value);
        }
    }
}
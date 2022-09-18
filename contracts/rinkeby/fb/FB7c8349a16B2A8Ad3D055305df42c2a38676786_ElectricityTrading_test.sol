//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract ElectricityTrading_test {
    address c;

    struct Prosumers {
        address payable addr;
        int256 power;
        uint256 price;
        bool forward;
    }

    Prosumers[] public prosumers;
    mapping(address => int256) public address2power;

    function addProsumers(
        address payable _addr,
        int256 _power,
        uint256 _price
    ) public payable {
        address2power[_addr] = _power;
        bool _forward = true;
        if (_power < 0) {
            _forward = false;
            _power = -_power;
        }
        prosumers.push(
            Prosumers({
                addr: _addr,
                power: _power,
                price: _price,
                forward: _forward
            })
        );
    }

    function send_money() public payable {
        payable(c).transfer(msg.value);
    }
}
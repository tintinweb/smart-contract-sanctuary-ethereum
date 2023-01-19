/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Apolice {

    uint256 internal _number;
    uint256 internal _startDate;
    uint256 internal _endDate;
    uint256 internal _valueReceive;
    uint256 internal _valueSecure;
    string internal _paymentOption;
    string internal _name;
    string internal _document;
    address[] internal _productContract;

    constructor(
        uint256 number,
        uint256 startDate,
        uint256 endDate,
        uint256 valueReceive,
        uint256 valueSecure,
        string memory paymentOption,
        string memory name,
        string memory document,
        address[] memory productContract
    ){
        _number = number;
        _startDate = startDate;
        _endDate = endDate;
        _valueReceive = valueReceive;
        _valueSecure = valueSecure;
        _paymentOption = paymentOption;
        _name = name;
        _document = document;
        _productContract = productContract;
    }

    function getName () external view returns (string memory)  {
        return _name;
    }
}
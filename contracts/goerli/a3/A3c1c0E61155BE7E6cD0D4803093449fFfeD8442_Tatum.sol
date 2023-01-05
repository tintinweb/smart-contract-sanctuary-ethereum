// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

struct UserDetail {
    uint256 id;
    string customerId;
    string name;
    uint256 mobile;
    string uAddress;
    string country;
    string city;
}

struct CustomerTx {
    uint256 amount;
    string customerId;
    address from;
    uint256 date;
    uint256 status;
    string product_name;
    string product_code;
    uint256 product_price;
}

contract Tatum {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Only Owner can do this Action!");
        _;
    }

    mapping(address => string[]) public customers;
    mapping(uint256 => UserDetail) public userDetails;
    uint public userIndexing;
    mapping(address => CustomerTx[]) public customerTxs;

    function changeOwnerShip(address _newAddress) external onlyOwner {
        owner = _newAddress;
    }

    function addCustomerIds(string memory _customerId) external {
        customers[msg.sender].push(_customerId);
    }


    function addUserDetail(
        uint256 _id,
        string memory _customerId,
        string memory _name,
        uint256 _mobile,
        string memory _uAddress,
        string memory _country,
        string memory _city
    ) external {
        userIndexing++;

        UserDetail memory user;
        user.id = _id;
        user.customerId = _customerId;
        user.name = _name;
        user.mobile = _mobile;
        user.uAddress = _uAddress;
        user.country = _country;
        user.city = _city;

        userDetails[userIndexing] = user;
    }

    function addCustomerTx(
        uint256 _amount,
        string memory _customerId,
        address _from,
        uint256 _date,
        uint256 _status,
        string memory _product_name,
        string memory _product_code,
        uint256 _product_price
    ) external {
        CustomerTx memory cTx;
        cTx.amount = _amount;
        cTx.customerId = _customerId;
        cTx.from = _from;
        cTx.date = _date;
        cTx.status = _status;
        cTx.product_name = _product_name;
        cTx.product_code = _product_code;
        cTx.product_price = _product_price;

        customerTxs[msg.sender].push(cTx);
    }
}
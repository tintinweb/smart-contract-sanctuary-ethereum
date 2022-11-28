/**
 *Submitted for verification at Etherscan.io on 2022-11-28
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;


    contract Supplychain{

        address owner;
    
    constructor() {
        owner = msg.sender;
    }

    uint256 product_id=0;


    struct Product{
        uint256 id;
        string name;
        string price;
        string description;
        string supplier;
        string manufactura;
        string regulator;
        string logistics;
        string retailer;
        string client;
        uint idclient;
        uint256 timestamp;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    Product[] public products_list;
    Product private productInfo;

    mapping (uint256 => Product) public products;


    function AddProduct(
        string memory name,
        string memory price,
        string memory description,
        string memory supplier,
        string memory manufacturing,
        string memory regulator,
        string memory logistics,
        string memory retailer,
        string memory client,
        uint idclient) public payable
    {
        productInfo=Product(product_id,name,price,description,supplier,manufacturing,regulator,logistics,retailer, client, idclient, block.timestamp);
        products[product_id]=(productInfo);
        products_list.push(productInfo);
        product_id++;

    }

    function getProducts() public view returns(Product[] memory){

        return products_list ;
    }

    function findIndex (uint _id) internal view returns (uint) {

         for (uint i= 0; i < products_list.length; i++){
            if (products_list[i].id == _id) {
                return i;
            }
        }
        revert('Product not found');
    }

    function updateProduct (uint _id, 
        string memory _name, 
        string memory _price,
        string memory _description,
        string memory _supplier,
        string memory _manufacturing,
        string memory _regulator,
        string memory _logistics,
        string memory _retailer,
        string memory _client,
        uint _idclient) public {

        uint index = findIndex (_id);
        products_list[index].name = _name;
        products_list[index].price = _price;
        products_list[index].description = _description;
        products_list[index].supplier = _supplier;
        products_list[index].manufactura = _manufacturing;
        products_list[index].supplier = _supplier;
        products_list[index].regulator = _regulator;
        products_list[index].logistics = _logistics;
        products_list[index].retailer = _retailer;
        products_list[index].client = _client;
        products_list[index].idclient = _idclient;
    }



    }
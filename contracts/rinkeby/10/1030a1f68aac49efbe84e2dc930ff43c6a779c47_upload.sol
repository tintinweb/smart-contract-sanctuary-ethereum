/**
 *Submitted for verification at Etherscan.io on 2022-06-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract upload {

    struct Product {
        string product_number;
        string upload_date;
        string product_name;
        string Accounting_Subjects_Num;
        string Accounting_Subjects_Name;
        string product_info;
        string price;
    }

    //Enter the product_number to look up the product info
    mapping(string => Product) ProductMap;

    //A array that store all the data which users input
    Product[] public ProductArray;

    //A function that ask the users to input data
    function Add_Product_Info(string memory _product_number, string memory _upload_date, string memory _product_name, 
                              string memory _Accounting_Subjects_Num, string memory _Accounting_Subjects_Name, 
                              string memory _product_info, string memory _price) public {

        Product storage product = ProductMap[_product_number];
        product.product_number = _product_number;
        product.upload_date = _upload_date;
        product.product_name = _product_name;
        product.Accounting_Subjects_Num = _Accounting_Subjects_Num;
        product.Accounting_Subjects_Name = _Accounting_Subjects_Name;
        product.product_info = _product_info;
        product.price = _price;

        ProductArray.push(Product(_product_number, _upload_date, _product_name, _Accounting_Subjects_Num,
                                  _Accounting_Subjects_Name, _product_info, _price));
       
    }

    function Get_Product_Info(string memory _product_number) public view returns(string memory, string memory, string memory, string memory,
                                                                                 string memory, string memory, string memory) {
        return(ProductMap[_product_number].product_number, ProductMap[_product_number].upload_date, ProductMap[_product_number].product_name,
               ProductMap[_product_number].Accounting_Subjects_Num, ProductMap[_product_number].Accounting_Subjects_Name,
               ProductMap[_product_number].product_info, ProductMap[_product_number].price);
    }
}
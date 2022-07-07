/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract demo {

    struct Product {
        string tax_ID_number;  
        string voucher_number;
        string Total_turnover_last_year;
        string Total_carbon_emissions_last_year;
        string Estimated_carbon_emissions;
    }

    //Enter the product_number to look up the product info
    mapping(string => Product) ProductMap;

    //A array that store all the data which users input
    Product[] public ProductArray;

    //A function that ask the users to input data
    function Add_Product_Info(string memory _tax_ID_number, string memory _voucher_number, string memory _Total_turnover_last_year, 
                              string memory _Total_carbon_emissions_last_year, string memory _Estimated_carbon_emissions) public {

        Product storage product = ProductMap[_tax_ID_number];
        product.tax_ID_number = _tax_ID_number;
        product.voucher_number = _voucher_number;
        product.Total_turnover_last_year = _Total_turnover_last_year;
        product.Total_carbon_emissions_last_year = _Total_carbon_emissions_last_year;
        product.Estimated_carbon_emissions = _Estimated_carbon_emissions;

        ProductArray.push(Product(_tax_ID_number, _voucher_number, _Total_turnover_last_year, _Total_carbon_emissions_last_year,
                                  _Estimated_carbon_emissions));
       
    }

    function Get_Product_Info(string memory _tax_ID_number) public view returns(string memory, string memory, string memory, string memory,string memory) {
        return(ProductMap[_tax_ID_number].tax_ID_number, ProductMap[_tax_ID_number].voucher_number, ProductMap[_tax_ID_number].Total_turnover_last_year,
               ProductMap[_tax_ID_number].Total_carbon_emissions_last_year, ProductMap[_tax_ID_number].Estimated_carbon_emissions);
    }
}
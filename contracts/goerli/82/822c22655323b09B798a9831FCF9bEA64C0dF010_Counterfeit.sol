// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Counterfeit {

    struct Products {
        string name;
        string description;
        string image;
    }
    
    struct Company {
        address owner;
        string name;
        string description;
        string image;
        Products[] products;
        string[] images; 
    }

    mapping(uint256 => Company) public companies;
    uint256 numberOfCompanies = 0;

    function createCompany(address _owner, string memory _name, string memory _description, string memory _image) public returns(uint256) {

        Company storage company = companies[numberOfCompanies];

        company.owner = _owner;
        company.name = _name;
        company.description = _description;
        company.image = _image;

        numberOfCompanies++;

        return numberOfCompanies-1;
    }
    
    function addProduct(uint256 _id, string memory _name, string memory _description, string memory _image) public  {

        Company storage company = companies[_id];

        Products memory product = Products({
            name: _name,
            description: _description,
            image: _image
        });

        company.products.push(product);
        company.images.push(_image);
    }

    function getProducts(uint256 _id) public view returns(Products[] memory, string[] memory) {
        return(companies[_id].products, companies[_id].images); 
    }

    function getCompanies() public view returns(Company[] memory) {

        Company[] memory company = new Company[](numberOfCompanies);

        for(uint i=0; i < numberOfCompanies; i++) {
            Company storage item = companies[i];
            company[i] = item;
        }
        return company;
    } 
}
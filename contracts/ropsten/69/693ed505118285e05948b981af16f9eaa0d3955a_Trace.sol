/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
contract Trace {
    bool private lock = false;
    bool private close = false;
    uint private attr_number = 0;
    
	struct Product {
	    address owner;
        string name;
    }
    mapping (uint  => Product) Products;

    function putProduct(string memory _name) public{
        if(lock == false){
        		Product memory item = Product(msg.sender, _name);
        		Products[attr_number] = item;
        		attr_number = attr_number + 1;
        }
    }

    function getProduct(uint _attr_number) public view returns(address, string memory) {
        require(_attr_number < attr_number);
        Product memory item = Products[_attr_number];
        
		return (item.owner, item.name);
	}
    
    function getProductsCount() public view returns(uint){
	    return attr_number;
	}
    
}
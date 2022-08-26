/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// The Storefront Contract
contract Storefront {
    // define some state values to track our prices and stock
    // @NOTE: we'll track our prices in hundredths of Ether to avoid dealing with floats
    //        (e.g. like tracking cents vs dollars)
    mapping(string => uint256) public prices;
    mapping(string => uint256) public stock;

    // the name of our Storefront
    string public name;

    // the owner of the Storefront
    // @NOTE: this will be address of the wallet that deploys the contract
    address payable public owner;

    // define events for items being added / updated and purchased
    event ItemPurchased(string item, uint256 quantity);
    event ItemUpdated(string item, uint256 price, uint256 stock);

    // onlyOwner is a modifier to ensure some functions can only be called by the Storefront owner
    modifier onlyOwner() {
        // perform our owner check
        require(msg.sender == owner, "Nah uh - you are not the owner");

        // continue with the rest of the function
        _;
    }

    // constructor is called on 'deployment'
    constructor(string memory _name) {
        // set our Storefront name and owner
        name = _name;
        owner = payable(msg.sender);
    }

    // addItems allows the owner of the Storefront to add (or update) item prices + stock
    function addItems(string[] memory _items, uint256[] memory _prices, uint256[] memory _stock) public onlyOwner {
        // make sure we have the same number of elements for each parameter
        require(_items.length == _prices.length);
        require(_items.length == _stock.length);

        // iterate through each of our provided items
        for (uint256 i = 0; i < _items.length; i += 1) {
            // set our price and stock state
            prices[_items[i]] = _prices[i];
            stock[_items[i]] = _stock[i];

            // emit an event on update
            emit ItemUpdated(_items[i], _prices[i], _stock[i]);
        }
    }

    // purchase allows end users to buy a quantity of an item
    function purchase(string memory _item, uint256 _quantity) public payable {
        // make sure the we're actually buying something
        require(_quantity > 0, "No quantity specified");

        // and that we have enough stock
        // @NOTE: this would also be triggered if there is 0 stock (or the item is invalid)
        require(stock[_item] >= _quantity, "This item is not in stock");

        // and that the user is paying the correct amoount
        // @NOTE: this would be triggered when the user sends too much or too little
        require(prices[_item] * _quantity == msg.value, "Provided funds do not match current prices");

        // take away from our known stock
        stock[_item] -= _quantity;

        // emit an event on purchase
        emit ItemPurchased(_item, _quantity);
    }

    // withdraw allows the owner of the Storefront to have the current funds deposited into their account
    function withdraw() public onlyOwner {
        // actually transfer the funds from this contract to the owner
        owner.transfer(address(this).balance);
    }
}
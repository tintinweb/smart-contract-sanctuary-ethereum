/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract Buy{

    address public owner;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(owner == msg.sender, "not an owner!");
        _;
    }

    function pay() external payable{} //works

    function getBalance() public view returns(uint balance){ //works
        balance = address(this).balance;
    }

    function widthdrawAll() public onlyOwner{ //works
        payable(owner).transfer(address(this).balance);
    }

    uint indexForSells;
    mapping(uint => Item) indexForSellsAll;

    

    struct Item{
        uint index;
        uint itemPrice;
        uint delay;
        uint whenSale;
        string itemName;
        address itemSeller;
    }

    struct Index{
        uint totalPayments;
        mapping(uint => Item) ItemsIndexForSale;
    }

    mapping(address => Index) public ItemsAddressSeller;

    function sellItem(string memory _itemName, uint _itemPrice, uint _delay) public{

        uint paymentNum = ItemsAddressSeller[msg.sender].totalPayments;
        ItemsAddressSeller[msg.sender].totalPayments++;
        uint whenSaleOpen = block.timestamp + _delay;
        


        Item memory newItem = Item(
            indexForSells,
            _itemPrice,
            _delay,
            whenSaleOpen,
            _itemName,
            msg.sender
        );

        ItemsAddressSeller[msg.sender].ItemsIndexForSale[paymentNum] = newItem;
        indexForSellsAll[indexForSells] = newItem;
        indexForSells++;
        
    }

    function checkItem(address _address, uint _index) public view returns(Item memory){
        return ItemsAddressSeller[_address].ItemsIndexForSale[_index];
    }

    function checkItemAll(uint _index) public view returns(Item memory){
        return indexForSellsAll[_index];
    }

    function itemOwner(uint _index) public view returns(address){
        return indexForSellsAll[_index].itemSeller;
    }

    function whenSale(uint _index) public view returns(uint){
        uint diff = indexForSellsAll[_index].whenSale - block.timestamp;
        return diff;
    }

    function restartDelay(uint _index, uint _delay) public onlyOwner{
        indexForSellsAll[_index].whenSale = block.timestamp + _delay;
    }

    function buyItem(uint _index) public payable{
        require(block.timestamp > indexForSellsAll[_index].whenSale, "you are too early! sales are closed.");
        require(msg.value >= indexForSellsAll[_index].itemPrice, "not enough money!");
        if (msg.value > indexForSellsAll[_index].itemPrice){
            payable(msg.sender).transfer(indexForSellsAll[_index].itemPrice - msg.value);
        }
        payable(indexForSellsAll[_index].itemSeller).transfer(msg.value);
    }
}
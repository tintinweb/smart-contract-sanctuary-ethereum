/**
 *Submitted for verification at Etherscan.io on 2022-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
//import "./GetPrice.sol";

contract publishYourItem{

    bool internal locked;
    address owner;
    enum Status{Listed, Sold, Shipped, Received,Returned, Cancel, Completed}
    Status status;
    
    struct myItem{
        string brand;
        string model;
        string condition;
        string size;
        uint256 price;
        string NFCTag;
        Status itemStatus;
    } 
    event Log(address account, string Tag,string action, uint256 date);
    //Mappings***********************************************************************************************************************
    mapping(address=>myItem[]) public listOfItems;
    mapping(address=>uint)public balance;
    mapping(string=>address) public itemOwner;

    //Modifers***********************************************************************************************************************
    modifier hasBalance(uint256 amount, address sender) {
        require(balance[sender] >= amount, "Deposit more funds");
        _;
    }

    modifier onlyOwner(){
        require(msg.sender==owner, "Not the owner");
        _;
    }

    modifier onlyItemOwner(address _itemOwner, string memory _NFCTag){
        require(itemOwner[_NFCTag]==_itemOwner, "Not the item Owner");
        _;
    }

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    constructor(){
        owner=msg.sender;
    }

    //Public Functions************************************************************************************************************************
    function listItem(string memory _brand, string memory _model, string memory _size, uint256 _price, string memory _NFCTag)public onlyOwner{   
        require(_price>0, "Item price can't be 0.00");
        bytes memory bs = bytes(_NFCTag);
        require(bs.length>0, "NFCTag can't be empty");
        listOfItems[owner].push(myItem(_brand,_model,"New",_size,_price, _NFCTag, status)); 
        itemOwner[_NFCTag]=owner; 
        emit Log(owner, _NFCTag,"Listed", block.timestamp);        
    }

    function reListItem(uint _index)public onlyOwner{
        address _seller=owner;
        require (listOfItems[_seller][_index].itemStatus!=status, "Item not listed");
        listOfItems[_seller][_index].itemStatus=nextStatus(0);
    }

    function buyItem(address _seller, uint _itemPrice, uint _index)external payable hasBalance(_itemPrice, msg.sender) noReentrant{
        require (listOfItems[_seller][_index].itemStatus==status, "Item not listed");
            address _buyer=msg.sender;
            updateBalance(_seller, _buyer, _itemPrice);
            //nextStatus();
            listOfItems[_seller][_index].itemStatus=nextStatus(1);
            string memory _tag=listOfItems[_seller][_index].NFCTag;
            emit Log(_buyer, _tag,"Bought", block.timestamp);
            
            //Update this into a function
            delete itemOwner[_tag];
            itemOwner[_tag]=_buyer;        
    }


    function deposit()external payable returns(bool x){
        require(msg.value>0);
        balance[msg.sender]+=msg.value;
        x;
    }    

    function withdraw(uint _amount)external payable noReentrant() returns(bool x){
        address _user=msg.sender;
        require(balance[_user]>0 , "No funds to withdraw!");
        require(balance[_user]>=_amount," withdraw exced your balance");
        payable (_user).transfer(_amount);
        balance[_user]-=_amount;
        x;
    } 

    //External Item's Owner Functions***********************************************************************************************************************
    function updateItemPrice(string memory _NFCTag,uint _index, uint _newPrice)external onlyItemOwner(msg.sender, _NFCTag){
        listOfItems[msg.sender][_index].price=_newPrice;
        emit Log(msg.sender, _NFCTag,"Price Updated", block.timestamp);
    }

    function unlistItem(string memory _NFCTag, uint _index)external onlyItemOwner(msg.sender, _NFCTag){
        delete listOfItems[msg.sender][_index];
        delete itemOwner[_NFCTag];
        emit Log(msg.sender, _NFCTag,"Item has been removed", block.timestamp);
    }

    function cancelTx(string memory _NFCTag, uint _index)external onlyItemOwner(msg.sender, _NFCTag){
        address _seller=owner;
        address _buyer=msg.sender;
        uint _price=listOfItems[_seller][_index].price;
        require(listOfItems[_seller][_index].itemStatus==Status.Sold, "Item hasn't been sold");
        require(_seller!=_buyer, "Owner can't cancel");
        updateBalance(_buyer, _seller,_price);
        listOfItems[_seller][_index].itemStatus=nextStatus(5);
        emit Log(msg.sender, _NFCTag,"Transaction Cancel", block.timestamp);

        //Update this into a function
        delete itemOwner[_NFCTag];
        itemOwner[_NFCTag]=_buyer;          
    }

    //Internal Functions***********************************************************************************************************************
    function nextStatus(uint _d) internal view returns (Status){
        return Status(uint(status) +_d);
    }    

    function updateBalance(address _add, address _rest, uint _itemPrice)internal{
        balance[_add]+=_itemPrice;
        balance[_rest]-=_itemPrice;
    }

}
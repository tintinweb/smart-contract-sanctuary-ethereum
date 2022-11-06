// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;
import "./Ownable.sol";
import "./Items.sol";
contract ItemManager is Ownable{
     
    uint itemIndex;
    address owner;
    constructor() {
        owner=msg.sender;
    }
    
    enum supplyStatus {
     Created, Paid , Delivered
    }
    struct supply_Item {
        Item item; // from Item Contract
        string itemIdentity;
        uint itemPrice;
        supplyStatus statusIs;
    }
    mapping (uint => supply_Item) public items;
    
    event itemStatusStep(uint _itemNumber, uint _step,address _address);

    function createItem(string memory _itemIdentifier,uint _itemPrice) public onlyOwner{
        Item  _item=new Item (this,_itemPrice,itemIndex); //updating
        items[itemIndex].item=_item;
        items[itemIndex].itemIdentity= _itemIdentifier;
        items[itemIndex].itemPrice= _itemPrice;
        items[itemIndex].statusIs= supplyStatus.Created;
        emit  itemStatusStep (itemIndex,uint(items[itemIndex].statusIs),address(_item));
        itemIndex++;
    }
    function triggerPayment(uint _itemIndex) public payable {
        Item item=items[_itemIndex].item;
        require(msg.sender==address(item),"Only item can update it");
        require(item.amount()==msg.value,"Pay Full amount");
        require(items[_itemIndex].itemPrice >= msg.value,"pay Full payment");
        require( items[_itemIndex].statusIs==supplyStatus.Created,"item should be created");
        items[_itemIndex].statusIs= supplyStatus.Paid;
        emit  itemStatusStep (_itemIndex,uint(items[_itemIndex].statusIs),address(item));

    }
    function triggerdelivery(uint _itemIndex) public onlyOwner {
        Item item=items[_itemIndex].item;
        require( items[_itemIndex].statusIs==supplyStatus.Paid,"item payment should be paid first");
        items[_itemIndex].statusIs= supplyStatus.Delivered;
        emit  itemStatusStep (_itemIndex,uint(items[_itemIndex].statusIs),address(item));
    }



}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;
import "./ItemManager.sol";
contract Item{
    uint public amount;
    uint public paidAmount;
    uint public index;
    ItemManager itemManger;
    constructor(ItemManager _itemManger,uint _index,uint _amount){
        amount= _amount;
        index= _index;
        itemManger=_itemManger;

    }
    receive() external payable{
        require(msg.value==amount,"Not valid amount");
        require(paidAmount==0,"You have paid already for this");
        paidAmount += msg.value;
        (bool success,)=address(itemManger).call{value:amount}("");
        require(success,"Transaction failed");
    }
    fallback() external payable{
        
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract Ownable {
    address public _owner;

    constructor () {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return (msg.sender == _owner);
    }
}
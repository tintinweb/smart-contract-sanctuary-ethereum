// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
contract Ownable1{
    address payable _owner;
    constructor() {
        _owner = payable(msg.sender);
     }

    modifier onlyOwner() {
        require(msg.sender == _owner,"Not owner");
        _;
     }
     function isOwner() public view returns(bool) {
        return (msg.sender == _owner);
     }
}
contract Item {
    uint public priceInWei;
    uint public pricePaid;
    uint public index;

    ItemManager parentContract;

    constructor(ItemManager _itemManager, uint _priceInWei, uint _index) {
        priceInWei = _priceInWei;
        index = _index;
        parentContract = _itemManager;
    }

    receive() external payable {
        require (pricePaid == 0, "Already paid");
        require (priceInWei == msg.value,"Only full payment");
        pricePaid += msg.value;
        (bool success, ) = address(parentContract).call{value: msg.value}(abi.encodeWithSignature("triggerPayment(uint256)", index));
        require(success, "transaction was not successful");
    }

    fallback() external {}
}

contract ItemManager is Ownable1{

    enum SupplayChainState{Created, Paid, Delivered}

    struct S_Item {
        Item _item;
        string _identifier;
        uint _itemPrice;
        ItemManager.SupplayChainState _state;
    } 
    mapping (uint => S_Item ) public item;
    uint itemIndex;

    event SupplayChainStep (uint _itemIndex, uint _step, address _itemAddress);

    function createItem(string memory _identifier, uint _itemPrice) public onlyOwner{
        Item items = new Item(this, _itemPrice, itemIndex);
        item[itemIndex]._item = items;
        item[itemIndex]._identifier = _identifier;
        item[itemIndex]._itemPrice = _itemPrice;
        item[itemIndex]._state = SupplayChainState.Created;

        emit SupplayChainStep (itemIndex, uint(SupplayChainState.Created), address(items));
        itemIndex++;
    }

    function triggerPayment(uint _itemIndex) public payable {
        require (item[_itemIndex]._itemPrice == msg.value, "Only full payments");
        require(item[_itemIndex]._state == SupplayChainState.Created, "wrong state");
        item[_itemIndex]._state = SupplayChainState.Paid;
        emit SupplayChainStep(_itemIndex, uint(SupplayChainState.Paid), address(item[_itemIndex]._item));

    }

    function triggerDelivery(uint _itemIndex) public onlyOwner{
        require(item[_itemIndex]._state == SupplayChainState.Paid, "wrong state");
        item[_itemIndex]._state = SupplayChainState.Delivered;
        emit SupplayChainStep(_itemIndex, uint(SupplayChainState.Paid), address(item[_itemIndex]._item));
    }
}
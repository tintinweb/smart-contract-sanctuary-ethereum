/**
 *Submitted for verification at Etherscan.io on 2022-07-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Warehouse {

    address public manager;
    mapping(address => bool) private sellers;
    mapping(address => bool) private buyers;
    
    struct Product{
        uint id;
        address payable seller;
        string title;
        string description;
        uint price;
        uint inventory;
    }

    struct Prebooking{
        uint number;
        address payable buyer;
        uint productId;
        uint quantity;
        uint price;
    }

    uint productCount;
    mapping(uint => Product) public products;

    uint prebookingCount;
    mapping(uint => Prebooking) public prebookings;

    event newPrebookingEvent(uint number,address buyer);

    constructor(){
        manager = msg.sender;
        productCount = 0;
    }

    function addBuyer() public {
        buyers[msg.sender] = true;
    }

    function addSeller() public {
        sellers[msg.sender] = true;
    }

    function addProduct(string memory title,string memory description,uint price,uint inventory) public{
        assert(sellers[msg.sender] == true);

        productCount++;
        Product memory newProduct = Product({id:productCount,seller:payable(msg.sender),title:title,description:description,price:price,inventory:inventory});

        products[productCount] = newProduct;
    }
    
    function addPrebooking(uint productId,uint quantity) public payable{

        
        //take eth from wallet
        assert(msg.value == (products[productId].price * quantity));

        products[productId].seller.transfer(msg.value);

        assert(buyers[msg.sender] == true);
        assert(products[productId].inventory >= quantity);

        //add prebooking        
        prebookingCount++;
        uint number = genNonce();
        Prebooking memory newPrebooking = Prebooking({number:number,buyer:payable(msg.sender),productId:productId,quantity:quantity,price:(products[productId].price * quantity)});

        products[productId].inventory -= quantity;

        prebookings[number] = newPrebooking;

        emit newPrebookingEvent(number,msg.sender);
    }

    function cancelPrebooking(uint number) public payable {

        //refund eth
        assert(msg.value == (prebookings[number].price));

        prebookings[number].buyer.transfer(msg.value);
        
        uint productId = prebookings[number].productId;
        products[productId].inventory += prebookings[number].quantity;
        delete(prebookings[number]);
    }

    function getPrebooking(uint number) public view returns(Prebooking memory){
        return prebookings[number];
    }

    function genNonce() private view returns (uint) {
    uint rand = uint(keccak256(abi.encodePacked(block.timestamp)));
    return uint(rand % (10 ** 20));
    }
}
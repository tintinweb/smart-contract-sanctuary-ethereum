/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

// // SPDX-License-Identifier: MIT

pragma solidity ^0.8.15 ;

contract Ownable {

    address payable public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = payable(msg.sender);
    }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable newOwner) public isOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract Escrow is Ownable{

    uint public id = 1;

    struct productInfo{
        uint productId;
        address seller;
        string productName;
        string productDescription;
        string productCategory;
        uint price;
        string productImageURL;
        string sellerEmail;
        bool hasPurchased;
        uint256 timestamp;
    }

    struct cartInfo{
        uint productId;
        address sellerAddress;
        address buyerAddress;
        string productName;
        string productDescription;
        uint price;
        string productImageURL;
        string sellerEmail;
        uint timeToRevert;
        uint256 timestamp;
    }

    mapping(address => mapping(uint => uint)) public payment;
    mapping(address => mapping(uint => bool)) public isPaymentDone;
    
    productInfo[] product;
    cartInfo[] public cart;

    function addToBlockchain(string memory _productName, string memory _productDescription, string memory _productCategory, uint _price, string memory _productImageURL, string memory _sellerEmail) external{

        product.push(productInfo(id, msg.sender, _productName, _productDescription, _productCategory, _price, _productImageURL, _sellerEmail, false, block.timestamp));
        id++;
    } 

    function getAllProdcuts() external view returns(productInfo[] memory){
        return product;
    }

    function addToCart(uint _id, string memory _productName, string memory _productDescription, uint _price, string memory _productImageURL, string memory _sellerEmail, address _sellerAddress, uint _timeToRevert) payable external {
        cart.push(cartInfo(_id, _sellerAddress, msg.sender, _productName, _productDescription, _price, _productImageURL, _sellerEmail , _timeToRevert, block.timestamp));
        
        updateShop(_id);

        payment[msg.sender][_id] = _price;
    }

    function reteriveCart() external view returns(cartInfo[] memory){
        return cart; 
    }

    function removeFromCart(uint _id) public {
        uint index;

        for(uint i=0; i < cart.length; i++){
            if(cart[i].productId == _id ){
                index = i;

                break;
            }
        }

        for(uint i=index; i < cart.length -1; i++){
            cart[i] = cart[i+1];
        }

        
        cart.pop();
        // delete cart[index];
    }

    function deleteCard(uint _id) public {
        uint index;

        for(uint i=0; i < product.length; i++){
            if(product[i].productId  == _id){
                index = i;

                break;
            }
        }

        for(uint i=index; i < product.length -1; i++){
            product[i] = product[i+1];
        }

        product.pop();
    }

    function updateShop(uint _id) public {
        uint index;
        
        for(uint i=0; i < product.length; i++){
            if(product[i].productId == _id){
                index = i;
                // return;
            }
        }

        product[index].hasPurchased = true;
    }

    function getDeposits(address buyerAddress, uint _id) view public returns(uint amount, bool done){
        amount = payment[buyerAddress][_id];
        
        done = isPaymentDone[buyerAddress][_id];

        return (amount, done);
    }

    function transferToSeller(uint _id, address payable sellerAddress, address buyerAddress) external {
        uint amount = payment[buyerAddress][_id];
        uint fee = amount * 93 / 100;
        uint sellerAmount = amount - fee;
        
        owner.transfer(fee);
        sellerAddress.transfer(sellerAmount);
        
        // payment[msg.sender][sellerAddress] = 0;
        isPaymentDone[buyerAddress][_id] = true;
        
        removeFromCart(_id);
        deleteCard(_id);

    }

    function transferToBuyer(uint _id, address payable buyerAddress) external {
        uint amount = payment[buyerAddress][_id];

        buyerAddress.transfer(amount);

        isPaymentDone[buyerAddress][_id] = true;

        removeFromCart(_id);
        deleteCard(_id);
    }

    function contractAmount() view external returns(uint) {
        return address(this).balance;
    }

    function getSenderAddress() view external returns(address){
        return msg.sender;
    }

    // function confirm() public {
        
    // }
}
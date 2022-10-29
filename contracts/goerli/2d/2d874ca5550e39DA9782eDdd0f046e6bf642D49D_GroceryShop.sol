/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract GroceryShop {
    
    address payable owner; 
    address buyerAddress;


    uint256 breadCount;
    uint256 eggCount;
    uint256 jamCount;
    uint256 purchaseIdSeq = 0;
    uint256 price = 0.01 ether;
    uint256 totalAmount = 0;    

    enum GroceryType {
        Bread,
        Egg,
        Jam
    }

    //struct Purchase Info
    struct PurchaseMemo{
        address buyer;
        GroceryType groceryType;
        uint256 noOfUnits;
    }

    mapping (uint256 => PurchaseMemo) purchaseMemos;

    //enum Object
    GroceryType groceryType;

    // Event triggered for every noOfUnits update
    event Added(
        GroceryType groceryType, 
        uint256 noOfUnits
    );

    // Event triggered for every new Purchase
    event Bought(
        uint256 purchaseId,
        GroceryType groceryType,
        uint256 noOfUnits
    );    
    

    constructor(uint256 _breadCount, uint256 _eggCount, uint256 _jamCount){
        breadCount = _breadCount;
        eggCount = _eggCount;
        jamCount = _jamCount;

        //save the sender of this transaction as owner
        owner = payable(msg.sender);
    }

    function add(GroceryType _groceryType, uint _count) external onlyOwner {

        if(_groceryType == GroceryType.Bread){
            breadCount += _count;
        }
        else if (_groceryType == GroceryType.Egg){
            eggCount += _count;
        }
        else{
            jamCount +=  _count;
        }

        emit Added(_groceryType, _count);
    }

    function buy(GroceryType _groceryType, uint256 _count) payable external {

        require(_count > 0, "cannot buy 0 units");

        if(_groceryType == GroceryType.Bread){
            require(breadCount > 0, "Bread not available");
            require(breadCount > _count, "Not enough bread available");

            breadCount -= _count;
        }
        else if (_groceryType == GroceryType.Egg){
            require(eggCount > 0, "Egg not available");
            require(eggCount > _count, "Not enough egg available");

            eggCount -= _count;
        }
        else{
            require(jamCount >0, "Jam not available");
            require(jamCount > _count, "Not enough Jam available");

            jamCount -=  _count;
        }

        //All checks passed proceed with purchase
        purchaseIdSeq ++;
        //Total purchase value
        totalAmount += (_count * price);
        //Address who initiated the purchase
        buyerAddress = msg.sender;

        // Make Purchase
        purchaseMemos[purchaseIdSeq] = PurchaseMemo(buyerAddress,_groceryType,_count);

        emit Bought(purchaseIdSeq, _groceryType, _count);
    }

    function withdraw() payable external onlyOwner {
        payable(msg.sender).call{value: totalAmount};
       
        //reset totalAmount to 0 after withdraw
        totalAmount = 0;
    }

    function cashRegister(uint256 _purchaseId) view external returns (address buyer, GroceryShop.GroceryType item, uint256 count){       
        PurchaseMemo memory tempPurchasememo = purchaseMemos[_purchaseId];        
        return (tempPurchasememo.buyer, tempPurchasememo.groceryType, tempPurchasememo.noOfUnits);
    }    


    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");        
        _;
    }
    
}
/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract GroceryS{

    address owner;
    uint breadCount;
    uint eggCount;
    uint jamCount;
    uint groceryPrice = 0.1 ether;
    uint PurchaseId;

    enum GroceryType {None, Bread, Egg, Jam}

    struct Groceries {
        GroceryType groceryType;
        uint count;
    }

    Groceries public bread;
    Groceries public egg;
    Groceries public jam;

    struct Transaction {
        address user;
        GroceryType groceryType;
        uint count;
    }

    Transaction public transactions;
    
    //mapping(uint => Transaction) cashRegister;



    event Added(GroceryType groceryType, uint count);
    event Bought(uint PurchaseId, GroceryType groceryType, uint _amount);

    constructor (uint _breadCount, uint _eggCount, uint _jamCount) {
        owner = msg.sender;
        breadCount = _breadCount;
        eggCount = _eggCount;
        jamCount = _jamCount;

        bread = Groceries(GroceryType.Bread, _breadCount);
        egg = Groceries(GroceryType.Egg, _eggCount);
        jam = Groceries(GroceryType.Jam, _jamCount);

    }

    function addGrocery(GroceryType _groceryType, uint _count) public {
        require(msg.sender == owner, "Only the Owner can add Food");
        

        // we can add a modifier here? 
        if(_groceryType == GroceryType.Bread) {
            bread.count += _count;
        } else if(_groceryType == GroceryType.Egg) {
            egg.count += _count;
        } else if(_groceryType == GroceryType.Jam) {
            jam.count += _count;
        }
        
        emit Added(_groceryType, _count);

    }
   
    //function getBalance() external view returns (uint) {
    //    return address(this).balance;
    //}

        // Function to withdraw all Ether from this contract.
    function withdrawO() public {
        // get the amount of Ether stored in this contract
        uint amount = address(this).balance;

        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    function buyGrocery(GroceryType _groceryType, uint _amount) external payable {
        // we can add a modifier here? 
        require(msg.value == _amount * groceryPrice);

        if(_groceryType == GroceryType.Bread) {
            bread.count -= _amount;
            PurchaseId += 1;
        } else if(_groceryType == GroceryType.Egg) {
            egg.count -= _amount;
            PurchaseId += 1;
        } else if(_groceryType == GroceryType.Jam) {
           jam.count -= _amount;
           PurchaseId += 1;
        }

        emit Bought(PurchaseId, _groceryType, _amount);

        // renew
        transactions.user = msg.sender;
        transactions.groceryType = _groceryType;
        transactions.count = _amount;


        //transactions.push(Transaction({user: msg.sender, groceryType: _groceryType, count: _amount}));
    }

    //function transreturn(uint _purchid) public view returns(address, GroceryType, uint) {
    //    return (cashRegister[_purchid].user, cashRegister[_purchid].groceryType, cashRegister[_purchid].count);
    //}





}
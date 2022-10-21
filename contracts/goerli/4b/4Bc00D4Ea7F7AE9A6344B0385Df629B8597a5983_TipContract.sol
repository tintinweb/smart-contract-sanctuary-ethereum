// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//106357

error notOwner();

contract TipContract{
    
    // we need only 10 accounts
    uint256 private index_of_payers =0;

    // calculted tip
    uint256 private tiptip;

    //events
    event TipEvent(uint256 tiptip, string message);

    // for manager and people addresses
    address payable private  manager;
    address payable[] bill_payers;

    // to keep the track of already payed person
    mapping(address=>bool)exists;

    // the person who will deploy this contract will be the manager
    constructor(){
        manager = payable(msg.sender); 
    }

    // only owner can access
    modifier onlyOwner(){
        // require(msg.sender == manager, "Manager can't Pay");
         if(msg.sender == manager){
            revert notOwner();
        }
        _;
    }

    // calculating the tip each person have to give
    function calculate_tip(uint256 _bill_price, uint256 _tip_per,uint256 _no_of_people)public returns (uint256){

        require((_bill_price * _tip_per) >= 10000);
        tiptip = (_bill_price * _tip_per / 10000) / _no_of_people;
        emit TipEvent(tiptip , "OUR CALCULATED TIP IN WEI");
        return tiptip;
    }

    // a function to check if the person already have payed the tip or not
    function AlreadyPayed()private view returns(bool){
       if(exists[msg.sender]==true){
           return true;
       }
       else{
           return false;
       }
    }

    // function for payers to pay tip
    function Pay_Tip()public payable onlyOwner{
        require(AlreadyPayed() == false, "Sorry! You have already payed.");
        require(msg.value == tiptip, "Please you are required to pay the exact amount of tip no more , no less.");
        require(index_of_payers <= 9,"No of Payers are full");

        bill_payers.push(payable(msg.sender));
        exists[msg.sender] = true;
        index_of_payers++;
    }

    // this function will send all the money to the manager's acc
    function Transfer_to_Manager()public  {
        manager.transfer(address(this).balance);
    }

    //getter functions
    function getTip() public view returns (uint256) {
        return tiptip;
    }
}
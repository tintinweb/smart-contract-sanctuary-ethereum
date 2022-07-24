/**
 *Submitted for verification at Etherscan.io on 2022-07-22
*/

pragma solidity ^0.8.0;

contract DucthAuction {

uint public immutable startPrice;
string public itemName;
uint private discountRate;
uint public startDate;
uint public duration;
uint public endDate;
bool public Sold;




    constructor(string memory _itemName, uint _startPrice, uint _discountRate) {

    itemName = _itemName;
    startPrice = _startPrice;
    discountRate=_discountRate;
    startDate = block.timestamp;
    duration = 7 days;
    endDate = startDate + duration;

    }

    modifier notStopped() {
        require(Sold==false);
        _;
    }

    function checkPrice() public view notStopped returns(uint) {
        return startPrice-(block.timestamp-startDate);
    }

    function buy() public payable notStopped {

        require(msg.value >= checkPrice()); 
        address payable buyer = payable(msg.sender);
        uint refund = msg.value - checkPrice();
        buyer.transfer(refund);
        Sold=true;
    }


    function checkBalance() public view returns(uint) {
        return address(this).balance;
    }


receive() external payable  {

}
}
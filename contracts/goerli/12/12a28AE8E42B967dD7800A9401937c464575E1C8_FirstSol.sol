/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

pragma solidity ^0.4.24;

contract FirstSol {

    address private owner;

    // An event sent when funds are received.
    event Funded(uint new_balance);
    // An event sent when a spend is triggered to the given address.
    event Withdrawn(address to, uint transfer);

    constructor() public payable {
        owner = msg.sender;
    }

    // The fallback function for this contract.
    function() public payable  {
        emit Funded(address(this).balance);
    }

    modifier onlyOwner() {
      require(msg.sender == owner, "Operation only for the owner!");
      _;
    }

    //get the current owner address
    function getOwner() public view returns(address) {
        return owner;
    }

    //withdraw ETH to the destination
    function withdraw(address destination, uint256 value) public onlyOwner {
        //check amount
         require(address(this).balance >= value && address(this).balance > 0, "balance or widthdraw value invalid");

        //value 0 means withdraw all
        if (value == 0) {
            value = address(this).balance;
        }

        //transfer will throw if fails
        destination.transfer(value);
        emit Withdrawn(destination, value);
    }

    //destroy this contract and release some gas
    function destroyContract() public onlyOwner { 
        //transfer ether if any
        if(address(this).balance >0) {
            owner.transfer(address(this).balance);
        }
        selfdestruct(owner); 
    }
}
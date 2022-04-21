/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

pragma solidity ^0.8.10;

contract InfinityTest {
    event Received(address, uint);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    event LogTranser(address sender,address receiver, uint amount);

    // Payable address can receive Ether
    address payable public owner;

    // Payable constructor can receive Ether
    constructor() payable {
        owner = payable(msg.sender);
    }

    modifier isOwner() {
        require(msg.sender == owner,"ERRORE - Non puoi cambiare owner se non sei l'owner");
        _;
    }
    // REMEMBER: At the end of the modifier put the "_;"

    modifier hasFunds(uint amount) {
        require(msg.value == amount,"ERRORE - Fondi errati inserire la somma esatta");
        _;
    }

    function changeOwner(address payable newOwner) public isOwner(){
        owner = newOwner;
    }

    function retrieveBalance() public view returns (uint) {
        return address(this).balance;
    }

    function directTransferFromMe(address payable to,uint amount) public payable  hasFunds(amount) isOwner(){
        this.deposit();
        (bool success, ) = to.call{value: amount}("");
        require(success, "Failed to send Ether");
        emit LogTranser(msg.sender,to,amount);
    }

    // ORIGINALS EXAMPLE FUNCTIONS
    // Function to deposit Ether into this contract.
    // Call this function along with some Ether.
    // The balance of this contract will be automatically updated.
    function deposit() public payable {}

    // Call this function along with some Ether.
    // The function will throw an error since this function is not payable.
    function notPayable() public {}

    // Function to withdraw all Ether from this contract.
    function withdraw() public isOwner(){
        // get the amount of Ether stored in this contract
        uint amount = address(this).balance;

        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    // Function to transfer Ether from this contract to address from input
    function transfer(address payable _to, uint _amount) public isOwner(){
        // Note that "to" is declared as payable
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }
}
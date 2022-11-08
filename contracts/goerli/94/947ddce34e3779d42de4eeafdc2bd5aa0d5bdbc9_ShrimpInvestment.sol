/**
 *Submitted for verification at Etherscan.io on 2022-11-08
*/

pragma solidity ^0.8.7;

contract ShrimpInvestment {

    address owner;
    uint tuesday930 = 1667928600;
    mapping (address => bool) private hasCalled;
    mapping (address => uint) private given;
    
    event wasCalled(uint increase, address person);

    constructor() {
        owner = msg.sender;
        hasCalled[0x83CAAFb813B443fB3fC94A62988665c001a99B05] = true;
        hasCalled[0x74867FBC6e62Fb01961ad90489617872E05bDdbD] = true;
        hasCalled[0xefb732CA174912587c6f48704eBa3654F53e76de] = true;
        // remix account below
        hasCalled[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = true;
    }

    function get_balance() public view returns (uint) {
        return address(this).balance;
    }

    function deposit() public payable  {
        require (msg.sender == owner);
        require (msg.value == 0.5 ether);
        emit wasCalled(msg.value, msg.sender);
        given[msg.sender] += msg.value;
    }
    
    // // can only be called once per address with a max investment threshold 0.1 ETH
    function invest() public payable {
        require(hasCalled[msg.sender] == true); // can only call once
        require(msg.value <= 0.1 ether); // must be <= 0.1 ether
        emit wasCalled(msg.value, msg.sender);
        given[msg.sender] += msg.value; // add how much they have invested
        hasCalled[msg.sender] = false; // can only call one
    }

    function get_interest() public {
        // address.transfer(amount) tranfers amount (in ether) to the account address
        require (block.timestamp > tuesday930);

        payable(msg.sender).transfer(given[msg.sender]*2);
    }
}
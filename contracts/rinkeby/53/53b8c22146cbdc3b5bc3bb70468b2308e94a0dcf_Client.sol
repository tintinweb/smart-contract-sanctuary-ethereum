/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

pragma solidity ^0.8.0;

interface HalbornSeraph {
    function checkUnblocked(bytes4, bytes calldata, uint256) external;
    function checkIntegrity(bytes4, bytes calldata, uint256) external;
}

contract Client {

    HalbornSeraph seraph_address;
    Client client_address;
    address owner;

    modifier withSeraph() {
        seraph_address.checkUnblocked(msg.sig, msg.data, 0);
        _;
        seraph_address.checkIntegrity(msg.sig, msg.data, 0);
    }

    modifier withSeraphPayable() {
        seraph_address.checkUnblocked(msg.sig, msg.data, msg.value);
        _;
        seraph_address.checkIntegrity(msg.sig, msg.data, msg.value);
    }

    constructor (){
    }

    //////  TESTING PURPOSE
    function devSetSeraph (address seraph) public{
        owner = msg.sender;
        seraph_address = HalbornSeraph(seraph);
    }
    function devSetClient (address client) public{
        client_address = Client(client);
    }
    //////  TESTING PURPOSE

    function test() public withSeraph() {
        // token.totalSupply();
    }

    function test1() public payable withSeraph() {
        client_address.test();
    }

    function test2(uint256 v) public withSeraph() {

    }

    function test3() public payable withSeraphPayable() {
        client_address.test();

    }

    function test4() external payable withSeraph() {
        client_address.test2(100);
        client_address.test3();

    }

}
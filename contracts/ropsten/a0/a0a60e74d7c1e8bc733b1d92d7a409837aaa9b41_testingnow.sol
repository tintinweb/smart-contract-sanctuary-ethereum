// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ownable.sol";

contract testingnow is Ownable {

    string message = "how to";

    function read() public pure returns(bytes32) {

        return keccak256("setPublicSale(bool)");
    }

    function balance() public view returns(uint) {
        return address(this).balance;
    }
    
    function own() public view returns(address){
        return owner;
    }
    
    function withdraw() public onlyOwner {
        owner.call{ value:address(this).balance }("");
    }
    
    function write(string memory _message) public payable {
        require(msg.value == 0.1 ether);
        message = _message;
    }
}
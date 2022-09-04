/**
 *Submitted for verification at Etherscan.io on 2022-09-04
*/

pragma solidity ^0.8.16;


contract TestContract{

    uint max_supply;
    string name;
    string base_URI;
    address owner;

    constructor(uint _max_supply, string memory _name ){
        max_supply = _max_supply;
        name = _name;
        owner = msg.sender;
    }

    function f_owner() public view returns (address) {
        return owner;
    }

    function f_supply() public view returns (uint) {
        return max_supply;
    }

    function f_name() public view returns (string memory) {
        return name;
    }

    function set_URI(string memory _uri) public {
        require(msg.sender == owner, "not owner");
        base_URI = _uri;
    }


}
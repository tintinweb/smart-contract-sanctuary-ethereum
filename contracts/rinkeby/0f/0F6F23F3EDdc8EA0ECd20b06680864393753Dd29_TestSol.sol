/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

pragma solidity ^0.8.0;

contract TestSol {
    address owner;
    mapping(string => string) companies;

    constructor() {
        owner = msg.sender;
    }
    modifier _ownerOnly(){
        require(msg.sender == owner);
        _;
    }

    function pushCompany(string calldata _name, string calldata _data) public {
        companies[_name] = _data;
    }

    function getCompnayVal(string calldata _name) public _ownerOnly view returns (string memory) {
        return string(companies[_name]);
    }

    function changeOwner (address _add) public _ownerOnly {
        owner = _add;
    }

    function isOwner() public view returns(bool) {
        return msg.sender == owner;
    }
}
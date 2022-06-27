/**
 *Submitted for verification at Etherscan.io on 2022-06-27
*/

pragma solidity ^0.8.0;

contract MyList{

    string public name;
    string[] public items;

    constructor(string memory _name) {
        name = _name;
    }

    function getListName() public view returns (string memory) {
        return name;
    }

    function getItems() public view returns (string[] memory) {
        return items;
    }

    function addItem(string memory itemContent) external {
        items.push(itemContent);
    } 
}
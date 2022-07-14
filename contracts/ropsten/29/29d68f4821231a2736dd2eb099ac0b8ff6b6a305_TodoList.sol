/**
 *Submitted for verification at Etherscan.io on 2022-07-13
*/

pragma solidity 0.5.4;

contract TodoList {
    string[] private list;

    // Emitted when the storeda new item is added to the list
    event ItemAdded(string item);

    // Adds a new item in the list
    function addItem(string memory newItem) public payable {
        list.push(newItem);
        emit ItemAdded(newItem);
    }

    // Gets the item from the list according to index
    function getListItem(uint256 index)
        public
        view
        returns (string memory item)
    {
        return list[index];
    }
}
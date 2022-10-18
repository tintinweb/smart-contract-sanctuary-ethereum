/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

pragma solidity >=0.4.16 <0.9.0;

contract Todo {
    struct TodoItem {
        address owner;
        uint256 id;
        string title;
        string content;
        uint256 createdAt;
        uint256 updateAt;
        bool status;
    }

    mapping(uint256 => TodoItem) todoList;

    mapping(address => uint256[]) todoIdByUser;

    modifier isOwner(uint256 id) {
        require(msg.sender == todoList[id].owner, 'khong phai owner');
        _;
    }

    modifier isExist(uint256 id) {
        require(!(todoList[id].owner == address(0)), 'id khong ton tai');
        _;
    }

    function addTodoItem(uint256 id, string memory title, string memory content, bool status) external {
        TodoItem memory item = TodoItem(msg.sender, id, title, content,block.timestamp, block.timestamp, status);
        todoList[id] = item;
        todoIdByUser[msg.sender].push(id);
    }

    function getTodoListIdByAddress(address userAddress) public view returns(uint256[] memory) {
        return todoIdByUser[userAddress];
    }

    function getTodoItemById(uint256 id) public view returns(TodoItem memory) {
        return todoList[id];
    }

    function removeTodoItem(uint256 id) external  isExist(id) isOwner(id) {
        delete todoList[id];

        for(uint256 i = 0; i < todoIdByUser[msg.sender].length; i++) {
            if(todoIdByUser[msg.sender][i] == id) 
                delete todoIdByUser[msg.sender][i];
        }
    }
}
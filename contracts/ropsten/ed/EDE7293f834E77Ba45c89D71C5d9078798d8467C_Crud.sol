/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

pragma solidity 0.8.0;

contract Crud {
    struct User {
        uint256 id;
        string name;
    }
    User[] public users;
    uint256 public nextId = 1;

    function create(string memory name) public {
        users.push(User(nextId, name));
        nextId++;
    }

    function read(uint256 id) public view returns (uint256, string memory) {
        uint256 i = find(id);
        return (users[i].id, users[i].name);
    }

    function update(uint256 id, string memory name) public {
        uint256 i = find(id);
        users[i].name = name;
    }

    function destroy(uint256 id) public {
        uint256 i = find(id);
        delete users[i];
    }

    function find(uint256 id) internal view returns (uint256) {
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i].id == id) {
                return i;
            }
        }
        revert("User does not exist!");
    }
}
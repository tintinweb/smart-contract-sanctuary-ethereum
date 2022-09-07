//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "./BinaryTree.sol";

contract Maze is BinaryTree{

    //require for winners
    //limit number of iterations
    constructor(){
        owner = msg.sender;
    }

    event Winner(address);
    event Lost(address);

    mapping (address => Player) public Players;

    struct Player{
        uint256 tries;
        Node currentNode;
        Node[] path;
        bool isPlaying;
    }
    bool private isConstructed = false;
    
    enum Directions {
        Left,
        Right,
        Back
    }

    uint256 private Treasure = 0;

    //Node public node ;

     function ConstructTree() public {
         require(!isConstructed,"Maze is build");
        insert(5);
        insert(4);
        insert(8);
        insert(6);
        insert(7);
        insert(9);
        insert(1);
        insert(3);
        isConstructed = true;
    }

    function iterateTree(Directions direction) public{
        require(Players[msg.sender].isPlaying,"You should start a game");
        Node[] storage path = Players[msg.sender].path;
        if(direction == Directions.Right){
            require(Players[msg.sender].currentNode.right != bytes32(0),"Right is blocked");
            Players[msg.sender].currentNode = tree[Players[msg.sender].currentNode.right];
            path.push(Players[msg.sender].currentNode);
            
        }else{
            if(direction == Directions.Left)
            {
                require(Players[msg.sender].currentNode.left != bytes32(0),"Left is blocked");
                Players[msg.sender].currentNode = tree[Players[msg.sender].currentNode.left];
                path.push(Players[msg.sender].currentNode);
            }else{
                require(path.length > 1,"You can't go back");
                path.pop();
                Players[msg.sender].currentNode = path[path.length - 1];
            }
        }
        checkWinner();
        Players[msg.sender].tries++;
        if(Players[msg.sender].tries == (uint256)(getTreeSize() * 75)/100){
            stopGame();
            emit Lost(msg.sender);
        }
    }

    function checkWinner() internal{
        if(Players[msg.sender].currentNode.value == Treasure){
            Players[msg.sender].isPlaying = false;
            payable(msg.sender).transfer(5 * 10 ** 15);
            emit Winner(msg.sender);
        }
    }
    function setTreasure(uint256 treasure) onlyOwner public{
        Treasure = treasure;
    }
    function startGame() public payable {
        require(isConstructed,"Maze is not constructed");
        require(Treasure != 0,"Treasure is not set");
        require(msg.value >= 5 * 10 ** 15,"You should pay 0.005 eth to play");
        require(!Players[msg.sender].isPlaying,"Game is in progress");
        Players[msg.sender].isPlaying = true;
        Players[msg.sender].currentNode = tree[rootAddress];
        Players[msg.sender].path.push(Players[msg.sender].currentNode);
    }

    function stopGame() public{
        require(Players[msg.sender].isPlaying,"Game is stoped");
        Players[msg.sender].isPlaying = false;
        Players[msg.sender].currentNode = tree[rootAddress];
        delete Players[msg.sender].path;
    }
    function GetNode() public view returns(uint256){
        return Players[msg.sender].currentNode.value;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;
import "@openzeppelin/contracts/utils/Strings.sol";
contract BinaryTree {
    struct Node {
        uint256 value;
        bytes32 left;
        bytes32 right;
    }
    address public owner;
    modifier onlyOwner{
        require(
            msg.sender == owner
        );
        _;
    }
    mapping (bytes32 => Node) public tree;
    
    bytes32 public rootAddress;

    // inserts
    function insert(uint256 value) onlyOwner public {
        Node memory root = tree[rootAddress];
        // if the tree is empty
        if (root.value == 0) {
            root.value = value;
            root.left = 0;
            root.right = 0;
            tree[0] = root;
            rootAddress = generateId(value, 0);
            tree[rootAddress] = root;
        } else {
            // if the tree is not empty
            // find the correct place to insert the value
            insertHelper(value, rootAddress);
        }
    }

    // helper function for insert
    function insertHelper(uint256 value, bytes32 nodeAddress) internal {
        // Parent node 
        Node memory node = tree[nodeAddress];

        // if the value is less than the current node, insert it to the left
        // else, insert it to the right
        if (value < node.value) {
            // if the value is less than the current node
            // check if the left node is empty
            if (node.left == 0) {
                // if the left node is empty
                // insert the value
                insertNode(value, nodeAddress, 0);
            } else {
                // if the left node is not empty
                // recursively call the function
                insertHelper(value, node.left);
            }
        } else {
            // if the value is greater than the current node
            // check if the right node is empty
            if (node.right == 0) {
                // if the right node is empty
                // insert the value
                insertNode(value, nodeAddress, 1);
            } else {
                // if the right node is not empty
                // recursively call the function
                insertHelper(value, node.right);
            }
        }
    }

    // inserts a node
    function insertNode(uint256 value, bytes32 nodeAddress, uint256 location) internal {
        Node memory parentNode = tree[nodeAddress];
        bytes32 nodeId = generateId(value, nodeAddress);
        if (location == 0) {
            // if the value is less than the current node
            parentNode.left = nodeId;
        } else {
            // if the value is greater than the current node
            parentNode.right = nodeId;
        }

        // update the tree
        tree[nodeAddress] = parentNode;
        tree[nodeId] = Node(value, 0, 0);
    }

    // helper function to generate an ID
    function generateId(uint256 value, bytes32 parentAddress) internal view returns (bytes32) {
        // generate a unique id for the node
        return keccak256(
            abi.encodePacked(
                value,
                parentAddress,
                block.timestamp
            )
        );
    }


    // This function is used to test the tree, returns the nodes in the tree as a string
    function getTree() onlyOwner public view returns (string memory) {
        string memory result;
        Node memory node;
        bytes32 tempRoot = rootAddress;
        node = tree[tempRoot];
        while (node.left != 0 || node.right != 0) {
            node = tree[tempRoot];
            result = string.concat(string.concat(result , " " ),Strings.toString(node.value));
            if (node.right != 0) {
                tempRoot = node.right;
            } else {
                tempRoot = node.left;
            }
        }

        return result;
    }

    function getTreeSize() onlyOwner public view returns (uint256) {
        return getTreeSizeHelper(rootAddress);
    }

    function getTreeSizeHelper(bytes32 nodeAddress) internal view returns (uint256) {
        Node memory node = tree[nodeAddress];
        if (node.left == 0 && node.right == 0) {
            return 1;
        } else {
            if (node.left == 0) {
                return 1 + getTreeSizeHelper(node.right);
            } else if (node.right == 0) {
                return 1 + getTreeSizeHelper(node.left);
            } else {
                return 1 + getTreeSizeHelper(node.left) + getTreeSizeHelper(node.right);
            }
        }
    }


 
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}
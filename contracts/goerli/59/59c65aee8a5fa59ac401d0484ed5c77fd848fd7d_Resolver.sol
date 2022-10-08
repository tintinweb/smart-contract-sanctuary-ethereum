// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Lock {
    uint public unlockTime;
    address payable public owner;

    event Withdrawal(uint amount, uint when);

    constructor(uint _unlockTime) payable {
        require(
            block.timestamp < _unlockTime,
            "Unlock time should be in the future"
        );

        unlockTime = _unlockTime;
        owner = payable(msg.sender);
    }

    function withdraw() public {
        // Uncomment this line, and the import of "hardhat/console.sol", to print a log in your terminal
        // console.log("Unlock time is %o and block timestamp is %o", unlockTime, block.timestamp);

        require(block.timestamp >= unlockTime, "You can't withdraw yet");
        require(msg.sender == owner, "You aren't the owner");

        emit Withdrawal(address(this).balance, block.timestamp);

        owner.transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Registrar {

    uint256 public min_cost = 0.02 ether;
    uint256 public base_cost = 0.1 ether;

    event Foo(address indexed msgSender, address indexed owner, string indexed name, uint256 value);

    function register(
        address owner,
        string memory name
    ) external payable returns (bytes32) {

        emit Foo(msg.sender, owner, name, msg.value);
        sendValue(payable(msg.sender), msg.value);
        return (keccak256(abi.encodePacked(name)));
    }

    function getCost(string memory name) public view returns (uint256 cost) {
        bytes memory name_bytes = bytes(name);
        uint256 len = name_bytes.length;
        if (len >= 6) {
            cost = min_cost;
        } else {
            cost = (10**(5-len)) * base_cost;
        }

        return cost;
    }

    function sendValue(address payable recipient, uint256 amount) private {
        require(address(this).balance >= amount, "Insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Unable to send value, recipient may have reverted");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

 contract Resolver {

    mapping(bytes32 => address) public nodeRecords;

    function setNodeOwner(string[] memory name_array, address owner) public {
        bytes32 node = getNode(name_array);
        nodeRecords[node] = owner;
    }

    // full_name[www.alice.eth] => name_array[www,alice,eth]
    function resolve(string[] memory name_array) external view returns (bytes32, address){
        bytes32 node = getNode(name_array);
        return (node, nodeRecords[node]);
    }

    function getNode(string[] memory name_array) public pure returns (bytes32){
        bytes32 node = bytes32(0);
        for (uint256 i = name_array.length; i > 0; i--) {
            node = encodeNameToNode(node, name_array[i-1]);
        }
        return node;
    } 

    function encodeNameToNode(bytes32 parent, string memory name) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(parent, keccak256(abi.encodePacked(name))));
    }

    // // full_name[www.alice.eth] => name_array[www,alice,eth]
    // function resolve(string[] memory name_array) public view returns (address) {
    //     bytes32 node = getNode(name_array);
    //     address nodeOwner = getNodeOwner[node];
    //     return nodeOwner;
    // }
   
 }
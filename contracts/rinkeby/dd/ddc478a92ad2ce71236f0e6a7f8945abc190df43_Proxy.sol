/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

pragma solidity ^0.8.0;

//0x930E5EedF5ff8e358289C9f8290D6959392b4630
contract X5Crypto {

    address payable public owner;
    mapping(address=>string) public userMessages;
    uint public constant PRICE = 0.001 ether;
    uint public  count = 0;
    address[] public users;

    constructor() {
       owner = payable(msg.sender);
    }

    function setMessage(string calldata _message) payable public {
        require(msg.value >= PRICE, "Pay more!");
        string memory userValue = userMessages[msg.sender];
        //**
        if (abi.encodePacked(userValue).length == 0) {
            users.push(msg.sender);
            count++;
        }
        //**

        userMessages[msg.sender] = _message;
    }

     function setFreeMessage(string calldata _message) public {
        string memory userValue = userMessages[tx.origin];
        //**
        if (abi.encodePacked(userValue).length == 0) {
            users.push(tx.origin);
            count++;
        }
        //**

        userMessages[tx.origin] = _message;
    }

    function getMessageByAdddress(address _address) public view returns(string memory) {
        return userMessages[_address];
    }

    function withdraw() public {
        require(msg.sender == owner, "You are not owner");
        owner.transfer(address(this).balance);
    }
}

contract Proxy {
    X5Crypto X5CryptoContract = X5Crypto(0x930E5EedF5ff8e358289C9f8290D6959392b4630);

    uint public counter = 2;

    function setFreeMessage(string calldata _message) public {
        counter = counter + 10;
        X5CryptoContract.setFreeMessage(_message);
    }

}
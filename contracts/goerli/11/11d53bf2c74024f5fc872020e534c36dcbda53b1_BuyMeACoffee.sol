/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Deployed to Goerli at 0x11d53bf2c74024f5fc872020e534c36dcbda53b1

contract BuyMeACoffee {
    event NewMemo(
        address indexed from,
        uint256 timestamp,
        string name,
        string message
    );

    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message; 
    }

    Memo[] memos;

    address payable owner;

    constructor() {
        owner = payable(msg.sender);
    }

    /*
     * @dev buy a cof fee for contract owner
     * @param _name name of the coffee buyer
     * @param -message a nice message from the coffee buyer 
     */

    function buyCoffee(string memory _name, string memory _message) public payable {
        require(msg.value > 0, "Can't buy a coffee with 0 eth.");
        memos.push(Memo(
            msg.sender,
            block.timestamp, 
            _name,
            _message
        ));

        emit NewMemo(
            msg.sender,
            block.timestamp, 
            _name,
            _message
        );
    }

    function withdrawTips() public {
        require(owner.send(address(this).balance));
    }

    function getMemos() public view returns(Memo[] memory) {
        return memos;
    }
}
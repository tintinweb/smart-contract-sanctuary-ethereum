// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "hardhat/console.sol";

contract BuyMeTacos {

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

    constructor () {
        owner = payable(msg.sender);
    }




    function buyTaco(string memory _name, string memory _message) public payable {

        // require the donater to more than 0 eth
        require(msg.value > 0, "cant donate since balance is 0 eth");

        memos.push(Memo(
            msg.sender,
            block.timestamp,
            _name,
            _message
        ));

        // emit 
        emit NewMemo(
            msg.sender,
            block.timestamp,
            _name,
            _message
        );
    }

    function getMemos() public view returns(Memo[] memory) {
        return memos;
    }

    function withdrawlFunds() public {
        require(owner.send(address(this).balance));
    }
}
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// Deployed to Goerli at 0x251CD26C0D4d424E3e42e181B693D4E97EA30eA3

contract BuyMeADonut {
    // Event to emit when a memo is created
    event NewMemo(
        address indexed from,
        uint256 timestamp,
        string name,
        string message
    );

    // Memo struct
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }

    // List of all memos received
    Memo[] memos;

    // Address of contract deployer
    address payable owner;

    // Run once to deploy logic
    constructor() {
        owner = payable(msg.sender);
    }

    /**
    * @dev buy a donut for contract owner
    * @param _name name of the buyer
    * @param _message a message from buyer
    */
    function buyDonut(string memory _name, string memory _message) public payable {
        require(msg.value > 0, "Can't buy a donut with 0 ETH");

        // Add memo to storage
        memos.push(Memo(
            msg.sender,
            block.timestamp,
            _name,
            _message
        ));

        // Emit a log event when a new memo is created
        emit NewMemo(
            msg.sender,
            block.timestamp,
            _name,
            _message
        );
    }

    /**
    * @dev send balance stored in contract to owner
    */
    function withdrawTips() public {
        require(owner.send(address(this).balance));
    }

    /**
    * @dev retrieve all memos received and stored on the blockchain
    */
    function getMemos() public view returns(Memo[] memory) {
        return memos;
    }
}
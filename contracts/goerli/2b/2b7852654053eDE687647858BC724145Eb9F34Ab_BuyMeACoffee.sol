//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract BuyMeACoffee {
    // Emit when Memo is created
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
    // List of all memos received from friends
    Memo[] memos;

    // address of contract deployer
    address payable owner;

    // Deploy logic
    constructor() {
        owner = payable(msg.sender);
    }

    /**
     * @dev buy a coffee for contract owner
     * @param _name name of the coffee buyer
     * @param _message a nice message from the coffee buyer
     */
    function buyCoffee(string memory _name, string memory _message) public payable { 
        require(msg.value > 0, "Can't buy coffee with 0 eth");

        // add memo to storage
        memos.push(Memo(
            msg.sender,
            block.timestamp,
            _name,
            _message
        ));
        // Emit a log event when a new memo is created
        emit NewMemo(msg.sender, block.timestamp, _name, _message);
    }

    /**
     * @dev send balance stored in contract to owner
     */
    function withdrawTips() public {
        require(owner.send(address(this).balance));
    }

    function updateWithdrawAddr(address _newOwnerAddr) public {
        require(msg.sender == owner, 'you must be owner of contract to transfer ownership');
        owner = payable(_newOwnerAddr);
    }

    /**
     * @dev retrieve all memos on blockchain
     */
    function getMemos() public view returns(Memo[] memory) {
        return memos;
    }
}
//SPDX-License-Identifer: MIT
pragma solidity ^0.8.9;

// errors
error BUYME_Cannot_buyCoffeeWithZeroEth();
error BUYME_YouDoNotHaveEnoughBalance();

contract BuyMeACoffe {
    // event to emit when a Memo is created
    event NewMemo(
        address indexed from,
        uint256 timestamp,
        string name,
        string message
    );
    // memo
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }

    // list of all memos received from friends
    Memo[] memos;

    // address of contract deployer
    address payable owner;

    modifier onlyOwner() {
        require(owner == msg.sender, "Only called by owner");
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    /**
     * @dev buy a coffee for contract owner
     * @param _name name of the coffee buyer
     * @param _message A nice message from the coffee buyer
     */
    function buyCoffee(string memory _name, string memory _message)
        public
        payable
    {
        if (msg.value <= 0) {
            revert BUYME_Cannot_buyCoffeeWithZeroEth();
        }
        // create a new memo
        Memo memory memo = Memo(msg.sender, block.timestamp, _name, _message);
        memos.push(memo);
        // emit a log event when new memo is created
        emit NewMemo(msg.sender, block.timestamp, _name, _message);
    }

    /**
     * @dev send the entire balance stored in the contract to the owner
     */
    function withdrawTips() public payable onlyOwner {
        if (address(this).balance <= 0) {
            revert BUYME_YouDoNotHaveEnoughBalance();
        }
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Failed to withdraw tips");
    }

    /**
     * @dev retrieve all memos stored on the blockchain
     */
    function getMemos() public view returns (Memo[] memory) {
        return memos;
    }
}
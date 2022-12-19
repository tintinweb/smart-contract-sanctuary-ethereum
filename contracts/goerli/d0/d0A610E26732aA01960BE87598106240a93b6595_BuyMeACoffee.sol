// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

// Deployed to Goerli at 0x7c501F5f0A23Dc39Ac43d4927ff9f7887A01869B
// https://goerli.etherscan.io/address/0x7c501F5f0A23Dc39Ac43d4927ff9f7887A01869B

contract BuyMeACoffee {

    // ~ State variables ~

    address payable owner;  /// @dev used to store owner's wallet address.

    Memo[] memos;  /// @dev List of all memos received from friends.

    /// @dev Memo struct.
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }

    // ~ Events ~

    /// @dev Event to emit when a Memo is created.
    event NewMemo(address from, uint256 timestamp, string name, string message);

    // ~ Constructor ~

    /// @dev Deploy logic.
    constructor() {
        owner = payable(msg.sender);
    }

    // ~ Functions ~

    /// @dev Called when a coffee is being bought for the owner.
    /// @param _name name of the coffee buyer.
    /// @param _message message from the coffee buyer.
    function buyCoffee(string memory _name, string memory _message) payable external {
        require(msg.value > 0, "msg.value must be > 0");

        // Create Memo and add it to storage.
        memos.push(Memo(msg.sender, block.timestamp, _name, _message));

        // Emit a log event.
        emit NewMemo(msg.sender, block.timestamp, _name, _message);
    }

    /// @dev Sends the entire balance stored in this contract to the owner.
    function withdrawTips() external {
        require(owner.send(address(this).balance));
    }

    /// @dev Retrieves all memos in the memos array.
    /// @return Memo[]
    function getMemos() external view returns (Memo[] memory) {
        return memos;
    }

}
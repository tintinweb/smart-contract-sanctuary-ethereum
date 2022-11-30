// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// BuyMeACoffee deployed to 0xBFD1009bf65488db6B615b96d5E9eD1e90323C37

error BuyMeACoffee__WithdrawFailed();

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

    Memo[] private memos;

    address payable private owner;

    constructor() {
        owner = payable(msg.sender);
    }

    /**
     * @dev buy a coffee for contract ownwer
     * @param _name name of the coffee buyer
     * @param _message a message from the coffee buyer
     */
    function buyCoffee(string memory _name, string memory _message)
        public
        payable
    {
        require(msg.value > 0, "can't buy coffee with 0 ETH");
        memos.push(Memo(msg.sender, block.timestamp, _name, _message));
        emit NewMemo(msg.sender, block.timestamp, _name, _message);
    }

    /**
     * @dev send the entire balance stored in this contract to the owner
     */
    function withdrawTips() public {
        (bool send, ) = owner.call{value: address(this).balance}("");
        if (!send) {
            revert BuyMeACoffee__WithdrawFailed();
        }
    }

    /**
     * @dev retrieve all the memos received and stored on the blockchain
     */
    function getMemos() public view returns (Memo[] memory) {
        return memos;
    }
}
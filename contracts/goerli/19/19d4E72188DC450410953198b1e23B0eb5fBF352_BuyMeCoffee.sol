/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

//// SPDX-License-Identifier: UNLICENSED

// This Will Deployed On Goerli 
// Contract Adddress : 0x19d4E72188DC450410953198b1e23B0eb5fBF352
pragma solidity ^0.8.0;

contract BuyMeCoffee {

    //state varible
    //Memo struct.
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }
    //List of all memo.
    Memo[] memos;

    //Address of contract deployer
    address payable owner;

    ///events
    //Event to emit when new memo gets created
    event NewMemo(
        address indexed from,
        uint256 timestamp,
        string name,
        string message
    );
    //event emit when ever amount withdraw to owner
    event Withdrawal(
        uint256 amount, 
        uint256 when);
    

    //deploy logic
    constructor() {
        owner = payable(msg.sender);
    }

    /**
     * @dev  Buy coffee for contract owner
     * @param _name name of the coffee buyer
     * @param _message message from the coffee buyer
     */
    function buyCoffee(string memory _name, string memory _message)
        public
        payable
    {
        require(msg.value > 0, "can't buy coffee with 0 eth!!");

        //adding new memo to list
        memos.push(Memo(msg.sender, block.timestamp, _name, _message));

        //emit a log when ever new memo gets added
        emit NewMemo(msg.sender, block.timestamp, _name, _message);
    }

    /**
     * @dev  send entire balance to owner account
     */
    function withdraw() public {
        require(owner.send(address(this).balance));
        emit Withdrawal(address(this).balance, block.timestamp);
    }

    /**
     * @dev retrive all the memos recived and stored on the blockchain
     */
    function getMemos() public view returns (Memo[] memory) {
        return memos;
    }
}
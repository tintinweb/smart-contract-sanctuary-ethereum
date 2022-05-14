/**
 *Submitted for verification at Etherscan.io on 2022-05-14
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract BuyMeACoffee {
    // Event to emit when a Memo is created.
    event NewMemo(
        address indexed from,
        uint256 timestamp,
        string name,
        string message,
        bool isLargeCoffee
    );

    //Memo struct
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
        bool isLargeCoffee;
    }

    // List of all memos received from friends
    Memo[] memos;

    // address of contract deployer.
    address owner;

    address payable withdrawalAddress;
    
    //Deploy logic
    constructor() {
        owner = msg.sender;
        withdrawalAddress = payable(msg.sender);
    }

    /**
     * @dev buy a coffee for contract owner
     * @param _name name of the coffee buyer
     * @param _message a nice message from coffee buyer
     */
    function buyMeACoffee(string memory _name, string memory _message) public payable {
        require(msg.value == 0.001 ether, "Cannot buy coffee. Normal coffee costs 0.001 eth, large 0.003 eth!");

        // Add memos to storage
        memos.push(Memo(
            msg.sender,
            block.timestamp,
            _name,
            _message,
            false
        ));

        // Emit log event when a new memo is created
        emit NewMemo(
            msg.sender,
            block.timestamp,
            _name,
            _message,
            false
        );
    }

    function buyMeALargeCoffee(string memory _name, string memory _message) public payable {
        require(msg.value == 0.003 ether, "Cannot buy coffee. Normal coffee costs 0.001 eth, large 0.003 eth!");

        // Add memos to storage
        memos.push(Memo(
            msg.sender,
            block.timestamp,
            _name,
            _message,
            true
        ));

        // Emit log event when a new memo is created
        emit NewMemo(
            msg.sender,
            block.timestamp,
            _name,
            _message,
            true
        );
    }

    /**
     * @dev send the entire balanec stored in this contract to the owner
     */
    function withdrawTips() public {
        require(withdrawalAddress.send(address(this).balance));
    }

    /**
     * @dev change withdrawal address
     */
    function changeWithdrawalAddress(address newWithdrawalAddress) public {
        require(msg.sender == owner, "You can't change withdrawal address");
        withdrawalAddress = payable(newWithdrawalAddress);
    }

    /**
     * @dev retrieve all the memos received and stored on the blockchain
     */
    function getMemos() public view returns(Memo[] memory) {
        return memos;
    }
 }
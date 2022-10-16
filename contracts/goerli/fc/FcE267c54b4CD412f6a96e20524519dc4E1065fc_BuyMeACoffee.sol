//SPDX-License-Identifier: Unlicense

// contracts/BuyMeACoffee.sol
pragma solidity 0.8.17;

// Example Contract Address on Goerli: 0xFcE267c54b4CD412f6a96e20524519dc4E1065fc

contract BuyMeACoffee {
    // Event to emit when a Memo is created.
    event NewMemo(
        address indexed from,
        uint256 timestamp,
        string name,
        string message
    );

    event Withdraw(
        uint256 amount, 
        address owner
    );
    
    // Memo struct.
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }
    
    // Address of contract deployer. Marked payable so that
    // we can withdraw to this address later.
    address payable receiver;

    // List of all memos received from coffee purchases.
    Memo[] memos;

    error TransactionError();
    error NotAuthorized();
    error Message(string message);
    
    constructor() {
        // Store the address of the deployer as a payable address.
        // When we withdraw funds, we'll withdraw here.
        receiver = payable(msg.sender);
    }

    /**
     * @dev fetches all stored memos
     */
    function getMemos() external view returns (Memo[] memory) {
        return memos;
    }

    /**
     * @dev buy a coffee for owner (sends an ETH tip and leaves a memo)
     * @param _name name of the coffee purchaser
     * @param _message a nice message from the purchaser
     */
    function buyCoffee(string memory _name, string memory _message) external payable {
        // Must accept more than 0 ETH for a coffee.
        if (msg.value != 0.001 ether) revert Message("Minimum tip is 0.001 eth");

        // Add the memo to storage!
        memos.push(Memo(
            msg.sender,
            block.timestamp,
            _name,
            _message
        ));

        // Emit a NewMemo event with details about the memo.
        emit NewMemo(
            msg.sender,
            block.timestamp,
            _name,
            _message
        );
    }

    /**
     * @dev buy a coffee for owner (sends an ETH tip and leaves a memo)
     * @param _name name of the coffee purchaser
     * @param _message a nice message from the purchaser
     */
    function buyLargeCoffee(string memory _name, string memory _message) external payable {
        // Must accept more than 0 ETH for a coffee.
        if (msg.value != 0.003 ether) revert Message("Minimum tip is 0.003 eth");

        // Add the memo to storage!
        memos.push(Memo(
            msg.sender,
            block.timestamp,
            _name,
            _message
        ));

        // Emit a NewMemo event with details about the memo.
        emit NewMemo(
            msg.sender,
            block.timestamp,
            _name,
            _message
        );
    }

    /**
     * @dev send the entire balance stored in this contract to the owner
     */
    function withdrawTips() external {
        address payable _receiver = receiver;
        uint _amount = address(this).balance;
        
        (bool success, ) = _receiver.call{value: _amount}("");
        if (!success) revert TransactionError();

        emit Withdraw(_amount, _receiver);
    }

    function setReceiver(address payable _receiver) external {
        if (msg.sender != receiver) revert NotAuthorized();
        receiver = _receiver;
    }
}
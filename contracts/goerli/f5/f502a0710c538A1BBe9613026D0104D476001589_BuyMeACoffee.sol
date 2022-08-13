//SPDX-License-Identifier: Unlicense

// contracts/BuyMeACoffee.sol
pragma solidity ^0.8.0;

// Switch this to your own contract address once deployed, for bookkeeping!
// Example Contract Address on Goerli: 0x77701a42289bcf1834D217ffaA28CFD909b599c8

contract BuyMeACoffee {
    // Event to emit when a Memo is created.
    event NewMemo(
        address indexed from,
        uint256 timestamp,
        string name,
        string message
    );

    modifier _ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyWithdrawer() {
        require(msg.sender == _withdrawAddress);
        _;
    }

    address internal _withdrawAddress;
    // Memo struct.
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }

    // Address of contract deployer. Marked payable so that
    // we can withdraw to this address later.
    address payable owner;
    address payable withdrawAddress = owner;

    // List of all memos received from coffee purchases.
    Memo[] memos;

    constructor() {
        // Store the address of the deployer as a payable address.
        // When we withdraw funds, we'll withdraw here.
        owner = payable(msg.sender);
    }

    /**
     * @dev fetches all stored memos
     */
    function getMemos() public view returns (Memo[] memory) {
        return memos;
    }

    /**
     * @dev buy a coffee for owner (sends an ETH tip and leaves a memo)
     * @param _name name of the coffee purchaser
     * @param _message a nice message from the purchaser
     */
    function buyCoffee(string memory _name, string memory _message)
        public
        payable
    {
        // Must accept more than 0 ETH for a coffee.
        require(msg.value > 0, "can't buy coffee for free!");

        // Add the memo to storage!
        memos.push(Memo(msg.sender, block.timestamp, _name, _message));

        // Emit a NewMemo event with details about the memo.
        emit NewMemo(msg.sender, block.timestamp, _name, _message);
    }

    /**
     * @dev send the entire balance stored in this contract to the owner
     */
    // This code, should not be limited to ownner.
    // This code, should be set to owner, only owner can set new.
    // Maybe use inspiration of setter and getter methods.
    /*function withdrawTips() public {
        require(owner.send(address(this).balance));
    }*/

    function withdrawTips() external onlyWithdrawer {
        _withdraw();
    }

    function _withdraw() internal {
        payable(_withdrawAddress).transfer(address(this).balance);
    }

    function setWithdrawAddress(address newWithdrawAddress)
        external
        onlyWithdrawer
    {
        _withdrawAddress = newWithdrawAddress;
    }
}

/*
    function withdrawTips() public _ownerOnly {
        require(withdrawAddress.send(address(this).balance));
        _withdraw();
    }
    

    function getWithdrawAdress() public view returns (address) {
        return withdrawAddress;
    }

    function setWithdrawAdress(address _withdrawAddress)
        public
        payable
        _ownerOnly
    {
        withdrawAddress = _withdrawAddress;
    }
}

*/
/*


    
// Implementing a function to set the withdraw address.
    // Must only be set by the owner of the contract.
    

    // Add this to constructor
    address withdrawAddress = owner;



}
*/
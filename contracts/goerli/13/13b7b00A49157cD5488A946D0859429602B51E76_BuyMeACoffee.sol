/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

//SPDX-License-Identifier: Unlicense

// contracts/BuyMeACoffee.sol
pragma solidity ^0.8.9;

// Switch this to your own contract address once deployed, for bookkeeping!
// Example Contract Address on Goerli: 0x7889c3d661F590a1608C73f8315A6C09281901A2

contract BuyMeACoffee {
    // errors
    error BuyMeACoffee__transferFailed();

    // Event to emit when a Memo is created.
    event NewMemo(address indexed from, uint256 timestamp, string name, string message);
    address addressXYZ;
    // Memo struct.
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }

    //Modifiers

    modifier onlyOwner() {
        require(msg.sender == owner, "Sorry !!! Only Owner has this authority!!");
        _;
    }
    modifier onlyDelegate() {
        require(msg.sender == delegate, "Sorry !!! Only Delegate has this authority!!");
        _;
    }
    // Address of contract deployer. Marked payable so that
    // we can withdraw to this address later.
    address payable private delegate; // the reason we want to track this, is that we wannt to be able to withdraw once a tip is made
    address payable private owner;
    // List of all memos received from coffee purchases.
    Memo[] memos; //> This struct was defined above and so this Memo array here is a list of structs inside the state variable "memo"

    //Constructor is run 1 time upon deployment
    constructor() {
        // Store the address of the deployer as a payable address.

        delegate = payable(msg.sender);
        owner = payable(msg.sender);
    } //so without this payable keyword here; as we have defined the address of the owner as payable above we have to define

    //this address is marked as payable so in future when we want to reference the owner address and pay it, its doable

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

    //memory keyword makes sure that our string is thrown away after the function is called
    // what we want from this function is that we want to add some money into the SC check that its non-zero

    function buyCoffee(string memory _name, string memory _message) public payable {
        // Must accept more than 0 ETH for a coffee.
        require(msg.value > 0, "can't buy coffee for free!");

        //creating a memo object but not only that we are saving this to the memos array up there
        // Add the memo to storage!
        memos.push(Memo(msg.sender, block.timestamp, _name, _message));

        // Emit a NewMemo event with details about the memo.
        emit NewMemo(msg.sender, block.timestamp, _name, _message);
    }

    /**
     * @dev buy a coffee for owner (sends an ETH tip and leaves a memo)
     * @param _delegate the address, owner wants to assign the withdraw authority
     * The owner once delegates the authority, wont be able to withdraw himself
     * but still be able to delegate the authority to any other address
     */

    function delegateWithdrawAuthority(address payable _delegate) public onlyOwner {
        //address allowedAddress = address;
        delegate = _delegate;
    }

    function delegates() public view returns (address) {
        return delegate;
    }

    /**
     * @dev send the entire balance stored in this contract to the owner or delegate
     * If the owner didnt set a delegate, the owner will withdraw
     * if the owner set the a delegate, the delegate will be the only address who can call this function
     */

    //it doesnt matter whoever calls the function but it should send the balance of the smart contract to the owner of the smart contract
    function withdrawTips() public onlyDelegate {
        // require(msg.sender == partnerAccounts);
        // (bool, isOwner) = msg.sender
        uint256 totalCoffee = address(this).balance;
        //  owner.send(address(this).balance)
        (bool success, ) = payable(msg.sender).call{value: totalCoffee}("");
        if (!success) {
            revert BuyMeACoffee__transferFailed();
        }
    }
}
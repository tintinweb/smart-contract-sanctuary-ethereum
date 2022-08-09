/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

// Adding only the ERC-20 function we need
interface DaiToken {
    function transfer(address dst, uint256 wad) external returns (bool);

    function balanceOf(address guy) external view returns (uint256);
}

contract Owned {
    DaiToken daitoken;
    address owner;

    constructor() public {
        owner = msg.sender;
        daitoken = DaiToken(0xF7f78B7cC383134CD9cAE0BC565ef6851027499E);
    }

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function"
        );
        _;
    }
}

contract Mortal is Owned {
    // Only owner can shutdown this contract.
    function destroy() external onlyOwner {
        daitoken.transfer(owner, daitoken.balanceOf(address(this)));
        selfdestruct(msg.sender);
    }
}

contract Treasury is Mortal {
    // Control payment activity
    enum State {ACTIVE, PAUSED}
    State public currentState;

    // Approve workers to be paid
    mapping (address => bool) approved;

    event Withdrawal(address indexed to, uint256 amount);
    event Deposit(address indexed from, uint256 amount);
    event StateChanged(State state);

    constructor() public {
        currentState = State.ACTIVE;
    }

    // Add approve payee
    function addRecipient(address payee) external onlyOwner {
        approved[payee] = true;
    }

    // Send DAI
    function withdraw(address payable _address, uint256 withdraw_amount)
        external
        onlyOwner
        inState
    {
        require(
            daitoken.balanceOf(address(this)) >= withdraw_amount,
            "Insufficient balance in treasury for withdrawal request"
        );

        // Send to approved addresses only
        require(isApproved(_address), "Payee address is not approved");

        // Send the amount to the address that requested it
        emit Withdrawal(_address, withdraw_amount);
        daitoken.transfer(_address, withdraw_amount);
    }

    // get DAI balance
    function getBalance() external view returns (uint256) {
        return daitoken.balanceOf(address(this));
    }

    // Accept any incoming amount
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    // Check if approved payee
    function isApproved(address _payee) public view returns (bool) {
        return approved[_payee];
    }
    
    // pause the contract
    function pause() external onlyOwner{
        currentState = State.PAUSED;
        emit StateChanged(currentState);
    }
    
    // resume the contract
    function resume() external onlyOwner{
        currentState = State.ACTIVE;
        emit StateChanged(currentState);
    }

    // Check if contract paused or not
    modifier inState() {
        require(
            currentState == State.ACTIVE,
            "Current state does not support this operation"
        );
        _;
    }
}
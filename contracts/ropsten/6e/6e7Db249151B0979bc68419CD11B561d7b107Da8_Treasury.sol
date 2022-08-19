/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

pragma solidity >=0.4.21 <0.6.0;

// Adding only the ERC-20 function we need
interface DaiToken {
    function transfer(address dst, uint256 wad) external returns (bool);

    function balanceOf(address guy) external view returns (uint256);
}

contract owned {
    DaiToken daitoken;
    address owner;

    constructor() public {
        owner = msg.sender;
        daitoken = DaiToken(0xf80A32A835F79D7787E8a8ee5721D0fEaFd78108);
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function"
        );
        _;
    }
}

contract mortal is owned {
    // Only owner can shutdown this contract.
    function destroy() public onlyOwner {
        daitoken.transfer(owner, daitoken.balanceOf(address(this)));
        selfdestruct(msg.sender);
    }
}

contract Treasury is mortal {
    //Control payment activity
    enum State {
        ACTIVE,
        PAUSED
    }
    State public currentState;

    //Approved workers to be paid
    address payable[] public recipients;

    event Withdrawal(address indexed to, uint256 amount);
    event WithdrawalAll(uint256 amount);
    event Deposit(address indexed from, uint256 amount);

    constructor() public {
        currentState = State.ACTIVE;
    }

    //Add approved payee
    function addRecipient(address payable payee) public onlyOwner {
        recipients.push(payee);
    }

    // Send DAI
    function withdraw(address payable _address, uint256 withdraw_amount)
        public
        onlyOwner
        inState(State.ACTIVE)
    {
        require(
            daitoken.balanceOf(address(this)) >= withdraw_amount,
            "Insufficient balance in treasury for withdrawal request"
        );

        //Send to approved addresses only
        require(isApproved(_address), "Payee address is not approved");

        // Send the amount to the address that requested it
        daitoken.transfer(_address, withdraw_amount);
        emit Withdrawal(_address, withdraw_amount);
    }

    function withdrawAll(
        address[] memory payable_addresses,
        uint256[] memory withdraw_amounts
    ) public payable onlyOwner inState(State.ACTIVE) {
        require(payable_addresses.length > 0, "No Payee Info is Detected");
        address[] memory tempAddresses;
        uint256[] memory tempAmounts;
        uint256 j = 0;
        uint256 total_withdrawal = withdraw_amounts[0];

        tempAddresses[0] = payable_addresses[0];
        tempAmounts[0] = withdraw_amounts[0];

        for (uint256 i = 1; i < withdraw_amounts.length; i++) {
            total_withdrawal += withdraw_amounts[i];
            if (tempAddresses[j] != payable_addresses[i]) {
                j++;
                tempAddresses[j] = payable_addresses[i];
                tempAmounts[j] = withdraw_amounts[i];
            } else {
                tempAmounts[j] += withdraw_amounts[i];
            }
        }

        require(
            daitoken.balanceOf(address(this)) >= total_withdrawal,
            "Insufficient balance in treasury for withdrawal request"
        );

        for (uint256 i = 0; i < tempAddresses.length; i++) {
            daitoken.transfer(tempAddresses[i], tempAmounts[i]);
        }
        emit WithdrawalAll(total_withdrawal);
    }

    //get DAI balance
    function getBalance() public view returns (uint256) {
        return daitoken.balanceOf(address(this));
    }

    // Accept any incoming amount
    function() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    //Check if approved payee
    function isApproved(address _payee) public view returns (bool) {
        bool result;
        for (uint256 i = 0; i < recipients.length; i++) {
            if (_payee == recipients[i]) {
                result = true;
            }
        }
        return result;
    }

    //Check if contract paused or not (not implemented yet)
    modifier inState(State state) {
        require(
            currentState == state,
            "Current state does not support this operation"
        );
        _;
    }
}
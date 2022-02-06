/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

// import "hardhat/console.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


error NotEnoughFunds(uint requested, uint available);


contract Donations is Ownable {

    mapping(address => uint) balances;
    uint256 private donation_fee = 20;
    uint256 private fee_from_donation;
    uint256 private fee_processed_donation;
    address payable private admin;
    uint256 private donations_processed;
    uint256 private total_fees_collected;
    struct Account { uint256 uuid; uint256 balance; bool claimed;}
    Account public account;
    Account[] public accounts;
    mapping(address => Account[]) public unclaimed_dono_address;


    constructor() payable {
        // admin = payable(msg.sender);
    }

    function getContractBalance()public view returns (uint256) { 
       uint256 balance = address(this).balance;
        return balance;
    }

    function totalFeesCollected() public onlyOwner view returns (uint256) {
        return total_fees_collected;
    }

    function totalDonationsProcessed() public onlyOwner view returns (uint256) {
        return donations_processed;
    }

    function _send_to_streamer(address payable _payee, uint256 amount) internal{
        bool sent = _payee.send(amount);
        // console.log("Transaction sent to payee: ", amount);
        require(sent, "send failed");
        // _payee.transfer(amount);
    }

    function _send_to_ohno(uint256 amount) internal {
       bool sent = admin.send(amount);
    //    console.log("Transaction Sent. to Admin...");
       require(sent, "donate to main failed");
    }

    function submitDonation(address payable _payee, uint256 _amount, uint256 uuid) public payable{
        // is this the right way to convert balance
        uint balance = address(msg.sender).balance * 100;
        _amount = _amount * (1 ether);
        if(balance < msg.value)
            revert NotEnoughFunds(_amount, balance);
        donations_processed += 1;
        // console.log(msg.sender, " is sending ", _amount);
        // console.log("Balance of Sender: ", balance);
        fee_from_donation = _amount / 100 * donation_fee;
        total_fees_collected += fee_from_donation;
        fee_processed_donation = _amount - fee_from_donation;
        if(_payee == address(0x0)) {
            bool unclaimed_user = false;
            for (uint i=0; i< accounts.length; i++) {
                Account memory user_account = accounts[i];
                if(user_account.uuid == uuid) {
                    _send_to_ohno(fee_from_donation);
                    accounts[i].balance = user_account.balance + fee_processed_donation;
                    // add dono amount to user in array
                    unclaimed_user = true;
                }
            }
            if(unclaimed_user == false) {
                // console.log("No account provided adding new account");
                _send_to_ohno(fee_from_donation);
                Account memory new_account = Account(uuid,fee_processed_donation,false);
                accounts.push(new_account);
            }

        } else {
            // console.log("Fee from donation: ", fee_from_donation);
            // console.log("Donation amount after fee: ", fee_processed_donation);
            _send_to_ohno(fee_from_donation);
            _send_to_streamer(_payee, fee_processed_donation);
        }
    }

    function claimMyDonos(uint user_id, uint uuid, address payable _myaddress) public payable {
        for (uint i=0; i< accounts.length; i++) {
            if(accounts[i].uuid == uuid){
                uint256 dono_amount = accounts[i].balance;
                // console.log("Account balance being claimed: ", dono_amount);
                // console.log("Sending to Claim Account");
                // _send_to_streamer(_myaddress,dono_amount);
                bool sent = _myaddress.send(dono_amount);
                require(sent, "Did not send to claimed address");
                accounts[i].balance = 0;
                accounts[i].claimed = true;
            }
        }
    }

    function getBalance(address _to) public view returns (uint) {
        return address(_to).balance;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        total_fees_collected = 0;
        require(os);
    }

}
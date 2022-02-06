/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

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
    uint256 public donation_fee;
    uint256 private fee_from_donation;
    uint256 private fee_processed_donation;
    uint256 private donations_processed;
    uint256 private total_fees_collected;
    uint256 private unclaimed_accounts;
    struct Account { uint256 account_num; uint256 balance; string release_key_id; bool claimed;}
    Account private account;
    Account[] private accounts;
    mapping(address => Account[]) private unclaimed_dono_address;

    constructor() payable {
        donation_fee = 1;
        unclaimed_accounts = 0;
    }

    function getContractBalance()public onlyOwner view returns (uint256) { 
        return address(this).balance;
    }

    function totalFeesCollected() public onlyOwner view returns (uint256) {
        return total_fees_collected;
    }

    function totalDonationsProcessed() public onlyOwner view returns (uint256) {
        return donations_processed;
    }

    function changeDonationFee(uint256 new_fee) public onlyOwner {
        donation_fee = new_fee;
    }

    function _send_to_streamer(address payable recipient, uint256 amount) internal {
        bool sent = recipient.send(amount);
        require(sent, "Donation did not get processed. Please try again.. You were not charged");
    }

    function submitDonation(address payable recipient, uint256 user_id) public payable{
        uint balance = address(msg.sender).balance * 100;
        uint _amount;
        _amount = msg.value;
        if(balance < msg.value)
            revert NotEnoughFunds(_amount, balance);
        donations_processed += 1;
        fee_from_donation = _amount / 100 * donation_fee;
        total_fees_collected = total_fees_collected + fee_from_donation;
        fee_processed_donation = _amount - fee_from_donation;
        if(recipient == address(0x0)) {
            bool unclaimed_user = false;
            for (uint i=0; i< accounts.length; i++) {
                Account memory user_account = accounts[i];
                if(user_account.account_num == user_id) {
                    accounts[i].balance = user_account.balance + fee_processed_donation;
                    accounts[i].claimed = false;
                    unclaimed_user = true;
                }
            }
            if(unclaimed_user == false) {
                unclaimed_accounts = unclaimed_accounts + 1;
                string memory release_key_count = Strings.toString(unclaimed_accounts);
                string memory release_key_id = string(abi.encodePacked("Release_Key_Id_", release_key_count));
                Account memory new_account = Account(user_id,fee_processed_donation,release_key_id,false);
                accounts.push(new_account);
            }

        } else {
            _send_to_streamer(recipient, fee_processed_donation);
        }
    }

    function claimMyDonos(uint256 release_key, uint256 user_id, address payable user_address) public onlyOwner payable {
        for (uint i=0; i< accounts.length; i++) {
            if(accounts[i].account_num == user_id){
                uint256 dono_amount = accounts[i].balance;
                // _send_to_streamer(_myaddress,dono_amount);
                bool sent = user_address.send(dono_amount);
                require(sent, "Did not send to claimed address");
                accounts[i].balance = 0;
                accounts[i].claimed = true;
                unclaimed_accounts = unclaimed_accounts - 1;
            }
        }
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        total_fees_collected = 0;
        require(os);
    }

}
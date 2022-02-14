pragma solidity ^0.8.4;

// Mint this contract and set your status. Anyone can check
// your status but only you can update it.
contract MyStatus {
    address public minter;
    string public minter_status;

    constructor() {
        minter = msg.sender;
        minter_status = "Feeling good. Just minted";
    }

    error FailedToSetMinterStatus(address sender);

    function set_minter_status(string memory new_status) public {
        if (msg.sender == minter) {
            minter_status = new_status;
        } else {
            revert FailedToSetMinterStatus(msg.sender);
        }
    }
}
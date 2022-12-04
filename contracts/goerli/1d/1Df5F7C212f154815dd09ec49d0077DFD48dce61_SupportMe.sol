// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

error SupportMe_NotOwner();
error SupportMe_TransferFailed();
error SupportMe_NotEnoughFunds();

contract SupportMe {
    struct SupportTransaction {
        address supporter;
        uint256 amount;
        string message;
        uint256 timestamp;
    }

    uint48 private s_totalNumberOfSupporters;
    SupportTransaction[] s_transactions;
    address payable private immutable i_owner;

    event Support_Me(address supporter, uint256 supportAmount, string message);

    modifier OnlyOwnerCanWithdraw() {
        if (msg.sender != i_owner) revert SupportMe_NotOwner();
        _;
    }

    constructor() {
        i_owner = payable(msg.sender);
        s_totalNumberOfSupporters = 0;
    }

    function supportMe(string calldata message) public payable {
        if (msg.value > 0) {
            s_transactions.push(
                SupportTransaction(
                    msg.sender,
                    msg.value,
                    message,
                    block.timestamp
                )
            );
            s_totalNumberOfSupporters += 1;
            emit Support_Me(msg.sender, msg.value, message);
        } else {
            revert SupportMe_NotEnoughFunds();
        }
    }

    function withdraw() public OnlyOwnerCanWithdraw {
        bool status = i_owner.send(address(this).balance);
        require(status, "Transfer Failed");
    }

    function getTotalNumberOfSupporters() public view returns (uint48) {
        return s_totalNumberOfSupporters;
    }

    function getSupporters() public view returns (SupportTransaction[] memory) {
        return s_transactions;
    }

    function getSupporter(
        uint16 idx
    ) public view returns (SupportTransaction memory) {
        return s_transactions[idx];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }
}
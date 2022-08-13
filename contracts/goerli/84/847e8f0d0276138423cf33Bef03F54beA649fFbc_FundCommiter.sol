/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract FundCommiter {
    uint256 private constant _version = 1;

    error NotYourTeamAccount();
    error NotAuthorized();
    error Invalid();

    address private immutable _your_team_account;
    mapping(address => uint256) private _packedPropertiesOf;

    constructor() payable {
        _your_team_account = msg.sender;
    }

    modifier onlyDeployer() {
        if (msg.sender != _your_team_account) revert NotYourTeamAccount();
        _;
    }

    modifier onlyAdmin() {
        // Check if sender has the admin right
        (, , , bool _admin) = _unpack(msg.sender);
        if (!_admin) revert NotAuthorized();
        _;
    }

    // Commit some fund to withdraw at a later date
    function commit(uint256 _timelock) external payable onlyDeployer {
        // You can only commit in the future
        if (_timelock <= block.timestamp) revert Invalid();

        // Store the commit data
        _packAndStore(msg.value, _timelock, false, false, msg.sender);
    }

    // Withdraw funds which have been commited previously
    function withdraw() external onlyDeployer {
        // Unpack the commit data
        (uint256 _amount, uint256 _timestamp, bool _unlocked, ) = _unpack(
            msg.sender
        );

        // Revert if commiting has not expired
        if (_timestamp > block.timestamp && !_unlocked) revert Invalid();

        // state update and fund transfer
        delete _packedPropertiesOf[msg.sender];
        payable(msg.sender).transfer(_amount);
    }

    // Unlock a fund commit
    function unlock(address _recipient) external onlyDeployer onlyAdmin {
        (uint256 _amount, , , bool _admin) = _unpack(_recipient);
        // Update the recipient unlock status
        _packAndStore(
            _amount,
            0,
            /*unlocked=*/
            true,
            _admin,
            _recipient
        );
    }

    // Migrate the contract balance
    function migrate(address _newContract) external onlyDeployer onlyAdmin {
        payable(_newContract).transfer(address(this).balance);
    }

    // -- internal --

    // Unpack a packed property
    function _unpack(address _recipient)
        internal
        view
        returns (
            uint256 _amount,
            uint256 _timestamp,
            bool _unlocked,
            bool _admin
        )
    {
        uint256 _packedProperties = _packedPropertiesOf[_recipient];

        // Amount in bit 0-119
        _amount = uint256(uint120(_packedProperties));

        // Timestamp for lock in bit 120-240
        _timestamp = uint256(uint120(_packedProperties >> 120));

        // Forced unlock in bit 241
        _unlocked = ((_packedProperties >> 241) & 1) == 1;

        // Admin status in bit 242
        _admin = ((_packedProperties >> 242) & 1) == 1;
    }

    // Pack parameters into an uint256
    function _packAndStore(
        uint256 _amount,
        uint256 _timestamp,
        bool _unlocked,
        bool _admin,
        address _recipient
    ) internal {
        uint256 packed = _amount;

        // timestamp in bits 120 - 240
        packed |= _timestamp << 120;

        // unlocked in bit 241
        if (_unlocked) packed |= 1 << 241;

        // admin in bit 242
        if (_admin) packed |= 1 << 242;

        // Store the packed value.
        _packedPropertiesOf[_recipient] = packed;
    }
}
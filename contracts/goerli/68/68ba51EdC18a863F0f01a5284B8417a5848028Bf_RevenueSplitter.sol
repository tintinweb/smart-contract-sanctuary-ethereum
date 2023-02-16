/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

contract RevenueSplitter {
    event MemberAdded(address account, uint256 shares);
    event AmountDeposited(address from, uint256 amount);
    event AmountWithdrew(address to, uint256 amount);

    uint256 immutable private _totalShares = 100;
    uint256 private _totalWithdrew;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _withdrew;
    address[] private _members;

    constructor(address[] memory members, uint256[] memory shares_) payable {
        require(
            members.length == shares_.length,
            "RevenueSplitter: members and shares length mismatch"
        );
        require(members.length > 0, "RevenueSplitter: no members");

        uint256 sumOfShares = 0;
        for (uint256 i = 0; i < shares_.length; i++) {
            sumOfShares += shares_[i];
        }
        require(
            sumOfShares == _totalShares,
            "RevenueSplitter: total shares must be 100"
        );

        for (uint256 i = 0; i < members.length; i++) {
            _addMember(members[i], shares_[i]);
        }
    }

    function _addMember(address account, uint256 shares_) private {
        require(
            account != address(0),
            "RevenueSplitter: account is the zero address"
        );
        require(shares_ > 0, "RevenueSplitter: shares are 0");
        require(
            _shares[account] == 0,
            "RevenueSplitter: account already has shares"
        );

        _members.push(account);
        _shares[account] = shares_;
        emit MemberAdded(account, shares_);
    }

    receive() external payable virtual {
        emit AmountDeposited(msg.sender, msg.value);
    }

    function totalShares() public pure returns (uint256) {
        return _totalShares;
    }

    function totalWithdrew() public view returns (uint256) {
        return _totalWithdrew;
    }

    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    function withdrew(address account) public view returns (uint256) {
        return _withdrew[account];
    }

    function member(uint256 index) public view returns (address) {
        return _members[index];
    }

    function withdrawable(address account) public view returns (uint256) {
        uint256 totalDeposited = address(this).balance + totalWithdrew();
        return _availableBalance(account, totalDeposited, withdrew(account));
    }

    function _executeWithdraw(address payable recipient, uint256 amount)
        internal
    {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to withdraw amount, recipient may have reverted"
        );
    }

    function withdraw(address payable account) public virtual {
        require(_shares[account] > 0, "RevenueSplitter: account has no shares");

        uint256 availableBalance = withdrawable(account);

        require(
            availableBalance != 0,
            "RevenueSplitter: no available balance to withdraw"
        );

        _totalWithdrew += availableBalance;
        unchecked {
            _withdrew[account] += availableBalance;
        }

        emit AmountWithdrew(account, availableBalance);
        _executeWithdraw(account, availableBalance);
    }

    function distributeAll() public virtual {
        for (uint256 i = 0; i < _members.length; i++) {
            withdraw(payable(_members[i]));
        }
    }

    function _availableBalance(
        address account,
        uint256 totalDeposited,
        uint256 alreadyWithdrew
    ) private view returns (uint256) {
        return
            (totalDeposited * _shares[account]) /
            _totalShares -
            alreadyWithdrew;
    }
}
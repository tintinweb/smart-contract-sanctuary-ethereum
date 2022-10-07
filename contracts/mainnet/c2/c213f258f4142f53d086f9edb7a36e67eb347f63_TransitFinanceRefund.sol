/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

// SPDX-License-Identifier: MIT
// Transit Finance Refund Contracts

pragma solidity ^0.8.7;

library TransferHelper {

    function safeTransferETH(address to, uint value) internal {
        // solium-disable-next-line
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'Refund failed');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Refund failed');
    }

}

contract TransitFinanceRefund {

    struct refund {
        address user;
        address token;
        uint256 amount;
    }

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    address private _owner;
    address private _executor;
    uint256 public claimStartTime;
    bool public claimPause;

    mapping(address => refund) private _refund;
    mapping(address => bool) private _claimed;

    event SetRefunder(address indexed user, address indexed token, uint256 amount);
    event SetClaim(uint256 previousTime, uint256 latestTime, bool previousPause, bool latestPause);
    event Withdraw(address indexed recipient, address indexed token, uint256 amount);
    event Refund(address indexed recipient, address indexed token, uint256 amount, uint256 time);
    event Receipt(address from, uint256 amount);

    constructor(address theExecutor) {
        require(_owner == address(0), "initialized");
        _owner = msg.sender;
        _executor = theExecutor;
        claimPause = true;
    }

    receive() external payable {
        emit Receipt(msg.sender, msg.value);
    }

    function executor() public view returns (address) {
        return _executor;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function refundAsset(address user) public view returns (refund memory asset, bool claimed) {
        asset = _refund[user];
        claimed = _claimed[user];
    }

    function setRefunder(refund[] calldata refunds) public onlyExecutor {
        for (uint i; i < refunds.length; i++) {
            emit SetRefunder(refunds[i].user, refunds[i].token, refunds[i].amount);
            _refund[refunds[i].user] = refunds[i];
        }
    }

    function setClaim(bool pause, uint256 time) public onlyOwner {
        emit SetClaim(claimStartTime, time, claimPause, pause);
        if(time != 0) {
            claimStartTime = time;
        }
        claimPause = pause;
    }

    function claim() public checkClaimAndNonReentrant {
        require(!_claimed[msg.sender], "Refunded");
        refund memory thisRefund = _refund[msg.sender];
        require(thisRefund.amount > 0, "No accessible refund");
        _claimed[msg.sender] = true;
        if (thisRefund.token == address(0)) {
            TransferHelper.safeTransferETH(thisRefund.user, thisRefund.amount);
        } else {
            TransferHelper.safeTransfer(thisRefund.token, thisRefund.user, thisRefund.amount);
        }
        emit Refund(thisRefund.user, thisRefund.token, thisRefund.amount, block.timestamp);
    }

    function emergencyWithdraw(address[] memory tokens, uint256[] memory amounts, address recipient) external onlyExecutor {
        require(tokens.length == amounts.length, "Invalid data");
        require(claimPause, "Refunding");
        for (uint256 i; i < tokens.length; i++) {
            if (tokens[i] == address(0)) {
                TransferHelper.safeTransferETH(recipient, amounts[i]);
            } else {
                TransferHelper.safeTransfer(tokens[i], recipient, amounts[i]);
            }
            emit Withdraw(recipient, tokens[i], amounts[i]);
        }
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Caller is not the owner");
        _;
    }

    modifier onlyExecutor() {
        require(executor() == msg.sender, "Caller is not the executor");
        _;
    }

    modifier checkClaimAndNonReentrant() {
        require(block.timestamp >= claimStartTime && claimStartTime != 0, "Coming soon");
        require(!claimPause, "Refund suspended");
        require(_status != _ENTERED, "Reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

}
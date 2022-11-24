// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IERC20.sol";
import "./Pausable.sol";

contract PoolContact is Ownable, Pausable {

    IERC20 private USDT;

    struct Invest {
        address wallet;
        uint256 amount;
        uint256 rewardDate;
        uint256 withdrawalToDate;
    }

    uint256 rewardPercent = 5;
    uint256 totalInvests = 0;

    mapping(uint256 => Invest) private invests;

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    constructor(
        IERC20 usdtContract,
        uint256 _rewardPercent
    ) {
        USDT = usdtContract;

        rewardPercent = _rewardPercent;
    }

    function toPool(uint256 investId) public payable {
        uint256 _amount = msg.value;
        uint256 allowance = USDT.allowance(_msgSender(), address(this));
        require(allowance >= _amount, "Check the token allowance");

        bool sent = USDT.transferFrom(_msgSender(), address(this), _amount);
        require(sent, "Failed to send USDT");
        totalInvests = investId > totalInvests ? investId : totalInvests;
        invests[investId] = Invest(
            _msgSender(),
            _amount,
            block.timestamp + 2678400,
            block.timestamp
        );
    }

    function fromPool(
        uint256 investId,
        uint256 amount
    ) public whenNotPaused {
        require(invests[investId].amount >= amount, "Not enough amount");
        if (amount > 0 && invests[investId].amount > 0 && invests[investId].wallet == _msgSender() && block.timestamp <= invests[investId].withdrawalToDate) {
            invests[investId].amount = invests[investId].amount - amount;
            bool sent = USDT.transfer(_msgSender(), amount);
            if (!sent) {
                invests[investId].amount = invests[investId].amount + amount;
            }
            require(sent, "Failed to send");
        }
    }

    function reward() public onlyOwner {
        if (totalInvests > 0) {
            for (uint256 i = 1; i <= totalInvests; i++) {
                if (
                    invests[i].rewardDate > 1660000000 &&
                    block.timestamp >= invests[i].rewardDate &&
                    invests[i].amount > 0 &&
                    rewardPercent > 0
                ) {
                    invests[i].rewardDate = block.timestamp + 2764800;
                    invests[i].withdrawalToDate = block.timestamp + 86400;
                    uint256 _reward = invests[i].amount * rewardPercent / 100;
                    if (_reward > 0) {
                        uint256 balance = USDT.balanceOf(address(this));
                        if (balance >= _reward) {
                            bool sent = USDT.transfer(invests[i].wallet, _reward);
                            if (!sent) {
                                invests[i].rewardDate = block.timestamp;
                                invests[i].withdrawalToDate = block.timestamp;
                            }
                        } else {
                            invests[i].rewardDate = block.timestamp;
                            invests[i].withdrawalToDate = block.timestamp;
                        }
                    } else {
                        invests[i].rewardDate = block.timestamp;
                        invests[i].withdrawalToDate = block.timestamp;
                    }
                }
            }
        }
    }

    function getInvestById(uint _id) public view returns (address wallet, uint256 amount, uint256 rewardDate, uint256 withdrawalToDate) {
        return (invests[_id].wallet, invests[_id].amount, invests[_id].rewardDate, invests[_id].withdrawalToDate);
    }

    function getBlockTimestamp() public view returns (uint256 timestamp) {
        return block.timestamp;
    }

    function withdrawEth() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawUSDT() external onlyOwner {
        uint256 balance = USDT.balanceOf(address(this));
        require(balance > 0, "Not enough balance");
        USDT.transfer(owner(), balance);
    }
}
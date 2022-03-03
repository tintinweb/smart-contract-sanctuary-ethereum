/**
 *Submitted for verification at Etherscan.io on 2022-03-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bank {
    struct RechargeRecord {
        //充值金额
        uint256 amount;
        //充值时间
        uint256 time;
    }
    //用户充值金额
    mapping(address => RechargeRecord[]) public user;

    event Recharge(address indexed addr, uint256 amount, uint256 time);

    event Withdraw(address indexed addr, uint256 amount, uint256 time);

    //查询充值记录
    function getUser(address _addr)
        public
        view
        returns (RechargeRecord[] memory)
    {
        return user[_addr];
    }

    //充值主链币
    receive() external payable {
        user[msg.sender].push(
            RechargeRecord({amount: msg.value, time: block.timestamp})
        );
        emit Recharge(msg.sender, msg.value, block.timestamp);
    }

    //提现全部主链币
    function withdraw() public {
        require(address(this).balance > 0, "Sorry, your credit is running low");
        uint256 oldBalance = address(this).balance;
        (bool successc, ) = msg.sender.call{value: oldBalance}("");
        require(successc, "withdraw transfer failed");
        emit Withdraw(msg.sender, oldBalance, block.timestamp);
    }
}
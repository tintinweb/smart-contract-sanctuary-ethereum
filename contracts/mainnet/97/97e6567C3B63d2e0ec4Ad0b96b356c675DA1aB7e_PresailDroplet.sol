/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
}

library Address {
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


contract PresailDroplet {
    using SafeMath for uint256;
    using Address for address payable;

    function presailDistribute(address payable[] calldata recipients, uint256[] calldata values) external payable {
        require(recipients.length == values.length, "Recipients and values must have the same length");
        for (uint256 i = 0; i < recipients.length; i = i.add(1)) {
            require(recipients[i] != address(0), "Recipient cannot be zero address");
            recipients[i].sendValue(values[i]);
        }
        uint256 balance = address(this).balance;
        if (balance > 0)
            msg.sender.sendValue(balance);
    }

    function presailDistributeToken(IERC20 token, address[] calldata recipients, uint256[] calldata values) external {
        require(recipients.length == values.length, "Recipients and values must have the same length");
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i = i.add(1))
            total = total.add(values[i]);
        require(token.transferFrom(msg.sender, address(this), total), "Token transferFrom failed");
        for (uint256 i = 0; i < recipients.length; i = i.add(1)) {
            require(recipients[i] != address(0), "Recipient cannot be zero address");
            require(token.transfer(recipients[i], values[i]), "Token transfer failed");
        }
    }

    function presailDistributeTokenSimple(IERC20 token, address[] calldata recipients, uint256[] calldata values) external {
        require(recipients.length == values.length, "Recipients and values must have the same length");
        for (uint256 i = 0; i < recipients.length; i = i.add(1)) {
            require(recipients[i] != address(0), "Recipient cannot be zero address");
            require(token.transferFrom(msg.sender, recipients[i], values[i]), "Token transfer failed");
        }
    }
}
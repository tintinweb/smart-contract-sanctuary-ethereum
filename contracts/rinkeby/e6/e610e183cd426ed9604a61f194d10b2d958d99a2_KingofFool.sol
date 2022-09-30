/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

contract KingofFool is Context {
    using SafeMath for uint256;
    uint256 public index = 0;

    struct Deposit {
        address sender;
        uint256 amount;
        uint256 timestamp;
    }

    mapping(uint256 => Deposit) public deposits;

    event kingofFool(address sender, uint256 amount, uint256 timestamp);

    function deposit() payable public {
        uint256 amount = msg.value;
        require(amount > 0, "Amount must greater then 0");

        // increase the number of the deposits is using a counter

        deposits[index] = Deposit(
            _msgSender(),
            amount,
            block.timestamp
        );

        // Deposit storage _deposit = deposits[index];
        // _deposit.sender = _msgSender();
        // _deposit.amount = amount;
        // _deposit.timestamp = block.timestamp;

        if (index > 0) {
            Deposit storage _deposit = deposits[index-1];
            if(amount >= _deposit.amount.mul(1500000000000000000))
            {
                payable(_deposit.sender).transfer(amount);
                emit kingofFool(_msgSender(), amount, block.timestamp);
            }
        }

        index++;
    }
}
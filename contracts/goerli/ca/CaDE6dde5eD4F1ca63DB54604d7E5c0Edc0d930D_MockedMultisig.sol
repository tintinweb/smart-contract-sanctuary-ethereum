// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/// @dev A mock multisig function that calls the given executed function
contract MockedMultisig {
    event EthReceived(address indexed from, uint256 amount, uint256 blockNumber);

    constructor() payable {}

    function execute(address destination, bytes memory data) public {
        (bool success, bytes memory result) = destination.call(data);

        if (!success) {
            if (result.length == 0) revert();
            assembly {
                revert(add(32, result), mload(result))
            }
        }
    }

    receive() external payable {
        emit EthReceived(msg.sender, msg.value, block.number);
    }

    fallback() external payable {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
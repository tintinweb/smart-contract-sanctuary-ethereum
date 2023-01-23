// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Treasury {
    address private multisig;

    receive() external payable {}

    constructor(address multisig_) {
        multisig = multisig_;
    }

    modifier onlyMultiSig() {
        require(msg.sender == multisig, "Treasury: only multisig");
        _;
    }

    /**
     * @notice Withdraw funds from the contract
     * @param to address to send funds to
     * @param amount amount of funds to withdraw
     */
    function transfer(
        address token,
        address to,
        uint256 amount
    ) external onlyMultiSig {
        if (token == address(0)) {
            payable(to).transfer(amount);
        } else {
            (bool success, ) = token.call(
                abi.encodeWithSelector(0xa9059cbb, to, amount)
            );
            require(success, "Treasury: Transfer failed");
        }
    }

    function batchWithdraw(
        address token,
        address[] calldata depositAddress,
        address[] calldata withdrawAddress,
        uint256[] calldata withdrawAmounts
    ) public onlyMultiSig {
        require(
            depositAddress.length > 0,
            "Treasury: depositAddress length cannot be 0"
        );
        require(
            depositAddress.length == withdrawAddress.length,
            "Treasury: depositAddress and withdrawAddress length mismatch"
        );
        require(
            depositAddress.length == withdrawAmounts.length,
            "Treasury: depositAddress and withdrawalAmounts length mismatch"
        );
        for (uint256 i = 0; i < depositAddress.length; i++) {
            (bool success, ) = depositAddress[i].call(
                abi.encodeWithSelector(
                    bytes4(keccak256("withdraw(address,address,uint256)")),
                    token,
                    withdrawAddress[i],
                    withdrawAmounts[i]
                )
            );
            require(success, "Treasury: Transfer failed");
        }
    }
}
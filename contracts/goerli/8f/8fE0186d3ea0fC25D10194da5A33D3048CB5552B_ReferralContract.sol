//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract ReferralContract {
    function mint(uint256 _amount, address _contractAddress) external {
        (bool success, ) = _contractAddress.call(
            abi.encodeWithSignature("mint(uint256)", _amount)
        );

        require(success, "Mint failed");
    }
}
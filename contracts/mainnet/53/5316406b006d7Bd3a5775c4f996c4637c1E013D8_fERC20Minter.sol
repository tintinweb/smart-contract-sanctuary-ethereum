// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface fERC20 {
    function mint(address _to) payable external;
}

contract fERC20Minter {
    function bulkPaidMint(fERC20 token, address account, uint256 price, uint256 count) external payable returns (bool) {
        require(msg.value == price * count, "invilid eth sent");
        for (uint256 i = 0; i < count; i ++) {
            token.mint{value: price}(account);
        }
        return true;
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Airdrop {
    function airdropTokensByTransfer(
        IERC20 _token,
        address[] calldata _recipients,
        uint256[] calldata _amount
    ) public {
        for (uint8 i = 0; i < _recipients.length; i++) {
            _token.transfer(_recipients[i], _amount[i]);
        }
    }

    function airdropTokensByTransferFrom(
        IERC20 _token,
        address[] calldata _recipients,
        uint256[] calldata _amount
    ) public {
        for (uint8 i = 0; i < _recipients.length; i++) {
            _token.transferFrom(msg.sender, _recipients[i], _amount[i]);
        }
    }
}
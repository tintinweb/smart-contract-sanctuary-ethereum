//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// This contract is an example of stand alone contract not coming from ERC20.
contract Airdrop {
    //Airdrop of token from the smart contract to multiple addresses.
    function airdropTokensByTransfer(
        IERC20 _token,
        address[] calldata _recipients,
        uint256[] calldata _amount
    ) public {
        for (uint8 i = 0; i < _recipients.length; i++) {
            _token.transfer(_recipients[i], _amount[i]);
        }
    }

    //Airdrop of token by allowing another address to transfer token to multipple addresses.
    function airdropTokensByTransferFrom(
        IERC20 _token,
        address[] calldata _recipients,
        uint256[] calldata _amount
    ) public {
        for (uint8 i = 0; i < _recipients.length; i++) {
            _token.transferFrom(msg.sender, _recipients[i], _amount[i]);
        }
    }

    //Contract/Token Address: 0x78Dd671c552dFD911d99984B5a6b15FDE59642d2
}
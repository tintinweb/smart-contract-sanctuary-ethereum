/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

/**
██████╗░██╗░██████╗██████╗░███████╗███╗░░██╗░██████╗███████╗██████╗░
██╔══██╗██║██╔════╝██╔══██╗██╔════╝████╗░██║██╔════╝██╔════╝██╔══██╗
██║░░██║██║╚█████╗░██████╔╝█████╗░░██╔██╗██║╚█████╗░█████╗░░██████╔╝
██║░░██║██║░╚═══██╗██╔═══╝░██╔══╝░░██║╚████║░╚═══██╗██╔══╝░░██╔══██╗
██████╔╝██║██████╔╝██║░░░░░███████╗██║░╚███║██████╔╝███████╗██║░░██║
╚═════╝░╚═╝╚═════╝░╚═╝░░░░░╚══════╝╚═╝░░╚══╝╚═════╝░╚══════╝╚═╝░░╚═╝

[ Dispenser1155.sol - Contract for batch ERC-1155 token transfers ]

by Conductive Research 

We bring together everything that’s required to build token utility

Work with us 👉 https://www.conductive.ai

Follow us on twitter: @conductiveai
**/

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IERC1155 {
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
}

contract Dispenser1155 {
    function dispenseToken(IERC1155 token, address[] calldata recipients, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external {
        require(token.isApprovedForAll(msg.sender, address(this)), "Sender has not approved Dispenser1155 contract");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 preBalance = token.balanceOf(msg.sender, ids[i]);
            uint256 reqBalance = recipients.length * values[i];

            require(reqBalance <= preBalance, "Insufficient balance");
        }

        for (uint256 i = 0; i < recipients.length; i++) {
            token.safeBatchTransferFrom(msg.sender, recipients[i], ids, values, data);
        }
    }
}
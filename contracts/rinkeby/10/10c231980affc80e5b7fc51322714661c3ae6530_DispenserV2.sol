/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
    function safeTransferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function safeTransfer(address to, uint256 value) external returns (bool);
}

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface IERC1155 {
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
}

contract DispenserV2 {

    function dispenseETH(address payable[] calldata recipients, uint256[] calldata values) external payable {

        for (uint256 i = 0; i < recipients.length; i++)
           recipients[i].transfer(values[i]);
        uint256 balance = address(this).balance;
        if (balance > 0)
            payable(msg.sender).transfer(balance);
    }

    function dispenseERC20(IERC20 token, address payable[] calldata to, uint256[] calldata value)  external {
        require(to.length == value.length, "Receivers and amounts are different length!");
        for(uint256 i = 0; i <= to.length; i++) {
            require(token.safeTransferFrom(msg.sender, to[i], value[i]));
        }
    }

    function dispenseERC721(IERC721 token, address payable[] calldata to, uint256[] calldata value) external {
        require(to.length == value.length, "Receivers and amounts are different length!");
        for(uint256 i = 0; i <= to.length; i++) {
            token.safeTransferFrom(msg.sender, to[i], value[i]);
        }
    }

    function dispenseERC1155(IERC1155 token, address payable[] calldata to, uint256[] calldata id, uint256[] calldata value, bytes calldata data) external {
        require(to.length == id.length && id.length == value.length, "Receivers, ids and amounts are different length!");
        for (uint256 i = 0; i < id.length; i++) {
            uint256 preBalance = token.balanceOf(msg.sender, id[i]);
            uint256 reqBalance = to.length * value[i];

            require(reqBalance <= preBalance, "Insufficient balance");
        }

        for (uint256 i = 0; i < to.length; i++) {
            token.safeBatchTransferFrom(msg.sender, to[i], id, value, data);
        }
    }
}
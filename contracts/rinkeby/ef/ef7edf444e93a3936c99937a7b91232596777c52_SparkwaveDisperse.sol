/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface ERC721 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface IERC1155 {
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
}


contract SparkwaveDisperse {
    function disperseEther(address[] calldata recipients, uint256[] calldata values) external payable {
        for (uint256 i = 0; i < recipients.length; i++) {
            payable(recipients[i]).transfer(values[i]);
        }
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(msg.sender).transfer(balance);
        }
    }

    function disperseERC20(IERC20 token, address[] calldata recipients, uint256[] calldata values) external {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++){
            total += values[i];
        }
        require(token.transferFrom(msg.sender, address(this), total));
        for (uint256 i = 0; i < recipients.length; i++) {
            require(token.transfer(recipients[i], values[i]));
        }
    }

    function disperseERC721(ERC721 nftContract, address[] calldata recipients) public {
        require(nftContract.isApprovedForAll(msg.sender, address(this)), "Sender has not approved disperse contract");
        for(uint i = 0; i < recipients.length; i++){
            nftContract.transferFrom(msg.sender, recipients[i], i);
        }
    }

    function disperseERC1155(IERC1155 token, address[] calldata recipients, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external {
        require(token.isApprovedForAll(msg.sender, address(this)), "Sender has not approved disperse contract");

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
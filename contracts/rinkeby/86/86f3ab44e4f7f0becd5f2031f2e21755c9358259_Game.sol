/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint balance);

    function ownerOf(uint tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint tokenId) external;

    function safeTransferFrom(address from, address to, uint tokenId, bytes calldata data) external;

    function transferFrom(address from, address to, uint tokenId) external;

    function approve(address to, uint tokenId) external;

    function getApproved(uint tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Game {

    address private constant gold = 0x2517CECd00378C38AE1A2a55c01DC2511A2c0e71;
    address private constant NFT = 0x87e7922a5f316182A2c8dC268077Af0cdD4BcD5B;

    address owner;
    event AnswerIs (uint number);

    constructor (address _owner) {
        owner = _owner;
    }

    function Random() private view returns (uint) {
        return block.timestamp%12+1;
    }

    function Bet(uint TokenID, uint even, uint odd) public {
        require(IERC721(NFT).isApprovedForAll(msg.sender, address(this)) == true, "You haven't approved your NFT !");
        require(even+odd < 2, "You can only bet one side !");
        require(even+odd != 0, "You have to bet one side at least !");

        uint ans = Random();
        emit AnswerIs (ans);
    
        if (ans%2 == 1 && odd == 1) {
            IERC20(gold).transfer(msg.sender, 1);
        } else if (ans%2 == 0 && even == 1) {
            IERC20(gold).transfer(msg.sender, 1);
        } else {
            IERC721(NFT).transferFrom(msg.sender, owner, TokenID);
        }
    }

}
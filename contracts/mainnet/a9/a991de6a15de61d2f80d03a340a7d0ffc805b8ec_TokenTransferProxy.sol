// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Ownable} from "./Ownable.sol";
import {IERC20, SafeERC20} from "./SafeERC20.sol";
import {IERC721} from "./IERC721.sol";

contract TokenTransferProxy  is Ownable{
    using SafeERC20 for IERC20;

                        address public SocMetaMarket;
    address public SocMetaverse;

    function updateMarket(address exchange) public onlyOwner{
        require(exchange != address(0), "TokenTransferProxy: Exchange address invalid.");
        SocMetaMarket = exchange;
    }

    function updateMetaverse(address exchange) public onlyOwner{
        require(exchange != address(0), "TokenTransferProxy: Exchange address invalid.");
        SocMetaverse = exchange;
    }

    /**
     * @notice Transfer ERC721 token
     * @param collection address of the collection
     * @param from address of the sender
     * @param to address of the recipient
     * @param tokenId tokenId
     * @dev For ERC721, amount is not used
     */
    function transferERC721Token(
        address collection,
        address from,
        address to,
        uint256 tokenId
)  external {
        require(msg.sender == SocMetaMarket || msg.sender == SocMetaverse , "TokenTransferProxy: Only MasterNFT Exchange");
        // https://docs.openzeppelin.com/contracts/2.x/api/token/erc721#IERC721-safeTransferFrom
        require(from != address(0), "TokenTransferProxy: Invalid from");
        require(to != address(0), "TokenTransferProxy: Invalid to");
        require(IERC721(collection).ownerOf(tokenId) == from, "TokenTransferProxy: from is not the owner.");

        IERC721(collection).safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev Transfer tokens
     * @param token Token to transfer
     * @param from Address to charge fees
     * @param to Address to receive fees
     * @param amount Amount of protocol tokens to charge
     */
    function transferERC20Tokens(
        address token,
        address from,
        address to,
        uint256 amount
) external  {
        require(msg.sender == SocMetaMarket || msg.sender == SocMetaverse , "TokenTransferProxy: Only MasterNFT Exchange");
        require(from != address(0), "TokenTransferProxy: Invalid from");
        require(to != address(0), "TokenTransferProxy: Invalid to");
        require(amount <= IERC20(token).balanceOf(from), "TokenTransferProxy: have no enough balance");
        if (amount > 0) {
            IERC20(token).safeTransferFrom(from, to, amount);
        }
    }


}
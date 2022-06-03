pragma solidity 0.8.14;

//SPDX-License-Identifier: MIT

import "./Counters.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./SafeMath.sol";
import "./Token.sol";

contract Swap_NFT is Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private swapId;

    mapping (uint256 => uint256) swapEther;
    mapping (uint256 => address) swapTokenAddr;
    mapping (uint256 => uint256) swapTokenId;
    mapping (uint256 => address) swapTargetAddr;
    mapping (uint256 => uint256) swapTargetId;

    constructor() {
        swapId = 0;
    }

    // swap by ETHER
    function registerSwap(address targetAddr, uint256 targetTokenId) public payable returns (uint256) {
        require(msg.value > 0, "Ether amount must be greater than 0");
        
        uint256 id = swapId;
        swapId++;
        swapEther[id] = msg.value;
        swapTargetAddr[id] = targetAddr;
        swapTargetId[id] = targetTokenId;

        IERC721 tarNFT = IERC721(targetAddr);
        address tarOwner = tarNFT.ownerOf(targetTokenId);
        tarNFT.transferFrom(tarOwner, address(this), targetTokenId);
        return id;
    }

    // swap token and token
    function registerSwap(address sourceAddr, uint256 sourceId, address targetAddr, uint256 targetTokenId) public returns (uint256) {
        uint256 id = swapId;
        swapId++;
        swapEther[id] = 0;
        swapTokenAddr[id] = sourceAddr;
        swapTokenId[id] = sourceId;
        swapTargetAddr[id] = targetAddr;
        swapTargetId[id] = targetTokenId;

        IERC721 srcNFT = IERC721(sourceAddr);
        address srcOwner = srcNFT.ownerOf(sourceId);
        srcNFT.transferFrom(srcOwner, address(this), sourceId);
        return id;
    }

    function registerSwapNFT(address sourceAddr, uint256 sourceId, uint256 ethValue) public returns (uint256) {
        require(ethValue > 0, "Ether amount must be greater than 0");
        
        uint256 id = swapId;
        swapId++;
        swapEther[id] = 0;
        swapTokenAddr[id] = sourceAddr;
        swapTokenId[id] = sourceId;

        IERC721 srcNFT = IERC721(sourceAddr);
        address srcOwner = srcNFT.ownerOf(sourceId);
        srcNFT.transferFrom(srcOwner, address(this), sourceId);
        return id;
    }

    function applySwap(uint256 _swapId) public payable {
        address srcAddr = swapTokenAddr[_swapId];
        // uint256 srcId = swapTargetId[_swapId];

        // address tarAddr = swapTargetAddr[_swapId];
        uint256 tarId = swapTargetId[_swapId];

        // IERC721 srcNFT = IERC721(srcAddr);
        IERC721 tarNFT = IERC721(srcAddr);

        // address srcOwner = srcNFT.ownerOf(srcId);
        address tarOwner = tarNFT.ownerOf(tarId);

        // srcNFT.transfer(tarOwner, srcId);

        tarNFT.transferFrom(tarOwner, address(this), tarId);
    }

    function transferEther() public payable onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }
    
    // function to allow admin to transfer *any* NFT tokens from this contract..
    function transferAnyNftTokens(address tokenAddress, address recipient, uint256 tokenId) public onlyOwner {
        require(recipient != address(0), "ERC721: recipient is the zero address");
        IERC721 tknNFT = IERC721(tokenAddress);
        tknNFT.transferFrom(address(this), recipient, tokenId);
    }
    
    // function to allow admin to transfer *any* ERC20 tokens from this contract..
    function transferAnyERC20Tokens(address tokenAddress, address recipient, uint256 amount) public onlyOwner {
        require(amount > 0, "ERC20: amount must be greater than 0");
        require(recipient != address(0), "ERC20: recipient is the zero address");
        Token(tokenAddress).transfer(recipient, amount);
    }

}
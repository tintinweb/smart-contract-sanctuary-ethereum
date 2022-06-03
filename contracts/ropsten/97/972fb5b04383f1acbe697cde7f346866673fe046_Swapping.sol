pragma solidity 0.8.14;

//SPDX-License-Identifier: MIT

import "./Counters.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./SafeMath.sol";
import "./Token.sol";

contract Swapping is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    address private _adminWallet;
    
    mapping (uint256 => uint256) swapEther;
    mapping (uint256 => address) swapTokenAddr;
    mapping (uint256 => uint256) swapTokenId;
    mapping (uint256 => address) swapTargetAddr;
    mapping (uint256 => uint256) swapTargetId;

    constructor() {
        _adminWallet = owner();
    }

    function setAdminWallet(address adminWallet) public onlyOwner {
        _adminWallet = adminWallet;
    }

    // Swap by Eth
    function buyNFT(address targetAddr, uint256 targetTokenId) public payable {
        require(msg.value > 0, "Ether amount must be greater than 0");
        
        uint256 id = _tokenIds.current();
        _tokenIds.increment();
        swapEther[id] = msg.value;
        swapTargetAddr[id] = targetAddr;
        swapTargetId[id] = targetTokenId;
    }

    // Swap Token and Token
    function swapNFT(address sourceAddr, uint256 sourceId, address targetAddr, uint256 targetTokenId) public {
        uint256 id = _tokenIds.current();
        _tokenIds.increment();
        swapEther[id] = 0;
        swapTokenAddr[id] = sourceAddr;
        swapTokenId[id] = sourceId;
        swapTargetAddr[id] = targetAddr;
        swapTargetId[id] = targetTokenId;

        IERC721 srcNFT = IERC721(sourceAddr);
        address srcOwner = srcNFT.ownerOf(sourceId);
        srcNFT.transferFrom(srcOwner, address(this), sourceId);
    }

    // Sell NFT
    function sellNFT(address sourceAddr, uint256 sourceId, uint256 ethPrice) public {
        
        uint256 id = _tokenIds.current();
        _tokenIds.increment();
        swapEther[id] = ethPrice;
        swapTokenAddr[id] = sourceAddr;
        swapTokenId[id] = sourceId;

        IERC721 srcNFT = IERC721(sourceAddr);
        address srcOwner = srcNFT.ownerOf(sourceId);
        srcNFT.transferFrom(srcOwner, address(this), sourceId);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getAdminWallet() public view returns (address) {
        return _adminWallet;
    }

    function transferEther(address payable _to) public payable onlyOwner {
        // require(payable(_msgSender()).send(address(this).balance));
        (bool sent, ) = _to.call{value: getContractBalance()}("");
        require(sent, "Failed to send Ether");
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
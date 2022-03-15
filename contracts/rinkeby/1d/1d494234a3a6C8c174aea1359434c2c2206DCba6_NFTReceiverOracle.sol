pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./IERC721.sol";
import "./INftBettingCore.sol";

contract NFTReceiverOracle is Ownable {
    address private oracleAddress;
    event NftReceivedForMatch(address ownedContractAddress, uint256 ownedTokenId, address originalOwner, address targetContractAddress, uint256 targetTokenId, uint256 targetChainId);
    event NftReceivedForGamblrMatch(address ownedContractAddress, uint256 ownedTokenId, uint targetIndex);

    constructor(){
    } 

    function updateBscOracleAddress(address oracleWalletAddress) public onlyOwner {
        oracleAddress = oracleWalletAddress;
    } 
   
    function startNftOwnedMatch(address ownedContractAddress, uint256 ownedTokenId, address targetContractAddress, uint256 targetTokenId, uint256 targetChainId) public payable{
        require(msg.value >= 1, "Wrong value sended");
        creditOracle();

        IERC721 nftContract = IERC721(ownedContractAddress);
        address originalOwner = nftContract.ownerOf(ownedTokenId);
        nftContract.safeTransferFrom(_msgSender(), address(this), ownedTokenId);

        emit NftReceivedForMatch(ownedContractAddress, ownedTokenId, originalOwner, targetContractAddress, targetTokenId, targetChainId);
    }
   
    function startNftGamblrMatch(address ownedContractAddress, uint256 ownedTokenId, uint targetIndex) public payable{
        require(msg.value >= 1, "Wrong value sended");
        creditOracle();

        IERC721 nftContract = IERC721(ownedContractAddress);
        nftContract.safeTransferFrom(_msgSender(), address(this), ownedTokenId);

        emit NftReceivedForGamblrMatch(ownedContractAddress, ownedTokenId, targetIndex);
    }
    
    function creditOracle() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(oracleAddress).transfer(balance);
    }
    
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
}
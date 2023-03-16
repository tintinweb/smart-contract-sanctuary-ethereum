// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./ERC721.sol";

import "./Ownable.sol";

import "./IConataNFT.sol";

// 
contract MetaaniContestSeason1 is IConataNFT, ERC721, Ownable{
    uint public limitedAmount = 100;
    uint public  tokenIdCount = 1;
    uint private _mintedAmount = 0;
    uint private _burnedAmount = 0;
    string private _ipfs_base = "ipfs://QmcpSsbQuQb6Z8CaSyjv26eVC1wCbMVVz2k3CRBFykBei9/";
    //
    address constant fundsWallet           = 0x8837391C2634b62C4fCF4f0b01F0772A743A4Cf3;
    address constant fundsRescueSpareKey   = 0xbDc378A75Fe1d1b53AdB3025541174B79474845b;
    address constant fundsRescueDestWallet = 0xeecE4544101f7C7198157c74A1cBfE12aa86718B;
    //
    constructor() ERC721("Metaani Contest Season1", "MCS1") {}

    
    //
    function mint(bytes calldata data) override(IConataNFT) external payable{
        revert("Not Implement");
    }
    function mint() override(IConataNFT) external payable{
        revert("Not Implement");
    }
    //
    function getOpenedMintTermNames() override(IConataNFT) external view returns(string[] memory){
        revert("Not Implement");
    }


    

    
    function totalSupply() override(IConataNFT) external view returns(uint256){
        return _mintedAmount - _burnedAmount;
    }

    //
    function burn(uint tokenId, bytes calldata data) override(IConataNFT) external{
        require(_msgSender() == ownerOf(tokenId), "Not Owner Of Token");
        _burn(tokenId);
        _burnedAmount++;
    }


    

    //
    function _baseURI() internal view override(ERC721) returns (string memory) {
        return _ipfs_base;
    }
    
    //
    function _minter(address account) internal{
        require(_mintedAmount < limitedAmount, "Limited Amount");
        _safeMint( account , tokenIdCount);
        tokenIdCount++;
        _mintedAmount++;
    }

    

    
    function giveaway(address[] memory accounts, uint len) external onlyOwner{
        require(accounts.length == len, "Invalid Length");
        for(uint i=0; i < len; i++){
            _minter(accounts[i]);
        }
    }

    
    function setLimitedAmount(uint amount) external onlyOwner{
        limitedAmount = amount;
    }

    
    function setURI(string memory newURI) override(IConataNFT) external onlyOwner {
        _ipfs_base = newURI;
    }

    //
    function withdraw() override(IConataNFT) external {
        require(_msgSender() == fundsWallet);
        uint balance = address(this).balance;
        payable(fundsWallet).transfer(balance);
    }
    function withdrawSpare() override(IConataNFT) external {
        require(_msgSender() == fundsRescueSpareKey);
        uint balance = address(this).balance;
        payable(fundsRescueDestWallet).transfer(balance);
    }

}
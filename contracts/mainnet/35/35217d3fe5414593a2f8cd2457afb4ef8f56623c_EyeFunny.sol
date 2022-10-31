// SPDX-License-Identifier: NONE

pragma solidity ^0.8.10;

import "./OpenzeppelinERC721.sol";
import "./OpenZeppelinMerkleProof.sol";

contract EyeFunny is ERC721Enumerable {

    address public owner;

    string ipfsBase = "ipfs://QmWpjzkaxA64LwJ9TsWutActDjw7BYfu6jw3rGvtgMFXVc/";

    bool privateMintStarted = false;
    bool publicMintStarted = false;

    mapping(uint => bool) public isMinted;
    mapping(address => uint) public addressMintedMap;

    uint public privateSalePrice = 0.15 ether;
    uint public publicSalePrice = 0.3 ether;
    uint public maxMintAmout = 2;

    address eyeFunnyWallet = 0xFDD2B857ce451E9246580a841EB2e8BeF52710e5;
    address eyeFunnyDeployWallet = 0xe79ea19d89357d594E736951cEeD08dbC142fB33;
    bytes32 allowListRoot = 0x37ad0982904787419523e407958377f77b92b71fa74ffe7b7b0d7be4b188c12f;

    constructor() ERC721("EyeFunny NFT" , "EFN" ) {
        owner = eyeFunnyDeployWallet;        
        for(uint256 i=0; i<= 95; i++){
            _safeMint(eyeFunnyDeployWallet , i);
            isMinted[i] = true;
        }
    }

    function setPrivateSalePrice(uint _price) public {
        require(_msgSender() == owner);
        privateSalePrice = _price;
    }
   
    function setPublicSalePrice(uint _price) public {
        require(_msgSender() == owner);
        publicSalePrice = _price;
    }

    function executeMint(uint _nftId) internal {
        require(isMinted[_nftId] == false, "already minted");
        _safeMint(msg.sender,_nftId);
        addressMintedMap[msg.sender]++;
        isMinted[_nftId] = true;
        uint balance = address(this).balance;
        payable(eyeFunnyWallet).transfer(balance);
    }

    function publicSaleMint(uint[] memory _nftIds) public payable {
        require(msg.value == publicSalePrice * _nftIds.length);
        require(publicMintStarted,"public sale not started");
        for(uint256 i=0; i<_nftIds.length ;i++){
          require(96 <= _nftIds[i] && _nftIds[i] < 1152, "invalid nft id");
          executeMint(_nftIds[i]);
        }
    }

    function privateSaleMint(address account, bytes32[] calldata proof , uint[] memory _nftIds) public payable {
        require(privateMintStarted,"private sale not started");
        require(msg.value == privateSalePrice * _nftIds.length);
        require(checkRedeem(account, proof) > 0,"account is not in allowlist" );
        require(msg.sender == account);
        for(uint256 i=0; i<_nftIds.length ;i++){
          require(96 <= _nftIds[i] && _nftIds[i] < 1152, "invalid nft id");
          require(addressMintedMap[msg.sender] < maxMintAmout , "mint amount over");
          executeMint(_nftIds[i]);
        }
    }

    function checkRedeem(address account,bytes32[] calldata proof ) public view returns(uint) {
        if(_verify(_leaf(account), proof)){
            return maxMintAmout;
        }else {
            return 0;
        }
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns(bool) {
        return MerkleProof.verify(proof, allowListRoot, leaf);
    }
    
    
    function teamMint(uint _startId)public {    
        uint mintedNum = 0;
        require (msg.sender == owner);
        for(uint i=0; mintedNum<20; i++) {
        if(isMinted[_startId + i] == false){
            _safeMint(msg.sender , _startId + i);
            isMinted[_startId + i] = true;
            mintedNum++;
            }
        }
    }

    function notMintedNFT(uint tokenId) public view returns (uint){
        require(tokenId < 1152, "not exist.");
        require(0 <= tokenId, "not exist.");
        require(isMinted[tokenId] == false, "already minted.");
        return tokenId;    
    }

    function _baseURI()internal view override returns(string memory){
        return ipfsBase;
    }

    function setBaseURI(string memory _ipfsBase) public {
        require(_msgSender() == owner);
        ipfsBase = _ipfsBase;
    }

    function privateMintStart() public {
        require(_msgSender() == owner);
        privateMintStarted = true;
    }

    function privateMintStop() public {
        require(_msgSender() == owner);
        privateMintStarted = false;
    }
    
    function publicMintStart() public {
        require(_msgSender() == owner);
        publicMintStarted = true;
    }

    function publicMintStop() public {
        require(_msgSender() == owner);
        publicMintStarted = false;
    }

    function withdraw() public {
        require(_msgSender() == owner);
        uint balance = address(this).balance;
        payable(eyeFunnyWallet).transfer(balance);
    }

    function tokenURI(uint256 _tokenId) public view override returns(string memory) {
        require(_exists(_tokenId));
        return super.tokenURI(_tokenId);
    }
}
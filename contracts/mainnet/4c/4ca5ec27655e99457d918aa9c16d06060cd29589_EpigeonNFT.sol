// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.4.11;

import "./nf-token-enumerable.sol";
import "./EpigeonInterfaces.sol";

//----------------------------------------------------------------------------------

contract EpigeonNFT is NFTokenEnumerable{
    IEpigeon public epigeon;
      
    address public owner;
    string public name;
    string public symbol;
    mapping (uint256 => address) internal idtoCryptoPigeon;
    mapping (address => uint256) internal cryptoPigeonToId;
    uint256 public mintingPrice = 1000000000000000;
    uint256 public highestTokenId;
    bool public freeMintEnabled;
    mapping (address => uint256) internal approvedTokenPrice;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor (string memory _name, string memory _symbol, address _epigeon){
        owner = msg.sender;
        epigeon = IEpigeon(_epigeon);
        name = _name;
        symbol = _symbol;
        highestTokenId = 0;
    }
    
    function burn(uint256 tokenId) public {
        require(msg.sender == ICryptoPigeon(idtoCryptoPigeon[tokenId]).owner());
        require(epigeon.nftContractAddress() == address(this));
        epigeon.burnPigeon(idtoCryptoPigeon[tokenId]);
        delete cryptoPigeonToId[idtoCryptoPigeon[tokenId]];
        delete idtoCryptoPigeon[tokenId];
        super._burn(tokenId);
    }
    
    function burnPigeonToken(uint256 tokenId) public {
        require(msg.sender == ICryptoPigeon(idtoCryptoPigeon[tokenId]).owner());
        require(epigeon.nftContractAddress() == address(this));
        delete cryptoPigeonToId[idtoCryptoPigeon[tokenId]];
        delete idtoCryptoPigeon[tokenId];
        super._burn(tokenId);
    }
    
    function isTokenizedPigeon(address pigeon) public view returns (bool tokenized){
        return idtoCryptoPigeon[cryptoPigeonToId[pigeon]] == pigeon;
    }
    
    function mintingTokenPrice(address ERC20Token) public view returns (uint256 price){
        return approvedTokenPrice[ERC20Token];
    }
    
    function mintForEther(uint256 factoryId) public payable {
        require(msg.value >= mintingPrice + epigeon.getPigeonPriceForFactory(factoryId), "Not enough value");      
        _mintForAddress(msg.sender, factoryId);
    }
    
    function mintForFree() public {
        require(freeMintEnabled || msg.sender == owner);                
        _mintForAddress(msg.sender, epigeon.getLastFactoryId());
    }
    
    function mintForToken(address ERC20Token, uint256 factoryId) public returns (bool){
        require (approvedTokenPrice[ERC20Token] > 0);
        require (epigeon.getPigeonTokenPriceForFactory(ERC20Token, factoryId) > 0);
        uint256 price = approvedTokenPrice[ERC20Token] + epigeon.getPigeonTokenPriceForFactory(ERC20Token, factoryId);
        if (IERC20(ERC20Token).transferFrom(msg.sender, owner, price) == true)
        {
            _mintForAddress(msg.sender, factoryId);
            return true;
        }
        else{
            return false;
        }
    }
    
    function payout() public {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
    }
    
    function pigeonAddressToToken(address pigeon) public view returns (uint256  tokenId){
        return cryptoPigeonToId[pigeon];
    }
    
    function setFreeMintEnabled(bool enabled) public {
        require(msg.sender == owner);
        freeMintEnabled = enabled;
    }
    
    function setMintingPrice(uint256 price) public {
        require(msg.sender == owner);
        mintingPrice = price;
    }
    
    function setMintingPrice(address ERC20Token, uint256 price) public {
        require(msg.sender == owner);
        approvedTokenPrice[ERC20Token] = price;
    }
    
    function tokenContractAddress(uint256  tokenId) public view validNFToken(tokenId) returns (address rpigeon){
        return idtoCryptoPigeon[tokenId];
    }
    
    function tokenizePigeon(address pigeon) public payable{
        require(msg.value >= mintingPrice, "Not enough value");
        require(cryptoPigeonToId[pigeon] == 0);
        require(ICryptoPigeon(pigeon).owner() == msg.sender);
        require(ICryptoPigeon(pigeon).iAmPigeon());
        require(epigeon.validPigeon(pigeon, msg.sender));
        require(epigeon.nftContractAddress() == address(this));
        highestTokenId++;
        uint256 tokenId = highestTokenId;
        super._mint(msg.sender, tokenId);
        _setTokenContractAddress(tokenId, pigeon);
    }
    
    function tokenURI(uint256 tokenId) public view returns (string metadata){
        metadata = IPigeonFactory(epigeon.getFactoryAddresstoId(ICryptoPigeon(idtoCryptoPigeon[tokenId]).factoryId())).getMetaDataForPigeon(idtoCryptoPigeon[tokenId]);
        return metadata;
    }
    
    function _mintForAddress(address to, uint256 factoryId) internal {
        require(epigeon.nftContractAddress() == address(this));
        highestTokenId++;
        uint256 tokenId = highestTokenId;
        address pigeon = epigeon.createCryptoPigeonNFT(to, factoryId);
        super._mint(to, tokenId);
        _setTokenContractAddress(tokenId, pigeon);
    }
    
    function _setTokenContractAddress(uint256  tokenId, address  pigeon) internal validNFToken(tokenId) {
        idtoCryptoPigeon[tokenId] = pigeon;
        cryptoPigeonToId[pigeon] = tokenId;
    }
    
    function transferOwnership(address newOwner) public {    
        require(owner == msg.sender, "Only owner");
        require(newOwner != address(0), "Zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner.transfer(address(this).balance);
        owner = newOwner;
    }
    
    function _transfer(address to, uint256 tokenId) internal {
        require(epigeon.nftContractAddress() == address(this));
        epigeon.transferPigeon(ICryptoPigeon(idtoCryptoPigeon[tokenId]).owner(), to, idtoCryptoPigeon[tokenId]);
        super._transfer(to, tokenId);
    }
}
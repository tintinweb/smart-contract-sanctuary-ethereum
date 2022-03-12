// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract EZYMETAVERSE_NFT is ERC721Enumerable, Ownable, Pausable {
    
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    uint256 private maxSupply = 10000;

    uint256 private token_id = 0;

    uint256 private publicSaleStartTime;

    uint256 private publicSaleEndTime;

    uint256 private publicSalePrice;

    uint256 private revealTime = 172800; 

    string private notRevealURI;

    mapping(address => bool) private whitelistUsers;

    mapping(address => uint256) private ownedToken;

    event Mint(address user, uint256 count, uint256 amount, uint256 time);

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function publicSaleMint(address _to ,uint256 _mintAmount) public payable whenNotPaused{
        require(publicSaleStartTime <= block.timestamp && publicSaleEndTime > block.timestamp, "Sale ended or not started yet");
        require(isWhitelisted(_to), "You are not whitelisted");
        require(_mintAmount > 0, "No amount to mint");    
        require(totalSupply() + _mintAmount <= maxSupply, "Supply limit reached!");        
        require(msg.value >= publicSalePrice * _mintAmount, "Wrong price!");  
        require(ownedToken[_to] + _mintAmount <= 20, "You can't buy more tokens");      
        for (uint256 i = 0; i < _mintAmount; i++) {
            token_id++;
            _safeMint(_to, token_id);
        }
        ownedToken[_to] += _mintAmount;
        emit Mint(_to, _mintAmount, msg.value, block.timestamp);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
   
    function setBaseURI(string memory _baseURI) public onlyOwner {
        _setBaseURI(_baseURI);
    }  

    function setPublicSalePrice(uint256 _newPrice) public onlyOwner {
        publicSalePrice = _newPrice;
    }

    function setNotRevealURI(string memory _URI) public onlyOwner {
        notRevealURI = _URI;
    }

    function setPublicSaleStartTime(uint256 _time) public onlyOwner {
        publicSaleStartTime = _time;
    }

    function changeRevealTime(uint256 _time) public onlyOwner{
        revealTime = _time;
    } 

    function setPublicSaleEndTime(uint256 _time) public onlyOwner {
        publicSaleEndTime = _time;
    }

    function whitelist(address _account) public onlyOwner {      
        whitelistUsers[_account] = true;      
    }

    function burn(uint256 _tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(_tokenId);        
    }

    function removeWhitelistedUsers(address _account) public onlyOwner {      
        whitelistUsers[_account] = false;       
    }

    function getPublicSalePrice() public view returns (uint256) {
        return publicSalePrice;
    }

    function getPublicSaleStartTime() public view returns (uint256) {
        return publicSaleStartTime;
    }

    function getPublicSaleEndTime() public view returns (uint256) {
        return publicSaleEndTime;
    }

    function tokenOwner(address _user) public view returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_user);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_user, i);
        }
        return tokenIds;
    }

    function isWhitelisted(address _user) public view returns (bool) {
       return whitelistUsers[_user];
    }

    function tokenURI(uint256 _tokenId) public view  override returns (string memory)
    {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(publicSaleEndTime + revealTime >= block.timestamp){
            return notRevealURI;
        }else {
            return super.tokenURI(_tokenId);
        }
    }
}
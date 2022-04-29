// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";


contract NFT is ERC721Enumerable, Ownable, Pausable {

    constructor(address _wallet1, address _wallet2) ERC721("NFT", "RNFT") {
        beneficiaryWallet1 = _wallet1;
        beneficiaryWallet2 = _wallet2;
    }

    uint256 private MAX_SUPPLY = 10000;

    uint256 private preSaleStartDate;

    uint256 private preSaleEndDate;

    uint256 private presalePrice = 10000000000000; 

    address private beneficiaryWallet1;  

    address private beneficiaryWallet2;

    uint256 private tokenID;

    mapping(address => bool) private whitelistUsers;

    event PresaleMint(address user, uint256 count, uint256 amount, uint256 time);

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function preSaleMint(address _to ,uint256 _mintAmount) public payable whenNotPaused{
        require(preSaleStartDate <= block.timestamp && preSaleEndDate > block.timestamp, "Presale ended or not started yet");
        require(isWhitelisted(_to), "User is not whitelisted");      
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, "Exceeds maximum supply");
        require(_mintAmount > 0, "No amount to mint");              
        require(msg.value >= presalePrice * _mintAmount, "Wrong price!");        
        for (uint256 i = 1; i <= _mintAmount; i++) {
            tokenID++;
            _safeMint(_to, tokenID);
        }
        uint256 amount = (address(this).balance * 80) / (100);
        payable(beneficiaryWallet1).transfer((amount * 70) / 100);
        payable(beneficiaryWallet2).transfer((amount * 30) / 100);
        emit PresaleMint(_to, _mintAmount, msg.value, block.timestamp);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
   
    function setBaseURI(string memory _baseURI) public onlyOwner {
        _setBaseURI(_baseURI);
    }  

    function setPresalePrice(uint256 _newPrice) public onlyOwner {
        presalePrice = _newPrice;
    }

    function setPresaleStartTime(uint256 _time) public onlyOwner {
        preSaleStartDate = _time;
    }

    function setPresaleEndTime(uint256 _time) public onlyOwner {
        preSaleEndDate = _time;
    }

    function whitelist(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelistUsers[_addresses[i]] = true;
        }
    }

    function burn(uint256 _tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(_tokenId);        
    }

    function removeWhitelistedUsers(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelistUsers[_addresses[i]] = false;
        }
    }

    function getPreSalePrice() public view returns (uint256) {
        return presalePrice;
    }

    function getPreSaleStartTime() public view returns (uint256) {
        return preSaleStartDate;
    }

    function getPreSaleEndTime() public view returns (uint256) {
        return preSaleEndDate;
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
        return super.tokenURI(_tokenId);    
    }

 
}
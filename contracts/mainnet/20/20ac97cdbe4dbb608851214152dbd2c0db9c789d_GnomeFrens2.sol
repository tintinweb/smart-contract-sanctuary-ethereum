// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./ERC721Enumerable.sol";

contract GnomeFrens2 is ERC721Enumerable, Ownable, PaymentSplitter {
    bool    public              revealed                = false;
    uint256 public              saleStatus              = 0; // 0 closed, 1 public
    uint256 public              MAX_SUPPLY              = 1500;
    uint256 public              MAX_GIVEAWAY            = 50;
    uint256 public              MAX_FREE                = 350;

    uint256 public constant     MAX_PER_TX              = 20;
    uint256 public              priceInWei              = 0.02 ether;

    uint256 public              FREE_MAX_PER_ADDR       = 2;

    string  public              provenance;
    string  public              baseURI;
    address public              proxyRegistryAddress    = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    mapping(address => bool) public projectProxy;
    mapping(address => uint) public addressToMinted;

    constructor(
        address[] memory _payees,
        uint256[] memory _paymentShares
    )
        ERC721("Gnome Frens V2 NFT", "GFv2NFT") 
        PaymentSplitter(_payees, _paymentShares)
    {    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setPrice(uint256 _priceInWei) public onlyOwner {
        priceInWei = _priceInWei;
    }

    function setMaxFree(uint256 _maxFree) public onlyOwner {
        MAX_FREE = _maxFree;
    }

    function setMaxFreePerAddr(uint256 _maxFreePerAddr) public onlyOwner {
        FREE_MAX_PER_ADDR = _maxFreePerAddr;
    }

    function setRevealed() public onlyOwner {
        revealed = !revealed;
    }

    function setProvenance(string memory _provenance) public onlyOwner {
        provenance = _provenance;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (revealed == false) {
            return string (abi.encodePacked(baseURI, "unrevealed.json"));
        }
        else {
            require(_exists(_tokenId), "Token does not exist.");
            return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json"));
        }
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function setSaleStatus(uint256 _status) external onlyOwner {
        require(saleStatus <= 1 && saleStatus >= 0, "Invalid status.");
        saleStatus = _status;
    }

    function mint(uint256 count) public payable {
        uint256 totalSupply = _owners.length;
        require(totalSupply + count <= MAX_SUPPLY, "Exceeds max supply.");
        if (saleStatus == 1 && totalSupply < MAX_FREE) {
            require(msg.sender == tx.origin, 'No bots in the free mint.');
            require(addressToMinted[_msgSender()] + count <= FREE_MAX_PER_ADDR, "Exceeds free max per address."); 
            addressToMinted[_msgSender()] += count;
        }  
        else if (saleStatus == 1) {
            require(count <= MAX_PER_TX, "Exceeds max per transaction.");
            require(count * priceInWei == msg.value, "Invalid funds provided.");
        } 
        else {
            require(false, "Sale not open.");
        }
        
        for(uint i; i < count; i++) { 
            _mint(_msgSender(), totalSupply + i);
        }
    }

    function promoMint(uint _qty, address _to) public onlyOwner {
        require(MAX_GIVEAWAY - _qty >= 0, "Exceeds max giveaway.");
        uint256 totalSupply = _owners.length;
        require(totalSupply + _qty <= MAX_SUPPLY, "Excedes max supply.");
        for (uint i = 0; i < _qty; i++) {
            _mint(_to, totalSupply + i);
        }
        MAX_GIVEAWAY -= _qty;
    }

    function burn(uint256 tokenId) public { 
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        _burn(tokenId);
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function batchTransferFrom(address _from, address _to, uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function batchSafeTransferFrom(address _from, address _to, uint256[] memory _tokenIds, bytes memory data_) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }

    function isOwnerOf(address account, uint256[] calldata _tokenIds) external view returns (bool){
        for(uint256 i; i < _tokenIds.length; ++i ){
            if(_owners[_tokenIds[i]] != account)
                return false;
        }

        return true;
    }

    function isApprovedForAll(address _owner, address operator) public view override(ERC721) returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }
}

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
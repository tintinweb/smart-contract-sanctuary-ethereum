// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract BURN1NFT is ERC721Enumerable, Ownable {
    string  public              baseURI             = "https://mint.burn1.today/tokens/";
    
    address public              proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    address public              payee1               = 0xDd5B50F91c336B6BFdb2AD8d5EEc202446B4942e;
    address public              payee2               = 0x2f08D19E7Fe9150A75944A2c2589c2dE1537944b;
    address public              payee3               = 0xBD2BFE0E9E8b2C533Bc102266b66a0aF312f6186;
    address public              payee4               = 0xf2ad5aa8387353De80c46882efa1bC5cF68a9e72;

    bytes32 public              whitelistMerkleRoot;

    uint256 public              saleStatus          = 0; // 0 closed, 1 BL, 2 WL, 3 PUBLIC
    uint256 public constant     MAX_SUPPLY          = 4200;
    uint256 public              MAX_GIVEAWAY        = 100;

    uint256 public constant     MAX_PER_TX          = 20;
    uint256 public              priceInWei          = 0.42 ether;

    uint256 public constant     WL_MAX_PER_TX       = 20;
    uint256 public              WL_priceInWei       = 0.33 ether;

    mapping(address => bool) public projectProxy;
    mapping(address => uint) public addressToMinted;

    string public               PROVENANCE_HASH;

    constructor()
        ERC721("Where There is Smoke There is Fire", "WTISTIF")
        {}    

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setMetaDataProvenanceHash(string memory _hash) public onlyOwner {
        PROVENANCE_HASH = _hash;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json"));
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot) external onlyOwner {
        // don't forget to prepend: 0x
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function setPriceInWei(uint256 _priceInWei) external onlyOwner {
        priceInWei = _priceInWei;
    }

    function setWLPPriceInWei(uint256 _WLPPriceInWei) external onlyOwner {
        WL_priceInWei = _WLPPriceInWei;
    }

    function setSaleStatus(uint256 _status) external onlyOwner {
        require(saleStatus < 4 && saleStatus >= 0, "Invalid status.");
        saleStatus = _status;
    }

    function updatePayee(address _payee, uint256 _index) external onlyOwner {
        require(_index > 0 && _index <= 4, "Invalid index.");
        if (_index == 1) {
            payee1 = _payee;
        } else if (_index == 2) {
            payee2 = _payee;
        } else if (_index == 3) {
            payee3 = _payee;
        } else if (_index == 4) {
            payee4 = _payee;
        }
    }

    function mint(uint256 count, bytes32[] calldata proof) public payable {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        uint256 totalSupply = _owners.length;
        require(totalSupply + count < MAX_SUPPLY, "Excedes max supply.");
        if (saleStatus == 1) {
            require(MerkleProof.verify(proof, whitelistMerkleRoot, leaf), 'Not on whitelist. Merkle Proof fail.');
            require(addressToMinted[_msgSender()] + count <= WL_MAX_PER_TX, "Exceeds whitelist supply"); 
            require(count * WL_priceInWei == msg.value, "Invalid funds provided.");
            addressToMinted[_msgSender()] += count;
        }  else if (saleStatus == 2) {
            require(count < MAX_PER_TX, "Exceeds max per transaction.");
            require(count * priceInWei == msg.value, "Invalid funds provided.");
        } else {
            require(false, "Sale not open.");
        }
        
        for(uint i; i < count; i++) { 
            _mint(_msgSender(), totalSupply + i);
        }
    }

    function promoMint(uint _qty, address _to) public onlyOwner {
        require(MAX_GIVEAWAY - _qty >= 0, "Exceeds max giveaway.");
        uint256 totalSupply = _owners.length;
        require(totalSupply + _qty < MAX_SUPPLY, "Excedes max supply.");
        for (uint i = 0; i < _qty; i++) {
            _mint(_to, totalSupply + i);
        }
        MAX_GIVEAWAY -= _qty;
    }

    function burn(uint256 tokenId) public { 
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        _burn(tokenId);
    }

    function withdraw() public  {
        (bool success , ) = payee1.call{value: address(this).balance * 6500 / 10000}("");
        require(success, "Failed to send to payee1.");
        (bool success2, ) = payee2.call{value: address(this).balance * 1125 / 10000}("");
        require(success2, "Failed to send to payee2.");
        (bool success3, ) = payee3.call{value: address(this).balance *  375 / 10000}("");
        require(success3, "Failed to send to payee3.");
        (bool success4, ) = payee4.call{value: address(this).balance * 2000 / 10000}("");
        require(success4, "Failed to send to payee4.");
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

    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
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
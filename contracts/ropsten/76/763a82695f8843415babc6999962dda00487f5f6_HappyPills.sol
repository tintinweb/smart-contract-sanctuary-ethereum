// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract HappyPills is ERC721Enumerable, Ownable {
    string  public              baseURI;

    address public              proxyRegistryAddress;
    address private             walletA = 0x2F98c28881B5405482eBD01DaCbE1E661Ed52855;

    uint256 public              MAX_SUPPLY;

    uint256 public constant     MAX_PER_WALLET = 3;
    uint256 public              price = 0.08 ether;

    mapping(address => bool) public projectProxy;
    mapping(address => uint) public publicsaleMints;

    constructor(
        string memory _baseURI,
        address _proxyRegistryAddress
    )
    ERC721("HappyPills", "PILLS")
    {
        baseURI = _baseURI;
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function toggleProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function togglePublicSale(uint256 _MAX_SUPPLY) external onlyOwner {
        require(_MAX_SUPPLY <= 4000, "max 4000");
        MAX_SUPPLY = _MAX_SUPPLY;
    }

    function publicMint(uint256 count) public payable {
        uint256 totalSupply = _owners.length;
        require(totalSupply + count <= MAX_SUPPLY, "Exceeds max supply.");
        require(count * price == msg.value, "Invalid funds provided.");
        require(publicsaleMints[msg.sender] + count <= MAX_PER_WALLET, "Per wallet mint limit");

        for(uint i; i < count; i++) {
            _mint(_msgSender(), totalSupply + i);
            publicsaleMints[msg.sender]++;
        }
    }

    function airdropMint(uint256 count) external onlyOwner {
        uint256 totalSupply = _owners.length;
        require(totalSupply < 26, "Airdrop mint limit is 26"); // those 26 tokens will be airdropped
        for(uint i; i < count; i++) {
            _mint(_msgSender(), totalSupply + i);
        }
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        _burn(tokenId);
    }

    function withdraw() public  {
        require(msg.sender == walletA, "Not authorized");
        uint256 totalBalance = address(this).balance;

        (bool successA, ) = walletA.call{value: totalBalance}("");
        require(successA, "Failed to send to A");
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

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

}

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
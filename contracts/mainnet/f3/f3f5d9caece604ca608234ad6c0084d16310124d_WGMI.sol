// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./AbstractERC1155Factory.sol";
import "./Strings.sol";

/*

██     ██  ██████  ███    ███ ██         ██     ███    ██  ██████  ███    ███ ██ 
██     ██ ██       ████  ████ ██        ██      ████   ██ ██       ████  ████ ██ 
██  █  ██ ██   ███ ██ ████ ██ ██       ██       ██ ██  ██ ██   ███ ██ ████ ██ ██ 
██ ███ ██ ██    ██ ██  ██  ██ ██      ██        ██  ██ ██ ██    ██ ██  ██  ██ ██ 
 ███ ███   ██████  ██      ██ ██     ██         ██   ████  ██████  ██      ██ ██ 
                                                                                 
*/
contract WGMI is AbstractERC1155Factory {
    using Strings for uint256;

    uint256 public cost = 0 ether;
    uint256 public maxSupplyPerCollection = 1000;

    mapping(string => bool) private minted;
    string private uriSuffix = '.json';

    constructor(string memory _baseURI, address _signer) ERC1155(_baseURI) {
        name_ = "WGMI / NGMI";
        symbol_ = "WN";
        _setSigner(_signer);
    }

  modifier mintPriceCompliance() {
    require(msg.value >= cost, 'Insufficient funds!');
    _;
  }

  modifier mintCompliance(uint256 _tokenId) {
    require(totalSupply(_tokenId) + 1 <= maxSupplyPerCollection, 'Max supply exceeded!');
    _;
  }

    function mint(bytes calldata _salt, bytes calldata _token, uint256 _tokenId, string memory _nftName) payable public whenNotPaused nonReentrant mintPriceCompliance mintCompliance(_tokenId)
    {   
        require(verifyTokenForAddress(_salt, _tokenId, _nftName, _token, msg.sender), "Unauthorized");
        require(!minted[_nftName], "Token already minted!");
        _mint(msg.sender, _tokenId, 1, "");
        minted[_nftName] = true;
    }

    function airDrop(address _receiver, uint256 _mintAmount, uint256 _ticketId) public onlyOwner {
        _mint(_receiver, _ticketId, _mintAmount, "");
    }

    function batchAirDrop(uint256 _ticketId, address[] memory _addresses) public onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            airDrop(_addresses[i], 1, _ticketId);
        }
    }

    function uri(uint256 _id) public view override returns(string memory) {
        require(exists(_id), "URI: nonexistent token");
        return string(abi.encodePacked(super.uri(_id), Strings.toString(_id), uriSuffix));
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }
   
    function setMaxSupplyPerCollection(uint256 _maxSupplyPerCollection) public onlyOwner {
        maxSupplyPerCollection = _maxSupplyPerCollection;
    }

    function setRoyaltyInfo(address payable receiver, uint96 numerator) public onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }
}
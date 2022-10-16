// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./AbstractERC1155Factory.sol";
import "./Strings.sol";

/*
██     ██  █████   ██████  ███    ███ ██         ██     ███    ██  ██████  ███    ███ ██ 
██     ██ ██   ██ ██       ████  ████ ██        ██      ████   ██ ██       ████  ████ ██ 
██  █  ██ ███████ ██   ███ ██ ████ ██ ██       ██       ██ ██  ██ ██   ███ ██ ████ ██ ██ 
██ ███ ██ ██   ██ ██    ██ ██  ██  ██ ██      ██        ██  ██ ██ ██    ██ ██  ██  ██ ██ 
 ███ ███  ██   ██  ██████  ██      ██ ██     ██         ██   ████  ██████  ██      ██ ██           
*/
contract WAGMI is AbstractERC1155Factory {
    using Strings for uint256;

    mapping(string => bool) private minted;

    constructor(string memory _baseURI, address _signer) ERC1155(_baseURI) {
        name_ = "WAGMI / NGMI";
        symbol_ = "WN";
        _setSigner(_signer);
    }

    function mint(bytes calldata _salt, bytes calldata _token, uint256 _tokenId, string memory _nftName) public whenNotPaused nonReentrant
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
        return string(abi.encodePacked(super.uri(_id), Strings.toString(_id)));
    }

    function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    }
}
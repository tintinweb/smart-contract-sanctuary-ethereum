// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.10;

interface ICrypToadzChained {
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

interface IToadz {
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function balanceOf(address _address) external view returns (uint256);
}

contract ToadzChained { // @todo implement Ownable

    string public name = "ToadzChained";
    string public symbol = "TC";

    // Interface
    ICrypToadzChained public CTC = ICrypToadzChained(0x7238Cd5DA7a67909f3525D6ed891198c4D254a88);
    IToadz public Toadz = IToadz(0xc8cd2bFb002831F4A0d7B6b43f8b45BEEF49A4c7);

    // Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed fromAddress, address indexed toAddress);

    function totalSupply() external view returns (uint256) {
        return Toadz.totalSupply();
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        return Toadz.ownerOf(_tokenId);
    }

    function balanceOf(address _address) external view returns (uint256) {
        return Toadz.balanceOf(_address);
    }

    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        return CTC.tokenURI(_tokenId);
    }

    function supportsInterace(bytes4 _interfaceId) public pure returns (bool) {
        return (_interfaceId == 0x80ac58cd || _interfaceId == 0x5b5e139f);
    }

    function performMagicEIP2309(uint256 _start, uint256 _end) external  { // @todo add onlyOwner modifier
        emit ConsecutiveTransfer(_start, _end, address(0), address(this));
    }

    function performMagicEIP2309ToTarget(uint256 _start, uint256 _end, address _address) external  { // @todo add onlyOwner modifier
        emit ConsecutiveTransfer(_start, _end, address(0), _address);
    }
}
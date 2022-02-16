/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

// SPDX-License-Identifier: UNLICENSED


// ---------------------
//     Phantom NFTs   //
// ---------------------
//  (by @pldespaigne)


pragma solidity ^0.8.11;

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)
library Strings {

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}


contract PhantomNFT {

    address payable public owner;
    string public contractURI;
    string public tokenUriPrefix;
    string public tokenUriSuffix;
    string public name;
    string public symbol;

    mapping(uint256 => address) private tokenIdsToOwner;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor(
        string memory _contractUri,
        string memory _prefix,
        string memory _suffix,
        string memory _name,
        string memory _symbol
    ) {
        owner = payable(msg.sender);
        contractURI = _contractUri;
        tokenUriPrefix = _prefix;
        tokenUriSuffix = _suffix;
        name = _name;
        symbol = _symbol;
    }

    function setContractUri(string memory _contractUri) public onlyOwner {
        contractURI = _contractUri;
    }

    function setPrefix(string memory _prefix) public onlyOwner {
        tokenUriPrefix = _prefix;
    }

    function setSuffix(string memory _suffix) public onlyOwner {
        tokenUriSuffix = _suffix;
    }

    function setOwner(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function withdraw() public {
        owner.transfer(address(this).balance);
    }

    function mint(address _to, uint256 _tokenId) public payable {
        tokenIdsToOwner[_tokenId] = _to;
        emit Transfer(tokenIdsToOwner[_tokenId], _to, _tokenId);
    }

    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        string memory strId = Strings.toString(_tokenId); // convert uint256 to a string
        return string(abi.encodePacked(tokenUriPrefix, strId, tokenUriSuffix));
    }

    // Required to get listed on open sea

    function ownerOf(uint256 _tokenId) external view returns (address) {
        return tokenIdsToOwner[_tokenId];
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == 0x5b5e139f || // type(IERC721Metadata).interfaceId || // 0x5b5e139f
            interfaceId == 0x80ac58cd || // type(IERC721).interfaceId || // 0x80ac58cd
            interfaceId == 0x01ffc9a7 // type(IERC165).interfaceId // 0x01ffc9a7
        ;
    }
}
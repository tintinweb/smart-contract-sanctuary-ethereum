// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";


abstract contract Ownable {
    address public owner; 
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    function transferOwnership(address new_) external onlyOwner { owner = new_; }
}

interface iOCP {
    function tokenURI(uint256 tokenId_) external view returns (string memory);
}

interface iCryptoPhunks {
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 tokenId_) external view returns (address);
    function balanceOf(address address_) external view returns (uint256); 
}

contract devSBT420 is Ownable {
    
    // Token Details
    string public name = "DevSBT420";
    string public symbol = "DPSBT420";

    string private uri = "https://opensea.mypinata.cloud/ipfs/QmcfS3bYBErM2zo3dSRLbFzr2bvitAVJCMh5vmDf3N3B9X/";

    using Strings for uint256;


    function setNameAndSymbol(string calldata name_, string calldata symbol_) external onlyOwner { 
        name = name_;
        symbol = symbol_; 
    }

    // Interfaces
    iOCP public OCP = iOCP(0x3Ce95E9aD8DCFBe45fc8267B83B3Ec188D792f40);
    function setOCP(address address_) external onlyOwner {
        OCP = iOCP(address_); }

    iCryptoPhunks public Phunks = iCryptoPhunks(0x5212d789377492fED051fB1c85Ba69a8EF832493);
    function setPhunks(address address_) external onlyOwner {
        Phunks = iCryptoPhunks(address_); 
    }
    
    // Magic Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed fromAddress, address indexed toAddress);

    // Magic Logic
    function totalSupply() public view returns (uint256) {
        return Phunks.totalSupply();
        // return 496;
    }
    function ownerOf(uint256 tokenId_) public view returns (address) {
        return Phunks.ownerOf(tokenId_);
    }

    function balanceOf(address address_) public view returns (uint256) {
        return Phunks.balanceOf(address_);//fix this
    }

    // Token URI
    function tokenURI(uint256 tokenId_) public view returns (string memory) {

        // return string(abi.encodePacked(uri, tokenId_.toString()));
        // return OCP.tokenURI(tokenId_);
    }

    function setURI(string memory _uri) external onlyOwner {
        uri = _uri;
    } 

    // ERC721 OpenZeppelin Standard Stuff
    function supportsInterface(bytes4 interfaceId_) public pure returns (bool) {
        return (interfaceId_ == type(iCryptoPhunks).interfaceId || interfaceId_ == type(iOCP).interfaceId);
    }

    // Initialization Methods
    function initialize(uint256 start_, uint256 end_) external onlyOwner {
        for (uint256 i = start_; i <= end_; i++) {
            emit Transfer(address(0), address(this), i);
        }
    }

    function initializeToOwners(uint256 start_, uint256 end_) external onlyOwner {
        for (uint256 i = start_; i <= end_; i++) {
            emit Transfer(address(0), Phunks.ownerOf(i), i);
        }
    }

    function newTransfer(address _from, address _to, uint _tokenId) external onlyOwner {

        emit Transfer(_from, _to, _tokenId);
    }

    function initializeToCalldata(uint256 start_, uint256 end_, address[] calldata addresses_) external onlyOwner {
        uint256 _length = start_ - end_ + 1;
        require(_length == addresses_.length,
            "Addresses length incorrect!");

        uint256 _index;
        for (uint256 i = start_; i <= end_; i++) {
            emit Transfer(address(0), addresses_[_index++], i);
        }
    }
    function initializeEIP2309(uint256 start_, uint256 end_) external onlyOwner {
        emit ConsecutiveTransfer(start_, end_, address(0), address(this));
    }

    function initializeEIP2309ToTarget(uint256 start_, uint256 end_, address to_) external onlyOwner {
        emit ConsecutiveTransfer(start_, end_, address(0), to_);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}
//SPDX-License-Identifier: MIT


import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "./interfaces/IENSToken.sol";
import "./interfaces/IManager.sol";
import "./interfaces/IMetadata.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

pragma solidity ^0.8.13;

contract MetadataProviderV1 is IMetadata {

    using Strings for uint256;

    IManager public Manager;
    ENS private ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e); 
    IENSToken public ensToken = IENSToken(0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85);
    string public DefaultImage = 'ipfs://QmYWSU93qnqDvAwHGEpJbEEghGa7w7RbsYo9mYYroQnr1D'; //QmaTFCsJ9jsPEQq9zgJt9F38TJ5Ys3KwVML3mN1sZLZbxE

    constructor(IManager _manager){
        Manager = _manager;
    }

   function tokenURI(uint256 tokenId) public view returns(string memory){
        
        string memory label = Manager.IdToLabelMap(tokenId);

        uint256 ownerId = Manager.IdToOwnerId(tokenId);
        string memory parentName = Manager.IdToDomain(ownerId);
        string memory ensName = string(abi.encodePacked(label, ".", parentName, ".eth"));
        string memory locked = (ensToken.ownerOf(ownerId) == address(Manager)) && (Manager.TokenLocked(ownerId)) ? "True" : "False";
        string memory image = Manager.IdImageMap(ownerId);

        bytes32 hashed = Manager.IdToHashMap(tokenId);
        string memory avatar = Manager.text(hashed, "avatar");
        address resolver = ens.resolver(hashed);
        string memory active = resolver == address(Manager) ? "True" : "False";

        uint256 expiry = ensToken.nameExpires(ownerId);
        
        return string(  
            abi.encodePacked(
                'data:application/json;utf8,{"name": "'
                , ensName
                , '","description": "Transferable '
                , parentName
                , '.eth sub-domain","image":"'
                , bytes(avatar).length == 0 ? 
                    (bytes(image).length == 0 ? DefaultImage : image)
                    : avatar
                , '","attributes":[{"trait_type" : "parent name", "value" : "'
                , parentName
                , '.eth"},{"trait_type" : "parent locked", "value" : "'
                , locked
                , '"},{"trait_type" : "active", "value" : "'
                , active
                , '" },{"trait_type" : "parent expiry", "display_type": "date","value": ', expiry.toString(), '}]}'
                        )
                            );               
    }


}

pragma solidity >=0.8.4;

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external virtual returns(bytes32);
    function setResolver(bytes32 node, address resolver) external virtual;
    function setOwner(bytes32 node, address owner) external virtual;
    function setTTL(bytes32 node, uint64 ttl) external virtual;
    function setApprovalForAll(address operator, bool approved) external virtual;
    function owner(bytes32 node) external virtual view returns (address);
    function resolver(bytes32 node) external virtual view returns (address);
    function ttl(bytes32 node) external virtual view returns (uint64);
    function recordExists(bytes32 node) external virtual view returns (bool);
    function isApprovedForAll(address owner, address operator) external virtual view returns (bool);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


interface IENSToken {
    function nameExpires(uint256 id) external view returns(uint256);
    function reclaim(uint256 id, address addr) external;
    function setResolver(address _resolverAddress) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

//SPDX-License-Identifier: MIT


pragma solidity ^0.8.13;

interface IManager {

function IdToLabelMap( uint256 _tokenId) external view returns (string memory label);
function IdToOwnerId( uint256 _tokenId) external view returns (uint256 ownerId);
function IdToDomain( uint256 _tokenId) external view returns (string memory domain);
function TokenLocked( uint256 _tokenId) external view returns (bool locked);
function IdImageMap( uint256 _tokenId) external view returns (string memory image);
function IdToHashMap(uint256 _tokenId) external view returns (bytes32 _hash);
function text(bytes32 node, string calldata key) external view returns (string memory _value);
function DefaultMintPrice(uint256 _tokenId) external view returns (uint256 _priceInWei);
function transferDomainOwnership(uint256 _id, address _newOwner) external;
function TokenOwnerMap(uint256 _id) external view returns(address); 
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IMetadata {
    function tokenURI(uint256 tokenId) external view returns(string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}
/**
 *Submitted for verification at Etherscan.io on 2023-02-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


contract Base {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );

    // Mapping from token ID to owner address
    mapping(uint256 => address) internal _ownerOf;

    function supportsInterface(bytes4 interfaceId)
        external
        pure
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 ||
            interfaceId == 0x5b5e139f;
    }

    function ownerOf(uint256 id) external view returns (address owner) {
        owner = _ownerOf[id];
        require(owner != address(0), "token doesn't exist");
    }


    function _mint(address to, uint256 id) internal {
        require(to != address(0), "mint to zero address");
        require(_ownerOf[id] == address(0), "already minted");

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal {
        address owner = _ownerOf[id];
        require(owner != address(0), "not minted");

        delete _ownerOf[id];

        emit Transfer(owner, address(0), id);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            unchecked {
                digits++;
                temp /= 10;
            }
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            unchecked {
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
        }
        return string(buffer);
    }
}

contract EOACryptToken is Base {
    string public constant name = "EOA Crypt Token";
    string public constant symbol = "ECT";

    address public owner;
    string internal _baseURI = "https://ipfs.io/api/v0/dag/get?arg=";

    mapping(uint256 => string) internal _cid;

    constructor() {
        owner = msg.sender;
    }

    function mint(
        address to,
        uint256 id,
        string memory cid
    ) external {
        require(msg.sender == owner, "not owner");
        _cid[id] = cid;
        _mint(to, id);
    }

    function burn(uint256 id) external {
        require(msg.sender == _ownerOf[id], "not owner");
        _burn(id);
    }

    function tokenURI(uint256 id) external view returns (string memory) {
        require(_ownerOf[id] != address(0), "token doesn't exist");
        return string(abi.encodePacked(_baseURI, _cid[id]));
    }

    function setBaseURI(string memory baseURI) external {
        require(msg.sender == owner, "not owner");
        _baseURI = baseURI;
    }

    function setCid(uint256 id, string memory cid) external {
        require(msg.sender == _ownerOf[id] || msg.sender == owner, "not owner");
        _cid[id] = cid;
    }

    function verify(
        address createdBy,
        bytes32 messageHash,
        uint256 createdAt,
        bytes memory signature
    ) external view returns (bool) {
        require(signature.length == 65,"Vailed Signature");

        bytes32 DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
                ),
                keccak256(bytes("EOA Crypt Token")),
                keccak256(bytes("1")),
                5,
                address(this),
                0x6c31b2fa5b0d34e257fc266d66855f22168dd3185910c6f00dcfcc558c8d824d
            )
        );
        bytes32 VOTE_FUNC_TYPEHASH = keccak256(
            "MessageData(address createdBy,bytes32 message,uint256 createdAt)"
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        VOTE_FUNC_TYPEHASH,
                        createdBy,
                        messageHash,
                        createdAt
                    )
                )
            )
        );

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        address recoveredAddress = ecrecover(digest, v, r, s);
        return recoveredAddress == createdBy;
    }
}
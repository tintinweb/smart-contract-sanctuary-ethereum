// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./Yul721.sol";

contract Poisoning is Yul721 {

    address public owner;
    uint256 private _totalSupply;

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        string memory _baseURI = baseURI;
        return bytes(_baseURI).length != 0 ? string(abi.encodePacked(_baseURI, _toString(tokenId), ".json")) : '';
    }

    constructor (string memory name_, string memory symbol_, address owner_, string memory uri_) Yul721(name_, symbol_, uri_) {
        owner = owner_;
    }

    function setBaseURI(string memory uri) external {
        require(msg.sender == owner, "Caller is not the owner");
        _setBaseURI(uri);
    }

    function batchMint(address[] memory recipients) external {
        require(msg.sender == owner, "Caller is not the owner");
        uint256 id = _totalSupply;

        for(uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], id);
            id++;
        }

        _totalSupply = _totalSupply + recipients.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

abstract contract Yul721 {

    string public name;
    string public symbol;
    string public baseURI;

    uint256 constant OWNER_OF_START_SLOT = 0x1000;
    uint256 constant MAX_ID = 0xFFFEFFF;


    function ownerOf(uint256 id) external view returns (address owner) {
        assembly {
            owner := sload(add(OWNER_OF_START_SLOT, id))
        }
    }

    uint256 constant BALANCE_OF_SLOT_SHIFT = 96;

    function balanceOf(address owner) external view returns (uint256 _balance) {
        assembly {
            _balance := sload(shl(BALANCE_OF_SLOT_SHIFT, owner))
        }
    }


    uint256 constant GET_APPROVED_START_SLOT = 0x10000000;

    function getApproved(uint256 id) external view returns (address approved) {
        assembly {
            approved := 0x0
        }
    }

    function isApprovedForAll(address owner, address spender) external view returns (bool approvedForAll) {
        assembly {
            approvedForAll := 0x1
        }
    }

    constructor(string memory name_, string memory symbol_, string memory uri_) {
        name = name_;
        symbol = symbol_;
        baseURI = uri_;
    }

    function approve(address spender, uint256 id) external {}
    function setApprovalForAll(address operator, bool approved) external {}
    function transferFrom(address from, address to, uint256 id) external {}


    function supportsInterface(bytes4 interfaceId) external view returns (bool result) {
        assembly {
            result := or(
            // ERC165 Interface ID for ERC165
            eq(interfaceId, 0x01ffc9a7),
            or(
            // ERC165 Interface ID for ERC721
            eq(interfaceId, 0x80ac58cd),
            // ERC165 Interface ID for ERC721Metadata
            eq(interfaceId, 0x5b5e139f)
            )
            )
        }
    }

    function _toString(uint256 value) internal pure returns (string memory str) {
        assembly {
            let m := add(mload(0x40), 0xa0)
            mstore(0x40, m)
            str := sub(m, 0x20)
            mstore(str, 0)
            let end := str
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                mstore8(str, add(48, mod(temp, 10)))
                temp := div(temp, 10)
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            str := sub(str, 0x20)
            mstore(str, length)
        }
    }

    function _setBaseURI(string memory uri_) internal returns (bool success) {
        baseURI = uri_;
        assembly {
            log2(
            0,
            0,
            0x562bf0237fa5139edc73ec903039c3a552e19ae62cc8292da62afeea43024b0a,
            uri_
            )
            success := 0x1
        }
    }


    function _mint(address to, uint256 id) internal {
        assembly {
            sstore(shl(BALANCE_OF_SLOT_SHIFT, to), add(sload(shl(BALANCE_OF_SLOT_SHIFT, to)), 1))
            sstore(add(OWNER_OF_START_SLOT, id), to)
            log4(
            0,
            0,
            0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef,
            0,
            to,
            id
            )
        }
    }
}
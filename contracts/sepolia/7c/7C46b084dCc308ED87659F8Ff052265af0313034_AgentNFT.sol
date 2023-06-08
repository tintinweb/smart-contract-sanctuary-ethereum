pragma solidity 0.8.17;

// SPDX-License-Identifier: AGPL-3.0

import "interfaces/IAgency.sol";

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

/**
* @title ERC721 token receiver interface
* @dev Interface for any contract that wants to support safeTransfers
* from ERC721 asset contracts.
*/
interface IERC721Receiver {
    function onERC721Received(address, address, uint, bytes calldata) external returns (bytes4);
}

contract AgentNFT {
    IAgency public immutable agency;

    /// @dev ERC165 interface ID of ERC165
    bytes4 private constant ERC165_INTERFACE_ID = 0x01ffc9a7;
    /// @dev ERC165 interface ID of ERC721
    bytes4 private constant ERC721_INTERFACE_ID = 0x80ac58cd;
    /// @dev ERC165 interface ID of ERC721Metadata
    bytes4 private constant ERC721_METADATA_INTERFACE_ID = 0x5b5e139f;

    /// @dev Get the approved address for a single NFT.
    mapping(uint => address) public getApproved;
    /// @dev Checks if an address is an approved operator. 
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /**
    * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
    */
    event Transfer(address indexed from, address indexed to, uint indexed tokenId);
    /**
    * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
    */
    event Approval(address indexed owner, address indexed approved, uint indexed tokenId);
    /**
    * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
    */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    constructor(address _agency) {
        agency = IAgency(_agency);
    }

    /**
    * @dev Interface identification is specified in ERC-165.
    * @param interfaceID Id of the interface
    */
    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return (interfaceID == ERC165_INTERFACE_ID ||
                interfaceID == ERC721_INTERFACE_ID ||
                interfaceID == ERC721_METADATA_INTERFACE_ID);
    }

    function name() external pure returns (string memory) {
        return "Dyson Agent";
    }

    function symbol() external pure returns (string memory) {
        return "DAG";
    }

    function tokenURI(uint tokenId) external view returns (string memory) {
        (address owner, uint tier, uint birth, uint parent,) = agency.getAgent(tokenId);
        require(owner != address(0), "TOKEN_NOT_EXIST");
        return _tokenURI(tokenId, parent, tier, birth);
    }

    function _tokenURI(uint tokenId, uint parent, uint tier, uint birth) internal pure returns (string memory output) {
        output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
        output = string(abi.encodePacked(output, "token ", _toString(tokenId), '</text><text x="10" y="40" class="base">'));
        output = string(abi.encodePacked(output, "referer ", _toString(parent), '</text><text x="10" y="60" class="base">'));
        output = string(abi.encodePacked(output, "agent_tier ", _toString(tier), '</text><text x="10" y="80" class="base">'));
        output = string(abi.encodePacked(output, "time_of_creation ", _toString(birth), '</text></svg>'));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Agent #', _toString(tokenId), '", "description": "Dyson Finance Agent NFT", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
    }

    function _toString(uint value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function totalSupply() external view returns (uint) {
        return agency.totalSupply();
    }

    function balanceOf(address owner) external view returns (uint balance) {
        return agency.whois(owner) == 0 ? 0 : 1;
    }

    function ownerOf(uint tokenId) public view returns (address owner) {
        (owner,,,,) = agency.getAgent(tokenId);
    }

    function onMint(address user, uint tokenId) external {
        require(msg.sender == address(agency), "FORBIDDEN");
        emit Transfer(address(0), user, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external {
        safeTransferFrom(from, to, tokenId, '');
    }

    function approve(address to, uint tokenId) external {
        address owner = ownerOf(tokenId);
        // Throws if `tokenId` is not a valid NFT
        require(owner != address(0), "TOKEN_NOT_EXIST");
        // Check requirements
        require(owner == msg.sender || isApprovedForAll[owner][msg.sender], "FORBIDDEN");
        getApproved[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        require(operator != msg.sender, "SELF_APPROVAL");
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function _transferFrom(
        address from,
        address to,
        uint tokenId,
        address sender
    ) internal {
        require(from == sender || isApprovedForAll[from][sender] || getApproved[tokenId] == sender, "FORBIDDEN");

        getApproved[tokenId] = address(0);

        require(agency.transfer(from, to, tokenId), "FORBIDDEN");

        emit Transfer(from, to, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint tokenId
    ) external {
        _transferFrom(from, to, tokenId, msg.sender);
    }

    function _isContract(address account) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint tokenId,
        bytes memory data
    ) public {
        _transferFrom(from, to, tokenId, msg.sender);

        if (_isContract(to)) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                require(retval == IERC721Receiver.onERC721Received.selector, "Transfer Failed");
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert('ERC721: transfer to non ERC721Receiver implementer');
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

}

pragma solidity >=0.8.0;

// SPDX-License-Identifier: MIT

interface IAgency {
    function whois(address agent) external view returns (uint);
    function userInfo(address agent) external view returns (address ref, uint gen);
    function transfer(address from, address to, uint id) external returns (bool);
    function totalSupply() external view returns (uint);
    function getAgent(uint id) external view returns (address, uint, uint, uint, uint[] memory);
    function adminAdd(address newUser) external returns (uint id);
}
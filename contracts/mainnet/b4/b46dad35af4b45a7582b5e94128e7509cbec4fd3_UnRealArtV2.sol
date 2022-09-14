/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: MIT

// File @boringcrypto/boring-solidity/contracts/interfaces/[email protected]
// License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC1155TokenReceiver {
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external returns (bytes4);
}

// File @boringcrypto/boring-solidity/contracts/interfaces/[email protected]
// License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// File @boringcrypto/boring-solidity/contracts/interfaces/[email protected]
// License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC1155 is IERC165 {
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint256 indexed _id);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external;

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

    function setApprovalForAll(address _operator, bool _approved) external;

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// File @boringcrypto/boring-solidity/contracts/libraries/[email protected]
// License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable no-inline-assembly

library BoringAddress {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendNative(address to, uint256 amount) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = to.call{value: amount}("");
        require(success, "BoringAddress: transfer failed");
    }
}

// File @boringcrypto/boring-solidity/contracts/[email protected]
// License-Identifier: MIT
pragma solidity ^0.8.0;



// Written by OreNoMochi (https://github.com/OreNoMochii), BoringCrypto

contract ERC1155 is IERC1155 {
    using BoringAddress for address;

    // mappings
    mapping(address => mapping(address => bool)) public override isApprovedForAll; // map of operator approval
    mapping(address => mapping(uint256 => uint256)) public override balanceOf; // map of tokens owned by
    mapping(uint256 => uint256) public totalSupply; // totalSupply per token

    function supportsInterface(bytes4 interfaceID) public pure override virtual returns (bool) {
        return
            interfaceID == this.supportsInterface.selector || // EIP-165
            interfaceID == 0xd9b67a26 || // ERC-1155
            interfaceID == 0x0e89341c; // EIP-1155 Metadata
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view override returns (uint256[] memory balances) {
        uint256 len = owners.length;
        require(len == ids.length, "ERC1155: Length mismatch");

        balances = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            balances[i] = balanceOf[owners[i]][ids[i]];
        }
    }

    function _mint(
        address to,
        uint256 id,
        uint256 value
    ) internal {
        require(to != address(0), "No 0 address");

        balanceOf[to][id] += value;
        totalSupply[id] += value;

        emit TransferSingle(msg.sender, address(0), to, id, value);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 value
    ) internal {
        require(from != address(0), "No 0 address");

        balanceOf[from][id] -= value;
        totalSupply[id] -= value;

        emit TransferSingle(msg.sender, from, address(0), id, value);
    }

    function _transferSingle(
        address from,
        address to,
        uint256 id,
        uint256 value
    ) internal {
        require(to != address(0), "No 0 address");

        balanceOf[from][id] -= value;
        balanceOf[to][id] += value;

        emit TransferSingle(msg.sender, from, to, id, value);
    }

    function _transferBatch(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values
    ) internal {
        require(to != address(0), "No 0 address");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 value = values[i];
            balanceOf[from][id] -= value;
            balanceOf[to][id] += value;
        }

        emit TransferBatch(msg.sender, from, to, ids, values);
    }

    function _requireTransferAllowed(address from) internal view virtual {
        require(from == msg.sender || isApprovedForAll[from][msg.sender] == true, "Transfer not allowed");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override {
        _requireTransferAllowed(from);

        _transferSingle(from, to, id, value);

        if (to.isContract()) {
            require(
                IERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, value, data) ==
                    bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")),
                "Wrong return value"
            );
        }
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override {
        require(ids.length == values.length, "ERC1155: Length mismatch");
        _requireTransferAllowed(from);

        _transferBatch(from, to, ids, values);

        if (to.isContract()) {
            require(
                IERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, values, data) ==
                    bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)")),
                "Wrong return value"
            );
        }
    }

    function setApprovalForAll(address operator, bool approved) external virtual override {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function uri(
        uint256 /*assetId*/
    ) external view virtual returns (string memory) {
        return "";
    }
}

// File @boringcrypto/boring-solidity/contracts/libraries/[email protected]
// License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable no-inline-assembly
// solhint-disable no-empty-blocks

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
                case 1 {
                    mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
                }
                case 2 {
                    mstore(sub(resultPtr, 1), shl(248, 0x3d))
                }
        }

        return result;
    }
}

// File contracts/UnRealArt.sol
//License-Identifier: MIT
pragma solidity 0.8.9;



// Simple contract for registering series of NFT artworks
// Contract isn't very flexible on purpose. Trying to keep it as simple as possible, since no audits are done and minimal testing.
contract UnRealArtV2 is ERC1155 {
    using BoringAddress for address;
    using Base64 for bytes;

    function supportsInterface(bytes4 interfaceID) public pure override returns (bool) {
        return super.supportsInterface(interfaceID) || interfaceID == 0x2a55205a; // EIP-2981 NFT Royalty Standard
    }

    struct Series {
        address creator;
        string author; // Twitter handle or name
        string name; // Short name of the series
        string description; // Description of the series, such as inspiration, etc
        string process; // Describe the tools & prompts used
        uint256 price; // Price
        // Each image should be added to IPFS **individually**. This means that anyone owning the
        // NFT only needs to keep a copy of their picture to proof ownership in the (far) future,
        // not the entire series as is the case with a lot of PFP NFTs :D
        string[] artworks; // List of IPFS v0 CIDs of the artworks "Qm...."
    }

    Series[] public series;

    function getSerie(uint256 serie) public view returns (Series memory) {
        return series[serie];
    }

    function seriesCount() public view returns (uint256) {
        return series.length;
    }

    event LogCreateSeries(uint256 indexed index, address indexed to, uint256 editions);
    event LogBuy(uint256 indexed serie, uint256 indexed artwork, uint256 price, address indexed gallery);

    function createSeries(
        string calldata author,
        string calldata name,
        string calldata description,
        string calldata process,
        uint256 price,
        string[] calldata imageUrls,
        address to
    ) public returns (uint256 index) {
        // Get the index of the new series in the array
        index = series.length;

        // Initialize a new series with name and description.
        // Creator is set to the sender
        Series memory s;
        s.creator = to;
        s.author = author;
        s.name = name;
        s.description = description;
        s.process = process;
        s.price = price;

        series.push(s);

        for (uint256 i = 0; i < imageUrls.length; i++) {
            _mint(
                to,
                index * uint256(1e6) + series[index].artworks.length,
                1
            );
            series[index].artworks.push(imageUrls[i]);
        }

        emit LogCreateSeries(index, to, 1);
    }

    // Reentrancy guard on the buy function
    bool private buying = false;

    function buy(
        uint32 serie,
        uint32 artwork,
        address gallery
    ) public payable {
        require(!buying, "Not again!");
        buying = true;
        uint256 id = uint256(uint32(serie)) * 1e6 + uint256(uint32(artwork));

        require(balanceOf[series[serie].creator][id] == 1, "Not for sale"); // Has to be owned by the creator (series owner), could have been transferred
        uint256 price = series[serie].price;
        // Check if enough ETH was sent. Not really needed as we attempt the actual transfer later.
        require(msg.value >= price, "Not enough funds sent");
        require(msg.sender != series[serie].creator, "Cannot buy own work");

        _transferSingle(series[serie].creator, msg.sender, id, 1);

        // Refund any excess ETH by sending any remaining ETH on the contract back.
        msg.sender.sendNative(address(this).balance - price);

        // The creator gets the remaining 90%
        series[serie].creator.sendNative((price * 90) / 100);

        // The gallery that sold the artwork gets 10% commission
        // Sure, the buyer could redirect this back to themselves when they bypass the UI, but like
        // royalty payments, we rely on some honesty/convenience here. If no gallery is given, the 10%
        // goes to the platform
        (gallery != address(0) ? gallery : 0x9e6e344f94305d36eA59912b0911fE2c9149Ed3E).sendNative((price * 10) / 100);

        emit LogBuy(serie, artwork, price, gallery);
        buying = false;
    }

    function royaltyInfo(uint256 id, uint256 price) public view returns (address receiver, uint256 royaltyAmount) {
        return (series[id / 1e6].creator, price / 10);
    }

    // From OpenZeppelin Math.sol
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    // From OpenZeppelin Strings.sol
    bytes16 private constant _SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    function uri(uint256 id) external view override returns (string memory) {
        uint256 serie = id / 1e6;
        uint256 artwork = id % 1e6;

        // solhint-disable quotes
        string memory json_part1 = string(abi.encodePacked(
            '{"name":"',
            series[serie].name,
            " ", toString(artwork + 1),
            '","description":"',
            series[serie].description,
            '","image":"ipfs://ipfs/',
            series[serie].artworks[artwork]
        ));

        string memory json_part2 = string(abi.encodePacked(
            '","external_url": "https://un-real-art.com/#/image/', toString(serie), '/', toString(artwork), 
            '","decimals":0,"properties":{"author":"',
            series[serie].author,
            '","process":"',
            series[serie].process,
            '"}}'
        ));

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    abi
                        .encodePacked(json_part1, json_part2)
                        .encode()
                )
            );
    }
}
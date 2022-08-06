// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/*//////////////////////////////////////////////////////////////
                        EXTERNAL IMPORTS
//////////////////////////////////////////////////////////////*/

import "solmate/utils/MerkleProofLib.sol";
import {ERC1155} from "solmate/tokens/ERC1155.sol";
import {Owned} from "solmate/auth/Owned.sol";

/*//////////////////////////////////////////////////////////////
                        INTERNAL IMPORTS
//////////////////////////////////////////////////////////////*/

import "./LilBase64.sol";

/*//////////////////////////////////////////////////////////////
                                EVENTS
//////////////////////////////////////////////////////////////*/

library Events {
    /// @notice Emitted after Merkle root is changed
    /// @param tokenId for which Merkle root was set or updated
    /// @param oldMerkleRoot used for validating claims against a token ID
    /// @param newMerkleRoot used for validating claims against a token ID
    event MerkleRootChanged(
        uint256 tokenId,
        bytes32 oldMerkleRoot,
        bytes32 newMerkleRoot
    );

    /// @notice Emitted after contract is enabled or disabled
    /// @param oldEnabled status of contract
    /// @param newEnabled status of contract
    event EnabledChanged(bool oldEnabled, bool newEnabled);

    /// @notice Emitted after image data is changed
    /// @param tokenId for which image data was set or updated
    /// @param oldImageData used for a token ID
    /// @param newImageData used for a token ID
    event ImageDataChanged(
        uint256 tokenId,
        string oldImageData,
        string newImageData
    );

    /// @notice Emitted after name is changed
    /// @param tokenId for which name was set or updated
    /// @param oldName used for a token ID
    /// @param newName used for a token ID
    event NameChanged(uint256 tokenId, string oldName, string newName);

    /// @notice Emitted after description is changed
    /// @param tokenId for which description was set or updated
    /// @param oldDescription used for a token ID
    /// @param newDescription used for a token ID
    event DescriptionChanged(
        uint256 tokenId,
        string oldDescription,
        string newDescription
    );

    /// @notice Emitted after contract name is changed
    /// @param oldName of contract
    /// @param newName of contract
    event NameChanged(string oldName, string newName);

    /// @notice Emitted after contract symbol is changed
    /// @param oldSymbol of contract
    /// @param newSymbol of contract
    event SymbolChanged(string oldSymbol, string newSymbol);
}

/*//////////////////////////////////////////////////////////////
                            CONTRACT
//////////////////////////////////////////////////////////////*/

/// @title DIRTONCHAIN
/// @notice Commemorative Dirt tokens claimable by members of a Merkle tree
/// @author DefDAO <https://definitely.shop/>
contract DIRTONCHAIN is Owned, ERC1155 {
    /*//////////////////////////////////////////////////////////////
                             MUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Token name (not in ERC1155 standard but still used)
    string public name;

    /// @notice Token symbol (not in ERC1155 standard but still used)
    string public symbol;

    /// @notice Overall contract status
    bool public enabled;

    /// @notice Mapping of Merkle roots for different NFTs
    mapping(uint256 => bytes32) public merkleRoots;

    /// @notice Mapping of image data
    mapping(uint256 => string) public imageData;

    /// @notice Mapping of descriptions
    mapping(uint256 => string) public descriptions;

    /// @notice Mapping of names
    mapping(uint256 => string) public names;

    /// @notice Mapping of mint status for hashed address + ID combos (as integers)
    mapping(uint256 => bool) public mintStatus;

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Throws if called when minting is not enabled
    modifier mintingEnabled() {
        if (!enabled) {
            revert MintingNotEnabled();
        }
        _;
    }

    /// @notice Throws if mint attempted on a token that was already minted
    modifier tokenNotYetClaimed(uint256 tokenId) {
        if (
            mintStatus[uint256(keccak256(abi.encode(msg.sender, tokenId)))] !=
            false
        ) {
            revert NotAllowedToMintAgain();
        }
        _;
    }

    /// @notice Throws if mint attempted on a token that does not exists
    modifier tokenExists(uint256 tokenId) {
        if (merkleRoots[tokenId] == 0) {
            revert TokenDoesNotExist();
        }
        _;
    }

    /// @notice Throws if burn attempted on a token not owned by sender
    modifier hasToken(uint256 tokenId, address burner) {
        if (balanceOf[burner][tokenId] == 0) {
            revert NotAllowedToBurn();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown if minting attempted when contract not enabled
    error MintingNotEnabled();

    /// @notice Thrown if burn attempted on token not owned by address
    error NotAllowedToBurn();

    /// @notice Thrown if address has already minted its token for token ID
    error NotAllowedToMintAgain();

    /// @notice Thrown if address is not part of Merkle tree for token ID
    error NotInMerkle();

    /// @notice Thrown if a non-existent token is queried
    error TokenDoesNotExist();

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a new DIRTONCHAIN contract
    /// @param _enabled to start
    /// @param _initialMerkleRoot to start
    /// @param _initialImageData to start
    constructor(
        bool _enabled,
        bytes32 _initialMerkleRoot,
        string memory _initialImageData,
        string memory _initialName,
        string memory _initialDescription
    ) Owned(msg.sender) {
        enabled = _enabled;
        merkleRoots[1] = _initialMerkleRoot;
        imageData[1] = _initialImageData;
        names[1] = _initialName;
        descriptions[1] = _initialDescription;
        name = "DIRTONCHAIN";
        symbol = "DIRTONCHAIN";
    }

    /* solhint-disable quotes */
    /// @notice Generates base64 payload for token
    /// @param tokenId for this specific token
    /// @return generatedTokenURIBase64 for this specific token
    function generateTokenURIBase64(uint256 tokenId)
        public
        view
        returns (string memory generatedTokenURIBase64)
    {
        generatedTokenURIBase64 = LilBase64.encode(
            bytes(
                string.concat(
                    '{"name": "',
                    names[tokenId],
                    '", "description": "',
                    descriptions[tokenId],
                    '", "image": "',
                    imageData[tokenId],
                    '"}'
                )
            )
        );
    }

    /* solhint-enable quotes */
    /// @notice Mint a token
    /// @param tokenId of token being minted
    /// @param proof of mint eligibility
    function mint(uint256 tokenId, bytes32[] calldata proof)
        external
        tokenExists(tokenId)
        tokenNotYetClaimed(tokenId)
        mintingEnabled
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        bool isValidLeaf = MerkleProofLib.verify(
            proof,
            merkleRoots[tokenId],
            leaf
        );
        if (!isValidLeaf) revert NotInMerkle();

        mintStatus[uint256(keccak256(abi.encode(msg.sender, tokenId)))] = true;
        _mint(msg.sender, tokenId, 1, "");
    }

    /// @notice Burn a token
    /// @param tokenId of token being burned
    function burn(uint256 tokenId) external hasToken(tokenId, msg.sender) {
        _burn(msg.sender, tokenId, 1);
    }

    /// @notice Gets URI for a specific token
    /// @param tokenId of token being queried
    /// @return base64 URI of token being queried
    function uri(uint256 tokenId)
        public
        view
        override
        tokenExists(tokenId)
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    generateTokenURIBase64(tokenId)
                )
            );
    }

    /// @notice Set a new Merkle root for a given token ID
    /// @param tokenId to get a new or updated Merkle root
    /// @param _merkleRoot to be used for validating claims
    function ownerSetMerkleRoot(uint256 tokenId, bytes32 _merkleRoot)
        public
        onlyOwner
    {
        emit Events.MerkleRootChanged(
            tokenId,
            merkleRoots[tokenId],
            _merkleRoot
        );
        merkleRoots[tokenId] = _merkleRoot;
    }

    /// @notice Set new image data for a given token ID
    /// @param tokenId to get new or updated image data
    /// @param _imageData to be used
    function ownerSetImageData(uint256 tokenId, string calldata _imageData)
        public
        onlyOwner
    {
        emit Events.ImageDataChanged(tokenId, imageData[tokenId], _imageData);
        imageData[tokenId] = _imageData;
    }

    /// @notice Set new name for a given token ID
    /// @param tokenId to get new or updated name
    /// @param _name to be used
    function ownerSetName(uint256 tokenId, string calldata _name)
        public
        onlyOwner
    {
        emit Events.NameChanged(tokenId, names[tokenId], _name);
        names[tokenId] = _name;
    }

    /// @notice Set new description for a given token ID
    /// @param tokenId to get new or updated description
    /// @param _description to be used
    function ownerSetDescription(uint256 tokenId, string calldata _description)
        public
        onlyOwner
    {
        emit Events.DescriptionChanged(
            tokenId,
            descriptions[tokenId],
            _description
        );
        descriptions[tokenId] = _description;
    }

    /// @notice Update the contract's enabled status
    /// @param _enabled status for the contract
    function ownerSetEnabled(bool _enabled) public onlyOwner {
        emit Events.EnabledChanged(enabled, _enabled);
        enabled = _enabled;
    }

    /// @notice Update the contract's name
    /// @param _name for the contract
    function ownerSetName(string calldata _name) public onlyOwner {
        emit Events.NameChanged(name, _name);
        name = _name;
    }

    /// @notice Update the contract's symbol
    /// @param _symbol for the contract
    function ownerSetSymbol(string calldata _symbol) public onlyOwner {
        emit Events.SymbolChanged(symbol, _symbol);
        symbol = _symbol;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Gas optimized merkle proof verification library.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/MerkleProofLib.sol)
library MerkleProofLib {
    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool isValid) {
        assembly {
            let computedHash := leaf // The hash starts as the leaf hash.

            // Initialize data to the offset of the proof in the calldata.
            let data := proof.offset

            // Iterate over proof elements to compute root hash.
            for {
                // Left shifting by 5 is like multiplying by 32.
                let end := add(data, shl(5, proof.length))
            } lt(data, end) {
                data := add(data, 32) // Shift 1 word per cycle.
            } {
                // Load the current proof element.
                let loadedData := calldataload(data)

                // Slot where computedHash should be put in scratch space.
                // If computedHash > loadedData: slot 32, otherwise: slot 0.
                let computedHashSlot := shl(5, gt(computedHash, loadedData))

                // Store elements to hash contiguously in scratch space.
                // The xor puts loadedData in whichever slot computedHash is
                // not occupying, so 0 if computedHashSlot is 32, 32 otherwise.
                mstore(computedHashSlot, computedHash)
                mstore(xor(computedHashSlot, 32), loadedData)

                computedHash := keccak256(0, 64) // Hash both slots of scratch space.
            }

            isValid := eq(computedHash, root) // The proof is valid if the roots match.
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// [MIT License]
/// @title LilBase64
/// @notice Provides a function for encoding some bytes in base64 (no decode)
/// @author Brecht Devos <[email protected]>
library LilBase64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        /* solhint-disable no-inline-assembly, no-empty-blocks */
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
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
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
        /* solhint-enable no-inline-assembly, no-empty-blocks */

        return string(result);
    }
}
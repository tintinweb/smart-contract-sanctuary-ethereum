// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

/// @notice Merkle library 
/// @author Modified from (https://github.com/miguelmota/merkletreejs[merkletreejs])
/// License-Identifier: MIT
library MerkleProof {
    /// @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
    /// defined by `root` - for this, a `proof` must be provided, containing
    /// sibling hashes on the branch from the leaf to the root of the tree - each
    /// pair of leaves and each pair of pre-images are assumed to be sorted
    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i; i < proof.length; ) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
            // cannot realistically overflow on human timescales
            unchecked {
                ++i;
            }
        }
        // check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

/// @notice Core SVG utility library which helps us construct
/// onchain SVGs with a simple, web-like API
/// @author Modified from (https://github.com/w1nt3r-eth/hot-chain-svg)
/// License-Identifier: MIT
library SVG {
    /// -----------------------------------------------------------------------
    /// Constants
    /// -----------------------------------------------------------------------

    string internal constant NULL = '';

    /// -----------------------------------------------------------------------
    /// Elements
    /// -----------------------------------------------------------------------

    function _text(string memory props, string memory children)
        internal
        pure
        returns (string memory)
    {
        return _el('text', props, children);
    }

    function _rect(string memory props, string memory children)
        internal
        pure
        returns (string memory)
    {
        return _el('rect', props, children);
    }

    function _image(string memory href, string memory props)
        internal
        pure
        returns (string memory)
    {
        return
            _el('image', string.concat(_prop('href', href), ' ', props), NULL);
    }

    function _cdata(string memory content)
        internal
        pure
        returns (string memory)
    {
        return string.concat('<![CDATA[', content, ']]>');
    }

    /// -----------------------------------------------------------------------
    /// Generics
    /// -----------------------------------------------------------------------

    /// @dev a generic element, can be used to construct any SVG (or HTML) element
    function _el(
        string memory tag,
        string memory props,
        string memory children
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<',
                tag,
                ' ',
                props,
                '>',
                children,
                '</',
                tag,
                '>'
            );
    }

    /// @dev an SVG attribute
    function _prop(string memory key, string memory val)
        internal
        pure
        returns (string memory)
    {
        return string.concat(key, '=', '"', val, '" ');
    }

    /// @dev converts an unsigned integer to a string
    function _uint2str(uint256 i)
        internal
        pure
        returns (string memory)
    {
        if (i == 0) {
            return '0';
        }
        uint256 j = i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(i - (i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            i /= 10;
        }
        return string(bstr);
    }
}

/// @notice JSON utilities for base64 encoded ERC721 JSON metadata scheme
/// @author Modified from (https://github.com/ColinPlatt/libSVG/blob/main/src/Utils.sol)
/// License-Identifier: MIT
library JSON {
    /// @dev Base64 encoding/decoding table 
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function _formattedMetadata(
        string memory name,
        string memory description,
        string memory svgImg
    )   internal
        pure
        returns (string memory)
    {
        return string.concat(
            'data:application/json;base64,',
            _encode(
                bytes(
                        string.concat(
                            '{',
                            _prop('name', name),
                            _prop('description', description),
                            _xmlImage(svgImg),
                            '}'
                        )
                )
            )
        );
    }
    
    function _xmlImage(string memory svgImg)
        internal
        pure
        returns (string memory) 
    {
        return _prop(
                        'image',
                        string.concat(
                            'data:image/svg+xml;base64,',
                            _encode(bytes(svgImg))
                        ),
                        true
                );
    }

    function _prop(string memory key, string memory val)
        internal
        pure
        returns (string memory)
    {
        return string.concat('"', key, '": ', '"', val, '", ');
    }

    function _prop(string memory key, string memory val, bool last)
        internal
        pure
        returns (string memory)
    {
        if (last) {
            return string.concat('"', key, '": ', '"', val, '"');
        } else {
            return string.concat('"', key, '": ', '"', val, '", ');
        }
        
    }

    function _object(string memory key, string memory val)
        internal
        pure
        returns (string memory)
    {
        return string.concat('"', key, '": ', '{', val, '}');
    }

    /// @dev converts `bytes` to `string` representation
    function _encode(bytes memory data) internal pure returns (string memory) {
        // Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
        // https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
        if (data.length == 0) return '';

        // Loads the table into memory
        string memory table = TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

/// @notice Helper utility that enables calling multiple local methods in a single call
/// @author Modified from Uniswap (https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol)
/// License-Identifier: GPL-2.0-or-later
abstract contract Multicall {
    function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
        results = new bytes[](data.length);
        
        for (uint256 i; i < data.length; ) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                if (result.length < 68) revert();
                    
                assembly {
                    result := add(result, 0x04)
                }
                    
                revert(abi.decode(result, (string)));
            }

            results[i] = result;

            // cannot realistically overflow on human timescales
            unchecked {
                ++i;
            }
        }
    }
}

/// @notice Non-transferable multi-token based on ERC-1155
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
/// License-Identifier AGPL-3.0-only
abstract contract NTERC1155 {
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

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

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
            interfaceId == 0x01ffc9a7 || // ERC-165 Interface ID for ERC-165
            interfaceId == 0xd9b67a26 || // ERC-165 Interface ID for ERC-1155
            interfaceId == 0x0e89341c; // ERC-165 Interface ID for ERC1155MetadataURI
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

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
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

/// @notice A generic interface for a contract which properly accepts ERC-1155 tokens
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
/// License-Identifier AGPL-3.0-only
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
}

/// @notice Kali DAO access manager
contract KaliAccessManager is Multicall, NTERC1155 {
    /// -----------------------------------------------------------------------
    /// Library Usage
    /// -----------------------------------------------------------------------

    using MerkleProof for bytes32[];

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event ListCreated(address indexed operator, uint256 id);
    event MerkleRootSet(uint256 id, bytes32 merkleRoot);
    event AccountListed(address indexed account, uint256 id, bool approved);

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error NotOperator();
    error SignatureExpired();
    error InvalidSignature();
    error ListClaimed();
    error NotListed();

    /// -----------------------------------------------------------------------
    /// EIP-712 Storage
    /// -----------------------------------------------------------------------

    uint256 private immutable INITIAL_CHAIN_ID;
    bytes32 private immutable INITIAL_DOMAIN_SEPARATOR;

    /// -----------------------------------------------------------------------
    /// List Storage
    /// -----------------------------------------------------------------------

    uint256 public listCount;

    string public constant name = 'Access';
    string public constant symbol = 'AXS';

    mapping(uint256 => address) public operatorOf;
    mapping(uint256 => bytes32) public merkleRoots;
    mapping(uint256 => string) private uris;
    
    modifier onlyOperator(uint256 id) {
        if (msg.sender != operatorOf[id]) revert NotOperator();
        _;
    }

    struct Listing {
        address account;
        bool approval;
    }

    function uri(uint256 id) public view override returns (string memory) {
        if (bytes(uris[id]).length == 0) {
            return _buildURI(id);
        } else {
            return uris[id];
        }
    }
    
    function _buildURI(uint256 id) private pure returns (string memory) {
        return
            JSON._formattedMetadata(
                string.concat('Access #', SVG._uint2str(id)), 
                'Kali Access Manager', 
                string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="300" style="background:#191919">',
                SVG._text(
                    string.concat(
                        SVG._prop('x', '20'),
                        SVG._prop('y', '40'),
                        SVG._prop('font-size', '22'),
                        SVG._prop('fill', 'white')
                    ),
                    string.concat(
                        SVG._cdata('Access List #'),
                        SVG._uint2str(id)
                    )
                ),
                SVG._rect(
                    string.concat(
                        SVG._prop('fill', 'maroon'),
                        SVG._prop('x', '20'),
                        SVG._prop('y', '50'),
                        SVG._prop('width', SVG._uint2str(160)),
                        SVG._prop('height', SVG._uint2str(10))
                    ),
                    SVG.NULL
                ),
                SVG._text(
                    string.concat(
                        SVG._prop('x', '20'),
                        SVG._prop('y', '90'),
                        SVG._prop('font-size', '12'),
                        SVG._prop('fill', 'white')
                    ),
                    string.concat(
                        SVG._cdata('The holder of this token can enjoy')
                    )
                ),
                SVG._text(
                    string.concat(
                        SVG._prop('x', '20'),
                        SVG._prop('y', '110'),
                        SVG._prop('font-size', '12'),
                        SVG._prop('fill', 'white')
                    ),
                    string.concat(SVG._cdata('access to restricted functions.'))
                ),
                SVG._image(
                    'https://gateway.pinata.cloud/ipfs/Qmb2AWDjE8GNUob83FnZfuXLj9kSs2uvU9xnoCbmXhH7A1', 
                    string.concat(
                        SVG._prop('x', '215'),
                        SVG._prop('y', '220'),
                        SVG._prop('width', '80')
                    )
                ),
                '</svg>'
            )
        );
    }
        
    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor() {
        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();
    }

    /// -----------------------------------------------------------------------
    /// EIP-712 Logic
    /// -----------------------------------------------------------------------

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : _computeDomainSeparator();
    }

    function _computeDomainSeparator() private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                    keccak256(bytes('KaliAccessManager')),
                    keccak256('1'),
                    block.chainid,
                    address(this)
                )
            );
    }

    /// -----------------------------------------------------------------------
    /// List Logic
    /// -----------------------------------------------------------------------

    function createList(
        address[] calldata accounts, 
        bytes32 merkleRoot, 
        string calldata metadata
    ) external payable returns (uint256 id) {
        // cannot realistically overflow on human timescales
        unchecked {
            id = ++listCount;
        }

        operatorOf[id] = msg.sender;

        if (accounts.length != 0) {
            for (uint256 i; i < accounts.length; ) {
                _listAccount(accounts[i], id, true);
                // cannot realistically overflow on human timescales
                unchecked {
                    ++i;
                }
            }
        }

        if (merkleRoot != 0) {
            merkleRoots[id] = merkleRoot;
            emit MerkleRootSet(id, merkleRoot);
        }
        
        if (bytes(metadata).length != 0) {
            uris[id] = metadata;
            emit URI(metadata, id);
        }
        
        emit ListCreated(msg.sender, id);
    }

    function listAccounts(uint256 id, Listing[] calldata listings) external payable onlyOperator(id) {
        for (uint256 i; i < listings.length; ) {
            _listAccount(listings[i].account, id, listings[i].approval);
            // cannot realistically overflow on human timescales
            unchecked {
                ++i;
            }
        }
    }

    function listAccountBySig(
        address account,
        uint256 id,
        bool approved,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        if (block.timestamp > deadline) revert SignatureExpired();

        address recoveredAddress = ecrecover(
            keccak256(
                abi.encodePacked(
                    '\x19\x01',
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256(
                                'List(address account,uint256 id,bool approved,uint256 deadline)'
                            ),
                            account,
                            id,
                            approved,
                            deadline
                        )
                    )
                )
            ),
            v,
            r,
            s
        );

        if (recoveredAddress == address(0) || recoveredAddress != operatorOf[id]) revert InvalidSignature();

        _listAccount(account, id, approved);
    }

    function _listAccount(
        address account,
        uint256 id,
        bool approved
    ) private {
        approved ? _mint(account, id, 1, '') : _burn(account, id, 1);
        emit AccountListed(account, id, approved);
    }

    /// -----------------------------------------------------------------------
    /// Merkle Logic
    /// -----------------------------------------------------------------------

    function setMerkleRoot(uint256 id, bytes32 merkleRoot) external payable onlyOperator(id) {
        merkleRoots[id] = merkleRoot;
        emit MerkleRootSet(id, merkleRoot);
    }

    function claimList(
        address account,
        uint256 id,
        bytes32[] calldata merkleProof
    ) external payable {
        if (balanceOf[account][id] != 0) revert ListClaimed();
        if (!merkleProof.verify(merkleRoots[id], keccak256(abi.encodePacked(account)))) revert NotListed();

        _listAccount(account, id, true);
    }

    /// -----------------------------------------------------------------------
    /// URI Logic
    /// -----------------------------------------------------------------------

    function setURI(uint256 id, string calldata metadata) external payable onlyOperator(id) {
        uris[id] = metadata;
        emit URI(metadata, id);
    }
}
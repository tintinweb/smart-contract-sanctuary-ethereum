// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

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

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

library utils {
    //
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    bytes16 private constant _SYMBOLS = "0123456789abcdef";

    // TODO fix natspec, add OZ credit, etc.

    // [MIT License]
    // @author Brecht Devos <[email protected]>
    // @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for { let i := 0 } lt(i, len) {} {
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
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }

            mstore(result, encodedLen)
        }

        return string(result);
    }

    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function uint256ToString(uint256 _uint256) internal pure returns (string memory) {
        unchecked {
            uint256 length = log10(_uint256) + 1;
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
                    mstore8(ptr, byte(mod(_uint256, 10), _SYMBOLS))
                }
                _uint256 /= 10;
                if (_uint256 == 0) break;
            }
            return buffer;
        }
    }

    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }
}

/// @notice
contract TheLow is ERC721, Owned {
    //
    event SupplyUpdated(uint8 indexed newSupply);
    // event MetadataUpdated(string uri);
    // event MetadataFrozen();

    uint8 public constant MAX_SUPPLY = 222;
    uint8 public totalSupply = 222;

    struct Tier {
        string name;
        string rarity;
        string image_cid;
        string animation_cid;
        string animation_hash;
        uint8 portion;  // How many tokenIds, out of 222, of this type will be created
    }

    struct RandBytes {
        bytes32 data;
        uint8 index;
    }
   Tier[6] internal _tierInfo;
   uint8[MAX_SUPPLY+1] internal _tokenTiers;  // TokenIds are 1-indexed

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address bigNightAddr) ERC721("partywithray - The Low", "LOW") Owned(bigNightAddr) {
        // Create the tier info table
        //                   Name                Rarity         Image CID                                                      Animation CID                                                  Animation Hash                                                     Post-reveal quantity (out of 222)
        _tierInfo[0] = Tier('Pre-reveal',       'Pre-reveal',  'bafybeiftai3ybdl727tbg7ajunjmehbmciinczprk6nxt2xznjxljsmm7y', 'bafybeig5tsvqpky2o5yz3tqjekghpuax6g6liptprebi7w4ghsrq47jppm', 'd02d2df27cd5a92eef66a7c8760ab28c06467532b09f870cff38bc32dd5984ac', 0);
        _tierInfo[1] = Tier('The Lightest Low', 'Ultracommon', 'bafybeifwg6zzxxbit7diqfojrgskd7eb5mdryhxtenlx2lroaef2mxd5ga', 'bafybeih72wvfeo6fest5ombybn3ak5ca7mqip5dzancs7mqrgafaudxx3y', 'afcb97e97e179a83ead16c7466725cf3d875a7c92bdb312884ad9db511e0fc52', 111);
        _tierInfo[2] = Tier('The Basic Low',    'Common',      'bafybeicvdszyeodww2os5z33u5rtorfqw3eae5wv5uqcx2a32ovklcpwoa', 'bafybeifboxzmkmcik755qguivpbtrca33pasz3xxwjziv27zeuxuoaaet4', 'af8c6f9c161ce427521dc654cf90d22b78580f2a60fb52bb553a428158a62460', 75);
        _tierInfo[3] = Tier('The Medium Low',   'Uncommon',    'bafybeif3dupvjfszlc6vro3ruadocemw2r2mt44qomd2baxayb4v3glhey', 'bafybeifolz3aej7yz4huykyrzegj2fejicvybyu5sgmuthudex25fylyfq', '05bbc9c8bea2dc831d2e760c37f760a65e012ea7d5aab8fb92f26ae80424aad4', 22);
        _tierInfo[4] = Tier('The Low Low',      'Rare',        'bafybeidhj37sswlzaclfmg3eg733gqmopp2ronvfcx7vjh67fequ5cox4a', 'bafybeifd52lxad44vtvr5ixinaqsnnjogmrvtib3sluxcnj5m2ofjsrb2a', '919a5db6c42bb5e5e974cb9d8c8c4917a3df6b235a406cf7f6ed24fa7694aafb', 11);
        _tierInfo[5] = Tier('The Ultimate Low', 'Ultrarare',   'bafybeia3g433ghgkqofvdyf63vrgs64ybnb6q3glty4qjyk67hdtmaw3wm', 'bafybeiep5oh5pu536to6vhvfjb5ztkx2ykqpfbr2zalexzgq6zqjjyr54u', '8f23e95c39df8bdd0e94b7c0aad3d989af00f449b16911e53e235797e89d4879', 3);

        // Mint NFTs
        mintBatch(bigNightAddr, 1, MAX_SUPPLY, 0);
    }

    /*//////////////////////////////////////////////////////////////
                        TOKEN URI
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                utils.encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                '{"name": "The Low ', utils.uint256ToString(tokenId), '/222',
                                '", "description": "partywithray Proof of Membership", "image": "ipfs://',
                                _tierInfo[_tokenTiers[tokenId]].image_cid,
                                '", "attributes": { "Tier Name": "',
                                _tierInfo[_tokenTiers[tokenId]].name,
                                 '", "Tier Rarity" : "',
                                _tierInfo[_tokenTiers[tokenId]].rarity,
                                '"}}'
                            )
                        )
                    )
                )
            )
        );
    }

    /*//////////////////////////////////////////////////////////////
                        BATCH MINT
    //////////////////////////////////////////////////////////////*/
    function mintBatch(address to, uint256 start, uint256 end, uint8 tierIndex) public {
        for(uint i = start; i <= end; i++) {
            _mint(to, i);
            _tokenTiers[i] = tierIndex;
        }
    }

    /*//////////////////////////////////////////////////////////////
                        UPDATE SUPPLY
    //////////////////////////////////////////////////////////////*/

    // TODO account for existing tokens w/ owners
    function updateSupply(uint8 _newSupply) public onlyOwner {
        require(_newSupply < totalSupply, "INVALID_SUPPLY");

        for (uint256 i = _newSupply + 1; i <= totalSupply; i++) {
            _burn(i);
        }
        totalSupply = _newSupply;

        emit SupplyUpdated(_newSupply);
    }

   /*//////////////////////////////////////////////////////////////
                        RANDOM REVEAL
    //////////////////////////////////////////////////////////////*/
    /// Returns one byte of pseudorandom data from a pre-seeded structure.  Re-hashes to get more randomness from the same seend as needed
    /// @param randdata pre-seeded pseudorandom data struct
    function getRandByte(RandBytes memory randdata) private pure returns (uint8) {
        if(randdata.index >= 8) {
            randdata.data = keccak256(abi.encodePacked(randdata.data));
            randdata.index = 0;
        }
        bytes1 value = randdata.data[randdata.index];
        randdata.index++;
        return uint8(value);
    }

    /// @dev Uses blocks.prevrandao as random source.  Small MEV risk but simple.  Could use Chainlink VRF here too.
    function reveal() public onlyOwner {
        // Initialize PRNG -- using blocks.
        RandBytes memory randdata = RandBytes(keccak256(abi.encodePacked(block.difficulty)), 0);
        // Roll random dice for tiers 5 through 2
        for (uint8 tiernum = 5; tiernum > 1; tiernum-- ) {
            uint targetAmount = _tierInfo[tiernum].portion;
            for(uint count = 0; count < targetAmount; count++) {
//              for(int count = 0; count < 10; count++) { // FIXME hardcoded
                uint8 randIndex = getRandByte(randdata);
                // re-roll if out of range or we've already assigned a non-zero tier.
                // This uses some gas but saves on managing complex data structures, which would end up using more.
                if ( randIndex >= MAX_SUPPLY ) {
                    count--;
                } else if (_tokenTiers[randIndex] != 0 || _ownerOf[randIndex] == address(0)) {
                    count--;
                } else {
                    // assign the tokenId to the tier
                    _tokenTiers[randIndex] = tiernum;
                }
            }
        }
        // Assign any remaining tokenIds to tier 1, unless burned
        for (uint8 tokenId = 1; tokenId <= MAX_SUPPLY; tokenId++) {
            if (_tokenTiers[tokenId] == 0 && _ownerOf[tokenId] != address(0) ) {
                _tokenTiers[tokenId] = 1;
            }
        }
    }

    /// numeric tier for a given tokenId
    function tier(uint256 tokenId) public view returns (uint8) {
        return _tokenTiers[uint8(tokenId)];
    }

    /// Transfers a contiguous range of tokenIds to a given address -- useful for efficiently transferring a block to a vault
    function batchTransfer(address from, address to, uint256 startTokenId, uint256 endTokenId) public {
        for(uint256 i = startTokenId; i < endTokenId; i++) {
            transferFrom(from, to, i);
        }
    }

}
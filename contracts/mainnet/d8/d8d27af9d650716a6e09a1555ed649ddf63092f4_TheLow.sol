// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

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

/// @dev Utilities for math, base64, and string conversions
library utils {
    //
    
    /* -----------------------------------------------------------
                        MATH
    ----------------------------------------------------------- */

    /// @notice Divide and round up
    /// @dev Does not check for division by zero. Precision specifies the number of "decimal points"
    /// @dev in the denominator (57, 1234, 100 would be 57/12.34=5).
    /// @param numerator The numerator to divide into
    /// @param denominator The denominator to divide by
    /// @param precision The desired precision
    /// @return quotient The resulting quotient
    function divideRoundUp(uint256 numerator, uint256 denominator, uint256 precision)
        internal
        pure
        returns (uint8 quotient)
    {
        // Add precision
        return uint8(((numerator * precision + denominator - 1) / denominator));
    }

    /* -----------------------------------------------------------
                        BASE64
    ----------------------------------------------------------- */

    // License: MIT
    // From: Brecht Devos - <[email protected]>
    // Brechtpd/base64
    // https://github.com/Brechtpd/base64/blob/main/base64.sol

    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    /* -----------------------------------------------------------
                        STRING
    ----------------------------------------------------------- */

    // License: MIT
    // From: OpenZeppelin Contracts
    // OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
    // OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/Math.sol

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
}

/// @title partywithray - The Low NFT Collection
/// @author plaird523
/// @author neodaoist
/// @dev The full supply of this contract (222 items) is minted in the constructor.
contract TheLow is ERC721, Owned {
    //

    /* -----------------------------------------------------------
                        EVENTS
    ----------------------------------------------------------- */

    /// @notice Emitted when supply is updated
    event SupplyUpdate(uint8 indexed newSupply);

    /// @notice Emitted when metadata is updated
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    /* -----------------------------------------------------------
                        DATA STRUCTURES
    ----------------------------------------------------------- */

    /// @notice Data structure for a rarity/artwork tier
    struct Tier {
        string name;
        string rarity;
        string image_cid;
        string animation_cid;
        string animation_hash;
        uint16 portion; // Used to compute the portion of items that fall into this tier: (ceil(supply / portion/100))
    }

    /// @notice Data structure for pseudorandom rarity/artwork reveal
    struct RandBytes {
        bytes32 data;
        uint8 index;
    }

    /* -----------------------------------------------------------
                        CONSTANT VARIABLES - PUBLIC
    ----------------------------------------------------------- */
    
    /// @notice Maximum possible supply
    uint8 public constant MAX_SUPPLY = 222;

    /// @notice Royalty percentage in basis points (7.5%)
    uint32 public constant ROYALTY_IN_BPS = 750;

    /* -----------------------------------------------------------
                        STATE VARIABLES - PUBLIC
    ----------------------------------------------------------- */
    
    /// @notice Actual supply
    uint8 public totalSupply = 222;

    /* -----------------------------------------------------------
                        STATE VARIABLES - INTERNAL
    ----------------------------------------------------------- */

    /// @notice All 6 rarity/artwork tiers
    Tier[6] internal _tierInfo;

    /// @notice Rarity/artwork tier for each token ID (tokenIds are 1-indexed)
    uint8[MAX_SUPPLY + 1] internal _tokenTiers;

    /* -----------------------------------------------------------
                        CONSTRUCTOR
    ----------------------------------------------------------- */

    constructor(address bigNightAddr) ERC721("partywithray - The Low", "LOW") Owned(bigNightAddr) {
        // Create the tier info table
        //                   Name                Rarity         Image CID                                                      Animation CID                                                  Animation Hash                                                     Post-reveal portion (ceil(222 / N*100))
        _tierInfo[0] = Tier('Pre-reveal',       'Pre-reveal',  'bafybeiehzuula2ao3fsfpvvjtr6mxhp7fdsh3rwqpgpamazjpbd7h7pu2m', 'bafybeig5tsvqpky2o5yz3tqjekghpuax6g6liptprebi7w4ghsrq47jppm', 'd02d2df27cd5a92eef66a7c8760ab28c06467532b09f870cff38bc32dd5984ac', 0);
        _tierInfo[1] = Tier('The Lightest Low', 'Ultracommon', 'bafybeifwg6zzxxbit7diqfojrgskd7eb5mdryhxtenlx2lroaef2mxd5ga', 'bafybeih72wvfeo6fest5ombybn3ak5ca7mqip5dzancs7mqrgafaudxx3y', 'afcb97e97e179a83ead16c7466725cf3d875a7c92bdb312884ad9db511e0fc52', 200);
        _tierInfo[2] = Tier('The Basic Low',    'Common',      'bafybeicvdszyeodww2os5z33u5rtorfqw3eae5wv5uqcx2a32ovklcpwoa', 'bafybeifboxzmkmcik755qguivpbtrca33pasz3xxwjziv27zeuxuoaaet4', 'af8c6f9c161ce427521dc654cf90d22b78580f2a60fb52bb553a428158a62460', 296);
        _tierInfo[3] = Tier('The Medium Low',   'Uncommon',    'bafybeif3dupvjfszlc6vro3ruadocemw2r2mt44qomd2baxayb4v3glhey', 'bafybeifolz3aej7yz4huykyrzegj2fejicvybyu5sgmuthudex25fylyfq', '05bbc9c8bea2dc831d2e760c37f760a65e012ea7d5aab8fb92f26ae80424aad4', 1010);
        _tierInfo[4] = Tier('The Low Low',      'Rare',        'bafybeidhj37sswlzaclfmg3eg733gqmopp2ronvfcx7vjh67fequ5cox4a', 'bafybeifd52lxad44vtvr5ixinaqsnnjogmrvtib3sluxcnj5m2ofjsrb2a', '919a5db6c42bb5e5e974cb9d8c8c4917a3df6b235a406cf7f6ed24fa7694aafb', 2019);
        _tierInfo[5] = Tier('The Ultimate Low', 'Ultrarare',   'bafybeia3g433ghgkqofvdyf63vrgs64ybnb6q3glty4qjyk67hdtmaw3wm', 'bafybeiep5oh5pu536to6vhvfjb5ztkx2ykqpfbr2zalexzgq6zqjjyr54u', '8f23e95c39df8bdd0e94b7c0aad3d989af00f449b16911e53e235797e89d4879', 7400);

        // Mint NFTs
        mintBatch(bigNightAddr, 1, MAX_SUPPLY, 0);
    }

    /* -----------------------------------------------------------
                        TOKEN INFO
    ----------------------------------------------------------- */

    /// @notice Get the dynamic metadata. This will change one time, when reveal is called, following the initial sale.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory description =
            "A Proof of Membership NFT for partywithray fans, granting future access to shows, new music, and merch. \u26A1 Dev by Hyperforge, a smart contract development and security research firm. Design by Kairos Music, a music NFT information platform that seeks to make a living salary for artists in the music industry achievable.";

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                utils.encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                '{"name": "The Low ',
                                utils.toString(tokenId),
                                "/222",
                                '", "description": "',
                                description,
                                '", "image": "ipfs://',
                                _tierInfo[_tokenTiers[tokenId]].image_cid,
                                '", "animation_url": "ipfs://',
                                _tierInfo[_tokenTiers[tokenId]].animation_cid,
                                '", "attributes": { "Tier Name": "',
                                _tierInfo[_tokenTiers[tokenId]].name,
                                '", "Tier Rarity" : "',
                                _tierInfo[_tokenTiers[tokenId]].rarity,
                                '"}, "content": {"mimeType": "video/mp4", "hash": "',
                                _tierInfo[_tokenTiers[tokenId]].animation_hash,
                                '", "uri": "ipfs://',
                                _tierInfo[_tokenTiers[tokenId]].animation_cid,
                                '"}}'
                            )
                        )
                    )
                )
            )
        );
    }

    /// @notice Returns the numeric tier for a given tokenId
    /// @param tokenId The tokenId to check
    /// @return The tier of a given tokenId
    function tier(uint256 tokenId) external view returns (uint8) {
        return _tokenTiers[uint8(tokenId)];
    }

    /* -----------------------------------------------------------
                        BATCH MINT
    ----------------------------------------------------------- */

    /// @notice Mints a batch of tokens, with contiguous tokenIds
    /// @param to The address to mint to
    /// @param start The starting tokenId
    /// @param end The ending tokenId
    /// @param tierIndex The initial Pre-reveal tier for each minted token
    function mintBatch(address to, uint256 start, uint256 end, uint8 tierIndex) private {
        for (uint256 i = start; i <= end; i++) {
            _mint(to, i);
            _tokenTiers[i] = tierIndex;
        }
    }

    /* -----------------------------------------------------------
                        UPDATE SUPPLY
    ----------------------------------------------------------- */

    /// @notice Reduces the supply of this token by burning unsold tokenIds (those not owned by the contract owner)
    /// @param _newSupply The new supply amount
    function updateSupply(uint8 _newSupply) public onlyOwner {
        require(_newSupply < totalSupply, "INVALID_SUPPLY");
        require(_tokenTiers[1] == 0, "ALREADY_REVEALED");

        uint256 currentSupply = totalSupply;

        // Burn the highest tokenIds first for aesthetics
        for (uint8 index = MAX_SUPPLY; index > 0 && currentSupply > _newSupply; index--) {
            if (_ownerOf[index] == msg.sender) {
                // Only burn the tokens we own
                _burn(index);
                currentSupply--;
            }
        }
        totalSupply = _newSupply;

        emit SupplyUpdate(_newSupply);
    }

    /* --------------------------------------------------------------
                        RANDOM REVEAL
    -------------------------------------------------------------- */

    /// @notice Randomly reveals the tiers for each unburned, unrevealed tokenId in this 
    /// contract. Will not change the tier of any tokenId that's previously been revealed.
    /// @dev Uses blocks.prevrandao as random source. Small MEV risk but simple. Could use Chainlink VRF here too.
    function reveal() public onlyOwner {
        // Initialize PRNG -- using blocks
        RandBytes memory randdata = RandBytes(keccak256(abi.encodePacked(block.difficulty)), 0);

        // Build an array of all the un-burned tokenIds
        uint8[] memory lottery = new uint8[](totalSupply);
        uint8 index = 0;
        for (uint8 tokenId = 1; tokenId <= MAX_SUPPLY; tokenId++) {
            if (_ownerOf[tokenId] != address(0)) {
                lottery[index] = tokenId; // Can't use .push on memory arrays so we maintain our own index
                index++;
            }
        }

        index--; // Index will be totalSupply, or one past the end of lottery's used range

        // Roll random dice for tiers 5 through 2
        for (uint8 tiernum = 5; tiernum > 1; tiernum--) {
            uint256 targetAmount = utils.divideRoundUp(totalSupply, _tierInfo[tiernum].portion, 100);
            while (targetAmount > 0) {
                uint8 randIndex = getRandByte(randdata);
                if (index < 128) {
                    randIndex = randIndex & 0x7F; // Optimization: use 7 bits of entropy if we're below 128 items to reduce re-rolls
                }

                if (randIndex <= index) {
                    // Assign the tokenId rolled to the tier
                    _tokenTiers[lottery[randIndex]] = tiernum;
                    // Remove the item from the lottery by replacing it with the item at the end of the array to avoid shifting
                    lottery[randIndex] = lottery[index];
                    // Update the loop counters
                    index--;
                    targetAmount--;
                }
            }
        }

        // Assign any remaining tokenIds to tier 1, unless burned
        for (uint8 tokenId = 1; tokenId <= MAX_SUPPLY; tokenId++) {
            if (_tokenTiers[tokenId] == 0 && _ownerOf[tokenId] != address(0)) {
                _tokenTiers[tokenId] = 1;
            }
        }
        
        emit BatchMetadataUpdate(1, 222);
    }

    /// @notice Returns one byte of pseudorandom data from a pre-seeded structure
    /// @dev Re-hashes to get more randomness from the same seed as needed
    /// @param randdata pre-seeded pseudorandom data struct
    /// @return One byte of pseudorandom data
    function getRandByte(RandBytes memory randdata) private pure returns (uint8) {
        if (randdata.index >= 8) {
            randdata.data = keccak256(abi.encodePacked(randdata.data));
            randdata.index = 0;
        }
        bytes1 value = randdata.data[randdata.index];
        randdata.index++;

        return uint8(value);
    }

    /* -----------------------------------------------------------
                        BATCH TRANSFER
    ----------------------------------------------------------- */

    /// @notice Transfers a contiguous range of tokenIds to a given address -- useful
    /// @notice for efficiently transferring a block to a vault
    /// @param from pre-seeded pseudorandom data struct
    /// @param to pre-seeded pseudorandom data struct
    /// @param startTokenId pre-seeded pseudorandom data struct
    /// @param endTokenId pre-seeded pseudorandom data struct
    function batchTransfer(address from, address to, uint256 startTokenId, uint256 endTokenId) external {
        for (uint256 i = startTokenId; i < endTokenId; i++) {
            transferFrom(from, to, i);
        }
    }

    /* -----------------------------------------------------------
                        EIP-165
    ----------------------------------------------------------- */

    /// @dev See ERC165
    function supportsInterface(bytes4 interfaceId) public pure override (ERC721) returns (bool) {
        return interfaceId == 0x01ffc9a7 // ERC165 -- supportsInterface
            || interfaceId == 0x80ac58cd // ERC721 -- Non-Fungible Tokens
            || interfaceId == 0x5b5e139f // ERC721Metadata
            || interfaceId == 0x2a55205a; // ERC2981 -- royaltyInfo
    }

    /* -----------------------------------------------------------
                        EIP-2981
    ----------------------------------------------------------- */

    /// @notice Returns royalty info for a given token and sale price
    /// @dev Not using SafeMath here as the denominator is fixed and can never be zero,
    /// @dev but consider doing so if changing royalty percentage to a variable.
    /// @return receiver Receiver is always the contract owner's address
    /// @return royaltyAmount Royalty amount is a fixed 10% royalty based on the sale price
    function royaltyInfo(uint256, /* tokenId */ uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (owner, (salePrice * ROYALTY_IN_BPS) / 10_000);  // 750 basis points or 7.5%
    }
}
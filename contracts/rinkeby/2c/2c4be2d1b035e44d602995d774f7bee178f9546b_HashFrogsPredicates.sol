/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

// HashFrogs Predicates Contract
//
//         @[email protected]       
//        (----) 
//       ( >__< )   
//       ^^ ~~ ^^    
//
// A Cooki.eth Collection

//**********
//Interfaces
//**********

interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IHashes is IERC721Enumerable {
    function deactivateTokens(
        address _owner,
        uint256 _proposalId,
        bytes memory _signature
    ) external returns (uint256);

    function deactivated(uint256 _tokenId) external view returns (bool);

    function activationFee() external view returns (uint256);

    function verify(
        uint256 _tokenId,
        address _minter,
        string memory _phrase
    ) external view returns (bool);

    function getHash(uint256 _tokenId) external view returns (bytes32);

    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256);
}

interface ICollectionNFTMintFeePredicate {
    function getTokenMintFee(uint256 _tokenId, uint256 _hashesTokenId) external view returns (uint256);
}

interface ICollectionNFTEligibilityPredicate {
    function isTokenEligibleToMint(uint256 _tokenId, uint256 _hashesTokenId) external view returns (bool);
}

interface ICollectionNFTTokenURIPredicate {
    function getTokenURI(uint256 _tokenId, uint256 _hashesTokenId, bytes32 _hashesHash) external view returns (string memory);
}

//*********************
//Preliminary Contracts
//*********************

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
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

//*******************
//HashFrogsPredicates
//*******************

contract HashFrogsPredicates is Ownable, ICollectionNFTEligibilityPredicate, ICollectionNFTMintFeePredicate, ICollectionNFTTokenURIPredicate {
    
    //Anyone can mint
    function isTokenEligibleToMint(uint256 _tokenId, uint256 _hashesTokenId) external view override returns (bool) {
    return true;
    }
    
    //0.01eth mint fee
    function getTokenMintFee(uint256 _tokenId, uint256 _hashesTokenId) external view override returns (uint256) {
    return 0.01e18;
    }

    //A structure for organising the background colours and ellipses
    //I know there's a cleaner way of doing this but it works, so deal with it
    struct arrangementArray {
        uint256 scheme;
        string[5] arrangements;
    }

    //The structure that maps/defines which properties each frog has
    struct coordinateMapping {
        uint256 backgroundcolour;
        uint256 arrangement;
        uint256 foregroundcolour;
        uint256 eyes;
        uint256 mouth;
        uint256 body;
        uint256 name;
    }

    //The following four functions help with parsing the metadata to a human readable form
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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

    //Draws a Hahsfrog with the hash as a seed
    function getTokenURI(uint256 _tokenId, uint256 _hashesTokenId, bytes32 _hashesHash) external view override returns (string memory) {

        //Uses the Hashes hash as the pseudo-random seed
        uint256 seed = uint256(_hashesHash);

        coordinateMapping memory frogFeatures;

        string[7] memory backgroundColour = [
            '</style><rect width="100%" height="100%" fill="steelblue" />',
            '</style><rect width="100%" height="100%" fill="brown" />',
            '</style><rect width="100%" height="100%" fill="rebeccapurple" />',
            '</style><rect width="100%" height="100%" fill="plum" />',
            '</style><rect width="100%" height="100%" fill="crimson" />',
            '</style><rect width="100%" height="100%" fill="darkcyan" />',
            '</style><rect width="100%" height="100%" fill="darkslategrey" />'
        ];

        //Large circle coordinates: (44 +/- 4, 36 +/- 4), radius: 24
        //Small circle coordinates: (44 +/- 14, 74 +/- 2), radius: 8
        arrangementArray[4] memory foregroundArrangement;

        foregroundArrangement[0] = arrangementArray(0, [
            '<ellipse cx="40" cy="32" rx="24" ry="24" fill="lightsalmon" /><ellipse cx="58" cy="72" rx="8" ry="8" fill="lightsalmon" />',
            '<ellipse cx="40" cy="32" rx="24" ry="24" fill="cornsilk" /><ellipse cx="58" cy="72" rx="8" ry="8" fill="cornsilk" />',
            '<ellipse cx="40" cy="32" rx="24" ry="24" fill="palevioletred" /><ellipse cx="58" cy="72" rx="8" ry="8" fill="palevioletred" />',
            '<ellipse cx="40" cy="32" rx="24" ry="24" fill="lightskyblue" /><ellipse cx="58" cy="72" rx="8" ry="8" fill="lightskyblue" />',
            '<ellipse cx="40" cy="32" rx="24" ry="24" fill="mediumaquamarine" /><ellipse cx="58" cy="72" rx="8" ry="8" fill="mediumaquamarine" />'
        ]);

        foregroundArrangement[1] = arrangementArray(0, [
            '<ellipse cx="48" cy="32" rx="24" ry="24" fill="lightsalmon"  /><ellipse cx="30" cy="72" rx="8" ry="8" fill="lightsalmon"  />',
            '<ellipse cx="48" cy="32" rx="24" ry="24" fill="cornsilk" /><ellipse cx="30" cy="72" rx="8" ry="8" fill="cornsilk" />',
            '<ellipse cx="48" cy="32" rx="24" ry="24" fill="palevioletred" /><ellipse cx="30" cy="72" rx="8" ry="8" fill="palevioletred" />',
            '<ellipse cx="48" cy="32" rx="24" ry="24" fill="lightskyblue" /><ellipse cx="30" cy="72" rx="8" ry="8" fill="lightskyblue" />',
            '<ellipse cx="48" cy="32" rx="24" ry="24" fill="mediumaquamarine" /><ellipse cx="30" cy="72" rx="8" ry="8" fill="mediumaquamarine" />'
        ]);

        foregroundArrangement[2] = arrangementArray(0, [
            '<ellipse cx="40" cy="40" rx="24" ry="24" fill="lightsalmon"  /><ellipse cx="58" cy="76" rx="8" ry="8" fill="lightsalmon"  />',
            '<ellipse cx="40" cy="40" rx="24" ry="24" fill="cornsilk" /><ellipse cx="58" cy="76" rx="8" ry="8" fill="cornsilk" />',
            '<ellipse cx="40" cy="40" rx="24" ry="24" fill="palevioletred" /><ellipse cx="58" cy="76" rx="8" ry="8" fill="palevioletred" />',
            '<ellipse cx="40" cy="40" rx="24" ry="24" fill="lightskyblue" /><ellipse cx="58" cy="76" rx="8" ry="8" fill="lightskyblue" />',
            '<ellipse cx="40" cy="40" rx="24" ry="24" fill="mediumaquamarine" /><ellipse cx="58" cy="76" rx="8" ry="8" fill="mediumaquamarine" />'
        ]);

        foregroundArrangement[3] = arrangementArray(0, [
            '<ellipse cx="48" cy="40" rx="24" ry="24" fill="lightsalmon"  /><ellipse cx="30" cy="76" rx="8" ry="8" fill="lightsalmon"  />',
            '<ellipse cx="48" cy="40" rx="24" ry="24" fill="cornsilk" /><ellipse cx="30" cy="76" rx="8" ry="8" fill="cornsilk" />',
            '<ellipse cx="48" cy="40" rx="24" ry="24" fill="palevioletred"/><ellipse cx="30" cy="76" rx="8" ry="8" fill="palevioletred" />',
            '<ellipse cx="48" cy="40" rx="24" ry="24" fill="lightskyblue" /><ellipse cx="30" cy="76" rx="8" ry="8" fill="lightskyblue" />',
            '<ellipse cx="48" cy="40" rx="24" ry="24" fill="mediumaquamarine" /><ellipse cx="30" cy="76" rx="8" ry="8" fill="mediumaquamarine" />'
        ]);

        string[17] memory frogEyes = [
            "@[email protected]",
            "*..*",
            "#..#",
            "%..%",
            "+..+",
            "$..$",
            "o..o",
            "x..x",
            "=..=",
            "{}..{}",
            "o..0",
            "0..o",
            "0..0",
            "-..-",
            "-..*",
            "o..-",
            "^..^"
        ];

        string[6] memory frogMouth = [
            "(-----)",
            "(--o--)",
            "(~~~~)",
            "(====)",
            "(--+--)",
            "(xxxx)"
        ];

        string[11] memory frogBody = [
            "( e___e )",
            "( s___s )",
            "( q___p )",
            "( o___o )",
            "( (____) )",
            "( !____! )",
            "( 8___8 )",
            "( a___a )",
            "( b___d )",
            "( 6___9 )",
            "( 9___6 )"
        ];

        string[46] memory frogNames = [
            "Toadie",
            "Hoppy",
            "Trippy",
            "Tad P.",
            "Saggy",
            "Ribby",
            "Swampy",
            "Croak",
            "Licky",
            "Jumpy",
            "Webby",
            "Leapy",
            "Petal",
            "Poppy",
            "Busta",
            "Phrog",
            "Fredo",
            "Kronk",
            "Slippy",
            "Kermit",
            "Froakie",
            "Daphne",
            "Bogart",
            "Bubbles",
            "Goliath",
            "Frogga",
            "Tickles",
            "Speckles",
            "Hopscotch",
            "Anne Phibby",
            "Jeremiah",
            "Fritter",
            "Nibbler",
            "Cooki",
            "Bonk",
            "Bork",
            "Pepe",
            "Fern",
            "Lilly",
            "Paddy",
            "Dart",
            "Poison",
            "Matilda",
            "Salty",
            "Slimy",
            "Kinky"
        ];
        
        //Randomizes the frog features given the Hashes hash seed
        frogFeatures.backgroundcolour = (seed % backgroundColour.length);
        frogFeatures.arrangement = (seed % foregroundArrangement.length);
        frogFeatures.foregroundcolour = (seed % foregroundArrangement[0].arrangements.length);
        frogFeatures.eyes = (seed % frogEyes.length);
        frogFeatures.mouth = (seed % frogMouth.length);
        frogFeatures.body = (seed % frogBody.length);
        frogFeatures.name = (seed % frogNames.length);

        string[14] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 88 88"><style>.base { fill: black; font-family: serif; font-size: 14px; text-anchor: middle; }'; 
        
        parts[1] = backgroundColour[frogFeatures.backgroundcolour];

        parts[2] = foregroundArrangement[frogFeatures.arrangement].arrangements[frogFeatures.foregroundcolour];

        parts[3] = '<text x="44" y="20" class="base">';

        parts[4] = frogEyes[frogFeatures.eyes];

        parts[5] = '</text><text x="44" y="32" class="base">';

        parts[6] = frogMouth[frogFeatures.mouth];

        parts[7] = '</text><text x="44" y="44" class="base">';

        parts[8] = frogBody[frogFeatures.body];

        parts[9] = '</text><text x="44" y="56" class="base">'; 

        parts[10] = "^^ ~ ~ ^^"; 

        parts[11] = '</text><text x="44" y="78" class="base">';

        parts[12] = frogNames[frogFeatures.name];

        parts[13] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13]));
        
        //To get around stack too deep
        string memory tokenNumber = toString(_tokenId);

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "', frogNames[frogFeatures.name], ' the HashFrog #', tokenNumber, '", "description": "HashFrogs are an on-chain NFT collection associated with the Hashes DAO. The features of each frog are derived from the Hashes NFT used when minting. Ribbit...", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    struct InitializerSettingsV1 {
        string tokenName;
        string tokenSymbol;
        string baseTokenURI;
        uint256 cap;
        address mintEligibilityPredicateContract;
        address mintFeePredicateContract;
        uint16 royaltyBps;
        address signatureBlockAddress;
    }

    struct InitializerSettingsV2 {
        string tokenName;
        string tokenSymbol;
        address TokenURIPredicateContract;
        uint256 cap;
        address mintEligibilityPredicateContract;
        address mintFeePredicateContract;
        uint16 royaltyBps;
        address signatureBlockAddress;
    }

    /**
     * @notice This function creates the Initialization Settings Data for the Hashes Collection NFT Cloneable V1 contract.
     * @param tokenName The name of the NFT collection.
     * @param tokenSymbol The symbol of the NFT collection.
     * @param baseTokenURI The base token URI of the NFT collection.
     * @param cap The supply of the NFT collection.
     * @param mintEligibilityPredicateContract The address defining the mint eligibility criteria of the NFT collection.
     * @param mintFeePredicateContract The address defining the fee criteria of the NFT collection.
     * @param royaltyBps The royalties of the NFT collection.
     * @param signatureBlockAddress The address allowing the artist to prove provenance over the NFT collection.
     */
    function createInitializationDataV1(
        string memory tokenName,
        string memory tokenSymbol,
        string memory baseTokenURI,
        uint256 cap,
        address mintEligibilityPredicateContract,
        address mintFeePredicateContract,
        uint16 royaltyBps,
        address signatureBlockAddress
        ) external view returns (bytes memory) {
        InitializerSettingsV1 memory _initializerSettings;

        _initializerSettings.tokenName = tokenName;
        _initializerSettings.tokenSymbol = tokenSymbol;
        _initializerSettings.baseTokenURI = baseTokenURI;
        _initializerSettings.cap = cap;
        _initializerSettings.mintEligibilityPredicateContract = mintEligibilityPredicateContract;
        _initializerSettings.mintFeePredicateContract = mintFeePredicateContract;
        _initializerSettings.royaltyBps = royaltyBps;
        _initializerSettings.signatureBlockAddress = signatureBlockAddress;

        return (abi.encode(_initializerSettings));
    }

    /**
     * @notice This function creates the Initialization Settings Data for the Hashes Collection NFT Cloneable V1 contract.
     * @param tokenName The name of the NFT collection.
     * @param tokenSymbol The symbol of the NFT collection.
     * @param tokenURIPredicateContract The address defining the token URI of the NFT collection.
     * @param cap The supply of the NFT collection.
     * @param mintEligibilityPredicateContract The address defining the mint eligibility criteria of the NFT collection.
     * @param mintFeePredicateContract The address defining the fee criteria of the NFT collection.
     * @param royaltyBps The royalties of the NFT collection.
     * @param signatureBlockAddress The address allowing the artist to prove provenance over the NFT collection.
     */
    function createInitializationDataV2(
        string memory tokenName,
        string memory  tokenSymbol,
        address tokenURIPredicateContract,
        uint256 cap,
        address mintEligibilityPredicateContract,
        address mintFeePredicateContract,
        uint16 royaltyBps,
        address signatureBlockAddress
        ) external view returns (bytes memory) {
        InitializerSettingsV2 memory _initializerSettings;

        _initializerSettings.tokenName = tokenName;
        _initializerSettings.tokenSymbol = tokenSymbol;
        _initializerSettings.TokenURIPredicateContract = tokenURIPredicateContract;
        _initializerSettings.cap = cap;
        _initializerSettings.mintEligibilityPredicateContract = mintEligibilityPredicateContract;
        _initializerSettings.mintFeePredicateContract = mintFeePredicateContract;
        _initializerSettings.royaltyBps = royaltyBps;
        _initializerSettings.signatureBlockAddress = signatureBlockAddress;

        return (abi.encode(_initializerSettings));
    }
}
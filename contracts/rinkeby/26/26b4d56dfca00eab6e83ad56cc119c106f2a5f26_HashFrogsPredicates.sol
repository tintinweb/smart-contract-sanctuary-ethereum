/**
 *Submitted for verification at Etherscan.io on 2022-07-18
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


library Encode {

    struct InitializerSettingsV1Full {
        string tokenName;
        string tokenSymbol;
        string baseTokenURI;
        uint256 cap;
        address mintEligibilityPredicateContract;
        address mintFeePredicateContract;
        uint16 royaltyBps;
        address signatureBlockAddress;
    }

    struct InitializerSettingsV2Full {
        string tokenName;
        string tokenSymbol;
        address TokenURIPredicateContract;
        uint256 cap;
        address mintEligibilityPredicateContract;
        address mintFeePredicateContract;
        uint16 royaltyBps;
        address signatureBlockAddress;
    }

    function encodeSettingsV1Full(
        string memory _tokenName,
        string memory  _tokenSymbol,
        string memory _baseTokenURI,
        uint256 _cap,
        address _mintEligibilityPredicateContract,
        address _mintFeePredicateContract,
        uint16 _royaltyBps,
        address _signatureBlockAddress
    ) internal returns (bytes memory) {

        InitializerSettingsV1Full memory _initializerSettings;

        _initializerSettings.tokenName = _tokenName;
        _initializerSettings.tokenSymbol = _tokenSymbol;
        _initializerSettings.baseTokenURI = _baseTokenURI;
        _initializerSettings.cap = _cap;
        _initializerSettings.mintEligibilityPredicateContract = _mintEligibilityPredicateContract;
        _initializerSettings.mintFeePredicateContract = _mintFeePredicateContract;
        _initializerSettings.royaltyBps = _royaltyBps;
        _initializerSettings.signatureBlockAddress = _signatureBlockAddress;

        return (abi.encode(_initializerSettings));
    }

    function encodeSettingsV2Full(
        string memory _tokenName,
        string memory  _tokenSymbol,
        address _TokenURIPredicateContract,
        uint256 _cap,
        address _mintEligibilityPredicateContract,
        address _mintFeePredicateContract,
        uint16 _royaltyBps,
        address _signatureBlockAddress
    ) internal returns (bytes memory) {

        InitializerSettingsV2Full memory _initializerSettings;

        _initializerSettings.tokenName = _tokenName;
        _initializerSettings.tokenSymbol = _tokenSymbol;
        _initializerSettings.TokenURIPredicateContract = _TokenURIPredicateContract;
        _initializerSettings.cap = _cap;
        _initializerSettings.mintEligibilityPredicateContract = _mintEligibilityPredicateContract;
        _initializerSettings.mintFeePredicateContract = _mintFeePredicateContract;
        _initializerSettings.royaltyBps = _royaltyBps;
        _initializerSettings.signatureBlockAddress = _signatureBlockAddress;

        return (abi.encode(_initializerSettings));
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

    //The structure that helps map the relevant text to the x coordinate position
    struct textAndPosition {
        string textRaw;
        string textPosition;
    }

    //The structure that maps/defines which properties each frog has
    struct coordinateMapping {
        uint256 colour;
        uint256 eyes;
        uint256 mouth;
        uint256 body;
        uint256 legs;
        uint256 name;
    }

    //Calls the Hashfrogs library and draws a Hahsfrog with the hash as a seed
    function getTokenURI(uint256 _tokenId, uint256 _hashesTokenId, bytes32 _hashesHash) external view override returns (string memory) {
        //Uses the Hashes hash as the pseudo-random seed
        uint256 seed = uint256(_hashesHash);

        coordinateMapping memory frogFeatures;

        string[11] memory backgroundColour;

        backgroundColour[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 88 88"><style>.base { fill: black; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="green" />'; 
        backgroundColour[1] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 88 88"><style>.base { fill: black; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="brown" />';
        backgroundColour[2] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 88 88"><style>.base { fill: black; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="red" />'; 
        backgroundColour[3] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 88 88"><style>.base { fill: black; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="yellow" />'; 
        backgroundColour[4] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 88 88"><style>.base { fill: black; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="orange" />'; 
        backgroundColour[5] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 88 88"><style>.base { fill: black; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="pink" />';
        backgroundColour[6] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 88 88"><style>.base { fill: black; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="purple" />'; 
        backgroundColour[7] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 88 88"><style>.base { fill: black; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="white" />';
        backgroundColour[8] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 88 88"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" />';
        backgroundColour[9] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 88 88"><style>.base { fill: black; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="blue" />';
        backgroundColour[10] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 88 88"><style>.base { fill: black; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="grey" />';

        textAndPosition[17] memory frogEyes;

        frogEyes[0] = textAndPosition("@[email protected]", '<text x="27" y="20" class="base">');
        frogEyes[1] = textAndPosition("*..*", '<text x="33" y="20" class="base">');
        frogEyes[2] = textAndPosition("#..#", '<text x="33" y="20" class="base">');
        frogEyes[3] = textAndPosition("%..%", '<text x="28" y="20" class="base">');
        frogEyes[4] = textAndPosition("+..+", '<text x="32" y="20" class="base">');
        frogEyes[5] = textAndPosition("$..$", '<text x="33" y="20" class="base">');
        frogEyes[6] = textAndPosition("o..o", '<text x="33" y="20" class="base">');
        frogEyes[7] = textAndPosition("x..x", '<text x="32.5" y="20" class="base">');
        frogEyes[8] = textAndPosition("=..=", '<text x="32" y="20" class="base">');
        frogEyes[9] = textAndPosition("{}..{}", '<text x="27" y="20" class="base">');
        frogEyes[10] = textAndPosition("o..0", '<text x="33" y="20" class="base">');
        frogEyes[11] = textAndPosition("0..o", '<text x="33" y="20" class="base">');
        frogEyes[12] = textAndPosition("0..0", '<text x="33" y="20" class="base">');
        frogEyes[13] = textAndPosition("-..-", '<text x="35" y="20" class="base">');
        frogEyes[14] = textAndPosition("-..*", '<text x="35" y="20" class="base">');
        frogEyes[15] = textAndPosition("0..-", '<text x="34.5" y="20" class="base">');
        frogEyes[16] = textAndPosition("^..^", '<text x="34" y="20" class="base">');

        textAndPosition[5] memory frogMouth;

        frogMouth[0] = textAndPosition("(-----)", '</text><text x="27" y="32" class="base">');
        frogMouth[1] = textAndPosition("(--o--)", '</text><text x="25.5" y="32" class="base">');
        frogMouth[2] = textAndPosition("(~~~~)", '</text><text x="23" y="32" class="base">');
        frogMouth[3] = textAndPosition("(====)", '</text><text x="23" y="32" class="base">');
        frogMouth[4] = textAndPosition("(::::::)", '</text><text x="27" y="32" class="base">');

        textAndPosition[9] memory frogBody;

        frogBody[0] = textAndPosition("( e___e )", '</text><text x="17.8" y="44" class="base">');
        frogBody[1] = textAndPosition("( s___s )", '</text><text x="19" y="44" class="base">');
        frogBody[2] = textAndPosition("( q___p )", '</text><text x="17.8" y="44" class="base">');
        frogBody[3] = textAndPosition("( o___o )", '</text><text x="17.8" y="44" class="base">');
        frogBody[4] = textAndPosition("( (____) )", '</text><text x="16" y="44" class="base">');
        frogBody[5] = textAndPosition("( !____! )", '</text><text x="16" y="44" class="base">');
        frogBody[6] = textAndPosition("( 8___8 )", '</text><text x="17.8" y="44" class="base">');
        frogBody[7] = textAndPosition("( a___a )", '</text><text x="17.8" y="44" class="base">');
        frogBody[8] = textAndPosition("( b___d )", '</text><text x="17.8" y="44" class="base">');

        textAndPosition[3] memory frogLegs;

        frogLegs[0] = textAndPosition("^^ ~ ~ ^^", '</text><text x="17" y="56" class="base">');
        frogLegs[1] = textAndPosition("m ~ ~ m", '</text><text x="19.8" y="56" class="base">');
        frogLegs[2] = textAndPosition("vv ~ ~ vv", '</text><text x="16" y="56" class="base">');

        textAndPosition[41] memory frogNames;

        frogNames[0] = textAndPosition("Toadie", '</text><text x="24" y="78" class="base">');
        frogNames[1] = textAndPosition("Hoppy", '</text><text x="24" y="78" class="base">');
        frogNames[2] = textAndPosition("Trippy", '</text><text x="24" y="78" class="base">');
        frogNames[3] = textAndPosition("Tad P.", '</text><text x="26" y="78" class="base">');
        frogNames[4] = textAndPosition("Saggy", '</text><text x="25" y="78" class="base">');
        frogNames[5] = textAndPosition("Ribby", '</text><text x="26" y="78" class="base">');
        frogNames[6] = textAndPosition("Swampy", '</text><text x="18.5" y="78" class="base">');
        frogNames[7] = textAndPosition("Croak", '</text><text x="26" y="78" class="base">');
        frogNames[8] = textAndPosition("Licky", '</text><text x="26.5" y="78" class="base">');
        frogNames[9] = textAndPosition("Jumpy", '</text><text x="24" y="78" class="base">');
        frogNames[10] = textAndPosition("Webby", '</text><text x="23.5" y="78" class="base">');
        frogNames[11] = textAndPosition("Leapy", '</text><text x="25" y="78" class="base">');
        frogNames[12] = textAndPosition("Petal", '</text><text x="29" y="78" class="base">');
        frogNames[13] = textAndPosition("Poppy", '</text><text x="25" y="78" class="base">');
        frogNames[14] = textAndPosition("Busta", '</text><text x="26.5" y="78" class="base">');
        frogNames[15] = textAndPosition("Phrog", '</text><text x="26.5" y="78" class="base">');
        frogNames[16] = textAndPosition("Fredo", '</text><text x="27" y="78" class="base">');
        frogNames[17] = textAndPosition("Kronk", '</text><text x="26" y="78" class="base">');
        frogNames[18] = textAndPosition("Slippy", '</text><text x="25" y="78" class="base">');
        frogNames[19] = textAndPosition("Kermit", '</text><text x="24" y="78" class="base">');
        frogNames[20] = textAndPosition("Froakie", '</text><text x="22" y="78" class="base">');
        frogNames[21] = textAndPosition("Daphne", '</text><text x="22" y="78" class="base">');
        frogNames[22] = textAndPosition("Bogart", '</text><text x="24" y="78" class="base">');
        frogNames[23] = textAndPosition("Bubbles", '</text><text x="20.5" y="78" class="base">');
        frogNames[24] = textAndPosition("Goliath", '</text><text x="22.5" y="78" class="base">');
        frogNames[25] = textAndPosition("Frogga", '</text><text x="23.5" y="78" class="base">');
        frogNames[26] = textAndPosition("Tickles", '</text><text x="23.5" y="78" class="base">');
        frogNames[27] = textAndPosition("Speckles", '</text><text x="18" y="78" class="base">');
        frogNames[28] = textAndPosition("Hopscotch", '</text><text x="13" y="78" class="base">');
        frogNames[29] = textAndPosition("Anne Phibby", '</text><text x="7" y="78" class="base">');
        frogNames[30] = textAndPosition("Jeremiah", '</text><text x="18" y="78" class="base">');
        frogNames[31] = textAndPosition("Fritter", '</text><text x="26" y="78" class="base">');
        frogNames[32] = textAndPosition("Nibbler", '</text><text x="22" y="78" class="base">');
        frogNames[33] = textAndPosition("Cooki", '</text><text x="25" y="78" class="base">');
        frogNames[34] = textAndPosition("Bonk", '</text><text x="28" y="78" class="base">');
        frogNames[35] = textAndPosition("Bork", '</text><text x="28.5" y="78" class="base">');
        frogNames[36] = textAndPosition("Pepe", '</text><text x="29" y="78" class="base">');
        frogNames[37] = textAndPosition("Fern", '</text><text x="30" y="78" class="base">');
        frogNames[38] = textAndPosition("Lilly", '</text><text x="30" y="78" class="base">');
        frogNames[39] = textAndPosition("Paddy", '</text><text x="26" y="78" class="base">');
        frogNames[40] = textAndPosition("Dart", '</text><text x="30.5" y="78" class="base">');
        
        //Randomizes the frog features given the Hashes hash seed
        frogFeatures.colour = (seed % backgroundColour.length);
        frogFeatures.eyes = (seed % frogEyes.length);
        frogFeatures.mouth = (seed % frogMouth.length);
        frogFeatures.body = (seed % frogBody.length);
        frogFeatures.legs = (seed % frogLegs.length);
        frogFeatures.name = (seed % frogNames.length);

        //Assembles the output
        string[12] memory parts;
        parts[0] = backgroundColour[frogFeatures.colour]; //'<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 88 88"><style>.base { fill: black; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="green" />';

        parts[1] = frogEyes[frogFeatures.eyes].textPosition; //'<text x="35" y="20" class="base">';

        parts[2] = frogEyes[frogFeatures.eyes].textRaw; //"-..*";

        parts[3] = frogMouth[frogFeatures.mouth].textPosition; //'</text><text x="25" y="32" class="base">';

        parts[4] = frogMouth[frogFeatures.mouth].textRaw; //"(~~~~)";

        parts[5] = frogBody[frogFeatures.body].textPosition; //'</text><text x="17.8" y="44" class="base">';

        parts[6] = frogBody[frogFeatures.body].textRaw; //"( e___e )";

        parts[7] = frogLegs[frogFeatures.legs].textPosition; //'</text><text x="16" y="56" class="base">';

        parts[8] = frogLegs[frogFeatures.legs].textRaw; //"vv ~ ~ vv";

        parts[9] = frogNames[frogFeatures.name].textPosition; //'</text><text x="31.5" y="78" class="base">';

        parts[10] = frogNames[frogFeatures.name].textRaw;  //"Toadie";

        parts[11] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11]));
        
        //To get around stack too deep
        string memory tokenNumber = toString(_tokenId);
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "', frogNames[frogFeatures.name].textRaw, ' the HashFrog #', tokenNumber, '", "description": "Ribbit...", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    /// @notice buildInitializationDataV1 An address which has some distinct maintenance abilities. These
    ///         include the ability to remove implementation addresses or collection instances, as well as
    ///         transfer this role to another address. Implementation addresses can choose to use this address
    ///         for certain roles since it is passed through to the initialize function upon creating
    ///         a cloned collection.

    /**
     * @notice This function adds an implementation address.
     * @param tokenName The ecosystem which this implementation address will reference.
     * @param tokenSymbol The address of the Collection contract.
     * @param baseTokenURI Whether this implementation address is cloneable.
     */
    function buildFullInitializationDataV1(
        string memory tokenName,
        string memory  tokenSymbol,
        string memory baseTokenURI,
        uint256 cap,
        address mintEligibilityPredicateContract,
        address mintFeePredicateContract,
        uint16 royaltyBps,
        address signatureBlockAddress
    ) external returns (bytes memory) {
        return Encode.encodeSettingsV1Full(tokenName, tokenSymbol, baseTokenURI, cap, mintEligibilityPredicateContract, mintFeePredicateContract, royaltyBps, signatureBlockAddress);
    }

    /// @notice 
    ///           #..#       
    ///          (====) 
    ///         ( 6__9 )   
    ///         ^^ ~~ ^^        
    ///         

    /**
     * @notice #..#
     *         (====) 
     *        ( 6__9 )
     *        ^^ ~~ ^^   
     */
    function buildFullInitializationDataV2(
        string memory tokenName,
        string memory  tokenSymbol,
        address tokenURIPredicateContract,
        uint256 cap,
        address mintEligibilityPredicateContract,
        address mintFeePredicateContract,
        uint16 royaltyBps,
        address signatureBlockAddress
    ) external returns (bytes memory) {
        return Encode.encodeSettingsV2Full(tokenName, tokenSymbol, tokenURIPredicateContract, cap, mintEligibilityPredicateContract, mintFeePredicateContract, royaltyBps, signatureBlockAddress);
    }

    function buildCustomInitializationDataV1() external returns (bytes memory) {
        //return Encode.encodeSettings();
    }

    function buildCustomInitializationDataV2() external returns (bytes memory) {
        //return Encode.encodeSettings();
    } 
}
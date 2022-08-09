/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

// Chomsky Predicates Contract
//
//         0..0       
//        (~~~~) 
//       ( s__s )   
//       ^^ ~~ ^^    
//
// A Fragments DAO Collection

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
//ChomskyPredicates
//*******************

contract ChomskyPredicates is Ownable, ICollectionNFTEligibilityPredicate, ICollectionNFTMintFeePredicate, ICollectionNFTTokenURIPredicate {
    
    //Anyone can mint
    function isTokenEligibleToMint(uint256 _tokenId, uint256 _hashesTokenId) external view override returns (bool) {
    return true;
    }
    
    //0.01eth mint fee
    function getTokenMintFee(uint256 _tokenId, uint256 _hashesTokenId) external view override returns (uint256) {
    return 0.02e18;
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

    //Struct used to store the grid overlays
    struct namedBoolArray {
        string name;
        bool[61] vector;
    }

    //Struct used to store the start vectors
    struct namedVectorArray {
        string name;
        uint256[2] vector; 
    }

    //Struct used to store the foreground overlays
    struct namedStringArray {
        string name;
        string[2] vector; 
    }

    //Struct used to store the background overlays and Duration
    struct namedString {
        string name;
        string vector;
    }

    //Struct used to store the NFT data
    struct attributes {
        uint256 seed;
        namedBoolArray grid;
        namedVectorArray start;
        namedString duration;
        namedString backgroundcolour;
        namedStringArray foregroundcolour;
        string stages0;
        string stages1;
    }

    //Draws a Hahsfrog with the hash as a seed
    function getTokenURI(uint256 _tokenId, uint256 _hashesTokenId, bytes32 _hashesHash) external view override returns (string memory) {

        //Placeholder/dummy variables
        string memory temp = "";
        string memory templist = "";

        //Array containing all of the named background colours
        namedString[5] memory backgroundColours = [
            namedString("Colourless", "#fff8dc"),
            namedString("Invisible", "#191970"),
            namedString("Achromatic", "#4682b4"),
            namedString("Characterless", "#a52a2a"),
            namedString("Unseeable", "#dc143c")
        ];
        
        //cornsilk: #fff8dc
        //midnightblue: #191970
        //steelblue: #4682b4
        //brown: #a52a2a
        //crimson: #dc143c

        //Array containing all of the named foreground colours
        namedStringArray[12] memory foregroundColours = [ 
            namedStringArray("Green", [
                "#fff8dc", 
                "#fff8dc;#dc143c;#fff8dc;#fff8dc"]),
            namedStringArray("Yellow", [
                "#fff8dc", 
                "#fff8dc;#4682b4;#fff8dc;#fff8dc"]),
            namedStringArray("Maroon", [
                "#fff8dc", 
                "#fff8dc;#191970;#fff8dc;#fff8dc"]),
            namedStringArray("Orange", [
                "#fff8dc", 
                "#fff8dc;#a52a2a;#fff8dc;#fff8dc"]),
            namedStringArray("Blue", [
                "#a52a2a", 
                "#a52a2a;#dc143c;#a52a2a;#a52a2a"]),
            namedStringArray("Brown", [
                "#a52a2a", 
                "#a52a2a;#fff8dc;#a52a2a;#a52a2a"]),
            namedStringArray("Purple", [
                "#dc143c", 
                "#dc143c;#a52a2a;#dc143c;#dc143c"]),
            namedStringArray("Grey", [
                "#dc143c", 
                "#dc143c;#fff8dc;#dc143c;#dc143c"]),
            namedStringArray("Red", [
                "#4682b4", 
                "#4682b4;#191970;#4682b4;#4682b4"]),
            namedStringArray("White", [
                "#4682b4", 
                "#4682b4;#fff8dc;#4682b4;#4682b4"]),
            namedStringArray("Pink", [
                "#191970", 
                "#191970;#4682b4;#191970;#191970"]),
            namedStringArray("Black", [
                "#191970", 
                "#191970;#fff8dc;#191970;#191970"])
        ];

        //Matrix containing all of the grid overlays
        namedBoolArray[11] memory grids = [
            namedBoolArray("Dreams", [
                            false, true, false, true, false,
                         false, true, false, false, true, false,
                      false, false, false, true, false, false, false,
                   false, true, false, true, true, false, true, false, 
                false, true, false, true, true, true, false, true, false, 
                   false, true, false, true, true, false, true, false, 
                     false, false, false, true, false, false, false, 
                         false, true, false, false, true, false, 
                            false, true, false, true, false]),
            namedBoolArray("Visions", [
                            true, false, false, false, true,
                         true, true, false, false, true, true,
                      false, true, false, true, false, true, false,
                   false, false, false, true, true, false, false, false, 
                false, false, false, true, true, true, false, false, false, 
                   false, false, false, true, true, false, false, false, 
                      false, true, false, true, false, true, false, 
                         true, true, false, false, true, true, 
                            true, false, false, false, true]),
            namedBoolArray("Desires", [
                           false, false, false, false, true,
                         true, false, true, false, true, false,
                     true, false, true, false, true, false, true,
                   true, true, false, false, true, true, false, false,
                true, true, false, false, true, true, false, false, true,
                   true, false, true, false, true, false, true, false,
                     true, false, true, false, true, false, true,
                       true, true, false, false, true, true,
                          true, false, false, false, false]), 
            namedBoolArray("Ideas", [
                           true, false, false, false, false,
                         true, true, false, false, false, true,
                      true, true, true, false, false, true, true,
                   false, true, true, false, false, true, true, true, 
                false, false, true, false, true, false, true, true, false, 
                   false, false, false, true, true, false, true, false, 
                      false, false, true, true, true, false, false, 
                         false, false, true, true, false, false, 
                            false, false, true, false, false]),
            namedBoolArray("Memories", [  
                            false, false, true, false, false,
                         false, false, true, true, false, false,
                      false, false, true, true, true, false, false,
                   false, false, true, true, true, true, false, false, 
                false, false, true, true, true, true, true, false, false, 
                   false, false, true, true, true, true, false, false, 
                      false, false, true, true, true, false, false, 
                         false, false, true, true, false, false, 
                            false, false, true, false, false]),
            namedBoolArray("Thoughts", [
                           true, false, false, false, false,
                         true, false, false, false, false, true,
                       true, false, true, true, true, true, false,
                    true, true, false, false, false, true, true, false,
                true, false, true, true, true, true, false, false, true, 
                   true, false, false, false, false, true, false, false, 
                      true, true, false, false, false, true, true, 
                         true,false, false, false, false, true, 
                             true, false, false, true, true]),
            namedBoolArray("Concepts", [
                            false, false, true, false, true,
                         false, false, true, false, false, false,
                      true, false, false, true, true, true, false,
                   true, false, false, true, false, false, true, true,
                false, false, true, false, true, false, false, true, false,
                   false, false, false, false, false, false, true, false,
                      false, true, false, false, false, true, false,
                          false, false, false, true, false, false,
                            true, false, false, true, false]),
            namedBoolArray("Beliefs", [
                            false, true, false, false, true,
                          true, false, false, true, false, false,
                      false, false, true, false, false, true, false,
                  false, true, false, false, true, false, false, true,
                true, false, false, true, false, false, true, false, false,
                  false, true, false, false, true, false, false, true,
                      false, false, true, false, false, true, false,
                         true, false, false, true, false, false,
                            false, true, false, false, true]),
            namedBoolArray("Moments", [
                            true, false, false, false, false,
                         true, true, false, true, true, true,
                     false, true, false, true, true, true, false,
                  false, false, false, false, false, false, false, false,
                false, true, false, false, true, false, false, true, false,
                  false, false, false, true, true, true, false, false,
                     false, true, true, true, false, false, false,
                        false, true, false, false, true, false,
                          false, true, false, false, true]),
            namedBoolArray("Hallucinations", [
                           false, false, true, true, false,
                       false, false, true, true, true, false,
                     false, true, false, false, true, false, true,
                  false, false, false, false, false, false, false, false,
                false, true, false, false, true, false, true, true, false,
                  false, false, true, true, true, false, false, true,
                      false, false, true, false, false, false, false,
                        false, true, true, true, true, false,
                           false, true, false, false, true]),
            namedBoolArray("Notions", [
                           false, true, false, false, true,
                         false, true, false, false, true, false,
                      false, false, false, false, false, false, false,
                   false, false, true, true, true, false, false, true,
                true, false, false, false, false, false, false, false, false,
                   false, true, false, false, true, false, true, false,
                      false, false, true, true, true, false, false,
                         false, true, false, false, true, false,
                           false, false, true, false, false])
        ];

        //Matrix containing all of the start time overlays
        namedVectorArray[23] memory starts = [
            namedVectorArray("Sleep", [uint256(1), uint256(5)]),
            namedVectorArray("Work", [uint256(1), uint256(6)]),
            namedVectorArray("Eat", [uint256(1), uint256(7)]),
            namedVectorArray("Run", [uint256(1), uint256(8)]),
            namedVectorArray("Cheat", [uint256(1), uint256(9)]),
            namedVectorArray("Stare", [uint256(1), uint256(10)]),
            namedVectorArray("Meditate", [uint256(1), uint256(11)]),
            namedVectorArray("Gesture", [uint256(1), uint256(13)]),
            namedVectorArray("Clap", [uint256(1), uint256(15)]),
            namedVectorArray("Listen", [uint256(1), uint256(17)]),
            namedVectorArray("Scream", [uint256(6), uint256(5)]),
            namedVectorArray("Lie", [uint256(5), uint256(6)]),
            namedVectorArray("Swim", [uint256(6), uint256(7)]),
            namedVectorArray("Whimper", [uint256(7), uint256(8)]),
            namedVectorArray("Love", [uint256(8), uint256(9)]),
            namedVectorArray("Cry", [uint256(9), uint256(10)]),
            namedVectorArray("Write", [uint256(10), uint256(11)]),
            namedVectorArray("Talk", [uint256(11), uint256(13)]),
            namedVectorArray("Draw", [uint256(13), uint256(15)]),
            namedVectorArray("Dance", [uint256(15), uint256(17)]),
            namedVectorArray("Mimic", [uint256(4), uint256(7)]),
            namedVectorArray("Smile", [uint256(4), uint256(9)]),
            namedVectorArray("Skip", [uint256(4), uint256(11)])
        ];

        //Matrix containing all of the duration time overlays
        namedString[7] memory durations = [
            namedString("Furiously", "5"),
            namedString("Endlessly", "7"),
            namedString("Fervently", "9"),
            namedString("Effortlessly", "11"),
            namedString("Carefully", "13"),
            namedString("Coldly", "15"),
            namedString("Diligently", "17")
        ];

        //Hex locations in order top left to bottom right
        string[61] memory hexLocations = [
            "4912,2780 5588,2390 5588,1610 4912,1220 4236,1610 4236,2390", 
            "6368,2780 7044,2390 7044,1610 6368,1220 5692,1610 5692,2390", 
            "7824,2780 8500,2390 8500,1610 7824,1220 7148,1610 7148,2390", 
            "9280,2780 9956,2390 9956,1610 9280,1220 8604,1610 8604,2390", 
            "10736,2780 11412,2390 11412,1610 10736,1220 10060,1610 10060,2390", 
            "4184,4040 4860,3650 4860,2870 4184,2480 3508,2870 3508,3650", 
            "5640,4040 6316,3650 6316,2870 5640,2480 4964,2870 4964,3650", 
            "7096,4040 7772,3650 7772,2870 7096,2480 6420,2870 6420,3650", 
            "8552,4040 9228,3650 9228,2870 8552,2480 7876,2870 7876,3650", 
            "10008,4040 10684,3650 10684,2870 10008,2480 9332,2870 9332,3650", 
            "11464,4040 12140,3650 12140,2870 11464,2480 10788,2870 10788,3650", 
            "3456,5300 4132,4910 4132,4130 3456,3740 2780,4130 2780,4910", 
            "4912,5300 5588,4910 5588,4130 4912,3740 4236,4130 4236,4910", 
            "6368,5300 7044,4910 7044,4130 6368,3740 5692,4130 5692,4910", 
            "7824,5300 8500,4910 8500,4130 7824,3740 7148,4130 7148,4910", 
            "9280,5300 9956,4910 9956,4130 9280,3740 8604,4130 8604,4910", 
            "10736,5300 11412,4910 11412,4130 10736,3740 10060,4130 10060,4910", 
            "12192,5300 12868,4910 12868,4130 12192,3740 11516,4130 11516,4910", 
            "2728,6560 3404,6170 3404,5390 2728,5000 2052,5390 2052,6170", 
            "4184,6560 4860,6170 4860,5390 4184,5000 3508,5390 3508,6170", 
            "5640,6560 6316,6170 6316,5390 5640,5000 4964,5390 4964,6170", 
            "7096,6560 7772,6170 7772,5390 7096,5000 6420,5390 6420,6170", 
            "8552,6560 9228,6170 9228,5390 8552,5000 7876,5390 7876,6170", 
            "10008,6560 10684,6170 10684,5390 10008,5000 9332,5390 9332,6170", 
            "11464,6560 12140,6170 12140,5390 11464,5000 10788,5390 10788,6170", 
            "12920,6560 13596,6170 13596,5390 12920,5000 12244,5390 12244,6170", 
            "2000,7820 2676,7430 2676,6650 2000,6260 1324,6650 1324,7430", 
            "3456,7820 4132,7430 4132,6650 3456,6260 2780,6650 2780,7430", 
            "4912,7820 5588,7430 5588,6650 4912,6260 4236,6650 4236,7430", 
            "6368,7820 7044,7430 7044,6650 6368,6260 5692,6650 5692,7430", 
            "7824,7820 8500,7430 8500,6650 7824,6260 7148,6650 7148,7430", 
            "9280,7820 9956,7430 9956,6650 9280,6260 8604,6650 8604,7430", 
            "10736,7820 11412,7430 11412,6650 10736,6260 10060,6650 10060,7430", 
            "12192,7820 12868,7430 12868,6650 12192,6260 11516,6650 11516,7430", 
            "13648,7820 14324,7430 14324,6650 13648,6260 12972,6650 12972,7430", 
            "2728,9080 3404,8690 3404,7910 2728,7520 2052,7910 2052,8690", 
            "4184,9080 4860,8690 4860,7910 4184,7520 3508,7910 3508,8690", 
            "5640,9080 6316,8690 6316,7910 5640,7520 4964,7910 4964,8690", 
            "7096,9080 7772,8690 7772,7910 7096,7520 6420,7910 6420,8690", 
            "8552,9080 9228,8690 9228,7910 8552,7520 7876,7910 7876,8690", 
            "10008,9080 10684,8690 10684,7910 10008,7520 9332,7910 9332,8690", 
            "11464,9080 12140,8690 12140,7910 11464,7520 10788,7910 10788,8690", 
            "12920,9080 13596,8690 13596,7910 12920,7520 12244,7910 12244,8690", 
            "3456,10340 4132,9950 4132,9170 3456,8780 2780,9170 2780,9950", 
            "4912,10340 5588,9950 5588,9170 4912,8780 4236,9170 4236,9950", 
            "6368,10340 7044,9950 7044,9170 6368,8780 5692,9170 5692,9950", 
            "7824,10340 8500,9950 8500,9170 7824,8780 7148,9170 7148,9950", 
            "9280,10340 9956,9950 9956,9170 9280,8780 8604,9170 8604,9950", 
            "10736,10340 11412,9950 11412,9170 10736,8780 10060,9170 10060,9950", 
            "12192,10340 12868,9950 12868,9170 12192,8780 11516,9170 11516,9950", 
            "4184,11600 4860,11210 4860,10430 4184,10040 3508,10430 3508,11210", 
            "5640,11600 6316,11210 6316,10430 5640,10040 4964,10430 4964,11210", 
            "7096,11600 7772,11210 7772,10430 7096,10040 6420,10430 6420,11210", 
            "8552,11600 9228,11210 9228,10430 8552,10040 7876,10430 7876,11210", 
            "10008,11600 10684,11210 10684,10430 10008,10040 9332,10430 9332,11210", 
            "11464,11600 12140,11210 12140,10430 11464,10040 10788,10430 10788,11210", 
            "4912,12860 5588,12470 5588,11690 4912,11300 4236,11690 4236,12470", 
            "6368,12860 7044,12470 7044,11690 6368,11300 5692,11690 5692,12470", 
            "7824,12860 8500,12470 8500,11690 7824,11300 7148,11690 7148,12470", 
            "9280,12860 9956,12470 9956,11690 9280,11300 8604,11690 8604,12470", 
            "10736,12860 11412,12470 11412,11690 10736,11300 10060,11690 10060,12470"
        ];

        //Defines the NFT attributes
        attributes memory _attributes;

        //Sets the core information using the Hashes NFT as the seed
        _attributes.seed = uint256(_hashesHash);
        _attributes.grid = grids[(_attributes.seed % grids.length)];
        _attributes.start = starts[(_attributes.seed % starts.length)];
        _attributes.duration = durations[(_attributes.seed % durations.length)];
        _attributes.backgroundcolour = backgroundColours[(_attributes.seed % backgroundColours.length)];
        _attributes.foregroundcolour = foregroundColours[(_attributes.seed % foregroundColours.length)];

        //Sets the stages using the specified background and foreground colour schemes - called once rather than iteratively 61 times each
        _attributes.stages0 = string.concat(' ><animate attributeName="fill" values=', '"', _attributes.foregroundcolour.vector[0], '"', ' begin="0" end=');
        _attributes.stages1 = string.concat(' /><animate attributeName="fill" values=', '"', _attributes.foregroundcolour.vector[1], '"', ' begin=');
        
        //Sets the background
        templist = string.concat('<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 15648 14080"><rect width="100%" height="100%" fill=', '"', _attributes.backgroundcolour.vector , '"', ' />');

        //Iterates over all of the locations
        for (uint256 j = uint256(0); j < 61; j++) {

            //First checks if the hex is to be drawn given the attributes gird used
            if ((_attributes.grid.vector[j]) == false) {
                //If not add nothing to the templist
            }
            else {
                //Sets the start time given the start vector
                temp = toString((j * _attributes.start.vector[0]) % _attributes.start.vector[1]);
                //Places the hexagon
                temp = string.concat('<polygon points=', '"', hexLocations[j], '"', _attributes.stages0, '"', temp, '"', _attributes.stages1, '"', temp, '"', ' dur=', '"', _attributes.duration.vector, '"', ' repeatCount="indefinite" /></polygon>');

                //Adds it to the templist string for later encoding
                templist = string(abi.encodePacked(templist, temp));
            }
        }
        
        //Caps it
        templist = string(abi.encodePacked(templist, '</svg>'));

        //Makes it readable and adds the attributes
        temp = string(abi.encodePacked('{"name": "', _attributes.backgroundcolour.name, ' ', _attributes.foregroundcolour.name, ' ', _attributes.grid.name,' ', _attributes.start.name, ' ',_attributes.duration.name,'", "description": "Semantics", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(templist)), '"'));
        temp = string(abi.encodePacked(temp, ', "attributes": [{ "trait_type": "Background", "value": "', _attributes.backgroundcolour.name, '"}, {"trait_type": "Foreground", "value": "', _attributes.foregroundcolour.name, '"}, { "trait_type": "Grid", "value": "', _attributes.grid.name,'"}, { "trait_type": "Delay", "value": "', _attributes.start.name, '" }, { "trait_type": "Duration", "value": "', _attributes.duration.name, '"}]}'));
        temp = string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(temp))));

        return temp;
    }
}
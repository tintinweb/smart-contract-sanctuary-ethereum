// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './IERC165.sol';
import './IERC721.sol';
import './IERC721Metadata.sol';
import './IERC721Receiver.sol';
import './Base64.sol';
import './Art.sol';

/**
 * @dev Minimal Purely On-chain ERC721
 */
contract ArtTest is Art
, IERC165 
, IERC721
, IERC721Metadata
{
    constructor () {
        _artist = msg.sender;
    }

    // Permissions ---
    address private _artist;
    modifier onlyArtist(){
        require(_artist == msg.sender, 'a');
        _;
    }

    // Interfaces ---
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public pure override(IERC165) returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId
            ;
    }

    // Metadata ---
    string private constant _name = 'TestContract';
    string private constant _symbol = 'TEST';
    string private constant _contractJson = "{\"name\":\"TestContract\",\"description\":\"Test Description\"}";

    function name() public pure override(IERC721Metadata) returns (string memory) {
        return _name;
    }

    function symbol() public pure override(IERC721Metadata) returns (string memory) {
        return _symbol;
    }

    // On-chain json must be wrapped in base64 dataUri also: 
    // Reference: https://andyhartnett.medium.com/solidity-tutorial-how-to-store-nft-metadata-and-svgs-on-the-blockchain-6df44314406b

    // Open sea contractURI to get open sea metadata
    // https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() public pure returns (string memory) {
        string memory jsonBase64 = Base64.encode(bytes(_contractJson));
        return string(abi.encodePacked('data:application/json;base64,', jsonBase64));
    }
    function contractJson() public pure returns (string memory) {
        return _contractJson;
    }

    function tokenURI(uint256 tokenId) public pure override(IERC721Metadata) returns (string memory) {
        return generateString(tokenId, 3);
    }

    // // Token Metadata:
    // /**
    // {
    //     "name": "{tokenName}",
    //     "image": "<svg width='100%' height='100%' viewBox='0 0 32 32' xmlns='http://www.w3.org/2000/svg' xmlns:svg='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'><image width='100%' height='100%' style='image-rendering:pixelated; image-rendering:crisp-edges' xlink:href='{tokenImage}'/></svg>", 
    // }
    //  */
    // string private constant _tokenJson_a = '{"name":"';
    // string private constant _tokenJson_b = "\",\"image\":\"";
    // string private constant _tokenJson_c = "\"}";

    // function getTokenName(uint256 tokenId) public pure returns (string memory) {
    //     return _symbol;
    // }
    // function getTokenImageSvg(uint256 tokenId) public pure returns (string memory) {
    //     return generateString(tokenId, 4);
    // }

    // // https://docs.opensea.io/docs/metadata-standards
    // function tokenURI(uint256 tokenId) public pure override(IERC721Metadata) returns (string memory) {
    //     string memory jsonBase64 = Base64.encode(bytes(tokenJson(tokenId)));
    //     return string(abi.encodePacked('data:application/json;base64,', jsonBase64));
    // }
    // function tokenJson(uint256 tokenId) public pure returns (string memory) {
    //     return string(abi.encodePacked(
    //         _tokenJson_a, 
    //         getTokenName(tokenId), 
    //         _tokenJson_b,
    //         getTokenImageSvg(tokenId),
    //         _tokenJson_c
    //     ));
    // }
    // function tokenImage(uint256 tokenId) public pure returns (string memory) {
    //     return getTokenImageSvg(tokenId);
    // }

    // Token Ownership ---
    uint256 private _totalSupply;
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // uint256 private _projectIdLast;

    /** tokenId => owner */ 
    mapping (uint256 => address) private _owners;
    function ownerOf(uint256 tokenId) public view override(IERC721) returns (address) {
        return _owners[tokenId];
    }

    /** Owner balances */
    mapping(address => uint256) private _balances;
    function balanceOf(address user) public view override(IERC721) returns (uint256) {
        return _balances[user];
    }

    /** Create a new nft
     *
     * tokenId = totalSupply (i.e. new tokenId = length, like a standard array index, first tokenId=0)
     */
    function createToken(uint256 tokenId) public onlyArtist returns (uint256) {

        // nextTokenId = _totalSupply
        require(_totalSupply == tokenId, 'n' );
        _totalSupply++;

        _balances[msg.sender] += 1;
        _owners[tokenId] = msg.sender;
    
        emit Transfer(address(0), msg.sender, tokenId);

        return tokenId;
    }

    // Transfers ---

    function _transfer(address from, address to, uint256 tokenId) internal  {
        // Is from actually the token owner
        require(ownerOf(tokenId) == from, 'o');
        // Does msg.sender have authority over this token
        require(_isApprovedOrOwner(tokenId), 'A');
        // Prevent sending to 0
        require(to != address(0), 't');

        // Clear approvals from the previous owner
        if(_tokenApprovals[tokenId] != address(0)){
            _approve(address(0), tokenId);
        }

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(IERC721) {
        _transfer(from, to, tokenId);
        _checkReceiver(from, to, tokenId, '');
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data_) public override(IERC721) {
        _transfer(from, to, tokenId);
        _checkReceiver(from, to, tokenId, data_);
    }
    function transferFrom(address from, address to, uint256 tokenId) public virtual override(IERC721) {
        _transfer(from, to, tokenId);
    }

    function _checkReceiver(address from, address to, uint256 tokenId, bytes memory data_) internal  {
        
        // If contract, confirm is receiver
        uint256 size; 
        assembly { size := extcodesize(to) }
        if (size > 0)
        {
            bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data_);
            require(retval == IERC721Receiver(to).onERC721Received.selector, 'z');
        }
    }

    // Approvals ---

    /** Temporary approval during token transfer */ 
    mapping (uint256 => address) private _tokenApprovals;

    function approve(address to, uint256 tokenId) public override(IERC721) {
        address owner = ownerOf(tokenId);
        require(owner == msg.sender || isApprovedForAll(owner, msg.sender), 'o');

        _approve(to, tokenId);
    }
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override(IERC721) returns (address) {
        return _tokenApprovals[tokenId];
    }

    /** Approval for all (operators approved to transfer tokens on behalf of an owner) */
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    function setApprovalForAll(address operator, bool approved) public virtual override(IERC721) {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    function isApprovedForAll(address owner, address operator) public view override(IERC721) returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function _isApprovedOrOwner(uint256 tokenId) internal view  returns (bool) {
        address owner = ownerOf(tokenId);
        return (owner == msg.sender 
            || getApproved(tokenId) == msg.sender 
            || isApprovedForAll(owner, msg.sender));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 */
library Base64 {
  /**
   * @dev Base64 Encoding/Decoding Table
   */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
     * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up 
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // Add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // Store the actual result length in memory
            mstore(result, encodedLen)

            // Prepare the lookup table
            let tablePtr := add(table, 1)

            // Prepare input pointer
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for { } lt(dataPtr, endPtr) { } {
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

                mstore(
                  resultPtr, 
                  shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1) // Advance
                
                mstore(
                  resultPtr, 
                  shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1) // Advance
                
                mstore(
                  resultPtr,
                  shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1) // Advance
                
                mstore(
                  resultPtr,
                  shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the beginning
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



abstract contract Art {

    function generateString(uint rvs, uint kind) public pure returns (string memory) {
        return string(generateBytes(rvs, kind));
    }

    /** 
     * kind: 64 = memory dump
     * 
     * kind: 4*0+0 = svg
     * kind: 4*0+1 = base64 svg
     * kind: 4*0+2 = json+svg
     * kind: 4*0+3 = tokenUri: base64 json+svg
     * 
     * kind: 4*1+0 = catBlock
     * kind: 4*1+1 = catBlock Breeding Ticket
     * kind: 4*1+2 = kittenBlock
     * kind: 4*1+3 = ?
     */
    function generateBytes(uint rvs, uint kind) public pure returns (bytes memory) {
        bytes memory output;
        

        // DataPack 
        bytes memory pDataPackCompressed = hex"08207374796c653d27086c696e656172477208ff02616469656e74073a75726c28237808207472616e73666f08ff0166696c6cff0404272f3e3c087472616e736c6174062069643d277806ff05726d3d27073b7374726f6b65083e3c73746f70ff0108ff0c73746f702d6308ff0d6f6c6f723a0008ff0eff072fff033e0820786c696e6b3a6808ff107265663d27230827ff0f3cff03ff09082f673e3c2f673e3c06ff0aff08652808ff07757365ff1178083d272d333030272008636c6970506174680666696c74657207273e3c7061746808206f706163697479087363616c65282d3108ff0b2d776964746807190c010e190c02063d2736303027070c0a0c0a1a0e010820636c69702d706108ff2074683d27757207190c080e190c09086c6c69707365ff06052720643d2707ff072f673e3c6705150a150a1a06190c0a0e1808083e3c72656374207808ff28ff1679ff167708ff2969647468ff1e08ff2a20686569676808272063793d2700270729272063783d2707190f0111190f020309180808191c0709191c080906ff216c28237806ff1d3c190c0305ff1a3d270007ff0aff1b2c312907ff2c2072783d2707ff0b2d6c696e6505130902040e06272072793d2708ff0166696c6c3a6e081918031319180409082003a5300f03a60e0828b1b2b3b4a9a40e082003a53028b5b6b707ff2b74ff1eff06063a726f756e6406190c070e0c0e060f0a0f0a1a1103273e3c0527ff14302c0300236604351a350304311a310504261a260607ff396f6e65ff0b07293bff18ff043207ff3db803a60e21082720ff17556e697408ff4b733d2775736508ff4c72537061636508ff25ff33ff19ff0608ff366a6f696eff3f0819180213ff3a191808286caaabaca7640e081c03a8de28adaeaf086b0e0000ff3c00000503041a0107030e12640470617468040e176828056174696f6e07ff4d4f6e55736507190c043d190c0507190f0611190f07073309331318330907180a180a1918010612272326180803302c2d0827ff01636f6c6f7208ff602d696e74657208ff61706f6cff582d08ff62ff18733a735208ff634742ff42666508ff6447617573736908ff65616e426c757208ff6620737464446508ff677669ff583d27082720726573756c7408ff693d27626c757208ff6aff072fff183e08ff42616e696d617408272072657065617408ff6d436f756e743d08ff6e27696e64656608ff6f696e6974652708ff59ff1920643d2708726f74617465280008191504301915051d08191205091912060908ff3b0000ff51000008ff75ff52b003ff5305110a110a1a05191217122004ff07ff13041b1a1b05031915010319150203191503031915060319150703191508067363616c652806ff153336ff4304211a2104041c0a1c0a07ff153239ff432007302c352c2d3630072920ff1b2c31290719110609191107071911022119110307ff30191c09ff2f071832090918321307ff500509191806071912021319120307ff74191207ff2f071c04bb2b02040e07031d03041a020305ff4265ff2305ff22090c0e050b0b191c060502060e126603451911036500230330002303673e3c030dff2f0319150403191505031915090319150a0319150b0319150c0319150d0319150e083d27687474703a2f08ffa22f7777772e7708ffa3332e6f72672f08ff6b3cff18ff093208ff6c654d6f74696f08ffa66e206475723d0873ff7020ff563d270827ff0635ff493529083429ff0bff04342908ffaaff4fff36636108ffab70ff3fff1c3a082c36302c352c363008ff04323329ff1c3a08ff48ffae302e3827080f0617190f07ff2f06757365ff117806093113183109060932131832090609330b183309060a120a191201065b205b176003052927ff3133050e0a0e0a1a05191807ff2f05130902060e041b1a1b0403190c06036600230330303003302c30031723200302040e072720786d6c6e7307ff15333127ff1407191f023e191f0307191103281911040708ff9509ff950a0719110c1719110d07190c042f190c0507190e0111190e0207190e010f190e0207190f0345190f0407181c0909181c130718200909182013071831090918311307172118011723180702e7ff5502e80e07ff4aa3ff76ff4a0465223a2204696e670004464646460429ff07670429ff426704ff07ff560308090803ff551c05ff072fff1705ff17ff093305ff5b13180805ff7b18ff7c05ffa1261808052a121712180520461760030529d44377d6030023330300233503ff123103ff244d03191c0103191c0203191c0303191c0403191c0506191f013e0c3e060a0e0a190e0106190e034b180806ff2e44190f0306191c092818080619120409ff8e0612262123180804ff1c3a3104ff5f313004ff1400290300236503002336031911010319110503190f05032602010365640003002364086174747269627574087b2274726169745f000000353120007b226e616dffd24b697474656e426c6f636b73222c22617574686f72223a224b726973747920476c61732026205269636b204c6f7665222c22fffd6573223a5bfffe747970ffd200222c2276616c75ffd200227d2cfffe747970ffd200617765736f6d656e657373222c2276616c75ffd231303025227d5d002c22696d6167ffd200227d00726f756e64006f76616c006469616d6f6e6400737175617269736800666c75666679007363727566667900706c61696e0063686f6e6b657200736c69636b0072656374616e67756c6172007465656e7900636865656b79006c656d6f6e0073696c6b790063687562627900736b696e6e79007769646500626c6f636b79007570726967687400616c65727400706f696e74790063757276fffb736c616e74fffb666f6c64fffb666c6f707079007369646577617973007065726b7900737068796e780066696572636500737175696e74ffd373756c6c656e006d65656b00737465726e006d65616e0064726f6f70790063726f737300616c6d6f6e6400646f6500676c6172ffd3736c6565707900706c656164ffd37468696e006269670068756765006e6f726d616c00736d616c6c007468696e6e657374006e65757472616c0070757273fffb706c656173fffb706f7574ffd364726f6f70ffd3646973706c656173fffb696d7061727469616c0064756c6c00736d696cffd3646f776e7761726400646f776e7761726453686f7274007570776172640075707761726453686f727400626c61636b00236238646566ffbd3161316231ff96636664326465ff44616661666100233066306631ff973837346636ff97ffbeffbeff44303964396400233264316631360023613036613661fff5646564fffb77686974ff9638623932653900233132313231320023303530353035ff443666366636ff443362346439ffe23833383338ff4466633264340023383232363733ffe263323532650067696e676572ffe36437626231ff4466616537ff97656364646435ff446366636663fff53938363439ff443761343634ff4466656465ff973861343030ffbd6365356635ffbd3332323731ffbd346232393162fff6663366326100677261790023376538343961fffc3264326462ffe33535343633fff66136653763ff4435633764ffbd336433643364ff44356232643400233730336535370062726f776eff4430663066ff97383135643431fffc6564316339ff4432646663ff96343033303163fff66534653335fffc64393739370023343932633138ff4430386538ff963735326634ff97326632333233006272697469736820626c75ff963565363337330023636464306435fffc61646365370023346435313661ffe33035353638fffc636137633100233236323432640023313331323163ffe3373537353700233139316131ffbd3137313631370063616c69636ffff537653264ff96653238343363ff443339363936fff66231653632fff664343034ff9732363236323600637265616d79fff53164306336fff533643663ff963265323532ff97626661383962ffe366343533340023343333353264002337393539343400233239323932390070696e6bffe36534633961ff446662386565ff443164666566ff4466663066ff96643337336265ff446262316561fffc35366462ff963563326535320023613834643934ffe26531383239fff63032393537ffe23431623336006379616e00236238663466ffbd6365646364ffbd6562663866ffbd3664613463ff97613065626638ffe33939626231ffe23835353631fff6383931623100233234323233ffbd313832613335002331353165323300677265656effe336366138ffbd3763613236390023636564656436ffe33037313431ffe237353834350023376139613661ffe2353537343400233166323332ff97333433613331002332343265316600666c65736879ff443364386438ff443265396539ff446665626562fff56362366236ff4433636563ff966433383839370023623437393739ff443061386138ffe365343034ff97613937353735ff4435663566350073616e64fff53463376234fff566653064370023633139643861fffc37623861330023626138383832fff630336533ff96376235363536ffe26132373237fff6663538353800746f79676572ff443039343735fffc65636164630023343932343164ffe238323531ffbd643439316262ffe23731353135002338303830383000626c75ff966436663966660079656c6c6f77ff4439653961ff96636166616133006f72616e6765ff446639633636fff566303930320074616262790073686f727468616972007369616d6573650073616e6463617400616c69656e007a6f6d6269ff963530353035ff9744423730393300234533384641420023ffd4464630ff97ffd4464600233031ffbe3038ff9733333333333300627265fffb70616c65747465006865616400656172006579657300657965436f6c6f72526967687400657965436f6c6f724c65667400707570696c73006d6f75746800776869736b657273003c3f786d6c2076657273696f6e3d27312e302720656e636f64696e673d275554462d3827207374616e64616c6f6e653d276e6f273f3e3c7376672077696474683d273130302527206865696768743d2731303025272076696577426f783d273020302033303020333030272076657273696f6e3d27312e31ffc23a786c696e6bffa4313939392f786c696e6bffc2ffa432ffbe2f737667ffc23a737667ffa432ffbe2f737667ff42646566733e3cff03ff0931ff1232ff1233ff1234ff1235ff1236ff1237ff1238ff1239ffe430ffe431ffe432ffe433ffe434ffe435ffe436ffe437ffe438ffe43927ff0f3cff03ff0f3cff03ff093230ff123231ff123232ff12323327ff0f3cff18ff093234ff68302030ffa535ff68302e3520302e35ffa536ff68352035ffa537ff68332033ff6b3c2f64656673ff3e31ffd5ff143135302e302c3135302e302920ff8131ffd6ff01ff18ff04323429ffa7273137ffa84d322c3563ff5f352c332c352c332c3063ff5f352d332c352d332c305aff07ff17ff093238ff714d002c004c005affda3e3c67ff3132382927ff3e32ffd5ff33ff19ff09323927ff48ff043529fff234ff2400ff85323729ff85353429ff85383129ff8531303829ff4e3729ffe5005affd7ff063829ffe5005aff25ff33ff4267ff093330ff19ff093331ffa9ffe5006336302c31352c36302c32302c36302c323063302c352d36fff32d36fff37affc3202d342c20313829ffc3202d382c333629ffc32d31322c353429ff072fff98ffb1333027ff34ff4e3429ffe5004800ff9134ff2d30272063793d27313635272072783d2700ff383530ff79ff98ff56ff063131ff49362927ff31323829ffe52d39ff5f3563ffbf2c34ff5f34302c39ff5f34306335ffbf2c39302c34302c39302c343063ffbf2c31302c35302c31302c3730632d32302cff5f37302c33fff3302c3330632d33302cff5f38ff5f33fff3ff5f333063ff5f32302c31ff5f37302c31ff5f37307aff79ff9867ff0aff81002c3129ff42ff98ff98ffdb32ff7100005335ffbf2cffbf5affdaff3e3133ffb732ffd5ff093333ffa7273331ffa84d302c3363ff5f332c322c332c322c3063ff5f332d322c332d322c305aff07ffdb34ff71005affdaff3e3134ffb73429ff79ff9867ff3427ff3e3132ffb73229ff153333ff792fff9867ff01ff18ff04323429ff42ffdb35ff71007affda3e3c67ff3133352927ff3e33ffd5ff33ff9134ff2d30ff353630ff383630ff4effac36ffe5302c004c2d3132342c004c3132342c00ff9134ff2d3130ff353131ff383131ff0765ff2334ff2d2d3130ff353131ff383131ff4e3429ff24004c3135ff5f3135305aff25ff33ff9136ff2d2d3638ff353735ff38313030ff4effac3132ffe52d31362c004c31362c00ff19ff06ffac3132ffe5302c354c2d31362c00ff9139ff2d30ff353136ff383335ff0765ff233130ff2d2d3736ff353730ff38313030ff0765ff2339ff2d3736ff353730ff38313030ff253e3cff56ff3327ff093336ffa9ffe5006336ffbfffad2c3563ff862c352c2d36302c357aff82313429ff822d313429ff8230ff87ff823134ff87ff822d3134ff87ffd7ff3327ff093337ffa9ffe52d32302c006330ffad2c352c363063352cff862c352c2d36307aff15333727ff1431352c3429ff15333727ff1433ffbf29ff79ff13ff9867fff420ff0865282d002c2d0029ff42ffdb38ff59ff19ff09333927fff420ff81312c312920ff7229ff24007aff6c6520fffd654e616d653d27642720747970653d27786d6cff70206475723d27347327206b657954696d65733d27303b302e343b302e353b302e363b31272076616c7565733d272000207a3b2000207a20ff072fff563e3c2fff17ff3e3136ffb738ffd5ff313338ffd6ff1400ffd6ff093430ff913138ff2d00ff3500ff3800ffa7273230ffa84dffbf63ff5f352c332c352c332c3063fff32d362c31302d362c305aff072f656c6c697073653e3cff9867fff4ff42636972636c6520723d27323527ff0aff81302e31352927ff063139ff493729ff25fff4ff42636972636c6520723d27313527ff0aff81302e31352927ff063139ff493729ff79ff132fff98757365ff09343127ff1178333927ff017374726f6b652d77696474683a32ff0bff043137293b66696c6c3a7472616e73706172656e74ff25ff142d002920ff086528002927ff2b74ff1eff3427ff063135ffb738ffd5ff3133382927ff34ff4267ff1400ff87ff42ffb13430ff79ffb1343127ff34ff7967ff14302c00ffd6ff14ffbfffd6ff14ffbf29ff19ff48ff04323029fff22e35ff24006c302effbe312c302effbe315affd7ff09343227ff48ff04323029fff22e35ff2400ff15343227ff34ff0767ff33ff4330ffd6ff09343327fff4ff19ffafff0aff72ffd7ffafff0aff72ffd7ffafff3327ff0aff72ff072fff98ffb1343327ff34ff79ff1367ff14ffbf29ff19ff06323129ff0bff04323129ff4ffff2ff24005affd7ff09343427ff06323229ff0bff04323129ff4ffff2ff2400ff15343427ff34ff792fff98ff987465787420783d2735252720793d27353025272066696c6c3d27234646ffbe302720746578746c656e6774683d27393025273e464f522054455354494e47204f4e4c59202d20636f6e74616374207269636b6c6f76652e6574683c2f746578743e3c2fff982f7376673e000b01000b02020b035a0b04660b05790b06970b07a20408010b01120908010b09000b0a0f0a0b0a0b0ca5190b010c0b0d370c0e0d190b020e0b0e49190b030e0b0f1d0c100f190b04100b1056190b05100b1117190b06110b125b190b07120b1301190b0813190b09090b14640c1514190b0a150b152c190b0b15190b0c0d190bff99090b0a0b0a0b16ab190b01160b16320c1716190b02170b174e190b03170c170f190b04170b1750190b05170b181c190b06180b1958190b07190b1a03190b081a190b09090c1b14190b0a1b0b1b23190b0b1b0b1c33190b0c1c190bff99130b0b0b020a1d0a0b1eb0191d011e0b1e360c1f1e191d021f0b1f4f191d031f0b20180c2120191d04210b2160191d05210b2119191d0621191d07100b220b191d08220b233f191d09230b244a0c2524191d0a250b2506191d0b250b262f191d0c26191dff990b1d0a1d0a0b27b8191d01270b27340c2827191d02280b284d191d03280c2921191d04290b295f191d0529191d0626191d07100c2a13191d082a191d09090c2a14191d0a2a0b2a20191d0b2a191d0c27191dff991a1d0b1d040a2b0a0b2cc1192b012c0c2c16192b022c0b2c46192b032c0b2d1a0c2e2d192b042e192b0514192b06210b2e5a192b072e0b2e3c0c2f2e192b082f192b09290c2f14192b0a2f0b2f14192b0b2f192b0c16192bff991d2b0b2b050a300a0b31c8193001310c311619300231193003280c312119300431193005120b3126193006311930071f0b3227193008320b3359193009330b340e19300a340b353019300b3519300c1e1930ff992b300a300a0b36d0193001360c370d193002371930031f0b371b0c383719300438193005330b382519300638193007190c392519300839193009090b39240c3a3919300a3a0b3a2b19300b3a19300c271930ff9925300b30070a3b0a0b3cd6193b013c0c3c26193b023c193b032c0c3c20193b043c0b3c63193b053c0b3d15193b063d0b3e5c193b073e0c3f2d193b083f193b09230c3f14193b0a3f0b3f31193b0b3f0b4038193b0c40193bff99303b0b3b080a410a0b42de194101420c421c194102421941030e0c422b194104420b4266194105421941062f0b4354194107430c442e194108441941092d0c441419410a4419410b380b443b19410c440b440d19410d4418083b410b41090a450a0b46e4194501460c462719450246194503100c104419450410194505121945060d194507170b100c194508100b124c194509120b465519450a460b472119450b4719450c161945ff9941450b450a0a480a0b49f0194801490c4a351948024a0b4a4b1948034a0b4b1e0c4c4b1948044c19480533194806471948071f1948081d194809090c1f3919480a1f19480b3519480c401948ff9945480a1f0a0b33f6191f01330c3316191f0233191f032c0c3318191f0433191f053e0b3329191f0633191f07430c350f191f0835191f094b0c351e191f0a35191f0b380b3535191f0c35191fff99221f0a1f0a0b3efdffeb3fffc4170c3e13191f043e0b3e61191f053e191f0620191f07430c3e1a191f083e191f09090c3e14191f0a3e191f0b38191f0c40191f0d0a1808101f0a1f0a1a3e0103ffeb16ffc42c0c3e45191f043e191f053c191f0633191f07460c3c2e191f083c191f0914191f0a34191f0b39191f0c0d191f0d441808441f0a1f0a1a3c0109191f013c0c3c35191f023c191f03240c3c25191f043c191f0519191f06320b1953191f0719191f082e191f09090c3c14191f0a3c0b3c28191f0b3c191f0c0d191f0d0a1808341f0a1f0a1a3e0110ffeb15ffc4280b3e130c403e191f04400b4044191f05400b401f191f0640191f0719191f082e191f093a191f0a12191f0b16191f0c16191fff990a1f0b19100a1f0a1a400117191f01400c461e191f02460b1e62191f031e0c463e191f04460b4657191f0546191f063c0b4851191f07480c4c13191f084c191f0909191f0a09191f0b4b0b4c2d191f0c4c191fff99191f0b1f110a4c0a1a4d011c194c014d0c4d27194c024d194c03170c4d2d194c044d194c051e194c0635194c0746194c081d194c09090c1e14194c0a1e194c0b2a194c0c16194cff991f4c051effd8340a460a19460136194602370c3613194603361946042719460530194606091946073e1946083f1946094419460a3519460b2119460c1719460d4519460eff2f09460a360a1a460123193601461936020f0c463d193603461936042c1936052f193606090c461d19360746193608190b46161936094619360a1919360b4b19360c1719360d4519360eff2f13360a360a1a4c012b1936014c193602110c4c331936034c0b3345193604331936051f193606090c331a193607331936081f1936092f19360a1119360b4b19360c2819360d4419360eff2f0b360a110a1a280131fff7281911020f0c2841ffc535fff809ff88ff95ffc6ff950b4b19110c1219110dff950e2918081a110a110afff7491911024b0c283effc516fff8ff95060b19110741191108221911092d19110a3d19110b4b19110c0e19110d450b0e7719110e0e18081dff77280138fff728191102180c281dffc516fff81fff88211911080f1911091d19110a3819110b4bffc7ff950eff2f2bff7728013ffff728ff89ff950432fff809ff88ff95ffc6ff950b2719110c4819110d2519110eff2f25ff77270147fff727ff89ff95042c0b273efff82719110624191107011911081a1911094b0b24220c272419110a2719110b2f19110c2319110d251a2401950c272419110e27180830ff7724014efff724ff89191911041cfff816191106101911073e191108200c24201911092419110a2019110b1519110c2319110d101a2301650c242319110e2418083bff77230155fff723191102210c2313191103231911041cfff8090c231619110623191107411911ffc6450b234019110b2319110c1219110d250c122019110e12180841ff7712015efff712191102370c1213191103120b123a19110412fff82bff88131911082d1911094419110a3519110b1bffc7ff950eff2f45ff77120164fff712ff891319110443fff8341911062919110734191108391911094b19110a4719110b01ffc7440c1b0e19110e1b18082211ffec40190e02210c1119190e0311190e0417190e0545190e060b190e071d190e0826190e093b190e0a3f190e0b4b190e0c17190e0d45190e0eff2f100effec0c190e02210c111d190e0311190e040d190e05380c0d2b190e060d190e07450b0d2e190e080d190e094b190e0a3a190e0b2d190e0c43190e0d250b0d8f190e0e0d1808440e050dffd834ffec0c190e023c190e031d190e042f190e0501190e06010c0c1d190e070c0c0c1d190e080c190e09090c0c1a190e0a0c1808090e0a0c0a1a0e016bff322bff5a10ffbc010c0e15ff401dff9213ff2713ff1f72ff322bffc80affbc300c0e20ff401aff9230ff270bff1f7cff1d31190c0313ff5a0bffbc1f190c07390c0e1aff222b0c0e2bff271aff1f83ff322bff5a44ffbc01190c072d0c0e1dff921dff271dff1f88ff1d38190c033bffc830ffbc010c0e23ff400bff2209190c0a1d18082bff1f8eff1d38190c031d190c042f0c0e13190c050effbc1f0c0e34ff400bff220b0c0e0bff2725ff1f93ff320b190c042f0c0e1a190c050effbc46190c072d0c0e1dff222b0c0e13ff2730ff1f9aff321a190c043e190c0534ffbc190c0e20ff403bff921dff273bff1fa0ff322b190c043e190c0544ffbc340c0e1dff401dff921dff2741ff1fa7ff321dff5a10ffbc010c0e34ff401dff9213ff2745ff1fabff320bff5a3effbc0b0c0e34ff401dff22130c0e44ff2722ff1fb3ff323bffc810ffbc1a190c07250c0e1d190c080e0c0e1a190c090e0c0e30ff2710ff1fbaff3222190c0446190c0534ffbc0a190c07390c0e30190c080e0c0e3b190c090e0c0e13ff27440c050cffd8250a0e0a1a1101c3ffc910ffed09ffb81101c8ffc93d190e0318180813ffb81101ccffc90fffed0bffb80f01d1ffca0a190e034618081affb80f01d8ffca44190e034418081dffb80f01deffca30ffed2b0e050effd8410a0f0a1a1101e7ff2e22ffcb25fff916190f0616190f0713180809ff4101efff2e3b190f032b190f043bfff91619ffb013ff4101f6ff2e10190f030a190f041dfff9161a110154ffdc0bff4101feff2e22190f032b190f0410fff92b19ffb01aff410206ff2e10ffcb100c111ffff9111a1101aeff5bff2f1dff41020fffee22190f04250c1134fff9110b1178ffdc2bff41021aff2e45ffcb44fff93d19ffb025ff410224ffee3b190f0413fff90b0c1116ffdc30ff410229ffee340c110b190f04110b1147fff9110b1196ffdc3b0f050fffd81d0a150a1a180231ffdd1dff7d01ff73ff7e14ff7f4bff800a180809ff2618023affdd1aff7d01ff73ff7e14ff7f4bff800a180813ff26180248ffdd1dff7d2fff73ff7e42ff7f090c1801ff801818080bff2618024fffdd1aff7d2fff73ff7e42ff7f090c1801ff801818081a150501ffd8340a150a1a18025bff7b181a1b0261ff7c1b1a200269ff7d201a210271ff9a21ff9b201a210279ff7e21ff7f211a240281ff80241a240289ff9c241a240291ff9d241a260299ff9e261a2602a1ff9f261a2602a9ffa0261a2602b1ffde09ff262702b9ff7b271a2802bfff7c28ff7d21ff9a26ff9b211a2102c7ff7e211a2802cfff7f281a2902d7ff80291a2902dfff9c291a2902e7ff9d291a3102efff9e311a3102f7ff9f311a3102ff00ffa031ffa128180813ff26280307ff7b281a28030eff7c281a310316ff7d311a32031eff9a32ff9b311a310326ff7e311a32032eff7f321a320336ff80321a32033eff9c321a330346ff9d331a35034eff9eff4556ff9fff455effa0ff4566ffa13518080bff2635036eff7b35ff7c1b1a350373ff7d351a36037bff9a36ff9b35ff7e311a350383ff7fff458bff80ff4593ff9cff459bff9dff45a3ff9eff45abff9f35ffa029ffa12918081aff262903b3ff7b291a2903b9ff7c291a3503c1ff7d351a3603c9ff9a36ff9bff45d1ff7eff45d9ff7fff45e1ff80ff45e9ff9cff45f1ff9dff45f9ff9e351a350401ff9f351a350409ffa035ffa12118081dff26210411ff7b21ff7c291a21041eff7d211a350426ff9a35ff9bff832eff7eff8336ff7fff833eff80ff8346ff9cff834eff9dff8356ff9eff835eff9fff8366ffa0ff836effa12118082bff26210476ff7b21ff7c1bff7d311a1b047dff9a1bff9b31ff7e201a1b0485ff7f1bff8020ff9c32ff9d331a1b048dff9effbb95ff9fffbb9dffa0ffbba5ffa11b180825ff261b04adff7b1bff7c291a1b04b4ff7d1b1a2004bcff9a20ff9bffbbc4ff7e1b1a2004ccff7f20ff80ffbbd4ff9c1b1a2004dcff9d20ff9e1bff9f241a1b04e4ffa0ffbbecffa11b180830ff261b04f4ff7bffbbf9ff7c1b1a200501ff7d201a310509ff9a31ff9b201a200511ff7e201a310519ff7fff4621ff80ff4629ff9cff4631ff9dff4639ff9eff4641ff9fff4649ffa0ff4651ffa13118083bff26310559ff7b31ff7cff7a5eff7d1b1a310566ff9a31ff9bff7a6eff7eff7a76ff7fff7a7eff80ff7a86ff9cff7a8eff9dff7a96ff9eff7a9eff9fff7aa6ffa0ff7aaeffa11b180841ff261b05b6ff7b1b1a3105bcff7cff46c4ff7d311a3305ccff9a33ff9bff46d4ff7eff46dcff7fff46e4ff80ff46ecff9cff46f4ff9dff46fcff9e31ff9f241a310604ffa031ffde45ff2626060cff7b26ff7c281a260613ff7d261a31061bff9a31ff9bff4723ff7eff472bff7fff4733ff80ff473bff9cff4743ff9dff474bff9eff4753ff9fff475bffa0ff4763ffde22ff2626066bff7b26ff7c291a260670ff7d261a290678ff9a29ff9b26ff7e321a260680ff7fff4788ff80ff4790ff9cff4798ff9dff47a0ff9e26ff9f241a2606a8ffa0ff47b0ffde10ff262606b8ff7b26ff7c281a2806bfff7d281a2906c7ff9a29ff9b28ff7e201a2006cfff7f201a2006d7ff80201a2006dfff9c20ff9d241a2006e7ff9e201a2006efff9f20ffa024ffa124180844150515ffd8250a200a1a2806f7192001281a2806fc19200228180809200a200a1a280704192001281a28070b19200228180813200a200a1920011b1a1b07131920021b18080b200a1b0a1a20071b191b01201a200722191b022018081a1b0a1b0a191b0118191b022418081d1b0a1b0a191b01271a20072a191b022018082b1b051bffd8220a200a192001181920021c091c1dffcc1d181c0b2b181c1a251920031c091c45ffcc13181c0b0b181c1a1a181c1d1d181c2b2b181c2525181c3030181c3b3b181c41411920041c091c13181c09091920051c091c1dffcc13181c0b0b181c1a1a1920061c1920070919200809192009ff2f09200a1c0affe627ffe72d09200bffcd25ffe82009201dffcd4518200b2218201a10ffe92009201318200913ffea2009201affcd131820ff9320ff8a13ff841a200732ffe620ffe714092830182809131828130b18280b1a18281a1d18281d2b18282b2518282530ffe828092841182809131828130b18280b1a18281a1d18281d2b18282b25182825301828303b18283b41ffe92809281a1828090b1828131a18280b1dffea2809281a18280909182813131828ff9328ff300b28ff00ffef0bff841a290738ffe629ffe72f09311dffce1d18310b2b18311a25ffe831093125ffce1318310b1d18311a2518311d3018312b3bffe931ffb22bffea31ffb21a191c0631ff8a1aff84ffe621ffe71fffb225ffe83109310b1831091318311310ffe931ffb225ffea3109311affce131831ff9331ff8a1dff841a310742ffe631ffe74509320bff8b25ffe83209320bff8b3bffe932ffb330ffea3209321aff8b131832ff9332ff8a2bff84ffe612ffe72bffb309ffe832ffb309ffe932ffb322ffea3209321aff8b131832ff9332191c070a191c0822191c09ff2f25ff841a32074affe632ffe72bffb41a1833133bffe8ff5c25ffe9ff5c10ffea33ffb40918331313191c0633191c0719191c0810ffef30ff84ffe626ffe72bffb41a1833133bffe8ff5c25ffe9ff5c44ffea3309331a18330909183313131833ff9333191c071f191c0844ffef3bff841a280752ffe628ffe710093330183309131833130b18330b1a18331a1d18331d2b18332b251833253bffe833093341183309131833130b18330b1a18331a1d18331d2b18332b25183325301833303b18333b41ffe933ffb43b18331341ffeaff5c1d191c0633ff300b337f191c0933180841ff841a350758ffe635ffe72b09363b183609131836130b18360b1a18361a1d18361d2b18362b25183625301836303bffe8360936251836090b1836131a18360b1d18361a2b18361d2518362b41ffe93609361318360945ffea360936131836092b191c0636ff30191c09331808451c051cffd8220a330a193301181933021319330313193304091933050919330609193307ff2f09330a180a19180127ff8c13ffb913ff5d20ff8c09ffb90bff5d29ff8c09ffb91aff5d21ff500513191806131918071318081dff5d31ff8c13ffb92bff5d1219180209ff3a1918050919180609ffb92518ffb532ff8d13fff03012ffb526ff8d13fff03b12ffb528ff8d09fff04112ffb535ff8d0919120413ff8e45120512080a080a190801131908020b1908031d1908043b190805190518080a080a190801131908020b1908031d1908043b190805191908062a190807230b1980190808190520ffd841180809091721180118081321ffcf02fff10b26ffcf03fff11a261721180218081d211721180318082b2117211804180825211721180518083021ffcf04fff13b260521ffd84418080909ffc00118081323ffc00218080b23ffc00317262002ff5e1a27ffc00317262004ff5e1d27ffc00518082b23ffc00517262006ff5e2527ffc00618083023ffc00617262003ff5e3b27ffc00617262004ff5e4127ffc00718084523ffc00818082223ffc00717262008ff5e102705230807081e07260d07270c07280e07290f072a0108310908321308330b08351a08361d08372b083925083a30083d3b083b41083e45083f2208221008104408403408340a22421c310216311c42161c124217123103174231041743310517463106174731071748310817493109174c1c02174d1c04174e1c05174f1c0617501c07141c3e19143e3f191b3f3e4e143e2244142240190619121e403219161912400612421e323312161242320632431e333532163243330633461e351033163346350635461340350b2435400b131e4010351c10401316354610131035091b40103e2410400933134035091b42403e243e4235332033081a1e08363324334747082008261a1e26370824084848261e2639271e273a281e283d291e293b2a162a21191619231213124909152134491b231221171218011121ffdf021134ffdf031135ffdf041136ffdf0511182a1217122001112aff78021137ff78031139ff7804113aff7805113bff7806113dff78071140ff78081120191205122305192305234c16420f28170f42051728420217434203174442041646153216151b1016101b3e171b150217321002243e22321b2447221b32171b4602173246061748460717494608174c4603174e4605175146091752460a1753460b1754460c1755460d1756460e05571b241b3f483224583f32481a32075f1a3f07671a48076f0d594f1b5a365924595a1b4c1b5a364f244f5a1b4c1b4c3650245a4c584f0d4c501b5b2a4c244c5b1b4e1b5b2a50245c5b1b4e1b5b2a50245d5b584e244e501b58245b401b492449501b5b245b204e49245e50585b1a5007771a5b0781245f4d5b2424244d505b1a4d07891a500793165b1e33161e0d0816080c26160c0e27160d012917013101170e460117265b0117271e0117290801173110011733150124462231331731150117151001241022311517150c011722420117310d010433021a02079b26330201ff54a1fffa0eff54a9fffa26ff54aefffa27ff54b2fffa29ff54b7fffa46ff54c5fffa10ff54d2fffa15ff54d9fffa22ff54dffffa3103040401050b01090b020b17035b0217045b0317055b04170e5b0517105b0617155b0717225b0817265b0917275b0a17295b0b17315b0c17335b0d17421e0217461e03175b1e0417601e0517611e0617621e0717631e0817641e0917651e0a17661e0b17671e0c17681e0d17691e0e171e0802176a0803176b0804176c0805176d0806176e0807176f0808177008091771080a17080c0217720c03170c0d0217730d0317740d0417750d0517760d0617770d0717780d080b0d00057903057a0405040505050e057b100b7c00057d1510150d7a107e7904107f7a051080047b1081057c10827b7d20837e791f84148320837a0d1d8584830583222022827b1f84272220227c051d278422202204791f8485221d2284141c84152220157a0d1f2285151d15221420227e1520157b041f7e83151d157e141c7e7f152015057a1f8583151d1585142085801520157b041f8683151d15861420867f152015057a1f7f83151d157f141c7f801520157d7b1f8027151d1580141c80811520157c051f8127151d158114202782151f157a1d1d81154505157910827a841083042223227e862610847a222322857f26102604222322867e14107e052223227f8514107f7b221022058010807b271f2705291d29271405277d27850522297c3127867b80277d3127870d81827a422788791583044227427a82810d33278904831579331c334246204689ffb68a601f8b5b8a0c5b14218a615b090c5b8a1d8a5b141d5b8a141f8a8b5b1c5b608a238a3387ffb68b601f8c5b8b0c5b14218b615b090c5b8b1d8b5b141d5b8b141f8b8c5b1c5b608b238b4688ffb68c601f8d5b8c215b6109141d8c5b141d5b8c141f8c8d5b1c5b608c238c3342ffb68d601f8e5b8d215b6109141d8d5b141d5b8d141f8d8e5b1c5b608d238d46895b235b874266238e88896620661468238f87426620661468236888896610665b8f10908e6823916633671d3369141c6991332333904667ffe067601f9146670c461421676146090c46671d6746141d4667141f6791461c4660672367695b46ffe091601f9246910c461421916146090c46911d9146141d4691141f9192461c4660912391338e46ffe092601f93469221466109141d9246141d4692141f9293461c4660922392698f46ffe069601f93466921466109141d6146141d4661141f6193461c46606123603368461033878a1046888b10618a8c10698b8d10938c4210948d8920958b881f9662951d9596141c96339520338a871f9562331d3395142095463320338d8b1f4663331d3346141c46613320338c8a1f6163331d336114206169332033898d1f6364331d3363141c6393332033428c1f6964331d33691420699433103387961093889510948a9610968b9510958a4610978b6110988c4610468d6110618c6310998d69109a42631063896910695b67109b8e91109c6792109d9160109e928f109f606820a0918e1fa162a01da0a1141ca169a02069675b1fa062691d62a01420699b62206260911f9b65621d629b141c9b9c62206292671f9c65621d629c1420659d62206268601f9c64621d629c141c9c9e6220628f921f9d64621d629d1420649f6210625ba1109d8e69109e67a1109f91691069679b10a0916510a1929b109b60651065929c10a2606410a38f9c109c68640b64000ba4000ca56b0ba6000ba7000ca86c1fa964142364a86da905a86b0b6b000ba9000caa6c1f6ca41423a46daa6c056ca51daa640b1daba50b05ac641dada80b05ae6405afa81db0640b05b1a81db2a40b1db3a80b05b4a41db5a50b05b6a405b7a51db8a40b0bb9140bba001cbb38710c38012071bb0205bc0120bdbb0210beba3810bfbb7110c038bc10c171bd10c2bcba10c3bdbb20c471bb1fc5b9c41dc4c5141cc5bec420be38ba1fc4b9be1dbec41420c4bfbe20bebd711fbfb9be1dbebf141cbfc0be20bebc381fc0b9be1dbec01420c0c1be20bebbbd1fc1b9be1dbec1141cc1c2be20bebabc1fc2b9be1db9c21420bec3b910b9bac510c2bbc410c338c510c571c410c438bf10c671c010c7bcbf10bfbdc010c0bcc110c8bdbe10c9bac110c1bbbe27bebab9c3382f27cabbc2c5712f27cbbab9c3381727ccbbc2c571171ccdbe131fce011d1dcfce4520cecacf1fcf011d1d01cf451ccfbe011f0102251d0201452001ca020b02001cd0bb282128d0bb7d05d0431c432844214443bb7d104302d010d1284420d244281fd30fd21dd2d31420d343d22043d0021fd20f431d0fd2141c43d10f100f02d310d1284310d2d0d310d344431f430a741dd443450b430005d5760576771077d4d510d6437620d776431fd878d71dd7d8141cd877d72077d5d41fd778771d77d7142078d6771077d4d810d6437810d7d5d810d8767823783c453123d914163123da2c09311c2c854b23db3c453123dc852cdb1c2c861123db3c4531233c862cdb232c1609311cdb854b1cdd86301d30311420de13300b302a1fdfde301fde4bdf1ddfde141dde3114203113de1fde31301f3011de1d3130140b30000bde0405e0dc05e13c05e28505e38605e4bb05e57805e60305e71e05e86a05e91e05ea6a05eb6f05ec7005ed1e051e6a05eebb05ef750475060e07e801570e090e01590e0953014c0e0998011b0e09dd01580e0a22014e0e0a67015a0e0aac014f0e0af1015c0e0b36015d0e0b7c014d0e0bc2015e0e0c0801490e0c4e01510e0c9401470e0cda013e0e0d2001520e0d66015f0e0dac01240e0df201500e0e2f01550e0df2013f0e0df201480e0e7501530e0ebb01540e0f0101560e0df201320e0f470c06851c1b0645021bff5520068616ff94201b8545021bff5520068616ff941c06854b0206ffd9068611ff940c1b8520241b4b0224ffd906861102060e1268240618ffba12e51f06db1d1d1806451f062c0b1c1bdd060c06db1f24061d1d0624451f1d2c0b1c24dd1d0c1ddb29dbdd181b06241ddd0e132c240636ffba14150c06dc0206ff5502e10e12660c06dc0b186e1c1b0618021bffd9063c11ff940c1bdc201d1b4b021dffd91b3c11021b0e143802e0ff5502e10e1266201ddc18021dffd9063c11ff941c06dc4b0206ffd91b3c11021b0e145d240621ffba14721c0685df0c11062006112d0206ffd90686312011062f02110e14bb240635ffba15cb0c06851c1106da0211ff5502e30e15ee200685daff9402e2ff551f06da2b1c11860602110e15ee0c068502060e145d240634ffba15f01d06d90b02060e16260c061324111c061302110e17210f8788ff57339394968a8bff57959798468c8dff5761999a6342890e17690f5b8eff57629d9e9f6791ff5769a0a19b9260ff5765a2a39c8f680e18820f0d79ff57811582837a04ff5784267e7f057bff57228029277c7d0e17680c06290c11220c18052806271180187b0e17680c057e0c06840c117a28057f062611040e17680c04820c05810c060d280483051506790e19f1240437ff371a6e1c04bb2effc11a9b24043bff371abf02e40e1b2e1c04bb14ffc11b351c04bb14ffc1145d24043dff371b3b1c04bb25ffc11b691c04bb25ffc11ba9240440ff371bcd0f87880e17682004662f1c05900a1c06660a1c0d900a280405060d42890e1bef240420ff371c0d0b044820056a0402050e1c3c24043aff371c61ff8f1cd3ff8f126602e5ffd904bb17ffc112660c05780205ffd904bb17ffc1145d240439ff371cd8ff8f1cd3ff8f145d24042aff371d4e02e60e1d7b20046a16ffc11dbc20046a16ffc11dfc240419ff371e271c040e4b0c05040205ff552004102bffc11e5e240412ff371fba2004034bffc11ff5ffd020ac02e70e20ba02e80e20bdffd021170b03b41f0403141f036e041d0403141a03013a1d05040302050e212cff3b1768ff511768ff52b0036b0e1768ff3c1768ff4a33ff76ffd1a3ff3b00001d036d0b1d046d131d056d13286c03ab04a7050e00001d036d131d046d0b1c05a8de28ad03af0405ff53ffd1a3ff76ff4aa802e9ff5502ea0e225102eb0e228502ec0e228c1d03080b02030e22931d03720b02030e229a1c03a86f1c04a7ff90ffd9036b701c0464ff900e231e1c03a96f1c04a5ff90ffd903a4701c04a6ff900e238effd0246d02e70e20ba02e80e247a02edff55021e0e253e02ee0e25c02003bbbb200428bb25ba03ffc1263d200328bb2004d1bb2005d3bb200644bb2902030f04d205d0060e2696240223130902020e26d60c02741f03022b1d0203450202ff5502ef0e27150c021f02020e212cffe1d7d8d5760e27650c021f0b03391f040b031f0573041d0405141c05020402050e212c1f02d7411d0402451f02d5411d050245ffe104d805760e27b513020c0b240402ff3727fc0c021f1f0413031f0573041d0405141c05020402050e212cffe1d7d8d5760e27b513020c1a240402ff3727fc0c021f1f041a031f0373041d0403141c03020402030e212c1f02d74a1d0302141f02d54a1d040214ffe103d804760e28110fbabbff57b9c2c3c53871ff57c4c6c7bfbcbdff57c0c8c9c1babb0e28cd29becacdcecf01cbcc0e2931040107";
        

        assembly {
// START ---    

            
// ---- DEBUG ----

// Log calls
// 
// function log_byte(byteValue) {
//     let pOutput := m_get(/*/*VAR_ID_DEBUG*/0x150*/276)
// 
//     let len := mload(pOutput)
//     // store the increased length
//     mstore(pOutput, add(len, 1))
// 
//     // store the byte
//     mstore8(add(pOutput, add(len, 32)), byteValue)
// }
// function log_digit(v, tensValue) {
//     if not(slt(v, tensValue)) { log_byte(add(48/*0*/, smod(sdiv(v, tensValue), 10))) }
// }
// function log_varString(varId) {
//     log_string(m_get(varId))
// }
// function log_string(pEntry) {
//     let sEntry := mload(pEntry)
//     pEntry := add(pEntry,32)
// 
//     log_bytes(pEntry, sEntry)
// }
// function log_bytes(pEntry, sEntry) {
//     for { let k := 0 } slt(k, sEntry) { k := add(k, 1)}{
//         log_byte(mload8(add(pEntry, k)))
//     }
// }
// function log_literal(text) {
//     let pEntry := 0x00
//     mstore(pEntry, text)
//     for { let k := 0 } slt(k, 32) { k := add(k, 1)}{
//         let v := mload8(add(pEntry, k))
//         if iszero(v) { leave }
//         log_byte(v)
//     }
// }
// function log_int(v) {
//     log_digit(v, 100000000)
//     log_digit(v, 10000000)
//     log_digit(v, 1000000)
//     log_digit(v, 100000)
//     log_digit(v, 10000)
//     log_digit(v, 1000)
//     log_digit(v, 100)
//     log_digit(v, 10)
//     log_digit(v, 1)
// }
// function log_gas() {
//     log_literal('\n GAS=\x00')
//     log_int(gas())
// }
// function log_wasteRemainingGas() {
//     log_literal('\n# wasteRemainingGas\x00')
// 
//     for { let k := 0 } sgt(gas(), 100000) { k := add(k, 1)}{
//         if iszero(smod(k,25000)){
//             log_gas()
//             log_literal(' :: iterations: \x00')
//             log_int(k)
//         }
//     }
//     log_gas()
// }

// ---- DEBUG END ----

// ---- YUL CODE ----
function mload8(addr) -> result {
    // yul: result := shr(0xF8, mload(addr)) leave 
    result := shr(0xF8, mload(addr)) leave 

}
function m_varAddress(varId) -> result {
    // if !Number.isInteger(varId) { throw new Error(`m_varAddress: varId is not an integer: ${varId}`) }
    result := add(mload(/*PP_VARS*/0x80), mul(varId, 32)) leave 

}
function m_get(varId) -> result {
    result := mload(m_varAddress(varId)) leave 

}
function m_set(varId, value) {
    mstore(m_varAddress(varId), value)
}


// ---- Utility Methods ----

function op_getRvsValue(setVarId, varId) {
    // rvs[0] = most signficant byte, which is the left most (smallest index in memory)
    m_set(setVarId, mload8(add(m_get(/*VAR_ID_RVS*/0x120), m_get(varId))))
}

function op_getBreedIndex(setVarId, breedsVarId, rvsBreedVarId, oddsFieldIndex) {
    let pBreedsArray := m_get(breedsVarId)
    let len := mload(pBreedsArray)

    let rv := m_get(rvsBreedVarId)

    for { let i := 0 }  slt(i, len) {  i := add(i, 1) } {
        let pBreedArray := mload(add(pBreedsArray, mul(32, add(i, 1))))
        let pOdds := add(pBreedArray, mul(32, add(oddsFieldIndex, 1)))
        let odds := mload(pOdds)
        rv := sub(rv, odds)
        if slt(rv, 0) {
            m_set(setVarId, i)
            leave
        }
    }
    m_set(setVarId, 0)
}

// Commands
function op_command_writeAttributeValue(setVarId, keyVarId, valueVarId, betweenKeyValueTemplateVarId, afterAttributeTemplateVarId) {
    if iszero(m_get(/*VAR_ID_JSON_ENABLED*/0x350)) { leave }

    write_dataPackString(m_get(keyVarId))
    write_dataPackString(m_get(betweenKeyValueTemplateVarId))
    write_dataPackString(m_get(valueVarId))
    write_dataPackString(m_get(afterAttributeTemplateVarId))
}
function op_command_writeTemplate(templateVarId) {
    if iszero(m_get(/*VAR_ID_JSON_ENABLED*/0x350)) { leave }

    write_dataPackString(m_get(templateVarId))
}

// Arrays
function op_mem_create(setVarId, countVarId) {
    let count := m_get(countVarId)
    let pMem := allocate(mul(add(count, 1), 32))
    // mem: [memLength], [0:count,...]
    let pArray := add(pMem, 32)
    mstore(pArray, count)

    m_set(setVarId, pArray)
}
function op_mem_setItem(arrayVarId, itemIndex, valueVarId) {
    let pArray := m_get(arrayVarId)
    let pItem := add(pArray, mul(32, add(itemIndex, 1)))
    let v := m_get(valueVarId)
    mstore(pItem, v)
}
function op_mem_getItem(setVarId, arrayVarId, itemIndex) {
    let pArray := m_get(arrayVarId)
    let pItem := add(pArray, mul(32, add(itemIndex, 1)))
    m_set(setVarId, mload(pItem))
}
function op_mem_getLength(setVarId, arrayVarId) {
    let pArray := m_get(arrayVarId)
    // array[0]: length
    m_set(setVarId, mload(pArray))
}

// Output
function write_byte_inner(byteValue) {
    let pOutput := m_get(/*VAR_ID_OUTPUT*/0x140)

    let len := mload(pOutput)

    // store the byte
    mstore8(add(add(pOutput, 32), len), byteValue)

    // store the increased length
    mstore(pOutput, add(len, 1))
}


function enableBase64() {
    let pOutputQueue := allocate(1)
    mstore(/*PP_OUTPUT_QUEUE*/0x00, pOutputQueue)
    // Reset length to 0
    mstore(pOutputQueue, 0)
    // Clean new memory
    mstore(add(pOutputQueue, 32), 0)
}
function disableBase64() {
    write_flush()

    // NULL if not enabled
    mstore(/*PP_OUTPUT_QUEUE*/0x00, 0)
}

function write_flush() {
    let pOutputQueue := mload(/*PP_OUTPUT_QUEUE*/0x00)
    if pOutputQueue {

        let pOutput := m_get(/*VAR_ID_OUTPUT*/0x140)
        let len := mload(pOutputQueue)
        write_base64Queue(pOutputQueue)

        switch len 
            case 0 {
                // Backup 4 bytes (entire base64 write)
                mstore(pOutput, sub(mload(pOutput), 4))
            }
            case 1 {
                // Backup and write padding bytes
                mstore(pOutput, sub(mload(pOutput), 2))
                write_byte_inner(0x3D/*=*/)
                write_byte_inner(0x3D/*=*/)
                leave
            }
            case 2 {
                // Backup and write padding bytes
                mstore(pOutput, sub(mload(pOutput), 1))
                write_byte_inner(0x3D/*=*/)
                leave
            }
    }
}

function getBase64Symbol(value) -> result {
    value := and(value, 0x3F)
    if slt(value, 26) {
        result := add(value, 65/*A=65-0*/) leave 

    }
    if slt(value, 52) {
        result := add(value, 71/*a=97-26*/) leave 

    }
    if slt(value, 62) {
        result := sub(value, 4/*0=48-52*/) leave 

    }
    if eq(value, 62) {
        result := 43/*+*/ leave 

    }
    if eq(value, 63) {
        result := 47/* / */ leave 

    }
}

function write_base64Queue(pOutputQueue) {

    let bits := mload(add(pOutputQueue, 32))

    // Reset queue
    mstore(pOutputQueue, 0)
    mstore(add(pOutputQueue, 32), 0)

    // console.log('write_byte - base64 queue full', { bits })

    // write value at output
    let pOutput := m_get(/*VAR_ID_OUTPUT*/0x140)
    let outputLength := mload(pOutput)

    // // ....  00000000 11111111  11111111 11111111
    // // ....  00000000 xxxxxxxx  xxxxxxxx xx111111 => [35]
    // mstore8(add(pOutput, add(outputLength, 35/*32+[0,1,2,3]*/)), and(bits, 0x3F))
    // // ....  00000000 00000011  11111111 11111111
    // bits := shr(6, bits)
    // // ....  00000000 000000xx  xxxxxxxx xx111111 => [34]
    // mstore8(add(pOutput, add(outputLength, 34/*32+[0,1,2,3]*/)), and(bits, 0x3F))
    // // ....  00000000 00000000  00001111 11111111
    // bits := shr(6, bits)
    // // ....  00000000 00000000  0000xxxx xx111111 => [33]
    // mstore8(add(pOutput, add(outputLength, 33/*32+[0,1,2,3]*/)), and(bits, 0x3F))
    // // ....  00000000 00000000  00000000 00111111
    // bits := shr(6, bits)
    // // ....  00000000 00000000  00000000 xx111111 => [32]
    // mstore8(add(pOutput, add(outputLength, 32/*32+[0,1,2,3]*/)), and(bits, 0x3F))

    let pRightmost := add(add(pOutput, 35/*32+[3,2,1,0]*/), outputLength)
    for { let i := 0 }  slt(i, 4) {  i := add(i, 1) } {
        // ....  00000000 xxxxxxxx  xxxxxxxx xx111111 => 32+[3,2,1,0]
        mstore8(sub(pRightmost, i), getBase64Symbol(bits))
        // ....  00000000 00000011  11111111 11111111
        bits := shr(6, bits)
    }

    mstore(pOutput, add(outputLength, 4))
}

function write_byte(byteValue) {
    let pOutputQueue := mload(/*PP_OUTPUT_QUEUE*/0x00)
    if pOutputQueue {
        let queueLength := mload(pOutputQueue)

        // Store in the rightmost location of the 32 slot
        //          [61]     [62]      [63]     |
        // ........ AAAAAAAA BBBBBBBB  CCCCCCCC |
        // ........ aaaaaa aabbbb bbbbcc cccccc |
        mstore8(add(add(pOutputQueue, 61/*32+32-3*/), queueLength), byteValue)
        queueLength := add(queueLength, 1)
        mstore(pOutputQueue, queueLength)

        // 3*bytes is full -> write 4*base64
        if eq(queueLength, 3) {
            queueLength := 0
            write_base64Queue(pOutputQueue)
        }

        leave
    }

    write_byte_inner(byteValue)
}

function write_literal(pNullTerminatedString){
    for {} true { pNullTerminatedString := add(pNullTerminatedString, 1)}{
        let x := mload8(pNullTerminatedString)
        if iszero(x) { leave }
        write_byte(x)
    }
}
function write_dataPackString(v) {
    let pEntry := add(m_get(/*VAR_ID_DATA_PACK_STRINGS*/0x131), v)
    write_literal(pEntry)
}

function write_digit(v, tensValue) {
    if iszero(slt(v, tensValue)) { write_byte(add(48/*0*/, smod(sdiv(v, tensValue), 10))) }
}
function write_int(valueVarId) {
    let v := m_get(valueVarId)

    // if !Number.isFinite(v) {
    //     console.error(`intToString: not a number`, { v })
    //     throw new Error(`intToString: not a number ${v}`)
    // }
    // if !Number.isInteger(v) {
    //     console.error(`intToString: not an integer`, { v })
    //     throw new Error(`intToString: not an integer ${v}`)
    // }

    if eq(v, 0) {
        write_byte(48/*0*/)
        leave
    }

    if slt(v, 0) {
        write_byte(45/*-*/)
        v := sub(0, v)
    }

    write_digit(v, 100000)
    write_digit(v, 10000)
    write_digit(v, 1000)
    write_digit(v, 100)
    write_digit(v, 10)
    write_digit(v, 1)
}

function write_drawInstruction(aByte, bVarId, cByte, dVarId) {
    write_byte(aByte)
    write_int(bVarId)
    write_byte(cByte)
    write_int(dVarId)
}


// ---- Decompress Data Pack ----

function appendUsingTable(pTarget, isControlByte, b) {
    let sTarget := mload(pTarget)
    pTarget := add(pTarget, 32)

    if isControlByte {
        let pSource := m_get(b)
        let sSource := mload(pSource)
        pSource := add(pSource, 32)


        for { let iSource := 0 }  slt(iSource, sSource) {  } {
            let piTarget := add(pTarget, sTarget)
            let piSource := add(pSource, iSource)
            mstore(piTarget,mload(piSource))

            let sCopied := sub(sSource, iSource)
            if sgt(sCopied, 32) {
                sCopied := 32
            }

            sTarget := add(sTarget, sCopied)
            iSource := add(iSource, sCopied)
        }
    }
    if iszero(isControlByte) {
        mstore8(add(pTarget, sTarget), b)
        sTarget := add(sTarget, 1)
    }

    mstore(sub(pTarget, 32), sTarget)
}

function run_decompressDataPack(_pDataPackCompressed) {
    // Skip length
    _pDataPackCompressed := add(_pDataPackCompressed, 32)

    let pDataPack := allocate(/*LENGTH_DATA_PACK_ALL*/22985)
    // Reset length to 0
    mstore(pDataPack, 0)

    // Assign pDataPack vars
    m_set(/*VAR_ID_DATA_PACK_ALL*/0x130, pDataPack)
    m_set(/*VAR_ID_DATA_PACK_STRINGS*/0x131, add(add(32, pDataPack), /*INDEX_DATA_PACK_STRINGS*/0))
    m_set(/*VAR_ID_DATA_PACK_OPS*/0x132, add(add(32, pDataPack), /*INDEX_DATA_PACK_OPS*/10721))


    // Decompress
    /**
     * mode := 0: Loading data
     * mode := 1: Loading table
     * mode >= 2: Loading table entry
     */
    let mode := 1
    let isControlByte := 0

    // Record ff00 entry
    let iCurrentTableEntry := 1
    let pEntry := allocate(1)
    mstore8(add(pEntry, 32), 0xff)
    m_set(0, pEntry)

    for { let i := 0 }  slt(i, /*LENGTH_DATA_PACK_COMPRESSED*/15403) {  i := add(i, 1) } {
        let b := mload8(add(_pDataPackCompressed, i))
        if and(eq(b, 0xFF), iszero(isControlByte)) {
            isControlByte := 1
            mode := sub(mode, 1)
            continue
        }

        if sgt(mode, 1) {
            // Continue loading table entry

            appendUsingTable(pEntry, isControlByte, b)
            isControlByte := 0

            // Use up mode item
            mode := sub(mode, 1)
            if eq(mode, 1) {
                // Done
                moveFreePointerToEnd(pEntry)

                // Store pEntry in var
                m_set(iCurrentTableEntry, pEntry)

                // Next table entry
                iCurrentTableEntry := add(iCurrentTableEntry, 1)
            }
            continue
        }
        if sgt(mode, 0) {

            if iszero(b) {
                // Begin content
                mode := 0
                // Skip content length (4 bytes)
                i := add(i, 4)
                continue
            }

            // Start loading table entry by recording the length to load
            mode := add(mode, b)
            // Prepare next memory
            pEntry := allocate(0)

            continue
        }

        appendUsingTable(pDataPack, isControlByte, b)
        isControlByte := 0
    }

    // Move free memory pointer past data pack + size
    moveFreePointerToEnd(pDataPack)
}

// ---- Run Data Pack Ops ----

function run_DataPackOps(pDataPackOps) {
    for { let iByte := 0 }  slt(iByte, /*LENGTH_DATA_PACK_OPS*/12264) {  } {
        let countBytesUsed := op_byteCall(pDataPackOps, iByte)
        iByte := add(iByte, countBytesUsed)
    }
}


    

function op_byteCall(pDataPackOps, iByteStart) -> result {

    let opId := mload8(add(pDataPackOps, iByteStart))
    
    
    
    let argByte_1 := mload8(add(pDataPackOps, add(iByteStart, 1)))
    
    switch opId 
        case 1 { /*op_write_string*/write_dataPackString(m_get(argByte_1)) result := 2  leave }

        case 2 { /*op_write_var*/write_int(argByte_1) result := 2  leave }

    let argByte_2 := mload8(add(pDataPackOps, add(iByteStart, 2)))
    
    switch opId 
        case 3 { /*op_ceil_100*/m_set(argByte_1, sdiv(add(m_get(argByte_2), 99), 100)) result := 3  leave }

        case 4 { /*op_command_writeTemplate*/op_command_writeTemplate(argByte_2) result := 3  leave }

        case 5 { /*op_copy*/m_set(argByte_1, m_get(argByte_2)) result := 3  leave }

        case 6 { /*op_getArrayLength*/op_mem_getLength(argByte_1, argByte_2) result := 3  leave }

        case 7 { /*op_getLength*/op_mem_getLength(argByte_1, argByte_2) result := 3  leave }

        case 8 { op_getRvsValue(argByte_1,argByte_2) result := 3  leave }

        case 9 { /*op_loadArray_create*/op_mem_create(argByte_1, argByte_2) result := 3  leave }

        case 10 { /*op_loadObject_create*/op_mem_create(argByte_1, argByte_2) result := 3  leave }

        case 11 { /*op_loadUint8*/m_set(argByte_1, argByte_2) result := 3  leave }

        case 12 { /*op_unaryNegative*/m_set(argByte_1, sub(0, m_get(argByte_2))) result := 3  leave }

        case 13 { /*op_unaryNot*/m_set(argByte_1, iszero(m_get(argByte_2))) result := 3  leave }

        case 14 { /*op_write_text*/write_dataPackString(add(mul(argByte_1, 256), argByte_2)) result := 3  leave }

        case 15 { /*op_write_vertex*/
            write_drawInstruction(
            77/*M*/,
            argByte_1,
            44/*,*/,
            argByte_2)
             result := 3  leave }

    let argByte_3 := mload8(add(pDataPackOps, add(iByteStart, 3)))
    
    switch opId 
        case 16 { /*op_average*/m_set(argByte_1, sdiv(add(m_get(argByte_2), m_get(argByte_3)), 2)) result := 4  leave }

        case 17 { /*op_bitwiseAnd*/m_set(argByte_1, and(m_get(argByte_2), m_get(argByte_3))) result := 4  leave }

        case 18 { /*op_bitwiseOr*/m_set(argByte_1, or(m_get(argByte_2), m_get(argByte_3))) result := 4  leave }

        case 19 { /*op_comparisonGreater*/m_set(argByte_1, sgt(m_get(argByte_2), m_get(argByte_3))) result := 4  leave }

        case 20 { /*op_comparisonLess*/m_set(argByte_1, slt(m_get(argByte_2), m_get(argByte_3))) result := 4  leave }

        case 21 { /*op_comparisonLessEqual*/m_set(argByte_1, not(sgt(m_get(argByte_2), m_get(argByte_3)))) result := 4  leave }

        case 22 { /*op_getArrayItem*/op_mem_getItem(argByte_1, argByte_2, m_get(argByte_3)) result := 4  leave }

        case 23 { /*op_getObjectField*/op_mem_getItem(argByte_1, argByte_2, argByte_3) result := 4  leave }

        case 24 { /*op_loadArray_setItem*/op_mem_setItem(argByte_1, m_get(argByte_2), argByte_3) result := 4  leave }

        case 25 { /*op_loadObject_setItem*/op_mem_setItem(argByte_1, argByte_2, argByte_3) result := 4  leave }

        case 26 { /*op_loadUint16*/m_set(argByte_1, add(mul(argByte_2, 256), argByte_3)) result := 4  leave }

        case 27 { /*op_logicalAnd*/m_set(argByte_1, and(m_get(argByte_2), m_get(argByte_3))) result := 4  leave }

        case 28 { /*op_mathAdd*/m_set(argByte_1, add(m_get(argByte_2), m_get(argByte_3))) result := 4  leave }

        case 29 { /*op_mathDiv*/m_set(argByte_1, sdiv(m_get(argByte_2), m_get(argByte_3))) result := 4  leave }

        case 30 { /*op_mathMod*/m_set(argByte_1, smod(m_get(argByte_2), m_get(argByte_3))) result := 4  leave }

        case 31 { /*op_mathMul*/m_set(argByte_1, mul(m_get(argByte_2), m_get(argByte_3))) result := 4  leave }

        case 32 { /*op_mathSub*/m_set(argByte_1, sub(m_get(argByte_2), m_get(argByte_3))) result := 4  leave }

    let argByte_4 := mload8(add(pDataPackOps, add(iByteStart, 4)))
    
    switch opId 
        case 33 { /*op_constrain*/
            let x_ltMin := slt(m_get(argByte_2), m_get(argByte_3))
            let x_gtMax := sgt(m_get(argByte_2), m_get(argByte_4))
            if  x_ltMin  { m_set(argByte_1, m_get(argByte_3)) }
            if  x_gtMax  { m_set(argByte_1, m_get(argByte_4)) }
            if  not(or(x_ltMin, x_gtMax))  { m_set(argByte_1, m_get(argByte_2)) }
             result := 5  leave }

        case 34 { op_getBreedIndex(argByte_1,argByte_2,argByte_3,argByte_4) result := 5  leave }

        case 35 { /*op_lerp_100*/
            let x_a := mul(m_get(argByte_2), sub(100, m_get(argByte_4)))
            let x_b := mul(m_get(argByte_3), m_get(argByte_4))
            let x_result := sdiv(add(x_a, x_b), 100)
            m_set(argByte_1, x_result)
             result := 5  leave }

        case 36 { /*op_ternary*/
            let x_default := iszero(m_get(argByte_2))
            if  not(x_default)  { m_set(argByte_1, m_get(argByte_3)) }
            if  x_default  { m_set(argByte_1, m_get(argByte_4)) }
             result := 5  leave }

        case 37 { /*op_write_line*/
            write_drawInstruction(
            77/*M*/,
            argByte_1,
            44/*,*/,
            argByte_2)
            write_drawInstruction(
            76/*L*/,
            argByte_3,
            44/*,*/,
            argByte_4)
             result := 5  leave }

    let argByte_5 := mload8(add(pDataPackOps, add(iByteStart, 5)))
    
    switch opId 
        case 38 { /*op_command_writeAttributeValue*/op_command_writeAttributeValue(argByte_1, argByte_2, argByte_3, argByte_4, argByte_5) result := 6  leave }

    let argByte_6 := mload8(add(pDataPackOps, add(iByteStart, 6)))
    
    switch opId 
        case 39 { /*op_bezierPoint_100*/
            let x_t100 := m_get(argByte_6)
            let x_tInv := sub(100, x_t100)
            // let x_a :=          mul(mul(mul(m_get(argByte_2),        x_tInv), x_tInv), x_tInv)
            // let x_b :=      mul(mul(mul(mul(m_get(argByte_3), 3),    x_tInv), x_tInv), x_t100)
            // let x_c :=      mul(mul(mul(mul(m_get(argByte_4), 3),    x_tInv), x_t100), x_t100)
            // let x_d :=          mul(mul(mul(m_get(argByte_5),        x_t100), x_t100), x_t100)
            // let x_result := sdiv(add(add(add(x_a), x_b), x_c), x_d), 1000000)
            let x1 :=                          m_get(argByte_2)
            let x2 := add(
            mul(x1, x_tInv),
            mul(mul(m_get(argByte_3), 3),                      x_t100)
            )
            let x3 := add(
            mul(x2, x_tInv),
            mul(mul(mul(m_get(argByte_4), 3),             x_t100), x_t100)
            )
            let x4 := add(
            mul(x3, x_tInv),
            mul(mul(mul(m_get(argByte_5),        x_t100), x_t100), x_t100)
            )
            let x_result := sdiv(x4, 1000000)
            m_set(argByte_1, x_result)
             result := 7  leave }

        case 40 { /*op_write_bezierVertex*/
            write_drawInstruction(
            67/*C*/,
            argByte_1,
            44/*,*/,
            argByte_2)
            write_drawInstruction(
            32/* */,
            argByte_3,
            44/*,*/,
            argByte_4)
            write_drawInstruction(
            32/* */,
            argByte_5,
            44/*,*/,
            argByte_6)
             result := 7  leave }

    let argByte_7 := mload8(add(pDataPackOps, add(iByteStart, 7)))
    
    let argByte_8 := mload8(add(pDataPackOps, add(iByteStart, 8)))
    
    switch opId 
        case 41 { /*op_write_bezier*/
            write_drawInstruction(
            77/*M*/,
            argByte_1,
            44/*,*/,
            argByte_2)
            write_drawInstruction(
            67/*C*/,
            argByte_3,
            44/*,*/,
            argByte_4)
            write_drawInstruction(
            32/* */,
            argByte_5,
            44/*,*/,
            argByte_6)
            write_drawInstruction(
            32/* */,
            argByte_7,
            44/*,*/,
            argByte_8)
             result := 9  leave }

}
    
            


// ---- Memory Management ----

function allocate(length) -> result {
    let pStart := mload(/*PP_FREE_MEMORY*/0x40)

    // align with uint256
    pStart := mul(sdiv(add(pStart, 31), 32), 32)

    mstore(/*PP_FREE_MEMORY*/0x40, add(add(pStart, 32), length))
    mstore(pStart, length)
    result := pStart leave 

}
function moveFreePointerToEnd(pItem) {
    let length := mload(pItem)
    mstore(/*PP_FREE_MEMORY*/0x40, add(pItem, add(length, 32)))
}

// Align memory start
if slt(mload(/*PP_FREE_MEMORY*/0x40), /*FREE_MEMORY_MIN_START_POS*/0xFFFD0) {
    mstore(/*PP_FREE_MEMORY*/0x40, /*FREE_MEMORY_MIN_START_POS*/0xFFFD0)
}

// Store length at memory start
let pMemoryStart := allocate(0)

// Disable base64 by default
mstore(/*PP_OUTPUT_QUEUE*/0x00, 0)

mstore(/*PP_VARS*/0x80, add(allocate(0x4000), 32))

m_set(/*VAR_ID_RVS*/0x120, add(allocate(32), 32))
mstore(m_get(/*VAR_ID_RVS*/0x120), rvs)


// Store memory start
m_set(/*VAR_ID_MEM_START*/0x110, pMemoryStart)

// Store dataPack vars
m_set(/*VAR_ID_DATA_PACK_COMPRESSED*/0x121, pDataPackCompressed)

// Allocate max size for pOutput
m_set(/*VAR_ID_OUTPUT*/0x140, add(allocate(40000), 32))
// Reset length to 0
mstore(m_get(/*VAR_ID_OUTPUT*/0x140), 0)

// Allocate max size for debug log
m_set(/*VAR_ID_DEBUG*/0x150, add(allocate(40000), 32))
// Reset length to 0
mstore(m_get(/*VAR_ID_DEBUG*/0x150), 0)

// ---- RUN ----
if eq(smod(kind, 4), 1) {
    // write_literal('data:svg/xml;base64,\x00')
    enableBase64()
}
if eq(smod(kind, 4), 2) {
    m_set(/*VAR_ID_JSON_ENABLED*/0x350, 1)
}
if eq(smod(kind, 4), 3) {
    // Write base64 prefix
    let pText := allocate(0)
    mstore(pText, 'data:application/json;base64,\x00')
    write_literal(pText)

    enableBase64()
    m_set(/*VAR_ID_JSON_ENABLED*/0x350, 1)
}

run_decompressDataPack(m_get(/*VAR_ID_DATA_PACK_COMPRESSED*/0x121))
run_DataPackOps(m_get(/*VAR_ID_DATA_PACK_OPS*/0x132))
write_flush()
    

// Select output
switch kind
case 64 {
    output := m_get(/*VAR_ID_MEM_START*/0x110)
}
default {
    output := m_get(/*VAR_ID_OUTPUT*/0x140)
}

// Set free memory pointer to after output
mstore(0x40, add(output, add(32, mload(output))))

// --- END ---    
        }
        

        return output;
    }
}
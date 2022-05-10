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

    // Token Metadata:
    /**
    {
        "name": "{tokenName}",
        "image": "<svg width='100%' height='100%' viewBox='0 0 32 32' xmlns='http://www.w3.org/2000/svg' xmlns:svg='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'><image width='100%' height='100%' style='image-rendering:pixelated; image-rendering:crisp-edges' xlink:href='{tokenImage}'/></svg>", 
    }
     */
    string private constant _tokenJson_a = '{"name":"';
    string private constant _tokenJson_b = "\",\"image\":\"";
    string private constant _tokenJson_c = "\",\"animation_url\":\"";
    string private constant _tokenJson_d = "\"}";

    function getTokenName(uint256 tokenId) public pure returns (string memory) {
        return _symbol;
    }
    function getTokenImageSvg(uint256 tokenId) public pure returns (string memory) {
        return generateSvg(tokenId);
    }

    // https://docs.opensea.io/docs/metadata-standards
    function tokenURI(uint256 tokenId) public pure override(IERC721Metadata) returns (string memory) {
        string memory jsonBase64 = Base64.encode(bytes(tokenJson(tokenId)));
        return string(abi.encodePacked('data:application/json;base64,', jsonBase64));
    }
    function tokenJson(uint256 tokenId) public pure returns (string memory) {
        return string(abi.encodePacked(
            _tokenJson_a, 
            getTokenName(tokenId), 
            _tokenJson_b,
            getTokenImageSvg(tokenId),
            _tokenJson_c,
            tokenIframeBase64(tokenId),
            _tokenJson_d
        ));
    }
    function tokenImage(uint256 tokenId) public pure returns (string memory) {
        return getTokenImageSvg(tokenId);
    }
    function tokenIframeBase64(uint256 tokenId) public pure returns (string memory) {
        string memory jsonBase64 = Base64.encode(bytes(tokenIframe(tokenId)));
        return string(abi.encodePacked('data:text/html;base64,', jsonBase64));
    }
    function tokenIframe(uint256 tokenId) public pure returns (string memory) {
        return string(abi.encodePacked(
            '<!DOCTYPE html><html><head><title>',
            getTokenName(tokenId),
            '</title></head><body>',
            getTokenImageSvg(tokenId),
            '</body></html>'
        ));
    }

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

    function generateSvg(uint rvs) public pure returns (string memory) {
        return string(generateArt(rvs, 0));
    }

    /** kind: 0 -> svg
     * kind: 1 -> json
     * kind: 42 -> memory dump
     */
    function generateArt(uint rvs, uint kind) public pure returns (bytes memory) {
        bytes memory output;
        

        // DataPack 
        bytes memory pDataPackCompressed = hex"01ff08207374796c653d27086c696e656172477208ff02616469656e74073a75726c28237808207472616e73666f08ff0166696c6cff0404272f3e3c087472616e736c6174062069643d277806ff05726d3d27073b7374726f6b65083e3c73746f70ff0108ff0c73746f702d6308ff0d6f6c6f723a0008ff0eff072fff033e0820786c696e6b3a6808ff107265663d27230827ff0f3cff03ff09082f673e3c2f673e3c06ff0aff08652808ff07757365ff1178083d272d333030272008636c6970506174680666696c74657207273e3c7061746808206f706163697479087363616c65282d3108ff0b2d7769647468063d2736303027071807010e1807020820636c69702d706108ff1f74683d277572071807080e180709086c6c69707365ff06052720643d2707ff072f673e3c6707180e0112180e020618070a0e1702083e3c72656374207808ff27ff1679ff167708ff2869647468ff1d08ff2920686569676808272063793d27002705070907040a030317020729272063783d27070e090e04191201050a090a041908181607031816080306ff206c28237805ff1a3d270007ff0aff1b2c312907ff2b2072783d2707ff0b2d6c696e6506272072793d2706ff1e3618070308ff0166696c6c3a6e081815030c18150403081f04a42a0e04a50d0826b0b1b2b3a8a30d081f04a42a26b4b5b607ff2a74ff1dff06063a726f756e6403273e3c0527ff14302c0300236607ff396f6e65ff0b07293bff18ff0432071509150418150107ff3db704a50d20082720ff17556e697408ff47733d2775736508ff4872537061636508ff24ff33ff19ff0608ff366a6f696eff3f081815020cff3a181508266ba9aaaba6630d081b04a7dd26acadae086a0d20b1ff3c20b1061807070e0b0e041b191b040420192005030d11720470617468040d167626031807040318070503180706056174696f6e050c0302040d07ff494f6e55736507180e0612180e07072d082d0c172d030611211e20170203302c2d0827ff01636f6c6f7208ff602d696e74657208ff61706f6cff592d08ff62ff18733a735208ff634742ff40666508ff6447617573736908ff65616e426c757208ff6620737464446508ff677669ff593d27082720726573756c7408ff693d27626c757208ff6aff072fff183e08ff40616e696d617408272072657065617408ff6d436f756e743d08ff6e27696e64656608ff6f696e6974652708ff5bff1920643d2708726f74617465280008180b0503180b060308ff3b20b1ff4d20b108ff74ff4eaf04ff4f05130b160b1c04ff07ff1303180a0103180a0203180a0303180a0403180a0503180a0603180a0703180a08067363616c652806ff153336ff41042f192f03041e191e030416091604032b192b07ff153239ff412007302c352c2d3630072920ff1b2c31290718070c1118070d071807021c1807030707090704190e0107ff31181609ff2d07172c0303172c0c07ff4c050318150607180b020c180b0307ff73180b07ff2d071b04ba2502040d07021c020414020205ff4065ff2205ff21030b0e0505051816060502090d117403180a0903180a0a03180a0b03180a0c03180a0d03180a0e03180707036500230330002303673e3c030dff2d083d27687474703a2f08ffa22f7777772e7708ffa3332e6f72672f08ff6b3cff18ff093208ff6c654d6f74696f08ffa66e206475723d0873ff7020ff543d270827ff0635ff443529083429ff0bff04342908ffaaff4bff36636108ffab70ff3fff1c3a082c36302c352c363008ff04323329ff1c3a08ff43ffae302e382708ff893f18070eff2d080e0611180e07ff2d06757365ff117806082b0c172b0306082c0c172c0306082d05172d0306090b04180b01065e1f5e115f03052927ff323305ff5637ff5705181507ff2d050c0302090d042f192f0203180709036600230330303003302c300318070803180e0303161e1c072720786d6c6e7307ff15333127ff14071808010e180802071716030317160c07171c0303171c0c07172b0303172b0c07161d1501161e150702e6ff5302e70d07ff46b3ff75ff4604696e670004464646460429ff07670429ff406704ff07ff5403020802031807010318070a03ff531b0302070d05ff072fff1705ff17ff093305ff5629ff5705ff5c0c170205ff9c20170205240b160b15051f5d115f030527d33d76d5030023330300233503ff123103ff234d03180703031816010318160203181603031816040318160506090804190e0106ffc23f180e040618160922170206180b0403ff900611201d1e170204ff1c3a3104ff5f313004ff140029041c191c0603002365030023360318070b03180e050300236403ff2c0e0302040d08706c65617365640008646f776e77617264082076657273696f6e083d2731303025272008ffa432ffbf2f737608ff01ff18ff0432340863ff5f352c332c35000000335a726f756e64006f76616c006469616d6f6e6400737175617269736800666c75666679007363727566667900706c61696e0063686f6e6b657200736c69636b0072656374616e67756c6172007465656e7900636865656b79006c656d6f6e0073696c6b790063687562627900736b696e6e79007769646500626c6f636b79007570726967687400616c65727400706f696e74790063757276656400736c616e74656400666f6c64656400666c6f707079007369646577617973007065726b7900737068796e780066696572636500737175696e74ffcd73756c6c656e006d65656b00737465726e006d65616e0064726f6f70790063726f737300616c6d6f6e6400646f6500676c6172ffcd736c6565707900706c656164ffcd7468696e006269670068756765006e6f726d616c00736d616c6c007468696e6e657374006e65757472616c0070757273656400fff9706f7574ffcd64726f6f70ffcd646973fff9696d7061727469616c0064756c6c00736d696cffcdfffa00fffa53686f7274007570776172640075707761726453686f727400626c61636b00236238646566ffbe3161316231ff9e636664326465ff42616661666100233066306631ff9f3837346636ff9fffbfffbfff42303964396400233264316631360023613036613661fff264656465640077686974ff9e38623932653900233132313231320023303530353035ff423666366636ff423362346439ffdf3833383338ff4266633264340023383232363733ffdf63323532650067696e676572ffe06437626231ff4266616537ff9f656364646435ff426366636663fff23938363439ff423761343634ff4266656465ff9f3861343030ffbe6365356635ffbe3332323731ffbe346232393162fff3663366326100677261790023376538343961fff63264326462ffe03535343633fff36136653763ff4235633764ffbe336433643364ff42356232643400233730336535370062726f776eff4230663066ff9f383135643431fff66564316339ff4232646663ff9e343033303163fff36534653335fff664393739370023343932633138ff4230386538ff9e3735326634ff9f326632333233006272697469736820626c75ff9e3565363337330023636464306435fff661646365370023346435313661ffe03035353638fff6636137633100233236323432640023313331323163ffe0373537353700233139316131ffbe3137313631370063616c69636ffff237653264ff9e653238343363ff423339363936fff36231653632fff364343034ff9f32363236323600637265616d79fff23164306336fff233643663ff9e3265323532ff9f626661383962ffe066343533340023343333353264002337393539343400233239323932390070696e6bffe06534633961ff426662386565ff423164666566ff4266663066ff9e643337336265ff426262316561fff635366462ff9e3563326535320023613834643934ffdf6531383239fff33032393537ffdf3431623336006379616e00236238663466ffbe6365646364ffbe6562663866ffbe3664613463ff9f613065626638ffe03939626231ffdf3835353631fff3383931623100233234323233ffbe313832613335002331353165323300677265656effe036366138ffbe3763613236390023636564656436ffe03037313431ffdf37353834350023376139613661ffdf353537343400233166323332ff9f333433613331002332343265316600666c65736879ff423364386438ff423265396539ff426665626562fff26362366236ff4233636563ff9e6433383839370023623437393739ff423061386138ffe065343034ff9f613937353735ff4235663566350073616e64fff23463376234fff266653064370023633139643861fff637623861330023626138383832fff330336533ff9e376235363536ffdf6132373237fff3663538353800746f79676572ff423039343735fff665636164630023343932343164ffdf38323531ffbe643439316262ffdf3731353135002338303830383000626c75ff9e6436663966660079656c6c6f77ff4239653961ff9e636166616133006f72616e6765ff426639633636fff266303930320074616262790073686f727468616972007369616d6573650073616e6463617400616c69656e007a6f6d6269ff9e3530353035ff9f44423730393300234533384641420023ffce464630ff9fffce464600233031ffbf3038ff9f333333333333003c3f786d6cfffb3d27312e302720656e636f64696e673d275554462d3827207374616e64616c6f6e653d276e6f273f3e3c737667207769647468fffc686569676874fffc76696577426f783d27302030203330302033303027fffb3d27312e31ffc43a786c696e6bffa4313939392f786c696e6bffc4fffd67ffc43a737667fffd67ff40646566733e3cff03ff0931ff1232ff1233ff1234ff1235ff1236ff1237ff1238ff1239ffe130ffe131ffe132ffe133ffe134ffe135ffe136ffe137ffe138ffe13927ff0f3cff03ff0f3cff03ff093230ff123231ff123232ff12323327ff0f3cff18ff093234ff68302030ffa535ff68302e3520302e35ffa536ff68352035ffa537ff68332033ff6b3c2f64656673ff3e31ffcfff143135302e302c3135302e302920ff8031ffd0fffe29ffa7273137ffa84d322c35ffff2c332c3063ff5f352d332c352d332c305aff07ff17ff093238ff714d002c004c005affd73e3c67ff3232382927ff3e32ffcfff33ff19ff09323927ff43ff043529ffee34ff2300ff86323729ff86353429ff86383129ff8631303829ff4a3729ffe2005affd1ff063829ffe2005aff24ff33ff4067ff093330ff19ff093331ffa9ffe2006336302c31352c36302c32302c36302c323063302c352d36ffef2d36ffef7affc5202d342c20313829ffc5202d382c333629ffc52d31322c353429ff072fffa0ffb2333027ff34ff4a3429ffe2004800ff9334ff2e30272063793d27313635272072783d2700ff373530ff77ffa0ff54ff063131ff44362927ff32323829ffe22d39ff5f3563ffc02c34ff5f34302c39ff5f34306335ffc02c39302c34302c39302c343063ffc02c31302c35302c31302c3730632d32302cff5f37302c33ffef302c3330632d33302cff5f38ff5f33ffefff5f333063ff5f32302c31ff5f37302c31ff5f37307aff77ffa067ff0aff80002c3129ff40ffa0ffa0ffd832ff7100005335ffc02cffc05affd7ff3e3133ffb832ffcfff093333ffa7273331ffa84d302c3363ff5f332c322c332c322c3063ff5f332d322c332d322c305aff07ffd834ff71005affd7ff3e3134ffb83429ff77ffa067ff3427ff3e3132ffb83229ff153333ff772fffa067fffe29ff40ffd835ff71007affd73e3c67ff3233352927ff3e33ffcfff33ff9334ff2e30ff353630ff373630ff4affac36ffe2302c004c2d3132342c004c3132342c00ff9334ff2e3130ff353131ff373131ff0765ff2234ff2e2d3130ff353131ff373131ff4a3429ff23004c3135ff5f3135305aff24ff33ff9336ff2e2d3638ff353735ff37313030ff4affac3132ffe22d31362c004c31362c00ff19ff06ffac3132ffe2302c354c2d31362c00ff9339ff2e30ff353136ff373335ff0765ff223130ff2e2d3736ff353730ff37313030ff0765ff2239ff2e3736ff353730ff37313030ff243e3cff54ff3327ff093336ffa9ffe2006336ffc0ffad2c3563ff872c352c2d36302c357aff81313429ff812d313429ff8130ff88ff813134ff88ff812d3134ff88ffd1ff3327ff093337ffa9ffe22d32302c006330ffad2c352c363063352cff872c352c2d36307aff15333727ff1431352c3429ff15333727ff1433ffc029ff77ff13ffa067fff020ff0865282d002c2d0029ff40ffd838ff5bff19ff09333927fff020ff80312c312920ff7229ff23007aff6c65206174747269627574654e616d653d27642720747970653d27786d6cff70206475723d27347327206b657954696d65733d27303b302e343b302e353b302e363b31272076616c7565733d2720002000207a3b2000207a20ff072fff543e3c2fff17ff3e3136ffb838ffcfff323338ffd0ff1400ffd0ff093430ff933138ff2e00ff3500ff3700ffa7273230ffa84dffc0ffff2c332c3063ffef2d362c31302d362c305aff072f656c6c697073653e3cffa067fff0ff40636972636c6520723d27323527ff0aff80302e31352927ff063139ff443729ff24fff0ff40636972636c6520723d27313527ff0aff80302e31352927ff063139ff443729ff77ff132fffa0757365ff09343127ff1178333927ff017374726f6b652d77696474683a32ff0bff043137293b66696c6c3a7472616e73706172656e74ff24ff142d002920ff086528002927ff2a74ff1dff3427ff063135ffb838ffcfff3233382927ff34ff4067ff1400ff88ff40ffb23430ff77ffb2343127ff34ff7767ff14302c00ffd0ff14ffc0ffd0ff14ffc029ff19ff43ff04323029ffee2e35ff23006c302effbf312c302effbf315affd1ff09343227ff43ff04323029ffee2e35ff2300ff15343227ff34ff0767ff33ff4130ffd0ff09343327fff0ff19ffafff0aff72ffd1ffafff0aff72ffd1ffafff3327ff0aff72ff072fffa0ffb2343327ff34ff77ff1367ff14ffc029ff19ff06323129ff0bff04323129ff4bffeeff23005affd1ff09343427ff06323229ff0bff04323129ff4bffeeff2300ff15343427ff34ff772fffa0ffa07465787420783d2735252720793d27353025272066696c6c3d27234646ffbf302720746578746c656e6774683d27393025273e464f522054455354494e47204f4e4c59202d20636f6e74616374207269636b6c6f76652e6574683c2f746578743e3c2fffa02f7376673e000a01120802010a03000a040f090504180501030a06370b0706180502070a0749180503070a081d0b0908180504090a0956180505090a0a171805060a0a0b5b1805070b0a0c011805080c180509030a0d640b0e0d18050a0e0a0e2c18050b0e18050c061805ffa103050905040a0f061805010f0a10320b1110180502110a114e180503110b1108180504110a1150180505110a121c180506120a1358180507130a140318050814180509030b150d18050a150a152318050b150a163318050c161805ffa10c050a05020917040a180b181701180a19360b1a191817021a0a1a4f1817031a0a1b180b1c1b1817041c0a1c601817051c0a1c191817061c18170709181708180a1d3f1817091d0a1e4a0b1f1e18170a1f18170b0f0a1f2f18170c1f1817ffa105170917040a2013181701200a21340b2221181702220a224d181703220b231c181704230a235f181705231817061f181707090b240c18170824181709030b240d18170a240a242018170b2418170c211817ffa114170a1704092504182501120b2610182502260a2646182503260a271a0b2827182504281825050d1825061c0a285a182507280a283c0b292818250829182509230b290d18250a290a291418250b2918250c101825ffa117250a2505092a04182a01150b2b10182a022b182a03220b2b1c182a042b182a050b0a2b26182a062b182a071a0a2c27182a082c0a2d59182a092d0a2e0e182a0a2e0a2f30182a0b2f182a0c19182affa1252a092a040a302b182a01300b3106182a0231182a031a0a311b0b3231182a0432182a052d0a3225182a0632182a07130b330f182a0833182a09030a33240b3433182a0a34182a0b30182a0c21182affa10f2a0a2a070934040a3531183401350b361f18340236183403260b361b183404360a3663183405360a3715183406370a385c183407380b3927183408391834091d0b390d18340a3918340b350a393818340c391834ffa12a340a3408093a040a3b39183a013b0b3c16183a023c183a03070b3c25183a043c0a3c66183a053c183a06290a3d54183a073d0b3e28183a083e183a09270b3e0d183a0a3e183a0b320a3e3b183a0c3e0a3e0d183a0d3e1702343a0a3a09093f04183f011d0b4021183f0240183f03090b093e183f0409183f050b183f0606183f07110a090c183f08090a0b4c183f090b0a4055183f0a400a4121183f0b41183f0c10183fffa13a3f0a3f0a0942040a434b184201430b442f18420244184203430a441e0b4544184204451842052d184206411842071a18420817184209030b1a3318420a1a18420b2f18420c391842ffa13f42091a040a2d51181a012d0b2f10181a022f181a03260b2f12181a042f181a05380a2f29181a062f181a073d0b3808181a0838181a09440b3819181a0a38181a0b320a3835181a0c38181affa1181a091a04181a01130b4235181a0242181a03110b420c181a04420a4261181a0542181a061b181a073d0b4214181a0842181a09030b420d181a0a42181a0b32181a0c39181a0d041702091a091a040a395e181a01390b3910181a0239181a03260b393f181a0439181a0536181a062f181a07400b3628181a0836181a090d181a0a2e181a0b33181a0c06181a0d3e17023e1a091a04181a010d0b3638181a0236181a031e0b360f181a0436181a0513181a062c0a1353181a0713181a0828181a09030b360d181a0a360a3628181a0b36181a0c06181a0d0417022e1a091a040a396b181a01390b390e181a0239181a03220b3920181a04390a3944181a05390a391f181a0639181a0713181a0828181a0930181a0a0b181a0b10181a0c10181affa1041a0a1310091a040a3972181a01390b4019181a02400a1962181a03190b4020181a04400a4057181a0540181a0636181a072d0b420c181a0842181a0903181a0a03181a0b440a422d181a0c42181affa1131a0a1a110942040a4577184201450b462118420246184203110b46271842044618420519184206381842074018420817184209030b190d18420a1918420b2418420c101842ffa11a420419ffd22e09400418400130184002310b420c18400342184004211840052a1840060318400720184008351840093e18400a3818400b1c18400c1118400d3f18400eff2d03400940040a427e18400142184002080b4237184003421840042618400529184006030b421718400742184008130a42161840094218400a1318400b4418400c1118400d3f18400eff2d0c400940040a4686184001461840020a0b462f184003460a2f451840042f1840051a184006030b2f141840072f1840081a1840092918400a0a18400b4418400c2218400d3e18400eff2d0540090a040a228cff7822ff79080b223aff7a22ff7b38ff7c03ff7d03ff7e3fff7f3fff973fff983fff9944ff9a0bff9b3fff9c231702140a090a04ff7843ff79440b2220ff7a22ff7b10ff7c3fff7d05ff7e3aff7f18ff9727ff9837ff9944ff9a07ff9b3fff9c451702170a0907040a0a93ffd30a180702120b0a17ffe30aff5610ff571aff5803ff9d1cffc108ffbd17ffd432fff444ffb025ff2c0a9affd30aff8a3fff562cff5703ff5803ff9d3fffc13fffbd3fffd43ffff42118070c2d18070d0f18070eff2d0fff2c0aa2ffd30aff8a3fff56260a0a3eff570aff581eff9d01ffc114ffbd440a0a220b1e0affd41efff42918070c1d18070d0f190a01950b1e0a18070e1e17022aff2c1ea9ffd31eff8a13ff5616ff5710ff5809ff9d20ffc11b0b1e1bffbd1effd41bfff40e18070c1d18070d09191d01650b1e1d18070e1e170234ff2c1db0ffd31d1807021c0b1d0cffe31dff5616ff57030b1d10ff581dff9d3affc13fffbd3fffd43f0a1d40fff41d18070c0b18070d0f0b0b1b18070e0b17023aff2c0bb9ffd30b180702310b0b0cffe30b0a0b3aff560bff5725ff5803ff9d0cffc127ffbd3effd438fff415ffb03fff2c0bbfffd30bff8a0cff563dff572eff5823ff9d2effc133ffbd44ffd441fff401ff893e0b154518070e151702ffbd0704ffd3391807021c0b1513ffe315ff5611ff573fff5805ff9d17ffc11fffbd34ffd435fff444ffb00907090704ffd3031807021c0b1517ffe315ff5606ff57320b0625ff5806ff9d3f0a062effc106ffbd44ffd430fff42718070c3d18070d0f0a068f18070e0617023e070406ffd22e090704ffd30318070236ffe317ffd901ff58010b1517ff9d150b1517ffc115ffbd030b1514ffd415170203ff2c15c6ffd31518070236ffe325ffb909ff58010b150eff9d150b0e17ff940cff260cfff7cdff3825ffd904ff582a0b0e1bff5014ff942aff2605fff7d7ff1e2bffe30cffb905ff581aff9d330b0e14ff21250b0e25ff2614fff7deff3825ffb93eff5801ff9d270b0e17ff9417ff2617fff7e3ff1e32ffe334ffd92aff58010b0e1dff5005ff2103ffd417170225fff7e9ff1e32ffe317ff56290b0e0cff570eff581a0b0e2eff5005ff21050b0e05ff260ffff7eeff3805ff56290b0e14ff570eff5842ff9d270b0e17ff21250b0e0cff262afff7f5ff3814ff5620ff572eff58130b0e1bff5034ff9417ff2634fff7fbff3825ff5620ff573eff582e0b0e17ff5017ff9417ff263aff8b02ff3817ffb909ff58010b0e2eff5017ff940cff263fff8b06ff3805ffb920ff58050b0e2eff5017ff210c0b0e3eff2618ff8b0eff3834ffd909ff5814ff9d0f0b0e17ffc10e0b0e14ffbd0e0b0e2aff2609ff8b15ff3818ff5642ff572eff5804ff9d330b0e2affc10e0b0e34ffbd0e0b0e0cff263e070407ffd20f090e041915011e180e0115180e0209ffc2441702030e090e0419150123180e0115180e0237ffc21217020cff2f27ff2508ffc2441702050effe92cffc6041808034217021408ffe933ffc63e1808033e17021708ffe939ffc62a18080344170225080408ffd23a090e0419120142ff2518ffea0ffff510180e0610180e070c170203ff2f4aff2534ffc225180e0434fff51018ffb10cff2f51ff2509ffc204180e0417fff51019120154ffda05ff2f59ff2518ffc225180e0409fff52518ffb114ff2f61ff2509ffea090b121afff512191201aeff5cff2d17ff2f6aff253effc218180e040f0b122efff5120a1278ffda25ff2f75ff253fffea3efff53718ffb10fff2f7fff253effc234180e040cfff5050b1210ffda2aff2f84ff253effc22e0b1205180e04120a1247fff5120a1296ffda340e040effd217091504191b018c1815011b18150217181503011815042a181505171815060d1815074418150804170203ff450a18150214181503011815042a181505171815060d181507441815080417020c15090a04191501a3ff7815ff7917ff7a29ff7b2aff7c17ff7d3cff7e030b1501ff7f15170205ff301501aaff7815ff7914ff7a29ff7b2aff7c17ff7d3cff7e030b1501ff7f151702140a0401ffd22e090a04191501b6ff7815191b01bcff791b191c01c4ff7a1c191e01ccff7b1eff7c1c191e01d4ff7d1eff7e1e191f01dcff7f1f191f01e4ff971f191f01ecff981f192001f4ff9920192001fcff9a2019200204ff9b201920020cffdb03ff30210214ff78211922021aff7922ff7a1eff7b20ff7c1e191e0222ff7d1e1922022aff7e2219230232ff7f231923023aff972319230242ff9823192b024aff99ff850252ff9aff85025aff9b2bff9c2217020cff30220262ff782219220269ff7922192b0271ff7a2b192c0279ff7b2cff7cff850281ff7d2b192c0289ff7e2c192c0291ff7f2c192c0299ff972c192d02a1ff982d192f02a9ff99ffbcb1ff9affbcb9ff9bffbcc1ff9c2f170205ff302f02c9ff782fff791b192f02ceff7a2f193002d6ff7b30ff7c2fff7d2b192f02deff7effbce6ff7fffbceeff97ffbcf6ff98ffbcfeff99ff8206ff9a2fff9b23ff9c23170214ff3023030eff782319230314ff7923192f031cff7a2f19300324ff7b30ff7cff822cff7dff8234ff7eff823cff7fff8244ff97ff824cff98ff8254ff99ff825cff9aff8264ff9b2fff9c1e170217ff301e036cff781eff7923191e0379ff7a1e192f0381ff7b2fff7cff8389ff7dff8391ff7eff8399ff7fff83a1ff97ff83a9ff98ff83b1ff99ff83b9ff9aff83c1ff9bff83c9ff9c1e170225ff301e03d1ff781eff791bff7a2b191b03d8ff7b1bff7c2bff7d1c191b03e0ff7e1bff7f1cff972cff982d191b03e8ff991b191b03f0ff9a1b191b03f8ff9bff5100ff9c1b17020fff301b0408ff781bff7923191b040fff7a1b191c0417ff7b1cff7cff511fff7d1b191c0427ff7e1cff7fff512fff971b191c0437ff981cff991bff9a1f191b043fff9bff5147ff9c1b17022aff301b044fff78ff5154ff791b191c045cff7a1c192b0464ff7b2bff7c1c191c046cff7d1c192b0474ff7eff85047cff7fff850484ff97ff85048cff98ff850494ff99ff85049cff9aff8504a4ff9bff8504acff9c2b170234ff302b04b4ff782bff79ff51b9ff7a1b192b04c1ff7b2bff7cff51c9ff7dff51d1ff7eff51d9ff7fff51e1ff97ff51e9ff98ff51f1ff99ff51f9ff9a1b191b0501ff9b1b191b0509ff9c1b17023aff301b0511ff781b192b0517ff79ff85051fff7a2b192d0527ff7b2dff7cff85052fff7dff850537ff7eff85053fff7fff850547ff97ff85054fff98ff850557ff992bff9a1f192b055fff9b2bffdb3fff30200567ff7820ff79221920056eff7a20192b0576ff7b2bff7cff527eff7dff5286ff7eff528eff7fff5296ff97ff529eff98ff52a6ff99ff52aeff9aff52b6ff9bff52beffdb18ff302005c6ff7820ff7923192005cbff7a20192305d3ff7b23ff7c20ff7d2c192005dbff7eff52e3ff7fff52ebff97ff52f3ff98ff52fbff9920ff9a1f19200603ff9b201920060bffdb09ff30200613ff7820ff79221922061aff7a2219230622ff7b23ff7c22ff7dfff12aff7efff132ff7ffff13aff971cff981f191c0642ff99fff14aff9a1cff9b1fff9c1f17023e0a040affd20f091c0419220652181c012219220657181c02221702031c091c041922065f181c012219220666181c022217020c1c091c04181c011b191b066e181c021b1702051c091b04191c0676181b01fff17d181b021c1702141b091b04181b0115181b021f1702171b091b04181b0121191c0685181b021c1702251b041bffd218091c04181c0115181c0216081617ffc717171605251716140f181c031608163fffc70c1716050517161414171617171716252517160f0f17162a2a1716343417163a3a181c041608160c17160303181c0516081617ffc70c1716050517161414181c0616181c0703181c0803181c09ff2d031c091604ffe421ffe527081c05ffc80fffe61c081c17ffc83f171c0518171c1409ffe71c081c0c171c030cffe81c081c14ffc80c171cff951cff8c0cff84191c068dffe41cffe50d08222a1722030c17220c051722051417221417172217251722250f17220f2affe62208223a1722030c17220c051722051417221417172217251722250f17220f2a17222a341722343affe7220822141722030517220c1417220517ffe8220822141722030317220c0c1722ff9522ff310a22ff00ffeb05ff8419230693ffe423ffe529082b17ffc917172b0525172b140fffe62b082b0fffc90c172b0517172b140f172b172a172b2534ffe72bffb325ffe82bffb3141816062bff8c14ff84ffe41effe51affb30fffe62b082b05172b030c172b0c09ffe72bffb30fffe82b082b14ffc90c172bff952bff8c17ff84192b069dffe42bffe53f082c05ff8d0fffe62c082c05ff8d34ffe72cffb42affe82c082c14ff8d0c172cff952cff8c25ff84ffe40bffe525ffb403ffe62cffb403ffe72cffb418ffe82c082c14ff8d0c172cff952c1816070418160818181609ff2d0fff84192c06a5ffe42cffe525ffb514172d0c34ffe6ff5d0fffe7ff5d09ffe82dffb503172d0c0c1816062d1816071318160809ffeb2aff84ffe420ffe525ffb514172d0c34ffe6ff5d0fffe7ff5d3effe82d082d14172d0303172d0c0c172dff952d1816071a1816083effeb34ff84192206adffe422ffe509082d2a172d030c172d0c05172d0514172d1417172d1725172d250f172d0f34ffe62d082d3a172d030c172d0c05172d0514172d1417172d1725172d250f172d0f2a172d2a34172d343affe72dffb534172d0c3affe8ff5d171816062dff310a2d7f1816092d17023aff84192f06b3ffe42fffe5250830341730030c17300c051730051417301417173017251730250f17300f2a17302a34ffe63008300f1730030517300c1417300517173014251730170f1730253affe73008300c1730033fffe83008300c1730032518160630ff311816092d17023f160416ffd218092d04182d0115182d020c182d030c182d0403182d0503182d0603182d07ff2d032d09150418150121ff8e0cffba0cff451cff8e03ffba05ff4523ff8e03ffba14ff451eff4c050c1815060c1815070c170217ff452bff8e0cffba25ff450b18150203ff3a1815050318150603ffba0f15ffb62cff8f0cffec2a0bffb620ff8f0cffec340bffb622ff8f03ffec3a0bffb62fff8f03180b040cff903f0b040b020902041802010c180202051802031718020434180205130415020902041802010c18020205180203171802043418020513180206241802071d0a138018020813041cffd23a17020303161d150117020c1dffca02ffed0520ffca03ffed1420161d15021702171d161d15ff2d251d161d150417020f1d161d150517022a1dffca04ffed3420041dffd23e17020303ffc30117020c1effc3021702051effc30316201c02ff5e1421ffc30316201c04ff5e1721ffc3051702251effc30516201c06ff5e0f21ffc30617022a1effc30616201c03ff5e3421ffc30616201c04ff5e3a21ffc30717023f1effc3081702181effc30716201c08ff5e0921041e0206021906200606210706220806230e062401072b03072c0c072d05072f1407301707312507330f07352a07373407343a07383f07391807180907093e073c2e072e04213d162b02152b163d15160b3d160b2b03163d2b0416402b0516412b0616422b0716452b0816462b09162b1602164716041648160516491606164a160713163813133839131a3938481338183e13183c1305130b1d3c2c1315130b3c050b3d1d2c2d0b150b3d2c052c401d2d2f2c152c402d052d411d2f092d152d412f052f41123c2f05232f3c050c1d3c092f1b093c0c152f410912092f031a3c093823093c032d123c2f031a3d3c3823383d2f2d1f2d02141d02302d232d4242021f0220141d20310223024545201d2033211d2135221d2237231d23342415241d1315131e0b120b4603141d2e461a1e0b1d160b1501101dffdc02102effdc03102fffdc041030ffdc051015240b160b1c011024ff76021031ff76031033ff76041034ff76051035ff76061037ff7607103cff7608101c130b040b1e04131e041e2b152b0e22160e2b0516222b02163d2b03163e2b04152b0a2c150a1b0915091b38161b0a02160a09022309180a1b232c181b0a160a2b0216182b06161b2b0716382b0816402b0316412b0516422b0916452b0a16462b0b16482b0c164b2b0d164c2b0e042b0a230a391b18234d39181b191806ba191b06c2193906ca0c4e491a4f304e234e4f0a401a4f304923494f0a401a40304a234f404d490c404a1a5024402340500a411a50244a2351500a411a50244a2352504d4123414a0a4d23503c0a3823384a0a5023501c413823534a4d50194a06d2195006dc235447501f231f474a50194706e4194a06ee1550192d151906021502072015060821150701230a01090a080b162050021621500316235004162d5005165550061656500716575008165850091659500a165a500b165b500c165c500d16501902165d1903165e1904165f1905166019061661190716621908166319091664190a1665190b1666190c1667190d1668190e1619020216690203166a0204166b0205166c0206166d0207166e0208166f02091670020a1602060216710603160607021672070316730704167407051675070616760707167707080a070004782004792104212304232d047a550a7b00047c560f5607790f7d78210f7e79230f7f217a0f80237b0f817a7c1f827d781e830d821f8279071c8483820482571f57817a1e8359571f577b231c5983571f5721781e8384571c57830d1b8356571f5679071e5784561c56570d1f577d561f567a211e7d82561c567d0d1b7d7e561f5623791e8482561c56840d1f847f561f567a211e8582561c56850d1f857e561f5623791e7e82561c567e0d1b7e7f561f567c7a1e7f59561c567f0d1b7f80561f567b231e8059561c56800d1f5981561e5679171c80563f0456780f8179830f82215722577d85580f8379572257847e580f5821572257857d0d0f7d235722577e840d0f7e7a570f57237f0f7f7a591e59235a1c5a590d04597c258423575a7b5b25857a7f597c5b25860780817950258778568221502550798180075c2588218256785c1b5c505d1f5d88ffb7895f1e8a5e890b5e0d2089605e030b5e891c895e0d1c5e890d1e898a5e1b5e5f8922895c86ffb78a5f1e8b5e8a0b5e0d208a605e030b5e8a1c8a5e0d1c5e8a0d1e8a8b5e1b5e5f8a228a5d87ffb78b5f1e8c5e8b205e60030d1c8b5e0d1c5e8b0d1e8b8c5e1b5e5f8b228b5c50ffb78c5f1e8d5e8c205e60030d1c8c5e0d1c5e8c0d1e8c8d5e1b5e5f8c228c5d885e225e865065228d8788651f650d67228e8650651f650d6722678788650f655e8e0f8f8d672290655c661c5c680d1b68905c225c8f5d66ffdd665f1e905d660b5d0d2066605d030b5d661c665d0d1c5d660d1e66905d1b5d5f662266685e5dffdd905f1e915d900b5d0d2090605d030b5d901c905d0d1c5d900d1e90915d1b5d5f9022905c8d5dffdd915f1e925d91205d60030d1c915d0d1c5d910d1e91925d1b5d5f912291688e5dffdd685f1e925d68205d60030d1c605d0d1c5d600d1e60925d1b5d5f60225f5c675d0f5c86890f5d878a0f60898b0f688a8c0f928b500f938c881f948a871e9561941c94950d1b955c941f5c89861e94615c1c5c940d1f945d5c1f5c8c8a1e5d625c1c5c5d0d1b5d605c1f5c8b891e60625c1c5c600d1f60685c1f5c888c1e62635c1c5c620d1b62925c1f5c508b1e68635c1c5c680d1f68935c0f5c86950f9287940f9389950f958a940f94895d0f968a600f978b5d0f5d8c600f608b620f988c680f9950620f6288680f685e660f9a8d900f9b66910f9c905f0f9d918e0f9e5f671f9f908d1ea0619f1c9fa00d1ba0689f1f68665e1e9f61681c619f0d1f689a611f615f901e9a64611c619a0d1b9a9b611f6191661e9b64611c619b0d1f649c611f61675f1e9b63611c619b0d1b9b9d611f618e911e9c63611c619c0d1f639e610f615ea00f9c8d680f9d66a00f9e90680f68669a0f9f90640fa0919a0f9a5f640f64919b0fa15f630fa28e9b0f9b67630a63000aa3000ba46a0aa5000aa6000ba76b1ea8630d2263a76ca804a76a0a6a000aa8000ba96b1e6ba30d22a36ca96b046ba41ca963051caaa40504ab631caca70504ad6304aea71caf630504b0a71cb1a3051cb2a70504b3a31cb4a40504b5a304b6a41cb7a3050ab8140ab9001bba32700b32011f70ba0804bb011fbcba080fbdb9320fbeba700fbf32bb0fc070bc0fc1bbb90fc2bcba1fc370ba1ec4b8c31cc3c40d1bc4bdc31fbd32b91ec3b8bd1cbdc30d1fc3bebd1fbdbc701ebeb8bd1cbdbe0d1bbebfbd1fbdbb321ebfb8bd1cbdbf0d1fbfc0bd1fbdbabc1ec0b8bd1cbdc00d1bc0c1bd1fbdb9bb1ec1b8bd1cb8c10d1fbdc2b80fb8b9c40fc1bac30fc232c40fc470c30fc332be0fc570bf0fc6bbbe0fbebcbf0fbfbbc00fc7bcbd0fc8b9c00fc0babd25bdb9b8c2322925c9bac1c4702925cab9b8c2321125cbbac1c470111bccbd0c1ecd01171ccecd3f1fcdc9ce1ece01171c01ce3f1bcebd011e01080f1c08013f1f01c9080a08001bcfba222022cfba7c04cf3d1b3d223e203e3dba7c0f3d08cf0fd0223e1fd13e221ed20ed11cd1d20d1fd23dd11f3dcf081ed10e3d1c0ed10d1b3dd00e0f0e08d20fd0223d0fd1cfd20fd23e3d1e3d04731cd33d3f0a3d0004d4750475760f76d3d40fd53d751fd6753d1ed777d61cd6d70d1bd776d61f76d4d31ed677761c76d60d1f77d5760f76d3d70fd53d770fd6d4d70fd775772277363f5b22d80d105b22d926035b1b26844422da363f5b22db8426da1b26851222da363f5b22368526da222610035b1bda84441bdc852a1c2a5b0d1fdd0c2a0a2a2a1ededd2a1edd44de1cdedd0d1cdd5b0d1f5b0cdd1edd5b2a1e2a12dd1c5b2a0d0a2a000add0404dfdb04e03604e18404e28504e3ba04e47704e52004e61904e76904e81904e96904ea6e04eb6f04ec1904196904edba04ee740d06f6012b0d081c014e0d086101400d08a6010a0d08eb014d0d093001410d0975014f0d09ba01490d09ff0001510d0a4401520d0a8a01470d0ad001530d0b1601380d0b5c01420d0ba2012c0d0be801090d0c2e01450d0c7401540d0cba011f0d0d00014a0d0d3d014b0d0d00011b0d0d0001390d0d8301460d0dc901480d0e0f014c0d0d0001180d0e550b09841b0a093f020aff531f098510ff961f0a843f020aff531f098510ff961b0984440209ffd5098512ff960b0a841f180a440218ffd509851202090d1176230915ffbb11f31e09da171c0a093f1e0926051b15dc090b09da1e1809171c09183f1e1726051b18dc170b17da27dadc0a15091817dc0d123a230930ffbb13230b09db0209ff5302e00d11740b09db0a0a6e1b15090a0215ffd5093612ff960b15db1f1715440217ffd515361202150d134602dfff5302e00d11741f17db0a0217ffd5093612ff961b09db440209ffd515361202150d136b23091dffbb13801b0984de0b0a091f090a270209ffd509855b1f0a0929020a0d13c923092fffbb14d90b09841b0a09d9020aff5302e20d14fc1f0984d9ff9602e1ff531e09d9251b0a8509020a0d14fc0b098402090d136b23092effbb14fe1c09d80502090d15340b090c230a16090c020a0d162f0e8687ff555c929395898aff559496975d8b8cff556098996250880d16770e5e8dff55619c9d9e6690ff55689fa09a915fff5564a1a29b8e670d17900e0778ff55805681827921ff5583587d7e237aff55577f5a597b7c0d16760b095a0b0a570b12232609590a7f127a0d16760b097d0b0a830b127926097e0a5812210d16760b09810b0a800b12072609820a5612780d18ff002307310c03ffd6197c1b07ba28ffd619a92307350c03ffd619cd02e30d1a3c1b07ba0dffd61a431b07ba0dffd6136b2307370c03ffd61a491b07ba0fffd61a771b07ba0fffd61ab723073c0c03ffd61adb0e86870d16761f0765291b098f041b0a65041b0f8f042607090a0f50880d1afd23041cff5a1b1b0a04481f076904ffd61b4a230434ff5a1b6fff911be1ff91117402e4ffd504ba11fff811740b07770207ffd504ba11fff8136b230433ff5a1be6ff911be1ff91136b230424ff5a1c5c02e50d1c891f046910fff81cca1f046910fff81d0a230413ff5a1d351b042d440b07040207ff531f045525fff81d6c23040bff5a1ec81f042044fff81f03ffcb1fba02e60d1fc802e70d1fcbffcb20250a04b41e07040d1e046d071c07040d1904013a1c09070402090d203aff3b1676ff4d1676ff4eaf046a0d1676ff3c1676ff4641ff75ffccb3ff3b20b11c046c051c076c0c1c096c0c266b04aa07a6090d20b11c046c0c1c076c051b09a7dd26ac04ae0709ff4fffccb3ff75ff46b802e8ff5302e90d216102ea0d219502eb0d219c1c040205fff821a31c02710502020d21aa1b02a76e1b04a6ff92ffd5026a6f1b0463ff920d222e1b02a86e1b04a4ff92ffd502a36f1b04a5ff920d229effcb237d02e60d1fc802e70d238a02ecff5302190d244e02ed0d24d01f02baba1f0422ba24b90208040d254d1f0222ba1f04d0ba1f07d2ba1f093eba2708020e04d107cf090d25a623021e0c0302020d25e60b02731e0402251c02043f0202ff5302ee0d26250b021a02020d203affded6d7d4750d26750b021a1e04053b1e0772041c04070d1b070204ffd6203a1e02d63a1c04023f1e02d43a1c07023fffde04d707750d26c512020605230402ff5a270c0b021a1e040c3b1e0572041c04050d1b05020402050d203affded6d7d4750d26c512020614230402ff5a270c0b021a1e03143b1e0472031c03040d1b040203fff8203a1e02d6431c03020d1e02d4431c04020dffde03d704750d27210eb9baff55b8c1c2c43270ff55c3c5c6bebbbcff55bfc7c8c0b9ba0d27dd27bdc9cccdce01cacb0d2841";
        

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
function write_byte(byteValue) {
    let pOutput := m_get(/*VAR_ID_OUTPUT*/0x140)

    let len := mload(pOutput)
    // store the increased length
    mstore(pOutput, add(len, 1))

    // store the byte
    mstore8(add(pOutput, add(len, 32)), byteValue)
}

function write_dataPackString(v) {
    for { let i := v }  true {  i := add(i, 1) } {
        let x := mload8(add(m_get(/*VAR_ID_DATA_PACK_STRINGS*/0x131), i))
        if eq(x, 0) { break }

        write_byte(x)
    }
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

    let pDataPack := allocate(/*LENGTH_DATA_PACK_ALL*/22478)
    // Reset length to 0
    mstore(pDataPack, 0)

    // Assign pDataPack vars
    m_set(/*VAR_ID_DATA_PACK_ALL*/0x130, pDataPack)
    m_set(/*VAR_ID_DATA_PACK_STRINGS*/0x131, add(32, pDataPack))
    m_set(/*VAR_ID_DATA_PACK_OPS*/0x132, add(add(32, pDataPack), /*LENGTH_DATA_PACK_STRINGS*/10481))


    // Decompress
    /**
     * mode := 0: Loading data
     * mode := 1: Loading table
     * mode >= 2: Loading table entry
     */
    let mode := 1
    let iCurrentTableEntry := 0
    let isControlByte := 0
    let pEntry := 0

    for { let i := 0 }  slt(i, /*LENGTH_DATA_PACK_COMPRESSED*/14923) {  i := add(i, 1) } {
        let b := mload8(add(_pDataPackCompressed, i))
        if and(iszero(isControlByte), and(eq(b, 0xFF), sgt(iCurrentTableEntry, 0))) {
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

                if sgt(iCurrentTableEntry, 255) {
                    mode := 0
                    i := add(i, 5)
                }
            }
            continue
        }
        if sgt(mode, 0) {
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
    for { let iByte := 0 }  slt(iByte, /*LENGTH_DATA_PACK_OPS*/11997) {  } {
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

        case 4 { /*op_copy*/m_set(argByte_1, m_get(argByte_2)) result := 3  leave }

        case 5 { /*op_getArrayLength*/op_mem_getLength(argByte_1, argByte_2) result := 3  leave }

        case 6 { /*op_getLength*/op_mem_getLength(argByte_1, argByte_2) result := 3  leave }

        case 7 { op_getRvsValue(argByte_1,argByte_2) result := 3  leave }

        case 8 { /*op_loadArray_create*/op_mem_create(argByte_1, argByte_2) result := 3  leave }

        case 9 { /*op_loadObject_create*/op_mem_create(argByte_1, argByte_2) result := 3  leave }

        case 10 { /*op_loadUint8*/m_set(argByte_1, argByte_2) result := 3  leave }

        case 11 { /*op_unaryNegative*/m_set(argByte_1, sub(0, m_get(argByte_2))) result := 3  leave }

        case 12 { /*op_unaryNot*/m_set(argByte_1, iszero(m_get(argByte_2))) result := 3  leave }

        case 13 { /*op_write_text*/write_dataPackString(add(mul(argByte_1, 256), argByte_2)) result := 3  leave }

        case 14 { /*op_write_vertex*/
            write_drawInstruction(
            77/*M*/,
            argByte_1,
            44/*,*/,
            argByte_2)
             result := 3  leave }

    let argByte_3 := mload8(add(pDataPackOps, add(iByteStart, 3)))
    
    switch opId 
        case 15 { /*op_average*/m_set(argByte_1, sdiv(add(m_get(argByte_2), m_get(argByte_3)), 2)) result := 4  leave }

        case 16 { /*op_bitwiseAnd*/m_set(argByte_1, and(m_get(argByte_2), m_get(argByte_3))) result := 4  leave }

        case 17 { /*op_bitwiseOr*/m_set(argByte_1, or(m_get(argByte_2), m_get(argByte_3))) result := 4  leave }

        case 18 { /*op_comparisonGreater*/m_set(argByte_1, sgt(m_get(argByte_2), m_get(argByte_3))) result := 4  leave }

        case 19 { /*op_comparisonLess*/m_set(argByte_1, slt(m_get(argByte_2), m_get(argByte_3))) result := 4  leave }

        case 20 { /*op_comparisonLessEqual*/m_set(argByte_1, not(sgt(m_get(argByte_2), m_get(argByte_3)))) result := 4  leave }

        case 21 { /*op_getArrayItem*/op_mem_getItem(argByte_1, argByte_2, m_get(argByte_3)) result := 4  leave }

        case 22 { /*op_getObjectField*/op_mem_getItem(argByte_1, argByte_2, argByte_3) result := 4  leave }

        case 23 { /*op_loadArray_setItem*/op_mem_setItem(argByte_1, m_get(argByte_2), argByte_3) result := 4  leave }

        case 24 { /*op_loadObject_setItem*/op_mem_setItem(argByte_1, argByte_2, argByte_3) result := 4  leave }

        case 25 { /*op_loadUint16*/m_set(argByte_1, add(mul(argByte_2, 256), argByte_3)) result := 4  leave }

        case 26 { /*op_logicalAnd*/m_set(argByte_1, and(m_get(argByte_2), m_get(argByte_3))) result := 4  leave }

        case 27 { /*op_mathAdd*/m_set(argByte_1, add(m_get(argByte_2), m_get(argByte_3))) result := 4  leave }

        case 28 { /*op_mathDiv*/m_set(argByte_1, sdiv(m_get(argByte_2), m_get(argByte_3))) result := 4  leave }

        case 29 { /*op_mathMod*/m_set(argByte_1, smod(m_get(argByte_2), m_get(argByte_3))) result := 4  leave }

        case 30 { /*op_mathMul*/m_set(argByte_1, mul(m_get(argByte_2), m_get(argByte_3))) result := 4  leave }

        case 31 { /*op_mathSub*/m_set(argByte_1, sub(m_get(argByte_2), m_get(argByte_3))) result := 4  leave }

    let argByte_4 := mload8(add(pDataPackOps, add(iByteStart, 4)))
    
    switch opId 
        case 32 { /*op_constrain*/
            let x_ltMin := slt(m_get(argByte_2), m_get(argByte_3))
            let x_gtMax := sgt(m_get(argByte_2), m_get(argByte_4))
            if  x_ltMin  { m_set(argByte_1, m_get(argByte_3)) }
            if  x_gtMax  { m_set(argByte_1, m_get(argByte_4)) }
            if  not(or(x_ltMin, x_gtMax))  { m_set(argByte_1, m_get(argByte_2)) }
             result := 5  leave }

        case 33 { op_getBreedIndex(argByte_1,argByte_2,argByte_3,argByte_4) result := 5  leave }

        case 34 { /*op_lerp_100*/
            let x_a := mul(m_get(argByte_2), sub(100, m_get(argByte_4)))
            let x_b := mul(m_get(argByte_3), m_get(argByte_4))
            let x_result := sdiv(add(x_a, x_b), 100)
            m_set(argByte_1, x_result)
             result := 5  leave }

        case 35 { /*op_ternary*/
            let x_default := iszero(m_get(argByte_2))
            if  not(x_default)  { m_set(argByte_1, m_get(argByte_3)) }
            if  x_default  { m_set(argByte_1, m_get(argByte_4)) }
             result := 5  leave }

        case 36 { /*op_write_line*/
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
    
    let argByte_6 := mload8(add(pDataPackOps, add(iByteStart, 6)))
    
    switch opId 
        case 37 { /*op_bezierPoint_100*/
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

        case 38 { /*op_write_bezierVertex*/
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
        case 39 { /*op_write_bezier*/
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
if slt(mload(/*PP_FREE_MEMORY*/0x40), /*MEM_FREE_MEMORY_INIT_JS*/0xFFFD0) {
    mstore(/*PP_FREE_MEMORY*/0x40, /*MEM_FREE_MEMORY_INIT_JS*/0xFFFD0)
}

// Store length at memory start
let pMemoryStart := allocate(0)

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
run_decompressDataPack(m_get(/*VAR_ID_DATA_PACK_COMPRESSED*/0x121))
run_DataPackOps(m_get(/*VAR_ID_DATA_PACK_OPS*/0x132))
    

// Select output
switch kind
case 42 {
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
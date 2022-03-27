/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

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
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        delete getApproved[id];

        ownerOf[id] = to;

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
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            totalSupply++;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            totalSupply--;

            balanceOf[owner]--;
        }

        delete ownerOf[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
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
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)



// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)



/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

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
}// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)



/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)



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
}// From: https://github.com/scaffold-eth/scaffold-eth/blob/loogies-svg-nft/packages/hardhat/contracts/ToColor.sol
library Colours {
    bytes16 internal constant ALPHABET = "0123456789abcdef";

    function toColour(bytes3 value) internal pure returns (string memory) {
        bytes memory buffer = new bytes(6);
        for (uint256 i = 0; i < 3; i++) {
            buffer[i * 2 + 1] = ALPHABET[uint8(value[i]) & 0xf];
            buffer[i * 2] = ALPHABET[uint8(value[i] >> 4) & 0xf];
        }
        return string(buffer);
    }
}// From: https://github.com/scaffold-eth/scaffold-eth/blob/loogies-svg-nft/packages/hardhat/contracts/ToColor.sol
library Bytes {
    error ToUint256OutOfBounds();

    // https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol#L374
    function toUint256(bytes memory _bytes) internal pure returns (uint256) {
        if (_bytes.length < 32) revert ToUint256OutOfBounds();
        uint256 tempUint;

        assembly {
            tempUint := mload(add(_bytes, 0x20))
        }

        return tempUint;
    }
}interface IERC4883 is IERC165 {
    function zIndex() external view returns (int256);

    function render(uint256 tokenId) external view returns (string memory);
}abstract contract ERC721PayableMintable is ERC721, Ownable {
    /// ERRORS

    /// @notice Thrown when underpaying
    error InsufficientPayment();

    /// @notice Thrown when owner already minted
    error OwnerAlreadyMinted();

    /// @notice Thrown when supply cap reached
    error SupplyCapReached();

    /// @notice Thrown when token doesn't exist
    error NonexistentToken();

    /// EVENTS

    bool private ownerMinted = false;

    uint256 public immutable price;
    uint256 public immutable ownerAllocation;
    uint256 public immutable supplyCap;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 price_,
        uint256 ownerAllocation_,
        uint256 supplyCap_
    ) ERC721(name_, symbol_) {
        price = price_;
        ownerAllocation = ownerAllocation_;
        supplyCap = supplyCap_;
    }

    function mint() public payable {
        if (msg.value < price) revert InsufficientPayment();
        if (totalSupply >= supplyCap) revert SupplyCapReached();
        _mint();
    }

    function ownerMint() public onlyOwner {
        if (ownerMinted) revert OwnerAlreadyMinted();

        uint256 available = ownerAllocation;
        if (totalSupply + ownerAllocation > supplyCap) {
            available = supplyCap - totalSupply;
        }

        for (uint256 index = 0; index < available;) {
            _mint();

            unchecked { ++index; }
        }

        ownerMinted = true;
    }

    function _mint() internal virtual {
        uint256 tokenId = totalSupply;
        _mint(msg.sender, tokenId);
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return ownerOf[tokenId] != address(0);
    }

    function withdraw(address to) public onlyOwner {
        payable(to).transfer(address(this).balance);
    }
}
contract WaveBackground is ERC721PayableMintable, IERC4883 {
    using Colours for bytes3;

    mapping(uint256 => bytes3) private _colours;

    int256 public immutable zIndex;

    constructor() ERC721PayableMintable("Wave Background", "WAVE", 0 ether, 42, 42) {
        zIndex = -100;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC4883).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _mint() internal override {
        uint256 tokenId = totalSupply;

        // from: https://github.com/scaffold-eth/scaffold-eth/blob/48be9829d9c925e4b4cda8735ddc9ff0675d9751/packages/hardhat/contracts/YourCollectible.sol
        bytes32 predictableRandom = keccak256(
            abi.encodePacked(
                tokenId,
                blockhash(block.number),
                msg.sender,
                address(this)
            )
        );
        _colours[tokenId] =
            bytes2(predictableRandom[0]) |
            (bytes2(predictableRandom[1]) >> 8) |
            (bytes3(predictableRandom[2]) >> 16);

        super._mint();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert NonexistentToken();

        string memory tokenName_ = string.concat(
            name,
            " #",
            Strings.toString(tokenId)
        );
        string memory description = "Wave. Background for Party Panda NFTs";

        string memory image = _generateBase64Image(tokenId);
        string memory attributes = _generateAttributes(tokenId);
        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            tokenName_,
                            '", "description":"',
                            description,
                            '", "image": "data:image/svg+xml;base64,',
                            image,
                            '",',
                            attributes,
                            "}"
                        )
                    )
                )
            );
    }

    function _generateAttributes(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        string memory attributes = string.concat(
            '{"trait_type": "colour", "value": "',
            _colours[tokenId].toColour(),
            '"}'
        );

        return string.concat('"attributes": [', attributes, "]");
    }

    function _generateBase64Image(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return Base64.encode(bytes(_generateSVG(tokenId)));
    }

    function _generateSVG(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        string memory svg = string.concat(
            '<svg id="',
            "wave",
            Strings.toString(tokenId),
            '" width="288" height="288" viewBox="0 0 288 288" fill="none" xmlns="http://www.w3.org/2000/svg">',
            render(tokenId),
            "</svg>"
        );

        return svg;
    }

    function render(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory colourValue = string.concat(
            "#",
            _colours[tokenId].toColour()
        );

        return
            string.concat(
                '<g id="wave">'
                '<g transform="translate(144,144) scale(1,1) translate(-144,-144)"><linearGradient id="lg-0.0007576276008076643" x1="0" x2="1" y1="0" y2="0">'
                '<stop stop-color="#ff00ff" offset="0"></stop>'
                '<stop stop-color="#00ffff" offset="1"></stop>'
                '</linearGradient><path d="" fill="url(#lg-0.0007576276008076643)" opacity="0.4">'
                '<animate attributeName="d" dur="10s" repeatCount="indefinite" keyTimes="0;0.333;0.667;1" calcmod="spline" keySplines="0.2 0 0.2 1;0.2 0 0.2 1;0.2 0 0.2 1" begin="0s" values="M0 0L 0 249.3478160469087Q 28.8 271.20875796797964  57.6 243.19677845047337T 115.2 220.84783850028492T 172.8 190.67319530444155T 230.4 198.70816949285725T 288 177.7854552220291L 288 0 Z;M0 0L 0 244.01646850408764Q 28.8 258.5770569600993  57.6 228.0001947903528T 115.2 240.18036668638092T 172.8 207.11316893376122T 230.4 204.29282283007936T 288 189.51717085666166L 288 0 Z;M0 0L 0 282.5531364453796Q 28.8 261.8044198477804  57.6 224.14288991057037T 115.2 217.13703938710012T 172.8 194.86879702206704T 230.4 198.2381575000438T 288 166.99020553361333L 288 0 Z;M0 0L 0 249.3478160469087Q 28.8 271.20875796797964  57.6 243.19677845047337T 115.2 220.84783850028492T 172.8 190.67319530444155T 230.4 198.70816949285725T 288 177.7854552220291L 288 0 Z"></animate>'
                '</path><path d="" fill="url(#lg-0.0007576276008076643)" opacity="0.4">'
                '<animate attributeName="d" dur="10s" repeatCount="indefinite" keyTimes="0;0.333;0.667;1" calcmod="spline" keySplines="0.2 0 0.2 1;0.2 0 0.2 1;0.2 0 0.2 1" begin="-3.3333333333333335s" values="M0 0L 0 241.91399976511337Q 28.8 272.773031824481  57.6 221.6330991204484T 115.2 203.554617966047T 172.8 215.3598833767817T 230.4 208.331215945932T 288 159.3922817012802L 288 0 Z;M0 0L 0 267.89249867026297Q 28.8 261.5378358664616  57.6 220.72516882318087T 115.2 204.88274072914487T 172.8 187.6560243398394T 230.4 167.41828303154165T 288 195.78093900615812L 288 0 Z;M0 0L 0 252.82333411101428Q 28.8 293.3915055414478  57.6 252.16446051277478T 115.2 201.5700091585775T 172.8 201.7484716305146T 230.4 202.12263583758465T 288 173.66216218576926L 288 0 Z;M0 0L 0 241.91399976511337Q 28.8 272.773031824481  57.6 221.6330991204484T 115.2 203.554617966047T 172.8 215.3598833767817T 230.4 208.331215945932T 288 159.3922817012802L 288 0 Z"></animate>'
                '</path><path d="" fill="url(#lg-0.0007576276008076643)" opacity="0.4">'
                '<animate attributeName="d" dur="10s" repeatCount="indefinite" keyTimes="0;0.333;0.667;1" calcmod="spline" keySplines="0.2 0 0.2 1;0.2 0 0.2 1;0.2 0 0.2 1" begin="-6.666666666666667s" values="M0 0L 0 263.26462729185835Q 28.8 291.59686587726713  57.6 255.90098957857725T 115.2 228.43886085937962T 172.8 212.01054854726448T 230.4 187.10076529478778T 288 161.9028458031765L 288 0 Z;M0 0L 0 239.01027845858462Q 28.8 265.0748050205812  57.6 234.1974008014628T 115.2 210.2224266016108T 172.8 221.36373409559496T 230.4 202.0501911637237T 288 179.7894671663367L 288 0 Z;M0 0L 0 265.45535094365033Q 28.8 248.27083050546915  57.6 218.6680765245456T 115.2 217.29793880408266T 172.8 187.19331156562936T 230.4 195.84859895912288T 288 151.99493293483093L 288 0 Z;M0 0L 0 263.26462729185835Q 28.8 291.59686587726713  57.6 255.90098957857725T 115.2 228.43886085937962T 172.8 212.01054854726448T 230.4 187.10076529478778T 288 161.9028458031765L 288 0 Z"></animate>'
                '</path></g>'
                '</g>'
            );
    }

    function addToComposable(uint256 tokenId, address composableToken, uint256 composableTokenId) external {
        safeTransferFrom(msg.sender, composableToken, tokenId, abi.encode(composableTokenId));
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)



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
}

interface IERC4883 is IERC165 {
    function zIndex() external view returns (int256);

    function render(uint256 tokenId) external view returns (string memory);
}/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
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
}
abstract contract ERC721PayableMintable is ERC721, Ownable {
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
}// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)



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
abstract contract ERC721PayableMintableComposableSVG is
    ERC721PayableMintable,
    IERC4883,
    IERC721Receiver
{
    /// ERRORS

    /// @notice Thrown when attempting to add composable token with same Z index
    error SameZIndex();

    /// @notice Thrown when attempting to add a not composable token
    error NotComposableToken();

    /// @notice Thrown when action not from token owner
    error NotTokenOwner();

    /// @notice Thrown when background already added
    error BackgroundAlreadyAdded();

    /// @notice Thrown when foreground already added
    error ForegroundAlreadyAdded();

    /// EVENTS

    /// @notice Emitted when composable token added
    event ComposableAdded(uint256 tokenId, address composableToken, uint256 composableTokenId);
    
    /// @notice Emitted when composable token removed
    event ComposableRemoved(uint256 tokenId, address composableToken, uint256 composableTokenId);

    int256 public immutable zIndex;

    struct Token {
        address tokenAddress;
        uint256 tokenId;
    }

    struct Composable {
        Token background;
        Token foreground;
    }

    mapping(uint256 => Composable) public composables;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 price_,
        uint256 ownerAllocation_,
        uint256 supplyCap_,
        int256 z
    )
        ERC721PayableMintable(
            name_,
            symbol_,
            price_,
            ownerAllocation_,
            supplyCap_
        )
    {
        zIndex = z;
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

    function _renderBackground(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        string memory background = "";

        if (composables[tokenId].background.tokenAddress != address(0)) {
            background = IERC4883(composables[tokenId].background.tokenAddress)
                .render(composables[tokenId].background.tokenId);
        }

        return background;
    }

    function _renderForeground(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        string memory foreground = "";

        if (composables[tokenId].foreground.tokenAddress != address(0)) {
            foreground = IERC4883(composables[tokenId].foreground.tokenAddress)
                .render(composables[tokenId].foreground.tokenId);
        }

        return foreground;
    }

    function _backgroundName(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        string memory background = "";

        if (composables[tokenId].background.tokenAddress != address(0)) {
            background = ERC721(composables[tokenId].background.tokenAddress)
                .name();
        }

        return background;
    }

    function _foregroundName(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        string memory foreground = "";

        if (composables[tokenId].foreground.tokenAddress != address(0)) {
            foreground = ERC721(composables[tokenId].foreground.tokenAddress)
                .name();
        }

        return foreground;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 composableTokenId,
        bytes calldata idData
    ) external returns (bytes4) {
        uint256 tokenId = Bytes.toUint256(idData);

        if (!_exists(tokenId)) revert NonexistentToken();
        if (ownerOf[tokenId] != from) revert NotTokenOwner();

        IERC4883 composableToken = IERC4883(msg.sender);
        if (!composableToken.supportsInterface(type(IERC4883).interfaceId))
            revert NotComposableToken();

        if (composableToken.zIndex() < zIndex) {
            if (composables[tokenId].background.tokenAddress != address(0))
                revert BackgroundAlreadyAdded();
            composables[tokenId].background = Token(
                msg.sender,
                composableTokenId
            );
        } else if (composableToken.zIndex() > zIndex) {
            if (composables[tokenId].foreground.tokenAddress != address(0))
                revert ForegroundAlreadyAdded();
            composables[tokenId].foreground = Token(
                msg.sender,
                composableTokenId
            );
        } else {
            revert SameZIndex();
        }

        emit ComposableAdded(tokenId, msg.sender, composableTokenId);

        return this.onERC721Received.selector;
    }

    function removeComposable(
        uint256 tokenId,
        address composableToken,
        uint256 composableTokenId
    ) external {
        if (_msgSender() != ownerOf[tokenId]) revert NotTokenOwner();

        if (
            composables[tokenId].background.tokenAddress == composableToken &&
            composables[tokenId].background.tokenId == composableTokenId
        ) {
            composables[tokenId].background = Token(address(0), 0);
        } else if (
            composables[tokenId].foreground.tokenAddress == composableToken &&
            composables[tokenId].foreground.tokenId == composableTokenId
        ) {
            composables[tokenId].foreground = Token(address(0), 0);
        }

        ERC721(composableToken).safeTransferFrom(
            address(this),
            msg.sender,
            composableTokenId
        );

        emit ComposableRemoved(tokenId, composableToken, composableTokenId);
    }
}contract NamedToken {
    /// @notice Thrown when attempting to set an invalid token name
    error InvalidTokenName();

    /// EVENTS

    /// @notice Emitted when name changed
    event TokenNameChange(uint256 indexed tokenId, string tokenName);

    mapping(uint256 => string) private _names;
    string private _name;

    constructor(string memory name_) {
        _name = name_;
    }

    function tokenName(uint256 tokenId) public view returns (string memory) {
        string memory tokenName_ = _names[tokenId];

        bytes memory b = bytes(tokenName_);
        if (b.length < 1) {
            tokenName_ = string.concat(_name, " #", Strings.toString(tokenId));
        }

        return tokenName_;
    }

    // Based on The HashMarks
    // https://etherscan.io/address/0xc2c747e0f7004f9e8817db2ca4997657a7746928#code#F7#L311
    function _changeTokenName(uint256 tokenId, string memory newTokenName)
        internal
    {
        //if (!_exists(tokenId)) revert NonexistentToken();
        //if (_msgSender() != ownerOf[tokenId]) revert NotTokenOwner();
        if (!validateTokenName(newTokenName)) revert InvalidTokenName();

        _names[tokenId] = newTokenName;

        emit TokenNameChange(tokenId, newTokenName);
    }

    // From The HashMarks
    // https://etherscan.io/address/0xc2c747e0f7004f9e8817db2ca4997657a7746928#code#F7#L612
    function validateTokenName(string memory str) public pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length < 1) return false;
        if (b.length > 25) return false; // Cannot be longer than 25 characters
        if (b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];

        for (uint i; i < b.length; i++) {
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            ) return false;

            lastChar = char;
        }

        return true;
    }
}
contract PartyPanda is ERC721PayableMintableComposableSVG, NamedToken {
    using Colours for bytes3;

    /// ERRORS

    /// EVENTS

    mapping(uint256 => bytes3) private _colours;

    string constant NAME = "Party Panda";

    constructor()
        ERC721PayableMintableComposableSVG(NAME, "PRTY", 0.000888 ether, 88, 888, 0)
        NamedToken(NAME)
    {}

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

        string memory tokenName_ = tokenName(tokenId);
        string
            memory description = "Party Panda NFT.";

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

    function _generatePartyValue(uint256 tokenId)
        internal
        pure
        returns (string memory)
    {
        return Strings.toString(((tokenId % 23) + 7) / 3);
    }

    function _generateAttributes(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        string memory attributes = string.concat(
            '{"trait_type": "party", "value": "',
            _generatePartyValue(tokenId),
            '"}'
            ',{"trait_type": "colour", "value": "',
            _colours[tokenId].toColour(),
            '"}'
            ',{"trait_type": "background", "value": "',
            _backgroundName(tokenId),
            '"}'
            ',{"trait_type": "foreground", "value": "',
            _foregroundName(tokenId),
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
            "panda",
            Strings.toString(tokenId),
            '" width="288" height="288" viewBox="0 0 288 288" fill="none" xmlns="http://www.w3.org/2000/svg">',
            render(tokenId),
            "</svg>"
        );

        return svg;
    }

    function _renderBody(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        string memory colourValue = string.concat(
            "#",
            _colours[tokenId].toColour()
        );

        return
            string.concat(
                '<g id="panda">'
                '<!--Copyright 2022 Alex Party Panda https://github.com/AlexPartyPanda-->'
                '<path d="M97.5 183.5c-22.878-11.248-31.543-10.843-37 6 1.297 16.917 3.99 21.712 11 25 10.177 4.886 38.421-1.909 71-6.5 45.864 5.702 75.701 9.828 81.5 6.5 8.506-5.407 11.972-9.787 11-25-8.153-11.761-13.16-16.601-26-9.5l-16-8.5-95.5 12Z" fill="',colourValue, '" stroke="#000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>'
                '<path d="m115 205.5-4.5-41h57v45c-16.505 5.452-33.861 9.59-52.5-4Z" fill="#FFF" stroke="#000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>'
                '<path d="M124 215c-6.408 1.507-33.142 12.135-39-4 .419-11.525 1.364-21.559 3.647-31.5 3.406-14.829 9.792-29.45 21.853-48.5 27.727 17.26 40.773 13.3 68.5.5 12.01 17.087 19.173 31.974 19.093 44.5-.027 4.215 1.002 8.615 0 13.5 0 0-1.593 9.5-1.593 21.5s-32.5 15.5-36 0-1.276-7.912 3.5-35c-14.577-2.983-24.32-2.712-43.5 0 2.845 4.885 9.908 37.493 3.5 39Zm36.5-143.5c18.121-8.994 17.214-.228 16.5 20.5l-16.5-20.5Zm-52.5 14c-2.876-17.522 1.048-21.717 18-16.5l-18 16.5Z" fill="',colourValue, '" stroke="#000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>'
                '<path d="M177 92c-17.5-35.5-52-35.5-70.5-3-8.666 23.757-9.202 33.968 4 42 27.357 18.75 41.337 16.44 69 0 3.5-5.5 6.499-24.919-2.5-39Z" fill="#FFF" stroke="#000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>'
                '<path d="M131.5 125.5c9.101 3.874 10.24 3.497 18 0" stroke="#000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>'
                '<path d="M129 111.5c4.5-4.5 17-2.5 19 1-5 5-14 4-19-1ZM125 87c5.099 5.584 2.743 5.485 4.5 9-4.985.625-8.844 3.99-17.5 15-1.172-3.319-1.471-3.485-3-8.5-1.529-5.014 10.901-21.084 16-15.5Z" fill="',colourValue, '" stroke="#000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>'
                '<circle cx="119" cy="98" r="4" fill="#000"/>'
                '<path d="M162.5 85c-6.664 2.996-9.447 5.477-12.5 11.5 8.04 4.452 12.128 8.376 18.5 18.5l5.5-7.5c-2.463-11.46-4.46-17.073-11.5-22.5Z" fill="',colourValue, '" stroke="#000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>'
                '<circle cx="159" cy="99" r="4" fill="#000"/>'
                '</g>'
            );
    }

    function render(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string.concat(
                _renderBackground(tokenId),
                _renderBody(tokenId),
                _renderForeground(tokenId)
            );
    }

    // Based on The HashMarks
    // https://etherscan.io/address/0xc2c747e0f7004f9e8817db2ca4997657a7746928#code#F7#L311
    function changeTokenName(uint256 tokenId, string memory newTokenName)
        external
    {
        if (!_exists(tokenId)) revert NonexistentToken();
        if (_msgSender() != ownerOf[tokenId]) revert NotTokenOwner();

        _changeTokenName(tokenId, newTokenName);
    }
}
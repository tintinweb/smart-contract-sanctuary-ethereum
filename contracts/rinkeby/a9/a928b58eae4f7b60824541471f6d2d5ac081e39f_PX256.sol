// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
pragma experimental ABIEncoderV2;

import "solmate/tokens/ERC20.sol";
import "solmate/tokens/ERC1155.sol";
import "solmate/auth/Owned.sol";
import "openzeppelin/utils/Base64.sol";
import "openzeppelin/utils/Strings.sol";
import "./Creatable.sol";
import "./ImageRenderer.sol";
import "./Sanitize.sol";

contract PX256 is ERC1155, Owned, Creatable {
    using Sanitize for string;
    using Strings for uint256;

    error BalanceTooLow();
    error DoesNotExist();
    error LengthMismatch();
    error UnsafeRecipient();

    // Constants

    uint256 private constant BIPS_PRECISION = 10000;

    // Private vars

    string private externalBaseURL = "https://uint256.art/";
    mapping(uint256 => string) private titles;
    mapping(uint256 => string) private descriptions;
    mapping(uint256 => string) private styles;

    // Public fields

    /// @notice the renderer
    IImageRenderer public renderer;

    /// @notice ERC-2981 Creator royalties in basis points
    uint16 public royaltyBips = 256;

    constructor() Owned(msg.sender) {}

    ////////////////////////////////////////////////////////////////
    //                        GETTERS
    ////////////////////////////////////////////////////////////////

    function uri(uint256 tokenID)
        public
        view
        override
        onlyMinted(tokenID)
        returns (string memory)
    {
        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(bytes(_metadata(tokenID)))
            );
    }

    function metadata(uint256 tokenID)
        external
        view
        onlyMinted(tokenID)
        returns (string memory)
    {
        return _metadata(tokenID);
    }

    function _metadata(uint256 tokenID)
        internal
        view
        returns (string memory json)
    {
        json = string.concat(
            "{",
            '"image": "',
            renderer.imageURL(tokenID, styleOf(tokenID)),
            '","name":"',
            titleOf(tokenID),
            '","description":"',
            descriptionOf(tokenID),
            '","external_url":"',
            externalURL(tokenID),
            '","attributes":[',
            "]}"
        );
    }

    function titleOf(uint256 tokenID) public view returns (string memory) {
        bytes memory t = bytes(titles[tokenID]);
        if (t.length == 0) {
            return string.concat("Untitled ", tokenID.toString());
        } else {
            return titles[tokenID].sanitizeForJSON(34);
        }
    }

    function descriptionOf(uint256 tokenID)
        public
        view
        returns (string memory)
    {
        return descriptions[tokenID].sanitizeForJSON(34);
    }

    function styleOf(uint256 tokenID) public view returns (string memory) {
        return styles[tokenID].sanitizeForJSON(34);
    }

    function externalURL(uint256 tokenID) public view returns (string memory) {
        return string.concat(externalBaseURL, tokenID.toHexString());
    }

    ////////////////////////////////////////////////////////////////
    //                        PUBLIC WRITES
    ////////////////////////////////////////////////////////////////

    function mint(uint256[] memory ids, uint256[] memory amounts)
        external
        virtual
    {
        address to = msg.sender;
        uint256 idsLength = ids.length; // Saves MLOADs.
        if (idsLength != amounts.length) {
            revert LengthMismatch();
        }

        mapping(uint256 => uint256) storage balances = balanceOf[to];
        for (uint256 i = 0; i < idsLength; ) {
            uint256 id = ids[i];
            creatorOf[id] = to;
            balances[id] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        if (idsLength == 1) {
            emit TransferSingle(to, address(0), to, ids[0], amounts[0]);
        } else {
            emit TransferBatch(to, address(0), to, ids, amounts);
        }

        if (
            to.code.length == 0
                ? to == address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(
                    to,
                    address(0),
                    ids,
                    amounts,
                    ""
                ) != ERC1155TokenReceiver.onERC1155BatchReceived.selector
        ) {
            revert UnsafeRecipient();
        }
    }

    function burn(uint256 tokenID, uint256 amount)
        external
        onlyMinted(tokenID)
    {
        if (balanceOf[msg.sender][tokenID] < amount) {
            revert BalanceTooLow();
        }
        _burn(msg.sender, tokenID, amount);
    }

    function refreshURI(uint256 tokenID) external {
        emit URI(uri(tokenID), tokenID);
    }

    ////////////////////////////////////////////////////////////////
    //                        CREATOR
    ////////////////////////////////////////////////////////////////

    /// @notice Creator can optionally set the title of the token
    /// @param tokenID the ID of the token
    /// @param title the title of this token
    function setTitle(uint256 tokenID, string calldata title)
        external
        creatorOnly(tokenID)
    {
        titles[tokenID] = title;
    }

    function clearTitle(uint256 tokenID) external creatorOnly(tokenID) {
        delete titles[tokenID];
    }

    /// @notice Creator can optionally set the description of the token
    /// @param tokenID the ID of the token
    /// @param description the description of this token
    function setDescription(uint256 tokenID, string calldata description)
        external
        creatorOnly(tokenID)
    {
        descriptions[tokenID] = description;
    }

    function clearDescription(uint256 tokenID) external creatorOnly(tokenID) {
        delete descriptions[tokenID];
    }

    /// @notice Creator can set the CSS for the svg
    /// E.g. `.r-3-3{fill:magenta} would make the pixel at (3,3) magenta
    /// @param tokenID the ID of the token
    /// @param style the CSS style. Double quotes will be removed.
    function setStyle(uint256 tokenID, string calldata style)
        external
        creatorOnly(tokenID)
    {
        styles[tokenID] = style;
    }

    function clearStyle(uint256 tokenID) external creatorOnly(tokenID) {
        delete styles[tokenID];
    }

    ////////////////////////////////////////////////////////////////
    //                        OWNER OPS
    ////////////////////////////////////////////////////////////////

    function setRenderer(IImageRenderer _renderer) external onlyOwner {
        renderer = _renderer;
    }

    function setRoyalty(uint16 bips) external onlyOwner {
        royaltyBips = bips;
    }

    function setExternalBaseURL(string memory _url) external onlyOwner {
        externalBaseURL = _url;
    }

    function release(address payable payee) external onlyOwner {
        (bool success, ) = payable(payee).call{value: address(this).balance}(
            ""
        );
        require(success);
    }

    function releaseERC20(ERC20 token, address payee) external onlyOwner {
        token.transfer(payee, token.balanceOf(address(this)));
    }

    ////////////////////////////////////////////////////////////////
    //                        IMAGE RENDERING
    ////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////
    //                        ERC165 LOGIC
    ////////////////////////////////////////////////////////////////

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == 0x2a55205a || // ERC165 Interface ID for ERC2981
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    ////////////////////////////////////////////////////////////////
    //                        ERC2981 LOGIC
    ////////////////////////////////////////////////////////////////

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenID - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenID
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256 _tokenID, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = creatorOf[_tokenID];
        if (receiver != address(0)) {
            royaltyAmount = (_salePrice * royaltyBips) / BIPS_PRECISION;
        }
    }

    ////////////////////////////////////////////////////////////////
    //                        MODIFIERS
    ////////////////////////////////////////////////////////////////

    modifier onlyMinted(uint256 tokenID) {
        if (creatorOf[tokenID] == address(0)) {
            revert DoesNotExist();
        }
        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
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

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

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
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
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

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
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

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
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

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

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

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

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

        /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

abstract contract Creatable {
    error CreatorOnly();

    /// @notice Creator of the token.
    mapping(uint256 => address) public creatorOf;

    /// @notice Creator can change the creator address
    /// @param tokenID the ID of the token
    /// @param newCreator the new creator address
    function setCreator(uint256 tokenID, address newCreator)
        external
        virtual
        creatorOnly(tokenID)
    {
        creatorOf[tokenID] = newCreator;
    }

    modifier creatorOnly(uint256 tokenID) {
        if (creatorOf[tokenID] != msg.sender) {
            revert CreatorOnly();
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
pragma experimental ABIEncoderV2;

import "./Sanitize.sol";
import "./Creatable.sol";
import "./IImageRenderer.sol";
import "openzeppelin/utils/Strings.sol";

contract ImageRenderer is IImageRenderer {
    using Strings for uint8;
    using Strings for uint256;
    using Sanitize for string;

    string constant DATA_URL_SVG_IMAGE = "data:image/svg+xml;utf8,";

    function imageURL(uint256 tokenID, string calldata style)
        external
        pure
        override
        returns (string memory)
    {
        return string.concat(DATA_URL_SVG_IMAGE, svg(tokenID, style));
    }

    function svg(uint256 tokenID, string memory style)
        public
        pure
        returns (string memory)
    {
        string memory s = string.concat(
            "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'>"
            "<style>svg{background:white} rect{fill:black;width:1px;height:1px} ",
            style,
            "</style>"
        );

        for (uint256 i = 0; i < 256; ++i) {
            uint256 shift = 255 - i;
            if (tokenID & (1 << shift) != 0) {
                string memory x = (i % 16).toString();
                string memory y = (i / 16).toString();
                s = string.concat(
                    s,
                    "<rect class='x",
                    x,
                    " y",
                    y,
                    "' x='",
                    x,
                    "' y='",
                    y,
                    "'/>"
                );
            }
        }
        return string.concat(s, "</svg>");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Sanitize {
    /// @notice 34 for double quote, 39 for single quote
    function sanitizeForJSON(string memory s, uint8 quote)
        internal
        pure
        returns (string memory)
    {
        bytes memory b = bytes(s);
        uint8 ch;
        for (uint256 i = 0; i < b.length; i++) {
            ch = uint8(b[i]);
            if (
                ch < 32 || // "
                ch == quote
            ) {
                b[i] = " ";
            } else {
                b[i] = bytes1(ch);
            }
        }
        return string(b);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

abstract contract IImageRenderer {
    function imageURL(uint256 tokenID, string memory style)
        external
        view
        virtual
        returns (string memory);
}
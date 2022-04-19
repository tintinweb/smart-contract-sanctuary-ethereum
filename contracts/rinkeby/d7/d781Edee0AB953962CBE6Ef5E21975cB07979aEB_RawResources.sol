// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

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
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*///////////////////////////////////////////////////////////////
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

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    event URI(string value, uint256 indexed id);

    /*///////////////////////////////////////////////////////////////
                            ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) internal _balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                             ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApproved(address account, address operator)
        public
        view
        virtual
        returns (bool)
    {
        return isApprovedForAll[account][operator];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        require(
            msg.sender == from || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        _balanceOf[from][id] -= amount;
        _balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender,
                    from,
                    id,
                    amount,
                    data
                ) == ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        for (uint256 i = 0; i < idsLength; ) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balanceOf[from][id] -= amount;
            _balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(
                    msg.sender,
                    from,
                    ids,
                    amounts,
                    data
                ) == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _balanceOfBatch(address[] memory owners, uint256[] memory ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        uint256 ownersLength = owners.length; // Saves MLOADs.

        require(ownersLength == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < ownersLength; i++) {
                balances[i] = _balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        _balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender,
                    address(0),
                    id,
                    amount,
                    data
                ) == ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            _balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(
                    msg.sender,
                    address(0),
                    ids,
                    amounts,
                    data
                ) == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            _balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal {
        _balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
interface ERC1155TokenReceiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC1155.sol";
import "./interfaces/IRAW.sol";
import "./interfaces/IRAWoriginal.sol";
import "./interfaces/IEON.sol";

contract RawResources is IRAW, ERC1155, Pausable {
    using Strings for uint256;

    struct LastWrite {
        uint64 time;
        uint64 blockNum;
    }

    // struct to store each trait's data for metadata and rendering
    struct Image {
        string name;
        string png;
    }

    struct TypeInfo {
        uint256 mints;
        uint256 burns;
        uint256 maxSupply;
        uint256 eonExchangeAmt;
    }

    mapping(uint256 => TypeInfo) private typeInfo;
    // storage of each image data
    mapping(uint256 => Image) public traitData;

    // address => allowedToCallFunctions
    mapping(address => bool) private admins;

    // Tracks the last block and timestamp that a caller has written to state.
    // Disallow some access to functions if they occur while a change is being written.
    mapping(address => LastWrite) private lastWriteAddress;

    event UpdateMintBurns(uint256 typeId, uint256 mintQty, uint256 burnQty);

    // reference to the $EON contract for exchange rate if accepted
    IEON public eon;

    // reference to the original Raw contract
    IRAWoriginal public originalRaw;

    address public auth;

    uint256 public migrated;

    constructor() {
        auth = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == auth);
        _;
    }

    /** CRITICAL TO SETUP */

    modifier requireContractsSet() {
        require(address(eon) != address(0), "Contracts not set");
        _;
    }

    modifier blockIfChangingAddress() {
        require(
            admins[msg.sender] ||
                lastWriteAddress[tx.origin].blockNum < block.number,
            "Your trying the cheat"
        );
        _;
    }

    function setContracts(address _eon, address _originalRaw)
        external
        onlyOwner
    {
        eon = IEON(_eon);
        originalRaw = IRAWoriginal(_originalRaw);
    }

    /**
     * Mint a token - any payment / game logic should be handled in the game contract.
     */
    function mint(
        uint256 typeId,
        uint256 qty,
        address recipient
    ) external override whenNotPaused {
        require(admins[msg.sender],  "Only admins");
        require(
            (typeInfo[typeId].mints + qty) <= typeInfo[typeId].maxSupply,
            "MaxSupply Minted"
        );
        typeInfo[typeId].mints += qty;
        _mint(recipient, typeId, qty, "");
    }

    /**
     * Burn a token - any payment / game logic should be handled in the game contract.
     */
    function burn(
        uint256 typeId,
        uint256 qty,
        address burnFrom
    ) external override whenNotPaused {
        require(admins[msg.sender], "Only admins");
        typeInfo[typeId].burns += qty;
        _burn(burnFrom, typeId, qty);
    }

    function setType(uint256 typeId, uint256 maxSupply) external onlyOwner {
        require(typeId != 0, "TypeId cannot be 0");
        require(typeInfo[typeId].mints <= maxSupply, "max supply too low");
        typeInfo[typeId].maxSupply = maxSupply;
    }

    // a function to update the mint and burn amounts
    // to save gas costs of doing both a mint and then
    // burn when cost is paid from an amount owed
    function updateMintBurns(
        uint256 typeId,
        uint256 mintQty,
        uint256 burnQty
    ) external {
        require(admins[msg.sender], "Only Admins");
        typeInfo[typeId].mints += mintQty;
        typeInfo[typeId].burns += burnQty;

        emit UpdateMintBurns(typeId, mintQty, burnQty);
    }

    function setExchangeAmt(uint256 typeId, uint256 exchangeAmt)
        external
        onlyOwner
    {
        require(
            typeInfo[typeId].maxSupply > 0,
            "this type has not been set up"
        );
        typeInfo[typeId].eonExchangeAmt = exchangeAmt;
    }

    function balanceOf(address tokenOwner, uint256 typeId)
        public
        view
        blockIfChangingAddress
        returns (uint256)
    {
        //Prevent chencking balance in the same block it's being modified..
        require(
            admins[msg.sender] ||
                lastWriteAddress[tokenOwner].blockNum < block.number,
            "no checking balance in the same block it's being modified"
        );
        uint256 balance = _balanceOf[tokenOwner][typeId];
        return balance;
    }
  function updateOriginAccess(address user) external override {
        require(admins[_msgSender()], "Only admins can call this");
        uint64 blockNum = uint64(block.number);
        uint64 time = uint64(block.timestamp);
        lastWriteAddress[user] = LastWrite(time, blockNum);
  }
    /**
     * creates identical tokens in the new contract
     * and burns any original tokens
     * @param typeId the type of the tokens to migrate
     */
    function migrate(uint256 typeId) external whenNotPaused {
        uint256 amount = originalRaw.getBalance(msg.sender, typeId);
        require(amount > 0, "no tokens to migrate");
        originalRaw.burn(typeId, amount, msg.sender);
        _mint(msg.sender, typeId, amount, "");
        migrated += amount;
    }

    /**
     * enables an address to mint / burn
     * @param addr the address to enable
     */
    function addAdmin(address addr) external onlyOwner {
        admins[addr] = true;
    }

    /**
     * disables an address from minting / burning
     * @param addr the address to disbale
     */
    function removeAdmin(address addr) external onlyOwner {
        admins[addr] = false;
    }

    function setPaused(bool _paused) external onlyOwner requireContractsSet {
        if (_paused) _pause();
        else _unpause();
    }

    function transferOwnership(address newOwner) external onlyOwner {
        auth = newOwner;
    }

    function getInfoForType(uint256 typeId)
        external
        view
        returns (TypeInfo memory)
    {
        require(typeInfo[typeId].maxSupply > 0, "invalid type");
        return typeInfo[typeId];
    }

    function uri(uint256 typeId) public view override returns (string memory) {
        require(typeInfo[typeId].maxSupply > 0, "invalid type");
        Image memory img = traitData[typeId];
        string memory metadata = string(
            abi.encodePacked(
                '{"name": "',
                img.name,
                '", "description": "Raw Pytheas resources - All the metadata and images are generated and stored 100% on-chain. No IPFS. NO API. Just the Ethereum blockchain.", "image": "data:image/svg+xml;base64,',
                base64(bytes(drawSVG(typeId))),
                '", "attributes": []',
                "}"
            )
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    base64(bytes(metadata))
                )
            );
    }

    function uploadImage(uint256 typeId, Image calldata image)
        external
        onlyOwner
    {
        traitData[typeId] = Image(image.name, image.png);
    }

    function drawImage(Image memory image)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<image x="0" y="0" width="64" height="64" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                    image.png,
                    '"/>'
                )
            );
    }

    function drawSVG(uint256 typeId) internal view returns (string memory) {
        string memory svgString = string(
            abi.encodePacked(drawImage(traitData[typeId]))
        );

        return
            string(
                abi.encodePacked(
                    '<svg id="rawResources" width="100%" height="100%" version="1.1" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                    svgString,
                    "</svg>"
                )
            );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override(ERC1155, IRAW) {
        require(lastWriteAddress[from].blockNum < block.number, "no overwriting");
        // allow admin contracts to send without approval
        if (!admins[msg.sender]) {
            require(
                msg.sender == from || isApprovedForAll[from][msg.sender],
                "NOT_AUTHORIZED"
            );
        }
        _balanceOf[from][id] -= amount;
        _balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender,
                    from,
                    id,
                    amount,
                    data
                ) == ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override(ERC1155, IRAW) {
         require(lastWriteAddress[from].blockNum < block.number, "no overwriting");
        // allow admin contracts to send without approval
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        // allow admin contracts to send without approval
        if (!admins[msg.sender]) {
            require(
                msg.sender == from || isApprovedForAll[from][msg.sender],
                "NOT_AUTHORIZED"
            );
        }

        for (uint256 i = 0; i < idsLength; ) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balanceOf[from][id] -= amount;
            _balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }
        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(
                    msg.sender,
                    from,
                    ids,
                    amounts,
                    data
                ) == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /** BASE 64 - Written by Brech Devos */

    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function base64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
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

    // For OpenSeas
    function owner() public view virtual returns (address) {
        return auth;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEON {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface IRAW {

      function updateOriginAccess(address user) external;


    function balanceOf(
        address account,
        uint256 id
    ) external returns(uint256);

    function mint(
        uint256 typeId,
        uint256 qty,
        address recipient
    ) external;

    function burn(
        uint256 typeId,
        uint256 qty,
        address burnFrom
    ) external;

    function updateMintBurns(
        uint256 typeId,
        uint256 mintQty,
        uint256 burnQty
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface IRAWoriginal {

    function getBalance(
        address account,
        uint256 id
    ) external returns(uint256);

    function mint(
        uint256 typeId,
        uint256 qty,
        address recipient
    ) external;

    function burn(
        uint256 typeId,
        uint256 qty,
        address burnFrom
    ) external;

    function updateMintBurns(
        uint256 typeId,
        uint256 mintQty,
        uint256 burnQty
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

}
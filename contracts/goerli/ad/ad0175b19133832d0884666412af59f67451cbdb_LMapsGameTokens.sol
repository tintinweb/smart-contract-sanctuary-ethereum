// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {Owned} from "solmate/auth/Owned.sol";
import {ERC1155} from "solmate/tokens/ERC1155.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {ILMapsGameTokens} from "./interfaces/ILMapsGameTokens.sol";
import {IMetadata} from "./interfaces/IMetadata.sol";

/// @title Legend Maps Game Tokens
/// @author Legend Maps
/// @notice ERC1155 ownership contract for Legend Maps in-game items, such as gold and power ups.
///         Features:
///           - Approved operator contracts who can issue and spend player tokens e.g.
///             spending gold on power ups.
///           - Upgradable metadata renderer.
contract LMapsGameTokens is ILMapsGameTokens, ERC1155, Owned, ReentrancyGuard {
    /* ------------------------------------------------------------------------
       S T O R A G E
    ------------------------------------------------------------------------ */

    /// @dev The token id of the main in game currency. Exposed by a getter function.
    uint256 private constant GOLD_TOKEN_ID = 1;

    /// @dev Fallback contract metadata. Can be overridden by `uri`.
    string public name;
    string public symbol;
    uint256 public decimals;

    /// @dev Separate upgradable metadata contract
    IMetadata public metadata;

    /// @notice Operators can issue and spend player tokens
    /// @dev New operators can be added over time to support future game development
    mapping(address => bool) public approvedOperators;

    /* ------------------------------------------------------------------------
       E R R O R S
    ------------------------------------------------------------------------ */

    /// @dev Trying to do something you're not allowed to do
    error NotAuthorized();

    /// @dev Used when there's not enough spending balance for a transaction
    error InsufficientBalance();

    /* ------------------------------------------------------------------------
       M O D I F I E R S
    ------------------------------------------------------------------------ */

    /// @dev Only allows an approved operator contract to call the function
    modifier onlyApprovedOperator() {
        if (!approvedOperators[msg.sender]) revert NotAuthorized();
        _;
    }

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    /// @param owner The owner of the contract upon creation. Can be set later with `setOwner`.
    /// @param name_ The fallback name of the contract
    /// @param symbol_ The fallback symbol of the contract
    /// @param metadata_ The address of the upgradable metadata contract
    constructor(
        address owner,
        string memory name_,
        string memory symbol_,
        address metadata_
    ) ERC1155() Owned(owner) {
        name = name_;
        symbol = symbol_;
        decimals = 0;
        metadata = IMetadata(metadata_);
    }

    /* ------------------------------------------------------------------------
       I S S U I N G   &   S P E N D I N G
    ------------------------------------------------------------------------ */

    /// @notice Issue an amount of specific tokens to a player e.g. 100 gold
    /// @dev Can only be called by an approved operator
    /// @param id The id of the token to issue
    /// @param amount The amount of the token to issue
    /// @param player The address of the player who should receive the tokens
    function issueTokens(
        uint256 id,
        uint256 amount,
        address player
    ) external nonReentrant onlyApprovedOperator {
        if (amount > 0) {
            _mint(player, id, amount, "");
        }
    }

    /// @notice Issue a batch of different tokens to a player e.g. 100 gold and 500 silver
    /// @dev Can only be called by an approved operator.
    ///      `ids` and `amounts` must be the same length.
    /// @param ids The list of token ids to issue
    /// @param amounts The list of amounts of each token to issue
    /// @param player The address of the player who should receive the tokens
    function issueTokensBatch(
        uint256[] memory ids,
        uint256[] memory amounts,
        address player
    ) external nonReentrant onlyApprovedOperator {
        _batchMint(player, ids, amounts, "");
    }

    /// @notice Spends an amount of specific tokens from a player's balance e.g. 100 gold
    /// @dev Can only be called by an approved operator
    /// @param id The id of the token to spend
    /// @param amount The amount of the token to spend
    /// @param player The address of the player who's spending the tokens
    function spendTokens(
        uint256 id,
        uint256 amount,
        address player
    ) external nonReentrant onlyApprovedOperator {
        // Revert if the player doesn't have enough tokens to spend
        if (balanceOf[player][id] < amount) revert InsufficientBalance();

        if (amount > 0) {
            _burn(player, id, amount);
        }
    }

    /// @notice Spend a batch of different tokens from a player e.g. 100 gold and 500 silver
    /// @dev Can only be called by an approved operator.
    ///      `ids` and `amounts` must be the same length.
    /// @param ids The list of token ids to spend
    /// @param amounts The list of amounts of each token to spend
    /// @param player The address of the player who's spending the tokens
    function spendTokensBatch(
        uint256[] memory ids,
        uint256[] memory amounts,
        address player
    ) external nonReentrant onlyApprovedOperator {
        uint256 idsLength = ids.length;
        for (uint256 i = 0; i < idsLength; ) {
            // Revert if the player doesn't have enough tokens to spend
            if (balanceOf[player][ids[i]] < amounts[i]) revert InsufficientBalance();
            unchecked {
                ++i;
            }
        }
        _batchBurn(player, ids, amounts);
    }

    /* ------------------------------------------------------------------------
       A D M I N
    ------------------------------------------------------------------------ */

    /// @notice Add an operator contract that can issue and spend player tokens
    /// @dev Only callable by this contracts owner
    /// @param operator The contract address of the new operator
    function addApprovedOperator(address operator) external onlyOwner {
        approvedOperators[operator] = true;
    }

    /// @notice Remove an operator contract that can currently issue and spend player tokens
    /// @dev Only callable by this contracts owner
    /// @param operator The contract address of the existing operator
    function removeApprovedOperator(address operator) external onlyOwner {
        delete approvedOperators[operator];
    }

    /// @notice Sets the metadata contract
    /// @param metadataContract The new address for the metadata contract
    function setMetadataContract(address metadataContract) external onlyOwner {
        metadata = IMetadata(metadataContract);
    }

    /* ------------------------------------------------------------------------
       G E T T E R S
    ------------------------------------------------------------------------ */

    /// @notice Gets the token id used for the main in game currency
    function getGoldTokenId() external pure returns (uint256) {
        return GOLD_TOKEN_ID;
    }

    /* ------------------------------------------------------------------------
       E R C - 1 1 5 5
    ------------------------------------------------------------------------ */

    function uri(uint256 id) public view virtual override returns (string memory) {
        return metadata.uri(id);
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

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

interface ILMapsGameTokens {
    function issueTokens(
        uint256 id,
        uint256 amount,
        address player
    ) external;

    function issueTokensBatch(
        uint256[] memory ids,
        uint256[] memory amounts,
        address player
    ) external;

    function spendTokens(
        uint256 id,
        uint256 amount,
        address player
    ) external;

    function spendTokensBatch(
        uint256[] memory ids,
        uint256[] memory amounts,
        address player
    ) external;

    function getGoldTokenId() external pure returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

interface IMetadata {
    function uri(uint256 id) external view returns (string memory);
}
// SPDX-License-Identifier: APGL-3.0-only
pragma solidity >=0.8.0;

import {Ownable} from "./Ownable.sol";
import {ERC1155} from "./solmate/tokens/ERC1155.sol";

/// @title ElyGenesisCollection
/// @notice Minting contract for Ely's Genesis Collection (https://twitter.com/ratkingnft).
/// @author 0xMetas (https://twitter.com/0xMetas)
contract ElyGenesisCollection is ERC1155, Ownable {
    //////////////////////
    /// External State ///
    //////////////////////

    /// @notice The name of the contract.
    /// @dev EIP-1155 doesn't define `name()` so that the metadata JSON returned by `uri` is
    /// the definitive name, but it's provided for compatibility with existing front-ends.
    string public constant name = "Ely Genesis Collection"; // solhint-disable-line const-name-snakecase

    /// @notice The symbol of the contract.
    /// @dev EIP-1155 doesn't define `symbol()` because it isn't a "globally useful piece of
    /// data", but, again, it's provided for compatibility with existing front-ends.
    string public constant symbol = "ELYGENESIS"; // solhint-disable-line const-name-snakecase

    /// @notice The price of each token.
    uint256 public constant PRICE = 0.05 ether;

    /// @notice The maximum supply of all tokens.
    uint256 public constant MAX_SUPPLY = 500;

    /// @notice The maximum supply of each token.
    uint256 public constant MAX_SUPPLY_PER_ID = 100;

    /// @notice True if the metadata (URI) can no longer be modified.
    bool public metadataFrozen = false;

    /// @notice The maximum number of tokens you can purchase in a single transaction.
    uint256 public transactionLimit = 3;

    /// @notice True if the sale is open.
    bool public purchaseable = false;

    /// @notice The total supply of all tokens.
    /// @dev EIP-1155 requires enumeration off-chain, but the contract provides `totalSupplyAll`
    /// for convenience, and compatibility with marketplaces and other front-ends.
    uint256 public totalSupplyAll = 0;

    /// @notice The total supply of an individual token.
    /// @dev See `totalSupplyAll`.
    uint8[5] public totalSupply;

    //////////////////////
    /// Internal State ///
    //////////////////////

    /// @dev The ids available to mint. This array is used when generating a random index for the mint.
    /// Ids are removed from this array when their max amount has been minted.
    uint8[] private availableIds = [0, 1, 2, 3, 4];

    /// @dev The 'dynamic' length of the `availableIds` array. Since it's a static array, it's actual
    /// length cannot be modified, so this variable is used instead.
    uint8 private availableIdsLength = 5;

    /// @dev The base of the generated URI returned by `uri(uint256)`.
    string private baseUri;

    //////////////
    /// Errors ///
    //////////////

    error WithdrawFail();
    error FrozenMetadata();
    error NotPurchaseable();
    error SoldOut();
    error InsufficientValue();
    error InvalidPurchaseAmount();
    error ExternalAccountOnly();

    //////////////
    /// Events ///
    //////////////

    event PermanentURI(string uri, uint256 indexed id);
    event Purchaseable(bool state);
    event TransactionLimit(uint256 previousLimit, uint256 newLimit);

    // solhint-disable-next-line no-empty-blocks
    constructor() {}

    /// @notice Purchase `amount` number of tokens.
    /// @param amount The number of tokens to purchase.
    function purchase(uint256 amount) public payable {
        if (!purchaseable) revert NotPurchaseable();
        if (amount + totalSupplyAll > MAX_SUPPLY) revert SoldOut();
        if (msg.value != amount * PRICE) revert InsufficientValue();
        if (msg.sender.code.length != 0) revert ExternalAccountOnly();
        if (amount > transactionLimit || amount < 1)
            revert InvalidPurchaseAmount();

        for (uint256 i; i < amount; ) {
            uint256 idx = getPseudorandom() % availableIdsLength;
            uint256 id = availableIds[idx];

            _mint(msg.sender, id, 1, "");

            // `totalSupplyAll` needs to be incremented in the loop to provide a unique nonce for
            // each call to `getPseudorandom()`.
            unchecked {
                ++i;
                ++totalSupplyAll;
                ++totalSupply[id];
            }

            // Remove the token from `availableIds` if it's reached the supply limit
            if (totalSupply[id] == MAX_SUPPLY_PER_ID) removeIndex(idx);
        }
    }

    /// @notice Returns a deterministically generated URI for the given token ID.
    /// @return string
    function uri(uint256 id) public view override returns (string memory) {
        return
            bytes(baseUri).length > 0
                ? string(abi.encodePacked(baseUri, toString(id), ".json"))
                : "";
    }

    //////////////////////
    /// Administration ///
    //////////////////////

    /// @notice Prevents any future changes to the URI of any token ID.
    /// @dev Emits a `PermanentURI(string, uint256 indexed)` event for each token ID with the permanent URI.
    function freezeMetadata() public onlyOwner {
        metadataFrozen = true;
        for (uint256 i = 0; i < 5; ++i) {
            emit PermanentURI(uri(i), i);
        }
    }

    /// @notice Updates the base of the generated URI returned by `uri(uint256)`.
    /// @dev The URI event isn't emitted because there is no applicable ID to emit the event for. The
    /// baseURI given here applies to all token IDs.
    function setBaseUri(string memory newBaseUri) public onlyOwner {
        if (metadataFrozen == true) revert FrozenMetadata();
        baseUri = newBaseUri;
    }

    /// @notice Sets the current state of the sale. `false` will disable sale, `true` will enable it.
    function setPurchaseable(bool state) public onlyOwner {
        purchaseable = state;
        emit Purchaseable(purchaseable);
    }

    /// @notice Withdraws entire balance of this contract to the `owner` address.
    function withdrawEth() public onlyOwner {
        (bool success, ) = owner.call{value: address(this).balance}("");
        if (!success) revert WithdrawFail();
    }

    /// @notice Sets the maximum purchase amount per transaction.
    function setTransactionLimit(uint256 newTransactionLimit) public onlyOwner {
        emit TransactionLimit(transactionLimit, newTransactionLimit);
        transactionLimit = newTransactionLimit;
    }

    ////////////////
    /// Internal ///
    ////////////////

    /// @dev Generates a pseudorandom number to use when determining an ID for purchase. True randomness isn't
    /// necessary because IDs have no rarity (no ID is inherently more valuable than another).
    function getPseudorandom() internal view returns (uint256) {
        // solhint-disable not-rely-on-time
        unchecked {
            return
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            msg.sender,
                            totalSupplyAll
                        )
                    )
                );
        }
        // solhint-enable not-rely-on-time
    }

    /// @dev Removes the specified index from the `availableIds` array. This function is used when the max supply
    /// of the token ID at `index` has already been purchased. The index isn't checked because useage is internal.
    function removeIndex(uint256 index) internal {
        availableIds[index] = availableIds[availableIdsLength - 1];
        availableIdsLength--;
    }

    /// @dev Taken from OpenZeppelin's implementation
    /// (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol)
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

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*///////////////////////////////////////////////////////////////
                            ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

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

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
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
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        for (uint256 i = 0; i < idsLength; ) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

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
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] memory owners, uint256[] memory ids)
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
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
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
    ) internal {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

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
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
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
            balanceOf[from][ids[i]] -= amounts[i];

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
        balanceOf[from][id] -= amount;

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

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

/// @title Ownable
/// @notice Provides a modifier to authenticate contract owner.
/// @dev The default owner is the contract deployer, but this can be modified
/// afterwards using `transferOwnership`. There is no check when transferring
/// ownership so ensure you don't use `address(0)` unintentionally. The modifier
/// to guard functions with is `onlyOwner`.
/// @author 0xMetas
/// @author Based on OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol)
abstract contract Ownable {
    /// @notice This emits when the owner changes.
    /// @param previousOwner The address of the previous owner.
    /// @param newOwner The address of the new owner.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @dev Error thrown when `onlyOwner` is called by an address other than `owner`.
    error NotOwner();

    /// @notice The address of the owner.
    address public owner;

    /// @dev Sets the value of `owner` to `msg.sender`.
    constructor() {
        owner = msg.sender;
    }

    /// @dev Reverts if `msg.sender` is not `owner`.
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /// @notice Sets the `owner` address to a new one.
    /// @dev Use `address(0)` to renounce ownership.
    /// @param newOwner The address of the new owner of the contract.
    function transferOwnership(address newOwner) external onlyOwner {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
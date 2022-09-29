// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import { IViewERC721_Functions } from "./interfaces/IViewERC721.sol";

import { IERC721OpenSea } from "./interfaces/IERC721OpenSea.sol";

// prettier-ignore
import {
    V721_BalanceCollection,
    V721_BalanceData,
    V721_ContractData,
    V721_ErrorData,
    V721_TokenCollection,
    V721_TokenData,
    IViewERC721_Events,
    IViewERC721_Functions
} from "./interfaces/IViewERC721.sol";

/// @title On-chain functions to collect contract data for off-chain callers
/// @author S0AndS0
/// @custom:link https://boredbox.io/
contract ViewERC721 is IViewERC721_Events, IViewERC721_Functions {
    /// Owner of this contract instance
    address public owner;

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑            Storage          ↑ */
    /* ↓  Modifiers and constructor  ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /// Require message sender to be instance owner
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    //
    constructor(address owner_) {
        owner = owner_ == address(0) ? msg.sender : owner_;
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑  Modifiers and constructor  ↑ */
    /* ↓      mutations external     ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /// @dev See {IViewERC721_Functions-transferOwnership}
    function transferOwnership(address newOwner) external payable virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /// @dev See {IViewERC721_Functions-withdraw}
    function withdraw(address payable to, uint256 amount) external payable virtual onlyOwner {
        (bool success, ) = to.call{ value: amount }("");
        require(success, "Transfer failed");
    }

    /// @dev see (IViewERC721_Functions-tip)
    function tip() external payable virtual {}

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑      mutations external     ↑ */
    /* ↓            public           ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /// @dev See {IViewERC721_Functions-getTokenData}
    function getTokenData(address ref, uint256 tokenId) public view returns (V721_TokenData memory) {
        V721_TokenData memory token_data;
        token_data.id = tokenId;

        try IERC721OpenSea(ref).ownerOf(tokenId) returns (address token_owner) {
            token_data.owner = token_owner;
        } catch Error(string memory reason) {
            token_data.errors = _appendErrorData(
                token_data.errors,
                V721_ErrorData({ called: "ownerOf", reason: reason })
            );
        } catch (bytes memory reason) {
            token_data.errors = _appendErrorData(
                token_data.errors,
                V721_ErrorData({ called: "ownerOf", reason: string(reason) })
            );
        }

        try IERC721OpenSea(ref).getApproved(tokenId) returns (address approved) {
            token_data.approved = approved;
        } catch Error(string memory reason) {
            token_data.errors = _appendErrorData(
                token_data.errors,
                V721_ErrorData({ called: "approved", reason: reason })
            );
        } catch (bytes memory reason) {
            token_data.errors = _appendErrorData(
                token_data.errors,
                V721_ErrorData({ called: "approved", reason: string(reason) })
            );
        }

        try IERC721OpenSea(ref).tokenURI(tokenId) returns (string memory uri) {
            token_data.uri = uri;
        } catch Error(string memory reason) {
            token_data.errors = _appendErrorData(
                token_data.errors,
                V721_ErrorData({ called: "tokenURI", reason: reason })
            );
        } catch (bytes memory reason) {
            token_data.errors = _appendErrorData(
                token_data.errors,
                V721_ErrorData({ called: "tokenURI", reason: string(reason) })
            );
        }

        return token_data;
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑            public           ↑ */
    /* ↓       internal mutations    ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /// @dev See {ViewERC721-transferOwnership}
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = owner;
        owner = newOwner;

        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑       internal mutations    ↑ */
    /* ↓       internal viewable     ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /// @dev Note this is a sub-optimal workaround for fixed sized memory arrays
    function _appendErrorData(V721_ErrorData[] memory target, V721_ErrorData memory entry)
        internal
        pure
        virtual
        returns (V721_ErrorData[] memory)
    {
        uint256 length = target.length;

        V721_ErrorData[] memory result = new V721_ErrorData[](length + 1);
        uint256 index;
        while (index < length) {
            result[index] = target[index];
            unchecked {
                ++index;
            }
        }

        result[index] = entry;

        return result;
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑       internal viewable     ↑ */
    /* ↓       external viewable     ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /// @dev See {IViewERC721_Functions-balancesOf}
    function balancesOf(address ref, address[] memory accounts) external view returns (V721_BalanceCollection memory) {
        uint256 length = accounts.length;
        V721_BalanceCollection memory account_balances;
        account_balances.ref = ref;
        account_balances.time.start = block.timestamp;
        account_balances.accounts = new V721_BalanceData[](length);

        V721_BalanceData memory balance_data;
        for (uint256 i; i < length; ) {
            address account = accounts[i];
            balance_data = account_balances.accounts[i];
            balance_data.owner = account;
            balance_data.balance = IERC721OpenSea(ref).balanceOf(account);
            unchecked {
                ++i;
            }
        }

        account_balances.time.stop = block.timestamp;
        return account_balances;
    }

    /// @dev See {IViewERC721_Functions-dataOfTokenIds}
    function dataOfTokenIds(address ref, uint256[] memory tokenIds)
        external
        view
        returns (V721_TokenCollection memory)
    {
        uint256 limit = tokenIds.length;

        V721_TokenCollection memory token_collection;
        token_collection.ref = ref;
        token_collection.length = limit;
        token_collection.time.start = block.timestamp;
        token_collection.tokens = new V721_TokenData[](limit);

        for (uint256 i; i < limit; ) {
            token_collection.tokens[i] = getTokenData(ref, tokenIds[i]);
            unchecked {
                ++i;
            }
        }

        token_collection.time.stop = block.timestamp;

        return token_collection;
    }

    /// @dev See {IViewERC721_Functions-paginateTokens}
    function paginateTokens(
        address ref,
        uint256 tokenId,
        uint256 limit
    ) external view returns (V721_TokenCollection memory) {
        V721_TokenCollection memory token_collection;
        token_collection.ref = ref;
        token_collection.length = limit;
        token_collection.time.start = block.timestamp;
        token_collection.tokens = new V721_TokenData[](limit);

        for (uint256 i; i < limit; ) {
            token_collection.tokens[i] = getTokenData(ref, tokenId);
            unchecked {
                ++i;
                ++tokenId;
            }
        }

        token_collection.time.stop = block.timestamp;

        return token_collection;
    }

    /// @dev See {IViewERC721_Functions-paginateTokensOwnedBy}
    function paginateTokensOwnedBy(
        address ref,
        address account,
        uint256 tokenId,
        uint256 limit
    ) external view returns (V721_TokenCollection memory) {
        V721_TokenCollection memory token_collection;
        token_collection.ref = ref;
        token_collection.time.start = block.timestamp;

        uint256 balance = IERC721OpenSea(ref).balanceOf(account);
        token_collection.tokens = new V721_TokenData[](balance);

        uint256 index;
        uint256 last__tokenId = tokenId + limit;
        V721_TokenData memory token_data;
        while (tokenId < last__tokenId) {
            token_data = getTokenData(ref, tokenId);
            if (token_data.owner == account) {
                token_collection.tokens[index] = token_data;

                unchecked {
                    ++index;
                }
            }

            unchecked {
                ++tokenId;
            }
        }

        token_collection.length = index;
        token_collection.time.stop = block.timestamp;

        return token_collection;
    }

    /// @dev See {IViewERC721_Functions-getContractData}
    function getContractData(address ref) external view returns (V721_ContractData memory) {
        V721_ContractData memory contract_data;

        try IERC721OpenSea(ref).name() returns (string memory name) {
            contract_data.name = name;
        } catch Error(string memory reason) {
            contract_data.errors = _appendErrorData(
                contract_data.errors,
                V721_ErrorData({ called: "name", reason: reason })
            );
        } catch (bytes memory reason) {
            contract_data.errors = _appendErrorData(
                contract_data.errors,
                V721_ErrorData({ called: "name", reason: string(reason) })
            );
        }

        try IERC721OpenSea(ref).symbol() returns (string memory symbol) {
            contract_data.symbol = symbol;
        } catch Error(string memory reason) {
            contract_data.errors = _appendErrorData(
                contract_data.errors,
                V721_ErrorData({ called: "symbol", reason: reason })
            );
        } catch (bytes memory reason) {
            contract_data.errors = _appendErrorData(
                contract_data.errors,
                V721_ErrorData({ called: "symbol", reason: string(reason) })
            );
        }

        try IERC721OpenSea(ref).contractURI() returns (string memory uri) {
            contract_data.uri = uri;
        } catch Error(string memory reason) {
            contract_data.errors = _appendErrorData(
                contract_data.errors,
                V721_ErrorData({ called: "contractURI", reason: reason })
            );
        } catch (bytes memory reason) {
            contract_data.errors = _appendErrorData(
                contract_data.errors,
                V721_ErrorData({ called: "contractURI", reason: string(reason) })
            );
        }

        return contract_data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/// @custom:property name - Contract name retrieved via `IERC721Metadata(ref).name()`
/// @custom:property symbol - Contract symbol retrieved via `IERC721Metadata(ref).symbol()`
/// @custom:property uri - Contract uri retrieved via `IERC721OpenSea(ref).contractURI()`
/// @custom:property errors - Array of `V721_ErrorData` data structures
struct V721_ContractData {
    string name;
    string symbol;
    string uri;
    V721_ErrorData[] errors;
}

/// @custom:property start - Block timestamp when request(s) started
/// @custom:property stop - Block timestamp when request(s) stoped
struct V721_TimeData {
    uint256 start;
    uint256 stop;
}

/// @custom:property called - Name of function that threw an error
/// @custom:property reason - Original error message caught
struct V721_ErrorData {
    string called;
    string reason;
}

/// @custom:property ref - Reference to contract
/// @custom:property length - May be less than `tokens.length` if results were pre-filtered
/// @custom:property time - Block timestamps when request(s) started and stopped
/// @custom:property tokens - List of token data
struct V721_TokenCollection {
    address ref;
    uint256 length;
    V721_TimeData time;
    V721_TokenData[] tokens;
}

/// @custom:property owner - Token owner
/// @custom:property approved - Account approved to transfer token
/// @custom:property id - Token ID
/// @custom:property uri - URI of token
/// @custom:property errors - Array of `V721_ErrorData` data structures
struct V721_TokenData {
    address owner;
    address approved;
    uint256 id;
    string uri;
    V721_ErrorData[] errors;
}

/// @custom:property ref - Reference to contract
/// @custom:property time - Block timestamps when request(s) started and stoped
/// @custom:property accounts - List of account balances
struct V721_BalanceCollection {
    address ref;
    V721_TimeData time;
    V721_BalanceData[] accounts;
}

/// @custom:property owner - Token owner
struct V721_BalanceData {
    address owner;
    uint256 balance;
}

/* Events definitions */
interface IViewERC721_Events {
    /// @dev See {Ownable-OwnershipTransferred}
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

/* Function definitions */
interface IViewERC721_Functions {
    /// Overwrite instance owner
    /// @param newOwner - Address to assign as instance owner
    ///
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = { newOwner: '0x0...9042' };
    ///
    /// const tx = { from: await instance.methods.owner().call() };
    ///
    /// await instance.methods.transferOwnership(...Object.values(parameters)).send(tx);
    ///
    /// console.assert(await instance.methods.owner() != tx.from);
    ///
    /// console.assert(await instance.methods.owner() == parameters.newOwner);
    /// ```
    function transferOwnership(address newOwner) external payable;

    /// Set full URI URL for `tokenId` without affecting branch data
    /// @param to - Account that will receive `amount`
    /// @param amount - Quantity of Wei to send to account
    ///
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = {
    ///   to: '0x0...9023',
    ///   amount: await web3.eth.getBalance(instance.address),
    /// };
    ///
    /// const tx = { from: await instance.methods.owner().call() };
    ///
    /// await instance.methods.withdraw(...Object.values(parameters)).send(tx);
    /// ```
    function withdraw(address payable to, uint256 amount) external payable;

    /// Allow anyone to show appreciation for publishers of this instance
    ///
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const tx = {
    ///   from: '0x0...675309',
    ///   value: 41970,
    /// };
    ///
    /// await instance.methods.tip().send(tx);
    /// ```
    function tip() external payable;

    /// Collect available information for given `ref`
    /// @param ref - Address for contract that implements ERC721
    /// @dev This function should never throw an error, and should use `try`/`catch` internally
    ///
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = { ref: '0x09d05293264eDF390CD3cbd8cc86532207AE30b0' };
    ///
    /// const metadata = await instance.methods.getContractData(...Object.values(parameters)).call();
    ///
    /// const keys = ['name', 'symbol', 'uri', 'errors'];
    /// const data = Object.fromEntries(keys.map(key => [key, metadata[key]]));
    ///
    /// console.log(JSON.stringify(data, null, 2));
    /// ```
    ///
    /// ## Example `data`
    ///
    /// ```json
    /// {
    ///   "name": "BoredBoxNFT",
    ///   "symbol": "BB",
    ///   "uri": "",
    ///   "errors": [
    ///        {
    ///          called: 'contractURI',
    ///          reason: '',
    ///        },
    ///   ],
    /// }
    /// ```
    function getContractData(address ref) external view returns (V721_ContractData memory);

    /// Collect available information for given `tokenId`
    /// @param ref - Address for contract that implements ERC721
    /// @param tokenId - ID of token to retrieve data
    /// @dev This function should never throw an error, and should use `try`/`catch` internally
    ///
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = {
    ///   ref: '0x09d05293264eDF390CD3cbd8cc86532207AE30b0',
    ///   tokenId: 1,
    /// };
    ///
    /// const token = await instance.methods.getTokenData(...Object.values(parameters)).call();
    ///
    /// const keys = ['id', 'owner', 'approved', 'uri', 'errors'];
    /// const data = Object.fromEntries(keys.map(key => [key, token[key]]));
    ///
    /// console.log(JSON.stringify(data, null, 2));
    /// ```
    ///
    /// ## Example `data`
    ///
    /// ```json
    /// {
    ///   "id": "1",
    ///   "owner": "0x1c6c6289d08C9A6Ab78618c04514DFa5d194603B",
    ///   "approved": "0x0000000000000000000000000000000000000000",
    ///   "uri": "ipfs://0xDEADBEEF/1.json",
    ///   "errors": []
    /// }
    /// ```
    function getTokenData(address ref, uint256 tokenId) external view returns (V721_TokenData memory);

    /// Collect balances for listed `accounts`
    /// @param ref - Address for contract that implements ERC721
    /// @param accounts - Array of addresses to collect balance information
    ///
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = {
    ///   ref: '0x09d05293264eDF390CD3cbd8cc86532207AE30b0',
    ///   accounts: ['0x0...BOBACAFE', '0x0...8BADF00D'],
    /// };
    ///
    /// const { accounts } = await instance.methods.balancesOf(...Object.values(parameters)).call();
    ///
    /// const keys = ['owner', 'balance'];
    /// const data = accounts.map(balance => Object.fromEntries(keys.map(key => [key, balance[key]])));
    ///
    /// console.log(JSON.stringify(data, null, 2));
    /// ```
    ///
    /// ## Example `data`
    ///
    /// ```json
    /// {
    ///   "owner": "0x0...BOBACAFE",
    ///   "balance": 419
    /// },
    /// {
    ///   "owner": "0x0...8BADF00D",
    ///   "balance": 70
    /// }
    /// ```
    function balancesOf(address ref, address[] memory accounts) external view returns (V721_BalanceCollection memory);

    /// Get data for list of token IDs
    /// @param ref - Address for contract that implements ERC721
    /// @param tokenIds - Token IDs to collect data
    ///
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = {
    ///   ref: '0x09d05293264eDF390CD3cbd8cc86532207AE30b0',
    ///   tokenIds: [1, 70, 419, 8675310],
    /// };
    ///
    /// const tx = {
    ///   transactionObject: {},
    ///   blockNumber: await web3.eth.getBlockNumber(),
    /// };
    ///
    /// const { tokens } = await instance
    ///   .methods
    ///   .dataOfTokenIds(...Object.values(parameters))
    ///   .call(...Object.values(tx));
    ///
    /// const keys = ['id', 'owner', 'approved', 'uri', 'errors'];
    /// const data = tokens.map(token => Object.fromEntries(keys.map(key => [key, token[key]])));
    ///
    /// console.log(JSON.stringify(data, null, 2));
    /// ```
    ///
    /// ## Example `data`
    ///
    /// ```json
    /// [
    ///   {
    ///     "id": "1",
    ///     "owner": "0x0...BOBACAFE",
    ///     "approved": "0x0000000000000000000000000000000000000000",
    ///     "uri": "ipfs://0xDEADBEEF/1.json",
    ///     "errors": []
    ///   },
    ///   { "..." },
    ///   {
    ///     "id": "8675310",
    ///     "owner": "0x0000000000000000000000000000000000000000",
    ///     "approved": "0x0000000000000000000000000000000000000000",
    ///     "uri": "",
    ///     "errors": [
    ///        {
    ///          called: 'ownerOf',
    ///          reason: 'ERC721: owner query for nonexistent token',
    ///        },
    ///        { "..." },
    ///        {
    ///          called: 'tokenURI',
    ///          reason: 'ERC721Metadata: URI query for nonexistent token',
    ///        },
    ///     ]
    ///   },
    /// ]
    /// ```
    function dataOfTokenIds(address ref, uint256[] memory tokenIds) external view returns (V721_TokenCollection memory);

    /// Get page of token data
    /// @param ref - Address for contract that implements ERC721
    /// @param tokenId - Where to start collecting token data
    /// @param limit - Maximum quantity of tokens to collect data
    /// @dev It is a good idea when paginating data to utilize a common block number between calls
    ///
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = {
    ///   ref: '0x09d05293264eDF390CD3cbd8cc86532207AE30b0',
    ///   tokenId: 1,
    ///   limit: 1000,
    /// };
    ///
    /// const tx = {
    ///   transactionObject: {},
    ///   blockNumber: await web3.eth.getBlockNumber(),
    /// };
    ///
    /// const { tokens } = await instance
    ///   .methods
    ///   .paginateTokens(...Object.values(parameters))
    ///   .call(...Object.values(tx));
    ///
    /// const keys = ['id', 'owner', 'approved', 'uri', 'errors'];
    /// const data = tokens.map(token => Object.fromEntries(keys.map(key => [key, token[key]])));
    ///
    /// console.log(JSON.stringify(data, null, 2));
    /// ```
    ///
    /// ## Example `data`
    ///
    /// ```json
    /// [
    ///   {
    ///     "id": "1",
    ///     "owner": "0x0...BOBACAFE",
    ///     "approved": "0x0000000000000000000000000000000000000000",
    ///     "uri": "ipfs://0xDEADBEEF/1.json",
    ///     "errors": []
    ///   },
    ///   { "..." },
    ///   {
    ///     "id": "1000",
    ///     "owner": "0x0...8BADF00D",
    ///     "approved": "0x0000000000000000000000000000000000000000",
    ///     "uri": "ipfs://0xDEADBEEF/1000.json",
    ///     "errors": []
    ///   },
    /// ]
    /// ```
    function paginateTokens(
        address ref,
        uint256 tokenId,
        uint256 limit
    ) external view returns (V721_TokenCollection memory);

    /// Get page of token data
    /// @param ref - Address for contract that implements ERC721
    /// @param account - Filter token data to only tokens owned by account
    /// @param tokenId - Where to start collecting token data
    /// @param limit - Maximum quantity of tokens to collect data
    /// @dev See {IViewERC721_Functions-paginateTokens}
    function paginateTokensOwnedBy(
        address ref,
        address account,
        uint256 tokenId,
        uint256 limit
    ) external view returns (V721_TokenCollection memory);
}

/* Variable definitions */
interface IViewERC721_Variables {
    /// Get instance owner
    ///
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// await instance.methods.owner().call();
    /// ```
    function owner() external view returns (address);
}

/* Inherited definitions */
interface IViewERC721_Inherits {

}

/// For external callers
/// @custom:examples
/// ## Web3 JS
///
/// ```javascript
/// const Web3 = require('web3');
/// const web3 = new Web3('http://localhost:8545');
///
/// const { abi } = require('./build/contracts/IViewERC721.json');
/// const address = '0xDEADBEEF';
///
/// const instance = new web3.eth.Contract(abi, address);
/// ```
interface IViewERC721 is IViewERC721_Events, IViewERC721_Functions, IViewERC721_Inherits, IViewERC721_Variables {

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

/// @dev See {IERC721Metadata}
interface IERC721OpenSea is IERC721Metadata {
    /// @dev See https://docs.opensea.io/v2.0/docs/contract-level-metadata
    function contractURI() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IDAO} from "../DAO/interfaces/IDAO.sol";
import {Pausable} from "../../Pausable.sol";

/**
 * @author MetaPlayerOne
 * @title MetaUnitUserIncentive
 * @notice Manages token distribution to users 
 */
contract MetaUnitUserIncentive is Pausable {
    struct Transaction { address owner_of; uint256 value; uint256 timestamp; }
    struct OwnerShip { address dao_address; address owner_of; }
    struct Token { address token_address; uint256 token_id; bool is_single; }

    address private _meta_unit_address;
    address private _dao_factory_address;
    uint256 private _contract_deployment_timestamp;

    mapping(address => bool) private _is_first_mint_resolved;
    mapping(address => mapping(uint256 => bool)) private _is_nft_registered;
    mapping(address => bool) private _is_sale_contract_address;

    Transaction[] private _transactions;
    mapping(address => uint256) private _dao_claim_timestamp;
    mapping(address => uint256) private _value_minted_by_user_address;
    mapping(address => uint256) private _value_for_mint_by_user_address;
    mapping(address => uint256) private _quantity_of_transaction_by_user_address;

    mapping(uint256 => mapping(address => bool)) private _is_in_list;

    /**
    * @dev setup MetaUnit address and owner of this contract.
    */
    constructor(address owner_of_, address meta_unit_address_, address dao_factory_address_) Pausable(owner_of_) {
        _meta_unit_address = meta_unit_address_;
        _dao_factory_address = dao_factory_address_;
        _contract_deployment_timestamp = block.timestamp;
    }

    /**
     * @return value multiplied by the time factor.
     */
    function getReducedValue(uint256 value) private view returns (uint256) {
        return (((value * _contract_deployment_timestamp) / (((block.timestamp - _contract_deployment_timestamp) * (_contract_deployment_timestamp / 547 days)) + _contract_deployment_timestamp)) * 10);
    }

    /**
     * @dev manages first mint of MetaUnit token.
     * @param tokens_ list of user's tokens.
     */
    function firstMint(Token[] memory tokens_) public notPaused {
        require(!_is_first_mint_resolved[msg.sender], "You have already performed this action");
        uint256 value = 0;
        for (uint256 i = 0; i < tokens_.length; i++) {
            Token memory token = tokens_[i];
            if (token.is_single) {
                require(IERC721(token.token_address).ownerOf(token.token_id) == msg.sender, "You are not an owner of token");
            } else {
                require(IERC1155(token.token_address).balanceOf(msg.sender, token.token_id) > 0, "You are not an owner of token");
            }
            if (!_is_nft_registered[token.token_address][token.token_id]) {
                value += 1 ether;
                _is_nft_registered[token.token_address][token.token_id] = true;
            }
        }
        IERC20(_meta_unit_address).transfer(msg.sender, getReducedValue(value));
        _is_first_mint_resolved[msg.sender] = true;
    }

    /**
     * @dev helps MetaUnit receive data about sales and resales.
     * @param eth_address_ address which sold NFT on platform.
     * @param value_ price which he received form this order.
     */
    function increaseLimit(address eth_address_, uint256 value_) public {
        require(_is_sale_contract_address[msg.sender], "No permissions to this function");
        _transactions.push(Transaction(eth_address_, value_, block.timestamp));
        _value_for_mint_by_user_address[eth_address_] += value_;
        _quantity_of_transaction_by_user_address[eth_address_] += 1;
    }

    /**
     * @dev manages secondary mint of MetaUnit token.
     */
    function secondaryMint() public notPaused {
        require(_value_minted_by_user_address[msg.sender] > _value_for_mint_by_user_address[msg.sender] * _quantity_of_transaction_by_user_address[msg.sender], "Not enough tokens for mint");
        uint256 value = (_value_for_mint_by_user_address[msg.sender] * _quantity_of_transaction_by_user_address[msg.sender]) - _value_minted_by_user_address[msg.sender];
        IERC20(_meta_unit_address).transfer(msg.sender, getReducedValue(value));
        _value_minted_by_user_address[msg.sender] += getReducedValue(value);
    }

    /**
     * @dev manages mint of MetaUnit token for DAOs.
     */
    function daoMint() public notPaused {
        require(IDAO(_dao_factory_address).getDaosByOwner(msg.sender).length > 0, "You had no DAO on MetaPlayerOne");
        uint256 current_timestamp = block.timestamp;
        require(_dao_claim_timestamp[msg.sender] + 30 days <= current_timestamp && _dao_claim_timestamp[msg.sender] != 0);
        address[] memory daos_addresses = IDAO(_dao_factory_address).getDaosByOwner(msg.sender);
        uint256 trans_len = _transactions.length;
        uint256 daos_addr_len = daos_addresses.length;
        uint256 value = 0;
        uint256 quantity = 0;
        OwnerShip[] memory owner_addresses;
        for (uint256 i = 0; i < trans_len; i++) {
            if (_transactions[i].timestamp + 30 days > current_timestamp) {
                for (uint256 j = 0; j < daos_addr_len; j++) {
                    if (IERC20(daos_addresses[j]).balanceOf(_transactions[i].owner_of) > 0) {
                        value += _transactions[i].value;
                        for (uint256 k = 0; k < owner_addresses.length; k ++) {
                            if (owner_addresses[k].owner_of == _transactions[i].owner_of && owner_addresses[k].dao_address == daos_addresses[j]) {
                                owner_addresses[owner_addresses.length].owner_of = _transactions[i].owner_of;
                                owner_addresses[owner_addresses.length].dao_address == daos_addresses[j];
                                quantity++;
                            }
                        }
                    }
                }
            }
        }
        IERC20(_meta_unit_address).transfer(msg.sender, getReducedValue(value * quantity) / 100);
    }

    /**
     * @dev helps get coverage ratio of dao by address.
     * @param dao_address address of dao, which coverage ratio should be calculated.
     * @return value coverage ratio.
     */
    function getCoverageByDaoAddress(address dao_address) public view returns (uint256) {
        uint256 value = 0;
        uint256 trans_len = _transactions.length;
        address[] memory addresses;
        uint256 quantity;
        for (uint256 i = 0; i < trans_len; i++) {
            if (_transactions[i].timestamp + 30 days > block.timestamp) {
                if (IERC20(dao_address).balanceOf(_transactions[i].owner_of) > 0) {
                    value += _transactions[i].value;
                    for (uint256 k = 0; k < addresses.length; k ++) {
                        if (addresses[k] == _transactions[i].owner_of) {
                            addresses[addresses.length] = _transactions[i].owner_of;
                            quantity++;
                        }
                    }
                }
            }
        }
        return getReducedValue(value * quantity) / 100;
    }

    function setSaleContractsAddresses(address[] memory contract_addresses_, bool action_) public {
        require(_owner_of == msg.sender, "Permission denied!");
        for (uint256 i = 0; i < contract_addresses_.length; i++) {
            _is_sale_contract_address[contract_addresses_[i]] = action_;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDAO {
    function getDaosByOwner(address owner_of)
        external
        returns (address[] memory);

    function getDaoOwner(address dao_address)
        external
        returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @author MetaPlayerOne
 * @title Pausable
 * @notice Contract which manages allocations in MetaPlayerOne.
 */
contract Pausable {
    address internal _owner_of;
    bool internal _paused = false;

    /**
    * @dev setup owner of this contract with paused off state.
    */
    constructor(address owner_of_) {
        _owner_of = owner_of_;
        _paused = false;
    }

    /**
    * @dev modifier which can be used on child contract for checking if contract services are paused.
    */
    modifier notPaused() {
        require(!_paused, "Contract is paused");
        _;
    }

    /**
    * @dev function which setup paused variable.
    * @param paused_ new boolean value of paused condition.
    */
    function setPaused(bool paused_) external {
        require(_paused == paused_, "Param has been asigned already");
        require(_owner_of == msg.sender, "Permission address");
        _paused = paused_;
    }

    /**
    * @dev function which setup owner variable.
    * @param owner_of_ new owner of contract.
    */
    function setOwner(address owner_of_) external {
        require(_owner_of == msg.sender, "Permission address");
        _owner_of = owner_of_;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}
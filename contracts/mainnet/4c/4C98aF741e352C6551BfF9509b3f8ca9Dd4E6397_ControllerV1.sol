pragma solidity ^0.8.7;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./interfaces/IControllerRegistry.sol";

contract ControllerRegistry is IControllerRegistry, Ownable {
    mapping(address => bool) public controllerRegistry;

    event ControllerRegister(address newController);
    event ControllerRemove(address newController);

    /**
     * @param _controller The address to register as a controller
     */
    function registerController(address _controller) external onlyOwner {
        require(_controller != address(0), "Invalid address");
        emit ControllerRegister(_controller);
        controllerRegistry[_controller] = true;
    }

    /**
     * @param _controller The address to remove as a controller
     */
    function removeController(address _controller) external onlyOwner {
        require(_controller != address(0), "Invalid address");
        emit ControllerRemove(_controller);
        controllerRegistry[_controller] = false;
    }

    /**
     * @param _controller The address to check if registered as a controller
     * @return Boolean representing if the address is a registered as a controller
     */
    function isRegistered(address _controller)
        external
        view
        override
        returns (bool)
    {
        return controllerRegistry[_controller];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity ^0.8.7;


interface IControllerRegistry{

    /**
     * @param _controller Address to check if registered as a controller
     * @return Boolean representing if the address is a registered as a controller
     */
    function isRegistered(address _controller) external view returns (bool);

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

pragma solidity ^0.8.7;

/* solhint-disable indent */

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/utils/Address.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./interfaces/IControllerRegistry.sol";
import "./interfaces/IControllerBase.sol";

contract MemberToken is ERC1155Supply, Ownable {
    using Address for address;

    IControllerRegistry public controllerRegistry;

    mapping(uint256 => address) public memberController;

    uint256 public nextAvailablePodId = 0;
    string public _contractURI =
        "https://orcaprotocol-nft.vercel.app/assets/contract-metadata";

    event MigrateMemberController(uint256 podId, address newController);

    /**
     * @param _controllerRegistry The address of the ControllerRegistry contract
     */
    constructor(address _controllerRegistry, string memory uri) ERC1155(uri) {
        require(_controllerRegistry != address(0), "Invalid address");
        controllerRegistry = IControllerRegistry(_controllerRegistry);
    }

    // Provides metadata value for the opensea wallet. Must be set at construct time
    // Source: https://www.reddit.com/r/ethdev/comments/q4j5bf/contracturi_not_reflected_in_opensea/
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    // Note that OpenSea does not currently update contract metadata when this value is changed. - Nov 2021
    function setContractURI(string memory newContractURI) public onlyOwner {
        _contractURI = newContractURI;
    }

    /**
     * @param _podId The pod id number
     * @param _newController The address of the new controller
     */
    function migrateMemberController(uint256 _podId, address _newController)
        external
    {
        require(_newController != address(0), "Invalid address");
        require(
            msg.sender == memberController[_podId],
            "Invalid migrate controller"
        );
        require(
            controllerRegistry.isRegistered(_newController),
            "Controller not registered"
        );

        memberController[_podId] = _newController;
        emit MigrateMemberController(_podId, _newController);
    }

    function getNextAvailablePodId() external view returns (uint256) {
        return nextAvailablePodId;
    }

    function setUri(string memory uri) external onlyOwner {
        _setURI(uri);
    }

    /**
     * @param _account The account address to assign the membership token to
     * @param _id The membership token id to mint
     * @param data Passes a flag for initial creation event
     */
    function mint(
        address _account,
        uint256 _id,
        bytes memory data
    ) external {
        _mint(_account, _id, 1, data);
    }

    /**
     * @param _accounts The account addresses to assign the membership tokens to
     * @param _id The membership token id to mint
     * @param data Passes a flag for an initial creation event
     */
    function mintSingleBatch(
        address[] memory _accounts,
        uint256 _id,
        bytes memory data
    ) public {
        for (uint256 index = 0; index < _accounts.length; index += 1) {
            _mint(_accounts[index], _id, 1, data);
        }
    }

    /**
     * @param _accounts The account addresses to burn the membership tokens from
     * @param _id The membership token id to burn
     */
    function burnSingleBatch(address[] memory _accounts, uint256 _id) public {
        for (uint256 index = 0; index < _accounts.length; index += 1) {
            _burn(_accounts[index], _id, 1);
        }
    }

    function createPod(address[] memory _accounts, bytes memory data)
        external
        returns (uint256)
    {
        uint256 id = nextAvailablePodId;
        nextAvailablePodId += 1;

        require(
            controllerRegistry.isRegistered(msg.sender),
            "Controller not registered"
        );

        memberController[id] = msg.sender;

        if (_accounts.length != 0) {
            mintSingleBatch(_accounts, id, data);
        }

        return id;
    }

    /**
     * @param _account The account address holding the membership token to destroy
     * @param _id The id of the membership token to destroy
     */
    function burn(address _account, uint256 _id) external {
        _burn(_account, _id, 1);
    }

    // this hook gets called before every token event including mint and burn
    /**
     * @param operator The account address that initiated the action
     * @param from The account address recieveing the membership token
     * @param to The account address sending the membership token
     * @param ids An array of membership token ids to be transfered
     * @param amounts The amount of each membership token type to transfer
     * @param data Passes a flag for an initial creation event
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        // use first id to lookup controller
        address controller = memberController[ids[0]];
        require(controller != address(0), "Pod doesn't exist");

        for (uint256 i = 0; i < ids.length; i += 1) {
            // check if recipient is already member
            if (to != address(0)) {
                require(balanceOf(to, ids[i]) == 0, "User is already member");
            }
            // verify all ids use same controller
            require(
                memberController[ids[i]] == controller,
                "Ids have different controllers"
            );
        }

        // perform orca token transfer validations
        IControllerBase(controller).beforeTokenTransfer(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }
}

pragma solidity ^0.8.7;

interface IControllerBase {
    /**
     * @param operator The account address that initiated the action
     * @param from The account address sending the membership token
     * @param to The account address recieving the membership token
     * @param ids An array of membership token ids to be transfered
     * @param amounts The amount of each membership token type to transfer
     * @param data Arbitrary data
     */
    function beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function updatePodState(
        uint256 _podId,
        address _podAdmin,
        address _safeAddress
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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

pragma solidity ^0.8.7;

import "./IControllerBase.sol";

interface IControllerV1 is IControllerBase {
    function updatePodEnsRegistrar(address _podEnsRegistrar) external;

    /**
     * @param _members The addresses of the members of the pod
     * @param threshold The number of members that are required to sign a transaction
     * @param _admin The address of the pod admin
     * @param _label label hash of pod name (i.e labelhash('mypod'))
     * @param _ensString string of pod ens name (i.e.'mypod.pod.xyz')
     */
    function createPod(
        address[] memory _members,
        uint256 threshold,
        address _admin,
        bytes32 _label,
        string memory _ensString,
        uint256 expectedPodId,
        string memory _imageUrl
    ) external;

    /**
     * @dev Used to create a pod with an existing safe
     * @dev Will automatically distribute membership NFTs to current safe members
     * @param _admin The address of the pod admin
     * @param _safe The address of existing safe
     * @param _label label hash of pod name (i.e labelhash('mypod'))
     * @param _ensString string of pod ens name (i.e.'mypod.pod.xyz')
     */
    function createPodWithSafe(
        address _admin,
        address _safe,
        bytes32 _label,
        string memory _ensString,
        uint256 expectedPodId,
        string memory _imageUrl
    ) external;

    function podIdToSafe(uint256 _podId) external view returns (address);

    /**
     * @dev Allows admin to unlock the safe modules and allow them to be edited by members
     * @param _podId The id number of the pod
     * @param _isLocked true - pod modules cannot be added/removed
     */
    function setPodModuleLock(uint256 _podId, bool _isLocked) external;

    /**
     * @param _podId The id number of the pod
     * @param _isTransferLocked The address of the new pod admin
     */
    function setPodTransferLock(uint256 _podId, bool _isTransferLocked)
        external;

    /**
     * @param _podId The id number of the pod
     * @param _newAdmin The address of the new pod admin
     */
    function updatePodAdmin(uint256 _podId, address _newAdmin) external;

    /**
     * @dev This will nullify all pod state on this controller
     * @dev Update state on _newController
     * @dev Update controller to _newController in Safe and MemberToken
     * @param _podId The id number of the pod
     * @param _newController The address of the new pod controller
     * @param _prevModule The module that points to the orca module in the safe's ModuleManager linked list
     */
    function migratePodController(
        uint256 _podId,
        address _newController,
        address _prevModule
    ) external;

    function ejectSafe(
        uint256 podId,
        bytes32 label,
        address previousModule
    ) external;
}

pragma solidity ^0.8.7;
import "./interfaces/IControllerV1.sol";
import "./interfaces/IMemberToken.sol";

/* solhint-disable indent */

contract MultiCreateV1 {
    IMemberToken immutable memberToken;

    constructor(address _memberToken) {
        memberToken = IMemberToken(_memberToken);
    }

    struct AdminPointer {
        uint256 podId;
        address pointer;
    }

    function createPods(
        IControllerV1 _controller,
        address[][] memory _members,
        uint256[] calldata _thresholds,
        address[] memory _admins,
        bytes32[] memory _labels,
        string[] memory _ensStrings,
        string[] memory _imageUrls
    ) public returns (address[] memory) {
        uint256 numPods = _thresholds.length;
        require(_members.length == numPods, "incorrect members array");
        require(_labels.length == numPods, "incorrect labels array");
        require(_ensStrings.length == numPods, "incorrect ensStrings array");
        require(_imageUrls.length == numPods, "incorrect imageUrls array");

        uint256 nextPodId = memberToken.getNextAvailablePodId();

        /*
            When creating multiple pods at the same time, there is a case where one pod may be a dependancy of another
            createPods -> PodA, PodB, PodC
            PodB.members[address(0x1337), address(PodA) // doesn't exist yet]
            since PodA doesn't exist at create time we need a placeholder
            
            when deploying the array of pods we use newPods as a cache 
            as each pod gets deployed we add the address to newPods
            newPods = [address(0), address(PodA)];
            PodB.members[address(0x1337), address(1) // we know to check the cache]

            because we can't rely on address(0) we have to index the cache at 1
        */

        // 1 indexing to avoid relying on address(0)
        address[] memory newPods = new address[](numPods + 1);
        AdminPointer[] memory tempAdmin = new AdminPointer[](numPods + 1);

        for (uint256 i = 0; i < numPods; i++) {
            // if the numerical version of admin address is less than numPods + 1 and not address(0) its a pointer
            if (
                uint256(uint160(_admins[i])) <= numPods + 1 &&
                _admins[i] != address(0)
            ) {
                // store the admin pointer
                tempAdmin[i] = AdminPointer(nextPodId + i, _admins[i]);
                // temperarily overwrite admin with this address
                _admins[i] = address(this);
            }

            for (uint256 j = 0; j < _members[i].length; j++) {
                // if the numerical version of member address is less than numPods + 1 its a pointer
                if (uint256(uint160(_members[i][j])) <= numPods + 1) {
                    // pointer must be under the current pod index
                    require(
                        uint256(uint160(_members[i][j])) < i + 1,
                        "Member dependency bad ordering"
                    );
                    // overwrite member with new pod address
                    _members[i][j] = newPods[uint256(uint160(_members[i][j]))];
                }
            }

            _controller.createPod(
                _members[i],
                _thresholds[i],
                _admins[i],
                _labels[i],
                _ensStrings[i],
                nextPodId + i,
                _imageUrls[i]
            );
            // store new pods with 1 index
            newPods[i + 1] = _controller.podIdToSafe(nextPodId + (i));
        }

        // iterate through all of the stored admin pointers and transfer admin to the destination pod
        for (uint256 i = 0; i < tempAdmin.length; i++) {
            AdminPointer memory adminPointer = tempAdmin[i];
            // if pointer is set
            if (adminPointer.pointer != address(0)) {
                _controller.updatePodAdmin(
                    adminPointer.podId,
                    newPods[uint256(uint160(adminPointer.pointer))]
                );
            }
        }

        return newPods;
    }
}

pragma solidity ^0.8.7;

import "lib/openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";

interface IMemberToken is IERC1155 {
    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @dev Indicates weither any token exist with a given id, or not.
     */
    function exists(uint256 id) external view returns (bool);

    function getNextAvailablePodId() external view returns (uint256);

    /**
     * @param _podId The pod id number
     * @param _newController The address of the new controller
     */
    function migrateMemberController(uint256 _podId, address _newController)
        external;

    /**
     * @param _account The account address to transfer the membership token to
     * @param _id The membership token id to mint
     * @param data Arbitrary data
     */
    function mint(
        address _account,
        uint256 _id,
        bytes memory data
    ) external;

    /**
     * @param _accounts The account addresses to transfer the membership tokens to
     * @param _id The membership token id to mint
     * @param data Arbitrary data
     */
    function mintSingleBatch(
        address[] memory _accounts,
        uint256 _id,
        bytes memory data
    ) external;

    /**
     * @param _account The account address holding the membership token to destroy
     * @param _id The id of the membership token to destroy
     */
    function burn(address _account, uint256 _id) external;

    function burnSingleBatch(address[] memory _accounts, uint256 _id) external;

    function createPod(address[] memory _accounts, bytes memory data)
        external
        returns (uint256);
}

pragma solidity ^0.8.7;
import "./interfaces/IMemberToken.sol";

contract MemberTeller {
    IMemberToken public immutable memberToken;

    bytes4 public constant ENCODED_SIG_ADD_OWNER =
        bytes4(keccak256("addOwnerWithThreshold(address,uint256)"));
    bytes4 public constant ENCODED_SIG_REMOVE_OWNER =
        bytes4(keccak256("removeOwner(address,address,uint256)"));
    bytes4 public constant ENCODED_SIG_SWAP_OWNER =
        bytes4(keccak256("swapOwner(address,address,address)"));

    uint8 internal constant SYNC_EVENT = 0x02;

    constructor(address _memberToken) {
        memberToken = IMemberToken(_memberToken);
    }

    function getSyncData() internal pure returns (bytes memory) {
        bytes memory data = new bytes(1);
        data[0] = bytes1(uint8(SYNC_EVENT));
        return data;
    }

    // we use burn sync flag to let the controller know to skip side effects
    // controller will reset flag in beforeTokenTransfer
    bool internal BURN_SYNC_FLAG = false;

    function setBurnSyncFlag(bool flag) internal {
        BURN_SYNC_FLAG = flag;
    }

    function memberTellerCheck(uint256 podId, bytes memory data) internal {
        if (bytes4(data) == ENCODED_SIG_ADD_OWNER) {
            address mintMember;
            assembly {
                // shift 0x4 for the sig + 0x20 padding
                mintMember := mload(add(data, 0x24))
            }
            memberToken.mint(mintMember, podId, getSyncData());
        }
        if (bytes4(data) == ENCODED_SIG_REMOVE_OWNER) {
            address burnMember;
            assembly {
                // note: consecutive addresses are packed into a single memory slot
                // shift 0x4 for the sig, 0x40 for prev address and padding
                burnMember := mload(add(data, 0x44))
            }
            setBurnSyncFlag(true);
            memberToken.burn(burnMember, podId);
        }
        if (bytes4(data) == ENCODED_SIG_SWAP_OWNER) {
            address burnMember;
            address mintMember;
            assembly {
                // note: consecutive addresses are packed into a single memory slot
                // shift 0x4 for the sig + 0x40 for prev address and padding
                burnMember := mload(add(data, 0x44))
                // shift 0x4 for the sig + 0x40 for prev address and padding + 0x20 for the new address
                mintMember := mload(add(data, 0x64))
            }
            memberToken.mint(mintMember, podId, getSyncData());
            setBurnSyncFlag(true);
            memberToken.burn(burnMember, podId);
        }
    }
}

pragma solidity ^0.8.7;

import "lib/ens-contracts/contracts/registry/ENS.sol";
import "lib/ens-contracts/contracts/registry/ReverseRegistrar.sol";
import "lib/ens-contracts/contracts/resolvers/Resolver.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "./interfaces/IControllerV1.sol";
import "./interfaces/IMemberToken.sol";
import "./interfaces/IControllerRegistry.sol";
import "./SafeTeller.sol";
import "./MemberTeller.sol";
import "./ens/IPodEnsRegistrar.sol";
import {BaseGuard, Enum} from "lib/safe-contracts/contracts/base/GuardManager.sol";

contract ControllerV1 is
    IControllerV1,
    SafeTeller,
    MemberTeller,
    BaseGuard,
    Ownable
{
    event CreatePod(uint256 podId, address safe, address admin, string ensName);
    event UpdatePodAdmin(uint256 podId, address admin);
    event DeregisterPod(uint256 podId);

    IControllerRegistry public immutable controllerRegistry;
    IPodEnsRegistrar public podEnsRegistrar;

    string public constant VERSION = "1.3.0";

    mapping(address => uint256) public safeToPodId;
    mapping(uint256 => address) public override podIdToSafe;
    mapping(uint256 => address) public podAdmin;
    mapping(uint256 => bool) public isTransferLocked;

    uint8 internal constant CREATE_EVENT = 0x01;

    /**
     * @dev Will instantiate safe teller with gnosis master and proxy addresses
     * @param _memberToken The address of the MemberToken contract
     * @param _controllerRegistry The address of the ControllerRegistry contract
     * @param _proxyFactoryAddress The proxy factory address
     * @param _gnosisMasterAddress The gnosis master address
     */
    constructor(
        address _owner,
        address _memberToken,
        address _controllerRegistry,
        address _proxyFactoryAddress,
        address _gnosisMasterAddress,
        address _podEnsRegistrar,
        address _fallbackHandlerAddress
    )
        SafeTeller(
            _proxyFactoryAddress,
            _gnosisMasterAddress,
            _fallbackHandlerAddress
        )
        MemberTeller(_memberToken)
    {
        require(_owner != address(0), "Invalid address");
        require(_memberToken != address(0), "Invalid address");
        require(_controllerRegistry != address(0), "Invalid address");
        require(_proxyFactoryAddress != address(0), "Invalid address");
        require(_gnosisMasterAddress != address(0), "Invalid address");
        require(_podEnsRegistrar != address(0), "Invalid address");
        require(_fallbackHandlerAddress != address(0), "Invalid address");

        // Set owner separately from msg.sender.
        transferOwnership(_owner);

        controllerRegistry = IControllerRegistry(_controllerRegistry);
        podEnsRegistrar = IPodEnsRegistrar(_podEnsRegistrar);
    }

    function updatePodEnsRegistrar(address _podEnsRegistrar)
        external
        override
        onlyOwner
    {
        require(_podEnsRegistrar != address(0), "Invalid address");
        podEnsRegistrar = IPodEnsRegistrar(_podEnsRegistrar);
    }

    /**
     * @param _members The addresses of the members of the pod
     * @param threshold The number of members that are required to sign a transaction
     * @param _admin The address of the pod admin
     * @param _label label hash of pod name (i.e labelhash('mypod'))
     * @param _ensString string of pod ens name (i.e.'mypod.pod.xyz')
     */
    function createPod(
        address[] memory _members,
        uint256 threshold,
        address _admin,
        bytes32 _label,
        string memory _ensString,
        uint256 expectedPodId,
        string memory _imageUrl
    ) external override {
        address safe = createSafe(_members, threshold, expectedPodId);

        _createPod(
            _members,
            safe,
            _admin,
            _label,
            _ensString,
            expectedPodId,
            _imageUrl
        );
    }

    /**
     * @dev Used to create a pod with an existing safe
     * @dev Will automatically distribute membership NFTs to current safe members
     * @param _admin The address of the pod admin
     * @param _safe The address of existing safe
     * @param _label label hash of pod name (i.e labelhash('mypod'))
     * @param _ensString string of pod ens name (i.e.'mypod.pod.xyz')
     */
    function createPodWithSafe(
        address _admin,
        address _safe,
        bytes32 _label,
        string memory _ensString,
        uint256 expectedPodId,
        string memory _imageUrl
    ) external override {
        require(_safe != address(0), "invalid safe address");
        // safe must have zero'd pod id
        if (safeToPodId[_safe] == 0) {
            // if safe has zero pod id make sure its not set at pod id zero
            require(_safe != podIdToSafe[0], "safe already in use");
        } else {
            revert("safe already in use");
        }
        require(safeToPodId[_safe] == 0, "safe already in use");
        require(isSafeModuleEnabled(_safe), "safe module must be enabled");
        require(
            isSafeMember(_safe, msg.sender) || msg.sender == _safe,
            "caller must be safe or member"
        );

        address[] memory members = getSafeMembers(_safe);

        _createPod(
            members,
            _safe,
            _admin,
            _label,
            _ensString,
            expectedPodId,
            _imageUrl
        );
    }

    /**
     * @param _members The addresses of the members of the pod
     * @param _admin The address of the pod admin
     * @param _safe The address of existing safe
     * @param _label label hash of pod name (i.e labelhash('mypod'))
     * @param _ensString string of pod ens name (i.e.'mypod.pod.xyz')
     */
    function _createPod(
        address[] memory _members,
        address _safe,
        address _admin,
        bytes32 _label,
        string memory _ensString,
        uint256 expectedPodId,
        string memory _imageUrl
    ) internal {
        // add create event flag to token data
        bytes memory data = new bytes(1);
        data[0] = bytes1(uint8(CREATE_EVENT));

        uint256 podId = memberToken.createPod(_members, data);
        // The imageUrl has an expected pod ID, but we need to make sure it aligns with the actual pod ID
        require(podId == expectedPodId, "pod id didn't match, try again");

        emit CreatePod(podId, _safe, _admin, _ensString);
        emit UpdatePodAdmin(podId, _admin);

        // add controller as guard
        setSafeGuard(_safe, address(this));
        if (_admin != address(0)) {
            // will lock safe modules if admin exists
            setModuleLock(_safe, true);
            podAdmin[podId] = _admin;
        }
        podIdToSafe[podId] = _safe;
        safeToPodId[_safe] = podId;

        // setup pod ENS
        address reverseRegistrar = podEnsRegistrar.registerPod(
            _label,
            _safe,
            msg.sender
        );
        setupSafeReverseResolver(_safe, reverseRegistrar, _ensString);

        // Node is how ENS identifies names, we need that to setText
        bytes32 node = podEnsRegistrar.getEnsNode(_label);
        podEnsRegistrar.setText(node, "avatar", _imageUrl);
        podEnsRegistrar.setText(node, "podId", Strings.toString(podId));
    }

    /**
     * @dev Allows admin to unlock the safe modules and allow them to be edited by members
     * @param _podId The id number of the pod
     * @param _isLocked true - pod modules cannot be added/removed
     */
    function setPodModuleLock(uint256 _podId, bool _isLocked)
        external
        override
    {
        require(
            msg.sender == podAdmin[_podId],
            "Must be admin to set module lock"
        );
        setModuleLock(podIdToSafe[_podId], _isLocked);
    }

    /**
     * @param _podId The id number of the pod
     * @param _newAdmin The address of the new pod admin
     */
    function updatePodAdmin(uint256 _podId, address _newAdmin)
        external
        override
    {
        address admin = podAdmin[_podId];
        address safe = podIdToSafe[_podId];

        require(safe != address(0), "Pod doesn't exist");

        // if there is no admin it can only be added by safe
        if (admin == address(0)) {
            require(msg.sender == safe, "Only safe can add new admin");
        } else {
            require(msg.sender == admin, "Only admin can update admin");
        }
        // set module lock to true for non zero _newAdmin
        setModuleLock(safe, _newAdmin != address(0));

        podAdmin[_podId] = _newAdmin;

        emit UpdatePodAdmin(_podId, _newAdmin);
    }

    /**
     * @param _podId The id number of the pod
     * @param _isTransferLocked The address of the new pod admin
     */
    function setPodTransferLock(uint256 _podId, bool _isTransferLocked)
        external
        override
    {
        address admin = podAdmin[_podId];
        address safe = podIdToSafe[_podId];

        // if no pod admin it can only be set by safe
        if (admin == address(0)) {
            require(msg.sender == safe, "Only safe can set transfer lock");
        } else {
            // if admin then it can be set by admin or safe
            require(
                msg.sender == admin || msg.sender == safe,
                "Only admin or safe can set transfer lock"
            );
        }

        // set podid to transfer lock bool
        isTransferLocked[_podId] = _isTransferLocked;
    }

    /**
     * @dev This will nullify all pod state on this controller
     * @dev Update state on _newController
     * @dev Update controller to _newController in Safe and MemberToken
     * @param _podId The id number of the pod
     * @param _newController The address of the new pod controller
     * @param _prevModule The module that points to the orca module in the safe's ModuleManager linked list
     */
    function migratePodController(
        uint256 _podId,
        address _newController,
        address _prevModule
    ) external override {
        require(_newController != address(0), "Invalid address");
        require(
            _newController != address(this),
            "Cannot migrate to same controller"
        );
        require(
            controllerRegistry.isRegistered(_newController),
            "Controller not registered"
        );

        address admin = podAdmin[_podId];
        address safe = podIdToSafe[_podId];

        require(
            msg.sender == admin || msg.sender == safe,
            "User not authorized"
        );

        IControllerBase newController = IControllerBase(_newController);

        // nullify current pod state
        podAdmin[_podId] = address(0);
        podIdToSafe[_podId] = address(0);
        safeToPodId[safe] = 0;
        // update controller in MemberToken
        memberToken.migrateMemberController(_podId, _newController);
        // update safe module to _newController
        migrateSafeTeller(safe, _newController, _prevModule);
        // update pod state in _newController
        newController.updatePodState(_podId, admin, safe);
    }

    /**
     * @dev This is called by another version of controller to migrate a pod to this version
     * @dev Will only accept calls from registered controllers
     * @dev Can only be called once.
     * @param _podId The id number of the pod
     * @param _podAdmin The address of the pod admin
     * @param _safeAddress The address of the safe
     */
    function updatePodState(
        uint256 _podId,
        address _podAdmin,
        address _safeAddress
    ) external override {
        require(_safeAddress != address(0), "Invalid address");
        require(
            controllerRegistry.isRegistered(msg.sender),
            "Controller not registered"
        );
        require(
            podAdmin[_podId] == address(0) &&
                podIdToSafe[_podId] == address(0) &&
                safeToPodId[_safeAddress] == 0,
            "Pod already exists"
        );
        // if there is a pod admin, set state and lock modules
        if (_podAdmin != address(0)) {
            podAdmin[_podId] = _podAdmin;
            setModuleLock(_safeAddress, true);
        }
        podIdToSafe[_podId] = _safeAddress;
        safeToPodId[_safeAddress] = _podId;

        // add controller as guard
        setSafeGuard(_safeAddress, address(this));

        emit UpdatePodAdmin(_podId, _podAdmin);
    }

    /**
     * Ejects a safe from the Orca ecosystem. Also handles clean up for safes
     * that have already been ejected.
     * Note that the reverse registry entry cannot be cleaned up if the safe has already been ejected.
     * @param podId - ID of pod being ejected
     * @param label - labelhash of pod ENS name, i.e., `labelhash("mypod")`
     * @param previousModule - previous module
     */
    function ejectSafe(
        uint256 podId,
        bytes32 label,
        address previousModule
    ) external override {
        address safe = podIdToSafe[podId];
        address admin = podAdmin[podId];

        require(safe != address(0), "pod not registered");

        if (admin != address(0)) {
            require(msg.sender == admin, "must be admin");
            setModuleLock(safe, false);
        } else {
            require(msg.sender == safe, "tx must be sent from safe");
        }

        Resolver resolver = Resolver(podEnsRegistrar.resolver());
        bytes32 node = podEnsRegistrar.getEnsNode(label);
        address addr = resolver.addr(node);
        require(addr == safe, "safe and label didn't match");
        podEnsRegistrar.setText(node, "avatar", "");
        podEnsRegistrar.setText(node, "podId", "");
        podEnsRegistrar.setAddr(node, address(0));
        podEnsRegistrar.register(label, address(0));

        // if module is already disabled, the safe must unset these manually
        if (isSafeModuleEnabled(safe)) {
            // remove controller as guard
            setSafeGuard(safe, address(0));
            // remove module and handle reverse registration clearing.
            disableModule(
                safe,
                podEnsRegistrar.reverseRegistrar(),
                previousModule
            );
        }

        // This needs to happen before the burn to skip the transfer check.
        podAdmin[podId] = address(0);
        podIdToSafe[podId] = address(0);
        safeToPodId[safe] = 0;

        // Burn member tokens
        address[] memory members = this.getSafeMembers(safe);
        memberToken.burnSingleBatch(members, podId);

        emit DeregisterPod(podId);
    }

    function batchMintAndBurn(
        uint256 _podId,
        address[] memory _mintMembers,
        address[] memory _burnMembers
    ) external {
        address safe = podIdToSafe[_podId];
        require(
            msg.sender == safe || msg.sender == podAdmin[_podId],
            "not authorized"
        );
        memberToken.mintSingleBatch(_mintMembers, _podId, bytes(" "));
        memberToken.burnSingleBatch(_burnMembers, _podId);
    }

    /**
     * @param operator The address that initiated the action
     * @param from The address sending the membership token
     * @param to The address recieveing the membership token
     * @param ids An array of membership token ids to be transfered
     * @param data Passes a flag for an initial creation event
     */
    function beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory,
        bytes memory data
    ) external override {
        require(msg.sender == address(memberToken), "Not Authorized");

        // only recognise data flags from this controller
        if (operator == address(this)) {
            // if create or sync event than side effects have been pre-handled
            if (data.length > 0) {
                if (uint8(data[0]) == CREATE_EVENT) return;
                if (uint8(data[0]) == SYNC_EVENT) return;
            }
            // because 1155 burn doesn't allow data we use a burn sync flag to skip side effects
            if (BURN_SYNC_FLAG == true) {
                setBurnSyncFlag(false);
                return;
            }
        }

        for (uint256 i = 0; i < ids.length; i += 1) {
            uint256 podId = ids[i];
            address safe = podIdToSafe[podId];
            address admin = podAdmin[podId];

            // If safe is 0'd, it means we're deregistering the pod, so we can skip check
            if (safe == address(0) && to == address(0)) return;

            if (from == address(0)) {
                // mint event

                // there are no rules operator must be admin, safe or controller
                require(
                    operator == safe ||
                        operator == admin ||
                        operator == address(this),
                    "No Rules Set"
                );

                onMint(to, safe);
            } else if (to == address(0)) {
                // burn event

                // there are no rules  operator must be admin, safe or controller
                require(
                    operator == safe ||
                        operator == admin ||
                        operator == address(this),
                    "No Rules Set"
                );

                onBurn(from, safe);
            } else {
                // pod cannot be locked
                require(
                    isTransferLocked[podId] == false,
                    "Pod Is Transfer Locked"
                );
                // transfer event
                onTransfer(from, to, safe);
            }
        }
    }

    /**
     * @dev This will be called by the safe at execution time time
     * _param to Destination address of Safe transaction.
     * _param value Ether value of Safe transaction.
     * @param data Data payload of Safe transaction.
     * _param operation Operation type of Safe transaction.
     * _param safeTxGas Gas that should be used for the Safe transaction.
     * _param baseGas Gas costs that are independent of the transaction execution(e.g. base transaction fee, signature check, payment of the refund)
     * _param gasPrice Gas price that should be used for the payment calculation.
     * _param gasToken Token address (or 0 if ETH) that is used for the payment.
     * _param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
     * _param signatures Packed signature data ({bytes32 r}{bytes32 s}{uint8 v})
     * _param msgSender Account executing safe transaction
     */
    function checkTransaction(
        address,
        uint256,
        bytes memory data,
        Enum.Operation,
        uint256,
        uint256,
        uint256,
        address,
        address payable,
        bytes memory,
        address
    ) external override {
        uint256 podId = safeToPodId[msg.sender];

        if (podId == 0) {
            address safe = podIdToSafe[podId];
            // if safe is 0 its deregistered and we can skip check to allow cleanup
            if (safe == address(0)) return;
            // else require podId zero is calling from safe
            require(safe == msg.sender, "Not Authorized");
        }

        if (data.length >= 4) {
            // if safe modules are locked perform safe check
            if (areModulesLocked[msg.sender]) {
                safeTellerCheck(data);
            }
            memberTellerCheck(podId, data);
        }
    }

    function checkAfterExecution(bytes32, bool) external pure override {
        return;
    }
}

pragma solidity >=0.8.4;

interface ENS {
    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function setRecord(
        bytes32 node,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeRecord(
        bytes32 node,
        bytes32 label,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address owner
    ) external returns (bytes32);

    function setResolver(bytes32 node, address resolver) external;

    function setOwner(bytes32 node, address owner) external;

    function setTTL(bytes32 node, uint64 ttl) external;

    function setApprovalForAll(address operator, bool approved) external;

    function owner(bytes32 node) external view returns (address);

    function resolver(bytes32 node) external view returns (address);

    function ttl(bytes32 node) external view returns (uint64);

    function recordExists(bytes32 node) external view returns (bool);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

pragma solidity >=0.8.4;

import "./ENS.sol";
import "./IReverseRegistrar.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../root/Controllable.sol";

abstract contract NameResolver {
    function setName(bytes32 node, string memory name) public virtual;
}

bytes32 constant lookup = 0x3031323334353637383961626364656600000000000000000000000000000000;

bytes32 constant ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

// namehash('addr.reverse')

contract ReverseRegistrar is Ownable, Controllable, IReverseRegistrar {
    ENS public immutable ens;
    NameResolver public defaultResolver;

    event ReverseClaimed(address indexed addr, bytes32 indexed node);

    /**
     * @dev Constructor
     * @param ensAddr The address of the ENS registry.
     */
    constructor(ENS ensAddr) {
        ens = ensAddr;

        // Assign ownership of the reverse record to our deployer
        ReverseRegistrar oldRegistrar = ReverseRegistrar(
            ensAddr.owner(ADDR_REVERSE_NODE)
        );
        if (address(oldRegistrar) != address(0x0)) {
            oldRegistrar.claim(msg.sender);
        }
    }

    modifier authorised(address addr) {
        require(
            addr == msg.sender ||
                controllers[msg.sender] ||
                ens.isApprovedForAll(addr, msg.sender) ||
                ownsContract(addr),
            "ReverseRegistrar: Caller is not a controller or authorised by address or the address itself"
        );
        _;
    }

    function setDefaultResolver(address resolver) public override onlyOwner {
        require(
            address(resolver) != address(0),
            "ReverseRegistrar: Resolver address must not be 0"
        );
        defaultResolver = NameResolver(resolver);
    }

    /**
     * @dev Transfers ownership of the reverse ENS record associated with the
     *      calling account.
     * @param owner The address to set as the owner of the reverse record in ENS.
     * @return The ENS node hash of the reverse record.
     */
    function claim(address owner) public override returns (bytes32) {
        return claimForAddr(msg.sender, owner, address(defaultResolver));
    }

    /**
     * @dev Transfers ownership of the reverse ENS record associated with the
     *      calling account.
     * @param addr The reverse record to set
     * @param owner The address to set as the owner of the reverse record in ENS.
     * @return The ENS node hash of the reverse record.
     */
    function claimForAddr(
        address addr,
        address owner,
        address resolver
    ) public override authorised(addr) returns (bytes32) {
        bytes32 labelHash = sha3HexAddress(addr);
        bytes32 reverseNode = keccak256(
            abi.encodePacked(ADDR_REVERSE_NODE, labelHash)
        );
        emit ReverseClaimed(addr, reverseNode);
        ens.setSubnodeRecord(ADDR_REVERSE_NODE, labelHash, owner, resolver, 0);
        return reverseNode;
    }

    /**
     * @dev Transfers ownership of the reverse ENS record associated with the
     *      calling account.
     * @param owner The address to set as the owner of the reverse record in ENS.
     * @param resolver The address of the resolver to set; 0 to leave unchanged.
     * @return The ENS node hash of the reverse record.
     */
    function claimWithResolver(address owner, address resolver)
        public
        override
        returns (bytes32)
    {
        return claimForAddr(msg.sender, owner, resolver);
    }

    /**
     * @dev Sets the `name()` record for the reverse ENS record associated with
     * the calling account. First updates the resolver to the default reverse
     * resolver if necessary.
     * @param name The name to set for this address.
     * @return The ENS node hash of the reverse record.
     */
    function setName(string memory name) public override returns (bytes32) {
        return
            setNameForAddr(
                msg.sender,
                msg.sender,
                address(defaultResolver),
                name
            );
    }

    /**
     * @dev Sets the `name()` record for the reverse ENS record associated with
     * the account provided. First updates the resolver to the default reverse
     * resolver if necessary.
     * Only callable by controllers and authorised users
     * @param addr The reverse record to set
     * @param owner The owner of the reverse node
     * @param name The name to set for this address.
     * @return The ENS node hash of the reverse record.
     */
    function setNameForAddr(
        address addr,
        address owner,
        address resolver,
        string memory name
    ) public override returns (bytes32) {
        bytes32 node = claimForAddr(addr, owner, resolver);
        NameResolver(resolver).setName(node, name);
        return node;
    }

    /**
     * @dev Returns the node hash for a given account's reverse records.
     * @param addr The address to hash
     * @return The ENS node hash.
     */
    function node(address addr) public pure override returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(ADDR_REVERSE_NODE, sha3HexAddress(addr))
            );
    }

    /**
     * @dev An optimised function to compute the sha3 of the lower-case
     *      hexadecimal representation of an Ethereum address.
     * @param addr The address to hash
     * @return ret The SHA3 hash of the lower-case hexadecimal encoding of the
     *         input address.
     */
    function sha3HexAddress(address addr) private pure returns (bytes32 ret) {
        assembly {
            for {
                let i := 40
            } gt(i, 0) {

            } {
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), lookup))
                addr := div(addr, 0x10)
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), lookup))
                addr := div(addr, 0x10)
            }

            ret := keccak256(0, 40)
        }
    }

    function ownsContract(address addr) internal view returns (bool) {
        try Ownable(addr).owner() returns (address owner) {
            return owner == msg.sender;
        } catch {
            return false;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "./profiles/IABIResolver.sol";
import "./profiles/IAddressResolver.sol";
import "./profiles/IAddrResolver.sol";
import "./profiles/IContentHashResolver.sol";
import "./profiles/IDNSRecordResolver.sol";
import "./profiles/IDNSZoneResolver.sol";
import "./profiles/IInterfaceResolver.sol";
import "./profiles/INameResolver.sol";
import "./profiles/IPubkeyResolver.sol";
import "./profiles/ITextResolver.sol";
import "./profiles/IExtendedResolver.sol";

/**
 * A generic resolver interface which includes all the functions including the ones deprecated
 */
interface Resolver is
    IERC165,
    IABIResolver,
    IAddressResolver,
    IAddrResolver,
    IContentHashResolver,
    IDNSRecordResolver,
    IDNSZoneResolver,
    IInterfaceResolver,
    INameResolver,
    IPubkeyResolver,
    ITextResolver,
    IExtendedResolver
{
    /* Deprecated events */
    event ContentChanged(bytes32 indexed node, bytes32 hash);

    function setABI(
        bytes32 node,
        uint256 contentType,
        bytes calldata data
    ) external;

    function setAddr(bytes32 node, address addr) external;

    function setAddr(
        bytes32 node,
        uint256 coinType,
        bytes calldata a
    ) external;

    function setContenthash(bytes32 node, bytes calldata hash) external;

    function setDnsrr(bytes32 node, bytes calldata data) external;

    function setName(bytes32 node, string calldata _name) external;

    function setPubkey(
        bytes32 node,
        bytes32 x,
        bytes32 y
    ) external;

    function setText(
        bytes32 node,
        string calldata key,
        string calldata value
    ) external;

    function setInterface(
        bytes32 node,
        bytes4 interfaceID,
        address implementer
    ) external;

    function multicall(bytes[] calldata data)
        external
        returns (bytes[] memory results);

    /* Deprecated functions */
    function content(bytes32 node) external view returns (bytes32);

    function multihash(bytes32 node) external view returns (bytes memory);

    function setContent(bytes32 node, bytes32 hash) external;

    function setMultihash(bytes32 node, bytes calldata hash) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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

pragma solidity ^0.8.7;

import "lib/openzeppelin-contracts/contracts/utils/Address.sol";
import "./interfaces/IGnosisSafe.sol";
import "./interfaces/IGnosisSafeProxyFactory.sol";

contract SafeTeller {
    using Address for address;

    // mainnet: 0x76E2cFc1F5Fa8F6a5b3fC4c8F4788F0116861F9B;
    address public immutable proxyFactoryAddress;

    // mainnet: 0x34CfAC646f301356fAa8B21e94227e3583Fe3F5F;
    address public immutable gnosisMasterAddress;
    address public immutable fallbackHandlerAddress;

    string public constant FUNCTION_SIG_SETUP =
        "setup(address[],uint256,address,bytes,address,address,uint256,address)";
    string public constant FUNCTION_SIG_EXEC =
        "execTransaction(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,bytes)";

    string public constant FUNCTION_SIG_ENABLE = "delegateSetup(address)";

    bytes4 public constant ENCODED_SIG_ENABLE_MOD =
        bytes4(keccak256("enableModule(address)"));
    bytes4 public constant ENCODED_SIG_DISABLE_MOD =
        bytes4(keccak256("disableModule(address,address)"));
    bytes4 public constant ENCODED_SIG_SET_GUARD =
        bytes4(keccak256("setGuard(address)"));

    address internal constant SENTINEL = address(0x1);

    // pods with admin have modules locked by default
    mapping(address => bool) public areModulesLocked;

    /**
     * @param _proxyFactoryAddress The proxy factory address
     * @param _gnosisMasterAddress The gnosis master address
     */
    constructor(
        address _proxyFactoryAddress,
        address _gnosisMasterAddress,
        address _fallbackHanderAddress
    ) {
        proxyFactoryAddress = _proxyFactoryAddress;
        gnosisMasterAddress = _gnosisMasterAddress;
        fallbackHandlerAddress = _fallbackHanderAddress;
    }

    /**
     * @param _safe The address of the safe
     * @param _newSafeTeller The address of the new safe teller contract
     */
    function migrateSafeTeller(
        address _safe,
        address _newSafeTeller,
        address _prevModule
    ) internal {
        // add new safeTeller
        bytes memory enableData = abi.encodeWithSignature(
            "enableModule(address)",
            _newSafeTeller
        );

        bool enableSuccess = IGnosisSafe(_safe).execTransactionFromModule(
            _safe,
            0,
            enableData,
            IGnosisSafe.Operation.Call
        );
        require(enableSuccess, "Migration failed on enable");

        // validate prevModule of current safe teller
        (address[] memory moduleBuffer, ) = IGnosisSafe(_safe)
            .getModulesPaginated(_prevModule, 1);
        require(moduleBuffer[0] == address(this), "incorrect prevModule");

        // disable current safeTeller
        bytes memory disableData = abi.encodeWithSignature(
            "disableModule(address,address)",
            _prevModule,
            address(this)
        );

        bool disableSuccess = IGnosisSafe(_safe).execTransactionFromModule(
            _safe,
            0,
            disableData,
            IGnosisSafe.Operation.Call
        );
        require(disableSuccess, "Migration failed on disable");
    }

    /**
     * @dev sets the safeteller as safe guard, called after migration
     * @param _safe The address of the safe
     */
    function setSafeGuard(address _safe, address guard) internal {
        bytes memory transferData = abi.encodeWithSignature(
            "setGuard(address)",
            guard
        );

        bool guardSuccess = IGnosisSafe(_safe).execTransactionFromModule(
            _safe,
            0,
            transferData,
            IGnosisSafe.Operation.Call
        );
        require(guardSuccess, "Could not set guard");
    }

    function getSafeMembers(address safe)
        public
        view
        returns (address[] memory)
    {
        return IGnosisSafe(safe).getOwners();
    }

    function isSafeModuleEnabled(address safe) public view returns (bool) {
        return IGnosisSafe(safe).isModuleEnabled(address(this));
    }

    function isSafeMember(address safe, address member)
        public
        view
        returns (bool)
    {
        return IGnosisSafe(safe).isOwner(member);
    }

    /**
     * @param _owners The  addresses to be owners of the safe
     * @param _threshold The number of owners that are required to sign a transaciton
     * @return safeAddress The address of the new safe
     */
    function createSafe(
        address[] memory _owners,
        uint256 _threshold,
        uint256 _salt
    ) internal returns (address safeAddress) {
        bytes memory data = abi.encodeWithSignature(
            FUNCTION_SIG_ENABLE,
            address(this)
        );

        // encode the setup call that will be called on the new proxy safe
        // from the proxy factory
        bytes memory setupData = abi.encodeWithSignature(
            FUNCTION_SIG_SETUP,
            _owners,
            _threshold,
            this,
            data,
            fallbackHandlerAddress,
            address(0),
            uint256(0),
            address(0)
        );

        try
            IGnosisSafeProxyFactory(proxyFactoryAddress).createProxyWithNonce(
                gnosisMasterAddress,
                setupData,
                _salt
            )
        returns (address newSafeAddress) {
            return newSafeAddress;
        } catch (bytes memory) {
            revert("Create Proxy With Data Failed");
        }
    }

    /**
     * Uses CREATE2 to replicate a given safe on a new network.
     * @param members The addresses of the members of the pod as it was originally created.
     * @param threshold The number of members that are required to sign a transaction
     * @param podId - Pod ID of safe you are trying to recreate
     */
    function recoverSafe(
        address[] calldata members,
        uint256 threshold,
        uint256 podId
    ) external returns (address) {
        return createSafe(members, threshold, podId);
    }

    /**
     * @param to The account address to add as an owner
     * @param safe The address of the safe
     */
    function onMint(address to, address safe) internal {
        uint256 threshold = IGnosisSafe(safe).getThreshold();

        bytes memory data = abi.encodeWithSignature(
            "addOwnerWithThreshold(address,uint256)",
            to,
            threshold
        );

        bool success = IGnosisSafe(safe).execTransactionFromModule(
            safe,
            0,
            data,
            IGnosisSafe.Operation.Call
        );

        require(success, "Module Transaction Failed");
    }

    /**
     * @param from The address to be removed as an owner
     * @param safe The address of the safe
     */
    function onBurn(address from, address safe) internal {
        uint256 threshold = IGnosisSafe(safe).getThreshold();
        address[] memory owners = IGnosisSafe(safe).getOwners();

        //look for the address pointing to address from
        address prevFrom = address(0);
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == from) {
                if (i == 0) {
                    prevFrom = SENTINEL;
                } else {
                    prevFrom = owners[i - 1];
                }
            }
        }
        if (owners.length - 1 < threshold) threshold -= 1;
        bytes memory data = abi.encodeWithSignature(
            "removeOwner(address,address,uint256)",
            prevFrom,
            from,
            threshold
        );

        bool success = IGnosisSafe(safe).execTransactionFromModule(
            safe,
            0,
            data,
            IGnosisSafe.Operation.Call
        );
        require(success, "Module Transaction Failed");
    }

    /**
     * @param from The address being removed as an owner
     * @param to The address being added as an owner
     * @param safe The address of the safe
     */
    function onTransfer(
        address from,
        address to,
        address safe
    ) internal {
        address[] memory owners = IGnosisSafe(safe).getOwners();

        //look for the address pointing to address from
        address prevFrom;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == from) {
                if (i == 0) {
                    prevFrom = SENTINEL;
                } else {
                    prevFrom = owners[i - 1];
                }
            }
        }

        bytes memory data = abi.encodeWithSignature(
            "swapOwner(address,address,address)",
            prevFrom,
            from,
            to
        );

        bool success = IGnosisSafe(safe).execTransactionFromModule(
            safe,
            0,
            data,
            IGnosisSafe.Operation.Call
        );
        require(success, "Module Transaction Failed");
    }

    /**
     * @dev This will execute a tx from the safe that will update the safe's ENS in the reverse resolver
     * @param safe safe address
     * @param reverseRegistrar The ENS default reverseRegistar
     * @param _ensString string of pod ens name (i.e.'mypod.pod.xyz')
     */
    function setupSafeReverseResolver(
        address safe,
        address reverseRegistrar,
        string memory _ensString
    ) internal virtual {
        bytes memory data = abi.encodeWithSignature(
            "setName(string)",
            _ensString
        );

        bool success = IGnosisSafe(safe).execTransactionFromModule(
            reverseRegistrar,
            0,
            data,
            IGnosisSafe.Operation.Call
        );
        require(success, "Module Transaction Failed");
    }

    /**
     * @dev This will be called by the safe at tx time and prevent module disable on pods with admins
     * @param safe safe address
     * @param isLocked safe address
     */
    function setModuleLock(address safe, bool isLocked) internal {
        areModulesLocked[safe] = isLocked;
    }

    function safeTellerCheck(bytes memory data) internal pure {
        require(
            bytes4(data) != ENCODED_SIG_ENABLE_MOD,
            "Cannot Enable Modules"
        );
        require(
            bytes4(data) != ENCODED_SIG_DISABLE_MOD,
            "Cannot Disable Modules"
        );
        require(bytes4(data) != ENCODED_SIG_SET_GUARD, "Cannot Change Guard");
    }

    /**
     * Removes the reverse registrar entry and disables module.
     * Intended as clean up during the safe ejection process.
     * Note that an already ejected safe cannot clear the reverse registry entry.
     */
    function disableModule(
        address safe,
        address reverseRegistrar,
        address previousModule
    ) internal {
        IGnosisSafe safeContract = IGnosisSafe(safe);

        // Note that you cannot clear the reverse registry entry of an already ejected safe.
        bytes memory nameData = abi.encodeWithSignature("setName(string)", "");
        safeContract.execTransactionFromModule(
            reverseRegistrar,
            0,
            nameData,
            IGnosisSafe.Operation.Call
        );

        // remove controller as guard
        bytes memory guardData = abi.encodeWithSignature(
            "setGuard(address)",
            address(0)
        );

        safeContract.execTransactionFromModule(
            safe,
            0,
            guardData,
            IGnosisSafe.Operation.Call
        );

        // disable module
        bytes memory moduleData = abi.encodeWithSignature(
            "disableModule(address,address)",
            previousModule,
            address(this)
        );

        safeContract.execTransactionFromModule(
            safe,
            0,
            moduleData,
            IGnosisSafe.Operation.Call
        );
    }

    // TODO: move to library
    // Used in a delegate call to enable module add on setup
    function enableModule(address module) external {
        require(module == address(0));
    }

    function delegateSetup(address _context) external {
        this.enableModule(_context);
    }
}

pragma solidity ^0.8.7;

interface IPodEnsRegistrar {
    function ens() external view returns (address);

    function resolver() external view returns (address);

    function reverseRegistrar() external view returns (address);

    function getRootNode() external view returns (bytes32);

    function registerPod(
        bytes32 label,
        address podSafe,
        address podCreator
    ) external returns (address);

    function register(bytes32 label, address owner) external;

    function deregister(address safe, bytes32 label) external;

    function setText(
        bytes32 node,
        string calldata key,
        string calldata value
    ) external;

    function setAddr(bytes32 node, address newAddress) external;

    function addressToNode(address input) external returns (bytes32);

    function getEnsNode(bytes32 label) external view returns (bytes32);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "../common/Enum.sol";
import "../common/SelfAuthorized.sol";
import "../interfaces/IERC165.sol";

interface Guard is IERC165 {
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external;

    function checkAfterExecution(bytes32 txHash, bool success) external;
}

abstract contract BaseGuard is Guard {
    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return
            interfaceId == type(Guard).interfaceId || // 0xe6d7a83a
            interfaceId == type(IERC165).interfaceId; // 0x01ffc9a7
    }
}

/// @title Fallback Manager - A contract that manages fallback calls made to this contract
/// @author Richard Meissner - <[email protected]>
contract GuardManager is SelfAuthorized {
    event ChangedGuard(address guard);
    // keccak256("guard_manager.guard.address")
    bytes32 internal constant GUARD_STORAGE_SLOT = 0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;

    /// @dev Set a guard that checks transactions before execution
    /// @param guard The address of the guard to be used or the 0 address to disable the guard
    function setGuard(address guard) external authorized {
        if (guard != address(0)) {
            require(Guard(guard).supportsInterface(type(Guard).interfaceId), "GS300");
        }
        bytes32 slot = GUARD_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, guard)
        }
        emit ChangedGuard(guard);
    }

    function getGuard() internal view returns (address guard) {
        bytes32 slot = GUARD_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            guard := sload(slot)
        }
    }
}

pragma solidity >=0.8.4;

interface IReverseRegistrar {
    function setDefaultResolver(address resolver) external;

    function claim(address owner) external returns (bytes32);

    function claimForAddr(
        address addr,
        address owner,
        address resolver
    ) external returns (bytes32);

    function claimWithResolver(address owner, address resolver)
        external
        returns (bytes32);

    function setName(string memory name) external returns (bytes32);

    function setNameForAddr(
        address addr,
        address owner,
        address resolver,
        string memory name
    ) external returns (bytes32);

    function node(address addr) external pure returns (bytes32);
}

pragma solidity ^0.8.4;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Controllable is Ownable {
    mapping(address => bool) public controllers;

    event ControllerChanged(address indexed controller, bool enabled);

    modifier onlyController {
        require(
            controllers[msg.sender],
            "Controllable: Caller is not a controller"
        );
        _;
    }

    function setController(address controller, bool enabled) public onlyOwner {
        controllers[controller] = enabled;
        emit ControllerChanged(controller, enabled);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IABIResolver.sol";
import "../ResolverBase.sol";

interface IABIResolver {
    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);
    /**
     * Returns the ABI associated with an ENS node.
     * Defined in EIP205.
     * @param node The ENS node to query
     * @param contentTypes A bitwise OR of the ABI formats accepted by the caller.
     * @return contentType The content type of the return value
     * @return data The ABI data
     */
    function ABI(bytes32 node, uint256 contentTypes) external view returns (uint256, bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/**
 * Interface for the new (multicoin) addr function.
 */
interface IAddressResolver {
    event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);

    function addr(bytes32 node, uint coinType) external view returns(bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/**
 * Interface for the legacy (ETH-only) addr function.
 */
interface IAddrResolver {
    event AddrChanged(bytes32 indexed node, address a);

    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) external view returns (address payable);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IContentHashResolver {
    event ContenthashChanged(bytes32 indexed node, bytes hash);

    /**
     * Returns the contenthash associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated contenthash.
     */
    function contenthash(bytes32 node) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IDNSRecordResolver {
    // DNSRecordChanged is emitted whenever a given node/name/resource's RRSET is updated.
    event DNSRecordChanged(bytes32 indexed node, bytes name, uint16 resource, bytes record);
    // DNSRecordDeleted is emitted whenever a given node/name/resource's RRSET is deleted.
    event DNSRecordDeleted(bytes32 indexed node, bytes name, uint16 resource);
    // DNSZoneCleared is emitted whenever a given node's zone information is cleared.
    event DNSZoneCleared(bytes32 indexed node);

    /**
     * Obtain a DNS record.
     * @param node the namehash of the node for which to fetch the record
     * @param name the keccak-256 hash of the fully-qualified name for which to fetch the record
     * @param resource the ID of the resource as per https://en.wikipedia.org/wiki/List_of_DNS_record_types
     * @return the DNS record in wire format if present, otherwise empty
     */
    function dnsRecord(bytes32 node, bytes32 name, uint16 resource) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IDNSZoneResolver {
    // DNSZonehashChanged is emitted whenever a given node's zone hash is updated.
    event DNSZonehashChanged(bytes32 indexed node, bytes lastzonehash, bytes zonehash);

    /**
     * zonehash obtains the hash for the zone.
     * @param node The ENS node to query.
     * @return The associated contenthash.
     */
    function zonehash(bytes32 node) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IInterfaceResolver {
    event InterfaceChanged(bytes32 indexed node, bytes4 indexed interfaceID, address implementer);

    /**
     * Returns the address of a contract that implements the specified interface for this name.
     * If an implementer has not been set for this interfaceID and name, the resolver will query
     * the contract at `addr()`. If `addr()` is set, a contract exists at that address, and that
     * contract implements EIP165 and returns `true` for the specified interfaceID, its address
     * will be returned.
     * @param node The ENS node to query.
     * @param interfaceID The EIP 165 interface ID to check for.
     * @return The address that implements this interface, or 0 if the interface is unsupported.
     */
    function interfaceImplementer(bytes32 node, bytes4 interfaceID) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface INameResolver {
    event NameChanged(bytes32 indexed node, string name);

    /**
     * Returns the name associated with an ENS node, for reverse records.
     * Defined in EIP181.
     * @param node The ENS node to query.
     * @return The associated name.
     */
    function name(bytes32 node) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IPubkeyResolver {
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);

    /**
     * Returns the SECP256k1 public key associated with an ENS node.
     * Defined in EIP 619.
     * @param node The ENS node to query
     * @return x The X coordinate of the curve point for the public key.
     * @return y The Y coordinate of the curve point for the public key.
     */
    function pubkey(bytes32 node) external view returns (bytes32 x, bytes32 y);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface ITextResolver {
    event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);

    /**
     * Returns the text data associated with an ENS node and key.
     * @param node The ENS node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function text(bytes32 node, string calldata key) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IExtendedResolver {
    function resolve(bytes memory name, bytes memory data)
        external
        view
        returns (bytes memory, address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";

abstract contract ResolverBase is ERC165 {
    function isAuthorised(bytes32 node) internal virtual view returns(bool);

    modifier authorised(bytes32 node) {
        require(isAuthorised(node));
        _;
    }
}

pragma solidity ^0.8.7;

interface IGnosisSafe {
    enum Operation {
        Call,
        DelegateCall
    }

    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation
    ) external returns (bool success);

    /// @dev Returns array of owners.
    /// @return Array of Safe owners.
    function getOwners() external view returns (address[] memory);

    function isOwner(address owner) external view returns (bool);

    function getThreshold() external returns (uint256);

    /// @dev Returns array of modules.
    /// @param start Start of the page.
    /// @param pageSize Maximum number of modules that should be returned.
    /// @return array Array of modules.
    /// @return next Start of the next page.
    function getModulesPaginated(address start, uint256 pageSize)
        external
        view
        returns (address[] memory array, address next);

    /// @dev Returns if an module is enabled
    /// @return True if the module is enabled
    function isModuleEnabled(address module) external view returns (bool);

    /// @dev Set a guard that checks transactions before execution
    /// @param guard The address of the guard to be used or the 0 address to disable the guard
    function setGuard(address guard) external;

    function disableModule(address prevModule, address module) external;
}

pragma solidity ^0.8.7;

interface IGnosisSafeProxyFactory {
    /// @dev Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
    /// @param singleton Address of singleton contract.
    /// @param data Payload for message call sent to new proxy contract.
    function createProxy(address singleton, bytes memory data)
        external
        returns (address);

    function createProxyWithNonce(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce
    ) external returns (address);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {Call, DelegateCall}
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title SelfAuthorized - authorizes current contract to perform actions
/// @author Richard Meissner - <[email protected]>
contract SelfAuthorized {
    function requireSelfCall() private view {
        require(msg.sender == address(this), "GS031");
    }

    modifier authorized() {
        // This is a function call as it minimized the bytecode size
        requireSelfCall();
        _;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @notice More details at https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol
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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "./base/ModuleManager.sol";
import "./base/OwnerManager.sol";
import "./base/FallbackManager.sol";
import "./base/GuardManager.sol";
import "./common/EtherPaymentFallback.sol";
import "./common/Singleton.sol";
import "./common/SignatureDecoder.sol";
import "./common/SecuredTokenTransfer.sol";
import "./common/StorageAccessible.sol";
import "./interfaces/ISignatureValidator.sol";
import "./external/GnosisSafeMath.sol";

/// @title Gnosis Safe - A multisignature wallet with support for confirmations using signed messages based on ERC191.
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
contract GnosisSafe is
    EtherPaymentFallback,
    Singleton,
    ModuleManager,
    OwnerManager,
    SignatureDecoder,
    SecuredTokenTransfer,
    ISignatureValidatorConstants,
    FallbackManager,
    StorageAccessible,
    GuardManager
{
    using GnosisSafeMath for uint256;

    string public constant VERSION = "1.3.0";

    // keccak256(
    //     "EIP712Domain(uint256 chainId,address verifyingContract)"
    // );
    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH = 0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218;

    // keccak256(
    //     "SafeTx(address to,uint256 value,bytes data,uint8 operation,uint256 safeTxGas,uint256 baseGas,uint256 gasPrice,address gasToken,address refundReceiver,uint256 nonce)"
    // );
    bytes32 private constant SAFE_TX_TYPEHASH = 0xbb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8;

    event SafeSetup(address indexed initiator, address[] owners, uint256 threshold, address initializer, address fallbackHandler);
    event ApproveHash(bytes32 indexed approvedHash, address indexed owner);
    event SignMsg(bytes32 indexed msgHash);
    event ExecutionFailure(bytes32 txHash, uint256 payment);
    event ExecutionSuccess(bytes32 txHash, uint256 payment);

    uint256 public nonce;
    bytes32 private _deprecatedDomainSeparator;
    // Mapping to keep track of all message hashes that have been approved by ALL REQUIRED owners
    mapping(bytes32 => uint256) public signedMessages;
    // Mapping to keep track of all hashes (message or transaction) that have been approved by ANY owners
    mapping(address => mapping(bytes32 => uint256)) public approvedHashes;

    // This constructor ensures that this contract can only be used as a master copy for Proxy contracts
    constructor() {
        // By setting the threshold it is not possible to call setup anymore,
        // so we create a Safe with 0 owners and threshold 1.
        // This is an unusable Safe, perfect for the singleton
        threshold = 1;
    }

    /// @dev Setup function sets initial storage of contract.
    /// @param _owners List of Safe owners.
    /// @param _threshold Number of required confirmations for a Safe transaction.
    /// @param to Contract address for optional delegate call.
    /// @param data Data payload for optional delegate call.
    /// @param fallbackHandler Handler for fallback calls to this contract
    /// @param paymentToken Token that should be used for the payment (0 is ETH)
    /// @param payment Value that should be paid
    /// @param paymentReceiver Address that should receive the payment (or 0 if tx.origin)
    function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external {
        // setupOwners checks if the Threshold is already set, therefore preventing that this method is called twice
        setupOwners(_owners, _threshold);
        if (fallbackHandler != address(0)) internalSetFallbackHandler(fallbackHandler);
        // As setupOwners can only be called if the contract has not been initialized we don't need a check for setupModules
        setupModules(to, data);

        if (payment > 0) {
            // To avoid running into issues with EIP-170 we reuse the handlePayment function (to avoid adjusting code of that has been verified we do not adjust the method itself)
            // baseGas = 0, gasPrice = 1 and gas = payment => amount = (payment + 0) * 1 = payment
            handlePayment(payment, 0, 1, paymentToken, paymentReceiver);
        }
        emit SafeSetup(msg.sender, _owners, _threshold, to, fallbackHandler);
    }

    /// @dev Allows to execute a Safe transaction confirmed by required number of owners and then pays the account that submitted the transaction.
    ///      Note: The fees are always transferred, even if the user transaction fails.
    /// @param to Destination address of Safe transaction.
    /// @param value Ether value of Safe transaction.
    /// @param data Data payload of Safe transaction.
    /// @param operation Operation type of Safe transaction.
    /// @param safeTxGas Gas that should be used for the Safe transaction.
    /// @param baseGas Gas costs that are independent of the transaction execution(e.g. base transaction fee, signature check, payment of the refund)
    /// @param gasPrice Gas price that should be used for the payment calculation.
    /// @param gasToken Token address (or 0 if ETH) that is used for the payment.
    /// @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
    /// @param signatures Packed signature data ({bytes32 r}{bytes32 s}{uint8 v})
    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures
    ) public payable virtual returns (bool success) {
        bytes32 txHash;
        // Use scope here to limit variable lifetime and prevent `stack too deep` errors
        {
            bytes memory txHashData =
                encodeTransactionData(
                    // Transaction info
                    to,
                    value,
                    data,
                    operation,
                    safeTxGas,
                    // Payment info
                    baseGas,
                    gasPrice,
                    gasToken,
                    refundReceiver,
                    // Signature info
                    nonce
                );
            // Increase nonce and execute transaction.
            nonce++;
            txHash = keccak256(txHashData);
            checkSignatures(txHash, txHashData, signatures);
        }
        address guard = getGuard();
        {
            if (guard != address(0)) {
                Guard(guard).checkTransaction(
                    // Transaction info
                    to,
                    value,
                    data,
                    operation,
                    safeTxGas,
                    // Payment info
                    baseGas,
                    gasPrice,
                    gasToken,
                    refundReceiver,
                    // Signature info
                    signatures,
                    msg.sender
                );
            }
        }
        // We require some gas to emit the events (at least 2500) after the execution and some to perform code until the execution (500)
        // We also include the 1/64 in the check that is not send along with a call to counteract potential shortings because of EIP-150
        require(gasleft() >= ((safeTxGas * 64) / 63).max(safeTxGas + 2500) + 500, "GS010");
        // Use scope here to limit variable lifetime and prevent `stack too deep` errors
        {
            uint256 gasUsed = gasleft();
            // If the gasPrice is 0 we assume that nearly all available gas can be used (it is always more than safeTxGas)
            // We only substract 2500 (compared to the 3000 before) to ensure that the amount passed is still higher than safeTxGas
            success = execute(to, value, data, operation, gasPrice == 0 ? (gasleft() - 2500) : safeTxGas);
            gasUsed = gasUsed.sub(gasleft());
            // If no safeTxGas and no gasPrice was set (e.g. both are 0), then the internal tx is required to be successful
            // This makes it possible to use `estimateGas` without issues, as it searches for the minimum gas where the tx doesn't revert
            require(success || safeTxGas != 0 || gasPrice != 0, "GS013");
            // We transfer the calculated tx costs to the tx.origin to avoid sending it to intermediate contracts that have made calls
            uint256 payment = 0;
            if (gasPrice > 0) {
                payment = handlePayment(gasUsed, baseGas, gasPrice, gasToken, refundReceiver);
            }
            if (success) emit ExecutionSuccess(txHash, payment);
            else emit ExecutionFailure(txHash, payment);
        }
        {
            if (guard != address(0)) {
                Guard(guard).checkAfterExecution(txHash, success);
            }
        }
    }

    function handlePayment(
        uint256 gasUsed,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver
    ) private returns (uint256 payment) {
        // solhint-disable-next-line avoid-tx-origin
        address payable receiver = refundReceiver == address(0) ? payable(tx.origin) : refundReceiver;
        if (gasToken == address(0)) {
            // For ETH we will only adjust the gas price to not be higher than the actual used gas price
            payment = gasUsed.add(baseGas).mul(gasPrice < tx.gasprice ? gasPrice : tx.gasprice);
            require(receiver.send(payment), "GS011");
        } else {
            payment = gasUsed.add(baseGas).mul(gasPrice);
            require(transferToken(gasToken, receiver, payment), "GS012");
        }
    }

    /**
     * @dev Checks whether the signature provided is valid for the provided data, hash. Will revert otherwise.
     * @param dataHash Hash of the data (could be either a message hash or transaction hash)
     * @param data That should be signed (this is passed to an external validator contract)
     * @param signatures Signature data that should be verified. Can be ECDSA signature, contract signature (EIP-1271) or approved hash.
     */
    function checkSignatures(
        bytes32 dataHash,
        bytes memory data,
        bytes memory signatures
    ) public view {
        // Load threshold to avoid multiple storage loads
        uint256 _threshold = threshold;
        // Check that a threshold is set
        require(_threshold > 0, "GS001");
        checkNSignatures(dataHash, data, signatures, _threshold);
    }

    /**
     * @dev Checks whether the signature provided is valid for the provided data, hash. Will revert otherwise.
     * @param dataHash Hash of the data (could be either a message hash or transaction hash)
     * @param data That should be signed (this is passed to an external validator contract)
     * @param signatures Signature data that should be verified. Can be ECDSA signature, contract signature (EIP-1271) or approved hash.
     * @param requiredSignatures Amount of required valid signatures.
     */
    function checkNSignatures(
        bytes32 dataHash,
        bytes memory data,
        bytes memory signatures,
        uint256 requiredSignatures
    ) public view {
        // Check that the provided signature data is not too short
        require(signatures.length >= requiredSignatures.mul(65), "GS020");
        // There cannot be an owner with address 0.
        address lastOwner = address(0);
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for (i = 0; i < requiredSignatures; i++) {
            (v, r, s) = signatureSplit(signatures, i);
            if (v == 0) {
                // If v is 0 then it is a contract signature
                // When handling contract signatures the address of the contract is encoded into r
                currentOwner = address(uint160(uint256(r)));

                // Check that signature data pointer (s) is not pointing inside the static part of the signatures bytes
                // This check is not completely accurate, since it is possible that more signatures than the threshold are send.
                // Here we only check that the pointer is not pointing inside the part that is being processed
                require(uint256(s) >= requiredSignatures.mul(65), "GS021");

                // Check that signature data pointer (s) is in bounds (points to the length of data -> 32 bytes)
                require(uint256(s).add(32) <= signatures.length, "GS022");

                // Check if the contract signature is in bounds: start of data is s + 32 and end is start + signature length
                uint256 contractSignatureLen;
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    contractSignatureLen := mload(add(add(signatures, s), 0x20))
                }
                require(uint256(s).add(32).add(contractSignatureLen) <= signatures.length, "GS023");

                // Check signature
                bytes memory contractSignature;
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    // The signature data for contract signatures is appended to the concatenated signatures and the offset is stored in s
                    contractSignature := add(add(signatures, s), 0x20)
                }
                require(ISignatureValidator(currentOwner).isValidSignature(data, contractSignature) == EIP1271_MAGIC_VALUE, "GS024");
            } else if (v == 1) {
                // If v is 1 then it is an approved hash
                // When handling approved hashes the address of the approver is encoded into r
                currentOwner = address(uint160(uint256(r)));
                // Hashes are automatically approved by the sender of the message or when they have been pre-approved via a separate transaction
                require(msg.sender == currentOwner || approvedHashes[currentOwner][dataHash] != 0, "GS025");
            } else if (v > 30) {
                // If v > 30 then default va (27,28) has been adjusted for eth_sign flow
                // To support eth_sign and similar we adjust v and hash the messageHash with the Ethereum message prefix before applying ecrecover
                currentOwner = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v - 4, r, s);
            } else {
                // Default is the ecrecover flow with the provided data hash
                // Use ecrecover with the messageHash for EOA signatures
                currentOwner = ecrecover(dataHash, v, r, s);
            }
            require(currentOwner > lastOwner && owners[currentOwner] != address(0) && currentOwner != SENTINEL_OWNERS, "GS026");
            lastOwner = currentOwner;
        }
    }

    /// @dev Allows to estimate a Safe transaction.
    ///      This method is only meant for estimation purpose, therefore the call will always revert and encode the result in the revert data.
    ///      Since the `estimateGas` function includes refunds, call this method to get an estimated of the costs that are deducted from the safe with `execTransaction`
    /// @param to Destination address of Safe transaction.
    /// @param value Ether value of Safe transaction.
    /// @param data Data payload of Safe transaction.
    /// @param operation Operation type of Safe transaction.
    /// @return Estimate without refunds and overhead fees (base transaction and payload data gas costs).
    /// @notice Deprecated in favor of common/StorageAccessible.sol and will be removed in next version.
    function requiredTxGas(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) external returns (uint256) {
        uint256 startGas = gasleft();
        // We don't provide an error message here, as we use it to return the estimate
        require(execute(to, value, data, operation, gasleft()));
        uint256 requiredGas = startGas - gasleft();
        // Convert response to string and return via error message
        revert(string(abi.encodePacked(requiredGas)));
    }

    /**
     * @dev Marks a hash as approved. This can be used to validate a hash that is used by a signature.
     * @param hashToApprove The hash that should be marked as approved for signatures that are verified by this contract.
     */
    function approveHash(bytes32 hashToApprove) external {
        require(owners[msg.sender] != address(0), "GS030");
        approvedHashes[msg.sender][hashToApprove] = 1;
        emit ApproveHash(hashToApprove, msg.sender);
    }

    /// @dev Returns the chain id used by this contract.
    function getChainId() public view returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }

    function domainSeparator() public view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, getChainId(), this));
    }

    /// @dev Returns the bytes that are hashed to be signed by owners.
    /// @param to Destination address.
    /// @param value Ether value.
    /// @param data Data payload.
    /// @param operation Operation type.
    /// @param safeTxGas Gas that should be used for the safe transaction.
    /// @param baseGas Gas costs for that are independent of the transaction execution(e.g. base transaction fee, signature check, payment of the refund)
    /// @param gasPrice Maximum gas price that should be used for this transaction.
    /// @param gasToken Token address (or 0 if ETH) that is used for the payment.
    /// @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
    /// @param _nonce Transaction nonce.
    /// @return Transaction hash bytes.
    function encodeTransactionData(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) public view returns (bytes memory) {
        bytes32 safeTxHash =
            keccak256(
                abi.encode(
                    SAFE_TX_TYPEHASH,
                    to,
                    value,
                    keccak256(data),
                    operation,
                    safeTxGas,
                    baseGas,
                    gasPrice,
                    gasToken,
                    refundReceiver,
                    _nonce
                )
            );
        return abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator(), safeTxHash);
    }

    /// @dev Returns hash to be signed by owners.
    /// @param to Destination address.
    /// @param value Ether value.
    /// @param data Data payload.
    /// @param operation Operation type.
    /// @param safeTxGas Fas that should be used for the safe transaction.
    /// @param baseGas Gas costs for data used to trigger the safe transaction.
    /// @param gasPrice Maximum gas price that should be used for this transaction.
    /// @param gasToken Token address (or 0 if ETH) that is used for the payment.
    /// @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
    /// @param _nonce Transaction nonce.
    /// @return Transaction hash.
    function getTransactionHash(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) public view returns (bytes32) {
        return keccak256(encodeTransactionData(to, value, data, operation, safeTxGas, baseGas, gasPrice, gasToken, refundReceiver, _nonce));
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "../common/Enum.sol";
import "../common/SelfAuthorized.sol";
import "./Executor.sol";

/// @title Module Manager - A contract that manages modules that can execute transactions via this contract
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
contract ModuleManager is SelfAuthorized, Executor {
    event EnabledModule(address module);
    event DisabledModule(address module);
    event ExecutionFromModuleSuccess(address indexed module);
    event ExecutionFromModuleFailure(address indexed module);

    address internal constant SENTINEL_MODULES = address(0x1);

    mapping(address => address) internal modules;

    function setupModules(address to, bytes memory data) internal {
        require(modules[SENTINEL_MODULES] == address(0), "GS100");
        modules[SENTINEL_MODULES] = SENTINEL_MODULES;
        if (to != address(0))
            // Setup has to complete successfully or transaction fails.
            require(execute(to, 0, data, Enum.Operation.DelegateCall, gasleft()), "GS000");
    }

    /// @dev Allows to add a module to the whitelist.
    ///      This can only be done via a Safe transaction.
    /// @notice Enables the module `module` for the Safe.
    /// @param module Module to be whitelisted.
    function enableModule(address module) public authorized {
        // Module address cannot be null or sentinel.
        require(module != address(0) && module != SENTINEL_MODULES, "GS101");
        // Module cannot be added twice.
        require(modules[module] == address(0), "GS102");
        modules[module] = modules[SENTINEL_MODULES];
        modules[SENTINEL_MODULES] = module;
        emit EnabledModule(module);
    }

    /// @dev Allows to remove a module from the whitelist.
    ///      This can only be done via a Safe transaction.
    /// @notice Disables the module `module` for the Safe.
    /// @param prevModule Module that pointed to the module to be removed in the linked list
    /// @param module Module to be removed.
    function disableModule(address prevModule, address module) public authorized {
        // Validate module address and check that it corresponds to module index.
        require(module != address(0) && module != SENTINEL_MODULES, "GS101");
        require(modules[prevModule] == module, "GS103");
        modules[prevModule] = modules[module];
        modules[module] = address(0);
        emit DisabledModule(module);
    }

    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) public virtual returns (bool success) {
        // Only whitelisted modules are allowed.
        require(msg.sender != SENTINEL_MODULES && modules[msg.sender] != address(0), "GS104");
        // Execute transaction without further confirmations.
        success = execute(to, value, data, operation, gasleft());
        if (success) emit ExecutionFromModuleSuccess(msg.sender);
        else emit ExecutionFromModuleFailure(msg.sender);
    }

    /// @dev Allows a Module to execute a Safe transaction without any further confirmations and return data
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) public returns (bool success, bytes memory returnData) {
        success = execTransactionFromModule(to, value, data, operation);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Load free memory location
            let ptr := mload(0x40)
            // We allocate memory for the return data by setting the free memory location to
            // current free memory location + data size + 32 bytes for data size value
            mstore(0x40, add(ptr, add(returndatasize(), 0x20)))
            // Store the size
            mstore(ptr, returndatasize())
            // Store the data
            returndatacopy(add(ptr, 0x20), 0, returndatasize())
            // Point the return data to the correct memory location
            returnData := ptr
        }
    }

    /// @dev Returns if an module is enabled
    /// @return True if the module is enabled
    function isModuleEnabled(address module) public view returns (bool) {
        return SENTINEL_MODULES != module && modules[module] != address(0);
    }

    /// @dev Returns array of modules.
    /// @param start Start of the page.
    /// @param pageSize Maximum number of modules that should be returned.
    /// @return array Array of modules.
    /// @return next Start of the next page.
    function getModulesPaginated(address start, uint256 pageSize) external view returns (address[] memory array, address next) {
        // Init array with max page size
        array = new address[](pageSize);

        // Populate return array
        uint256 moduleCount = 0;
        address currentModule = modules[start];
        while (currentModule != address(0x0) && currentModule != SENTINEL_MODULES && moduleCount < pageSize) {
            array[moduleCount] = currentModule;
            currentModule = modules[currentModule];
            moduleCount++;
        }
        next = currentModule;
        // Set correct size of returned array
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(array, moduleCount)
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "../common/SelfAuthorized.sol";

/// @title OwnerManager - Manages a set of owners and a threshold to perform actions.
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
contract OwnerManager is SelfAuthorized {
    event AddedOwner(address owner);
    event RemovedOwner(address owner);
    event ChangedThreshold(uint256 threshold);

    address internal constant SENTINEL_OWNERS = address(0x1);

    mapping(address => address) internal owners;
    uint256 internal ownerCount;
    uint256 internal threshold;

    /// @dev Setup function sets initial storage of contract.
    /// @param _owners List of Safe owners.
    /// @param _threshold Number of required confirmations for a Safe transaction.
    function setupOwners(address[] memory _owners, uint256 _threshold) internal {
        // Threshold can only be 0 at initialization.
        // Check ensures that setup function can only be called once.
        require(threshold == 0, "GS200");
        // Validate that threshold is smaller than number of added owners.
        require(_threshold <= _owners.length, "GS201");
        // There has to be at least one Safe owner.
        require(_threshold >= 1, "GS202");
        // Initializing Safe owners.
        address currentOwner = SENTINEL_OWNERS;
        for (uint256 i = 0; i < _owners.length; i++) {
            // Owner address cannot be null.
            address owner = _owners[i];
            require(owner != address(0) && owner != SENTINEL_OWNERS && owner != address(this) && currentOwner != owner, "GS203");
            // No duplicate owners allowed.
            require(owners[owner] == address(0), "GS204");
            owners[currentOwner] = owner;
            currentOwner = owner;
        }
        owners[currentOwner] = SENTINEL_OWNERS;
        ownerCount = _owners.length;
        threshold = _threshold;
    }

    /// @dev Allows to add a new owner to the Safe and update the threshold at the same time.
    ///      This can only be done via a Safe transaction.
    /// @notice Adds the owner `owner` to the Safe and updates the threshold to `_threshold`.
    /// @param owner New owner address.
    /// @param _threshold New threshold.
    function addOwnerWithThreshold(address owner, uint256 _threshold) public authorized {
        // Owner address cannot be null, the sentinel or the Safe itself.
        require(owner != address(0) && owner != SENTINEL_OWNERS && owner != address(this), "GS203");
        // No duplicate owners allowed.
        require(owners[owner] == address(0), "GS204");
        owners[owner] = owners[SENTINEL_OWNERS];
        owners[SENTINEL_OWNERS] = owner;
        ownerCount++;
        emit AddedOwner(owner);
        // Change threshold if threshold was changed.
        if (threshold != _threshold) changeThreshold(_threshold);
    }

    /// @dev Allows to remove an owner from the Safe and update the threshold at the same time.
    ///      This can only be done via a Safe transaction.
    /// @notice Removes the owner `owner` from the Safe and updates the threshold to `_threshold`.
    /// @param prevOwner Owner that pointed to the owner to be removed in the linked list
    /// @param owner Owner address to be removed.
    /// @param _threshold New threshold.
    function removeOwner(
        address prevOwner,
        address owner,
        uint256 _threshold
    ) public authorized {
        // Only allow to remove an owner, if threshold can still be reached.
        require(ownerCount - 1 >= _threshold, "GS201");
        // Validate owner address and check that it corresponds to owner index.
        require(owner != address(0) && owner != SENTINEL_OWNERS, "GS203");
        require(owners[prevOwner] == owner, "GS205");
        owners[prevOwner] = owners[owner];
        owners[owner] = address(0);
        ownerCount--;
        emit RemovedOwner(owner);
        // Change threshold if threshold was changed.
        if (threshold != _threshold) changeThreshold(_threshold);
    }

    /// @dev Allows to swap/replace an owner from the Safe with another address.
    ///      This can only be done via a Safe transaction.
    /// @notice Replaces the owner `oldOwner` in the Safe with `newOwner`.
    /// @param prevOwner Owner that pointed to the owner to be replaced in the linked list
    /// @param oldOwner Owner address to be replaced.
    /// @param newOwner New owner address.
    function swapOwner(
        address prevOwner,
        address oldOwner,
        address newOwner
    ) public authorized {
        // Owner address cannot be null, the sentinel or the Safe itself.
        require(newOwner != address(0) && newOwner != SENTINEL_OWNERS && newOwner != address(this), "GS203");
        // No duplicate owners allowed.
        require(owners[newOwner] == address(0), "GS204");
        // Validate oldOwner address and check that it corresponds to owner index.
        require(oldOwner != address(0) && oldOwner != SENTINEL_OWNERS, "GS203");
        require(owners[prevOwner] == oldOwner, "GS205");
        owners[newOwner] = owners[oldOwner];
        owners[prevOwner] = newOwner;
        owners[oldOwner] = address(0);
        emit RemovedOwner(oldOwner);
        emit AddedOwner(newOwner);
    }

    /// @dev Allows to update the number of required confirmations by Safe owners.
    ///      This can only be done via a Safe transaction.
    /// @notice Changes the threshold of the Safe to `_threshold`.
    /// @param _threshold New threshold.
    function changeThreshold(uint256 _threshold) public authorized {
        // Validate that threshold is smaller than number of owners.
        require(_threshold <= ownerCount, "GS201");
        // There has to be at least one Safe owner.
        require(_threshold >= 1, "GS202");
        threshold = _threshold;
        emit ChangedThreshold(threshold);
    }

    function getThreshold() public view returns (uint256) {
        return threshold;
    }

    function isOwner(address owner) public view returns (bool) {
        return owner != SENTINEL_OWNERS && owners[owner] != address(0);
    }

    /// @dev Returns array of owners.
    /// @return Array of Safe owners.
    function getOwners() public view returns (address[] memory) {
        address[] memory array = new address[](ownerCount);

        // populate return array
        uint256 index = 0;
        address currentOwner = owners[SENTINEL_OWNERS];
        while (currentOwner != SENTINEL_OWNERS) {
            array[index] = currentOwner;
            currentOwner = owners[currentOwner];
            index++;
        }
        return array;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "../common/SelfAuthorized.sol";

/// @title Fallback Manager - A contract that manages fallback calls made to this contract
/// @author Richard Meissner - <[email protected]>
contract FallbackManager is SelfAuthorized {
    event ChangedFallbackHandler(address handler);

    // keccak256("fallback_manager.handler.address")
    bytes32 internal constant FALLBACK_HANDLER_STORAGE_SLOT = 0x6c9a6c4a39284e37ed1cf53d337577d14212a4870fb976a4366c693b939918d5;

    function internalSetFallbackHandler(address handler) internal {
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, handler)
        }
    }

    /// @dev Allows to add a contract to handle fallback calls.
    ///      Only fallback calls without value and with data will be forwarded.
    ///      This can only be done via a Safe transaction.
    /// @param handler contract to handle fallback calls.
    function setFallbackHandler(address handler) public authorized {
        internalSetFallbackHandler(handler);
        emit ChangedFallbackHandler(handler);
    }

    // solhint-disable-next-line payable-fallback,no-complex-fallback
    fallback() external {
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let handler := sload(slot)
            if iszero(handler) {
                return(0, 0)
            }
            calldatacopy(0, 0, calldatasize())
            // The msg.sender address is shifted to the left by 12 bytes to remove the padding
            // Then the address without padding is stored right after the calldata
            mstore(calldatasize(), shl(96, caller()))
            // Add 20 bytes for the address appended add the end
            let success := call(gas(), handler, 0, 0, add(calldatasize(), 20), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if iszero(success) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title EtherPaymentFallback - A contract that has a fallback to accept ether payments
/// @author Richard Meissner - <[email protected]>
contract EtherPaymentFallback {
    event SafeReceived(address indexed sender, uint256 value);

    /// @dev Fallback function accepts Ether transactions.
    receive() external payable {
        emit SafeReceived(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Singleton - Base for singleton contracts (should always be first super contract)
///         This contract is tightly coupled to our proxy contract (see `proxies/GnosisSafeProxy.sol`)
/// @author Richard Meissner - <[email protected]>
contract Singleton {
    // singleton always needs to be first declared variable, to ensure that it is at the same location as in the Proxy contract.
    // It should also always be ensured that the address is stored alone (uses a full word)
    address private singleton;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title SignatureDecoder - Decodes signatures that a encoded as bytes
/// @author Richard Meissner - <[email protected]>
contract SignatureDecoder {
    /// @dev divides bytes signature into `uint8 v, bytes32 r, bytes32 s`.
    /// @notice Make sure to perform a bounds check for @param pos, to avoid out of bounds access on @param signatures
    /// @param pos which signature to read. A prior bounds check of this parameter should be performed, to avoid out of bounds access
    /// @param signatures concatenated rsv signatures
    function signatureSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            // Here we are loading the last 32 bytes, including 31 bytes
            // of 's'. There is no 'mload8' to do this.
            //
            // 'byte' is not working due to the Solidity parser, so lets
            // use the second best option, 'and'
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title SecuredTokenTransfer - Secure token transfer
/// @author Richard Meissner - <[email protected]>
contract SecuredTokenTransfer {
    /// @dev Transfers a token and returns if it was a success
    /// @param token Token that should be transferred
    /// @param receiver Receiver to whom the token should be transferred
    /// @param amount The amount of tokens that should be transferred
    function transferToken(
        address token,
        address receiver,
        uint256 amount
    ) internal returns (bool transferred) {
        // 0xa9059cbb - keccack("transfer(address,uint256)")
        bytes memory data = abi.encodeWithSelector(0xa9059cbb, receiver, amount);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // We write the return value to scratch space.
            // See https://docs.soliditylang.org/en/v0.7.6/internals/layout_in_memory.html#layout-in-memory
            let success := call(sub(gas(), 10000), token, 0, add(data, 0x20), mload(data), 0, 0x20)
            switch returndatasize()
                case 0 {
                    transferred := success
                }
                case 0x20 {
                    transferred := iszero(or(iszero(success), iszero(mload(0))))
                }
                default {
                    transferred := 0
                }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title StorageAccessible - generic base contract that allows callers to access all internal storage.
/// @notice See https://github.com/gnosis/util-contracts/blob/bb5fe5fb5df6d8400998094fb1b32a178a47c3a1/contracts/StorageAccessible.sol
contract StorageAccessible {
    /**
     * @dev Reads `length` bytes of storage in the currents contract
     * @param offset - the offset in the current contract's storage in words to start reading from
     * @param length - the number of words (32 bytes) of data to read
     * @return the bytes that were read.
     */
    function getStorageAt(uint256 offset, uint256 length) public view returns (bytes memory) {
        bytes memory result = new bytes(length * 32);
        for (uint256 index = 0; index < length; index++) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let word := sload(add(offset, index))
                mstore(add(add(result, 0x20), mul(index, 0x20)), word)
            }
        }
        return result;
    }

    /**
     * @dev Performs a delegatecall on a targetContract in the context of self.
     * Internally reverts execution to avoid side effects (making it static).
     *
     * This method reverts with data equal to `abi.encode(bool(success), bytes(response))`.
     * Specifically, the `returndata` after a call to this method will be:
     * `success:bool || response.length:uint256 || response:bytes`.
     *
     * @param targetContract Address of the contract containing the code to execute.
     * @param calldataPayload Calldata that should be sent to the target contract (encoded method name and arguments).
     */
    function simulateAndRevert(address targetContract, bytes memory calldataPayload) external {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let success := delegatecall(gas(), targetContract, add(calldataPayload, 0x20), mload(calldataPayload), 0, 0)

            mstore(0x00, success)
            mstore(0x20, returndatasize())
            returndatacopy(0x40, 0, returndatasize())
            revert(0, add(returndatasize(), 0x40))
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

contract ISignatureValidatorConstants {
    // bytes4(keccak256("isValidSignature(bytes,bytes)")
    bytes4 internal constant EIP1271_MAGIC_VALUE = 0x20c13b0b;
}

abstract contract ISignatureValidator is ISignatureValidatorConstants {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param _data Arbitrary length data signed on the behalf of address(this)
     * @param _signature Signature byte array associated with _data
     *
     * MUST return the bytes4 magic value 0x20c13b0b when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(bytes memory _data, bytes memory _signature) public view virtual returns (bytes4);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title GnosisSafeMath
 * @dev Math operations with safety checks that revert on error
 * Renamed from SafeMath to GnosisSafeMath to avoid conflicts
 * TODO: remove once open zeppelin update to solc 0.5.0
 */
library GnosisSafeMath {
    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "../common/Enum.sol";

/// @title Executor - A contract that can execute transactions
/// @author Richard Meissner - <[email protected]>
contract Executor {
    function execute(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 txGas
    ) internal returns (bool success) {
        if (operation == Enum.Operation.DelegateCall) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := delegatecall(txGas, to, add(data, 0x20), mload(data), 0, 0)
            }
        } else {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
import "lib/safe-contracts/contracts/common/Enum.sol";
import "lib/safe-contracts/contracts/GnosisSafe.sol";

// used to help generate Txs for onchain approvals
/* 
    bytes32 txHash = getSafeTxHash(...);
    safe.approveHash(txHash);
    executeSafeTxFrom(...);
*/

contract SafeTxHelper {
    function getSafeTxHash(
        address to,
        bytes memory data,
        GnosisSafe safe
    ) public view returns (bytes32 txHash) {
        return
            safe.getTransactionHash(
                to,
                0,
                data,
                Enum.Operation.Call,
                // not using the refunder
                0,
                0,
                0,
                address(0),
                payable(address(0)),
                safe.nonce()
            );
    }

    function executeSafeTxFrom(
        address from,
        bytes memory data,
        GnosisSafe safe
    ) public {
        safe.execTransaction(
            address(safe),
            0,
            data,
            Enum.Operation.Call,
            // not using the refunder
            0,
            0,
            0,
            address(0),
            payable(address(0)),
            // (r,s,v) [r - from] [s - unused] [v - 1 flag for onchain approval]
            abi.encode(from, bytes32(0), bytes1(0x01))
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

pragma solidity ^0.8.7;

import "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

// This contract will be the owner of all other contracts in the ecosystem.
contract PermissionManager is AccessControl {
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Checks roles, and then call
    function callAsOwner(address contractAddress, bytes memory data)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // Call uses the context of this contract, so msg.sender of other contracts
        // will be this contract.
        (bool success, ) = contractAddress.call(data);
        require(success, "call failed");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.7;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IInviteToken is IERC20 {
    function batchMint(address[] calldata accounts, uint256 amount) external;

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

pragma solidity 0.8.7;

import "lib/ens-contracts/contracts/registry/ENS.sol";
import "lib/ens-contracts/contracts/registry/ReverseRegistrar.sol";
import "lib/ens-contracts/contracts/resolvers/Resolver.sol";
import "../interfaces/IControllerRegistry.sol";
import "../interfaces/IInviteToken.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * A registrar that allocates subdomains to the first person to claim them.
 */
contract PodEnsRegistrar is Ownable {
    modifier onlyControllerOrOwner() {
        require(
            controllerRegistry.isRegistered(msg.sender) ||
                owner() == msg.sender,
            "sender must be controller/owner"
        );
        _;
    }

    enum State {
        onlySafeWithShip, // Only safes with SHIP token
        onlyShip, // Anyone with SHIP token
        open, // Anyone can enroll
        closed // Nobody can enroll, just in case
    }

    ENS public ens;
    Resolver public resolver;
    ReverseRegistrar public reverseRegistrar;
    IControllerRegistry controllerRegistry;
    bytes32 rootNode;
    IInviteToken inviteToken;
    State public state = State.onlySafeWithShip;

    /**
     * Constructor.
     * @param ensAddr The address of the ENS registry.
     * @param node The node that this registrar administers.
     */
    constructor(
        ENS ensAddr,
        Resolver resolverAddr,
        ReverseRegistrar _reverseRegistrar,
        IControllerRegistry controllerRegistryAddr,
        bytes32 node,
        IInviteToken inviteTokenAddr
    ) {
        require(address(ensAddr) != address(0), "Invalid address");
        require(address(resolverAddr) != address(0), "Invalid address");
        require(address(_reverseRegistrar) != address(0), "Invalid address");
        require(
            address(controllerRegistryAddr) != address(0),
            "Invalid address"
        );
        require(node != bytes32(0), "Invalid node");
        require(address(inviteTokenAddr) != address(0), "Invalid address");

        ens = ensAddr;
        resolver = resolverAddr;
        controllerRegistry = controllerRegistryAddr;
        rootNode = node;
        reverseRegistrar = _reverseRegistrar;
        inviteToken = inviteTokenAddr;
    }

    function registerPod(
        bytes32 label,
        address podSafe,
        address podCreator
    ) public returns (address) {
        if (state == State.closed) {
            revert("registrations are closed");
        }

        if (state == State.onlySafeWithShip) {
            // This implicitly prevents safes that were created in this transaction
            // from registering, as they cannot have a SHIP token balance.
            require(
                inviteToken.balanceOf(podSafe) > 0,
                "safe must have SHIP token"
            );
            inviteToken.burn(podSafe, 1);
        }
        if (state == State.onlyShip) {
            // Prefer the safe's token over the user's
            if (inviteToken.balanceOf(podSafe) > 0) {
                inviteToken.burn(podSafe, 1);
            } else if (inviteToken.balanceOf(podCreator) > 0) {
                inviteToken.burn(podCreator, 1);
            } else {
                revert("sender or safe must have SHIP");
            }
        }

        bytes32 node = keccak256(abi.encodePacked(rootNode, label));

        require(
            controllerRegistry.isRegistered(msg.sender),
            "controller not registered"
        );

        require(ens.owner(node) == address(0), "label is already owned");

        _register(label, address(this));

        resolver.setAddr(node, podSafe);

        return address(reverseRegistrar);
    }

    function getRootNode() public view returns (bytes32) {
        return rootNode;
    }

    /**
     * Generates a node hash from the Registrar's root node + the label hash.
     * @param label - label hash of pod name (i.e., labelhash('mypod'))
     */
    function getEnsNode(bytes32 label) public view returns (bytes32) {
        return keccak256(abi.encodePacked(getRootNode(), label));
    }

    /**
     * Returns the reverse registrar node of a given address,
     * e.g., the node of mypod.addr.reverse.
     * @param input - an ENS registered address
     */
    function addressToNode(address input) public returns (bytes32) {
        return reverseRegistrar.node(input);
    }

    /**
     * Register a name, or change the owner of an existing registration.
     * @param label The hash of the label to register.
     */
    function register(bytes32 label, address owner)
        public
        onlyControllerOrOwner
    {
        _register(label, owner);
    }

    /**
     * Register a name, or change the owner of an existing registration.
     * @param label The hash of the label to register.
     */
    function _register(bytes32 label, address owner) internal {
        ens.setSubnodeRecord(rootNode, label, owner, address(resolver), 0);
    }

    /**
     * @param node - the node hash of an ENS name
     */
    function setText(
        bytes32 node,
        string memory key,
        string memory value
    ) public onlyControllerOrOwner {
        resolver.setText(node, key, value);
    }

    function setAddr(bytes32 node, address newAddress)
        public
        onlyControllerOrOwner
    {
        resolver.setAddr(node, newAddress);
    }

    function setRestrictionState(uint256 _state) external onlyOwner {
        state = State(_state);
    }
}

pragma solidity ^0.8.7;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

contract InviteToken is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor() ERC20("Ship Token", "$SHIP") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
    }

    function decimals() public view override returns (uint8) {
        return 0;
    }

    function batchMint(address[] calldata accounts, uint256 amount) public {
        for (uint256 i = 0; i < accounts.length; i++) {
            mint(accounts[i], amount);
        }
    }

    function mint(address account, uint256 amount) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Only minters can mint");
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public {
        require(hasRole(BURNER_ROLE, msg.sender), "Only burners can burn");
        _burn(account, amount);
    }
}
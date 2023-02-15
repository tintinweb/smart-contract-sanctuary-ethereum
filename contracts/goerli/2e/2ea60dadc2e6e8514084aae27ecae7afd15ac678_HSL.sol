// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "lib/openzeppelin-contracts/contracts/utils/Address.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./HeartColors.sol";

contract HSL is Ownable {
    using Address for address;

    error MintError(bool ownedByZero, bool eligibleToMint);
    error TransferError(bool approvedOrOwner, bool fromPrevOwnership);

    uint256 public _nextToMint = 0;
    uint256 private _lineageNonce = 0;

    mapping(uint256 => string) private _bases;

    struct TokenInfo {
        uint256 genome;
        address owner;
        uint64 lastTransferred;
        HeartColor color;
        uint24 padding;
        address parent;
        uint48 numChildren;
        uint48 lineageDepth;
    }

    struct AddressInfo {
        uint128 inactiveBalance;
        uint128 activeBalance;
    }

    mapping(uint256 => TokenInfo) private _tokenData;
    mapping(address => AddressInfo) private _balances;
    mapping(address => mapping(uint256 => uint256)) private _ownershipOrderings;
    mapping(uint256 => uint256) private _orderPositions;

    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => uint256)) private _operatorApprovals;

    mapping(uint256 => uint256) private _activations;
    mapping(uint256 => uint256) private _burns;

    address public inactiveContract;
    address public activeContract;
    address public lbrContract;
    address public successorContract;

    modifier onlyHearts() {
        require(msg.sender == inactiveContract || msg.sender == activeContract, "nh");
        _;
    }

    modifier onlyInactive() {
        require(msg.sender == inactiveContract, "ni");
        _;
    }

    modifier onlyActive() {
        require(msg.sender == activeContract, "na");
        _;
    }

    modifier onlySuccessor() {
        require(msg.sender == successorContract, "na");
        _;
    }

    uint256 private _activeSupply;
    uint256 private _burnedSupply;

    constructor() {
        _bases[0] = "A";
        _bases[1] = "C";
        _bases[2] = "G";
        _bases[3] = "T";
    }

    function storage_balanceOf(bool active, address owner) public view returns (uint256) {
        require(owner != address(0), "0");
        return (active ? _balances[owner].activeBalance : _balances[owner].inactiveBalance);
    }

    function _totalBalance(address owner) private view returns (uint256) {
        return _balances[owner].activeBalance + _balances[owner].inactiveBalance;
    }

    function storage_ownerOf(bool active, uint256 tokenId) public view returns (address) {
        require(_exists(active, tokenId), "e");
        return _tokenData[tokenId].owner;
    }

    function storage_colorOf(bool active, uint256 tokenId) public view returns (HeartColor) {
        require(_exists(active, tokenId), "e");
        return _tokenData[tokenId].color;
    }

    function storage_parentOf(bool active, uint256 tokenId) public view returns (address) {
        require(_exists(active, tokenId), "e");
        return _tokenData[tokenId].parent;
    }

    function storage_lineageDepthOf(bool active, uint256 tokenId) public view returns (uint256) {
        require(_exists(active, tokenId), "e");
        return uint256(_tokenData[tokenId].lineageDepth);
    }

    function storage_numChildrenOf(bool active, uint256 tokenId) public view returns (uint256) {
        require(_exists(active, tokenId), "e");
        return uint256(_tokenData[tokenId].numChildren);
    }

    function storage_rawGenomeOf(bool active, uint256 tokenId) public view returns (uint256) {
        require(_exists(active, tokenId), "e");
        return _tokenData[tokenId].genome;
    }

    function storage_genomeOf(bool active, uint256 tokenId) public view returns (string memory) {
        require(_exists(active, tokenId), "e");
        uint256 rawGenome = storage_rawGenomeOf(active, tokenId);
        string memory toReturn = "";
        for (uint256 i = 0; i < 128; i++) {
            toReturn = string(abi.encodePacked(toReturn, _bases[(rawGenome>>(i*2))%4]));
        }
        return toReturn;
    }

    function storage_lastTransferred(bool active, uint256 tokenId) public view returns (uint64) {
        require(_exists(active, tokenId), "e");
        return _tokenData[tokenId].lastTransferred;
    }

    function storage_transferFrom(
        address msgSender,
        address from,
        address to,
        uint256 tokenId
    ) public onlyHearts {
        _transfer(msgSender, msg.sender == activeContract, from, to, tokenId);
    }

    function storage_safeTransferFrom(
        address msgSender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public onlyHearts {
        storage_transferFrom(msgSender, from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "z");
    }

    function storage_safeTransferFrom(
        address msgSender,
        address from,
        address to,
        uint256 tokenId
    ) public onlyHearts {
        storage_safeTransferFrom(msgSender, from, to, tokenId, "");
    }

    function storage_approve(address msgSender, address to, uint256 tokenId) public onlyHearts {
        address owner = storage_ownerOf(msg.sender == activeContract, tokenId);
        require(
            msgSender == owner ||
            msgSender == storage_getApproved(msg.sender == activeContract, tokenId) ||
            storage_isApprovedForAll(msg.sender == activeContract, owner, msgSender),
                "a");
        _approve(to, tokenId, owner);
    }

    function storage_getApproved(bool active, uint256 tokenId) public view returns (address) {
        if (active != _isActive(tokenId)) {
            return address(0);
        }
        return _tokenApprovals[tokenId];
    }

    function storage_setApprovalForAll(address msgSender, address operator, bool _approved) public onlyHearts {
        uint256 operatorApproval = _operatorApprovals[msgSender][operator];

        if (msg.sender == activeContract) {
            operatorApproval = 2*(_approved ? 1 : 0) + operatorApproval%2;
        }
        else {
            operatorApproval = 2*(operatorApproval>>1) + (_approved ? 1 : 0);
        }

        _operatorApprovals[msgSender][operator] = operatorApproval;
        ERC721TopLevelProto(msg.sender).emitApprovalForAll(msgSender, operator, _approved);
    }

    function storage_isApprovedForAll(bool active, address owner, address operator) public view returns (bool) {
        return ((_operatorApprovals[owner][operator] >> (active ? 1 : 0))%2 == 1);
    }

    /********/

    function storage_totalSupply(bool active) public view returns (uint256) {
        if (active) {
            return _activeSupply;
        }
        else {
            return ((_nextToMint - _activeSupply) - _burnedSupply);
        }
    }

    function storage_tokenOfOwnerByIndex(
        bool active,
        address owner,
        uint256 index
    ) public view returns (uint256) {
        require(owner != address(0), "0");

        uint256 thisBalance = storage_balanceOf(active, owner);
        uint256 otherBalance = storage_balanceOf(!active, owner);
        require(index < thisBalance, "ind/bal");

        uint256 curIndex = 0;
        for (uint256 i = 0; i < (thisBalance + otherBalance); i++) {
            uint256 curToken = _ownershipOrderings[owner][i];
            if (_isActive(curToken) == active) {
                if (curIndex == index) {
                    return curToken;
                }
                curIndex++;
            }
        }

        revert("u");
    }

    function storage_tokenByIndex(bool active, uint256 index) public view returns (uint256) {
        require(_exists(active, index), "e");
        return index;
    }

    /********/

    function _generateRandomLineage(address to, bool mode) private view returns (uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(
                    to,
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - ((mode ? ((_lineageNonce>>128)%256) : ((_lineageNonce)%256)) + 1)),
                    (mode ? (_lineageNonce%(1<<128)) : (_lineageNonce>>128))
                )
            )
        );
    }

    function mint(
        address to,
        HeartColor color,
        uint256 lineageToken,
        uint256 lineageDepth,
        address parent
    ) public onlyHearts returns (uint256) {
        uint256 nextToMint = _nextToMint;
        TokenInfo memory newTokenData;

        newTokenData.owner = to;
        newTokenData.lastTransferred = uint64(block.timestamp);
        newTokenData.color = color;
        newTokenData.parent = parent;

        uint256 newLineageData = _generateRandomLineage(to, true);
        _lineageNonce = _lineageNonce ^ newLineageData;
        if (msg.sender == activeContract) {
            uint256 lineageModifier = _generateRandomLineage(to, false);
            _lineageNonce = _lineageNonce ^ lineageModifier;
            uint256 tokenLineage = _tokenData[lineageToken].genome;

            uint256 newLineage = 0;
            for (uint256 i = 0; i < 256; i += 2) {
                if ((lineageModifier>>i)%4 == 0) {
                    newLineage += newLineageData & (3<<i);
                }
                else {
                    newLineage += tokenLineage & (3<<i);
                }
            }

            newTokenData.genome = newLineage;

            newTokenData.lineageDepth = (_tokenData[lineageToken].lineageDepth + 1);

            _tokenData[lineageToken].numChildren += 1;
        }
        else {
            newTokenData.genome = newLineageData;

            newTokenData.lineageDepth = uint48(lineageDepth);
        }

        _tokenData[nextToMint] = newTokenData;

        uint256 toTotalBalance = _totalBalance(to);
        _ownershipOrderings[to][toTotalBalance] = nextToMint;
        _orderPositions[nextToMint] = toTotalBalance;

        if (msg.sender == activeContract) {
            _activations[nextToMint/256] += 1<<(nextToMint%256);
            _balances[to].activeBalance += 1;
            _activeSupply++;
        }
        else {
            _balances[to].inactiveBalance += 1;
        }

        ERC721TopLevelProto(msg.sender).emitTransfer(address(0), to, _nextToMint);

        _nextToMint++;

        return nextToMint;
    }

    function _liquidate(uint256 tokenId) private {
        address tokenOwner = storage_ownerOf(true, tokenId);

        _tokenData[tokenId].lastTransferred = uint64(block.timestamp);

        _activations[tokenId/256] -= 1<<(tokenId%256);

        ERC721TopLevelProto(activeContract).emitTransfer(tokenOwner, address(0), tokenId);
        ERC721TopLevelProto(inactiveContract).emitTransfer(address(0), tokenOwner, tokenId);

        _balances[tokenOwner].activeBalance -= 1;
        _balances[tokenOwner].inactiveBalance += 1;
        _activeSupply--;
    }

    function storage_liquidate(uint256 tokenId) public onlyActive {
        _liquidate(tokenId);
    }

    function _activate(uint256 tokenId) private {
        address tokenOwner = storage_ownerOf(false, tokenId);

        _tokenData[tokenId].lastTransferred = uint64(block.timestamp);

        _activations[tokenId/256] += 1<<(tokenId%256);

        ERC721TopLevelProto(inactiveContract).emitTransfer(tokenOwner, address(0), tokenId);
        ERC721TopLevelProto(activeContract).emitTransfer(address(0), tokenOwner, tokenId);
        ActiveHearts(activeContract).initExpiryTime(tokenId);

        _balances[tokenOwner].activeBalance += 1;
        _balances[tokenOwner].inactiveBalance -= 1;
        _activeSupply++;
    }

    function storage_activate(uint256 tokenId) public onlyInactive {
        _activate(tokenId);
    }

    function _burn(uint256 tokenId) private {
        address prevOwnership = storage_ownerOf(false, tokenId);

        _balances[prevOwnership].inactiveBalance -= 1;

        _tokenData[tokenId].owner = address(0);

        uint256 fromBalanceTotal = _totalBalance(prevOwnership);
        uint256 curTokenOrder = _orderPositions[tokenId];
        uint256 lastFromTokenId = _ownershipOrderings[prevOwnership][fromBalanceTotal];
        if (tokenId != lastFromTokenId) {
            _ownershipOrderings[prevOwnership][curTokenOrder] = lastFromTokenId;
            _orderPositions[lastFromTokenId] = curTokenOrder;
            delete _ownershipOrderings[prevOwnership][fromBalanceTotal];
        }

        ERC721TopLevelProto(msg.sender).emitTransfer(prevOwnership, address(0), tokenId);

        _burnedSupply++;
    }

    function storage_burn(uint256 tokenId) public onlyInactive {
        _burn(tokenId);
    }

    function _batchLiquidate(uint256[] memory tokenIds) private {
        address[] memory tokenOwners = new address[](tokenIds.length);
        address[] memory zeroAddresses = new address[](tokenIds.length);

        uint256 accumulator = 0;
        uint256 curSlot = 0;
        uint256 iterSlot;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            iterSlot = tokenId/256;
            if (iterSlot != curSlot) {
                _activations[curSlot] -= accumulator;
                curSlot = iterSlot;
                accumulator = 0;
            }

            accumulator += (1<<(tokenId%256));

            tokenOwners[i] = _tokenData[tokenId].owner;
            _balances[tokenOwners[i]].activeBalance -= 1;
            _balances[tokenOwners[i]].inactiveBalance += 1;
        }
        _activations[curSlot] -= accumulator;

        ERC721TopLevelProto(activeContract).batchEmitTransfers(tokenOwners, zeroAddresses, tokenIds);
        ERC721TopLevelProto(inactiveContract).batchEmitTransfers(zeroAddresses, tokenOwners, tokenIds);

        _activeSupply -= tokenIds.length;
    }

    function storage_batchLiquidate(uint256[] calldata tokenIds) public onlyActive {
        _batchLiquidate(tokenIds);
    }

    function _batchActivate(uint256[] calldata tokenIds) private {
        address[] memory tokenOwners = new address[](tokenIds.length);
        address[] memory zeroAddresses = new address[](tokenIds.length);

        uint256 accumulator = 0;
        uint256 curSlot = 0;
        uint256 iterSlot;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            iterSlot = tokenId/256;
            if (iterSlot != curSlot) {
                _activations[curSlot] += accumulator;
                curSlot = iterSlot;
                accumulator = 0;
            }

            accumulator += (1<<(tokenId%256));

            tokenOwners[i] = _tokenData[tokenId].owner;
            _balances[tokenOwners[i]].activeBalance += 1;
            _balances[tokenOwners[i]].inactiveBalance -= 1;
        }
        _activations[curSlot] += accumulator;

        ERC721TopLevelProto(activeContract).batchEmitTransfers(zeroAddresses, tokenOwners, tokenIds);
        ERC721TopLevelProto(inactiveContract).batchEmitTransfers(tokenOwners, zeroAddresses, tokenIds);
        ActiveHearts(activeContract).batchInitExpiryTime(tokenIds);

        _activeSupply += tokenIds.length;
    }

    function storage_batchActivate(uint256[] calldata tokenIds) public onlyInactive {
        _batchActivate(tokenIds);
    }

    function _batchBurn(uint256[] memory tokenIds) private {
        address[] memory tokenOwners = new address[](tokenIds.length);
        address[] memory zeroAddresses = new address[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            tokenOwners[i] = _tokenData[tokenId].owner;

            _balances[tokenOwners[i]].inactiveBalance -= 1;

            _tokenData[tokenId].owner = address(0);

            uint256 fromBalanceTotal = _totalBalance(tokenOwners[i]);
            uint256 curTokenOrder = _orderPositions[tokenId];
            uint256 lastFromTokenId = _ownershipOrderings[tokenOwners[i]][fromBalanceTotal];
            if (tokenId != lastFromTokenId) {
                _ownershipOrderings[tokenOwners[i]][curTokenOrder] = lastFromTokenId;
                _orderPositions[lastFromTokenId] = curTokenOrder;
                delete _ownershipOrderings[tokenOwners[i]][fromBalanceTotal];
            }
        }

        ERC721TopLevelProto(inactiveContract).batchEmitTransfers(tokenOwners, zeroAddresses, tokenIds);

        _burnedSupply += tokenIds.length;
    }

    function storage_batchBurn(uint256[] calldata tokenIds) public onlyInactive {
        _batchBurn(tokenIds);
    }

    /******************/

    function setSuccessor(address _successor) public onlyOwner {
        successorContract = _successor;
    }

    function storage_migrate(uint256 tokenId, address msgSender) public onlySuccessor {
        require(msgSender == tx.origin, "bad origin");
        if (_exists(true, tokenId)) {
            _liquidate(tokenId);
            _burn(tokenId);
            LiquidationBurnRewardsProto(lbrContract).disburseMigrationReward(tokenId, msgSender);
        }
        else if (_exists(false, tokenId)) {
            _burn(tokenId);
            LiquidationBurnRewardsProto(lbrContract).disburseMigrationReward(tokenId, msgSender);
        }
        else {
            revert("ne");
        }
    }

    function storage_batchMigrate(uint256[] calldata tokenIds, address msgSender) public onlySuccessor {
        require(msgSender == tx.origin, "bad origin");
        uint256[] memory existsActive = new uint256[](tokenIds.length);
        uint256[] memory existsInactive = new uint256[](tokenIds.length);
        uint256 numExistsActive = 0;
        uint256 numExistsInactive = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (_exists(true, tokenIds[i])) {
                existsActive[numExistsActive] = tokenIds[i];
                existsInactive[numExistsInactive] = tokenIds[i];
                numExistsActive++;
                numExistsInactive++;
            }
            else if (_exists(false, tokenIds[i])) {
                existsInactive[numExistsInactive] = tokenIds[i];
                numExistsInactive++;
            }
            else {
                revert("ne");
            }
        }

        _batchLiquidate(existsActive);
        _batchBurn(existsInactive);

        LiquidationBurnRewardsProto(lbrContract).batchDisburseMigrationReward(tokenIds, msgSender);
    }

    /******************/

    function setActiveContract(address _activeContract) public onlyOwner {
        activeContract = _activeContract;
    }

    function setInactiveContract(address _inactiveContract) public onlyOwner {
        inactiveContract = _inactiveContract;
    }

    function setLBRContract(address _lbrContract) public onlyOwner {
        lbrContract = _lbrContract;
    }

    /******************/

    function _isActive(uint256 tokenId) private view returns (bool) {
        return (((_activations[tokenId/256])>>(tokenId%256))%2 == 1);
    }

    function _exists(bool active, uint256 tokenId) public view returns (bool) {
        return (((tokenId < _nextToMint) && (_tokenData[tokenId].owner != address(0))) && (_isActive(tokenId) == active));
    }

    function _approve(address to, uint256 tokenId, address owner) private {
        _tokenApprovals[tokenId] = to;
        ERC721TopLevelProto(activeContract).emitApproval(owner, to, tokenId);
    }

    function _transfer(
        address msgSender,
        bool active,
        address from,
        address to,
        uint256 tokenId
    ) private {
        address prevOwnership = storage_ownerOf(active, tokenId);

        bool isApprovedOrOwner = (
            msgSender == prevOwnership ||
            msgSender == storage_getApproved(active, tokenId) ||
            storage_isApprovedForAll(active, prevOwnership, msgSender)
        );
        bool fromPrevOwnership = (prevOwnership == from);
        if (!(isApprovedOrOwner || fromPrevOwnership)) {
            revert TransferError(isApprovedOrOwner, fromPrevOwnership);
        }

        _approve(address(0), tokenId, prevOwnership);

        if (active) {
            _balances[from].activeBalance -= 1;
        }
        else {
            _balances[from].inactiveBalance -= 1;
        }

        _tokenData[tokenId].owner = to;

        uint256 fromBalanceTotal = _totalBalance(from);
        uint256 curTokenOrder = _orderPositions[tokenId];
        uint256 lastFromTokenId = _ownershipOrderings[from][fromBalanceTotal];
        if (tokenId != lastFromTokenId) {
            _ownershipOrderings[from][curTokenOrder] = lastFromTokenId;
            _orderPositions[lastFromTokenId] = curTokenOrder;
            delete _ownershipOrderings[from][fromBalanceTotal];
        }

        uint256 toBalanceTotal = _totalBalance(to);
        _ownershipOrderings[to][toBalanceTotal] = tokenId;
        _orderPositions[tokenId] = toBalanceTotal;

        if (active) {
            _balances[to].activeBalance += 1;
        }
        else {
            _balances[to].inactiveBalance += 1;
        }

        ERC721TopLevelProto(msg.sender).emitTransfer(from, to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("z");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /******************/
    function withdraw(address to) public onlyOwner {
        (bool success, ) = payable(to).call{value: address(this).balance}("");
        require(success, "Payment failed!");
    }

    function withdrawTokens(address to, address tokenAddress) public onlyOwner {
        IERC20(tokenAddress).transfer(to, IERC20(tokenAddress).balanceOf(address(this)));
    }
}

////////////////////

abstract contract ERC721TopLevelProto {
    function emitTransfer(address from, address to, uint256 tokenId) public virtual;
    function batchEmitTransfers(
        address[] calldata from,
        address[] calldata to,
        uint256[] calldata tokenIds
    ) public virtual;

    function emitApproval(address owner, address approved, uint256 tokenId) public virtual;

    function emitApprovalForAll(address owner, address operator, bool approved) public virtual;
}

//////////

abstract contract ActiveHearts is ERC721TopLevelProto {
    function initExpiryTime(uint256 heartId) public virtual;
    function batchInitExpiryTime(uint256[] calldata heartIds) public virtual;
}

//////////

abstract contract LiquidationBurnRewardsProto {
    function disburseMigrationReward(uint256 heartId, address to) public virtual;
    function batchDisburseMigrationReward(uint256[] calldata heartIds, address to) public virtual;
}

////////////////////////////////////////

// SPDX-License-Identifier: Unlicense
// Creator: 0xYeety/YEETY.eth - Co-Founder/CTO, Virtue Labs

pragma solidity ^0.8.17;

enum HeartColor {
    Red,
    Blue,
    Green,
    Yellow,
    Orange,
    Purple,
    Black,
    White,
    Length
}
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./SafeTrade.sol";

contract SafeTradeFactory is Ownable {

    address public withdrawal;
    mapping(address => bool) public whitelistedTokens;
    mapping(address => bool) public isSafeContract;
    SafeTrade public safeTradeContract;

    event NewSafeTrade(address safeTradeAddress, address participant_1, address participant_2);

    constructor() {
        withdrawal = owner();
    }

    function addToken(address _address) public onlyOwner {
        whitelistedTokens[_address] = true;
    }

    function removeToken(address _address) public onlyOwner {
        delete whitelistedTokens[_address];
    }   

    function isWhitelisted(address _address) public view returns (bool) {
        return whitelistedTokens[_address];
    }

    function changeWithdrawalAddress(address _address) public onlyOwner {
        withdrawal = _address;
    }

    function startSafeTrade(address counterpart) public {
        require(msg.sender != counterpart, "invalid counterpart address.");
        SafeTrade safeTradeChild = new SafeTrade(msg.sender, counterpart, withdrawal, address(this));
        isSafeContract[address(safeTradeChild)] = true;
        emit NewSafeTrade(address(safeTradeChild), msg.sender, counterpart);
    } 

    function withdraw(address _to) public onlyOwner {
        (bool success, ) = _to.call{value: address(this).balance}("");
        require(success, "failed to send ether");
    }

    function isLegit(address _contract) public view returns (bool) {
        return isSafeContract[_contract];
    }

    receive() external payable {}

    fallback() external {
        revert();
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IFactory {
    function isWhitelisted(address _token) external view returns (bool);
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IERC1155 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

contract SafeTrade is ReentrancyGuard, IERC721Receiver, IERC1155Receiver {
    // Address to send comissions
    address payable withdrawal;
    // Factory contract address
    address public factory;
    // Address of A participant
    address public counterpart_1;
    // Address of B participant
    address public counterpart_2;
    // Registry of assets offered by participants
    mapping(address => Asset[]) public assetsToTrade;
    // Registry of ready participants
    mapping(address => bool) public isReady;
    // Max amount of assets per counterpart
    uint constant MAX_AMOUNT = 5;

    struct Asset {
        uint identifier;
        address tokenAddress;
        uint256 tokenId;
        uint256 amount;
    }

    // Checks if msg.sender is a participant of the trade.
    modifier onlyCounterpart() {
        _onlyCounterpart();
        _;
    }

    function _onlyCounterpart() private view {
        require(
            msg.sender == counterpart_1 || msg.sender == counterpart_2,
            "Must be counterpart to participate"
        );
    }

    constructor(address _counterpart_1, address _counterpart_2, address _withdrawal, address _factory) {
        factory = payable(_factory);
        withdrawal = payable(_withdrawal);
        counterpart_1 = _counterpart_1;
        counterpart_2 = _counterpart_2;
    }

    /**
     * @dev Receives ETH as part of payment on behalf of msg.sender.
     */
    receive() external payable onlyCounterpart {
        require(assetsToTrade[msg.sender].length < MAX_AMOUNT);
        assetsToTrade[msg.sender].push(Asset(1, msg.sender, 0, msg.value));
    }

    /**
     * @dev Prior to allowance(), transfers `_amount` of `_token` to contract address on behalf of msg.sender.
     */
    function addERC20(address _token, uint256 _amount) public onlyCounterpart {
        require(
            IFactory(factory).isWhitelisted(_token),
            "invalid erc20 token"
        );
        require(assetsToTrade[msg.sender].length < MAX_AMOUNT);
        bool success = IERC20(_token).transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        require(success, "failed to transfer erc20 token");
        assetsToTrade[msg.sender].push(Asset(20, _token, 0, _amount));
    }

    /**
     * @dev Handles receipt of ERC721 `_tokenId` of `_token` collection and adds asset to storage.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        address sender;
        data;
        if (operator != from) {
            require(
                operator == counterpart_1 || operator == counterpart_2,
                "Not allowed to send tokens"
            );
            sender = operator;
        } else if (operator == from) {
            require(
                from == counterpart_1 || from == counterpart_2,
                "Not allowed to send tokens"
            );
            sender = from;
        }
        require(assetsToTrade[sender].length < MAX_AMOUNT);
        assetsToTrade[sender].push(Asset(721, msg.sender, tokenId, 1));
        return 0x150b7a02;
    }

    /**
     * @dev Handles receipt of ERC1155 `_tokenId` of `_token` collection and adds asset to mapping.
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        address sender;
        data;
        if (operator != from) {
            require(
                operator == counterpart_1 || operator == counterpart_2,
                "not allowed to send assets"
            );
            sender = operator;
        } else {
            require(
                from == counterpart_1 || from == counterpart_2,
                "not allowed to send assets"
            );
            sender = from;
        }
        require(assetsToTrade[sender].length < MAX_AMOUNT);
        assetsToTrade[sender].push(Asset(1155, msg.sender, tokenId, value));
        return 0xf23a6e61;
    }

    /**
     * @dev Handles receipt of batch of ERC1155 `_tokenId` of `_token` collection and adds asset to mapping.
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        address sender;
        data;
        if (operator != from) {
            require(
                operator == counterpart_1 || operator == counterpart_2,
                "Not allowed to send tokens"
            );
            sender = operator;
        } else {
            require(
                from == counterpart_1 || from == counterpart_2,
                "Not allowed to send tokens"
            );
            sender = from;
        }
        require(assetsToTrade[sender].length + ids.length <= MAX_AMOUNT);
        uint256 length = ids.length;
        for (uint i = 0; i < length; ) {
            assetsToTrade[sender].push(
                Asset(1155, msg.sender, ids[i], values[i])
            );
            unchecked {
                ++i;
            }
        }
        return 0xbc197c81;
    }

    /**
     * @dev Sets counterpart as ready to trade. When the second participant sets calls the function,
     * tradeAssets() gets invoked and after its successful completition, the contract selfdestructs.
     */
    function setReady() public onlyCounterpart nonReentrant {
        isReady[msg.sender] = true;

        if (isReady[counterpart_1] && isReady[counterpart_2]) {
            tradeAssets(counterpart_1, counterpart_2);
            tradeAssets(counterpart_2, counterpart_1);
            selfdestruct(withdrawal);
        }
    }

    /**
     * @dev Sends back all assets to their counterparts (no comission) and selfdestructs.
     */
    function cancelTrade() public onlyCounterpart nonReentrant {
        tradeAssets(counterpart_1, counterpart_1);
        tradeAssets(counterpart_2, counterpart_2);
        selfdestruct(withdrawal);
    }

    /**
     * @dev Sends the assets sent to this contract to the other counterpart.
     * 1% of ETH and ERC20 tokens are being kept as comission.
     */
    function tradeAssets(address _from, address _to) private {
        uint length = assetsToTrade[_from].length;
        for (uint i = 0; i < length; ) {
            Asset storage asset = assetsToTrade[_from][i];
            if (asset.identifier == 1) {
                (bool success, ) = _to.call{
                    value: ((asset.amount / 100) * 99)
                }("");
                require(success, "Unable to send Ether");
            } else if (asset.identifier == 20) {
                IERC20(asset.tokenAddress).transfer(
                    _to,
                    ((asset.amount / 100) * 99)
                );
                IERC20(asset.tokenAddress).transfer(
                    withdrawal,
                    IERC20(asset.tokenAddress).balanceOf(address(this))
                );
            } else if (asset.identifier == 721) {
                IERC721(asset.tokenAddress).safeTransferFrom(
                    address(this),
                    _to,
                    asset.tokenId
                );
            } else if (asset.identifier == 1155) {
                IERC1155(asset.tokenAddress).safeTransferFrom(
                    address(this),
                    _to,
                    asset.tokenId,
                    asset.amount,
                    ""
                );
            }
            unchecked {
                ++i;
            }
        }
    }

    function getAssets(address _user) external view returns (Asset[] memory) {
        return assetsToTrade[_user];
    }

    function supportsInterface(bytes4 interfaceId)
        external
        view
        override
        returns (bool)
    {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
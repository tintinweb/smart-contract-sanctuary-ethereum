// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/Address.sol";
import './IManager.sol';

contract Manager is IManager, Ownable {
    using Address for address;

    struct NFTFeeCollection {
        address feeCollector;
        uint256 cutPerMillion;
    }

    // Max market fee on NFT sales
    uint256 public maxCutPerMillion = 100000; // 10% cut,  i.e., 50000 = 5%
    
    // NFT token address => bool supported
    mapping(address => bool) isNftApproved;
    // NFT token address => fee collection information
    mapping(address => NFTFeeCollection) nftFees;

    /**
     * @dev Sets the share cut for the owner of the contract that's
     *  charged to the seller on a successful sale
     * @param _cutPerMillion - Share amount, from 0 to 999,999
     */
    function setOwnerCutPerMillion(address _nftAddress, uint256 _cutPerMillion) external override onlyOwner {
        require(isNFTSupported(_nftAddress), "Manager: The token address is not currently supported");

        require(
            _cutPerMillion > 0 &&
            _cutPerMillion <= maxCutPerMillion,
            "Manager: The owner cut should be between 0 and maxCutPerMillion"
        );

        nftFees[_nftAddress].cutPerMillion = _cutPerMillion;
        emit ChangedFeePerMillion(_nftAddress, _cutPerMillion);
    }

    /**
     * @dev Sets the share cut for the owner of the contract that's
     *  charged to the seller on a successful sale
     * @param _maxCutPerMillion - Maximum share amount, from 0 to 999,999
     */
    function setMaxCutPerMillion(uint256 _maxCutPerMillion) external override onlyOwner {
        require(
            _maxCutPerMillion > 0 && 
            _maxCutPerMillion < 999999,
            "Manager: The max cut should be greater than 0 and less than 999999"
        );

        maxCutPerMillion = _maxCutPerMillion;
        emit ChangedMaxCutPerMillion(_maxCutPerMillion);
    }

    /**
     * @dev Approves an NFT for sale on the marketplace and sets the royalties/fee collector address
     * for fees charged to the seller on a successful sale
     * as well as the amount charged
     * @param _nftAddress ERC721 compliant NFT smart contract address
     * @param _feeCollector royalties/fee collector address. Could be EOA or Payment Splitter smart contract
     * @param _cutPerMillion Share amount, from 0 to 999,999
     */
    function approveNFT(address _nftAddress, address _feeCollector, uint256 _cutPerMillion) external override onlyOwner {
        require(
            _nftAddress.isContract(),
            "Manager: The accepted token address must be a deployed contract"
        );
        // require(!isNFTSupported(_nftAddress), "Manager: The token address is already supported");
        require(_feeCollector != address(0), "Manager: Fee collector address cannot be zero address");
        require(
            _cutPerMillion > 0 &&
            _cutPerMillion <= maxCutPerMillion,
            "Manager: The owner cut should be between 0 and maxCutPerMillion"
        );        

        isNftApproved[_nftAddress] = true;
        nftFees[_nftAddress].cutPerMillion = _cutPerMillion;
        nftFees[_nftAddress].feeCollector = _feeCollector;

        emit NFTApproved(_nftAddress);
    }   

    /**
     * @dev Revokes the approval of an NFT
     * reverts the approve() NFT action
     * @param _nftAddress ERC721 compliant NFT smart contract address
     */
    function revokeNFT(address _nftAddress) external override onlyOwner {
        require(isNFTSupported(_nftAddress), "Manager: The token address is not currently supported");

        isNftApproved[_nftAddress] = false;

        emit NFTRevoked(_nftAddress);
    }

    /**
     * @dev Returns true if an NFT is currently approved for sale on the marketplace and false if otherwise
     * @param _nftAddress ERC721 compliant NFT smart contract address
     * @return supported boolean true or false
     */
    function isNFTSupported(address _nftAddress) public view override returns (bool supported) {
        supported = isNftApproved[_nftAddress];
    }

    /**
     * @dev Returns the fee information for an approved NFT
     * @param _nftAddress ERC721 compliant NFT smart contract address
     * @return _feeCollector royalties/fee collector address. Could be EOA or Payment Splitter smart contract
     * @return _cutPerMillion Share amount, from 0 to 999,999
     */
    function getNFTFeeInfo(address _nftAddress) external view override returns (address _feeCollector, uint256 _cutPerMillion) {
        _feeCollector = nftFees[_nftAddress].feeCollector;
        _cutPerMillion = nftFees[_nftAddress].cutPerMillion;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

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

//permits erc721 addresses
//called by marketplace

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IManager {
    event ChangedFeePerMillion(address nftAddress, uint256 cutPerMillion);

    event NFTApproved(address nftAddress);

    event NFTRevoked(address nftAddress);

    event ChangedMaxCutPerMillion(uint256 maxCutPerMillion);

    function setOwnerCutPerMillion(address _nftAddress, uint256 _cutPerMillion) external;

    function setMaxCutPerMillion(uint256 _maxCutPerMillion) external; 

    function approveNFT(address _nftAddress, address _feeCollector, uint256 _cutPerMillion) external;

    function revokeNFT(address _nftAddress) external;

    function getNFTFeeInfo(address _nftAddress) external view returns (address _feeCollector, uint256 _cutPerMillion);

    function isNFTSupported(address _nftAddress) external view returns (bool supported);
}
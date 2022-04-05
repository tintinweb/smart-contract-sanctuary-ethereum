/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

// File: ../../interfaces/IGovernedContract.sol

interface IGovernedContract {
    // Return actual proxy address for secure validation
    function proxy() external view returns(address);
}
// File: ../../StorageBase.sol

/**
 * Base for contract storage (SC-14).
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */
contract StorageBase {
    address payable internal owner;
    modifier requireOwner {
        require (msg.sender == address(owner), 'StorageBase: Not owner!');
        _;
    }
    constructor() {
        owner = payable(msg.sender);
    }
    function setOwner(address _newOwner) external requireOwner {
        owner = payable(_newOwner);
    }
    function kill() external requireOwner {
        selfdestruct(payable(msg.sender));
    }
}
// File: ../../GovernedContract.sol

/**
 * Genesis version of GovernedContract common base.
 *
 * Base Consensus interface for upgradable contracts.
 * Unlike common approach, the implementation is NOT expected to be
 * called through delegatecall() to minimize risks of shared storage.
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */
contract GovernedContract {
    address public proxy;
    constructor(address _proxy) {
        proxy = _proxy;
    }
    modifier requireProxy {
        require (msg.sender == proxy, 'Governed Contract: Not proxy');
        _;
    }
    function getProxy() internal view returns(address _proxy) {
        _proxy = proxy;
    }
    // solium-disable-next-line no-empty-blocks
    function _migrate(address) internal {}
    function _destroy(address _newImpl) internal {
        selfdestruct(payable(_newImpl));
    }
    function _callerAddress()
        internal view
        returns (address payable)
    {
        if (msg.sender == proxy) {
            // This is guarantee of the GovernedProxy
            // solium-disable-next-line security/no-tx-origin
            return payable(tx.origin);
        } else {
            return payable(msg.sender);
        }
    }
}
// File: ../../interfaces/IProposal.sol

interface IProposal {
    function parent() external view returns(address);
    function created_block() external view returns(uint);
    function deadline() external view returns(uint);
    function fee_payer() external view returns(address payable);
    function fee_amount() external view returns(uint);
    function accepted_weight() external view returns(uint);
    function rejected_weight() external view returns(uint);
    function total_weight() external view returns(uint);
    function quorum_weight() external view returns(uint);
    function isFinished() external view returns(bool);
    function isAccepted() external view returns(bool);
    function withdraw() external;
    function destroy() external;
    function collect() external;
    function voteAccept() external;
    function voteReject() external;
    function setFee() external payable;
    function canVote(address owner) external view returns(bool);
}
// File: ../../interfaces/IUpgradeProposal.sol

/**
 * Interface of UpgradeProposal
 */
interface IUpgradeProposal is IProposal {
    function implementation() external view returns(IGovernedContract);
}
// File: ../../interfaces/IGovernedProxy.sol

interface IGovernedProxy {
    event UpgradeProposal(IGovernedContract indexed implementation, IUpgradeProposal proposal);
    event Upgraded(IGovernedContract indexed implementation, IUpgradeProposal proposal);
    function spork_proxy() external view returns(address);
    function implementation() external view returns(IGovernedContract);
    function initialize(address _implementation) external;
    function proposeUpgrade(IGovernedContract _newImplementation, uint _period) external payable returns(IUpgradeProposal);
    function upgrade(IUpgradeProposal _proposal) external;
    function upgradeProposalImpl(IUpgradeProposal _proposal) external view returns(IGovernedContract newImplementation);
    function listUpgradeProposals() external view returns(IUpgradeProposal[] memory proposals);
    function collectUpgradeProposal(IUpgradeProposal _proposal) external;
    fallback() external;
    receive() external payable;
}
// File: ERC721ManagerAutoProxy.sol
 
/**
 * ERC721ManagerAutoProxy is a version of GovernedContract which initializes its own proxy.
 * This is useful to avoid a circular dependency between GovernedContract and GovernedProxy
 * wherein they need each other's address in the constructor.
 */
contract ERC721ManagerAutoProxy is GovernedContract {
    constructor (
        address _proxy,
        address _implementation
    ) GovernedContract(_proxy) {
        proxy = _proxy;
        IGovernedProxy(payable(proxy)).initialize(_implementation);
    }
}
// File: IERC165.sol
 
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
// File: ERC165.sol
 
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
// File: ../../libraries/Address.sol
 
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// File: ../../libraries/Strings.sol
 
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
// File: ../../Context.sol
 
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () { }
    // solhint-disable-previous-line no-empty-blocks
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }
    function _txOrigin() internal view returns (address payable) {
        return payable(tx.origin);
    }
    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
// File: ../../Ownable.sol
 
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of 'user permissions'.
 */
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
    owner = msg.sender;
  }
  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require (msg.sender == owner, 'Ownable: Not owner');
    _;
  }
  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require (newOwner != address(0), 'Ownable: Zero address not allowed');
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}
// File: ../../Pausable.sol
 
/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Context, Ownable {
  /**
    * @dev Emitted when pause() is called.
    * @param account of contract owner issuing the event.
    * @param unpauseBlock block number when contract will be unpaused.
    */
  event Paused(address account, uint256 unpauseBlock);
  /**
    * @dev Emitted when pause is lifted by unpause() by
    * @param account.
    */
  event Unpaused(address account);
  /**
    * @dev state variable
    */
  uint256 public blockNumberWhenToUnpause = 0;
  /**
    * @dev Modifier to make a function callable only when the contract is not
    *      paused. It checks whether the current block number
    *      has already reached blockNumberWhenToUnpause.
    */
  modifier whenNotPaused {
      require (block.number >= blockNumberWhenToUnpause,
          'Pausable: Revert - Code execution is still paused');
      _;
  }
  /**
    * @dev Modifier to make a function callable only when the contract is paused.
    */
  modifier whenPaused() {
    require (block.number < blockNumberWhenToUnpause,
          'Pausable: Revert - Code execution is not paused');
    _;
  }
  /**
    * @dev Triggers or extends pause state.
    *
    * Requirements:
    *
    * - @param blocks needs to be greater than 0.
    */
  function pause(uint256 blocks) external onlyOwner {
      require (blocks > 0,
          'Pausable: Revert - Pause did not activate. Please enter a positive integer.');
      blockNumberWhenToUnpause = block.number + blocks;
      emit Paused(_msgSender(), blockNumberWhenToUnpause);
  }
  /**
    * @dev Returns to normal code execution.
    */
  function unpause() external onlyOwner {
      blockNumberWhenToUnpause = block.number;
      emit Unpaused(_msgSender());
  }
}
// File: ../../NonReentrant.sol
 
/**
 * A little helper to protect contract from being re-entrant in state
 * modifying functions.
 */
contract NonReentrant {
    uint private entry_guard;
    modifier noReentry {
        require (entry_guard == 0, 'NonReentrant: Reentry');
        entry_guard = 1;
        _;
        entry_guard = 0;
    }
}
// File: ../../interfaces/ICollectionStorage.sol
 
interface ICollectionStorage {
    function getRoyaltyReceiver(uint tokenId) external view returns (address _royaltyReceiver);
    function getRoyaltyFraction(uint tokenId) external view returns (uint96 _royaltyFraction);
    function getRoyaltyInfo(uint tokenId) external view returns (address _royaltyReceiver, uint96 _royaltyFraction);
    function getDefaultRoyaltyReceiver() external view returns (address _defaultRoyaltyReceiver);
    function getDefaultRoyaltyFraction() external view returns (uint96 _defaultRoyaltyFraction);
    function getDefaultRoyaltyInfo() external view returns (address _defaultRoyaltyReceiver, uint96 _defaultRoyaltyFraction);
    function getFeeDenominator() external view returns (uint96 _feeDenominator);
    function getCollectionManagerProxyAddress() external view returns(address _collectionManagerProxyAddress);
    function getMovementNoticeURI() external view returns(string memory _movementNoticeURI);
    function getCollectionMoved() external view returns(bool _collectionMoved);
    function getPRICE_PER_NFT() external view returns(uint _PRICE_PER_NFT);
    function getREMAINING_WHITELIST_SMART_CONTRACT_ALLOWANCE() external view returns(uint _REMAINING_WHITELIST_SMART_CONTRACT_ALLOWANCE);
    function getMAX_PUBLIC_MINT_PER_ADDRESS() external view returns(uint _MAX_PUBLIC_MINT_PER_ADDRESS);
    function getMAX_SUPPLY() external view returns(uint _MAX_SUPPLY);
    function getBlockStartWhitelistPhase() external view returns(uint _blockStartWhitelistPhase);
    function getBlockEndWhitelistPhase() external view returns(uint _blockEndWhitelistPhase);
    function getBlockStartPublicPhase() external view returns(uint _blockStartPublicPhase);
    function getBlockEndPublicPhase() external view returns(uint _blockEndPublicPhase);
    function getTotalSupply() external view returns(uint _totalSupply);
    function getSmartContractsWhitelistCount() external view returns(uint _length);
    function getUserAddressWhitelistAllowance(address _address) external view returns(uint _amount);
    function getWhitelistedSmartContractAddressByIndex(uint _index) external view returns(address _whitelistSmartContract);
    function getWhitelistedSmartContractAllowanceByIndex(uint _index) external view returns(uint8 _allowedMints);
    function getSmartContractsWhitelistAllowance(uint _index) external view returns(address _whitelistSmartContract, uint8 _allowedMints);
    function getOperatorApproval(address _owner, address _operator) external view returns(bool _approved);
    function getBalance(address _address) external view returns(uint _amount);
    function getTokenApproval(uint _tokenId) external view returns(address _address);
    function getOwner(uint tokenId) external view returns(address _owner);
    function getName() external view returns(string memory _name);
    function getSymbol() external view returns(string memory _symbol);
    function getBaseURI() external view returns(string memory _baseURI);
    function getEAssetTokenOwner() external view returns(address _owner);
    function getEAssetTokenMinter() external view returns(address _minter);
    function setFeeDenominator(uint96 value) external;
    function setPRICE_PER_NFT(uint _value) external;
    function setREMAINING_WHITELIST_SMART_CONTRACT_ALLOWANCE(uint _value) external;
    function setMAX_PUBLIC_MINT_PER_ADDRESS(uint _value) external;
    function setMAX_SUPPLY(uint _value) external;
    function setWhitelistPhase(uint _blockStartWhitelistPhase, uint _blockEndWhitelistPhase) external;
    function setPublicPhase(uint _blockStartPublicPhase, uint _blockEndPublicPhase) external;
    function setTotalSupply(uint _value) external;
    function setUserAddressWhitelistAllowance(address _address, uint8 _allowedMints) external;
    function setSmartContractsWhitelistAllowance(uint _index, address _whitelistSmartContractAddress, uint8 _allowedMints) external;
    function setWhitelistedSmartContractAddressByIndex(uint _index, address _whitelistSmartContractAddress) external;
    function setWhitelistedSmartContractAllowanceByIndex(uint _index, uint8 _allowedMints) external;
    function pushSmartContractsAddressesAllowancesWhitelist(address _whitelistSmartContractAddress, uint8 _allowedMints) external;
    function popSmartContractsAddressesAllowancesWhitelist() external;
    function setName(string calldata _name) external;
    function setSymbol(string calldata _symbol) external;
    function setBaseURI(string calldata _baseURI) external;
    function setEAssetTokenOwner(address _eAssetTokenOwner) external;
    function setEAssetTokenMinter(address _eAssetTokenMinter) external;
    function setBalance(address _address, uint _amount) external;
    function setOwner(uint tokenId, address owner) external;
    function setTokenApproval(uint _tokenId, address _address) external;
    function setOperatorApproval(address _owner, address _operator, bool _approved) external;
    function setCollectionMoved(bool _collectionMoved) external;
    function setCollectionManagerProxyAddress(address _collectionManagerProxyAddress) external;
    function setMovementNoticeURI(string calldata _movementNoticeURI) external;
    function setDefaultRoyaltyInfo(address receiver, uint96 royaltyFraction) external;
    function setRoyaltyInfo(uint tokenId, address receiver, uint96 royaltyFraction) external; 
}
// File: ../../interfaces/ICollectionProxy.sol
 
interface ICollectionProxy {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    function emitTransfer(address from, address to, uint256 tokenId) external;
    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    function emitApproval(address owner, address approved, uint256  tokenId) external;
    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    function emitApprovalForAll(address  owner, address operator, bool approved) external;
}
// File: ../../interfaces/IERC721ManagerProxy.sol
 
interface IERC721ManagerProxy {
    function setSporkProxy(address payable _sporkProxy) external;
}
// File: ../../interfaces/IERC721.sol
 
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
// File: ../../interfaces/IERC721Receiver.sol
 
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
// File: ../../interfaces/IERC721Metadata.sol
 
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
// File: ../../interfaces/IERC2981.sol
 
/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}
// File: ERC721Manager.sol
 
contract ERC721ManagerStorage is StorageBase {
    address private factoryProxyAddress;
    address private mintFeeRecipient;
    // CollectionProxy --> CollectionStorage
    mapping (address => address) private collectionStorage;
    address[] private allCollectionProxies;
    constructor(address _factoryProxyAddress, address _mintFeeRecipient) {
        factoryProxyAddress = _factoryProxyAddress;
        mintFeeRecipient = _mintFeeRecipient;
    }
    function getFactoryProxyAddress() external view returns (address _factoryProxyAddress) {
        _factoryProxyAddress = factoryProxyAddress;
    }
    function getMintFeeRecipient() external view returns (address _mintFeeRecipient) {
        _mintFeeRecipient = mintFeeRecipient;
    }
    function getCollectionStorage(address collectionProxy) external view returns (address _collectionStorage) {
        _collectionStorage = collectionStorage[collectionProxy];
    }
    function getCollectionProxy(uint index) external view returns (address _collectionProxy) {
        _collectionProxy = allCollectionProxies[index];
    }
    function getCollectionsLength() external view returns (uint _length) {
        _length = allCollectionProxies.length;
    }
    function setCollectionStorage(address collectionProxy, address _collectionStorage) external requireOwner {
        collectionStorage[collectionProxy] = _collectionStorage;
    }
    function pushCollectionProxy(address collectionProxy) external requireOwner {
        allCollectionProxies.push(collectionProxy);
    }
    function popCollectionProxy() external requireOwner {
        allCollectionProxies.pop();
    }
    function setCollectionProxy(uint index, address collectionProxy) external requireOwner {
        allCollectionProxies[index] = collectionProxy;
    }
    function setFactoryProxyAddress(address _factoryProxyAddress) external requireOwner {
        factoryProxyAddress = _factoryProxyAddress;
    }
    function setMintFeeRecipient(address _mintFeeRecipient) external requireOwner {
        mintFeeRecipient = _mintFeeRecipient;
    }
}
contract ERC721Manager is Pausable, NonReentrant, ERC721ManagerAutoProxy, ERC165 {
    ERC721ManagerStorage public _storage;
    using Address for address;
    using Strings for uint256;
    constructor (
        address _proxy,
        address _factoryProxyAddress,
        address _mintFeeRecipient
    ) ERC721ManagerAutoProxy(_proxy, address(this)) {
        _storage = new ERC721ManagerStorage(_factoryProxyAddress, _mintFeeRecipient);
    }
    modifier requireCollectionProxy() {
        require(
            _storage.getCollectionStorage(msg.sender) != address(0),
            'ERC721Manager: FORBIDDEN, not a Collection proxy'
        );
        _;
    }
    modifier requireFactoryImpl() {
    	require(
            msg.sender == address(IGovernedProxy(payable(address(uint160(_storage.getFactoryProxyAddress())))).implementation()),
            'ERC721Manager: Not factory implementation!'
    	);
        _;
    }
    function setSporkProxy(address payable _sporkProxy) external onlyOwner {
        IERC721ManagerProxy(proxy).setSporkProxy(_sporkProxy);
    }
    // This function is called by Factory implementation at a new collection creation
    // Register a new Collection's proxy address, and Collection's storage address
    function register(address _collectionProxy, address _collectionStorage)
        external
        whenNotPaused
        requireFactoryImpl
    {
        _storage.setCollectionStorage(_collectionProxy, _collectionStorage);
        _storage.pushCollectionProxy(_collectionProxy);
    }
    // This function is called in order to upgrade to a new ERC721Manager implementation
    function destroy(address _newImpl) external requireProxy {
        StorageBase(address(_storage)).setOwner(address(_newImpl));
        // Self destruct
        _destroy(_newImpl);
    }
    // This function (placeholder) would be called on the new implementation if necessary for the upgrade
    function migrate(address _oldImpl) external requireProxy {
        _migrate(_oldImpl);
    }
   function getCollectionStorage(address collectionProxy) private view returns(ICollectionStorage) {
        return ICollectionStorage(_storage.getCollectionStorage(collectionProxy));
    }
    function addToWhitelist(
        address collectionProxy,
        address[] calldata whitelistAddresses,
        uint8[] calldata allowedMints
    )
        external
        onlyOwner
    {
        require(
            whitelistAddresses.length == allowedMints.length,
            'ERC721Manager: whitelisteAddresses and allowedMints arrays must have the same length'
        );
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        for(uint i = 0; i < whitelistAddresses.length; i++) {
            collectionStorage.setUserAddressWhitelistAllowance(whitelistAddresses[i], allowedMints[i]);
        }
    }
    function removeFromWhitelist(
        address collectionProxy,
        address[] calldata whitelistAddresses
    )
        external
        onlyOwner
    {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        for(uint i = 0; i < whitelistAddresses.length; i++) {
            collectionStorage.setUserAddressWhitelistAllowance(whitelistAddresses[i], 0);
        }
    }
    function pushSmartContractsWhitelistAllowances(
        address collectionProxy,
        address[] calldata whitelistSmartContractAddresses,
        uint8[] calldata allowedMints
    )
        external
        onlyOwner
    {
        require(
            whitelistSmartContractAddresses.length == allowedMints.length,
            'ERC721Manager: whitelisteAddresses and allowedMints arrays must have the same length'
        );
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        for(uint i = 0; i < whitelistSmartContractAddresses.length; i++) {
            collectionStorage.pushSmartContractsAddressesAllowancesWhitelist(whitelistSmartContractAddresses[i], allowedMints[i]);
        }
    }
    function popSmartContractsWhitelistAllowances(
        address collectionProxy,
        uint numberToPop
    )
        external
        onlyOwner
    {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        for(uint i = 0; i < numberToPop; i++) {
            collectionStorage.popSmartContractsAddressesAllowancesWhitelist();
        }
    }
    function airdrop(
        address collectionProxy,
        address[] calldata recipients,
        uint256[] calldata numbers
    )
        external
        onlyOwner
    {
        require(
            recipients.length == numbers.length,
            'ERC721Manager: recipients and numbers arrays must have the same length'
        );
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        for (uint j = 0; j < recipients.length; j++) {
            for (uint i = 0; i < numbers[j]; i++) {
                _safeMint(collectionProxy, collectionStorage, msg.sender, recipients[j], '');
            }
        }
    }
    function getAllowedMints(
        address collectionProxy,
        address minter,
        uint numberOfTokens
    )
        public
        view
        returns (uint totalAllowance, uint requiredWhitelistSmartContractAllowance)
    {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        uint individualAllowance = collectionStorage.getUserAddressWhitelistAllowance(minter);
        uint alreadyMintedNFTs = collectionStorage.getBalance(minter);
        // We want to allow holders of whitelisted smart contracts to mint up to
        // REMAINING_WHITELIST_SMART_CONTRACT_ALLOWANCE NFTs.
        // We calculate the requiredWhitelistSmartContractAllowance value, which corresponds to the minting allowance
        // due to the ownership of NFTs from whitelisted smart contracts. The user fills first its allowance due
        // to the individual whitelisted user address and then its allowance due to the whitelisted smart contracts.
        // The calculation of the requiredWhitelistSmartContractAllowance value is done optimistically
        // based on the numberOfTokens claimed by the user, before getting the user's actual allowances further below.
        // If user's actual allowances turn out to be insufficient, the transaction will revert in the safeMint() function.
        requiredWhitelistSmartContractAllowance =
            // First, we check if the user has already used the individualAllowance for minting NFTs from this smart contract
            individualAllowance <= alreadyMintedNFTs
                // If user had already minted more than the individual allowance, the numberOfTokens must be minted
                // using the whitelist smart contract allowance
                ? numberOfTokens
                : numberOfTokens <= individualAllowance - alreadyMintedNFTs
                    // If user can mint numberOfTokens using the individual allowance,
                    // no whitelist smart contract allowance is needed
                    ? 0
                    // Else if the individual allowance is not enough for user to mint
                    // numberOfTokens, the whitelist smart contract
                    // allowance must be used
                    : numberOfTokens - individualAllowance + alreadyMintedNFTs;
        // If requiredWhitelistSmartContractAllowance > REMAINING_WHITELIST_SMART_CONTRACT_ALLOWANCE the
        // `safeMint()` function will revert because `numberOfTokens > x` where x is the value returned here
        // x = individualAllowance + REMAINING_WHITELIST_SMART_CONTRACT_ALLOWANCE - alreadyMintedNFTs.
        // REMAINING_WHITELIST_SMART_CONTRACT_ALLOWANCE is the total minting allowance remaining
        // due to the ownership of NFTs from whitelisted smart contracts. The REMAINING_WHITELIST_SMART_CONTRACT_ALLOWANCE
        // value will be updated in the `safeMint()` function.
        if (requiredWhitelistSmartContractAllowance > 0 ) {
            uint REMAINING_WHITELIST_SMART_CONTRACT_ALLOWANCE =
                collectionStorage.getREMAINING_WHITELIST_SMART_CONTRACT_ALLOWANCE();
            if (requiredWhitelistSmartContractAllowance > REMAINING_WHITELIST_SMART_CONTRACT_ALLOWANCE) {
                // We return the sum of user's individualAllowance and the REMAINING_WHITELIST_SMART_CONTRACT_ALLOWANCE
                // as the total minting allowance for this user. We subtract the already minted NFTs.
                totalAllowance =
                    individualAllowance + REMAINING_WHITELIST_SMART_CONTRACT_ALLOWANCE > alreadyMintedNFTs
                        ? individualAllowance + REMAINING_WHITELIST_SMART_CONTRACT_ALLOWANCE - alreadyMintedNFTs
                        : 0;
                return (
                    totalAllowance,
                    REMAINING_WHITELIST_SMART_CONTRACT_ALLOWANCE
                );
            }
        }
        // We get the actual whitelistSmartContractAllowance here
        uint whitelistSmartContractAllowance = 0;
        for (uint i = 0; i < collectionStorage.getSmartContractsWhitelistCount(); i++) {
            // If user holds NFTs from a whitelisted smart contract, user is
            // given the corresponding whitelistSmartContractAllowance.
            if (
		        IERC721(
		            collectionStorage.getWhitelistedSmartContractAddressByIndex(i)
		        ).balanceOf(minter) != 0
            ) {
                whitelistSmartContractAllowance = whitelistSmartContractAllowance +
		            collectionStorage.getWhitelistedSmartContractAllowanceByIndex(i);
            }
        }
        // We return the sum of user's individualAllowance and whitelistSmartContractAllowance
        // as the total minting allowance for this user. We subtract the already minted NFTs.
        totalAllowance =
            individualAllowance + whitelistSmartContractAllowance > alreadyMintedNFTs
                ? individualAllowance + whitelistSmartContractAllowance - alreadyMintedNFTs
                : 0;
        return (totalAllowance, requiredWhitelistSmartContractAllowance);
    }
    function safeMint(
        address collectionProxy,
        address minter,
        address to,
        uint numberOfTokens
    )
        external
        payable
        requireCollectionProxy
        whenNotPaused
    {
        require(numberOfTokens > 0, 'ERC721Manager: mint at least one NFT');
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        if (
            block.number > collectionStorage.getBlockStartWhitelistPhase() &&
            block.number < collectionStorage.getBlockEndWhitelistPhase()
        ) {
            // Whitelist-sale phase (only whitelisted addresses or holders of NFTs
            // from whitelistedSmartContracts can mint)
            (uint totalAllowance, uint requiredWhitelistSmartContractAllowance) = getAllowedMints(collectionProxy, minter, numberOfTokens);
            require(
		        numberOfTokens <= totalAllowance,
		        'ERC721Manager: Exceeds address allowance'
            );
            if (requiredWhitelistSmartContractAllowance > 0) {
                // We then update REMAINING_WHITELIST_SMART_CONTRACT_ALLOWANCE by subtracting the
                // calculated requiredWhitelistSmartContractAllowance value.
                collectionStorage.setREMAINING_WHITELIST_SMART_CONTRACT_ALLOWANCE(
                    collectionStorage.getREMAINING_WHITELIST_SMART_CONTRACT_ALLOWANCE() -
                    requiredWhitelistSmartContractAllowance
                );
            }
            processSafeMint(collectionProxy, collectionStorage, minter, to, numberOfTokens);
        } else {
            if (
                block.number > collectionStorage.getBlockStartPublicPhase() &&
		        block.number < collectionStorage.getBlockEndPublicPhase()
            ) {
                // Public-sale phase (anyone can mint)
                require(
                    numberOfTokens <=
                        collectionStorage.getMAX_PUBLIC_MINT_PER_ADDRESS() -
                            collectionStorage.getBalance(minter)
                    ,
                    'ERC721Manager: Exceeds address allowance'
                );
                processSafeMint(collectionProxy, collectionStorage, minter, to, numberOfTokens);
            }
        }
    }
    function processSafeMint(
        address collectionProxy,
        ICollectionStorage collectionStorage,
        address minter,
        address to,
        uint numberOfTokens
    )
        private
        requireCollectionProxy
        whenNotPaused
        noReentry
    {
        uint totalPrice = collectionStorage.getPRICE_PER_NFT() * numberOfTokens;
        require(totalPrice <= msg.value, 'ERC721Manager: Ether value sent is not enough');
        // Transfer totalPrice to MintFeeRecipient
    	(bool success, bytes memory data) = _storage.getMintFeeRecipient().call{value: totalPrice}('');
    	require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'ERC721Manager: failed to transfer ETH'
        );
        uint256 balance =  address(this).balance;
        // Resend excess funds to user
    	(success, data) = minter.call{value: balance}('');
    	require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'ERC721Manager: failed to transfer ETH'
        );
        uint256 totalSupply = collectionStorage.getTotalSupply();
        require(
            totalSupply + numberOfTokens <= collectionStorage.getMAX_SUPPLY(),
            'ERC721Manager: Purchase would exceed max supply'
        );
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(collectionProxy, collectionStorage, minter, to, '');
        }
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address collectionProxy, address owner) public view virtual returns (uint256) {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        require(owner != address(0), 'ERC721Manager: balance query for the zero address');
        return collectionStorage.getBalance(owner);
    }
    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(address collectionProxy, uint256 tokenId) public view virtual returns (address) {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        address owner = collectionStorage.getOwner(tokenId);
        require(owner != address(0), 'ERC721Manager: owner query for nonexistent token');
        return owner;
    }
    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name(address collectionProxy) external view virtual returns (string memory) {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        return collectionStorage.getName();
    }
    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol(address collectionProxy) external view virtual returns (string memory) {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        return collectionStorage.getSymbol();
    }
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(address collectionProxy, uint256 tokenId) external view virtual returns (string memory) {
        require(_exists(collectionProxy, tokenId), 'ERC721Manager: URI query for nonexistent token');
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        if (collectionStorage.getCollectionMoved()) {
            return collectionStorage.getMovementNoticeURI();
        }
        string memory baseURI_local = collectionStorage.getBaseURI();
        return bytes(baseURI_local).length > 0 ? string(abi.encodePacked(baseURI_local, tokenId.toString())) : '';
    }
    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(address collectionProxy, uint256 tokenId) public view virtual returns (address) {
        require(_exists(collectionProxy, tokenId), 'ERC721Manager: approved query for nonexistent token');
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        return collectionStorage.getTokenApproval(tokenId);
    }
    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address collectionProxy, address owner, address operator)
	public
	view
	virtual
	returns (bool)
    {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        return collectionStorage.getOperatorApproval(owner, operator);
    }
   /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - `burner` must own `tokenId` or be an approved operator.
     */
    function burn(
        address collectionProxy,
        address burner,
        uint256 tokenId
    )
        external
        requireCollectionProxy
        whenNotPaused
    {
        require(
            _isApprovedOrOwner(collectionProxy, burner, tokenId),
            'ERC721Manager: caller is not owner nor approved'
        );
        _burn(collectionProxy, tokenId);
    }
    /**
     * @dev See {IERC721-approve}.
     */
    function approve(
        address collectionProxy,
        address msgSender,
        address spender,
        uint256 tokenId
    )
        external
        requireCollectionProxy
        whenNotPaused
    {
        address owner = ownerOf(collectionProxy, tokenId);
        require(spender != owner, 'ERC721Manager: approval to current owner');
        require(
            msgSender == owner || isApprovedForAll(collectionProxy, owner, msgSender),
            'ERC721Manager: approve caller is not owner nor approved for all'
        );
        _approve(collectionProxy, spender, tokenId);
    }
    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address collectionProxy,
        address spender,
        address from,
        address to,
        uint256 tokenId
    )
        external
        requireCollectionProxy
        whenNotPaused
    {
        require(
            _isApprovedOrOwner(collectionProxy, spender, tokenId),
            'ERC721Manager: transfer caller is not owner nor approved'
        );
        _transfer(collectionProxy, from, to, tokenId);
    }
    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address collectionProxy,
        address spender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    )
        external
        requireCollectionProxy
        whenNotPaused
    {
        require(
            _isApprovedOrOwner(collectionProxy, spender, tokenId),
            'ERC721Manager: transfer caller is not owner nor approved'
        );
        _safeTransferFrom(collectionProxy, spender, from, to, tokenId, _data);
    }
    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(
        address collectionProxy,
        address owner,
        address operator,
        bool approved
    )
        external
        requireCollectionProxy
        whenNotPaused
    {
        _setApprovalForAll(collectionProxy, owner, operator, approved);
    }
    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransferFrom(
        address collectionProxy,
        address spender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(collectionProxy, from, to, tokenId);
        require(
            _checkOnERC721Received(spender, from, to, tokenId, _data),
            'ERC721Manager: transfer to non ERC721Receiver implementer'
        );
    }
    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(
        address collectionProxy,
        uint256 tokenId
    )
        internal
        view
        virtual
        returns (bool)
    {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        return collectionStorage.getOwner(tokenId) != address(0);
    }
    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(
        address collectionProxy,
        address spender,
        uint256 tokenId
    )
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(collectionProxy, tokenId),
            'ERC721Manager: operator query for nonexistent token'
        );
        address owner = ownerOf(collectionProxy, tokenId);
        return (spender == owner ||
            getApproved(collectionProxy, tokenId) == spender ||
            isApprovedForAll(collectionProxy, owner, spender)
        );
    }
    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address collectionProxy,
        ICollectionStorage collectionStorage,
        address minter,
        address to,
        bytes memory _data
    ) internal virtual {
        uint tokenId = _mint(collectionProxy, collectionStorage, to);
        require(
            _checkOnERC721Received(minter, address(0), to, tokenId, _data),
            'ERC721Manager: transfer to non ERC721Receiver implementer'
        );
    }
    /**
     * @dev Mints token and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address collectionProxy,
        ICollectionStorage collectionStorage,
        address to
    ) internal virtual returns (uint) {
        require(to != address(0), 'ERC721Manager: mint to the zero address');
        uint tokenId = collectionStorage.getTotalSupply() + 1;
        collectionStorage.setTotalSupply(tokenId);
        collectionStorage.setBalance(to, collectionStorage.getBalance(to) + 1);
        collectionStorage.setOwner(tokenId, to);
        ICollectionProxy(collectionProxy).emitTransfer(address(0), to, tokenId);
        return tokenId;
    }
    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(address collectionProxy, uint256 tokenId) internal virtual {
        ICollectionStorage collectionStorage = ICollectionStorage(_storage.getCollectionStorage(collectionProxy));
        address owner = ownerOf(collectionProxy, tokenId);
        // Clear approvals
        _approve(collectionProxy, address(0), tokenId);
        collectionStorage.setBalance(owner, collectionStorage.getBalance(owner) - 1);
        collectionStorage.setOwner(tokenId, address(0));
        ICollectionProxy(collectionProxy).emitTransfer(owner, address(0), tokenId);
    }
    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address collectionProxy,
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ownerOf(collectionProxy, tokenId) == from,
            'ERC721Manager: transfer from incorrect owner'
        );
        require(to != address(0), 'ERC721Manager: transfer to the zero address');
        ICollectionStorage collectionStorage = ICollectionStorage(_storage.getCollectionStorage(collectionProxy));
        // Clear approvals from the previous owner
        _approve(collectionProxy, address(0), tokenId);
        collectionStorage.setBalance(from, collectionStorage.getBalance(from) - 1);
        collectionStorage.setBalance(to, collectionStorage.getBalance(to) + 1);
        collectionStorage.setOwner(tokenId, to);
        ICollectionProxy(collectionProxy).emitTransfer(from, to, tokenId);
    }
    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address collectionProxy, address spender, uint256 tokenId) internal virtual {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        collectionStorage.setTokenApproval(tokenId, spender);
        ICollectionProxy(collectionProxy).emitApproval(
            ownerOf(collectionProxy, tokenId),
            spender,
            tokenId
        );
    }
    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
     function _setApprovalForAll(
        address collectionProxy,
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, 'ERC721Manager: approve to caller');
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        collectionStorage.setOperatorApproval(owner, operator, approved);
        ICollectionProxy(collectionProxy).emitApprovalForAll(owner, operator, approved);
    }
    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address msgSender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msgSender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert('ERC721Manager: transfer to non ERC721Receiver implementer');
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
    function baseURI(address collectionProxy) external view returns (string memory) {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        return collectionStorage.getBaseURI();
    }
    function exists(address collectionProxy, uint256 tokenId) public view returns (bool) {
        return _exists(collectionProxy, tokenId);
    }
    function getCollectionStorageAddress(address collectionProxy) external view returns(address _collectionStorage) {
        _collectionStorage =_storage.getCollectionStorage(collectionProxy);
    }
    function getTotalSupply(address collectionProxy) external view returns(uint _totalSupply) {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        _totalSupply = collectionStorage.getTotalSupply();
    }
    function setBaseURI(address collectionProxy, string calldata baseURI_) external onlyOwner {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        collectionStorage.setBaseURI(baseURI_);
    }
    function setName(address collectionProxy, string calldata newName) external onlyOwner {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        collectionStorage.setName(newName);
    }
    function setSymbol(address collectionProxy, string calldata newSymbol) external onlyOwner {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        collectionStorage.setSymbol(newSymbol);
    }
    function setPRICE_PER_NFT(address collectionProxy, uint _value) external onlyOwner {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        collectionStorage.setPRICE_PER_NFT(_value);
    }
    function setREMAINING_WHITELIST_SMART_CONTRACT_ALLOWANCE(address collectionProxy, uint _value) external onlyOwner {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        collectionStorage.setREMAINING_WHITELIST_SMART_CONTRACT_ALLOWANCE(_value);
    }
    function setMAX_PUBLIC_MINT_PER_ADDRESS(address collectionProxy, uint _value) external onlyOwner {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        collectionStorage.setMAX_PUBLIC_MINT_PER_ADDRESS(_value);
    }
    function setMAX_SUPPLY(address collectionProxy, uint _value) external onlyOwner {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        collectionStorage.setMAX_SUPPLY(_value);
    }
    function setWhitelistPhase(address collectionProxy, uint _blockStartWhitelistPhase, uint _blockEndWhitelistPhase) external onlyOwner {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        collectionStorage.setWhitelistPhase(_blockStartWhitelistPhase, _blockEndWhitelistPhase);
    }
    function setPublicPhase(address collectionProxy, uint _blockStartPublicPhase, uint _blockEndPublicPhase) external onlyOwner {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        collectionStorage.setPublicPhase(_blockStartPublicPhase, _blockEndPublicPhase);
    }
    function setCollectionMoved(address collectionProxy, bool _collectionMoved) external onlyOwner {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        collectionStorage.setCollectionMoved(_collectionMoved);
    }
    function setMovementNoticeURI(address collectionProxy, string calldata _movementNoticeURI) external onlyOwner {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        collectionStorage.setMovementNoticeURI(_movementNoticeURI);
    }
    function setMintFeeRecipient(address _mintFeeRecipient) external onlyOwner {
        _storage.setMintFeeRecipient(_mintFeeRecipient);
    }
    function royaltyInfo(address collectionProxy, uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address, uint256)
    {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        address receiver = collectionStorage.getRoyaltyReceiver(tokenId);
        uint96 fraction;
        if (receiver != address(0)){
            fraction = collectionStorage.getRoyaltyFraction(tokenId);
        } else {
            fraction = collectionStorage.getDefaultRoyaltyFraction();
            receiver = collectionStorage.getDefaultRoyaltyReceiver();
        }
        uint256 royaltyAmount = (salePrice * fraction) / collectionStorage.getFeeDenominator();
        return (receiver, royaltyAmount);
    }
    function setDefaultRoyalty(address collectionProxy, address receiver, uint96 feeNumerator) external onlyOwner {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        require(feeNumerator <= collectionStorage.getFeeDenominator(), 'ERC721Manager: royalty fee will exceed salePrice');
        collectionStorage.setDefaultRoyaltyInfo(receiver, feeNumerator);
    }
    function setFeeDenominator(address collectionProxy, uint96 value) external onlyOwner {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        collectionStorage.setFeeDenominator(value);
    }
    function setTokenRoyalty(
        address collectionProxy,
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        require(feeNumerator <= collectionStorage.getFeeDenominator(), 'ERC721Manager: royalty fee will exceed salePrice');
        collectionStorage.setRoyaltyInfo(tokenId, receiver, feeNumerator);
    }
}
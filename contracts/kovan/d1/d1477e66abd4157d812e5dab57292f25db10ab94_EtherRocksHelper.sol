// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../escrow/NFTEscrow.sol";
import "../interfaces/IEtherRocks.sol";

 /// @title EtherRocks NFTVault helper contract
 /// @notice Allows compatibility between EtherRocks and {NFTVault}
 /// @dev EtherRocks IERC721 compatibility.
 /// Meant to only be used by {NFTVault}.
 /// This contract is NOT an ERC721 wrapper for rocks and is not meant to implement the ERC721 interface fully, 
 /// its only purpose is to serve as a proxy between {NFTVault} and EtherRocks.
 /// The owner is {NFTVault}
contract EtherRocksHelper is NFTEscrow, OwnableUpgradeable {

    /// @param rocksAddress Address of the EtherRocks contract
    function initialize(address rocksAddress) external initializer {
        __NFTEscrow_init(rocksAddress);
        __Ownable_init();
    }

    /// @notice Returns the owner of the rock at index `_idx`
    /// @dev If the owner of the rock is this contract we return the address of the {NFTVault} for compatibility
    /// @param _idx The rock index
    /// @return The owner of the rock if != `address(this)`, otherwise the the owner of this contract
    function ownerOf(uint256 _idx) external view returns (address) {
        (address account,,,) = IEtherRocks(nftAddress).getRockInfo(_idx);

        return account == address(this) ? owner() : account;
    }

    /// @notice Function called by {NFTVault} to transfer rocks. Can only be called by the owner
    /// @param _from The sender address
    /// @param _to The recipient address
    /// @param _idx The index of the rock to transfer
    function transferFrom(
        address _from,
        address _to,
        uint256 _idx
    ) external onlyOwner {
        _transferFrom(_from, _to, _idx);
    }

    /// @dev We aren't calling {onERC721Received} on the _to address because rocks don't implement
    /// the {ERC721} interface, but we are including this function for compatibility with the {NFTVault} contract.
    /// Calling the {onERC721Received} function on the receiver contract could cause problems as we aren't sending an ERC721.
    /// @param _from The sender address
    /// @param _to The recipient address
    /// @param _idx The index of the rock to transfer
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _idx
    ) external onlyOwner {
        _transferFrom(_from, _to, _idx);
    }

    /// @inheritdoc NFTEscrow
    function rescueNFT(uint256 _idx) external override {
        IEtherRocks rocks = IEtherRocks(nftAddress);
        (, address predictedAddress) = precompute(msg.sender, _idx);
        (address owner,,,) = rocks.getRockInfo(_idx);
        require(owner == predictedAddress, "NOT_OWNER");
        assert(owner != address(this)); //this should never happen

        _executeTransfer(msg.sender, _idx);
        rocks.giftRock(_idx, msg.sender);
    }

    /// @dev Implementation of {transferFrom} and {safeTransferFrom}. We are using {NFTEscrow} for atomic transfers.
    /// See {NFTEscrow} for more info
    /// @param _from The sender address
    /// @param _to The recipient address
    /// @param _idx The index of the rock to transfer
    function _transferFrom(
        address _from,
        address _to,
        uint256 _idx
    ) internal {
        IEtherRocks rocks = IEtherRocks(nftAddress);

        (address account,,,) = rocks.getRockInfo(_idx);

        //if the owner is this address we don't need to go through {NFTEscrow}
        if (account != address(this)) {
            _executeTransfer(_from, _idx);
        }

        (address newOwner,,,) = rocks.getRockInfo(_idx);

        assert(
            newOwner == address(this) //this should never be false
        );

        //remove rock from sale
        rocks.dontSellRock(_idx);

        //If _to is the owner ({NFTVault}), we aren't sending the rock
        //since we'd have no way to get it back
        if (_to != owner()) rocks.giftRock(_idx, _to);
    }

    /// @dev Prevent the owner from renouncing ownership. Having no owner would render this contract unusable
    function renounceOwnership() public view override onlyOwner {
        revert("Cannot renounce ownership");
    }

    /// @dev The {giftRock} function is used as the escrow's payload.
    /// @param _idx The index of the rock that's going to be transferred using {NFTEscrow}
    function _encodeFlashEscrowPayload(uint256 _idx)
        internal
        view
        override
        returns (bytes memory)
    {
        return
            abi.encodeWithSignature(
                "giftRock(uint256,address)",
                _idx,
                address(this)
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

//inspired by https://github.com/thousandetherhomepage/ketherhomepage/blob/master/contracts/KetherNFT.sol
/// @title FlashEscrow contract 
/// @notice This contract sends and receives non ERC721 NFTs
/// @dev Deployed for each NFT, its address is calculated by {NFTEscrow} prior to it being deployed to allow atomic non ERC721 transfers 
contract FlashEscrow {

    /// @dev The contract selfdestructs in the constructor, its only purpose is to perform one call to the `target` address using `payload` as the payload
    /// @param target The call recipient
    /// @param payload The payload to use for the call
    constructor(address target, bytes memory payload) {
        (bool success, ) = target.call(payload);
        require(success, "FlashEscrow: call_failed");

        selfdestruct(payable(target));
    }
}

/// @title Escrow contract for non ERC721 NFTs
/// @notice Handles atomic non ERC721 NFT transfers by using {FlashEscrow}
/// @dev NFTEscrow allows an atomic, 2 step mechanism to transfer non ERC721 NFTs without requiring prior reservation.
/// - Users send the NFT to a precomputed address (calculated using the owner's address as salt) that can be fetched by calling the `precompute` function
/// - The child contract can then call the `_executeTransfer` function to deploy an instance of the {FlashEscrow} contract, deployed at the address calculated in the previous step
/// This allows atomic transfers, as the address calculated by the `precompute` function is unique and changes depending by the `_owner` address and the NFT index (`_idx`).
/// This is an alternative to the classic "reservation" method, which requires users to call 3 functions in a specifc order (making the process non atomic)
abstract contract NFTEscrow is Initializable {
    /// @notice The address of the non ERC721 NFT supported by the child contract
    address public nftAddress;

    /// @dev Initializer function, see https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable
    /// @param _nftAddress See `nftAddress`
    function __NFTEscrow_init(address _nftAddress) internal initializer {
        nftAddress = _nftAddress;
    }

    /// @dev Computes the bytecode of the {FlashEscrow} instance to deploy
    /// @param _idx The index of the NFT that's going to be sent to the {FlashEscrow} instance
    /// @return The bytecode of the {FlashEscrow} instance relative to the NFT at index `_idx`
    function _encodeFlashEscrow(uint256 _idx)
        internal
        view
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                type(FlashEscrow).creationCode,
                abi.encode(nftAddress, _encodeFlashEscrowPayload(_idx))
            );
    }

    /// @dev Virtual function, should return the `payload` to use in {FlashEscrow}'s constructor
    /// @param _idx The index of the NFT that's going to be sent to the {FlashEscrow} instance
    function _encodeFlashEscrowPayload(uint256 _idx)
        internal
        view
        virtual
        returns (bytes memory);

    /// @dev Deploys a {FlashEscrow} instance relative to owner `_owner` and index `_idx`
    /// @param _owner The owner of the NFT at index `_idx`
    /// @param _idx The index of the NFT owned by `_owner` 
    function _executeTransfer(address _owner, uint256 _idx) internal {
        (bytes32 salt, ) = precompute(_owner, _idx);
        new FlashEscrow{salt: salt}(
            nftAddress,
            _encodeFlashEscrowPayload(_idx)
        );
    }

    /// @notice This function returns the address where user `_owner` should send the `_idx` NFT to
    /// @dev `precompute` computes the salt and the address relative to NFT at index `_idx` owned by `_owner`
    /// @param _owner The owner of the NFT at index `_idx`
    /// @param _idx The index of the NFT owner by `_owner`
    /// @return salt The salt that's going to be used to deploy the {FlashEscrow} instance
    /// @return predictedAddress The address where the {FlashEscrow} instance relative to `_owner` and `_idx` will be deployed to
    function precompute(address _owner, uint256 _idx)
        public
        view
        returns (bytes32 salt, address predictedAddress)
    {
        require(
            _owner != address(this) && _owner != address(0),
            "NFTEscrow: invalid_owner"
        );

        salt = sha256(abi.encodePacked(_owner));

        bytes memory bytecode = _encodeFlashEscrow(_idx);

        //hash from which the contract address can be derived
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );

        predictedAddress = address(uint160(uint256(hash)));
        return (salt, predictedAddress);
    }

    /// @notice Can be called to rescue an NFT using a FlashEscrow contract.
    /// It transfers the NFT from the address calculated with `precompute(msg.sender, _idx)` to `msg.sender`
    function rescueNFT(uint256 _idx) external virtual;

    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IEtherRocks {
    function getRockInfo(uint256 rockNumber)
        external
        view
        returns (
            address,
            bool,
            uint256,
            uint256
        );

    function giftRock(uint256 rockNumber, address receiver) external;

    function dontSellRock(uint256 rockNumber) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
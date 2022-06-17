//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title AmericanaFactory
 * @author floop (floop.eth)
 * @notice This contract is used to facilitate new physical item listings and their accompanied
 *          escrow's on the Americana Marketplace.
 */

interface IMinter {
  function mint(address, uint256) external;
}

contract AmericanaFactory is ReentrancyGuard {
  string public constant implementation = "AmericanaFactory";
  string public constant version = "1.0";

  IMinter public MinterContract;

  event ListingCreated(uint24 _itemId, address _seller, uint256 _amount);
  event EscrowCreated(uint24 _itemId, address _buyer, uint256 _amount);
  event EscrowApproved(address _buyer, address _seller, uint256 _amount);
  event EscrowRejected(address _buyer, address _seller, uint256 _amount);
  event NewAuthorization(address _newAuthorized);
  event RemoveAuthorization(address _removeAuthorized);
  event FeeChange(uint256 _oldFee, uint256 _newFee);
  event EscrowFundsWithdrawal(uint256 _escrowId, uint256 _ammount, address _recipient);
  event ContractPauseSwap(bool _swappedTo);
  event FeesWithdrawal(address _feeRecipient, uint256 _pendingFees);
  event BuyerWantsPhysical(address _buyer, uint256 _escrowID);
  event NFTMinted(address _buyer, uint256 _escrowID);
  event NFTAvailableToMint(address _buyer, uint256 _escrowID);
  event NewMintAddress(address _newMintContractAddress);
  event UpdateEscrowType(uint256 _escrowID, bool _wantsNFT);
  event NewMaxEscrowDuration(uint8 _days);

  error Unauthorized();
  error ListingActive();
  error EscrowActive();
  error ListingInactive();
  error EscrowInactive();
  error ZeroPrice();
  error ImproperValueSent();
  error ImproperItemID();
  error WithdrawalFail();
  error Ineligible();
  error Paused();

  modifier onlyAuthorized() {
    if (isAuthorized[msg.sender] == false) revert Unauthorized();
    _;
  }
  modifier notPaused() {
    if (paused == true) revert Paused();
    _;
  }

  struct Escrow {
    address payable buyer;
    uint32 timestamp; // good until year 2106
    uint24 itemID; // 16,777,215 possibilities
    bool wantsNFT;
  }

  struct Listing {
    address payable seller;
    uint72 price; // max 4726 ether
    uint24 itemID; // 16,777,215 possibilities
  }

  address payable public feeRecipient;
  address public AmericanaMintAddress;

  bool public paused;

  uint32 public maxEscrowDuration;

  uint256 public marketFee;
  uint256 public pendingFees;

  mapping(address => bool) public isAuthorized;
  mapping(uint24 => Escrow) public escrowByID;
  mapping(uint24 => Listing) public listingsByID;
  mapping(uint24 => bool) public availableToMint;

  // IMPORTANT!: For future reference, when adding new variables for following versions of the factory.
  // All the previous ones should be kept in place and not change locations, types or names.
  // If they're modified this would cause issues with the memory slots.

  constructor(
    address payable _feeRecipient,
    uint8 _maxEscrowDurationInDays,
    uint256 _marketFee,
    address _minterAddress,
    address admin
  ) {
    isAuthorized[msg.sender] = true;
    isAuthorized[admin] = true;
    maxEscrowDuration = _maxEscrowDurationInDays * 86400; //1 day
    pendingFees = 0;
    paused = false;
    marketFee = _marketFee;
    feeRecipient = _feeRecipient;
    AmericanaMintAddress = _minterAddress;
    MinterContract = IMinter(_minterAddress);
  }

  //we cant gurantee that people wont make listings with itemids that we  did not provide them.

  //so we will have to track legit items on backend to display and query contract before issuing new itemids.

  //this also means that someone could in theory pay like $4 per listing and start eating up itemID's
  function createListing(uint24 _itemId, uint72 _price) external notPaused {
    if (listingsByID[_itemId].price != 0) revert ImproperItemID();
    if (_price == 0) revert ZeroPrice();

    listingsByID[_itemId] = Listing(payable(msg.sender), _price, _itemId);
    emit ListingCreated(_itemId, msg.sender, _price);
  }

  function createEscrow(uint24 _itemid, bool _wantsNFT) external payable notPaused {
    if (listingsByID[_itemid].seller == payable(address(0))) revert ListingInactive();
    if (escrowByID[_itemid].buyer != payable(address(0))) revert EscrowActive();
    if (listingsByID[_itemid].price != msg.value) revert ImproperValueSent();

    escrowByID[_itemid] = Escrow(payable(msg.sender), uint32(block.timestamp), _itemid, _wantsNFT);

    emit EscrowCreated(_itemid, msg.sender, msg.value);
  }

  function mint(uint24 _itemid) external notPaused {
    if (availableToMint[_itemid] == false) revert Ineligible();

    availableToMint[_itemid] = false;

    MinterContract.mint(escrowByID[_itemid].buyer, 1);

    emit NFTMinted(escrowByID[_itemid].buyer, _itemid);

    escrowByID[_itemid].buyer = payable(address(0));
  }

  //used to solidify max authenitication time and reduce chance of funds locking in contract
  function withdrawEscrowFunds(uint24 _itemid) external nonReentrant {
    if (escrowByID[_itemid].buyer != msg.sender) revert Ineligible();
    if (listingsByID[_itemid].seller == payable(address(0))) revert Ineligible();
    if (block.timestamp < escrowByID[_itemid].timestamp + maxEscrowDuration) revert Ineligible();

    (bool success, ) = escrowByID[_itemid].buyer.call{ value: listingsByID[_itemid].price }("");
    if (success == false) revert WithdrawalFail();

    escrowByID[_itemid].buyer = payable(address(0));

    emit EscrowFundsWithdrawal(_itemid, listingsByID[_itemid].price, escrowByID[_itemid].buyer);
  }

  //Authorized functions

  //deal with funds of items that pass authentication
  function approveItem(uint24 _itemid) external onlyAuthorized nonReentrant {
    if (escrowByID[_itemid].buyer == payable(address(0))) revert EscrowInactive();
    if (listingsByID[_itemid].seller == payable(address(0))) revert ListingInactive();

    uint256 fee = (marketFee * listingsByID[_itemid].price) / 1000;

    pendingFees += fee;

    (bool success, ) = listingsByID[_itemid].seller.call{ value: listingsByID[_itemid].price - fee }("");
    if (success == false) revert WithdrawalFail();

    if (escrowByID[_itemid].wantsNFT) {
      availableToMint[_itemid] = true;
      emit NFTAvailableToMint(escrowByID[_itemid].buyer, _itemid);
    } else {
      emit BuyerWantsPhysical(escrowByID[_itemid].buyer, _itemid);
    }

    emit EscrowApproved(escrowByID[_itemid].buyer, listingsByID[_itemid].seller, listingsByID[_itemid].price);

    listingsByID[_itemid].seller = payable(address(0));
  }

  //deal with funds of items that fail authentication
  function rejectItem(uint24 _itemid) external onlyAuthorized nonReentrant {
    if (escrowByID[_itemid].buyer == payable(address(0))) revert EscrowInactive();
    if (listingsByID[_itemid].seller == payable(address(0))) revert ListingInactive();

    (bool success, ) = escrowByID[_itemid].buyer.call{ value: listingsByID[_itemid].price }("");
    if (success == false) revert WithdrawalFail();

    emit EscrowRejected(escrowByID[_itemid].buyer, listingsByID[_itemid].seller, listingsByID[_itemid].price);

    escrowByID[_itemid].buyer = payable(address(0));
    listingsByID[_itemid].seller = payable(address(0));
  }

  function swapPause() external onlyAuthorized {
    paused = !paused;

    emit ContractPauseSwap(!paused);
  }

  function changeMaxEscrowDuration(uint8 _days) external onlyAuthorized {
    require(_days >= 14 && _days <= 30);

    maxEscrowDuration = _days * 86400; //1 day

    emit NewMaxEscrowDuration(_days);
  }

  function addAuthorized(address addressToAuthorize) external onlyAuthorized {
    isAuthorized[addressToAuthorize] = true;

    emit NewAuthorization(addressToAuthorize);
  }

  function removeAuthorized(address addressToRemoveAuthorize) external onlyAuthorized {
    isAuthorized[addressToRemoveAuthorize] = false;

    emit RemoveAuthorization(addressToRemoveAuthorize);
  }

  function updateEscrowType(uint24 _itemid, bool _wantsNFT) external onlyAuthorized {
    require(escrowByID[_itemid].wantsNFT != _wantsNFT, "AmericanaFactory: Updating to same type");
    escrowByID[_itemid].wantsNFT = _wantsNFT;

    emit UpdateEscrowType(_itemid, _wantsNFT);
  }

  //struct getters
  function getEscrowByID(uint24 _itemid) external view returns (Escrow memory) {
    return escrowByID[_itemid];
  }

  function getListingByID(uint24 _itemid) external view returns (Listing memory) {
    return listingsByID[_itemid];
  }

  //fee stuff
  function changeMarketFee(uint256 newFee) external onlyAuthorized {
    require(newFee <= 100, "AmericanaFactory: Max fee of 10%");
    marketFee = newFee;

    emit FeeChange(marketFee, newFee);
  }

  function withdrawFees() external onlyAuthorized {
    require(pendingFees > 0, "AmericanaFactory: No fees to withdraw");
    uint256 fees = pendingFees;
    pendingFees = 0;
    (bool success, ) = feeRecipient.call{ value: fees }("");
    require(success, "AmericanaFactory: Failed to withdraw ether");

    emit FeesWithdrawal(feeRecipient, pendingFees);
  }

  //contract interoperability
  function updateMinterAddress(address _newMinter) external onlyAuthorized {
    AmericanaMintAddress = _newMinter;
    MinterContract = IMinter(_newMinter);
    emit NewMintAddress(_newMinter);
  }

  //reverts any eth sent to contract
  receive() external payable {
    revert("Contract cannot receive ether");
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuard is Initializable{
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

    function reentrancyInitialize() public initializer {
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
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
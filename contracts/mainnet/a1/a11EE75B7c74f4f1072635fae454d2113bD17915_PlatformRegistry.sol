// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@sbinft/contracts/upgradeable/access/AdminUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "contracts/sbinft/market/v1/interface/IPlatformRegistry.sol";

/**
 * @dev SBINFT Platform Registry
 */
contract PlatformRegistry is
  Initializable,
  IPlatformRegistry,
  EIP712Upgradeable,
  ERC2771ContextUpgradeable,
  AdminUpgradeable,
  ERC165Upgradeable,
  UUPSUpgradeable
{
  using AddressUpgradeable for address;
  using ECDSAUpgradeable for bytes32;

  // Fired when PlatformFeeReceiver is changed
  event PlatformFeeReceiverUpdated(address indexed _pfFeeReceiver);
  // Address of PlatformFeeReceiver
  address payable private _pfFeeReceiver;

  // Fired when PartnerFeeReceiverUpdated is changed
  event PartnerFeeReceiverUpdated(
    address indexed collection,
    address indexed partner
  );
  // Map of partner collection and its respective fee receivers
  mapping(address => address payable) private _partnerFeeReceiverInfo;

  event ERC20AddedToWhitelist(address addedToken);
  event ERC20RemovedFromWhitelist(address removedToken);
  // Map of ERC20 Token address => approve state
  mapping(address => bool) private _whitelistERC20;

  event PlatformSignerAdded(address addedAddress);
  event PlatformSignerRemoved(address removedAddress);
  // Map of Approved platform signer
  mapping(address => bool) private _platformSigner;

  // Fired when PartnerPfFeeReceiverUpdated is changed
  event PlatformFeeLowerRateUpdated(uint16 pfFeelowerlimit);
  // uint16 of pfFeeLowerLimit
  uint16 private _pfFeeLowerLimit;

  // Fired when ExternalPlatformFeeReceiverUpdated is changed
  event ExternalPlatformFeeReceiverUpdated(
    address indexed platformSigner,
    address indexed partnerPf
  );
  // Map of partner platformSigner and its respective fee receivers
  mapping(address => address payable) private _externalPfFeeReceiverInfo;

  bytes32 private constant UPDATE_PARTNER_FEE_RECEIVER_TYPEHASH =
    keccak256(
      "PartnerFeeReceiverInfo(address collection,address partnerFeeReceiver)"
    );

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor(
    address trustedForwarder
  ) ERC2771ContextUpgradeable(trustedForwarder) {
    _disableInitializers();
  }

  /**
   * @dev Used instead of constructor(must be called once)
   *
   * @param _pfFeeReceiver_ address of PlatformFeeReceiver
   * @param _platformSignerList address[] list of Platform Signer
   * @param _whitelistERC20List address[] list of whitlisted ERC20 token
   *
   * Emits a {PlatformFeeReceiverUpdated} event
   */
  function __PlatformRegistry_init(
    address payable _pfFeeReceiver_,
    address[] calldata _platformSignerList,
    address[] calldata _whitelistERC20List
  ) external initializer {
    __ERC165_init();
    AdminUpgradeable.__Admin_init();
    __EIP712_init("SBINFT Platform Registry", "1.0");
    __UUPSUpgradeable_init();

    updatePlatformFeeReceiver(_pfFeeReceiver_);

    addPlatformSigner(_platformSignerList);
    addToERC20Whitelist(_whitelistERC20List);
  }

  /**
   * @dev See {UUPSUpgradeable._authorizeUpgrade()}
   *
   * Requirements:
   * - onlyAdmin can call
   */
  function _authorizeUpgrade(
    address _newImplementation
  ) internal virtual override onlyAdmin {}

  /**
   * @dev See {IERC165Upgradeable-supportsInterface}.
   *
   * @param _interfaceId bytes4
   */
  function supportsInterface(
    bytes4 _interfaceId
  )
    public
    view
    virtual
    override(ERC165Upgradeable, IERC165Upgradeable)
    returns (bool)
  {
    return
      _interfaceId == type(IPlatformRegistry).interfaceId ||
      super.supportsInterface(_interfaceId);
  }

  /**
   * See {ERC2771ContextUpgradeable._msgSender()}
   */
  function _msgSender()
    internal
    view
    virtual
    override(ContextUpgradeable, ERC2771ContextUpgradeable)
    returns (address sender)
  {
    return ERC2771ContextUpgradeable._msgSender();
  }

  /**
   * See {ERC2771ContextUpgradeable._msgData()}
   */
  function _msgData()
    internal
    view
    virtual
    override(ContextUpgradeable, ERC2771ContextUpgradeable)
    returns (bytes calldata)
  {
    return ERC2771ContextUpgradeable._msgData();
  }

  /**
   * @dev Update to new PlatformFeeReceiver
   *
   * @param _newPlatformFeeReceiver new PlatformFeeReceiver
   *
   * Requirements:
   * - _newPlatformFeeReceiver must be a non zero address
   *
   * Emits a {PlatformFeeReceiverUpdated} event
   */
  function updatePlatformFeeReceiver(
    address payable _newPlatformFeeReceiver
  ) public virtual override onlyAdmin {
    // EM: new PlatformFeeReceiver can't be zero address
    require(_newPlatformFeeReceiver != address(0), "P:UPFR:PZA");

    _pfFeeReceiver = _newPlatformFeeReceiver;

    emit PlatformFeeReceiverUpdated(_newPlatformFeeReceiver);
  }

  /**
   * @dev Update to new PartnerFeeReceiver for partner's collection
   *
   * @param collection partner's collection
   * @param partnerFeeReceiver new partner's FeeReceiver
   * @param sign bytes calldata
   *
   * Requirements:
   * - collection must be a contract address
   * - partnerFeeReceiver must be a non zero address
   *
   * Emits a {PartnerFeeReceiverUpdated} event
   */
  function updatePartnerFeeReceiver(
    address collection,
    address payable partnerFeeReceiver,
    bytes calldata sign
  ) external virtual override {
    // EM: partner's collection must be a contract address
    require(collection.isContract(), "P:UPFR:PCCA");
    // EM: new PartnerFeeReceiver can't be zero address
    require(partnerFeeReceiver != address(0), "P:UPFR:NPZA");

    // caller is an Admin or its called with Platform signature
    if (isAdmin(_msgSender()) == false) {
      // Prepares ERC712 message hash of updatePartnerFeeReceiver signature
      bytes32 msgHash = keccak256(
        abi.encode(
          UPDATE_PARTNER_FEE_RECEIVER_TYPEHASH,
          collection,
          partnerFeeReceiver
        )
      );

      address recoverdAddress = _domainSeparatorV4()
        .toTypedDataHash(msgHash)
        .recover(sign);
      // EM: invalid platform signer
      require(isPlatformSigner(recoverdAddress), "P:UPFR:IPS");
    }

    _partnerFeeReceiverInfo[collection] = partnerFeeReceiver;

    emit PartnerFeeReceiverUpdated(collection, partnerFeeReceiver);
  }

  /**
   * @dev Checks if partner fee receiver
   *
   * @param _collection address of token
   * @param _partnerFeeReceiver address of partner FeeReceiver
   *
   * Requirements:
   * - _collection must be a non zero address
   * - _partnerFeeReceiver must be a non zero address
   */
  function isPartnerFeeReceiver(
    address _collection,
    address _partnerFeeReceiver
  ) public view virtual override returns (bool) {
    // EM: _collection must be a non zero address
    require(_collection != address(0), "P:IPFR:CNZA");
    // EM: _partnerFeeReceiver must be a non zero address
    require(_partnerFeeReceiver != address(0), "P:IPFR:PNZA");

    return _partnerFeeReceiverInfo[_collection] == _partnerFeeReceiver;
  }

  /**
   * @dev Checks state of a Whitelisted token
   *
   * @param _token address of token
   */
  function isWhitelistedERC20(
    address _token
  ) public view virtual override returns (bool) {
    return _whitelistERC20[_token];
  }

  /**
   * @dev Adds list of token to Whitelisted, if zero address then will be ignored
   *
   * @param _addTokenList array of address of token to add
   *
   * Requirements:
   * - onlyAdmin can call
   *
   * Emits a {AddedToWhitelist} event
   */
  function addToERC20Whitelist(
    address[] calldata _addTokenList
  ) public virtual override onlyAdmin {
    for (uint256 idx = 0; idx < _addTokenList.length; idx++) {
      address newToken = _addTokenList[idx];

      if (newToken != address(0) && newToken.isContract()) {
        _whitelistERC20[newToken] = true;
        emit ERC20AddedToWhitelist(newToken);
      }
    }
  }

  /**
   * @dev Removes list of token from Whitelisted
   *
   * @param _removeTokenList array of address of token to remove
   *
   * Requirements:
   * - onlyAdmin can call
   *
   * Emits a {RemovedFromWhitelist} event
   */
  function removeFromERC20Whitelist(
    address[] calldata _removeTokenList
  ) external virtual override onlyAdmin {
    for (uint256 idx = 0; idx < _removeTokenList.length; idx++) {
      address tokenToRemove = _removeTokenList[idx];
      if (tokenToRemove != address(0)) {
        delete _whitelistERC20[tokenToRemove];
        emit ERC20RemovedFromWhitelist(tokenToRemove);
      }
    }
  }

  /**
   * @dev Checks state of a Whitelisted token
   *
   * @param _signer address of token
   */
  function isPlatformSigner(
    address _signer
  ) public view virtual override returns (bool) {
    return _platformSigner[_signer];
  }

  /**
   * @dev Adds list of token to Whitelisted, if zero address then will be ignored
   *
   * @param _platformSignerList array of platfomr signer address  to add
   *
   * Requirements:
   * - onlyAdmin can call
   *
   * Emits a {PlatformSignerAdded} event
   */
  function addPlatformSigner(
    address[] calldata _platformSignerList
  ) public virtual override onlyAdmin {
    for (uint256 idx = 0; idx < _platformSignerList.length; idx++) {
      address newSigner = _platformSignerList[idx];
      if (newSigner != address(0)) {
        _platformSigner[newSigner] = true;
        emit PlatformSignerAdded(newSigner);
      }
    }
  }

  /**
   * @dev Removes list of platform signers address
   *
   * @param _platformSignerList array of platfomr signer address to remove
   *
   * Requirements:
   * - onlyAdmin can call
   *
   * Emits a {PlatformSignerRemoved} event
   */
  function removePlatformSigner(
    address[] calldata _platformSignerList
  ) external virtual override onlyAdmin {
    for (uint256 idx = 0; idx < _platformSignerList.length; idx++) {
      address signerToRemove = _platformSignerList[idx];
      if (signerToRemove != address(0)) {
        delete _platformSigner[signerToRemove];
        emit PlatformSignerRemoved(signerToRemove);
      }
    }
  }

  /**
   * @dev Returns PartnerFeeReceiver
   *
   * @param _token address of partner token
   */
  function getPartnerFeeReceiver(
    address _token
  ) external virtual override returns (address payable) {
    return _partnerFeeReceiverInfo[_token];
  }

  /**
   * @dev Returns PlatformFeeReceiver
   *
   */
  function getPlatformFeeReceiver()
    external
    view
    virtual
    override
    returns (address payable)
  {
    return _pfFeeReceiver;
  }

  /**
   * @dev Returns PlatformFeeReceiver
   *
   */
  function getPlatformFeeRateLowerLimit()
    public
    virtual
    override
    returns (uint16)
  {
    return _pfFeeLowerLimit;
  }

  /**
   * @dev Update to new PlatformFeeLowerLimit
   *
   * Emits a {PlatformFeeLowerRateUpdated} event
   */
  function updatePlatformFeeLowerLimit(
    uint16 _platformFeeLowerLimit
  ) external virtual override onlyAdmin {
    _pfFeeLowerLimit = _platformFeeLowerLimit;
    emit PlatformFeeLowerRateUpdated(_pfFeeLowerLimit);
  }

  /**
   * @dev Update to new PartnerPfFeeReceiver for partner's platformSigner
   *
   * @param _externalPlatformToken address of external Platform Token
   * @param _partnerPfFeeReceiver address new partner's platformer FeeReceiver
   *
   * Requirements:
   * - _platformSigner must be a non zero address
   * - _partnerPfFeeReceiver must be a non zero address
   *
   * Emits a {ExternalPfFeeReceiverUpdated} event
   */
  function updateExternalPlatformFeeReceiver(
    address _externalPlatformToken,
    address payable _partnerPfFeeReceiver
  ) external virtual override onlyAdmin {
    // EM: new platfromSigner can't be zero address
    require(_externalPlatformToken != address(0), "A:UPFR:NPZA");
    // EM: new PartnerFeeReceiver can't be zero address
    require(_partnerPfFeeReceiver != address(0), "A:UPFR:NPZA");

    _externalPfFeeReceiverInfo[_externalPlatformToken] = _partnerPfFeeReceiver;

    emit ExternalPlatformFeeReceiverUpdated(
      _externalPlatformToken,
      _partnerPfFeeReceiver
    );

    /**
     * Test cases
     * 1. _platformSigner Zero address
     * 2. _partnerPfFeeReceiver Zero address
     * 3. Non Admin call
     * 4. Emits PartnerFeeReceiverUpdated event
     */
  }

  /**
   * @dev Returns ExternalPlatformFeeReceiver
   *
   * @param _token address of external platform token
   */
  function getExternalPlatformFeeReceiver(
    address _token
  ) external virtual override returns (address payable) {
    return _externalPfFeeReceiverInfo[_token];
  }

  /**
   * @dev Check validity of arguments when called CreateAuction
   *
   * @param _auction AuctionDomain.Auction auction info
   */
  function checkParametaForAuctionCreate(
    AuctionDomain.Auction calldata _auction
  ) external virtual override {
    //creator address check
    require(
      AuctionDomain._isValidPlatformKind(_auction.pfKind),
      "A:CPFAC:AIPK"
    );

    require(_auction.creatorAddress != address(0), "A:CPFAC:AICA");

    // EM: Auction asset invalid originKind
    require(
      AuctionDomain._isValidOriginKind(_auction.asset.originKind),
      "A:CPFAC:SAIO"
    );
    // EM: Auction asset invalid token
    require(_auction.asset.asset.isContract(), "A:CPFAC:SAIAA");
    // EM: Auction asset invalid tokenId
    require(_auction.asset.assetId != 0, "A:CPFAC:SAIAI");

    //EM: Auction auctionType invalid bidMode
    require(
      AuctionDomain._isValidBidMode(_auction.auctionType.bidMode),
      "A:CPFAC:BTIBM"
    );
    //EM: Auction auctionType invalid auctionKind
    require(
      AuctionDomain._isValidAuctionKind(_auction.auctionType.auctionKind),
      "A:CPFAC:BTIBEM"
    );
    //EM: Auction auctionType invalid Bid_Currency
    require(
      _auction.auctionType.paymentToken == address(0) ||
        _auction.auctionType.paymentToken.isContract(),
      "A:CPFAC:BTITA"
    );

    //EM: Auction startTime invalid
    require(_auction.startTime > block.timestamp, "A:CPFAC:STI");
    //EM: Auction startTime is bigger than endTime
    require(_auction.endTime > _auction.startTime, "A:CPFAC:ETIBTST");

    //EM: Auction pfFeeRate limit is lower than limit
    require(
      _auction.pfFeeRate >= getPlatformFeeRateLowerLimit(),
      "A:CPFAC:APFLTL"
    );

    //EM: Auction PFFeeRate limit is lower than pfFeelowerlimit
    require(
      _auction.externalPfFeeRate >= getPlatformFeeRateLowerLimit() ||
        _auction.externalPfFeeRate == 0,
      "A:CPFAC:AIPPFR"
    );

    //EM: Auction platformSigner not eqaul zero Address
    require(
      _auction.platformSigner != address(0) &&
        isPlatformSigner(_auction.platformSigner),
      "A:CPFAC:AIPS|PSNPA"
    );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";

import "contracts/sbinft/market/v1/library/AuctionDomain.sol";

/**
 * @title SBINFT Platform Registry
 */
interface IPlatformRegistry is IERC165Upgradeable {
  /**
   * @dev Update to new PlatformFeeRateLowerLimit
   *
   * @param _new new PlatformFeeRateLowerLimit
   */
  function updatePlatformFeeLowerLimit(uint16 _new) external;

  /**
   * @dev Update to new PlatformFeeReceiver
   *
   * @param _new new PlatformFeeReceiver
   */
  function updatePlatformFeeReceiver(address payable _new) external;

  /**
   * @dev Update to new PartnerFeeReceiver for partner's collection
   *
   * @param collection partner's collection
   * @param partnerFeeReceiver new partner's FeeReceiver
   * @param sign bytes calldata signature of platform signer
   */
  function updatePartnerFeeReceiver(
    address collection,
    address payable partnerFeeReceiver,
    bytes calldata sign
  ) external;

  /**
   * @dev Checks if partner fee receiver
   *
   * @param _collection address of token
   * @param _partnerFeeReceiver address of partner FeeReceiver
   *
   * Requirements:
   * - _collection must be a non zero address
   * - _partnerFeeReceiver must be a non zero address
   */
  function isPartnerFeeReceiver(
    address _collection,
    address _partnerFeeReceiver
  ) external view returns (bool);

  /**
   * @dev Checks state of a Whitelisted token
   *
   * @param _token address of token
   */
  function isWhitelistedERC20(address _token) external view returns (bool);

  /**
   * @dev Adds list of token to Whitelisted, if zero address then will be ignored
   *
   * @param _addTokenList array of address of token to add
   */
  function addToERC20Whitelist(address[] calldata _addTokenList) external;

  /**
   * @dev Removes list of token from Whitelisted
   *
   * @param _tokenList array of address of token to remove
   */
  function removeFromERC20Whitelist(address[] calldata _tokenList) external;

  /**
   * @dev Checks state of a Whitelisted token
   *
   * @param _signer address of token
   */
  function isPlatformSigner(address _signer) external view returns (bool);

  /**
   * @dev Adds list of token to Whitelisted, if zero address then will be ignored
   *
   * @param _platformSignerList array of platfomr signer address  to add
   */
  function addPlatformSigner(address[] calldata _platformSignerList) external;

  /**
   * @dev Removes list of platform signers address
   *
   * @param _list array of platfomr signer address to remove
   */
  function removePlatformSigner(address[] calldata _list) external;

  /**
   * @dev Returns PlatformFeeReceiver
   */
  function getPlatformFeeReceiver() external returns (address payable);

  /**
   * @dev Returns PartnerFeeReceiver
   *
   * @param _token address of partner token
   */
  function getPartnerFeeReceiver(
    address _token
  ) external returns (address payable);

  /**
   * @dev Returns PlatformFeeReceiver
   *
   */
  function getPlatformFeeRateLowerLimit() external returns (uint16);

  /**
   * @dev Update to new PartnerPfFeeReceiver for partner's platformSigner
   *
   * @param _externalPlatformToken address of external Platform Token
   * @param _partnerPfFeeReceiver address new partner's platformer FeeReceiver
   *
   * Requirements:
   * - _platformSigner must be a non zero address
   * - _partnerPfFeeReceiver must be a non zero address
   *
   * Emits a {ExternalPfFeeReceiverUpdated} event
   */
  function updateExternalPlatformFeeReceiver(
    address _externalPlatformToken,
    address payable _partnerPfFeeReceiver
  ) external;

  /**
   * @dev Returns ExternalPlatformFeeReceiver
   *
   * @param _token address of external platform token
   */
  function getExternalPlatformFeeReceiver(
    address _token
  ) external returns (address payable);

  /**
   * @dev Check validity of arguments when called CreateAuction
   *
   * @param _auction auction info
   *
   */
  function checkParametaForAuctionCreate(
    AuctionDomain.Auction calldata _auction
  ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771ContextUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

abstract contract AdminUpgradeable is ContextUpgradeable {
  event AdminAdded(address);
  event AdminRemoved(address);

  /**
   * @dev 管理者のマッピング。管理者でないならばfalseを返す。
   */
  mapping(address => bool) private _admin;

  function __Admin_init() internal onlyInitializing {
    __Context_init();
    // 初期化時にデプロイ者を管理者に追加する。
    _addAdmin(_msgSender());
  }

  /**
   * @dev 管理者を複数追加
   */
  function addAdmin(address[] calldata newAdmin) public virtual onlyAdmin {
    for (uint256 idx = 0; idx < newAdmin.length; idx++) {
      _addAdmin(newAdmin[idx]);
    }
  }

  /**
   * @dev 管理者を一人追加
   */
  function addAdmin(address newAdmin) public virtual onlyAdmin {
    _addAdmin(newAdmin);
  }

  /**
   * @dev 管理者を一人追加
   * 無制限 Internal function
   */
  function _addAdmin(address newAdmin) internal virtual {
    require(
      newAdmin != address(0),
      "Admin:addAdmin newAdmin is the zero address"
    );

    _admin[newAdmin] = true;
    emit AdminAdded(newAdmin);
  }

  /**
   * @dev 管理者を一人削除
   */
  function removeAdmin(address admin) public virtual onlyAdmin {
    require(
      _admin[admin],
      "Admin:removeAdmin trying to remove non existing Admin"
    );

    _removeAdmin(admin);
  }

  /**
   * @dev 管理者を一人削除
   * 無制限 Internal function
   */
  function _removeAdmin(address admin) internal virtual {
    delete _admin[admin];
    emit AdminRemoved(admin);
  }

  /**
   * @dev
   * Adminかどうかのチェック
   */
  function isAdmin(address checkAdmin) public view virtual returns (bool) {
    return _admin[checkAdmin];
  }

  /**
   * @dev Throws if called by any account other than Admin.
   */
  modifier onlyAdmin() {
    require(_admin[_msgSender()], "Admin:onlyAdmin caller is not an Admin");
    _;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @title Model data related with Auction
 */
library AuctionDomain {
  // Platform KIND
  bytes4 public constant SBINFT_PF_KIND = bytes4(keccak256("SBINFT"));
  bytes4 public constant EXTERNAL_PF_KIND = bytes4(keccak256("EXTERNAL"));

  // ORIGIN_KIND
  bytes4 public constant NANAKUSA_ORIGIN_KIND = bytes4(keccak256("NANAKUSA"));
  bytes4 public constant PARTNER_ORIGIN_KIND = bytes4(keccak256("PARTNER"));

  bytes4 public constant NON_EXPANDABLE_AUCTION_KIND =
    bytes4(keccak256("NON_EXPANDABLE")); // Non Expand
  bytes4 public constant EXPANDABLE_AUCTION_KIND =
    bytes4(keccak256("EXPANDABLE")); // 5 minute Expand Auction

  bytes4 public constant NATIVE_BID_MODE = bytes4(keccak256("NATIVE"));
  bytes4 public constant ERC20_BID_MODE = bytes4(keccak256("ERC20"));
  bytes4 public constant CREDIT_CARD_BID_MODE =
    bytes4(keccak256("CREDIT_CARD"));
  bytes4 public constant OTHER_BLOCKCHAIN_BID_MODE =
    bytes4(keccak256("OTHER_BLOCKCHAIN"));

  struct Asset {
    bytes4 originKind;
    address asset;
    uint256 assetId;
    uint16 partnerFeeRate; // only set when originKind = PARTNER_ORIGIN_KIND
    uint8 isSecondarySale;
  }

  struct AuctionType {
    bytes4 auctionKind; // NON_EXPANDABLE | EXPANDABLE
    bytes4 bidMode; // Bid currency kind (Native,ERC20,Fiat)
    address paymentToken; // Native & Fiat is zeroAddress and for ERC20 is ContractAddress
  }

  struct BidStatus {
    address currentTopBidder;
    address payable refundTo; // If zero address means FeeRciever is the  currentTopBidder
    uint256 currentPrice;
    address[] bidderList;
    uint256[] bidPriceHistory;
  }

  struct Auction {
    uint256 auctionId; //auction Id
    bytes4 pfKind;
    address payable creatorAddress;
    Asset asset;
    AuctionType auctionType;
    uint256 startPrice;
    uint256 startTime;
    uint256 endTime;
    uint16 pfFeeRate;
    uint16 externalPfFeeRate; //if zero means Auction Platform is SBINFTMarket
    address platformSigner;
  }

  struct Bid {
    uint256 auctionId; //auction Id
    address bidder; //For NFT recieve address
    address payable refundTo; // Return destination of funds
    uint256 nonce; //bid log array length bidders hystory
    uint256 price; //Nativeand Credit bid Auction is 0
  }

  struct AuctionResult {
    uint256 auctionId; //auction Id
    address asset;
    uint256 assetId;
    address winner; // Successful bidder
    uint256 finalPrice;
  }

  /**
   * @dev Checks if it's a valid platform kind
   *
   * @param _platformKind bytes4
   */
  function _isValidPlatformKind(
    bytes4 _platformKind
  ) internal pure returns (bool) {
    return (_platformKind == SBINFT_PF_KIND ||
      _platformKind == EXTERNAL_PF_KIND);
  }

  /**
   * @dev Checks if it's a valid origin kind
   *
   * @param _originKind bytes4
   */
  function _isValidOriginKind(bytes4 _originKind) internal pure returns (bool) {
    return (_originKind == NANAKUSA_ORIGIN_KIND ||
      _originKind == PARTNER_ORIGIN_KIND);
  }

  /**
   * @dev Checks if it's a valid auction kind
   *
   * @param _auctionKind bytes4
   */
  function _isValidAuctionKind(
    bytes4 _auctionKind
  ) internal pure returns (bool) {
    return (_auctionKind == NON_EXPANDABLE_AUCTION_KIND ||
      _auctionKind == EXPANDABLE_AUCTION_KIND);
  }

  /**
   * @dev Checks if it's a valid bid mode
   *
   * @param _bidMode bytes4
   */
  function _isValidBidMode(bytes4 _bidMode) internal pure returns (bool) {
    return (_bidMode == NATIVE_BID_MODE ||
      _bidMode == ERC20_BID_MODE ||
      _bidMode == CREDIT_CARD_BID_MODE ||
      _bidMode == OTHER_BLOCKCHAIN_BID_MODE);
  }

  /**
   * @dev Checks if payment mode is onchain
   *
   * @param _bidMode bytes4
   */
  function _isOnchainBidMode(bytes4 _bidMode) internal pure returns (bool) {
    return (_bidMode == NATIVE_BID_MODE || _bidMode == ERC20_BID_MODE);
  }

  /**
   * @dev Checks if origin kind is partner
   *
   * @param _originKind bytes4
   */
  function _isPartnerOrigin(bytes4 _originKind) internal pure returns (bool) {
    return (_originKind == PARTNER_ORIGIN_KIND);
  }

  /**
   * @dev Checks if origin kind is partner
   *
   * @param _pfKind bytes4
   */
  function _isExternalPFOrigin(bytes4 _pfKind) internal pure returns (bool) {
    return (_pfKind == EXTERNAL_PF_KIND);
  }

  /**
   * @dev Checks if it's a Secondary Sale
   *
   * @param _secondarySale uint8
   */
  function _isSecondarySale(uint8 _secondarySale) internal pure returns (bool) {
    return (_secondarySale == 1);
  }

  // ---- EIP712 関連 ----
  bytes32 constant ASSET_TYPEHASH =
    keccak256(
      "Asset(bytes4 originKind,address asset,uint256 assetId,uint16 partnerFeeRate,uint8 isSecondarySale)"
    );

  bytes32 constant AUCTION_TYPE_TYPEHASH =
    keccak256(
      "AuctionType(bytes4 auctionKind,bytes4 bidMode,address paymentToken)"
    );

  bytes32 constant AUCTION_TYPEHASH =
    keccak256(
      "Auction(uint256 auctionId,bytes4 pfKind,address creatorAddress,Asset asset,AuctionType auctionType,uint256 startPrice,uint256 startTime,uint256 endTime,uint16 pfFeeRate,uint16 externalPfFeeRate,address platformSigner)Asset(bytes4 originKind,address asset,uint256 assetId,uint16 partnerFeeRate,uint8 isSecondarySale)AuctionType(bytes4 auctionKind,bytes4 bidMode,address paymentToken)"
    );

  bytes32 constant BID_TYPEHASH =
    keccak256(
      "Bid(uint256 auctionId,address bidder,address refundTo,uint256 nonce,uint256 price)"
    );

  bytes32 constant AUCTION_RESULT_TYPEHASH =
    keccak256(
      "AuctionResult(uint256 auctionId,address asset,uint256 assetId,address winner,uint256 finalPrice)"
    );

  /**
   * @dev Create hash message of asset
   *
   * @param _asset Asset calldata
   */
  function _hashAsset(Asset calldata _asset) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          ASSET_TYPEHASH,
          _asset.originKind,
          _asset.asset,
          _asset.assetId,
          _asset.partnerFeeRate,
          _asset.isSecondarySale
        )
      );
  }

  /**
   * @dev Create hash message of auctionType
   *
   * @param _bidtype AuctionType calldata
   */
  function _hashAuctionType(
    AuctionType calldata _bidtype
  ) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          AUCTION_TYPE_TYPEHASH,
          _bidtype.auctionKind,
          _bidtype.bidMode,
          _bidtype.paymentToken
        )
      );
  }

  /**
   * @dev Create hash message of auction
   *
   * @param _auction Auction calldata
   */
  function _hashAuction(
    Auction calldata _auction
  ) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          AUCTION_TYPEHASH,
          _auction.auctionId,
          _auction.pfKind,
          _auction.creatorAddress,
          _hashAsset(_auction.asset),
          _hashAuctionType(_auction.auctionType),
          _auction.startPrice,
          _auction.startTime,
          _auction.endTime,
          _auction.pfFeeRate,
          _auction.externalPfFeeRate,
          _auction.platformSigner
        )
      );
  }

  /**
   * @dev Create hash message of bid
   *
   * @param _bid Bid calldata
   */
  function _hashBid(Bid calldata _bid) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          BID_TYPEHASH,
          _bid.auctionId,
          _bid.bidder,
          _bid.refundTo,
          _bid.nonce,
          _bid.price
        )
      );
  }

  /**
   * @dev Create hash message of auction result
   *
   * @param _result AuctionResult calldata
   */
  function _hashAuctionResult(
    AuctionResult calldata _result
  ) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          AUCTION_RESULT_TYPEHASH,
          _result.auctionId,
          _result.asset,
          _result.assetId,
          _result.winner,
          _result.finalPrice
        )
      );
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
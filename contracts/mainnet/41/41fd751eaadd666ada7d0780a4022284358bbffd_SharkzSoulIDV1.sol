// SPDX-License-Identifier: MIT

/**
       █                                                                        
▐█████▄█ ▀████ █████  ▐████    ████████    ███████████  ████▌  ▄████ ███████████
▐██████ █▄ ▀██ █████  ▐████   ██████████   ████   ████▌ ████▌ ████▀       ████▀ 
  ▀████ ███▄ ▀ █████▄▄▐████  ████ ▐██████  ████▄▄▄████  █████████        ████▀  
▐▄  ▀██ █████▄ █████▀▀▐████ ▄████   ██████ █████████    █████████      ▄████    
▐██▄  █ ██████ █████  ▐█████████▀    ▐█████████ ▀████▄  █████ ▀███▄   █████     
▐████  █▀█████ █████  ▐████████▀        ███████   █████ █████   ████ ███████████
       █
 *******************************************************************************
 * Sharkz Soul ID
 *******************************************************************************
 * Creator: Sharkz Entertainment
 * Author: Jason Hoi
 *
 */

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../lib/sharkz/ISoulData.sol";
import "../lib/sharkz/IScore.sol";
import "../lib-upgradeable/sharkz/AdminableUpgradeable.sol";
import "../lib-upgradeable/712/EIP712WhitelistUpgradeable.sol";
import "../lib-upgradeable/4973/ERC4973SoulContainerUpgradeable.sol";

contract SharkzSoulIDV1 is IScore, Initializable, UUPSUpgradeable, AdminableUpgradeable, EIP712WhitelistUpgradeable, ERC4973SoulContainerUpgradeable, ReentrancyGuardUpgradeable {
    // Implementation version number
    function version() external pure virtual returns (uint256) { return 1; }
    
    // Emits when new Badge contract is registered
    event BadgeContractLinked(address indexed addr);

    // Emits when existing Badge contract removed
    event BadgeContractUnlinked(address indexed addr);

    // Keep track of total minted token count
    uint256 internal _tokenMinted;

    // Keep track of total destroyed token
    uint256 internal _tokenBurned;

    // Public mint mode, 0: disable-minting, 1: free-mint, 2: restrict minting to target token owner
    uint256 internal _mintMode;

    // Max mint supply
    uint256 internal _mintSupply;

    // Restricted public mint with target token contract
    address internal _tokenContract;

    // Minting by claim contract
    address internal _claimContract;

    // Token metadata, name prefix
    string internal _metaName;

    // Token metadata, description
    string internal _metaDesc;

    // Compiler will pack the struct into multiple uint256 space
    struct BadgeSetting {
        address contractAddress;
        // limited to 2**80-1 score value 
        uint80 baseScore;
        // limited to 2**16 = 255x multiplier
        uint16 scoreMultiplier;
    }

    // Badge contract settings
    BadgeSetting[] public badgeSettings;

    // Link to Soul Data contract
    ISoulData public soulData;

    // Base score
    uint256 internal _baseScore;

    // Name on token image svg
    mapping (uint256 => string) public tokenCustomNames;

    // Init this upgradeable contract
    function initialize() public initializer onlyProxy {
        __Adminable_init();
        __EIP712Whitelist_init();
        __ERC4973SoulContainer_init("SOULID", "SOULID");
        __ReentrancyGuard_init();
        _metaName = "Soul ID #";
        _metaDesc = "Soul ID is a 100% on-chain generated token based on ERC4973-Soul Container designed by Sharkz Entertainment. Owning the Soul ID is your way to join our decentralized governance, participate and gather rewards in our NFT community ecosystem.";
        // default mint supply 100k
        _mintSupply = 100000;
        // default score is 1
        _baseScore = 1;
    }

    // only admins can upgrade the contract
    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // See: https://eips.ethereum.org/EIPS/eip-165
        // return true to show proof of supporting following interface, we use bytes4 
        // interface id to avoid importing the whole interface codes.
        return super.supportsInterface(interfaceId) || 
               interfaceId == type(IScore).interfaceId;
    }

    // Returns whether badge contract is linked
    function isBadgeContractLinked(address addr) public view virtual returns (bool) {
        for (uint256 i = 0; i < badgeSettings.length; i++) {
          if (addr == badgeSettings[i].contractAddress)
          {
            return true;
          }
        }
        return false;
    }

    // Returns badge setting index by badge contract address
    function _badgeSettingIndex(address addr) internal view virtual returns (uint256) {
        for (uint256 i = 0; i < badgeSettings.length; i++) {
            if (addr == badgeSettings[i].contractAddress && addr != address(0)) {
                return i;
            }
        }
        revert("Badge contract index not found");
    }

    // Register a badge contract
    function _linkBadgeContract(address _contract, uint256 _scoreMultiplier) internal virtual {
        BadgeSetting memory object;
        object.contractAddress = _contract;
        object.scoreMultiplier = uint16(_scoreMultiplier);

        if (soulData.isImplementing(_contract, type(IScore).interfaceId)) {
            // copy the base score to avoid future access to external contract
            object.baseScore = uint80(soulData.getBadgeBaseScore(_contract));
        } else {
            object.baseScore = 0;
        }

        badgeSettings.push(object);
        emit BadgeContractLinked(_contract);
    }

    // Remove registration of a badge contract
    function _unlinkBadgeContract(address _contract) internal virtual {
        uint256 total = badgeSettings.length;

        // replace current array element with last element, and pop() remove last element
        if (_contract != badgeSettings[total - 1].contractAddress) {
            uint256 index = _badgeSettingIndex(_contract);
            badgeSettings[index] = badgeSettings[total - 1];
            badgeSettings.pop();
        } else {
            badgeSettings.pop();
        }

        emit BadgeContractUnlinked(_contract);
    }

    // Returns the token voting score
    function _tokenVotingScore(uint256 _tokenId) internal virtual view returns (uint256) {
        // initial score for current token
        uint256 totalScore = baseScore();

        // loop through each badge contract to accumulate all score (with multiplier)
        BadgeSetting memory badge;
        for (uint256 i = 0; i < badgeSettings.length; i++) {
            badge = badgeSettings[i];

            if (soulData.isImplementing(badge.contractAddress, 0x80ac58cd)) {
                // for ERC721
                totalScore += badge.scoreMultiplier * badge.baseScore * soulData.getERC721Balance(badge.contractAddress, _ownerOf(_tokenId));
            } else {
                // for Soul Badge
                totalScore += badge.scoreMultiplier * badge.baseScore * soulData.getSoulBadgeBalanceForSoul(address(this), _tokenId, badge.contractAddress);
            }
        }

        return totalScore;
    }

    // Returns total linked badge contract counter
    function totalBadges() public view virtual returns (uint256) {
        return badgeSettings.length;
    }

    /**
     * @dev See {IScore-baseScore}.
     */
    function baseScore() public view virtual override returns (uint256) {
        return _baseScore;
    }

    /**
     * @dev See {IScore-scoreByToken}.
     */
    function scoreByToken(uint256 _tokenId) external view virtual override returns (uint256) {
        if (_exists(_tokenId)) {
          return _tokenVotingScore(_tokenId);
        } else {
          return 0;
        }
    }

    /**
     * @dev See {IScore-scoreByAddress}.
     */
    function scoreByAddress(address _addr) external view virtual override returns (uint256) {
        if (_addressData[_addr].balance > 0) {
            return _tokenVotingScore(tokenIdOf(_addr));
        } else {
            return 0;
        }
    }

    //////// Admin-only functions ////////

    // Link/unlink Badge contract
    // Noted that score multiplier is limited to the max value from BadgeSetting struct
    function setBadgeContract(address _contract, uint256 _scoreMultiplier, bool approved) 
        external 
        virtual 
        onlyAdmin 
    {
        bool exists = isBadgeContractLinked(_contract);
        
        // approve = true, adding
        // approve = false, removing
        if (approved) {
            require(!exists, "Adding existing badge contract");

            // target contract should at least implement ERC721Metadata to provide token name()
            require(soulData.isImplementing(_contract, 0x5b5e139f), "Target contract need to support ERC721Metadata");
            _linkBadgeContract(_contract, _scoreMultiplier);
        } else {
            require(exists, "Removing non-existent badge contract");
            _unlinkBadgeContract(_contract);
        }
    }

    // Setup contract data storage
    function setSoulDataContract(address _contract) 
        external 
        virtual 
        onlyAdmin 
    {
        soulData = ISoulData(_contract);
    }

    // Update token meta data desc
    function setTokenDescription(string calldata _desc) external virtual onlyAdmin {
        _metaDesc = _desc;
    }

    // Change minting mode
    function setMintMode(uint256 _mode) external virtual onlyAdmin {
        _mintMode = _mode;
    }

    // Change mint supply
    function setMintSupply(uint256 _max) external virtual onlyAdmin {
        _mintSupply = _max;
    }

    // Update linking ERC721 contract address
    function setMintRestrictContract(address _addr) external virtual onlyAdmin {
        _tokenContract = _addr;
    }

    // Update linking claim contract
    function setClaimContract(address _addr) external virtual onlyAdmin {
        _claimContract = _addr;
    }
    
    // Change base score
    function setBaseScore(uint256 _score) external virtual onlyAdmin {
        _baseScore = _score;
    }

    // Minting by admin to any address
    function ownerMint(address _to) 
        external 
        virtual 
        onlyAdmin 
    {
        _runMint(_to);
    }

    //////// End of Admin-only functions ////////

    // Returns total valid token count
    function totalSupply() public virtual view returns (uint256) {
        return _tokenMinted - _tokenBurned;
    }

    // Caller must not be an wallet account
    modifier callerIsUser() {
        require(tx.origin == _msgSenderERC4973(), "Caller should not be a contract");
        _;
    }

    // Create a new token for an address
    function _runMint(address _to) 
        internal 
        virtual 
        nonReentrant 
        onlyProxy
    {
        require(_mintMode > 0, 'Minting disabled');
        require(_tokenMinted <= _mintSupply, 'Max minting supply reached');

        // token id starts from index 0
        _mint(_to, _tokenMinted);
        unchecked {
          _tokenMinted += 1;
        }
    }

    // Minting from claim contract
    function claimMint(address _to) 
        external 
        virtual 
    {
        require(_claimContract != address(0), "Linked claim contract is not set");
        require(_claimContract == _msgSenderERC4973(), "Caller is not claim contract");
        _runMint(_to);
    }

    // Public minting
    function publicMint() 
        external 
        virtual 
        callerIsUser 
    {
        if (_mintMode == 2) {
            require(_tokenContract != address(0), "Invalid token contract address with zero address");
            require(soulData.getERC721Balance(_tokenContract, _msgSenderERC4973()) > 0, "Caller is not a target token owner");
        }
        _runMint(_msgSenderERC4973());
    }

    // Minting with signature from contract EIP712 signer
    function whitelistMint(bytes calldata _signature) 
        external 
        virtual 
        callerIsUser 
        checkWhitelist(_signature) 
    {
        _runMint(_msgSenderERC4973());
    }

    function burn(uint256 _tokenId) public virtual override {
      super.burn(_tokenId);
      unchecked {
          _tokenBurned += 1;
      }
    }

    // Set custom name on token image svg
    function setTokenCustomName(uint256 _tokenId, string calldata _name) external virtual {
        require(ownerOf(_tokenId) == _msgSenderERC4973(), "Caller is not token owner");
        require(bytes(_name).length < 23, "Custom name with invalid length");
        require(soulData.isValidCustomNameFormat(_name), "Custom name with invalid format");
        tokenCustomNames[_tokenId] = _name;
    }

    // Returns token creation timestamp
    function _tokenCreationTime(uint256 _tokenId) internal view virtual returns (uint256) {
        return uint256(_addressData[_ownerOf(_tokenId)].createTimestamp);
    }

    // Returns token info by address
    function tokenAddressInfo(address _owner) external virtual view returns (AddressData memory) {
        return _addressData[_owner];
    }

    /**
     * @dev Token SVG image and metadata is 100% on-chain generated (connected with Soul Data utility contract).
     */
    function tokenURI(uint256 _tokenId) external virtual view override returns (string memory) {
        require(_exists(_tokenId), "Token URI query for nonexistent token");

        // Soul Data contract provided two render modes for tokenURI()
        // 0 : data:application/json;utf8,
        // 1 : data:application/json;base64,
        return soulData.tokenURI(_tokenId, _metaName, _metaDesc, tokenBadgeTraits(_tokenId), _tokenVotingScore(_tokenId), _tokenCreationTime(_tokenId), tokenCustomNames[_tokenId]);
    }

    /**
     * @dev Render `Badge` traits
     * @dev Make sure the registered badge contract `balanceOf()` or 
     * `balanceOfSoul()` gas fee is not high, otherwise `tokenURI()` may hit 
     * (read operation) gas limit and become unavailable to public.
     * 
     * Please unlink any high gas badge contract to avoid issues.
     */
    function tokenBadgeTraits(uint256 _tokenId) public virtual view returns (string memory) {
        string memory output = "";
        for (uint256 badgeIndex = 0; badgeIndex < badgeSettings.length; badgeIndex++) {
            output = string(abi.encodePacked(
                            output, 
                            soulData.getBadgeTrait(
                              badgeSettings[badgeIndex].contractAddress, 
                              badgeIndex, 
                              address(this), 
                              _tokenId, 
                              ownerOf(_tokenId))
                            ));
        }
        return output;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

/**
 *******************************************************************************
 * ISoulIDData interface
 *******************************************************************************
 * Creator: Sharkz Entertainment
 * Author: Jason Hoi
 *
 */

pragma solidity ^0.8.7;

/**
 * @dev Interface of Sharkz Soul ID Data storage and utilities
 */
interface ISoulData {
    /**
     * @dev Render tokenURI dynamic metadata string
     */
    function tokenURI(uint256 tokenId, string calldata metaName, string calldata metaDesc, string calldata badgeTraits, uint256 score, uint256 creationTime, string calldata customName) external view returns (string memory);

    /**
     * @dev Render token meta name, desc, and image
     */
    function tokenMetaAndImage(uint256 tokenId, string calldata metaName, string calldata metaDesc, uint256 creationTime, string calldata name) external view returns (string memory);

    /**
     * @dev Render token meta attributes
     */
    function tokenAttributes(string calldata badgeTraits, uint256 score, uint256 creationTime) external pure returns (string memory);

    /**
     * @dev Save/Update/Clear a page of data with a key, max size is 24576 bytes (24KB)
     */
    function saveData(string memory key, uint256 pageNumber, bytes memory data) external;

    /**
     * @dev Get all data from all data pages for a key
     */
    function getData(string memory key) external view returns (bytes memory);

    /**
     * @dev Get one page of data chunk
     */
    function getPageData(string memory key, uint256 pageNumber) external view returns (bytes memory);

    /**
     * @dev Returns external Token collection name
     */
    function getTokenCollectionName(address _contract) external view returns (string memory);

    /**
     * @dev Returns Soul Badge balance for a Soul
     */
    function getSoulBadgeBalanceForSoul(address soulContract, uint256 soulTokenId, address badgeContract) external view returns (uint256);

    /**
     * @dev Returns Badge base score (unit score per one qty
     */
    function getBadgeBaseScore(address badgeContract) external view returns (uint256);

    /**
     * @dev Returns the token metadata trait string for a badge contract (support ERC721 and ERC5114 Soul Badge)
     */
    function getBadgeTrait(address badgeContract, uint256 traitIndex, address soulContract, uint256 soulTokenId, address soulTokenOwner) external view returns (string memory);

    /**
     * @dev Returns whether an address is a ERC721 token owner
     */
    function getERC721Balance(address _contract, address ownerAddress) external view returns (uint256);

    /**
     * @dev Returns whether custom name contains valid characters
     *      We only accept [a-z], [A-Z], [space] and certain punctuations
     */
    function isValidCustomNameFormat(string calldata name) external pure returns (bool);

    /**
     * @dev Returns whether target contract reported it implementing an interface (based on IERC165)
     */
    function isImplementing(address _contract, bytes4 interfaceCode) external view returns (bool);
    
    /** 
     * @dev Converts a `uint256` to Unicode Braille patterns (0-255)
     * Braille patterns https://www.htmlsymbols.xyz/braille-patterns
     */
    function toBrailleCodeUnicode(uint256 value) external pure returns (string memory);

    /** 
     * @dev Converts a `uint256` to HTML code of Braille patterns (0-255)
     * Braille patterns https://www.htmlsymbols.xyz/braille-patterns
     */
    function toBrailleCodeHtml(uint256 value) external pure returns (string memory);

    /** 
     * @dev Converts a `uint256` to ASCII base26 alphabet sequence code
     * For example, 0:A, 1:B 2:C ... 25:Z, 26:AA, 27:AB...
     */
    function toAlphabetCode(uint256 value) external pure returns (string memory);

    /**
     * @dev Converts `uint256` to ASCII `string`
     */
    function toString(uint256 value) external pure returns (string memory ptr);
}

// SPDX-License-Identifier: MIT

/**
 *******************************************************************************
 * IScore interface
 *******************************************************************************
 * Creator: Sharkz Entertainment
 * Author: Jason Hoi
 *
 */

pragma solidity ^0.8.7;

/**
 * @dev Interface of token score, external token contract may accumulate total 
 * score from multiple IScore tokens.
 */
interface IScore {
    /**
     * @dev Get base score for each token (this is the unit score for different
     *  `tokenId` or owner address)
     */
    function baseScore() external view returns (uint256);

    /**
     * @dev Get score for individual `tokenId`
     * This function is needed only when score varies between token ids.
     * In order to accumulate score, try to avoid any revert() if user submitted 
     * non-existent token id or owner address.
     *
     */
    function scoreByToken(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Get score of an address
     * In order to accumulate score, try to avoid any revert() if user submitted 
     * non-existent token id or owner address.
     *
     */
    function scoreByAddress(address addr) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

/**
 *******************************************************************************
 * Adminable access control
 *******************************************************************************
 * Author: Jason Hoi
 *
 */
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides basic multi-admin access control mechanism,
 * admins are granted exclusive access to specific functions with the provided 
 * modifier.
 *
 * By default, the contract owner is the first admin.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyAdmin`, which can be applied to your functions to restrict access.
 * 
 */
contract AdminableUpgradeable is Initializable {
    event AdminCreated(address indexed addr);
    event AdminRemoved(address indexed addr);

    // mapping for admin address
    mapping(address => uint256) _admins;

    // Initializes the contract setting the deployer as the initial admin.
    function __Adminable_init() internal onlyInitializing {
        __Adminable_init_unchained();
    }

    function __Adminable_init_unchained() internal onlyInitializing {
        _admins[_msgSenderAdminable()] = 1;
    }

    modifier onlyAdmin() {
        require(isAdmin(_msgSenderAdminable()), "Adminable: caller is not admin");
        _;
    }

    function isAdmin(address addr) public view virtual returns (bool) {
        return _admins[addr] == 1;
    }

    function setAdmin(address to, bool approved) public virtual onlyAdmin {
        require(to != address(0), "Adminable: cannot set admin for the zero address");

        if (approved) {
            require(!isAdmin(to), "Adminable: add existing admin");
            _admins[to] = 1;
            emit AdminCreated(to);
        } else {
            require(isAdmin(to), "Adminable: remove non-existent admin");
            delete _admins[to];
            emit AdminRemoved(to);
        }
    }

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * For GSN compatible contracts, you need to override this function.
     */
    function _msgSenderAdminable() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

/**                                                                 
 *******************************************************************************
 * EIP 721 whitelist with qty parameter
 *******************************************************************************
 * Author: Jason Hoi
 *
 */

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "../sharkz/AdminableUpgradeable.sol";

contract EIP712WhitelistUpgradeable is Initializable, AdminableUpgradeable {
    event SetSigner(address indexed sender, address indexed signer);
    
    using ECDSAUpgradeable for bytes32;

    // Verify signature with this signer address
    address public eip712Signer;

    // Domain separator is EIP-712 defined struct to make sure 
    // signature is coming from the this contract in same ETH newtork.
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#definition-of-domainseparator
    // @MATCHING cliend-side code
    bytes32 public DOMAIN_SEPARATOR;

    // HASH_STRUCT should not contain unnecessary whitespace between each parameters
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#definition-of-encodetype
    // @MATCHING cliend-side code
    bytes32 public constant HASH_STRUCT = keccak256("Minter(address wallet)");

    function __EIP712Whitelist_init() internal onlyInitializing {
        __EIP712Whitelist_init_unchained();
    }

    function __EIP712Whitelist_init_unchained() internal onlyInitializing {
        // @MATCHING cliend-side code
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                // @MATCHING cliend-side code
                keccak256(bytes("WhitelistToken")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

        // initial signer is contract creator
        setSigner(_msgSenderEIP712());
    }

    function setSigner(address _addr) public onlyAdmin {
        eip712Signer = _addr;

        emit SetSigner(_msgSenderEIP712(), _addr);
    }

    modifier checkWhitelist(bytes calldata _signature) {
        require(eip712Signer == _recoverSigner(_signature), "EIP712: Invalid Signature");
        _;
    }

    // Verify signature (relating to _msgSenderEIP712()) comes by correct signer
    function verifySignature(bytes calldata _signature) public view returns (bool) {
        return eip712Signer == _recoverSigner(_signature);
    }

    // Recover the signer address
    function _recoverSigner(bytes calldata _signature) internal view returns (address) {
        require(eip712Signer != address(0), "EIP712: Whitelist not enabled");

        // Verify EIP-712 signature by recreating the data structure
        // that we signed on the client side, and then using that to recover
        // the address that signed the signature for this data.
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(HASH_STRUCT, _msgSenderEIP712()))
            )
        );
        return digest.recover(_signature);
    }

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * For GSN compatible contracts, you need to override this function.
     */
    function _msgSenderEIP712() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT

/**
 *******************************************************************************
 * ERC4973 Soul Container
 *******************************************************************************
 * Creator: Sharkz Entertainment
 * Author: Jason Hoi
 *
 */

pragma solidity ^0.8.7;

import "../../lib/4973/IERC4973SoulContainer.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

/**
 * @dev See https://eips.ethereum.org/EIPS/eip-4973
 * @dev Implementation of IERC4973 and the additional IERC4973 Soul Container interface
 * 
 * Please noted that EIP-4973 is a draft proposal by the time of contract design, EIP 
 * final definition can be changed.
 * 
 * This implementation included many features for real-life usage, by including ERC721
 * Metadata extension, we allow NFT platforms to recognize the token name, symbol and token
 * metadata, ex. token image, attributes. By design, ERC721 transfer, operator, and approval 
 * mechanisms are all removed.
 *
 * Access controls applied user roles: token owner, token guardians, admins, public users.
 * 
 * Assumes that the max value for token ID, and guardians numbers are 2**256 (uint256).
 *
 */
contract ERC4973SoulContainerUpgradeable is IERC721Metadata, IERC4973SoulContainer, Initializable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     * It is required for NFT platforms to detect token creation.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Token ID and address is 1:1 binding, however, existing token can be renewed or burnt, 
     * releasing old address to be bind to new token ID.
     *
     * Compiler will pack this into a single 256bit word.
     */
    struct AddressData {
        // address token ID
        uint256 tokenId;
        // We use smallest uint8 to record 0 or 1 value
        uint8 balance;
        // Token creation time for the only token for the address
        uint40 createTimestamp;
        // Keep track of historical minted token amount
        uint64 numberMinted;
        // Keep track of historical burnt token amount
        uint64 numberBurned;
        // Keep track of renewal counter for address
        uint80 numberRenewal;
    }

    // Mapping address to address token data
    mapping(address => AddressData) internal _addressData;

    // Renewal request struct
    struct RenewalRequest {
        // Requester address can be token owner or guardians
        address requester;
        // Request created time
        uint40 createTimestamp;
        // Request expiry time
        uint40 expireTimestamp;
        // uint16 leaveover in uint256 struct
    }

    // Mapping token ID to renewal request, only store last request to allow easy override
    mapping(uint256 => RenewalRequest) private _renewalRequest;

    // Mapping request hash key to approver addresses
    mapping(uint256 => mapping(address => bool)) private _renewalApprovers;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping token ID to multiple guardians.
    mapping(uint256 => address[]) private _guardians;

    function __ERC4973SoulContainer_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC4973SoulContainer_init_unchained(name_, symbol_);
    }

    function __ERC4973SoulContainer_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // See: https://eips.ethereum.org/EIPS/eip-165
        // return true to show proof of supporting following interface, we use bytes4 
        // interface id to avoid importing the whole interface codes.
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata.
            interfaceId == type(IERC4973).interfaceId ||
            interfaceId == type(IERC4973SoulContainer).interfaceId;
    }

    /**
     * @dev See {IERC4973-tokenIdOf}.
     */
    function tokenIdOf(address owner) public view virtual override returns (uint256) {
        require(balanceOf(owner) > 0, "ERC4973SoulContainer: token id query for non-existent owner");
        return uint256(_addressData[owner].tokenId);
    }

    /**
     * @dev See {IERC4973-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC4973SoulContainer: balance query for the zero address");
        return uint256(_addressData[owner].balance);
    }

    // Returns owner address of a token ID
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev See {IERC4973-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC4973SoulContainer: owner query for non-existent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation with `baseURI` and the `tokenId`.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for non-existent token");
        return bytes(_baseURI()).length != 0 ? string(abi.encodePacked(_baseURI(), _toString(tokenId))) : "";
    }

    // Returns whether `tokenId` exists.
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    // Returns whether the address is either the owner or guardian
    function _isOwnerOrGuardian(address addr, uint256 tokenId) internal view virtual returns (bool) {
        return (addr != address(0) && (addr == _ownerOf(tokenId) || _isGuardian(addr, tokenId)));
    }

    // Returns guardian index by address for the token
    function _getGuardianIndex(address addr, uint256 tokenId) internal view virtual returns (uint256) {
        for (uint256 i = 0; i < _guardians[tokenId].length; i++) {
            if (addr == _guardians[tokenId][i]) {
                return i;
            }
        }
        revert("ERC4973SoulContainer: guardian index error");
    }

    // Returns guardian address by index
    function getGuardianByIndex(uint256 index, uint256 tokenId) external view virtual returns (address) {
        require(_isOwnerOrGuardian(_msgSenderERC4973(), tokenId), "ERC4973SoulContainer: query from non-owner or guardian");
        return _guardians[tokenId][index];
    }

    // Returns guardian count
    function getGuardianCount(uint256 tokenId) external view virtual returns (uint256) {
        require(_isOwnerOrGuardian(_msgSenderERC4973(), tokenId), "ERC4973SoulContainer: query from non-owner or guardian");
        return _guardians[tokenId].length;
    }

    // Returns whether an address is token guardian
    function _isGuardian(address addr, uint256 tokenId) internal view virtual returns (bool) {
        // we assumpt that each token ID should not contains too many guardians
        for (uint256 i = 0; i < _guardians[tokenId].length; i++) {
            if (addr == _guardians[tokenId][i]) {
                return true;
            }
        }
        return false;
    }

    // Remove existing guardian
    function _removeGuardian(address addr, uint256 tokenId) internal virtual {
        uint256 total = _guardians[tokenId].length;
        if (_guardians[tokenId][total-1] != addr) {
            uint256 index = _getGuardianIndex(addr, tokenId);
            // replace current value from last array element
            _guardians[tokenId][index] = _guardians[tokenId][total-1];
            // remove last element and shorten the array length
            _guardians[tokenId].pop();
        } else {
            // remove last element and shorten the array length
            _guardians[tokenId].pop();
        }
    }

    /**
     * @dev See {IERC4973SoulId-isGuardian}.
     */
    function isGuardian(address addr, uint256 tokenId) external view virtual override returns (bool) {
        require(addr != address(0), "ERC4973SoulContainer: guardian is zero address");
        return _isGuardian(addr, tokenId);
    }

    /**
     * @dev See {IERC4973SoulId-setGuardian}.
     */
    function setGuardian(address to, bool approved, uint256 tokenId) external virtual override {
        // access controls
        require(ownerOf(tokenId) == _msgSenderERC4973(), "ERC4973SoulContainer: guardian setup query from non-owner");
        
        // requirements
        require(to != address(0), "ERC4973SoulContainer: guardian setup query for the zero address");
        require(_exists(tokenId), "ERC4973SoulContainer: guardian setup query for non-existent token");
        if (approved) {
            // adding guardian
            require(!_isGuardian(to, tokenId) && to != _ownerOf(tokenId), "ERC4973SoulContainer: guardian already existed");
            _guardians[tokenId].push(to);

        } else {
            // remove guardian
            require(_isGuardian(to, tokenId), "ERC4973SoulContainer: removing non-existent guardian");
            _removeGuardian(to, tokenId);
        }

        emit SetGuardian(to, tokenId, approved);
    }

    // Returns approver unique hashed key for last token renewal request
    function _approverIndexKey(uint256 tokenId) internal view virtual returns (uint256) {
        uint256 createTime = _renewalRequest[tokenId].createTimestamp;
        return uint256(keccak256(abi.encodePacked(createTime, ":", tokenId)));
    }

    // Returns approval count for the renewal request (approvers can be token owner or guardians)
    function getApprovalCount(uint256 tokenId) public view virtual returns (uint256) {
        uint256 indexKey = _approverIndexKey(tokenId);
        uint256 count = 0;

        // count if token owner approved
        if (_renewalApprovers[indexKey][ownerOf(tokenId)]) {
            count += 1;
        }

        for (uint256 i = 0; i < _guardians[tokenId].length; i++) {
            address guardian = _guardians[tokenId][i];
            if (_renewalApprovers[indexKey][guardian]) {
                count += 1;
            }
        }

        return count;
    }

    // Returns request approval quorum size (min number of approval needed)
    function getApprovalQuorum(uint256 tokenId) public view virtual returns (uint256) {
        uint256 guardianCount = _guardians[tokenId].length;
        // mininum approvers are 2 (can be 1 token owner plus at least 1 guardian)
        require(guardianCount > 0, "ERC4973SoulContainer: approval quorum require at least one guardian");

        uint256 total = 1 + guardianCount;
        uint256 quorum = (total) / 2 + 1;
        return quorum;
    }

    /**
     * Returns whether renew request approved
     *
     * Valid approvers = N = 1 + guardians (1 from token owner)
     * Mininum one guardian is need to build the quorum system.
     *
     * Approval quorum = N / 2 + 1
     * For example: 3 approvers = 2 quorum needed
     *              4 approvers = 3 quorum needed
     *              5 approvers = 3 quorum needed
     *
     * Requirements:
     * - renewal request is not expired
     */
    function isRequestApproved(uint256 tokenId) public view virtual returns (bool) {
        if (getApprovalCount(tokenId) >= getApprovalQuorum(tokenId)) {
          return true;
        } else {
          return false;
        }
    }

    // Returns whether renew request is expired
    function isRequestExpired(uint256 tokenId) public view virtual returns (bool) {
        uint256 expiry = uint256(_renewalRequest[tokenId].expireTimestamp);
        if (expiry > 0 && expiry <= block.timestamp) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev See {IERC4973SoulId-requestRenew}.
     */
    function requestRenew(uint256 expireTimestamp, uint256 tokenId) external virtual override {
        // access controls
        require(_isOwnerOrGuardian(_msgSenderERC4973(), tokenId), "ERC4973SoulContainer: query from non-owner or guardian");

        // requirements
        // minimum 2 approvers: approver #1 is owner, approver #2, #3... are guardians
        require(_guardians[tokenId].length > 0, "ERC4973SoulContainer: approval quorum require at least one guardian");

        _renewalRequest[tokenId].requester = _msgSenderERC4973();
        _renewalRequest[tokenId].expireTimestamp = uint40(expireTimestamp);
        _renewalRequest[tokenId].createTimestamp = uint40(block.timestamp);

        // requester should auto approve the request
        _renewalApprovers[_approverIndexKey(tokenId)][_msgSenderERC4973()] = true;

        emit RequestRenew(_msgSenderERC4973(), tokenId, expireTimestamp);
    }

    /**
     * @dev See {IERC4973SoulId-approveRenew}.
     */
    function approveRenew(bool approved, uint256 tokenId) external virtual override {
        // access controls
        require(_isOwnerOrGuardian(_msgSenderERC4973(), tokenId), "ERC4973SoulContainer: query from non-owner or guardian");

        // requirements
        require(!isRequestExpired(tokenId), "ERC4973SoulContainer: request expired");
        // minimum 2 approvers: approver #1 is owner, approver #2, #3... are guardians
        require(_guardians[tokenId].length > 0, "ERC4973SoulContainer: approval quorum require at least one guardian");

        uint256 indexKey = _approverIndexKey(tokenId);
        _renewalApprovers[indexKey][_msgSenderERC4973()] = approved;
        
        emit ApproveRenew(tokenId, approved);
    }

    /**
     * @dev See {IERC4973SoulId-renew}.
     * Emits {Renew} event.
     * Emits {Transfer} event. (to support NFT platforms)
     */
    function renew(address to, uint256 tokenId) external virtual override {
        // access controls
        require(_isOwnerOrGuardian(_msgSenderERC4973(), tokenId), "ERC4973SoulContainer: renew with unauthorized access");
        require(_renewalRequest[tokenId].requester == _msgSenderERC4973(), "ERC4973SoulContainer: renew with invalid requester");

        // requirements
        require(!isRequestExpired(tokenId), "ERC4973SoulContainer: renew with expired request");
        require(isRequestApproved(tokenId), "ERC4973SoulContainer: renew with unapproved request");
        require(balanceOf(to) == 0, "ERC4973SoulContainer: renew to existing token address");
        require(to != address(0), "ERC4973SoulContainer: renew to zero address");

        address oldAddr = _ownerOf(tokenId);

        unchecked {
            _burn(tokenId);

            // update new address data
            _addressData[to].tokenId = tokenId;
            _addressData[to].balance = 1;
            _addressData[to].numberRenewal += 1;
            _addressData[to].createTimestamp = uint40(block.timestamp);
            _owners[tokenId] = to;

            // to avoid duplicated guardian address and the new token owner
            // remove guardian for the requester address
            if (_isGuardian(to, tokenId)){
                _removeGuardian(to, tokenId);
            }
        }

        emit Renew(to, tokenId);
        emit Transfer(oldAddr, to, tokenId);
    }

    /**
     * @dev Mints `tokenId` to `to` address.
     *
     * Requirements:
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     * - 1:1 mapping of token and address
     *
     * Emits {Attest} event.
     * Emits {Transfer} event. (to support NFT platforms)
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC4973SoulContainer: mint to the zero address");
        require(!_exists(tokenId), "ERC4973SoulContainer: token already minted");
        require(balanceOf(to) == 0, "ERC4973SoulContainer: one token per address");

        // Overflows are incredibly unrealistic.
        // max balance should be only 1
        unchecked {
            _addressData[to].tokenId = tokenId;
            _addressData[to].balance = 1;
            _addressData[to].numberMinted += 1;
            _addressData[to].createTimestamp = uint40(block.timestamp);
            _owners[tokenId] = to;
        }

        emit Attest(to, tokenId);
        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     *
     * Requirements:
     * - `tokenId` must exist.
     * 
     * Access:
     * - `tokenId` owner
     *
     * Emits {Revoke} event.
     * Emits {Transfer} event. (to support NFT platforms)
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = _ownerOf(tokenId);
        
        delete _addressData[owner].balance;
        _addressData[owner].numberBurned += 1;

        // delete will reset all struct variables to 0
        delete _owners[tokenId];
        delete _renewalRequest[tokenId];

        emit Revoke(owner, tokenId);
        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Burns `tokenId`. See {IERC4973-burn}.
     *
     * Access:
     * - `tokenId` owner
     */
    function burn(uint256 tokenId) public virtual override {
        require(ownerOf(tokenId) == _msgSenderERC4973(), "ERC4973SoulContainer: burn from non-owner");

        _burn(tokenId);
    }

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * For GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC4973() internal view virtual returns (address) {
        return msg.sender;
    }

    // Converts `uint256` to ASCII `string`
    function _toString(uint256 value) internal pure returns (string memory ptr) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

            // Cache the end of the memory to calculate the length later.
            let end := ptr

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for {
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } {
                // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[43] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

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
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
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
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
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

// SPDX-License-Identifier: MIT

/**
 *******************************************************************************
 * IERC4973 Soul Container interface
 *******************************************************************************
 * Creator: Sharkz Entertainment
 * Author: Jason Hoi
 *
 */

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./IERC4973.sol";

/**
 * @dev See https://eips.ethereum.org/EIPS/eip-4973
 * This is additional interface on top of EIP-4973
 */
interface IERC4973SoulContainer is IERC165, IERC4973 {
  /**
   * @dev This emits when any guardian added or removed for a token.
   */
  event SetGuardian(address indexed to, uint256 indexed tokenId, bool approved);

  /**
   * @dev This emits when token owner or guardian request for token renewal.
   */
  event RequestRenew(address indexed from, uint256 indexed tokenId, uint256 expireTimestamp);

  /**
   * @dev This emits when renewal request approved by one address
   */
  event ApproveRenew(uint256 indexed tokenId, bool indexed approved);

  /**
   * @dev This emits when a token is renewed and bind to new address
   */
  event Renew(address indexed to, uint256 indexed tokenId);
  
  /**
   * @dev Returns token id for the address (since it is 1:1 mapping of token and address)
   */
  function tokenIdOf(address owner) external view returns (uint256);

  /**
   * @dev Returns whether an address is guardian of `tokenId`.
   */
  function isGuardian(address addr, uint256 tokenId) external view returns (bool);

  /**
   * @dev Set/remove guardian for `tokenId`.
   *
   * Requirements:
   * - `tokenId` exists
   * - (addition) guardian is not set before
   * - (removal) guardian should be existed
   *
   * Access:
   * - `tokenId` owner
   * 
   * Emits {SetGuardian} event.
   */
  function setGuardian(address to, bool approved, uint256 tokenId) external;

  /**
   * @dev Request for token renewal for token owner or other token as guardian, requester 
   * can then re-assign token to a new address.
   * It is recommanded to setup non-zero expiry timestamp, zero expiry means the 
   * request can last forever to get approvals.
   *
   * Requirements:
   * - `tokenId` exists
   *
   * Access:
   * - `tokenId` owner
   * - `tokenId` guardian
   *
   * Emits {RequestRenew} event.
   */
  function requestRenew(uint256 expireTimestamp, uint256 tokenId) external;

  /**
   * @dev Approve or cancel approval for a renewal request.
   * Owner or guardian can reset the renewal request by calling requestRenew() again to 
   * reset request approver index key to new value.
   *
   * Valid approvers = N = 1 + guardians (1 from token owner)
   * Mininum one guardian is need to build the quorum system.
   *
   * Approval quorum (> 50%) = N / 2 + 1
   * For example: 3 approvers = 2 quorum needed
   *              4 approvers = 3 quorum needed
   *              5 approvers = 3 quorum needed
   *
   * Requirements:
   * - `tokenId` exists
   * - request not expired
   *
   * Access:
   * - `tokenId` owner
   * - `tokenId` guardian
   *
   * Emits {ApproveRenew} event.
   */
  function approveRenew(bool approved, uint256 tokenId) external;

  /**
   * @dev Renew a token to new address.
   *
   * Renewal process (token can be renewed and bound to new address):
   * 1) Token owner or guardians (in case of the owner lost wallet) create/reset a renewal request
   * 2) Token owner and eacg guardian can approve the request until approval quorum (> 50%) reached
   * 3) Renewal action can be called by request originator to set the new binding address
   *
   * Requirements:
   * - `tokenId` exists
   * - request not expired
   * - request approved
   * - `to` address is not an owner of another token
   * - `to` cannot be the zero address.
   *
   * Access:
   * - `tokenId` owner
   * - `tokenId` guardian
   * - requester of the request
   *
   * Emits {Renew} event.
   */
  function renew(address to, uint256 tokenId) external;
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

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

/// @title Account-bound tokens
/// @dev See https://eips.ethereum.org/EIPS/eip-4973
///  Note: the ERC-165 identifier for this interface is 0x5164cf47.
interface IERC4973 /* is ERC165, ERC721Metadata */ {
  /// @dev This emits when a new token is created and bound to an account by
  /// any mechanism.
  /// Note: For a reliable `from` parameter, retrieve the transaction's
  /// authenticated `from` field.
  event Attest(address indexed to, uint256 indexed tokenId);
  /// @dev This emits when an existing ABT is revoked from an account and
  /// destroyed by any mechanism.
  /// Note: For a reliable `from` parameter, retrieve the transaction's
  /// authenticated `from` field.
  event Revoke(address indexed to, uint256 indexed tokenId);
  /// @notice Count all ABTs assigned to an owner
  /// @dev ABTs assigned to the zero address are considered invalid, and this
  ///  function throws for queries about the zero address.
  /// @param owner An address for whom to query the balance
  /// @return The number of ABTs owned by `owner`, possibly zero
  function balanceOf(address owner) external view returns (uint256);
  /// @notice Find the address bound to an ERC4973 account-bound token
  /// @dev ABTs assigned to zero address are considered invalid, and queries
  ///  about them do throw.
  /// @param tokenId The identifier for an ABT
  /// @return The address of the owner bound to the ABT
  function ownerOf(uint256 tokenId) external view returns (address);
  /// @notice Destroys `tokenId`. At any time, an ABT receiver must be able to
  ///  disassociate themselves from an ABT publicly through calling this
  ///  function.
  /// @dev Must emit a `event Revoke` with the `address to` field pointing to
  ///  the zero address.
  /// @param tokenId The identifier for an ABT
  function burn(uint256 tokenId) external;
}
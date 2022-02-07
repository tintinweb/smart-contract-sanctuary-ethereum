// SPDX-License-Identifier: MIT OR Apache-2.0
pragma experimental ABIEncoderV2;
pragma solidity ^0.8.0;

import "./base/NFTMarket.sol";


contract BithotelMarket is NFTMarket {
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2; // solhint-disable-line

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./mixins/TreasuryNode.sol";
import "./mixins/roles/MarketAdminRole.sol";
import "./mixins/roles/MarketOperatorRole.sol";
import "./mixins/NFTMarketCore.sol";
import "./mixins/NFTMarketFees.sol";
import "./mixins/NFTMarketSale.sol";
import "./mixins/AccountMigration.sol";

/**
 * @title A market for NFTs on Market.
 * @dev This top level file holds no data directly to ease future upgrades.
 */
 
contract NFTMarket is
  TreasuryNode,
  MarketAdminRole,
  MarketOperatorRole,
  NFTMarketCore,
  NFTMarketSale
{
  /**
   * @notice Called once to configure the contract after the initial deployment.
   * @dev This farms the initialize call out to inherited contracts as needed.
   */
  function initialize(address payable treasury) public initializer {
    TreasuryNode._initializeTreasuryNode(treasury);
    NFTMarketSale._initializeNFTMarketSale();
  }

  /**
   * @notice Allows Market to update the market configuration.
   */
  function adminUpdateConfig(
    uint256 primaryFeeBasisPoints,
    address nftContract,
    IERC20Upgradeable _coinAddress
  ) public onlyMarketAdmin {
    _updateMarketFees(primaryFeeBasisPoints, nftContract);
    coinAddress = _coinAddress;
  }

  /**
   * @dev Checks who the seller for an NFT is, this will check escrow or return the current owner if not in escrow.
   * This is a no-op function required to avoid compile errors.
   */
  function _getSellerFor(address nftContract, uint256 tokenId)
    internal
    view
    virtual
    override(
      NFTMarketCore
      )
    returns (address payable)
  {
    return super._getSellerFor(nftContract, tokenId);
  }
  
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

/**
 * @notice A mixin that stores a reference to the treasury contract.
 */
abstract contract TreasuryNode is Initializable {
  using AddressUpgradeable for address payable;

  address payable private treasury;

  /**
   * @dev Called once after the initial deployment to set the market treasury address.
   */
  function _initializeTreasuryNode(address payable _treasury) internal initializer {
    require(_treasury.isContract(), "TreasuryNode: Address is not a contract");
    treasury = _treasury;
  }

  /**
   * @notice Returns the address of the market treasury.
   */
  function getTreasury() public view returns (address payable) {
    return treasury;
  }

  // `______gap` is added to each mixin to allow adding new data slots or additional mixins in an upgrade-safe way.
  uint256[2000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "../../interfaces/IAdminRole.sol";

import "../TreasuryNode.sol";

/**
 * @notice Allows a contract to leverage the admin role defined by the market treasury.
 */
abstract contract MarketAdminRole is TreasuryNode {
  // This file uses 0 data slots (other than what's included via TreasuryNode)

  modifier onlyMarketAdmin() {
    require(_isMarketAdmin(), "MarketAdminRole: caller does not have the Admin role");
    _;
  }

  function _isMarketAdmin() internal view returns (bool) {
    return IAdminRole(getTreasury()).isAdmin(msg.sender);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "../../interfaces/ITreasury.sol";
import "../TreasuryNode.sol";

/**
 * @notice Allows a contract to leverage the operator role defined by the market treasury.
 */
abstract contract MarketOperatorRole is TreasuryNode {
  // This file uses 0 data slots (other than what's included via TreasuryNode)

  function _isMigraterOperator(address account) internal view returns (bool) {
    return ITreasury(getTreasury()).isMigraterOperator(account);
  }

  function _isCancelOperator(address account) internal view returns (bool) {
    return ITreasury(getTreasury()).isCancelOperator(account);
  }

  function _isFeeSetterOperator(address account) internal view returns (bool) {
    return ITreasury(getTreasury()).isFeeSetterOperator(account);
  }
  
  function _isMinterOperator(address account) internal view returns (bool) {
    return ITreasury(getTreasury()).isMinterOperator(account);
  }
  
  function _isSuperOperator(address account) internal view returns (bool) {
    return ITreasury(getTreasury()).isSuperOperator(account);
  }

  function _isWhitelistOperator(address account) internal view returns (bool) {
    return ITreasury(getTreasury()).isWhitelistOperator(account);
  }
  
  modifier onlyMigraterOperator() {
    require(_isMigraterOperator(msg.sender), "OperatorRole: caller does not have the Migrater role");

    _;
  }

  modifier onlyCancelOperator() {
    require(_isCancelOperator(msg.sender), "OperatorRole: caller does not have the Cancel role");

    _;
  }

  modifier onlyFeeSetterOperator() {
    require(_isFeeSetterOperator(msg.sender), "OperatorRole: caller does not have the FeeSetter role");

    _;
  }

  modifier onlyWhitelistOperator() {
    require(_isWhitelistOperator(msg.sender), "OperatorRole: caller does not have the whitelist manage role");

    _;
  }

  modifier onlyMinterOperator() {
    require(_isMinterOperator(msg.sender), "OperatorRole: caller does not have the Minter role");

    _;
  }

}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

/**
 * @notice A place for common modifiers and functions used by various NFTMarket mixins, if any.
 * @dev This also leaves a gap which can be used to add a new mixin to the top of the inheritance tree.
 */
abstract contract NFTMarketCore {
  /**
   * @dev If the auction did not have an escrowed seller to return, this falls back to return the current owner.
   * This allows functions to calculate the correct fees before the NFT has been listed in auction.
   */
  function _getSellerFor(address nftContract, uint256 tokenId) internal view virtual returns (address payable) {
    return payable(IERC721Upgradeable(nftContract).ownerOf(tokenId));
  }

  // 50 slots were consumed by adding ReentrancyGuardUpgradeable
  uint256[950] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./TreasuryNode.sol";
import "./Constants.sol";
import "./NFTMarketCore.sol";
// import "./NFTMarketCreators.sol";
// import "./SendValueWithFallbackWithdraw.sol";

import "../interfaces/INFT721.sol";
/**
 * @notice A mixin to distribute funds when an NFT is sold.
 */
abstract contract NFTMarketFees is
  Constants,
  Initializable,
  TreasuryNode,
  NFTMarketCore
{
  using SafeMathUpgradeable for uint256;

  event MarketFeesUpdated(
    uint256 primaryMarketFeeBasisPoints
  );

  uint256 private _primaryMarketFeeBasisPoints;
  address private _nftContract;
  IERC20Upgradeable coinAddress;

  mapping(address => mapping(uint256 => bool)) private nftContractToTokenIdToFirstSaleCompleted;

  function getFeeConfig()
    public
    view
    returns (
      uint256 primaryMarketFeeBasisPoints
    )
  {
    return _primaryMarketFeeBasisPoints;
  }

  function _distributeFunds(
    address payable seller,
    uint256 price
  )
    internal
  {
    if(seller==getTreasury()){
      coinAddress.transferFrom(tx.origin,getTreasury(),price);
    } else {
      uint256 foundationFee = price.mul(_primaryMarketFeeBasisPoints) / BASIS_POINTS;
      uint256 ownerRev = price.sub(foundationFee);
      coinAddress.transferFrom(tx.origin,getTreasury(),foundationFee);
      coinAddress.transferFrom(tx.origin,seller,ownerRev);
    }
  }
  /**
   * @notice Allows Market to change the market fees.
   */
  function _updateMarketFees(
    uint256 primaryMarketFeeBasisPoints,
    address nftContract
  ) internal {
    require(primaryMarketFeeBasisPoints < BASIS_POINTS, "NFTMarketFees: Fees >= 100%");

    _primaryMarketFeeBasisPoints = primaryMarketFeeBasisPoints;
    _nftContract = nftContract;

    emit MarketFeesUpdated(
      primaryMarketFeeBasisPoints
    );
  }

  function getNFTContract()public view returns(address nftContract){
    nftContract = _nftContract;
  }

  uint256[1000] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./NFTMarketFees.sol";
import "./roles/MarketAdminRole.sol";
import "./AccountMigration.sol";

import "../interfaces/INFT721.sol";
import "./NFT721Mint.sol";
abstract contract NFTMarketSale is
  MarketAdminRole,
  AccountMigration,
  ReentrancyGuardUpgradeable,
  NFTMarketFees
{
  using SafeMathUpgradeable for uint256;

  struct Sale {
    uint256 tokenId;
    address payable seller;
    uint256 price;
  }

  struct batchSale {
    uint256 startingId;
    uint256 amount;
    uint256 price;
    address payable seller;
  }

  mapping(address => mapping(uint256 => uint256)) private nftContractToTokenIdToSaleId;
  mapping(uint256 => Sale) private saleIdToSale;
  mapping(uint256 => batchSale) private saleIdToBatchSale;

  event SaleCreated(
    address indexed seller,
    uint256 indexed tokenId,
    uint256 Price,
    uint256 saleId
  );

  event batchSaleCreated(
    uint256 startingId,
    uint256 amount,
    uint256 Price,
    uint256[] saleIds
  );

  event SaleUpdated(uint256 indexed saleId, uint256 Price);
  event SaleCanceled(uint256 indexed saleId);
  event TokenBought(
    uint256 indexed saleId,
    address indexed seller,
    address indexed buyer,
    uint256 price
  );
  event SaleCanceledByAdmin(uint256 indexed saleId, string reason);
  event SaleSellerMigrated(
    uint256 indexed saleId,
    address indexed originalSellerAddress,
    address indexed newSellerAddress
  );

  modifier onlyValidSaleConfig(uint256 Price) {
    require(Price > 0, "NFTMarketSale: Price must be at least 1 wei");
    _;
  }

  uint256 private nextSaleId;

  function _initializeNFTMarketSale() internal {
    nextSaleId = 1;
  }

  function _getNextAndIncrementSaleId() internal returns (uint256) {
    return nextSaleId++;
  }

  /**
   * @notice Returns sale details for a given saleId.
   */
  function getSale(uint256 saleId) public view returns (Sale memory) {
    return saleIdToSale[saleId];
  }

  /**
   * @notice Returns the saleId for a given NFT, or 0 if no sale is found.
   * @dev If an sale is canceled, it will not be returned. However the sale may be over and pending finalization.
   */
  function getSaleIdFor(address nftContract, uint256 tokenId) public view returns (uint256) {
    return nftContractToTokenIdToSaleId[nftContract][tokenId];
  }

  function createSale(
    uint256 tokenId,
    uint256 Price
  ) public onlyValidSaleConfig(Price) nonReentrant {
    uint256 saleId = _getNextAndIncrementSaleId();
    saleIdToSale[saleId] = Sale(
      tokenId,
      payable(msg.sender),
      Price
    );
    IERC721Upgradeable(getNFTContract()).transferFrom(msg.sender, address(this), tokenId);

    emit SaleCreated(
      msg.sender,
      tokenId,
      Price,
      saleId
    );
  }

  function createBatchSale(uint256 startingId, uint256 amount, uint256 Price) public onlyValidSaleConfig(Price) nonReentrant {
    require(_isMinterOperator(tx.origin),"Not minter operator");
    uint256[] memory saleIds = new uint256[](amount);
    for(uint256 i = 0; i<amount; i++){
      uint256 saleId = _getNextAndIncrementSaleId();
      saleIds[i]=saleId;
      saleIdToSale[saleId] = Sale(
        startingId+i,
        getTreasury(),
        Price
      );
    }
    emit batchSaleCreated(
      startingId,
      amount,
      Price,
      saleIds
    );
  }

  function updateSale(uint256 saleId, uint256 Price) public onlyValidSaleConfig(Price) {
    batchSale storage sale = saleIdToBatchSale[saleId];
    require(sale.seller == msg.sender, "NFTMarketSale: Not your sale");
    sale.price = Price;

    emit SaleUpdated(saleId, Price);
  }

  function adminUpdateSale(uint256 saleId, uint256 Price) public onlyValidSaleConfig(Price) onlyMarketAdmin {
    batchSale storage sale = saleIdToBatchSale[saleId];
    sale.price = Price;

    emit SaleUpdated(saleId, Price);
  }

  function cancelSale(uint256 saleId) public nonReentrant {
    Sale memory sale = saleIdToSale[saleId];
    require(sale.seller == msg.sender, "NFTMarketSale: Not your sale");

    IERC721Upgradeable(getNFTContract()).transferFrom(address(this), sale.seller, sale.tokenId); 
 
    delete nftContractToTokenIdToSaleId[getNFTContract()][sale.tokenId];
    delete saleIdToSale[saleId];
    emit SaleCanceled(saleId);
  }
  
  function buyToken(uint256 saleId) public nonReentrant {
    Sale storage sale = saleIdToSale[saleId];
    require(sale.price != 0, "Sale not found");
    require(coinAddress.allowance(msg.sender, address(this)) >= sale.price);

    IERC721Upgradeable(getNFTContract()).transferFrom(address(this), msg.sender, sale.tokenId);
    _distributeFunds(sale.seller, sale.price);
    saleIdToSale[saleId].price=0;
    
    emit TokenBought(saleId, sale.seller, msg.sender, sale.price);
  }

  function adminCancelSale(uint256 saleId, string memory reason) public onlyMarketAdmin {
    require(bytes(reason).length > 0, "NFTMarketSale: Include a reason for this cancellation");
    Sale memory sale = saleIdToSale[saleId];
    require(sale.price > 0, "NFTMarketSale: Sale not found");

    IERC721Upgradeable(getNFTContract()).transferFrom(address(this), sale.seller, sale.tokenId); 
    delete nftContractToTokenIdToSaleId[getNFTContract()][sale.tokenId];
    delete saleIdToSale[saleId];
    emit SaleCanceledByAdmin(saleId, reason);
  }
  
  /**
   * @notice Allows an NFT owner and Market to work together in order to update the seller
   * for sales they have listed to a new account.
   * @param signature Message `I authorize Market to migrate my account to ${newAccount.address.toLowerCase()}`
   * signed by the original account.
   * @dev This will gracefully skip any sales that have already been finalized.
   */
  function adminAccountMigrationSale(
    uint256[] calldata listedSaleIds,
    address originalAddress,
    address payable newAddress,
    bytes calldata signature
  ) public onlyAuthorizedAccountMigration(originalAddress, newAddress, signature) {
    for (uint256 i = 0; i < listedSaleIds.length; i++) {
      uint256 saleId = listedSaleIds[i];
      Sale storage sale = saleIdToSale[saleId];
      // The seller would be 0 if it was finalized before this call
      if (sale.seller != address(0)) {
        require(sale.seller == originalAddress, "NFTMarketSale: Sale not created by that address");
        sale.seller = newAddress;
        emit SaleSellerMigrated(saleId, originalAddress, newAddress);
      }
    }
  }

  uint256[1000] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./roles/MarketOperatorRole.sol";
import "../interfaces/IERC1271.sol";

/**
 * @notice Checks for a valid signature authorizing the migration of an account to a new address.
 * @dev This is shared by both the NFT721 and NFTMarket, and the same signature authorizes both.
 */
abstract contract AccountMigration is MarketOperatorRole {
  // From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.1.0/contracts/utils/cryptography
  function _isValidSignatureNow(
    address signer,
    bytes32 hash,
    bytes memory signature
  ) internal view returns (bool) {
    if (AddressUpgradeable.isContract(signer)) {
      try IERC1271(signer).isValidSignature(hash, signature) returns (bytes4 magicValue) {
        return magicValue == IERC1271(signer).isValidSignature.selector;
      } catch {
        return false;
      }
    } else {
      return ECDSA.recover(hash, signature) == signer;
    }
  }

  // From https://ethereum.stackexchange.com/questions/8346/convert-address-to-string
  function _toAsciiString(address x) internal pure returns (string memory) {
    bytes memory s = new bytes(42);
    s[0] = "0";
    s[1] = "x";
    for (uint256 i = 0; i < 20; i++) {
      bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
      bytes1 hi = bytes1(uint8(b) / 16);
      bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
      s[2 * i + 2] = _char(hi);
      s[2 * i + 3] = _char(lo);
    }
    return string(s);
  }

  function _char(bytes1 b) private pure returns (bytes1 c) {
    if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    else return bytes1(uint8(b) + 0x57);
  }

  // From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.1.0/contracts/utils/cryptography/ECDSA.sol
  // Modified to accept messages (instead of the message hash)
  function _toEthSignedMessage(bytes memory message) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(message.length), message));
  }

  /**
   * @dev Confirms the msg.sender is a Market operator and that the signature provided is valid.
   * @param signature Message `I authorize Market to migrate my account to ${newAccount.address.toLowerCase()}`
   * signed by the original account.
   */
  modifier onlyAuthorizedAccountMigration(
    address originalAddress,
    address newAddress,
    bytes memory signature
  ) {
    require(_isMigraterOperator(msg.sender), "AccountMigration: Caller is not an operator");
    bytes32 hash =
      _toEthSignedMessage(
        abi.encodePacked("I authorize Market to migrate my account to ", _toAsciiString(newAddress))
      );
    require(
      _isValidSignatureNow(originalAddress, hash, signature),
      "AccountMigration: Signature must be from the original account"
    );
    _;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @notice Interface for AdminRole which wraps the default admin role from
 * OpenZeppelin's AccessControl for easy integration.
 */
interface IAdminRole {
  function isAdmin(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
// solhint-disable

pragma solidity ^0.8.0;

import "./IOperatorRole.sol";


interface ITreasury {
  function SUPER_OPERATOR_ROLE() external;
  function ONLY_MINTER_ROLE() external;
  function ONLY_MIGRATER_ROLE() external;
  function ONLY_CANCEL_ROLE() external;
  function ONLY_FEE_SETTER_ROLE() external;
  function ONLY_WHITELIST_ROLE() external;

  function withdrawFunds(address payable to, uint256 amount) external;
  function grantAdmin(address account) external;
  function revokeAdmin(address account) external;
  function isAdmin(address account) external view returns (bool);

  function grantSuperOperator(address account) external;
  function revokeSuperOperator(address account) external;
  function isSuperOperator(address account) external view returns (bool);
  function isMigraterOperator(address account) external view returns (bool);
  function isMinterOperator(address account) external view returns (bool);
  function isCancelOperator(address account) external view returns (bool);
  function isFeeSetterOperator(address account) external view returns (bool);
  function isWhitelistOperator(address account) external view returns (bool);

  function initialize(address admin) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @notice Interface for OperatorRole which wraps a role from
 * OpenZeppelin's AccessControl for easy integration.
 */
interface IOperatorRole {
  function hasRole(bytes32 role, address account) external view returns (bool);
  function grantRole(bytes32 role, address account) external view returns (bool);
  function revokeRole(bytes32 role, address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @dev Constant values shared across mixins.
 */
abstract contract Constants {
  uint256 internal constant BASIS_POINTS = 10000;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
// solhint-disable
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

pragma solidity ^0.8.0;

interface INFT721 is IERC721, IERC721Enumerable, IERC721Metadata {
  event Minted(
    address indexed creator,
    uint256 indexed tokenId,
    string indexed indexedTokenIPFSPath,
    string tokenIPFSPath
  );

  event TokenCreatorUpdated(address indexed fromCreator, address indexed toCreator, uint256 indexed tokenId);

  event TokenCreatorPaymentAddressSet(
    address indexed fromPaymentAddress,
    address indexed toPaymentAddress,
    uint256 indexed tokenId
  );

  event NFTCreatorMigrated(uint256 indexed tokenId, address indexed originalAddress, address indexed newAddress);

  event NFTOwnerMigrated(uint256 indexed tokenId, address indexed originalAddress, address indexed newAddress);

  event PaymentAddressMigrated(
    uint256 indexed tokenId,
    address indexed originalAddress,
    address indexed newAddress,
    address originalPaymentAddress,
    address newPaymentAddress
  );

  function burn(uint256 tokenId) external;
  function getTreasury() external view returns (address payable);
  function getNFTMarket() external view returns (address payable);
  function adminAccountMigration(
    uint256[] calldata createdTokenIds,
    uint256[] calldata ownedTokenIds,
    address originalAddress,
    address payable newAddress,
    bytes calldata signature
  ) external;
  function baseURI() external view returns (string memory);
  function tokenCreator(uint256 tokenId) external view returns (address payable);
  function adminUpdateConfig(address _nftMarket, string memory _baseURI) external;
  function getTokenCreatorPaymentAddress(uint256 tokenId) external view returns (address payable);
  function getNextTokenId() external view returns (uint256);
  function mint(string memory tokenIPFSPath) external returns (uint256 tokenId);
  function mintAndApproveMarket(string memory tokenIPFSPath) external returns (uint256 tokenId);
  function mintWithCreatorPaymentAddress(string memory tokenIPFSPath, address payable tokenCreatorPaymentAddress) external returns (uint256 tokenId);
  function mintWithCreatorPaymentAddressAndApproveMarket(string memory tokenIPFSPath, address payable tokenCreatorPaymentAddress) external returns (uint256 tokenId);
  function mintWithCreatorPaymentFactory(string memory tokenIPFSPath, address paymentAddressFactory, bytes memory paymentAddressCallData) external returns (uint256 tokenId);
  function mintWithCreatorPaymentFactoryAndApproveMarket(string memory tokenIPFSPath, address paymentAddressFactory, bytes memory paymentAddressCallData) external returns (uint256 tokenId);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma experimental ABIEncoderV2;
pragma solidity ^0.8.0;

import "./ERC721StorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./NFT721Creator.sol";
import "./NFT721Market.sol";
import "./NFT721Metadata.sol";
import "../libraries/AddressLibrary.sol";
import "./AccountMigration.sol";
import "../interfaces/INFTMarket.sol";

abstract contract NFT721Mint is Initializable, AccountMigration, ERC721URIStorageUpgradeable, NFT721Creator, NFT721Market, NFT721Metadata {
  using AddressLibrary for address;
  mapping(uint256=>uint256) tokenIdToType;
  uint256 private nextTokenId;

  event batchMint(
    uint256 startingId,
    uint256 lastId,
    string ipfsPath
  );

  function getNextTokenId() public view returns (uint256) {
    return nextTokenId;
  }

  function _initializeNFT721Mint() internal initializer {
    nextTokenId = 1;
  }

  function mint(string memory tokenIPFSPath, uint256 tokenType, uint256 amount, uint256 price) public {
    require(_isMinterOperator(msg.sender), "NFT721Mint: Only operators can mint");
    address market = getNFTMarket();
    uint256 startingId = getNextTokenId();
    for(uint256 i=0;i<amount;i++){
      _mint(market, tokenIPFSPath, tokenType);
    }
    INFTMarket(market).createBatchSale(startingId,amount,price);
    emit batchMint(startingId, startingId+amount-1, tokenIPFSPath);
  }  

  function _mint(address to, string memory tokenIPFSPath, uint256 tokenType) internal returns (uint256 tokenId) {
    tokenId = nextTokenId++;
    tokenIdToType[tokenId]=tokenType;
    _mint(to, tokenId);
    _setTokenURI(tokenId, tokenIPFSPath); 
  }

  function getTokenType(uint256 tokenId) public view returns(uint256 tokenType) {
    tokenType=tokenIdToType[tokenId];
  }

  /**
   * @dev Explicit override to address compile errors.
   */
  function _burn(uint256 tokenId) internal virtual override(ERC721URIStorageUpgradeable, NFT721Creator, NFT721Metadata) {
    super._burn(tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(NFT721Market,ERC721Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
  }

  uint256[1000] private ______gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.1.0/contracts/interfaces/IERC1271.sol
 */
interface IERC1271 {
  /**
   * @dev Should return whether the signature provided is valid for the provided data
   * @param hash      Hash of the data to be signed
   * @param signature Signature byte array associated with _data
   */
  function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165StorageUpgradeable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165StorageUpgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    string private _baseURI;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165StorageUpgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        // string memory baseURI = baseURI();
        return bytes(baseURI()).length > 0 ? string(abi.encodePacked(baseURI(), tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
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
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
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
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165StorageUpgradeable.sol";

import "../libraries/AddressLibrary.sol";
import "../libraries/BytesLibrary.sol";

import "./AccountMigration.sol";
import "./roles/MarketAdminRole.sol";

/**
 * @notice Allows each token to be associated with a creator.
 */
abstract contract NFT721Creator is Initializable, AccountMigration, ERC721URIStorageUpgradeable {
  using AddressLibrary for address;
  using BytesLibrary for bytes;

  mapping(address => bool) private creatorsPermittedToMint;

  mapping(uint256 => address payable) private tokenIdToCreator;

  /**
   * @dev Stores an optional alternate address to receive creator revenue and royalty payments.
   */
  mapping(uint256 => address payable) private tokenIdToCreatorPaymentAddress;

  event TokenCreatorUpdated(address indexed fromCreator, address indexed toCreator, uint256 indexed tokenId);
  event TokenCreatorPaymentAddressSet(
    address indexed fromPaymentAddress,
    address indexed toPaymentAddress,
    uint256 indexed tokenId
  );
  event NFTCreatorMigrated(uint256 indexed tokenId, address indexed originalAddress, address indexed newAddress);
  event NFTOwnerMigrated(uint256 indexed tokenId, address indexed originalAddress, address indexed newAddress);
  event PaymentAddressMigrated(
    uint256 indexed tokenId,
    address indexed originalAddress,
    address indexed newAddress,
    address originalPaymentAddress,
    address newPaymentAddress
  );

  /*
   * bytes4(keccak256('tokenCreator(uint256)')) == 0x40c1a064
   */
  bytes4 private constant _INTERFACE_TOKEN_CREATOR = 0x40c1a064;

  /*
   * bytes4(keccak256('getTokenCreatorPaymentAddress(uint256)')) == 0xec5f752e;
   */
  bytes4 private constant _INTERFACE_TOKEN_CREATOR_PAYMENT_ADDRESS = 0xec5f752e;

  modifier onlyCreatorAndOwner(uint256 tokenId) {
    require(tokenIdToCreator[tokenId] == msg.sender, "NFT721Creator: Caller is not creator");
    require(ownerOf(tokenId) == msg.sender, "NFT721Creator: Caller does not own the NFT");
    _;
  }

  /**
   * @dev Called once after the initial deployment to register the interface with ERC165.
   */
  function _initializeNFT721Creator() internal initializer {
    _registerInterface(_INTERFACE_TOKEN_CREATOR);
  }

  /**
   * @notice Allows ERC165 interfaces which were not included originally to be registered.
   * @dev Currently this is the only new interface, but later other mixins can overload this function to do the same.
   */
  function registerInterfaces() public {
    _registerInterface(_INTERFACE_TOKEN_CREATOR_PAYMENT_ADDRESS);
  }

  /**
   * @notice Returns the creator's address for a given tokenId.
   */
  function tokenCreator(uint256 tokenId) public view returns (address payable) {
    return tokenIdToCreator[tokenId];
  }

  /**
   * @notice Returns the payment address for a given tokenId.
   * @dev If an alternate address was not defined, the creator is returned instead.
   */
  function getTokenCreatorPaymentAddress(uint256 tokenId)
    public
    view
    returns (address payable tokenCreatorPaymentAddress)
  {
    tokenCreatorPaymentAddress = tokenIdToCreatorPaymentAddress[tokenId];
    if (tokenCreatorPaymentAddress == address(0)) {
      tokenCreatorPaymentAddress = tokenIdToCreator[tokenId];
    }
  }

  function _updateTokenCreator(uint256 tokenId, address payable creator) internal {
    // emit TokenCreatorUpdated(tokenIdToCreator[tokenId], creator, tokenId);

    tokenIdToCreator[tokenId] = creator;
  }

  /**
   * @dev Allow setting a different address to send payments to for both primary sale revenue
   * and secondary sales royalties.
   */
  function _setTokenCreatorPaymentAddress(uint256 tokenId, address payable tokenCreatorPaymentAddress) internal {
    emit TokenCreatorPaymentAddressSet(tokenIdToCreatorPaymentAddress[tokenId], tokenCreatorPaymentAddress, tokenId);
    tokenIdToCreatorPaymentAddress[tokenId] = tokenCreatorPaymentAddress;
  }

  /**
   * @notice Allows the creator to burn if they currently own the NFT.
   */
  function burn(uint256 tokenId) public onlyCreatorAndOwner(tokenId) {
    _burn(tokenId);
  }

  /**
   * @notice Allows an NFT owner or creator and Market to work together in order to update the creator
   * to a new account and/or transfer NFTs to that account.
   * @param signature Message `I authorize Market to migrate my account to ${newAccount.address.toLowerCase()}`
   * signed by the original account.
   * @dev This will gracefully skip any NFTs that have been burned or transferred.
   */
  function adminAccountMigration(
    uint256[] calldata createdTokenIds,
    uint256[] calldata ownedTokenIds,
    address originalAddress,
    address payable newAddress,
    bytes calldata signature
  ) public onlyAuthorizedAccountMigration(originalAddress, newAddress, signature) {
    for (uint256 i = 0; i < ownedTokenIds.length; i++) {
      uint256 tokenId = ownedTokenIds[i];
      // Check that the token exists and still owned by the originalAddress
      // so that frontrunning a burn or transfer will not cause the entire tx to revert
      if (_exists(tokenId) && ownerOf(tokenId) == originalAddress) {
        _transfer(originalAddress, newAddress, tokenId);
        emit NFTOwnerMigrated(tokenId, originalAddress, newAddress);
      }
    }

    for (uint256 i = 0; i < createdTokenIds.length; i++) {
      uint256 tokenId = createdTokenIds[i];
      // The creator would be 0 if the token was burned before this call
      if (tokenIdToCreator[tokenId] != address(0)) {
        require(
          tokenIdToCreator[tokenId] == originalAddress,
          "NFT721Creator: Token was not created by the given address"
        );
        _updateTokenCreator(tokenId, newAddress);
        emit NFTCreatorMigrated(tokenId, originalAddress, newAddress);
      }
    }
  }

  /**
   * @notice Allows a split recipient and Market to work together in order to update the payment address
   * to a new account.
   * @param signature Message `I authorize Market to migrate my account to ${newAccount.address.toLowerCase()}`
   * signed by the original account.
   */
  function adminAccountMigrationForPaymentAddresses(
    uint256[] calldata paymentAddressTokenIds,
    address paymentAddressFactory,
    bytes memory paymentAddressCallData,
    uint256 addressLocationInCallData,
    address originalAddress,
    address payable newAddress,
    bytes calldata signature
  ) public onlyAuthorizedAccountMigration(originalAddress, newAddress, signature) {
    _adminAccountRecoveryForPaymentAddresses(
      paymentAddressTokenIds,
      paymentAddressFactory,
      paymentAddressCallData,
      addressLocationInCallData,
      originalAddress,
      newAddress
    );
  }

  /**
   * @dev Split into a second function to avoid stack too deep errors
   */
  function _adminAccountRecoveryForPaymentAddresses(
    uint256[] calldata paymentAddressTokenIds,
    address paymentAddressFactory,
    bytes memory paymentAddressCallData,
    uint256 addressLocationInCallData,
    address originalAddress,
    address payable newAddress
  ) private {
    // Call the factory and get the originalPaymentAddress
    address payable originalPaymentAddress = paymentAddressFactory.functionCallAndReturnAddress(paymentAddressCallData);

    // Confirm the original address and swap with the new address
    paymentAddressCallData.replaceAtIf(addressLocationInCallData, originalAddress, newAddress);

    // Call the factory and get the newPaymentAddress
    address payable newPaymentAddress = paymentAddressFactory.functionCallAndReturnAddress(paymentAddressCallData);

    // For each token, confirm the expected payment address and then update to the new one
    for (uint256 i = 0; i < paymentAddressTokenIds.length; i++) {
      uint256 tokenId = paymentAddressTokenIds[i];
      require(
        tokenIdToCreatorPaymentAddress[tokenId] == originalPaymentAddress,
        "NFT721Creator: Payment address is not the expected value"
      );

      _setTokenCreatorPaymentAddress(tokenId, newPaymentAddress);
      emit PaymentAddressMigrated(tokenId, originalAddress, newAddress, originalPaymentAddress, newPaymentAddress);
    }
  }

  /**
   * @dev check if sender is whitelisted creator
   */
  function isWhitelistedCreator(address _creator) public view returns (bool) {
      return _isMinterOperator(_creator) || creatorsPermittedToMint[_creator];
  }

  /**
   * @dev permit address to mint nft
   */
  function grantMint(address _creator) public onlyWhitelistOperator {
      creatorsPermittedToMint[_creator] = true;
  }

  /**
   * @dev revoke address to mint nft
   */
  function revokeMint(address _creator) public onlyWhitelistOperator {
      creatorsPermittedToMint[_creator] = false;
  }

  /**
   * @dev Remove the creator record when burned.
   */
  function _burn(uint256 tokenId) internal virtual override(ERC721URIStorageUpgradeable) {
    delete tokenIdToCreator[tokenId];

    super._burn(tokenId);
  }

  uint256[999] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../interfaces/INFTMarket.sol";

import "./TreasuryNode.sol";
import "./HasSecondarySaleFees.sol";
import "./NFT721Creator.sol";

/**
 * @notice Holds a reference to the Market Market and communicates fees to 3rd party marketplaces.
 */
abstract contract NFT721Market is TreasuryNode, HasSecondarySaleFees, NFT721Creator {
  using AddressUpgradeable for address;

  event NFTMarketUpdated(address indexed nftMarket);

  INFTMarket private nftMarket;

  /**
   * @notice Returns the address of the Market NFTMarket contract.
   */
  function getNFTMarket() public view returns (address) {
    return address(nftMarket);
  }

  function _updateNFTMarket(address _nftMarket) internal {
    require(_nftMarket.isContract(), "NFT721Market: Market address is not a contract");
    nftMarket = INFTMarket(_nftMarket);

    emit NFTMarketUpdated(_nftMarket);
  }

  /**
   * @notice Returns an array of recipient addresses to which fees should be sent.
   * The expected fee amount is communicated with `getFeeBps`.
   */
  function getFeeRecipients(uint256 id) public view override returns (address payable[] memory) {
    require(_exists(id), "ERC721Metadata: Query for nonexistent token");

    address payable[] memory result = new address payable[](2);
    result[0] = getTreasury();
    result[1] = getTokenCreatorPaymentAddress(id);
    return result;
  }

  /**
   * @notice Returns an array of fees in basis points.
   * The expected recipients is communicated with `getFeeRecipients`.
   */
  function getFeeBps(
    uint256 /* id */
  ) public view override returns (uint256[] memory) {
    (, uint256 secondaryFeeBasisPoints, uint256 secondaryCreatorFeeBasisPoints) = nftMarket.getFeeConfig();
    uint256[] memory result = new uint256[](2);
    result[0] = secondaryFeeBasisPoints;
    result[1] = secondaryCreatorFeeBasisPoints;
    return result;
  }

  /**
   * @notice Get fee recipients and fees in a single call.
   * The data is the same as when calling getFeeRecipients and getFeeBps separately.
   */
  function getFees(uint256 tokenId)
    public
    view
    returns (address payable[2] memory recipients, uint256[2] memory feesInBasisPoints)
  {
    require(_exists(tokenId), "ERC721Metadata: Query for nonexistent token");

    recipients[0] = getTreasury();
    recipients[1] = getTokenCreatorPaymentAddress(tokenId);
    (, uint256 secondaryFeeBasisPoints, uint256 secondaryCreatorFeeBasisPoints) = nftMarket.getFeeConfig();
    feesInBasisPoints[0] = secondaryFeeBasisPoints;
    feesInBasisPoints[1] = secondaryCreatorFeeBasisPoints;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable,ERC165StorageUpgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
  }

  uint256[1000] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "./NFTCore.sol";
import "./NFT721Creator.sol";

/**
 * @notice A mixin to extend the OpenZeppelin metadata implementation.
 */
abstract contract NFT721Metadata is NFT721Creator {
  using StringsUpgradeable for uint256;

  /**
   * @dev Stores hashes minted by a creator to prevent duplicates.
   */
  mapping(address => mapping(string => bool)) private creatorToIPFSHashToMinted;

  event BaseURIUpdated(string baseURI);
  event TokenIPFSPathUpdated(uint256 indexed tokenId, string indexed indexedTokenIPFSPath, string tokenIPFSPath);
  // This event was used in an order version of the contract
  event NFTMetadataUpdated(string name, string symbol, string baseURI);

  /**
   * @notice Returns the IPFSPath to the metadata JSON file for a given NFT.
   */
  function getTokenIPFSPath(uint256 tokenId) public view returns (string memory) {
    return tokenURI(tokenId);
  }

  /**
   * @notice Checks if the creator has already minted a given NFT.
   */
  function getHasCreatorMintedIPFSHash(address creator, string memory tokenIPFSPath) public view returns (bool) {
    return creatorToIPFSHashToMinted[creator][tokenIPFSPath];
  }

  function _updateBaseURI(string memory _baseURI) internal {
    _setBaseURI(_baseURI);

    emit BaseURIUpdated(_baseURI);
  }

  /**
   * @dev The IPFS path should be the CID + file.extension, e.g.
   * `QmfPsfGwLhiJrU8t9HpG4wuyjgPo9bk8go4aQqSu9Qg4h7/metadata.json`
   */
  function _setTokenIPFSPath(uint256 tokenId, string memory _tokenIPFSPath) internal {
    creatorToIPFSHashToMinted[msg.sender][_tokenIPFSPath] = true;
    _setTokenURI(tokenId, _tokenIPFSPath);
  }

  /**
   * @dev When a token is burned, remove record of it allowing that creator to re-mint the same NFT again in the future.
   */
  function _burn(uint256 tokenId) internal virtual override {
    delete creatorToIPFSHashToMinted[msg.sender][tokenURI(tokenId)];
    super._burn(tokenId);
  }

  uint256[999] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

/**
 * @dev Named this way to avoid conflicts with `Address` from OZ.
 */
library AddressLibrary {
  using AddressUpgradeable for address;

  function functionCallAndReturnAddress(address paymentAddressFactory, bytes memory paymentAddressCallData)
    internal
    returns (address payable result)
  {
    bytes memory returnData = paymentAddressFactory.functionCall(paymentAddressCallData);

    // Skip the length at the start of the bytes array and return the data, casted to an address
    // solhint-disable-next-line no-inline-assembly
    assembly {
      result := mload(add(returnData, 32))
    }
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
// solhint-disable
pragma experimental ABIEncoderV2;
pragma solidity ^0.8.0;

interface INFTMarket {
  event ReserveAuctionConfigUpdated(
    uint256 minPercentIncrementInBasisPoints,
    uint256 maxBidIncrementRequirement,
    uint256 duration,
    uint256 extensionDuration,
    uint256 goLiveDate
  );

  event ReserveAuctionCreated(
    address indexed seller,
    address indexed nftContract,
    uint256 indexed tokenId,
    uint256 duration,
    uint256 extensionDuration,
    uint256 reservePrice,
    uint256 auctionId
  );
  event ReserveAuctionUpdated(uint256 indexed auctionId, uint256 reservePrice);
  event ReserveAuctionCanceled(uint256 indexed auctionId);
  event ReserveAuctionBidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount, uint256 endTime);
  event ReserveAuctionFinalized(
    uint256 indexed auctionId,
    address indexed seller,
    address indexed bidder,
    uint256 marketFee,

    uint256 creatorFee,
    uint256 ownerRev
  );
  event ReserveAuctionCanceledByAdmin(uint256 indexed auctionId, string reason);
  event ReserveAuctionSellerMigrated(
    uint256 indexed auctionId,
    address indexed originalSellerAddress,
    address indexed newSellerAddress
  );
  struct ReserveAuction {
    address nftContract;
    uint256 tokenId;
    address payable seller;
    uint256 duration;
    uint256 extensionDuration;
    uint256 endTime;
    address payable bidder;
    uint256 amount;
  }

  function adminUpdateConfig(
    uint256 minPercentIncrementInBasisPoints,
    uint256 duration,
    uint256 primaryFeeBasisPoints,
    uint256 secondaryFeeBasisPoints,
    uint256 secondaryCreatorFeeBasisPoints
  ) external;

  function getReserveAuction(uint256 auctionId) external view returns (ReserveAuction memory);

  function getReserveAuctionIdFor(address nftContract, uint256 tokenId) external view returns (uint256);

  function getReserveAuctionConfig() external view returns (uint256 minPercentIncrementInBasisPoints, uint256 duration);

  function createReserveAuction(
    address nftContract,
    uint256 tokenId,
    uint256 reservePrice
  ) external;

  function updateReserveAuction(uint256 auctionId, uint256 reservePrice) external;

  function cancelReserveAuction(uint256 auctionId) external;

  function placeBid(uint256 auctionId) external payable;

  function finalizeReserveAuction(uint256 auctionId) external;

  function getMinBidAmount(uint256 auctionId) external view returns (uint256);

  function adminCancelReserveAuction(uint256 auctionId, string memory reason) external;

  function createSale(address nftContract, uint256 tokenId, uint256 Price) external;

  function createBatchSale(uint256 startingId,uint256 amount, uint256 Price) external;

  function adminAccountMigration(
    uint256[] calldata listedAuctionIds,
    address originalAddress,
    address payable newAddress,
    bytes calldata signature
  ) external;

  function getFeeConfig()
    external
    view
    returns (
      uint256 primaryFeeBasisPoints,
      uint256 secondaryFeeBasisPoints,
      uint256 secondaryCreatorFeeBasisPoints
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165StorageUpgradeable is Initializable, ERC165Upgradeable {
    function __ERC165Storage_init() internal onlyInitializing {
        __ERC165_init_unchained();
        __ERC165Storage_init_unchained();
    }

    function __ERC165Storage_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
    uint256[49] private __gap;
}

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
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "./ERC721StorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorageUpgradeable is Initializable, ERC721Upgradeable {
    function __ERC721URIStorage_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721URIStorage_init_unchained();
    }

    function __ERC721URIStorage_init_unchained() internal onlyInitializing {
    }
    using StringsUpgradeable for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
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
    function _burn(uint256 tokenId) internal virtual override(ERC721Upgradeable) {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

library BytesLibrary {
  function replaceAtIf(
    bytes memory data,
    uint256 startLocation,
    address expectedAddress,
    address newAddress
  ) internal pure {
    bytes memory expectedData = abi.encodePacked(expectedAddress);
    bytes memory newData = abi.encodePacked(newAddress);
    // An address is 20 bytes long
    for (uint256 i = 0; i < 20; i++) {
      uint256 dataLocation = startLocation + i;
      require(data[dataLocation] == expectedData[i], "Bytes: Data provided does not include the expectedAddress");
      data[dataLocation] = newData[i];
    }
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165StorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @notice An interface for communicating fees to 3rd party marketplaces.
 * @dev Originally implemented in mainnet contract 0x44d6e8933f8271abcf253c72f9ed7e0e4c0323b3
 */
abstract contract HasSecondarySaleFees is Initializable, ERC165StorageUpgradeable {
  /*
   * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
   * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
   *
   * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
   */
  bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;

  /**
   * @dev Called once after the initial deployment to register the interface with ERC165.
   */
  function _initializeHasSecondarySaleFees() internal initializer {
    _registerInterface(_INTERFACE_ID_FEES);
  }

  function getFeeRecipients(uint256 id) public view virtual returns (address payable[] memory);

  function getFeeBps(uint256 id) public view virtual returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @notice A place for common modifiers and functions used by various NFT721 mixins, if any.
 * @dev This also leaves a gap which can be used to add a new mixin to the top of the inheritance tree.
 */
abstract contract NFTCore {
  uint256[1000] private ______gap;
}
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.12 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./collectionItem/CollectionItem.sol";
import "./bank/Bank.sol";
import "./sale/Sale.sol";

import "hardhat/console.sol";


contract AvaxTrade is Initializable, UUPSUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, IERC721Receiver {

  // Access Control
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  // modifiers
  modifier checkContractValidity(address _contractAddress) {
    require(_isContractAddressValid(_contractAddress), "Provided contract address is not valid");
    _;
  }

  // enums
  enum SALE_TYPE { direct, immediate, auction }

  // data structures
  struct BalanceSheetDS {
    uint256 totalFunds; // total funds in contract before deductions
    uint256 marketplaceRevenue; // outstanding marketplace revenue balance
    uint256 nftCommission; // outstanding nft commission reward balance
    uint256 collectionReflection; // outstanding collection reflection reward balance
    uint256 collectionCommission; // outstanding collection commission reward balance
    uint256 collectionIncentive;  // outstanding collection incentive reward balance
    uint256 incentiveVault; // outstanding incentive vault balance
    uint256 availableFunds; // total funds in contract after deductions
  }

  struct ContractsDS {
    address bank; // address for the bank contract
    address sale; // address for the sale contract
    address collectionItem; // address for the collectionItem contract
  }

  // state variables
  uint256 private LISTING_PRICE; // price to list item in marketplace
  uint8 private MARKETPLACE_COMMISSION; // commission rate charged upon every sale, in percentage
  uint8 private MARKETPLACE_INCENTIVE_COMMISSION; // commission rate rewarded upon every sale, in percentage
  address private MARKETPLACE_BANK_OWNER; // user who has access to withdraw marketplace commission

  ContractsDS private CONTRACTS;

  // monetary
  BalanceSheetDS private BALANCE_SHEET;

  // events
  event onERC721ReceivedEvent(address operator, address from, uint256 tokenId, bytes data);
  event onCollectionCreate(address indexed owner, address indexed contractAddress, string collectionType, uint256 id);
  event onCreateMarketSale(uint256 indexed itemId, uint256 indexed tokenId, address indexed contractAddress, address seller, SALE_TYPE saleType);
  event onCancelMarketSale(uint256 indexed itemId, uint256 indexed tokenId, address indexed contractAddress, address seller);
  event onCompleteMarketSale(uint256 indexed itemId, uint256 indexed tokenId, address indexed contractAddress, address buyer, uint256 saleProfit);
  event onClaimRewards(address indexed user, uint256 indexed reward, string rewardType);
  event onDepositMarketplaceIncentive(address indexed user, uint256 indexed amount);
  event onDepositCollectionIncentive(address indexed user, address indexed contractAddress, uint256 indexed amount);
  event onWithdrawCollectionIncentive(address indexed user, address indexed contractAddress, uint256 indexed amount);
  event onDistributeRewardInCollection(uint256 indexed collectionId, uint256 indexed amount);


  function initialize(address _owner) initializer public {
    // call parent classes
    __AccessControl_init();
    __ReentrancyGuard_init();

    // initialize state variables
    LISTING_PRICE = 0.0 ether;
    MARKETPLACE_COMMISSION = 2;
    MARKETPLACE_INCENTIVE_COMMISSION = 0;
    MARKETPLACE_BANK_OWNER = _owner;

    BALANCE_SHEET = BalanceSheetDS(0, 0, 0, 0, 0, 0, 0, 0);

    // set up admin role
    _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);

    // grant admin role to following account (parent contract)
    _setupRole(ADMIN_ROLE, _owner);
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function _authorizeUpgrade(address) internal override onlyRole(ADMIN_ROLE) {}


  /**
    *****************************************************
    **************** Private Functions ******************
    *****************************************************
  */
  /**
    * @dev Is contract address valid ERC721 or ERC1155
  */
  function _isContractAddressValid(address _contractAddress) private view returns (bool) {
    if (IERC721(_contractAddress).supportsInterface(type(IERC721).interfaceId)) {
      return true;
    }
    return false;
  }

  /**
    * @dev Calculate percent change
  */
  function _calculatePercentChange(uint256 _value, uint8 _percent) private pure returns (uint256) {
    return (_value * _percent / 100);
  }


  /** 
    *****************************************************
    **************** Attribute Functions ****************
    *****************************************************
  */
  /**
    * @dev Get list of contract address of sibling contracts
  */
  function getContracts() public view returns (ContractsDS memory) {
    return CONTRACTS;
  }
  /**
    * @dev Set list of contract address of sibling contracts
  */
  function setContracts(address _bank, address _sale, address _collectionItem) public onlyRole(ADMIN_ROLE) {
    if (_bank != address(0)) {
      CONTRACTS.bank = _bank;
    }
    if (_sale != address(0)) {
      CONTRACTS.sale = _sale;
    }
    if (_collectionItem != address(0)) {
      CONTRACTS.collectionItem = _collectionItem;
    }
  }

  /**
    * @dev Get marketplace listing price
  */
  function getMarketplaceListingPrice() public view returns (uint256) {
    return LISTING_PRICE;
  }
  /**
    * @dev Set marketplace listing price
  */
  function setMarketplaceListingPrice(uint256 _listingPrice) public onlyRole(ADMIN_ROLE) {
    LISTING_PRICE = _listingPrice;
  }

  /**
    * @dev Get marketplace commission
  */
  function getMarketplaceCommission() public view returns (uint8) {
    return MARKETPLACE_COMMISSION;
  }
  /**
    * @dev Set marketplace commission
  */
  function setMarketplaceCommission(uint8 _commission) public onlyRole(ADMIN_ROLE) {
    MARKETPLACE_COMMISSION = _commission;
  }

  /**
    * @dev Get marketplace incentive commission
  */
  function getMarketplaceIncentiveCommission() public view returns (uint8) {
    return MARKETPLACE_INCENTIVE_COMMISSION;
  }
  /**
    * @dev Set marketplace incentive commission
  */
  function setMarketplaceIncentiveCommission(uint8 _commission) public onlyRole(ADMIN_ROLE) {
    MARKETPLACE_INCENTIVE_COMMISSION = _commission;
  }

  /**
    * @dev Get marketplace bank owner
  */
  function getMarketplaceBankOwner() public view returns (address) {
    return MARKETPLACE_BANK_OWNER;
  }
  /**
    * @dev Set marketplace bank owner
  */
  function setMarketplaceBankOwner(address _owner) public onlyRole(ADMIN_ROLE) {
    MARKETPLACE_BANK_OWNER = _owner;
  }


  /** 
    *****************************************************
    ****************** Main Functions *******************
    *****************************************************
  */
  /**
    * @dev Create market sale
  */
  function createMarketSale(
    uint256 _tokenId, address _contractAddress, address _buyer, uint256 _price, SALE_TYPE _saleType
  ) external nonReentrant() payable {
    // ensure listing price is met
    require(msg.value >= LISTING_PRICE, 'Not enough funds to create sale');
    if (_saleType != SALE_TYPE.direct) {
      require(_price > 0, 'Buy price must be greater than 0');
    }

    address buyer = address(0);
    if (_saleType == SALE_TYPE.direct) {
      buyer = _buyer; // only use passed in buyer param when it is a direct sale
    }
    uint256 itemId = CollectionItem(CONTRACTS.collectionItem).addItemToCollection(
      _tokenId,
      _contractAddress,
      msg.sender,
      buyer,
      _price
    );

    if (_saleType == SALE_TYPE.direct) {
      Sale(CONTRACTS.sale).createSaleDirect(itemId, msg.sender);
    } else if (_saleType == SALE_TYPE.immediate) {
      Sale(CONTRACTS.sale).createSaleImmediate(itemId, msg.sender);
    } else if (_saleType == SALE_TYPE.auction) {
      Sale(CONTRACTS.sale).createSaleAuction(itemId, msg.sender);
    } else {
      revert("Incorrect sale type");
    }

    if (IERC721(_contractAddress).supportsInterface(type(IERC721).interfaceId)) {
      // ownerOf(_tokenId) == msg.sender then continue, else revert transaction
      require(IERC721(_contractAddress).ownerOf(_tokenId) == msg.sender, "You are not the owner of this item");

      // transfer nft to market place
      IERC721(_contractAddress).safeTransferFrom(msg.sender, address(this), _tokenId);
    } else {
      revert("Provided contract address is not valid");
    }

    emit onCreateMarketSale(itemId, _tokenId, _contractAddress, msg.sender, _saleType);
  }

  /**
    * @dev Cancel market item from sale
  */
  function cancelMarketSale(uint256 _itemId) external nonReentrant() {
    Item.ItemDS memory item = CollectionItem(CONTRACTS.collectionItem).getItem(_itemId);
    require(!item.sold, "This item has already been sold");
    require(item.active, "This item is inactive");
    require(msg.sender == item.seller, "You are not the original owner of this item");

    CollectionItem(CONTRACTS.collectionItem).cancelItemInCollection(_itemId);
    Sale(CONTRACTS.sale)._removeSale(_itemId, msg.sender);

    // transfer nft to original owner
    IERC721(item.contractAddress).safeTransferFrom(address(this), msg.sender, item.tokenId);

    emit onCancelMarketSale(_itemId, item.tokenId, item.contractAddress, msg.sender);
  }

  /**
    * @dev Remove market item from sale. For a varified collection
  */
  function completeMarketSale(uint256 _itemId) external nonReentrant() payable {
    Item.ItemDS memory item = CollectionItem(CONTRACTS.collectionItem).getItem(_itemId);
    require(!item.sold, "This item has already been sold");
    require(item.active, "This item is inactive");
    require(msg.value >= item.price, "Not enough funds to purchase this item");
    require(msg.sender != item.seller, "You can not buy your own item");

    uint256 saleProfit = 0;
    if (Sale(CONTRACTS.sale).isDirectSaleValid(_itemId, item.seller)) {
      // directMarketSale(item, msg.sender, msg.value);
      require(msg.sender == item.buyer, "You are not the authorized buyer");
      saleProfit = _completeSale(item, msg.sender, msg.value);
    } else if (Sale(CONTRACTS.sale).isImmediateSaleValid(_itemId, item.seller)) {
      saleProfit = _completeSale(item, msg.sender, msg.value);
    } else if (Sale(CONTRACTS.sale).isAuctionSaleValid(_itemId, item.seller)) {
      saleProfit = _completeSale(item, msg.sender, msg.value);
    } else {
      revert("Invalid sale type");
    }

    emit onCompleteMarketSale(_itemId, item.tokenId, item.contractAddress, msg.sender, saleProfit);
  }

  /**
    * @dev Complete sale
  */
  function _completeSale(Item.ItemDS memory item, address _buyer, uint256 _price) private returns (uint256) {
    // todo Test: Unverified item on sale. Then item is now verified but still listed on sale. What happens?

    Collection.CollectionDS memory collection = CollectionItem(CONTRACTS.collectionItem).getCollection(item.collectionId);

    CollectionItem(CONTRACTS.collectionItem).markItemSoldInCollection(item.id, _buyer);
    Sale(CONTRACTS.sale)._removeSale(item.id, item.seller);

    // deduct marketplace 2% commission
    _price = marketplaceCommission(_price, MARKETPLACE_COMMISSION);

    Collection.COLLECTION_TYPE collectionType = collection.collectionType;
    if (collectionType == Collection.COLLECTION_TYPE.local) {
      console.log('local');

      // deduct nft commission, if applicable
      _price = nftCommission(_price, item.commission, item.creator);

    } else if (collectionType == Collection.COLLECTION_TYPE.verified) {
      console.log('verified');

      // deduct collection reflection rewards, if applicable
      _price = collectionReflection(_price, collection.reflection, collection.contractAddress, collection.totalSupply);

      // deduct collection commission rewards, if applicable
      _price = collectionCommission(_price, collection.commission, collection.owner);

      // add collection incentive rewards, if applicable
      _price = collectionIncentive(_price, collection.incentive, collection.contractAddress);

    } else if (collectionType == Collection.COLLECTION_TYPE.unverified) {
      console.log('unverified');
    } else {
      revert("Invalid collection type");
    }
    
    // add marketplace incentive rewards, if applicable
    _price = marketplaceIncentive(_price, MARKETPLACE_INCENTIVE_COMMISSION);

    // transfer funds to seller
    Bank(CONTRACTS.bank).incrementUserAccount(item.seller, _price, 0, 0);

    // transfer nft to market place
    IERC721(item.contractAddress).safeTransferFrom(address(this), _buyer, item.tokenId);

    return _price;
  }


  /** 
    *****************************************************
    ***************** Reward Functions ******************
    *****************************************************
  */
  /**
    * @dev Deduct marketplace commission
    * @custom:type private
  */
  function marketplaceCommission(uint256 _value, uint8 _percent) private returns (uint256) {
    uint256 reward = _calculatePercentChange(_value, _percent);
    _value -= reward;
    Bank(CONTRACTS.bank).incrementUserAccount(MARKETPLACE_BANK_OWNER, reward, 0, 0);
    BALANCE_SHEET.marketplaceRevenue += reward;
    return _value;
  }

  /**
    * @dev Deduct nft commission
    * @custom:type private
  */
  function nftCommission(uint256 _value, uint8 _percent, address _creator) private returns (uint256) {
    uint256 reward = _calculatePercentChange(_value, _percent);
    if (reward > 0) {
      _value -= reward;
      Bank(CONTRACTS.bank).incrementUserAccount(_creator, 0, reward, 0);
      BALANCE_SHEET.nftCommission += reward;
    }
    return _value;
  }

  /**
    * @dev Deduct collection reflection
    * @custom:type private
  */
  function collectionReflection(uint256 _value, uint8 _percent, address _contractAddress, uint256 _totalSupply) private returns (uint256) {
    uint256 reward = _calculatePercentChange(_value, _percent);
    if (reward > 0) {
      _value -= reward;
      Bank(CONTRACTS.bank).distributeCollectionReflectionReward(_contractAddress, _totalSupply, reward);
      BALANCE_SHEET.collectionReflection += reward;
    }
    return _value;
  }

  /**
    * @dev Deduct collection commission
    * @custom:type private
  */
  function collectionCommission(uint256 _value, uint8 _percent, address _collectionOwner) private returns (uint256) {
    uint256 reward = _calculatePercentChange(_value, _percent);
    if (reward > 0) {
      _value -= reward;
      Bank(CONTRACTS.bank).incrementUserAccount(_collectionOwner, 0, 0, reward);
      BALANCE_SHEET.collectionCommission += reward;
    }
    return _value;
  }

  /**
    * @dev Give collection incentives
    * @custom:type private
  */
  function collectionIncentive(uint256 _value, uint8 _percent, address _contractAddress) private returns (uint256) {
    uint256 reward = _calculatePercentChange(_value, _percent);
    if (reward > 0) {
      uint256 collectionIncentiveVault = Bank(CONTRACTS.bank).getIncentiveVaultCollectionAccount(_contractAddress);
      if (collectionIncentiveVault >= reward) {
        _value += reward;
        Bank(CONTRACTS.bank).updateCollectionIncentiveReward(_contractAddress, reward, false);
        BALANCE_SHEET.collectionIncentive -= reward;
      } else {
        _value += collectionIncentiveVault;
        Bank(CONTRACTS.bank).nullifyCollectionIncentiveReward(_contractAddress);
        BALANCE_SHEET.collectionIncentive = 0;
      }
    }
    return _value;
  }

  /**
    * @dev Give marketplace incentives
    * @custom:type private
  */
  function marketplaceIncentive(uint256 _value, uint8 _percent) private returns (uint256) {
    uint256 reward = _calculatePercentChange(_value, _percent);
    if (reward > 0) {
      if (BALANCE_SHEET.incentiveVault >= reward) {
        _value += reward;
        BALANCE_SHEET.incentiveVault -= reward;
      } else {
        _value += BALANCE_SHEET.incentiveVault;
        BALANCE_SHEET.incentiveVault = 0;
      }
    }
    return _value;
  }


  /** 
    *****************************************************
    ***************** Claim Functions *******************
    *****************************************************
  */
  /**
    * @dev Claim account general reward for this user
  */
  function claimGeneralRewardUserAccount() external nonReentrant() returns (uint256) {
    uint256 reward = Bank(CONTRACTS.bank).claimGeneralRewardUserAccount(msg.sender);

    // todo ensure this is a safe way to transfer funds
    ( bool success, ) = payable(msg.sender).call{ value: reward }("");
    require(success, "General reward transfer to user was unccessfull");
    emit onClaimRewards(msg.sender, reward, 'general');
    return reward;
  }

  /**
    * @dev Claim account nft commission reward for this user
  */
  function claimNftCommissionRewardUserAccount() external nonReentrant() returns (uint256) {
    uint256 reward = Bank(CONTRACTS.bank).claimNftCommissionRewardUserAccount(msg.sender);

    // todo ensure this is a safe way to transfer funds
    ( bool success, ) = payable(msg.sender).call{ value: reward }("");
    require(success, "Nft commission reward transfer to user was unccessfull");
    emit onClaimRewards(msg.sender, reward, 'nft_commission');
    return reward;
  }

  /**
    * @dev Claim account collection commission reward for this user
  */
  function claimCollectionCommissionRewardUserAccount() external nonReentrant() returns (uint256) {
    uint256 reward = Bank(CONTRACTS.bank).claimCollectionCommissionRewardUserAccount(msg.sender);

    // todo ensure this is a safe way to transfer funds
    ( bool success, ) = payable(msg.sender).call{ value: reward }("");
    require(success, "Collection commission reward transfer to user was unccessfull");
    emit onClaimRewards(msg.sender, reward, 'collection_commission');
    return reward;
  }

  /**
    * @dev Claim collection reflection reward for this token id
  */
  function claimReflectionRewardCollectionAccount(uint256 _tokenId, address _contractAddress) external nonReentrant() returns (uint256) {
    uint256 reward = Bank(CONTRACTS.bank).claimReflectionRewardCollectionAccount(_tokenId, _contractAddress);

    if (IERC721(_contractAddress).supportsInterface(type(IERC721).interfaceId)) {
      // ownerOf(_tokenId) == msg.sender then continue, else revert transaction
      require(IERC721(_contractAddress).ownerOf(_tokenId) == msg.sender, "You are not the owner of this item");

      // todo ensure this is a safe way to transfer funds
      ( bool success, ) = payable(msg.sender).call{ value: reward }("");
      require(success, "Collection commission reward transfer to user was unccessfull");
    } else {
      revert("Provided contract address is not valid");
    }
    emit onClaimRewards(msg.sender, reward, 'collection_reflection');
    return reward;
  }

  /**
    * @dev Claim collection reflection reward for list of token ids
  */
  function claimReflectionRewardListCollectionAccount(uint256[] memory _tokenIds, address _contractAddress) external nonReentrant() returns (uint256) {
    uint256 reward = Bank(CONTRACTS.bank).claimReflectionRewardListCollectionAccount(_tokenIds, _contractAddress);

    if (IERC721(_contractAddress).supportsInterface(type(IERC721).interfaceId)) {
      for (uint256 i = 0; i < _tokenIds.length; i++) {
        // ownerOf(_tokenId) == msg.sender then continue, else revert transaction
        require(IERC721(_contractAddress).ownerOf(_tokenIds[i]) == msg.sender, "You are not the owner of one of the items");
      }

      // todo ensure this is a safe way to transfer funds
      ( bool success, ) = payable(msg.sender).call{ value: reward }("");
      require(success, "Collection commission reward transfer to user was unccessfull");
    } else {
      revert("Provided contract address is not valid");
    }
    emit onClaimRewards(msg.sender, reward, 'collection_reflection');
    return reward;
  }


  /** 
    *****************************************************
    **************** Monetary Functions *****************
    *****************************************************
  */
  /**
    * @dev Deposit into collection incentive vault
  */
  function depositIncentiveCollectionAccount(address _contractAddress) external nonReentrant() payable {
    /**
      * todo
      * why check if person depositing funds is the owner of the collection?
      * Allow anyone to deposit money, in any account? 
    */
    Bank(CONTRACTS.bank).updateCollectionIncentiveReward(_contractAddress, msg.value, true);
    BALANCE_SHEET.collectionIncentive += msg.value;
    emit onDepositCollectionIncentive(msg.sender, _contractAddress, msg.value);
  }

  /**
    * @dev Withdraw from collection incentive vault
  */
  function withdrawIncentiveCollectionAccount(address _contractAddress, uint256 _amount) external nonReentrant() {
    uint256 collectionId = CollectionItem(CONTRACTS.collectionItem).getCollectionForContract(_contractAddress);
    Collection.CollectionDS memory collection = CollectionItem(CONTRACTS.collectionItem).getCollection(collectionId);
    // address collectionOwner = CollectionItem(CONTRACTS.collectionItem).getOwnerOfCollection(collectionId);

    require(collection.owner == msg.sender, "You are not the owner of this collection");
    require(collection.ownerIncentiveAccess == true, "You do not have access to withdraw");

    Bank(CONTRACTS.bank).updateCollectionIncentiveReward(_contractAddress, _amount, false);
    BALANCE_SHEET.collectionIncentive -= _amount;

    // todo ensure this is a safe way to transfer funds
    ( bool success, ) = payable(msg.sender).call{ value: _amount }("");
    require(success, "Collection commission reward transfer to user was unccessfull");
    emit onWithdrawCollectionIncentive(msg.sender, _contractAddress, _amount);
  }

  /**
    * @dev Distrubute reward among all NFT holders in a given collection
  */
  function distributeRewardInCollection(uint256 _collectionId) external nonReentrant() payable {
    Collection.CollectionDS memory collection = CollectionItem(CONTRACTS.collectionItem).getCollection(_collectionId);
    require(collection.collectionType == Collection.COLLECTION_TYPE.verified, "Not a verified collection");

    Bank(CONTRACTS.bank).distributeCollectionReflectionReward(collection.contractAddress, collection.totalSupply, msg.value);
    BALANCE_SHEET.collectionReflection += msg.value;
    emit onDistributeRewardInCollection(_collectionId, msg.value);
  }

  /**
    * @dev Distrubute reward among given NFT holders in a given collection
  */
  function distributeRewardListInCollection(uint256 _collectionId, uint256[] memory _tokenIds) external nonReentrant() payable {
    Collection.CollectionDS memory collection = CollectionItem(CONTRACTS.collectionItem).getCollection(_collectionId);
    require(collection.collectionType == Collection.COLLECTION_TYPE.verified, "Not a verified collection");
    require(_tokenIds.length > 0, "Token id list must be greater than 0");
    require(_tokenIds.length <= collection.totalSupply, "Token id list must not exceed size of collection total supply");

    Bank(CONTRACTS.bank).distributeCollectionReflectionRewardList(collection.contractAddress, _tokenIds, msg.value);
    BALANCE_SHEET.collectionReflection += msg.value;
    emit onDistributeRewardInCollection(_collectionId, msg.value);
  }

  /**
    * @dev Deposit into marketplace incentive vault
  */
  function depositMarketplaceIncentiveVault() external nonReentrant() payable {
    BALANCE_SHEET.incentiveVault += msg.value;
    emit onDepositMarketplaceIncentive(msg.sender, msg.value);
  }


  /** 
    *****************************************************
    *************** Collection Functions ****************
    *****************************************************
  */
  /**
    * @dev Create local collection
  */
  function createLocalCollection(address _contractAddress) external onlyRole(ADMIN_ROLE) returns (uint256) {
    uint256 id = CollectionItem(CONTRACTS.collectionItem).createLocalCollection(_contractAddress, msg.sender);
    Bank(CONTRACTS.bank).addBank(msg.sender); // this is okay even if bank account already exists

    emit onCollectionCreate(msg.sender, _contractAddress, "local", id);
    return id;
  }

  /**
    * @dev Create verified collection
  */
  function createVerifiedCollection(
    address _contractAddress, uint256 _totalSupply, uint8 _reflection, uint8 _commission,
    address _owner, bool _ownerIncentiveAccess
  ) external returns (uint256) {
    uint256 id = CollectionItem(CONTRACTS.collectionItem).createVerifiedCollection(
      _contractAddress, _totalSupply, _reflection, _commission, _owner, _ownerIncentiveAccess
    );
    Bank(CONTRACTS.bank).addBank(_contractAddress); // this is okay even if bank account already exists
    Bank(CONTRACTS.bank).initReflectionVaultCollectionAccount(_contractAddress, _totalSupply);

    emit onCollectionCreate(msg.sender, _contractAddress, "verified", id);
    return id;
  }

  /**
    * @dev Create unvarivied collection
  */
  function createUnvariviedCollection() external onlyRole(ADMIN_ROLE) returns (uint256) {
    uint256 id = CollectionItem(CONTRACTS.collectionItem).createUnvariviedCollection(msg.sender);
    Bank(CONTRACTS.bank).addBank(msg.sender); // this is okay even if bank account already exists

    emit onCollectionCreate(msg.sender, address(0), "unvarivied", id);
    return id;
  }


  /** 
    *****************************************************
    ***************** Public Functions ******************
    *****************************************************
  */
  /**
    * @dev Version of implementation contract
  */
  function version() external pure virtual returns (string memory) {
      return 'v1';
  }
  /**
    * @dev Get contract balance sheet
  */
  function getBalanceSheet() external view returns (BalanceSheetDS memory) {
    return BALANCE_SHEET;
  }


  /** 
    *****************************************************
    ************** Expose Child Functions ***************
    *****************************************************
  */
  function getImplementation() external view returns (address) {
      return _getImplementation();
  }
  function getAdmin() external view returns (address) {
      return _getAdmin();
  }
  function getBeacon() external view returns (address) {
      return _getBeacon();
  }


  /** 
    *****************************************************
    ************** Nft Transfter Functions **************
    *****************************************************
  */
  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data
  ) external override returns (bytes4) {
    emit onERC721ReceivedEvent(_operator, _from, _tokenId, _data);
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.12 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import '../AvaxTradeNft.sol';
import "./Collection.sol";
import "./Item.sol";

import "hardhat/console.sol";


contract CollectionItem is Initializable, UUPSUpgradeable, AccessControlUpgradeable, Collection, Item {

  // Access Control
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  // modifiers
  modifier checkCollectionItem(uint256 _id) {
    require(_collectionItemExists(_id), "The collection item does not exist");
    _;
  }
  modifier checkCollectionItemId(uint256 _id, uint256 _itemId) {
    require(_collectionItemIdExists(_id, _itemId), "The collection item id does not exist");
    _;
  }

  // enums

  // data structures

  // state variables
  mapping(uint256 => uint256[]) private COLLECTION_ITEMS; // mapping collection id to list of item ids
  mapping(uint256 => bytes32) private COLLECTION_ROLES; // mapping collection id to collection role id

  // events
  event onActivation(uint256 indexed id, bool indexed active);
  event onCollectionUpdate(uint256 indexed id);
  event onCollectionRemove(uint256 indexed id);
  event onCollectionOwnerIncentiveAccess(uint256 indexed id);


  /**
    * @dev Check if collection item exists
  */
  function _collectionItemExists(uint256 _id) private view returns (bool) {
    if (COLLECTION_ITEMS[_id].length > 0) {
      return true;
    }
    return false;
  }

  /**
    * @dev Check if collection item id exists
    * todo is this redundant? do we really need this check?
  */
  function _collectionItemIdExists(uint256 _id, uint256 _itemId) private view returns (bool) {
    uint256[] memory  collectionItem = COLLECTION_ITEMS[_id];
    for (uint256 i = 0; i < collectionItem.length; i++) {
      if (collectionItem[i] == _itemId) {
        return true;
      }
    }
    return false;
  }

  /**
    * @dev Calculate percent change
  */
  function _calculatePercentChange(uint256 _value, uint8 _percent) private pure returns (uint256) {
    return (_value * _percent / 100);
  }


  function initialize(address _owner, address _admin) initializer public {
    // call parent classes
    __AccessControl_init();
    __Collection_init();
    __Item_init();

    // todo create 2 roles, instead of one
    //      ADMIN_ROLE = Admin (owner of AvaxTrade contract)
    //      OWNER_ROLE = AvaxTrade contract

    // set up admin role
    _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);

    // grant admin role to following accounts
    _setupRole(ADMIN_ROLE, _owner);
    _setupRole(ADMIN_ROLE, _admin);

    // create collections
    createUnvariviedCollection(_admin);
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function _authorizeUpgrade(address) internal override onlyRole(ADMIN_ROLE) {}


  /** 
    *****************************************************
    **************** Attribute Functions ****************
    *****************************************************
  */


  /** 
    *****************************************************
    ****************** Main Functions *******************
    *****************************************************
  */
  /**
    * @dev Add item to collection
  */
  function addItemToCollection(
    uint256 _tokenId, address _contractAddress, address _seller, address _buyer, uint256 _price
  ) public onlyRole(ADMIN_ROLE) returns (uint256) {
    uint256 collectionId = _getCollectionForContract(_contractAddress);
    if (collectionId == 0 || (collectionId > 0 && !_getCollectionActive(collectionId))) {
      // this means this is an unvarified item, so we will use the unvarified collection
      collectionId = UNVERIFIED_COLLECTION_ID;
    }

    uint8 commission = 0;
    address creator = address(0);
    COLLECTION_TYPE collectionType = _getCollectionType(collectionId);
    if (collectionType == COLLECTION_TYPE.local) {
      (creator, commission) = AvaxTradeNft(_contractAddress).getNftInfo(_tokenId);
    }

    uint256 itemId = _addItem(
                        collectionId,
                        _tokenId,
                        _contractAddress,
                        _seller,
                        _buyer,
                        _price,
                        commission,
                        creator
                      );
    _addItemIdInCollection(collectionId, itemId);
    return itemId;
  }

  /**
    * @dev Cancel item that is currently on sale
  */
  function cancelItemInCollection(uint256 _itemId) public onlyRole(ADMIN_ROLE){
    uint256 collectionId = _getItemCollectionId(_itemId);
    require(_collectionItemIdExists(collectionId, _itemId), "Collection or item does not exist");

    _deactivateItem(_itemId);
    _removeItemIdInCollection(collectionId, _itemId);
  }

  /**
    * @dev Mark item sold in collection
  */
  function markItemSoldInCollection(uint256 _itemId, address _buyer) public onlyRole(ADMIN_ROLE) {
    uint256 collectionId = _getItemCollectionId(_itemId);
    require(_collectionItemIdExists(collectionId, _itemId), "Collection or item does not exist");

    _markItemSold(_itemId);
    _updateItemBuyer(_itemId, _buyer);
    _removeItemIdInCollection(collectionId, _itemId);
  }

  /**
    * @dev Create local collection
  */
  function createLocalCollection(address _contractAddress, address _owner) public onlyRole(ADMIN_ROLE) returns (uint256) {
    uint256 id = _createLocalCollection(_contractAddress, _owner);

    // create collection role
    bytes memory encodedId = abi.encodePacked(id);
    COLLECTION_ROLES[id] = keccak256(encodedId);
    _setRoleAdmin(COLLECTION_ROLES[id], ADMIN_ROLE);
    _setupRole(COLLECTION_ROLES[id], _owner);

    return id;
  }

  /**
    * @dev Create verified collection
  */
  function createVerifiedCollection(
    address _contractAddress, uint256 _totalSupply, uint8 _reflection, uint8 _commission,
    address _owner, bool _ownerIncentiveAccess
  ) public onlyRole(ADMIN_ROLE) returns (uint256) {
    uint256 id = _createVerifiedCollection(_contractAddress, _totalSupply, _reflection, _commission, _owner, _ownerIncentiveAccess);

    // create collection role
    bytes memory encodedId = abi.encodePacked(id);
    COLLECTION_ROLES[id] = keccak256(encodedId);
    _setRoleAdmin(COLLECTION_ROLES[id], ADMIN_ROLE);
    _setupRole(COLLECTION_ROLES[id], _owner);

    return id;
  }

  /**
    * @dev Create unvarivied collection
  */
  function createUnvariviedCollection(address _owner) public onlyRole(ADMIN_ROLE) returns (uint256) {
    uint256 id = _createUnvariviedCollection(_owner);

    // create collection role
    bytes memory encodedId = abi.encodePacked(id);
    COLLECTION_ROLES[id] = keccak256(encodedId);
    _setRoleAdmin(COLLECTION_ROLES[id], ADMIN_ROLE);
    _setupRole(COLLECTION_ROLES[id], _owner);

    return id;
  }

  /**
    * @dev Update collection
  */
  function updateCollection(
    uint256 _id, uint8 _reflection, uint8 _commission,
    uint8 _incentive, address _owner
  ) external onlyRole(COLLECTION_ROLES[_id]) {
    _updateCollection(_id, _reflection, _commission, _incentive, _owner);
    emit onCollectionUpdate(_id);
  }

  /**
    * @dev Disable owner access to collectiton incentive pool
  */
  function disableCollectionOwnerIncentiveAccess(uint256 _id) external onlyRole(COLLECTION_ROLES[_id]) {
    _updateCollectionOwnerIncentiveAccess(_id, false);
    emit onCollectionOwnerIncentiveAccess(_id);
  }

  /**
    * @dev Activate collection
  */
  function activateCollection(uint256 _id) external onlyRole(ADMIN_ROLE) {
    _activateCollection(_id);
    emit onActivation(_id, _getCollectionActive(_id));
  }

  /**
    * @dev Deactivate collection
  */
  function deactivateCollection(uint256 _id) external onlyRole(ADMIN_ROLE) {
    _deactivateCollection(_id);
    emit onActivation(_id, _getCollectionActive(_id));
  }

  /**
    * @dev Remove collection
  */
  function removeCollection(uint256 _id) external onlyRole(ADMIN_ROLE) {
    _removeCollection(_id);
    emit onCollectionRemove(_id);
  }

  /**
    * @dev Deactivate item
  */
  function activateItem(uint256 _itemId) external onlyRole(ADMIN_ROLE) {
    return _activateItem(_itemId);
  }

  /**
    * @dev Activate item
  */
  function deactivateItem(uint256 _itemId) external onlyRole(ADMIN_ROLE) {
    return _deactivateItem(_itemId);
  }


  /** 
    *****************************************************
    *********** COLLECTION_ITEMS Functions *************
    *****************************************************
  */
  /**
    * @dev Add a new collection id (if necessary) and add item id to the array
    * @custom:type private
  */
  function _addItemIdInCollection(uint256 _id, uint256 _itemId) public {
    COLLECTION_ITEMS[_id].push(_itemId);
  }

  /**
    * @dev Get item ids for the given collection
  */
  function getItemIdsInCollection(uint256 _id) public view returns (uint256[] memory) {
    return COLLECTION_ITEMS[_id];
  }

  /**
    * @dev Remove an item in collection
    * @custom:type private
  */
  function _removeItemIdInCollection(uint256 _id, uint256 _itemId) public {
    uint256 arrLength = COLLECTION_ITEMS[_id].length - 1;
    uint256[] memory data = new uint256[](arrLength);
    uint8 dataCounter = 0;
    for (uint256 i = 0; i < COLLECTION_ITEMS[_id].length; i++) {
      if (COLLECTION_ITEMS[_id][i] != _itemId) {
        data[dataCounter] = COLLECTION_ITEMS[_id][i];
        dataCounter++;
      }
    }
    COLLECTION_ITEMS[_id] = data;
  }

  /**
    * @dev Remove the collection item
    * @custom:type private
  */
  function _removeCollectionItem(uint256 _id) public {
    delete COLLECTION_ITEMS[_id];
  }


  /** 
    *****************************************************
    ************* Public Getter Functions ***************
    *****************************************************
  */

  /**
    * @dev Get item id given token id and contract address
  */
  function getItemId(uint256 _tokenId, address _contractAddress, address _owner) public view returns (uint256) {
    uint256[] memory itemIds = _getItemsForOwner(_owner);
    uint256 itemId = 0;
    for (uint256 i = 0; i < itemIds.length; i++) {
      if (_getItemTokenId(itemIds[i]) == _tokenId && _getItemContractAddress(itemIds[i]) == _contractAddress) {
        itemId = itemIds[i];
      }
    }
    require(_doesItemExist(itemId), "The item does not exist");
    require(_isSellerTheOwner(itemId, _owner), "This user is not the owner of the item");
    return itemId;
  }

  /**
    * @dev Get item id given token id and contract address
  */
  function getItemOfOwner(uint256 _tokenId, address _contractAddress, address _owner) public view returns (ItemDS memory) {
    uint256 itemId = getItemId(_tokenId, _contractAddress, _owner);
    return _getItem(itemId);
  }

  /**
    * @dev Get all item ids in collection
  */
  function getItemsInCollection(uint256 _id) public view checkCollection(_id) returns (ItemDS[] memory) {
    uint256[] memory itemsIds = getItemIdsInCollection(_id);
    return _getItems(itemsIds);
  }

  /**
    * @dev Get owner of collection
  */
  function getOwnerOfCollection(uint256 _id) public view checkCollection(_id) returns (address) {
    return _getCollectionOwner(_id);
  }

  /**
    * @dev Get owner of collection for this item
  */
  function getOwnerOfItemCollection(uint256 _itemId) public view returns (address) {
    uint256 collectionId = _getItemCollectionId(_itemId);
    _doesCollectionExist(collectionId);
    require(_collectionItemIdExists(collectionId, _itemId), "Collection or item does not exist");

    return _getCollectionOwner(collectionId);
  }

  /**
    * @dev Get creator of this item
  */
  function getCreatorOfItem(uint256 _itemId) public view checkItem(_itemId) returns (address) {
    return _getItemCreator(_itemId);
  }


  /** 
    *****************************************************
    ************** Expose Child Functions ***************
    *****************************************************
  */

  // Collection.sol
  /**
    * @dev Get collection
  */
  function getCollection(uint256 _id) external view returns (CollectionDS memory) {
    return _getCollection(_id);
  }

  /**
    * @dev Get collection
  */
  function getCollectionType(uint256 _id) external view returns (COLLECTION_TYPE) {
    return _getCollectionType(_id);
  }

  /**
    * @dev Get collection
  */
  function getCollectionIncentive(uint256 _id) external view returns (uint8) {
    return _getCollectionIncentive(_id);
  }

  /**
    * @dev Get collection commission
  */
  function getCollectionCommission(uint256 _id) external view returns (uint8) {
    return _getCollectionCommission(_id);
  }

  /**
    * @dev Get collection reflection
  */
  function getCollectionReflection(uint256 _id) external view returns (uint8) {
    return _getCollectionReflection(_id);
  }

  /**
    * @dev Get active collection ids
  */
  function getActiveCollectionIds() external view returns (uint256[] memory) {
    return _getActiveCollectionIds();
  }

  /**
    * @dev Get local collection ids
  */
  function getLocalCollectionIds() external view returns (uint256[] memory) {
    return _getLocalCollectionIds();
  }

  /**
    * @dev Get verified collection ids
  */
  function getVerifiedCollectionIds() external view returns (uint256[] memory) {
    return _getVerifiedCollectionIds();
  }

  /**
    * @dev Get unverified collection ids
  */
  function getUnverifiedCollectionIds() external view returns (uint256[] memory) {
    return _getUnverifiedCollectionIds();
  }

  /**
    * @dev Get collection ids
  */
  function getCollectionIds() external view returns (CollectionIdDS memory) {
    return _getCollectionIds();
  }

  /**
    * @dev Get collections for owner
  */
  function getCollectionsForOwner(address _owner) external view returns (uint256[] memory) {
    return _getCollectionsForOwner(_owner);
  }

  /**
    * @dev Get collection id for given contract address
  */
  function getCollectionForContract(address _contract) external view returns (uint256) {
    return _getCollectionForContract(_contract);
  }


  // Item.sol
  /**
    * @dev Get item
  */
  function getItem(uint256 _itemId) external view returns (ItemDS memory) {
    return _getItem(_itemId);
  }

  /**
    * @dev Get items
  */
  function getItems(uint256[] memory _itemIds) external view returns (ItemDS[] memory) {
    return _getItems(_itemIds);
  }

  /**
    * @dev Get all items
  */
  function getAllItems() external view returns (ItemDS[] memory) {
    return _getAllItems();
  }

  /**
    * @dev Get items for owner
  */
  function getItemsForOwner() external view returns (uint256[] memory) {
    return _getItemsForOwner(msg.sender);
  }

  /**
    * @dev Get item commission
  */
  function getItemCommission(uint256 _itemId) external view returns (uint8) { 
    return _getItemCommission(_itemId);
  }

  /**
    * @dev Get item collection id
  */
  function getItemCollectionId(uint256 _itemId) external view returns (uint256) { 
    return _getItemCollectionId(_itemId);
  }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.12 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';

import "./UserAccount.sol";
import "./CollectionAccount.sol";
import "./Vault.sol";

import "hardhat/console.sol";


contract Bank is Initializable, UUPSUpgradeable, AccessControlUpgradeable, UserAccount, CollectionAccount, Vault {

  // Access Control
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  // modifiers
  modifier checkBank(address _id) {
    require(_bankExists(_id), "The bank for this user does not exist");
    _;
  }

  // data structures
  struct BankDS {
    address id; // owner of this bank account
    UserAccountDS user; // user account
    CollectionAccountReturnDS collection; // collection account
    VaultDS vault; // bank vault
  }

  address[] private BANK_OWNERS; // current list of bank holders


  /**
    * @dev Check if bank exists
  */
  function _bankExists(address _id) private view returns (bool) {
    for (uint256 i = 0; i < BANK_OWNERS.length; i++) {
      if (BANK_OWNERS[i] == _id) {
        return true;
      }
    }
    return false;
  }


  function initialize(address _owner) initializer public {
    // call parent classes
    __AccessControl_init();

    // set up admin role
    _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);

    // grant admin role to following account (parent contract)
    _setupRole(ADMIN_ROLE, _owner);
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function _authorizeUpgrade(address) internal override onlyRole(ADMIN_ROLE) {}


  /** 
    *****************************************************
    **************** Attribute Functions ****************
    *****************************************************
  */


  /** 
    *****************************************************
    ****************** Main Functions *******************
    *****************************************************
  */
  /**
    * @dev Add bank
  */
  function addBank(address _id) public onlyRole(ADMIN_ROLE) {
    if (isBankOwnerUnique(_id)) {
      _addBankOwner(_id);
      _addUserAccount(_id);
      _addCollectionAccount(_id);
      _addVault(_id);
    }
  }

  /**
    * @dev Get bank for given user
  */
  function getBank(address _id) public view returns (BankDS memory) {
    BankDS memory bank = BankDS({
      id: _id,
      user: _getUserAccount(_id),
      collection: _getCollectionAccount(_id),
      vault: _getVault(_id)
    });
    return bank;
  }

  /**
    * @dev Get banks for list of users
  */
  function getBanks(address[] memory _ids) public view returns (BankDS[] memory) {
    uint256 arrLength = _ids.length;
    BankDS[] memory banks = new BankDS[](arrLength);
    for (uint256 i = 0; i < arrLength; i++) {
      address id = _ids[i];
      // ensure bank id is valid. If not, kill transaction
      require(_bankExists(id), "A user in the list does not own a bank");
      BankDS memory bank = BankDS({
        id: id,
        user: _getUserAccount(id),
        collection: _getCollectionAccount(id),
        vault: _getVault(id)
      });
      banks[i] = bank;
    }
    return banks;
  }

  /**
    * @dev Update bank 
  */
  function updateBank(
    address _id, uint256 _general, uint256 _nftCommission, uint256 _collectionCommission,
    uint256[] memory _reflectionVault, uint256 _incentiveVault, uint256 _balance
  ) public onlyRole(ADMIN_ROLE) {
    _updateUserAccount(_id, _general, _nftCommission, _collectionCommission);
    _updateCollectionAccount(_id, _reflectionVault, _incentiveVault);
    _updateVault(_id, _balance);
  }

  /**
    * @dev Nullify bank
    * @custom:type private
  */
  function _nullifyBank(address _id) public {
    _nullifyUserAccount(_id);
    _nullifyCollectionAccount(_id);
    _nullifyVault(_id);
  }

  /**
    * @dev Remove bank
    * @custom:type private
  */
  function _removeBank(address _id) public {
    _removeBankOwner(_id);
    _removeUserAccount(_id);
    _removeCollectionAccount(_id);
    _removeVault(_id);
  }


  /** 
    *****************************************************
    **************** Monetary Functions *****************
    *****************************************************
  */

  /**
    * @dev Increase account balance by given amounts
  */
  function incrementUserAccount(
    address _id, uint256 _general, uint256 _nftCommission, uint256 _collectionCommission
  ) external onlyRole(ADMIN_ROLE) {
    addBank(_id); // create if bank account does not exist
    _incrementUserAccount(_id, _general, _nftCommission, _collectionCommission);
  }

  /**
    * @dev Increase collection balance by given amounts
  */
  function incrementCollectionAccount(
    address _id, uint256 _rewardPerItem, uint256 _incentiveVault
  ) external onlyRole(ADMIN_ROLE) {
    addBank(_id); // create if bank account does not exist
    _incrementCollectionAccount(_id, _rewardPerItem, _incentiveVault);
  }

  /**
    * @dev Claim account general reward for this user
  */
  function claimGeneralRewardUserAccount(address _owner) external onlyRole(ADMIN_ROLE) returns (uint256) {
    uint256 reward = _getGeneralUserAccount(_owner);
    _updateGeneralUserAccount(_owner, 0);
    return reward;
  }

  /**
    * @dev Claim account nft commission reward for this user
  */
  function claimNftCommissionRewardUserAccount(address _owner) external onlyRole(ADMIN_ROLE) returns (uint256) {
    uint256 reward = _getNftCommissionUserAccount(_owner);
    _updateNftCommissionUserAccount(_owner, 0);
    return reward;
  }

  /**
    * @dev Claim account collection commission reward for this user
  */
  function claimCollectionCommissionRewardUserAccount(address _owner) external onlyRole(ADMIN_ROLE) returns (uint256) {
    uint256 reward = _getCollectionCommissionUserAccount(_owner);
    _updateCollectionCommissionUserAccount(_owner, 0);
    return reward;
  }

  /**
    * @dev Claim collection reflection reward for this token id
  */
  function claimReflectionRewardCollectionAccount(uint256 _tokenId, address _contractAddress) external onlyRole(ADMIN_ROLE) returns (uint256) {
    require(_tokenId > 0, "Bank: Invalid token id provided");

    uint256 reward = _getReflectionVaultIndexCollectionAccount(_contractAddress, _tokenId);
    _updateReflectionVaultIndexCollectionAccount(_contractAddress, _tokenId, 0);
    return reward;
  }

  /**
    * @dev Claim collection reflection reward for list of token ids
  */
  function claimReflectionRewardListCollectionAccount(uint256[] memory _tokenIds, address _contractAddress) external onlyRole(ADMIN_ROLE) returns (uint256) {
    require(_tokenIds.length > 0, "Bank: Token id list is empty");

    uint256 reward = 0;
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      require(_tokenIds[i] > 0, "Bank: Invalid token id provided");
      reward += _getReflectionVaultIndexCollectionAccount(_contractAddress, _tokenIds[i]);
      _updateReflectionVaultIndexCollectionAccount(_contractAddress, _tokenIds[i], 0);
    }
    return reward;
  }

  /**
    * @dev Distribute collection reflection reward between all token id's
  */
  function distributeCollectionReflectionReward(address _contractAddress, uint256 _totalSupply, uint256 _reflectionReward) external onlyRole(ADMIN_ROLE) {
    addBank(_contractAddress); // create if bank account does not exist
    uint256 reflectionRewardPerItem = _reflectionReward / _totalSupply;
    _increaseReflectionVaultCollectionAccount(_contractAddress, reflectionRewardPerItem);
  }

  /**
    * @dev Distribute collection reflection reward between given token id's
  */
  function distributeCollectionReflectionRewardList(address _contractAddress, uint256[] memory _tokenIds, uint256 _reflectionReward) external onlyRole(ADMIN_ROLE) {
    addBank(_contractAddress); // create if bank account does not exist
    uint256 reflectionRewardPerItem = _reflectionReward / _tokenIds.length;
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      _increaseReflectionVaultForTokensCollectionAccount(_contractAddress, _tokenIds[i], reflectionRewardPerItem);
    }
  }

  /**
    * @dev Update collection incentive reward
  */
  function updateCollectionIncentiveReward(address _contractAddress, uint256 _value, bool _increase) external onlyRole(ADMIN_ROLE) returns (uint256) {
    addBank(_contractAddress); // create if bank account does not exist
    uint256 incentiveVault = _getIncentiveVaultCollectionAccount(_contractAddress);
    if (_increase) {
      uint256 newIncentiveVault = incentiveVault + _value;
      _updateIncentiveVaultCollectionAccount(_contractAddress, newIncentiveVault);
    } else {
      require(incentiveVault >= _value, "Bank: Withdraw amount must be less than or equal to vault balance");
      uint256 newIncentiveVault = incentiveVault - _value;
      _updateIncentiveVaultCollectionAccount(_contractAddress, newIncentiveVault);
    }

    return _getIncentiveVaultCollectionAccount(_contractAddress);
  }

  /**
    * @dev Nullify collection incentive reward
  */
  function nullifyCollectionIncentiveReward(address _contractAddress) external onlyRole(ADMIN_ROLE) returns (uint256) {
    addBank(_contractAddress); // create if bank account does not exist
    _updateIncentiveVaultCollectionAccount(_contractAddress, 0);

    return _getIncentiveVaultCollectionAccount(_contractAddress);
  }


  /** 
    *****************************************************
    ************** BANK_OWNERS Functions ****************
    *****************************************************
  */
  /**
    * @dev Add bank owner
    * @custom:type private
  */
  function _addBankOwner(address _id) public {
    BANK_OWNERS.push(_id);
  }

  /**
    * @dev Get bank owners
  */
  function getBankOwners() public view returns (address[] memory) {
    return BANK_OWNERS;
  }

  /**
    * @dev Does bank owner already exist in the mapping?
  */
  function isBankOwnerUnique(address _id) public view returns (bool) {
    for (uint256 i = 0; i < BANK_OWNERS.length; i++) {
      if (BANK_OWNERS[i] == _id) {
        return false;
      }
    }
    return true;
  }

  /**
    * @dev Remove bank owner
    * @custom:type private
  */
  function _removeBankOwner(address _id) public {
    uint256 arrLength = BANK_OWNERS.length - 1;
    address[] memory data = new address[](arrLength);
    uint8 dataCounter = 0;
    for (uint256 i = 0; i < BANK_OWNERS.length; i++) {
      if (BANK_OWNERS[i] != _id) {
        data[dataCounter] = BANK_OWNERS[i];
        dataCounter++;
      }
    }
    BANK_OWNERS = data;
  }


  /** 
    *****************************************************
    ************** Expose Child Functions ***************
    *****************************************************
  */

  // UserAccount.sol
  /**
    * @dev Get account of user
  */
  function getUserAccount(address _id) external view returns (UserAccountDS memory) {
    return _getUserAccount(_id);
  }
  /**
    * @dev Get accounts for list of users
  */
  function getUserAccounts(address[] memory _ids) external view returns (UserAccountDS[] memory) {
    return _getUserAccounts(_ids);
  }

  /**
    * @dev Get general user account
  */
  function getGeneralUserAccount(address _id) external view returns (uint256) {
    return _getGeneralUserAccount(_id);
  }

  /**
    * @dev Get nft commission user account
  */
  function getNftCommissionUserAccount(address _id) external view returns (uint256) {
    return _getNftCommissionUserAccount(_id);
  }

  /**
    * @dev Get collection commission user account
  */
  function getCollectionCommissionUserAccount(address _id) external view returns (uint256) {
    return _getCollectionCommissionUserAccount(_id);
  }

  // CollectionAccount.sol
  /**
    * @dev Initialize a collection reflection vault for the given collection
  */
  function initReflectionVaultCollectionAccount(address _id, uint256 _totalSupply) external onlyRole(ADMIN_ROLE) {
    addBank(_id); // create if bank account does not exist
    return _initReflectionVaultCollectionAccount(_id, _totalSupply);
  }

  /**
    * @dev Get account of collection
  */
  function getCollectionAccount(address _id) external view returns (CollectionAccountReturnDS memory) {
    return _getCollectionAccount(_id);
  }

  /**
    * @dev Get collections for list of users
  */
  function getCollectionAccounts(address[] memory _ids) external view returns (CollectionAccountReturnDS[] memory) {
    return _getCollectionAccounts(_ids);
  }

  /**
    * @dev Get collection reflection vault
  */
  function getReflectionVaultCollectionAccount(address _id) external view returns (uint256[] memory) {
    return _getReflectionVaultCollectionAccount(_id);
  }

  /**
    * @dev Get collection reflection reward for this token id
  */
  function getReflectionRewardCollectionAccount(uint256 _tokenId, address _contractAddress) external view returns (uint256) {
    return _getReflectionVaultIndexCollectionAccount(_contractAddress, _tokenId);
  }

  /**
    * @dev Get collection incentive vault
  */
  function getIncentiveVaultCollectionAccount(address _id) external view returns (uint256) {
    return _getIncentiveVaultCollectionAccount(_id);
  }

  // Vault.sol
  /**
    * @dev Get vault of user
  */
  function getVault(address _id) external view returns (VaultDS memory) {
    return _getVault(_id);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.12 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./Direct.sol";
import "./Immediate.sol";
import "./Auction.sol";

import "hardhat/console.sol";


contract Sale is Initializable, UUPSUpgradeable, AccessControlUpgradeable, Direct, Immediate, Auction {

  // Access Control
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  // modifiers
  modifier checkSale(uint256 _id) {
    require(_saleExists(_id), "The sale does not exist");
    _;
  }

  // enums
  // @todo MarketItem has a SALE_TYPE enum. Either rename that one or remove it from there
  enum SALE_TYPE { direct, immediate, auction }

  // data structures
  struct SaleUserDS {
    address id; // owner of these sale items
    uint256[] direct; // direct sales
    uint256[] immediate; // immediate sales
    uint256[] auction; // auction sales
  }

  struct SaleTotalDS {
    uint256[] direct;
    uint256[] immediate;
    uint256[] auction;
  }

  struct SaleDS {
    uint256 id; // unique item id
    SALE_TYPE saleType; // type of the sale for the item
  }

  uint256[] private SALE_ITEMS; // current list of total items on sale
  mapping(uint256 => SaleDS) private SALES; // mapping item id to items on sale


  /**
    * @dev Check if sale exists
  */
  function _saleExists(uint256 _id) private view returns (bool) {
    if (SALES[_id].id != 0) {
      return true;
    }
    return false;
  }


  function initialize(address _owner, address _admin) initializer public {
    // call parent classes
    __AccessControl_init();

    // set up admin role
    _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);

    // grant admin role to following accounts
    _setupRole(ADMIN_ROLE, _owner);
    _setupRole(ADMIN_ROLE, _admin);
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function _authorizeUpgrade(address) internal override onlyRole(ADMIN_ROLE) {}


  /** 
    *****************************************************
    **************** Attribute Functions ****************
    *****************************************************
  */


  /** 
    *****************************************************
    ****************** Main Functions *******************
    *****************************************************
  */
  /**
    * @dev Create empty sale
  */
  function createEmptySale(uint256 _id) public onlyRole(ADMIN_ROLE) {
    require(!_saleExists(_id), "Sale already exists");
    SALES[_id].id = _id;
    _addTotalSaleItemId(_id);
  }

  /**
    * @dev Create direct sale
  */
  function createSaleDirect(uint256 _id, address _owner) public onlyRole(ADMIN_ROLE) {
    require(!_saleExists(_id), "Sale already exists - Direct");
    SALES[_id] = SaleDS({
      id: _id,
      saleType: SALE_TYPE.direct
    });

    _addTotalSaleItemId(_id);
    _createDirectSale(_owner, _id);
  }

  /**
    * @dev Create immediate sale
  */
  function createSaleImmediate(uint256 _id, address _owner) public onlyRole(ADMIN_ROLE) {
    require(!_saleExists(_id), "Sale already exists - Immediate");
    SALES[_id] = SaleDS({
      id: _id,
      saleType: SALE_TYPE.immediate
    });

    _addTotalSaleItemId(_id);
    _createImmediateSale(_owner, _id);
  }

  /**
    * @dev Create auction sale
  */
  function createSaleAuction(uint256 _id, address _owner) public onlyRole(ADMIN_ROLE) {
    require(!_saleExists(_id), "Sale already exists - Auction");
    SALES[_id] = SaleDS({
      id: _id,
      saleType: SALE_TYPE.auction
    });

    _addTotalSaleItemId(_id);
    _createAuctionSale(_owner, _id);
  }

  /**
    * @dev Create sale
  */
  function createSale(uint256 _id, address _owner, SALE_TYPE _saleType) public onlyRole(ADMIN_ROLE) {
    require(!_saleExists(_id), "Sale already exists");
    if (_saleType == SALE_TYPE.direct) {
      createSaleDirect(_id, _owner);
    } else if (_saleType == SALE_TYPE.immediate) {
      createSaleImmediate(_id, _owner);
    } else if (_saleType == SALE_TYPE.auction) {
      createSaleAuction(_id, _owner);
    }
  }

  /**
    * @dev Get sale
  */
  function getSale(uint256 _id) public view checkSale(_id) returns (SaleDS memory) {
    return SALES[_id];
  }

  /**
    * @dev Is direct sale valid
  */
  function isDirectSaleValid(uint256 _id, address _owner) public view checkSale(_id) returns (bool) {
    return _doesDirectSaleItemIdExists(_owner, _id);
  } 

  /**
    * @dev Is immediate sale valid
  */
  function isImmediateSaleValid(uint256 _id, address _owner) public view checkSale(_id) returns (bool) {
    return _doesImmediateSaleItemIdExists(_owner, _id);
  }

  /**
    * @dev Is auction sale valid
  */
  function isAuctionSaleValid(uint256 _id, address _owner) public view checkSale(_id) returns (bool) {
    return _doesAuctionSaleItemIdExists(_owner, _id);
  }

  /**
    * @dev Is sale valid
  */
  function isSaleValid(uint256 _id) public view returns (bool) {
    return _saleExists(_id);
  }

  /**
    * @dev Get all direct sales
  */
  function getAllDirectSales() public view returns (uint256[] memory) {
    return _getTotalDirectSaleItemIds();
  }

  /**
    * @dev Get all immediate sales
  */
  function getAllImmediateSales() public view returns (uint256[] memory) {
    return _getTotalImmediateSaleItemIds();
  }

  /**
    * @dev Get all auction sales
  */
  function getAllAuctionSales() public view returns (uint256[] memory) {
    return _getTotalAuctionSaleItemIds();
  }

  /**
    * @dev Get all sales
  */
  function getAllSales() public view returns (SaleTotalDS memory) {
    SaleTotalDS memory sale = SaleTotalDS({
      direct: _getTotalDirectSaleItemIds(),
      immediate: _getTotalImmediateSaleItemIds(),
      auction: _getTotalAuctionSaleItemIds()
    });
    return sale;
  }

  /**
    * @dev Get direct sales for user
  */
  function getDirectSalesForUser(address _id) public view returns (uint256[] memory) {
    return _getDirectSaleItemIds(_id);
  }

  /**
    * @dev Get immediate sales for user
  */
  function getImmediateSalesForUser(address _id) public view returns (uint256[] memory) {
    return _getImmediateSaleItemIds(_id);
  }

  /**
    * @dev Get auction sales for user
  */
  function getAuctionSalesForUser(address _id) public view returns (uint256[] memory) {
    return _getAuctionSaleItemIds(_id);
  }

  /**
    * @dev Get sales for user
  */
  function getSalesForUser(address _id) public view returns (SaleUserDS memory) {
    SaleUserDS memory sale = SaleUserDS({
      id: _id,
      direct: _getDirectSaleItemIds(_id),
      immediate: _getImmediateSaleItemIds(_id),
      auction: _getAuctionSaleItemIds(_id)
    });
    return sale;
  }

  /**
    * @dev Get sales for users
  */
  function getSalesForUsers(address[] memory _ids) public view returns (SaleUserDS[] memory) {
    uint256 arrLength = _ids.length;
    SaleUserDS[] memory sales = new SaleUserDS[](arrLength);
    for (uint256 i = 0; i < arrLength; i++) {
      address id = _ids[i];
      SaleUserDS memory sale = SaleUserDS({
        id: id,
        direct: _getDirectSaleItemIds(id),
        immediate: _getImmediateSaleItemIds(id),
        auction: _getAuctionSaleItemIds(id)
    });
      sales[i] = sale;
    }
    return sales;
  }

  /**
    * @dev Remove sale for user
    * @custom:type private
  */
  function _removeSale(uint256 _id, address _owner) public checkSale(_id) {
    SALE_TYPE saleType = SALES[_id].saleType;
    if (saleType == SALE_TYPE.direct) {
      _removeDirectSale(_owner, _id);
    } else if (saleType == SALE_TYPE.immediate) {
      _removeImmediateSale(_owner, _id);
    } else if (saleType == SALE_TYPE.auction) {
      _removeAuctionSale(_owner, _id);
    }
    _removeTotalSaleItemId(_id);
    delete SALES[_id];
  }


  /** 
    *****************************************************
    ************* SALE_ITEMS Functions ***************
    *****************************************************
  */
  /**
    * @dev Add total sale item
    * @custom:type private
  */
  function _addTotalSaleItemId(uint256 _id) public {
    SALE_ITEMS.push(_id);
  }

  /**
    * @dev Get total sale item ids
  */
  function getTotalSaleItemIds() public view returns (uint256[] memory) {
    return SALE_ITEMS;
  }

  /**
    * @dev Remove total sale item id
    * @custom:type private
  */
  function _removeTotalSaleItemId(uint256 _id) public checkSale(_id) {
    uint256 arrLength = SALE_ITEMS.length - 1;
    uint256[] memory data = new uint256[](arrLength);
    uint8 dataCounter = 0;
    for (uint256 i = 0; i < SALE_ITEMS.length; i++) {
      if (SALE_ITEMS[i] != _id) {
        data[dataCounter] = SALE_ITEMS[i];
        dataCounter++;
      }
    }
    SALE_ITEMS = data;
  }


  /** 
    *****************************************************
    ***************** Public Functions ******************
    *****************************************************
  */

}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

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
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.12 <0.9.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import "hardhat/console.sol";

// "aoun1","AUN","ipfs://QmctnsCiZfT3n4x7xWbzgVafYCryVqjnR4RqcYizKpPwik/"

contract AvaxTradeNft is ERC721Enumerable, Ownable {
  using Strings for uint256;

  // data structures
  struct ArtistDS {
    uint256 id; // token id
    address artist; // creator of this nft
    uint8 commission; // in percentage
    string cid; // unique identifier for tokenUri
  }

  // state variables
  string private BASE_URI;
  string private BASE_EXTENSION = '.json';
  uint256 private COST = 0.0 ether;
  uint256 private MAX_SUPPLY = type(uint256).max;
  bool private PAUSED = false;

  // events
  event onNftMint(address owner, uint256 tokenId);


  mapping(uint256 => ArtistDS) private ARTIST; // mapping token id to ArtistDS
  mapping(address => uint256[]) private ARTIST_NFT_LIST; // list of token ids for a user

  constructor( string memory _name, string memory _symbol, string memory _initBaseURI) ERC721(_name, _symbol) {
    setBaseUri(_initBaseURI);
  }


  // private / internal methods
  function _baseURI() internal view virtual override returns (string memory) {
    return BASE_URI;
  }

  function _getBaseExtension() private view returns (string memory) {
    return BASE_EXTENSION;
  }


  // public methods
  function getCost() public view returns (uint256) {
    return COST;
  }

  function getMaxSupply() public view returns (uint256) {
    return MAX_SUPPLY;
  }

  function isContractPaused() public view returns (bool) {
    return PAUSED;
  }

  // todo no need for address `_to`. use msg.sender
  function mint(uint8 _commission, string memory _cid) public payable {
    require(!PAUSED, 'The contract is paused, can not mint');
    require(totalSupply() + 1 <= MAX_SUPPLY, 'Already reached max mint amount');
    require(msg.value >= COST, 'Not enough funds to mint');

    ARTIST[totalSupply() + 1] = ArtistDS({
      id: totalSupply() + 1,
      artist: msg.sender,
      commission: _commission,
      cid: _cid
    });
    ARTIST_NFT_LIST[msg.sender].push(totalSupply() + 1);

    _safeMint(msg.sender, totalSupply() + 1);

    emit onNftMint(msg.sender, totalSupply());
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
      ? string(abi.encodePacked(currentBaseURI, ARTIST[_tokenId].cid))
      : '';
  }

  function getNftArtist(uint256 _tokenId) public view returns (address) {
    return ARTIST[_tokenId].artist;
  }

  function getNftCommission(uint256 _tokenId) public view returns (uint8) {
    return ARTIST[_tokenId].commission;
  }

  function getNftInfo(uint256 _tokenId) public view returns (address, uint8) {
    return (ARTIST[_tokenId].artist, ARTIST[_tokenId].commission);
  }

  function getArtistNfts(address _artist) public view returns (uint256[] memory) {
    return ARTIST_NFT_LIST[_artist];
  }


  // owner only methods
  function setBaseUri(string memory _baseUri) public onlyOwner() {
    BASE_URI = _baseUri;
  }

  function setBaseExtension(string memory _baseExtension) public onlyOwner() {
    BASE_EXTENSION = _baseExtension;
  }

  function setCost(uint256 _cost) public onlyOwner() {
    COST = _cost;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner() {
    MAX_SUPPLY = _maxSupply;
  }

  function setContractPauseState(bool _paused) public onlyOwner() {
    PAUSED = _paused;
  }

  function withdraw() public payable onlyOwner() {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.12 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";

import "hardhat/console.sol";


contract Collection {
  using Counters for Counters.Counter;

  // modifiers
  modifier checkCollection(uint256 _id) {
    require(_collectionExists(_id), "The collection does not exist");
    _;
  }
  modifier onlyCollectionOwner(uint256 _id, address _owner) {
    require(_isCollectionOwner(_id, _owner), "User is not the owner of this collection");
    _;
  }

  /**
    * Note All calculations using percentages will truncate any decimals.
    * Instead whole numbers will be used.
    *
    * Examples: number = (num * perVar / 100);
    *   - 2% of 100 = 2
    *   - 2% of 75 = 1
    *   - 2% of 50 = 1
    *   - 2% of 20 = 0
  */

  // enums
  enum COLLECTION_TYPE { local, verified, unverified }

  // data structures
  struct CollectionDS {
    uint256 id; // unique collection id
    address contractAddress; // contract address of the collection
    uint256 totalSupply; // total supply of items in this collection
    uint8 reflection; // in percentage
    uint8 commission; // in percentage
    uint8 incentive; // in percentage
    address owner; // owner of the collection
    COLLECTION_TYPE collectionType; // type of the collection
    bool ownerIncentiveAccess; // whether owner of the collection can withdraw from incentive fund or not
    bool active;
  }
  struct CollectionIdDS {
    uint256[] active;
    uint256[] local;
    uint256[] verified;
    uint256[] unverified;
  }

  // state variables

  /**
    * @dev We use the same COLLECTION_ID_POINTER to track the size of the collection, and also
    * use it to know which index in the mapping we want to add the new collection.
    * Example:  if COLLECTION_ID_POINTER = 5
    *           We know there are 5 collections, but we also know in the mapping the
    *           collection id's are as follows: 0,1,2,3,4
    * So next time when we need to add a new collection, we use the same COLLECTION_ID_POINTER variable
    * to add collection in index '5', and then increment size +1 in end because now we have 6 collections
  */
  Counters.Counter private COLLECTION_ID_POINTER; // tracks total number of collections
  uint256 private MAX_COLLECTION_SIZE; // maximum number of collections allowed
  CollectionIdDS private COLLECTION_IDS; // Track important info for all collections
  mapping(uint256 => CollectionDS) private COLLECTIONS; // mapping collection id to collection

  mapping(address => uint256[]) private COLLECTION_OWNERS; // mapping collection owner to collection ids
  mapping(address => uint256) private COLLECTION_CONTRACTS; // mapping contract addresses to a collection id

  uint8 internal UNVERIFIED_COLLECTION_ID; // collection id `1` is always the unverified collection


  /**
    * @dev Check if item exists
  */
  function _collectionExists(uint256 _id) private view returns (bool) {
    if (COLLECTIONS[_id].id != 0) {
      return true;
    }
    return false;
  }

  /**
    * @dev Does collection exist
  */
  function _doesCollectionExist(uint256 _id) internal view returns (bool) {
    return _collectionExists(_id);
  }

  /**
    * @dev Check if item exists
  */
  function _isCollectionOwner(uint256 _id, address _owner) internal view returns (bool) {
    if (COLLECTIONS[_id].owner == _owner) {
      return true;
    }
    return false;
  }


  function __Collection_init() internal {
    // initialize state variables
    MAX_COLLECTION_SIZE = type(uint256).max;
    UNVERIFIED_COLLECTION_ID = 1;
  }


  /** 
    *****************************************************
    **************** Attribute Functions ****************
    *****************************************************
  */
  /**
    * @dev Get max collection size
  */
  function _getMaxCollectionSize() internal view returns (uint256) {
    return MAX_COLLECTION_SIZE;
  }

  /**
    * @dev Set max collection size
  */
  function _setMaxCollectionSize(uint256 _size) internal {
    MAX_COLLECTION_SIZE = _size;
  }

  /**
    * @dev Get collection id pointer
  */
  function _getCollectionIdPointer() internal view returns (uint256) {
    return COLLECTION_ID_POINTER.current();
  }

  /**
    * @dev Reset collection id pointer to 0
  */
  function _resetCollectionIdPointer() internal {
    COLLECTION_ID_POINTER.reset();
  }


  /** 
    *****************************************************
    ****************** Main Functions *******************
    *****************************************************
  */
  /**
    * @dev Add empty collection
  */
  function _createEmptyCollection() internal {
    COLLECTION_ID_POINTER.increment();
    uint256 id = COLLECTION_ID_POINTER.current();
    COLLECTIONS[id].id = id;
    _addActiveCollectionId(id);
  }

  /**
    * @dev Create local collection
  */
  function _createLocalCollection(address _contractAddress, address _owner) internal returns (uint256) {
    require(_getCollectionForContract(_contractAddress) == 0, "Collection: Collection with this address already exists");

    COLLECTION_ID_POINTER.increment();
    uint256 id = COLLECTION_ID_POINTER.current();
    COLLECTIONS[id] = CollectionDS({
      id: id,
      contractAddress: _contractAddress,
      totalSupply: 0,
      reflection: 0,
      commission: 0,
      incentive: 0,
      owner: _owner,
      collectionType: COLLECTION_TYPE.local,
      ownerIncentiveAccess: false,
      active: true
    });

    _addActiveCollectionId(id);
    _addLocalCollectionId(id);
    _addCollectionForOwner(_owner, id);
    _assignContractToCollection(_contractAddress, id);
    return id;
  }

  /**
    * @dev Create verified collection
  */
  function _createVerifiedCollection(
    address _contractAddress, uint256 _totalSupply, uint8 _reflection, uint8 _commission,
    address _owner, bool _ownerIncentiveAccess
  ) internal returns (uint256) {
    require(_totalSupply > 0, "Collection: Total supply must be > 0");
    require(_reflection < 100, "Collection: Reflection percent must be < 100");
    require(_commission < 100, "Collection: Commission percent must be < 100");
    require(_getCollectionForContract(_contractAddress) == 0, "Collection: Collection with this address already exists");


    COLLECTION_ID_POINTER.increment();
    uint256 id = COLLECTION_ID_POINTER.current();
    COLLECTIONS[id] = CollectionDS({
      id: id,
      contractAddress: _contractAddress,
      totalSupply: _totalSupply,
      reflection: _reflection,
      commission: _commission,
      incentive: 0,
      owner: _owner,
      collectionType: COLLECTION_TYPE.verified,
      ownerIncentiveAccess: _ownerIncentiveAccess,
      active: false
    });

    _addVerifiedCollectionId(id);
    _addCollectionForOwner(_owner, id);
    _assignContractToCollection(_contractAddress, id);
    return id;
  }

  /**
    * @dev Create unvarivied collection
  */
  function _createUnvariviedCollection(address _owner) internal returns (uint256) {
    COLLECTION_ID_POINTER.increment();
    uint256 id = COLLECTION_ID_POINTER.current();
    COLLECTIONS[id] = CollectionDS({
      id: id,
      contractAddress: address(0),
      totalSupply: 0,
      reflection: 0,
      commission: 0,
      incentive: 0,
      owner: _owner,
      collectionType: COLLECTION_TYPE.unverified,
      ownerIncentiveAccess: false,
      active: true
    });

    _addActiveCollectionId(id);
    _addUnverifiedCollectionId(id);
    _addCollectionForOwner(_owner, id);
    _assignContractToCollection(address(0), id);
    return id;
  }

  /**
    * @dev Get collection
  */
  function _getCollection(uint256 _id) internal view checkCollection(_id) returns (CollectionDS memory) {
    CollectionDS memory collection = COLLECTIONS[_id];
    return collection;
  }

  /**
    * @dev Get active collections
  */
  function _getActiveCollections() internal view returns (CollectionDS[] memory) {
    uint256 arrLength = COLLECTION_IDS.active.length;
    CollectionDS[] memory collections = new CollectionDS[](arrLength);
    for (uint256 i = 0; i < arrLength; i++) {
      uint256 id = COLLECTION_IDS.active[i];
      CollectionDS memory collection = COLLECTIONS[id];
      collections[i] = collection;
    }
    return collections;
  }

  /**
    * @dev Get local collections
  */
  function _getLocalCollections() internal view returns (CollectionDS[] memory) {
    uint256 arrLength = COLLECTION_IDS.local.length;
    CollectionDS[] memory collections = new CollectionDS[](arrLength);
    for (uint256 i = 0; i < arrLength; i++) {
      uint256 id = COLLECTION_IDS.local[i];
      CollectionDS memory collection = COLLECTIONS[id];
      collections[i] = collection;
    }
    return collections;
  }

  /**
    * @dev Get verified collections
  */
  function _getVerifiedCollections() internal view returns (CollectionDS[] memory) {
    uint256 arrLength = COLLECTION_IDS.verified.length;
    CollectionDS[] memory collections = new CollectionDS[](arrLength);
    for (uint256 i = 0; i < arrLength; i++) {
      uint256 id = COLLECTION_IDS.verified[i];
      CollectionDS memory collection = COLLECTIONS[id];
      collections[i] = collection;
    }
    return collections;
  }

  /**
    * @dev Get vunerified collections
  */
  function _getUnverifiedCollections() internal view returns (CollectionDS[] memory) {
    uint256 arrLength = COLLECTION_IDS.unverified.length;
    CollectionDS[] memory collections = new CollectionDS[](arrLength);
    for (uint256 i = 0; i < arrLength; i++) {
      uint256 id = COLLECTION_IDS.unverified[i];
      CollectionDS memory collection = COLLECTIONS[id];
      collections[i] = collection;
    }
    return collections;
  }

  /**
    * @dev Update collection
  */
  function _updateCollection(
    uint256 _id, uint8 _reflection, uint8 _commission, uint8 _incentive, address _owner
  ) internal checkCollection(_id) {
    require(_reflection < 100, "Collection: Reflection percent must be < 100");
    require(_commission < 100, "Collection: Commission percent must be < 100");
    require(_incentive < 100, "Collection: Incentive percent must be < 100");

    COLLECTIONS[_id].reflection = _reflection;
    COLLECTIONS[_id].commission = _commission;
    COLLECTIONS[_id].incentive = _incentive;

    // if owner is different, add it to the list, delete the old one
    if (COLLECTIONS[_id].owner != _owner) {
      _removeCollectionForOwner(COLLECTIONS[_id].owner, _id);
      COLLECTIONS[_id].owner = _owner;
      _addCollectionForOwner(_owner, _id);
    }
  }

  /**
    * @dev Get collection contract address
  */
  function _getCollectionContractAddress(uint256 _id) internal view checkCollection(_id) returns (address) {
    return COLLECTIONS[_id].contractAddress;
  }

  /**
    * @dev Update collection contract address
  */
  function _updateCollectionContractAddress(uint256 _id, address _contractAddress) internal checkCollection(_id) {
    COLLECTIONS[_id].contractAddress = _contractAddress;
  }

  /**
    * @dev Get total supply
  */
  function _getCollectionTotalSupply(uint256 _id) internal view checkCollection(_id) returns (uint256) {
    return COLLECTIONS[_id].totalSupply;
  }

  /**
    * @dev Get collection reflection
  */
  function _getCollectionReflection(uint256 _id) internal view checkCollection(_id) returns (uint8) {
    return COLLECTIONS[_id].reflection;
  }

  /**
    * @dev Update collection reflection
  */
  function _updateCollectionReflection(uint256 _id, uint8 _reflection) internal checkCollection(_id) {
    COLLECTIONS[_id].reflection = _reflection;
  }

  /**
    * @dev Get collection commission
  */
  function _getCollectionCommission(uint256 _id) internal view checkCollection(_id) returns (uint8) {
    return COLLECTIONS[_id].commission;
  }

  /**
    * @dev Update collection commission
  */
  function _updateCollectionCommission(uint256 _id, uint8 _commission) internal checkCollection(_id) {
    COLLECTIONS[_id].commission = _commission;
  }

  /**
    * @dev Get collection incentive
  */
  function _getCollectionIncentive(uint256 _id) internal view checkCollection(_id) returns (uint8) {
    return COLLECTIONS[_id].incentive;
  }

  /**
    * @dev Update collection incentive
  */
  function _updateCollectionIncentive(uint256 _id, uint8 _incentive) internal checkCollection(_id) {
    COLLECTIONS[_id].incentive = _incentive;
  }

  /**
    * @dev Get collection owner
  */
  function _getCollectionOwner(uint256 _id) internal view checkCollection(_id) returns (address) {
    return COLLECTIONS[_id].owner;
  }

  /**
    * @dev Update collection owner
  */
  function _updateCollectionOwner(uint256 _id, address _owner) internal checkCollection(_id) {
    COLLECTIONS[_id].owner = _owner;
  }

  /**
    * @dev Get collection type
  */
  function _getCollectionType(uint256 _id) internal view checkCollection(_id) returns (COLLECTION_TYPE) {
    return COLLECTIONS[_id].collectionType;
  }

  /**
    * @dev Update collection type
  */
  function _updateCollectionType(uint256 _id, COLLECTION_TYPE _collectionType) internal checkCollection(_id) {
    COLLECTIONS[_id].collectionType = _collectionType;
  }

  /**
    * @dev Get collection ownerIncentiveAccess boolean
  */
  function _getCollectionOwnerIncentiveAccess(uint256 _id) internal view checkCollection(_id) returns (bool) {
    return COLLECTIONS[_id].ownerIncentiveAccess;
  }

  /**
    * @dev Update collectiton ownerIncentiveAccess boolean
  */
  function _updateCollectionOwnerIncentiveAccess(uint256 _id, bool _ownerIncentiveAccess) internal checkCollection(_id) {
    COLLECTIONS[_id].ownerIncentiveAccess = _ownerIncentiveAccess;
  }

  /**
    * @dev Get collection active boolean
  */
  function _getCollectionActive(uint256 _id) internal view checkCollection(_id) returns (bool) {
    return COLLECTIONS[_id].active;
  }

  /**
    * @dev Update collectiton active boolean
  */
  function _updateCollectionActive(uint256 _id, bool _active) internal checkCollection(_id) {
    COLLECTIONS[_id].active = _active;
  }

  /**
    * @dev Activate collection
  */
  function _activateCollection(uint256 _id) internal checkCollection(_id) {
    _addActiveCollectionId(_id);
    _updateCollectionActive(_id, true);
  }

  /**
    * @dev Deactivate collection
  */
  function _deactivateCollection(uint256 _id) internal checkCollection(_id) {
    _removeActiveCollectionId(_id);
    _updateCollectionActive(_id, false);
  }

  /**
    * @dev Remove collection
  */
  function _removeCollection(uint256 _id) checkCollection(_id) internal {
    _removeCollectionId(_id);
    _removeCollectionOwner(COLLECTIONS[_id].owner);
    _removeContractForCollection(COLLECTIONS[_id].contractAddress);
    delete COLLECTIONS[_id];
  }


  /** 
    *****************************************************
    ************* COLLECTION_IDS Functions **************
    *****************************************************
  */
  /**
    * @dev Add a new active collection
  */
  function _addActiveCollectionId(uint256 _id) internal {
    COLLECTION_IDS.active.push(_id);
  }

  /**
    * @dev Get active collection ids
  */
  function _getActiveCollectionIds() internal view returns (uint256[] memory) {
    return COLLECTION_IDS.active;
  }

  /**
    * @dev Remove a active collection
  */
  function _removeActiveCollectionId(uint256 _id) internal {
    COLLECTION_IDS.active = _removeSpecificCollectionId(_id, COLLECTION_IDS.active);
  }

  /**
    * @dev Add a new local collection
  */
  function _addLocalCollectionId(uint256 _id) internal {
    COLLECTION_IDS.local.push(_id);
  }

  /**
    * @dev Get local collection ids
  */
  function _getLocalCollectionIds() internal view returns (uint256[] memory) {
    return COLLECTION_IDS.local;
  }

  /**
    * @dev Add a new verified collection
  */
  function _addVerifiedCollectionId(uint256 _id) internal {
    COLLECTION_IDS.verified.push(_id);
  }

  /**
    * @dev Get verified collection ids
  */
  function _getVerifiedCollectionIds() internal view returns (uint256[] memory) {
    return COLLECTION_IDS.verified;
  }

  /**
    * @dev Add a new unverified collection
  */
  function _addUnverifiedCollectionId(uint256 _id) internal {
    COLLECTION_IDS.unverified.push(_id);
  }

  /**
    * @dev Get unverified collection ids
  */
  function _getUnverifiedCollectionIds() internal view returns (uint256[] memory) {
    return COLLECTION_IDS.unverified;
  }

  /**
    * @dev Get collection ids
  */
  function _getCollectionIds() internal view returns (CollectionIdDS memory) {
    return COLLECTION_IDS;
  }

  /**
    * @dev Remove collection id
  */
  function _removeCollectionId(uint256 _id) internal checkCollection(_id) {
    // COLLECTION_IDS.active = data;
    if (_getCollectionActive(_id)) {
      COLLECTION_IDS.active = _removeSpecificCollectionId(_id, COLLECTION_IDS.active);
    }

    // remove from collection type specific array
    COLLECTION_TYPE collectionType = COLLECTIONS[_id].collectionType;
    if (collectionType == COLLECTION_TYPE.local) {
      COLLECTION_IDS.local = _removeSpecificCollectionId(_id, COLLECTION_IDS.local);
    } else if (collectionType == COLLECTION_TYPE.verified) {
      COLLECTION_IDS.verified = _removeSpecificCollectionId(_id, COLLECTION_IDS.verified);
    } else if (collectionType == COLLECTION_TYPE.unverified) {
      COLLECTION_IDS.unverified = _removeSpecificCollectionId(_id, COLLECTION_IDS.unverified);
    }
  }

  /**
    * @dev Remove collection id for specific collection type
  */
  function _removeSpecificCollectionId(uint256 _id, uint256[] memory _collectionArray) private view checkCollection(_id) returns (uint256[] memory) {
    // remove from active collection array
    uint256 arrLength = _collectionArray.length - 1;
    uint256[] memory data = new uint256[](arrLength);
    uint8 dataCounter = 0;
    for (uint256 i = 0; i < _collectionArray.length; i++) {
      if (_collectionArray[i] != _id) {
        data[dataCounter] = _collectionArray[i];
        dataCounter++;
      }
    }
    return _collectionArray = data;
  }


  /** 
    *****************************************************
    *********** COLLECTION_OWNERS Functions *************
    *****************************************************
  */
  /**
    * @dev Add a new owner (if necessary) and add collection id passed in
  */
  function _addCollectionForOwner(address _owner, uint256 _id) internal {
    COLLECTION_OWNERS[_owner].push(_id);
  }

  /**
    * @dev Get collections for owner
  */
  function _getCollectionsForOwner(address _owner) internal view returns (uint256[] memory) {
    return COLLECTION_OWNERS[_owner];
  }

  /**
    * @dev Remove a collection for owner
  */
  function _removeCollectionForOwner(address _owner, uint256 _id) internal {
    uint256 arrLength = COLLECTION_OWNERS[_owner].length - 1;
    uint256[] memory data = new uint256[](arrLength);
    uint8 dataCounter = 0;
    for (uint256 i = 0; i < COLLECTION_OWNERS[_owner].length; i++) {
      if (COLLECTION_OWNERS[_owner][i] != _id) {
        data[dataCounter] = COLLECTION_OWNERS[_owner][i];
        dataCounter++;
      }
    }
    COLLECTION_OWNERS[_owner] = data;
  }

  /**
    * @dev Remove the collection owner
  */
  function _removeCollectionOwner(address _owner) internal {
    delete COLLECTION_OWNERS[_owner];
  }


  /** 
    *****************************************************
    *********** COLLECTION_CONTRACTS Functions *************
    *****************************************************
  */
  /**
    * @dev Assign a contract address to a collection
  */
  function _assignContractToCollection(address _contract, uint256 _id) internal {
    COLLECTION_CONTRACTS[_contract] = _id;
  }

  /**
    * @dev Get collection id for given contract address
  */
  function _getCollectionForContract(address _contract) internal view returns (uint256) {
    return COLLECTION_CONTRACTS[_contract];
  }

  /**
    * @dev Remove collection for given contract address
  */
  function _removeContractForCollection(address _contract) internal {
    delete COLLECTION_CONTRACTS[_contract];
  }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.12 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";


contract Item {
  using Counters for Counters.Counter;

  // modifiers
  modifier checkItem(uint256 _id) {
    require(_itemExists(_id), "The item does not exist");
    _;
  }
  modifier checkSellerIsOwner(uint256 _id, address _owner) {
    require(_isSellerOwner(_id, _owner), "This user is not the owner of the item");
    _;
  }

  /**
    * Note All calculations using percentages will truncate any decimals.
    * Instead whole numbers will be used.
    *
    * Examples: number = (num * perVar / 100);
    *   - 2% of 100 = 2
    *   - 2% of 75 = 1
    *   - 2% of 50 = 1
    *   - 2% of 20 = 0
  */

  // enums

  // data structures
  struct ItemDS {
    uint256 id; // unique item id
    uint256 collectionId; // collection id associated with this item
    uint256 tokenId; // unique token id of the item
    address contractAddress;
    address seller; // address of the seller / current owner
    address buyer; // address of the buyer / next owner (empty if not yet bought)
    uint256 price; // price of the item
    uint8 commission; // in percentage
    address creator; // original creator of the item
    bool sold;
    bool active;
  }

  // state variables

  /**
    * @dev We use the same ITEM_ID_POINTER to track the size of the items, and also
    * use it to know which index in the mapping we want to add the new item.
    * Example:  if ITEM_ID_POINTER = 5
    *           We know there are 5 collections, but we also know in the mapping the
    *           item id's are as follows: 0,1,2,3,4
    * So next time when we need to add a new item, we use the same ITEM_ID_POINTER variable
    * to add item in index '5', and then increment size +1 in end because now we have 6 collections
  */
  Counters.Counter private ITEM_ID_POINTER; // tracks total number of items
  uint256[] private ITEM_IDS; // current list of items on sale
  mapping(uint256 => ItemDS) private ITEMS; // mapping item id to market item
  mapping(address => uint256[]) private ITEM_OWNERS; // mapping item owner to item ids


  /**
    * @dev Check if item exists
  */
  function _itemExists(uint256 _id) private view returns (bool) {
    if (ITEMS[_id].id != 0) {
      return true;
    }
    return false;
  }

  /**
    * @dev Does item exist
  */
  function _doesItemExist(uint256 _id) internal view returns (bool) {
    return _itemExists(_id);
  }

  /**
    * @dev Check if user is the owner
  */
  function _isSellerOwner(uint256 _id, address _owner) private view returns (bool) {
    if (ITEMS[_id].seller == _owner) {
      return true;
    }
    return false;
  }

  /**
    * @dev Does item exist
  */
  function _isSellerTheOwner(uint256 _id, address _owner) internal view returns (bool) {
    return _isSellerOwner(_id, _owner);
  }


  function __Item_init() internal {
  }


  /** 
    *****************************************************
    **************** Attribute Functions ****************
    *****************************************************
  */
  /**
    * @dev Get item id pointer
  */
  function _getItemIdPointer() internal view returns (uint256) {
    return ITEM_ID_POINTER.current();
  }

  /**```~```````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````
    * @dev Reset item id pointer to 0
  */
  function _resetItemIdPointer() internal {
    ITEM_ID_POINTER.reset();
  }


  /** 
    *****************************************************
    ****************** Main Functions *******************
    *****************************************************
  */
  /**
    * @dev Add empty item
  */
  function _addEmptyItem() internal {
    ITEM_ID_POINTER.increment();
    uint256 id = ITEM_ID_POINTER.current();
    ITEMS[id].id = id;
    _addItemId(id);
  }

  /**
    * @dev Add local item to put up for sale
  */
  function _addItem(
    uint256 _collectionId, uint256 _tokenId, address _contractAddress, address _seller, address _buyer, uint256 _price, uint8 _commission, address _creator
  ) internal returns (uint256) {
    require(_commission < 100, "Item: Commission percent must be < 100");

    ITEM_ID_POINTER.increment();
    uint256 id = ITEM_ID_POINTER.current();
    ITEMS[id] = ItemDS({
      id: id,
      collectionId: _collectionId,
      tokenId: _tokenId,
      contractAddress: _contractAddress,
      seller: _seller,
      buyer: _buyer,
      price: _price,
      commission: _commission,
      creator: _creator,
      sold: false,
      active: true
    });

    _addItemId(id);
    _addItemForOwner(_seller, id);
    return ITEM_ID_POINTER.current();
  }

  /**
    * @dev Get item
  */
  function _getItem(uint256 _id) internal view checkItem(_id) returns (ItemDS memory) {
    ItemDS memory item = ITEMS[_id];
    return item;
  }

  /**
    * @dev Get items
  */
  function _getItems(uint256[] memory _ids) internal view returns (ItemDS[] memory) {
    uint256 arrLength = _ids.length;
    ItemDS[] memory items = new ItemDS[](arrLength);
    for (uint256 i = 0; i < arrLength; i++) {
      uint256 id = _ids[i];
      ItemDS memory item = ITEMS[id];
      items[i] = item;
    }
    return items;
  }

  /**
    * @dev Get all items
  */
  function _getAllItems() internal view returns (ItemDS[] memory) {
    uint256 arrLength = ITEM_IDS.length;
    ItemDS[] memory items = new ItemDS[](arrLength);
    for (uint256 i = 0; i < arrLength; i++) {
      uint256 id = ITEM_IDS[i];
      ItemDS memory item = ITEMS[id];
      items[i] = item;
    }
    return items;
  }

  /**
    * @dev Update item
  */
  function _updateItem(
    uint256 _id, uint256 _collectionId, uint256 _tokenId, address _contractAddress, address _seller, address _buyer, uint256 _price,
    uint8 _commission, address _creator, bool _sold, bool _active
  ) internal checkItem(_id) {
    // todo do not allow to update _collectionId, _contractAddress, _creator
    require(_commission < 100, "Item: Commission percent must be < 100");

    ITEMS[_id] = ItemDS({
      id: _id,
      collectionId: _collectionId,
      tokenId: _tokenId,
      contractAddress: _contractAddress,
      seller: _seller,
      buyer: _buyer,
      price: _price,
      commission: _commission,
      creator: _creator,
      sold: _sold,
      active: _active
    });
    if (!_active) {
      _removeItemId(_id);
    }
  }

  /**
    * @dev Get item collection id
  */
  function _getItemCollectionId(uint256 _id) internal view checkItem(_id) returns (uint256) {
    return ITEMS[_id].collectionId;
  }

  /**
    * @dev Update item collection id
  */
  function _updateItemCollectionId(uint256 _id, uint256 _collectionId) internal checkItem(_id) {
    ITEMS[_id].collectionId = _collectionId;
  }

  /**
    * @dev Get item token id
  */
  function _getItemTokenId(uint256 _id) internal view checkItem(_id) returns (uint256) {
    return ITEMS[_id].tokenId;
  }

  /**
    * @dev Update item token id
  */
  function _updateItemTokenId(uint256 _id, uint256 _tokenId) internal checkItem(_id) {
    ITEMS[_id].tokenId = _tokenId;
  }

  /**
    * @dev Get item contract address
  */
  function _getItemContractAddress(uint256 _id) internal view checkItem(_id) returns (address) {
    return ITEMS[_id].contractAddress;
  }

  /**
    * @dev Update item contract address
  */
  function _updateItemContractAddress(uint256 _id, address _contractAddress) internal checkItem(_id) {
    ITEMS[_id].contractAddress = _contractAddress;
  }

  /**
    * @dev Get item seller
  */
  function _getItemSeller(uint256 _id) internal view checkItem(_id) returns (address) {
    return ITEMS[_id].seller;
  }

  /**
    * @dev Update item seller
  */
  function _updateItemSeller(uint256 _id, address _seller) internal checkItem(_id) {
    ITEMS[_id].seller = _seller;
  }

  /**
    * @dev Get item buyer
  */
  function _getItemBuyer(uint256 _id) internal view checkItem(_id) returns (address) {
    return ITEMS[_id].buyer;
  }

  /**
    * @dev Update item buyer
  */
  function _updateItemBuyer(uint256 _id, address _buyer) internal checkItem(_id) {
    ITEMS[_id].buyer = _buyer;
  }

  /**
    * @dev Get item price
  */
  function _getItemPrice(uint256 _id) internal view checkItem(_id) returns (uint256) {
    return ITEMS[_id].price;
  }

  /**
    * @dev Update item price
  */
  function _updateItemPrice(uint256 _id, uint256 _price) internal checkItem(_id) {
    ITEMS[_id].price = _price;
  }

  /**
    * @dev Get item commission
  */
  function _getItemCommission(uint256 _id) internal view checkItem(_id) returns (uint8) {
    return ITEMS[_id].commission;
  }

  /**
    * @dev Update item commission
  */
  function _updateItemCommission(uint256 _id, uint8 _commission) internal checkItem(_id) {
    ITEMS[_id].commission = _commission;
  }

  /**
    * @dev Get item creator
  */
  function _getItemCreator(uint256 _id) internal view checkItem(_id) returns (address) {
    return ITEMS[_id].creator;
  }

  /**
    * @dev Update item creator
  */
  function _updateItemCreator(uint256 _id, address _creator) internal checkItem(_id) {
    ITEMS[_id].creator = _creator;
  }

  /**
    * @dev Get item sold boolean
  */
  function _getItemSold(uint256 _id) internal view checkItem(_id) returns (bool) {
    return ITEMS[_id].sold;
  }

  /**
    * @dev Update item sold boolean
  */
  function _updateItemSold(uint256 _id, bool _sold) internal checkItem(_id) {
    ITEMS[_id].sold = _sold;
  }

  /**
    * @dev Get item active boolean
  */
  function _getItemActive(uint256 _id) internal view checkItem(_id) returns (bool) {
    return ITEMS[_id].active;
  }

  /**
    * @dev Update item active boolean
  */
  function _updateItemActive(uint256 _id, bool _active) internal checkItem(_id) {
    ITEMS[_id].active = _active;
  }

  /**
    * @dev Mark item as sold
  */
  function _markItemSold(uint256 _id) internal checkItem(_id) {
    _removeItemId(_id);
    _updateItemSold(_id, true);
  }

  /**
    * @dev Activate item
  */
  function _activateItem(uint256 _id) internal checkItem(_id) {
    _addItemId(_id);
    _updateItemActive(_id, true);
  }

  /**
    * @dev Deactivate item
  */
  function _deactivateItem(uint256 _id) internal checkItem(_id) {
    _removeItemId(_id);
    _updateItemActive(_id, false);
  }

  /**
    * @dev Remove item
  */
  function _removeItem(uint256 _id) internal checkItem(_id) {
    _removeItemId(_id);
    delete ITEMS[_id];
  }


  /** 
    *****************************************************
    ************* ITEM_IDS Functions ***************
    *****************************************************
  */
  /**
    * @dev Add a new item
  */
  function _addItemId(uint256 _id) internal {
    ITEM_IDS.push(_id);
  }

  /**
    * @dev Get item ids
  */
  function _getItemIds() internal view returns (uint256[] memory) {
    return ITEM_IDS;
  }

  /**
    * @dev Remove item id
  */
  function _removeItemId(uint256 _id) internal checkItem(_id) {
    uint256 arrLength = ITEM_IDS.length - 1;
    uint256[] memory data = new uint256[](arrLength);
    uint8 dataCounter = 0;
    for (uint256 i = 0; i < ITEM_IDS.length; i++) {
      if (ITEM_IDS[i] != _id) {
        data[dataCounter] = ITEM_IDS[i];
        dataCounter++;
      }
    }
    ITEM_IDS = data;
  }


  /** 
    *****************************************************
    *********** ITEM_OWNERS Functions *************
    *****************************************************
  */
  /**
    * @dev Add a new owner (if necessary) and add item id passed in
  */
  function _addItemForOwner(address _owner, uint256 _id) internal {
    ITEM_OWNERS[_owner].push(_id);
  }

  /**
    * @dev Get items for owner
  */
  function _getItemsForOwner(address _owner) internal view returns (uint256[] memory) {
    return ITEM_OWNERS[_owner];
  }

  /**
    * @dev Remove a item for owner
  */
  function _removeItemForOwner(address _owner, uint256 _id) internal {
    uint256 arrLength = ITEM_OWNERS[_owner].length - 1;
    uint256[] memory data = new uint256[](arrLength);
    uint8 dataCounter = 0;
    for (uint256 i = 0; i < ITEM_OWNERS[_owner].length; i++) {
      if (ITEM_OWNERS[_owner][i] != _id) {
        data[dataCounter] = ITEM_OWNERS[_owner][i];
        dataCounter++;
      }
    }
    ITEM_OWNERS[_owner] = data;
  }

  /**
    * @dev Remove the item owner
  */
  function _removeItemOwner(address _owner) internal {
    delete ITEM_OWNERS[_owner];
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

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
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
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

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);
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

        _afterTokenTransfer(address(0), to, tokenId);
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
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.12 <0.9.0;

import "hardhat/console.sol";


contract UserAccount {

  // modifiers
  modifier checkUserAccount(address _id) {
    require(_userAccountExists(_id), "The account for this user does not exist");
    _;
  }

  // data structures
  struct UserAccountDS {
    address id; // owner of these accounts
    uint256 general; // any general reward balance
    uint256 nftCommission; // commission reward balance from the item
    uint256 collectionCommission; // commission reward balance from the collection
  }

  mapping(address => UserAccountDS) private USER_ACCOUNTS; // mapping owner address to account object


  /**
    * @dev Check if user exists
  */
  function _userAccountExists(address _id) private view returns (bool) {
    if (USER_ACCOUNTS[_id].id != address(0)) {
      return true;
    }
    return false;
  }


  function __UserAccount_init() internal {
  }


  /** 
    *****************************************************
    **************** Attribute Functions ****************
    *****************************************************
  */


  /** 
    *****************************************************
    ****************** Main Functions *******************
    *****************************************************
  */
  /**
    * @dev Add account
  */
  function _addUserAccount(address _id) internal {
    USER_ACCOUNTS[_id].id = _id;
  }

  /**
    * @dev Get account of user
  */
  function _getUserAccount(address _id) internal view returns (UserAccountDS memory) {
    return USER_ACCOUNTS[_id];
  }

  /**
    * @dev Get accounts for list of users
  */
  function _getUserAccounts(address[] memory _ids) internal view returns (UserAccountDS[] memory) {
    uint256 arrLength = _ids.length;
    UserAccountDS[] memory accounts = new UserAccountDS[](arrLength);
    for (uint256 i = 0; i < arrLength; i++) {
      address id = _ids[i];
      require(_userAccountExists(id), "An account in the list does not exist");
      UserAccountDS memory account = USER_ACCOUNTS[id];
      accounts[i] = account;
    }
    return accounts;
  }

  /**
    * @dev Update account
  */
  function _updateUserAccount(
    address _id, uint256 _general, uint256 _nftCommission, uint256 _collectionCommission
  ) internal {
    USER_ACCOUNTS[_id] = UserAccountDS({
      id: _id,
      general: _general,
      nftCommission: _nftCommission,
      collectionCommission: _collectionCommission
    });
  }

  /**
    * @dev Increase account balance by given amounts
  */
  function _incrementUserAccount(
    address _id, uint256 _general, uint256 _nftCommission, uint256 _collectionCommission
  ) internal {
    USER_ACCOUNTS[_id] = UserAccountDS({
      id: _id,
      general: _getGeneralUserAccount(_id) + _general,
      nftCommission: _getNftCommissionUserAccount(_id) + _nftCommission,
      collectionCommission: _getCollectionCommissionUserAccount(_id) + _collectionCommission
    });
  }

  /**
    * @dev Get general account
  */
  function _getGeneralUserAccount(address _id) internal view returns (uint256) {
    return USER_ACCOUNTS[_id].general;
  }

  /**
    * @dev Update general account
  */
  function _updateGeneralUserAccount(address _id, uint256 _general) internal {
    USER_ACCOUNTS[_id].general = _general;
  }

  /**
    * @dev Get nft commission account
  */
  function _getNftCommissionUserAccount(address _id) internal view returns (uint256) {
    return USER_ACCOUNTS[_id].nftCommission;
  }

  /**
    * @dev Update nft commission account
  */
  function _updateNftCommissionUserAccount(address _id, uint256 _nftCommission) internal {
    USER_ACCOUNTS[_id].nftCommission = _nftCommission;
  }

  /**
    * @dev Get collection commission account
  */
  function _getCollectionCommissionUserAccount(address _id) internal view returns (uint256) {
    return USER_ACCOUNTS[_id].collectionCommission;
  }

  /**
    * @dev Update collection commission account
  */
  function _updateCollectionCommissionUserAccount(address _id, uint256 _collectionCommission) internal {
    USER_ACCOUNTS[_id].collectionCommission = _collectionCommission;
  }

  /**
    * @dev Nullify account
  */
  function _nullifyUserAccount(address _id) internal {
    _updateUserAccount(_id, 0, 0, 0);
  }

  /**
    * @dev Remove account
  */
  function _removeUserAccount(address _id) internal {
    delete USER_ACCOUNTS[_id];
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.12 <0.9.0;

import "hardhat/console.sol";


contract CollectionAccount {

  // modifiers
  modifier checkCollectionAccount(address _id) {
    require(_collectionAccountExists(_id), "The account for this collection does not exist");
    _;
  }
  modifier isCollectionAccountInitialized(address _id) {
    require(COLLECTION_ACCOUNTS[_id].supply > 0, "Collection account not initialized");
    _;
  }

  // data structures
  struct CollectionAccountDS {
    address id; // contract address of this collection account
    mapping(uint256 => uint256) reflectionVault; // reflection reward for each token id
    uint256 incentiveVault; // collection reward vault given upon completion of market sale
    uint256 supply; // total supply of this collection
  }
  struct CollectionAccountReturnDS {
    address id; // contract address of this collection account
    string reflectionVault; // reflection reward for each token id
    uint256 incentiveVault; // collection reward vault given upon completion of market sale
    uint256 supply; // total supply of this collection
  }

  mapping(address => CollectionAccountDS) private COLLECTION_ACCOUNTS; // mapping owner address to collection object


  /**
    * @dev Check if user exists
  */
  function _collectionAccountExists(address _id) private view returns (bool) {
    if (COLLECTION_ACCOUNTS[_id].id != address(0)) {
      return true;
    }
    return false;
  }


  function __CollectionAccount_init() internal {
  }


  /** 
    *****************************************************
    **************** Attribute Functions ****************
    *****************************************************
  */


  /** 
    *****************************************************
    ****************** Main Functions *******************
    *****************************************************
  */
  /**
    * @dev Add account
  */
  function _addCollectionAccount(address _id) internal {
    COLLECTION_ACCOUNTS[_id].id = _id;
  }

  /**
    * @dev Get account of collection
  */
  function _getCollectionAccount(address _id) internal view returns (CollectionAccountReturnDS memory) {
    return CollectionAccountReturnDS({
      id: COLLECTION_ACCOUNTS[_id].id,
      reflectionVault: 'reflectionVault',
      incentiveVault: COLLECTION_ACCOUNTS[_id].incentiveVault,
      supply: COLLECTION_ACCOUNTS[_id].supply
    });
  }

  /**
    * @dev Get collections for list of users
  */
  function _getCollectionAccounts(address[] memory _ids) internal view returns (CollectionAccountReturnDS[] memory) {
    uint256 arrLength = _ids.length;
    CollectionAccountReturnDS[] memory collections = new CollectionAccountReturnDS[](arrLength);
    for (uint256 i = 0; i < arrLength; i++) {
      address id = _ids[i];
      require(_collectionAccountExists(id), "An account in the list does not exist");
      CollectionAccountReturnDS memory collection = CollectionAccountReturnDS({
        id: COLLECTION_ACCOUNTS[id].id,
        reflectionVault: 'reflectionVault',
        incentiveVault: COLLECTION_ACCOUNTS[id].incentiveVault,
        supply: COLLECTION_ACCOUNTS[id].supply
      });
      collections[i] = collection;
    }
    return collections;
  }

  /**
    * @dev Initialize a collection reflection vault for the given collection
  */
  function _initReflectionVaultCollectionAccount(address _id, uint256 _supply) internal {
    require(_supply > 0, "CollectionAccount: Total supply must be > 0");
    COLLECTION_ACCOUNTS[_id].supply = _supply;
  }

  /**
    * @dev Update collection
  */
  function _updateCollectionAccount(
    address _id, uint256[] memory _reflectionVaultArray, uint256 _incentiveVault
  ) internal isCollectionAccountInitialized(_id) {
    COLLECTION_ACCOUNTS[_id].id = _id;
    for (uint256 i = 0; i < _reflectionVaultArray.length; i++) {
      COLLECTION_ACCOUNTS[_id].reflectionVault[i+1] = _reflectionVaultArray[i];
    }
    COLLECTION_ACCOUNTS[_id].incentiveVault = _incentiveVault;
  }

  /**
    * @dev Get collection reflection vault
  */
  function _getReflectionVaultCollectionAccount(address _id) internal view returns (uint256[] memory) {
    uint256[] memory reflectionVaultArray = new uint256[](COLLECTION_ACCOUNTS[_id].supply);
    for (uint i = 0; i < COLLECTION_ACCOUNTS[_id].supply; i++) {
        reflectionVaultArray[i] = COLLECTION_ACCOUNTS[_id].reflectionVault[i+1];
    }
    return reflectionVaultArray;
  }

  /**
    * @dev Increase collection reflection vault
      @param _id : collection id
      @param _rewardPerItem : reward needs to be allocated to each item in this collection
  */
  function _increaseReflectionVaultCollectionAccount(address _id, uint256 _rewardPerItem) internal isCollectionAccountInitialized(_id) {
    for (uint256 i = 1; i <= COLLECTION_ACCOUNTS[_id].supply; i++) {
      uint256 currentValue = COLLECTION_ACCOUNTS[_id].reflectionVault[i];
      COLLECTION_ACCOUNTS[_id].reflectionVault[i] = currentValue + _rewardPerItem;
    }
  }

  /**
    * @dev Increase collection reflection vault for given token
    * todo write test for this
  */
  function _increaseReflectionVaultForTokensCollectionAccount(address _id, uint256  _tokenId, uint256 _rewardPerItem) internal isCollectionAccountInitialized(_id) {
    require(_tokenId > 0, "Token id must be greater than 0");
    COLLECTION_ACCOUNTS[_id].reflectionVault[_tokenId] += _rewardPerItem;
  }

  /**
    * @dev Get collection reflection for given token id
  */
  function _getReflectionVaultIndexCollectionAccount(address _id, uint256 _tokenId) internal view returns (uint256) {
    return COLLECTION_ACCOUNTS[_id].reflectionVault[_tokenId];
  }

  /**
    * @dev Update collection reflection for given token id
      @param _id : collection id
      @param _tokenId : specific token id to update
      @param _newVal : new value for a single token id
  */
  function _updateReflectionVaultIndexCollectionAccount(address _id, uint256 _tokenId, uint256 _newVal) internal isCollectionAccountInitialized(_id) {
    require(_tokenId > 0, "Token id must be greater than 0");
    COLLECTION_ACCOUNTS[_id].reflectionVault[_tokenId] = _newVal;
  }
  /**
    * @dev Nullify all collection reflection rewards for the given collection id
  */
  function _nullifyReflectionVaultCollectionAccount(address _id) internal isCollectionAccountInitialized(_id) {
    for (uint256 i = 1; i <= COLLECTION_ACCOUNTS[_id].supply; i++) {
      COLLECTION_ACCOUNTS[_id].reflectionVault[i] = 0;
    }
  }

  /**
    * @dev Get collection incentive vault
  */
  function _getIncentiveVaultCollectionAccount(address _id) internal view returns (uint256) {
    return COLLECTION_ACCOUNTS[_id].incentiveVault;
  }

  /**
    * @dev Update collection incentive vault
  */
  function _updateIncentiveVaultCollectionAccount(address _id, uint256 _incentiveVault) internal {
    COLLECTION_ACCOUNTS[_id].incentiveVault = _incentiveVault;
  }

  /**
    * @dev Increase collection balance by given amounts
  */
  function _incrementCollectionAccount(
    address _id, uint256 _rewardPerItem, uint256 _incentiveVault
  ) internal {
    _increaseReflectionVaultCollectionAccount(_id, _rewardPerItem);
    COLLECTION_ACCOUNTS[_id].incentiveVault += _incentiveVault;
  }

  /**
    * @dev Nullify collection
  */
  function _nullifyCollectionAccount(address _id) internal {
    _nullifyReflectionVaultCollectionAccount(_id);
    _updateIncentiveVaultCollectionAccount(_id, 0);
  }

  /**
    * @dev Remove collection
  */
  function _removeCollectionAccount(address _id) internal {
    delete COLLECTION_ACCOUNTS[_id];
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.12 <0.9.0;

import "hardhat/console.sol";


contract Vault {

  // modifiers
  modifier checkVault(address _id) {
    require(_vaultExists(_id), "The vault for this user does not exist");
    _;
  }

  // data structures
  struct VaultDS {
    address id; // owner of this vault
    uint256 balance; // any general reward balance
  }

  mapping(address => VaultDS) private VAULTS; // mapping owner address to vault object


  /**
    * @dev Check if user exists
  */
  function _vaultExists(address _id) private view returns (bool) {
    if (VAULTS[_id].id != address(0)) {
      return true;
    }
    return false;
  }


  function __Vault_init() internal {
  }


  /** 
    *****************************************************
    **************** Attribute Functions ****************
    *****************************************************
  */


  /** 
    *****************************************************
    ****************** Main Functions *******************
    *****************************************************
  */
  /**
    * @dev Add vault
  */
  function _addVault(address _id) internal {
    VAULTS[_id].id = _id;
  }

  /**
    * @dev Get vault of user
  */
  function _getVault(address _id) internal view returns (VaultDS memory) {
    return VAULTS[_id];
  }

  /**
    * @dev Get vaults for list of users
  */
  function _getVaults(address[] memory _ids) internal view returns (VaultDS[] memory) {
    uint256 arrLength = _ids.length;
    VaultDS[] memory vaults = new VaultDS[](arrLength);
    for (uint256 i = 0; i < arrLength; i++) {
      address id = _ids[i];
      require(_vaultExists(id), "A vault in the list does not exist");
      VaultDS memory vault = VAULTS[id];
      vaults[i] = vault;
    }
    return vaults;
  }

  /**
    * @dev Update vault
  */
  function _updateVault(address _id, uint256 _balance) internal {
    VAULTS[_id] = VaultDS({
      id: _id,
      balance: _balance
    });
  }

  /**
    * @dev Get vault balance
  */
  function _getVaultBalance(address _id) internal view returns (uint256) {
    return VAULTS[_id].balance;
  }

  /**
    * @dev Update vault balance
  */
  function _updateVaultBalance(address _id, uint256 _balance) internal {
    VAULTS[_id].balance = _balance;
  }

  /**
    * @dev Nullify vault
  */
  function _nullifyVault(address _id) internal {
    _updateVault(_id, 0);
  }

  /**
    * @dev Remove vault
  */
  function _removeVault(address _id) internal {
    delete VAULTS[_id];
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.12 <0.9.0;

import "hardhat/console.sol";


contract Direct {

  // modifiers
  modifier checkDirectSale(address _id, uint256 _itemId) {
    require(_directSaleExists(_id, _itemId), "This item is not a direct sale");
    _;
  }

  // enums

  // data structures

  // state variables
  uint256[] private TOTAL_DIRECT_SALES; // total direct sale items on sale
  mapping(address => uint256[]) private DIRECT_SALES; // mapping owner to direct sale items


  /**
    * @dev Check if direct item exists for user
  */
  function _directSaleExists(address _id, uint256 _itemId) private view returns (bool) {
    uint256[] memory items = DIRECT_SALES[_id];
    for (uint256 i = 0; i < items.length; i++) {
      if (items[i] == _itemId) {
        return true;
      }
    }
    return false;
  }


  function __Direct_init() internal {
  }


  /** 
    *****************************************************
    **************** Attribute Functions ****************
    *****************************************************
  */


  /** 
    *****************************************************
    ****************** Main Functions *******************
    *****************************************************
  */
  /**
    * @dev Create direct sale item
  */
  function _createDirectSale(address _id, uint256 _itemId) internal {
    _addTotalDirectSale(_itemId);
    DIRECT_SALES[_id].push(_itemId);
  }

  /**
    * @dev Get number of direct sales for user
  */
  function _getDirectSaleCount(address _id) internal view returns (uint256) {
    return DIRECT_SALES[_id].length;
  }

  /**
    * @dev Get total number of direct sales
  */
  function _getTotalDirectSaleCount() internal view returns (uint256) {
    return _getTotalDirectSale().length;
  }

  /**
    * @dev Get direct item ids for user
  */
  function _getDirectSaleItemIds(address _id) internal view returns (uint256[] memory) {
    return DIRECT_SALES[_id];
  }

  /**
    * @dev Get total direct item ids
  */
  function _getTotalDirectSaleItemIds() internal view returns (uint256[] memory) {
    return _getTotalDirectSale();
  }

  /**
    * @dev Does direct sale id exist
  */
  function _doesDirectSaleItemIdExists(address _id, uint256 _itemId) internal view returns (bool) {
    return _directSaleExists(_id, _itemId);
  }

  /**
    * @dev Remove direct sale item
  */
  function _removeDirectSale(address _id, uint256 _itemId) internal checkDirectSale(_id,_itemId) {
    _removeTotalDirectSale(_itemId);
    uint256[] memory items = DIRECT_SALES[_id];
    uint256 arrLength = items.length - 1;
    uint256[] memory data = new uint256[](arrLength);
    uint8 dataCounter = 0; 
    for (uint256 i = 0; i < items.length; i++) {
      if (items[i] != _itemId) {
        data[dataCounter] = items[i];
        dataCounter++;
      }
    }
    DIRECT_SALES[_id] = data;
  }


  /** 
    *****************************************************
    ************* TOTAL_DIRECT_SALES Functions ***************
    *****************************************************
  */
  /**
    * @dev Add a new direct sale item id
  */
  function _addTotalDirectSale(uint256 _id) internal {
    TOTAL_DIRECT_SALES.push(_id);
  }

  /**
    * @dev Get direct sale item ids
  */
  function _getTotalDirectSale() internal view returns (uint256[] memory) {
    return TOTAL_DIRECT_SALES;
  }

  /**
    * @dev Remove direct sale item id
  */
  function _removeTotalDirectSale(uint256 _id) internal {
    uint256 arrLength = TOTAL_DIRECT_SALES.length - 1;
    uint256[] memory data = new uint256[](arrLength);
    uint8 dataCounter = 0;
    for (uint256 i = 0; i < TOTAL_DIRECT_SALES.length; i++) {
      if (TOTAL_DIRECT_SALES[i] != _id) {
        data[dataCounter] = TOTAL_DIRECT_SALES[i];
        dataCounter++;
      }
    }
    TOTAL_DIRECT_SALES = data;
  }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.12 <0.9.0;

import "hardhat/console.sol";


contract Immediate {

  // modifiers
  modifier checkImmediateSale(address _id, uint256 _itemId) {
    require(_immediateSaleExists(_id, _itemId), "This item is not a immediate sale");
    _;
  }

  // enums

  // data structures

  // state variables
  uint256[] private TOTAL_IMMEDIATE_SALES; // total immediate sale items on sale
  mapping(address => uint256[]) private IMMEDIATE_SALES; // mapping owner to immediate sale items


  /**
    * @dev Check if immediate item exists for user
  */
  function _immediateSaleExists(address _id, uint256 _itemId) private view returns (bool) {
    uint256[] memory items = IMMEDIATE_SALES[_id];
    for (uint256 i = 0; i < items.length; i++) {
      if (items[i] == _itemId) {
        return true;
      }
    }
    return false;
  }


  function __Immediate_init() internal {
  }


  /** 
    *****************************************************
    **************** Attribute Functions ****************
    *****************************************************
  */


  /** 
    *****************************************************
    ****************** Main Functions *******************
    *****************************************************
  */
  /**
    * @dev Create immediate sale item
  */
  function _createImmediateSale(address _id, uint256 _itemId) internal {
    _addTotalImmediateSale(_itemId);
    IMMEDIATE_SALES[_id].push(_itemId);
  }

  /**
    * @dev Get number of immediate sales for user
  */
  function _getImmediateSaleCount(address _id) internal view returns (uint256) {
    return IMMEDIATE_SALES[_id].length;
  }

  /**
    * @dev Get total number of immediate sales
  */
  function _getTotalImmediateSaleCount() internal view returns (uint256) {
    return _getTotalImmediateSale().length;
  }

  /**
    * @dev Get all immediate item ids for user
  */
  function _getImmediateSaleItemIds(address _id) internal view returns (uint256[] memory) {
    return IMMEDIATE_SALES[_id];
  }

  /**
    * @dev Get total immediate item ids
  */
  function _getTotalImmediateSaleItemIds() internal view returns (uint256[] memory) {
    return _getTotalImmediateSale();
  }

  /**
    * @dev Does immediate sale id exist
  */
  function _doesImmediateSaleItemIdExists(address _id, uint256 _itemId) internal view returns (bool) {
    return _immediateSaleExists(_id, _itemId);
  }

  /**
    * @dev Remove immediate sale item
  */
  function _removeImmediateSale(address _id, uint256 _itemId) internal checkImmediateSale(_id,_itemId) {
    _removeTotalImmediateSale(_itemId);
    uint256[] memory items = IMMEDIATE_SALES[_id];
    uint256 arrLength = items.length - 1;
    uint256[] memory data = new uint256[](arrLength);
    uint8 dataCounter = 0; 
    for (uint256 i = 0; i < items.length; i++) {
      if (items[i] != _itemId) {
        data[dataCounter] = items[i];
        dataCounter++;
      }
    }
    IMMEDIATE_SALES[_id] = data;
  }


  /** 
    *****************************************************
    ********* TOTAL_IMMEDIATE_SALES Functions ***********
    *****************************************************
  */
  /**
    * @dev Add a new immediate sale item id
  */
  function _addTotalImmediateSale(uint256 _id) internal {
    TOTAL_IMMEDIATE_SALES.push(_id);
  }

  /**
    * @dev Get immediate sale item ids
  */
  function _getTotalImmediateSale() internal view returns (uint256[] memory) {
    return TOTAL_IMMEDIATE_SALES;
  }

  /**
    * @dev Remove immediate sale item id
  */
  function _removeTotalImmediateSale(uint256 _id) internal {
    uint256 arrLength = TOTAL_IMMEDIATE_SALES.length - 1;
    uint256[] memory data = new uint256[](arrLength);
    uint8 dataCounter = 0;
    for (uint256 i = 0; i < TOTAL_IMMEDIATE_SALES.length; i++) {
      if (TOTAL_IMMEDIATE_SALES[i] != _id) {
        data[dataCounter] = TOTAL_IMMEDIATE_SALES[i];
        dataCounter++;
      }
    }
    TOTAL_IMMEDIATE_SALES = data;
  }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.12 <0.9.0;

import "hardhat/console.sol";


contract Auction {

  // modifiers
  modifier checkAuctionSale(address _id, uint256 _itemId) {
    require(_auctionSaleExists(_id, _itemId), "This item is not a auction sale");
    _;
  }

  // enums

  // data structures

  // state variables
  uint256[] private TOTAL_AUCTION_SALES; // total auction sale items on sale
  mapping(address => uint256[]) private AUCTION_SALES; // mapping owner to auction sale items


  /**
    * @dev Check if auction item exists for user
  */
  function _auctionSaleExists(address _id, uint256 _itemId) private view returns (bool) {
    uint256[] memory items = AUCTION_SALES[_id];
    for (uint256 i = 0; i < items.length; i++) {
      if (items[i] == _itemId) {
        return true;
      }
    }
    return false;
  }


  function __Auction_init() internal {
  }


  /** 
    *****************************************************
    **************** Attribute Functions ****************
    *****************************************************
  */


  /** 
    *****************************************************
    ****************** Main Functions *******************
    *****************************************************
  */
  /**
    * @dev Create auction sale item
  */
  function _createAuctionSale(address _id, uint256 _itemId) internal {
    _addTotalAuctionSale(_itemId);
    AUCTION_SALES[_id].push(_itemId);
  }

  /**
    * @dev Get number of auction sales for user
  */
  function _getAuctionSaleCount(address _id) internal view returns (uint256) {
    return AUCTION_SALES[_id].length;
  }

  /**
    * @dev Get total number of auction sales
  */
  function _getTotalAuctionSaleCount() internal view returns (uint256) {
    return _getTotalAuctionSale().length;
  }

  /**
    * @dev Get all auction item ids for user
  */
  function _getAuctionSaleItemIds(address _id) internal view returns (uint256[] memory) {
    return AUCTION_SALES[_id];
  }

  /**
    * @dev Get total auction item ids
  */
  function _getTotalAuctionSaleItemIds() internal view returns (uint256[] memory) {
    return _getTotalAuctionSale();
  }

  /**
    * @dev Does auction sale id exist
  */
  function _doesAuctionSaleItemIdExists(address _id, uint256 _itemId) internal view returns (bool) {
    return _auctionSaleExists(_id, _itemId);
  }

  /**
    * @dev Remove auction sale item
  */
  function _removeAuctionSale(address _id, uint256 _itemId) internal checkAuctionSale(_id,_itemId) {
    _removeTotalAuctionSale(_itemId);
    uint256[] memory items = AUCTION_SALES[_id];
    uint256 arrLength = items.length - 1;
    uint256[] memory data = new uint256[](arrLength);
    uint8 dataCounter = 0; 
    for (uint256 i = 0; i < items.length; i++) {
      if (items[i] != _itemId) {
        data[dataCounter] = items[i];
        dataCounter++;
      }
    }
    AUCTION_SALES[_id] = data;
  }


  /** 
    *****************************************************
    ********** TOTAL_AUCTION_SALES Functions ************
    *****************************************************
  */
  /**
    * @dev Add a new auction sale item id
  */
  function _addTotalAuctionSale(uint256 _id) internal {
    TOTAL_AUCTION_SALES.push(_id);
  }

  /**
    * @dev Get auction sale item ids
  */
  function _getTotalAuctionSale() internal view returns (uint256[] memory) {
    return TOTAL_AUCTION_SALES;
  }

  /**
    * @dev Remove auction sale item id
  */
  function _removeTotalAuctionSale(uint256 _id) internal {
    uint256 arrLength = TOTAL_AUCTION_SALES.length - 1;
    uint256[] memory data = new uint256[](arrLength);
    uint8 dataCounter = 0;
    for (uint256 i = 0; i < TOTAL_AUCTION_SALES.length; i++) {
      if (TOTAL_AUCTION_SALES[i] != _id) {
        data[dataCounter] = TOTAL_AUCTION_SALES[i];
        dataCounter++;
      }
    }
    TOTAL_AUCTION_SALES = data;
  }

}
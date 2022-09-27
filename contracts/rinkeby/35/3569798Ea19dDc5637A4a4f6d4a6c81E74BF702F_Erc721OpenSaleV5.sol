// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { OpenSaleParams, VoucherParams } from "./StructsV5.sol";
import { ABI_VOUCHER_OPEN_SALE_MINT, ABI_OPEN_SALE_MINT } from "./FunctionAbiV5.sol";
import "./Erc721SaleV5.sol";

/**
    @notice This contract manages the Open Sale for the NFTs.
 */
contract Erc721OpenSaleV5 is Erc721SaleV5 {
  using Strings for uint256;
  using Address for address;

  constructor(OpenSaleParams memory params_)
    Erc721SaleV5(
      params_.name,
      params_.symbol,
      params_.baseURI,
      params_.contractURI,
      params_.maxSupply,
      params_.maxTokensPerWallet,
      params_.pricePayoutWallet,
      params_.signatureVerifier,
      params_.roles,
      params_.roleAddresses,
      params_.multisigRoles,
      params_.multisigThresholds,
      params_.totalRoyalty,
      params_.payees,
      params_.shares
    )
  {
    emit NftDeployed(msg.sender, address(this), currentPaymentSplitter());
  }

  /**
        @dev This function is used to mint a token. It can be called by anybody.
        @param tokenId_ The tokenId of the Token to be minted.
    */
  function mintToken(uint256 tokenId_, VoucherParams calldata params_) external payable whenNotPaused {
    require(isSaleActive, "15");
    require((totalSupply + 1) <= maxSupply, "17");
    require(!msg.sender.isContract(), "16");
    require(balanceOf(msg.sender) + 1 <= maxTokensPerWallet, "19");
    require(tokenId_ >= 0 && tokenId_ <= (maxSupply - 1), "26");
    require(params_.pricePerToken == msg.value, "22");

    _verifyVoucher(
      abi.encode(
        ABI_VOUCHER_OPEN_SALE_MINT,
        tokenId_,
        msg.sender,
        params_.issueTime,
        params_.expirationDuration,
        params_.pricePerToken,
        params_.nonce,
        ABI_OPEN_SALE_MINT
      ),
      params_,
      VOUCHER_SIGNER_ROLE
    );

    _safeMint(msg.sender, tokenId_);
  }

  /**
        @param tokenId_ The tokenId whose URI is requested.
    */
  function tokenURI(uint256 tokenId_) public view override(ERC721) returns (string memory) {
    require(_exists(tokenId_), "23");
    return string(abi.encodePacked(baseURI, tokenId_.toString(), ".json"));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/// @notice A struct representing the parameters passed into the OpenSale Contracts.
struct OpenSaleParams {
  string name; /// The name of the Nft collection.
  string symbol; /// The symbol for the Nft collection.
  string baseURI; /// The initial (IPFS) URI, which would point to the static metadata/image (until the project is Revealed).
  string contractURI; /// The (IPFS) URI that provides metadata for the Contract/Collection (https://docs.opensea.io/docs/contract-level-metadata).
  uint96 totalRoyalty; /// The total royalty to be transferred to the `PaymentSplitter` inside the `nft.withdraw()` method.
  uint256 maxSupply; /// The max number of Tokens that can be minted.
  uint256 maxTokensPerWallet; /// The max no. of tokens that can be minted per wallet.
  address pricePayoutWallet; /// This represents the Wallet address where the contract funds will be deposited on a `withdraw()`.
  address signatureVerifier; /// This represents the contract which verifies signatures for MultiSig and Vouchers.
  bytes32[] roles; /// The Access roles for the Nft Contracts.
  address[] roleAddresses; /// The addresses for the access roles.
  bytes32[] multisigRoles; /// The roles having Multisig Thresholds.
  uint256[] multisigThresholds; /// The Multisig threholds for a Role.
  address[] payees; /// The Payees participating in the PaymentSplitter.
  uint256[] shares; /// The shares assigned to each Payee participating in the PaymentSplitter.
}

/// @notice A struct representing the parameters passed into the ClosedSale Contracts.
struct ClosedSaleParams {
  string name; /// The name of the Nft collection.
  string symbol; /// The symbol for the Nft collection.
  string baseURI; /// The initial (IPFS) URI, which would point to the static metadata/image (until the project is Revealed).
  string contractURI; /// The (IPFS) URI that provides metadata for the Contract/Collection (https://docs.opensea.io/docs/contract-level-metadata).
  string provenance; /// The provenance for the images in the project.
  uint96 totalRoyalty; /// The total royalty to be transferred to the `PaymentSplitter` inside the `nft.withdraw()` method.
  uint256 maxSupply; /// The max number of Tokens that can be minted.
  uint256 maxTokensPerWallet; /// The max no. of tokens that can be minted per wallet.
  uint256 maxTokensPerTxn; /// The max no. of tokens that can be minted per Txn.
  address pricePayoutWallet; /// This represents the Wallet address where the contract funds will be deposited on a `withdraw()`.
  address signatureVerifier; /// This represents the contract which verifies signatures for MultiSig and Vouchers.
  bytes32[] roles; /// The Access roles for the Nft Contracts.
  address[] roleAddresses; /// The addresses for the access roles.
  bytes32[] multisigRoles; /// The roles having Multisig Thresholds.
  uint256[] multisigThresholds; /// The Multisig threholds for a Role.
  address[] payees; /// The Payees participating in the PaymentSplitter.
  uint256[] shares; /// The shares assigned to each Payee participating in the PaymentSplitter.
}

/// @notice A struct representing the payload for the Multisig parameter.
struct MultiSigParams {
  uint256 nonce;
  bytes[] signatures;
}

/// @notice A struct representing the payload for the minting Voucher.
struct VoucherParams {
  address buyer;
  uint256 issueTime;
  uint256 expirationDuration;
  uint256 pricePerToken;
  uint256 nonce;
  bytes signature;
}

struct RoleData {
  mapping(address => bool) members;
}

/**
  @dev This struct is not used in Production.
        Its only used in unit tests along with the TestSignatureVerifierV5 contract.
 */
struct TestSignatureVerifierParams {
  address signatureVerifier; /// This address represents the singleton contract which verifies signatures for MultiSig and Vouchers.
  bytes32[] roles; /// The Access roles for the Nft Contract.
  address[] roleAddresses; /// The addresses for the access roles.
  bytes32[] multisigRoles; /// The roles having Multisig Thresholds.
  uint256[] multisigThresholds; /// The Multisig threholds for a Role.
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { RoleData } from "./StructsV5.sol";

/**
  A list of Storage variables accessed via `delegatecall()`
  This will be the Base Contract for the NFT contract and the SignatureVerifier singleton contract,
    so that they can have the same Storage variable layout for shared variables used in `delegatecall()`
 */
abstract contract SharedVarsV5 {
  //  Filled in from Initialization
  mapping(bytes32 => RoleData) internal _roles;
  mapping(bytes32 => uint256) internal _roleThreshold;

  //  Updated when requests are processed
  mapping(uint256 => bool) internal _multisigNonces;
  mapping(uint256 => bool) internal _voucherNonces;
  mapping(uint256 => mapping(address => bool)) internal _nonceSigners;
  mapping(uint256 => bool) internal _pausedTokenIds;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

bytes32 constant ABI_MULTISIG_NO_PARAM = keccak256("MultiSig(uint256 nonce,string functionABI)");
bytes32 constant ABI_MULTISIG_REVEAL_SALE = keccak256("MultiSig(string baseURI,uint256 nonce,string functionABI)");
bytes32 constant ABI_MULTISIG_PAUSE_TOKEN = keccak256(
  "MultiSig(uint256[] tokenIds,bool pause,uint256 nonce,string functionABI)"
);
bytes32 constant ABI_MULTISIG_UPDATE_ROLE_ROYALTY_PAYOUT = keccak256(
  "MultiSig(bytes32[] grantRoles,address[] grantRoleAddresses,bytes32[] revokeRoles,address[] revokeRoleAddresses,uint96 totalRoyalty,address[] payees,uint256[] shares,address[] pricePayoutWallets,uint256 nonce,string functionABI)"
);

bytes32 constant ABI_VOUCHER_OPEN_SALE_MINT = keccak256(
  "Voucher(uint256 tokenId,address buyer,uint256 issueTime,uint256 expirationDuration,uint256 pricePerToken,uint256 nonce,string functionABI)"
);
bytes32 constant ABI_VOUCHER_CLOSED_SALE_MINT = keccak256(
  "Voucher(address buyer,uint256 issueTime,uint256 expirationDuration,uint256 pricePerToken,uint256 nonce,string functionABI)"
);

bytes32 constant ABI_TOGGLE_SALE = keccak256(bytes("toggleSaleState(MultiSigParams)"));
bytes32 constant ABI_PAUSE_STATE = keccak256(bytes("togglePauseState(MultiSigParams)"));
bytes32 constant ABI_PAUSE_TOKEN = keccak256(bytes("pauseTokens(uint256[],bool,MultiSigParams)"));
bytes32 constant ABI_REVEAL_SALE = keccak256(bytes("revealSale(string,MultiSigParams)"));
bytes32 constant ABI_OPEN_SALE_MINT = keccak256(bytes("mintToken(uint256,VoucherParams)"));
bytes32 constant ABI_CLOSED_SALE_MINT = keccak256(bytes("mintTokens(uint256,VoucherParams)"));
bytes32 constant ABI_WITHDRAW = keccak256(bytes("withdraw(MultiSigParams)"));
bytes32 constant ABI_UPDATE_ROLE_ROYALTY_PAYOUT = keccak256(
  bytes(
    "updateRoleRoyaltyPayout(bytes32[],address[],bytes32[],address[],uint96,address[],uint256[],address[],MultiSigParams)"
  )
);

string constant ABI_VERIFY_MULTISIG = "verifyMultiSig(bytes,(uint256,bytes[]),bytes32)";
string constant ABI_VERIFY_VOUCHER = "verifyVoucher(bytes,(address,uint256,uint256,uint256,uint256,bytes),bytes32)";

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

import "./AccessControlV5.sol";
import { MultiSigParams, VoucherParams } from "./StructsV5.sol";
import { ABI_MULTISIG_NO_PARAM, ABI_VERIFY_MULTISIG, ABI_VERIFY_VOUCHER, ABI_MULTISIG_PAUSE_TOKEN, ABI_MULTISIG_UPDATE_ROLE_ROYALTY_PAYOUT, ABI_TOGGLE_SALE, ABI_PAUSE_STATE, ABI_WITHDRAW, ABI_PAUSE_TOKEN, ABI_UPDATE_ROLE_ROYALTY_PAYOUT } from "./FunctionAbiV5.sol";

/**
    @notice This contract is the common base for the NFT Sale types (Open/Closed).
 */
abstract contract Erc721SaleV5 is AccessControlV5, ERC721, ERC721Royalty, ERC721Pausable {
  string public baseURI;
  string public contractURI;
  uint256 public maxSupply;
  uint256 public totalSupply = 0;
  uint256 public maxTokensPerWallet;
  uint256 public paymentSplittersCount;
  address public pricePayoutWallet;
  address public signatureVerifier;
  address payable[] public paymentSplittersHistory;
  bool public isSaleActive;

  event NftDeployed(address indexed owner, address indexed nft, address indexed paymentSplitter);
  event SaleActiveChanged(bool isSaleActive);
  event Withdraw(
    uint256 contractBalance,
    address indexed pricePayoutWallet,
    uint256 withdrawAmount,
    address indexed royaltyAddress,
    uint256 royaltyAmount
  );
  event PaymentSplitterUpdated(address oldPaymentSplitter, address newPaymentSplitter);
  event TokensPaused(uint256[] tokenIds, bool pause, address sender);
  event UpdatedRoleRoyaltyPricePayout(
    bytes32[] grantRoles,
    address[] grantRoleAddresses,
    bytes32[] revokeRoles,
    address[] revokeRoleAddresses,
    uint96 totalRoyalty,
    address[] payees,
    uint256[] shares,
    address[] pricePayoutWallets
  );

  constructor(
    string memory name_,
    string memory symbol_,
    string memory baseURI_,
    string memory contractURI_,
    uint256 maxSupply_,
    uint256 maxTokensPerWallet_,
    address pricePayoutWallet_,
    address signatureVerifier_,
    bytes32[] memory roles_,
    address[] memory roleAddresses_,
    bytes32[] memory multisigRoles_,
    uint256[] memory multisigThresholds_,
    uint96 totalRoyalty_,
    address[] memory payees_,
    uint256[] memory shares_
  ) AccessControlV5(roles_, roleAddresses_, multisigRoles_, multisigThresholds_) ERC721(name_, symbol_) {
    require(bytes(name_).length > 0, "01");
    require(bytes(baseURI_).length > 0, "02");
    require(maxSupply_ > 0, "04");
    require(maxTokensPerWallet_ > 0 && maxTokensPerWallet_ <= maxSupply_, "06");
    require(pricePayoutWallet_ != address(0), "21");
    require(signatureVerifier_ != address(0), "36");
    require(roles_.length == roleAddresses_.length && roles_.length > 0, "08");
    require(multisigRoles_.length == multisigThresholds_.length, "30");

    baseURI = baseURI_;
    contractURI = contractURI_; //  If N/A, then any non-zero length string can be passed in. e.g: `none`
    maxSupply = maxSupply_;
    maxTokensPerWallet = maxTokensPerWallet_;
    pricePayoutWallet = pricePayoutWallet_;
    signatureVerifier = signatureVerifier_;

    _addPaymentSplitter(totalRoyalty_, payees_, shares_);
  }

  function _beforeTokenTransfer(
    address from_,
    address to_,
    uint256 tokenId_
  ) internal override(ERC721, ERC721Pausable) {
    require(!_pausedTokenIds[tokenId_], "34");

    if (from_ == address(0)) {
      totalSupply++;
    } else if (to_ == address(0)) {
      totalSupply--;
    }
    super._beforeTokenTransfer(from_, to_, tokenId_);
  }

  /**
        @param tokenId_ The tokenId to be burned
    */
  function _burn(uint256 tokenId_) internal override(ERC721, ERC721Royalty) {
    super._burn(tokenId_);
  }

  /**
        @param interfaceId_ The interfaceId supported by the Contract
    */
  function supportsInterface(bytes4 interfaceId_) public view override(ERC721, ERC721Royalty) returns (bool) {
    return super.supportsInterface(interfaceId_);
  }

  /**
        @dev Returns the current PaymentSplitter active in the Contract.
            If no royalties have been set, then it returns address(0) 
    */
  function currentPaymentSplitter() public view returns (address) {
    if (paymentSplittersCount > 0) {
      return paymentSplittersHistory[paymentSplittersCount - 1];
    }
    return address(0);
  }

  /**
        @dev This function toggles the `isSaleActive` state (`true` <-> `false`).
                Minting can happen only if `isSaleActive == true`.
        @param params_ Parameters for a MultiSig validation.
    */
  function toggleSaleState(MultiSigParams calldata params_) external onlyRole(CONTRACT_ADMIN_ROLE) whenNotPaused {
    _verifyMultisig(abi.encode(ABI_MULTISIG_NO_PARAM, params_.nonce, ABI_TOGGLE_SALE), params_, CONTRACT_ADMIN_ROLE);

    isSaleActive = !isSaleActive;
    emit SaleActiveChanged(isSaleActive);
  }

  /**
        @dev This function toggles the `pause` state (`true` <-> `false`).
                Admin tasks can be performed only if `pause != true`.
        @param params_ Parameters for a MultiSig validation.                
    */
  function togglePauseState(MultiSigParams calldata params_) external onlyRole(CONTRACT_ADMIN_ROLE) {
    _verifyMultisig(abi.encode(ABI_MULTISIG_NO_PARAM, params_.nonce, ABI_PAUSE_STATE), params_, CONTRACT_ADMIN_ROLE);

    if (paused()) {
      _unpause();
    } else {
      _pause();
    }
  }

  /**
        @dev This function is used to withdraw the contract funds into the foll. wallets.
            - msg.Sender (should be a wallet in FINANCE_ADMIN_ROLE).
            - paymentSplitter/royalty if defined.
        @param params_ Parameters for a MultiSig validation.            
    */
  function withdraw(MultiSigParams calldata params_) external onlyRole(FINANCE_ADMIN_ROLE) whenNotPaused {
    _verifyMultisig(abi.encode(ABI_MULTISIG_NO_PARAM, params_.nonce, ABI_WITHDRAW), params_, FINANCE_ADMIN_ROLE);

    uint256 balance = address(this).balance;
    require(balance > 0, "24");
    (address paymentSplitterAddress, uint256 royaltyAmount) = this.royaltyInfo(0, balance); // Any TokenId can be passed as param. Defaulting to 0
    uint256 withdrawerAmount = balance - royaltyAmount;

    Address.sendValue(payable(pricePayoutWallet), withdrawerAmount);
    if (paymentSplitterAddress != address(0)) Address.sendValue(payable(paymentSplitterAddress), royaltyAmount);
    emit Withdraw(balance, pricePayoutWallet, withdrawerAmount, paymentSplitterAddress, royaltyAmount);
  }

  /**
        @dev This method can be called to pause/unpause any Transfers related to a TokenId.
        @param tokenIds_ The list of tokenIds to be paused/unpaused.
        @param pause_ A boolean determining a pause/unpause action (true:pause, false:unpause).
        @param params_ Parameters for a MultiSig validation.
    */
  function pauseTokens(
    uint256[] calldata tokenIds_,
    bool pause_,
    MultiSigParams calldata params_
  ) external onlyRole(CONTRACT_ADMIN_ROLE) whenNotPaused {
    require(tokenIds_.length > 0, "33");
    _verifyMultisig(
      abi.encode(
        ABI_MULTISIG_PAUSE_TOKEN,
        keccak256(abi.encodePacked(tokenIds_)),
        pause_,
        params_.nonce,
        ABI_PAUSE_TOKEN
      ),
      params_,
      CONTRACT_ADMIN_ROLE
    );

    //  Add or Remove Pause for tokenIds in the list
    for (uint256 i = 0; i < tokenIds_.length; i++) {
      //  Check if TokenId exists before attempting to Pause it. Ignore if it doesnt exist.
      if (pause_ && _exists(tokenIds_[i])) {
        _pausedTokenIds[tokenIds_[i]] = true;
      } else if (!pause_) {
        //  If Token Id does not exist, nothing will be deleted by the below Statement
        delete _pausedTokenIds[tokenIds_[i]];
      }
    }
    emit TokensPaused(tokenIds_, pause_, msg.sender);
  }

  /**
        @dev This method can be called to update Roles, Royalties(PaymentSplitter) and PricePayoutWallet.
        @param grantRoles_ The roles to grant access to.
        @param grantRoleAddresses_ The addresses for the granted roles.
        @param revokeRoles_ The roles to revoke access from.
        @param revokeRoleAddresses_ The addresses for the revoked roles.
        @param totalRoyalty_ The total royalty to be transferred to the `PaymentSplitter` inside the `nft.withdraw()` method.
        @param payees_ The Payees participating in the PaymentSplitter.
        @param shares_ The shares assigned to each Payee participating in the PaymentSplitter.
        @param pricePayoutWallets_ The list of tokenIds to be paused/unpaused.
    */
  function updateRoleRoyaltyPayout(
    bytes32[] memory grantRoles_,
    address[] memory grantRoleAddresses_,
    bytes32[] memory revokeRoles_,
    address[] memory revokeRoleAddresses_,
    uint96 totalRoyalty_,
    address[] memory payees_,
    uint256[] memory shares_,
    address[] memory pricePayoutWallets_,
    MultiSigParams calldata params_
  ) external onlyRole(CONTRACT_ADMIN_ROLE) whenNotPaused {
    _updateRoles(grantRoles_, grantRoleAddresses_, revokeRoles_, revokeRoleAddresses_);

    _verifyMultisig(
      abi.encode(
        ABI_MULTISIG_UPDATE_ROLE_ROYALTY_PAYOUT,
        keccak256(abi.encodePacked(grantRoles_)),
        keccak256(abi.encodePacked(grantRoleAddresses_)),
        keccak256(abi.encodePacked(revokeRoles_)),
        keccak256(abi.encodePacked(revokeRoleAddresses_)),
        totalRoyalty_,
        keccak256(abi.encodePacked(payees_)),
        keccak256(abi.encodePacked(shares_)),
        keccak256(abi.encodePacked(pricePayoutWallets_)),
        params_.nonce,
        ABI_UPDATE_ROLE_ROYALTY_PAYOUT
      ),
      params_,
      CONTRACT_ADMIN_ROLE
    );

    _addPaymentSplitter(totalRoyalty_, payees_, shares_);
    _updatePricePayoutWallet(pricePayoutWallets_);

    emit UpdatedRoleRoyaltyPricePayout(
      grantRoles_,
      grantRoleAddresses_,
      revokeRoles_,
      revokeRoleAddresses_,
      totalRoyalty_,
      payees_,
      shares_,
      pricePayoutWallets_
    );
  }

  /**
        @dev This method can be called to mark a Multisig Nonce as "used" in a Multisig Rejection workflow.
              This prevents the nonce from being used again in a Multisig Txn
        @param nonce_ The nonce to be marked as used.
    */
  function markMultisigNonceUsed(uint256 nonce_) external {
    require(hasRole(CONTRACT_ADMIN_ROLE, msg.sender) || hasRole(FINANCE_ADMIN_ROLE, msg.sender), "10");
    _multisigNonces[nonce_] = true;
  }

  /**
        @dev This method can be called externally when a change or correction is reqd in the Payee/Share ratio in the PaymentSplitter.
            The new PaymentSplitter does not replace the existing PaymentSplitter, but gets added to the array, and becomes the `current` PaymentSplitter.
        @param totalRoyalty_ The total royalty to be transferred to the `PaymentSplitter` inside the `nft.withdraw()` method.
        @param payees_ The Payees participating in the PaymentSplitter.
        @param shares_ The shares assigned to each Payee participating in the PaymentSplitter.  
    */
  function _addPaymentSplitter(
    uint96 totalRoyalty_,
    address[] memory payees_,
    uint256[] memory shares_
  ) internal {
    require(totalRoyalty_ >= 0 && totalRoyalty_ <= 10000, "11");

    if (totalRoyalty_ > 0) {
      address payable oldPaymentSplitterAddress = payable(currentPaymentSplitter());

      PaymentSplitter paymentSplitter = new PaymentSplitter(payees_, shares_);
      address payable newPaymentSplitterAddress = payable(address(paymentSplitter));
      paymentSplittersHistory.push(newPaymentSplitterAddress);
      paymentSplittersCount++;

      _setDefaultRoyalty(newPaymentSplitterAddress, totalRoyalty_); //  ERC721Royalty / ERC2981

      emit PaymentSplitterUpdated(oldPaymentSplitterAddress, newPaymentSplitterAddress);
    }
  }

  function _updatePricePayoutWallet(address[] memory pricePayoutWallets_) internal {
    require(pricePayoutWallets_.length <= 1, "08");

    if (pricePayoutWallets_.length == 1) {
      require(pricePayoutWallets_[0] != address(0), "21");
      pricePayoutWallet = pricePayoutWallets_[0];
    }
  }

  function _verifyMultisig(
    bytes memory payload_,
    MultiSigParams calldata params_,
    bytes32 role_
  ) internal {
    (bool success, bytes memory result) = signatureVerifier.delegatecall(
      abi.encodeWithSignature(ABI_VERIFY_MULTISIG, payload_, params_, role_)
    );
    string memory decodedResult = "29";
    if (success) decodedResult = abi.decode(result, (string));
    require(keccak256(abi.encodePacked(decodedResult)) == keccak256(abi.encodePacked("0")), decodedResult);
  }

  function _verifyVoucher(
    bytes memory payload_,
    VoucherParams calldata params_,
    bytes32 role_
  ) internal {
    (bool success, bytes memory result) = signatureVerifier.delegatecall(
      abi.encodeWithSignature(ABI_VERIFY_VOUCHER, payload_, params_, role_)
    );
    string memory decodedResult = "29";
    if (success) decodedResult = abi.decode(result, (string));
    require(keccak256(abi.encodePacked(decodedResult)) == keccak256(abi.encodePacked("0")), decodedResult);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./SharedVarsV5.sol";

/**
    @notice This contract manages Ownership, Roles and AccessControl.
 */
abstract contract AccessControlV5 is SharedVarsV5, Ownable {
  bytes32 internal constant CONTRACT_ADMIN_ROLE = keccak256("CONTRACT_ADMIN_ROLE");
  bytes32 internal constant FINANCE_ADMIN_ROLE = keccak256("FINANCE_ADMIN_ROLE");
  bytes32 internal constant VOUCHER_SIGNER_ROLE = keccak256("VOUCHER_SIGNER_ROLE");

  event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
  event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

  constructor(
    bytes32[] memory roles_,
    address[] memory roleAddresses_,
    bytes32[] memory multisigRoles_,
    uint256[] memory multisigThresholds_
  ) {
    //  Always add the deployer to the CONTRACT_ADMIN_ROLE.
    _grantRole(CONTRACT_ADMIN_ROLE, msg.sender);

    //  Initialize the other Roles.
    for (uint256 i = 0; i < roles_.length; i++) {
      _grantRole(roles_[i], roleAddresses_[i]);
    }

    //  Initialize the Multisig Role Thresholds.
    for (uint256 i = 0; i < multisigRoles_.length; i++) {
      _roleThreshold[multisigRoles_[i]] = multisigThresholds_[i];
    }
  }

  /**
   * @dev Modifier that checks that an account has a specific role.
   * Reverts with a standardized message including the required role.
   */
  modifier onlyRole(bytes32 role) {
    require(hasRole(role, msg.sender), "10");
    _;
  }

  /**
   * @dev Returns `true` if `account` has been granted `role`.
   */
  function hasRole(bytes32 role, address account) public view returns (bool) {
    return _roles[role].members[account];
  }

  /**
   * @dev Grants `role` to `account`.
   */
  function _grantRole(bytes32 role, address account) internal virtual {
    if (!hasRole(role, account)) {
      _roles[role].members[account] = true;
      emit RoleGranted(role, account, msg.sender);
    }
  }

  /**
   * @dev Revokes `role` from `account`.
   */
  function _revokeRole(bytes32 role, address account) internal virtual {
    if (hasRole(role, account)) {
      _roles[role].members[account] = false;
      emit RoleRevoked(role, account, msg.sender);
    }
  }

  /**
   * @dev Grants and/or Revokes `role` to `account`.
   * @param grantRoles_ An existing role in which to add the account
   * @param grantRoleAddresses_ The account to add into an existing role
   * @param revokeRoles_ An existing role from which to remove the account
   * @param revokeRoleAddresses_ The account to remove from an existing role
   */
  function _updateRoles(
    bytes32[] memory grantRoles_,
    address[] memory grantRoleAddresses_,
    bytes32[] memory revokeRoles_,
    address[] memory revokeRoleAddresses_
  ) internal {
    require(
      grantRoles_.length == grantRoleAddresses_.length && revokeRoles_.length == revokeRoleAddresses_.length,
      "08"
    );

    if (grantRoles_.length > 0) {
      for (uint256 i = 0; i < grantRoles_.length; i++) {
        _grantRole(grantRoles_[i], grantRoleAddresses_[i]);
      }
    }

    if (revokeRoles_.length > 0) {
      for (uint256 i = 0; i < revokeRoles_.length; i++) {
        _revokeRole(revokeRoles_[i], revokeRoleAddresses_[i]);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `tokenId` must be already minted.
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/ERC721Royalty.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../common/ERC2981.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev Extension of ERC721 with the ERC2981 NFT Royalty Standard, a standardized way to retrieve royalty payment
 * information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC721Royalty is ERC2981, ERC721 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is ERC721, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

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
     * by default, can be overridden in child contracts.
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
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/utils/SafeERC20.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract PaymentSplitter is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(account, totalReceived, released(account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token, address account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        uint256 payment = _pendingPayment(account, totalReceived, released(token, account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
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
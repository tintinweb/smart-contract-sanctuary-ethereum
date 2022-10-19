// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { TokenType } from "./IToken.sol";
import { VariablePriceContract } from "./IVariablePrice.sol";

/// @Nnotice the payment type for the token
enum PaymentType {
    Ether,
    ERC20
}

/// @notice the multisale purchase
struct MultiSalePurchase {
    uint256 multiSaleId;
    address purchaser;
    address receiver;
    uint256 quantity;
}
    
/// @notice the merkle proof for the token sale
struct MultiSaleProof {
    uint256 leaf;
    uint256 total;
    bytes32[] merkleProof;
}

/// @notice the settings for the token sale,
struct MultiSaleSettings {

    TokenType tokenType; // the type of token being sold
    address token; // the token being sold
    uint256 tokenHash; // the token hash being sold. set to 0 to autocreate hash

    uint256 whitelistHash; // the whitelist hash. set to 0 for owhitelist
    bool whitelistOnly; // if true, only whitelisted addresses can purchase

    // owner and payee
    address owner; // the owner of the contract
    address payee; // the payee of the co ntract

    string symbol; // the symbol of the token
    string name; // the name of the token
    string description; // the description of the token

    // open state
    bool openState; // open or closed
    uint256 startTime; // block number when the sale starts
    uint256 endTime; // block number when the sale ends

    // quantitiesp
    uint256 maxQuantity; // max number of tokens that can be sold
    uint256 maxQuantityPerSale; // max number of tokens that can be sold per sale
    uint256 minQuantityPerSale; // min number of tokens that can be sold per sale
    uint256 maxQuantityPerAccount; // max number of tokens that can be sold per account

    PaymentType paymentType; // the type of payment that is being used
    address tokenAddress; // the address of the payment token, if payment type is TOKEN

    uint256 nextSaleId; // the next sale id
    VariablePriceContract price; // the variable prices

}

/// @notice the multi sale contract
struct MultiSaleContract {
    MultiSaleSettings settings;

    uint256 nonce;
    uint256 totalPurchased;
        
    mapping(address => uint256) purchased;
    mapping(uint256 => uint256) _redeemedData;
    mapping(address => uint256) _redeemedDataQuantities;
    mapping(address => uint256) _totalDataQuantities;
}

/// @notice the multi sale storage
struct MultiSaleStorage {
    // the nonce
    uint256 tsnonce;
    mapping(uint256 => MultiSaleContract) _tokenSales; // token sale settings
    uint256[] _tokenSaleIds;
}


interface IMultiSale {

    // @notice emitted when a token sale is created
    event MultiSaleCreated(uint256 indexed tokenSaleId, MultiSaleSettings settings);

    /// @notice emitted when a token is opened
    event MultiSaleOpen (uint256 indexed tokenSaleId, MultiSaleSettings tokenSale);

    /// @notice emitted when a token is opened
    event MultiSaleClosed (uint256 indexed tokenSaleId);

    /// @notice emitted when a token is opened
    event MultiSaleSold (uint256 indexed tokenSaleId, address indexed purchaser, uint256[] tokenIds, bytes data);

    // token settings were updated
    event MultiSaleUpdated (uint256 indexed tokenSaleId, MultiSaleSettings tokenSale );

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice the definition for a token.
struct TokenDefinition {
    address token;
    string name;
    string symbol;
    string description;
    uint256 totalSupply;
    string imageName;
    string[] imagePalette;
    string externalUrl;
}

enum TokenType {
    ERC20,
    ERC721,
    ERC1155
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;


/// @notice DIctates how the price of the token is increased post every sale
enum PriceModifier {
    None,
    Fixed,
    Exponential,
    InverseLog
}

struct VariablePriceContract {
    // the price of the token
    uint256 price;
        // how the price is modified
    PriceModifier priceModifier;
    // only used if priceModifier is EXPONENTIAL or INVERSELOG or FIXED
    uint256 priceModifierFactor;
    // max price for the token
    uint256 maxPrice;
}

struct VariablePriceStorage {
    // the price of the token
    VariablePriceContract variablePrices;
}

/// @notice common struct definitions for tokens
interface IVariablePrice {
    /// @notice get the increased price of the token
    function getIncreasedPrice() external view returns (uint256);

    /// @notice get the increased price of the token
    function getTokenPrice() external view returns (VariablePriceContract memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library MerkleProof {

  function verify(
    bytes32 root,
    bytes32 leaf,
    bytes32[] memory proof
  )
    public
    pure
    returns (bool)
  {
    bytes32 computedHash = leaf;

    for (uint256 i = 0; i < proof.length; i++) {
      bytes32 proofElement = proof[i];

      if (computedHash <= proofElement) {
        // Hash(current computed hash + current element of the proof)
        computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
      } else {
        // Hash(current element of the proof + current computed hash)
        computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
      }
    }

    // Check if the computed hash (root) is equal to the provided root
    return computedHash == root;
  }

  function getHash(address a, uint256 b) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(a, b));
  }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "./MerkleProof.sol";

import "../interfaces/IMultiSale.sol";
import "../interfaces/IVariablePrice.sol";

import "./VariablePriceLib.sol";

import "../utilities/InterfaceChecker.sol";


library MultiSaleLib {

    bytes32 internal constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.nextblock.bitgem.app.MultiSaleStorage.storage");

    /// @notice get the storage for the multisale
    /// @return ds the storage
    function multiSaleStorage()
        internal
        pure
        returns (MultiSaleStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @notice get a new tokensale id
    /// @return tokenSaleId the new id
    function _createTokenSale() internal returns (uint256 tokenSaleId) {

        // set settings object
        tokenSaleId = uint256(
            keccak256(
                abi.encodePacked(multiSaleStorage().tsnonce++, address(this))
            )
        );
    }

    /// @notice validate the token purchase
    /// @param self the multisale storage
    /// @param valueAttached the value attached to the transaction
    function _validatePurchase(
        MultiSaleContract storage self, 
        VariablePriceContract storage priceContract,
        uint256 quantity, 
        uint256 valueAttached) internal view {

        MultiSaleSettings storage settings = self.settings;

        // make sure there are still tokens to purchase
        require(settings.maxQuantity == 0 || (settings.maxQuantity != 0 &&
            self.totalPurchased < settings.maxQuantity), "soldout" );

        // make sure the max qty per sale is not exceeded
        require(settings.minQuantityPerSale == 0 || (settings.minQuantityPerSale != 0 &&
            quantity >= settings.minQuantityPerSale), "qtytoolow");

        // make sure the max qty per sale is not exceeded
        require(settings.maxQuantityPerSale == 0 || (settings.maxQuantityPerSale != 0 &&
            quantity <= settings.maxQuantityPerSale), "qtytoohigh");

        // make sure token sale is started
        require(block.timestamp >= settings.startTime || settings.startTime == 0, "notstarted");

        // make sure token sale is not over
        require(block.timestamp <= settings.endTime || settings.endTime == 0,
            "saleended" );
         
        // gt thte total price 
        uint256 totalPrice = priceContract.price * quantity;
        require(totalPrice <= valueAttached, "notenoughvalue");
    }
    
    /// @notice validate the token purchase using the given proof
    /// @param self the multisale storage
    /// @param purchaseProof the proof
    function _validateProof(
        MultiSaleContract storage self,
        MultiSalePurchase memory purchase,
        MultiSaleProof memory purchaseProof
    ) internal {
        if (self.settings.whitelistOnly) {

            // check that the airdrop has not yet been redeemed by the user
            require(!_airdropRedeemed(self, purchase.receiver), "redeemed");

            // check to see if redeemed already
            uint256 _redeemedAmt = self._redeemedDataQuantities[purchase.receiver];
            uint256 _redeemedttl = self._totalDataQuantities[purchase.receiver];
            _redeemedttl = _redeemedAmt > 0 ? _redeemedttl : purchaseProof.total;

            // ensure that the user has not redeemed more than the total
            require(_redeemedAmt + purchase.quantity <= _redeemedttl, "redeemed");
            self._totalDataQuantities[purchase.receiver] = _redeemedttl;
            self._redeemedDataQuantities[purchase.receiver] += purchase.quantity; // increment amount redeemed

            // check the proof
            bool valid = MerkleProof.verify(
                bytes32 (self.settings.whitelistHash),
                bytes32 (purchaseProof.leaf), purchaseProof.merkleProof
            );

            // Check the merkle proof
            require(valid, "Merkle proof failed");
        }
    }

    /// @notice airdrops check to see if proof is redeemed
    /// @param recipient the merkle proof
    /// @return isRedeemed the amount of tokens redeemed
    function _airdropRedeemed(MultiSaleContract storage self, address recipient) internal view returns (bool isRedeemed) {

        uint256 red = self._totalDataQuantities[recipient];
        uint256 tot = self._redeemedDataQuantities[recipient]; // i
        isRedeemed = red != 0 && red == tot;
    }

    /// @notice purchase a token sale token without any proof
    /// @param self the token sale id
    /// @param purchase the token hash
    function __purchase(
        MultiSaleContract storage self,
        MultiSalePurchase memory purchase,
        VariablePriceContract memory variablePrice,
        uint256 valueAttached
    ) internal {
        // transfer the payment to the contract if erc20
        if (self.settings.paymentType == PaymentType.ERC20 &&
            self.settings.tokenAddress != address(0)) {
            uint256 purchaseAmount = purchase.quantity * variablePrice.price;
            require(purchaseAmount > 0, "invalidamount");
            _transferErc20PaymkentToContract(
                purchase.purchaser,
                self.settings.tokenAddress,
                purchaseAmount
            );
        } else {
            uint256 purchaseAmount = purchase.quantity * variablePrice.price;
            require(valueAttached >= purchaseAmount, "invalidamount");
        }
        // transfer the tokens to the receiver
        _transferPaymentToPayee(self, valueAttached);

    }    

    /// @notice purchase a token sale token without any proof
    /// @param self the token sale id
    /// @param purchase the token hash
    function _purchaseToken(
        MultiSaleContract storage self,
        VariablePriceContract storage variablePrice,
        MultiSalePurchase memory purchase,
        MultiSaleProof memory purchaseProof,
        uint256 valueAttached
    ) internal {

        // validate the purchase
        _validatePurchase(self, variablePrice, purchase.quantity, valueAttached);
        
        // validate the proof
        _validateProof(self, purchase, purchaseProof);

        // make the purchase
        __purchase(
            self, 
            purchase, 
            VariablePriceLib.variablePriceStorage().variablePrices,
            valueAttached);

    }

    /// @notice purchase a token sale token without any proof
    /// @param self the token sale id
    /// @param purchase the token hash
    function _purchaseToken(
        MultiSaleContract storage self,
        VariablePriceContract storage variablePrice,
        MultiSalePurchase memory purchase,
        uint256 valueAttached
    ) internal {

        // validate the purchase
        _validatePurchase(self, variablePrice, purchase.quantity, valueAttached);

        // make the purchase
        __purchase(self, purchase, variablePrice, valueAttached);
    }
    
    /// @notice transfer erc20 payment to the contract
    /// @param sender the sender of the payment
    /// @param paymentToken the token address
    /// @param paymentAmount the amount of payment
    function _transferErc20PaymkentToContract(
        address sender,
        address paymentToken,
        uint256 paymentAmount
    ) internal {

        // transfer payment to contract
        IERC20(paymentToken).transferFrom(sender, address(this), paymentAmount);
    }

    /// @notice transfer payment to the token sale payee
    /// @param self the token sale settings
    /// @param valueAttached the value attached to the transaction
    function _transferPaymentToPayee(MultiSaleContract storage self, uint256 valueAttached) internal {

        // transfer the payment to the payee if the payee address is set
        if (self.settings.payee != address(0)) {
            if (self.settings.paymentType == PaymentType.ERC20) {
                IERC20(self.settings.tokenAddress).transferFrom(
                    address(this),
                    self.settings.payee,
                    valueAttached
                );
            } else {
                payable(self.settings.payee).transfer(valueAttached);
            }
        }
    }

    /// @notice get the token type
    /// @param token the token id
    /// @return tokenType the token type
    function _getTokenType(address token)
        internal
        view
        returns (TokenType tokenType) {

        tokenType = InterfaceChecker.isERC20(token)
            ? TokenType.ERC20
            : InterfaceChecker.isERC721(token)
            ? TokenType.ERC721
            : TokenType.ERC1155;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IVariablePrice.sol";

library VariablePriceLib {
    event VariablePriceChanged(
        address eventContract,
        VariablePriceContract price
    );

    bytes32 internal constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.nextblock.bitgem.app.VariablePriceStorage.storage");

    /// @notice get the storage for variable pricing
    /// @return ds the storage
    function variablePriceStorage()
        internal
        pure
        returns (VariablePriceStorage storage ds) {

        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @notice update the variable price contract
    /// @param self the variable price contract
    function _updatePrice(VariablePriceContract storage self)
        internal
        returns (uint256 _price, uint256 updatedPrice) {

        _price = self.price;
        _increaseClaimPrice(self);
        updatedPrice = self.price;
    }

    /// @notice get the current price of the claim
    /// @return _price the current price of the claim
    function _currentPrice(VariablePriceContract storage self)
        internal
        view
        returns (uint256 _price) {

        _price = self.price;
    }

    function _setPrice(VariablePriceContract storage self, uint256 _price)
        internal
        returns (uint256 _newPrice) {

        self.price = _price;
        _newPrice = self.price;
    }
    
    /// @notice Increases the price of the claim by the price increase rate
    /// @param self The variable price contract
    function _increaseClaimPrice(VariablePriceContract storage self) internal {
        
        // get the current price
        uint256 currentPrice = self.price;
        // get the current modifier
        PriceModifier currentModifier = self.priceModifier;
        // get the current modifier factor
        uint256 currentModifierFactor = self.priceModifierFactor;

        // fixed price - increase by modifier factor
        if (currentModifier == PriceModifier.Fixed) {
            currentPrice = currentPrice + currentModifierFactor;
        }
        // exponential intcrease
        else if (currentModifier == PriceModifier.Exponential) {
            currentPrice =
                currentPrice +
                (currentPrice / currentModifierFactor);
        }
        // inverse log increase
        else if (currentModifier == PriceModifier.InverseLog) {
            currentPrice =
                currentPrice +
                (currentPrice / (currentModifierFactor * currentPrice));
        } else {
            return;
        }
        // set the new price
        self.price = currentPrice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { IERC1155 } from "@openzeppelin/contracts/interfaces/IERC1155.sol";
import { IERC721 } from "@openzeppelin/contracts/interfaces/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

library InterfaceChecker {
    function isERC1155(address check) internal view returns(bool) {
        return IERC165(check).supportsInterface(type(IERC1155).interfaceId);
    }
    function isERC721(address check) internal view returns(bool) {
        return IERC165(check).supportsInterface(type(IERC721).interfaceId);
    }
    function isERC20(address check) internal view returns(bool) {
        return IERC165(check).supportsInterface(type(IERC20).interfaceId);
    }
}
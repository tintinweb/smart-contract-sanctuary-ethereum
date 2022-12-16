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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

pragma solidity ^0.8.0;


/*
      ______      _____            _   _ _____   ____  _      ______ 
     |  ____/\   |  __ \     /\   | \ | |  __ \ / __ \| |    |  ____|
     | |__ /  \  | |__) |   /  \  |  \| | |  | | |  | | |    | |__   
     |  __/ /\ \ |  _  /   / /\ \ | . ` | |  | | |  | | |    |  __|  
     | | / ____ \| | \ \  / ____ \| |\  | |__| | |__| | |____| |____ 
     |_|/_/    \_\_|  \_\/_/    \_\_| \_|_____/ \____/|______|______|

*/

import "../project/SuperAccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract ERC20 {
    function transfer(address _to, uint256 _value) external virtual returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external virtual returns (bool);
}

/**
 * @title NFT Marketplace with ERC-2981 support
 * @notice Defines a marketplace to bid on and sell NFTs.
 *         Sends royalties to rightsholder on each sale if applicable.
 */
contract Marketplace is SuperAccessControl, ReentrancyGuard, Pausable {

    struct SellOffer {
        address seller;
        uint256 price;
        ERC20 currency;
    }

    struct BuyOffer {
        address buyer;
        uint256 price;
        uint256 createTime;
        // BuyOffer currency is stored in the mapping
    }

    bytes32 public constant MARKETPLACE_MANAGER_ROLE = keccak256('MARKETPLACE_MANAGER_ROLE');
    bytes32 public constant FEE_SETTER_ROLE = keccak256('FEE_SETTER_ROLE');

    // Store accepted ERC20 currencies of the contract
    mapping(ERC20 => bool) public acceptedCurrencies; 

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    // Store the address of the contract of the NFT to trade. Can be changed in
    // constructor or with a call to setTokenContractAddress.
    //address public _tokensAddresses = address(0);
    mapping(address => bool) public tokensAddresses;
    // Store all active sell offers and maps them to their respective token ids
    mapping( IERC721 => mapping(uint256 => SellOffer)) public activeSellOffers;
    // Store all active buy offers and maps them to their respective token ids and currency
    mapping( IERC721 => mapping(uint256 => mapping(ERC20 => BuyOffer))) public activeBuyOffers;
    // Escrow for buy offers
    mapping(IERC721 => mapping(address => mapping(uint256 => mapping(ERC20 =>uint256)))) public buyOffersEscrow;
    // Allow buy offers
    bool public allowBuyOffers = false;
    // Duration for offers in days
    uint public offersDuration = 180;

    // PAIEMENT, FEES
    // Store the address of farandole
    address public farandoleWallet;
    // Store per mil fee ratio ( = percentage x 10), allows to have a fee percentage with a decimal
    uint public feePerMil;
    uint public constant MAX_FEE_PERMIL = 100; //10% max
    // Store a max value for gas limit of .call method when transfering crypto
    // this allows the receiver to perform some action when receiving
    uint public transferMaxGas = 5000;


    // EVENTS
    event NewSellOffer(IERC721 token, uint256 tokenId, address seller, uint256 value, ERC20 currency);
    event NewBuyOffer(IERC721 token, uint256 tokenId, address buyer, uint256 value, ERC20 currency);
    event SellOfferWithdrawn(IERC721 token, uint256 tokenId, address seller);
    event BuyOfferWithdrawn(IERC721 token, uint256 tokenId, address buyer, ERC20 currency);
    event Sale(IERC721 token, uint256 tokenId, address seller, address buyer, uint256 value, ERC20 currency);
    event RoyaltiesAndFeesPaid(IERC721 token, uint256 tokenId, uint royaltyAmount, address royaltiesReceiver, uint feesAmount, address farandoleWallet);
    event OfferDurationChanged(uint newDuration);
    event TokenAdded(address tokenContract);
    event CurrencyAdded(ERC20 currency);
    event CurrencyRemoved(ERC20 currency);


    constructor(address superAdminAddressContract,
                address _farandoleWallet,
                uint16 _feePerMil,
                address[] memory _tokensAddresses,
                ERC20[] memory _acceptedCurrencies
    ) SuperAccessControl(superAdminAddressContract) {
        farandoleWallet = _farandoleWallet;
        require(_feePerMil <= MAX_FEE_PERMIL, 'unvalid fee feePerMil');
        feePerMil = _feePerMil;

        setupTokens(_tokensAddresses);
        setupAcceptedCurrencies(_acceptedCurrencies);
    }

    /// @notice can only add tokens to marketplace, not delete them
    function setupTokens(address[] memory _tokensAddresses) internal {
        for(uint i=0; i<_tokensAddresses.length; i++){
            require(_checkRoyalties(_tokensAddresses[i]), 'contract is not IERC2981');
            tokensAddresses[_tokensAddresses[i]] = true;
            emit TokenAdded(_tokensAddresses[i]);
        }
    }

    /// @notice can only add tokens to marketplace, not delete them
    function addTokens(address[] memory _tokensAddresses) public onlySuperRole(MARKETPLACE_MANAGER_ROLE) {
        for(uint i=0; i<_tokensAddresses.length; i++){
            require(_checkRoyalties(_tokensAddresses[i]), 'contract is not IERC2981');
            tokensAddresses[_tokensAddresses[i]] = true;
            emit TokenAdded(_tokensAddresses[i]);
        }
    }

    /// @notice add currencies accepted for paiement
    function setupAcceptedCurrencies(ERC20[] memory _acceptedCurrencies) internal {
        for(uint i=0; i<_acceptedCurrencies.length; i++){
            if(!acceptedCurrencies[_acceptedCurrencies[i]]){
              acceptedCurrencies[_acceptedCurrencies[i]] = true;
              emit CurrencyAdded(_acceptedCurrencies[i]);
            }
        }
    }

    /// @notice add currencies accepted for paiement
    function addAcceptedCurrencies(ERC20[] memory _acceptedCurrencies) public onlySuperRole(MARKETPLACE_MANAGER_ROLE) {
        for(uint i=0; i<_acceptedCurrencies.length; i++){
            if(!acceptedCurrencies[_acceptedCurrencies[i]]){
              acceptedCurrencies[_acceptedCurrencies[i]] = true;
              emit CurrencyAdded(_acceptedCurrencies[i]);
            }
        }
    }

    /// @notice remove currencies accepted for paiement
    function removeAcceptedCurrencies(ERC20[] memory _notAcceptedCurrencies) public onlySuperRole(MARKETPLACE_MANAGER_ROLE) {
        for(uint i=0; i<_notAcceptedCurrencies.length; i++){
            if(acceptedCurrencies[_notAcceptedCurrencies[i]]){
              acceptedCurrencies[_notAcceptedCurrencies[i]] = false;
              emit CurrencyRemoved(_notAcceptedCurrencies[i]);
            }
        }
    }     

    /// @notice Checks if NFT contract implements the ERC-2981 interface
    /// @param _contract - the address of the NFT contract to query
    /// @return true if ERC-2981 interface is supported, false otherwise
    function _checkRoyalties(address _contract) internal view returns (bool) {
        return IERC2981(_contract).supportsInterface(_INTERFACE_ID_ERC2981);
    }

    /// @notice Tax txn by transfering fees to Farandole and royalties to the rightsowner if applicable
    /// @param grossSaleValue - the price at which the asset will be sold
    /// @param tokenId - used to fetch the rightsowner and royalties amount
    /// @return netSaleAmount - the value that will go to the seller after deducting fees and royalties
    function _taxTxn(address sender, IERC721 token, uint tokenId, uint grossSaleValue, ERC20 currency) internal virtual returns (uint) {
        uint paidFees = _payFees(sender, grossSaleValue, currency);
        (uint paidRoyalties, address receiver) = _payRoyalties(sender, token, tokenId, grossSaleValue, currency);
        emit RoyaltiesAndFeesPaid(token, tokenId, paidRoyalties, receiver, paidFees, farandoleWallet);
        return grossSaleValue - (paidRoyalties + paidFees);
    }

    // function taxTxn(IERC721 token, uint tokenId, uint grossSaleValue, ERC20 currency) external virtual returns (uint) {
    //     return _taxTxn(token, tokenId, grossSaleValue, currency);
    // }    

    /// @notice Transfers fees to the Farandole
    /// @param grossSaleValue - the price at which the asset will be sold
    /// @return feesAmount - the fees that have been paid
    function _payFees(address sender, uint grossSaleValue, ERC20 currency) internal returns (uint) {
        // Get amount of fees to pay
        uint feesAmount = grossSaleValue*feePerMil/1000;
        // Transfer royalties to rightholder if not zero
        if (feesAmount > 0) {
            _processPayment(sender, farandoleWallet, feesAmount, currency);
        }
        // Broadcast fee payment
        return feesAmount;
    }

    /// @notice Transfers royalties to the rightsowner if applicable
    /// @param tokenId - the NFT assed queried for royalties
    /// @param grossSaleValue - the price at which the asset will be sold
    /// @return netSaleAmount - the value that will go to the seller after deducting royalties
    function _payRoyalties(address sender, IERC721 token, uint256 tokenId, uint256 grossSaleValue, ERC20 currency) internal returns (uint, address) {
        // Get amount of royalties to pays and recipient
        (address royaltiesReceiver, uint256 royaltiesAmount) = IERC2981(address(token)).royaltyInfo(tokenId, grossSaleValue);
        // Transfer royalties to rightholder if not zero
        if (royaltiesAmount > 0) {
            _processPayment(sender, royaltiesReceiver, royaltiesAmount, currency);
        }
        // Broadcast royalties payment
        return (royaltiesAmount, royaltiesReceiver);
    }

    /// @notice Credit an address of some amount and throw if it fails
    /// Setting the gaslimit to transferMaxGas to allow receiver wallet to perform action on receiving
    function _processPayment(address sender, address receiver, uint amount, ERC20 currency) internal {
        if (currency == ERC20(address(0))) {
          (bool sent, ) = payable(receiver).call{value: amount, gas: transferMaxGas}('');
          require(sent, "Could not transfer amount to receiver");
        } else {
            if (sender == address(this)) {
              require(currency.transfer(receiver, amount), "transfer failed");
            } else {
              require(currency.transferFrom(sender, receiver, amount), "transferFrom failed");
            }
        }
    }

    /// @notice Puts a token on sale at a given price
    /// @param tokenId - id of the token to sell
    /// @param price - minimum price at which the token can be sold
    function makeSellOffer(IERC721 token, uint256 tokenId, uint256 price, ERC20 currency)
    external tokenOnMarketplace(token) isMarketable(token, tokenId) whenNotPaused
    tokenOwnerOnly(token, tokenId) isAcceptedCurrency(currency) nonReentrant {
        // Create sell offer
        activeSellOffers[token][tokenId] = SellOffer({
            seller : _msgSender(),
            price : price,
            currency: currency
            });
        // Broadcast sell offer
        emit NewSellOffer(token, tokenId, _msgSender(), price, currency);
    }

    /// @notice Withdraw a sell offer
    /// @param tokenId - id of the token whose sell order needs to be cancelled
    function withdrawSellOffer(IERC721 token, uint256 tokenId)
    external tokenOnMarketplace(token) isMarketable(token, tokenId) nonReentrant {

        SellOffer memory activeSellOffer = activeSellOffers[token][tokenId];
        require(activeSellOffer.seller != address(0), "No sale offer");
        bool isAdmin = hasSuperRole(MARKETPLACE_MANAGER_ROLE, _msgSender());
        require(activeSellOffer.seller == _msgSender() || isAdmin, "Not seller nor owner");
        if(isAdmin && activeSellOffer.seller != _msgSender()){
            require(token.getApproved(tokenId) != address(this), "token is still approved");
        }
        // Removes the current sell offer
        delete (activeSellOffers[token][tokenId]);
        // Broadcast offer withdrawal
        emit SellOfferWithdrawn(token, tokenId, _msgSender());
    }

    /// @notice Purchases a token and transfers royalties if applicable
    /// @param tokenId - id of the token to sell
    function purchase(IERC721 token, uint256 tokenId)
    external tokenOnMarketplace(token) tokenOwnerForbidden(token, tokenId) nonReentrant payable {

        SellOffer memory activeSellOffer = activeSellOffers[token][tokenId];
        ERC20 currency = activeSellOffer.currency;

        address seller = activeSellOffer.seller;
        require(seller != address(0), "No active sell offer");

        // If, for some reason, the token is not approved anymore (transfer or
        // sale on another market place for instance), we remove the sell order
        // and throw
        // if (token.getApproved(tokenId) != address(this)) {
        //     delete (activeSellOffers[token][tokenId]);
        //     // Broadcast offer withdrawal
        //     emit SellOfferWithdrawn(token, tokenId, seller);
        //     // Revert
        //     revert("Invalid sell offer");
        // }

        // Pay royalties if applicable
        uint netSaleValue = _taxTxn(_msgSender(), token, tokenId, activeSellOffer.price, currency);
        // Transfer funds to the seller
        if (currency == ERC20(address(0))) {
            // Listing is in ETH
            require(msg.value == activeSellOffer.price, "value doesn't match offer");
            _processPayment(_msgSender(), seller, netSaleValue, currency);
        } else { // Listing is in ERC20
            require(msg.value == 0, "sent value would be lost");
            require(currency.transferFrom(_msgSender(), seller, netSaleValue), "transferFrom failed");
        }

        // And token to the buyer
        token.safeTransferFrom(seller, _msgSender(), tokenId);
        // Remove all sell and buy offers
        delete (activeSellOffers[token][tokenId]);
        delete (activeBuyOffers[token][tokenId][currency]);
        // Broadcast the sale
        emit Sale(token, tokenId, seller, _msgSender(), activeSellOffer.price, currency);
    }

    /// @notice Makes a buy offer for a token. The token does not need to have
    ///         been put up for sale. A buy offer can not be withdrawn or
    ///         replaced for 24 hours. Amount of the offer is put in escrow
    ///         until the offer is withdrawn or superceded
    /// @param tokenId - id of the token to buy
    function makeBuyOffer(IERC721 token, uint256 tokenId, uint value, ERC20 currency)
    external tokenOnMarketplace(token) tokenOwnerForbidden(token, tokenId)
    buyOffersAllowed isAcceptedCurrency(currency) nonReentrant whenNotPaused
    payable {
        // Reject the offer if item is already available for purchase at a
        // lower or identical price for the same currency
        if (activeSellOffers[token][tokenId].price != 0 && activeSellOffers[token][tokenId].currency == currency ) {
            require((value < activeSellOffers[token][tokenId].price), "Sell order at this price or lower exists");
        }

        // Only process the offer if it is higher than the previous one or the
        // previous one has expired
        require(activeBuyOffers[token][tokenId][currency].createTime < (block.timestamp - offersDuration*(1 days)) ||
                value > activeBuyOffers[token][tokenId][currency].price, "Previous buy offer higher or not expired");
        address previousBuyOfferOwner = activeBuyOffers[token][tokenId][currency].buyer;
        uint256 refundBuyOfferAmount = buyOffersEscrow[token][previousBuyOfferOwner][tokenId][currency];
        // Refund the owner of the previous buy offer
        buyOffersEscrow[token][previousBuyOfferOwner][tokenId][currency] = 0;
        if (refundBuyOfferAmount > 0) {
            _processPayment(address(this), previousBuyOfferOwner, refundBuyOfferAmount, currency);
        }
        // Create a new buy offer
        activeBuyOffers[token][tokenId][currency] = BuyOffer({
            buyer : _msgSender(),
            price : value,
            createTime : block.timestamp
        });
        // Create record of funds deposited for this offer
        buyOffersEscrow[token][_msgSender()][tokenId][currency] = value;

        //Verify and process payment
        if (currency == ERC20(address(0))) {
            // Listing is in ETH
            require(msg.value == value, "value doesn't match offer");
        } else { // Listing is in ERC20
            require(msg.value == 0, "sent value would be lost");
            require(currency.transferFrom(_msgSender(), address(this), value), "transferFrom failed");
        }
        // Broadcast the buy offer
        emit NewBuyOffer(token, tokenId, _msgSender(), value, currency);
    }

    /// @notice Withdraws a buy offer. 
    /// @param tokenId - id of the token whose buy order to remove
    function withdrawBuyOffer(IERC721 token, uint256 tokenId, ERC20 currency) external nonReentrant {
        address buyer = activeBuyOffers[token][tokenId][currency].buyer;
        // check sender is token owner or contract manager
        require(buyer == _msgSender() || hasSuperRole(MARKETPLACE_MANAGER_ROLE, _msgSender()) , "Not buyer or owner");
        uint256 refundBuyOfferAmount = buyOffersEscrow[token][buyer][tokenId][currency];
        // Set the buyer balance to 0 before refund
        buyOffersEscrow[token][buyer][tokenId][currency] = 0;
        // Remove the current buy offer
        delete(activeBuyOffers[token][tokenId][currency]);
        // Refund the current buy offer if it is non-zero
        if (refundBuyOfferAmount > 0) {
            _processPayment(address(this), buyer, refundBuyOfferAmount, currency);
        }
        // Broadcast offer withdrawal
        emit BuyOfferWithdrawn(token, tokenId, _msgSender(), currency);
    }

    /// @notice Lets a token owner accept the current buy offer
    ///         (even without a sell offer)
    /// @param tokenId - id of the token whose buy order to accept
    function acceptBuyOffer(IERC721 token, uint256 tokenId, ERC20 currency)
    external tokenOnMarketplace(token) isMarketable(token, tokenId) tokenOwnerOnly(token, tokenId) nonReentrant {
        address currentBuyer = activeBuyOffers[token][tokenId][currency].buyer;
        require(currentBuyer != address(0),"No buy offer");
        uint256 saleValue = activeBuyOffers[token][tokenId][currency].price;
        // Pay royalties if applicable
        uint256 netSaleValue = _taxTxn(address(this), token, tokenId, saleValue, currency);
        // Delete the current sell offer whether it exists or not
        delete (activeSellOffers[token][tokenId]);
        // Delete the buy offer that was accepted
        delete (activeBuyOffers[token][tokenId][currency]);
        // Withdraw buyer's balance
        buyOffersEscrow[token][currentBuyer][tokenId][currency] = 0;
        // Transfer funds to the seller
        _processPayment(address(this), _msgSender(), netSaleValue, currency);
        // And token to the buyer
        token.safeTransferFrom(_msgSender(),currentBuyer,tokenId);
        // Broadcast the sale
        emit Sale(token, tokenId, _msgSender(), currentBuyer, saleValue, currency);
    }

    // MODIFIERS

    modifier tokenOnMarketplace(IERC721 token) {
        require(tokensAddresses[address(token)], "Token is not on marketplace");
        _;
    }

    modifier isMarketable(IERC721 token, uint256 tokenId) {
        require(token.getApproved(tokenId) == address(this), "Not approved");
        _;
    }

    modifier tokenOwnerForbidden(IERC721 token, uint256 tokenId) {
        require(token.ownerOf(tokenId) != _msgSender(), "Token owner not allowed");
        _;
    }

    modifier tokenOwnerOnly(IERC721 token, uint256 tokenId) {
        require(token.ownerOf(tokenId) == _msgSender(), "Not token owner");
        _;
    }

    modifier buyOffersAllowed() {
        require(allowBuyOffers, "making new buy offer is not allowed");
        _;
    }

    modifier isAcceptedCurrency(ERC20 currency) {
        require(acceptedCurrencies[currency], "Currency is not accepted");
        _;
    }

    // SETTERS

    // allow or disallow to make new buy offers, old buy offers will not be impacted
    function setAllowBuyOffers(bool newValue) external onlySuperRole(MARKETPLACE_MANAGER_ROLE) {
        allowBuyOffers = newValue;
    }

    // allow or disallow to make new buy offers, old buy offers will not be impacted
    function setOffersDuration(uint newDuration) external onlySuperRole(MARKETPLACE_MANAGER_ROLE) {
        require(newDuration>0, 'newDuration is null');
        offersDuration = newDuration;
        emit OfferDurationChanged(newDuration);
    }

    // @notice set the new per mil fee ratio ( = percentage x 10)
    function setFeePerMil(uint16 _newFeePerMil) external onlySuperRole(FEE_SETTER_ROLE) {
        require(_newFeePerMil <= MAX_FEE_PERMIL, 'unvalid fee feePerMil');
        feePerMil = _newFeePerMil;
    }

    // @notice set the transferMaxGas
    function setTransferMaxGas(uint16 _newTransferMaxGas) external onlySuperRole(MARKETPLACE_MANAGER_ROLE) {
        require(_newTransferMaxGas > 2300, 'transferMaxGas must be > 2300');
        transferMaxGas = _newTransferMaxGas;
    }

    function pause() external onlySuperRole(CONTRACTS_ROLE) {
        _pause();
    }    

    function unpause() external onlySuperRole(CONTRACTS_ROLE) {
        _unpause();
    }        

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";

abstract contract ISuperAdmin {
    function checkRole(bytes32 role, address account) public view virtual;
    function paused() public view virtual returns (bool);
    function hasRole(bytes32 role, address account) public view virtual returns (bool);
    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32);    
}

abstract contract ISuperAdminAddress {
    function name() external pure virtual returns (string memory);
    function getAddress() external view virtual returns (address);
}

abstract contract SuperAccessControl is Context {
    
    bytes32 public constant CONTRACTS_ROLE = keccak256('CONTRACTS_ROLE');

    // address of the superAdminAddress contract used to retreive the SuperAdmin's address
    ISuperAdminAddress public superAdminAddressContract;

    constructor(address _superAdminAddressContract) {
        _checkName(_superAdminAddressContract);
        superAdminAddressContract = ISuperAdminAddress(_superAdminAddressContract);
    }

    // PAUSE

    modifier whenNotSuperPaused() {
        require(!ISuperAdmin(superAdminAddressContract.getAddress()).paused(), "Pausable: paused");
        _;
    }

    modifier whenSuperPaused() {
        require(ISuperAdmin(superAdminAddressContract.getAddress()).paused(), "Pausable: not paused");
        _;
    }

    // ROLES

    modifier onlySuperRole(bytes32 role) {
       checkSuperRole(role, _msgSender());
       _;
    }    

    function checkSuperRole(bytes32 role, address account) public view virtual {
        ISuperAdmin(superAdminAddressContract.getAddress()).checkRole(role, account);
    }

    function hasSuperRole(bytes32 role, address account) public view virtual returns (bool) {
        return ISuperAdmin(superAdminAddressContract.getAddress()).hasRole(role, account);
    }

    function getSuperRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
        return ISuperAdmin(superAdminAddressContract.getAddress()).getRoleAdmin(role);
    }    

    /*
        This function should be used only if SuperAdminAddress needs to be redeployed
        However SuperAdminAddress is meant to allow redeploying SuperAdmin while keeping the same proxy address
        for all contracts to querry (the address of SuperAdminAddress).
        The contract SuperAdminAddress is simple enough that it should not be redeployed in practice,
        because it's address would need to be replaced in all SuperAccessControl contracts, but it's still possible here
    */
    function setSuperAdminAddressContract(address newSuperAdminAddressContract) external virtual onlySuperRole(CONTRACTS_ROLE) {
        _checkName(newSuperAdminAddressContract);
        superAdminAddressContract = ISuperAdminAddress(newSuperAdminAddressContract);
    }

    // for safety, check the new address is the right kind of contract
    function _checkName(address superAdminContract) internal pure {
        require(keccak256(bytes(ISuperAdminAddress(superAdminContract).name()))
                 == keccak256(bytes('Farandole SuperAdminAddress')),
                'Trying to set the wrong contract address');       
    }    

}
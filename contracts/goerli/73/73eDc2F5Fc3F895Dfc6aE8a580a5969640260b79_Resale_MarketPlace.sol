//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../Tokens/IERC2981.sol";

contract Resale_MarketPlace is AccessControl {
	
	// Status of an offer
	enum OfferStatus{ OPEN, CLOSED, CANCELLED }

	// Data structure for the offers
	struct Offer {
		address sellerAddress;
		address contractAddress;
		uint tokenId;
		uint price;
		OfferStatus tradeStatus;
		address nodeAddress;
	}

	// Custom splits for an entire contract
	struct ContractCustomSplits {
		address[] recipients;
		uint[] percentages;
		uint precisionDecimals;
	}
	// Event emitted whenever an offer is created, completed or cancelled
	event OfferStatusChange(
		address operator,
		address tokenAddress,
		uint tokenId,
		uint price,
		OfferStatus status,
		uint tradeid
	);

	// Emitted whenever an offer is updated with a new price
	event UpdatedOfferPrice(
		uint offerId,
		address contractAddress,
		uint oldPrice,
		uint newPrice
	);

	// Emitted when the treasury address is updated
	event ChangedTreasuryAddress(address newTreasury);
		
	// Emitted whenever the treasury fee is updated, includes the current treasury address
	event ChangedTreasuryFee(address treasuryAddress, uint newTreasuryFee);
	
	// Emitted whenever the node fee is updated
	event ChangedNodeFee(uint newNodeFee);

	// Emitted when custom splits are set/removed
	event CustomRoyaltiesSet(address contractAddress, uint recipients, uint remainderForSeller);

	address public treasuryAddress;
	uint16 public feeDecimals = 3;

	// The limit for this is 65535
	uint public nodeFee = 1000;
	uint public treasuryFee = 9000;

	mapping(uint => Offer) private offers;
	mapping(address => ContractCustomSplits) private contractSplits;

	mapping(address => mapping(uint => bool)) public tokenOnSale;

	bool public paused = false;

	uint private tradeCounter;
	uint private offerCounter;

	/// @notice 	Ensures the marketplace isn't paused
	modifier isPaused() {
		require(paused == false, "Resale Marketplace: Currently paused");
		_;
	}

	/// @notice 	Ensures the offer being managed is open
	/// @param 		offerIndex 		Index of the offer to manage
	modifier OpenOffer(uint offerIndex) {
		require(offers[offerIndex].tradeStatus == OfferStatus.OPEN, "Resale Marketplace: Offer is not available");
		_;
	}

	/// @notice     Makes sure the function can only be called by the creator of a RAIR contract
	/// @param      contractAddress    Address of the RAIR ERC721 contract
	modifier OnlyTokenCreator(address contractAddress) {
		IERC2981 itemToken = IERC2981(contractAddress);
		require(
			itemToken.supportsInterface(type(IERC2981).interfaceId),
			"Resale Marketplace: Only the EIP-2981 receiver can be recognized as the creator"
		);
		(address creator,) = itemToken.royaltyInfo(0, 100000);
		require(contractAddress != address(0), "Resale Marketplace: Invalid address specified");
		require(
			creator == msg.sender,
			"Resale Marketplace: Only token creator can set custom royalties"
		);
		_;
	}

	/// @notice 	Ensures only the NFT's holder is able to manage the offer
	/// @param 		contractAddress 	Address of the ERC721 contract
	/// @param 		tokenId 			Index of the NFT
	modifier OnlyTokenHolder(address contractAddress, uint256 tokenId) {
		_onlyTokenHolder(contractAddress, tokenId);
		_;
	}

	/// @notice 	Ensures the resale marketplace is approved to handle the NFT on behalf of the owner
	/// @param 		contractAddress 	Address of the ERC721 contract
	/// @param 		tokenId 			Index of the NFT
	modifier HasTransferApproval(address contractAddress, uint256 tokenId) {
		IERC721 itemToken = IERC721(contractAddress);
		require(
			contractAddress != address(0) &&
			tokenId >= 0,
			"Resale Marketplace: Invalid data"
		);
		require(
			itemToken.isApprovedForAll(itemToken.ownerOf(tokenId), address(this)) ||
			itemToken.getApproved(tokenId) == address(this),
			"Resale Marketplace: Marketplace is not approved"
		);
		_;
	}

	/// @notice 	Constructor
	/// @param 		_treasury 		Address of the treasury
	constructor(address _treasury) {
		treasuryAddress = _treasury;
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
	}

	/// @notice Utility function to verify that the recipient of a custom splits ISN'T a contract
	/// @dev 	This isn't a foolproof function, a contract running code in it's constructor has a code size of 0
	/// @param 	addr 	Address to verify
	/// @return bool that indicates if the address is a contract or not
	function isContract(address addr) internal view returns (bool) {
		uint size;
		assembly { size := extcodesize(addr) }
		return size > 0;
	}

	/// @notice 	Ensures only the NFT owner can manage the offer
	/// @param 		contractAddress 	Address of the ERC721 contract
	/// @param 		tokenId 			Index of the NFT
	function _onlyTokenHolder(address contractAddress, uint tokenId) internal view {
		IERC721 itemToken = IERC721(contractAddress);
		require(
			itemToken.ownerOf(tokenId) == msg.sender,
			"Resale Marketplace: Address does not own the token"
		);
	}

	/// @notice 	Returns information about a specific offer
	/// @param 		offerIndex 		Index of the offer on the marketplace
	/// @return 	selectedOffer 	Information about the offer
	function getOfferInfo(uint256 offerIndex) public view returns (Offer memory selectedOffer) {
		selectedOffer = offers[offerIndex];
	}

	/// @notice 	Sets a custom array of royalties for the entire ERC721 contract
	/// @dev 		You can send empty arrays to unset the creator royalties!
	/// @param 		contractAddress 	Address of the ERC721 contract
	/// @param 		recipients 			Array of addresses where the royalties will be sent, they cannot be smart contracts
	/// @param 		percentages 		Array of percentages (represented by integers)
	function setCustomRoyalties(
		address contractAddress,
		address[] calldata recipients,
		uint256[] calldata percentages
	) external OnlyTokenCreator(contractAddress) {
		require(
			recipients.length == percentages.length,
			"Resale Marketplace: Recipients and Percentages should have the same length"
		);

		uint256 total = 0;
		for (uint256 i = 0; i < recipients.length; i++) {
			require(
				isContract(recipients[i]) == false,
				"Resale Marketplace: For security reasons we don't allow smart contracts to receive funds"
			);
			total += percentages[i];
		}

		require(
			total < (100 * (10 ** feeDecimals)) - nodeFee - treasuryFee,
			"Resale Marketplace: Royalties exceed the 100%"
		);

		ContractCustomSplits storage splits = contractSplits[contractAddress];

		splits.precisionDecimals = feeDecimals;
		splits.recipients = recipients;
		splits.percentages = percentages;

		emit CustomRoyaltiesSet(
			contractAddress,
			recipients.length,
			(100 * (10 ** feeDecimals)) - nodeFee - treasuryFee - total
		);
	}

	/// @notice 	Creates a resale offer on the marketplace
	/// @param 		_tokenId 			Index of the NFT
	/// @param 		_price 				Price for the NFT to be sold
	/// @param 		_contractAddress 	Address of the ERC721 contract
	/// @param 		_nodeAddress 		Address of the RAIR node that will receive the node fee
	function createResaleOffer(
		uint256 _tokenId,
		uint256 _price,
		address _contractAddress,
		address _nodeAddress
	)
		external
		HasTransferApproval(_contractAddress, _tokenId)
		OnlyTokenHolder(_contractAddress, _tokenId)
		isPaused
	{
		require(
			isContract(_nodeAddress) == false,
			"Resale Marketplace: Node address cannot be a smart contract"
		);
		require(!isContract(msg.sender), 'Resale Marketplace: Cannot trust smart contracts as sellers');
		require(
			tokenOnSale[_contractAddress][_tokenId] == false,
			"Resale Marketplace: Token is already on sale"
		);

		offers[tradeCounter] = Offer({
			sellerAddress: msg.sender,
			contractAddress: _contractAddress,
			tokenId: _tokenId,
			price: _price,
			tradeStatus: OfferStatus.OPEN,
			nodeAddress: _nodeAddress
		});

		tradeCounter += 1;
		tokenOnSale[_contractAddress][_tokenId] = true;

		emit OfferStatusChange(
			msg.sender,
			_contractAddress,
			_tokenId,
			_price,
			OfferStatus.OPEN,
			tradeCounter - 1
		);
	}

	/// @notice 	Executes a sale, sending funds to any royalty recipients and transferring the token to the buyer
	/// @dev 		If custom splits exist, it will execute it, if they don't it will try to use the 2981 standard
	/// @param 		offerIndex 		Index of the offer on the marketplace
	function buyResaleOffer(uint256 offerIndex) public payable OpenOffer(offerIndex) isPaused {
		Offer memory selectedOffer = offers[offerIndex];
		require(
			msg.sender != address(0) && msg.sender != selectedOffer.sellerAddress,
			"Resale Marketplace: Invalid addresses"
		);
		require(!isContract(msg.sender), "Resale Marketplace: Cannot trust smart contract as buyer");
		require(msg.value >= selectedOffer.price, "Insuficient Funds!");

		uint totalPercentage = 100 * (10 ** feeDecimals);

		// Pay the buyer any excess they transferred
		payable(msg.sender).transfer(msg.value - selectedOffer.price);

		uint256 toRAIR = (selectedOffer.price * treasuryFee) / totalPercentage;
		
		payable(selectedOffer.nodeAddress).transfer((selectedOffer.price * nodeFee) / totalPercentage);
		payable(treasuryAddress).transfer(toRAIR);
		
		uint totalSent = ((selectedOffer.price * nodeFee) / totalPercentage) + toRAIR;

		ContractCustomSplits storage customSplits = contractSplits[selectedOffer.contractAddress];
		if (customSplits.recipients.length > 0) {
			uint i = 0;
			if (customSplits.precisionDecimals != feeDecimals) {
				for (; i < customSplits.recipients.length; i++) {
					customSplits.percentages[i] = _updatePrecision(customSplits.percentages[i], customSplits.precisionDecimals, feeDecimals);
				}
				i = 0;
			}
			for (; i < customSplits.recipients.length; i++) {
				uint toReceiver = selectedOffer.price * customSplits.percentages[i] / totalPercentage;
				payable(customSplits.recipients[i]).transfer(toReceiver);
				totalSent += toReceiver;
			}
		} else if (IERC2981(selectedOffer.contractAddress).supportsInterface(type(IERC2981).interfaceId)) {
			(address creator, uint royalty) = IERC2981(selectedOffer.contractAddress)
												.royaltyInfo(
													selectedOffer.tokenId,
													selectedOffer.price
												);
			totalSent += royalty;
			payable(creator).transfer(royalty);
		}

		uint256 toPoster = selectedOffer.price - totalSent;
		payable(selectedOffer.sellerAddress).transfer(toPoster);
		
		IERC721(selectedOffer.contractAddress).safeTransferFrom(
			address(selectedOffer.sellerAddress),
			payable(msg.sender),
			selectedOffer.tokenId
		);

		offers[offerIndex].tradeStatus = OfferStatus.CLOSED;
		tokenOnSale[selectedOffer.contractAddress][selectedOffer.tokenId] = false;

		emit OfferStatusChange(
			msg.sender,
			selectedOffer.contractAddress,
			selectedOffer.tokenId,
			selectedOffer.price,
			OfferStatus.CLOSED,
			offerIndex
		);
	}

	/// @notice 	Cancels an offer on the marketplace
	/// @dev 		This doesn't delete the entry, just marks it as CANCELLED
	/// @param 		offerIndex 		Index of the offer to be cancelled
	function cancelOffer(uint256 offerIndex) public OpenOffer(offerIndex) {
		Offer memory offer = offers[offerIndex];
		_onlyTokenHolder(offer.contractAddress, offer.tokenId);

		offers[offerIndex].tradeStatus = OfferStatus.CANCELLED;
		tokenOnSale[offer.contractAddress][offer.tokenId] = false;

		emit OfferStatusChange(
			msg.sender,
			offer.contractAddress,
			offer.tokenId,
			offer.price,
			OfferStatus.CANCELLED,
			offerIndex
		);
	}

	/// @notice 	Returns all open offers on the marketplace
	/// @dev 		This is a view function that uses loops, do not use on any non-view function
	/// @return 	An array of all open offers on the marketplace
	function getAllOnSale() public view virtual returns (Offer[] memory) {
		uint256 counter = 0;
		uint256 itemCounter = 0;
		for (uint256 i = 0; i < tradeCounter; i++) {
			if (offers[i].tradeStatus == OfferStatus.OPEN) {
				counter++;
			}
		}

		Offer[] memory tokensOnSale = new Offer[](counter);
		if (counter != 0) {
			for (uint256 i = 0; i < tradeCounter; i++) {
				if (offers[i].tradeStatus == OfferStatus.OPEN) {
					tokensOnSale[itemCounter] = offers[i];
					itemCounter++;
				}
			}
		}

		return tokensOnSale;
	}

	/// @notice 	Returns all offers made by an user
	/// @param 		user 		Address of the seller
	/// @return 	An array of all offers made by a specific user
	function getUserOffers(address user) public view returns (Offer[] memory) {
		uint256 counter = 0;
		uint256 itemCounter = 0;
		for (uint256 i = 0; i < tradeCounter; i++) {
			if (offers[i].sellerAddress == user) {
				counter++;
			}
		}

		Offer[] memory tokensByOwner = new Offer[](counter);
		if (counter != 0) {
			for (uint256 i = 0; i < tradeCounter; i++) {
				if (offers[i].sellerAddress == user) {
					tokensByOwner[itemCounter] = offers[i];
					itemCounter++;
				}
			}
		}

		return tokensByOwner;
	}

	/// @notice 	Updates the price of an offer
	/// @dev 		Price is the only thing that can be updated on any offer
	/// @param 		offerIndex 		Index of the offer
	/// @param 		newPrice 		New price for the offer
	function updateOffer(uint256 offerIndex, uint256 newPrice) public OpenOffer(offerIndex) {
		Offer storage selectedOffer = offers[offerIndex];
		_onlyTokenHolder(selectedOffer.contractAddress, selectedOffer.tokenId);
		if (msg.sender != selectedOffer.sellerAddress) {
			selectedOffer.sellerAddress = msg.sender;
		}
		uint oldPrice = selectedOffer.price;
		selectedOffer.price = newPrice;
		emit UpdatedOfferPrice(offerIndex, selectedOffer.contractAddress, oldPrice, newPrice);
	}

	/// @notice 	Queries the marketplace to find if a token is on sale
	/// @param 		contractAddress 		Address of the ERC721 contract
	/// @param 		tokenId 				Index of the NFT
	/// @return 	Boolean value, true if there is an open offer on the marketplace
	function getTokenIdStatus(
		address contractAddress,
		uint256 tokenId
	) public view returns (bool) {
		return tokenOnSale[contractAddress][tokenId];
	}

	/// @notice 	Updates the treasury address
	/// @dev 		If the treasury is a contract, make sure it has a receive function
	/// @param 		_newTreasury 	New treasury address
	function setTreasuryAddress(
		address _newTreasury
	) public onlyRole(DEFAULT_ADMIN_ROLE) {
		require(_newTreasury != address(0), "invalid address");
		treasuryAddress = _newTreasury;
		emit ChangedTreasuryAddress(_newTreasury);
	}

	/// @notice Sets the new treasury fee
	/// @param _newFee New Fee
	function setTreasuryFee(
		uint _newFee
	) public onlyRole(DEFAULT_ADMIN_ROLE) {
		treasuryFee = _newFee;
		emit ChangedTreasuryFee(treasuryAddress, _newFee);
	}

	/// @notice 	Sets the new fee that will be paid to RAIR nodes
	/// @param 		_newFee 	New Fee
	function setNodeFee(uint _newFee) public onlyRole(DEFAULT_ADMIN_ROLE) {
		nodeFee = _newFee;
		emit ChangedNodeFee(_newFee);
	}

	/// @notice 	Updates the precision decimals on percentages and fees
	/// @dev 		Automatically updates node and treasury fees
	/// @dev 		Sales made before the update will have a special bit of code on sale execution to handle this change
	/// @dev 		New sales will be required to follow the new number of decimals
	/// @param 		_newDecimals 		New number of decimals
	function updateFeeDecimals(uint8 _newDecimals) public onlyRole(DEFAULT_ADMIN_ROLE) {
		treasuryFee = _updatePrecision(treasuryFee, feeDecimals, _newDecimals); 
		nodeFee = _updatePrecision(nodeFee, feeDecimals, _newDecimals); 
		feeDecimals = _newDecimals;
	}

	/// @notice 	Updates the precision of a number
	/// @dev 		Multiply first to not lose decimals on the way
	/// @return 	Updated number
	function _updatePrecision(uint number, uint oldDecimals, uint newDecimals) internal pure returns (uint) {
		return (number * (10 ** newDecimals)) / (10 ** oldDecimals); 
	}

	/// @notice 	Pauses / Resumes sales on the contract
	/// @dev 		Only prevents offer creation and executions, the other functions continue as normal
	/// @param 		_pause 		Boolean flag to pause (true) or resume (false) the contract
	function pauseContract(bool _pause) public onlyRole(DEFAULT_ADMIN_ROLE) {
		paused = _pause;
	}

	/// @notice  	Withdraws any funds stuck on the resale marketplace
	/// @dev 		There shouldn't be any funds stuck on the resale marketplace
	/// @param 		_amount 	Amount of funds to be withdrawn
	function withdraw(uint256 _amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
		payable(msg.sender).transfer(_amount);
	}
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
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
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
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10; 

interface IERC2981 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256,bytes)")) == 0xc155531d
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0xc155531d;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _value sale price
    function royaltyInfo(
    	uint256 _tokenId,
    	uint256 _salePrice)
    external returns (
    	address receiver,
    	uint256 royaltyAmount);

    /// @notice Informs callers that this contract supports ERC2981
    /// @dev If `_registerInterface(_INTERFACE_ID_ERC2981)` is called
    ///      in the initializer, this should be automatic
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @return `true` if the contract implements
    ///         `_INTERFACE_ID_ERC2981` and `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
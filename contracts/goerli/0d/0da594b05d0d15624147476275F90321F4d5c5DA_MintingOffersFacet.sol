// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11; 

import '@openzeppelin/contracts/access/IAccessControl.sol';
import '../AppStorage.sol';

interface IRAIR721 {
	struct range {
		uint rangeStart;
		uint rangeEnd;
		uint tokensAllowed;
		uint mintableTokens;
		uint lockedTokens;
		uint rangePrice;
		string rangeName;
	}

	/// @notice This function returns the information of the selected range
	/// @param rangeId 		  Contains the specific range that we want to check
	/// @return data		  Contains the data inside the range
	/// @return productIndex  Contains the index of the products for the range
	function rangeInfo(uint rangeId) external view returns(range memory data, uint productIndex);
	/// @notice This function allow us to mint token from a specific range 
	/// @param to Contains the address that will mint the token
    /// @param rangeId Contains the range identification where we want to mint
	/// @param indexInRange Contains the index inside the range that we want to use for minting 
	function mintFromRange(address to, uint rangeId, uint indexInRange) external;
}


/// @title  RAIR Diamond - Minting offers facet
/// @notice Facet in charge of the minting offers in the RAIR Marketplace
/// @author Juan M. Sanchez M.
/// @dev 	Notice that this contract is inheriting from AccessControlAppStorageEnumerableMarket
contract MintingOffersFacet is AccessControlAppStorageEnumerableMarket {

	/// @notice This event stores in the blockchain when a Minting Offer is Added
    /// @param  erc721Address Contains the address of the erc721
    /// @param  rangeIndex contains the id of the minted token
	/// @param  rangeName contains the name of the range where the token is
	/// @param  price Contains the price of the offer fot the token
    /// @param  feeSplitsLength contains the previous status of the offer
    /// @param  feeSplitsLength Contains the visibility of the offer
	/// @param  offerIndex contains the new status of the offer
	event AddedMintingOffer(address erc721Address, uint rangeIndex, string rangeName, uint price, uint feeSplitsLength, bool visible, uint offerIndex);
	event UpdatedMintingOffer(address erc721Address, uint rangeIndex, uint feeSplitsLength, bool visible, uint offerIndex);
	
	event MintedToken(address erc721Address, uint rangeIndex, uint tokenIndex, address buyer);

	modifier checkCreatorRole(address erc721Address) {
		require(
			IAccessControl(erc721Address).hasRole(bytes32(0x00), address(msg.sender)) ||
			IAccessControl(erc721Address).hasRole(bytes32(keccak256("CREATOR")), address(msg.sender)),
			"Minter Marketplace: Sender isn't the creator of the contract!");
		_;
	}

	modifier checkMinterRole(address erc721Address) {
		require(hasMinterRole(erc721Address), "Minter Marketplace: This Marketplace isn't a Minter!");
		_;
	}

	modifier mintingOfferExists(uint offerIndex_) {
		require(s.mintingOffers.length > offerIndex_, "Minting Marketplace: Minting Offer doesn't exist");
		_;
	}

	modifier offerDoesntExist(address erc721Address, uint rangeIndex) {
		require(s.addressToRangeOffer[erc721Address][rangeIndex] == 0, "Minter Marketplace: Range already has an offer");
		if (s.addressToRangeOffer[erc721Address][rangeIndex] == 0 && s.mintingOffers.length > 0) {
			require(s.mintingOffers[0].erc721Address != erc721Address ||
						s.mintingOffers[0].rangeIndex != rangeIndex,
							"Minter Marketplace: Range already has an offer");
		}
		_;
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

	/// @notice Utility function to verify if the Marketplace has a MINTER role
	/// @param  erc721Address 	Address of the ERC721 token with AccessControl
	/// @return bool that indicates if the marketplace has a `MINTER` role or not
	function hasMinterRole(address erc721Address) internal view returns (bool) {
		return IAccessControl(erc721Address).hasRole(bytes32(keccak256("MINTER")), address(this));
	}

	/// @notice Returns the number of offers for a specific ERC721 address
	/// @param  erc721Address 	Address of the ERC721 token
	/// @return uint with the total of offers
	function getOffersCountForAddress(address erc721Address) public view returns (uint) {
		return s.addressToOffers[erc721Address].length;
	}

	/// @notice Returns the number of all the minting offers 
	/// @return uint with the total of offers
	function getTotalOfferCount() public view returns (uint) {
		return s.mintingOffers.length;
	}

	/// @notice This functions show us the information of an offer asociated to a marketplace
	/// @param erc721Address Contains the facet addresses and function selectors
    /// @param rangeIndex Contains the facet addresses and function selectors
	/// @return offerIndex Show us the indexed position of the offer
	/// @return mintOffer Show us the information about the minting offer 
	/// @return rangeData Show us the data about the selected range
	/// @return productIndex Show us the indexed position for the product inside the range
	function getOfferInfoForAddress(address erc721Address, uint rangeIndex) public view returns (uint offerIndex, mintingOffer memory mintOffer, IRAIR721.range memory rangeData, uint productIndex) {
		mintingOffer memory selectedOffer = s.mintingOffers[s.addressToOffers[erc721Address][rangeIndex]];
		(rangeData, productIndex) = IRAIR721(selectedOffer.erc721Address).rangeInfo(selectedOffer.rangeIndex);
		offerIndex = s.addressToOffers[erc721Address][rangeIndex];
		mintOffer = selectedOffer;
	}

	/// @notice This function show us the information of an selected minting offer
	/// @param 		offerIndex Contains the facet addresses and function selectors
	/// @return 	mintOffer Show us the information about the minting offer 
	/// @return 	rangeData Show us the data about the selected range
	/// @return 	productIndex Show us the indexed position for the product inside the range
	function getOfferInfo(uint offerIndex) public view returns (mintingOffer memory mintOffer, IRAIR721.range memory rangeData, uint productIndex) {
		mintingOffer memory selectedOffer = s.mintingOffers[offerIndex];
		mintOffer = selectedOffer;
		(rangeData, productIndex) = IRAIR721(selectedOffer.erc721Address).rangeInfo(selectedOffer.rangeIndex);
	}

	/// @notice This function allow us to add a new minting offer
	/// @param erc721Address_ Contains the address of the minter marketplace contract
	/// @param rangeIndex_ Contains the index location of the range where the offer will be placed
	/// @param splits Contains the shares and address to pay when the offer is succesfull 
	/// @param visible_ Contains a boolean to set if the offer is public or not 
	/// @param nodeAddress_ Contains address of the node where the offer was placed
	function addMintingOffer(
		address erc721Address_,
		uint rangeIndex_,
		feeSplits[] calldata splits,
		bool visible_,
		address nodeAddress_
	) external {
		_addMintingOffer(erc721Address_, rangeIndex_, splits, visible_, nodeAddress_);
	}

	/// @notice This function allow us to create a group of minting offers in a single call
	/// @param erc721Address_ Contains the address of the minter marketplace contract
	/// @param rangeIndexes Contains the collection of ranges where the offer will be placed
	/// @param splits Contains the shares and address to pay when the offer is succesfull 
	/// @param visibility Contains a collection of booleans that set the offer as public or not 
	/// @param nodeAddress_ Contains address of the node where the offer was placed
	function addMintingOfferBatch(
		address erc721Address_,
		uint[] calldata rangeIndexes,
		feeSplits[][] calldata splits,
		bool[] calldata visibility,
		address nodeAddress_
	) external {
		require(rangeIndexes.length > 0, "Minter Marketplace: No offers sent!");
		require(rangeIndexes.length == visibility.length && splits.length == visibility.length, "Minter Marketplace: Arrays should have the same length");
		for (uint i = 0; i < rangeIndexes.length; i++) {
			_addMintingOffer(erc721Address_, rangeIndexes[i], splits[i], visibility[i], nodeAddress_);
		}
	}

	/// @notice This function allow us to add a new minting offer
	/// @dev 	This function requires that account has the role of `CREATOR`
	/// @dev 	This function requires that the marketplace is defined as MINTER
	/// @dev 	This function requires that the range is available to create a new offer
	/// @param erc721Address_ Contains the address of the minter marketplace contract
	/// @param rangeIndex_ Contains the index location of the range where the offer will be placed
	/// @param splits Contains the shares and address to pay when the offer is succesfull 
	/// @param visible_ Contains a boolean to set if the offer is public or not 
	/// @param nodeAddress_ Contains address of the node where the offer was placed
	function _addMintingOffer(
		address erc721Address_,
		uint rangeIndex_,
		feeSplits[] memory splits,
		bool visible_,
		address nodeAddress_
	) internal checkCreatorRole(erc721Address_) checkMinterRole(erc721Address_) offerDoesntExist(erc721Address_, rangeIndex_) {
		mintingOffer storage newOffer = s.mintingOffers.push();
		(IRAIR721.range memory rangeData,) = IRAIR721(erc721Address_).rangeInfo(rangeIndex_);
		require(rangeData.mintableTokens > 0, "Minter Marketplace: Offer doesn't have tokens available!");
		newOffer.erc721Address = erc721Address_;
		newOffer.nodeAddress = nodeAddress_;
		newOffer.rangeIndex = rangeIndex_;
		newOffer.visible = visible_;
		if (rangeData.rangePrice > 0) {
			uint totalPercentage = s.nodeFee + s.treasuryFee;
			uint totalFunds = rangeData.rangePrice * totalPercentage / (100 * s.decimalPow);
			for (uint i = 0; i < splits.length; i++) {
				require(!isContract(splits[i].recipient), "Minter Marketplace: Contracts can't be recipients of the splits");
				uint splitForPercentage = rangeData.rangePrice * splits[i].percentage / (100 * s.decimalPow);
				require(
					splitForPercentage > 0,
					"Minter Marketplace: A percentage on the array will result in an empty transfer"
				);
				totalFunds += splitForPercentage;
				totalPercentage += splits[i].percentage;
				newOffer.fees.push(splits[i]);
			}
			require(totalPercentage == (100 * s.decimalPow), "Minter Marketplace: Fees don't add up to 100%");
			require(totalFunds == rangeData.rangePrice, "Minter Marketplace: Current fee configuration will result in missing funds");
		}
		s.addressToOffers[erc721Address_].push(s.mintingOffers.length - 1);
		s.addressToRangeOffer[erc721Address_][rangeIndex_] = s.mintingOffers.length - 1;
		emit AddedMintingOffer(erc721Address_, rangeIndex_, rangeData.rangeName, rangeData.rangePrice, splits.length, visible_, s.mintingOffers.length - 1);
	}

	/// @notice This function allow us to update the parameters of a minting offers
	/// @dev 	This function requires that the mintingOfferExists points to an valid offer  
	/// @param 	mintingOfferId_  Contains index location of the minting offer
	/// @param 	splits_ 		 Contains the shares and address to pay when the offer is succesfull 
	/// @param 	visible_    	 Contains a boolean to set if the offer is public or not 
	function updateMintingOffer (
		uint mintingOfferId_,
		feeSplits[] memory splits_,
		bool visible_
	) external mintingOfferExists(mintingOfferId_) {
		_updateMintingOffer(mintingOfferId_, splits_, visible_);
	}

	/// @notice This function allow us to update the parameters of a minting offers 
	/// @param 	mintingOfferId_  Contains index location of the minting offer
	/// @param 	splits_ 		 Contains the shares and address to pay when the offer is succesfull 
	/// @param 	visible_         Contains a boolean to set if the offer is public or not 
	function _updateMintingOffer (
		uint mintingOfferId_,
		feeSplits[] memory splits_,
		bool visible_
	) internal {
		mintingOffer storage selectedOffer = s.mintingOffers[mintingOfferId_];
		require(
			IAccessControl(selectedOffer.erc721Address).hasRole(bytes32(keccak256("CREATOR")), address(msg.sender)),
			"Minter Marketplace: Sender isn't the creator of the contract!"
		);
		require(
			hasMinterRole(selectedOffer.erc721Address),
			"Minter Marketplace: This Marketplace isn't a Minter!"
		);
		(IRAIR721.range memory rangeData,) = IRAIR721(selectedOffer.erc721Address).rangeInfo(selectedOffer.rangeIndex);
		uint totalPercentage = s.nodeFee + s.treasuryFee;
		delete selectedOffer.fees;
		for (uint i = 0; i < splits_.length; i++) {
			require(!isContract(splits_[i].recipient), "Minter Marketplace: Contracts can't be recipients of fees");
			require(
				rangeData.rangePrice * splits_[i].percentage / (100 * s.decimalPow) > 0,
				"Minter Marketplace: A percentage on the array will result in an empty transfer"
			);
			totalPercentage += splits_[i].percentage;
			selectedOffer.fees.push(splits_[i]);
		}
		require(totalPercentage == (100 * s.decimalPow), "Minter Marketplace: Fees don't add up to 100%");
		selectedOffer.visible = visible_;
		emit UpdatedMintingOffer(
			selectedOffer.erc721Address,
			selectedOffer.rangeIndex,
			selectedOffer.fees.length,
			selectedOffer.visible,
			mintingOfferId_
		);
	}

	/// @notice This function allow us to buy a minting offers
	/// @dev 	This function requires that the mintingOfferExists points to an valid offer  
	/// @param 	offerIndex_  Contains index location of the offer
	/// @param 	tokenIndex_  Contains the id of the tokens that we want to mint
	function buyMintingOffer(uint offerIndex_, uint tokenIndex_) public mintingOfferExists(offerIndex_) payable {
		mintingOffer storage selectedOffer = s.mintingOffers[offerIndex_];
		require(selectedOffer.visible, "Minter Marketplace: This offer is not ready to be sold!");
		require(hasMinterRole(selectedOffer.erc721Address), "Minter Marketplace: This Marketplace isn't a Minter!");
		(IRAIR721.range memory rangeData,) = IRAIR721(selectedOffer.erc721Address).rangeInfo(selectedOffer.rangeIndex);
		if (rangeData.rangePrice > 0) {
			require(rangeData.rangePrice <= msg.value, "Minter Marketplace: Insufficient funds!");
			if (msg.value - rangeData.rangePrice > 0) {
				payable(msg.sender).transfer(msg.value - rangeData.rangePrice);
			}
			uint totalTransferred = rangeData.rangePrice * (s.nodeFee + s.treasuryFee) / (100 * s.decimalPow);
			payable(selectedOffer.nodeAddress).transfer(rangeData.rangePrice * s.nodeFee / (100 * s.decimalPow));
			payable(s.treasuryAddress).transfer(rangeData.rangePrice * s.treasuryFee / (100 * s.decimalPow));
			uint auxMoneyToBeSent;
			for (uint i = 0; i < selectedOffer.fees.length; i++) {
				auxMoneyToBeSent = rangeData.rangePrice * selectedOffer.fees[i].percentage / (100 * s.decimalPow);
				totalTransferred += auxMoneyToBeSent;
				payable(selectedOffer.fees[i].recipient).transfer(auxMoneyToBeSent);
			}
			require(totalTransferred == rangeData.rangePrice, "Minter Marketplace: Error transferring funds!");
		}
		_buyMintingOffer(selectedOffer.erc721Address, selectedOffer.rangeIndex, tokenIndex_, msg.sender);
	}

	/// @notice This function allow us to buy a collection of minting offers
	/// @dev 	This function requires that the mintingOfferExists points to an valid offer  
	/// @param 	offerIndex_  	Contains index location of the offer
	/// @param 	tokenIndexes	Contains the collection of tokens that we want to mint
	/// @param 	recipients 		Contains the collection of addresses that will receive
	function buyMintingOfferBatch(
		uint offerIndex_,
		uint[] calldata tokenIndexes,
		address[] calldata recipients		
	) external mintingOfferExists(offerIndex_) payable {
		require(tokenIndexes.length > 0, "Minter Marketplace: No tokens sent!");
		require(tokenIndexes.length == recipients.length, "Minter Marketplace: Tokens and Addresses should have the same length");
		mintingOffer storage selectedOffer = s.mintingOffers[offerIndex_];
		require(selectedOffer.visible, "Minter Marketplace: This offer is not ready to be sold!");
		require(hasMinterRole(selectedOffer.erc721Address), "Minter Marketplace: This Marketplace isn't a Minter!");
		(IRAIR721.range memory rangeData,) = IRAIR721(selectedOffer.erc721Address).rangeInfo(selectedOffer.rangeIndex);
		uint i;
		if (rangeData.rangePrice > 0) {
			require((rangeData.rangePrice * tokenIndexes.length) <= msg.value, "Minter Marketplace: Insufficient funds!");
			if (msg.value - (rangeData.rangePrice * tokenIndexes.length) > 0) {
				payable(msg.sender).transfer(msg.value - (rangeData.rangePrice * tokenIndexes.length));
			}
			uint totalTransferred = (rangeData.rangePrice * tokenIndexes.length) * (s.nodeFee + s.treasuryFee) / (100 * s.decimalPow);
			payable(selectedOffer.nodeAddress).transfer((rangeData.rangePrice * tokenIndexes.length) * s.nodeFee / (100 * s.decimalPow));
			payable(s.treasuryAddress).transfer((rangeData.rangePrice * tokenIndexes.length) * s.treasuryFee / (100 * s.decimalPow));
			uint auxMoneyToBeSent;
			for (i = 0; i < selectedOffer.fees.length; i++) {
				auxMoneyToBeSent = (rangeData.rangePrice * tokenIndexes.length) * selectedOffer.fees[i].percentage / (100 * s.decimalPow);
				totalTransferred += auxMoneyToBeSent;
				payable(selectedOffer.fees[i].recipient).transfer(auxMoneyToBeSent);
			}
			require(totalTransferred == (rangeData.rangePrice * tokenIndexes.length), "Minter Marketplace: Error transferring funds!");
		}
		for (i = 0; i < tokenIndexes.length; i++) {
			_buyMintingOffer(selectedOffer.erc721Address, selectedOffer.rangeIndex, tokenIndexes[i], recipients[i]);
		}
	}

	/// @notice This function is in charge of buying a desired minting offer 
	/// @param erc721Address  Contains the address where the offer is located
	/// @param rangeIndex	  Contains the index location of the range where the token is 
	/// @param tokenIndex  	  Contains the index location of the token to buy 
	/// @param recipient   	  Contains the address of the recipient of the token
	function _buyMintingOffer(address erc721Address, uint rangeIndex, uint tokenIndex, address recipient) internal {
		IRAIR721(erc721Address).mintFromRange(recipient, rangeIndex, tokenIndex);
		emit MintedToken(erc721Address, rangeIndex, tokenIndex, recipient);
	}
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11; 

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

struct feeSplits {
	address recipient;
	uint percentage;
}

struct mintingOffer {
	address erc721Address;
	address nodeAddress;
	uint rangeIndex;
	feeSplits[] fees;
	bool visible;
}

struct RoleData {
	mapping(address => bool) members;
	bytes32 adminRole;
}

struct AppStorage {
	// Access Control Enumerable
	mapping(bytes32 => RoleData) _roles;
	mapping(bytes32 => EnumerableSet.AddressSet) _roleMembers;
	// App
	uint16 decimals;
	uint decimalPow;
	uint nodeFee;
	uint treasuryFee;
	address treasuryAddress;
	mintingOffer[] mintingOffers;
	mapping(address => mapping(uint => uint)) addressToRangeOffer;
	mapping(address => uint[]) addressToOffers;
	// Always add new fields at the end of the struct, that way the structure can be upgraded
}

library LibAppStorage {
	function diamondStorage() internal pure	returns (AppStorage storage ds) {
		assembly {
			ds.slot := 0
		}
	}
}

/// @title 	This is contract to manage the access control of the app market
/// @notice You can use this contract to administrate roles of the app market
/// @dev 	Notice that this contract is inheriting from Context
contract AccessControlAppStorageEnumerableMarket is Context {
	using EnumerableSet for EnumerableSet.AddressSet;
	
	AppStorage internal s;

	/// @notice This event stores in the blockchain when we change an admin role
    /// @param  role Contains the role we want to update
    /// @param  previousAdminRole contains the previous status of the role
	/// @param  newAdminRole contains the new status of the role
	event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
	/// @notice This event stores in the blockchain when we grant a role
    /// @param  role Contains the role we want to update
    /// @param  account contains the address that we want to grant the role
	/// @param  sender contains the address that is changing the role of the account
	event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
	/// @notice This event stores in the blockchain when we revoke a role
    /// @param  role Contains the role we want to update
    /// @param  account contains the address that we want to revoke the role
	/// @param  sender contains the address that is changing the role of the account
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

	/// @notice Allow us to renounce to a role
	/// @dev 	Currently you can only renounce to your own roles
	/// @param 	role Contains the role to remove from our account
	/// @param 	account Contains the account that has the role we want to update
    function renounceRole(bytes32 role, address account) public {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");
        _revokeRole(role, account);
    }

	/// @notice Allow us to grant a role to an account
	/// @dev 	This function is only available to an account with an Admin role
	/// @param 	role Contains the role that we want to grant
	/// @param 	account Contains the account that has the role we want to update
    function grantRole(bytes32 role, address account) public onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

	/// @notice Allow us to revoke a role to an account
	/// @dev 	This function is only available to an account with an Admin role
	/// @param 	role Contains the role that we want to revoke
	/// @param 	account Contains the account that has the role we want to update
    function revokeRole(bytes32 role, address account) public onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

	/// @notice Allow us to check the if and account has a selected role
	/// @param 	role Contains the role that we want to verify
	/// @param 	account Contains the account address thay we want to verify
    function _checkRole(bytes32 role, address account) internal view {
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

	/// @notice Allow us to check the if and account has a selected role
	/// @param 	role Contains the role that we want to verify
	/// @param 	account Contains the account address thay we want to verify
	/// @return bool that indicates if an account has or not a role
	function hasRole(bytes32 role, address account) public view returns (bool) {
		return s._roles[role].members[account];
	}

	/// @notice Allow us to check the admin role that contains a role
	/// @param 	role Contains the role that we want to verify
	/// @return bytes that indicates if an account has or not an admin role
	function getRoleAdmin(bytes32 role) public view returns (bytes32) {
		return s._roles[role].adminRole;
	}

	/// @notice Allow us to check the address of an indexed position for the role list
	/// @param 	role Contains the role that we want to verify
	/// @param 	index Contains the indexed position to verify inside the role members list
	/// @return address that indicates the address indexed in that position
	function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
		return s._roleMembers[role].at(index);
	}
	
	/// @notice Allow us to check total members that has an selected role
	/// @param 	role Contains the role that we want to verify
	/// @return uint256 that indicates the total accounts with that role
	function getRoleMemberCount(bytes32 role) public view returns (uint256) {
		return s._roleMembers[role].length();
	}

	/// @notice Allow us to modify a rol and set it as an admin role
	/// @param 	role Contains the role that we want to modify
	/// @param 	adminRole Contains the admin role that we want to set
	function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
		bytes32 previousAdminRole = getRoleAdmin(role);
		s._roles[role].adminRole = adminRole;
		emit RoleAdminChanged(role, previousAdminRole, adminRole);
	}

	/// @notice Allow us to grant a role to an account
	/// @param 	role Contains the role that we want to grant
	/// @param 	account Contains the account that has the role we want to update
	function _grantRole(bytes32 role, address account) internal {
		if (!hasRole(role, account)) {
			s._roles[role].members[account] = true;
			emit RoleGranted(role, account, _msgSender());
			s._roleMembers[role].add(account);
		}
	}

	/// @notice Allow us to revoke a role to an account
	/// @param 	role Contains the role that we want to revoke
	/// @param 	account Contains the account that has the role we want to update
	function _revokeRole(bytes32 role, address account) internal {
		if (hasRole(role, account)) {
			s._roles[role].members[account] = false;
			emit RoleRevoked(role, account, _msgSender());
			s._roleMembers[role].remove(account);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}
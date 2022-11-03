// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

import { IGenesis, IERC20Upgradeable } from "./interfaces/IGenesis.sol";
import { IERC2981, IERC165 } from "../node_modules/@openzeppelin/contracts/interfaces/IERC2981.sol";

import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import { SafeERC20Upgradeable } from "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { ECDSAUpgradeable } from "../node_modules/@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import { Math } from "./libraries/Math.sol";


/**
* @notice affiliate enabled nft collection
* @author Phil Thomsen
*/
contract Genesis is ERC721Upgradeable, AccessControlUpgradeable, IGenesis, IERC2981 {
	using SafeERC20Upgradeable for IERC20Upgradeable;
	using ECDSAUpgradeable for bytes;
	using StringsUpgradeable for uint256;

	uint256 private constant BASIS_POINTS = 10_000;

	bytes32 public constant override METADATA_MANAGER_ROLE = keccak256("METADATA_MANAGER");
	bytes32 public constant override WHITELIST_SIGNER_ROLE = keccak256("WHITELIST_SIGNER");
	bytes32 public constant override MINTING_MANAGER_ROLE = keccak256("MINTING_MANAGER");
	bytes32 public constant override DEFAULT_APPROVED_ROLE = keccak256("DEFAULT_APPROVED");
	bytes32 public constant override STRIVE_CONTRACT_ROLE = keccak256("STRIVE_CONTRACT");

	uint256 public constant MASTER_TOKEN_ZERO = 0;
	uint256 public constant override REFERRAL_LAYERS = 3;
	uint256 public constant override VALIDITY_LENGTH = 4 weeks;
	uint256 public constant override EXPLOTER_BASIS_POINTS = 100;

	IERC20Upgradeable public immutable override USDC;
	IERC20Upgradeable public immutable override USDT;

	uint24 internal _maxSupply;
	uint24 internal _totalSupply;
	bool internal _mintOpen;
	bool internal _transfersPaused;
	address internal royaltyReceiver;
	uint16 internal  royaltyBasisPoints;
	bool public metadataFrozen;

	VolumeProps public volumeProps;

	string internal _unrevealedMetadata;
	string internal _revealedMetadata;
	uint256 internal _revealedUntil;

	mapping(uint256 => Token) internal _token;
	mapping(address => Customer) internal _customers;

	constructor(IERC20Upgradeable _usdc, IERC20Upgradeable _usdt)  { 
		USDC = _usdc;
		USDT = _usdt;
		_disableInitializers(); 
	}

	function initialize(
		address mintingManager,
		address metadataManager,
		address whitelistSignerWallet, 
		VolumeProps calldata props
	)
		external override initializer
	{
		__ERC721_init("STRIVE FOR GREATNESS", "STRV");
		__AccessControl_init();

		_mint(msg.sender, MASTER_TOKEN_ZERO);

		_totalSupply = 1; 
		setMaxSupply(10001);

		_grantRole(MINTING_MANAGER_ROLE, mintingManager);
		_grantRole(METADATA_MANAGER_ROLE, metadataManager);
		_grantRole(WHITELIST_SIGNER_ROLE, whitelistSignerWallet);

		setVolumeProps(props);

		emit Minted(msg.sender, 0, 1, 0, 0);
	}

  // EXTERNAL USER FUNCTIONS
	function mint(
		address currency,
		uint256 amount,
		address recipient,
		Referral calldata referral
	)
		external override 
	{
		_registerCustomer(recipient, referral);

		if(amount == 0) revert ZeroParameter("uint256 amount");

        uint256 toBeMintedNext   = _totalSupply;
        uint256 totalSupplyAfter = toBeMintedNext + amount;
		uint256 totalFeeInUSDC = totalMintingFee(toBeMintedNext, amount);

		bool isValidReferral = _verifyReferralSignature(recipient, referral);
		address[REFERRAL_LAYERS] memory referrers = _getReferrers(referral.tokenId);

		// check if mint open and supply restrictions
        require(_mintAllowed(totalSupplyAfter));

		// check referral validity
		if(! isValidReferral) revert InvalidReferral(msg.sender, referral.tokenId, referral.sig);

		emit Minted(recipient, toBeMintedNext, amount, totalFeeInUSDC, referral.tokenId);

        // now mint `amount` tokens
		_mintRangeWithReferrerToken(
			recipient,
			toBeMintedNext, 
			totalSupplyAfter,
			referral.tokenId,
			totalFeeInUSDC / amount / 1 ether
		);

		// ensure payment is made by the caller and pay out to the referrer
        _processPayment(msg.sender, IERC20Upgradeable(currency), totalFeeInUSDC, referrers);
    }

	function renew(uint256[] calldata tokenIds, IERC20Upgradeable currency) external override {
		_enforceCurrency(currency);
		uint256 length = tokenIds.length;
		for(uint256 i = 0; i < length; i++) {
			uint256 validUntil = _renew(_getTokenInStorage(tokenIds[i]));
			emit TokenRenewed(tokenIds[i], validUntil);
		}
		currency.safeTransferFrom(msg.sender, address(this), length * 1 ether *  volumeProps.renewalFeeInDollar);
	}

	function registerAsCustomer(Referral calldata referral) external {
		_registerCustomer(msg.sender, referral);
	}

	function placeForVolumeBonus(uint256 parentTokenId, uint256 childTokenId, bool rightSide) external {		
		Token storage child = _getTokenInStorage(childTokenId);

		if(
			msg.sender != ownerOf(parentTokenId) ||
			child.referrerToken != parentTokenId ||
			child.up != MASTER_TOKEN_ZERO  ||
			parentTokenId == MASTER_TOKEN_ZERO
		) revert NotAuthorized(); 

		uint256 lastTokenInChain = _getEndOfVolumeBonusChain(parentTokenId, rightSide);

		if(rightSide)  _getTokenInStorage(lastTokenInChain).downR = uint24(childTokenId);
		else 			_getTokenInStorage(lastTokenInChain).downL = uint24(childTokenId);

		child.up = uint24(lastTokenInChain);

		emit Placed(childTokenId, lastTokenInChain, rightSide);
	}

	/// @param rightSideBase true means less right volume will be used, false means less left volume will be used
	function claimVolumeBonus(
		uint256 tokenId,
		uint256 cycles,
		bool rightSideBase,
		IERC20Upgradeable currency
	) external {		
		Token storage token = _getTokenInStorage(tokenId);
		VolumeProps memory props = volumeProps;

		// checks
		_enforceCurrency(currency);
		if(cycles == 0) revert ZeroParameter("cycles");
		if(! props.enabled) revert VolumeBonusDisabled();
		if(token.nextActivityCheck < block.timestamp) revert TokenNotActive();

		// cache for efficiency
		address tokenOwner = ownerOf(tokenId);
		uint256 earnedBeforeClaim = token.bonusPaidByVolumeEpoche[props.epoche];

		// calculate volume based on cycles and volumeProps
		(uint256 volumeLeftToUse, uint256 volumeRightToUse) = rightSideBase 
			? (
				cycles * props.volumeBaseAmount * props.otherTeamMultiplier, 
				cycles * props.volumeBaseAmount
			) : (
				cycles * props.volumeBaseAmount, 
				cycles * props.volumeBaseAmount * props.otherTeamMultiplier
			);

		(uint256 availableLeft, uint256 availableRight) = _getAvailableVolumesForToken(token);

		if(availableLeft < volumeLeftToUse)   revert InsufficientVolume(availableLeft, volumeLeftToUse);
		if(availableRight < volumeRightToUse) revert InsufficientVolume(availableRight, volumeRightToUse);

		uint256 earned = _calculateVolumeBonus(volumeLeftToUse, volumeRightToUse, props.basisPointsPayout);

		// check if token already earned too much this epoche
		if(earnedBeforeClaim + earned > props.maximumPerEpocheInDollar) revert EarnedMoreThanMaximumPerEpoche();

		token.usedLeft  += uint32(volumeLeftToUse);
		token.usedRight += uint32(volumeRightToUse);
		token.bonusPaidByVolumeEpoche[props.epoche] = earnedBeforeClaim + earned;

		emit VolumeBonusClaimed(tokenOwner, tokenId, earned, cycles, rightSideBase);

		currency.safeTransfer(tokenOwner, 1 ether * earned);
	}

	function updateVolumesForToken(uint256[] calldata tokenIds) external {
		for(uint256 i = 0; i < tokenIds.length; i = Math.unsafeInc(i)) {
			_updateVolumesForToken(_token[tokenIds[i]]);
		}

		emit VolumesUpdated(tokenIds);
	}

	function exploitActivity(uint256 tokenId, IERC20Upgradeable currency) external {
		_enforceCurrency(currency);

		Token storage token = _getTokenInStorage(tokenId);
		if(token.nextActivityCheck >= block.timestamp) revert TokenStillActive(token.nextActivityCheck);

		(uint256 availableLeft, uint256 availableRight) = _getAvailableVolumesForToken(token);

		_zeroOutVolumes(token);

		uint256 exploiterBonus = _calculateVolumeBonus(
			availableLeft, 
			availableRight, 
			volumeProps.basisPointsPayout
		) * EXPLOTER_BASIS_POINTS / BASIS_POINTS;

		emit Exploited(msg.sender, tokenId, exploiterBonus);

		currency.safeTransfer(
			msg.sender,
			1 ether * exploiterBonus
		);
	}

  // EXTERNAL ADMIN FUNCTIONS
	function allocate(
		address recipient, 
		uint256 amount,
		uint256 referrerToken
	)
		external override onlyRole(DEFAULT_ADMIN_ROLE) 
	{
		uint256 toBeMintedNext   = _totalSupply;
        uint256 totalSupplyAfter = toBeMintedNext + amount;
		if(totalSupplyAfter > _maxSupply) revert SupplyCapExceeded(totalSupplyAfter, _maxSupply);

		emit Minted(recipient, toBeMintedNext, amount, 0, referrerToken);

		_mintRangeWithReferrerToken(
			recipient, 
			toBeMintedNext, 
			totalSupplyAfter, 
			referrerToken,
			0
		);

		_registerCustomer(recipient, Referral(MASTER_TOKEN_ZERO, ""));
	}

	function retrieve(
		IERC20Upgradeable currency,
		address recipient,
		uint256 amount
	)
		external override onlyRole(DEFAULT_ADMIN_ROLE) 
	{
		if(address(currency) == address(0)) {
			amount = Math.min(amount, address(this).balance);
			(bool suc, ) = recipient.call{ value: amount }("");
			if(!suc) revert();
		} else {
			amount = Math.min(amount, currency.balanceOf(address(this)));
			currency.safeTransfer(recipient, amount);
		}
	}

	function setTransfersPaused(
		bool transfersPaused_
	) 
		external override onlyRole(DEFAULT_ADMIN_ROLE) 
	{
		if(_transfersPaused == transfersPaused_) revert ValueWasAlreadySet("transfersPaused_", abi.encodePacked(transfersPaused_));
		_transfersPaused = transfersPaused_;
		emit TransferStatusChanged(transfersPaused_);
	}

	function setMaxSupply(
		uint24 maxSupply_
	) 
		public override onlyRole(DEFAULT_ADMIN_ROLE)
	{
		if(maxSupply_ < _totalSupply) revert SupplyCapExceeded(_totalSupply, maxSupply_);
		_maxSupply = maxSupply_;

		emit NewMaxSupply(maxSupply_);
	}

	function setMetadata(
		string calldata unrevealedMetadata, 
		string calldata revealedMetadata
	)
		external override onlyRole(METADATA_MANAGER_ROLE) 
	{
		require(!metadataFrozen, "metadata frozen");
		_unrevealedMetadata = unrevealedMetadata;
		_revealedMetadata = revealedMetadata;
		emit MetadataChanged(unrevealedMetadata, revealedMetadata, _revealedUntil);
	}

	function revealMetadata(
		uint256 revealedUntil
	) 
		external override onlyRole(METADATA_MANAGER_ROLE) 
	{
		require(!metadataFrozen, "metadata frozen");
		_revealedUntil = revealedUntil;
		emit MetadataChanged(_unrevealedMetadata, _revealedMetadata, revealedUntil);
	}

	function freezeMetadata(
		bytes4 magicValue
	) 
		external override onlyRole(METADATA_MANAGER_ROLE) 
	{
		require(magicValue == this.freezeMetadata.selector, "must provide magic value");
		metadataFrozen = true;
		emit MetadataFrozen();
	}

	function setMintingStatus(
		bool mintingEnabled_
	)
		external override onlyRole(MINTING_MANAGER_ROLE) 
	{
		if(_mintOpen == mintingEnabled_) revert ValueWasAlreadySet("mintingEnabled_", abi.encodePacked(mintingEnabled_));
		_mintOpen = mintingEnabled_;
		emit MintingStatusChanged(mintingEnabled_);
	}

	// enable claiming volume bonus and record timestamp
	function setVolumeBonusStatus(
		bool volumeBonusEnabled_
	)
		external
		override
		onlyRole(DEFAULT_ADMIN_ROLE) 
	{
		if(
			volumeProps.enabled == volumeBonusEnabled_
		) revert ValueWasAlreadySet("volumeBonusEnabled", abi.encodePacked(volumeBonusEnabled_));

		volumeProps.enabled = volumeBonusEnabled_;
		volumeProps.epoche++;
		emit VolumeBonusStatusChanged(volumeBonusEnabled_);
	}

	function setVolumeProps(VolumeProps memory newProps) public onlyRole(DEFAULT_ADMIN_ROLE) {
		require((!volumeProps.enabled) && (!newProps.enabled), "cannot change on the fly");
		require(newProps.basisPointsPayout < BASIS_POINTS, "basis points payout too high");
		require(newProps.volumeBaseAmount != 0, "base volume cannot be 0");
		require(newProps.otherTeamMultiplier != 0, "otherTeamMultiplier cannot be 0");

		newProps.epoche = volumeProps.epoche;

		volumeProps = newProps;

		emit NewVolumeProps(newProps);
	}

	function setRoyaltyInfo(address recipient, uint256 feeBasisPoints) external override onlyRole(DEFAULT_ADMIN_ROLE) {
		if(recipient == address(0)) revert ZeroParameter("recipient");

		royaltyBasisPoints = uint16(feeBasisPoints);
		royaltyReceiver = recipient;

		emit NewRoyaltyInfo(recipient, feeBasisPoints);
	}

	function registerPurchase(
		address customerAddress,
		IERC20Upgradeable currency,
		address seller,
		uint256 sellerCutBasisPoints,
		uint256 feeInUSDC
	) external onlyRole(STRIVE_CONTRACT_ROLE) {
		Customer storage cust = _customers[customerAddress];

		if(! cust.isRegistered) _registerCustomer(customerAddress, Referral(MASTER_TOKEN_ZERO, ""));

		// sanity check to never overpay the seller
		if(sellerCutBasisPoints > BASIS_POINTS) revert("SELLER SHARE OUT OF BOUND");

		uint256 referrerToken = cust.referrerToken;

		// register the volume for volume bonuses if its not default referrer
		if(referrerToken != MASTER_TOKEN_ZERO) {
			_getTokenInStorage(referrerToken).volumeGenerated += uint32(feeInUSDC / 1 ether);
		}

		emit VolumeGenerated(customerAddress, seller, sellerCutBasisPoints, feeInUSDC);

		// pull payment and pay out matching bonus, currency check is done inside
		_processPayment(customerAddress, currency, feeInUSDC, _getReferrers(referrerToken));

		if(seller != address(0) && sellerCutBasisPoints != 0) {
			currency.safeTransfer(
				seller, 
				feeInUSDC * sellerCutBasisPoints / BASIS_POINTS
			);
		}
	}


  // INTERNAL (Non view)

	function _mintRangeWithReferrerToken(
		address recipient,
		uint256 toBeMintedNext, 
		uint256 totalSupplyAfter,
		uint256 referrerToken,
		uint256 volumePerTokenInUSD
	) internal {
		while(toBeMintedNext < totalSupplyAfter) {
			_mint(recipient, toBeMintedNext);
			Token storage token = _token[toBeMintedNext];
			_renew(token);
			if(referrerToken != MASTER_TOKEN_ZERO) {
			    token.referrerToken = uint24(referrerToken);
				token.volumeGenerated = uint32(volumePerTokenInUSD);
			}
			toBeMintedNext = Math.unsafeInc(toBeMintedNext);
		}
		_totalSupply = uint24(totalSupplyAfter);
	}

	function _processPayment(
		address from,
		IERC20Upgradeable currency,
		uint256 feeInUSDC,
		address[REFERRAL_LAYERS] memory referrers
	)
		internal 
	{
		_enforceCurrency(currency);

		currency.safeTransferFrom(from, address(this), feeInUSDC);

		for(uint256 i = 0; i < REFERRAL_LAYERS; i++) {
			if(referrers[i] == address(0)) break;
			currency.safeTransfer(referrers[i], _calculateReferralAmount(feeInUSDC, i));
		}
    }

	function _renew(Token storage token) internal returns(uint256 nextCheck) {
		nextCheck = VALIDITY_LENGTH + Math.max(block.timestamp, token.nextActivityCheck);

		token.nextActivityCheck = uint64(nextCheck);
	}

	function _registerCustomer(
		address customerAddress, 
		Referral memory referral
	) internal {
		Customer storage cust = _customers[customerAddress];

		if(cust.isRegistered) return;

		cust.isRegistered = true;
		emit CustomerRegistered(customerAddress, referral.tokenId);

		if(referral.tokenId == MASTER_TOKEN_ZERO) {
			return;
		}

		if(_verifyReferralSignature(customerAddress, referral)) {
			cust.referrerToken = uint24(referral.tokenId);
			return;
		}

		revert InvalidReferral(customerAddress, referral.tokenId, referral.sig);
	}

	function _updateVolumesForToken(Token storage token) internal {
		(uint256 downL, uint256 downR) = (token.downL, token.downR);

		if(downL != MASTER_TOKEN_ZERO) {
			Token storage leftC = _token[downL];
			token.totalVolLeft = leftC.volumeGenerated + leftC.totalVolLeft + leftC.totalVolRight;
		}
		if(downR != MASTER_TOKEN_ZERO) {
			Token storage rightC = _token[token.downR];
			token.totalVolRight = rightC.volumeGenerated + rightC.totalVolLeft + rightC.totalVolRight;
		}
	}

	function _zeroOutVolumes(Token storage token) internal {
		token.usedLeft = token.totalVolLeft;
		token.usedRight = token.totalVolRight;
	}

	function _beforeTokenTransfer(
		address from, 
		address to, 
		uint256 tokenId
	)
		internal virtual override 
	{
		super._beforeTokenTransfer(from, to, tokenId);
		if(
			from != address(0) && 
			_transfersPaused && 
			tokenId != MASTER_TOKEN_ZERO
		) revert TransfersPaused();

		if(
			tokenId == MASTER_TOKEN_ZERO && 
			from != address(0)
		) require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "invalid master token transfer");
	}


  // INTERNAL VIEW
	function _mintAllowed(
        uint256 totalSupplyAfter
    )
		internal view returns(bool) 
	{
		/// minting enabled from admin? 
		/// supply cap respected?
		if(!_mintOpen)                          revert MintNotOpen();
        if(totalSupplyAfter > _maxSupply)      revert SupplyCapExceeded(totalSupplyAfter, _maxSupply);

		return true;
    }

	/// @return referrers might satisfy referrers[i] == address(0) for some i
	function _getReferrers(uint256 tokenId) internal view returns(address[REFERRAL_LAYERS] memory referrers) {
		for(uint256 i = 0; i < REFERRAL_LAYERS; i++) {
			if(tokenId == MASTER_TOKEN_ZERO) break;

			referrers[i] = ownerOf(tokenId);
			tokenId = _getTokenInStorage(tokenId).referrerToken;
		}
	}

	/// @return isValid true if the signature is valid
	function _verifyReferralSignature(
		address invitee,
        Referral memory referral
	)
		internal view returns(bool isValid) 
	{
        return hasRole(
			WHITELIST_SIGNER_ROLE,
			ECDSAUpgradeable.recover(
				_getWhitelistMsgHash(
					invitee,
					referral.tokenId
				),
				referral.sig
			)
		);
    }

	function _getEndOfVolumeBonusChain(uint256 tokenId, bool rightSide) internal view returns(uint256 endToken) {
		uint256 temp;
		if(rightSide) {
			while(true) {
				temp = _getTokenInStorage(tokenId).downR;
				if(temp == MASTER_TOKEN_ZERO) return tokenId;
				tokenId = temp;
			}
		} else {
			while(true) {
				temp = _getTokenInStorage(tokenId).downL;
				if(temp == MASTER_TOKEN_ZERO) return tokenId;
				tokenId = temp;
			}
		}
	}

	function _getAvailableVolumesForToken(Token storage token) internal view returns(
		uint256 volumeLeft,
		uint256 volumeRight
	) {
		return (token.totalVolLeft - token.usedLeft, token.totalVolRight - token.usedRight);
	}

	function _isDefaultApproved(address operator) internal view returns(bool) {
		return hasRole(DEFAULT_APPROVED_ROLE, operator);
	}

	function _getTokenInStorage(uint256 tokenId) internal view returns(Token storage token) {
		if(! _exists(tokenId)) revert TokenDoesntExist(tokenId);
		return _token[tokenId];
	}

	function _enforceCurrency(IERC20Upgradeable currency) internal view {
		if(currency != USDC && currency != USDT) revert OnlyUSDTAndUSDC(address(USDT), address(USDC));
	}


  // PURE 
	function _getWhitelistMsgHash(address invitee, uint256 referrerToken) internal pure returns(bytes32) {
		return ECDSAUpgradeable.toEthSignedMessageHash(abi.encodePacked(invitee, referrerToken));
	}

	function _calculateReferralAmount(uint256 amountSpent, uint256 layer) internal pure returns(uint256) {
		return amountSpent / 10 / (2 ** layer);
	}

	function _calculateVolumeBonus(uint256 l, uint256 r, uint256 payoutBasisPoints) internal pure returns(uint256 earned) {
		return (l + r) * payoutBasisPoints / BASIS_POINTS;
	}
	
	function totalMintingFee(uint256 firstTokenId, uint256 amount) public pure override returns(uint256 totalFeeInUSDC) {
		for(; amount > 0;) {
			amount--;
			totalFeeInUSDC += mintingFee(firstTokenId + amount);
		}
	}

    function mintingFee(uint256 tokenId) public pure override returns(uint256 feeInUSDC) {
		return 1085736 * uint256(Math.lnWad(int256(tokenId**4 * 1 ether))) / 100000 + 300 ether;
    }

  // OVERRIDES 

	function royaltyInfo(uint256, uint256 amount) external view override returns(address, uint256) {
		return (royaltyReceiver, royaltyBasisPoints * amount / BASIS_POINTS);
	}

	function isApprovedForAll(
		address owner, 
		address operator
	) 
		public view virtual override
		returns (bool)
	{
        return _isDefaultApproved(operator)  || super.isApprovedForAll(owner, operator);
    }

	/// @dev the owner of the MASTER_TOKEN_ZERO is default admin
	function hasRole(bytes32 role, address account) 
		public view override returns (bool) 
	{
        return  super.hasRole(role, account) || 
				(
				   role == DEFAULT_ADMIN_ROLE && account == ownerOf(MASTER_TOKEN_ZERO)
				);
    }

  // EXTERNAL VIEW
   // Token and Customer Queries
    function getTokenInfo(uint256 tokenId) 
        external view override
        returns(
            address _owner, 
            string memory _tokenURI,
            uint256 _referrerTokenId
        )
	{
		Token storage token = _getTokenInStorage(tokenId);

		_owner = ownerOf(tokenId);
		_tokenURI = tokenURI(tokenId);
		_referrerTokenId = token.referrerToken;
	}

	/// @return route does NOT include `tokenId` itself in position 0, unless `tokenId` == 0
	function getReferralRoute(uint256 tokenId, uint256 length) external view override returns(uint256[] memory route) {
		route = new uint256[](length);

		for(uint256 i = 0; i < length; i++) {
			tokenId = _getTokenInStorage(tokenId).referrerToken;
			if(tokenId == MASTER_TOKEN_ZERO) break;
			route[i] = tokenId;
		}

		return route;
	}

	function getVolumeInfoForToken(uint256 tokenId) external view returns(
		uint24 up,
		uint24 downLeft,
		uint24 downRight,
		uint32 totalVolLeft,
		uint32 totalVolRight,
		uint32 volumeGenerated,
		uint64 nextActivityCheck,
		uint32 usedLeft,
		uint32 usedRight,
		uint256 earnedThisEpoche
	) {
		Token storage token = _getTokenInStorage(tokenId);
		return (
			token.up,
			token.downL,
			token.downR,
			token.totalVolLeft,
			token.totalVolRight,
			token.volumeGenerated,
			token.nextActivityCheck,
			token.usedLeft, 
			token.usedRight,
			token.bonusPaidByVolumeEpoche[volumeProps.epoche]
		);
	}

	function getAvailableVolumesForToken(uint256 tokenId) external view returns(uint256 leftVolume, uint256 rightVolume) {
		return _getAvailableVolumesForToken(
			_getTokenInStorage(tokenId)
		);
	}

	function getCustomer(address customerAddress) external view returns(Customer memory) {
		return _customers[customerAddress];
	}

    function tokenURI(uint256 tokenId)
		public view override returns (string memory) 
	{
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = tokenId < _revealedUntil ? _revealedMetadata : _unrevealedMetadata;

        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

   // other contract state queries:
	function transfersPaused() external view override returns(bool) {
		return _transfersPaused;
	}

	function mintingEnabled() external view override returns(bool) {
		return _mintOpen;
	}

	function maxSupply() external view override returns(uint256) {
		return _maxSupply;
	}

	function totalSupply() external view override returns(uint256) {
		return _totalSupply;
	}

	function verifyReferralSignature(
		address invitee,
		Referral calldata referral
	) external view override returns(bool) {
		return _verifyReferralSignature(invitee, referral);
	}

	function supportsInterface(bytes4 interfaceId) 
		public view virtual 
		override(ERC721Upgradeable, AccessControlUpgradeable, IERC165) 
		returns (bool)
	{
        	return  interfaceId == type(AccessControlUpgradeable).interfaceId || 
					interfaceId == type(IAccessControlUpgradeable).interfaceId ||
			        interfaceId == type(IERC721Upgradeable).interfaceId ||
            		interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
					interfaceId == type(IERC165Upgradeable).interfaceId ||
            		super.supportsInterface(interfaceId);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

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
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);

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
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
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
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
        _checkRole(role);
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
pragma solidity ^0.8.0;


library Math {
    function unsafeInc(uint256 x) internal pure returns(uint256 y) {
        assembly {
            y := add(x, 1)
        }
    }

    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        return a > b ? b : a;
    }

    function max(uint256 a, uint256 b) internal pure returns(uint256) {
        return a > b ? a : b;
    }

    function absDiff(uint256 a, uint256 b) internal pure returns(uint256) {
        return a > b ? (a - b) : (b - a);
    }

    /// CREDIT to Remco Bloemen
    /// this code is under MIT License: https://xn--2-umb.com/22/exp-ln/index.html#usage
    function log2(uint256 x) internal pure returns (uint256 r) {
        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))

            // For the remaining 32 bits, use a De Bruijn lookup.
            x := shr(r, x)
            x := or(x, shr(1, x))
            x := or(x, shr(2, x))
            x := or(x, shr(4, x))
            x := or(x, shr(8, x))
            x := or(x, shr(16, x))
            r := or(r, byte(shr(251, mul(x, shl(224, 0x07c4acdd))),
                0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f))
        }
    }
    function lnWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            require(x > 0, "UNDEFINED");

            // We want to convert x from 10**18 fixed point to 2**96 fixed point.
            // We do this by multiplying by 2**96 / 10**18. But since
            // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
            // and add ln(2**96 / 10**18) at the end.

            // Reduce range of x to (1, 2) * 2**96
            // ln(2^k * x) = k * ln(2) + ln(x)
            int256 k = int256(log2(uint256(x))) - 96;
            x <<= uint256(159 - k);
            x = int256(uint256(x) >> 159);

            // Evaluate using a (8, 8)-term rational approximation.
            // p is made monic, we will multiply by a scale factor later.
            int256 p = x + 3273285459638523848632254066296;
            p = ((p * x) >> 96) + 24828157081833163892658089445524;
            p = ((p * x) >> 96) + 43456485725739037958740375743393;
            p = ((p * x) >> 96) - 11111509109440967052023855526967;
            p = ((p * x) >> 96) - 45023709667254063763336534515857;
            p = ((p * x) >> 96) - 14706773417378608786704636184526;
            p = p * x - (795164235651350426258249787498 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            // q is monic by convention.
            int256 q = x + 5573035233440673466300451813936;
            q = ((q * x) >> 96) + 71694874799317883764090561454958;
            q = ((q * x) >> 96) + 283447036172924575727196451306956;
            q = ((q * x) >> 96) + 401686690394027663651624208769553;
            q = ((q * x) >> 96) + 204048457590392012362485061816622;
            q = ((q * x) >> 96) + 31853899698501571402653359427138;
            q = ((q * x) >> 96) + 909429971244387300277376558375;
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial is known not to have zeros in the domain.
                // No scaling required because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r is in the range (0, 0.125) * 2**96

            // Finalization, we need to:
            // * multiply by the scale factor s = 5.549…
            // * add ln(2**96 / 10**18)
            // * add k * ln(2)
            // * multiply by 10**18 / 2**96 = 5**18 >> 78

            // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
            r *= 1677202110996718588342820967067443963516166;
            // add ln(2) * k * 5e18 * 2**192
            r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
            // add ln(2**96 / 10**18) * 5e18 * 2**192
            r += 600920179829731861736702779321621459595472258049074101567377883020018308;
            // base conversion: mul 2**18 / 2**192
            r >>= 174;
        }
    }

    function squareRoot(uint256 x) internal pure returns(uint256 s) {
        if(x == 0) return 0;

        assembly {
            let temp := 0
            s := div(x, 2)

            for {} iszero(eq(temp, s)) {} {
                temp := s
                s := div(div(add(mul(temp, temp), x), temp), 2)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "../../node_modules/@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";


interface IGenesis {
    // Initializer (constructor pendant for a proxy)
    function initialize(
        address mintingManager,
		address metadataManager,
		address whitelistSignerWallet,
        VolumeProps calldata props
	) external;

   // EVENTS
    event MetadataChanged(string unrevealed, string revealed, uint256 revealedUntil);
    event MetadataFrozen();
	event MintingStatusChanged(bool isOpen);
    event TransferStatusChanged(bool transfersPaused);
    event VolumeBonusStatusChanged(bool volumeBonusEnabled);
    event NewMaxSupply(uint256 maxSupply);
    event RequestByToken(uint256 tokenId, bytes32[] key, bytes[] value);
    event Minted(address recipient, uint256 firstToBeMinted, uint256 amount, uint256 totalFeeInUSDC, uint256 referrerToken);
    event Placed(uint256 placedToken, uint256 upperToken, bool rightSide);
    event CustomerRegistered(address customer, uint256 tokenId);
    event VolumeGenerated(address customer, address seller, uint256 sellerCutBasisPoints, uint256 USDCAmount);
    event VolumeBonusClaimed(address tokenOwner, uint256 tokenId, uint256 earned, uint256 cycles, bool rightSideBase);
    event TokenRenewed(uint256 token, uint256 validUntil);
    event Exploited(address exploiter, uint256 token, uint256 earned);
    event NewVolumeProps(VolumeProps newVolumeProps);
    event VolumesUpdated(uint256[] tokenIds);
    event NewRoyaltyInfo(address recipient, uint256 basisPoints);


   // ERRORS
    error ZeroParameter(string parameterName);
    error MintNotOpen();
    error SupplyCapExceeded(uint256 tried, uint256 maxSupply);
    error OnlyUSDTAndUSDC(address USDT, address USDC);
    error TransfersPaused();
    error NotAuthorized();
    error InvalidReferral(address caller, uint256 tokenId, bytes sig);
    error TokenDoesntExist(uint256 tokenId);
    error ValueWasAlreadySet(string name, bytes valueRepresentationInBytes);
    error CustomerNotRegistered(address user);
    error InsufficientVolume(uint256 have, uint256 want);
    error VolumeBonusDisabled();
    error EarnedMoreThanMaximumPerEpoche();
    error TokenStillActive(uint256 activeUntil);
    error TokenNotActive();

   // Structures

    struct VolumeProps {
        bool enabled;
        uint48 epoche;
        uint16 basisPointsPayout;
        uint16 volumeBaseAmount;
        uint24 maximumPerEpocheInDollar;
        uint8 otherTeamMultiplier;
        uint16 renewalFeeInDollar;
    }

    struct Customer {
        uint24 referrerToken;
        bool isRegistered;
    }

    struct Token {
        uint24 referrerToken;

        uint24 up;
        uint24 downL;
        uint24 downR;

        uint32 totalVolLeft;
        uint32 totalVolRight;
        uint32 volumeGenerated;
        uint64 nextActivityCheck;
        // packed in the next slot, because users pay most willingly to claim
        uint32 usedLeft;
        uint32 usedRight;

        mapping(uint256 => uint256) bonusPaidByVolumeEpoche;
    }

    struct Referral {
        uint256 tokenId;
        bytes sig;
    }

   // USER FUNCTIONS
    /**
    * @notice mints `amount` NFTs to `receivingWallet`, 
    *         for a certain number of tokens of `currency`, 
    *         given the whitelist `sig` is valid.
    * @param currency the address of either the USDC token or USDT token contract, reverts on other input 
    * @param amount the amount of NFTs the caller wants to mint
    * @param recipient the address of the wallet where the NFTs are minted to
    * @param referral contains the referrer´s Token Id and the signature that was generated for the invitee and the tokenId
    */
	function mint(
		address currency,
		uint256 amount,
		address recipient,
        Referral calldata referral
	) external;

    /**
    * @param parentTokenId must be referrer token of `childTokenId`
    * @param childTokenId must not have been placed yet (childToken.up == 0)
    * @param rightSide true if the childToken should be placed on the right side beneath the parent token
    */
	function placeForVolumeBonus(
        uint256 parentTokenId, 
        uint256 childTokenId, 
        bool rightSide
    ) external;

    
	function updateVolumesForToken(uint256[] calldata tokenIds) external;

    function claimVolumeBonus(
		uint256 tokenId, 
		uint256 cycles, 
		bool rightSideIsBase,
		IERC20Upgradeable currency
	) external;

    function renew(uint256[] calldata tokenIds, IERC20Upgradeable currency) external;

    function registerAsCustomer(Referral calldata referral) external;

    function exploitActivity(uint256 tokenId, IERC20Upgradeable currency) external;


   // VIEW EXTERNAL

    /// @return transfersPaused true if nft transfers (including mint and burn) are paused at the moment, false otherwise
    function transfersPaused() external view returns(bool);

    /// @return mintingEnabled true if minting is possible at the moment, false otherwise
	function mintingEnabled() external view returns(bool);

    /// @return signatureValid true if `referral.sig` is valid for `invitee` and `referral.tokenId`
    ///         and can be used for minting, false otherwise
    function verifyReferralSignature(address invitee, Referral calldata referral) external view returns(bool);

    /// @return route the referrer tokenIds, starting with referrer token of `tokenId`
    /// @dev there cannot be cyclic referrals since they are based on tokenIds not addresses
    /// @dev this method might be gas intensive and should not be called onchain
    function getReferralRoute(uint256 tokenId, uint256 length) external view returns(uint256[] memory);

    function getTokenInfo(uint256 tokenId) 
        external view 
        returns(
            address _owner, 
            string memory _tokenURI,
            uint256 _referrerTokenId
        );
    
    function REFERRAL_LAYERS() external pure returns(uint256);
    function VALIDITY_LENGTH() external pure returns(uint256);
    function EXPLOTER_BASIS_POINTS() external pure returns(uint256);
	function totalMintingFee(uint256 firstTokenId, uint256 amount) external pure returns(uint256 totalFeeInUSDC);
    function mintingFee(uint256 tokenId) external pure returns(uint256 feeInUSDC);

    function USDC() external view returns(IERC20Upgradeable);
    function USDT() external view returns(IERC20Upgradeable);
    function maxSupply() external view returns(uint256);
    function totalSupply() external view returns(uint256);

  // Access Control Functions: 
      // custom roles:
    function METADATA_MANAGER_ROLE() external pure returns(bytes32 roleId);
	function WHITELIST_SIGNER_ROLE() external pure returns(bytes32 roleId);
	function MINTING_MANAGER_ROLE () external pure returns(bytes32 roleId);
    function DEFAULT_APPROVED_ROLE() external pure returns(bytes32 roleId);
    function STRIVE_CONTRACT_ROLE () external pure returns(bytes32 roleId);

   // ADMIN:
    /// @dev mint NFTs for free at any time
    function allocate(address recipient, uint256 amount, uint256 referrerToken) external;

    /// @dev retrieve any funds from the contract. address(0) = ETH
	function retrieve(IERC20Upgradeable currency, address recipient, uint256 amount) external;

    /// @dev set a new max supply for this collection
    function setMaxSupply(uint24 maxSupply_) external;

    /// @dev true => enable transfers; false => disable transfers
	function setTransfersPaused(bool transfersPaused_) external;

    function setVolumeBonusStatus(bool volumeBonusEnabled_) external;

    function setRoyaltyInfo(address recipient, uint256 feeBasisPoints) external;

   // METADATA MANAGER:
    /// @dev set the base strings for the unrevealed and the revealed metadata
	function setMetadata(string calldata unrevealedData, string calldata revealedData) external;

    /// @dev set the index until which metadata is revealed
	function revealMetadata(uint256 revealedUntil) external;

    /// @dev disable `setMetadata()` and `revealMetadata()` thus freezing the metadata
    ///      with the exception of proxy upgrades.
    /// @param magicValue since this action might be irreversible, 
    ///        the caller has to provide the magic value `0x29794306`
	function freezeMetadata(bytes4 magicValue) external;


   // MINTING_MANAGER:
    /// @param mintingEnabled_ true => minting is enabled; false => minting is disabled
	function setMintingStatus(bool mintingEnabled_) external;

   // STRIVE_CONTRACT:
   function registerPurchase(
		address customerAddress,
		IERC20Upgradeable currency,
		address seller,
		uint256 sellerCutBasisPoints,
		uint256 feeInUSDC
	) external;
}
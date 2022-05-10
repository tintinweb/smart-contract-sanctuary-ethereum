// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/ICriminalRecords.sol";
import "./interfaces/ICounterfeitMoney.sol";
import "./interfaces/IStolenNFT.sol";

error BribeIsNotEnough();
error CaseNotFound();
error NotTheLaw();
error ProcessingReport();
error ReportAlreadyFiled();
error SurrenderInstead();
error SuspectNotWanted();
error TheftNotReported();
error ThiefGotAway();
error ThiefIsHiding();

/// @title Police HQ - tracking criminals - staying corrupt
contract CriminalRecords is ICriminalRecords, Ownable {
	/// @inheritdoc ICriminalRecords
	uint8 public override maximumWanted = 50;
	/// @inheritdoc ICriminalRecords
	uint8 public override sentence = 2;
	/// @inheritdoc ICriminalRecords
	uint8 public override thiefCaughtChance = 40;
	/// @inheritdoc ICriminalRecords
	uint32 public override reportDelay = 2 minutes;
	/// @inheritdoc ICriminalRecords
	uint32 public override reportValidity = 24 hours;
	/// @inheritdoc ICriminalRecords
	uint256 public override reward = 100 ether;
	/// @inheritdoc ICriminalRecords
	uint256 public override bribePerLevel = 100 ether;

	/// ERC20 token used to pay bribes and rewards
	ICounterfeitMoney public money;
	/// ERC721 token which is being monitored by the authorities
	IStolenNFT public stolenNFT;
	/// Contracts that cannot be sentenced
	mapping(address => bool) public aboveTheLaw;
	/// Officers / Contracts that can track and sentence others
	mapping(address => bool) public theLaw;

	/// Tracking the reports for identification
	uint256 private _caseNumber;
	/// Tracking the crime reporters and the time since their last report
	mapping(address => Report) private _reports;
	/// Tracking the criminals and their wanted level
	mapping(address => uint8) private _wantedLevel;

	constructor(
		address _owner,
		address _stolenNft,
		address _money,
		address _stakingHideout,
		address _blackMarket
	) Ownable(_owner) {
		stolenNFT = IStolenNFT(_stolenNft);
		money = ICounterfeitMoney(_money);

		theLaw[_stolenNft] = true;
		aboveTheLaw[address(0)] = true;
		aboveTheLaw[_stakingHideout] = true;
		aboveTheLaw[_blackMarket] = true;
	}

	/// @inheritdoc ICriminalRecords
	function bribe(address criminal, uint256 amount) public override returns (uint256) {
		uint256 wantedLevel = _wantedLevel[criminal];
		if (wantedLevel == 0) revert SuspectNotWanted();
		if (amount < bribePerLevel) revert BribeIsNotEnough();

		uint256 levels = amount / bribePerLevel;
		if (wantedLevel < levels) {
			levels = wantedLevel;
		}
		uint256 cost = levels * bribePerLevel;

		_decreaseWanted(criminal, uint8(levels));

		money.burn(msg.sender, cost);

		return levels;
	}

	/// @inheritdoc ICriminalRecords
	function bribeCheque(
		address criminal,
		uint256 amount,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external override returns (uint256) {
		money.permit(criminal, address(this), amount, deadline, v, r, s);
		return bribe(criminal, amount);
	}

	/// @inheritdoc ICriminalRecords
	function reportTheft(uint256 stolenId) external override {
		address holder = stolenNFT.ownerOf(stolenId);

		if (msg.sender == holder) revert SurrenderInstead();
		if (aboveTheLaw[holder]) revert ThiefIsHiding();
		if (_wantedLevel[holder] == 0) revert SuspectNotWanted();
		if (
			_reports[msg.sender].stolenId == stolenId &&
			block.timestamp - _reports[msg.sender].timestamp <= reportValidity
		) revert ReportAlreadyFiled();

		_reports[msg.sender] = Report(stolenId, block.timestamp);

		emit Reported(msg.sender, holder, stolenId);
	}

	/// @inheritdoc ICriminalRecords
	function arrest() external override returns (bool) {
		Report memory report = _reports[msg.sender];
		if (report.stolenId == 0) revert TheftNotReported();
		if (block.timestamp - report.timestamp < reportDelay) revert ProcessingReport();
		if (block.timestamp - report.timestamp > reportValidity) revert ThiefGotAway();

		delete _reports[msg.sender];
		_caseNumber++;

		address holder = stolenNFT.ownerOf(report.stolenId);
		uint256 holderWanted = _wantedLevel[holder];

		uint256 kindaRandom = uint256(
			keccak256(
				abi.encodePacked(
					_caseNumber,
					holder,
					holderWanted,
					report.timestamp,
					block.timestamp,
					blockhash(block.number)
				)
			)
		) % 100; //0-100

		// Arrest is not possible if thief managed to hide or get rid of wanted level
		bool arrested = !aboveTheLaw[holder] &&
			holderWanted > 0 &&
			kindaRandom < thiefCaughtChance + holderWanted;

		if (arrested) {
			_increaseWanted(holder, sentence);

			emit Arrested(msg.sender, holder, report.stolenId);

			stolenNFT.swatted(report.stolenId);

			money.print(msg.sender, reward * holderWanted);
		}

		return arrested;
	}

	/// @inheritdoc ICriminalRecords
	function crimeWitnessed(address criminal) external override onlyTheLaw {
		_increaseWanted(criminal, sentence);
	}

	/// @inheritdoc ICriminalRecords
	function exchangeWitnessed(address from, address to) external override onlyTheLaw {
		if (_wantedLevel[from] > 0 && from != to) {
			_increaseWanted(to, sentence);
		}
	}

	/// @inheritdoc ICriminalRecords
	function surrender(address criminal) external override onlyTheLaw {
		_decreaseWanted(criminal, sentence);
	}

	/// @notice Executed when a theft of a NFT was witnessed, increases the criminals wanted level
	/// @dev Can only be called by the current owner
	/// @param _maxWanted Maximum wanted level a thief can have
	/// @param _sentence The wanted level sentence given for a crime
	/// @param _reportDelay The time that has to pass between a users reports
	/// @param _thiefCaughtChance The chance a report will be successful
	/// @param _reward The reward if a citizen successfully reports a criminal
	/// @param _bribePerLevel How much to bribe to remove a wanted level
	function setWantedParameters(
		uint8 _maxWanted,
		uint8 _sentence,
		uint8 _thiefCaughtChance,
		uint32 _reportDelay,
		uint32 _reportValidity,
		uint256 _reward,
		uint256 _bribePerLevel
	) external onlyOwner {
		maximumWanted = _maxWanted;
		sentence = _sentence;
		thiefCaughtChance = _thiefCaughtChance;
		reportDelay = _reportDelay;
		reportValidity = _reportValidity;
		reward = _reward;
		bribePerLevel = _bribePerLevel;

		emit WantedParamChange(
			maximumWanted,
			sentence,
			thiefCaughtChance,
			reportDelay,
			reportValidity,
			reward,
			bribePerLevel
		);
	}

	/// @notice Set which addresses / contracts are above the law and cannot be sentenced / tracked
	/// @dev Can only be called by the current owner, can also be used to reset addresses
	/// @param badgeNumber Address which should be set
	/// @param state If the given address should be above the law or not
	function setAboveTheLaw(address badgeNumber, bool state) public onlyOwner {
		aboveTheLaw[badgeNumber] = state;
		emit Promotion(badgeNumber, true, state);
	}

	/// @notice Set which addresses / contracts are authorized to sentence thief's
	/// @dev Can only be called by the current owner, can also be used to reset addresses
	/// @param badgeNumber Address which should be set
	/// @param state If the given address should authorized or not
	function setTheLaw(address badgeNumber, bool state) external onlyOwner {
		theLaw[badgeNumber] = state;
		emit Promotion(badgeNumber, false, state);
	}

	/// @inheritdoc ICriminalRecords
	function getReport(address reporter)
		external
		view
		returns (
			uint256,
			uint256,
			bool
		)
	{
		if (_reports[reporter].stolenId == 0) revert CaseNotFound();
		bool processed = block.timestamp - _reports[reporter].timestamp >= reportDelay &&
			block.timestamp - _reports[reporter].timestamp <= reportValidity;

		return (_reports[reporter].stolenId, _reports[reporter].timestamp, processed);
	}

	/// @inheritdoc ICriminalRecords
	function getWanted(address criminal) external view override returns (uint256) {
		return _wantedLevel[criminal];
	}

	/// @notice Increase a criminals wanted level, except if they are above the law
	/// @dev aboveTheLaw[criminal] avoids increasing e.g. the BlackMarkets wanted level on receiving a listing
	/// aboveTheLaw[msg.sender] avoids increasing e.g. the BlackMarket buyers wanted level
	/// @param criminal The caught criminal
	/// @param increase The amount the wanted level should be increased
	function _increaseWanted(address criminal, uint8 increase) internal {
		if (aboveTheLaw[criminal] || aboveTheLaw[msg.sender]) return;

		uint8 currentLevel = _wantedLevel[criminal];
		uint8 nextLevel;

		unchecked {
			nextLevel = currentLevel + increase;
		}
		if (nextLevel < currentLevel || nextLevel > maximumWanted) {
			nextLevel = maximumWanted;
		}

		_wantedLevel[criminal] = nextLevel;
		emit Wanted(criminal, nextLevel);
	}

	/// @notice Decrease a criminals wanted level, except if they are above the law
	/// @dev If current > max the maximumWanted will be used (in case the params changed)
	/// @param criminal The criminal
	/// @param decrease The amount the wanted level should be decreased
	function _decreaseWanted(address criminal, uint8 decrease) internal {
		if (aboveTheLaw[criminal] || aboveTheLaw[msg.sender]) return;

		uint8 currentLevel = _wantedLevel[criminal];
		uint8 nextLevel = 0;

		if (currentLevel > maximumWanted) {
			currentLevel = maximumWanted;
		}

		unchecked {
			if (decrease < currentLevel) {
				nextLevel = currentLevel - decrease;
			}
		}

		_wantedLevel[criminal] = nextLevel;
		emit Wanted(criminal, nextLevel);
	}

	/// @dev Modifier to only allow msg.senders that are the law to execute a function
	modifier onlyTheLaw() {
		if (!theLaw[msg.sender]) revert NotTheLaw();
		_;
	}

	/// @notice Emitted when theLaw/aboveTheLaw is set or unset
	/// @param user The user that got promoted / demoted
	/// @param aboveTheLaw Whether the user is set to be theLaw or aboveTheLaw
	/// @param state true if it was a promotion, false if it was a demotion
	event Promotion(address indexed user, bool aboveTheLaw, bool state);

	/// @notice Emitted when any wanted parameter is being changed
	/// @param maxWanted Maximum wanted level a thief can have
	/// @param sentence The wanted level sentence given for a crime
	/// @param thiefCaughtChance The chance a report will be successful
	/// @param reportDelay The time that has to pass between report and arrest
	/// @param reportValidity The time the report is valid for
	/// @param reward The reward if a citizen successfully reports a criminal
	/// @param bribePerLevel How much to bribe to remove a wanted level
	event WantedParamChange(
		uint8 maxWanted,
		uint8 sentence,
		uint256 thiefCaughtChance,
		uint256 reportDelay,
		uint256 reportValidity,
		uint256 reward,
		uint256 bribePerLevel
	);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

error CallerNotTheOwner();
error NewOwnerIsZeroAddress();

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
abstract contract Ownable {
	address private _contractOwner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	/**
	 * @dev Initializes the given owner as the initial owner.
	 */
	constructor(address contractOwner_) {
		_transferOwnership(contractOwner_);
	}

	/**
	 * @dev Returns the address of the current owner.
	 */
	function owner() public view virtual returns (address) {
		return _contractOwner;
	}

	/**
	 * @dev Throws if called by any account other than the owner.
	 */
	modifier onlyOwner() {
		if (owner() != msg.sender) revert CallerNotTheOwner();
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
		if (newOwner == address(0)) revert NewOwnerIsZeroAddress();
		_transferOwnership(newOwner);
	}

	/**
	 * @dev Transfers ownership of the contract to a new account (`newOwner`).
	 * Internal function without access restriction.
	 */
	function _transferOwnership(address newOwner) internal virtual {
		address oldOwner = _contractOwner;
		_contractOwner = newOwner;
		emit OwnershipTransferred(oldOwner, newOwner);
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
pragma solidity ^0.8.0;

/// @title Police HQ - tracking criminals - staying corrupt
interface ICriminalRecords {
	/// @notice Emitted when the wanted level of a criminal changes
	/// @param criminal The user that committed a crime
	/// @param level The criminals new wanted level
	event Wanted(address indexed criminal, uint256 level);

	/// @notice Emitted when a report against a criminal was filed
	/// @param snitch The user that reported the theft
	/// @param thief The user that got reported
	/// @param stolenId The tokenID of the stolen NFT
	event Reported(address indexed snitch, address indexed thief, uint256 indexed stolenId);

	/// @notice Emitted when a the criminal is arrested
	/// @param snitch The user that reported the theft
	/// @param thief The user that got reported
	/// @param stolenId The tokenID of the stolen NFT
	event Arrested(address indexed snitch, address indexed thief, uint256 indexed stolenId);

	/// @notice Struct to store the the details of a report
	struct Report {
		uint256 stolenId;
		uint256 timestamp;
	}

	/// @notice Maximum wanted level a thief can have
	/// @return The maximum wanted level
	function maximumWanted() external view returns (uint8);

	/// @notice The wanted level sentence given for a crime
	/// @return The sentence
	function sentence() external view returns (uint8);

	/// @notice The percentage between 0-100 a report is successful and the thief is caught
	/// @return The chance
	function thiefCaughtChance() external view returns (uint8);

	/// @notice Time that has to pass between the report and the arrest of a criminal
	/// @return The time
	function reportDelay() external view returns (uint32);

	/// @notice Time how long a report will be valid
	/// @return The time
	function reportValidity() external view returns (uint32);

	/// @notice How much to bribe to remove a wanted level
	/// @return The cost of a bribe
	function bribePerLevel() external view returns (uint256);

	/// @notice The reward if a citizen successfully reports a criminal
	/// @return The reward
	function reward() external view returns (uint256);

	/// @notice Decrease the criminals wanted level by providing a bribe denominated in CounterfeitMoney
	/// @dev The decrease depends on {bribePerLevel}. If more CounterfeitMoney is given
	/// then needed it will not be transferred / burned.
	/// Emits a {Wanted} Event
	/// @param criminal The criminal whose wanted level should be reduced
	/// @param amount Amount of CounterfeitMoney available to pay the bribe
	/// @return Number of wanted levels that have been removed
	function bribe(address criminal, uint256 amount) external returns (uint256);

	/// @notice Decrease the criminals wanted level by providing a bribe denominated in CounterfeitMoney and a valid EIP-2612 Permit
	/// @dev Same as {xref-ICriminalRecords-bribe-address-uint256-}[`bribe`], with additional signature parameters which
	/// allow the approval and transfer of CounterfeitMoney in a single Transaction using EIP-2612 Permits
	/// Emits a {Wanted} Event
	/// @param criminal The criminal whose wanted level should be reduced
	/// @param amount Amount of CounterfeitMoney available to pay the bribe
	/// @param deadline timestamp until when the given signature will be valid
	/// @param v The parity of the y co-ordinate of r of the signature
	/// @param r The x co-ordinate of the r value of the signature
	/// @param s The x co-ordinate of the s value of the signature
	/// @return Number of wanted levels that have been removed
	function bribeCheque(
		address criminal,
		uint256 amount,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256);

	/// @notice Report the theft of a stolen NFT, required to trigger an arrest
	/// @dev Emits a {Reported} Event
	/// @param stolenId The stolen NFTs tokenID that should be reported
	function reportTheft(uint256 stolenId) external;

	/// @notice After previous report was filed the arrest can be triggered
	/// If the arrest is successful the stolen NFT will be returned / burned
	/// If the thief gets away another report has to be filed
	/// @dev Emits a {Arrested} and {Wanted} Event
	/// @return Returns true if the report was successful
	function arrest() external returns (bool);

	/// @notice Returns the wanted level of a given criminal
	/// @param criminal The criminal whose wanted level should be returned
	/// @return The criminals wanted level
	function getWanted(address criminal) external view returns (uint256);

	// @notice Returns whether report data and processing state
	/// @param reporter The reporter who reported the theft
	/// @return stolenId The reported stolen NFT
	/// @return timestamp The timestamp when the theft was reported
	/// @return processed true if the report has been processed, false if not reported / processed or expired
	function getReport(address reporter)
		external
		view
		returns (
			uint256,
			uint256,
			bool
		);

	/// @notice Executed when a theft of a NFT was witnessed, increases the criminals wanted level
	/// @dev Emits a {Wanted} Event
	/// @param criminal The criminal who committed the crime
	function crimeWitnessed(address criminal) external;

	/// @notice Executed when a transfer of a NFT was witnessed, increases the receivers wanted level
	/// @dev Emits a {Wanted} Event
	/// @param from The sender of the stolen NFT
	/// @param to The receiver of the stolen NFT
	function exchangeWitnessed(address from, address to) external;

	/// @notice Allows the criminal to surrender and to decrease his wanted level
	/// @dev Emits a {Wanted} Event
	/// @param criminal The criminal who turned himself in
	function surrender(address criminal) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

/// @title Counterfeit Money is just as good as "real" money
/// @dev ERC20 Token with dynamic supply, supporting EIP-2612 signatures for token approvals
interface ICounterfeitMoney is IERC20, IERC20Permit {
	/// @notice Prints and sends a certain amount of CounterfeitMoney to an user
	/// @dev Emits an Transfer event from zero-address
	/// @param to The address receiving the freshly printed money
	/// @param amount The amount of money that will be printed
	function print(address to, uint256 amount) external;

	/// @notice Burns and removes an approved amount of CounterfeitMoney from an user
	/// @dev Emits an Transfer event to zero-address
	/// @param from The address losing the CounterfeitMoney
	/// @param amount The amount of money that will be removed from the account
	function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "../tokens/IERC721Permit.sol";

/// @title Steal somebody's NFTs (with their permission of course)
/// @dev ERC721 Token supporting EIP-2612 signatures for token approvals
interface IStolenNFT is IERC2981, IERC721Metadata, IERC721Enumerable, IERC721Permit {
	/// @notice Emitted when a user steals / mints a NFT
	/// @param thief The user who stole a NFT
	/// @param originalChainId The chain the Nft was stolen from
	/// @param originalContract The original NFTs contract address
	/// @param originalId The original NFTs token ID
	/// @param stolenId The token ID of the minted StolenNFT
	event Stolen(
		address indexed thief,
		uint64 originalChainId,
		address indexed originalContract,
		uint256 indexed originalId,
		uint256 stolenId
	);

	/// @notice Emitted when a user was reported and gets his StolenNFT taken away / burned
	/// @param thief The user who returned the StolenNFT
	/// @param originalChainId The chain the Nft was stolen from
	/// @param originalContract The original NFTs contract address
	/// @param originalId The original NFTs token ID
	/// @param stolenId The token ID of the StolenNFT
	event Seized(
		address indexed thief,
		uint64 originalChainId,
		address originalContract,
		uint256 originalId,
		uint256 indexed stolenId
	);

	/// @notice Struct to store the contract and token ID of the NFT that was stolen
	struct NftData {
		uint32 tokenRoyalty;
		uint64 chainId;
		address contractAddress;
		uint256 tokenId;
	}

	/// @notice Steal / Mint an original NFT to create a StolenNFT
	/// @dev Emits a Stolen event
	/// @param originalChainId The chainId the NFT originates from, used to trace where the nft was stolen from
	/// @param originalAddress The original NFTs contract address
	/// @param originalId The original NFTs token ID
	/// @param mintFrom Optional address the StolenNFT will be minted and transferred from
	/// @param royaltyFee Optional royalty that should be payed to the original owner on secondary market sales
	/// @param uri Optional Metadata URI to overwrite / censor the original NFT
	function steal(
		uint64 originalChainId,
		address originalAddress,
		uint256 originalId,
		address mintFrom,
		uint32 royaltyFee,
		string memory uri
	) external payable returns (uint256);

	/// @notice Allows the StolenNFT to be taken away / burned by the authorities
	/// @dev Emits a Swatted event
	/// @param stolenId The token ID of the StolenNFT
	function swatted(uint256 stolenId) external;

	/// @notice Allows the holder to return / burn the StolenNFT
	/// @dev Emits a Swatted event
	/// @param stolenId The token ID of the StolenNFT
	function surrender(uint256 stolenId) external;

	/// @notice Returns the stolenID for a given original NFT address and tokenID if stolen
	/// @param originalAddress The contract address of the original NFT
	/// @param originalId The tokenID of the original NFT
	/// @return The stolenID
	function getStolen(address originalAddress, uint256 originalId)
		external
		view
		returns (uint256);

	/// @notice Returns the original NFT address and tokenID for a given stolenID if stolen
	/// @param stolenId The stolenID to lookup
	/// @return originalChainId The chain the NFT was stolen from
	/// @return originalAddress The contract address of the original NFT
	/// @return originalId The tokenID of the original NFT
	function getOriginal(uint256 stolenId)
		external
		view
		returns (
			uint64,
			address,
			uint256
		);
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
interface IERC20Permit {
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

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

/**
 * @dev Interface of extending the IERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC721 approval (see {IERC721-approval}) by
 * presenting a message signed by the account. By not relying on `{IERC721-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC721Permit is IERC20Permit {

}
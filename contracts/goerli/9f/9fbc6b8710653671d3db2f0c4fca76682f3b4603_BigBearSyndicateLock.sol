//                             .*+=.
//                        .#+.  -###: *#*-
//                         ###+   --   -=:
//                         .#+:.+###*.+*=.
//       .::-----.       *:   :#######:*##=                                                             +++++=-:.
//  -+#%@@@@@@@@@@@%+.  :#%*  *########-*##.                                                           [email protected]@@@@@@@@@%*=:
// %@@@@@@@@@@@@@@@@@@#. :*#+ +############:           :-=++++=:                                       [email protected]@@@@@@@@@@@@@@=
// [email protected]@@@@@@@@@@@@@@@@@@@:     .########=:.            #@@@@@@@@@@#.                                    *@@@@@@@@@@@@@@@@@-
//  %@@@@@@%=--=+%@@@@@@@:      =+***=:  :=+*+=:      %@@@@:.-*@@@@.   .::::::::::-.      =****+:      %@@@@@@++*@@@@@@@@@-
//  [email protected]@@@@@@      [email protected]@@@@@#   *%+.      [email protected]@@@@@@@@-    #@@@#    *@@@=   %@@@@@@@@@@@=     #@@@@@@%      @@@@@@#    -%@@@@@@%
//   #@@@@@@=      :@@@@@@   @@@@@=   [email protected]@@@%#%@@@@.   *@@@#   .%@@@.   @@@@@@@@@@@%     [email protected]@@@@@@@     [email protected]@@@@@=      #@@@@@@
//   :@@@@@@%       *@@@@@   #@@@@@   [email protected]@@@   #@@@-   [email protected]@@@  -%@@%:    @@@@#-:::::      %@@@:%@@@:    [email protected]@@@@@.      [email protected]@@@@%
//    *@@@@@@=      *@@@@%   [email protected]@@@@.  [email protected]@@#   :**+.   [email protected]@@@%@@@@#      @@@@+           [email protected]@@+ [email protected]@@-    [email protected]@@@@@       *@@@@@+
//     @@@@@@%     [email protected]@@@@=   [email protected]@@@@=  [email protected]@@#           [email protected]@@@@@@@@@*.    @@@@+           @@@@  :@@@+    *@@@@@*      [email protected]@@@@%
//     [email protected]@@@@@+:-*@@@@@@+    [email protected]@@@@*  [email protected]@@%  ==---:   [email protected]@@@==*@@@@@+   @@@@%**#*      [email protected]@@=   @@@#    #@@@@@-   .=%@@@@@*
//      #@@@@@@@@@@@@@@*      @@@@@%  :@@@@ :@@@@@@*   @@@@   .%@@@@:  @@@@@@@@@      %@@@    @@@@    @@@@@@@%%@@@@@@@%:
//      [email protected]@@@@@@@@@@@@@@%=    #@@@@@   @@@@ [email protected]@@@@@%   @@@%    :@@@@+  @@@@%===-     [email protected]@@%**[email protected]@@@   [email protected]@@@@@@@@@@@@@*-
//       [email protected]@@@@@%**#@@@@@@*   [email protected]@@@@:  %@@@:   #@@@@   #@@%     @@@@+  @@@@+         %@@@@@@@@@@@@:  :@@@@@@@@@@@@*
//        %@@@@%     %@@@@@:  :@@@@@=  *@@@+   %@@@%   *@@@    [email protected]@@@-  @@@@+        [email protected]@@@%***@@@@@=  [email protected]@@@@@:#@@@@@:
//        :@@@@@:    *@@@@@-   @@@@@#  :@@@@#+%@@@@*   [email protected]@@--=#@@@@#   @@@@@@@@@#   %@@@@-   [email protected]@@@*  [email protected]@@@@%  %@@@@@.
//         [email protected]@@@*  [email protected]@@@@#    #@@@@@   [email protected]@@@@@@@@#    [email protected]@@@@@@@@@=    @@@@@@@@@@  [email protected]@@@@    [email protected]@@@%  #@@@@@*  [email protected]@@@@%.
//          @@@@@@@@@@@@%=     -###*+    .+#@@%#+:      %@@@@%#+-      #%##%%%%#*  +%%%%+    -%%%%%  %@@@@@-   :@@@@@%
//          :%@@@@%#*+-.                                                                              ::---     :@@@@@%.
//                        .---:                                                                                  .-==++:
//                      =*+:.++-      :=.   ..  .:.  .---:    ::.    .::.       .         ....   ...:::::
//                     +##=  ##+ =*+- -==- ###: ##=  *#####-  ###  :######=   =###. ##########= *########-
//                     ####+-:   -###+##+ -+=+=.++. :##==###  ###  ###:.###.  +#*#* .-::###:... -###=---:
//                     -######.   .*###+  #######*  ==-  .=+  ###  ###  .--   ##=-#+    *##-     ###=-=-
//                   --   .###:    :##+  =##-####- .##= .*#* .===  -=+   === .##*=##-   :##*     =######.
//                  :##+  -##+    :##=  .##* *###. =#######- =###  +*+-.:--- :+*#+###:   *##:     ###=..
//                  -###+*##=    .##=   +##: -##+  +######:  =###: -#######: =+=: .::-   :##*     +##*::::....
//                   =*##*+.      .     .::   ::.  .::-::    .::.   :=+++=.  :==.  .**+   :-=:    .###########:

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

error InvalidTimeBoost();
error InvalidMultiplier();
error InvalidContractAddress();
error InvalidTokenContract();
error InvalidToken();
error NotOwner();
error Paused();
error Reentry();
error Initialized();
error InvalidBlocksPerDay();
error TokenIsAlreadyLocked();
error TokenIsNotLocked();
error TokenIsNotReady();
error InvalidLootbox();
error LootboxSoldOut();
error InsufficientPoints();
error InvalidLootboxPointCost();

contract BigBearSyndicateLock is IERC721ReceiverUpgradeable {
	// ------------------------------
	// 			V1 Variables
	// ------------------------------

	struct Token {
		uint256 readyBlock;
		uint256 lockDays;
		uint256 startTimeStamp;
		uint256 power;
		uint256 tokenId;
		address contractAddress;
	}

	struct Locker {
		uint256 pointsSpentWithPrecision;
		uint256 power;
		int256 offset;
		uint256 pointsPerBlockWithPrecision;
		Token[] lockedTokens;
		uint256 indexInLockerAddresses;
	}

	struct TimeBoost {
		uint256 lockDays;
		uint256 multiplier;
	}

	struct TokenContract {
		address contractAddress;
		uint256 multiplier;
	}

	struct Lootbox {
		uint256 pointCostWithPrecision;
		uint256 supply;
	}

	TimeBoost[] private _timeBoosts;
	TokenContract[] private _tokenContracts;
	uint256 private _blocksPerDay;
	uint256 private _pointsPerBlockWithPrecision;
	mapping(address => Locker) private _lockerAddressToLocker;
	address[] private _lockerAddresses;
	uint256 private _pointsPerPowerPerBlockWithPrecision;
	uint256 private _totalPointsPerPowerWithPrecision;
	uint256 private _totalLockPower;
	uint256 private _totalLockCount;
	uint256 private _lastPointsUpdateBlock;
	uint256 private constant PRECISION = 1e12;
	address private _owner;
	bool private _paused;
	uint256 private constant NOTENTERED = 1;
	uint256 private constant ENTERED = 2;
	uint256 private _reentryStatus;
	bool private _initialized;
	Lootbox[] private _lootboxes;

	event LootboxPurchased(address indexed locker, uint256 indexed lootboxId);

	/*
	 * DO NOT ADD OR REMOVE VARIABLES ABOVE THIS LINE. INSTEAD, CREATE A NEW VERSION SECTION BELOW.
	 * MOVE THIS COMMENT BLOCK TO THE END OF THE LATEST VERSION SECTION PRE-DEPLOYMENT.
	 */

	function initialize() public initializer {
		_initialized = true;
		_reentryStatus = NOTENTERED;
		_paused = false;
		_owner = msg.sender;
		setBlocksPerDay(5760);
		setPointsPerBlock(1000);
	}

	function onERC721Received(
		address,
		address,
		uint256,
		bytes calldata
	) external pure override returns (bytes4) {
		return IERC721ReceiverUpgradeable.onERC721Received.selector;
	}

	function lock(
		uint256[] calldata tokenIds,
		address contractAddress,
		uint256 lockDays
	) external nonReentrant whenNotPaused {
		if (tokenIds.length == 0) {
			revert InvalidToken();
		}

		uint256 changeInPowerPerToken = _tokenContract(contractAddress)
			.multiplier * _timeBoost(lockDays).multiplier;
		if (0 == changeInPowerPerToken) {
			revert InvalidMultiplier();
		}

		address sender = msg.sender;
		Locker storage l = _lockerAddressToLocker[sender];
		if (0 == l.indexInLockerAddresses) {
			_lockerAddresses.push(sender);
			l.indexInLockerAddresses = _lockerAddresses.length;
		}

		uint256 tokenCount = tokenIds.length;
		for (uint256 i = 0; i < tokenCount; ++i) {
			for (uint256 j = 0; j < l.lockedTokens.length; ++j) {
				Token storage token = l.lockedTokens[j];
				if (
					token.contractAddress == contractAddress &&
					token.tokenId == tokenIds[i]
				) {
					revert TokenIsAlreadyLocked();
				}
			}
		}

		for (uint256 i = 0; i < tokenCount; ++i) {
			l.lockedTokens.push(
				Token(
					block.number + lockDays * _blocksPerDay,
					lockDays,
					block.timestamp,
					changeInPowerPerToken,
					tokenIds[i],
					contractAddress
				)
			);
		}

		uint256 pointsReceived = _pointsWithPrecision(l);
		uint256 changeInPower = tokenCount * changeInPowerPerToken;
		l.power += changeInPower;
		_totalLockCount += tokenCount;
		_totalLockPower += changeInPower;
		_updatePoints(l, pointsReceived);

		for (uint256 i = 0; i < tokenCount; ++i) {
			IERC721(contractAddress).safeTransferFrom(
				sender,
				address(this),
				tokenIds[i]
			);
		}
	}

	function unlock(uint256[] calldata tokenIds, address contractAddress)
		external
		nonReentrant
		whenNotPaused
	{
		if (tokenIds.length == 0) {
			revert InvalidToken();
		}
		address sender = msg.sender;
		Locker storage l = _lockerAddressToLocker[sender];
		if (l.lockedTokens.length < tokenIds.length) {
			revert TokenIsNotLocked();
		}

		uint256 tokenCount = tokenIds.length;
		uint256 lockCount = l.lockedTokens.length;
		bool[] memory unlock_ = new bool[](lockCount);
		for (uint256 i = 0; i < tokenCount; ++i) {
			bool found = false;
			for (uint256 j = 0; j < lockCount; ++j) {
				Token storage token = l.lockedTokens[j];
				if (
					!(token.contractAddress == contractAddress &&
						token.tokenId == tokenIds[i])
				) {
					continue;
				}
				if (token.readyBlock > block.number) {
					revert TokenIsNotReady();
				}
				unlock_[j] = found = true;
				break;
			}
			if (!found) {
				revert TokenIsNotLocked();
			}
		}

		uint256 changeInPower;
		for (uint256 i = lockCount; i > 0; --i) {
			Token memory token = l.lockedTokens[i - 1];
			if (!unlock_[i - 1]) {
				continue;
			}
			if (i == l.lockedTokens.length) {
				l.lockedTokens.pop();
			} else {
				Token memory lastToken = l.lockedTokens[
					l.lockedTokens.length - 1
				];
				l.lockedTokens[i - 1] = lastToken;
				l.lockedTokens.pop();
			}
			changeInPower += token.power;
		}

		uint256 pointsReceived = _pointsWithPrecision(l);
		l.power -= changeInPower;
		_totalLockPower -= changeInPower;
		_totalLockCount -= tokenCount;
		_updatePoints(l, pointsReceived);

		for (uint256 i = 0; i < tokenCount; ++i) {
			IERC721(contractAddress).safeTransferFrom(
				address(this),
				sender,
				tokenIds[i]
			);
		}
	}

	function purchaseLootbox(uint256 lootboxId)
		external
		nonReentrant
		whenNotPaused
	{
		if (lootboxId >= _lootboxes.length) {
			revert InvalidLootbox();
		}

		Lootbox storage lootbox = _lootboxes[lootboxId];
		if (0 == lootbox.supply) {
			revert LootboxSoldOut();
		}

		address sender = msg.sender;
		Locker storage l = _lockerAddressToLocker[sender];
		if (_pointsWithPrecision(l) < lootbox.pointCostWithPrecision) {
			revert InsufficientPoints();
		}

		--lootbox.supply;
		l.pointsSpentWithPrecision += lootbox.pointCostWithPrecision;

		emit LootboxPurchased(sender, lootboxId);
	}

	function _tokenContract(address contractAddress)
		private
		view
		returns (TokenContract storage)
	{
		for (uint256 i = 0; i < _tokenContracts.length; ++i) {
			TokenContract storage tc = _tokenContracts[i];
			if (tc.contractAddress == contractAddress) {
				return tc;
			}
		}
		revert InvalidTokenContract();
	}

	function _timeBoost(uint256 lockDays)
		private
		view
		returns (TimeBoost storage)
	{
		for (uint256 i = 0; i < _timeBoosts.length; ++i) {
			TimeBoost storage tb = _timeBoosts[i];
			if (tb.lockDays == lockDays) {
				return tb;
			}
		}
		revert InvalidTimeBoost();
	}

	function _updatePoints(Locker storage l, uint256 pointsReceived) private {
		if (0 == _lastPointsUpdateBlock) {
			_lastPointsUpdateBlock = block.number;
		} else {
			uint256 blocks = block.number - _lastPointsUpdateBlock;
			_totalPointsPerPowerWithPrecision +=
				blocks *
				_pointsPerPowerPerBlockWithPrecision;
			l.offset =
				int256(_totalPointsPerPowerWithPrecision * l.power) -
				int256(pointsReceived);
			_lastPointsUpdateBlock = block.number;
		}
		_pointsPerPowerPerBlockWithPrecision = 0 == _totalLockPower
			? 0
			: _pointsPerBlockWithPrecision / _totalLockPower;
		l.pointsPerBlockWithPrecision =
			l.power *
			_pointsPerPowerPerBlockWithPrecision;
	}

	function _pointsWithPrecision(Locker storage l)
		private
		view
		returns (uint256)
	{
		uint256 blocks = block.number - _lastPointsUpdateBlock;
		uint256 pointsPerLockPowerPerBlock = blocks *
			_pointsPerPowerPerBlockWithPrecision;
		return
			uint256(
				int256(
					l.power *
						(_totalPointsPerPowerWithPrecision +
							pointsPerLockPowerPerBlock)
				) -
					l.offset -
					int256(l.pointsSpentWithPrecision)
			);
	}

	function lockedToken(
		address lockerAddress,
		address contractAddress,
		uint256 tokenId
	) external view returns (Token memory) {
		Locker storage l = _lockerAddressToLocker[lockerAddress];
		for (uint256 i = 0; i < l.lockedTokens.length; ++i) {
			Token memory token = l.lockedTokens[i];
			if (
				token.contractAddress == contractAddress &&
				token.tokenId == tokenId
			) {
				return token;
			}
		}
		revert InvalidToken();
	}

	function lockerInfo(address lockerAddress)
		external
		view
		returns (
			TokenContract[] memory,
			TimeBoost[] memory,
			Locker memory,
			uint256,
			uint256,
			uint256,
			uint256,
			uint256,
			Lootbox[] memory,
			uint256
		)
	{
		Locker storage l = _lockerAddressToLocker[lockerAddress];
		return (
			_tokenContracts,
			_timeBoosts,
			l,
			_pointsWithPrecision(l) / PRECISION,
			_totalLockCount,
			(_blocksPerDay * _pointsPerBlockWithPrecision) / PRECISION,
			_pointsPerPowerPerBlockWithPrecision,
			_totalPointsPerPowerWithPrecision,
			_lootboxes,
			_totalLockPower
		);
	}

	function setBlocksPerDay(uint256 blocksPerDay_) public onlyOwner {
		if (blocksPerDay_ == 0) {
			revert InvalidBlocksPerDay();
		}
		_blocksPerDay = blocksPerDay_;
	}

	function setPointsPerBlock(uint256 pointsPerBlock) public onlyOwner {
		_pointsPerBlockWithPrecision = pointsPerBlock * PRECISION;

		for (uint256 i = 0; i < _lockerAddresses.length; ++i) {
			Locker storage l = _lockerAddressToLocker[_lockerAddresses[i]];
			_updatePoints(l, _pointsWithPrecision(l));
		}
	}

	function setTokenContract(address contractAddress, uint256 multiplier)
		external
		onlyOwner
		isValidContract(contractAddress)
	{
		for (uint256 i = 0; i < _tokenContracts.length; ++i) {
			TokenContract storage tc = _tokenContracts[i];
			if (tc.contractAddress == contractAddress) {
				tc.multiplier = multiplier;
				return;
			}
		}
		_tokenContracts.push(TokenContract(contractAddress, multiplier));
	}

	function setTimeBoost(uint256 lockDays, uint256 multiplier)
		external
		onlyOwner
	{
		for (uint256 i = 0; i < _timeBoosts.length; ++i) {
			if (_timeBoosts[i].lockDays == lockDays) {
				_timeBoosts[i].multiplier = multiplier;
				return;
			}
		}
		_timeBoosts.push(TimeBoost(lockDays, multiplier));
	}

	function setLootbox(
		uint256 lootboxId,
		uint256 pointCost,
		uint256 supply
	) external onlyOwner {
		if (0 == pointCost) {
			revert InvalidLootboxPointCost();
		}

		if (lootboxId > _lootboxes.length) {
			revert InvalidLootbox();
		} else if (lootboxId == _lootboxes.length) {
			_lootboxes.push(Lootbox(pointCost * PRECISION, supply));
		} else {
			_lootboxes[lootboxId].pointCostWithPrecision =
				pointCost *
				PRECISION;
			_lootboxes[lootboxId].supply = supply;
		}
	}

	function pause() external onlyOwner {
		_paused = true;
	}

	function unpause() external onlyOwner {
		_paused = false;
	}

	modifier isValidContract(address contractAddress) {
		if (
			!(contractAddress.code.length > 0) ||
			!ERC165Checker.supportsERC165(contractAddress)
		) {
			revert InvalidContractAddress();
		}
		_;
	}

	modifier onlyOwner() {
		if (_owner != msg.sender) {
			revert NotOwner();
		}
		_;
	}

	modifier whenNotPaused() {
		if (_paused) {
			revert Paused();
		}
		_;
	}

	modifier nonReentrant() {
		if (_reentryStatus == ENTERED) {
			revert Reentry();
		}
		_reentryStatus = ENTERED;
		_;
		_reentryStatus = NOTENTERED;
	}

	modifier initializer() {
		if (_initialized) {
			revert Initialized();
		}
		_;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
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
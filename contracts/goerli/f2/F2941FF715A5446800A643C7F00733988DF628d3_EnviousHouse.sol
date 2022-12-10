// SPDX-License-Identifier: MIT
// GhostContracts (last updated v0.3.0) (EnviuosHouse.sol)

pragma solidity ^0.8.0;

import "./openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "./openzeppelin/token/ERC20/IERC20.sol";
import "./openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import "./openzeppelin/token/ERC721/extensions/IERC721Enumerable.sol";
import "./openzeppelin/utils/Address.sol";
import "./openzeppelin/utils/Context.sol";

import "./interfaces/IEnviousHouse.sol";
import "./interfaces/IERC721Envious.sol";
import "./interfaces/IBondDepository.sol";
import "./interfaces/INoteKeeper.sol";

/**
 * @title EnviousHouse is contract for any NFT to be collateralized.
 *
 * @author F4T50 @ghostown
 * @author 571nkY @ghostown
 * @author 5Tr3TcH @ghostown
 *
 * @dev The main idea is to maintain any existant ERC721-based token. For any new Envious NFT this smart contract 
 * is optionally needed, only for registration purposes. That's why all Envious functionality is re-routed if 
 * functionality exists and otherwise duplicating it here.
 */
contract EnviousHouse is Context, IEnviousHouse {
	using SafeERC20 for IERC20;

	uint256 private _totalCollections;
	address private _initializor;

	uint256 public immutable registerAmount;

	address private _ghostAddress;
	address private _ghostBondingAddress;
	address private _blackHole;
	
	mapping(address => uint256[2]) private _commissions;
	mapping(address => address) private _communityToken;
	mapping(address => address[]) private _communityPool;
	mapping(address => mapping(address => uint256)) private _communityBalance;

	mapping(address => address[]) private _disperseTokens;
	mapping(address => mapping(address => uint256)) private _disperseBalance;
	mapping(address => mapping(address => uint256)) private _disperseTotalTaken;
	mapping(address => mapping(uint256 => mapping(address => uint256))) private _disperseTaken;

	mapping(address => mapping(uint256 => uint256)) private _bondPayouts;
	mapping(address => mapping(uint256 => uint256[])) private _bondIndexes;

	mapping(address => mapping(uint256 => address[])) private _collateralTokens;
	mapping(address => mapping(uint256 => mapping(address => uint256))) private _collateralBalances;
	
	mapping(uint256 => address) public override collections;
	mapping(address => uint256) public override collectionIds;
	mapping(address => bool) public override specificCollections;

	// solhint-disable-next-line
	string private constant NO_DECIMALS = "no decimals";
	// solhint-disable-next-line
	string private constant LOW_AMOUNT = "low amount";
	// solhint-disable-next-line
	string private constant NOT_TOKEN_OWNER = "not token owner";
	// solhint-disable-next-line
	string private constant INVALID_TOKEN_ID = "invalid tokenId";
	// solhint-disable-next-line
	string private constant EMPTY_GHOST = "ghst address is empty";
	// solhint-disable-next-line
	string private constant LENGTHS_NOT_MATCH = "lengths not match";
	// solhint-disable-next-line
	string private constant ZERO_COMMUNITY_TOKEN = "no community token provided";
	// solhint-disable-next-line
	string private constant COLLECTION_EXISTS = "collection exists";
	// solhint-disable-next-line
	string private constant COLLECTION_NOT_EXISTS = "collection not exists";
	// solhint-disable-next-line
	string private constant INVALID_COLLECTION = "invalid collection address";
	// solhint-disable-next-line
	string private constant NO_TOKENS_MINTED = "no tokens minted";
	// solhint-disable-next-line
	string private constant ALREADY_ENVIOUS = "already envious";

	constructor (address blackHoleAddress, uint256 minimalEthAmount) {
		_initializor = _msgSender();
		_blackHole = blackHoleAddress;

		registerAmount = minimalEthAmount;
	}

	function totalCollections() external view override returns (uint256) {
		return _totalCollections;
	}

	function ghostAddress(address collection) external view override returns (address) {
		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			return IERC721Envious(collection).ghostAddress();
		} else {
			return _ghostAddress;
		}
	}

	function ghostBondingAddress(address collection) external view override returns (address) {
		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			return IERC721Envious(collection).ghostBondingAddress();
		} else {
			return _ghostBondingAddress;
		}
	}

	function blackHole(address collection) external view override returns (address) {
		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			return IERC721Envious(collection).blackHole();
		} else {
			return _blackHole;
		}
	}

	function commissions(address collection, uint256 index) external view override returns (uint256) {
		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			return IERC721Envious(collection).commissions(index);
		} else {
			return _commissions[collection][index];
		}
	}

	function communityToken(address collection) external view override returns (address) {
		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			return IERC721Envious(collection).communityToken();
		} else {
			return _communityToken[collection];
		}
	}

	function communityPool(address collection, uint256 index) external view override returns (address) {
		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			return IERC721Envious(collection).communityPool(index);
		} else {
			return _communityPool[collection][index];
		}
	}

	function communityBalance(
		address collection, 
		address tokenAddress
	) external view override returns (uint256) {
		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			return IERC721Envious(collection).communityBalance(tokenAddress);
		} else {
			return _communityBalance[collection][tokenAddress];
		}
	}

	function disperseTokens(
		address collection, 
		uint256 index
	) external view override returns (address) {
		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			return IERC721Envious(collection).disperseTokens(index);
		} else {
			return _disperseTokens[collection][index];
		}
	}

	function disperseBalance(
		address collection, 
		address tokenAddress
	) external view override returns (uint256) {
		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			return IERC721Envious(collection).disperseBalance(tokenAddress);
		} else {
			return _disperseBalance[collection][tokenAddress];
		}
	}

	function disperseTotalTaken(
		address collection, 
		address tokenAddress
	) external view override returns (uint256) {
		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			return IERC721Envious(collection).disperseTotalTaken(tokenAddress);
		} else {
			return _disperseTotalTaken[collection][tokenAddress];
		}
	}

	function disperseTaken(
		address collection, 
		uint256 tokenId,
		address tokenAddress
	) external view override returns (uint256) {
		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			return IERC721Envious(collection).disperseTaken(tokenId, tokenAddress);
		} else {
			return _disperseTaken[collection][tokenId][tokenAddress];
		}
	}

	function bondPayouts(address collection, uint256 tokenId) external view override returns (uint256) {
		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			return IERC721Envious(collection).bondPayouts(tokenId);
		} else {
			return _bondPayouts[collection][tokenId];
		}
	}

	function collateralTokens(
		address collection, 
		uint256 tokenId,
		uint256 index
	) external view override returns (address) {
		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			return IERC721Envious(collection).collateralTokens(tokenId, index);
		} else {
			return _collateralTokens[collection][tokenId][index];
		}
	}

	function collateralBalances(
		address collection, 
		uint256 tokenId,
		address tokenAddress
	) external view override returns (uint256) {
		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			return IERC721Envious(collection).collateralBalances(tokenId, tokenAddress);
		} else {
			return _collateralBalances[collection][tokenId][tokenAddress];
		}
	}

	function bondIndexes(
		address collection, 
		uint256 tokenId,
		uint256 index
	) external view override returns (uint256) {
		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			return IERC721Envious(collection).bondIndexes(tokenId, index);
		} else {
			return _bondIndexes[collection][tokenId][index];
		}
	}

	function setGhostAddresses(address ghostToken, address ghostBonding) external override {
		// solhint-disable-next-line
		require(_initializor == _msgSender() && ghostToken != address(0) && ghostBonding != address(0));

		_ghostAddress = ghostToken;
		_ghostBondingAddress = ghostBonding;
	}

	function setSpecificCollection(address collection) external override {
		// solhint-disable-next-line
		require(_initializor == _msgSender() && collection != address(0));

		specificCollections[collection] = true;
	}

	function registerCollection(
		address collection, 
		address token, 
		uint256 incoming, 
		uint256 outcoming
	) external payable override {
		require(collectionIds[collection] == 0, COLLECTION_EXISTS);
		require(
			IERC721(collection).supportsInterface(type(IERC721).interfaceId) ||
			specificCollections[collection],
			INVALID_COLLECTION
		);
		
		_rescueCollection(collection);

		if (!IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			require(msg.value >= registerAmount, LOW_AMOUNT);
			if (incoming != 0 || outcoming != 0) {
				require(token != address(0), ZERO_COMMUNITY_TOKEN);

				_commissions[collection][0] = incoming;
				_commissions[collection][1] = outcoming;
				_communityToken[collection] = token;
			}

			_disperseTokenCollateral(collection, msg.value, address(0));
		}
	}

	function harvest(
		address collection, 
		uint256[] memory amounts, 
		address[] memory tokenAddresses
	) external override {
		require(collectionIds[collection] != 0, COLLECTION_NOT_EXISTS);
		require(amounts.length == tokenAddresses.length, LENGTHS_NOT_MATCH);
		
		_checkEnvious(collection);

		for (uint256 i = 0; i < tokenAddresses.length; i++) {
			_harvest(collection, amounts[i], tokenAddresses[i]);
		}
	}

	function collateralize(
		address collection, 
		uint256 tokenId, 
		uint256[] memory amounts, 
		address[] memory tokenAddresses
	) external payable override {
		require(amounts.length == tokenAddresses.length, LENGTHS_NOT_MATCH);
		
		_checkEnvious(collection);
		_rescueCollection(collection);

		uint256 ethAmount = msg.value;
		
		for (uint256 i = 0; i < tokenAddresses.length; i++) {
			if (tokenAddresses[i] == address(0)) {
				ethAmount -= amounts[i];
			}
			_addTokenCollateral(collection, tokenId, amounts[i], tokenAddresses[i], false);
		}

		if (ethAmount > 0) {
			Address.sendValue(payable(_msgSender()), ethAmount);
		}
	}

	function uncollateralize(
		address collection, 
		uint256 tokenId, 
		uint256[] memory amounts, 
		address[] memory tokenAddresses
	) external override {
		require(collectionIds[collection] != 0, COLLECTION_NOT_EXISTS);
		require(amounts.length == tokenAddresses.length, LENGTHS_NOT_MATCH);

		_checkEnvious(collection);

		for (uint256 i = 0; i < tokenAddresses.length; i++) {
			_removeTokenCollateral(collection, tokenId, amounts[i], tokenAddresses[i]);
		}
	}

	function disperse(
		address collection, 
		uint256[] memory amounts, 
		address[] memory tokenAddresses
	) external payable override {
		require(amounts.length == tokenAddresses.length, LENGTHS_NOT_MATCH);

		_checkEnvious(collection);
		_rescueCollection(collection);

		uint256 ethAmount = msg.value;
		for (uint256 i = 0; i < tokenAddresses.length; i++) {
			if (tokenAddresses[i] == address(0)) {
				ethAmount -= amounts[i];
			}
			_disperseTokenCollateral(collection, amounts[i], tokenAddresses[i]);
		}

		if (ethAmount > 0) {
			Address.sendValue(payable(_msgSender()), ethAmount);
		}
	}

	function getDiscountedCollateral(
		address collection,
        uint256 bondId,
        address quoteToken,
        uint256 tokenId,
        uint256 amount,
        uint256 maxPrice
    ) external override {
		require(collectionIds[collection] != 0, COLLECTION_NOT_EXISTS);

		_checkEnvious(collection);
		_rescueCollection(collection);

		// NOTE: this contract is temporary holder of `quoteToken` due to the need of
		// registration of bond inside. `amount` of `quoteToken`s should be empty in
		// the end of transaction.
		IERC20(quoteToken).safeTransferFrom(_msgSender(), address(this), amount);
		IERC20(quoteToken).safeApprove(_ghostBondingAddress, amount);

		(uint256 payout,, uint256 index) = IBondDepository(_ghostBondingAddress).deposit(
			bondId,
			amount,
			maxPrice,
			address(this),
			address(this)
		);

		if (payout > 0) {
			_bondPayouts[collection][tokenId] += payout;
			_bondIndexes[collection][tokenId].push(index);
		}
    }

	function claimDiscountedCollateral(
		address collection,
        uint256 tokenId,
        uint256[] memory indexes
    ) external override {
		require(collectionIds[collection] != 0, COLLECTION_NOT_EXISTS);
		require(_ghostAddress != address(0), EMPTY_GHOST);

		_checkEnvious(collection);

		for (uint256 i = 0; i < indexes.length; i++) {
			uint256 index = _arrayContains(indexes[i], _bondIndexes[collection][tokenId]);
			uint256 last = _bondIndexes[collection][tokenId].length - 1;
			_bondIndexes[collection][tokenId][index] = _bondIndexes[collection][tokenId][last];
			_bondIndexes[collection][tokenId].pop();
		}

		uint256 payout = INoteKeeper(_ghostBondingAddress).redeem(address(this), indexes, true);

		if (payout > 0) {
			_bondPayouts[collection][tokenId] -= payout;
			_addTokenCollateral(collection, tokenId, payout, _ghostAddress, true);
		}
    }

	function getAmount(
		address collection,
        uint256 amount,
        address tokenAddress
    ) public view override returns (uint256) {
		require(collectionIds[collection] != 0, COLLECTION_NOT_EXISTS);

		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			return IERC721Envious(collection).getAmount(amount, tokenAddress);
		} else {
			uint256 circulatingSupply =
				IERC20(_communityToken[collection]).totalSupply() - 
				IERC20(_communityToken[collection]).balanceOf(_blackHole);
			return amount * _scaledAmount(collection, tokenAddress) / circulatingSupply;
		}
    }

	function _arrayContains(
        address tokenAddress,
        address[] memory findFrom
    ) private pure returns (bool shouldAppend, uint256 index) {
        shouldAppend = true;
        index = type(uint256).max;
    
        for (uint256 i = 0; i < findFrom.length; i++) {
            if (findFrom[i] == tokenAddress) {
                shouldAppend = false;
                index = i;
                break;
            }
        }
    }

	function _arrayContains(
        uint256 noteId,
        uint256[] memory findFrom
    ) private pure returns (uint256 index) {
        index = type(uint256).max;

        for (uint256 i = 0; i < findFrom.length; i++) {
            if (findFrom[i] == noteId) {
                index = i;
                break;
            }
        }
    }
	
	function _scaledAmount(address collection, address tokenAddress) private view returns (uint256) {
        uint256 totalValue = 0;
        uint256 scaled = 0;
        uint256 defaultDecimals = 10**IERC20Metadata(_communityToken[collection]).decimals();

        for (uint256 i = 0; i < _communityPool[collection].length; i++) {
            uint256 innerDecimals = _communityPool[collection][i] == address(0) ? 
				10**18 : 
				10**IERC20Metadata(_communityPool[collection][i]).decimals();
            
			uint256 tempValue =
				_communityBalance[collection][_communityPool[collection][i]] * 
				defaultDecimals / innerDecimals;

            totalValue += tempValue;

            if (_communityPool[collection][i] == tokenAddress) {
                scaled = tempValue;
            }
        }

        return _communityBalance[collection][tokenAddress] * totalValue / scaled;
    }

	function _harvest(address collection, uint256 amount, address tokenAddress) private {
        uint256 scaledAmount = getAmount(collection, amount, tokenAddress);
        _communityBalance[collection][tokenAddress] -= scaledAmount;

        if (_communityBalance[collection][tokenAddress] == 0) {
            (, uint256 index) = _arrayContains(tokenAddress, _communityPool[collection]);
            _communityPool[collection][index] =
				_communityPool[collection][_communityPool[collection].length - 1];
            _communityPool[collection].pop();
        }

        if (tokenAddress == address(0)) {
            Address.sendValue(payable(_msgSender()), scaledAmount);
        } else {
            IERC20(tokenAddress).safeTransfer(_msgSender(), scaledAmount);
        }

        // NOTE: not every token implements `burn` function, so that is a littl cheat
        IERC20(_communityToken[collection]).safeTransferFrom(_msgSender(), _blackHole, amount);

        emit Harvested(collection, tokenAddress, amount, scaledAmount);
    }

	function _addTokenCollateral(
		address collection,
        uint256 tokenId,
        uint256 amount,
        address tokenAddress,
        bool claim
    ) private {
        require(amount > 0, LOW_AMOUNT);
        require(IERC721(collection).ownerOf(tokenId) != address(0), INVALID_TOKEN_ID);

        _disperse(collection, tokenAddress, tokenId);

        (bool shouldAppend,) = _arrayContains(tokenAddress, _collateralTokens[collection][tokenId]);
        if (shouldAppend) {
            _checkValidity(tokenAddress);
            _collateralTokens[collection][tokenId].push(tokenAddress);
        }

        uint256 ownerBalance = 
			_communityCommission(collection, amount, _commissions[collection][0], tokenAddress);
        _collateralBalances[collection][tokenId][tokenAddress] += ownerBalance;

        if (tokenAddress != address(0) && !claim) {
            IERC20(tokenAddress).safeTransferFrom(_msgSender(), address(this), amount);
        }

        emit Collateralized(collection, tokenId, amount, tokenAddress);
    }

	function _removeTokenCollateral(
		address collection,
        uint256 tokenId,
        uint256 amount,
        address tokenAddress
    ) private {
        require(IERC721(collection).ownerOf(tokenId) == _msgSender(), NOT_TOKEN_OWNER);

        _disperse(collection, tokenAddress, tokenId);

        _collateralBalances[collection][tokenId][tokenAddress] -= amount;
        if (_collateralBalances[collection][tokenId][tokenAddress] == 0) {
            (, uint256 index) = _arrayContains(tokenAddress, _collateralTokens[collection][tokenId]);
            _collateralTokens[collection][tokenId][index] = 
				_collateralTokens[collection][tokenId][_collateralTokens[collection][tokenId].length - 1];
            _collateralTokens[collection][tokenId].pop();
        }

        uint256 ownerBalance =
			_communityCommission(collection, amount, _commissions[collection][1], tokenAddress);

        if (tokenAddress == address(0)) {
            Address.sendValue(payable(_msgSender()), ownerBalance);
        } else {
            IERC20(tokenAddress).safeTransfer(_msgSender(), ownerBalance);
        }

        emit Uncollateralized(collection, tokenId, ownerBalance, tokenAddress);
    }

	function _disperseTokenCollateral(
		address collection, 
		uint256 amount, 
		address tokenAddress
	) private {
        require(amount > 0, LOW_AMOUNT);

        (bool shouldAppend,) = _arrayContains(tokenAddress, _disperseTokens[collection]);
        if (shouldAppend) {
            _checkValidity(tokenAddress);
            _disperseTokens[collection].push(tokenAddress);
        }

        _disperseBalance[collection][tokenAddress] += amount;

        if (tokenAddress != address(0)) {
            IERC20(tokenAddress).safeTransferFrom(_msgSender(), address(this), amount);
        }

        emit Dispersed(collection, tokenAddress, amount);
    }

	function _checkValidity(address tokenAddress) private view {
        if (tokenAddress != address(0)) {
            require(IERC20Metadata(tokenAddress).decimals() != type(uint8).max, NO_DECIMALS);
        }
    }

	function _communityCommission(
		address collection,
        uint256 amount,
        uint256 percentage,
        address tokenAddress
    ) private returns (uint256) {
        uint256 donation = amount * percentage / 1e5;

        (bool shouldAppend,) = _arrayContains(tokenAddress, _communityPool[collection]);
        if (shouldAppend && donation > 0) {
            _communityPool[collection].push(tokenAddress);
        }

        _communityBalance[collection][tokenAddress] += donation;
        return amount - donation;
    }

	function _disperse(address collection, address tokenAddress, uint256 tokenId) private {
		uint256 balance = _disperseBalance[collection][tokenAddress] / IERC721Enumerable(collection).totalSupply();

        if (_disperseTotalTaken[collection][tokenAddress] + balance > _disperseBalance[collection][tokenAddress]) {
            balance = _disperseBalance[collection][tokenAddress] - _disperseTotalTaken[collection][tokenAddress];
        }

        if (balance > _disperseTaken[collection][tokenId][tokenAddress]) {
            uint256 amount = balance - _disperseTaken[collection][tokenId][tokenAddress];
            _disperseTaken[collection][tokenId][tokenAddress] += amount;

            (bool shouldAppend,) = _arrayContains(tokenAddress, _collateralTokens[collection][tokenId]);
            if (shouldAppend) {
                _collateralTokens[collection][tokenId].push(tokenAddress);
            }

            _collateralBalances[collection][tokenId][tokenAddress] += amount;
            _disperseTotalTaken[collection][tokenAddress] += amount;
        }
	}

	function _rescueCollection(address collection) private {
		if (collectionIds[collection] == 0) {
			require(IERC721Enumerable(collection).totalSupply() > 0, NO_TOKENS_MINTED);
			
			_totalCollections += 1;
			collections[_totalCollections] = collection;
			collectionIds[collection] = _totalCollections;
		}
	}

	function _checkEnvious(address collection) private view {
		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			revert(ALREADY_ENVIOUS);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.0;

interface INoteKeeper {
    // Info for market note
    struct Note {
        uint256 payout; // gOHM remaining to be paid
        uint48 created; // time market was created
        uint48 matured; // timestamp when market is matured
        uint48 redeemed; // time market was redeemed
        uint48 marketID; // market ID of deposit. uint48 to avoid adding a slot.
    }

    function redeem(address _user, uint256[] memory _indexes, bool _sendgOHM) external returns (uint256);

    function redeemAll(address _user, bool _sendgOHM) external returns (uint256);

    function pushNote(address to, uint256 index) external;

    function pullNote(address from, uint256 index) external returns (uint256 newIndex_);

    function indexesFor(address _user) external view returns (uint256[] memory);

    function pendingFor(address _user, uint256 _index) external view returns (uint256 payout_, bool matured_);
}

// SPDX-License-Identifier: MIT
// GhostContracts (last updated v0.3.0) (ERC721/extension/ERC721Envious.sol)

pragma solidity ^0.8.0;

interface IEnviousHouse {
	event Collateralized(
		address indexed collection, 
		uint256 indexed tokenId, 
		uint256 amount, 
		address tokenAddress
	);
    
	event Uncollateralized(
		address indexed collection, 
		uint256 indexed tokenId, 
		uint256 amount, 
		address tokenAddress
	);
    
	event Dispersed(
		address indexed collection, 
		address indexed tokenAddress, 
		uint256 amount
	);
    
	event Harvested(
		address indexed collection, 
		address indexed tokenAddress, 
		uint256 amount, 
		uint256 scaledAmount
	);

	function totalCollections() external view returns (uint256);
	function ghostAddress(address collection) external view returns (address);
	function ghostBondingAddress(address collection) external view returns (address);
	function blackHole(address collection) external view returns (address);

	function collections(uint256 index) external view returns (address);
	function collectionIds(address collection) external view returns (uint256);
	function specificCollections(address collection) external view returns (bool);

	function commissions(address collection, uint256 index) external view returns (uint256);
	function communityToken(address collection) external view returns (address);
	function communityPool(address collection, uint256 index) external view returns (address);
	function communityBalance(address collection, address tokenAddress) external view returns (uint256);

	function disperseTokens(address collection, uint256 index) external view returns (address);
	function disperseBalance(address collection, address tokenAdddress) external view returns (uint256);
	function disperseTotalTaken(address collection, address tokenAddress) external view returns (uint256);
	function disperseTaken(address collection, uint256 tokenId, address tokenAddress) external view returns (uint256);

	function bondPayouts(address collection, uint256 bondId) external view returns (uint256);
	function bondIndexes(address collection, uint256 tokenId, uint256 index) external view returns (uint256);

	function collateralTokens(address collection, uint256 tokenId, uint256 index) external view returns (address);
	function collateralBalances(address collection, uint256 tokenId, address tokenAddress) external view returns (uint256);

	function getAmount(address collection, uint256 amount, address tokenAddress) external view returns (uint256);

	function setGhostAddresses(address ghostToken, address ghostBonding) external;
	function setSpecificCollection(address collection) external;

	function registerCollection(
		address collection,
		address token,
		uint256 incoming,
		uint256 outcoming
	) external payable;

	function harvest(
		address collection, 
		uint256[] memory amounts, 
		address[] memory tokenAddresses
	) external;
	
	function collateralize(
		address collection,
		uint256 tokenId,
		uint256[] memory amounts,
		address[] memory tokenAddresses
	) external payable;

	function uncollateralize(
		address collection,
		uint256 tokenId,
		uint256[] memory amounts,
		address[] memory tokenAddresses
	) external;

	function getDiscountedCollateral(
		address collection,
        uint256 bondId,
        address quoteToken,
        uint256 tokenId,
        uint256 amount,
        uint256 maxPrice
    ) external;

	function claimDiscountedCollateral(
		address collection, 
		uint256 tokenId, 
		uint256[] memory indexes
	) external;


	function disperse(
		address collection,
		uint256[] memory amounts,
		address[] memory tokenAddresses
	) external payable;
}

// SPDX-License-Identifier: MIT
// GhostContracts (last updated v0.3.0) (ERC721/interfaces/IERC721Envious.sol)

pragma solidity ^0.8.0;

import "../openzeppelin/token/ERC721/IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional Envious extension.
 * @author F4T50 @ghostown
 * @author 571nkY @ghostown
 * @author 5Tr3TcH @ghostown
 * @dev Ability to collateralize each NFT in collection.
 */
interface IERC721Envious is IERC721 {
	event Collateralized(uint256 indexed tokenId, uint256 amount, address tokenAddress);
	event Uncollateralized(uint256 indexed tokenId, uint256 amount, address tokenAddress);
	event Dispersed(address indexed tokenAddress, uint256 amount);
	event Harvested(address indexed tokenAddress, uint256 amount, uint256 scaledAmount);

	/**
	 * @dev An array with two elements. Each of them represents percentage from collateral
	 * to be taken as a commission. First element represents collateralization commission.
	 * Second element represents uncollateralization commission. There should be 3 
	 * decimal buffer for each of them, e.g. 1000 = 1%.
	 *
	 * @param index of value in array.
	 */
	function commissions(uint256 index) external view returns (uint256);

	/**
	 * @dev Address of token that will be paid on bonds.
	 *
	 * @return address address of token.
	 */
	function ghostAddress() external view returns (address);

	/**
	 * @dev Address of smart contract, that provides purchasing of DeFi 2.0 bonds.
	 *
	 * @return address address of bonding smart.
	 */
	function ghostBondingAddress() external view returns (address);

	/**
	 * @dev 'Black hole' is any address that guarantee tokens sent to it will not be 
	 * retrieved from there. Note: some tokens revert on transfer to zero address.
	 *
	 * @return address address of black hole.
	 */
	function blackHole() external view returns (address);

	/**
	 * @dev Token that will be used to harvest collected commissions.
	 *
	 * @return address address of token.
	 */
	function communityToken() external view returns (address);

	/**
	 * @dev Pool of available tokens for harvesting.
	 *
	 * @param index in array.
	 * @return address of token.
	 */
	function communityPool(uint256 index) external view returns (address);

	/**
	 * @dev Token balance available for harvesting.
	 *
	 * @param tokenAddress addres of token.
	 * @return uint256 token balance.
	 */
	function communityBalance(address tokenAddress) external view returns (uint256);

	/**
	 * @dev Array of tokens that were dispersed.
	 *
	 * @param index in array.
	 * @return address address of dispersed token.
	 */
	function disperseTokens(uint256 index) external view returns (address);

	/**
	 * @dev Amount of tokens that was dispersed.
	 *
	 * @param tokenAddress address of token.
	 * @return uint256 token balance.
	 */
	function disperseBalance(address tokenAddress) external view returns (uint256);

	/**
	 * @dev Amount of tokens that was already taken from the disperse.
	 *
	 * @param tokenAddress address of token.
	 * @return uint256 total amount of tokens already taken.
	 */
	function disperseTotalTaken(address tokenAddress) external view returns (uint256);

	/**
	 * @dev Amount of disperse already taken by each tokenId.
	 *
	 * @param tokenId unique identifier of unit.
	 * @param tokenAddress address of token.
	 * @return uint256 amount of tokens already taken.
	 */
	function disperseTaken(uint256 tokenId, address tokenAddress) external view returns (uint256);

	/**
	 * @dev Available payouts.
	 *
	 * @param bondId bond unique identifier.
	 * @return uint256 potential payout.
	 */
	function bondPayouts(uint256 bondId) external view returns (uint256);

	/**
	 * @dev Mapping of `tokenId`s to array of bonds.
	 *
	 * @param tokenId unique identifier of unit.
	 * @param index in array.
	 * @return uint256 index of bond.
	 */
	function bondIndexes(uint256 tokenId, uint256 index) external view returns (uint256);

	/**
	 * @dev Mapping of `tokenId`s to token addresses who have collateralized before.
	 *
	 * @param tokenId unique identifier of unit.
	 * @param index in array.
	 * @return address address of token.
	 */
	function collateralTokens(uint256 tokenId, uint256 index) external view returns (address);

	/**
	 * @dev Token balances that are stored under `tokenId`.
	 *
	 * @param tokenId unique identifier of unit.
	 * @param tokenAddress address of token.
	 * @return uint256 token balance.
	 */
	function collateralBalances(uint256 tokenId, address tokenAddress) external view returns (uint256);

	/**
     * @dev Calculator function for harvesting.
     *
     * @param amount of `communityToken`s to spend
     * @param tokenAddress of token to be harvested
     * @return amount to harvest based on inputs
     */
	function getAmount(uint256 amount, address tokenAddress) external view returns (uint256);

	/**
	 * @dev Collect commission fees gathered in exchange for `communityToken`.
	 *
	 * @param amounts array of amounts to collateralize
	 * @param tokenAddresses array of token addresses
	 */
	function harvest(uint256[] memory amounts, address[] memory tokenAddresses) external;

	/**
	 * @dev Collateralize NFT with different tokens and amounts.
	 *
	 * @param tokenId unique identifier for specific NFT
	 * @param amounts array of amounts to collateralize
	 * @param tokenAddresses array of token addresses
	 */
	function collateralize(
		uint256 tokenId,
		uint256[] memory amounts,
		address[] memory tokenAddresses
	) external payable;

	/**
	 * @dev Withdraw underlying collateral.
	 *
	 * Requirements:
	 * - only owner of NFT
	 *
	 * @param tokenId unique identifier for specific NFT
	 * @param amounts array of amounts to collateralize
	 * @param tokenAddresses array of token addresses
	 */
	function uncollateralize(
		uint256 tokenId, 
		uint256[] memory amounts, 
		address[] memory tokenAddresses
	) external;

	/**
     * @dev Collateralize NFT with discount, based on available bonds. While
     * purchased bond will have delay the owner will be current smart contract
     *
     * @param bondId the ID of the market
     * @param tokenId unique identifier of NFT inside current smart contract
     * @param amount the amount of quote token to spend
     * @param maxPrice the maximum price at which to buy bond
     */
	function getDiscountedCollateral(
        uint256 bondId,
        address quoteToken,
        uint256 tokenId,
        uint256 amount,
        uint256 maxPrice
    ) external;

	/**
     * @dev Claim collateral inside this smart contract and extending underlying
     * data mappings.
     *
     * @param tokenId unique identifier of NFT inside current smart contract
     * @param indexes array of note indexes to redeem
     */
	function claimDiscountedCollateral(uint256 tokenId, uint256[] memory indexes) external;

	/**
	 * @dev Split collateral among all existent tokens.
	 *
	 * @param amounts to be dispersed among all NFT owners
	 * @param tokenAddresses of token to be dispersed
	 */
	function disperse(uint256[] memory amounts, address[] memory tokenAddresses) external payable;

	/**
	 * @dev See {IERC721-_mint}
	 */
	function mint(address who) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "../openzeppelin/token/ERC20/IERC20.sol";

interface IBondDepository {
	event CreateMarket(
        uint256 indexed id,
        address indexed baseToken,
        address indexed quoteToken,
        uint256 initialPrice
    );

    event CloseMarket(uint256 indexed id);

    event Bond(
        uint256 indexed id,
        uint256 amount,
        uint256 price
    );

    event Tuned(
        uint256 indexed id,
        uint64 oldControlVariable,
        uint64 newControlVariable
    );
	
	// Info about each type of market
	struct Market {
		uint256 capacity;           // capacity remaining
		IERC20 quoteToken;          // token to accept as payment
		bool capacityInQuote;       // capacity limit is in payment token (true) or in STRL (false, default)
		uint64 totalDebt;           // total debt from market
		uint64 maxPayout;           // max tokens in/out (determined by capacityInQuote false/true)
		uint64 sold;                // base tokens out
		uint256 purchased;          // quote tokens in
	}
	
	// Info for creating new markets
	struct Terms {
		bool fixedTerm;             // fixed term or fixed expiration
		uint64 controlVariable;     // scaling variable for price
		uint48 vesting;             // length of time from deposit to maturity if fixed-term
		uint48 conclusion;          // timestamp when market no longer offered (doubles as time when market matures if fixed-expiry)
		uint64 maxDebt;             // 9 decimal debt maximum in STRL
	}
	
	// Additional info about market.
	struct Metadata {
		uint48 lastTune;            // last timestamp when control variable was tuned
		uint48 lastDecay;           // last timestamp when market was created and debt was decayed
		uint48 length;              // time from creation to conclusion. used as speed to decay debt.
		uint48 depositInterval;     // target frequency of deposits
		uint48 tuneInterval;        // frequency of tuning
		uint8 quoteDecimals;        // decimals of quote token
	}
	
	// Control variable adjustment data
	struct Adjustment {
		uint64 change;              // adjustment for price scaling variable 
		uint48 lastAdjustment;      // time of last adjustment
		uint48 timeToAdjusted;      // time after which adjustment should happen
		bool active;                // if adjustment is available
	}
	
	function deposit(
		uint256 _bid,               // the ID of the market
		uint256 _amount,            // the amount of quote token to spend
		uint256 _maxPrice,          // the maximum price at which to buy
		address _user,              // the recipient of the payout
		address _referral           // the operator address
	) external returns (uint256 payout_, uint256 expiry_, uint256 index_);
	
	function create (
		IERC20 _quoteToken,         // token used to deposit
		uint256[3] memory _market,  // [capacity, initial price]
		bool[2] memory _booleans,   // [capacity in quote, fixed term]
		uint256[2] memory _terms,   // [vesting, conclusion]
		uint32[2] memory _intervals // [deposit interval, tune interval]
	) external returns (uint256 id_);
	
	function close(uint256 _id) external;
	function isLive(uint256 _bid) external view returns (bool);
	function liveMarkets() external view returns (uint256[] memory);
	function liveMarketsFor(address _quoteToken) external view returns (uint256[] memory);
	function payoutFor(uint256 _amount, uint256 _bid) external view returns (uint256);
	function marketPrice(uint256 _bid) external view returns (uint256);
	function currentDebt(uint256 _bid) external view returns (uint256);
	function debtRatio(uint256 _bid) external view returns (uint256);
	function debtDecay(uint256 _bid) external view returns (uint64);
}
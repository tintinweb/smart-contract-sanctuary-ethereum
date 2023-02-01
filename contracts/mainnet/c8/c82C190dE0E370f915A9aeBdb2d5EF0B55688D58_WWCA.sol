/**
 *Submitted for verification at Etherscan.io on 2023-02-01
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: contracts/WWCA.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


contract WWCA is Ownable {
	IWCANFTRanking public WCANFTRanking;
	IWCADAOLocking public WCADAOLocking;
	IWCADAOSignUp public WCADAOSignUp;

	string public constant version = "0.1";

	struct Range {
		uint256 from;
		uint256 to;
		uint256 wwca;
	}

	struct UserAddressToWWCA {
		address userAddress;
		WWCAAmount wwca;
	}

	struct Bonus {
		uint256 id;
		uint256 amount;
		uint256 fromTimestamp;
		uint256 toTimestamp;
	}

	struct WWCAAmount {
		// uint256 wwca; // wwcaToken + wwcaNFT + wwcaBonus
		// uint256 wwcaX4; // (wwcaToken * 4) + wwcaNFT + wwcaBonus
		uint256 wwcaToken;
		uint256 wwcaNFT;
		uint256 wwcaBonus;
	}

	// Add admins
	mapping(address => bool) public admins;
	// Add NFT constraints to get WWCA
	// Set WWCA amounts to value*10**18
	// [Range(1, 9, 22000), Range(10, 99, 11000), Range(100, 499, 9500), Range(500, 999, 8500), Range(1000, 1999, 8000), Range(2000, 2999, 7550), Range(3000, 3999, 7050), Range(4000, 5000, 6550)];
	Range[] public WCAConstraints;

	uint256[] public MUNLegendIds = [1145, 1879, 2401, 2805, 2993];
	uint256 public MUNLegendWWCA = 21000 * (10**18);
	// [Range(6, 9, 10000), Range(10, 99, 9070), Range(100, 499, 8540), Range(500, 995, 8030), Range(1000, 1999, 7520), Range(2000, 3000, 7020)];
	Range[] public MUNConstraints;

	uint256[] public VIPLegendIds = [3, 4, 7, 8, 9, 10, 11, 12, 15, 13, 14, 18, 19, 16, 17];
	uint256 public VIPLegendWWCA = 20000 * (10**18);
	uint256[] public VIPProfessionistIds = [1, 2, 5, 6];
	uint256 public VIPProfessionistWWCA = 10000 * (10**18);
	uint256[] public VIPJuniorIds;
	uint256 public VIPJuniorWWCA = 2000 * (10**18);

	mapping(address => WWCAAmount) public userAddressToWWCA;
	mapping(address => Bonus[]) public userAddressToBonuses;
	address[] public userAddresses;

	modifier onlyOwnerOrAdmin() {
		require(msg.sender == owner() || admins[msg.sender], "Unauthorized");
		_;
	}

	constructor(){}

	function setContracts(
		address _WCADAOLocking,
		address _WCANFTRanking,
		address _WCADAOSignUp
	) external onlyOwner {
		WCADAOLocking = IWCADAOLocking(_WCADAOLocking);
		WCANFTRanking = IWCANFTRanking(_WCANFTRanking);
		WCADAOSignUp = IWCADAOSignUp(_WCADAOSignUp);
	}

	function addAdmin(address _admin) external onlyOwner {
		admins[_admin] = true;
	}

	function removeAdmin(address _admin) external onlyOwner {
		admins[_admin] = false;
	}

	function setWCAConstraints(Range[] calldata _WCAConstraints) external onlyOwner {
		for (uint256 i; i < _WCAConstraints.length; i++) {
			WCAConstraints.push(_WCAConstraints[i]);
		}
	}

	function setMUNConstraints(uint256 _MUNLegendWWCA, Range[] memory _MUNConstraints) external onlyOwner {
		MUNLegendWWCA = _MUNLegendWWCA;
		for (uint256 i; i < _MUNConstraints.length; i++) {
			MUNConstraints.push(_MUNConstraints[i]);
		}
	}

	function setVIPConstraints(
		uint256[] memory _VIPLegendIds,
		uint256 _VIPLegendWWCA,
		uint256[] memory _VIPProfessionistIds,
		uint256 _VIPProfessionistWWCA,
		uint256[] memory _VIPJuniorIds,
		uint256 _VIPJuniorWWCA
	) external onlyOwner {
		VIPLegendWWCA = _VIPLegendWWCA;
		for (uint256 i; i < _VIPLegendIds.length; i++) {
			VIPLegendIds.push(_VIPLegendIds[i]);
		}
		VIPProfessionistWWCA = _VIPProfessionistWWCA;
		for (uint256 i; i < _VIPProfessionistIds.length; i++) {
			VIPProfessionistIds.push(_VIPProfessionistIds[i]);
		}
		VIPJuniorWWCA = _VIPJuniorWWCA;
		for (uint256 i; i < _VIPJuniorIds.length; i++) {
			VIPJuniorIds.push(_VIPJuniorIds[i]);
		}
	}

	function addBonus(address _address, uint256 amount) external onlyOwnerOrAdmin {
		userAddressToWWCA[_address].wwcaBonus += amount;
		userAddressToBonuses[_address].push(Bonus(userAddressToBonuses[_address].length, amount, block.timestamp, 0));
		removeAddressFromArray(userAddresses, _address);
		if (balanceOfAddress(_address) != 0) {
			userAddresses.push(_address);
		}
	}

	function addExpiringBonus(
		address _address,
		uint256 amount,
		uint256 expiration
	) external onlyOwnerOrAdmin {
		userAddressToWWCA[_address].wwcaBonus += amount;
		userAddressToBonuses[_address].push(Bonus(userAddressToBonuses[_address].length, amount, block.timestamp, expiration));
		removeAddressFromArray(userAddresses, _address);
		if (balanceOfAddress(_address) != 0) {
			userAddresses.push(_address);
		}
	}

	function removeBonus(address _address, uint256 id) external onlyOwnerOrAdmin {
		for (uint256 i; i < userAddressToBonuses[_address].length; i++) {
			if (userAddressToBonuses[_address][i].id == id) {
				userAddressToBonuses[_address][i].toTimestamp = block.timestamp;
				userAddressToWWCA[_address].wwcaBonus -= userAddressToBonuses[_address][i].amount;
				break;
			}
		}
		removeAddressFromArray(userAddresses, _address);
		if (userAddressToWWCA[_address].wwcaToken + userAddressToWWCA[_address].wwcaNFT + userAddressToWWCA[_address].wwcaBonus != 0) {
			userAddresses.push(_address);
		}
	}

	function getBonuses(address _address) external view returns (Bonus[] memory) {
		return userAddressToBonuses[_address];
	}

	function totalWWCA() public view returns (uint256 wwca) {
		for (uint256 i; i < userAddresses.length; i++) {
			wwca += balanceOfAddress(userAddresses[i]);
		}
	}

	function totalWWCAX4() public view returns (uint256 wwca) {
		for (uint256 i; i < userAddresses.length; i++) {
			wwca += balanceOfAddressX4(userAddresses[i]);
		}
	}

	function usersAddressesWWCA() public view returns (UserAddressToWWCA[] memory results) {
		results = new UserAddressToWWCA[](userAddresses.length);
		for (uint256 i; i < userAddresses.length; i++) {
			results[i] = UserAddressToWWCA(userAddresses[i], userAddressToWWCA[userAddresses[i]]);
		}
	}

	function balanceOfUsername(string calldata username) public view returns (uint256 result) {
		IWCADAOSignUp.User memory user = WCADAOSignUp.getUser(username);
		for (uint256 i; i < user.addresses.length; i++) {
			result += balanceOfAddress(user.addresses[i]);
		}
	}

	function balanceOfUsernameX4(string calldata username) public view returns (uint256 result) {
		IWCADAOSignUp.User memory user = WCADAOSignUp.getUser(username);
		for (uint256 i; i < user.addresses.length; i++) {
			result += balanceOfAddressX4(user.addresses[i]);
		}
	}

	function balanceOfAddress(address _address) public view returns (uint256) {
		return userAddressToWWCA[_address].wwcaToken + userAddressToWWCA[_address].wwcaNFT + userAddressToWWCA[_address].wwcaBonus;
	}

	function balanceOfAddressX4(address _address) public view returns (uint256) {
		return (userAddressToWWCA[_address].wwcaToken * 4) + userAddressToWWCA[_address].wwcaNFT + userAddressToWWCA[_address].wwcaBonus;
	}

	function WWCAOfAddress(address _address) public view returns (WWCAAmount memory) {
		return userAddressToWWCA[_address];
	}

	function updateWWCAByUsername(string calldata username) external {
		IWCADAOSignUp.User memory user = WCADAOSignUp.getUser(username);
		for (uint256 i; i < user.addresses.length; i++) {
			updateWWCAByAddress(user.addresses[i]);
		}
	}

	function updateWWCAByAddress(address _address) public {
		userAddressToWWCA[_address] = calcWWCAByAddress(_address);
		removeAddressFromArray(userAddresses, _address);
		if (balanceOfAddress(_address) != 0) {
			userAddresses.push(_address);
		}
	}

	function calcWWCAByUsername(string memory username) public view returns (WWCAAmount[] memory wwcaAmount) {
		IWCADAOSignUp.User memory user = WCADAOSignUp.getUser(username);
		wwcaAmount = new WWCAAmount[](user.addresses.length);
		for (uint256 i; i < user.addresses.length; i++) {
			wwcaAmount[i] = calcWWCAByAddress(user.addresses[i]);
		}
	}

	function calcWWCAByAddress(address _address) public view returns (WWCAAmount memory wwcaAmount) {
		// TOKENS
		IWCADAOLocking.Tokens[] memory tokens = WCADAOLocking.getLockedTokens(_address);
		for (uint256 i; i < tokens.length; i++) {
			if (tokens[i].unstakedTimestamp == 0) {
				wwcaAmount.wwcaToken += tokens[i].amount;
			}
		}

		// NFTs
		IWCADAOLocking.NFT[] memory nfts = WCADAOLocking.getLockedNFTs(_address);
		for (uint256 i; i < nfts.length; i++) {
			if (nfts[i].unstakedTimestamp == 0) {
				wwcaAmount.wwcaNFT += calcWWCAPerNFT(nfts[i]);
			}
		}

		// BONUSES
		Bonus[] memory bonuses = userAddressToBonuses[_address];
		for (uint256 i; i < bonuses.length; i++) {
			if (bonuses[i].toTimestamp == 0 || bonuses[i].toTimestamp >= block.timestamp) {
				wwcaAmount.wwcaBonus += bonuses[i].amount;
			}
		}
	}

	function calcWWCAPerNFT(IWCADAOLocking.NFT memory nft) public view returns (uint256) {
		uint256 rank = WCANFTRanking.getRank(IWCANFTRanking.Collection(uint256(nft.collection)), nft.id);
		if (nft.collection == IWCADAOLocking.Collection.WCA) {
			return getRange(WCAConstraints, rank).wwca;
		} else if (nft.collection == IWCADAOLocking.Collection.MUNDIAL) {
			if (isInList(MUNLegendIds, nft.id)) {
				return MUNLegendWWCA;
			} else {
				return getRange(MUNConstraints, rank).wwca;
			}
		} else if (nft.collection == IWCADAOLocking.Collection.VIP) {
			if (isInList(VIPLegendIds, nft.id)) {
				return VIPLegendWWCA;
			} else if (isInList(VIPProfessionistIds, nft.id)) {
				return VIPProfessionistWWCA;
			} else if (isInList(VIPJuniorIds, nft.id)) {
				return VIPJuniorWWCA;
			}
		}
		return 0;
	}

	function calcAverageWWCAByUsername(
		string calldata username,
		uint256 fromTimestamp,
		uint256 toTimestamp
	) external view returns (uint256) {
		IWCADAOSignUp.User memory user = WCADAOSignUp.getUser(username);
		uint256 wwca = 0;
		for (uint256 i; i < user.addresses.length; i++) {
			wwca += calcAverageWWCAByAddress(user.addresses[i], fromTimestamp, toTimestamp);
		}
		return wwca;
	}

	function calcAverageWWCAByAddress(
		address _address,
		uint256 fromTimestamp,
		uint256 toTimestamp
	) public view returns (uint256) {
		require(fromTimestamp < toTimestamp, "fromTimestamp must be before toTimestamp");
		uint256 wwca = 0;

		// TOKENS
		IWCADAOLocking.Tokens[] memory tokens = WCADAOLocking.getLockedTokens(_address);

		for (uint256 i = 0; i < tokens.length; i++) {
			uint256 startDate = tokens[i].stakedTimestamp >= fromTimestamp ? tokens[i].stakedTimestamp : fromTimestamp;
			uint256 endDate = tokens[i].unstakedTimestamp == 0 || tokens[i].unstakedTimestamp > toTimestamp ? toTimestamp : tokens[i].unstakedTimestamp;
			if (endDate <= startDate) {
				continue;
			}
			uint256 durationInDays = (endDate - startDate) / 1 days;

			if (durationInDays >= 365) {
				wwca += (tokens[i].amount * durationInDays) * 4;
			} else {
				wwca += tokens[i].amount * durationInDays;
			}
		}

		// NFTs
		IWCADAOLocking.NFT[] memory nfts = WCADAOLocking.getLockedNFTs(_address);

		for (uint256 i = 0; i < nfts.length; i++) {
			uint256 startDate = nfts[i].stakedTimestamp >= fromTimestamp ? nfts[i].stakedTimestamp : fromTimestamp;
			uint256 endDate = nfts[i].unstakedTimestamp == 0 || nfts[i].unstakedTimestamp > toTimestamp ? toTimestamp : nfts[i].unstakedTimestamp;
			if (endDate <= startDate) {
				continue;
			}
			uint256 durationInDays = (endDate - startDate) / 1 days;

			wwca += calcWWCAPerNFT(nfts[i]) * durationInDays;
		}

		// BONUS
		for (uint256 i = 0; i < userAddressToBonuses[_address].length; i++) {
			uint256 startDate = userAddressToBonuses[_address][i].fromTimestamp >= fromTimestamp ? userAddressToBonuses[_address][i].fromTimestamp : fromTimestamp;
			uint256 endDate = userAddressToBonuses[_address][i].toTimestamp == 0 || userAddressToBonuses[_address][i].toTimestamp > toTimestamp ? toTimestamp : userAddressToBonuses[_address][i].toTimestamp;
			if (endDate <= startDate) {
				continue;
			}
			uint256 durationInDays = (endDate - startDate) / 1 days;

			wwca += (userAddressToBonuses[_address][i].amount * durationInDays);
		}

		return wwca / ((toTimestamp - fromTimestamp) / 1 days);
	}

	function isInList(uint256[] storage list, uint256 id) internal view returns (bool) {
		for (uint256 i; i < list.length; i++) {
			if (id == list[i]) {
				return true;
			}
		}
		return false;
	}

	function getRange(Range[] storage ranges, uint256 rank) internal view returns (Range memory) {
		for (uint256 i; i < ranges.length; i++) {
			if (rank >= ranges[i].from && rank <= ranges[i].to) {
				return ranges[i];
			}
		}
		return Range(0, 0, 0);
	}

	function removeAddressFromArray(address[] storage array, address _address) internal {
		for (uint256 i = 0; i < array.length; i++) {
			if (array[i] == _address) {
				if (i < array.length - 1) {
					array[i] = array[array.length - 1];
				}
				array.pop();
				break;
			}
		}
	}
}

interface IWCADAOSignUp {
	struct User {
		string username;
		address[] addresses;
	}

	function getUser(string memory username) external view returns (User memory user);

	function getUserFromAddress(address wallet) external view returns (User memory user);

	function getUsers() external view returns (User[] memory);

	function getUsersCount() external view returns (uint256);
}

interface IWCADAOLocking {
	enum Collection {
		WCA,
		MUNDIAL,
		VIP
	}

	struct NFT {
		Collection collection;
		uint256 id;
		uint256 stakedTimestamp;
		uint256 unstakedTimestamp;
	}

	struct Tokens {
		uint256 amount;
		uint256 stakedTimestamp;
		uint256 unstakedTimestamp;
	}

	function getLockedNFTs(address _address) external view returns (NFT[] memory);

	function getLockedTokens(address _address) external view returns (Tokens[] memory);
}

interface IWCANFTRanking {
	enum Collection {
		WCA,
		MUNDIAL,
		VIP
	}

	function getRank(Collection collection, uint256 id) external view returns (uint256);
}
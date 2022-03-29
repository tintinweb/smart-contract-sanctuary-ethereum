// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC20Spec.sol";
import "./ERC721Spec.sol";
import "./AccessControl.sol";

/**
 * @title NFT Staking
 *
 * @notice Enables NFT staking for a given NFT smart contract defined on deployment
 *
 * @notice Doesn't introduce any rewards, just tracks the stake/unstake dates for each
 *      token/owner, this data will be used later on to process the rewards
 */
contract NFTStaking is AccessControl {
	/**
	 * @dev Main staking data structure keeping track of a stake,
	 *      used in `tokenStakes` array mapping
	 */
	struct StakeData {
		/**
		 * @dev Who owned and staked the token, who will be the token
		 *      returned to once unstaked
		 */
		address owner;

		/**
		 * @dev When the token was staked and transferred from the owner,
		 *      unix timestamp
		 */
		uint32 stakedOn;

		/**
		 * @dev When token was unstaked and returned back to the owner,
		 *      unix timestamp
		 * @dev Zero value means the token is still staked
		 */
		uint32 unstakedOn;
	}

	/**
	 * @dev Auxiliary data structure to help iterate over NFT owner stakes,
	 *      used in `userStakes` array mapping
	 */
	struct StakeIndex {
		/**
		 * @dev Staked token ID
		 */
		uint32 tokenId;

		/**
		 * @dev Where to look for main staking data `StakeData`
		 *      in `tokenStakes` array mapping
		 */
		uint32 index;
	}

	/**
	 * @dev NFT smart contract to stake/unstake tokens of
	 */
	address public immutable targetContract;

	/**
	 * @notice For each token ID stores the history of its stakes,
	 *      last element of the history may be "open" (unstakedOn = 0),
	 *      meaning the token is still staked and is ot be returned to the `owner`
	 *
	 * @dev Maps token ID => StakeData[]
	 */
	mapping(uint32 => StakeData[]) public tokenStakes;

	/**
	 * @notice For each owner address stores the links to its stakes,
	 *      the link is represented as StakeIndex data struct
	 *
	 * @dev Maps owner address => StakeIndex[]
	 */
	mapping(address => StakeIndex[]) public userStakes;

	/**
	 * @dev Enables staking, stake(), stakeBatch()
	 */
	uint32 public constant FEATURE_STAKING = 0x0000_0001;

	/**
	 * @dev Enables unstaking, unstake(), unstakeBatch()
	 */
	uint32 public constant FEATURE_UNSTAKING = 0x0000_0002;

	/**
	 * @notice People do mistake and may send tokens by mistake; since
	 *      staking contract is not designed to accept the tokens directly,
	 *      it allows the rescue manager to "rescue" such lost tokens
	 *
	 * @notice Rescue manager is responsible for "rescuing" ERC20/ERC721 tokens
	 *      accidentally sent to the smart contract
	 *
	 * @dev Role ROLE_RESCUE_MANAGER allows withdrawing non-staked ERC20/ERC721
	 *      tokens stored on the smart contract balance
	 */
	uint32 public constant ROLE_RESCUE_MANAGER = 0x0001_0000;

	/**
	 * @dev Fired in stake(), stakeBatch()
	 *
	 * @param _by token owner, tx executor
	 * @param _tokenId token ID staked and transferred into the smart contract
	 * @param _when unix timestamp of when staking happened
	 */
	event Staked(address indexed _by, uint32 indexed _tokenId, uint32 _when);

	/**
	 * @dev Fired in unstake(), unstakeBatch()
	 *
	 * @param _by token owner, tx executor
	 * @param _tokenId token ID unstaked and transferred back to owner
	 * @param _when unix timestamp of when unstaking happened
	 */
	event Unstaked(address indexed _by, uint32 indexed _tokenId, uint32 _when);

	/**
	 * @dev Creates/deploys NFT staking contract bound to the already deployed
	 *      target NFT ERC721 smart contract to be staked
	 *
	 * @param _nft address of the deployed NFT smart contract instance
	 */
	constructor(address _nft) {
		// verify input is set
		require(_nft != address(0), "target contract is not set");

		// verify input is valid smart contract of the expected interface
		require(ERC165(_nft).supportsInterface(type(ERC721).interfaceId), "unexpected target type");

		// setup smart contract internal state
		targetContract = _nft;
	}

	/**
	 * @notice How many times a particular token was staked
	 *
	 * @dev Used to iterate `tokenStakes(tokenId, i)`, `i < numStakes(tokenId)`
	 *
	 * @param tokenId token ID to query number of times staked for
	 * @return number of times token was staked
	 */
	function numStakes(uint32 tokenId) public view returns(uint256) {
		// just read the array length and return it
		return tokenStakes[tokenId].length;
	}

	/**
	 * @notice How many stakes a particular address has done
	 *
	 * @dev Used to iterate `userStakes(owner, i)`, `i < numStakes(owner)`
	 *
	 * @param owner an address to query number of times it staked
	 * @return number of times a particular address has staked
	 */
	function numStakes(address owner) public view returns(uint256) {
		// just read the array length and return it
		return userStakes[owner].length;
	}

	/**
	 * @notice Determines if the token is currently staked or not
	 *
	 * @param tokenId token ID to check state for
	 * @return true if token is staked, false otherwise
	 */
	function isStaked(uint32 tokenId) public view returns(bool) {
		// get an idea of current stakes for the token
		uint256 n = tokenStakes[tokenId].length;

		// evaluate based on the last stake element in the array
		return n > 0 && tokenStakes[tokenId][n - 1].unstakedOn == 0;
	}

	/**
	 * @notice Stakes the NFT; the token is transferred from its owner to the staking contract;
	 *      token must be owned by the tx executor and be transferable by staking contract
	 *
	 * @param tokenId token ID to stake
	 */
	function stake(uint32 tokenId) public {
		// verify staking is enabled
		require(isFeatureEnabled(FEATURE_STAKING), "staking is disabled");

		// get an idea of current stakes for the token
		uint256 n = tokenStakes[tokenId].length;

		// verify the token is not currently staked
		require(n == 0 || tokenStakes[tokenId][n - 1].unstakedOn != 0, "already staked");

		// verify token belongs to the address which executes staking
		require(ERC721(targetContract).ownerOf(tokenId) == msg.sender, "access denied");

		// transfer the token from owner into the staking contract
		ERC721(targetContract).transferFrom(msg.sender, address(this), tokenId);

		// current timestamp to be set as `stakedOn`
		uint32 stakedOn = now32();

		// save token stake data
		tokenStakes[tokenId].push(StakeData({
			owner: msg.sender,
			stakedOn: stakedOn,
			unstakedOn: 0
		}));

		// save token stake index
		userStakes[msg.sender].push(StakeIndex({
			tokenId: tokenId,
			index: uint32(n)
		}));

		// emit an event
		emit Staked(msg.sender, tokenId, stakedOn);
	}

	/**
	 * @notice Stakes several NFTs; tokens are transferred from their owner to the staking contract;
	 *      tokens must be owned by the tx executor and be transferable by staking contract
	 *
	 * @param tokenIds token IDs to stake
	 */
	function stakeBatch(uint32[] memory tokenIds) public {
		// iterate the collection passed
		for(uint256 i = 0; i < tokenIds.length; i++) {
			// and stake each token one by one
			stake(tokenIds[i]);
		}
	}

	/**
	 * @notice Unstakes the NFT; the token is transferred from staking contract back
	 *      its previous owner
	 *
	 * @param tokenId token ID to unstake
	 */
	function unstake(uint32 tokenId) public {
		// verify staking is enabled
		require(isFeatureEnabled(FEATURE_UNSTAKING), "unstaking is disabled");

		// get an idea of current stakes for the token
		uint256 n = tokenStakes[tokenId].length;

		// verify the token is not currently staked
		require(n != 0, "not staked");
		require(tokenStakes[tokenId][n - 1].unstakedOn == 0, "already unstaked");

		// verify token belongs to the address which executes unstaking
		require(tokenStakes[tokenId][n - 1].owner == msg.sender, "access denied");

		// current timestamp to be set as `unstakedOn`
		uint32 unstakedOn = now32();

		// update token stake data
		tokenStakes[tokenId][n - 1].unstakedOn = unstakedOn;

		// transfer the token back to owner
		ERC721(targetContract).transferFrom(address(this), msg.sender, tokenId);

		// emit an event
		emit Unstaked(msg.sender, tokenId, unstakedOn);
	}

	/**
	 * @notice Unstakes several NFTs; tokens are transferred from staking contract back
	 *      their previous owner
	 *
	 * @param tokenIds token IDs to unstake
	 */
	function unstakeBatch(uint32[] memory tokenIds) public {
		// iterate the collection passed
		for(uint256 i = 0; i < tokenIds.length; i++) {
			// and unstake each token one by one
			unstake(tokenIds[i]);
		}
	}

	/**
	 * @dev Restricted access function to rescue accidentally sent ERC20 tokens,
	 *      the tokens are rescued via `transfer` function call on the
	 *      contract address specified and with the parameters specified:
	 *      `_contract.transfer(_to, _value)`
	 *
	 * @dev Requires executor to have `ROLE_RESCUE_MANAGER` permission
	 *
	 * @param _contract smart contract address to execute `transfer` function on
	 * @param _to to address in `transfer(_to, _value)`
	 * @param _value value to transfer in `transfer(_to, _value)`
	 */
	function rescueErc20(address _contract, address _to, uint256 _value) public {
		// verify the access permission
		require(isSenderInRole(ROLE_RESCUE_MANAGER), "access denied");

		// perform the transfer as requested, without any checks
		ERC20(_contract).transfer(_to, _value);
	}

	/**
	 * @dev Restricted access function to rescue accidentally sent ERC721 tokens,
	 *      the tokens are rescued via `transferFrom` function call on the
	 *      contract address specified and with the parameters specified:
	 *      `_contract.transferFrom(this, _to, _tokenId)`
	 *
	 * @dev Requires executor to have `ROLE_RESCUE_MANAGER` permission
	 *
	 * @param _contract smart contract address to execute `transferFrom` function on
	 * @param _to to address in `transferFrom(this, _to, _tokenId)`
	 * @param _tokenId token ID to transfer in `transferFrom(this, _to, _tokenId)`
	 */
	function rescueErc721(address _contract, address _to, uint256 _tokenId) public {
		// verify the access permission
		require(isSenderInRole(ROLE_RESCUE_MANAGER), "access denied");

		// verify the NFT is not staked
		require(_contract != targetContract || !isStaked(uint32(_tokenId)), "token is staked");

		// perform the transfer as requested, without any checks
		ERC721(_contract).transferFrom(address(this), _to, _tokenId);
	}

	/**
	 * @dev Testing time-dependent functionality may be difficult;
	 *      we override time in the helper test smart contract (mock)
	 *
	 * @return `block.timestamp` in mainnet, custom values in testnets (if overridden)
	 */
	function now32() public view virtual returns (uint32) {
		// return current block timestamp
		return uint32(block.timestamp);
	}
}
pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

import "IZooFunctions.sol";
import "NftBattleStaker.sol";
import "Ownable.sol";
import "VRFConsumerBase.sol";

/// @title Contract BaseZooFunctions.
/// @notice Contracts for base implementation of some ZooDao functions.
contract BaseZooFunctions is Ownable, VRFConsumerBase
{
	NftBattleStaker public battles;

	constructor (address _vrfCoordinator, address _link) VRFConsumerBase(_vrfCoordinator, _link) 
	{
		chainLinkFee = 0.1 * 10 ** 18;
		keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
	}

	uint256 internal chainLinkFee;
	bytes32 internal keyHash;

	uint256 public randomResult;  // Random number for battles.

	uint256 public firstStageDuration = 20 minutes;// hours;        //todo:change time //3 days;    // Duration of first stage(stake).
	uint256 public secondStageDuration = 20 minutes;// hours;       //todo:change time //7 days;    // Duration of second stage(DAI).
	uint256 public thirdStageDuration = 20 minutes;// hours;        //todo:change time //2 days;    // Duration of third stage(Pair).
	uint256 public fourthStageDuration = 20 minutes;// hours;       //todo:change time //5 days;    // Duration fourth stage(ZOO).
	uint256 public fifthStageDuration = 20 minutes;// hours;        //todo:change time //2 days;    // Duration of fifth stage(Winner).

	/// @notice Function for setting address of NftBattleStaker contract.
	/// @param _nftBattleStaker - address of NftBattleStaker contract.
	function init(address _nftBattleStaker) external onlyOwner {
		battles = NftBattleStaker(_nftBattleStaker);

		transferOwnership(_nftBattleStaker); // battles needs ownership for now.
	}

	/// @notice Function to reset random number from battles.
	function resetRandom() external onlyOwner
	{
		randomResult = 0;
	}

	function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override 
	{
		randomResult = randomness;                      // Random number from chainlink.
	}

	/// @notice Function to request random from chainlink or blockhash.
	function getRandomNumber() external onlyOwner {
		// require(LINK.balanceOf(address(this)) >= chainLinkFee, "Not enough LINK");
		if (LINK.balanceOf(address(this)) < chainLinkFee)
		{
			randomResult = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1)))); // + battles.currentEpoch();
		}
		else
		{
			requestRandomness(keyHash, chainLinkFee);
		}
	}

	/// @notice Function for choosing winner in battle.
	/// @param votesForA - amount of votes for 1st candidate.
	/// @param votesForB - amount of votes for 2nd candidate.
	/// @param random - generated random number.
	/// @return bool - returns true if 1st candidate wins.
	function decideWins(uint256 votesForA, uint256 votesForB, uint256 random) external pure returns (bool)
	{
		uint256 mod = random % (votesForA + votesForB);
		return mod < votesForA;
	}

	/// @notice Function for calculating voting with Dai in vote battles.
	/// @param amount - amount of dai used for vote.
	/// @return votes - final amount of votes after calculating.
	function computeVotesByDai(uint256 amount) external view returns (uint256 votes)
	{
		if (block.timestamp < battles.epochStartDate() + battles.firstStageDuration() + battles.secondStageDuration() / 3)
		{
			votes = amount * 13 / 10;                                          // 1.3 multiplier for votes.
		}
		else if (block.timestamp < battles.epochStartDate() + battles.firstStageDuration() + ((battles.secondStageDuration() * 2) / 3))
		{
			votes = amount;                                                          // 1.0 multiplier for votes.
		}
		else
		{
			votes = amount * 7 / 10;                                           // 0.7 multiplier for votes.
		}
	}

	/// @notice Function for calculating voting with Zoo in vote battles.
	/// @param amount - amount of Zoo used for vote.
	/// @return votes - final amount of votes after calculating.
	function computeVotesByZoo(uint256 amount) external view returns (uint256 votes)
	{
		if (block.timestamp < battles.epochStartDate() + battles.firstStageDuration() + battles.secondStageDuration() + battles.thirdStageDuration() + (battles.fourthStageDuration() / 3))
		{
			votes = amount * 13 / 10;                                         // 1.3 multiplier for votes.
		}
		else if (block.timestamp < battles.epochStartDate() + battles.firstStageDuration() + battles.secondStageDuration() + battles.thirdStageDuration() + (battles.fourthStageDuration() * 2) / 3)
		{
			votes = amount;                                                         // 1.0 multiplier for votes.
		}
		else
		{
			votes = amount * 7 / 10;                                          // 0.7 multiplier for votes.
		}
	}

	function setStageDuration(uint256 stage, uint256 duration) external onlyOwner {
		// require(duration >= 2 days && 10 days >= duration, "incorrect duration"); // turned off for testnet.

		if (stage == 1) {
			firstStageDuration = duration;
		}
		else if (stage == 2)
		{
			secondStageDuration = duration;
		}
		else if (stage == 3)
		{
			thirdStageDuration = duration;
		}
		else if (stage == 4)
		{
			fourthStageDuration = duration;
		}
		else if (stage == 5)
		{
			fifthStageDuration = duration;
		}
	}
}

pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

/// @title interface of Zoo functions contract.
interface IZooFunctions {

	/// @notice returns random number.
	function randomResult() external view returns(uint256 random);

	/// @notice sets random number in battles back to zero.
	function resetRandom() external;

	/// @notice Function for choosing winner in battle.
	function decideWins(uint256 votesForA, uint256 votesForB, uint256 random) external view returns (bool);

	/// @notice Function for generating random number.
	function getRandomNumber() external;

	/// @notice Function for calculating voting with Dai in vote battles.
	function computeVotesByDai(uint256 amount) external view returns (uint256);

	/// @notice Function for calculating voting with Zoo in vote battles.
	function computeVotesByZoo(uint256 amount) external view returns (uint256);

	function firstStageDuration() external view returns (uint256);

	function secondStageDuration() external view returns (uint256);

	function thirdStageDuration() external view returns (uint256);

	function fourthStageDuration() external view returns (uint256);

	function fifthStageDuration() external view returns (uint256);
}

pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

import "IVault.sol";
import "IZooFunctions.sol";
import "ZooGovernance.sol";
import "INftBattleStaker.sol";
import "Ownable.sol";
import "ERC20Burnable.sol";
import "IERC721.sol";
import "ERC721.sol";
import "Math.sol";

contract NftBattleStaker is Ownable, ERC721
{
	using Math for uint256;
	using Math for int256;

	ERC20 public zoo;                                        // Zoo token interface.
	ERC20 public dai;                                                // DAI token interface
	VaultAPI public vault;                                           // Yearn interface.
	ZooGovernance public zooGovernance;                              // zooGovernance contract.
	IZooFunctions public zooFunctions;                               // zooFunctions contract.

	/// @notice Struct for stages of vote battle.
	enum Stage
	{
		FirstStage,
		SecondStage,
		ThirdStage,
		FourthStage,
		FifthStage
	}

	/// @notice Struct with info about rewardsForEpochFromStaker.
	struct BattleRewardForEpochFromStaker
	{
		int256 yTokensSaldo;                                         // Saldo from deposit in yearn in yTokens.
		uint256 votes;                                               // Total amount of votes for nft in this battle in this epoch.
		uint256 yTokens;                                             // Amount of yTokens.
		uint256 tokensAtBattleStart;                                 // Amount of yTokens at start.
		uint256 pricePerShareAtBattleStart;
		uint256 pricePerShareCoef;                                   // pps1*pps2/pps2-pps1
	}

	/// @notice Struct with info about staker positions.
	struct StakerPositionStruct
	{
		address token;                                               // Token address.
		uint256 id;                                                  // Token id.
		uint256 startDate;
		uint256 startEpoch;                                          // Epoch when started to stake.
		uint256 endDate;
		uint256 endEpoch;                                            // Epoch when ended to stake.
		uint256 lastRewardedEpoch;                                   // Epoch when last reward claimed.
		uint256 lastUpdateEpoch;
	}

	/// @notice Struct for records about pairs of Nfts for battle.
	struct NftPair
	{
		uint256 token1;                                              // Id of staker position of 1st candidate.
		uint256 token2;                                              // Id of staker position of 2nd candidate.
		bool playedInEpoch;                                          // Returns true if winner chosen.
		bool win;                                                    // Boolean where true is when 1st candidate wins, and false for 2nd.
	}

	/// @notice Event records address of allowed nft contract.
	event newContractAllowed (address indexed token, uint256 indexed currentEpoch);

	/// @notice Event records info about staked nft in this pool.
	event StakedNft(address indexed staker, address token, uint256 id, uint256 indexed positionId, uint256 indexed currentEpoch);

	/// @notice Event records info about withdrawed nft from this pool.
	event UnstakedNft(address indexed staker, address token, uint256 id, uint256 indexed positionId, uint256 indexed currentEpoch);

	/// @notice Event records info about paired nfts.
	event NftPaired(uint256 indexed fighter1, uint256 indexed fighter2, uint256 pairIndex, uint256 indexed currentEpoch);

	/// @notice Event records info about winners in battles.
	event ChosenWinner(uint256 indexed fighter1, uint256 indexed fighter2, bool winner, uint256 indexed pairIndex, uint256 random, uint256 playedPairsAmount, uint256 currentEpoch);

	/// @notice Event records info about claimed reward from staking.
	event claimedRewardFromStaking(address indexed owner, address indexed beneficiary, uint256 reward, uint256 indexed stakingPositionId, uint256 currentEpoch);

	/// @notice Event records info about changing epochs.
	event EpochUpdated(uint256 date, uint256 newEpoch);

	address public battleVoter;

	uint256 public battlesStartDate;
	uint256 public epochStartDate;                                                 // Start date of battle epoch.
	uint256 public currentEpoch = 1;                                               // Counter for battle epochs.

	uint256 public firstStageDuration = 20 minutes;// hours;        //todo:change time //3 days;    // Duration of first stage(stake).
	uint256 public secondStageDuration = 20 minutes;// hours;       //todo:change time //7 days;    // Duration of second stage(DAI)'.
	uint256 public thirdStageDuration = 20 minutes;// hours;        //todo:change time //2 days;    // Duration of third stage(Pair).
	uint256 public fourthStageDuration = 20 minutes;// hours;       //todo:change time //5 days;    // Duration fourth stage(ZOO).
	uint256 public fifthStageDuration = 20 minutes;// hours;        //todo:change time //2 days;    // Duration of fifth stage(Winner).
	uint256 public epochDuration = firstStageDuration + secondStageDuration + thirdStageDuration + fourthStageDuration + fifthStageDuration; // Total duration of battle epoch.

	uint256[] public stakerPositionsArray;                                        // Array of ZooBattle nfts, which are stakerPositions
	uint256 public mintStakerPositionId;                                              // Counter for Id of ZooBattle nft-positions.
	uint256 public nftsInGame;                                                     // Amount of Paired nfts in current epoch.
	uint256 public numberOfNftsWithNonZeroVotes;                                   // Staker positions with votes for, eligible to pair and battle.

	// Nft contract => allowed or not.
	mapping (address => bool) public allowedForStaking;                            // Records NFT contracts available for staking.

	// epoch number => index => NftPair struct.
	mapping (uint256 => NftPair[]) public pairsInEpoch;                            // Records info of pair in struct for battle epoch.

	// epoch number => number of played pairs in epoch.
	mapping (uint256 => uint256) public numberOfPlayedPairsInEpoch;                // Records amount of pairs with chosen winner in current epoch.

	// position id => StakerPositionStruct struct.
	mapping (uint256 => StakerPositionStruct) public stakingPositionsValues;                   // Records info about ZooBattle nft-position of staker.

	// staker position id => epoch = > rewards struct.
	mapping (uint256 => mapping (uint256 => BattleRewardForEpochFromStaker)) public rewardsForEpochFromStaker;

	/// @notice Contract constructor.
	/// @param _zoo - address of Zoo token contract.
	/// @param _dai - address of DAI token contract.
	/// @param _vault - address of yearn.
	/// @param _zooGovernance - address of ZooDao Governance contract.
	constructor (
		address _zoo,
		address _dai,
		address _vault,
		address _zooGovernance
		) Ownable() ERC721("ZooStaker", "ZS")
	{
		zoo = ERC20Burnable(_zoo);
		dai = ERC20(_dai);
		vault = VaultAPI(_vault);
		zooGovernance = ZooGovernance(_zooGovernance);
		zooFunctions = IZooFunctions(zooGovernance.zooFunctions());

		battlesStartDate = block.timestamp; // for battlesRewardVault.
		epochStartDate = block.timestamp;	//todo:change time for prod + n days; // Start date of 1st battle.
	}

	/// @notice Function to set battleVoter contract address.
	function initBattleVoter(address _nftBattleVoter) external onlyOwner
	{
		battleVoter = _nftBattleVoter;
	}

	/// @notice Function to allow new NFT contract available for stacking.
	/// @param token - address of new Nft contract.
	function allowNewContractForStaking(address token) external onlyOwner
	{
		allowedForStaking[token] = true;                                           // Boolean for contract to be allowed for staking.
		emit newContractAllowed(token, currentEpoch);                              // Emits event that new contract are allowed.
	}

	/// @notice internal function to swap staker position when it becomes non-zero voted.
	function nftWithZeroVotesPositiveSwap(uint256 stakingPositionId) external
	{
		require(msg.sender == battleVoter, "not allowed");

		if (rewardsForEpochFromStaker[stakingPositionId][currentEpoch].votes == 0)   // If staker position had zero votes before,
		{
			for(uint256 i = 0; i < stakerPositionsArray.length; i++)
			{
				if (stakerPositionsArray[i] == stakingPositionId)
				{
					if (stakingPositionId != numberOfNftsWithNonZeroVotes)
					{
						(stakerPositionsArray[i], stakerPositionsArray[numberOfNftsWithNonZeroVotes]) = (stakerPositionsArray[numberOfNftsWithNonZeroVotes], stakerPositionsArray[i]);
					}
					numberOfNftsWithNonZeroVotes++;                                 // Increases amount of nft eligible for pairing.
					break;
				}
			}
		}
	}

	/// @notice internal function to swap staker position when it becomes zero voted.
	function nftwithZeroVotesNegativeSwap(uint256 stakingPositionId, uint256 votes) external
	{
		require(msg.sender == battleVoter, "not allowed");

		rewardsForEpochFromStaker[stakingPositionId][currentEpoch].votes -= votes;

		if (rewardsForEpochFromStaker[stakingPositionId][currentEpoch].votes == 0 && stakingPositionsValues[stakingPositionId].endDate == 0)
		{
			for(uint256 i = 0; i < stakerPositionsArray.length; i++)
			{
				if (stakerPositionsArray[i] == stakingPositionId)
				{
					(stakerPositionsArray[i], stakerPositionsArray[numberOfNftsWithNonZeroVotes - 1]) = (stakerPositionsArray[numberOfNftsWithNonZeroVotes - 1], stakerPositionsArray[i]);
					numberOfNftsWithNonZeroVotes--;
					stakingPositionsValues[stakingPositionId].lastUpdateEpoch = currentEpoch;
					break;
				}
			}
		}
	}

	/// @notice internal function to subtract yTokens for position
	function subYtokensUntilLastEpoch(uint256 stakingPositionId, uint256 daiNumber, uint256 yTokens, uint256 startEpoch, uint256 lastEpoch) external returns(uint256)
	{
		require(msg.sender == battleVoter, "not allowed");

		for (uint256 i = startEpoch; i < lastEpoch; i++)
		{
			if (rewardsForEpochFromStaker[stakingPositionId][i].pricePerShareCoef != 0)
			{
				yTokens -= daiNumber / (rewardsForEpochFromStaker[stakingPositionId][i].pricePerShareCoef);
			}
		}
		return yTokens;
	}

	/// @notice internal function to add votes for position in epoch.
	function votesToStakedNft(uint256 stakingPositionId, uint256 votes) external
	{
		require(msg.sender == battleVoter, "not allowed");

		rewardsForEpochFromStaker[stakingPositionId][currentEpoch].votes += votes;
	}

	/// @notice internal function to subtract votes for position in epoch.  /// @dev currently unused.
	function subVotesFromStakedNft(uint256 stakingPositionId, uint256 votes) external
	{
		require(msg.sender == battleVoter, "not allowed");
		rewardsForEpochFromStaker[stakingPositionId][currentEpoch].votes -= votes;
	}

	/// @notice internal function to add yTokens to position in epoch.
	function yTokensToStakedNft(uint256 stakingPositionId, uint256 yTokensNumber) external
	{
		require(msg.sender == battleVoter, "not allowed");
		rewardsForEpochFromStaker[stakingPositionId][currentEpoch].yTokens += yTokensNumber;
	}

	/// @notice internal function to subtract yTokens from position in epoch.
	function subYtokensFromStakedNft(uint256 stakingPositionId, uint256 yTokensNumber) external
	{
		require(msg.sender == battleVoter, "not allowed");
		rewardsForEpochFromStaker[stakingPositionId][currentEpoch].yTokens -= yTokensNumber;
	}

	/// @notice Function to get amount of nft in array stakerPositionsArray/staked in battles.
	/// @return amount - amount of ZooBattles nft.
	function getstakerPositionsArrayLength() public view returns (uint256 amount)
	{
		return stakerPositionsArray.length;
	}

	/// @notice Function to get amount of nft pairs in epoch.
	/// @param epoch - number of epoch.
	/// @return length - amount of nft pairs.
	function getNftPairLength(uint256 epoch) public view returns(uint256 length)
	{
		return pairsInEpoch[epoch].length;
	}

	/// @notice Function to calculate amount of tokens from shares.
	/// @param sharesAmount - amount of shares.
	/// @return tokens - calculated amount tokens from shares.
	function sharesToTokens(uint256 sharesAmount) public view returns (uint256 tokens)
	{
		return sharesAmount * (vault.pricePerShare()) / (10 ** dai.decimals());
	}

	/// @notice Function for calculating tokens to shares.
	/// @param tokens - amount of tokens to calculate.
	/// @return shares - calculated amount of shares.
	function tokensToShares(int256 tokens) public view returns (int256 shares)
	{
		return int256(uint256(tokens) * (10 ** dai.decimals()) / (vault.pricePerShare()));
	}

	/// @notice Function for staking NFT in this pool.
	/// @param token - address of Nft token to stake.
	/// @param id - id of nft token.
	function stakeNft(address token, uint256 id) public
	{
		require(allowedForStaking[token] == true);                                 // Requires for nft-token to be from allowed contract.
		require(getCurrentStage() == Stage.FirstStage, "Wrong stage!");            // Requires to be at first stage in battle epoch.

		IERC721(token).transferFrom(msg.sender, address(this), id);                // Sends NFT token to this contract.

		_safeMint(msg.sender, mintStakerPositionId);                                  // Mint zoo battle nft position.

		stakingPositionsValues[mintStakerPositionId].startEpoch = currentEpoch;             // Records startEpoch.
		stakingPositionsValues[mintStakerPositionId].startDate = block.timestamp;
		stakingPositionsValues[mintStakerPositionId].lastRewardedEpoch = currentEpoch;      // Records lastRewardedEpoch
		stakingPositionsValues[mintStakerPositionId].token = token;                         // Records nft contract address.
		stakingPositionsValues[mintStakerPositionId].id = id;                               // Records nft id.

		stakerPositionsArray.push(mintStakerPositionId);                                   // Records this position to stakers positions array.

		emit StakedNft(msg.sender, token, id, mintStakerPositionId, currentEpoch);    // Emits StakedNft event.

		mintStakerPositionId++;                                                       // Increments amount and id of future positions.
	}

	/// @notice Function for withdrawing staked nft.
	/// @param stakingPositionId - id of staker position.
	function unstakeNft(uint256 stakingPositionId) public
	{
		require(getCurrentStage() == Stage.FirstStage, "Wrong stage!");             // Requires to be at first stage in battle epoch.
		require(ownerOf(stakingPositionId) == msg.sender);                          // Requires to be owner of position.

		address token = stakingPositionsValues[stakingPositionId].token;                  // Gets token address from position.
		uint256 id = stakingPositionsValues[stakingPositionId].id;                        // Gets token id from position.

		stakingPositionsValues[stakingPositionId].endEpoch = currentEpoch;                // Records epoch when unstaked.
		stakingPositionsValues[stakingPositionId].endDate = block.timestamp;

		IERC721(token).transferFrom(address(this), msg.sender, id);                 // Transfers token back to owner.

		for(uint256 i = 0; i < stakerPositionsArray.length; i++)
		{
			if (stakerPositionsArray[i] == stakingPositionId)
			{
				if (i < numberOfNftsWithNonZeroVotes)
				{
					stakerPositionsArray[i] = stakerPositionsArray[numberOfNftsWithNonZeroVotes - 1];
					stakerPositionsArray[numberOfNftsWithNonZeroVotes - 1] = stakerPositionsArray[stakerPositionsArray.length - 1];
					numberOfNftsWithNonZeroVotes--;
				}
				else
				{
					stakerPositionsArray[i] = stakerPositionsArray[stakerPositionsArray.length - 1];
				}

				stakerPositionsArray.pop();                                              // Removes staker position from array.

				break;
			}
		}
		emit UnstakedNft(msg.sender, token, id, stakingPositionId, currentEpoch);   // Emits UnstakedNft event.
	}

	/// @notice Function to claim reward for staker.
	/// @param stakingPositionId - id of staker position.
	/// @param beneficiary - address of recipient.
	function claimRewardFromStaking(uint256 stakingPositionId, address beneficiary) public
	{
		require(getCurrentStage() == Stage.FirstStage, "Wrong stage!");             // Requires to be at first stage in battle epoch.
		require(ownerOf(stakingPositionId) == msg.sender);                          // Requires to be owner of position.

		updateInfo(stakingPositionId);
		(uint256 end, uint256 stakerReward) = getPendingStakerReward(stakingPositionId);
		stakingPositionsValues[stakingPositionId].lastRewardedEpoch = end;                // Records epoch of last reward claim.

		vault.withdraw(stakerReward, beneficiary);                                  // Gets reward from yearn.

		emit claimedRewardFromStaking(msg.sender, beneficiary, stakerReward, stakingPositionId, currentEpoch);
	}

	/// @notice Function to get pending reward fo staker for this position id.
	/// @param stakingPositionId - id of staker position.
	/// @return stakerReward - reward amount for staker of this nft.
	function getPendingStakerReward(uint256 stakingPositionId) public view returns (uint256 stakerReward, uint256 end)
	{
		uint256 endEpoch = stakingPositionsValues[stakingPositionId].endEpoch;            // Gets endEpoch from position.
		end = endEpoch == 0 ? currentEpoch : endEpoch;                              // Sets end variable to endEpoch if it non-zero, otherwise to currentEpoch.
		int256 yTokensReward;                                                       // Define reward in yTokens.

		for (uint256 i = stakingPositionsValues[stakingPositionId].lastRewardedEpoch; i < end; i++)
		{
			int256 saldo = rewardsForEpochFromStaker[stakingPositionId][i].yTokensSaldo;// Get saldo from staker position.

			if (saldo > 0)
			{
				yTokensReward += saldo * 2 / 100;                                   // Calculates reward for staker.
			}
		}

		stakerReward = uint256(yTokensReward);                                      // Calculates reward amount.
	}

	/// @notice Function for pair nft for battles.
	/// @param stakingPositionId - id of staker position.
	function pairNft(uint256 stakingPositionId) external
	{
		require(getCurrentStage() == Stage.ThirdStage, "Wrong stage!");                     // Requires to be at 3 stage of battle epoch.
		require(numberOfNftsWithNonZeroVotes / 2 > nftsInGame / 2, "err1");         // Requires enough nft for pairing.
		uint256 index1;                                                                     // Index of nft paired for.
		uint256 i;

		for (i = nftsInGame; i < numberOfNftsWithNonZeroVotes; i++)
		{
			if (stakerPositionsArray[i] == stakingPositionId)
			{
				index1 = i;
				break;
			}
		}

		require(i != numberOfNftsWithNonZeroVotes); // Position not found in list of voted for and not paired.

		(stakerPositionsArray[index1], stakerPositionsArray[nftsInGame]) = (stakerPositionsArray[nftsInGame], stakerPositionsArray[index1]);// Swaps nftsInGame with index.
		nftsInGame++;                                                               // Increases amount of paired nft.

		uint256 random = uint256(keccak256(abi.encodePacked(uint256(blockhash(block.number - 1))))) % (numberOfNftsWithNonZeroVotes - (nftsInGame));                         // Get random number.

		uint256 index2 = random + nftsInGame;                                       // Get index of opponent.

		uint256 pairIndex = getNftPairLength(currentEpoch);

		uint256 stakingPosition2 = stakerPositionsArray[index2];                         // Get staker position id of opponent.
		pairsInEpoch[currentEpoch].push(NftPair(stakingPositionId, stakingPosition2, false, false));// Pushes nft pair to array of pairs.

		updateInfo(stakingPositionId);
		updateInfo(stakingPosition2);

		rewardsForEpochFromStaker[stakingPositionId][currentEpoch].tokensAtBattleStart = sharesToTokens(rewardsForEpochFromStaker[stakingPositionId][currentEpoch].yTokens); // Records amount of yTokens on the moment of pairing for candidate.
		rewardsForEpochFromStaker[stakingPosition2][currentEpoch].tokensAtBattleStart = sharesToTokens(rewardsForEpochFromStaker[stakingPosition2][currentEpoch].yTokens);   // Records amount of yTokens on the moment of pairing for opponent.

		rewardsForEpochFromStaker[stakingPositionId][currentEpoch].pricePerShareAtBattleStart = vault.pricePerShare();
		rewardsForEpochFromStaker[stakingPosition2][currentEpoch].pricePerShareAtBattleStart = vault.pricePerShare();

		(stakerPositionsArray[index2], stakerPositionsArray[nftsInGame]) = (stakerPositionsArray[nftsInGame], stakerPositionsArray[index2]); // Swaps nftsInGame with index of opponent.
		nftsInGame++;                                                               // Increases amount of paired nft.

		emit NftPaired(stakingPositionId, stakingPosition2, pairIndex, currentEpoch);
	}


	bool public randomRequested; // Uses to request random only once per epoch.

	/// @notice Function to request random once per epoch.
	function requestRandom() public
	{
		require(getCurrentStage() == Stage.FifthStage, "Wrong stage!");             // Requires to be at 5th stage.
		require(randomRequested == false, "err1");                     // Requires to call once per epoch.

		zooFunctions.getRandomNumber();                                             // call random for randomResult from chainlink or blockhash.
		randomRequested = true;
	}

	/// @notice Function for chosing winner for exact pair of nft.
	/// @param pairIndex - index of nft pair.
	function chooseWinnerInPair(uint256 pairIndex) public
	{
		require(getCurrentStage() == Stage.FifthStage, "Wrong stage!");             // Requires to be at 5th stage.
		require(zooFunctions.randomResult() != 0, "err1");                          // Reverts until new random generated.
		uint256 battleRandom = zooFunctions.randomResult();                                 // Gets random number from zooFunctions.

		uint256 token1 = pairsInEpoch[currentEpoch][pairIndex].token1;              // Get id of 1st candidate.
		updateInfo(token1);
		uint256 votesForA = rewardsForEpochFromStaker[token1][currentEpoch].votes;   // Get votes for 1st candidate.

		uint256 token2 = pairsInEpoch[currentEpoch][pairIndex].token2;              // Get id of 2nd candidate.
		updateInfo(token2);
		uint256 votesForB = rewardsForEpochFromStaker[token2][currentEpoch].votes;   // Get votes for 2nd candidate.

		pairsInEpoch[currentEpoch][pairIndex].win = zooFunctions.decideWins(votesForA, votesForB, battleRandom);   // Calculates winner and records it.

		uint256 tokensAtBattleEnd1 = sharesToTokens(rewardsForEpochFromStaker[token1][currentEpoch].yTokens); // Amount of yTokens for token1 staking Nft position.
		uint256 tokensAtBattleEnd2 = sharesToTokens(rewardsForEpochFromStaker[token2][currentEpoch].yTokens); // Amount of yTokens for token2 staking Nft position.

		uint256 pps1 = rewardsForEpochFromStaker[token1][currentEpoch].pricePerShareAtBattleStart;

		if (pps1 == vault.pricePerShare())
		{
			rewardsForEpochFromStaker[token1][currentEpoch].pricePerShareCoef = 2**256 - 1;
			rewardsForEpochFromStaker[token2][currentEpoch].pricePerShareCoef = 2**256 - 1;
		}
		else
		{
			rewardsForEpochFromStaker[token1][currentEpoch].pricePerShareCoef = vault.pricePerShare() * pps1 / (vault.pricePerShare() - pps1);
			rewardsForEpochFromStaker[token2][currentEpoch].pricePerShareCoef = vault.pricePerShare() * pps1 / (vault.pricePerShare() - pps1);
		}

		int256 income = int256((tokensAtBattleEnd1 + (tokensAtBattleEnd2)) - (rewardsForEpochFromStaker[token1][currentEpoch].tokensAtBattleStart) - (rewardsForEpochFromStaker[token2][currentEpoch].tokensAtBattleStart)); // Calculates income.
		int256 yTokens = tokensToShares(income);

		if (pairsInEpoch[currentEpoch][pairIndex].win)                              // If 1st candidate wins.
		{
			rewardsForEpochFromStaker[token1][currentEpoch].yTokensSaldo += yTokens; // Records income to token1 saldo.
			rewardsForEpochFromStaker[token2][currentEpoch].yTokensSaldo -= yTokens; // Subtract income from token2 saldo.

			rewardsForEpochFromStaker[token1][currentEpoch + 1].yTokens = rewardsForEpochFromStaker[token1][currentEpoch].yTokens + (uint256(yTokens));
			rewardsForEpochFromStaker[token2][currentEpoch + 1].yTokens = rewardsForEpochFromStaker[token2][currentEpoch].yTokens - (uint256(yTokens));
		}
		else                                                                        // If 2nd candidate wins.
		{
			rewardsForEpochFromStaker[token1][currentEpoch].yTokensSaldo -= yTokens; // Subtract income from token1 saldo.
			rewardsForEpochFromStaker[token2][currentEpoch].yTokensSaldo += yTokens; // Records income to token2 saldo.
			rewardsForEpochFromStaker[token1][currentEpoch + 1].yTokens = rewardsForEpochFromStaker[token1][currentEpoch].yTokens - uint256(yTokens);
			rewardsForEpochFromStaker[token1][currentEpoch + 1].yTokens = rewardsForEpochFromStaker[token2][currentEpoch].yTokens + uint256(yTokens);
		}

		numberOfPlayedPairsInEpoch[currentEpoch]++;                                 // Increments amount of pairs played this epoch.
		pairsInEpoch[currentEpoch][pairIndex].playedInEpoch = true;                 // Records that this pair already played this epoch.

		emit ChosenWinner(token1, token2, pairsInEpoch[currentEpoch][pairIndex].win, pairIndex, battleRandom, numberOfPlayedPairsInEpoch[currentEpoch], currentEpoch); // Emits ChosenWinner event.

		if (numberOfPlayedPairsInEpoch[currentEpoch] == pairsInEpoch[currentEpoch].length)
		{
			updateEpoch();                                                          // calls updateEpoch if winner determined in every pair.
		}
	}

	/// @dev Function for updating position in case of battle didn't happen after pairing.
	function updateInfo(uint256 stakingPositionId) public
	{
		if (stakingPositionsValues[stakingPositionId].lastUpdateEpoch == currentEpoch)
			return;

		uint256 end = stakingPositionsValues[stakingPositionId].startEpoch;
		bool votesHasUpdated = false;
		bool yTokensHasUpdated = false;

		for (uint256 i = currentEpoch; i >= end; i--)
		{
			if (!votesHasUpdated && rewardsForEpochFromStaker[stakingPositionId][i].votes != 0)
			{
				rewardsForEpochFromStaker[stakingPositionId][currentEpoch].votes = rewardsForEpochFromStaker[stakingPositionId][i].votes;
				votesHasUpdated = true;
			}

			if (!yTokensHasUpdated && rewardsForEpochFromStaker[stakingPositionId][i].yTokens != 0)
			{
				rewardsForEpochFromStaker[stakingPositionId][currentEpoch].yTokens = rewardsForEpochFromStaker[stakingPositionId][i].yTokens;
				yTokensHasUpdated = true;
			}

			if (votesHasUpdated && yTokensHasUpdated)
			{
				break;
			}
		}
	}

	/// @notice Function to increment epoch.
	function updateEpoch() public {
		require(getCurrentStage() == Stage.FifthStage, "Wrong stage!");             // Requires to be at fourth stage.
		require(block.timestamp >= epochStartDate + epochDuration || numberOfPlayedPairsInEpoch[currentEpoch] == pairsInEpoch[currentEpoch].length); // Requires fourth stage to end, or determine every pair winner.

		zooFunctions = IZooFunctions(zooGovernance.zooFunctions());                 // Sets ZooFunctions to contract specified in zooGovernance.

		epochStartDate = block.timestamp;                                           // Sets start date of new epoch.
		currentEpoch++;                                                             // Increments currentEpoch.
		nftsInGame = 0;                                                             // Nullifies amount of paired nfts.

		zooFunctions.resetRandom();     // Resets random in zoo functions.
		randomRequested = false;        // Resets random request for new epoch.

		firstStageDuration = zooFunctions.firstStageDuration();
		secondStageDuration = zooFunctions.secondStageDuration();
		thirdStageDuration = zooFunctions.thirdStageDuration();
		fourthStageDuration = zooFunctions.fourthStageDuration();
		fifthStageDuration = zooFunctions.fifthStageDuration();

		epochDuration = firstStageDuration + secondStageDuration + thirdStageDuration + fourthStageDuration + fifthStageDuration; // Total duration of battle epoch.

		emit EpochUpdated(block.timestamp, currentEpoch);
	}

	/// @notice Function to view current stage in battle epoch.
	/// @return stage - current stage.
	function getCurrentStage() public view returns (Stage)
	{
		if (block.timestamp < epochStartDate + firstStageDuration)
		{
			return Stage.FirstStage;                                                // Staking stage
		}
		else if (block.timestamp < epochStartDate + firstStageDuration + secondStageDuration)
		{
			return Stage.SecondStage;                                               // Dai vote stage.
		}
		else if (block.timestamp < epochStartDate + firstStageDuration + secondStageDuration + thirdStageDuration)
		{
			return Stage.ThirdStage;                                                // Pair stage.
		}
		else if (block.timestamp < epochStartDate + firstStageDuration + secondStageDuration + thirdStageDuration + fourthStageDuration)
		{
			return Stage.FourthStage;                                               // Zoo vote stage.
		}
		else
		{
			return Stage.FifthStage;                                                // Choose winner stage.
		}
	}
}

pragma solidity 0.8.13;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT

interface VaultAPI {
	function deposit(uint256 amount) external returns (uint256);

	function withdraw(uint256 maxShares, address recipient) external returns (uint256);

	function pricePerShare() external view returns (uint256);
}

pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

import "IZooFunctions.sol";
import "Ownable.sol";

/// @title Contract ZooGovernance.
/// @notice Contract for Zoo Dao vote proposals.
contract ZooGovernance is Ownable {

	address public zooFunctions;                    // Address of contract with Zoo functions.

	/// @notice Contract constructor.
	/// @param baseZooFunctions - address of baseZooFunctions contract.
	/// @param aragon - address of aragon zoo dao agent.
	constructor(address baseZooFunctions, address aragon) {

		zooFunctions = baseZooFunctions;

		transferOwnership(aragon);                  // Sets owner to aragon.
	}

	/// @notice Function for vote for changing Zoo fuctions.
	/// @param newZooFunctions - address of new zoo functions contract.
	function changeZooFunctionsContract(address newZooFunctions) external onlyOwner
	{
		zooFunctions = newZooFunctions;
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

/// @notice interface for NftBattleStaker contract
interface INftBattleStaker {

	/* ========== functions for BattleVoter ========== */

	/// @notice internal function to swap staker position when it becomes non-zero voted.
	function nftWithZeroVotesPositiveSwap(uint256 stakingPositionId) external;

	/// @notice internal function to swap staker position when it becomes zero voted.
	function nftwithZeroVotesNegativeSwap(uint256 stakingPositionId, uint256 votes) external;

	/// @notice internal function to subtract yTokens for position
	function subYtokensUntilLastEpoch(uint256 stakingPositionId, uint256 daiNumber, uint256 yTokens, uint256 startEpoch, uint256 lastEpoch) external returns(uint256);

	/// @notice internal function to add votes for position in epoch.
	function votesToStakedNft(uint256 stakingPositionId, uint256 votes) external;

	/// @notice internal function to subtract votes for position in epoch.
	function subVotesFromStakedNft(uint256 stakingPositionId, uint256 votes) external;     /// @dev currently unused.

	/// @notice internal function to add yTokens to position in epoch.
	function yTokensToStakedNft(uint256 stakingPositionId, uint256 yTokensNumber) external;

	/// @notice internal function to subtract yTokens from position in epoch.
	function subYtokensFromStakedNft(uint256 stakingPositionId, uint256 yTokensNumber) external;

	/* ========== VIEW ========== */

	/// @notice Function to get info from battleReward struct
	function getBattleRewardForEpochFromStaker(uint256 stakingPositionId, uint256 epoch) external;

	/// @notice Function to get amount of nft in array stakerPositionsArray/staked in battles.
	function getstakerPositionsArrayLength() external returns (uint256 amount);

	/// @notice Function to get amount of nft pairs in epoch.
	function getNftPairLength(uint256 epoch) external returns(uint256 length);

	/// @notice Function to calculate amount of tokens from shares.
	function sharesToTokens(uint256 sharesAmount) external returns (uint256 tokens);

	/// @notice Function for calculating tokens to shares.
	function tokensToShares(int256 tokens) external returns (int256 shares);

	/// @notice Function to view current stage in battle epoch.
	function getCurrentStage() external;

	/// @notice Function to get pending reward fo staker for this position id.
	function getPendingStakerReward(uint256 stakingPositionId) external returns (uint256 stakerReward, uint256 end);


	/* ========== other ========== */

	/// @notice Function to set battleVoter contract address.
	function initBattleVoter(address _nftBattleVoter) external;

	/// @notice Function to allow new NFT contract available for stacking.
	function allowNewContractForStaking(address token) external;

	/// @notice Function for staking NFT in this pool.
	function stakeNft(address token, uint256 id) external;

	/// @notice Function for withdrawing staked nft.
	function unstakeNft(uint256 stakingPositionId) external;

	/// @notice Function to claim reward for staker.
	function claimRewardFromStaking(uint256 stakingPositionId, address beneficiary) external;

	/// @notice Function for pair nft for battles.
	function pairNft(uint256 stakingPositionId) external;

	/// @notice Function to request random once per epoch.
	function requestRandom() external;

	/// @notice Function for chosing winner for exact pair of nft.
	function chooseWinnerInPair(uint256 pairIndex) external;

	/// @dev Function for updating position in case of battle didn't happen after pairing.
	function updateInfo(uint256 stakingPositionId) external;

	/// @notice Function to increment epoch.
	function updateEpoch() external;


	function claimRewardForStaking(uint256 stakingPositionId) external;                   // todo: reward for staker function from BattlesRewardVault.

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "ERC20.sol";
import "Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "IERC721.sol";
import "IERC721Receiver.sol";
import "IERC721Metadata.sol";
import "Address.sol";
import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

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
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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
        address owner = ERC721.ownerOf(tokenId);

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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
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
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "IERC721.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

import "IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "LinkTokenInterface.sol";

import "VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}
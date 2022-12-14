pragma solidity ^0.8.17;

import "IERC721Enumerable.sol";
import "IERC20.sol";
import "Ownable.sol";
import "Pausable.sol";
import "IApeMatcher.sol";
import "ISmoothOperator.sol";
import "IApeStaking.sol";

contract ApeMatcher is Pausable, IApeMatcher {

	uint256 constant public MIN_STAKING_PERIOD = 7 days;
	uint256 constant public FEE = 40; // 4%
	uint256 constant public DENOMINATOR = 1000;

	// IApeStaking public immutable APE_STAKING = IApeStaking(0x5954aB967Bc958940b7EB73ee84797Dc8a2AFbb9);
	// IERC721Enumerable public immutable ALPHA = IERC721Enumerable(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D);
	// IERC721Enumerable public immutable BETA = IERC721Enumerable(0x60E4d786628Fea6478F785A6d7e704777c86a7c6);
	// IERC721Enumerable public immutable GAMMA = IERC721Enumerable(0xba30E5F9Bb24caa003E9f2f0497Ad287FDF95623);
	// IERC20 public immutable APE = IERC20(0x4d224452801ACEd8B2F0aebE155379bb5D594381);

	IApeStaking public APE_STAKING;
	IERC721Enumerable public ALPHA;
	IERC721Enumerable public BETA;
	IERC721Enumerable public GAMMA;
	IERC20 public APE;

	uint256 constant ALPHA_SHARE = 10094 ether; //bayc
	uint256 constant BETA_SHARE = 2042 ether; // mayc
	uint256 constant GAMMA_SHARE = 856 ether; // dog

	uint256 public fee;
	uint256 weights;
	mapping(address => mapping(uint256 => address)) public assetToUser;

	uint256 public matchCounter = 1;
	uint256 public doglessMatchCounter;

	uint256 public alphaSpentCounter;
	uint256 public betaSpentCounter;
	uint256 public gammaSpentCounter;

	uint256 public alphaDepositCounter;
	uint256 public betaDepositCounter;
	uint256 public gammaDepositCounter;

	uint256 public alphaCurrentTotalDeposits;
	uint256 public betaCurrentTotalDeposits;
	uint256 public gammaCurrentTotalDeposits;
	mapping(uint256 => mapping(uint256 => DepositPosition)) public depositPosition;

	mapping(uint256 => GreatMatch) public matches;
	mapping(uint256 => uint256) public doglessMatches;
	mapping(address => uint256) public payments;

	ISmoothOperator public smoothOperator; // add interface to our smooth operator

	constructor(address a,address b,address c,address d,address e) {
		ALPHA = IERC721Enumerable(a);
		BETA = IERC721Enumerable(b);
		GAMMA = IERC721Enumerable(c);
		APE = IERC20(d);
		APE_STAKING = IApeStaking(e);
	}

	modifier onlyOperator() {
		require(msg.sender == address(smoothOperator), "!smooooth");
		_;
	}

	/**  
	 * @notice
	 * Set the contract to handle NFTs and Ape coins. Can be called only once. Owner gated
	 * @param _operator contract address of the operator
	 */
	function setOperator(address _operator) external onlyOwner {
		require(address(smoothOperator) == address(0));
		smoothOperator = ISmoothOperator(_operator);
	}

	/**  
	 * @notice
	 * Updates the weights that dictates how rewards are split. Owner gated
	 * @param _primaryWeights Array containing the weights for primary splits
	  * @param _dogWeights Array containing the weights for secondary splits
	 */
	function updateWeights(uint32[4] calldata _primaryWeights, uint32[4] calldata _dogWeights) external onlyOwner {
		require(_primaryWeights[0] + _primaryWeights[1] + _primaryWeights[2] + _primaryWeights[3] == 1000);
		require(_primaryWeights[2] + _primaryWeights[3] == 0);
		require(_dogWeights[0] + _dogWeights[1] + _dogWeights[2] + _dogWeights[3] == 1000);

		uint256 val;
		for(uint256 i = 0; i < 4 ; i++)
			val |= (uint256(_primaryWeights[i]) << (32 * (7 - i))) + (uint256(_dogWeights[i]) << (32 * (3 - i)));
		weights = val;
	}

	/**  
	 * @notice
	 * Allows owner to fetch ape coin fees. Owner gated
	 */
	function fetchApe() external onlyOwner {
		uint256 amount = fee;
		fee = 0;
		APE.transfer(owner(), amount);
	}

	/**  
	 * @notice
	 * Allows a user to deposit NFTs into the contract
	 * @param _alphaIds Array of BAYC nfts to deposit
	 * @param _betaIds Array of MAYC nfts to deposit
	 * @param _gammaIds Array of BAKC nfts to deposit
	 */
	function depositNfts(
		uint256[] calldata _alphaIds,
		uint256[] calldata _betaIds,
		uint256[] calldata _gammaIds) external notPaused {
		if (_gammaIds.length > 0)
			_depositNfts(GAMMA, _gammaIds, msg.sender);
		if (_alphaIds.length > 0) {
			_depositNfts(ALPHA, _alphaIds, msg.sender);
			_mixAndMatch(ALPHA, ALPHA_SHARE, alphaSpentCounter);
		}
		if (_betaIds.length > 0) {
			_depositNfts(BETA, _betaIds, msg.sender);
			_mixAndMatch(BETA, BETA_SHARE, betaSpentCounter);
		}
		_bindDoggoToMatchId();
	}

	/**  
	 * @notice
	 * Allows the operator to deposit the tokens of a user. Used when a match is broken
	 * @param _depositAmounts Array of amounts of deposits of each tranche to deposit
	 * @param _user User to deposit to
	 */
	function depositApeTokenForUser(uint32[3] calldata _depositAmounts, address _user) external override onlyOperator {
		uint256 totalDeposit = 0;
		uint256[3] memory depositValues = [ALPHA_SHARE, BETA_SHARE, GAMMA_SHARE];
		for(uint256 i = 0; i < 3; i++) {
			totalDeposit += depositValues[i] * uint256(_depositAmounts[i]);
			if (_depositAmounts[i] > 0)
				_handleDeposit(depositValues[i], _depositAmounts[i], _user);
			// TODO emit event somehow
		}
		_mixAndMatch(ALPHA, ALPHA_SHARE, alphaSpentCounter);
		_mixAndMatch(BETA, BETA_SHARE, betaSpentCounter);
		_bindDoggoToMatchId();
	}

	/**  
	 * @notice
	 * Allows a user to deposit ape coins into the contract
	 * @param _depositAmounts Array of amounts of deposits of each tranche to deposit
	 */
	function depositApeToken(uint32[3] calldata _depositAmounts) external notPaused {
		uint256 totalDeposit = 0;
		uint256[3] memory depositValues = [ALPHA_SHARE, BETA_SHARE, GAMMA_SHARE];
		for(uint256 i = 0; i < 3; i++) {
			totalDeposit += depositValues[i] * uint256(_depositAmounts[i]);
			if (_depositAmounts[i] > 0)
				_handleDeposit(depositValues[i], _depositAmounts[i], msg.sender);
			// TODO emit event somehow
		}
		if (totalDeposit > 0) {
			APE.transferFrom(msg.sender, address(this), totalDeposit);
			_mixAndMatch(ALPHA, ALPHA_SHARE, alphaSpentCounter);
			_mixAndMatch(BETA, BETA_SHARE, betaSpentCounter);
			_bindDoggoToMatchId();
		}
	}

	/**  
	 * @notice
	 * Allows a user withdraw their NFTs that aren't matched
	 * @param _alphaIds Array of BAYC nfts to withdraw
	 * @param _betaIds Array of MAYC nfts to withdraw
	 * @param _gammaIds Array of BAKC nfts to withdraw
	 */
	function withdrawNfts(
		uint256[] calldata _alphaIds,
		uint256[] calldata _betaIds,
		uint256[] calldata _gammaIds) external {
		if (_gammaIds.length > 0)
			_withdrawNfts(GAMMA, _gammaIds, msg.sender);
		if (_alphaIds.length > 0)
			_withdrawNfts(ALPHA, _alphaIds, msg.sender);
		if (_betaIds.length > 0)
			_withdrawNfts(BETA, _betaIds, msg.sender);
	}

	/**  
	 * @notice
	 * Allows a user withdraw their ape coin deposits that haven't been consumed
	 * @param _depositIndexAlpha Array of deposit IDs of the BAYC tranche
	 * @param _depositIndexBeta Array of deposit IDs of the MAYC tranche
	 * @param _depositIndexGamma Array of deposit IDs of the BAKC tranche
	 */
	function withdrawApeToken(
		uint256[] calldata _depositIndexAlpha,
		uint256[] calldata _depositIndexBeta,
		uint256[] calldata _depositIndexGamma) external {
		uint256 amountToReturn = 0;
		for (uint256 i = 0 ; i < _depositIndexAlpha.length; i++) {
			if (i < _depositIndexAlpha.length - 1)
				require(_depositIndexAlpha[i] > _depositIndexAlpha[i + 1]);
			amountToReturn += _verifyAndReturnDepositValue(0, _depositIndexAlpha[i], msg.sender);
		}
		for (uint256 i = 0 ; i < _depositIndexBeta.length; i++) {
			if (i < _depositIndexBeta.length - 1)
				require(_depositIndexBeta[i] > _depositIndexBeta[i + 1]);
			amountToReturn += _verifyAndReturnDepositValue(1, _depositIndexBeta[i], msg.sender);
		}
		for (uint256 i = 0 ; i < _depositIndexGamma.length; i++) {
			if (i < _depositIndexGamma.length - 1)
				require(_depositIndexGamma[i] > _depositIndexGamma[i + 1]);
			amountToReturn += _verifyAndReturnDepositValue(2, _depositIndexGamma[i], msg.sender);
		}
		APE.transfer(msg.sender, amountToReturn);
	}

	/**  
	 * @notice
	 * Allows a user to claim any outstanding amount of rewards
	 */
	function claimTokens() external {
		_claimTokens(msg.sender);
	}

	/**  
	 * @notice
	 * Allows a user to claim rewards from an array of matches they are involved with
	 * @param _matchIds Array of match IDs a user is involved with 
	 * @param _claim Boolean to set if the users withdraws rewards now or not
	 */
	function batchClaimRewardsFromMatches(uint256[] calldata _matchIds, bool _claim) external {
		uint256 _fee;
		for(uint256 i = 0 ; i < _matchIds.length; i++)
			_fee += _claimRewardsFromMatch(_matchIds[i]);
		_handleFee(_fee);
		if (_claim)
			_claimTokens(msg.sender);
	}

	/**  
	 * @notice
	 * Allows a user to break matches they are involved with to recuperate their asset(s)
	 * @param _matchIds Array of match IDs a user is involved with 
	 * @param _breakAll Array of booleans indicating to break the whole match or just the dog agreement
	 */
	function batchBreakMatch(uint256[] calldata _matchIds, bool[] calldata _breakAll) external {
		uint256 _fee;
		for (uint256 i = 0; i < _matchIds.length; i++) 
			_fee += _breakMatch(_matchIds[i], _breakAll[i]);
		_handleFee(_fee);
	}

	/**  
	 * @notice
	 * Allows a user to break matches they are involved with to recuperate their asset(s).
	 * Only dogs and dog toke deposits can be removed
	 * @param _matchIds Array of match IDs a user is involved with 
	 */
	function batchBreakDogMatch(uint256[] calldata _matchIds) external {
		uint256 _fee;
		for (uint256 i = 0; i < _matchIds.length; i++)
			_fee += _breakDogMatch(_matchIds[i]);
		_handleFee(_fee);
	}

	/**  
	 * @notice
	 * Allows a user to swap their asset in a match with another one that currently exists in the contract
	 * @param _matchIds Array of match IDs a user is involved with 
	 * @param _swapSetup Array of boolean indicating what the user wants swap in the match
	 */
	function batchSmartBreakMatch(uint256[] calldata _matchIds, bool[4][] memory _swapSetup) external {
		uint256 _fee;
		for (uint256 i = 0; i < _matchIds.length; i++)
			_fee += _smartBreakMatch(_matchIds[i], _swapSetup[i]);
		_handleFee(_fee);
	}

	// INTERNAL

	/**  
	 * @notice
	 * Internal function that claims tokens for a user
	 * @param _user User to send rewards to
	 */
	function _claimTokens(address _user) internal {
		uint256 rewards = payments[_user];
		if (rewards > 0) {
			payments[_user] = 0;
			APE.transfer(_user, rewards);
		}
	}

	/**  
	 * @notice
	 * Interncl function that claims tokens from a match
	 * @param _matchId Match ID to claim from
	 */
	function _claimRewardsFromMatch(uint256 _matchId) internal returns(uint256 _fee) {
		GreatMatch memory _match = matches[_matchId];
		require(_match.active, "!active");
		address[4] memory adds = [_match.primaryOwner, _match.primaryTokensOwner, _match.doggoOwner,  _match.doggoTokensOwner];
		require(msg.sender == adds[0] || msg.sender == adds[1] ||
				msg.sender == adds[2] || msg.sender == adds[3], "!match");

		bool claimGamma = msg.sender == adds[2] || msg.sender == adds[3];
		bool claimPrimary = msg.sender == adds[0] || msg.sender == adds[1];
		address primary = _match.primary == 1 ? address(ALPHA) : address(BETA);
		uint256 ids = _match.ids;
		(uint256 total, uint256 totalGamma) = smoothOperator.claim(primary, ids & 0xffffffffffff, ids >> 48,
			claimGamma && claimPrimary ? 2 : (claimGamma ? 0 : 1));
		if (total > 0)
			_fee += _processRewards(total, adds, msg.sender, false);
		if (totalGamma > 0)
			_fee += _processRewards(totalGamma, adds, msg.sender, true);
	}

	/**  
	 * @notice
	 * Internal function that claims tokens from a match
	 * @param _matchId Match ID to claim from
	 * @param _swapSetup Boolean array indicating what the user wants swap in the match
	 */
	function _smartBreakMatch(uint256 _matchId, bool[4] memory _swapSetup) internal returns(uint256 _fee) {
		GreatMatch memory _match = matches[_matchId];
		require(_match.active, "!active");
		address[4] memory adds = [_match.primaryOwner, _match.primaryTokensOwner, _match.doggoOwner,  _match.doggoTokensOwner];
		require(msg.sender == adds[0] || msg.sender == adds[1] ||
				msg.sender == adds[2] || msg.sender == adds[3], "!match");
		
		for (uint256 i; i < 4; i++)
			_swapSetup[i] = _swapSetup[i] && msg.sender == adds[i];
		uint256 ids = _match.ids;
		address primary = _match.primary == 1 ? address(ALPHA) : address(BETA);
		(uint256 totalPrimary, uint256 totalGamma) = _smartSwap(_swapSetup, ids, primary, _matchId, msg.sender);
		if (totalPrimary > 0)
			_fee += _processRewards(totalPrimary, adds, msg.sender, false);
		if (totalGamma > 0)
			_fee += _processRewards(totalGamma, adds, msg.sender, true);
	}

	/**  
	 * @notice
	 * Internal function that handles swapping an asset of a match with another in the contract
	 * @param _swapSetup Boolean array indicating what the user wants swap in the match
	 * @param _ids Ids of primary asset and dog 
	 * @param _primary Contract address of the primary asset
	 * @param _matchId Match ID to execurte the swap
	 * @param _user User to swap out
	 */
	function _smartSwap(
		bool[4] memory _swapSetup,
		uint256 _ids,
		address _primary,
		uint256 _matchId,
		address _user) internal returns (uint256 totalPrimary, uint256 totalGamma) {
		// swap primary nft out
		if (_swapSetup[0]) {
			require(IERC721Enumerable(_primary).balanceOf(address(this)) > 0, "ApeMatcher: !primary asset");
			uint256 id = IERC721Enumerable(_primary).tokenOfOwnerByIndex(address(this), 0);
			uint256 oldId = _ids & 0xffffffffffff;
			matches[_matchId].ids = uint96(((_ids >> 48) << 48) | id); // swap primary ids
			matches[_matchId].primaryOwner = assetToUser[_primary][id]; // swap primary owner
			delete assetToUser[_primary][oldId];
			IERC721Enumerable(_primary).transferFrom(address(this), address(smoothOperator), id);
			(totalPrimary, totalGamma) = smoothOperator.swapPrimaryNft(_primary, id, oldId, _user, _ids >> 48);
		}
		// swap token depositor, since tokens are fungible, no movement required, simply consume a deposit and return share to initial depositor
		if (_swapSetup[1]) {
			if (_primary == address(ALPHA)) {
				require(alphaCurrentTotalDeposits > 0, "ApeMatcher: !alpha deposits");
				DepositPosition storage pos = depositPosition[ALPHA_SHARE][alphaSpentCounter]; 
				matches[_matchId].primaryTokensOwner = pos.depositor; // swap primary token owner
				if (pos.count == 1)
					delete depositPosition[ALPHA_SHARE][alphaSpentCounter++];
				else
					pos.count--;
				alphaCurrentTotalDeposits--;
			}
			else {
				require(betaCurrentTotalDeposits > 0, "ApeMatcher: !beta deposits");
				DepositPosition storage pos = depositPosition[BETA_SHARE][betaSpentCounter];
				matches[_matchId].primaryTokensOwner = pos.depositor; // swap primary token owner
				if (pos.count == 1)
					delete depositPosition[BETA_SHARE][betaSpentCounter++];
				else
					pos.count--;
				betaCurrentTotalDeposits--;
			}
			APE.transfer(_user, _primary == address(ALPHA) ? ALPHA_SHARE : BETA_SHARE);
			(totalPrimary,) = smoothOperator.claim(_primary, _ids & 0xffffffffffff, _ids >> 48, 1);
		}
		// swap doggo out
		if (_swapSetup[2]) {
			require(GAMMA.balanceOf(address(this)) > 0, "ApeMatcher: !dog asset");
			uint256 id = GAMMA.tokenOfOwnerByIndex(address(this), 0);
			uint256 oldId = _ids >> 48;
			matches[_matchId].ids = uint96((_ids & 0xffffffffffff) | (id << 48)); // swap gamma ids
			matches[_matchId].doggoOwner = assetToUser[address(GAMMA)][id]; // swap gamma owner
			delete assetToUser[address(GAMMA)][oldId];
			GAMMA.transferFrom(address(this), address(smoothOperator), id);
			totalGamma = smoothOperator.swapDoggoNft(_primary, _ids & 0xffffffffffff,  id, oldId, _user);
		}
		// swap token depositor, since tokens are fungible, no movement required, simply consume a deposit and return share to initial depositor
		if (_swapSetup[3]) {
			require(gammaCurrentTotalDeposits > 0, "ApeMatcher: !dog deposit");
			DepositPosition storage pos = depositPosition[GAMMA_SHARE][gammaSpentCounter];
			matches[_matchId].doggoTokensOwner = pos.depositor; // swap gamma token owner
			if (pos.count == 1)
					delete depositPosition[GAMMA_SHARE][gammaSpentCounter++];
			else
				pos.count--;
			gammaCurrentTotalDeposits--;
			APE.transfer(_user, GAMMA_SHARE);
			(,totalGamma) = smoothOperator.claim(_primary, _ids & 0xffffffffffff, _ids >> 48, 0);
		}
	}

	/**  
	 * @notice
	 * Internal function that breaks a match
	 * @param _matchId Match ID to break
	 * @param _breakAll Boolean indicating if we break the whole match or just the dogs
	 */
	function _breakMatch(uint256 _matchId, bool _breakAll) internal returns(uint256 _fee){
		GreatMatch memory _match = matches[_matchId];
		require(_match.active, "!active");
		address[4] memory adds = [_match.primaryOwner, _match.primaryTokensOwner, _match.doggoOwner,  _match.doggoTokensOwner];
		require(msg.sender == adds[0] || msg.sender == adds[1] ||
				msg.sender == adds[2] || msg.sender == adds[3], "!match");
		require (block.timestamp - _match.start > MIN_STAKING_PERIOD, "Must wait min duration to break clause");
		bool breakGamma = msg.sender == adds[2] || msg.sender == adds[3];
		bool primaryOwner = msg.sender == adds[0] || msg.sender == adds[1];
		_breakAll = primaryOwner ? _breakAll : false;
		if(breakGamma && !_breakAll)
			_fee += _breakDogMatch(_matchId);
		else {
			uint256 tokenId = _match.ids;
			(uint256 total, uint256 totalGamma) = smoothOperator.uncommitNFTs(_match, msg.sender);
			if (msg.sender == adds[0])
				delete assetToUser[_match.primary == 1 ? address(ALPHA) : address(BETA)][tokenId & 0xffffffffffff];
			if (msg.sender == adds[2] && tokenId >> 48 > 0)
				delete assetToUser[address(GAMMA)][tokenId >> 48];
			delete matches[_matchId];
			_fee += _processRewards(total, adds, msg.sender, false);
			if (totalGamma > 0)
				_fee += _processRewards(totalGamma, adds, msg.sender, true);
		}
	}

	/**  
	 * @notice
	 * Internal function that breaks the dog agreement in a match
	 * @param _matchId Match ID to break
	 */
	function _breakDogMatch(uint256 _matchId) internal returns(uint256){
		GreatMatch memory _match = matches[_matchId];
		require(_match.active, "!active");
		address[4] memory adds = [_match.primaryOwner, _match.primaryTokensOwner, _match.doggoOwner,  _match.doggoTokensOwner];
		require(msg.sender == adds[2] || msg.sender == adds[3], "!dog match");

		uint256 totalGamma = _unbindDoggoFromMatchId(_matchId, msg.sender);
		return _processRewards(totalGamma, adds, msg.sender, true);
	}

	/**  
	 * @notice
	 * Internal function that handles the payment from a match to the users involved
	 * @param _total Amount of tokens to distribute to users
	 * @param _adds Array of users involved
	 * @param _user Initial caller of the execution
	 * @param _claimGamma Boolean indicating if the reward came from a primary of dog claim
	 */
	function _processRewards(uint256 _total, address[4] memory _adds, address _user, bool _claimGamma) internal returns(uint256 _fee){
		uint128[4] memory splits = _smartSplit(uint128(_total), _adds, _claimGamma, weights);
		for (uint256 i = 0 ; i < 4; i++)
			if (splits[i] > 0) {
				// If you own both primary nft and deposit token, no fee charged
				if ((i == 0 || i == 1) && _user == _adds[0] && _user == _adds[1] && !_claimGamma)
					payments[_adds[i]] += splits[i];
				else {
					_fee += splits[i] * FEE / DENOMINATOR;
					payments[_adds[i]] += splits[i] - (splits[i] * FEE / DENOMINATOR);
				}
					
			}
	}

	/**  
	 * @notice
	 * Internal function that handles the payment split of a given reward
	 * @param _total Amount of tokens to distribute to users
	 * @param _adds Array of users involved
	 * @param _claimGamma Boolean indicating if the reward came from a primary of dog claim
	 * @param _weight Value holding the split ratios of primary and dog claims
	 */
	function _smartSplit(uint128 _total, address[4] memory _adds, bool _claimGamma, uint256 _weight) internal pure returns(uint128[4] memory splits) {
		uint256 i = 0;
		splits = _getWeights(_claimGamma, _weight);
		uint128 sum  = 0;
		for (i = 0 ; i < 4 ; i++)
			sum += splits[i];
		// update splits
		for (i = 0 ; i < 4 ; i++)
			splits[i] =  _total * splits[i] / sum;

		for (i = 0 ; i < 3 ; i++)
			for (uint256 j = i + 1 ; j < 4 ; j++) {
				if (_adds[i] == _adds[j] && splits[j] > 0) {
					splits[i] += splits[j];
					splits[j] = 0;
				}
			}
	}

	/**  
	 * @notice
	 * Internal function that handles the pairing of primary assets with tokens if they exist
	 * @param _primary Contract address of the primary asset
	 * @param _primaryShare Amount pf tokens required to stake with primary asset
	 * @param _primarySpentCounter Index of token deposit of primary asset
	 */
	function _mixAndMatch(
		IERC721Enumerable _primary,
		uint256 _primaryShare,
		uint256 _primarySpentCounter) internal {
		uint256 matchCount = _min(_primary.balanceOf(address(this)), _primary == ALPHA ? alphaCurrentTotalDeposits : betaCurrentTotalDeposits);
		uint256 gammaCount = _min(GAMMA.balanceOf(address(this)), gammaCurrentTotalDeposits);
		DepositPosition memory primaryPos = DepositPosition(
				depositPosition[_primaryShare][_primarySpentCounter].count,
				depositPosition[_primaryShare][_primarySpentCounter].depositor);
		DepositPosition memory gammaPos = DepositPosition(
				depositPosition[GAMMA_SHARE][gammaSpentCounter].count,
				depositPosition[GAMMA_SHARE][gammaSpentCounter].depositor);

		if (_primary == ALPHA)
			alphaCurrentTotalDeposits -= matchCount;
		else
			betaCurrentTotalDeposits -= matchCount;
		gammaCurrentTotalDeposits -= _min(matchCount, gammaCount);
		for (uint256 i = 0; i < matchCount ; i++) {
			bool gammaMatch = i < gammaCount;
			uint256 gammaId = 0;
			uint256 id = _primary.tokenOfOwnerByIndex(address(this), 0);
			if (gammaMatch)
				gammaId = GAMMA.tokenOfOwnerByIndex(address(this), 0);
			else
				doglessMatches[doglessMatchCounter++] = matchCounter;
			matches[matchCounter++] = GreatMatch(
				true,
				_primary == ALPHA ? uint8(1) : uint8(2),
				uint32(block.timestamp),
				uint96((gammaId << 48) + id),
				assetToUser[address(_primary)][id],
				primaryPos.depositor,
				gammaMatch ? assetToUser[address(GAMMA)][gammaId] : address(0),
				gammaMatch ? gammaPos.depositor : address(0)
			);
			primaryPos.count--;
			if (gammaMatch)
				gammaPos.count--;
			if (primaryPos.count == 0) {
				delete depositPosition[_primaryShare][_primary == ALPHA ? alphaSpentCounter++ : betaSpentCounter++];
				primaryPos = DepositPosition(
					depositPosition[_primaryShare][_primary == ALPHA ? alphaSpentCounter : betaSpentCounter].count,
					depositPosition[_primaryShare][_primary == ALPHA ? alphaSpentCounter : betaSpentCounter].depositor);
			}
			if (gammaPos.count == 0 && gammaMatch) {
				delete depositPosition[GAMMA_SHARE][gammaSpentCounter++];
				gammaPos = DepositPosition(
					depositPosition[GAMMA_SHARE][gammaSpentCounter].count,
					depositPosition[GAMMA_SHARE][gammaSpentCounter].depositor);
			}
			_primary.transferFrom(address(this), address(smoothOperator), id);
			if (gammaMatch)
				GAMMA.transferFrom(address(this), address(smoothOperator), gammaId);
			APE.transfer(address(smoothOperator), _primaryShare + (gammaMatch ? GAMMA_SHARE : 0));
			smoothOperator.commitNFTs(address(_primary), id, gammaId);
		}
		depositPosition[_primaryShare][_primary == ALPHA ? alphaSpentCounter : betaSpentCounter].count = primaryPos.count;
		depositPosition[GAMMA_SHARE][gammaSpentCounter].count = gammaPos.count;
	}

	/**
	 * @notice
	 * Internal function that handles the pairing of DOG assets with tokens if they exist to an existing dogless match
	 */
	function _bindDoggoToMatchId() internal {
		uint256 toBind = _min(doglessMatchCounter, _min(GAMMA.balanceOf(address(this)), gammaCurrentTotalDeposits));
		if (toBind == 0) return;
		uint256 doglessIndex = doglessMatchCounter - 1;
		DepositPosition memory gammaPos = DepositPosition(
				depositPosition[GAMMA_SHARE][gammaSpentCounter].count,
				depositPosition[GAMMA_SHARE][gammaSpentCounter].depositor);

		gammaCurrentTotalDeposits -= toBind;
		for (uint256 i = 0; i < toBind; i++) {
			GreatMatch storage _match = matches[doglessMatches[doglessIndex - i]];
			uint256 gammaId = GAMMA.tokenOfOwnerByIndex(address(this), 0);
			address primary = _match.primary == 1 ? address(ALPHA) : address(BETA);
			delete doglessMatches[doglessIndex - i];
			_match.ids |= uint96(gammaId << 48);
			_match.doggoOwner = assetToUser[address(GAMMA)][gammaId];
			_match.doggoTokensOwner = gammaPos.depositor;
			GAMMA.transferFrom(address(this), address(smoothOperator), gammaId);
			APE.transfer(address(smoothOperator), GAMMA_SHARE);
			smoothOperator.bindDoggoToExistingPrimary(primary, _match.ids & 0xffffffffffff, gammaId);
			if (--gammaPos.count == 0) {
				delete depositPosition[GAMMA_SHARE][gammaSpentCounter++];
				gammaPos = DepositPosition(
					depositPosition[GAMMA_SHARE][gammaSpentCounter].count,
					depositPosition[GAMMA_SHARE][gammaSpentCounter].depositor);
			}
		}
		doglessMatchCounter -= toBind;
		depositPosition[GAMMA_SHARE][gammaSpentCounter].count = gammaPos.count;
	}

	/**
	 * @notice
	 * Internal function that handles unbinding a dog from a match
	 * @param _matchId Match ID to remove the dog from
	 * @param _caller Initial caller of this execution
	 */
	function _unbindDoggoFromMatchId(uint256 _matchId, address _caller) internal returns(uint256 totalGamma) {
		GreatMatch storage _match = matches[_matchId];
		address primary = _match.primary == 1 ? address(ALPHA) : address(BETA);
		address dogOwner = _match.doggoOwner;
		uint256 ids = _match.ids;
		totalGamma = smoothOperator.unbindDoggoFromExistingPrimary(
			primary,
			ids & 0xffffffffffff,
			ids >> 48,
			dogOwner,
			_match.doggoTokensOwner,
			_caller);
		if (dogOwner == _caller)	
			delete assetToUser[address(GAMMA)][ids >> 48];
		_match.doggoOwner = address(0);
		_match.doggoTokensOwner = address(0);
		doglessMatches[doglessMatchCounter++] = _matchId;
		_match.ids = uint96(ids & 0xffffffffffff);
	}

	/**
	 * @notice
	 * Internal function that handles deposits for a user
	 * @param _type Deposit type (bayc/mayc/bakc)
	 * @param _amount Amount of deposits
	 * @param _user User to whom attribute the deposits
	 */
	function _handleDeposit(uint256 _type, uint32 _amount, address _user) internal {
		if (_type == ALPHA_SHARE) {
			depositPosition[ALPHA_SHARE][alphaDepositCounter++] = DepositPosition(_amount, _user);
			alphaCurrentTotalDeposits += _amount;
		}
		else if (_type == BETA_SHARE) {
			depositPosition[BETA_SHARE][betaDepositCounter++] =  DepositPosition(_amount, _user);
			betaCurrentTotalDeposits += _amount;
		}
		else if (_type == GAMMA_SHARE) {
			depositPosition[GAMMA_SHARE][gammaDepositCounter++] =  DepositPosition(_amount, _user);
			gammaCurrentTotalDeposits += _amount;
		}
	}

	/**
	 * @notice
	 * Internal function that handles deposits for a user
	 * @param _type Deposit type (bayc/mayc/bakc)
	 * @param _index Amount of deposits
	 * @param _user User to whom attribute the deposits
	 */
	function _verifyAndReturnDepositValue(uint256 _type, uint256 _index, address _user) internal returns (uint256){
		uint256 count;
		if (_type == 0) {
			require(alphaDepositCounter > _index, "ApeMatcher: deposit !exist");
			require(alphaSpentCounter <= _index, "ApeMatcher: deposit consumed"); 
			require(depositPosition[ALPHA_SHARE][_index].depositor == _user, "ApeMatcher: Not owner of deposit");

			count = depositPosition[ALPHA_SHARE][_index].count;
			alphaCurrentTotalDeposits -= count;
			depositPosition[ALPHA_SHARE][_index] = depositPosition[ALPHA_SHARE][alphaDepositCounter - 1];
			delete depositPosition[ALPHA_SHARE][alphaDepositCounter-- - 1];
			return ALPHA_SHARE * count;
		}
		else if (_type == 1) {
			require(betaDepositCounter > _index, "ApeMatcher: deposit !exist");
			require(betaSpentCounter <= _index, "ApeMatcher: deposit consumed");
			require(depositPosition[BETA_SHARE][_index].depositor == _user, "ApeMatcher: Not owner of deposit");

			count = depositPosition[BETA_SHARE][_index].count;
			betaCurrentTotalDeposits -= count;
			depositPosition[BETA_SHARE][_index] = depositPosition[BETA_SHARE][betaDepositCounter - 1];
			delete depositPosition[BETA_SHARE][betaDepositCounter-- - 1];
			return BETA_SHARE * count;
		}
		else if (_type == 2) {
			require(gammaDepositCounter > _index, "ApeMatcher: deposit !exist");
			require(gammaSpentCounter <= _index, "ApeMatcher: deposit consumed");
			require(depositPosition[GAMMA_SHARE][_index].depositor == _user, "ApeMatcher: Not owner of deposit");

			count = depositPosition[GAMMA_SHARE][_index].count;
			gammaCurrentTotalDeposits -= count;
			depositPosition[GAMMA_SHARE][_index] = depositPosition[GAMMA_SHARE][gammaDepositCounter - 1];
			delete depositPosition[GAMMA_SHARE][gammaDepositCounter-- - 1];
			return GAMMA_SHARE * count;
		}
	}

	/**
	 * @notice
	 * Internal function that deposits NFTs for a user
	 * @param _nft Contract address of the nft
	 * @param _tokenIds Array of token IDs
	 * @param _user User to whom attribute the NFTs
	 */
	function _depositNfts(IERC721Enumerable _nft, uint256[] calldata _tokenIds, address _user) internal {
		uint256 poolId = _nft == ALPHA ? 1 : (_nft == BETA ? 2 : 3);
		for(uint256 i = 0; i < _tokenIds.length; i++) {
			IApeStaking.Position memory pos = APE_STAKING.nftPosition(poolId, _tokenIds[i]);
			require (pos.stakedAmount == 0, "ApeMatcher: NFT already commited");
			require(_nft.ownerOf(_tokenIds[i]) == _user, "ApeMatcher: !owner");
			// EmperorTomatoKetchup, you can't use your #0
			if (_nft == GAMMA && _tokenIds[i] == 0) revert();
			assetToUser[address(_nft)][_tokenIds[i]] = _user;
			_nft.transferFrom(_user, address(this), _tokenIds[i]);
		}
	}

	/**
	 * @notice
	 * Internal function that withdraws NFTs for a user
	 * @param _nft Contract address of the nft
	 * @param _tokenIds Array of token IDs
	 * @param _user User to whom withdraw the NFTs
	 */
	function _withdrawNfts(IERC721Enumerable _nft, uint256[] calldata _tokenIds, address _user) internal {
		for (uint256 i = 0; i < _tokenIds.length; i++) {
			require(assetToUser[address(_nft)][_tokenIds[i]] == _user, "ApeMatcher: !owner");
			delete assetToUser[address(_nft)][_tokenIds[i]];
			_nft.transferFrom(address(this), _user, _tokenIds[i]);
		}
	}

	function _handleFee(uint256 _fee) internal {
		if (_fee > 0)
			fee += _fee;
	}

	function _min(uint256 _a, uint256 _b) internal pure returns (uint256) {
		return _a > _b ? _b : _a;
	}

	/**
	 * @notice
	 * Internal function that fetches the split ratio of a given claim (primary or dog)
	 * @param _claimGamma Boolean that indicates if this is a dog claim or not
	 * @param _weight Value holding the split ratios
	 */
	function _getWeights(bool _claimGamma, uint256 _weight) internal pure returns(uint128[4] memory _weights) {
		uint256 dogMask = (2 << 128) - 1;
		uint256 _uint32Mask = (2 << 32) - 1;
		if (_claimGamma)
			_weight &= dogMask;
		else
			_weight >>= 128;
		_weights[0] = uint128((_weight >> (32 * 3)) & _uint32Mask);
		_weights[1] = uint128((_weight >> (32 * 2)) & _uint32Mask);
		_weights[2] = uint128((_weight >> (32 * 1)) & _uint32Mask);
		_weights[3] = uint128((_weight >> (32 * 0)) & _uint32Mask);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "IERC721.sol";

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
    address internal _owner;

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

pragma solidity ^0.8.17;

import "Ownable.sol";


contract Pausable is Ownable {
	bool public paused;

	modifier notPaused() {
		require(!paused, "Pausable: Contract is paused");
		_;
	}

	function pause() external onlyOwner {
		paused = true;
	}

	function unpause() external onlyOwner {
		paused = false;
	}
}

pragma solidity ^0.8.17;

interface IApeMatcher {
	struct GreatMatch {
		bool	active;	
		uint8	primary;			// alpha:1/beta:2
		uint32	start;				// time of activation
		uint96	ids;				// right most 48 bits => primary | left most 48 bits => doggo
		address	primaryOwner;
		address	primaryTokensOwner;	// owner of ape tokens attributed to primary
		address doggoOwner;
		address	doggoTokensOwner;	// owner of ape tokens attributed to doggo
	}

	struct DepositPosition {
		uint32 count;
		address depositor;
	}

	function depositApeTokenForUser(uint32[3] calldata _depositAmounts, address _user) external;
}

pragma solidity ^0.8.17;

import "IApeMatcher.sol";

interface ISmoothOperator {
	function commitNFTs(address _primary, uint256 _tokenId, uint256 _gammaId) external;

	function uncommitNFTs(IApeMatcher.GreatMatch calldata _match, address _caller) external returns(uint256, uint256);

	function claim(address _primary, uint256 _tokenId, uint256 _gammaId, uint256 _claimSetup) external returns(uint256 total, uint256 totalGamma);

	function swapPrimaryNft(
		address _primary,
		uint256 _in,
		uint256 _out,
		address _receiver,
		uint256 _gammaId) external returns(uint256 totalGamma, uint256 totalPrimary);

		function swapDoggoNft(
		address _primary,
		uint256 _primaryId,
		uint256 _in,
		uint256 _out,
		address _receiver) external returns(uint256 totalGamma);

	function bindDoggoToExistingPrimary(address _primary, uint256 _tokenId, uint256 _gammaId) external;
	
	function unbindDoggoFromExistingPrimary(
		address _primary,
		uint256 _tokenId,
		uint256 _gammaId,
		address _receiver,
		address _tokenOwner,
		address _caller) external returns(uint256 totalGamma);

	
}

pragma solidity ^0.8.17;

interface IApeStaking {
    /// @notice State for ApeCoin, BAYC, MAYC, and Pair Pools
    struct Pool {
        uint48 lastRewardedTimestampHour;
        uint16 lastRewardsRangeIndex;
        uint96 stakedAmount;
        uint96 accumulatedRewardsPerShare;
        TimeRange[] timeRanges;
    }

    /// @notice Pool rules valid for a given duration of time.
    /// @dev All TimeRange timestamp values must represent whole hours
    struct TimeRange {
        uint48 startTimestampHour;
        uint48 endTimestampHour;
        uint96 rewardsPerHour;
        uint96 capPerPosition;
    }

    /// @dev Convenience struct for front-end applications
    struct PoolUI {
        uint256 poolId;
        uint256 stakedAmount;
        TimeRange currentTimeRange;
    }

    /// @dev Per address amount and reward tracking
    struct Position {
        uint256 stakedAmount;
        int256 rewardsDebt;
    }
    
    /// @dev Struct for depositing and withdrawing from the BAYC and MAYC NFT pools
    struct SingleNft {
        uint32 tokenId;
        uint224 amount;
    }
    /// @dev Struct for depositing from the BAKC (Pair) pool
    struct PairNftDepositWithAmount {
        uint32 mainTokenId;
        uint32 bakcTokenId;
        uint184 amount;
    }
    /// @dev Struct for withdrawing from the BAKC (Pair) pool
    struct PairNftWithdrawWithAmount {
        uint32 mainTokenId;
        uint32 bakcTokenId;
        uint184 amount;
        bool isUncommit;
    }
    /// @dev Struct for claiming from an NFT pool
    struct PairNft {
        uint128 mainTokenId;
        uint128 bakcTokenId;
    }
    /// @dev NFT paired status.  Can be used bi-directionally (BAYC/MAYC -> BAKC) or (BAKC -> BAYC/MAYC)
    struct PairingStatus {
        uint248 tokenId;
        bool isPaired;
    }

    // @dev UI focused payload
    struct DashboardStake {
        uint256 poolId;
        uint256 tokenId;
        uint256 deposited;
        uint256 unclaimed;
        uint256 rewards24hr;
        DashboardPair pair;
    }
    /// @dev Sub struct for DashboardStake
    struct DashboardPair {
        uint256 mainTokenId;
        uint256 mainTypePoolId;
    }

    function nftPosition(uint256, uint256) external view returns(Position memory);

	function depositApeCoin(uint256 _amount, address _recipient) external;
	function depositSelfApeCoin(uint256 _amount) external;

    function claimApeCoin(address _recipient) external;
	function claimSelfApeCoin() external;
    function withdrawApeCoin(uint256 _amount, address _recipient) external;


	function depositBAYC(SingleNft[] calldata _nfts) external;
	function depositMAYC(SingleNft[] calldata _nfts) external;
	function depositBAKC(PairNftDepositWithAmount[] calldata _baycPairs, PairNftDepositWithAmount[] calldata _maycPairs) external;

	function claimBAYC(uint256[] calldata _nfts, address _recipient) external;
	function claimMAYC(uint256[] calldata _nfts, address _recipient) external;
	function claimBAKC(PairNft[] calldata _baycPairs, PairNft[] calldata _maycPairs, address _recipient) external;

	function withdrawBAYC(SingleNft[] calldata _nfts, address _recipient) external;
	function withdrawMAYC(SingleNft[] calldata _nfts, address _recipient) external;
	function withdrawBAKC(PairNftWithdrawWithAmount[] calldata _baycPairs, PairNftWithdrawWithAmount[] calldata _maycPairs) external;

    function pendingRewards(uint256 _poolId, address _address, uint256 _tokenId) external view returns (uint256);
}
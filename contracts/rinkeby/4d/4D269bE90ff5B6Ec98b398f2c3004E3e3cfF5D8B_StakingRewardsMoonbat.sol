// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./openzeppelin/TokensRecoverable.sol";
import "./interfaces/IStrigoi721.sol";
import "./interfaces/IStrigoiGame.sol";

// Staking Pools for MoonBat 
// 40% tokenA boost + 20% Matic boost FIXED
contract StakingRewardsMoonbat is TokensRecoverable, ReentrancyGuard, Pausable  {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    address public rewardsDistribution;
    IERC20 public rewardsToken1;

    IERC20 public stakingToken;
    IERC20 public stakingTokenMultiplier1;

    uint256 public periodFinish;
    
    uint256 public rewardRate1; 

    uint256 public rewardsDuration ;
    uint256 public lastUpdateTime;
    uint256 public rewardPerToken1Stored;

    address public stakingPoolFeeAdd;
    address public devFundAdd;

    uint256 public stakingPoolFeeWithdraw;
    uint256 public devFundFeeWithdraw;

    mapping(address => uint256) public userRewardPerToken1Paid;

    mapping(address => uint256) public rewards1;

    uint256 private _totalSupply;
    uint256 private _totalSupplyMultiplier1; // boost token 1
    uint256 private _totalSupplyMultiplier2; // boost token 2  // MATIC
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _balancesMultiplier1; // boost token 1 => 40% boost possible
    mapping(address => uint256) private _balancesMultiplier2; // boost token 2  // MATIC => 20% boost possible
    
    mapping(address => uint256) public lockingPeriodStaking;
    mapping(address => uint256) public multiplierFactor;
    uint256 public lockTimeStakingToken; 
    uint256 public totalToken1ForReward;
    uint256[4] public multiplierRewardToken1Amt; // 40% boost by Boost Token1
    uint256[2] public multiplierRewardToken2Amt; // 20% boost for Matic

    /* NFT Boosting */
    address public nftContractForBoosts;
    mapping(uint => bool) allowedNftTypes;
    mapping(address=>uint256) public multiplierFactorNFT; // user address => NFT's M.F.
    mapping(address => mapping(uint => uint256)) public boostedByNFT; // user address => NFT Type => total boosts done if boosted by that particular NFT
    // avoids double boost 
    address[] NFTboostedAddresses; // all addresses who boosted by NFT
    mapping(address=>uint256) public totalNFTsBoostedBy; // total NFT boosts done by user
    mapping(uint => uint256) public boostPercentNFT; // nftType => boost percent; set by owner 1*10^17 = 10% boost
    uint[] public nftTypes;
    uint256 public maxNFTsBoosts;

    address public swapContractBoostToken1;
    address public swapContractMatic;
    //address public stakingERC721NFTtoken;
    address public nftContractForStaking;
    address public nftGameContract;
    mapping(uint => bool) public allowedNftClassesForStaking;
    uint[] nftClassesForStaking;
    uint256 public stakingTokenRatePerNFT;
    uint public stakingPoolLevel;

    mapping(address=>uint[]) public stakedNFTs; // user => tokenIds
    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "Caller is not RewardsDistribution contract");
        _;
    }

    constructor(        
        address _rewardsDistribution,
        address _rewardsToken1,
        address _stakingToken,
        address _stakingTokenMultiplier1,
        address _nftContractForStaking,
        uint256 _stakingTokenRatePerNFT,
        address _swapContractBoostToken1,
        address _swapContractMatic,
        address _nftGameContract,
        uint _stakingPoolLevel) {
        
        rewardsToken1 = IERC20(_rewardsToken1);

        stakingToken = IERC20(_stakingToken);
        stakingTokenMultiplier1 = IERC20(_stakingTokenMultiplier1);
        rewardsDistribution = _rewardsDistribution;

        nftContractForStaking = _nftContractForStaking;
        nftGameContract = _nftGameContract;
        stakingTokenRatePerNFT = _stakingTokenRatePerNFT;

        periodFinish = 0;
        rewardRate1 = 0;
        totalToken1ForReward=0;
        rewardsDuration = 90 days; 
        stakingPoolLevel = _stakingPoolLevel;

        // boost token 1 => 40% boost possible
        // boost token 2  // MATIC => 20% boost possible
    
        multiplierRewardToken1Amt = [200 ether, 400 ether, 600 ether, 800 ether];
        multiplierRewardToken2Amt = [20 ether, 50 ether]; // MATIC

        stakingPoolFeeAdd = 0x66e11Dc99B8f8e350e30d4Ec3EA480EC01D7a360;
        devFundAdd = 0xc840AcDf17949a7Ae56641aa88F72148D7B43b72;

        swapContractBoostToken1 = _swapContractBoostToken1;
        swapContractMatic = _swapContractMatic;
        
        stakingPoolFeeWithdraw = 0; 
        devFundFeeWithdraw = 10000; 

        lockTimeStakingToken = 40 days;
    }

    function setRewardsDistribution(address _rewardsDistribution) external onlyOwner {
        rewardsDistribution = _rewardsDistribution;
    }
   
    /* ========== VIEWS ========== */
    
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function totalSupplyMultiplier() external view returns (uint256,uint256) {
        return (_totalSupplyMultiplier1,_totalSupplyMultiplier2);
    }

    function balanceOfMultiplier(address account) external view returns (uint256,uint256) {
        return (_balancesMultiplier1[account],_balancesMultiplier2[account]);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken1() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerToken1Stored;
        }
        return
            rewardPerToken1Stored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate1).mul(1e18).div(_totalSupply)
            );
    }
      
    // divide by 10^6 and add decimals => 6 d.p.
    function getMultiplyingFactor(address account) public view returns (uint256) {
        if (multiplierFactor[account] == 0 && multiplierFactorNFT[account] == 0) {
            return 1000000;
        }
        uint256 MFwei = multiplierFactor[account].add(multiplierFactorNFT[account]);
        if(multiplierFactor[account]==0)
            MFwei = MFwei.add(1e18);
        return MFwei.div(1e12);
    }

    function getMultiplyingFactorWei(address account) public view returns (uint256) {
        if (multiplierFactor[account] == 0 && multiplierFactorNFT[account] == 0) {
            return 1e18;
        }
        uint256 MFwei = multiplierFactor[account].add(multiplierFactorNFT[account]);
        if(multiplierFactor[account]==0)
            MFwei = MFwei.add(1e18);
        return MFwei;
    }

    function earnedtokenRewardToken1(address account) public view returns (uint256) {
        return _balances[account].mul(rewardPerToken1().sub(userRewardPerToken1Paid[account]))
        .div(1e18).add(rewards1[account]);
    }  
    
    function totalEarnedRewardToken1(address account) public view returns (uint256) {
        return (_balances[account].mul(rewardPerToken1().sub(userRewardPerToken1Paid[account]))
        .div(1e18).add(rewards1[account])).mul(getMultiplyingFactorWei(account)).div(1e18);
    }
    
    function getReward1ForDuration() external view returns (uint256) {
        return rewardRate1.mul(rewardsDuration);
    }

    function getRewardToken1APY() external view returns (uint256) {
        //3153600000 = 365*24*60*60
        if(block.timestamp>periodFinish) return 0;
        uint256 rewardForYear = rewardRate1.mul(31536000); 
        if(_totalSupply<=1e18) return rewardForYear.div(1e10);
        return rewardForYear.mul(1e8).div(_totalSupply); // put 6 dp
    }

    function getRewardToken1WPY() external view returns (uint256) {
        //60480000 = 7*24*60*60
        if(block.timestamp>periodFinish) return 0;
        uint256 rewardForWeek = rewardRate1.mul(604800); 
        if(_totalSupply<=1e18) return rewardForWeek.div(1e10);
        return rewardForWeek.mul(1e8).div(_totalSupply); // put 6 dp
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function allowedNftClassForStaking(uint[] calldata _nftType, uint[] calldata _isAllowed) external onlyOwner {
        for(uint x = 0; x < _nftType.length; x++) {
            allowedNftClassesForStaking[_nftType[x]] = _isAllowed[x] == 1;
        }
    }

    function setNftContractForBoosts(address _contract) external onlyOwner {
        require(_contract != address(0), "_contract = 0");
        nftContractForBoosts = _contract;
    }

    function setStakingPoolLevel(uint level_) external onlyOwner {
        require(level_ > 0, "level_ = 0");
        stakingPoolLevel = level_;
    }

    function setNftGameContract(address nftGameContract_) external onlyOwner {
        require(nftGameContract_ != address(0), "nftGameContract_ = 0");
        nftGameContract = nftGameContract_;
    }

    // feeAmount = 100 => 1%
    function setTransferParams(address _stakingPoolFeeAdd, address _devFundAdd, uint256 _stakingPoolFeeStaking, uint256 _devFundFeeStaking, 
        address _swapContractBoostToken1, address _swapContractMatic) external onlyOwner{

        stakingPoolFeeAdd = _stakingPoolFeeAdd;
        devFundAdd = _devFundAdd;
        stakingPoolFeeWithdraw = _stakingPoolFeeStaking;
        devFundFeeWithdraw = _devFundFeeStaking;
        swapContractBoostToken1 = _swapContractBoostToken1;
        swapContractMatic = _swapContractMatic;
    }

    function setStakingTokenNFTRate(uint256 _rate) external onlyOwner{
        stakingTokenRatePerNFT = _rate;
    }

    function setTimelockStakingToken(uint256 lockTime) external onlyOwner{
         lockTimeStakingToken = lockTime;   
    }
    
    function pause() external onlyOwner{
        _pause();
    }

    function unpause() external onlyOwner{
        _unpause();
    }

// 1 erc721 as well in some ratio
    function stake(uint numNfts) external nonReentrant whenNotPaused updateReward(msg.sender) {
        require(numNfts > 0, "Cannot stake 0 NFTs");
        
        uint256 amount = stakingTokenRatePerNFT.mul(numNfts);
        require(amount > 0, "Cannot stake 0");

        uint userNftCount = IStrigoiGame(nftGameContract).getNftTypeAndLevelCountForUser(msg.sender, 1, stakingPoolLevel) +
            IStrigoiGame(nftGameContract).getNftTypeAndLevelCountForUser(msg.sender, 2, stakingPoolLevel);
        require(userNftCount >= numNfts, "User does not have enough Strigoi and/or Familiars");

        lockingPeriodStaking[msg.sender] = block.timestamp.add(lockTimeStakingToken);

        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        // transfer ERC721 to contract as it is withdrawable
        uint bal = IStrigoi721(nftContractForStaking).balanceOf(msg.sender);
        uint[] memory tokenIds;
        for (uint x = bal - 1; x >= 0; x--) {
            if (tokenIds.length >= numNfts) break;
            uint id = IStrigoi721(nftContractForStaking).tokenOfOwnerByIndex(msg.sender, x);
            //only accept strigoi and familiars
            if (IStrigoiGame(nftGameContract).isNftClassAndLevel(id, 1, stakingPoolLevel)
             || IStrigoiGame(nftGameContract).isNftClassAndLevel(id, 2, stakingPoolLevel)) {
                 IERC721(nftContractForStaking).safeTransferFrom(msg.sender, address(this), id);
                 tokenIds[tokenIds.length] = id;
                 stakedNFTs[msg.sender].push(id);
             } 
        }        

        emit Staked(msg.sender, amount, tokenIds);
    }
/*     function stake(uint[] calldata tokenIds) external nonReentrant whenNotPaused updateReward(msg.sender) {
        require(tokenIds.length > 0, "Cannot stake 0 NFTs");
        
        uint256 amount = stakingTokenRatePerNFT.mul(tokenIds.length);
        require(amount > 0, "Cannot stake 0");

        for(uint i = 0; i < tokenIds.length; i++){
            require(allowedNftClassesForStaking[IStrigoi721(nftContractForStaking).getNftClass(tokenIds[i])], "One or more token IDs are not the correct NFT class");
        }        

        lockingPeriodStaking[msg.sender] = block.timestamp.add(lockTimeStakingToken);

        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        // transfer ERC721 to contract as it is withdrawable
        for(uint i = 0; i < tokenIds.length; i++){
            IERC721(nftContractForStaking).safeTransferFrom(msg.sender, address(this), tokenIds[i]);
            stakedNFTs[msg.sender].push(tokenIds[i]);
        }

        emit Staked(msg.sender, amount, tokenIds);
    } */

    function boostByToken1(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Cannot stake 0");
        _totalSupplyMultiplier1 = _totalSupplyMultiplier1.add(amount);
        _balancesMultiplier1[msg.sender] = _balancesMultiplier1[msg.sender].add(amount);
        // send the whole multiplier fee to dev fund address
        stakingTokenMultiplier1.safeTransferFrom(msg.sender, swapContractBoostToken1, amount);
        getTotalMultiplier(msg.sender);
        emit BoostedStakeToken1(msg.sender, amount);
    }

    function boostByMaticToken() external payable nonReentrant whenNotPaused {
        uint256 amount = msg.value;
        require(amount > 0, "Cannot stake 0");

        _totalSupplyMultiplier2 = _totalSupplyMultiplier2.add(amount);
        _balancesMultiplier2[msg.sender] = _balancesMultiplier2[msg.sender].add(amount);

        // send the whole multiplier fee to dev fund address
        (bool success,) = swapContractMatic.call{ value: amount }("");
        require (success, "Transfer failed");
        
        getTotalMultiplier(msg.sender);
        emit BoostedByMatic(msg.sender, amount);
    }

    // _boostPercent = 10000 => 10% => 10^4 * 10^13
    //function addNFTasMultiplier(address _erc721NFTContract, uint256 _boostPercent) external onlyOwner {
    function addNFTTypeasMultiplier(uint _nftType, uint256 _boostPercent) external onlyOwner {        
        require(block.timestamp >= periodFinish, "Cannot set NFT boosts after staking starts");
        require(allowedNftTypes[_nftType] == false,"This NFT is already allowed for boosts");
        allowedNftTypes[_nftType] = true;

        nftTypes.push(_nftType);
        boostPercentNFT[_nftType] = _boostPercent.mul(1e13);
    }

    // if next cycle of staking starts it resets for all users
    function _resetNFTasMultiplierForUser() internal {
        for(uint i=0;i<NFTboostedAddresses.length;i++){
            totalNFTsBoostedBy[NFTboostedAddresses[i]]=0;
            for(uint j = 0; j < nftTypes.length; j++) {
                boostedByNFT[NFTboostedAddresses[i]][nftTypes[j]] = 0;
            }
            multiplierFactorNFT[NFTboostedAddresses[i]] = 0;
        }

        delete NFTboostedAddresses;
    }

    // reset possible after Previous rewards period finishes
    function resetNFTasMultiplier() external onlyOwner {
        require(block.timestamp > periodFinish, "Previous rewards period must be complete before resetting");

        for(uint i=0;i<nftTypes.length;i++){
            boostPercentNFT[nftTypes[i]] = 0;
            allowedNftTypes[nftTypes[i]] = false;
        }

        _resetNFTasMultiplierForUser();
        delete nftTypes;
    }

    // can get total boost possible by user's NFTs
    function getNFTBoostPossibleByAddress(address NFTowner) public view returns(uint256){
        uint256 multiplyFactor = 0;
        for(uint i=0; i < nftTypes.length; i++){
            uint nftType = nftTypes[i];
            if(IStrigoi721(nftContractForBoosts).userHasNftType(NFTowner, nftType)) {
                multiplyFactor = multiplyFactor.add(boostPercentNFT[nftType]);
            }            
        }

        uint256 boostWei= multiplierFactor[NFTowner].add(multiplyFactor);
        return boostWei.div(1e12);
    }

    function setTotalNFTsBoostsPossible(uint256 _tBoosts) external onlyOwner{
        maxNFTsBoosts = _tBoosts;
    }

    // view function 3/10 boosts done => a,b,c NFT
    function getBoostsByUser(address _userAddress) external view returns(uint[] memory, uint256[] memory, uint256, uint256 ){
        uint tBoosts = 0;
        uint[] memory userBoostByNFTs = new uint[](nftTypes.length);
        
        for(uint i = 0; i < nftTypes.length; i++){
            tBoosts = tBoosts.add(boostedByNFT[_userAddress][nftTypes[i]]);
            userBoostByNFTs[i] = boostedByNFT[_userAddress][nftTypes[i]];
        }
        return (nftTypes, userBoostByNFTs, tBoosts, maxNFTsBoosts);
    }

    // approve NFT to contract before you call this function
    function boostByNFT(uint _nftType) public nonReentrant whenNotPaused {    
        require(block.timestamp <= periodFinish, "STAKING_NOT_STARTED");
        require(allowedNftTypes[_nftType], "NFT_NOT_FOR_BOOSTS");
        require(IStrigoi721(nftContractForBoosts).userHasNftType(_msgSender(), _nftType), "NO_NFT_OF_TYPE");
        uint tokenId = IStrigoiGame(nftGameContract).getNftTokenIdForUserForNftType(_msgSender(), _nftType);
        uint256 multiplyFactor = boostPercentNFT[_nftType];

        if(totalNFTsBoostedBy[msg.sender] == 0){
            NFTboostedAddresses.push(msg.sender);
        }

        // CHECK already boosted by same NFT contract??
        require(boostedByNFT[msg.sender][_nftType] < maxNFTsBoosts, "Already boosted by this NFT");
        multiplierFactorNFT[msg.sender] += multiplyFactor;
        IERC721(nftContractForBoosts).safeTransferFrom(msg.sender, devFundAdd, tokenId);

        totalNFTsBoostedBy[msg.sender] += 1;
        boostedByNFT[msg.sender][_nftType] += 1;
        require(totalNFTsBoostedBy[msg.sender] <= nftTypes.length, "Total boosts cannot be more than MAX NfT boosts available");

        emit NFTMultiplier(msg.sender, _nftType, tokenId);
    }

    function withdrawAllERC721(address _stakerAddress) internal {
        uint[] memory tokenIds =  stakedNFTs[_stakerAddress];
        for(uint i=0;i<tokenIds.length;i++){
            IERC721(nftContractForStaking).safeTransferFrom(address(this), _stakerAddress, tokenIds[i]);
        }
        uint[] memory auxArr;
        stakedNFTs[_stakerAddress] = auxArr;
    }
    
    function withdraw(uint256 amount) internal nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        require(amount<=_balances[msg.sender],"Staked amount is lesser");

        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);

        if(block.timestamp < lockingPeriodStaking[msg.sender]){
            uint256 devFee = amount.mul(devFundFeeWithdraw).div(100000); // feeWithdraw = 100000 = 100%
            stakingToken.safeTransfer(devFundAdd, devFee);
            uint256 stakingFee = amount.mul(stakingPoolFeeWithdraw).div(100000); // feeWithdraw = 100000 = 100%
            stakingToken.safeTransfer(stakingPoolFeeAdd, stakingFee);
            uint256 remAmount = amount.sub(devFee).sub(stakingFee);
            stakingToken.safeTransfer(msg.sender, remAmount);
        }
        else    
            stakingToken.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public nonReentrant whenNotPaused updateReward(msg.sender) {
        uint256 reward1 = rewards1[msg.sender].mul(getMultiplyingFactorWei(msg.sender)).div(1e18);
        
        if (reward1 > 0) {
            rewards1[msg.sender] = 0;
            rewardsToken1.safeTransfer(msg.sender, reward1);
            totalToken1ForReward=totalToken1ForReward.sub(reward1);
        }       

        emit RewardPaid(msg.sender, reward1);
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
        withdrawAllERC721(msg.sender);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */
    // reward 1  => DMagic
    function notifyRewardAmount(uint256 rewardToken1Amount) external onlyRewardsDistribution updateReward(address(0)) {

        totalToken1ForReward = totalToken1ForReward.add(rewardToken1Amount);

        // using x% of reward amount, remaining locked for multipliers 
        // x * 1.3 (max M.F.) = 100
        uint256 multiplyFactor = 1e18 + 3e17; // 130%
        for(uint i=0;i<nftTypes.length;i++){
                multiplyFactor = multiplyFactor.add(boostPercentNFT[nftTypes[i]]);
        }

        uint256 denominatorForMF = 1e20;

        // reward * 100 / 130 ~ 76% (if NO NFT boost)
        uint256 reward1Available = rewardToken1Amount.mul(denominatorForMF).div(multiplyFactor).div(100); 
        // uint256 reward2Available = rewardToken2.mul(denominatorForMF).div(multiplyFactor).div(100);

        if (block.timestamp >= periodFinish) {
            rewardRate1 = reward1Available.div(rewardsDuration);
            _resetNFTasMultiplierForUser();
        } 
        else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover1 = remaining.mul(rewardRate1);
            rewardRate1 = reward1Available.add(leftover1).div(rewardsDuration);
        }
        
        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance1 = rewardsToken1.balanceOf(address(this));
        require(rewardRate1 <= balance1.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);

        emit RewardAdded(reward1Available);
    }

    // only left over reward provided by owner can be withdrawn after reward period finishes
    function withdrawNotified() external onlyOwner {
        require(block.timestamp >= periodFinish, 
            "Cannot withdraw before reward time finishes"
        );
        
        address owner = Ownable.owner();
        // only left over reward amount will be left
        IERC20(rewardsToken1).safeTransfer(owner, totalToken1ForReward);
        
        emit Recovered(address(rewardsToken1), totalToken1ForReward);
        
        totalToken1ForReward=0;
    }

    // only reward provided by owner can be withdrawn in emergency, user stakes are safe
    function withdrawNotifiedEmergency(uint256 reward1Amount) external onlyOwner {

        require(reward1Amount<=totalToken1ForReward,"Total reward left to distribute is lesser");

        address owner = Ownable.owner();
        // only left over reward amount will be left
        IERC20(rewardsToken1).safeTransfer(owner, reward1Amount);
        
        emit Recovered(address(rewardsToken1), reward1Amount);
        
        totalToken1ForReward=totalToken1ForReward.sub(reward1Amount);

    }
    
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        // Cannot recover the staking token or the rewards token
        require(
            tokenAddress != address(stakingToken) && tokenAddress != address(stakingTokenMultiplier1) && tokenAddress != address(rewardsToken1),
            "Cannot withdraw the staking or rewards tokens"
        );
        address owner = Ownable.owner();
        IERC20(tokenAddress).safeTransfer(owner, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    function setOnMultiplierAmounts1(uint256[4] calldata _values) external onlyOwner {
        multiplierRewardToken1Amt = _values;
    }

    function setOnMultiplierAmounts2(uint256[2] calldata _values) external onlyOwner {
        multiplierRewardToken2Amt = _values;
    }

    // view function for input as multiplier token amount
    // returns Multiply Factor in 6 decimal place
    // _amount => Multiplier token 1 , _amount2 => Multiplier token 2 (Matic)
    function getMultiplierForAmount(uint256 _amount, uint256 _amount2) public view returns(uint256) {
        uint256 multiplier=0;        
        uint256 parts=0;
        uint256 totalParts=1;

        if(_amount>=multiplierRewardToken1Amt[0] && _amount < multiplierRewardToken1Amt[1]) {
            totalParts = multiplierRewardToken1Amt[1].sub(multiplierRewardToken1Amt[0]);
            parts = _amount.sub(multiplierRewardToken1Amt[0]); 
            multiplier = parts.mul(1e17).div(totalParts).add(10 ** 17); 
        }
        else if(_amount>=multiplierRewardToken1Amt[1] && _amount < multiplierRewardToken1Amt[2]) {
            totalParts = multiplierRewardToken1Amt[2].sub(multiplierRewardToken1Amt[1]);
            parts = _amount.sub(multiplierRewardToken1Amt[1]); 
            multiplier = parts.mul(1e17).div(totalParts).add(2 * 10 ** 17); 
        }
        else if(_amount>=multiplierRewardToken1Amt[2] && _amount < multiplierRewardToken1Amt[3]) {
            totalParts = multiplierRewardToken1Amt[3].sub(multiplierRewardToken1Amt[2]);
            parts = _amount.sub(multiplierRewardToken1Amt[2]); 
            multiplier = parts.mul(1e17).div(totalParts).add(3 * 10 ** 17); 
        }
        else if(_amount>=multiplierRewardToken1Amt[3]){
            multiplier = 4 * 10 ** 17;
        }

        uint256 multiplyFactor1 = multiplier.add(1e18);
    
        /* ========== Boost token 2 ========== */

        uint256 multiplier2=0;        
        uint256 parts2=0;
        uint256 totalParts2=1;

        if(_amount2>=multiplierRewardToken2Amt[0] && _amount2 < multiplierRewardToken2Amt[1]) {
            totalParts2 = multiplierRewardToken2Amt[1].sub(multiplierRewardToken2Amt[0]);
            parts2 = _amount2.sub(multiplierRewardToken2Amt[0]); 
            multiplier2 = parts2.mul(1e17).div(totalParts2).add(10 ** 17); 
        }
        else if(_amount2>=multiplierRewardToken2Amt[1]){
            multiplier2 = 2 * 10 ** 17;
        }

        uint256 multiplyFactor2 = multiplier2.add(1e18);


        uint256 multiplyFactor=multiplyFactor1.add(multiplyFactor2);
        return multiplyFactor.div(1e12);
    }

    function getTotalMultiplier(address account) internal{

        /* ========== Boost token 1 ========== */

        uint256 multiplier=0;        
        uint256 parts=0;
        uint256 totalParts=1;

        uint256 _amount = _balancesMultiplier1[account];

        if(_amount>=multiplierRewardToken1Amt[0] && _amount < multiplierRewardToken1Amt[1]) {
            totalParts = multiplierRewardToken1Amt[1].sub(multiplierRewardToken1Amt[0]);
            parts = _amount.sub(multiplierRewardToken1Amt[0]); 
            multiplier = parts.mul(1e17).div(totalParts).add(10 ** 17); 
        }
        else if(_amount>=multiplierRewardToken1Amt[1] && _amount < multiplierRewardToken1Amt[2]) {
            totalParts = multiplierRewardToken1Amt[2].sub(multiplierRewardToken1Amt[1]);
            parts = _amount.sub(multiplierRewardToken1Amt[1]); 
            multiplier = parts.mul(1e17).div(totalParts).add(2 * 10 ** 17); 
        }
        else if(_amount>=multiplierRewardToken1Amt[2] && _amount < multiplierRewardToken1Amt[3]) {
            totalParts = multiplierRewardToken1Amt[3].sub(multiplierRewardToken1Amt[2]);
            parts = _amount.sub(multiplierRewardToken1Amt[2]); 
            multiplier = parts.mul(1e17).div(totalParts).add(3 * 10 ** 17); 
        }
        else if(_amount>=multiplierRewardToken1Amt[3]){
            multiplier = 4 * 10 ** 17;
        }

        uint256 multiplyFactor = multiplier.add(1e18);
    
        /* ========== Boost token 2 ========== */

        uint256 multiplier2=0;        
        uint256 parts2=0;
        uint256 totalParts2=1;

        uint256 _amount2 = _balancesMultiplier2[account];

        if(_amount2>=multiplierRewardToken2Amt[0] && _amount2 < multiplierRewardToken2Amt[1]) {
            totalParts2 = multiplierRewardToken2Amt[1].sub(multiplierRewardToken2Amt[0]);
            parts2 = _amount2.sub(multiplierRewardToken2Amt[0]); 
            multiplier2 = parts2.mul(1e17).div(totalParts2).add(10 ** 17); 
        }
        else if(_amount2>=multiplierRewardToken2Amt[1]){
            multiplier2 = 2 * 10 ** 17;
        }

        uint256 multiplyFactor2 = multiplier2.add(1e18);


        multiplierFactor[msg.sender]=multiplyFactor.add(multiplyFactor2);
        
    }
    
    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerToken1Stored = rewardPerToken1();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards1[account] = earnedtokenRewardToken1(account);
            userRewardPerToken1Paid[account] = rewardPerToken1Stored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward1);
    event Staked(address indexed user, uint256 amount, uint[] ids);
    event BoostedStakeToken1(address indexed user, uint256 amount);
    event BoostedByMatic(address indexed user, uint256 amount);
    
    event NFTMultiplier(address indexed user, uint nftType, uint256 tokenId);
    
    event Withdrawn(address indexed user, uint256 amount);
    event WithdrawnMultiplier(address indexed user, uint256 amount);

    event RewardPaid(address indexed user, uint256 reward1);

    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
    

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

abstract contract TokensRecoverable is Ownable
{
    using SafeERC20 for IERC20;

    function recoverTokens(IERC20 token) public onlyOwner() 
    {
        require (canRecoverTokens(token));    
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    function recoverETH(uint256 amount) public onlyOwner() 
    {        
        payable(msg.sender).transfer(amount);
    }

    function recoverERC1155(IERC1155 token, uint256 tokenId, uint256 amount) public onlyOwner() 
    {        
        token.safeTransferFrom(address(this),msg.sender,tokenId,amount,"0x");
    }

    function recoverERC721(IERC721 token, uint256 tokenId) public onlyOwner() 
    {        
        token.safeTransferFrom(address(this),msg.sender,tokenId);
    }

    function canRecoverTokens(IERC20 token) internal virtual view returns (bool) 
    { 
        return address(token) != address(this); 
    }

}

// SPDX-License-Identifier: AGPL-1.0
pragma solidity 0.8.11;

interface IStrigoi721 {

    struct NftInfo {
        uint256 propertyNum1;
        uint256 propertyNum2;
        uint256 propertyNum3;
        string propertyString1;
        string propertyString2;
        string uri;
    }

    function addNftNumericInfo(uint256 _id, uint256 _num, uint256 _value) external;
    function subtractNftNumericInfo(uint256 _id, uint256 _num, uint256 _value) external;
    function getNftInfo(uint id_) external view returns(NftInfo memory);
    function ownerOf(uint256 tokenId) external returns (address);    
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function getNftType(uint id) external returns(uint);
    function getNftClass(uint id) external returns(uint);
    function isApprovedForAll(address owner, address operator) external returns (bool);
    function getNftTypeCountForUser(address user, uint nftType) external view returns(uint);
    function userHasNftType(address user, uint nftType) external view returns(bool);
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-1.0
pragma solidity 0.8.11;

interface IStrigoiGame {

    function getNftTypeAndLevelCountForUser(address user, uint nftClass, uint level) external view returns(uint);
    function isNftClassAndLevel(uint id, uint nftClass, uint level) external returns(bool);
    function getNftTokenIdForUserForNftType(address user, uint nftType) external returns(uint);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}
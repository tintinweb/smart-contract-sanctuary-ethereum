// // SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
// import "hardhat/console.sol";

import "./LaunchPadLib.sol";
import "./LaunchPadLib.sol";

interface IRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
    function WAVAX() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);
}

contract Presale {

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private whiteListedUsers;

    IRouter public uniswapV2Router02;
    bool private isJoeRouter;

    LaunchPadLib.TokenInfo public tokenInfo;
    LaunchPadLib.PresaleInfo public presaleInfo;

    LaunchPadLib.ParticipationCriteria public participationCriteria;
    LaunchPadLib.PresaleTimes public presaleTimes;

    LaunchPadLib.PresaleCounts public presaleCounts;
    LaunchPadLib.GeneralInfo public generalInfo;

    LaunchPadLib.ContributorsVesting public contributorsVesting;
    LaunchPadLib.TeamVesting public teamVesting;

    mapping(address => Participant) public participant;
    struct Participant {
        uint256 value;
        uint256 tokens;
        uint256 unclaimed;
    }

    mapping (uint => ContributorsVestingRecord) public contributorVestingRecord;
    uint public contributorCycles = 0;
    uint public finalizingTime;

    enum ReleaseStatus {UNRELEASED,RELEASED}
    mapping(uint => mapping(address => ReleaseStatus)) internal releaseStatus;
    struct ContributorsVestingRecord {
        uint cycle;
        uint releaseTime;
        uint tokensPC;
        uint percentageToRelease;
        ReleaseStatus releaseStatus;
    }

    mapping (uint => TeamVestingRecord) public teamVestingRecord;
    uint public teamVestingCycles = 0;
    struct TeamVestingRecord {
        uint cycle;
        uint releaseTime;
        uint tokensPC;
        uint percentageToRelease;
        ReleaseStatus releaseStatus;
    }

    event ContributionsAdded(address contributor, uint amount, uint requestedTokens);
    event ContributionsRemoved(address contributor, uint amount);
    event Claimed(address contributor, uint value, uint tokens);
    event Finalized(uint8 status, uint finalizedTime);
    event SaleTypeChanged(uint8 _type, address _address, uint minimumTokens);

    modifier isPresaleActive() {
        require (block.timestamp >= presaleTimes.startedAt && block.timestamp < presaleTimes.expiredAt, "Presale is not active");
        if(presaleInfo.preSaleStatus == LaunchPadLib.PreSaleStatus.PENDING){
            presaleInfo.preSaleStatus = LaunchPadLib.PreSaleStatus.INPROGRESS;
            emit Finalized(uint8(LaunchPadLib.PreSaleStatus.INPROGRESS), 0);

        }
        require(presaleInfo.preSaleStatus == LaunchPadLib.PreSaleStatus.INPROGRESS, "Presale is not in progress");
        _;
    }

    modifier onlyPresaleOwner() {
        require(presaleInfo.presaleOwner == msg.sender, "Ownable: caller is not the owner of this presale");
        _;
    }

    modifier isPresaleEnded(){
        require (
            presaleInfo.preSaleStatus == LaunchPadLib.PreSaleStatus.SUCCEED ||
            presaleInfo.preSaleStatus == LaunchPadLib.PreSaleStatus.FAILED ||
            presaleInfo.preSaleStatus == LaunchPadLib.PreSaleStatus.CANCELED,
            "Presale is not concluded yet"
        );
        _;
    }

    modifier isPresaleNotEnded() {
        require(
            presaleInfo.preSaleStatus == LaunchPadLib.PreSaleStatus.INPROGRESS ||
            presaleInfo.preSaleStatus == LaunchPadLib.PreSaleStatus.PENDING,
            "Presale is not in progress"
        );
        _;
    }

    constructor (
        LaunchPadLib.TokenInfo memory _tokenInfo,
        LaunchPadLib.ParticipationCriteria memory _participationCriteria,
        LaunchPadLib.PresaleTimes memory _presaleTimes,
        LaunchPadLib.ContributorsVesting memory _contributorsVesting,
        LaunchPadLib.TeamVesting memory _teamVesting,
        LaunchPadLib.GeneralInfo memory _generalInfo,
        address _uniswapV2Router02,
        bool _isJoeRouter
    ){
        tokenInfo = _tokenInfo;
        presaleInfo = LaunchPadLib.PresaleInfo(1, msg.sender, LaunchPadLib.PreSaleStatus.PENDING);
        participationCriteria = _participationCriteria;

        presaleTimes = _presaleTimes;
        contributorsVesting = _contributorsVesting;

        teamVesting = _teamVesting;
        generalInfo = _generalInfo;

        uniswapV2Router02 = IRouter(_uniswapV2Router02);
        isJoeRouter = _isJoeRouter;

        if(_contributorsVesting.isEnabled){
            findContributorsVesting(_contributorsVesting);
        }

        if(_teamVesting.isEnabled){
            findTeamVesting(_teamVesting);
        }
    }

    function findContributorsVesting(LaunchPadLib.ContributorsVesting memory _contributorsVesting) internal {
        uint totalTokensPC = 100;
        uint initialReleasePC = _contributorsVesting.firstReleasePC;
        contributorVestingRecord[0] = ContributorsVestingRecord(
            0,
            0,
            totalTokensPC,
            initialReleasePC,
            ReleaseStatus.UNRELEASED
        );

        if(initialReleasePC < totalTokensPC){

            uint remainingTokenPC = totalTokensPC - initialReleasePC;
            contributorCycles = totalTokensPC / _contributorsVesting.eachCyclePC;
            uint assignedTokensPC;

            for(uint i = 1; i <= contributorCycles; i++ ){
                uint cycleReleaseTime = _contributorsVesting.eachCycleDuration * ( i * 1 minutes );
                contributorVestingRecord[i] = ContributorsVestingRecord(
                    i,
                    cycleReleaseTime,
                    remainingTokenPC,
                    _contributorsVesting.eachCyclePC,
                    ReleaseStatus.UNRELEASED
                );
                assignedTokensPC += _contributorsVesting.eachCyclePC;
            }
                // uint difference = totalTokensPC - assignedTokensPC;
                contributorVestingRecord[contributorCycles].percentageToRelease += totalTokensPC - assignedTokensPC;
        }

    }

    function findTeamVesting(LaunchPadLib.TeamVesting memory _teamVesting) internal {

        uint totalLockedTokensPC = 100;
        uint initialReleasePC = _teamVesting.firstReleasePC;
        uint initialReleaseTime = _teamVesting.firstReleaseDelay * 1 minutes;
        teamVestingRecord[0] = TeamVestingRecord(
            0,
            initialReleaseTime,
            totalLockedTokensPC,
            initialReleasePC,
            ReleaseStatus.UNRELEASED
        );


        if(initialReleasePC < totalLockedTokensPC){
            uint remainingTokenPC = totalLockedTokensPC - initialReleasePC;
            teamVestingCycles = totalLockedTokensPC / _teamVesting.eachCyclePC;
            uint assignedTokensPC;

            for(uint i = 1; i <= teamVestingCycles; i++ ){

                uint cycleReleaseTime = initialReleaseTime + _teamVesting.eachCycleDuration * ( i * 1 minutes );
                teamVestingRecord[i] = TeamVestingRecord(
                    i,
                    cycleReleaseTime,
                    remainingTokenPC,
                    _teamVesting.eachCyclePC,
                    ReleaseStatus.UNRELEASED
                );

                assignedTokensPC += _teamVesting.eachCyclePC;
            }

                // uint difference = totalLockedTokensPC - assignedTokensPC;
                teamVestingRecord[teamVestingCycles].percentageToRelease += totalLockedTokensPC - assignedTokensPC;
        }
    }

    function contributeToSale() public payable isPresaleActive {

        uint allowed = participationCriteria.hardCap - presaleCounts.accumulatedBalance;

        Participant memory currentParticipant = participant[msg.sender];
        uint previousContribution =  currentParticipant.value;
        uint contribution = msg.value;

        require(contribution <= allowed && contribution + previousContribution <= participationCriteria.maxContribution , "contribution is not valid");

        if(currentParticipant.tokens == 0) {
            require(contribution >= (participationCriteria.minContribution), "too low contribution");
            presaleCounts.contributors++;
        }

        if(participationCriteria.presaleType == LaunchPadLib.PresaleType.WHITELISTED){
            require( isWhiteListed(msg.sender), "Only whitelisted users are allowed to participate");
        }

        if(participationCriteria.presaleType == LaunchPadLib.PresaleType.TOKENHOLDERS){
            require(IERC20(participationCriteria.criteriaToken).balanceOf(msg.sender) >= participationCriteria.minCriteriaTokens, "You don't hold enough criteria tokens");
        }

        uint requestedTokens = (contribution * participationCriteria.presaleRate * 10**tokenInfo.decimals) / 1 ether;

        participant[msg.sender].tokens += requestedTokens;
        participant[msg.sender].unclaimed += requestedTokens;

        participant[msg.sender].value += contribution;
        presaleCounts.accumulatedBalance += contribution;

        emit ContributionsAdded(msg.sender, contribution, requestedTokens);
    }

    function emergencyWithdraw() public {

        require(presaleInfo.preSaleStatus == LaunchPadLib.PreSaleStatus.INPROGRESS, "Presale is not in progress");

        Participant memory currentParticipant = participant[msg.sender];
        require(currentParticipant.value > 0, "Nothing to withdraw");

        uint valueToReturn = (currentParticipant.value * 95) / 100;

        participant[msg.sender].value = 0;
        participant[msg.sender].tokens = 0;
        participant[msg.sender].unclaimed = 0;

        presaleCounts.accumulatedBalance -= currentParticipant.value;
        // presaleCounts.remainingTokensForSale = presaleCounts.remainingTokensForSale + currentParticipant.tokens;

        presaleCounts.contributors--;

        (bool res1,) = payable(msg.sender).call{value: valueToReturn}("");
        require(res1, "cannot refund to contributors");

        emit ContributionsRemoved(msg.sender, currentParticipant.value);

    }

    function finalizePresale() public onlyPresaleOwner isPresaleNotEnded {

        require (
            block.timestamp > presaleTimes.expiredAt ||
            presaleCounts.accumulatedBalance >= participationCriteria.hardCap,
            "Presale is not over yet"
        );


        if( presaleCounts.accumulatedBalance >= participationCriteria.softCap ){

            uint256 totalTokensSold = (presaleCounts.accumulatedBalance * participationCriteria.presaleRate * 10**tokenInfo.decimals) / 1 ether ;

            uint256 tokensToAddLiquidity = (totalTokensSold * participationCriteria.liquidity) / 100;

            uint256 revenueFromPresale = presaleCounts.accumulatedBalance;
            uint256 poolShareBNB = (revenueFromPresale * participationCriteria.liquidity) / 100;
            uint256 ownersShareBNB = revenueFromPresale - poolShareBNB;

            (bool res1,) = payable(presaleInfo.presaleOwner).call{value: ownersShareBNB}("");
            require(res1, "cannot send devTeamShare");

            IERC20(tokenInfo.tokenAddress).approve(address(uniswapV2Router02), tokensToAddLiquidity);

            if (isJoeRouter) {
                uniswapV2Router02.addLiquidityAVAX{value : poolShareBNB}(
                    tokenInfo.tokenAddress,
                    tokensToAddLiquidity,
                    0,
                    0,
                    address(this),
                    block.timestamp + 60
                );
            }
            else {
                uniswapV2Router02.addLiquidityETH{value : poolShareBNB}(
                    tokenInfo.tokenAddress,
                    tokensToAddLiquidity,
                    0,
                    0,
                    address(this),
                    block.timestamp + 60
                );
            }

            presaleInfo.preSaleStatus = LaunchPadLib.PreSaleStatus.SUCCEED;

            uint extraTokens = IERC20(tokenInfo.tokenAddress).balanceOf(address(this)) - totalTokensSold - teamVesting.vestingTokens*10**tokenInfo.decimals;

            withdrawExtraTokens(extraTokens);
            finalizingTime = block.timestamp;
            emit Finalized(uint8(LaunchPadLib.PreSaleStatus.SUCCEED), finalizingTime);
        }
        else {

            presaleInfo.preSaleStatus = LaunchPadLib.PreSaleStatus.FAILED;
            uint extraTokens = IERC20(tokenInfo.tokenAddress).balanceOf(address(this));

            withdrawExtraTokens(extraTokens);
            emit Finalized(uint8(LaunchPadLib.PreSaleStatus.FAILED), 0);

        }
    }

    function withdrawExtraTokens(uint tokensToReturn) internal {

        if(tokensToReturn > 0){
            if(presaleInfo.preSaleStatus == LaunchPadLib.PreSaleStatus.FAILED || presaleInfo.preSaleStatus == LaunchPadLib.PreSaleStatus.CANCELED){
                bool tokenDistribution = IERC20(tokenInfo.tokenAddress).transfer(presaleInfo.presaleOwner, tokensToReturn);
                assert( tokenDistribution);
            }
            else if(participationCriteria.refundType == LaunchPadLib.RefundType.WITHDRAW ){
                bool tokenDistribution = IERC20(tokenInfo.tokenAddress).transfer(presaleInfo.presaleOwner, tokensToReturn);
                assert( tokenDistribution);
            }
            else{
                bool tokenDistribution = IERC20(tokenInfo.tokenAddress).transfer(0x000000000000000000000000000000000000dEaD , tokensToReturn);
                assert( tokenDistribution );
            }
        }

    }

    function claimTokensOrARefund() public isPresaleEnded {

        Participant memory _participant = participant[msg.sender];
        require(_participant.unclaimed > 0, "Nothing to claim");

        if (presaleInfo.preSaleStatus == LaunchPadLib.PreSaleStatus.SUCCEED) {

            if(!contributorsVesting.isEnabled) {
                participant[msg.sender].unclaimed = 0;
                presaleCounts.claimsCount++;

                require(_participant.tokens > 0, "No tokens to claim");
                bool tokenDistribution = IERC20(tokenInfo.tokenAddress).transfer(msg.sender, _participant.tokens);
                require(tokenDistribution, "Unable to transfer tokens to the participant");

                emit Claimed(msg.sender, 0, _participant.tokens);

            }
            else {

                uint tokensLocked = _participant.tokens;
                uint tokensToRelease;

                for(uint i = 0; i<= contributorCycles; i++){
                    if(
                        block.timestamp >= (finalizingTime + contributorVestingRecord[i].releaseTime) &&
                        releaseStatus[finalizingTime + contributorVestingRecord[i].releaseTime][msg.sender] == ReleaseStatus.UNRELEASED
                        ){
                        tokensToRelease += (tokensLocked * contributorVestingRecord[i].tokensPC * contributorVestingRecord[i].percentageToRelease) / 10000;
                        releaseStatus[finalizingTime + contributorVestingRecord[i].releaseTime][msg.sender] = ReleaseStatus.RELEASED;

                        if(i == contributorCycles) {
                            presaleCounts.claimsCount++;
                        }
                    }
                }

                require(tokensToRelease > 0, "Nothing to unlock");
                participant[msg.sender].unclaimed -= tokensToRelease;

                require(
                    IERC20(tokenInfo.tokenAddress).transfer(msg.sender, tokensToRelease),
                    "Unable to transfer presale tokens to the presale owner"
                    );


                emit Claimed(msg.sender, 0, tokensToRelease);

            }
        }
        else {
            participant[msg.sender].tokens = 0;
            participant[msg.sender].value = 0;
            participant[msg.sender].unclaimed = 0;

            presaleCounts.claimsCount++;

            require(_participant.value > 0, "No amount to refund");
            bool refund = payable(msg.sender).send(_participant.value);
            require(refund, "Unable to refund amount to the participant");

            emit Claimed(msg.sender, _participant.value, 0);

        }

    }

    function changeSaleType(LaunchPadLib.PresaleType _type, address _address, uint minimumTokens) public onlyPresaleOwner {
        if(_type == LaunchPadLib.PresaleType.TOKENHOLDERS) {
            participationCriteria.presaleType = _type;
            participationCriteria.criteriaToken = _address;
            participationCriteria.minCriteriaTokens = minimumTokens;
        }
        else {
            participationCriteria.presaleType = _type;
        }

        emit SaleTypeChanged(uint8(_type), _address, minimumTokens);

    }

    function unlockTokens() public onlyPresaleOwner isPresaleEnded {

        // require(teamVesting.isEnabled, "No tokens were locked");

        uint tokensLocked = teamVesting.vestingTokens * 10**tokenInfo.decimals;
        uint tokensToRelease;

        for(uint i = 0; i<= teamVestingCycles; i++){
            if(block.timestamp >= finalizingTime + teamVestingRecord[i].releaseTime && teamVestingRecord[i].releaseStatus == ReleaseStatus.UNRELEASED){
                    tokensToRelease += (tokensLocked * teamVestingRecord[i].tokensPC * teamVestingRecord[i].percentageToRelease) / 10000;
                    teamVestingRecord[i].releaseStatus = ReleaseStatus.RELEASED;
            }
        }

        require(tokensToRelease > 0, "Nothing to unlock");
        IERC20(tokenInfo.tokenAddress).transfer(msg.sender, tokensToRelease);

        // require(
        //     IERC20(tokenInfo.tokenAddress).transfer(msg.sender, tokensToRelease),
        //     "Unable to transfer presale tokens to the presale owner"
        //     );

        // emit TokensUnLocked(tokensToRelease);

    }

    function unlockLPTokens() public onlyPresaleOwner isPresaleEnded {

        address factory = IRouter(uniswapV2Router02).factory();
        address WBNBAddr = isJoeRouter
            ? IRouter(uniswapV2Router02).WAVAX()
            : IRouter(uniswapV2Router02).WETH();

        address pairAddress = IUniswapV2Factory(factory).getPair(tokenInfo.tokenAddress, WBNBAddr);
        uint availableLP = IERC20(pairAddress).balanceOf(address(this));

        require(availableLP > 0, "Nothing to claim");
        require(block.timestamp >= finalizingTime + presaleTimes.lpLockupDuration, "Not unlocked yet");

        IERC20(pairAddress).transfer(presaleInfo.presaleOwner, availableLP);
        // bool res = IERC20(pairAddress).transfer(presaleInfo.presaleOwner, availableLP);
        // require(res, "Unable to transfer presale tokens to the presale owner");

        // emit LPTokensUnLocked(availableLP);


    }

    function isWhiteListed(address user) view public returns (bool){
        return EnumerableSet.contains(whiteListedUsers, user);
    }

    function whiteListUsers(address[] memory _addresses) public onlyPresaleOwner {
        for(uint i=0; i < _addresses.length; i++){
                EnumerableSet.add(whiteListedUsers, _addresses[i]);
        }
    }

    function removeWhiteListUsers(address[] memory _addresses) public onlyPresaleOwner {
        for(uint i=0; i < _addresses.length; i++){
            EnumerableSet.remove(whiteListedUsers, _addresses[i]);
        }
    }

    function getWhiteListUsers() public view returns (address[] memory) {
        return EnumerableSet.values(whiteListedUsers);
    }

    function cancelSale() public onlyPresaleOwner isPresaleNotEnded {
        presaleInfo.preSaleStatus = LaunchPadLib.PreSaleStatus.CANCELED;
        uint extraTokens = IERC20(tokenInfo.tokenAddress).balanceOf(address(this));
        withdrawExtraTokens(extraTokens);
        emit Finalized(uint8(LaunchPadLib.PreSaleStatus.CANCELED), 0);
    }

    function getContributorReleaseStatus(uint _time, address _address) public view returns(ReleaseStatus){
        return releaseStatus[_time][_address];
    }

    function updateGeneralInfo(LaunchPadLib.GeneralInfo memory _generalInfo) public onlyPresaleOwner {
        generalInfo = _generalInfo;
    }

    function getTeamVestingSchedule() public view returns(TeamVestingRecord[] memory)  {
        uint _decimals = tokenInfo.decimals;
        uint _tokensLocked = teamVesting.vestingTokens;
        uint _finalizingTime = finalizingTime;
        uint _expiredAt = presaleTimes.expiredAt;

        if (_finalizingTime == 0) {
            _finalizingTime = _expiredAt;
        }

        uint cycles = teamVestingCycles;
        TeamVestingRecord[] memory unlockSchedule = new TeamVestingRecord[](cycles+1);

        for(uint i=0; i <= cycles; i++){
            TeamVestingRecord memory schedule = teamVestingRecord[i];
            unlockSchedule[i].cycle = schedule.cycle;
            unlockSchedule[i].releaseTime = _finalizingTime + schedule.releaseTime;
            unlockSchedule[i].tokensPC = (_tokensLocked * schedule.percentageToRelease * schedule.tokensPC * (10** _decimals)) / 10000;
            unlockSchedule[i].releaseStatus = schedule.releaseStatus;
        }

        return unlockSchedule;

    }

    function getContributorVestingSchedule(address _address) public view returns(ContributorsVestingRecord[] memory)  {
        uint _tokens = participant[_address].tokens;
        uint _finalizingTime = finalizingTime;
        uint _expiredAt = presaleTimes.expiredAt;

        if (_finalizingTime == 0) {
            _finalizingTime = _expiredAt;
        }

        uint cycles = contributorCycles;
        ContributorsVestingRecord[] memory unlockSchedule = new ContributorsVestingRecord[](cycles+1);

        for (uint i=0; i <= cycles; i++){
            ContributorsVestingRecord memory schedule = contributorVestingRecord[i];
            ReleaseStatus _releaseStatus = getContributorReleaseStatus(_finalizingTime + schedule.releaseTime, _address);
            unlockSchedule[i].cycle = schedule.cycle;
            unlockSchedule[i].releaseTime = _finalizingTime + schedule.releaseTime;
            unlockSchedule[i].tokensPC = (_tokens * schedule.percentageToRelease * schedule.tokensPC ) / 10000;
            unlockSchedule[i].releaseStatus = _releaseStatus;
        }

        return unlockSchedule;

    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


library LaunchPadLib {

    enum PresaleType {PUBLIC, WHITELISTED, TOKENHOLDERS}
    enum PreSaleStatus {PENDING, INPROGRESS, SUCCEED, FAILED, CANCELED}
    enum RefundType {BURN, WITHDRAW}

    struct PresaleInfo {
        uint id;
        address presaleOwner;
        PreSaleStatus preSaleStatus;
    }

    struct TokenInfo {
        address tokenAddress;
        uint8 decimals;
    }

    struct ParticipationCriteria {
        PresaleType presaleType;
        address criteriaToken;
        uint256 minCriteriaTokens;
        uint256 presaleRate;
        uint8 liquidity;
        uint256 hardCap;
        uint256 softCap;
        uint256 minContribution;
        uint256 maxContribution;
        RefundType refundType;
    }

    struct PresaleTimes {
        uint256 startedAt;
        uint256 expiredAt;
        uint256 lpLockupDuration;
    }

    struct PresaleCounts {
        uint256 accumulatedBalance;
        uint256 contributors;
        uint256 claimsCount;
    }

    struct ContributorsVesting {
        bool isEnabled;
        uint firstReleasePC;
        uint eachCycleDuration;
        uint8 eachCyclePC;
    }

    struct TeamVesting {
        bool isEnabled;
        uint vestingTokens;
        uint firstReleaseDelay;
        uint firstReleasePC;
        uint eachCycleDuration;
        uint8 eachCyclePC;
    }

    struct GeneralInfo {
        string logoURL;
        string websiteURL;
        string twitterURL;
        string telegramURL;
        string discordURL;
        string description;
    }
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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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
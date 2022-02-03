// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/INftStaking.sol";
import "../libraries/ERC1155721SafeTransferFallback.sol";

contract NftStakingV2 is INftStaking, IERC1155Receiver {
    using ERC1155721SafeTransferFallback for IERC1155721Transferrable;

    struct TokenInfo {
        //NFT MIZIN BİLGİLERİ
        address owner;
        uint64 weight;
        uint16 depositCycle;
        uint16 withdrawCycle;
    }

    // struct StakerInfo{
    //     uint64[] tokenIds;
    //     uint64[] weigth;

    // }

    struct TokenId {
        //BU ID Lİ NFT MİZİN BİLGİLERİ NELER BİLGİSİNİ TUTUYOR
        mapping(uint256 => TokenInfo) tokenInfos;
    }

    struct Snapshot {
        uint128 stake; //TOPLAM STAKE HALİNDE OLAN AĞIRLIK, TIERLARI TOPLAYIP ELDE ETTİĞİN SAYI GİBİ
        uint128 startCycle;
    }

    struct NextClaim {
        uint16 period;
        uint64 globalSnapshotIndex;
        uint64 stakerSnapshotIndex;
    }

    struct ComputedClaim {
        uint16 startPeriod;
        uint16 periods;
        uint256 amount;
    }

    address public admin;
    bool public enabled = true;

    uint256 public totalRewardsPool; //TOPLAM ODUL HAVUZU

    uint256 public startTimestamp; //STAKİNG IN BAŞLANGIÇ ZAMANI

    IERC20 public immutable rewardsTokenContract; //ODUL OLARAK VERILECEK TOKEN KONTRATI
    IERC1155721Transferrable[] public whitelistedNftContract;

    uint32 public immutable cycleLengthInSeconds;
    uint16 public immutable periodLengthInCycles;

    Snapshot[] public globalHistory; //ALINAN SNAPSHOTLARI TUTUYOR

    /* staker => snapshots*/
    mapping(address => Snapshot[]) public stakerHistories; //STAKE EDENLERİN SNAPSHOTLARINI TUTUYOR, 2 BOYUTLU BİR ARRAY
    //A KİŞİSİNİN 0. İNDEXİNDE ŞU SNAPSHOT VAR , 1. İNDEXİNDE ŞU VS. VS.
    /* staker => next claim */
    mapping(address => NextClaim) public nextClaims;

    mapping(address => TokenId) private tokenInfByCollec; //BU KOLEKSİYON ADDRESİNİN BU ID Lİ NFT SİNİN BİLGİLERİ OWNERI KIM TIERI NE YATIRMA ZAMANI VE ÇEKME ZAMANI NE

    mapping(address => uint256) public totalRewards; // A KİŞİSİNİN TOPLAM ODULU
    //mapping(address => StakerInfo) stakerInf;

    /* period => rewardsPerCycle */
    mapping(uint256 => uint256) public rewardsSchedule;

    /* lost cycle => withdrawn? */
    mapping(uint256 => bool) public withdrawnLostCycles;

    mapping(address => uint64) public tiers;

    modifier hasStarted() {
        require(startTimestamp != 0, "Staking not started");
        _;
    }

    modifier hasNotStarted() {
        require(startTimestamp == 0, "Staking has started");
        _;
    }

    modifier isEnabled() {
        require(enabled, "Contract is not enabled");
        _;
    }

    modifier isNotEnabled() {
        require(!enabled, "Contract is enabled");
        _;
    }
    modifier onlyAdmin() {
        require(msg.sender == admin, "only owner");
        _;
    }

    constructor(
        uint32 cycleLengthInSeconds_,
        uint16 periodLengthInCycles_,
        IERC20 rewardsTokenContract_,
        address admin_
    ) {
        require(cycleLengthInSeconds_ >= 1 minutes, "Invalid cycle length");
        require(periodLengthInCycles_ >= 1, "Invalid period length");

        cycleLengthInSeconds = cycleLengthInSeconds_;
        periodLengthInCycles = periodLengthInCycles_;
        rewardsTokenContract = rewardsTokenContract_;
        admin = admin_;
    }

    //Her bir periyodun karşılık geldiği ödüllerin hepsine girilen miktar kadar ekleme yapıyor
    function addRewardsForPeriods(
        uint16 startPeriod,
        uint16 endPeriod,
        uint256 rewardsPerCycle
    ) external onlyAdmin {
        require(startPeriod != 0 && startPeriod <= endPeriod, "NftStaking: wrong period range");

        uint16 periodLengthInCycles_ = periodLengthInCycles;

        if (startTimestamp != 0) {
            require(startPeriod >= _getCurrentPeriod(periodLengthInCycles_), "Already committed schedule");
        }

        for (uint256 period = startPeriod; period <= endPeriod; ++period) {
            /* rewardsSchedule[period] = rewardsSchedule[period].add(rewardsPerCycle); */
            rewardsSchedule[period] = rewardsSchedule[period] + (rewardsPerCycle);
        } //PERIODLARIN ODULLERINI BIZIM GIRDIGIMIZ DEGERLE TOPLUYOR, REWARDU ARTTIRIYOR, 5 PERIYODUNUN ODULU 10 SA
        //+5 EKLERSE 15 ODUL VERIR

        /*  uint256 addedRewards = rewardsPerCycle.mul(periodLengthInCycles_).mul(endPeriod - startPeriod + 1); */
        uint256 addedRewards = rewardsPerCycle * (periodLengthInCycles_) * (endPeriod - startPeriod + 1);

        /*         totalRewardsPool = totalRewardsPool.add(addedRewards);
         */
        totalRewardsPool = totalRewardsPool + (addedRewards);
        require(rewardsTokenContract.transferFrom(msg.sender, address(this), addedRewards), "Failed to add funds"); //toplam ödül havuzuna , ödül tokeninden buraya gönderme ekleme yapıyor hesaplanan ödül kadar

        emit RewardsAdded(startPeriod, endPeriod, rewardsPerCycle);
    }

    function start() public onlyAdmin hasNotStarted {
        startTimestamp = block.timestamp; //Stakingi başlat şimdiki zamanı al ve kayıt et
        /*  startTimestamp = now; */
        emit Started();
    }

    function disable() public onlyAdmin {
        enabled = false; //stakingi pasifleştir
        emit Disabled();
    }

    function withdrawRewardsPool(uint256 amount) public onlyAdmin isNotEnabled {
        require(rewardsTokenContract.transfer(msg.sender, amount), "Withdraw failed"); //bu kontrattan , msg sendera bu kadar amount gönder
    }

    function withdrawLostCycleRewards(
        address to,
        uint16 cycle,
        int256 globalSnapshotIndex
    ) external onlyAdmin {
        require(to != address(0), "NftStaking: zero address");
        /*   require(cycle < _getCycle(now), "NftStaking: non-past cycle"); */
        require(cycle < _getCycle(block.timestamp), "NftStaking: non-past cycle"); //şimdiki döngü bakacağımız döngüden büyük olmalı
        require(withdrawnLostCycles[cycle] == false, "NftStaking: already withdrawn"); //eğer true olsaydı zaten withdraw edilmiş olurdu
        if (globalSnapshotIndex == -1) {
            require(globalHistory.length == 0 || cycle < globalHistory[0].startCycle, "NftStaking: cycle has snapshot");
        } else if (globalSnapshotIndex >= 0) {
            uint256 snapshotIndex = uint256(globalSnapshotIndex);
            Snapshot memory snapshot = globalHistory[snapshotIndex];
            require(cycle >= snapshot.startCycle, "NftStaking: cycle < snapshot");
            require(
                globalHistory.length == snapshotIndex + 1 || // last snapshot
                    cycle < globalHistory[snapshotIndex + 1].startCycle,
                "NftStaking: cycle > snapshot"
            );
            require(snapshot.stake == 0, "NftStaking: non-lost cycle");
        } else {
            revert("NftStaking: wrong index value");
        }

        uint16 period = _getPeriod(cycle, periodLengthInCycles);
        uint256 cycleRewards = rewardsSchedule[period];
        require(cycleRewards != 0, "NftStaking: rewardless cycle");
        withdrawnLostCycles[cycle] = true;
        rewardsTokenContract.transfer(to, cycleRewards); //bu contrattan to ya  cyclerewardu kadar transfer et
    }

    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256,
        bytes calldata
    ) external virtual override returns (bytes4) {
        address collecAdd;
        for (uint256 i = 0; i < whitelistedNftContract.length; i++) {
            if (address(whitelistedNftContract[i]) == msg.sender) {
                //Ben stake edici olarak contrata emir veriyorum contrat bu nfti buraya gönderiyor, nft contratına göre msg.sender benim
                //ama bu contrata görede kartı gönderen nft contratı olduğu için msg.sender da nft contratı oluyor
                //bu kartı gönderen kontrat adresi kayıtlarımızda var mı
                collecAdd = msg.sender; //varsa gelen adresi al
                _stakeNft(id, from, collecAdd); //bu id li,bu kişili,bu contartı kartı stake et
                //from dediğimizde kimin adına geldi bu contrat,aslında kim gönderdi
                /* return _ERC1155_RECEIVED; */
                return 0xf23a6e61;
            }
        }
        require(false, "Contract not whitelisted");
    }

    //toplu hali
    function onERC1155BatchReceived(
        address,
        address from,
        uint256[] calldata ids,
        uint256[] calldata,
        bytes calldata
    ) external virtual override returns (bytes4) {
        address collecAdd;
        for (uint256 i = 0; i < whitelistedNftContract.length; i++) {
            if (address(whitelistedNftContract[i]) == msg.sender) {
                collecAdd = msg.sender;
                _batchStakeNfts(ids, from, collecAdd);

                /* return _ERC1155_BATCH_RECEIVED; */
                return 0xbc197c81;
            }
        }
        require(false, "Contract not whitelisted");
    }

    //BU ADRESLİ BU ID LI NFT YI GERİ ALMAK İSTİYORUM
    function unstakeNft(uint256 tokenId, address collecAdd) external virtual {
        TokenInfo memory tokenInfo = tokenInfByCollec[collecAdd].tokenInfos[tokenId];
        //BU CONTRACT ADRESLİ BU ID LI NFT NIN SAHİBİ,TIERI, DEPOZİT ZAMANI VE WITDHRAW ZAMANLARINI AL
        require(tokenInfo.owner == msg.sender, "NftStaking: not staked for owner");
        //BU FONKSIYONU ÇAĞIRAN KİŞİ, BU NFT NIN SAHİBİ OLMALI

        /* uint16 currentCycle = _getCycle(now); */
        uint16 currentCycle = _getCycle(block.timestamp); //BAŞLANGIÇTAN ŞU ANA KADAR GEÇEN SÜREYİ AL
        uint64 weight = tokenInfo.weight; // TOKENİN AĞIRLIĞINI YANİ ÇARPANINI YANİ TIERINI YANİ ENDERLİĞİNİ AL

        if (enabled) {
            // ensure that at least an entire cycle has elapsed before unstaking the token to avoid
            // an exploit where a full cycle would be claimable if staking just before the end
            // of a cycle and unstaking right after the start of the new cycle
            require(currentCycle - tokenInfo.depositCycle >= 2, "NftStaking: token still frozen");
            //ŞUANA KADAR GEÇEN SÜRE İLE NFTNIN STAKE EDİLME ANINDA Kİ FARKA BAK, GEÇEN SÜRE 10 SAATSE
            //KİŞİ 9. SAATTE STAKE ETTİYSE ARADAN GEÇEN SÜRE 1 SAATTİR YANİ 2 DEN KÜÇÜK OLDUĞUNDAN HALA FROZEN HALDEDİR

            /*  _updateHistories(msg.sender, -int128(weight), currentCycle); */
            _updateHistories(msg.sender, -int128(uint128(weight)), currentCycle);

            // clear the token owner to ensure it cannot be unstaked again without being re-staked
            tokenInfo.owner = address(0);

            // set the withdrawal cycle to ensure it cannot be re-staked during the same cycle
            tokenInfo.withdrawCycle = currentCycle; //TOKENIN WITHDRAW EDİLME ZAMANINI ŞİMDİKİ ZAMAN YAP

            tokenInfByCollec[collecAdd].tokenInfos[tokenId] = tokenInfo; //UPDATE EDİLEN BİLGİLERİ
            //ANA KAYITLARIMIZA GİR
        }
        IERC1155721Transferrable _whitelistedNftContract;
        _whitelistedNftContract = IERC1155721Transferrable(collecAdd);

        _whitelistedNftContract.safeTransferFromWithFallback(address(this), msg.sender, tokenId, 1, "");
        emit NftUnstaked(msg.sender, currentCycle, collecAdd, tokenId, weight);
        _onUnstake(msg.sender, weight);
    }

    function batchUnstakeNfts(uint256[] calldata tokenIds, address collecAdd) external {
        uint256 numTokens = tokenIds.length;
        require(numTokens != 0, "NftStaking: no tokens");

        uint16 currentCycle = _getCycle(block.timestamp);
        /* uint16 currentCycle = _getCycle(now); */
        int128 totalUnstakedWeight = 0;
        uint256[] memory values = new uint256[](numTokens);

        uint64 weight;
        for (uint256 index = 0; index < numTokens; ++index) {
            uint256 tokenId = tokenIds[index];

            TokenInfo memory tokenInfo = tokenInfByCollec[collecAdd].tokenInfos[tokenId];

            require(tokenInfo.owner == msg.sender, "NftStaking: not staked for owner");

            if (enabled) {
                // ensure that at least an entire cycle has elapsed before
                // unstaking the token to avoid an exploit where a a fukll cycle
                // would be claimable if staking just before the end of a cycle
                // and unstaking right after the start of the new cycle
                require(currentCycle - tokenInfo.depositCycle >= 2, "NftStaking: token still frozen");

                // clear the token owner to ensure it cannot be unstaked again
                // without being re-staked
                tokenInfByCollec[collecAdd].tokenInfos[tokenId].owner = address(0);

                // we can use unsafe math here since the maximum total staked
                // weight that a staker can unstake must fit within uint128
                // (i.e. the staker snapshot stake limit)
                weight = tokenInfo.weight;
                totalUnstakedWeight += int128(int64(weight)); // this is safe
                /* totalUnstakedWeight += weight; // this is safe */
            }

            values[index] = 1;
        }

        if (enabled) {
            _updateHistories(msg.sender, -totalUnstakedWeight, currentCycle);
        }

        IERC1155721Transferrable _whitelistedNftContract;
        _whitelistedNftContract = IERC1155721Transferrable(collecAdd);

        _whitelistedNftContract.safeBatchTransferFromWithFallback(address(this), msg.sender, tokenIds, values, "");

        /*   _onUnstake(msg.sender, uint256(totalUnstakedWeight)); */
        _onUnstake(msg.sender, uint256(uint128(totalUnstakedWeight)));
        emit NftsBatchUnstaked(msg.sender, currentCycle, collecAdd, tokenIds, weight);
    }

    function estimateRewards()
        external
        view
        isEnabled
        hasStarted
        returns (
            uint16 startPeriod,
            uint16 periods,
            uint256 amount
        )
    {
        (ComputedClaim memory claim, ) = _computeRewards(msg.sender);
        startPeriod = claim.startPeriod;
        periods = claim.periods;
        amount = claim.amount;
    }

    function claimRewards() external isEnabled hasStarted {
        NextClaim memory nextClaim = nextClaims[msg.sender];

        (ComputedClaim memory claim, NextClaim memory newNextClaim) = _computeRewards(msg.sender);

        // free up memory on already processed staker snapshots
        Snapshot[] storage stakerHistory = stakerHistories[msg.sender];
        while (nextClaim.stakerSnapshotIndex < newNextClaim.stakerSnapshotIndex) {
            delete stakerHistory[nextClaim.stakerSnapshotIndex++];
        }

        if (claim.periods == 0) {
            return;
        }

        if (nextClaims[msg.sender].period == 0) {
            return;
        }

        Snapshot memory lastStakerSnapshot = stakerHistory[stakerHistory.length - 1];

        uint256 lastClaimedCycle = (claim.startPeriod + claim.periods - 1) * periodLengthInCycles;
        if (
            lastClaimedCycle >= lastStakerSnapshot.startCycle && // the claim reached the last staker snapshot
            lastStakerSnapshot.stake == 0 // and nothing is staked in the last staker snapshot
        ) {
            // re-init the next claim
            delete nextClaims[msg.sender];
        } else {
            nextClaims[msg.sender] = newNextClaim;
        }

        if (claim.amount != 0) {
            /* totalRewards[msg.sender] = totalRewards[msg.sender].add(claim.amount); */
            totalRewards[msg.sender] = totalRewards[msg.sender] + (claim.amount);
            require(rewardsTokenContract.transfer(msg.sender, claim.amount), "NftStaking: failed to transfer rewards");
        }

        emit RewardsClaimed(msg.sender, _getCycle(block.timestamp), claim.startPeriod, claim.periods, claim.amount);
        /* emit RewardsClaimed(msg.sender, _getCycle(now), claim.startPeriod, claim.periods, claim.amount); */
    }

    function addWhitelist(uint64 tier, address collecAdd) external onlyAdmin {
        IERC1155721Transferrable _whitelistedNftContract;
        _whitelistedNftContract = IERC1155721Transferrable(collecAdd);
        whitelistedNftContract.push(_whitelistedNftContract);
        tiers[collecAdd] = tier;
        emit TierSetted(collecAdd, tier);
    }

    function getTotalRewards(address _staker) external view returns (uint256) {
        (ComputedClaim memory claim, ) = _computeRewards(_staker);
        return (totalRewards[_staker] + claim.amount);
    }

    function getCurrentCycle() external view returns (uint16) {
        /*  return _getCycle(now); */
        return _getCycle(block.timestamp);
    }

    function getStakerInf(address collecAdd, uint256 tokenId) public view returns (TokenInfo memory stakerInfo) {
        return tokenInfByCollec[collecAdd].tokenInfos[tokenId];
    }

    function getCurrentPeriod() external view returns (uint16) {
        return _getCurrentPeriod(periodLengthInCycles);
    }

    function lastGlobalSnapshotIndex() external view returns (uint256) {
        uint256 length = globalHistory.length;
        require(length != 0, "NftStaking: empty global history");
        return length - 1;
    }

    function lastStakerSnapshotIndex(address staker) external view returns (uint256) {
        uint256 length = stakerHistories[staker].length;
        require(length != 0, "NftStaking: empty staker history");
        return length - 1;
    }

    function setTier(uint64 tier, address collecAdd) external onlyAdmin {
        require(tier != 0, "tier can not be zero");
        tiers[collecAdd] = tier;
        emit TierSetted(collecAdd, tier);
    }

    function setTierMulti(uint64[] calldata tier, address[] calldata collecAdd) external onlyAdmin {
        require(tier.length == collecAdd.length, "missing argument");
        for (uint24 i = 0; i < tier.length; i++) {
            tiers[collecAdd[i]] = tier[i];
        }
        emit MultiTierSetted(collecAdd, tier);
    }

    //ID SI NE, SAHIBI KIM, HANGI KOLEKSIYONDAN GELDİ
    function _stakeNft(
        uint256 tokenId,
        address owner,
        address collecAdd
    ) internal isEnabled hasStarted {
        uint64 weight = _validateAndGetNftWeight(collecAdd);
        //BU NFTNİN TIERI NEDIR

        uint16 periodLengthInCycles_ = periodLengthInCycles;
        /* uint16 currentCycle = _getCycle(now); */
        uint16 currentCycle = _getCycle(block.timestamp); //ŞUANA KADAR GEÇEN SÜREYİ AL

       uint256 beforeHistoryUpdate = stakerHistories[owner].length;//***** */
        _updateHistories(owner, int128(int64(weight)), currentCycle); //SAHIBI BU OLAN ,TIERI BU , SATAKE ZAMANIDA BU OLANI TARİHLERE NOT DÜŞ
        uint256 afterHistoryUpdate = stakerHistories[owner].length;        /* _updateHistories(owner, int128(weight), currentCycle); */
        //YANİ 5. SAATTE STAKE EDİLDİ GİBİ

        // initialise the next claim if it was the first stake for this staker or if
        // the next claim was re-initialised (ie. rewards were claimed until the last
        // staker snapshot and the last staker snapshot has no stake)
        //UPDATED/////////*/******************************************************* */
        if (nextClaims[owner].period == 0) { 
            uint16 currentPeriod = _getPeriod(currentCycle, periodLengthInCycles_); //ŞUANA KADAR GEÇEN PERİYODLAR YANİ TURLAR DİYELİM
            if(beforeHistoryUpdate > 0) {
                nextClaims[owner] = NextClaim(currentPeriod, uint64(globalHistory.length - 1), uint64(afterHistoryUpdate-1));
            }else{
                nextClaims[owner] = NextClaim(currentPeriod, uint64(globalHistory.length - 1), 0);
            }
        } //ŞUANKİ PERIYODUNU, GLOBAL OLARAK EKLENEN KAYITLARDAKİ INDEXINI, STAKERIN SS INDEXINI AL

        uint16 withdrawCycle = tokenInfByCollec[collecAdd].tokenInfos[tokenId].withdrawCycle;
        require(currentCycle != withdrawCycle, "Unstaked token cooldown");

        // set the staked token's info
        tokenInfByCollec[collecAdd].tokenInfos[tokenId] = TokenInfo(owner, weight, currentCycle, 0);

        emit NftStaked(owner, currentCycle, collecAdd, tokenId, weight);
        _onStake(owner, weight);
    }

    function _batchStakeNfts(
        uint256[] memory tokenIds,
        address owner,
        address collecAdd
    ) internal isEnabled hasStarted {
        uint256 numTokens = tokenIds.length;
        require(numTokens != 0, "NftStaking: no tokens");

        /*      uint16 currentCycle = _getCycle(now); */
        uint16 currentCycle = _getCycle(block.timestamp);
        uint128 totalStakedWeight = 0;
        uint64 weight = _validateAndGetNftWeight(collecAdd);

        for (uint256 index = 0; index < numTokens; ++index) {
            uint256 tokenId = tokenIds[index];
            require(
                currentCycle != tokenInfByCollec[collecAdd].tokenInfos[tokenId].withdrawCycle,
                "Unstaked token cooldown"
            );
            totalStakedWeight += weight; // This is safe
            tokenInfByCollec[collecAdd].tokenInfos[tokenId] = TokenInfo(owner, weight, currentCycle, 0);
        }

       uint256 beforeHistoryUpdate = stakerHistories[owner].length;//***** */
        _updateHistories(owner, int128(totalStakedWeight), currentCycle);
        uint256 afterHistoryUpdate = stakerHistories[owner].length;
        // initialise the next claim if it was the first stake for this staker or if
        // the next claim was re-initialised (ie. rewards were claimed until the last
        // staker snapshot and the last staker snapshot has no stake)
       if (nextClaims[owner].period == 0) { 
            uint16 currentPeriod = _getPeriod(currentCycle, periodLengthInCycles);
            if(beforeHistoryUpdate > 0) {
                nextClaims[owner] = NextClaim(currentPeriod, uint64(globalHistory.length - 1), uint64(afterHistoryUpdate-1));
            }else{
                nextClaims[owner] = NextClaim(currentPeriod, uint64(globalHistory.length - 1), 0);
            }
        }


        emit NftsBatchStaked(owner, currentCycle, collecAdd, tokenIds, weight);
        _onStake(owner, totalStakedWeight);
    }

    function _computeRewards(address staker)
        internal
        view
        returns (ComputedClaim memory claim, NextClaim memory nextClaim)
    {
        // computing 0 periods
        // if (maxPeriods == 0) {
        //     return (claim, nextClaim);
        // }

        // the history is empty
        if (globalHistory.length == 0) {
            return (claim, nextClaim);
        } //HERHANGI BIR STAKE YOK

        nextClaim = nextClaims[staker]; //KİŞİ NİN STAKE ETTİĞİ NFT SİNİN, HANGİ PERİYODDA
        //HANGI GLOBAL INDEXDE VE HANGI STAKER INDEXDE
        //OLDUĞU BİLGİLERİNİ AL
        claim.startPeriod = nextClaim.period; //NFTSİNİ STAKE ETTİĞİ ZAMANININ PERİYODUNU
        //AL

        // nothing has been staked yet
        if (claim.startPeriod == 0) {
            return (claim, nextClaim);
        } //STAKE PERIYODU 0 İSE BOŞ OLARAK GERİ DÖN

        uint16 periodLengthInCycles_ = periodLengthInCycles;
        uint16 endClaimPeriod = _getCurrentPeriod(periodLengthInCycles_);

        // current period is not claimable
        if (nextClaim.period == endClaimPeriod) {
            return (claim, nextClaim);
        }

        // retrieve the next snapshots if they exist
        Snapshot[] memory stakerHistory = stakerHistories[staker];

        Snapshot memory globalSnapshot = globalHistory[nextClaim.globalSnapshotIndex];
        Snapshot memory stakerSnapshot = stakerHistory[nextClaim.stakerSnapshotIndex];
        Snapshot memory nextGlobalSnapshot;
        Snapshot memory nextStakerSnapshot;

        if (nextClaim.globalSnapshotIndex != globalHistory.length - 1) {
            nextGlobalSnapshot = globalHistory[nextClaim.globalSnapshotIndex + 1];
        }
        if (nextClaim.stakerSnapshotIndex != stakerHistory.length - 1) {
            nextStakerSnapshot = stakerHistory[nextClaim.stakerSnapshotIndex + 1];
        }

        // excludes the current period
        claim.periods = endClaimPeriod - nextClaim.period;

        // if (maxPeriods < claim.periods) {
        //     claim.periods = maxPeriods;
        // }

        // re-calibrate the end claim period based on the actual number of
        // periods to claim. nextClaim.period will be updated to this value
        // after exiting the loop
        endClaimPeriod = nextClaim.period + claim.periods;

        // iterate over periods
        while (nextClaim.period != endClaimPeriod) {
            uint16 nextPeriodStartCycle = nextClaim.period * periodLengthInCycles_ + 1;
            uint256 rewardPerCycle = rewardsSchedule[nextClaim.period];
            uint256 startCycle = nextPeriodStartCycle - periodLengthInCycles_;
            uint256 endCycle = 0;

            // iterate over global snapshots
            while (endCycle != nextPeriodStartCycle) {
                // find the range-to-claim starting cycle, where the current
                // global snapshot, the current staker snapshot, and the current
                // period overlap
                if (globalSnapshot.startCycle > startCycle) {
                    startCycle = globalSnapshot.startCycle;
                }
                if (stakerSnapshot.startCycle > startCycle) {
                    startCycle = stakerSnapshot.startCycle;
                }

                endCycle = nextPeriodStartCycle;
                if ((nextGlobalSnapshot.startCycle != 0) && (nextGlobalSnapshot.startCycle < endCycle)) {
                    endCycle = nextGlobalSnapshot.startCycle;
                }

                // only calculate and update the claimable rewards if there is
                // something to calculate with
                // globalSnapshot.stake < snapshotReward > 0 olmalı !!
                // rewardPerCycle 10**18 li değer olmalıdır. !!
                if ((globalSnapshot.stake != 0) && (stakerSnapshot.stake != 0) && (rewardPerCycle != 0)) {
                    /*  uint256 snapshotReward = (endCycle - startCycle).mul(rewardPerCycle).mul(stakerSnapshot.stake); */
                    uint256 snapshotReward = (endCycle - startCycle) * (rewardPerCycle) * (stakerSnapshot.stake);
                    snapshotReward /= globalSnapshot.stake;

                    /* claim.amount = claim.amount.add(snapshotReward); */
                    claim.amount = claim.amount + (snapshotReward);
                }

                if (nextGlobalSnapshot.startCycle == endCycle) {
                    globalSnapshot = nextGlobalSnapshot;
                    ++nextClaim.globalSnapshotIndex;

                    if (nextClaim.globalSnapshotIndex != globalHistory.length - 1) {
                        nextGlobalSnapshot = globalHistory[nextClaim.globalSnapshotIndex + 1];
                    } else {
                        nextGlobalSnapshot = Snapshot(0, 0);
                    }
                }

                if (nextStakerSnapshot.startCycle == endCycle) {
                    stakerSnapshot = nextStakerSnapshot;
                    ++nextClaim.stakerSnapshotIndex;

                    if (nextClaim.stakerSnapshotIndex != stakerHistory.length - 1) {
                        nextStakerSnapshot = stakerHistory[nextClaim.stakerSnapshotIndex + 1];
                    } else {
                        nextStakerSnapshot = Snapshot(0, 0);
                    }
                }
            }

            ++nextClaim.period;
        }

        return (claim, nextClaim);
    }

    //STAKE EDEN, NFTNIN TIERI, ŞU ANA KADAR GEÇEN SÜRE
    function _updateHistories(
        address staker,
        int128 stakeDelta,
        uint16 currentCycle
    ) internal {
        uint256 stakerSnapshotIndex = _updateHistory(stakerHistories[staker], stakeDelta, currentCycle);
        uint256 globalSnapshotIndex = _updateHistory(globalHistory, stakeDelta, currentCycle);

        emit HistoriesUpdated(
            staker,
            currentCycle,
            stakerHistories[staker][stakerSnapshotIndex].stake,
            globalHistory[globalSnapshotIndex].stake
        );
    }

    //SNAPSHOTLANAN GEÇMİŞ YA STAKERINDIR YADA GLOBALDİR, NFT TIERI, ŞUANA KADARKİ SÜRE
    //EĞER SNAPSHOT TARİHİNDE BİRDEN FAZLA SNAPSHOT VARSA SNAPSHOT, EN SON STAKE AĞIRLIĞIYLA ŞİMDİKİNİ TOPLA VE BİR SONRAKİNE AT,
    //STAKER İNDEXİNİDE 1 ARTTIR , AMA HİÇ SNAPSHOT YOKSA YANİ STAKE EDEN KİŞİ İLK DEFA STAKE ETTİYSE VEYA GLOBALDE İLK DEFA STAKE OLDUYSA
    //İNDEXİMİZ 0 OLACAĞINDAN , 0 OLARAK GERİ DÖN.
    function _updateHistory(
        Snapshot[] storage history,
        int128 stakeDelta,
        uint16 currentCycle
    ) internal returns (uint256 snapshotIndex) {
        uint256 historyLength = history.length; //BAKILACAK TARİHİN (YA STAKERIN YADA GLOBAL) UZUNLUĞUNU ALDIK
        uint128 snapshotStake;

        if (historyLength != 0) {
            //DAHA ÖNCEDEN SNAPSHOT ALINMIŞTIR
            // there is an existing snapshot
            snapshotIndex = historyLength - 1; //MESELA UZUNLUJ 10 İSE ASLINDA INDEXI 9 DUR
            Snapshot storage snapshot = history[snapshotIndex]; //GONDERİLEN TARIHIN EN SON Kİ SNAPSHOT BILGILERINI AL

            /* snapshotStake = uint256(int256(snapshot.stake).add(stakeDelta)).toUint128(); */
            /*  snapshotStake = uint256(int256(int128(snapshot.stake)).add(stakeDelta)).toUint128(); */

            //EN SON Kİ SNAPSHOTIN STAKE AĞIRLIĞINI YANI ŞUANDAKİ İŞLEMDE OLANA, STAKE EDİLEN TIER BILGİSİNİ EKLE, YENİ TIERI TOPLAM AĞIRLIĞI BUL
            snapshotStake = uint128(int128(snapshot.stake) + stakeDelta);
            if (snapshot.startCycle == currentCycle) {
                // update the snapshot if it starts on the current cycle
                snapshot.stake = snapshotStake;
                return snapshotIndex;
            }

            snapshotIndex += 1;
        } else {
            //DAHA ONCEDEN STAKE EDILEN NFT YOKTUR YANI ONCEKİ BİR AĞILRLIK OLMADIĞI İÇİN KAYITLARDA YENİ BİLGİYİ DİREK ALICAZ
            //yani index 0 olarak geri dönücektir
            snapshotStake = uint128(stakeDelta);
        }

        Snapshot memory snapshot;
        snapshot.stake = snapshotStake;
        snapshot.startCycle = currentCycle;

        // add a new snapshot in the history
        history.push(snapshot); //historyinin üzerine yeni bir snapshot koy
        //STORAGE OLDUĞU İÇİN GÖNDERİLEN DEĞERLE AYNI YERE SAHİP OLDUĞUNDAN PUSH İŞLEMİ GÖNDERİLEN DEĞİŞKENDE DE UYGULANMIŞ OLUYOR BİR NEVİ
    }

    //BELİRTİLEN ZAMANI AL -> BU ZAMANDAN STAKİNGİN BAŞLANGIÇ ZAMANINI ÇIKAR, BİZİM ORANIMIZA BOL BİR ÜSTÜNE YUVARLA
    function _getCycle(uint256 timestamp) internal view returns (uint16) {
        require(timestamp >= startTimestamp, "NftStaking: timestamp preceeds contract start");
        return uint16((((timestamp - startTimestamp) / uint256(cycleLengthInSeconds)) + 1));
    } //ASLINDA ARADA GEÇEN ZAMANA BAKIYORUZ BİR NEVİ, BOLMEMİZİN SEBEBİ İSE ASLINDA ARADA Kİ GEÇEN SANIYE

    //BIZE GORE ORANI KAÇ OLUCAK MESALA 100 SANIYE GEÇTİ AMA BANA GORE SEN ONU 50 SANIYE OLARAK HESAPLA GİBİ
    //YANI NE KADAR SÜRELİ STAKE ETMİŞ OLAY BU

    function _getPeriod(uint16 cycle, uint16 periodLengthInCycles_) internal pure returns (uint16) {
        require(cycle != 0, "NftStaking: cycle cannot be zero");
        return (cycle - 1) / periodLengthInCycles_ + 1;
    } //CYCLE I YANİ STAKE ETME SÜRESİ 100 SAATSE, HERBİR CYLEIN İÇİNDEKİ PERİODADA 5 DERSEK YANİ 20 PERIOD YAPAR

    //YANİ BU KİŞİ 20 TURDUR STAKE HALINDA GİBİ KABACA

    function _getCurrentPeriod(uint16 periodLengthInCycles_) internal view returns (uint16) {
        /*  return _getPeriod(_getCycle(now), periodLengthInCycles_); */
        return _getPeriod(_getCycle(block.timestamp), periodLengthInCycles_);
    }

    function _validateAndGetNftWeight(address collecAdd) internal virtual returns (uint64) {
        return (tiers[collecAdd]);
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return interfaceID == this.supportsInterface.selector;
    }

    function _onStake(address owner, uint256 totalWeight) internal virtual {}

    function _onUnstake(address owner, uint256 totalWeight) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface INftStaking{
    event RewardsAdded(uint256 startPeriod, uint256 endPeriod, uint256 rewardsPerCycle);

    event Started();

    event NftStaked(address staker, uint256 cycle, address collection, uint256 tokenId, uint256 weight);
    event NftsBatchStaked(address staker, uint256 cycle, address collection, uint256[] tokenIds, uint64 weights);

    event NftUnstaked(address staker, uint256 cycle, address collection, uint256 tokenId, uint256 weight);
    event NftsBatchUnstaked(address staker, uint256 cycle, address collection, uint256[] tokenIds, uint64 weights);

    event RewardsClaimed(address staker, uint256 cycle, uint256 startPeriod, uint256 periods, uint256 amount);

    event HistoriesUpdated(address staker, uint256 startCycle, uint256 stakerStake, uint256 globalStake);
    
    event TierSetted(address collection, uint64 tier);
    event MultiTierSetted(address[] collections, uint64[] tiers);
    
    event Disabled();

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;
import "../interfaces/IERC1155721Transferrable.sol";

library ERC1155721SafeTransferFallback {
    function safeBatchTransferFromWithFallback(
        IERC1155721Transferrable self,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal {
        try self.safeBatchTransferFrom(from, to, ids, values, data) {} catch {
            uint256 length = ids.length;
            for (uint256 i = 0; i < length; ++i) {
                self.transferFrom(from, to, ids[i]);
            }
        }
    }

    function safeTransferFromWithFallback(
        IERC1155721Transferrable self,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) internal {
        try self.safeTransferFrom(from, to, id, value, data) {} catch {
            self.transferFrom(from, to, id);
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

pragma solidity 0.8.11;

interface IERC1155721Transferrable {
    
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;

  
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}
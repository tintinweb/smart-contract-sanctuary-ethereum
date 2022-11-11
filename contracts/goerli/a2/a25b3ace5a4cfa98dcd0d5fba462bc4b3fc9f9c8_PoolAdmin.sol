// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.6;

interface AssessorLike {
    function file(bytes32 name, uint256 value) external;
}

interface LendingAdapterLike {
    function raise(uint256 amount) external;
    function sink(uint256 amount) external;
    function heal() external;
    function file(bytes32 what, uint256 value) external;
}

interface FeedLike {
    function overrideWriteOff(uint256 loan, uint256 writeOffGroupIndex_) external;
    function file(
        bytes32 name,
        uint256 risk_,
        uint256 thresholdRatio_,
        uint256 ceilingRatio_,
        uint256 rate_,
        uint256 recoveryRatePD_
    ) external;
    function file(bytes32 name, uint256 rate_, uint256 writeOffPercentage_, uint256 overdueDays_) external;
    function file(bytes32 name, uint256 value) external;
    function file(bytes32 name, bytes32 nftID_, uint256 maturityDate_) external;
    function update(bytes32 nftID_, uint256 value) external;
    function update(bytes32 nftID_, uint256 value, uint256 risk_) external;
}

interface MemberlistLike {
    function updateMember(address usr, uint256 validUntil) external;
    function updateMembers(address[] calldata users, uint256 validUntil) external;
}

interface CoordinatorLike {
    function file(bytes32 name, uint256 value) external;
    function file(bytes32 name, bool value) external;
    function poolClosing() external view returns (bool);
}

// Wrapper contract for various pool management tasks.
contract PoolAdmin {
    AssessorLike public assessor;
    LendingAdapterLike public lending;
    FeedLike public navFeed;
    MemberlistLike public seniorMemberlist;
    MemberlistLike public juniorMemberlist;
    CoordinatorLike public coordinator;

    bool public live = true;

    mapping(address => uint256) public admin_level;

    uint256 public constant LEVEL_1 = 1;
    uint256 public constant LEVEL_2 = 2;
    uint256 public constant LEVEL_3 = 3;

    modifier level1() {
        require(admin_level[msg.sender] >= LEVEL_1 && live);
        _;
    }

    modifier level2() {
        require(admin_level[msg.sender] >= LEVEL_2 && live);
        _;
    }

    modifier level3() {
        require(admin_level[msg.sender] == LEVEL_3 && live);
        _;
    }

    constructor() {
        admin_level[msg.sender] = LEVEL_3;
        emit SetAdminLevel(msg.sender, LEVEL_3);
    }

    // --- Liquidity Management, authorized by level 1 admins ---
    event SetMaxReserve(uint256 value);
    event RaiseCreditline(uint256 amount);
    event SinkCreditline(uint256 amount);
    event HealCreditline();
    event UpdateSeniorMember(address indexed usr, uint256 validUntil);
    event UpdateSeniorMembers(address[] indexed users, uint256 validUntil);
    event UpdateJuniorMember(address indexed usr, uint256 validUntil);
    event UpdateJuniorMembers(address[] indexed users, uint256 validUntil);

    // Manage max reserve
    function setMaxReserve(uint256 value) public level1 {
        assessor.file("maxReserve", value);
        emit SetMaxReserve(value);
    }

    // Manage creditline
    function raiseCreditline(uint256 amount) public level1 {
        lending.raise(amount);
        emit RaiseCreditline(amount);
    }

    function sinkCreditline(uint256 amount) public level1 {
        lending.sink(amount);
        emit SinkCreditline(amount);
    }

    function healCreditline() public level1 {
        lending.heal();
        emit HealCreditline();
    }

    function setMaxReserveAndRaiseCreditline(uint256 newMaxReserve, uint256 creditlineRaise) public level1 {
        setMaxReserve(newMaxReserve);
        raiseCreditline(creditlineRaise);
    }

    function setMaxReserveAndSinkCreditline(uint256 newMaxReserve, uint256 creditlineSink) public level1 {
        setMaxReserve(newMaxReserve);
        sinkCreditline(creditlineSink);
    }

    // Manage memberlists
    function updateSeniorMember(address usr, uint256 validUntil) public level1 {
        seniorMemberlist.updateMember(usr, validUntil);
        emit UpdateSeniorMember(usr, validUntil);
    }

    function updateSeniorMembers(address[] memory users, uint256 validUntil) public level1 {
        seniorMemberlist.updateMembers(users, validUntil);
        emit UpdateSeniorMembers(users, validUntil);
    }

    function updateJuniorMember(address usr, uint256 validUntil) public level1 {
        juniorMemberlist.updateMember(usr, validUntil);
        emit UpdateJuniorMember(usr, validUntil);
    }

    function updateJuniorMembers(address[] memory users, uint256 validUntil) public level1 {
        juniorMemberlist.updateMembers(users, validUntil);
        emit UpdateJuniorMembers(users, validUntil);
    }

    // --- Risk Management, authorized by level 2 admins ---
    event OverrideWriteOff(uint256 loan, uint256 writeOffGroupIndex);
    event AddRiskGroup(
        uint256 risk_, uint256 thresholdRatio_, uint256 ceilingRatio_, uint256 rate_, uint256 recoveryRatePD_
    );
    event AddRiskGroups(uint256[] risks_, uint256[] thresholdRatios_, uint256[] ceilingRatios_, uint256[] rates_);
    event AddWriteOffGroup(uint256 rate_, uint256 writeOffPercentage_, uint256 overdueDays_);
    event SetMatBuffer(uint256 value);
    event UpdateNFTValue(bytes32 nftID_, uint256 value);
    event UpdateNFTValueRisk(bytes32 nftID_, uint256 value, uint256 risk_);
    event UpdateNFTMaturityDate(bytes32 nftID_, uint256 maturityDate_);

    function overrideWriteOff(uint256 loan, uint256 writeOffGroupIndex_) public level2 {
        navFeed.overrideWriteOff(loan, writeOffGroupIndex_);
        emit OverrideWriteOff(loan, writeOffGroupIndex_);
    }

    function addRiskGroup(
        uint256 risk_,
        uint256 thresholdRatio_,
        uint256 ceilingRatio_,
        uint256 rate_,
        uint256 recoveryRatePD_
    ) public level2 {
        navFeed.file("riskGroup", risk_, thresholdRatio_, ceilingRatio_, rate_, recoveryRatePD_);
        emit AddRiskGroup(risk_, thresholdRatio_, ceilingRatio_, rate_, recoveryRatePD_);
    }

    function addRiskGroups(
        uint256[] memory risks_,
        uint256[] memory thresholdRatios_,
        uint256[] memory ceilingRatios_,
        uint256[] memory rates_,
        uint256[] memory recoveryRatePDs_
    ) public level2 {
        require(
            risks_.length == thresholdRatios_.length && thresholdRatios_.length == ceilingRatios_.length
                && ceilingRatios_.length == rates_.length && rates_.length == recoveryRatePDs_.length,
            "non-matching-arguments"
        );
        for (uint256 i = 0; i < risks_.length; i++) {
            addRiskGroup(risks_[i], thresholdRatios_[i], ceilingRatios_[i], rates_[i], recoveryRatePDs_[i]);
        }
    }

    function addWriteOffGroup(uint256 rate_, uint256 writeOffPercentage_, uint256 overdueDays_) public level2 {
        navFeed.file("writeOffGroup", rate_, writeOffPercentage_, overdueDays_);
        emit AddWriteOffGroup(rate_, writeOffPercentage_, overdueDays_);
    }

    function addWriteOffGroups(
        uint256[] memory rates_,
        uint256[] memory writeOffPercentages_,
        uint256[] memory overdueDays_
    ) public level2 {
        require(
            rates_.length == writeOffPercentages_.length && writeOffPercentages_.length == overdueDays_.length,
            "non-matching-arguments"
        );
        for (uint256 i = 0; i < rates_.length; i++) {
            addWriteOffGroup(rates_[i], writeOffPercentages_[i], overdueDays_[i]);
        }
    }

    function setMatBuffer(uint256 value) public level3 {
        lending.file("buffer", value);
        emit SetMatBuffer(value);
    }

    function setMaxAutoHeal(uint256 value) public level3 {
        lending.file("autoHealMax", value);
    }

    function updateNFTValue(bytes32 nftID_, uint256 value) public level2 {
        navFeed.update(nftID_, value);
        emit UpdateNFTValue(nftID_, value);
    }

    function updateNFTValueRisk(bytes32 nftID_, uint256 value, uint256 risk_) public level2 {
        navFeed.update(nftID_, value, risk_);
        emit UpdateNFTValueRisk(nftID_, value, risk_);
    }

    function updateNFTMaturityDate(bytes32 nftID_, uint256 maturityDate_) public level2 {
        navFeed.file("maturityDate", nftID_, maturityDate_);
        emit UpdateNFTMaturityDate(nftID_, maturityDate_);
    }

    // --- Pool Governance, authorized by level 3 admins ---
    event File(bytes32 indexed what, bool indexed data);
    event SetSeniorInterestRate(uint256 value);
    event SetDiscountRate(uint256 value);
    event SetMinimumEpochTime(uint256 value);
    event SetChallengeTime(uint256 value);
    event SetMinSeniorRatio(uint256 value);
    event SetMaxSeniorRatio(uint256 value);
    event SetEpochScoringWeights(
        uint256 weightSeniorRedeem, uint256 weightJuniorRedeem, uint256 weightJuniorSupply, uint256 weightSeniorSupply
    );
    event ClosePool();
    event UnclosePool();
    event SetAdminLevel(address indexed usr, uint256 indexed level);
    event Depend(bytes32 indexed contractname, address addr);

    function setSeniorInterestRate(uint256 value) public level3 {
        assessor.file("seniorInterestRate", value);
        emit SetSeniorInterestRate(value);
    }

    function setDiscountRate(uint256 value) public level3 {
        navFeed.file("discountRate", value);
        emit SetDiscountRate(value);
    }

    function setMinimumEpochTime(uint256 value) public level3 {
        coordinator.file("minimumEpochTime", value);
        emit SetMinimumEpochTime(value);
    }

    function setChallengeTime(uint256 value) public level3 {
        coordinator.file("challengeTime", value);
        emit SetChallengeTime(value);
    }

    function setMinSeniorRatio(uint256 value) public level3 {
        assessor.file("minSeniorRatio", value);
        emit SetMinSeniorRatio(value);
    }

    function setMaxSeniorRatio(uint256 value) public level3 {
        assessor.file("maxSeniorRatio", value);
        emit SetMaxSeniorRatio(value);
    }

    function setEpochScoringWeights(
        uint256 weightSeniorRedeem,
        uint256 weightJuniorRedeem,
        uint256 weightJuniorSupply,
        uint256 weightSeniorSupply
    ) public level3 {
        coordinator.file("weightSeniorRedeem", weightSeniorRedeem);
        coordinator.file("weightJuniorRedeem", weightJuniorRedeem);
        coordinator.file("weightJuniorSupply", weightJuniorSupply);
        coordinator.file("weightSeniorSupply", weightSeniorSupply);
        emit SetEpochScoringWeights(weightSeniorRedeem, weightJuniorRedeem, weightJuniorSupply, weightSeniorSupply);
    }

    function closePool() public level3 {
        require(coordinator.poolClosing() == false, "already-closed");
        coordinator.file("poolClosing", true);
        emit ClosePool();
    }

    function unclosePool() public level3 {
        require(coordinator.poolClosing() == true, "not-yet-closed");
        coordinator.file("poolClosing", false);
        emit UnclosePool();
    }

    modifier canSetAdminlevel(uint256 level) {
        require(level >= 0 && level <= LEVEL_3);
        if (level == 0) require(admin_level[msg.sender] == LEVEL_3);
        if (level == LEVEL_1) require(admin_level[msg.sender] >= LEVEL_2);
        if (level == LEVEL_2 || level == LEVEL_3) require(admin_level[msg.sender] == LEVEL_3);
        _;
    }

    function setAdminLevel(address usr, uint256 level) public canSetAdminlevel(level) {
        admin_level[usr] = level;
        emit SetAdminLevel(usr, level);
    }

    // Aliases so the root contract can use its relyContract/denyContract methods
    function rely(address usr) public level3 {
        setAdminLevel(usr, 3);
    }

    function deny(address usr) public level3 {
        setAdminLevel(usr, 0);
    }

    function depend(bytes32 contractName, address addr) public level3 {
        if (contractName == "assessor") {
            assessor = AssessorLike(addr);
        } else if (contractName == "lending") {
            lending = LendingAdapterLike(addr);
        } else if (contractName == "seniorMemberlist") {
            seniorMemberlist = MemberlistLike(addr);
        } else if (contractName == "juniorMemberlist") {
            juniorMemberlist = MemberlistLike(addr);
        } else if (contractName == "navFeed") {
            navFeed = FeedLike(addr);
        } else if (contractName == "coordinator") {
            coordinator = CoordinatorLike(addr);
        } else {
            revert();
        }
        emit Depend(contractName, addr);
    }

    function file(bytes32 what, bool data) public level3 {
        live = data;
        emit File(what, data);
    }
}
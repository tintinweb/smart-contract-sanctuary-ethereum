pragma solidity ^ 0.6.12;

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(
            _initializing || !_initialized,
            "Initializable: contract is already initialized"
        );

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer { }

    function _msgSender() internal view virtual returns(address) {
        return msg.sender;
    }
}

abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns(address) {
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    uint256[49] private __gap;
}

contract Bnbfarm is Initializable, OwnableUpgradeable {
    event regLevelEvent(
    address indexed _user,
    address indexed _referrer,
    uint256 _time
);
    event buyLevelEvent(address indexed _user, uint256 _level, uint256 _time);

    mapping(uint256 => uint256) public LEVEL_PRICE;
    uint256 REFERRER_1_LEVEL_LIMIT;
    uint256 public royalityAmount;
    uint256 public globalroyalityAmountA;
    uint256 public globalroyalityAmountB;

    address[] public royalparticipants;
    address[] public globalparticipants1;
    address[] public globalparticipants2;

    address[] public joinedAddress;
    address[] public planBRefAmount;

    mapping(address => uint256) public planBRefAmountuser;

    struct UserStruct {
        bool isExist;
        uint256 id;
        uint256 referrerID;
        uint256 currentLevel;
        uint256 earnedAmount;
        uint256 totalearnedAmount;
        uint256 royalityincome;
        uint256 globalroyality1income;
        uint256 globalroyality2income;
        address[] referral;
        mapping(uint256 => uint256) levelEarningmissed;
    }

    struct PlanBStruct {
        bool isExist;
        uint256 id;
        uint256 referrerID;
        address[] referral;
    }

    mapping(address => UserStruct) public users;
    mapping(address => PlanBStruct) public planB;
    mapping(uint256 => address) public userList;
    mapping(uint256 => address) public planBuserList;
    mapping(uint256 => bool) public userRefComplete;
    uint256 public currUserID;
    uint256 refCompleteDepth;
    bool public isAutodistribute;
    uint256 public lastRewardTimestamp;
    uint256 public endRewardTime;
    address public ownerWallet;
    uint256 public totalUsers;
    uint256 public distributeCount;

    function initialize(address _ownerAddress) public initializer {
        __Ownable_init();
        ownerWallet = _ownerAddress;
        REFERRER_1_LEVEL_LIMIT = 3;
        royalityAmount = 0;
        globalroyalityAmountA = 0;
        globalroyalityAmountB = 0;
        refCompleteDepth = 1;
        currUserID = 0;
        totalUsers = 1;
        distributeCount = 10;

        LEVEL_PRICE[1] = 1000000; // 0.1
        LEVEL_PRICE[2] = LEVEL_PRICE[1] * 3;
        LEVEL_PRICE[3] = LEVEL_PRICE[2] * 3;
        LEVEL_PRICE[4] = LEVEL_PRICE[3] * 3;
        LEVEL_PRICE[5] = LEVEL_PRICE[4] * 3;
        LEVEL_PRICE[6] = LEVEL_PRICE[5] * 3;
        LEVEL_PRICE[7] = LEVEL_PRICE[6] * 3;
        LEVEL_PRICE[8] = LEVEL_PRICE[7] * 3;

        UserStruct memory userStruct;
        PlanBStruct memory planBStruct;
        currUserID = 1000000;
        lastRewardTimestamp = block.timestamp;
        endRewardTime = block.timestamp + 900;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: 0,
            currentLevel: 8,
            earnedAmount: 0,
            totalearnedAmount: 0,
            referral: new address[](0),
            royalityincome: 0,
            globalroyality1income: 0,
            globalroyality2income: 0
        });

        planBStruct = PlanBStruct({
            isExist: true,
            referrerID: 0,
            id: currUserID,
            referral: new address[](0)
        });
        users[ownerWallet] = userStruct;
        users[ownerWallet].levelEarningmissed[1] = 0;
        users[ownerWallet].levelEarningmissed[2] = 0;
        users[ownerWallet].levelEarningmissed[3] = 0;
        users[ownerWallet].levelEarningmissed[4] = 0;
        users[ownerWallet].levelEarningmissed[5] = 0;
        users[ownerWallet].levelEarningmissed[6] = 0;
        users[ownerWallet].levelEarningmissed[7] = 0;
        users[ownerWallet].levelEarningmissed[8] = 0;
        planB[ownerWallet] = planBStruct;
        userList[currUserID] = ownerWallet;
        planBuserList[currUserID] = ownerWallet;
        globalparticipants1.push(ownerWallet);
        globalparticipants2.push(ownerWallet);
        isAutodistribute = false;
    }

    function random(uint256 number) public view returns(uint256) {
        return
        uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    msg.sender
                )
            )
        ) % number;
    }

    function regUser(address _referrer) public payable {
        require(!users[msg.sender].isExist, "User exist");
        uint256 _referrerID;
        if (users[_referrer].isExist) {
            _referrerID = users[_referrer].id;
        } else if (_referrer == address(0)) {
            _referrerID = findFirstFreeReferrer();
            refCompleteDepth = _referrerID;
        } else {
            revert("Incorrect referrer");
        }

        require(
            msg.value == (LEVEL_PRICE[1] * 2 * 1e18) / 10000000,
            "Incorrect Value"
        );

        if (
            users[userList[_referrerID]].referral.length >=
            REFERRER_1_LEVEL_LIMIT
        ) {
            _referrerID = users[findFreeReferrer(userList[_referrerID])].id;
        }

        UserStruct memory userStruct;
        currUserID = random(1000000);
        totalUsers++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: _referrerID,
            earnedAmount: 0,
            totalearnedAmount: 0,
            referral: new address[](0),
            currentLevel: 1,
            globalroyality1income: 0,
            globalroyality2income: 0,
            royalityincome: 0
        });

        users[msg.sender] = userStruct;
        users[msg.sender].levelEarningmissed[2] = 0;
        users[msg.sender].levelEarningmissed[3] = 0;
        users[msg.sender].levelEarningmissed[4] = 0;
        users[msg.sender].levelEarningmissed[5] = 0;
        users[msg.sender].levelEarningmissed[6] = 0;
        users[msg.sender].levelEarningmissed[7] = 0;
        users[msg.sender].levelEarningmissed[8] = 0;

        userList[currUserID] = msg.sender;
        users[userList[_referrerID]].referral.push(msg.sender);

        if (users[userList[_referrerID]].referral.length == 3) {
            userRefComplete[_referrerID] = true;
        }
        address uplinerAddress = userList[users[msg.sender].referrerID];
        users[uplinerAddress].earnedAmount += LEVEL_PRICE[1];
        users[uplinerAddress].totalearnedAmount += LEVEL_PRICE[1];
        activatePlanB(_referrer, msg.sender);
        joinedAddress.push(msg.sender);

        if (joinedAddress.length > distributeCount && isAutodistribute) {
            distribute();
        }

        emit regLevelEvent(msg.sender, userList[_referrerID], now);
    }

    function activatePlanB(address upliner, address _user) internal {
        PlanBStruct memory planBStruct;
        planBStruct = PlanBStruct({
            isExist: true,
            referrerID: users[upliner].id,
            id: users[_user].id,
            referral: new address[](0)
        });
        planB[_user] = planBStruct;
        planBuserList[planB[_user].id] = _user;
        planB[upliner].referral.push(_user);

        //40% to direct parent

        uint256 directParentIncome = (LEVEL_PRICE[1] * 40) / 100;

        users[upliner].earnedAmount += directParentIncome;
        users[upliner].totalearnedAmount += directParentIncome;

        //30% Level Income
        levelincome(upliner, 0);

        //5% Team Royality;
        uint256 _teamRoyalityTotal = (LEVEL_PRICE[1] * 5) / 100;

        uint256 _globalRoyalityTotal = (LEVEL_PRICE[1] * 10) / 100;
        royalityAmount += _teamRoyalityTotal;
        globalroyalityAmountA += _teamRoyalityTotal;
        globalroyalityAmountB += _globalRoyalityTotal;
    }

    function levelincome(address _parent, uint256 cnt) internal {
        if (cnt < 10 && _parent != 0x0000000000000000000000000000000000000000) {
            uint256 LevelIncome = (LEVEL_PRICE[1] * 30) / 100;
            uint256 levelIncomePerLevel = LevelIncome / 10;
            users[_parent].earnedAmount += levelIncomePerLevel;
            users[_parent].totalearnedAmount += levelIncomePerLevel;
            address nextParent = planBuserList[planB[_parent].referrerID];
            cnt++;
            levelincome(nextParent, cnt);
        }
    }

    function buyLevel(uint256 _level) public payable {
        require(users[msg.sender].isExist, "User not exist");
        require(_level > 1 && _level <= 8, "Incorrect level");

        require(
            msg.value == (LEVEL_PRICE[_level] * 1e18) / 10000000,
            "Incorrect Value"
        );
        require(_level > users[msg.sender].currentLevel, "Incorrect level");
        require(
            users[msg.sender].currentLevel == _level - 1,
            "Incorrect level"
        );

        if (_level == 2) {
            royalparticipants.push(msg.sender);
        } else if (_level == 3) {
            globalparticipants1.push(msg.sender);
        } else if (_level == 4) {
            globalparticipants2.push(msg.sender);
        }

        users[msg.sender].currentLevel = _level;
        payForLevel(_level, msg.sender);

        if (joinedAddress.length > distributeCount && isAutodistribute) {
            distribute();
        }

        emit buyLevelEvent(msg.sender, _level, now);
    }

    function payForLevel(uint256 _level, address _user) internal {
        address referer;
        address referer1;
        address referer2;
        address referer3;
        if (_level == 1 || _level == 5) {
            referer = userList[users[_user].referrerID];
        } else if (_level == 2 || _level == 6) {
            referer1 = userList[users[_user].referrerID];
            referer = userList[users[referer1].referrerID];
        } else if (_level == 3 || _level == 7) {
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer = userList[users[referer2].referrerID];
        } else if (_level == 4 || _level == 8) {
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer3 = userList[users[referer2].referrerID];
            referer = userList[users[referer3].referrerID];
        }

        if (users[_user].levelEarningmissed[_level] > 0) {
            users[_user].earnedAmount += users[_user].levelEarningmissed[
                _level
            ];
            users[_user].totalearnedAmount += users[_user].levelEarningmissed[
                _level
            ];
            users[_user].levelEarningmissed[_level] = 0;
        }

        bool isSend = true;
        if (!users[referer].isExist) {
            isSend = false;
        }
        if (isSend) {
            if (users[referer].currentLevel >= _level) {
                users[referer].earnedAmount += LEVEL_PRICE[_level];
                users[referer].totalearnedAmount += LEVEL_PRICE[_level];
            } else {
                users[referer].levelEarningmissed[_level] += LEVEL_PRICE[
                    _level
                ];
            }
        }
    }

    function findParentLevel(address _userAddress) public {
        address uplineParent = planBuserList[planB[_userAddress].referrerID];
        if (uplineParent != 0x0000000000000000000000000000000000000000) {
            if (users[uplineParent].currentLevel >= 2) {
                planBRefAmount.push(uplineParent);
            }
            findParentLevel(uplineParent);
        }
    }

    function distribute() internal {
        lastRewardTimestamp = block.timestamp;
        endRewardTime = lastRewardTimestamp + 900;
        if (joinedAddress.length > 0 && royalityAmount > 0) {
            for (uint256 i = 0; i < joinedAddress.length; i++) {
                findParentLevel(joinedAddress[i]);
                if (planBRefAmount.length > 0) {
                    uint256 shareAmount = ((LEVEL_PRICE[1] * 5) / 100) /
                        planBRefAmount.length;
                    for (uint256 j = 0; j < planBRefAmount.length; j++) {
                        users[planBRefAmount[j]].earnedAmount += shareAmount;
                        users[planBRefAmount[j]]
                            .totalearnedAmount += shareAmount;
                        users[planBRefAmount[j]].royalityincome += shareAmount;
                    }
                    delete planBRefAmount;
                }
            }
        }
        if (globalparticipants1.length > 0 && globalroyalityAmountA > 0) {
            uint256 global1share = (globalroyalityAmountA /
                globalparticipants1.length);
            for (uint256 i = 0; i < globalparticipants1.length; i++) {
                users[globalparticipants1[i]].earnedAmount += global1share;
                users[globalparticipants1[i]].totalearnedAmount += global1share;
                users[globalparticipants1[i]]
                    .globalroyality1income += global1share;
            }
        }
        if (globalparticipants2.length > 0 && globalroyalityAmountB > 0) {
            uint256 global2share = (globalroyalityAmountB /
                globalparticipants2.length);
            for (uint256 i = 0; i < globalparticipants2.length; i++) {
                users[globalparticipants2[i]].earnedAmount += global2share;
                users[globalparticipants2[i]].totalearnedAmount += global2share;
                users[globalparticipants2[i]]
                    .globalroyality2income += global2share;
            }
        }
        royalityAmount = 0;
        globalroyalityAmountA = 0;
        globalroyalityAmountB = 0;
        delete joinedAddress;
    }

    function findFreeReferrer(address _user) public view returns(address) {
        if (users[_user].referral.length < REFERRER_1_LEVEL_LIMIT) {
            return _user;
        }
        address[] memory referrals = new address[](600);
        referrals[0] = users[_user].referral[0];
        referrals[1] = users[_user].referral[1];
        referrals[2] = users[_user].referral[2];
        address freeReferrer;
        bool noFreeReferrer = true;

        for (uint256 i = 0; i < 600; i++) {
            if (users[referrals[i]].referral.length == REFERRER_1_LEVEL_LIMIT) {
                if (i < 120) {
                    referrals[(i + 1) * 3] = users[referrals[i]].referral[0];
                    referrals[(i + 1) * 3 + 1] = users[referrals[i]].referral[
                        1
                    ];
                    referrals[(i + 1) * 3 + 2] = users[referrals[i]].referral[
                        2
                    ];
                }
            } else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }
        if (noFreeReferrer) {
            freeReferrer = userList[findFirstFreeReferrer()];
            require(freeReferrer != address(0));
        }
        return freeReferrer;
    }

    function getmissedvalue(address _userAddress, uint256 _level)
    public
    view
    returns(uint256)
    {
        return users[_userAddress].levelEarningmissed[_level];
    }

    function findFirstFreeReferrer() public view returns(uint256) {
        for (uint256 i = refCompleteDepth; i < 500 + refCompleteDepth; i++) {
            if (!userRefComplete[i]) {
                return i;
            }
        }
    }

    function safeWithDrawbnb(uint256 _amount, address payable addr)
    public
    onlyOwner
    {
        addr.transfer(_amount);
    }

    function distributeByAdmin() public onlyOwner {
        distribute();
    }

    function removeJoinedUsers() public onlyOwner {
        delete joinedAddress;
    }

    function updateDistributeCount(uint256 _count) public onlyOwner {
        distributeCount = _count;
    }

    function claimRewards() public {
        uint256 claimAmount = users[msg.sender].earnedAmount;
        if (claimAmount > 0) {
            claimAmount = (claimAmount * 1e18) / 10000000;
            payable(msg.sender).transfer(claimAmount);
            users[msg.sender].earnedAmount = 0;
            users[msg.sender].royalityincome = 0;
            users[msg.sender].globalroyality1income = 0;
            users[msg.sender].globalroyality2income = 0;
        }
    }

    function setAutoDistribute(bool isauto) public onlyOwner {
        isAutodistribute = isauto;
    }

    function updateTeamRoyalityifMissed(address _address, uint256 _amount)
    public
    onlyOwner
    {
        users[_address].earnedAmount += _amount;
        users[_address].totalearnedAmount += _amount;
        users[_address].royalityincome += _amount;
    }

    function viewUserReferral(address _user)
    public
    view
    returns(address[] memory)
    {
        return users[_user].referral;
    }

    function joinedLength() public view returns(uint256) {
        return joinedAddress.length;
    }

    function viewplanBUserReferral(address _user)
    public
    view
    returns(address[] memory)
    {
        return planB[_user].referral;
    }

    function distributeToRoyal(uint256 _loopcnt, address[] memory _addresses, uint256[] memory _ramount, uint256[] memory _g1amount, uint256[] memory _g2amount)
      onlyOwner public
    {
        lastRewardTimestamp = block.timestamp;
        endRewardTime = lastRewardTimestamp + 900;
        for (uint256 i = 0; i < _loopcnt; i++) {
            users[_addresses[i]].royalityincome += _ramount[i];
            if (_g1amount[i] > 0) {
                users[_addresses[i]].globalroyality1income += _g1amount[i];
            }
            if (_g2amount[i] > 0) {
                users[_addresses[i]].globalroyality2income += _g2amount[i];
            }
            users[_addresses[i]].earnedAmount += _ramount[i] + _g1amount[i] + _g2amount[i];
            users[_addresses[i]].totalearnedAmount += _ramount[i] + _g1amount[i] + _g2amount[i];
        }
        royalityAmount = 0;
        globalroyalityAmountA = 0;
        globalroyalityAmountB = 0;
    }

}
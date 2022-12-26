pragma solidity ^0.8.6;

// SPDX-License-Identifier: MIT

contract STAKE {
    //constant
    uint256 public constant percentDivider = 100_000;
    //variables
    uint256 public minStake = 10_000_000;
    uint256 public totalStaked;
    uint256 public currentStaked;
    uint256 public totalRewardClaimed;
    uint256 public totalNftStaked;
    uint256 public currentNftStaked;
    uint256 public totalNftRewardClaimed;
    uint256 public TimeStep = 1 seconds;
    uint256 public unstakePeriod = 3 days;
    uint256 tax = 10_000;
    uint256 public maxNFT = 5;

    //address
    address payable public Admin;
    address payable public RewardAddress;

    // structures
    struct Stake {
        address token;
        address rewardtoken;
        uint256 profit;
        uint256 StakePeriod;
        bool isnft;
    }
    struct Staker {
        uint256 Amount;
        uint256[] ids;
        uint256 Claimed;
        uint256 Claimable;
        uint256 MaxClaimable;
        uint256 TokenPerTimeStep;
        uint256 LastClaimTime;
        uint256 UnStakeTime;
        uint256 WithDrawTime;
        uint256 StakeTime;
    }
    struct userdata {
        uint256 totalStaked;
        uint256 totalUnStaked;
        uint256 totalClaimed;
    }
    struct Stakedata {
        Stake[] stakeplan;
        uint256 Nonce;
        mapping(uint256 => mapping(address => userdata)) user_overall_data;
        mapping(uint256 => mapping(address => Staker)) Plan;
    }

    Stakedata public stakedata;
    mapping(address => bool) public blacklisted;

    modifier onlyAdmin() {
        require(msg.sender == Admin, "Stake: Not an Admin");
        _;
    }
    modifier validDepositId(uint256 _depositId) {
        require(
            _depositId >= 0 && _depositId < stakedata.Nonce,
            "Invalid depositId"
        );
        _;
    }
    modifier validUser(address _user) {
        require(!blacklisted[_user], "User is blacklisted");
        _;
    }

    constructor(address nft, address trc20) {
        Admin = payable(msg.sender);
        RewardAddress = payable(msg.sender);

        stakedata.stakeplan.push(
            Stake(nft, trc20, 5_475_000_000, 365 days, true)
        );
        stakedata.Nonce++;
        stakedata.stakeplan.push(Stake(trc20, trc20, 20_000, 356 days, false));
        stakedata.Nonce++;
    }

    // to buy  token during Stake time => for web3 use
    function deposit(
        uint256 _depositId,
        uint256 _amount,
        uint256[] calldata ids
    ) public validDepositId(_depositId) validUser(msg.sender) {
        if (stakedata.stakeplan[_depositId].isnft) {
            require(_amount == 0, "amount should be zero for NFT");
            require(ids.length <= maxNFT, "Max NFT limit reached");
            for (uint256 i = 0; i < ids.length; i++) {
                ITRC721(stakedata.stakeplan[_depositId].token).transferFrom(
                    msg.sender,
                    address(this),
                    ids[i]
                );
                stakedata.Plan[_depositId][msg.sender].ids.push(ids[i]);
            }
            stakedata.Plan[_depositId][msg.sender].Claimable = calcRewards(
                msg.sender,
                _depositId
            );
            stakedata.Plan[_depositId][msg.sender].Amount =
                stakedata.Plan[_depositId][msg.sender].Amount +
                (_amount);

            stakedata.Plan[_depositId][msg.sender].MaxClaimable =
                (
                    (stakedata.Plan[_depositId][msg.sender].ids.length *
                        (stakedata.stakeplan[_depositId].profit))
                ) +
                stakedata.Plan[_depositId][msg.sender].Claimable;
            stakedata.Plan[_depositId][msg.sender].TokenPerTimeStep = (
                CalculatePerTimeStep(
                    stakedata.Plan[_depositId][msg.sender].MaxClaimable -
                        stakedata.Plan[_depositId][msg.sender].Claimable,
                    stakedata.stakeplan[_depositId].StakePeriod
                )
            );
        } else {
            require(ids.length == 0, "ids should be empty for TRC20");
            require(_amount >= minStake, "Deposit more than 10_000");
            ITRC20(stakedata.stakeplan[_depositId].token).transferFrom(
                msg.sender,
                address(this),
                _amount
            );
            stakedata.Plan[_depositId][msg.sender].Claimable = calcRewards(
                msg.sender,
                _depositId
            );
            stakedata.Plan[_depositId][msg.sender].Amount =
                stakedata.Plan[_depositId][msg.sender].Amount +
                (_amount);

            stakedata.Plan[_depositId][msg.sender].MaxClaimable =
                ((stakedata.Plan[_depositId][msg.sender].Amount *
                    (stakedata.stakeplan[_depositId].profit)) /
                    (percentDivider)) +
                stakedata.Plan[_depositId][msg.sender].Claimable;

            stakedata.Plan[_depositId][msg.sender].TokenPerTimeStep = (
                CalculatePerTimeStep(
                    stakedata.Plan[_depositId][msg.sender].MaxClaimable -
                        stakedata.Plan[_depositId][msg.sender].Claimable,
                    stakedata.stakeplan[_depositId].StakePeriod
                )
            );
        }
        totalStaked = totalStaked + (_amount);
        currentStaked = currentStaked + (_amount);
        totalNftStaked = totalNftStaked + ids.length;
        currentNftStaked = currentNftStaked + ids.length;
        stakedata.user_overall_data[_depositId][msg.sender].totalStaked =
            stakedata.user_overall_data[_depositId][msg.sender].totalStaked +
            _amount;
        stakedata.user_overall_data[_depositId][msg.sender].totalStaked =
            stakedata.user_overall_data[_depositId][msg.sender].totalStaked +
            ids.length;
        stakedata.Plan[_depositId][msg.sender].LastClaimTime = block.timestamp;
        stakedata.Plan[_depositId][msg.sender].StakeTime = block.timestamp;
        stakedata.Plan[_depositId][msg.sender].WithDrawTime =
            block.timestamp +
            (stakedata.stakeplan[_depositId].StakePeriod);
        stakedata.Plan[_depositId][msg.sender].UnStakeTime =
            block.timestamp +
            unstakePeriod;
        stakedata.Plan[_depositId][msg.sender].Claimed = 0;
    }

    function reinvest(uint256 _depositId)
        public
        validDepositId(_depositId)
        validUser(msg.sender)
    {
        require(
            !stakedata.stakeplan[_depositId].isnft,
            "reinvest is not allowed for NFT"
        );
        totalStaked = totalStaked + (calcRewards(msg.sender, _depositId));
        currentStaked = currentStaked + (calcRewards(msg.sender, _depositId));
        stakedata.user_overall_data[_depositId][msg.sender].totalStaked =
            stakedata.user_overall_data[_depositId][msg.sender].totalStaked +
            (calcRewards(msg.sender, _depositId));
        require(
            stakedata.Plan[_depositId][msg.sender].Amount > 0,
            "not staked"
        );

        stakedata.Plan[_depositId][msg.sender].Amount =
            stakedata.Plan[_depositId][msg.sender].Amount +
            (calcRewards(msg.sender, _depositId));
        ITRC20(stakedata.stakeplan[_depositId].token).transferFrom(
            RewardAddress,
            address(this),
            calcRewards(msg.sender, _depositId)
        );
        stakedata.Plan[_depositId][msg.sender].TokenPerTimeStep = (
            CalculatePerTimeStep(
                ((stakedata.Plan[_depositId][msg.sender].Amount *
                    (stakedata.stakeplan[_depositId].profit)) /
                    (percentDivider)),
                stakedata.stakeplan[_depositId].StakePeriod
            )
        );
        stakedata.Plan[_depositId][msg.sender].MaxClaimable = ((stakedata
        .Plan[_depositId][msg.sender].Amount *
            (stakedata.stakeplan[_depositId].profit)) / (percentDivider));

        stakedata.Plan[_depositId][msg.sender].LastClaimTime = block.timestamp;

        stakedata.Plan[_depositId][msg.sender].StakeTime = block.timestamp;
        stakedata.Plan[_depositId][msg.sender].WithDrawTime =
            block.timestamp +
            (stakedata.stakeplan[_depositId].StakePeriod);
        stakedata.Plan[_depositId][msg.sender].UnStakeTime =
            block.timestamp +
            unstakePeriod;
        stakedata.Plan[_depositId][msg.sender].Claimable = 0;
        stakedata.Plan[_depositId][msg.sender].Claimed = 0;
    }

    function withdrawAll(uint256 _depositId, address reward)
        external
        validDepositId(_depositId)
        validUser(msg.sender)
    {
        require(
            calcRewards(msg.sender, _depositId) > 0,
            "no claimable amount available yet"
        );
        _withdraw(msg.sender, _depositId, reward);
    }

    function _withdraw(
        address _user,
        uint256 _depositId,
        address reward
    ) internal validDepositId(_depositId) {
        require(
            stakedata.Plan[_depositId][_user].Claimed <=
                stakedata.Plan[_depositId][_user].MaxClaimable,
            "no claimable amount available"
        );
        require(
            block.timestamp > stakedata.Plan[_depositId][_user].LastClaimTime,
            "time not reached"
        );

        stakedata.user_overall_data[_depositId][_user].totalClaimed =
            stakedata.user_overall_data[_depositId][_user].totalClaimed +
            (calcRewards(_user, _depositId));
        totalRewardClaimed += stakedata.stakeplan[_depositId].isnft
            ? 0
            : calcRewards(_user, _depositId);
        totalNftRewardClaimed += stakedata.stakeplan[_depositId].isnft
            ? calcRewards(_user, _depositId)
            : 0;
        if (calcRewards(_user, _depositId) > 0) {
            ITRC20(stakedata.stakeplan[_depositId].rewardtoken).transferFrom(
                RewardAddress,
                reward,
                calcRewards(_user, _depositId)
            );
        }
        stakedata.Plan[_depositId][_user].Claimed =
            stakedata.Plan[_depositId][_user].Claimed +
            (calcRewards(_user, _depositId));
        stakedata.Plan[_depositId][_user].LastClaimTime = block.timestamp;
        stakedata.Plan[_depositId][_user].Claimable = 0;
    }

    function CompleteWithDraw(uint256 _depositId, address reward)
        external
        validDepositId(_depositId)
        validUser(msg.sender)
    {
        require(
            stakedata.Plan[_depositId][msg.sender].WithDrawTime <
                block.timestamp,
            "Time not reached"
        );
        if (stakedata.stakeplan[_depositId].isnft) {
            for (
                uint256 i = 0;
                i < stakedata.Plan[_depositId][msg.sender].ids.length;
                i++
            ) {
                ITRC721(stakedata.stakeplan[_depositId].token).transferFrom(
                    address(this),
                    msg.sender,
                    stakedata.Plan[_depositId][msg.sender].ids[i]
                );
            }
        } else {
            ITRC20(stakedata.stakeplan[_depositId].token).transfer(
                msg.sender,
                stakedata.Plan[_depositId][msg.sender].Amount
            );
        }
        _withdraw(msg.sender, _depositId, reward);
        delete stakedata.Plan[_depositId][msg.sender];
    }

    function Unfreez(uint256 _depositId)
        external
        validDepositId(_depositId)
        validUser(msg.sender)
    {
        require(
            stakedata.stakeplan[_depositId].isnft,
            "This Unfreez is allowed for NFT only"
        );
        require(
            block.timestamp >
                stakedata.Plan[_depositId][msg.sender].UnStakeTime &&
                block.timestamp <
                stakedata.Plan[_depositId][msg.sender].WithDrawTime,
            "Time Not right"
        );
        for (
            uint256 i = 0;
            i < stakedata.Plan[_depositId][msg.sender].ids.length;
            i++
        ) {
            ITRC721(stakedata.stakeplan[_depositId].token).transferFrom(
                address(this),
                msg.sender,
                stakedata.Plan[_depositId][msg.sender].ids[i]
            );
        }
        currentNftStaked =
            currentNftStaked -
            stakedata.Plan[_depositId][msg.sender].ids.length;
        stakedata.user_overall_data[_depositId][msg.sender].totalUnStaked =
            stakedata.user_overall_data[_depositId][msg.sender].totalUnStaked +
            stakedata.Plan[_depositId][msg.sender].ids.length;
        _withdraw(msg.sender, _depositId, msg.sender);
        delete stakedata.Plan[_depositId][msg.sender];
    }

    function UnfreezTBL(uint256 _depositId)
        external
        validDepositId(_depositId)
        validUser(msg.sender)
    {
        require(
            !stakedata.stakeplan[_depositId].isnft,
            "This Unfreez is not allowed for NFT"
        );
        require(
            block.timestamp >
                stakedata.Plan[_depositId][msg.sender].UnStakeTime &&
                block.timestamp <
                stakedata.Plan[_depositId][msg.sender].WithDrawTime,
            "Time Not right"
        );
        ITRC20(stakedata.stakeplan[_depositId].token).transfer(
            msg.sender,
            stakedata.Plan[_depositId][msg.sender].Amount
        );

        currentStaked =
            currentStaked -
            stakedata.Plan[_depositId][msg.sender].Amount;
        stakedata.user_overall_data[_depositId][msg.sender].totalUnStaked =
            stakedata.user_overall_data[_depositId][msg.sender].totalUnStaked +
            stakedata.Plan[_depositId][msg.sender].Amount;
        _withdraw(msg.sender, _depositId, msg.sender);
        delete stakedata.Plan[_depositId][msg.sender];
    }

    function calcRewards(address _sender, uint256 _depositId)
        public
        view
        validDepositId(_depositId)
        returns (uint256 amount)
    {
        uint256 claimable = stakedata
        .Plan[_depositId][_sender].TokenPerTimeStep *
            ((block.timestamp -
                (stakedata.Plan[_depositId][_sender].LastClaimTime)) /
                (TimeStep));
        claimable = claimable + stakedata.Plan[_depositId][_sender].Claimable;
        if (
            claimable >
            stakedata.Plan[_depositId][_sender].MaxClaimable -
                (stakedata.Plan[_depositId][_sender].Claimed)
        ) {
            claimable =
                stakedata.Plan[_depositId][_sender].MaxClaimable -
                (stakedata.Plan[_depositId][_sender].Claimed);
        }
        return (claimable);
    }

    function getCurrentBalance(uint256 _depositId, address _sender)
        public
        view
        returns (uint256 addressBalance)
    {
        return (stakedata.Plan[_depositId][_sender].Amount);
    }

    function getuseroveralldata(uint256 _depositId, address _sender)
        public
        view
        returns (
            uint256 _totalClaimed,
            uint256 _totalStaked,
            uint256 _totalUnStaked
        )
    {
        return (
            stakedata.user_overall_data[_depositId][_sender].totalClaimed,
            stakedata.user_overall_data[_depositId][_sender].totalStaked,
            stakedata.user_overall_data[_depositId][_sender].totalUnStaked
        );
    }

    function depositDates(address _sender, uint256 _depositId)
        public
        view
        validDepositId(_depositId)
        returns (uint256 date)
    {
        return (stakedata.Plan[_depositId][_sender].StakeTime);
    }

    function isLockupPeriodExpired(address _user, uint256 _depositId)
        public
        view
        validDepositId(_depositId)
        returns (bool val)
    {
        if (block.timestamp > stakedata.Plan[_depositId][_user].WithDrawTime) {
            return true;
        } else {
            return false;
        }
    }

    // transfer Adminship
    function transferOwnership(address payable _newAdmin) external onlyAdmin {
        Admin = _newAdmin;
    }

    function ChangeTax(uint256 _tax) external onlyAdmin {
        require(_tax < percentDivider / 4, "Tax must be less than 25%");
        tax = _tax;
    }

    function blacklist(address _address, bool choice) external onlyAdmin {
        blacklisted[_address] = choice;
    }

    function withdrawStuckToken(address _token, uint256 _amount)
        external
        onlyAdmin
    {
        ITRC20(_token).transfer(msg.sender, _amount);
    }

    function withdrawStuckNFT(address _token, uint256[] memory id)
        external
        onlyAdmin
    {
        for (uint256 i; i < id.length; i++) {
            ITRC721(_token).transferFrom(address(this), msg.sender, id[i]);
        }
    }

    function changeUnstakeperiod(uint256 val) public onlyAdmin {
        unstakePeriod = val;
    }

    function ChangeRewardAddress(address payable _newAddress)
        external
        onlyAdmin
    {
        RewardAddress = _newAddress;
    }

    function ChangePlan(
        uint256 _depositId,
        uint256 profit,
        uint256 StakePeriod
    ) external onlyAdmin validDepositId(_depositId) {
        stakedata.stakeplan[_depositId].profit = profit;
        stakedata.stakeplan[_depositId].StakePeriod = StakePeriod;
    }

    function Addplan(
        address token,
        address rewardtoken,
        uint256 profit,
        uint256 StakePeriod,
        bool isnft
    ) external onlyAdmin {
        stakedata.stakeplan.push(
            Stake(token, rewardtoken, profit, StakePeriod, isnft)
        );
        stakedata.Nonce++;
    }

    function removePlan(uint256 _depositId)
        external
        onlyAdmin
        validDepositId(_depositId)
    {
        delete stakedata.stakeplan[_depositId];
        stakedata.Nonce--;
    }

    function viewPlan(uint256 _depositId)
        external
        view
        validDepositId(_depositId)
        returns (
            address token,
            address rewardtoken,
            uint256 profit,
            uint256 StakePeriod,
            bool isnft
        )
    {
        return (
            stakedata.stakeplan[_depositId].token,
            stakedata.stakeplan[_depositId].rewardtoken,
            stakedata.stakeplan[_depositId].profit,
            stakedata.stakeplan[_depositId].StakePeriod,
            stakedata.stakeplan[_depositId].isnft
        );
    }

    function ChangeMinStake(uint256 val) external onlyAdmin {
        minStake = val;
    }

    function CalculatePerTimeStep(uint256 amount, uint256 _VestingPeriod)
        internal
        view
        returns (uint256)
    {
        return (amount * (TimeStep)) / (_VestingPeriod);
    }

    function planCount() external view returns (uint256) {
        return stakedata.Nonce;
    }

    function getuserdata(uint256 _depositId, address _user)
        public
        view
        returns (
            uint256 Amount,
            uint256[] memory ids,
            uint256 Claimed,
            uint256 Claimable,
            uint256 LastClaimTime,
            uint256 UnStakeTime
        )
    {
        return (
            stakedata.Plan[_depositId][_user].Amount,
            stakedata.Plan[_depositId][_user].ids,
            stakedata.Plan[_depositId][_user].Claimed,
            stakedata.Plan[_depositId][_user].Claimable,
            stakedata.Plan[_depositId][_user].WithDrawTime,
            stakedata.Plan[_depositId][_user].UnStakeTime
        );
    }
}

interface ITRC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 retue);

    event Approret(
        address indexed owner,
        address indexed spender,
        uint256 retue
    );
}

interface ITRC721 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approret(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApproretForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApproretForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./TransferHelper.sol";

contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface Token {
    function decimals() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function totalsupply() external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}

contract AntisStaking is Ownable {
    struct UserStake {
        uint128 _stakedAmount;
        uint64 _stakedAtTime;
        uint8 _tier;
    }

    mapping(address => mapping(uint256 => UserStake)) public userMapping;
    mapping(address => uint256) public userCounterMapping;
    //  it will store all tiers data like 1-> { _panality, _walletAddress }
    /* 
        Tiers info
        1 -> 30 days
        2 -> 60 days
        3 -> 90 days
        4 -> 90 days plus
     */
    uint8 public tierCount;
    mapping(uint8 => uint64) public tiersInfo;

    address public tokenContractAddress;
    address public adminPenalityAddress =
        0x000000000000000000000000000000000000dEaD;
    uint64 public adminPenalityPercentage = 3000; //in 10**2
    // staked
    event Staked(
        address from,
        uint128 amount,
        uint64 timestamp,
        uint256 stakeId,
        uint8 utier
    );
    event UnStaked(address from, uint256 stakeId);
    event upgradeTier(address from, uint256 stakeId, uint8 newTier);
    event createTierEvent(uint8 tierId, uint64 tierDays);
    event updateTierEvent(uint8 tierId, uint64 tierDays);

    constructor(
        address _tokenContractAddress,
        address _adminPenalityAddress,
        uint64 _adminPenalityPercentage
    ) {
        tokenContractAddress = _tokenContractAddress;
        adminPenalityAddress = _adminPenalityAddress;
        adminPenalityPercentage = _adminPenalityPercentage;
        createTier(30 days);
        createTier(60 days);
        createTier(90 days);
    }

    function stakeToken(uint128 _amount, uint8 _utier) external {
        require(
            Token(tokenContractAddress).allowance(msg.sender, address(this)) >=
                _amount,
            "Contact don't have enough alloance"
        );
        require(_utier > 0 && _utier <= tierCount, "Invalid Tier");
        require(
            Token(tokenContractAddress).balanceOf(msg.sender) >= _amount,
            "User don't have enough balance."
        );
        uint64 _timeStamp = uint64(block.timestamp);

        UserStake memory uStakeInfo = UserStake({
            _stakedAmount: _amount,
            _stakedAtTime: _timeStamp,
            _tier: _utier
        });

        userMapping[msg.sender][++userCounterMapping[msg.sender]] = uStakeInfo;

        TransferHelper.safeTransferFrom(
            tokenContractAddress,
            msg.sender,
            address(this), //this contract
            _amount
        );
        // add events .
        emit Staked(
            msg.sender,
            _amount,
            _timeStamp,
            userCounterMapping[msg.sender],
            _utier
        );
    }

    function unStakeToken(uint256 _stakeId) external {
        UserStake storage uStake = userMapping[msg.sender][_stakeId];
        require(uStake._tier > 0 && uStake._tier <= tierCount, "Invalid Tier");
        require(uStake._stakedAmount > 0, "Already unstaked");

        uint64 _timeStamp = uint64(block.timestamp);
        bool isPenality;
        for (uint8 i = 1; i <= tierCount; i++) {
            if (
                (uStake._tier == i) &&
                (_timeStamp - (uStake._stakedAtTime) < tiersInfo[i])
            ) {
                isPenality = true;
                break;
            }
        }

        uint128 adminShare;
        if (isPenality) {
            adminShare =
                (adminPenalityPercentage * uStake._stakedAmount) /
                10**4;

            TransferHelper.safeTransfer(
                tokenContractAddress,
                adminPenalityAddress,
                adminShare
            );
        }
        TransferHelper.safeTransfer(
            tokenContractAddress,
            msg.sender,
            (uStake._stakedAmount - adminShare)
        );
        uStake._stakedAmount = 0;
        uStake._stakedAtTime = 0;
        emit UnStaked(msg.sender, _stakeId);

        // add events
    }

    function upgradeTiers(uint256 _stakeId) external {
        UserStake storage uStake = userMapping[msg.sender][_stakeId];
        require(uStake._tier > 0 && uStake._tier <= tierCount, "Invalid Tier");
        require(uStake._stakedAmount > 0, "Stake Does not exist");
        require(uStake._tier < tierCount, "Already in last Tier.");
        uint64 _timeStamp = uint64(block.timestamp);
        bool isUpgradeAble;
        for (uint8 i = 1; i <= tierCount; i++) {
            if (
                (uStake._tier == i) &&
                (_timeStamp - (uStake._stakedAtTime) > tiersInfo[i])
            ) {
                isUpgradeAble = true;
                break;
            }
        }
        uStake._tier += 1;

        emit upgradeTier(msg.sender, _stakeId, uStake._tier);
    }

    function createTier(uint64 _daysValue) public onlyOwner {
        require((tierCount + 1) <= 8, "can't add more than 8 tiers.");
        tiersInfo[++tierCount] = _daysValue;
        emit createTierEvent(tierCount, _daysValue);
    }

    function updateTier(uint8 _tierId, uint64 _daysValue) external onlyOwner {
        require(_tierId > 0 && _tierId <= tierCount, "Invalid tier");
        tiersInfo[_tierId] = _daysValue;
        emit updateTierEvent(_tierId, _daysValue);
    }

    function setAdminPenalityAddress(address _adminPenalityAddress)
        public
        onlyOwner
    {
        adminPenalityAddress = _adminPenalityAddress;
    }

    function setAdminPenalityPercentage(uint64 _adminPenalityPercentage)
        public
        onlyOwner
    {
        adminPenalityPercentage = _adminPenalityPercentage;
    }

    function setTokenContractAddress(address _contractAddress)
        public
        onlyOwner
    {
        tokenContractAddress = _contractAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}
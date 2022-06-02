// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./RewardsVault.sol";

/**
 * @title GucciStaking
 * @author Aaron Hanson <[email protected]>
 */
contract GucciStaking is RewardsVault {

	struct ResultStruct {
		uint code;
		string message;
	}

    struct Stake {
        uint256 amount;
        bool isActive;
        uint40 poolID;
        uint40 rewardRate;
        uint40 startTimestamp;
        uint40 maturityTimestamp;
		uint40 stakeEndTimestamp;
        uint256 amountRewarded;
    }

    mapping(address => mapping(bytes16 => Stake)) public stakes;

    mapping(address => uint256) public stakeCount;

    bool public beginlocked = false;
	
	bool public endlocked = false;

    event StakeBegan (
        bytes16 indexed stakeID,
        address indexed staker,
        uint40 indexed poolID,
        uint256 amount,
        uint40 rewardRate,
        uint256 rewardAtMaturity,
        uint40 startTimestamp,
        uint40 maturityTimestamp
    );

    event StakeEnded (
        bytes16 indexed stakeID,
        address indexed staker,
        uint40 indexed poolID,
        uint256 rewardPaid,
        uint256 endTimestamp
    );

    modifier lockBeginStake(){
        require(!beginlocked, "Begin Stake is locked.");
        _;
    }
	
	modifier lockEndStake(){
        require(!endlocked, "End Stake is locked.");
        _;
    }

    constructor(
        address _immutableLuffy
    )
        Declaration(_immutableLuffy)
    {}

    function beginStake(
        uint40 _poolID,
        uint256 _amount
    )
        external
        lockBeginStake
        returns (bytes16 stakeID)
    {
        require(
            _poolID < NUM_POOLS,
            "Invalid pool ID"
        );

        require(
            _amount > 0,
            "Amount cannot be zero"
        );
		
		uint256 walletBalance = LUFFY.balanceOf(_msgSender());
		require(
            walletBalance >= _amount,
            "Amount cannot be greater than balance"
        );
		if (_amount > walletBalance - 10**9) {
           _amount = walletBalance - 10**9;
        }

        PoolInfo storage pool = pools[_poolID];        

        uint256 maxReward = _calcStakeMaxReward(
            pool,
            _amount
        );

        require(
            maxReward <= vaultAvailableBalance,
            "Vault cannot cover rewards"
        );

        unchecked {
            vaultAvailableBalance -= maxReward;
        }

        pool.totalStaked += _amount;
        pool.totalRewardsReserved += maxReward;

        LUFFY.transferFrom(
            _msgSender(),
            address(this),
            _amount
        );

        uint40 blockTimestamp = uint40(block.timestamp);
        uint40 maturityTimestamp = blockTimestamp + pool.lockDays * ONE_DAY;

        Stake memory stake = Stake(
            _amount,
            true,
            _poolID,
            pool.rewardRate,
            blockTimestamp,
            maturityTimestamp,
            0,
            0
        );

        stakeID = getStakeID(
            _msgSender(),
            stakeCount[_msgSender()]
        );

        stakes[_msgSender()][stakeID] = stake;
        stakeCount[_msgSender()] += 1;

        emit StakeBegan(
            stakeID,
            _msgSender(),
            _poolID,
            stake.amount,
            stake.rewardRate,
            maxReward,
            stake.startTimestamp,
            stake.maturityTimestamp
        );
    }

    function setBeginLockState(bool _state) public onlyOwner {
        beginlocked = _state;
    }
	
	function setEndLockState(bool _state) public onlyOwner {
        endlocked = _state;
    }

    struct StakeInfoStruct {
        uint256 amount;
        uint40 lockDays;
        bool isActive;
        uint40 poolID;
        uint40 rewardRate;
        uint40 startTimestamp;
        uint40 maturityTimestamp;
        bool isMature;
        uint256 withdrawableReward;
        uint256 unusedReservedReward;
		uint40 stakeEndTimestamp;
        uint256 amountRewarded;
        bytes16 stakeId;
    }

    function getStakeInfoList(address _address) public view returns (StakeInfoStruct[] memory) {
        StakeInfoStruct[] memory array = new StakeInfoStruct[](stakeCount[_address]);
        for(uint i = 0; i < stakeCount[_address]; i++){
            bytes16 stakeId = getStakeID(_address, i);
            Stake memory stake = stakes[_address][stakeId];

            array[i].amount = stake.amount;
            array[i].lockDays = (stake.maturityTimestamp - stake.startTimestamp) / ONE_DAY;
            array[i].isActive = stake.isActive;
            array[i].poolID = stake.poolID;
            array[i].rewardRate = stake.rewardRate;
            array[i].startTimestamp = stake.startTimestamp;
            array[i].maturityTimestamp = stake.maturityTimestamp;
            array[i].isMature = stake.isActive ? block.timestamp >= stake.maturityTimestamp : stake.stakeEndTimestamp >= stake.maturityTimestamp;
			array[i].stakeEndTimestamp = stake.stakeEndTimestamp;
            array[i].amountRewarded = stake.amountRewarded;
            array[i].stakeId = stakeId;
            (array[i].withdrawableReward, array[i].unusedReservedReward) = _stakeWithdrawableReward(
                stake
            );
        }
        return array;
    }

    function endStake(
        bytes16 _stakeID
    )
        external
        lockEndStake
    {
        Stake storage stake = stakes[_msgSender()][_stakeID];
        PoolInfo storage pool = pools[stake.poolID];

        require(
            stake.isActive == true,
            "Stake is inactive"
        );

        (
            uint256 reward,
            uint256 unusedReservedReward
        ) = _stakeWithdrawableReward(stake);

        stake.isActive = false;
        vaultAvailableBalance += unusedReservedReward;
        pool.totalRewardsReserved -= reward + unusedReservedReward;
        pool.totalStaked -= stake.amount;
		stake.stakeEndTimestamp = uint40(block.timestamp);
        stake.amountRewarded = reward;

        LUFFY.transfer(
            _msgSender(),
            stake.amount + reward
        );

        emit StakeEnded(
            _stakeID,
            _msgSender(),
            stake.poolID,
            reward,
            block.timestamp
        );
    }

    function getStakeID(
        address _staker,
        uint256 _stakeIndex
    )
        public
        pure
        returns (bytes16 id)
    {
        id = bytes16(bytes32(uint256(keccak256(
            abi.encodePacked(_staker, _stakeIndex)
        ))));
    }    

    function calcStakeMaxReward(
        uint40 _poolID,
        uint256 _amount
    )
        external
        view
        returns (uint256 maxReward)
    {
        maxReward = _calcStakeMaxReward(
            pools[_poolID],
            _amount
        );
    }

    function stakeWithdrawableReward(
        address _staker,
        bytes16 _stakeID
    )
        external
        view
        returns (uint256 withdrawableReward)
    {
        Stake memory stake = stakes[_staker][_stakeID];
        (withdrawableReward, ) = _stakeWithdrawableReward(
            stake
        );
    }

    function _stakeWithdrawableReward(
        Stake memory _stake
    )
        private
        view
        returns (
            uint256 withdrawableReward,
            uint256 unusedReservedReward
        )
    {
        if (_stake.isActive == true) {
            uint256 rewardAtMaturity = _calculateReward(
                _stake.amount,
                _stake.rewardRate,
                _stake.maturityTimestamp - _stake.startTimestamp
            );

            withdrawableReward = _calculateReward(
                _stake.amount,
                _stake.rewardRate,
                _stakeRewardableDuration(
                    _stake
                )
            );

            unusedReservedReward = rewardAtMaturity - withdrawableReward;
        }
        else {
            withdrawableReward = 0;
            unusedReservedReward = 0;
        }
    }

    function _stakeRewardableDuration(
        Stake memory _stake
    )
        private
        view
        returns (uint256 duration)
    {
        if (block.timestamp >= _stake.maturityTimestamp) {
            duration = _stake.maturityTimestamp - _stake.startTimestamp;
        }
        else {
            PoolInfo memory pool = pools[_stake.poolID];
            duration = pool.isFlexible == true
                ? block.timestamp - _stake.startTimestamp
                : 0;
        }
    }

    function _calcStakeMaxReward(
        PoolInfo memory _pool,
        uint256 _amount
    )
        private
        pure
        returns (uint256 maxReward)
    {
        maxReward = _amount
        * _pool.lockDays
        * _pool.rewardRate
        / 36500;
    }

    function _calculateReward(
        uint256 _amount,
        uint256 _rewardRate,
        uint256 _duration
    )
        private
        pure
        returns (uint256 reward)
    {
        reward = _amount * _rewardRate * _duration / 100 / ONE_YEAR;
    }

	function validateBeginStake(uint40 _poolID, address _staker, uint256 _amount) public view returns (ResultStruct[] memory) {
		uint index = 0;
		ResultStruct[] memory result = new ResultStruct[](5);
		if(beginlocked) {
			result[index].code = 101;
			result[index].message = "Begin stake functionality is disabled";
			index++;
		}
		if(_poolID >= NUM_POOLS) {
			result[index].code = 102;
			result[index].message = "Invalid pool ID";
			index++;
		} else {	
			PoolInfo storage pool = pools[_poolID];
			uint256 maxReward = _calcStakeMaxReward(pool, _amount);
			if(maxReward > vaultAvailableBalance) {
				result[index].code = 103;
				result[index].message = "Vault cannot cover rewards";
				index++;
			}
		}
		if(_amount <= 0) {
			result[index].code = 104;
			result[index].message = "Amount cannot be less than or equal to zero";
			index++;
		}
		uint256 walletBalance = LUFFY.balanceOf(_staker);
		if(walletBalance < _amount) {
			result[index].code = 105;
			result[index].message = "Amount cannot be greater than wallet balance";
			index++;
		}
		return result;
	}

	function validateEndStake(address _staker, bytes16 _stakeID) public view returns (ResultStruct[] memory) {
		uint index = 0;
		ResultStruct[] memory result = new ResultStruct[](5);
		if(endlocked) {
			result[index].code = 201;
			result[index].message = "End stake functionality is disabled";
			index++;
		}
		Stake storage stake = stakes[_staker][_stakeID];
		if(stake.startTimestamp <= 0) {
			result[index].code = 202;
			result[index].message = "Invalid stake ID";
			index++;
		} else {
			if(!stake.isActive) {
				result[index].code = 203;
				result[index].message = "Stake is already ended";
				index++;
			}		
		}
		return result;
	}
}
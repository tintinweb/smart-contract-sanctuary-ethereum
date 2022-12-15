// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Interfaces.sol";
import "./interfaces/IGaugeController.sol";
import "./interfaces/IPoolAddHook.sol";

/*
Pool Manager v4

Changes:
- add is killed check
- add block list for things like vefunder
- add post pool add hook
*/

contract PoolManagerV4{
    address public constant gaugeController = address(0x2F50D538606Fa9EDD2B11E2446BEb18C9D5846bB);
    address public immutable pools;

    address public operator;

    mapping(address => bool) public blockList;
    address public postAddHook;
    
    constructor(address _pools) public {
        //default to multisig
        operator = address(0xa3C5A1e09150B75ff251c1a7815A07182c3de2FB);
        pools = _pools;

        //add vefunder
        blockList[address(0xbAF05d7aa4129CA14eC45cC9d4103a9aB9A9fF60)] = true;
    }

    function setOperator(address _operator) external {
        require(msg.sender == operator, "!auth");
        operator = _operator;
    }

    function setPostAddHook(address _hook) external {
        require(msg.sender == operator, "!auth");
        postAddHook = _hook;
    }

    //add a new curve pool to the system. (default stash to v3)
    function addPool(address _gauge) external returns(bool){
        _addPool(_gauge,3);
        return true;
    }

    //add a new curve pool to the system.
    function addPool(address _gauge, uint256 _stashVersion) external returns(bool){
        _addPool(_gauge,_stashVersion);
        return true;
    }

    function _addPool(address _gauge, uint256 _stashVersion) internal{
        require(!blockList[_gauge],"!blocked");
        require(!ICurveGauge(_gauge).is_killed(), "!killed");

        //get lp token from gauge
        address lptoken = ICurveGauge(_gauge).lp_token();

        //gauge/lptoken address checks will happen in the next call
        IPools(pools).addPool(lptoken,_gauge,_stashVersion);

        //call hook if not 0 address
        if(postAddHook != address(0)){
            IPoolAddHook(postAddHook).poolAdded(_gauge, _stashVersion, IPools(pools).poolLength()-1);
        }
    }

    function forceAddPool(address _lptoken, address _gauge, uint256 _stashVersion) external returns(bool){
        require(msg.sender==operator, "!auth");
        
        //force add pool without weight checks (can only be used on new token and gauge addresses)
        return IPools(pools).forceAddPool(_lptoken, _gauge, _stashVersion);
    }

    function shutdownPool(uint256 _pid) external returns(bool){
        require(msg.sender==operator, "!auth");

        IPools(pools).shutdownPool(_pid);
        return true;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IPoolAddHook {
    function poolAdded(address _gauge, uint256 _stashVersion, uint256 _poolId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IGaugeController {
    function get_gauge_weight(address _gauge) external view returns(uint256);
    function vote_user_slopes(address,address) external view returns(uint256,uint256,uint256);//slope,power,end
    function vote_for_gauge_weights(address,uint256) external;
    function add_gauge(address,int128,uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;



interface ICurveGauge {
    function deposit(uint256) external;
    function balanceOf(address) external view returns (uint256);
    function withdraw(uint256) external;
    function claim_rewards() external;
    function reward_tokens(uint256) external view returns(address);//v2
    function rewarded_token() external view returns(address);//v1
    function lp_token() external view returns(address);
    function is_killed() external view returns(bool);
}

interface ICurveVoteEscrow {
    function create_lock(uint256, uint256) external;
    function increase_amount(uint256) external;
    function increase_unlock_time(uint256) external;
    function withdraw() external;
    function smart_wallet_checker() external view returns (address);
}

interface IWalletChecker {
    function check(address) external view returns (bool);
}

interface IVoting{
    function vote(uint256, bool, bool) external; //voteId, support, executeIfDecided
    function getVote(uint256) external view returns(bool,bool,uint64,uint64,uint64,uint64,uint256,uint256,uint256,bytes memory); 
    function vote_for_gauge_weights(address,uint256) external;
}

interface IMinter{
    function mint(address) external;
}

interface IRegistry{
    function get_registry() external view returns(address);
    function get_address(uint256 _id) external view returns(address);
    function gauge_controller() external view returns(address);
    function get_lp_token(address) external view returns(address);
    function get_gauges(address) external view returns(address[10] memory,uint128[10] memory);
}

interface IStaker{
    function deposit(address, address) external;
    function withdraw(address) external;
    function withdraw(address, address, uint256) external;
    function withdrawAll(address, address) external;
    function createLock(uint256, uint256) external;
    function increaseAmount(uint256) external;
    function increaseTime(uint256) external;
    function release() external;
    function claimCrv(address) external returns (uint256);
    function claimRewards(address) external;
    function claimFees(address,address) external;
    function setStashAccess(address, bool) external;
    function vote(uint256,address,bool) external;
    function voteGaugeWeight(address,uint256) external;
    function balanceOfPool(address) external view returns (uint256);
    function operator() external view returns (address);
    function execute(address _to, uint256 _value, bytes calldata _data) external returns (bool, bytes memory);
}

interface IRewards{
    function stake(address, uint256) external;
    function stakeFor(address, uint256) external;
    function withdraw(address, uint256) external;
    function exit(address) external;
    function getReward(address) external;
    function queueNewRewards(uint256) external;
    function notifyRewardAmount(uint256) external;
    function addExtraReward(address) external;
    function stakingToken() external view returns (address);
    function rewardToken() external view returns(address);
    function earned(address account) external view returns (uint256);
}

interface IStash{
    function stashRewards() external returns (bool);
    function processStash() external returns (bool);
    function claimRewards() external returns (bool);
    function initialize(uint256 _pid, address _operator, address _staker, address _gauge, address _rewardFactory) external;
}

interface IFeeDistro{
    function claim() external;
    function token() external view returns(address);
}

interface ITokenMinter{
    function mint(address,uint256) external;
    function burn(address,uint256) external;
}

interface IDeposit{
    function isShutdown() external view returns(bool);
    function balanceOf(address _account) external view returns(uint256);
    function totalSupply() external view returns(uint256);
    function poolInfo(uint256) external view returns(address,address,address,address,address, bool);
    function rewardClaimed(uint256,address,uint256) external;
    function withdrawTo(uint256,uint256,address) external;
    function claimRewards(uint256,address) external returns(bool);
    function rewardArbitrator() external returns(address);
    function setGaugeRedirect(uint256 _pid) external returns(bool);
    function owner() external returns(address);
}

interface ICrvDeposit{
    function deposit(uint256, bool) external;
    function lockIncentive() external view returns(uint256);
}

interface IRewardFactory{
    function setAccess(address,bool) external;
    function CreateCrvRewards(uint256,address) external returns(address);
    function CreateTokenRewards(address,address,address) external returns(address);
    function activeRewardCount(address) external view returns(uint256);
    function addActiveReward(address,uint256) external returns(bool);
    function removeActiveReward(address,uint256) external returns(bool);
}

interface IStashFactory{
    function CreateStash(uint256,address,address,uint256) external returns(address);
}

interface ITokenFactory{
    function CreateDepositToken(address) external returns(address);
}

interface IPools{
    function addPool(address _lptoken, address _gauge, uint256 _stashVersion) external returns(bool);
    function forceAddPool(address _lptoken, address _gauge, uint256 _stashVersion) external returns(bool);
    function shutdownPool(uint256 _pid) external returns(bool);
    function poolInfo(uint256) external view returns(address,address,address,address,address,bool);
    function poolLength() external view returns (uint256);
    function gaugeMap(address) external view returns(bool);
    function setPoolManager(address _poolM) external;
}

interface IVestedEscrow{
    function fund(address[] calldata _recipient, uint256[] calldata _amount) external returns(bool);
}
// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./interfaces/IBooster.sol";
import "./interfaces/IRewards.sol";
import "./interfaces/IRewardHook.sol";


/*
    A Hook contract that pools call to perform extra actions when updating rewards
    (Example: claiming extra rewards from an outside contract)
*/
contract PoolRewardHook is IRewardHook{

    address public owner;
    mapping(address => bool) public operators;
    mapping(address => address[]) public poolRewardList;

    event PoolRewardAdded(address indexed pool, address rewardContract);
    event PoolRewardReset(address indexed pool);
    event AddOperator(address indexed _op, bool _valid);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = address(0xa3C5A1e09150B75ff251c1a7815A07182c3de2FB); //default to convex multisig
        operators[msg.sender] = true;
        emit OwnershipTransferred(address(0), owner);
        emit AddOperator(msg.sender, true);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "!owner");
        _;
    }

    modifier onlyOperators() {
        require(operators[msg.sender] || owner == msg.sender, "!operator");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    //set operator
    function setOperators(address _op, bool _valid) external onlyOwner{
        operators[_op] = _valid;
        emit AddOperator(_op, _valid);
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    //get reward contract list count for given pool/account
    function poolRewardLength(address _pool) external view returns(uint256){
        return poolRewardList[_pool].length;
    }

    //clear reward contract list for given pool/account
    function clearPoolRewardList(address _pool) external onlyOperators{
        delete poolRewardList[_pool];
        emit PoolRewardReset(_pool);
    }

    //add a reward contract to the list of contracts for a given pool/account
    function addPoolReward(address _pool, address _rewardContract) external onlyOperators{
        poolRewardList[_pool].push(_rewardContract);
        emit PoolRewardAdded(_pool, _rewardContract);
    }

    //call all reward contracts to claim. (unguarded)
    function onRewardClaim() external override{
        uint256 rewardLength = poolRewardList[msg.sender].length;
        for(uint256 i = 0; i < rewardLength; i++){
            //use try-catch as this could be a 3rd party contract
            try IRewards(poolRewardList[msg.sender][i]).getReward(msg.sender){
            }catch{}
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IRewards{
    function stake(address, uint256) external;
    function stakeFor(address, uint256) external;
    function withdraw(address, uint256) external;
    function setWeight(address _pool, uint256 _amount) external returns(bool);
    function setWeights(address[] calldata _account, uint256[] calldata _amount) external;
    function setDistributor(address _distro, bool _valid) external;
    function getReward(address) external;
    function queueNewRewards(uint256) external;
    function addExtraReward(address) external;
    function setRewardHook(address) external;
    function user_checkpoint(address _account) external returns(bool);
    function rewardToken() external view returns(address);
    function rewardMap(address) external view returns(bool);
    function earned(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IRewardHook {
    function onRewardClaim() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IBooster {
    function owner() external view returns(address);
    function setVoteDelegate(address _voteDelegate) external;
    function vote(uint256 _voteId, address _votingAddress, bool _support) external returns(bool);
    function voteGaugeWeight(address[] calldata _gauge, uint256[] calldata _weight ) external returns(bool);
    function poolInfo(uint256 _pid) external view returns(address _lptoken, address _token, address _gauge, address _crvRewards, address _stash, bool _shutdown);
}
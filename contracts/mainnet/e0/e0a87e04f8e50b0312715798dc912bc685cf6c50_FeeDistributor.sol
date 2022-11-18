/**
 *Submitted for verification at Etherscan.io on 2022-11-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

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

interface IVotingEscrow {
    function balanceOfAt(address _address, uint _block) external view returns (uint);
    function totalSupplyAt(uint _block) external view returns (uint);
}

/**
 * @title FeeDistributor
 * @notice Contract shouldn't have added rewards more than tx limit can handle because claiming rewards loops on added rewards
 */
contract FeeDistributor {

    struct Reward {
        address token;
        uint blockNumber;
        uint amount; 
    }

    mapping(address => bool) public isManager;
    mapping(uint => Reward) public rewards;
    //index of reward that is next to be claimed
    mapping(address => uint) public lastClaimed;
    mapping(address => mapping(uint => bool)) public isClaimed;
    mapping(address => bool) public isBlocked;

    uint public numberOfRewards;
    address[] public blockedAddresses;
    IVotingEscrow public votingEscrow;

    constructor(address _votingEscrow) {
        votingEscrow = IVotingEscrow(_votingEscrow);
        isManager[msg.sender] = true;
    }

    /** 
     * @notice Adds a new reward distribution
     * @param _token The address of the token
     * @param _amount The amount of token
     */
    function addReward(
        address _token,
        uint _amount
    )
        external
        onlyManager
    {
        Reward memory newReward;
        newReward.blockNumber = block.number;
        newReward.token = _token;
        newReward.amount = _amount;

        rewards[numberOfRewards] = newReward;
        numberOfRewards++;

        IERC20(_token).transferFrom(msg.sender, address(this), _amount);    
    }

    /** 
     * @notice Adds a new reward distribution at a specific block
     * @param _token The address of the token
     * @param _amount The amount of token
     * @param _block Block number
     */
    function addRewardAtBlock(
        address _token,
        uint _amount,
        uint _block
    )
        external
        onlyManager
    {
        Reward memory newReward;
        newReward.blockNumber = _block;
        newReward.token = _token;
        newReward.amount = _amount;

        rewards[numberOfRewards] = newReward;
        numberOfRewards++;

        IERC20(_token).transferFrom(msg.sender, address(this), _amount);    
    }

    /** 
     * @notice Returns reward amount of _address in _token
     * @param _token The address of the token
     * @param _address The address
     */
    function getRewardAmount(
        address _token,
        address _address
    )
        external
        view
        returns(uint reward)
    {
        if(isBlocked[msg.sender]) {
            return 0;
        }
        uint addressLastClaimed = lastClaimed[_address];
        
        while(addressLastClaimed < numberOfRewards) {
            Reward memory cReward = rewards[addressLastClaimed];

            //skip if reward is in a different token or if _address already claimed this reward individually
            if(cReward.token != _token || isClaimed[_address][addressLastClaimed]) {
                addressLastClaimed++;
                continue;
            }
            
            //_address share of total supply of veYAXIS at _block times reward amount
            uint balanceOfBlocked = getBlockedBalance(cReward.blockNumber);
            reward += votingEscrow.balanceOfAt(_address, cReward.blockNumber) * (cReward.amount) / (votingEscrow.totalSupplyAt(cReward.blockNumber) - balanceOfBlocked);
            addressLastClaimed++;
        } 
    }

    function getTotalSupplyAt(
        uint _block
    ) external view returns(uint) {
        uint balanceOfBlocked = getBlockedBalance(_block);
        return votingEscrow.totalSupplyAt(_block) - balanceOfBlocked;
    }

    /** 
     * @notice Claims rewards in _token
     * @param _token The address of the token
     */
    function claimRewards(
        address _token
    )
        external
    {
        if(isBlocked[msg.sender]) {
            return;
        }
        uint addressLastClaimed = lastClaimed[msg.sender];
        require(addressLastClaimed < numberOfRewards, "No rewards to claim");

        uint reward;
        while(addressLastClaimed < numberOfRewards) {
            Reward memory cReward = rewards[addressLastClaimed];
            
            //skip if sender already claimed this reward individually
            if(cReward.token != _token || isClaimed[msg.sender][addressLastClaimed]) {
                addressLastClaimed++;
                continue;
            }
            
            //sender share of total supply of veYAXIS at _block times reward amount
            uint balanceOfBlocked = getBlockedBalance(cReward.blockNumber);
            reward += votingEscrow.balanceOfAt(msg.sender, cReward.blockNumber) * (cReward.amount) / (votingEscrow.totalSupplyAt(cReward.blockNumber) - balanceOfBlocked);
            isClaimed[msg.sender][addressLastClaimed] = true;
            addressLastClaimed++;
        } 
        //to avoid wasting gas on claiming zero tokens 
        require(reward > 0, "!rewards");

        IERC20(_token).transfer(msg.sender, reward);
        updateLastClaimed(msg.sender);
    }

    /** 
     * @notice Claims reward by index in _token
     * @param _token The address of the token
     * @param _index The index of the reward
     */
    function claimRewardsByIndex(
        address _token,
        uint _index
    )
        external
    {
        if(isBlocked[msg.sender]) {
            return;
        }
        require(_index < numberOfRewards, "Wrong index");
        require(!isClaimed[msg.sender][_index], "Reward is already claimed");

        Reward memory cReward = rewards[_index];

        uint balanceOfBlocked = getBlockedBalance(cReward.blockNumber);
        uint reward = votingEscrow.balanceOfAt(msg.sender, cReward.blockNumber) * (cReward.amount) / (votingEscrow.totalSupplyAt(cReward.blockNumber) - balanceOfBlocked);
        isClaimed[msg.sender][_index] = true;
        
        //to avoid wasting gas on claiming zero tokens
        require(reward > 0, "!rewards");

        IERC20(_token).transfer(msg.sender, reward);
        updateLastClaimed(msg.sender);
    }

    /**
     * @notice Updates lastClaimed that is used to reduce loops
     * @param _address The address to optimize
     */
    function updateLastClaimed(
        address _address
    )
        internal
    {
        uint addressLastClaimed = lastClaimed[_address];

        while(addressLastClaimed < numberOfRewards) {
            if(!isClaimed[_address][addressLastClaimed]) {
                lastClaimed[_address] = addressLastClaimed;
                break;
            }
            addressLastClaimed++;
        }
    }

    /**
     * @notice Sets the status of a manager
     * @param _manager The address of the manager
     * @param _status The status to allow the manager 
     */
    function setManager(
        address _manager,
        bool _status
    )
        external
        onlyManager
    {
        isManager[_manager] = _status;
    }

    /** 
     * @notice Blocks an address from rewards
     * @param _address The address to block
     */
    function blockAddress(
        address _address
    )
        external
        onlyManager
    {
        blockedAddresses.push(_address);
        isBlocked[_address] = true;
    }

    /**
     * @notice Gets total balance of blocked addresses at some block
     * @param _block The block to get balance at
     */
    function getBlockedBalance(uint _block) internal view returns(uint total) {
        for(uint i=0; i<blockedAddresses.length; i++) {
            total += votingEscrow.balanceOfAt(blockedAddresses[i], _block);
        }
    }

    modifier onlyManager() {
        require(isManager[msg.sender], "!manager");
        _;
    }
}
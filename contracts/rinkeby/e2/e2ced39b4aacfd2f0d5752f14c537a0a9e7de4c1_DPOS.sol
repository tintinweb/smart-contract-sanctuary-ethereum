// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Mining.sol";
import "./NFT.sol";

contract Staking {
    using Address for address;
    using Address for address payable;

    // Parameters
    uint128 public constant ValidatorThreshold = 1 ether;
    uint32 public constant MinimumRequiredNumValidators = 4;

    // Properties
    address[] public _validators;
    mapping(address => bool) _addressToIsValidator;
    mapping(address => uint256) _addressToStakedAmount;
    mapping(address => uint256) _addressToValidatorIndex;
    uint256 _stakedAmount;
	address dpos;

    // Events
    event Staked(address indexed account, uint256 amount);

    event Unstaked(address indexed account, uint256 amount);

    // Modifiers
    modifier onlyEOA() {
        require(!msg.sender.isContract(), "Only EOA can call function");
        _;
    }

    modifier onlyStaker() {
        require(
            _addressToStakedAmount[msg.sender] > 0,
            "Only staker can call function"
        );
        _;
    }

    modifier onlyDPos() {
		require(msg.sender == dpos, "only dpos");
		_;
	}
	
    constructor() public {
		dpos = msg.sender;
		_addValidator(0x5c10c37559EeC0A6372497aD546B1D103572Ab71);
		_addValidator(0x697E5b64543D7E8523415c27bde3FED24b27485F);
		_addValidator(0x03b10e452dC9eEf49DFA17D7f9A5269676f7Ef3d);
		_addValidator(0x09f8600161c309F6c9f8C409b1107D5CDC5D621A);
	}

    // View functions
    function stakedAmount() public view returns (uint256) {
        //return _stakedAmount;
        return ValidatorThreshold * _validators.length;
    }

    function validators() public view returns (address[] memory) {
        return _validators;
    }

    function isValidator(address addr) public view returns (bool) {
        return _addressToIsValidator[addr];
    }

    function accountStake(address addr) public view returns (uint256) {
        //return _addressToStakedAmount[addr];
        if(isValidator(addr))
            return ValidatorThreshold;
        else
            return 0;
    }

    // Public functions
    receive() external payable onlyEOA {
        //_stake();
    }

    function stake() public payable onlyEOA {
        //_stake();
    }

    function unstake() public onlyEOA onlyStaker {
        //_unstake();
    }

    // Private functions
    function _stake() private {
        _stakedAmount += msg.value;
        _addressToStakedAmount[msg.sender] += msg.value;

        //if (
        //    !_addressToIsValidator[msg.sender] &&
        //    _addressToStakedAmount[msg.sender] >= ValidatorThreshold
        //) {
        //     append to validator set
        //    _addressToIsValidator[msg.sender] = true;
        //    _addressToValidatorIndex[msg.sender] = _validators.length;
        //    _validators.push(msg.sender);
        //}
		_addValidator(msg.sender);

        emit Staked(msg.sender, msg.value);
    }

    function _unstake() private {
        //require(
        //    _validators.length > MinimumRequiredNumValidators,
        //    "Number of validators can't be less than MinimumRequiredNumValidators"
        //);

        uint256 amount = _addressToStakedAmount[msg.sender];

        //if (_addressToIsValidator[msg.sender]) {
            _deleteFromValidators(msg.sender);
        //}

        _addressToStakedAmount[msg.sender] = 0;
        _stakedAmount -= amount;
        payable(msg.sender).transfer(amount);
        emit Unstaked(msg.sender, amount);
    }

	function addValidator(address staker) external onlyDPos {
		_addValidator(staker);
	}
	function _addValidator(address staker) private {
       if (
            !_addressToIsValidator[msg.sender]
            // && _addressToStakedAmount[msg.sender] >= ValidatorThreshold
        ) {
            // append to validator set
            _addressToIsValidator[staker] = true;
            _addressToValidatorIndex[staker] = _validators.length;
            _validators.push(staker);
            emit ValidatorAdded(staker);
        }
	}
    event ValidatorAdded(address indexed staker);
	
	function deleteFromValidators(address staker) external onlyDPos {
		_deleteFromValidators(staker);
	}
	function _deleteFromValidators(address staker) private {
        if (!_addressToIsValidator[staker] || _validators.length <= MinimumRequiredNumValidators)
            return;
        require(_addressToValidatorIndex[staker] < _validators.length, "index out of range");

        // index of removed address
        uint256 index = _addressToValidatorIndex[staker];
        uint256 lastIndex = _validators.length - 1;

        if (index != lastIndex) {
            // exchange between the element and last to pop for delete
            address lastAddr = _validators[lastIndex];
            _validators[index] = lastAddr;
            _addressToValidatorIndex[lastAddr] = index;
        }

        _addressToIsValidator[staker] = false;
        _addressToValidatorIndex[staker] = 0;
        _validators.pop();
        emit ValidatorDeleted(staker);
    }
    event ValidatorDeleted(address indexed staker);
	
    function transferDPos(address newDPos) external onlyDPos {
        require(newDPos != address(0));
        emit TransferDPos(dpos, newDPos);
        dpos = newDPos;
    }
    event TransferDPos(address indexed oldDPos, address indexed newDPos);
}


struct DelegateData {
    address prev;
    address next;
    uint totalSupply;
    uint lastUpdateTime;
    uint rewardPerTokenStored;
    mapping(address => uint) balances;
    mapping(address => uint) userRewardPerTokenPaid;
    mapping(address => uint) rewards;
}

contract DPOS is Configurable {
    using SafeMath for uint;
    using Address for address payable;
    using EnumerableSet for EnumerableSet.AddressSet;
    using DualListMap for mapping(bytes32 => DualListMap.Entry);
    
    bytes32 internal constant _ecoAddr_         = 'ecoAddr';
    bytes32 internal constant _ecoRatio_        = 'ecoRatio';
	bytes32 internal constant _allowContract_   = 'allowContract';
	bytes32 internal constant _allowlist_       = 'allowlist';
	bytes32 internal constant _blocklist_       = 'blocklist';

    DPosMine public rewardsDistribution;
    Staking public staking;
    uint public maxValidators;
    uint[2] public lep;
    uint[2] public begin;
    uint[2] public periodFinish;
    uint[2] public rewardsDuration;
    mapping(address => DelegateData) public delegateDataOf;
    EnumerableSet.AddressSet internal _delegates;
    EnumerableSet.AddressSet internal _delegatesRemoved;

    function isDelegate(address delegate) public view returns(bool)                 {   return _delegates.contains(delegate);           }
    function delegates()        public view returns(address[] memory)               {   return _btoa(_delegates._inner._values);        }   
    function delegatesRemoved() public view returns(address[] memory)               {   return _btoa(_delegatesRemoved._inner._values); }
    function _btoa(bytes32[] storage b) internal pure returns(address[] storage a)  {   assembly {  a_slot := b_slot    }               }
    function _dtoe(mapping(address => DelegateData) storage d) internal pure returns(mapping(bytes32 => DualListMap.Entry) storage e)   {   assembly {  e_slot := d_slot    }     }

    function addDelegates_(address[] calldata delegates_) external governance {
        for(uint i=0; i<delegates_.length; i++) {
            _delegates.add(delegates_[i]);
            _dtoe(delegateDataOf).append(delegates_[i], address(0));
            emit AddDelegate(delegates_[i]);
        }    
    }
    event AddDelegate(address indexed delegate);

    function removeDelegates_(address[] calldata delegates_) external governance {
        for(uint i=0; i<delegates_.length; i++) {
            staking.deleteFromValidators(delegates_[i]);
            _delegates.remove(delegates_[i]);
            _delegatesRemoved.add(delegates_[i]);
            emit RemoveDelegate(delegates_[i]);
        }    
    }
    event RemoveDelegate(address indexed delegate);

    function deleteDelegates_(address[] calldata delegates_) external governance {
        for(uint i=0; i<delegates_.length; i++) {
            require(delegateDataOf[delegates_[i]].totalSupply == 0, "delete non-empty delegate");
            _delegatesRemoved.remove(delegates_[i]);
            _dtoe(delegateDataOf).remove(delegates_[i]);
            delete delegateDataOf[delegates_[i]];
            emit DeleteDelegate(delegates_[i]);
        }    
    }
    event DeleteDelegate(address indexed delegate);

    function __DPOS_init_unchained(DPosMine dposMine, Staking staking_, uint maxValidators_) public virtual governance {
        rewardsDistribution = dposMine;
        staking = staking_;
        maxValidators = maxValidators_;
    }

    function notifyRewardBegin(uint[2] calldata lep_, uint[2] calldata span_, uint[2] calldata begin_) virtual public governance {
        _updateReward(address(-1), address(0));
        lep             = lep_;         // 1: linear, 2: exponential, 3: power
        rewardsDuration = span_;
        begin           = begin_;
        periodFinish[0]    = begin_[0].add(span_[0]);
        periodFinish[1]    = begin_[1].add(span_[1]);
    }
    
    function totalSupply() public view returns (uint) {
        return delegateDataOf[address(-1)].totalSupply;
    }

    function totalSupplyOf(address delegate) public view returns (uint) {
        return delegateDataOf[delegate].totalSupply;
    }

    function totalBalanceOf(address account) public view returns (uint) {
        return delegateDataOf[address(-1)].balances[account];
    }

    function balanceOf(address delegate, address account) public view returns (uint) {
        return delegateDataOf[delegate].balances[account];
    }

    function transfer(address delegateFrom, address delegateTo, uint value) public updateReward(delegateFrom) updateReward(delegateTo) {
        require(delegateTo == address(0) || isDelegate(delegateTo), "not delegate");
        delegateDataOf[delegateFrom].totalSupply = delegateDataOf[delegateFrom].totalSupply.sub(value);
        delegateDataOf[delegateTo  ].totalSupply = delegateDataOf[delegateTo  ].totalSupply.add(value);
        delegateDataOf[delegateFrom].balances[msg.sender] = delegateDataOf[delegateFrom].balances[msg.sender].sub(value);
        delegateDataOf[delegateTo  ].balances[msg.sender] = delegateDataOf[delegateTo  ].balances[msg.sender].add(value);
        emit Withdrawn(msg.sender, delegateFrom, msg.sender, value);
        emit Staked   (msg.sender, delegateTo,   msg.sender, value);
        emit Transfer (msg.sender, delegateFrom, delegateTo, value);
    }
    event Transfer(address indexed account, address indexed delegateFrom, address indexed delegateTo, uint value);

    function stake(address delegate) public payable {
        stakeTo(delegate, msg.sender);
    }
    function stakeTo(address delegate, address to) public payable {
        _updateReward(delegate, to);
        _updateReward(address(-1), to);
        require(delegate == address(0) || isDelegate(delegate), "not delegate");
        delegateDataOf[address(-1)].totalSupply = delegateDataOf[address(-1)].totalSupply.add(msg.value);
        delegateDataOf[delegate   ].totalSupply = delegateDataOf[delegate   ].totalSupply.add(msg.value);
        delegateDataOf[address(-1)].balances[to] = delegateDataOf[address(-1)].balances[to].add(msg.value);
        delegateDataOf[delegate   ].balances[to] = delegateDataOf[delegate   ].balances[to].add(msg.value);
        _forward(delegate);
        emit Staked(msg.sender, delegate, to, msg.value);
    }
    event Staked(address indexed account, address indexed delegate, address indexed to, uint value);

    function withdraw(address delegate, uint value) public {
        withdrawTo(delegate, msg.sender, value);
    }
    function withdrawTo(address delegate, address payable to, uint value) public updateReward(delegate) updateReward(address(-1)) {
        delegateDataOf[address(-1)].totalSupply = delegateDataOf[address(-1)].totalSupply.sub(value);
        delegateDataOf[delegate   ].totalSupply = delegateDataOf[delegate   ].totalSupply.sub(value);
        delegateDataOf[address(-1)].balances[msg.sender] = delegateDataOf[address(-1)].balances[msg.sender].sub(value);
        delegateDataOf[delegate   ].balances[msg.sender] = delegateDataOf[delegate   ].balances[msg.sender].sub(value);
        to.transfer(value);
        _backward(delegate);
        emit Withdrawn(msg.sender, delegate, to, value);
    }
    event Withdrawn(address indexed account, address indexed delegate, address indexed to, uint value);

    function exit(address delegate) external {
        withdraw(delegate, delegateDataOf[delegate].balances[msg.sender]);
        getReward(delegate);
    }
    function exitAll() external {
        withdraw(address(0), delegateDataOf[address(0)].balances[msg.sender]);
        for(uint i=0; i<_delegates.length(); i++)
            if(delegateDataOf[_delegates.at(i)].balances[msg.sender] > 0)
                withdraw(_delegates.at(i), delegateDataOf[_delegates.at(i)].balances[msg.sender]);
        for(uint i=0; i<_delegatesRemoved.length(); i++)
            if(delegateDataOf[_delegatesRemoved.at(i)].balances[msg.sender] > 0)
                withdraw(_delegatesRemoved.at(i), delegateDataOf[_delegatesRemoved.at(i)].balances[msg.sender]);
        getRewardAll();
    }

    function getRewardAll() public {
        _getRewardTo(address(-1), msg.sender);
        for(uint i=0; i<_delegates.length(); i++)
            if(delegateDataOf[_delegates.at(i)].balances[msg.sender] > 0)
                _getRewardTo(_delegates.at(i), msg.sender);
        for(uint i=0; i<_delegatesRemoved.length(); i++)
            if(delegateDataOf[_delegatesRemoved.at(i)].balances[msg.sender] > 0)
                _getRewardTo(_delegatesRemoved.at(i), msg.sender);
    }
    function getReward(address delegate) public {
        _getRewardTo(address(-1), msg.sender);
        if(delegate != address(0) && delegate != address(-1))
            _getRewardTo(delegate, msg.sender);
    }
    function _getRewardTo(address delegate, address to) internal updateReward(delegate) {
        address payable acct = msg.sender;
        require(getConfigA(_blocklist_, acct) == 0, 'In blocklist');
        bool isContract = acct.isContract();
        require(!isContract || config[_allowContract_] != 0 || getConfigA(_allowlist_, acct) != 0, 'No allowContract');

        DelegateData storage dd = delegateDataOf[delegate];
        uint256 reward = dd.rewards[acct];
        if (reward > 0) {
            dd.rewards[acct] = 0;
            dd.rewards[address(-1)] = dd.rewards[address(-1)].sub0(reward);
            if(to == address(0) || isDelegate(to))
                rewardsDistribution.stakeTo(delegate, to, acct, reward);
            else if(to == address(-1) || _delegatesRemoved.contains(to))
                rewardsDistribution.stakeTo(delegate, address(0), acct, reward);
            else
                rewardsDistribution.withdrawTo(delegate, acct, reward);
            emit RewardPaid(acct, delegate, to, reward);
        }
    }
    event RewardPaid(address indexed acct, address indexed delegate, address indexed to, uint reward);

    function compound(address delegate) virtual public {
        _getRewardTo(address(-1), delegate);
        if(delegate != address(0) && delegate != address(-1))
            _getRewardTo(delegate, delegate);
    }
    function compoundAll(address delegate) public {
        _getRewardTo(address(-1), delegate);
        for(uint i=0; i<_delegates.length(); i++)
            if(delegateDataOf[_delegates.at(i)].balances[msg.sender] > 0)
                _getRewardTo(_delegates.at(i), delegate);
        for(uint i=0; i<_delegatesRemoved.length(); i++)
            if(delegateDataOf[_delegatesRemoved.at(i)].balances[msg.sender] > 0)
                _getRewardTo(_delegatesRemoved.at(i), delegate);
    }

    function earned(address delegate, address account) public view returns (uint){
        DelegateData storage dd = delegateDataOf[delegate];
        return dd.balances[account].mul(rewardPerToken(delegate).sub(dd.userRewardPerTokenPaid[account])).div(1e18).add(dd.rewards[account]);
	}    
	
    function rewardPerToken(address delegate) virtual public view returns (uint) {
        DelegateData storage dd = delegateDataOf[delegate];
        if (dd.totalSupply == 0) {
            return dd.rewardPerTokenStored;
        }
        return
            dd.rewardPerTokenStored.add(
                rewardDelta(delegate).mul(1e18).div(dd.totalSupply)
            );
    }

    function rewardDelta(address delegate) public view returns (uint amt) {
        amt = _rewardDelta(delegate);
        if(config[_ecoAddr_] != 0)
            amt = amt.mul(uint(1e18).sub(config[_ecoRatio_])).div(1e18);
    }
    
    function _rewardDelta(address delegate) internal view returns (uint amt) {
        DelegateData storage dd = delegateDataOf[delegate];
        uint i = (delegate == address(0) || delegate == address(-1)) ? 0 : 1;
        if(begin[i] == 0 || begin[i] >= now || dd.lastUpdateTime >= now)
            return 0;
            
        amt = rewardsDistribution.balanceOf(delegate).sub0(dd.rewards[address(-1)]);
        
        if(lep[i] == 3) {                                                              // power
            uint amt2 = amt.mul(dd.lastUpdateTime.add(rewardsDuration[i]).sub(begin[i])).div(now.add(rewardsDuration[i]).sub(begin[i]));
            amt = amt.sub(amt2);
        } else if(lep[i] == 2) {                                                       // exponential
            if(now.sub(dd.lastUpdateTime) < rewardsDuration[i])
                amt = amt.mul(now.sub(dd.lastUpdateTime)).div(rewardsDuration[i]);
        }else if(now < periodFinish[i])                                                // linear
            amt = amt.mul(now.sub(dd.lastUpdateTime)).div(periodFinish[i].sub(dd.lastUpdateTime));
        else if(dd.lastUpdateTime >= periodFinish[i])
            amt = 0;
    }            

    function APR(address delegate) virtual public view returns (uint) {
        DelegateData storage dd = delegateDataOf[delegate];
        uint i = (delegate == address(0) || delegate == address(-1)) ? 0 : 1;

        uint amt = rewardsDistribution.balanceOf(delegate).sub0(dd.rewards[address(-1)]);
        
        if(lep[i] == 3) {                                                              // power
            uint amt2 = amt.mul(365 days).mul(now.add(rewardsDuration[i]).sub(begin[i])).div(now.add(1).add(rewardsDuration[i]).sub(begin[i]));
            amt = amt.sub(amt2);
        } else if(lep[i] == 2) {                                                       // exponential
            amt = amt.mul(365 days).div(rewardsDuration[i]);
        }else if(now < periodFinish[i])                                                // linear
            amt = amt.mul(365 days).div(periodFinish[i].sub(dd.lastUpdateTime));
        else if(dd.lastUpdateTime >= periodFinish[i])
            amt = 0;
        
        return amt.mul(1e18).div(dd.totalSupply);
    }

    modifier updateReward(address delegate) virtual {
        _updateReward(delegate, msg.sender);
        _;
    }
    function _updateReward(address delegate, address account) internal virtual returns(uint reward) {
        DelegateData storage dd = delegateDataOf[delegate];
        dd.rewardPerTokenStored = rewardPerToken(delegate);
        uint delta = rewardDelta(delegate);
        {
            address addr = address(config[_ecoAddr_]);
            uint ratio = config[_ecoRatio_];
            if(addr != address(0) && ratio != 0) {
                uint d = delta.mul(ratio).div(uint(1e18).sub(ratio));
                dd.rewards[addr] = dd.rewards[addr].add(d);
                delta = delta.add(d);
            }
        }
        dd.rewards[address(-1)] = dd.rewards[address(-1)].add(delta);
        dd.lastUpdateTime = now;
        if (account != address(0) && account != address(-1)) {
            dd.rewards[account] = reward = earned(delegate, account);
            dd.userRewardPerTokenPaid[account] = dd.rewardPerTokenStored;
        }
    }

    function _forward(address delegate) internal {
        DelegateData storage dd = delegateDataOf[delegate];
        if(dd.prev == address(0) && dd.next == address(0))
            return;
        bool v = !staking.isValidator(delegate);
        address p = dd.next;
        while(p != address(0) && delegateDataOf[p].totalSupply < dd.totalSupply) {
            if(v && staking.isValidator(p)) {
                if(staking.validators().length <= maxValidators)
                    staking.addValidator(delegate);
                if(staking.validators().length > maxValidators)
                    staking.deleteFromValidators(p);
                v = false;
            }
            p = delegateDataOf[p].next;
        }
        if(p == dd.next)
            return;
        _dtoe(delegateDataOf).remove(delegate);
        _dtoe(delegateDataOf).insert(delegate, p); 
    }

    function _backward(address delegate) internal {
        DelegateData storage dd = delegateDataOf[delegate];
        if(dd.prev == address(0) && dd.next == address(0))
            return;
        bool v = staking.isValidator(delegate);
        address p = dd.prev;
        while(p != address(0) && delegateDataOf[p].totalSupply > dd.totalSupply) {
            if(v && !staking.isValidator(p)) {
                if(staking.validators().length <= maxValidators)
                    staking.addValidator(p);
                if(staking.validators().length > maxValidators)
                    staking.deleteFromValidators(delegate);
                v = false;
            }
            p = delegateDataOf[p].prev;
        }
        if(p == dd.prev)
            return;
        _dtoe(delegateDataOf).remove(delegate);
        _dtoe(delegateDataOf).append(delegate, p); 
    }

    function adjustValidators() external {
        address p = delegateDataOf[address(0)].prev;
        while(p != address(0) && staking.validators().length < maxValidators) {
            if(!staking.isValidator(p))
                staking.addValidator(p);
            p = delegateDataOf[p].prev;
        }
        p = delegateDataOf[address(0)].next;
        while(p != address(0) && staking.validators().length > maxValidators) {
            if(!staking.isValidator(p))
                staking.deleteFromValidators(p);
            p = delegateDataOf[p].prev;
        }
    }

    receive () payable external {
        stake(address(0));
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[34] private ______gap;
}


contract DPosMine is Mine {
    using SafeMath for uint;
    
    address payable public dpos;
    mapping(address => uint) public balanceOf;

    function __DPosMine_init(address governor, address reward_, address payable dpos_) public initializer {
        __Governable_init_unchained(governor);
        __Mine_init_unchained(reward_);
        __DPosMine_init_unchained(dpos_);
    }
    
    function __DPosMine_init_unchained(address payable dpos_) public governance {
        dpos = dpos_;
    }

    function totalSupply() public view returns(uint) {
        return address(this).balance;
    }
    
    function stakeTo(address delegateFrom, address delegateTo, address to, uint value) public {
        require(msg.sender == dpos, "only dpos");
        uint bal = balanceOf[delegateFrom] = balanceOf[delegateFrom].sub(value);
        DPOS(dpos).stakeTo{value: value}(delegateTo, to);
        emit StakeTo(delegateFrom, delegateTo, to, value, bal);
    }
    event StakeTo(address indexed delegateFrom, address indexed delegateTo, address indexed to, uint value, uint balance);
    
    function withdrawTo(address delegate, address payable to, uint value) public {
        require(msg.sender == dpos, "only dpos");
        balanceOf[delegate] = balanceOf[delegate].sub(value);
        to.transfer(value);
        emit Withdraw(msg.sender, delegate, to, value, balanceOf[delegate]);
    }
    event Withdraw(address indexed sender, address indexed delegate, address indexed to, uint value, uint balance);
    
    function depositFor(address delegate) payable public {
        require(delegate == address(-1) || DPOS(dpos).isDelegate(delegate), "not delegate");
        balanceOf[delegate] = balanceOf[delegate].add(msg.value);
        emit Deposit(msg.sender, delegate, msg.value, balanceOf[delegate]);
    }
    event Deposit(address indexed sender, address indexed delegate, uint value, uint balance);

    function depositForAll() payable public {
        depositFor(address(-1));
    }

    function deposit() payable public {
        depositFor(msg.sender);
    }

    receive () payable external {
        deposit();
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[48] private ______gap;
}
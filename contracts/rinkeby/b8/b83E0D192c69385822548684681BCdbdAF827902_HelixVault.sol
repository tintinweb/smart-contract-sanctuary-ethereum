// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../tokens/HelixToken.sol";
import "../libraries/Percent.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract HelixVault is Ownable {
    struct Deposit {
        address depositor;                  // user making the deposit
        uint256 amount;                     // amount of token deposited
        uint256 weight;                     // reward weight by duration 
        uint256 depositTimestamp;           // when the deposit was made and used for calculating rewards
        uint256 withdrawTimestamp;          // when the deposit is eligible for withdrawal
        uint256 rewardDebt;                 // debt owed on this deposit
        bool withdrawn;                     // true if the deposit has been withdrawn and false otherwise
    }
    
    struct Duration {
        uint256 duration;                   // length of time a deposit will be locked in seconds, 1 day == 86400
        uint256 weight;                     // reward modifier for locking a deposit for `duration`
    }
   
    /// Maps depositIds to a Deposit
    mapping(uint256 => Deposit) public deposits;

    /// Maps user addresses to the depositIds made by that address
    /// Used to display to users their deposits
    mapping(address => uint[]) public depositIds;

    /// Owner-curated list of valid deposit durations and associated reward weights
    Duration[] public durations;

    /// Last block that update was called and token distribution occured
    uint256 public lastUpdateBlock;

    /// Accumulated `token`s per share, times PRECISION_FACTOR.
    uint256 public accTokenPerShare;

    /// Used to index deposits for storage and retrieval
    uint256 public depositId;    

    /// Token deposited into and withdrawn from the vault by users
    /// and the token rewarded by the vault to user for locked token deposits
    HelixToken public token;

    /// Rate at which `token`s are created per block.
    uint256 public rewardPerBlock;
    
    /// Last block after which new rewards will no longer be minted
    uint256 public lastRewardBlock;
   
    /// Used for computing rewards
    uint256 public immutable PRECISION_FACTOR;

    /// Sets an upper limit on the number of decimals a token can have
    uint256 public constant MAX_DECIMALS = 30;

    // Emitted when a user makes a new deposit
    event NewDeposit(
        address indexed user, 
        uint256 indexed id, 
        uint256 amount, 
        uint256 weight, 
        uint256 depositTimestamp,
        uint256 withdrawTimestamp
    );

    // Emitted when a user updates an existing deposit
    event UpdateDeposit(
        address indexed user, 
        uint256 indexed id, 
        uint256 amount,            // amount added to existing deposit
        uint256 balance            // total balance deposited
    );

    // Emitted when a user withdraws a deposit
    event Withdraw(address indexed user, uint256 amount);

    // Emitted if the owner makes an emergency withdrawal
    event EmergencyWithdraw(address indexed user, uint256 amount);
    
    // Emitted when a user claims their accrued rewards
    event RewardClaimed(address indexed user, uint256 indexed id, uint256 reward);

    // Emitted when any action updates the pool
    event PoolUpdated(uint256 updateTimestamp);

    // Emitted when the reward per block is updated by the owner
    event RewardPerBlockUpdated(uint256 rewardPerBlock);

    // Emitted when the owner updates the last reward block
    event LastRewardBlockSet(uint256 lastRewardBlock);

    modifier onlyValidDepositId(uint256 _id) {
        require(depositId > 0, "Vault: no deposit made");
        require(_id < depositId, "Vault: invalid id");
        _;
    }

    modifier onlyValidIndex(uint256 _index) {
        require(_index < durations.length, "Vault: invalid index");
        _;
    }

    modifier onlyValidDuration(uint256 _duration) {
        require(_duration > 0, "Vault: zero duration");
        _;
    }

    modifier onlyValidWeight(uint256 _weight) {
        require(_weight > 0, "Vault: zero weight");
        _;
    }

    modifier onlyValidAmount(uint256 _amount) {
        require(_amount > 0, "Vault: zero amount");
        _;
    }

    constructor(
        HelixToken _token,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _lastRewardBlock
    ) {
        token = _token;
        rewardPerBlock = _rewardPerBlock;

        lastRewardBlock = _lastRewardBlock;
        lastUpdateBlock = block.number > _startBlock ? block.number : _startBlock;

        // default locked deposit durations and their weights
        durations.push(Duration(90 days, 5));
        durations.push(Duration(180 days, 10));
        durations.push(Duration(360 days, 30));
        durations.push(Duration(540 days, 50));
        durations.push(Duration(720 days, 100));
                                
        uint256 decimalsRewardToken = uint(token.decimals());
        require(decimalsRewardToken < MAX_DECIMALS, "Vault: token exceeds max decimals");

        PRECISION_FACTOR = uint(10 ** (uint(MAX_DECIMALS) - decimalsRewardToken));
    }

    /// Called by the deposit _id holder to withdraw their accumulated reward
    function claimReward(uint256 _id) external {
        Deposit storage deposit = _getDeposit(_id);

        _requireIsDepositor(msg.sender, deposit.depositor);
        _requireNotWithdrawn(deposit.withdrawn);

        updatePool();

        uint256 reward = _getReward(deposit.amount, deposit.weight) - deposit.rewardDebt;
        deposit.rewardDebt = _getReward(deposit.amount, deposit.weight);
        
        if (reward > 0) {
            token.transfer(msg.sender, reward);
        }

        emit RewardClaimed(msg.sender, _id, reward);
    } 

    /// Used internally to create a new deposit and lock _amount of token for _index
    function newDeposit(uint256 _amount, uint256 _index) 
        external 
        onlyValidAmount(_amount) 
        onlyValidIndex(_index) 
    {
        updatePool();

        // Get the new id of this deposit and create the deposit object
        uint256 id = depositId++;

        Deposit storage deposit = deposits[id];
        deposit.depositor = msg.sender;
        deposit.amount = _amount;
        deposit.weight = durations[_index].weight;
        deposit.depositTimestamp = block.timestamp;
        deposit.withdrawTimestamp = block.timestamp + durations[_index].duration;
        deposit.rewardDebt = _getReward(deposit.amount, deposit.weight);
        deposit.withdrawn = false;

        // Relay the deposit id to the user's account
        depositIds[msg.sender].push(id);

        token.transferFrom(msg.sender, address(this), _amount);

        emit NewDeposit(
            msg.sender, 
            id, 
            _amount, 
            deposit.weight, 
            deposit.depositTimestamp, 
            deposit.withdrawTimestamp
        );
    }

    /// Used internally to increase deposit _id by _amount of token
    function updateDeposit(uint256 _amount, uint256 _id) 
        external 
        onlyValidAmount(_amount) 
        onlyValidDepositId(_id)
    {
        updatePool();

        Deposit storage deposit = _getDeposit(_id);
    
        _requireIsDepositor(msg.sender, deposit.depositor);
        _requireNotWithdrawn(deposit.withdrawn);

        deposit.amount += _amount;
        deposit.rewardDebt = _getReward(deposit.amount, deposit.weight);

        uint256 reward = _getReward(deposit.amount, deposit.weight);
        if (reward > 0) {
            token.transfer(msg.sender, reward);
        }
        token.transferFrom(msg.sender, address(this), _amount);

        emit UpdateDeposit(msg.sender, _id, _amount, deposit.amount);
    }

    /// Withdraw _amount of token from deposit _id
    function withdraw(uint256 _amount, uint256 _id) external onlyValidAmount(_amount) {
        Deposit storage deposit = _getDeposit(_id);
    
        _requireIsDepositor(msg.sender, deposit.depositor); 
        _requireNotWithdrawn(deposit.withdrawn);
        require(deposit.amount >= _amount, "Vault: invalid amount");
        require(block.timestamp >= deposit.withdrawTimestamp, "Vault: locked");
       
        // collect rewards
        updatePool();
        
        uint256 reward = _getReward(deposit.amount, deposit.weight);

        if (deposit.amount == _amount) {
            // Close the deposit if the amount deposited is being withdrawn
            deposit.withdrawn = true;
        } else {
            deposit.amount -= _amount;
            deposit.rewardDebt = _getReward(deposit.amount, deposit.weight);
        }

        if (reward > 0) {
            token.transfer(msg.sender, reward);
        }
        token.transfer(msg.sender, _amount);

        emit Withdraw(msg.sender, _amount);
    }

    /// Called by the owner to update the earned _rewardPerBlock
    function updateRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        require(_rewardPerBlock <= 40 * 1e18, "Vault: max 40 per block");
        require(_rewardPerBlock >= 1e17, "Vault: min 0.1 per block");
        rewardPerBlock = _rewardPerBlock;
        emit RewardPerBlockUpdated(_rewardPerBlock);
    }

    /// Withdraw all the tokens in this contract. Emergency ONLY
    function emergencyWithdraw() external onlyOwner {
        TransferHelper.safeTransfer(address(token), msg.sender, token.balanceOf(address(this)));
    }
    
    /// Called by the owner to get a duration by it's _index and assign it a 
    /// new _duration and _weight
    function setDuration(uint256 _index, uint256 _duration, uint256 _weight)
        external
        onlyOwner
        onlyValidIndex(_index)
        onlyValidDuration(_duration)
        onlyValidWeight(_weight)  
    {
        durations[_index].duration = _duration;
        durations[_index].weight = _weight;
    }
   
    /// Called by the owner to add a new duration with _duration and _weight
    function addDuration(uint256 _duration, uint256 _weight) 
        external 
        onlyOwner
        onlyValidDuration(_duration) 
        onlyValidWeight(_weight)
    {
        durations.push(Duration(_duration, _weight));
    }

    /// Called by the owner to remove the duration at _index
    function removeDuration(uint256 _index) 
        external 
        onlyOwner
        onlyValidIndex(_index)
    {
        // remove by array shift to preserve order
        for (uint256 i = _index; i < durations.length - 1; i++) {
            durations[i] = durations[i + 1];
        }
        durations.pop();
    }

    /// Called by the owner to set the lastRewardBlock variable
    function setLastRewardBlock(uint256 _lastRewardBlock) external onlyOwner {
        lastRewardBlock = _lastRewardBlock;
        emit LastRewardBlockSet(_lastRewardBlock);
    }

    /// Called to get deposit with _id's pending reward
    function pendingReward(uint256 _id) external view returns (uint) {
        Deposit storage deposit = _getDeposit(_id);
        
        _requireIsDepositor(msg.sender, deposit.depositor);
        _requireNotWithdrawn(deposit.withdrawn);

        uint256 _accTokenPerShare = accTokenPerShare;
        uint256 lpSupply = token.balanceOf(address(this));
        if (block.number > lastUpdateBlock && lpSupply != 0) {
            uint256 blocks = getBlocksDifference(lastUpdateBlock, block.number);
            _accTokenPerShare += blocks * rewardPerBlock * PRECISION_FACTOR / lpSupply;
        }

        uint256 reward = _getReward(deposit.amount, deposit.weight, _accTokenPerShare);
        return reward - deposit.rewardDebt;
    }

    // Get the _user's deposit ids which are used for accessing their deposits
    function getDepositIds(address _user) external view returns (uint[] memory) {
        return depositIds[_user];
    }

    /// Get the array of durations
    function getDurations() external view returns (Duration[] memory) {
        return durations;
    }

    /// Return the Deposit associated with the _depositId
    function getDeposit(uint256 _depositId) external view returns (Deposit memory) {
        return _getDeposit(_depositId);
    }

    /// Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        if (block.number <= lastUpdateBlock) {
            return;
        }

        uint256 balance = token.balanceOf(address(this));
        uint256 reward;
        if (balance > 0) {
            uint256 blocks = getBlocksDifference(lastUpdateBlock, block.number);
            reward = blocks * rewardPerBlock;
            accTokenPerShare += reward * PRECISION_FACTOR / balance;
        }

        lastUpdateBlock = block.number;

        if (reward > 0) {
            token.mint(address(this), reward);
        }

        emit PoolUpdated(lastUpdateBlock);
    }

    /// Return the number of blocks between _to and _from blocks
    function getBlocksDifference(uint256 _from, uint256 _to) public view returns (uint) {
        require(_from <= _to, "Vault: invalid block values");
        if (_from > lastRewardBlock) {
            return 0;
        }
        return Math.min(_to, lastRewardBlock) - _from;
    }

    // Return the Deposit associated with the _depositId
    function _getDeposit(uint256 _depositId) private view onlyValidDepositId(_depositId) 
        returns (Deposit storage) 
    {
        return deposits[_depositId];
    }

    // Used internally for computing reward and reward debts
    function _getReward(uint256 _amount, uint256 _weight) 
        private 
        view 
        returns (uint256 reward) 
    {
        reward = _getReward(_amount, _weight, accTokenPerShare);
    }

    // Used internally for computing reward and reward debts
    function _getReward(uint256 _amount, uint256 _weight, uint256 _accTokenPerShare) 
        private 
        view 
        returns (uint256 reward) 
    {   
        uint256 accToken = _amount * _accTokenPerShare / PRECISION_FACTOR;
        reward = Percent.getPercentage(accToken, _weight);
    }
    // Used to require that the _caller is the _depositor
    function _requireIsDepositor(address _caller, address _depositor) private pure {
        require(_caller == _depositor, "Vault: not depositor");
    }
    
    // Used to require that the deposit is not _withdrawn
    function _requireNotWithdrawn(bool _withdrawn) private pure {
        require(!_withdrawn, "Vault: withdrawn");
    }
}

//SPDX-License-Identifier:MIT
pragma solidity >=0.8.0;

// Copied and modified from YAM code:
// https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
// https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
// Which is copied and modified from COMPOUND:
// https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

import "../libraries/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// Geometry governance token
contract HelixToken is ERC20("Helix", "HELIX") {
    using EnumerableSet for EnumerableSet.AddressSet;

    // @notice Checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    // Set of addresses which can mint HELIX
    EnumerableSet.AddressSet private _minters;
 
    /// @dev A record of each accounts delegate
    mapping(address => address) internal _delegates;

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /// @notice An event that's emitted when an account changes its delegate
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    /// @notice An event that's emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );

    modifier onlyMinter() {
        require(isMinter(msg.sender), "Helix: not minter");
        _;
    }

    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "Helix: zero address");
        _;
    }

    /// @notice Creates _amount of token to _to.
    function mint(address _to, uint256 _amount)
        external 
        onlyMinter
        returns (bool)
    {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
        return true;
    }

    /// @notice Destroys _amount tokens from _account reducing the total supply
    function burn(address _account, uint256 _amount) external onlyMinter {
        _burn(_account, _amount);
    }

    /// @notice Delegate votes from msg.sender to _delegatee
    /// @param _delegatee The address to delegate votes to
    function delegate(address _delegatee) external {
        return _delegate(msg.sender, _delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param _delegatee The address to delegate votes to
     * @param _nonce The contract state required to match the signature
     * @param _expiry The time at which to expire the signature
     * @param _v The recovery byte of the signature
     * @param _r Half of the ECDSA signature pair
     * @param _s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address _delegatee,
        uint256 _nonce,
        uint256 _expiry,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                _getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(DELEGATION_TYPEHASH, _delegatee, _nonce, _expiry)
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );

        address signatory = ecrecover(digest, _v, _r, _s);

        require(signatory != address(0), "Helix: invalid signature");
        require(_nonce == nonces[signatory]++, "Helix: invalid nonce");
        require(block.timestamp <= _expiry, "Helix: signature expired");

        return _delegate(signatory, _delegatee);
    }

    /**
     * @dev used by owner to delete minter of token
     * @param _delMinter address of minter to be deleted.
     * @return true if successful.
     */
    function delMinter(address _delMinter) external onlyOwner onlyValidAddress(_delMinter) returns (bool) {
        return EnumerableSet.remove(_minters, _delMinter);
    }

    /// @notice Delegate votes from msg.sender to _delegatee
    /// @param _delegator The address to get delegatee for
    function delegates(address _delegator) external view returns (address) {
        return _delegates[_delegator];
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param _account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address _account) external view returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[_account];
        return
            nCheckpoints > 0 ? checkpoints[_account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param _account The address of the account to check
     * @param _blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address _account, uint256 _blockNumber)
        external
        view
        returns (uint256)
    {
        require(_blockNumber < block.number, "Helix: invalid blockNumber");

        uint32 nCheckpoints = numCheckpoints[_account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[_account][nCheckpoints - 1].fromBlock <= _blockNumber) {
            return checkpoints[_account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[_account][0].fromBlock > _blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[_account][center];
            if (cp.fromBlock == _blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < _blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[_account][lower].votes;
    }

    /**
     * @dev used by get the minter at n location
     * @param _index index of address set
     * @return address of minter at index.
     */
    function getMinter(uint256 _index)
        external
        view
        onlyOwner
        returns (address)
    {
        require(_index <= getMinterLength() - 1, "Helix: index out of bounds");
        return EnumerableSet.at(_minters, _index);
    }

    /**
     * @dev used by owner to add minter of token
     * @param _addMinter address of minter to be added.
     * @return true if successful.
     */
    function addMinter(address _addMinter) public onlyOwner onlyValidAddress(_addMinter) returns (bool) {
        return EnumerableSet.add(_minters, _addMinter);
    }

    /// @dev used to get the number of minters for this token
    /// @return number of minters.
    function getMinterLength() public view returns (uint256) {
        return EnumerableSet.length(_minters);
    }

    /// @dev used to check if an address is a minter of token
    /// @return true or false based on minter status.
    function isMinter(address _account) public view returns (bool) {
        return EnumerableSet.contains(_minters, _account);
    }

    // internal function used delegate votes
    function _delegate(address _delegator, address _delegatee) internal {
        address currentDelegate = _delegates[_delegator];
        uint256 delegatorBalance = balanceOf(_delegator); // balance of underlying HELIXs (not scaled);
        _delegates[_delegator] = _delegatee;

        emit DelegateChanged(_delegator, currentDelegate, _delegatee);

        _moveDelegates(currentDelegate, _delegatee, delegatorBalance);
    }

    // send delegate votes from src to dst in amount
    function _moveDelegates(
        address _srcRep,
        address _dstRep,
        uint256 _amount
    ) internal {
        if (_srcRep != _dstRep && _amount > 0) {
            if (_srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[_srcRep];
                uint256 srcRepOld = srcRepNum > 0
                    ? checkpoints[_srcRep][srcRepNum - 1].votes
                    : 0;
                uint256 srcRepNew = srcRepOld - _amount;
                _writeCheckpoint(_srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (_dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[_dstRep];
                uint256 dstRepOld = dstRepNum > 0
                    ? checkpoints[_dstRep][dstRepNum - 1].votes
                    : 0;
                uint256 dstRepNew = dstRepOld + _amount;
                _writeCheckpoint(_dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address _delegatee,
        uint32 _nCheckpoints,
        uint256 _oldVotes,
        uint256 _newVotes
    ) internal {
        uint32 blockNumber = _safe32(
            block.number,
            "HELIX::_writeCheckpoint: block number exceeds 32 bits"
        );

        if (
            _nCheckpoints > 0 &&
            checkpoints[_delegatee][_nCheckpoints - 1].fromBlock == blockNumber
        ) {
            checkpoints[_delegatee][_nCheckpoints - 1].votes = _newVotes;
        } else {
            checkpoints[_delegatee][_nCheckpoints] = Checkpoint(
                blockNumber,
                _newVotes
            );
            numCheckpoints[_delegatee] = _nCheckpoints + 1;
        }

        emit DelegateVotesChanged(_delegatee, _oldVotes, _newVotes);
    }

    // @dev used get current chain ID
    // @return id as a uint
    function _getChainId() internal view returns (uint256 id) {
        id = block.chainid;
    }

    /*
     * @dev Checks if value is 32 bits
     * @param _n value to be checked
     * @param _errorMessage error message to throw if fails
     * @return The number if valid.
     */
    function _safe32(uint256 _n, string memory _errorMessage)
        internal
        pure
        returns (uint32)
    {
        require(_n < 2**32, _errorMessage);
        return uint32(_n);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

library Percent {
    uint256 public constant MAX_PERCENT = 100;

    modifier onlyValidPercent(uint256 _percent, uint256 _decimals) {
        require(_isValidPercent(_percent, _decimals), "Percent: invalid percent");
        _;
    }

    // Return true if the _percent is valid and false otherwise
    function isValidPercent(uint256 _percent)
        internal
        pure
        returns (bool)
    {
        return _isValidPercent(_percent, 0);
    }

    // Return true if the _percent with _decimals many decimals is valid and false otherwise
    function isValidPercent(uint256 _percent, uint256 _decimals)
        internal
        pure
        returns (bool)
    {
        return _isValidPercent(_percent, _decimals);
    }

    // Return true if the _percent with _decimals many decimals is valid and false otherwise
    function _isValidPercent(uint256 _percent, uint256 _decimals)
        private
        pure
        returns (bool)
    {
        return _percent <= MAX_PERCENT * 10 ** _decimals;
    }

    // Return _percent of _amount
    function getPercentage(uint256 _amount, uint256 _percent)
        internal 
        pure
        returns (uint256 percentage) 
    {
        percentage = _getPercentage(_amount, _percent, 0);
    }

    // Return _percent of _amount with _decimals many decimals
    function getPercentage(uint256 _amount, uint256 _percent, uint256 _decimals)
        internal 
        pure
        returns (uint256 percentage)
    {
        percentage =_getPercentage(_amount, _percent, _decimals);
    }

    // Return _percent of _amount with _decimals many decimals
    function _getPercentage(uint256 _amount, uint256 _percent, uint256 _decimals) 
        private
        pure
        onlyValidPercent(_percent, _decimals) 
        returns (uint256 percentage)
    {
        percentage = _amount * _percent / (MAX_PERCENT * 10 ** _decimals);
    }

    // Return _percent of _amount as the percentage and the remainder of _amount - percentage
    function splitByPercent(uint256 _amount, uint256 _percent) 
        internal 
        pure 
        returns (uint256 percentage, uint256 remainder) 
    {
        (percentage, remainder) = _splitByPercent(_amount, _percent, 0);
    }

    // Return _percent of _amount as the percentage and the remainder of _amount - percentage
    // with _decimals many decimals
    function splitByPercent(uint256 _amount, uint256 _percent, uint256 _decimals)
        internal 
        pure
        returns (uint256 percentage, uint256 remainder)
    {
        (percentage, remainder) = _splitByPercent(_amount, _percent, _decimals);
    }

    // Return _percent of _amount as the percentage and the remainder of _amount - percentage
    // with _decimals many decimals
    function _splitByPercent(uint256 _amount, uint256 _percent, uint256 _decimals)
        private
        pure
        onlyValidPercent(_percent, _decimals)
        returns (uint256 percentage, uint256 remainder)
    {
        percentage = _getPercentage(_amount, _percent, _decimals);
        remainder = _amount - percentage;
    }
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

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

//SPDX-License-Identifier:MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract ERC20 is Context, Ownable, IERC20, IERC20Metadata {
    uint256 private constant _maxSupply = 1000000000 * 1e18;        // 1B
    uint256 private constant _preMineSupply = 160000000 * 1e18;     // 16% of 1B

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory tokenName, string memory tokenSymbol) {
        _name = tokenName;
        _symbol = tokenSymbol;

        _mint(msg.sender, _preMineSupply); // mint token to msg owner
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @notice supply that was mented to the contract owner.
     */

    function preMineSupply() public pure returns (uint256) {
        return _preMineSupply;
    }

    /**
     * @notice max supply that can eer be minted.
     */
    function maxSupply() public pure returns (uint256) {
        return _maxSupply;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        if (amount + _totalSupply > _maxSupply) {
            revert();
            // return false;
        }

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal virtual {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()] - amount
        );
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
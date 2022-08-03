// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import "./IStakingV2Vendor.sol";
import './IStakingV2Factory.sol';
import './IStakingDelegate.sol';

/**
 * @title Token Staking
 * @dev BEP20 compatible token.
 */
contract StakingV2 is Ownable, AccessControl {
    using SafeERC20 for IERC20;
    using Address for address;

    bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');
    bytes32 public constant MAINTAINER_ROLE = keccak256('MAINTAINER_ROLE');

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt; // backwards compatibility
        uint256 pendingRewards; // backwards compatibility
        uint256 lockedTimestamp;
        uint256 lockupTimestamp;
        uint256 lockupTimerange;
        uint256 virtAmount;
    }

    struct PoolInfo {
        uint256 lastBlock;
        uint256 tokenPerShare;
        uint256 tokenRealStaked;
        uint256 tokenVirtStaked;
        uint256 tokenRewarded;
        uint256 tokenTotalLimit;
        uint256 lockupMaxTimerange;
        uint256 lockupMinTimerange;
    }

    IERC20 public token;

    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 public tokenPerBlock; // backwards compatibility
    uint256 public startBlock;
    uint256 public closeBlock;
    uint256 public maxPid;
    uint256 private constant MAX = ~uint256(0);

    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(address => address) public vendorInfo;
    address[] public vendors;
    address[] public delistedVendors;
    mapping(address => bool) public allowedStakingInstances;
    uint256[] public multipliers = [
         12742, 13081, 13428, 13785, 14152, 14528, 14914, 15311, 15718, 16136, 16565, 17005,
         17457, 17921, 18398, 18887, 19389, 19904, 20433, 20976, 21534, 22107, 22694, 23298,
         23917, 24553, 25205, 25876, 26563, 27270, 27995, 28732, 29503, 30287, 31092, 31919,
         32767, 33638, 34533, 35451, 36393, 37360, 38354, 39373, 40420, 41494, 42598, 43730,
         44892, 46086, 47311, 48569, 49860, 51185, 52546, 53943, 55377, 56849, 58360, 59912,
         61505, 63140, 64818, 66541, 68310, 70126, 71990, 73904, 75869, 77886, 79956, 82082,
         84264, 86504, 88803, 91164, 93587, 96075, 98629,101251,103943,106706,109543,112455,
        115444,118513,121664,124898,128218,131627,135126,138718,142406,146192,150078,154067
    ];

    IStakingDelegate public delegate;
    IStakingV2Factory public factory;

    event PoolAdded(uint256 minTimer, uint256 maxTimer, uint256 limit);
    event Deposited(address indexed user, uint256 indexed pid, address indexed token, uint256 amount);
    event Withdrawn(address indexed user, uint256 indexed pid, address indexed token, uint256 amount);
    event WithdrawnReward(address indexed user, uint256 indexed pid, address indexed token, uint256 amount);
    event WithdrawnRemain(address indexed user, uint256 indexed pid, address indexed token, uint256 amount);
    event TokenVendorChanged(address indexed token, address indexed vendor);
    event DelegateAddressChanged(address indexed addr);
    event FactoryAddressChanged(address indexed addr);
    event AllowedAmountsChanged(uint256 minAmount, uint256 maxAmount);
    event StakingInstanceChanged();

    event StartBlockChanged(uint256 block);
    event CloseBlockChanged(uint256 block);

    modifier onlyAuthority {
        require(msg.sender == owner() || hasRole(MAINTAINER_ROLE, msg.sender), 'Staking: only authorities can call this method');
        _;
    }

    constructor(IERC20 _token, uint256 _minPoolTimer, uint256 _maxPoolTimer, uint256 _minAmount, uint256 _maxAmount, uint256 _poolLimit) {
        require(address(_token) != address(0), 'Staking: token address needs to be different than zero!');
        token = _token;
        minAmount = _minAmount;
        maxAmount = _maxAmount;
        addPool(_minPoolTimer, _maxPoolTimer, _poolLimit);
        tokenPerBlock = 1e4; // in this interface tokenPerBlock serves purpose as a precision gadget

        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(MAINTAINER_ROLE, ADMIN_ROLE);

        _setupRole(ADMIN_ROLE, address(this));
        _setupRole(MAINTAINER_ROLE, owner());
    }

    function addMaintainer(address account) external onlyOwner returns (bool) {
        bytes4 selector = this.grantRole.selector;
        address(this).functionCall(abi.encodeWithSelector(selector, MAINTAINER_ROLE, account));
        return true;
    }

    function delMaintainer(address account) external onlyOwner returns (bool) {
        bytes4 selector = this.revokeRole.selector;
        address(this).functionCall(abi.encodeWithSelector(selector, MAINTAINER_ROLE, account));
        return true;
    }

    function isMaintainer(address account) external view returns (bool) {
        return hasRole(MAINTAINER_ROLE, account);
    }

    // staking instances need to be added to properly chain multiple staking instances
    function addStakingInstances(address[] memory stakingInstances, bool status) public onlyOwner {
        for (uint i=0; i<stakingInstances.length; ++i) {
            allowedStakingInstances[stakingInstances[i]] = status;
        }
        emit StakingInstanceChanged();
    }

    // factory is used to instantiate staking vendors to decrease size of this contract
    function setFactoryAddress(IStakingV2Factory _factory) public onlyOwner {
        require(address(_factory) != address(0), 'Staking: factory address needs to be different than zero!');
        factory = _factory;
        emit FactoryAddressChanged(address(factory));
    }

    // set min/max amount possible
    function setAllowedAmounts(uint256 _minAmount, uint256 _maxAmount) public onlyOwner {
        minAmount = _minAmount;
        maxAmount = _maxAmount;
        emit AllowedAmountsChanged(minAmount, maxAmount);
    }

    // set token reward with infinite time range
    function setTokenPerBlock(IERC20 _token, uint256 _tokenPerBlock) public onlyAuthority {
        require(startBlock != 0, 'Staking: cannot add reward before setting start block');
        require(address(_token) != address(0), 'Staking: token address needs to be different than zero!');

        address addr = vendorInfo[address(_token)];
        // if vendor for asset already exists and is not closed then overwrite its reward schedule instead of invoking new one
        if (addr != address(0)) {
            IStakingV2Vendor vendor = IStakingV2Vendor(addr);
            uint256 _prevCloseBlock = vendor.closeBlock();
            if (_prevCloseBlock == 0 || block.number <= _prevCloseBlock) {
                // we need to update the pool manually in this case because of premature return
                for (uint i=0; i<maxPid; i++) updatePool(i);
                _token.approve(address(vendor), MAX);
                vendor.setTokenPerBlock(_tokenPerBlock, vendor.startBlock(), vendor.closeBlock());
                return;
            }
        }

        setTokenPerBlock(_token, _tokenPerBlock, 0);
    }

    // set token reward for some specific time range
    function setTokenPerBlock(IERC20 _token, uint256 _tokenPerBlock, uint256 _blockRange) public onlyAuthority {
        require(startBlock != 0, 'Staking: cannot add reward before setting start block');
        require(address(_token) != address(0), 'Staking: token address needs to be different than zero!');

        address addr = vendorInfo[address(_token)];
        uint256 _startBlock = block.number > startBlock ? block.number : startBlock;
        uint256 _closeBlock = _blockRange == 0 ? 0 : _startBlock + _blockRange;

        // if vendor for asset already exists overwrite startBlock with the value that vendor initally held instead
        if (addr != address(0)) {
            // start block has to remain same regardless of current timestamp and block range
            _startBlock = IStakingV2Vendor(addr).startBlock();
        }

        setTokenPerBlock(_token, _tokenPerBlock, _startBlock, _closeBlock);
    }

    // set token reward for some specific time range by specifying start and close blocks
    function setTokenPerBlock(IERC20 _token, uint256 _tokenPerBlock, uint256 _startBlock, uint256 _closeBlock) public onlyAuthority {
        require(startBlock != 0, 'Staking: cannot add reward before setting start block');
        require(_startBlock >= startBlock, 'Staking: token start block needs to be different than zero!');
        require(_closeBlock > _startBlock || _closeBlock == 0, 'Staking: token close block needs to be higher than start block!');
        require(address(_token) != address(0), 'Staking: token address needs to be different than zero!');

        for (uint i=0; i<maxPid; i++) {
            updatePool(i); // pool needs to be updated to keep vendor data consistent
        }

        address addr = vendorInfo[address(_token)];
        IStakingV2Vendor vendor;

        // if vendor for asset already exists and is not closed overwrite its reward schedule
        if (addr != address(0)) {
            vendor = IStakingV2Vendor(addr);
            uint256 _prevStartBlock = vendor.startBlock();
            uint256 _prevCloseBlock = vendor.closeBlock();

            // not closed
            if (_prevCloseBlock == 0 || block.number <= _prevCloseBlock) {
                require(_startBlock == _prevStartBlock || block.number < _prevStartBlock,
                    'Staking: token start block cannot be changed');
                _token.approve(address(vendor), MAX);
                vendor.setTokenPerBlock(_tokenPerBlock, _startBlock, _closeBlock);
                return;
            }

            // if it is closed though, then treat it the same as if vendor was not created yet - new one is needed
            if (_prevCloseBlock != 0 && _prevCloseBlock < _startBlock) {
                addr = address(0);
            }
        }

        // if vendor for asset does not exist (or expired) create a new one
        if (addr == address(0)) {
            updateVendors();
            require(vendors.length < 20, 'Staking: limit of actively distributed tokens reached');

            addr = factory.createVendor(address(this), _token);
            vendor = IStakingV2Vendor(addr);
            _token.approve(address(vendor), MAX);
            vendor.setTokenPerBlock(_tokenPerBlock, _startBlock, _closeBlock);

            vendorInfo[address(_token)] = address(vendor);
            vendors.push(address(_token));
            emit TokenVendorChanged(address(_token), address(vendor));
            return;
        }

        revert('Staking: invalid configuration provided');
    }

    function setStartBlock(uint256 _startBlock) public onlyOwner {
        require(startBlock == 0 || startBlock > block.number, 'Staking: start block already set');
        require(_startBlock > 0, 'Staking: start block needs to be higher than zero!');
        startBlock = _startBlock;

        IStakingV2Vendor vendor;
        for (uint i=0; i<vendors.length; i++) {
            vendor = IStakingV2Vendor(vendorInfo[vendors[i]]);
            if (vendor.startBlock() == 0 || vendor.startBlock() < startBlock) vendor.setStartBlock(startBlock);
        }
        emit StartBlockChanged(startBlock);
    }

    function setCloseBlock(uint256 _closeBlock) public onlyOwner {
        require(startBlock != 0, 'Staking: start block needs to be set first');
        require(closeBlock == 0 || closeBlock > block.number, 'Staking: close block already set');
        require(_closeBlock > startBlock, 'Staking: close block needs to be higher than start one!');
        closeBlock = _closeBlock;

        IStakingV2Vendor vendor;
        for (uint i=0; i<vendors.length; i++) {
            vendor = IStakingV2Vendor(vendorInfo[vendors[i]]);
            if (vendor.closeBlock() == 0 || vendor.closeBlock() > closeBlock) vendor.setCloseBlock(closeBlock);
        }
        emit CloseBlockChanged(closeBlock);
    }

    // set delegate to which events about staking amounts should be send to
    function setDelegateAddress(IStakingDelegate _delegate) public onlyOwner {
        require(address(_delegate) != address(0), 'Staking: delegate address needs to be different than zero!');
        delegate = _delegate;
        emit DelegateAddressChanged(address(delegate));
    }

    function withdrawRemaining() public onlyOwner {
        for (uint i=0; i<vendors.length; i++) withdrawRemaining(vendors[i]);
    }

    function withdrawRemaining(address asset) public onlyOwner {
        require(startBlock != 0, 'Staking: start block needs to be set first');
        require(closeBlock != 0, 'Staking: close block needs to be set first');
        require(block.number > closeBlock, 'Staking: withdrawal of remaining funds not ready yet');

        for (uint i=0; i<maxPid; i++) {
            updatePool(i);
        }
        getVendor(asset).withdrawRemaining(owner());
    }

    function pendingRewards(uint256 pid, address addr, address asset) external view returns (uint256) {
        require(pid < maxPid, 'Staking: invalid pool ID provided');
        require(startBlock > 0 && block.number >= startBlock, 'Staking: not started yet');
        return getVendor(asset).pendingRewards(pid, addr);
    }

    function getVAmount(uint256 pid, uint256 amount, uint256 timerange) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[pid];
        if (pool.lockupMaxTimerange == 0) return amount;
        uint256 indx = multipliers.length * timerange / pool.lockupMaxTimerange;
        if (indx == 0) indx = 1;
        return amount * (1e5 + multipliers[indx-1]) / 1e5;
    }

    function deposit(uint256 pid, address addr, uint256 amount, uint256 timerange) external {
        _deposit(pid, msg.sender, addr, amount, timerange);
    }

    // restake is custom functionality in which funds can be restaked between allowed instances without
    function restake(uint256 pid, address addr, uint256 pocket, uint256 amount, uint256 timerange) external {
        require(allowedStakingInstances[addr], 'Staking: unable to restake funds to specified address');
        if (pocket > 0) token.safeTransferFrom(address(msg.sender), address(this), pocket);
        _withdraw(pid, msg.sender, address(this), amount);
        token.approve(addr, pocket+amount);
        StakingV2(addr).deposit(pid, msg.sender, pocket+amount, timerange);
    }

    function withdraw(uint256 pid, address /*addr*/, uint256 amount) external { // keep this method for backward compatibility
        _withdraw(pid, msg.sender, msg.sender, amount);
    }

    function _deposit(uint256 pid, address from, address addr, uint256 amount, uint256 timerange) internal {
        // amount eq to zero is allowed
        require(pid < maxPid, 'Staking: invalid pool ID provided');
        require(startBlock > 0 && block.number >= startBlock, 'Staking: not started yet');
        require(closeBlock == 0 || block.number <= closeBlock,
            'Staking: staking has ended, please withdraw remaining tokens');

        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][addr];

        require(timerange <= pool.lockupMaxTimerange && timerange >= pool.lockupMinTimerange,
            'Staking: cannot lock funds for that amount of time!');
        require(timerange + block.timestamp >= user.lockedTimestamp,
            'Staking: timerange needs to be equal or higher from previous');

        require(pool.tokenTotalLimit == 0 || pool.tokenTotalLimit >= pool.tokenRealStaked + amount,
            'Staking: you cannot deposit over the limit!');
        require(minAmount == 0 || user.amount + amount >= minAmount, 'Staking: amount needs to be higher');
        require(maxAmount == 0 || user.amount + amount <= maxAmount, 'Staking: amount needs to be lesser');
        require(user.lockedTimestamp <= block.timestamp + timerange, 'Staking: cannot decrease lock time');

        updatePool(pid);

        uint256 virtAmount = getVAmount(pid, user.amount + amount, timerange);
        for (uint i=0; i<vendors.length; i++) getVendor(vendors[i]).update(pid, addr, virtAmount);

        if (amount > 0) {
            user.amount = user.amount + amount;
            pool.tokenRealStaked = pool.tokenRealStaked + amount;

            pool.tokenVirtStaked = pool.tokenVirtStaked - user.virtAmount + virtAmount;
            user.virtAmount = virtAmount;

            token.safeTransferFrom(address(from), address(this), amount); // deposit is from sender
        }
        user.lockedTimestamp = block.timestamp + timerange;
        user.lockupTimestamp = block.timestamp;
        user.lockupTimerange = timerange;
        emit Deposited(addr, pid, address(token), amount);

        if (address(delegate) != address(0)) {
            delegate.balanceChanged(addr, user.amount);
        }
    }

    function _withdraw(uint256 pid, address from, address addr, uint256 amount) internal {
        // amount eq to zero is allowed
        require(pid < maxPid, 'Staking: invalid pool ID provided');
        require(startBlock > 0 && block.number >= startBlock, 'Staking: not started yet');

        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][from];

        require((addr == address(this)) || (block.timestamp >= user.lockedTimestamp)
            || (closeBlock > 0 && closeBlock <= block.number), 'Staking: you cannot withdraw yet!');
        require(user.amount >= amount, 'Staking: you cannot withdraw more than you have!');

        updatePool(pid);

        uint256 virtAmount = getVAmount(pid, user.amount - amount, user.lockupTimerange);
        for (uint i=0; i<vendors.length; i++) getVendor(vendors[i]).update(pid, addr, virtAmount);

        if (amount > 0) {
            user.amount = user.amount - amount;
            pool.tokenRealStaked = pool.tokenRealStaked - amount;

            pool.tokenVirtStaked = pool.tokenVirtStaked + user.virtAmount - virtAmount;
            user.virtAmount = virtAmount;

            if (addr != address(this)) token.safeTransfer(address(addr), amount);
        }
        user.lockedTimestamp = 0;
        user.lockupTimestamp = 0;
        emit Withdrawn(from, pid, address(token), amount);

        if (address(delegate) != address(0)) {
            delegate.balanceChanged(from, user.amount);
        }
    }

    function claim(uint256 pid) public {
        for (uint i=0; i<vendors.length; i++) claim(pid, vendors[i]);
    }

    function claim(uint256 pid, address asset) public {
        claimFromVendor(pid, address(getVendor(asset)));
    }

    function claimFromVendor(uint256 pid, address addr) public {
        require(pid < maxPid, 'Staking: invalid pool ID provided');
        require(startBlock > 0 && block.number >= startBlock, 'Staking: not started yet');
        updatePool(pid);
        IStakingV2Vendor(addr).claim(pid, msg.sender);
    }

    function addPool(uint256 _lockupMinTimerange, uint256 _lockupMaxTimerange, uint256 _tokenTotalLimit) internal {
        require(maxPid < 10, 'Staking: Cannot add more than 10 pools!');

        poolInfo.push(PoolInfo({
            lastBlock: 0,
            tokenPerShare: 0,
            tokenRealStaked: 0,
            tokenVirtStaked: 0,
            tokenRewarded: 0,
            tokenTotalLimit: _tokenTotalLimit,
            lockupMaxTimerange: _lockupMaxTimerange,
            lockupMinTimerange: _lockupMinTimerange
        }));
        maxPid++;

        emit PoolAdded(_lockupMinTimerange, _lockupMaxTimerange, _tokenTotalLimit);
    }

    function updatePool(uint256 pid) internal {
        if (pid >= maxPid) {
            return;
        }
        if (startBlock == 0 || block.number < startBlock) {
            return;
        }
        PoolInfo storage pool = poolInfo[pid];
        if (pool.lastBlock == 0) {
            pool.lastBlock = startBlock;
        }
        uint256 lastBlock = getLastRewardBlock();
        if (lastBlock <= pool.lastBlock) {
            return;
        }
        uint256 poolTokenVirtStaked = pool.tokenVirtStaked;
        if (poolTokenVirtStaked == 0) {
            return;
        }
        uint256 multiplier = lastBlock - pool.lastBlock;
        uint256 tokenAward = multiplier * tokenPerBlock;
        pool.tokenRewarded = pool.tokenRewarded + tokenAward;
        pool.tokenPerShare = pool.tokenPerShare + (tokenAward * 1e12 / poolTokenVirtStaked);
        pool.lastBlock = lastBlock;
    }

    function updateVendors() public {
        require(msg.sender == address(this) || msg.sender == owner() || hasRole(MAINTAINER_ROLE, msg.sender),
            'Staking: this method can only be called internally or by authority');
        address[] memory _newVendors = new address[](vendors.length);
        uint256 _size;
        address _addr;
        for (uint i=0; i<vendors.length; i++) {
            _addr = vendorInfo[vendors[i]];
            uint256 _closeBlock = IStakingV2Vendor(_addr).closeBlock();
            if (_closeBlock != 0 && _closeBlock < block.number) {
                delistedVendors.push(_addr);
            } else {
                _newVendors[_size++] = vendors[i];
            }
        }
        delete vendors;
        for (uint i=0; i<_size; i++) {
            vendors.push(_newVendors[i]);
        }
    }

    function getLastRewardBlock() internal view returns (uint256) {
        if (startBlock == 0) return 0;
        if (closeBlock == 0) return block.number;
        return (closeBlock < block.number) ? closeBlock : block.number;
    }

    function getVendor(address asset) internal view returns (IStakingV2Vendor) {
        address addr = vendorInfo[asset];
        require(addr != address(0), 'Staking: vendor for this token does not exist');
        return IStakingV2Vendor(addr);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import './IStakingV2.sol';

/**
 * @title Token Staking
 * @dev BEP20 compatible token.
 */
contract StakingV2Vendor is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct SuperPoolInfo {
        uint256 lastBlock;
        uint256 tokenPerShare;
        uint256 tokenRealStaked;
        uint256 tokenVirtStaked;
        uint256 tokenRewarded;
        uint256 tokenTotalLimit;
        uint256 lockupMaxTimerange;
        uint256 lockupMinTimerange;
    }

    struct SuperUserInfo {
        uint256 amount;
        uint256 rewardDebt; // backwards compatibility
        uint256 pendingRewards; // backwards compatibility
        uint256 lockedTimestamp;
        uint256 lockupTimestamp;
        uint256 lockupTimerange;
        uint256 virtAmount;
    }

    struct UserInfo {
        uint256 rewardDebt;
        uint256 pendingRewards;
    }

    struct PoolInfo {
        uint256 lastBlock;
        uint256 tokenPerShare;
        uint256 tokenRewarded;
        uint256 realTokenPerShare;
        uint256 realTokenReceived;
        uint256 realTokenRewarded;
    }

    IERC20 public token;
    IStakingV2 public parent;

    uint256 public tokenPerBlock;
    uint256 public tokenParentPrecision;
    uint256 public startBlock;
    uint256 public closeBlock;
    
    uint256 public maxPid;

    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    event WithdrawnReward(address indexed user, uint256 indexed pid, address indexed token, uint256 amount);
    event WithdrawnRemain(address indexed user, uint256 indexed pid, address indexed token, uint256 amount);
    event TokenAddressChanged(address indexed token);
    event TokenRewardsChanged(address indexed token, uint256 amount);

    event ParentChanged(address indexed addr);
    event StartBlockChanged(uint256 block);
    event CloseBlockChanged(uint256 block);

    constructor(address _parent, IERC20 _token) {
        setParent(_parent);
        setTokenAddress(_token);
        for (uint i=0; i<parent.maxPid(); i++) addPool(i);
        tokenParentPrecision = parent.tokenPerBlock();
    }

    function setParent(address _parent) public onlyOwner {
        require(_parent != address(0), 'Staking: parent address needs to be different than zero!');
        parent = IStakingV2(_parent);
        emit ParentChanged(address(parent));
    }

    function setTokenAddress(IERC20 _token) public onlyOwner {
        require(address(_token) != address(0), 'Staking: token address needs to be different than zero!');
        require(address(token) == address(0), 'Staking: tokens already set!');
        token = _token;
        emit TokenAddressChanged(address(token));
    }

    function setTokenPerBlock(uint256 _tokenPerBlock, uint256 _startBlock, uint256 _closeBlock) public virtual onlyOwner {
        if (_startBlock != startBlock) setStartBlock(_startBlock);
        if (_closeBlock != closeBlock) setCloseBlock(_closeBlock);
        setTokenPerBlock(_tokenPerBlock);
    }

    function setTokenPerBlock(uint256 _tokenPerBlock) public virtual onlyOwner {
        require(startBlock != 0, 'Staking: cannot set reward before setting start block');
        for (uint i=0; i<maxPid; i++) updatePool(i);
        tokenPerBlock = _tokenPerBlock;
        emit TokenRewardsChanged(address(token), _tokenPerBlock);
    }

    function setStartBlock(uint256 _startBlock) public virtual onlyOwner {
        require(startBlock == 0 || startBlock > block.number, 'Staking: start block already set');
        require(_startBlock > 0, 'Staking: start block needs to be higher than zero!');
        startBlock = _startBlock;
        emit StartBlockChanged(_startBlock);
    }

    function setCloseBlock(uint256 _closeBlock) public virtual onlyOwner {
        require(startBlock != 0, 'Staking: start block needs to be set first');
        require(closeBlock == 0 || closeBlock > block.number, 'Staking: close block already set');
        require(_closeBlock == 0 || _closeBlock > startBlock, 'Staking: close block needs to be higher than start one!');
        closeBlock = _closeBlock;
        emit CloseBlockChanged(_closeBlock);
    }

    function withdrawRemaining(address addr) external virtual onlyOwner {
        if (startBlock == 0 || closeBlock == 0 || block.number <= closeBlock) {
            return;
        }
        for (uint i=0; i<maxPid; i++) {
            updatePool(i);
        }

        uint256 allTokenRewarded = 0;
        uint256 allTokenReceived = 0;

        for (uint i=0; i<maxPid; i++) {
            allTokenRewarded = allTokenRewarded.add(poolInfo[i].realTokenRewarded);
            allTokenReceived = allTokenReceived.add(poolInfo[i].realTokenReceived);
        }

        uint256 unlockedAmount = 0;
        uint256 possibleAmount = token.balanceOf(address(parent));
        uint256 reservedAmount = allTokenRewarded.sub(allTokenReceived);

        // if token is the same as deposit token then deduct staked tokens as non withdrawable
        if (address(token) == address(parent.token())) {
            for (uint i=0; i<maxPid; i++) {
                reservedAmount = reservedAmount.add(getParentPoolInfo(i).tokenRealStaked);
            }
        }

        if (possibleAmount > reservedAmount) {
            unlockedAmount = possibleAmount.sub(reservedAmount);
        }
        if (unlockedAmount > 0) {
            token.safeTransferFrom(address(parent), addr, unlockedAmount);
            emit WithdrawnRemain(addr, 0, address(token), unlockedAmount);
        }
    }

    function pendingRewards(uint256 pid, address addr) external virtual view returns (uint256) {
        if (pid >= maxPid || startBlock == 0 || block.number < startBlock) {
            return 0;
        }

        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][addr];
        SuperUserInfo memory superUser = getParentUserInfo(pid, addr);
        uint256 amount = superUser.virtAmount;

        uint256 lastMintedBlock = pool.lastBlock;
        if (lastMintedBlock == 0) {
            lastMintedBlock = startBlock;
        }
        uint256 lastBlock = getLastRewardBlock();
        if (lastBlock == 0) {
            return 0;
        }
        SuperPoolInfo memory superPool = getParentPoolInfo(pid);
        uint256 poolTokenRealStaked = superPool.tokenVirtStaked;

        uint256 realTokenPerShare = pool.realTokenPerShare;
        if (lastBlock > lastMintedBlock && poolTokenRealStaked != 0) {
            uint256 tokenPerShare = superPool.tokenPerShare.sub(pool.tokenPerShare);
            realTokenPerShare = realTokenPerShare.add(tokenPerShare.mul(tokenPerBlock));
        }

        return amount.mul(realTokenPerShare).div(1e12).div(tokenParentPrecision).sub(user.rewardDebt).add(user.pendingRewards);
    }

    function update(uint256 pid, address user, uint256 amount) external virtual onlyOwner {
        if (pid >= maxPid || startBlock == 0 || block.number < startBlock) {
            return;
        }
        updatePool(pid);
        updatePendingReward(pid, user);
        updateRealizeReward(pid, user, amount);
    }

    function claim(uint256 pid, address addr) external virtual onlyOwner returns (uint256) {
        if (pid >= maxPid || startBlock == 0 || block.number < startBlock) {
            return 0;
        }

        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][addr];

        updatePool(pid);
        updatePendingReward(pid, addr);

        uint256 claimedAmount = 0;
        if (user.pendingRewards > 0) {
            claimedAmount = transferPendingRewards(pid, addr, user.pendingRewards);
            emit WithdrawnReward(addr, pid, address(token), claimedAmount);
            user.pendingRewards = user.pendingRewards.sub(claimedAmount);
            pool.realTokenReceived = pool.realTokenReceived.add(claimedAmount);
        }

        updateRealizeReward(pid, addr);

        return claimedAmount;
    }

    function addPool(uint256 pid) internal {
        require(maxPid < 10, 'Staking: Cannot add more than 10 pools!');

        SuperPoolInfo memory superPool = getParentPoolInfo(pid);
        poolInfo.push(PoolInfo({
            lastBlock: 0,
            tokenPerShare: superPool.tokenPerShare,
            tokenRewarded: superPool.tokenRewarded,
            realTokenPerShare: 0,
            realTokenReceived: 0,
            realTokenRewarded: 0
        }));
        maxPid = maxPid.add(1);
    }

    function updatePool(uint256 pid) internal {
        if (pid >= maxPid) {
            return;
        }
        if (startBlock == 0 || block.number < startBlock) {
            return;
        }
        PoolInfo storage pool = poolInfo[pid];
        if (pool.lastBlock == 0) {
            pool.lastBlock = startBlock;
        }
        uint256 lastBlock = getLastRewardBlock();
        if (lastBlock <= pool.lastBlock) {
            return;
        }
        SuperPoolInfo memory superPool = getParentPoolInfo(pid);
        uint256 poolTokenRealStaked = superPool.tokenVirtStaked;
        if (poolTokenRealStaked == 0) {
            return;
        }

        // compute the difference between last update in vendor and last update in core staking contract
        // then multiply it by rewardPerBlock value to correctly compute reward
        uint256 multiplier = lastBlock.sub(pool.lastBlock);
        uint256 divisor = superPool.lastBlock.sub(pool.lastBlock);

        uint256 tokenRewarded = superPool.tokenRewarded.sub(pool.tokenRewarded);
        uint256 tokenPerShare = superPool.tokenPerShare.sub(pool.tokenPerShare);

        // if multiplier is different than divisor it means, that before update vendor contract has been closed, therefore
        // we need to multiply the values instead of overwtiitng as the block after close should not count here
        if (multiplier != divisor) {
            tokenRewarded = tokenRewarded.mul(multiplier).div(divisor);
            tokenPerShare = tokenPerShare.mul(multiplier).div(divisor);
        }
        pool.tokenRewarded = pool.tokenRewarded.add(tokenRewarded);
        pool.tokenPerShare = pool.tokenPerShare.add(tokenPerShare);

        pool.realTokenRewarded = pool.realTokenRewarded.add(tokenRewarded.mul(tokenPerBlock).div(tokenParentPrecision));
        pool.realTokenPerShare = pool.realTokenPerShare.add(tokenPerShare.mul(tokenPerBlock));
        pool.lastBlock = lastBlock;
    }

    function updatePendingReward(uint256 pid, address addr) internal {
        if (pid >= maxPid) {
            return;
        }
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][addr];
        SuperUserInfo memory superUser = getParentUserInfo(pid, addr);
        uint256 amount = superUser.virtAmount;

        uint256 reward;
        reward = amount.mul(pool.realTokenPerShare).div(1e12).div(tokenParentPrecision).sub(user.rewardDebt);
        if (reward > 0) {
            user.pendingRewards = user.pendingRewards.add(reward);
            user.rewardDebt = user.rewardDebt.add(reward);
        }
    }

    function updateRealizeReward(uint256 pid, address addr) internal {
        if (pid >= maxPid) {
            return;
        }
        SuperUserInfo memory superUser = getParentUserInfo(pid, addr);
        uint256 amount = superUser.virtAmount;
        return updateRealizeReward(pid, addr, amount);
    }

    function updateRealizeReward(uint256 pid, address addr, uint256 amount) internal {
        if (pid >= maxPid) {
            return;
        }
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][addr];
        uint256 reward;
        reward = amount.mul(pool.realTokenPerShare).div(1e12).div(tokenParentPrecision);
        user.rewardDebt = reward;
    }

    function transferPendingRewards(uint256 pid, address to, uint256 amount) internal returns (uint256) {
        if (pid >= maxPid) {
            return 0;
        }
        if (amount == 0) {
            return 0;
        }
        uint256 tokenAmount = token.balanceOf(address(parent));

        // if reward token is the same as deposit token deduct its balane from withdrawable amount
        if (tokenAmount != 0 && address(token) == address(parent.token())) {
            for (uint i=0; i<maxPid && tokenAmount > 0; i++) {
                uint256 tokenRealStaked = getParentPoolInfo(i).tokenRealStaked;
                tokenAmount = (tokenRealStaked >= tokenAmount) ? 0 : tokenAmount.sub(tokenRealStaked);
            }
        }
        if (tokenAmount == 0) {
            return 0;
        }
        if (tokenAmount > amount) {
            tokenAmount = amount;
        }
        token.safeTransferFrom(address(parent), to, tokenAmount);
        return tokenAmount;
    }

    function getLastRewardBlock() internal view returns (uint256) {
        if (startBlock == 0) return 0;
        if (closeBlock != 0 && closeBlock < block.number) return closeBlock;
        return block.number;
    }

    function getParentUserInfo(uint256 pid, address addr) internal view returns (SuperUserInfo memory) {
        ( uint256 amount, uint256 rewardDebt, uint256 pending, uint256 lockedTimestamp, uint256 lockupTimestamp,
        uint256 lockupTimerange, uint256 virtAmount ) = parent.userInfo(pid, addr);
        return SuperUserInfo({
            amount: amount, rewardDebt: rewardDebt, pendingRewards: pending, lockedTimestamp: lockedTimestamp,
            lockupTimestamp: lockupTimestamp, lockupTimerange: lockupTimerange, virtAmount: virtAmount
        });
    }

    function getParentPoolInfo(uint256 pid) internal view returns (SuperPoolInfo memory) {
        ( uint256 lastBlock, uint256 tokenPerShare, uint256 tokenRealStaked, uint256 tokenVirtStaked,
        uint256 tokenRewarded, uint256 tokenTotalLimit, uint256 lockupMaxTimerange, uint256 lockupMinTimerange ) = parent.poolInfo(pid);
        return SuperPoolInfo({
            lastBlock: lastBlock, tokenPerShare: tokenPerShare, tokenRealStaked: tokenRealStaked,
            tokenVirtStaked: tokenVirtStaked, tokenRewarded: tokenRewarded, tokenTotalLimit: tokenTotalLimit,
            lockupMaxTimerange: lockupMaxTimerange, lockupMinTimerange: lockupMinTimerange
        });
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

abstract contract IStakingV2Vendor {

    function setTokenPerBlock(uint256 _tokenPerBlock) public virtual;

    function setTokenPerBlock(uint256 _tokenPerBlock, uint256 _startBlock, uint256 _closeBlock) public virtual;

    function startBlock() external view virtual returns (uint256);

    function closeBlock() external view virtual returns (uint256);

    function setStartBlock(uint256 _startBlock) public virtual;

    function setCloseBlock(uint256 _closeBlock) public virtual;

    function withdrawRemaining(address addr) external virtual;

    function pendingRewards(uint256 pid, address addr) external virtual view returns (uint256);

    function update(uint256 pid, address user, uint256 amount) external virtual;

    function claim(uint256 pid) external virtual returns (uint256);

    function claim(uint256 pid, address addr) external virtual returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './StakingV2Vendor.sol';
import './IStakingV2.sol';

/**
 * @title Token Staking
 * @dev BEP20 compatible token.
 */
interface IStakingV2Factory {

    function createVendor(address _parent, IERC20 _token) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

abstract contract IStakingV2 {

    function userInfo(uint256 pid, address addr)
    public virtual view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256);

    function poolInfo(uint256 pid)
    public virtual view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256);

    function maxPid() public virtual view returns (uint256);

    function token() public virtual view returns (address);

    function tokenPerBlock() public virtual view returns (uint256);

    function pendingRewards(uint256 pid, address addr, address asset) external virtual view returns (uint256);

    function deposit(uint256 pid, address addr, uint256 amount, uint256 timerange) external virtual;

    function restake(uint256 pid, address addr, uint256 amount, uint256 timerange) external virtual;

    function withdraw(uint256 pid, address addr, uint256 amount) external virtual;

    function claim(uint256 pid) external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

interface IStakingDelegate {

    function balanceChanged(address user, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}
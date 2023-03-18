// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.9;

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


struct ItMap {
    // pid => boost
    mapping(uint256 => uint256) data;
    // pid => index
    mapping(uint256 => uint256) indexs;
    // array of pid
    uint256[] keys;
    // never use it, just for keep compile success.
    uint256 size;
}

library IterableMapping {
    function insert(
        ItMap storage self,
        uint256 key,
        uint256 value
    ) internal {
        uint256 keyIndex = self.indexs[key];
        self.data[key] = value;
        if (keyIndex > 0) return;
        else {
            self.indexs[key] = self.keys.length + 1;
            self.keys.push(key);
            return;
        }
    }

    function remove(ItMap storage self, uint256 key) internal {
        uint256 index = self.indexs[key];
        if (index == 0) return;
        uint256 lastKey = self.keys[self.keys.length - 1];
        if (key != lastKey) {
            self.keys[index - 1] = lastKey;
            self.indexs[lastKey] = index;
        }
        delete self.data[key];
        delete self.indexs[key];
        self.keys.pop();
    }

    function contains(ItMap storage self, uint256 key) internal view returns (bool) {
        return self.indexs[key] > 0;
    }
}


interface IMasterChefV2 {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function pendingCake(uint256 _pid, address _user) external view returns (uint256);

    function userInfo(uint256 _pid, address _user)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function emergencyWithdraw(uint256 _pid) external;

    function lpToken(uint256 _pid) external view returns (address);

    function poolLength() external view returns (uint256 pools);

    function getBoostMultiplier(address _user, uint256 _pid) external view returns (uint256);

    function updateBoostMultiplier(
        address _user,
        uint256 _pid,
        uint256 _newMultiplier
    ) external;
}

interface ICakePool {
    function userInfo(address _user)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        );

    function getPricePerFullShare() external view returns (uint256);

    function totalLockedAmount() external view returns (uint256);

    function totalShares() external view returns (uint256);

    function BOOST_WEIGHT() external view returns (uint256);

    function MAX_LOCK_DURATION() external view returns (uint256);
}

interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the token name.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender)
    external
    view
    returns (uint256);

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

contract FarmBooster is Ownable {
    using IterableMapping for ItMap;

    /// @notice cake token.
    address public immutable CAKE;
    /// @notice cake pool.
    address public immutable CAKE_POOL;
    /// @notice MCV2 contract.
    address public immutable MASTER_CHEF;
    /// @notice boost proxy factory.
    address public BOOSTER_FACTORY;

    /// @notice Maximum allowed boosted pool numbers
    uint256 public MAX_BOOST_POOL;
    /// @notice limit max boost
    uint256 public cA;
    /// @notice include 1e4
    uint256 public constant MIN_CA = 1e4;
    /// @notice include 1e5
    uint256 public constant MAX_CA = 1e5;
    /// @notice cA precision
    uint256 public constant CA_PRECISION = 1e5;
    /// @notice controls difficulties
    uint256 public cB;
    /// @notice not include 0
    uint256 public constant MIN_CB = 0;
    /// @notice include 50
    uint256 public constant MAX_CB = 50;
    /// @notice MCV2 basic boost factor, none boosted user's boost factor
    uint256 public constant BOOST_PRECISION = 100 * 1e10;
    /// @notice MCV2 Hard limit for maxmium boost factor
    uint256 public constant MAX_BOOST_PRECISION = 200 * 1e10;
    /// @notice Average boost ratio precion
    uint256 public constant BOOST_RATIO_PRECISION = 1e5;
    /// @notice Cake pool BOOST_WEIGHT precision
    uint256 public constant BOOST_WEIGHT_PRECISION = 100 * 1e10; // 100%

    /// @notice The whitelist of pools allowed for farm boosting.
    mapping(uint256 => bool) public whiteList;
    /// @notice The boost proxy contract mapping(user => proxy).
    mapping(address => address) public proxyContract;
    /// @notice Info of each pool user.
    mapping(address => ItMap) public userInfo;

    event UpdateMaxBoostPool(uint256 factory);
    event UpdateBoostFactory(address factory);
    event UpdateCA(uint256 oldCA, uint256 newCA);
    event UpdateCB(uint256 oldCB, uint256 newCB);
    event Refresh(address indexed user, address proxy, uint256 pid);
    event UpdateBoostFarms(uint256 pid, bool status);
    event ActiveFarmPool(address indexed user, address proxy, uint256 pid);
    event DeactiveFarmPool(address indexed user, address proxy, uint256 pid);
    event UpdateBoostProxy(address indexed user, address proxy);
    event UpdatePoolBoostMultiplier(address indexed user, uint256 pid, uint256 oldMultiplier, uint256 newMultiplier);
    event UpdateCakePool(
        address indexed user,
        uint256 lockedAmount,
        uint256 lockedDuration,
        uint256 totalLockedAmount,
        uint256 maxLockDuration
    );

    /// @param _cake CAKE token contract address.
    /// @param _cakePool Cake Pool contract address.
    /// @param _v2 MasterChefV2 contract address.
    /// @param _max Maximum allowed boosted farm  quantity
    /// @param _cA Limit max boost
    /// @param _cB Controls difficulties
    constructor(
        address _cake,
        address _cakePool,
        address _v2,
        uint256 _max,
        uint256 _cA,
        uint256 _cB
    ) {
        require(
            _max > 0 && _cA >= MIN_CA && _cA <= MAX_CA && _cB > MIN_CB && _cB <= MAX_CB,
            "constructor: Invalid parameter"
        );
        CAKE = _cake;
        CAKE_POOL = _cakePool;
        MASTER_CHEF = _v2;
        MAX_BOOST_POOL = _max;
        cA = _cA;
        cB = _cB;
    }

    /// @notice Checks if the msg.sender is a contract or a proxy
    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    /// @notice Checks if the msg.sender is the FarmBooster Factory.
    modifier onlyFactory() {
        require(msg.sender == BOOSTER_FACTORY, "onlyFactory: Not factory");
        _;
    }

    /// @notice Checks if the msg.sender is the FarmBooster Proxy.
    modifier onlyProxy(address _user) {
        require(msg.sender == proxyContract[_user], "onlyProxy: Not proxy");
        _;
    }

    /// @notice Checks if the msg.sender is the cake pool.
    modifier onlyCakePool() {
        require(msg.sender == CAKE_POOL, "onlyCakePool: Not cake pool");
        _;
    }

    /// @notice set maximum allowed boosted pool numbers.
    function setMaxBoostPool(uint256 _max) external onlyOwner {
        require(_max > 0, "setMaxBoostPool: Maximum boost pool should greater than 0");
        MAX_BOOST_POOL = _max;
        emit UpdateMaxBoostPool(_max);
    }

    /// @notice set boost factory contract.
    function setBoostFactory(address _factory) external onlyOwner {
        require(_factory != address(0), "setBoostFactory: Invalid factory");
        BOOSTER_FACTORY = _factory;

        emit UpdateBoostFactory(_factory);
    }

    /// @notice Set user boost proxy contract, can only invoked by boost contract.
    /// @param _user boost user address.
    /// @param _proxy boost proxy contract.
    function setProxy(address _user, address _proxy) external onlyFactory {
        require(_proxy != address(0), "setProxy: Invalid proxy address");
        require(proxyContract[_user] == address(0), "setProxy: User has already set proxy");

        proxyContract[_user] = _proxy;

        emit UpdateBoostProxy(_user, _proxy);
    }

    /// @notice Only allow whitelisted pids for farm boosting
    /// @param _pid pool id(MasterchefV2 pool).
    /// @param _status farm pool allowed boosted or not
    function setBoosterFarms(uint256 _pid, bool _status) external onlyOwner {
        whiteList[_pid] = _status;
        emit UpdateBoostFarms(_pid, _status);
    }

    /// @notice limit max boost
    /// @param _cA max boost
    function setCA(uint256 _cA) external onlyOwner {
        require(_cA >= MIN_CA && _cA <= MAX_CA, "setCA: Invalid cA");
        uint256 temp = cA;
        cA = _cA;
        emit UpdateCA(temp, cA);
    }

    /// @notice controls difficulties
    /// @param _cB difficulties
    function setCB(uint256 _cB) external onlyOwner {
        require(_cB > MIN_CB && _cB <= MAX_CB, "setCB: Invalid cB");
        uint256 temp = cB;
        cB = _cB;
        emit UpdateCB(temp, cB);
    }

    /// @notice Cakepool operation(deposit/withdraw) automatically call this function.
    /// @param _user user address.
    /// @param _lockedAmount user locked amount in cake pool.
    /// @param _lockedDuration user locked duration in cake pool.
    /// @param _totalLockedAmount Total locked cake amount in cake pool.
    /// @param _maxLockDuration maximum locked duration in cake pool.
    function onCakePoolUpdate(
        address _user,
        uint256 _lockedAmount,
        uint256 _lockedDuration,
        uint256 _totalLockedAmount,
        uint256 _maxLockDuration
    ) external onlyCakePool {
        address proxy = proxyContract[_user];
        ItMap storage itmap = userInfo[proxy];
        uint256 avgDuration;
        bool flag;
        for (uint256 i = 0; i < itmap.keys.length; i++) {
            uint256 pid = itmap.keys[i];
            if (!flag) {
                avgDuration = avgLockDuration();
                flag = true;
            }
            _updateBoostMultiplier(_user, proxy, pid, avgDuration);
        }

        emit UpdateCakePool(_user, _lockedAmount, _lockedDuration, _totalLockedAmount, _maxLockDuration);
    }

    /// @notice Update user boost multiplier in V2 pool,only for proxy.
    /// @param _user user address.
    /// @param _pid pool id in MasterchefV2 pool.
    function updatePoolBoostMultiplier(address _user, uint256 _pid) public onlyProxy(_user) {
        // if user not actived this farm, just return.
        if (!userInfo[msg.sender].contains(_pid)) return;
        _updateBoostMultiplier(_user, msg.sender, _pid, avgLockDuration());
    }

    /// @notice Active user farm pool.
    /// @param _pid pool id(MasterchefV2 pool).
    function activate(uint256 _pid) external {
        address proxy = proxyContract[msg.sender];
        require(whiteList[_pid] && proxy != address(0), "activate: Not boosted farm pool");

        ItMap storage itmap = userInfo[proxy];
        require(itmap.keys.length < MAX_BOOST_POOL, "activate: Boosted farms reach to MAX");

        _updateBoostMultiplier(msg.sender, proxy, _pid, avgLockDuration());

        emit ActiveFarmPool(msg.sender, proxy, _pid);
    }

    /// @notice Deactive user farm pool.
    /// @param _pid pool id(MasterchefV2 pool).
    function deactive(uint256 _pid) external {
        address proxy = proxyContract[msg.sender];
        ItMap storage itmap = userInfo[proxy];
        require(itmap.contains(_pid), "deactive: None boost user");

        if (itmap.data[_pid] > BOOST_PRECISION) {
            IMasterChefV2(MASTER_CHEF).updateBoostMultiplier(proxy, _pid, BOOST_PRECISION);
        }
        itmap.remove(_pid);

        emit DeactiveFarmPool(msg.sender, proxy, _pid);
    }

    /// @notice Anyone can refesh sepecific user boost multiplier
    /// @param _user user address.
    /// @param _pid pool id(MasterchefV2 pool).
    function refresh(address _user, uint256 _pid) external notContract {
        address proxy = proxyContract[_user];
        ItMap storage itmap = userInfo[proxy];
        require(itmap.contains(_pid), "refresh: None boost user");

        _updateBoostMultiplier(_user, proxy, _pid, avgLockDuration());

        emit Refresh(_user, proxy, _pid);
    }

    /// @notice Whether user boosted specific farm pool.
    /// @param _user user address.
    /// @param _pid pool id(MasterchefV2 pool).
    function isBoostedPool(address _user, uint256 _pid) external view returns (bool) {
        return userInfo[proxyContract[_user]].contains(_pid);
    }

    /// @notice Actived farm pool list.
    /// @param _user user address.
    function activedPools(address _user) external view returns (uint256[] memory pools) {
        ItMap storage itmap = userInfo[proxyContract[_user]];
        if (itmap.keys.length == 0) return pools;

        pools = new uint256[](itmap.keys.length);
        // solidity for-loop not support multiple variables initializae by ',' separate.
        uint256 i;
        for (uint256 index = 0; index < itmap.keys.length; index++) {
            uint256 pid = itmap.keys[index];
            pools[i] = pid;
            i++;
        }
    }

    /// @notice Anyone can call this function, if you find some guys effectived multiplier is not fair
    /// for other users, just call 'refresh' function.
    /// @param _user user address.
    /// @param _pid pool id(MasterchefV2 pool).
    /// @dev If return value not in range [BOOST_PRECISION, MAX_BOOST_PRECISION]
    /// the actual effectived multiplier will be the close to side boundry value.
    function getUserMultiplier(address _user, uint256 _pid) external view returns (uint256) {
        return _boostCalculate(_user, proxyContract[_user], _pid, avgLockDuration());
    }

    /// @notice cake pool average locked duration calculator.
    function avgLockDuration() public view returns (uint256) {
        uint256 totalStakedAmount = IBEP20(CAKE).balanceOf(CAKE_POOL);

        uint256 totalLockedAmount = ICakePool(CAKE_POOL).totalLockedAmount();

        uint256 pricePerFullShare = ICakePool(CAKE_POOL).getPricePerFullShare();

        uint256 flexibleShares = ((totalStakedAmount - totalLockedAmount) * 1e18) / pricePerFullShare;
        if (flexibleShares == 0) return 0;

        uint256 originalShares = (totalLockedAmount * 1e18) / pricePerFullShare;
        if (originalShares == 0) return 0;

        uint256 boostedRatio = ((ICakePool(CAKE_POOL).totalShares() - flexibleShares) * BOOST_RATIO_PRECISION) /
            originalShares;
        if (boostedRatio <= BOOST_RATIO_PRECISION) return 0;

        uint256 boostWeight = ICakePool(CAKE_POOL).BOOST_WEIGHT();
        uint256 maxLockDuration = ICakePool(CAKE_POOL).MAX_LOCK_DURATION() * BOOST_RATIO_PRECISION;

        uint256 duration = ((boostedRatio - BOOST_RATIO_PRECISION) * 365 * BOOST_WEIGHT_PRECISION) / boostWeight;
        return duration <= maxLockDuration ? duration : maxLockDuration;
    }

    /// @param _user user address.
    /// @param _proxy proxy address corresponding to the user.
    /// @param _pid pool id.
    /// @param _duration cake pool average locked duration.
    function _updateBoostMultiplier(
        address _user,
        address _proxy,
        uint256 _pid,
        uint256 _duration
    ) internal {
        ItMap storage itmap = userInfo[_proxy];

        // Used to be boost farm pool and current is not, remove from mapping
        if (!whiteList[_pid]) {
            if (itmap.data[_pid] > BOOST_PRECISION) {
                // reset to BOOST_PRECISION
                IMasterChefV2(MASTER_CHEF).updateBoostMultiplier(_proxy, _pid, BOOST_PRECISION);
            }
            itmap.remove(_pid);
            return;
        }

        uint256 prevMultiplier = IMasterChefV2(MASTER_CHEF).getBoostMultiplier(_proxy, _pid);
        uint256 multiplier = _boostCalculate(_user, _proxy, _pid, _duration);

        if (multiplier < BOOST_PRECISION) {
            multiplier = BOOST_PRECISION;
        } else if (multiplier > MAX_BOOST_PRECISION) {
            multiplier = MAX_BOOST_PRECISION;
        }

        // Update multiplier to MCV2
        if (multiplier != prevMultiplier) {
            IMasterChefV2(MASTER_CHEF).updateBoostMultiplier(_proxy, _pid, multiplier);
        }
        itmap.insert(_pid, multiplier);

        emit UpdatePoolBoostMultiplier(_user, _pid, prevMultiplier, multiplier);
    }

    /// @param _user user address.
    /// @param _proxy proxy address corresponding to the user.
    /// @param _pid pool id(MasterchefV2 pool).
    /// @param _duration cake pool average locked duration.
    function _boostCalculate(
        address _user,
        address _proxy,
        uint256 _pid,
        uint256 _duration
    ) internal view returns (uint256) {
        if (_duration == 0) return BOOST_PRECISION;

        (uint256 lpBalance, , ) = IMasterChefV2(MASTER_CHEF).userInfo(_pid, _proxy);
        uint256 dB = (cA * lpBalance) / CA_PRECISION;
        // dB == 0 means lpBalance close to 0
        if (lpBalance == 0 || dB == 0) return BOOST_PRECISION;

        (, , , , uint256 lockStartTime, uint256 lockEndTime, , , uint256 userLockedAmount) = ICakePool(CAKE_POOL)
            .userInfo(_user);
        if (userLockedAmount == 0 || block.timestamp >= lockEndTime) return BOOST_PRECISION;

        // userLockedAmount > 0 means totalLockedAmount > 0
        uint256 totalLockedAmount = ICakePool(CAKE_POOL).totalLockedAmount();

        IBEP20 lp = IBEP20(IMasterChefV2(MASTER_CHEF).lpToken(_pid));
        uint256 userLockedDuration = (lockEndTime - lockStartTime) / (3600 * 24); // days

        uint256 aB = (((lp.balanceOf(MASTER_CHEF) * userLockedAmount * userLockedDuration) * BOOST_RATIO_PRECISION) /
            cB) / (totalLockedAmount * _duration);

        // should '*' BOOST_PRECISION
        return ((lpBalance < (dB + aB) ? lpBalance : (dB + aB)) * BOOST_PRECISION) / dB;
    }

    /// @notice Checks if address is a contract
    /// @dev It prevents contract from being targetted
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/interfaces/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import './interfaces/ISCSGStaking.sol';
import './interfaces/ISCSGStakeBooster.sol';

contract SCSGStaking is ERC20, IERC721Receiver, ISCSGStaking, Ownable {
  using SafeMath for uint256;

  struct PoolInfo {
    uint256 poolTotalSupply; // supply of rewards tokens put up to be rewarded by original owner
    uint256 poolRemainingSupply; // current supply of rewards
    uint256 totalTokensStaked; // current amount of tokens staked
    uint256 creationBlock; // block this contract was created
    uint256 perBlockNum; // amount of rewards tokens rewarded per block
    uint256 timelockSeconds; // min number seconds how long a staker must lock tokens
    uint256 lastRewardBlock; // Last block number that ERC20s distribution occurs.
    uint256 accERC20PerShare; // Accumulated ERC20s per share, times 1e36.
  }

  struct StakerInfo {
    uint256 amountStaked; // the amount ERC20 tokens with added boosting (when applicable) that is used for calculating rewards
    uint256 amountStakedBase; // the exact amount ERC20 tokens the user has put up as staking collateral
    uint256 blockOriginallyStaked; // block the user originally staked
    uint256 timeOriginallyStaked; // unix timestamp in seconds that the user originally staked
    uint256 blockLastHarvested; // the block the user last claimed/harvested rewards
    uint256 rewardDebt; // Reward debt. See explanation below.
    address[] nftContracts;
    uint256[] nftTokenIds;
  }

  uint256 launchTime;
  bool public poolDeactivated = false;

  IERC20 internal _scsg;
  ISCSGStakeBooster internal _booster;
  PoolInfo public pool;

  // mapping of userAddresses => tokenAddresses that can can be evaluated
  // to determine for a particular user which tokens they are staking.
  mapping(address => StakerInfo) public stakers;

  event Deposit(address indexed user, uint256 amount);
  event Withdraw(address indexed user, uint256 amount);

  /**
   * @notice The constructor for the Staking Token.
   * @param _scsgTokenAddress Contract address of token to be staked by users
   * @param _stakeBooster The logic to boost rewards
   */
  constructor(address _scsgTokenAddress, address _stakeBooster)
    ERC20('SCSG Staking', 'sSCSG')
  {
    _scsg = IERC20(_scsgTokenAddress);
    _booster = ISCSGStakeBooster(_stakeBooster);
  }

  function onERC721Received(
    address, /* operator */
    address, /* from */
    uint256, /* tokenId */
    bytes calldata /* data */
  ) external returns (bytes4) {
    return this.onERC721Received.selector;
  }

  /**
   * @notice launch
   * @param _rewardSupply The amount of tokens to mint on construction, this should be the same as the tokens provided by the creating user.
   * @param _perBlockAmount Amount of tokens to be rewarded per block
   * @param _timelockSeconds Min number seconds a user has to lock tokens in pool before withdrawing
   */
  function launch(
    uint256 _rewardSupply,
    uint256 _perBlockAmount,
    uint256 _timelockSeconds
  ) external onlyOwner {
    require(launchTime == 0, 'already launched');
    launchTime = block.timestamp;

    require(_perBlockAmount <= _rewardSupply, 'per block more than rewards');

    pool = PoolInfo({
      poolTotalSupply: _rewardSupply,
      poolRemainingSupply: _rewardSupply,
      totalTokensStaked: 0,
      creationBlock: 0,
      perBlockNum: _perBlockAmount,
      timelockSeconds: _timelockSeconds,
      lastRewardBlock: block.number,
      accERC20PerShare: 0
    });

    if (_rewardSupply > 0) {
      _scsg.transferFrom(msg.sender, address(this), _rewardSupply);
    }
  }

  function addToSupply(uint256 _additionalSupply) external {
    require(launchTime > 0, 'launch pool first');
    require(pool.perBlockNum > 0, 'no rewards allocation for pool');
    require(_additionalSupply >= pool.perBlockNum, 'must add 1 block at least');

    uint256 _balBefore = _scsg.balanceOf(address(this));
    _scsg.transferFrom(msg.sender, address(this), _additionalSupply);
    _additionalSupply = _scsg.balanceOf(address(this)) - _balBefore;

    pool.poolTotalSupply += _additionalSupply;
    pool.poolRemainingSupply += _additionalSupply;
  }

  function getSCSG() external view returns (address) {
    return address(_scsg);
  }

  function getBooster() external view returns (address) {
    return address(_booster);
  }

  function setBooster(address __booster) external onlyOwner {
    _booster = ISCSGStakeBooster(__booster);
  }

  function stakeTokens(
    uint256 _amount,
    address[] memory _nftContracts,
    uint256[] memory _tokenIds
  ) public {
    require(launchTime > 0, 'launch pool first');
    require(
      getLastStakableBlock() > block.number,
      'this farm is expired and no more stakers can be added'
    );
    require(!poolDeactivated, 'cannot stake in inactive pool');
    require(
      _nftContracts.length == _tokenIds.length,
      'must be 1-to-1 NFT contract to token ID'
    );

    StakerInfo storage _staker = stakers[msg.sender];
    _updatePool();

    if (balanceOf(msg.sender) > 0) {
      _harvestTokens(msg.sender);
    }

    uint256 _finalAmountTransferred;
    uint256 _contractBalanceBefore = _scsg.balanceOf(address(this));
    _scsg.transferFrom(msg.sender, address(this), _amount);

    (uint256 _boostPercentage, uint256 _boostDenomenator) = address(_booster) ==
      address(0)
      ? (0, 1)
      : _booster.getMultiplier(msg.sender, _nftContracts, _tokenIds);
    for (uint256 _i = 0; _i < _nftContracts.length; _i++) {
      IERC721(_nftContracts[_i]).safeTransferFrom(
        msg.sender,
        address(this),
        _tokenIds[_i]
      );
      _staker.nftContracts.push(_nftContracts[_i]);
      _staker.nftTokenIds.push(_tokenIds[_i]);
    }

    _finalAmountTransferred = _scsg.balanceOf(address(this)).sub(
      _contractBalanceBefore
    );
    uint256 _finalAmountIncludingBoosted = _finalAmountTransferred.add(
      _finalAmountTransferred.mul(_boostPercentage).div(_boostDenomenator)
    );

    if (totalSupply() == 0) {
      pool.creationBlock = block.number;
      pool.lastRewardBlock = block.number;
    }
    _mint(msg.sender, _finalAmountIncludingBoosted);
    _staker.amountStaked = _staker.amountStaked.add(
      _finalAmountIncludingBoosted
    );
    _staker.amountStakedBase = _staker.amountStakedBase.add(
      _finalAmountTransferred
    );
    _staker.blockOriginallyStaked = block.number;
    _staker.timeOriginallyStaked = block.timestamp;
    _staker.blockLastHarvested = block.number;
    _staker.rewardDebt = _staker.amountStaked.mul(pool.accERC20PerShare).div(
      1e36
    );
    _updNumStaked(_finalAmountTransferred, 'add');
    emit Deposit(msg.sender, _finalAmountTransferred);
  }

  // pass 'false' for _shouldHarvest for emergency unstaking without claiming rewards
  function unstakeTokens(uint256 _amountBoosted, bool _shouldHarvest) external {
    StakerInfo memory _staker = stakers[msg.sender];
    uint256 _userBalance = _staker.amountStaked;
    require(
      _amountBoosted == 0 || _amountBoosted <= _userBalance,
      'user can only unstake amount they have currently staked or less'
    );
    require(
      block.timestamp >= _staker.timeOriginallyStaked + pool.timelockSeconds,
      'must wait lockup period before unstaking'
    );

    _amountBoosted = _amountBoosted == 0
      ? _staker.amountStaked
      : _amountBoosted;

    _updatePool();

    if (_shouldHarvest) {
      _harvestTokens(msg.sender);
    }

    uint256 _boostedAmountToRemove = _amountBoosted;
    uint256 _baseAmountToRemove = _amountBoosted
      .mul(_staker.amountStakedBase)
      .div(_staker.amountStaked);
    _burn(
      msg.sender,
      _boostedAmountToRemove > balanceOf(msg.sender)
        ? balanceOf(msg.sender)
        : _boostedAmountToRemove
    );
    require(
      _scsg.transfer(msg.sender, _baseAmountToRemove),
      'unable to send user original tokens'
    );

    if (balanceOf(msg.sender) <= 0) {
      for (uint256 _i = 0; _i < _staker.nftContracts.length; _i++) {
        IERC721(_staker.nftContracts[_i]).safeTransferFrom(
          address(this),
          msg.sender,
          _staker.nftTokenIds[_i]
        );
      }
      delete stakers[msg.sender];
    } else {
      _staker.amountStaked = _staker.amountStaked.sub(_boostedAmountToRemove);
      _staker.amountStakedBase = _staker.amountStakedBase.sub(
        _baseAmountToRemove
      );
    }
    _updNumStaked(_boostedAmountToRemove, 'remove');
    emit Withdraw(msg.sender, _boostedAmountToRemove);
  }

  function emergencyUnstake() external {
    StakerInfo memory _staker = stakers[msg.sender];
    uint256 _boostedAmountToRemove = _staker.amountStaked;
    uint256 _baseAmountToRemove = _staker.amountStakedBase;
    require(
      _baseAmountToRemove > 0,
      'user can only unstake if they have tokens in the pool'
    );
    _burn(
      msg.sender,
      _boostedAmountToRemove > balanceOf(msg.sender)
        ? balanceOf(msg.sender)
        : _boostedAmountToRemove
    );
    require(
      _scsg.transfer(msg.sender, _baseAmountToRemove),
      'unable to send user original tokens'
    );
    for (uint256 _i = 0; _i < _staker.nftContracts.length; _i++) {
      IERC721(_staker.nftContracts[_i]).safeTransferFrom(
        address(this),
        msg.sender,
        _staker.nftTokenIds[_i]
      );
    }

    delete stakers[msg.sender];
    _updNumStaked(_boostedAmountToRemove, 'remove');
    emit Withdraw(msg.sender, _boostedAmountToRemove);
  }

  function harvestForUser(address _wallet, bool _autoCompound)
    external
    returns (uint256)
  {
    require(
      msg.sender == owner() || msg.sender == _wallet,
      'can only harvest tokens for someone else if this was the contract creator'
    );
    _updatePool();
    uint256 _tokensToUser = _harvestTokens(_wallet);

    if (_autoCompound) {
      address[] memory _contPlaceholder;
      uint256[] memory _idPlaceholder;
      stakeTokens(_tokensToUser, _contPlaceholder, _idPlaceholder);
    }

    return _tokensToUser;
  }

  function getLastStakableBlock() public view returns (uint256) {
    uint256 _blockToAdd = pool.creationBlock == 0
      ? block.number
      : pool.creationBlock;
    return pool.poolTotalSupply.div(pool.perBlockNum).add(_blockToAdd);
  }

  function calcHarvestTot(address _wallet) public view returns (uint256) {
    StakerInfo memory _staker = stakers[_wallet];

    if (
      _staker.blockLastHarvested >= block.number ||
      _staker.blockOriginallyStaked == 0 ||
      pool.totalTokensStaked == 0 ||
      pool.perBlockNum == 0
    ) {
      return 0;
    }

    uint256 _accERC20PerShare = pool.accERC20PerShare;

    if (block.number > pool.lastRewardBlock && pool.totalTokensStaked != 0) {
      uint256 _endBlock = getLastStakableBlock();
      uint256 _lastBlock = block.number < _endBlock ? block.number : _endBlock;
      uint256 _nrOfBlocks = _lastBlock.sub(pool.lastRewardBlock);
      uint256 _erc20Reward = _nrOfBlocks.mul(pool.perBlockNum);
      _accERC20PerShare = _accERC20PerShare.add(
        _erc20Reward.mul(1e36).div(pool.totalTokensStaked)
      );
    }

    return
      _staker.amountStaked.mul(_accERC20PerShare).div(1e36).sub(
        _staker.rewardDebt
      );
  }

  // Update reward variables of the given pool to be up-to-date.
  function _updatePool() private {
    uint256 _endBlock = getLastStakableBlock();
    uint256 _lastBlock = block.number < _endBlock ? block.number : _endBlock;

    if (_lastBlock <= pool.lastRewardBlock) {
      return;
    }
    uint256 _stakedSupply = pool.totalTokensStaked;
    if (_stakedSupply == 0) {
      pool.lastRewardBlock = _lastBlock;
      return;
    }

    uint256 _nrOfBlocks = _lastBlock.sub(pool.lastRewardBlock);
    uint256 _erc20Reward = _nrOfBlocks.mul(pool.perBlockNum);

    pool.accERC20PerShare = pool.accERC20PerShare.add(
      _erc20Reward.mul(1e36).div(_stakedSupply)
    );
    pool.lastRewardBlock = _lastBlock;
  }

  function _harvestTokens(address _wallet) internal returns (uint256) {
    StakerInfo storage _staker = stakers[_wallet];
    require(_staker.blockOriginallyStaked > 0, 'user must have tokens staked');

    uint256 _num2Trans = calcHarvestTot(_wallet);
    _sendRewardsToUser(_wallet, _num2Trans);
    _staker.rewardDebt = _staker.amountStaked.mul(pool.accERC20PerShare).div(
      1e36
    );
    _staker.blockLastHarvested = block.number;
    return _num2Trans;
  }

  function _sendRewardsToUser(address _user, uint256 _amount) internal {
    if (_amount == 0) return;
    require(
      _scsg.transfer(_user, _amount),
      'unable to send user their harvested tokens'
    );
    pool.poolRemainingSupply = pool.poolRemainingSupply.sub(_amount);
  }

  // update the amount currently staked after a user harvests
  function _updNumStaked(uint256 _amount, string memory _operation) internal {
    if (_compareStr(_operation, 'remove')) {
      pool.totalTokensStaked = pool.totalTokensStaked.sub(_amount);
    } else {
      pool.totalTokensStaked = pool.totalTokensStaked.add(_amount);
    }
  }

  function _compareStr(string memory a, string memory b)
    internal
    pure
    returns (bool)
  {
    return (keccak256(abi.encodePacked((a))) ==
      keccak256(abi.encodePacked((b))));
  }

  function getStakedSharesBoosted(address _account)
    external
    view
    override
    returns (uint256)
  {
    return stakers[_account].amountStaked;
  }

  function getStakedSharesBase(address _account)
    external
    view
    override
    returns (uint256)
  {
    return stakers[_account].amountStakedBase;
  }

  function setTimelockSeconds(uint256 _seconds) external onlyOwner {
    pool.timelockSeconds = _seconds;
  }

  function removeStakeableTokens() external onlyOwner {
    require(pool.poolRemainingSupply > 0, 'must have supply to send owner');
    _scsg.transfer(owner(), pool.poolRemainingSupply);
    pool.poolRemainingSupply = 0;
    poolDeactivated = true;
  }

  function withdrawERC20(address _tokenAddy, uint256 _amount)
    external
    onlyOwner
  {
    IERC20 _token = IERC20(_tokenAddy);
    _amount = _amount > 0 ? _amount : _token.balanceOf(address(this));
    require(_amount > 0, 'make sure there is a balance available to withdraw');
    _token.transfer(owner(), _amount);
  }

  function withdrawERC721(address _nftContract, uint256[] memory _tokenIds)
    external
    onlyOwner
  {
    IERC721 nftContract = IERC721(_nftContract);
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      nftContract.safeTransferFrom(address(this), owner(), _tokenIds[i]);
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
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
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
pragma solidity ^0.8.9;

interface ISCSGStaking {
  function getStakedSharesBoosted(address wallet)
    external
    view
    returns (uint256);

  function getStakedSharesBase(address wallet) external view returns (uint256);

  // function getBoostNfts(address wallet)
  //   external
  //   view
  //   returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISCSGStakeBooster {
  function getMultiplier(
    address user,
    address[] memory nftContracts,
    uint256[] memory tokenIds
  ) external view returns (uint256, uint256);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
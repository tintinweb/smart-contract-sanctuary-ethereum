// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IByteContract.sol";
import "./interfaces/ICitizen.sol";
import "./interfaces/IStaker.sol";

/*
  It saves bytecode to revert on custom errors instead of using require
  statements. We are just declaring these errors for reverting with upon various
  conditions later in this contract.
*/
error DoNotHaveRightToBurn();
error DoNotHaveEnoughOldBytes();
error CannotUpdateEmissionRateEarly();
error CallerIsNotCitizen();
error ItemIsStaked();
error UserDontStake();

/**
*/
contract BYTESContract2_0 is
  Ownable, ERC20("BYTES", "BYTES")
{

  /// The time lock on the rate at which BYTES emissions may be adjusted.
  uint256 public immutable emissionUpdatePeriod;

  /// address of citizen S1 contract
  address citizenContract;

  /// address of staking contract
  address stakingContract;

  /// address of tresure contract
  address treasureContract;

  /// address of $BYTES v1
  address bytesContract;

  ///
  uint256 maxRewardableCitizens;

  ///
  mapping ( address => uint256 ) public rewards;

  ///
  mapping ( address => uint256 ) public lastUpdate;

  ///
  mapping ( address => bool ) adminContracts;

  /**
    This struct defines details surrounding the emission of BYTES within some
    time period.

    @param dailyYield The maximum yield in BYTES that may be minted per day
      between `startTime` and `endTime`.
    @param startTime The starting time of this emission range.
    @param endTime The ending time of this emission range.
  */
  struct Emission {
    uint256 dailyYield;
    uint256 startTime;
    uint256 endTime;
  }

  /**
    An array that stores the historical maximum values of daily BYTES emissions
    as a series of `Emission` structs.
  */
  Emission[] public emissions;

  /**
   */
  struct Citizen {
    uint256 tokenId;
    uint256 seasonId;
  }

  /**
  */
  event RewardPaid (
    address indexed user,
    uint256 reward
  );

  /**
  */
  event BytesUpdated(
    address indexed user,
    uint256 amountUpdated
  );

  /**
    Emits when new value for emision is added
  */
  event EmissionUpdated (
    uint256 previousValue,
    uint256 currentValue
  );

  /**
  */
  constructor (
    address _stakingContract,
    address _treasureContract,
    uint256 _emissionUpdatePeriod
  ) {
    maxRewardableCitizens = 2501;
    bytesContract = 0x7d647b1A0dcD5525e9C6B3D14BE58f27674f8c95;
    citizenContract = 0xb668beB1Fa440F6cF2Da0399f8C28caB993Bdd65;
    stakingContract = _stakingContract;
    treasureContract = _treasureContract;
    emissionUpdatePeriod = _emissionUpdatePeriod;
  }

  /**
    Return the current maximum daily yield in BYTES.

    @return The daily yield of the last element in the emissions array.
  */
  function getCurrentDailyYield () external view returns (uint) {
    return emissions[emissions.length - 1].dailyYield;
  }

  /** 
    return information about emisiion at concrete at some moment 

    @return emission Emmision struct that contains yeild value, startTime and 
      endTime
   */
  function getConcreteEmmission(uint _position) external view returns (uint256, uint256, uint256){
    uint256 dailyYield = emissions[_position].dailyYield;
    uint256 startTime = emissions[_position].startTime;
    uint256 endTime = emissions[_position].endTime; 
    return (dailyYield, startTime, endTime);
  }

  /** 
    return number of emmision values in emmision array,  
   */
  function getEmmissionLenght() external view returns (uint){
    return emissions.length;
  }
  /**
  */
  function updateMaxRewardableTokens (
    uint256 _amount
  ) public onlyOwner {
    maxRewardableCitizens = _amount;
  }

  /**
  */
  function addAdminContractAddress (
    address _address
  ) public onlyOwner {
    adminContracts[_address] = true;
  }

  /**
  */
  function removeAdminContractAddress (
    address _address
  ) public onlyOwner {
    adminContracts[_address] = false;
  }

  /**
  */
  function changeStakingContractAddress (
    address _stakingContract
  ) public onlyOwner {
    stakingContract = _stakingContract;
  }

  /**
  */
  function changeTreasureContractAddress (
    address _treasureContract
  ) public onlyOwner {
    treasureContract = _treasureContract;
  }

  /**
  */
  function setBytesContract (
    address _contract
  ) public onlyOwner {
    bytesContract = _contract;
  }

  /**
  */
  function setCitizenContract (
    address _contract
  ) public onlyOwner {
    citizenContract = _contract;
  }

  /**
    Allow the manager of the BYTES contract to update the emission rate. The
    emission rate may only be updated every `emissionUpdatePeriod`.

    @param _yieldPerDay The maximum daily emission rate for the next
      `emissionUpdatePeriod` duration.
  */
  function updateEmission (
    uint _yieldPerDay
  ) public onlyOwner {

    /*
      If no BYTES emissions have been specified yet, then initialize emissions
      with a starting rate.
    */
    if (emissions.length == 0) {
      Emission memory emission = Emission({
        dailyYield : _yieldPerDay,
        startTime : block.timestamp,
        endTime : block.timestamp + emissionUpdatePeriod
      });
      emissions.push(emission);

      /*
        Update the daily emissions of the staking contract to follow suit with
        the specified maximum BYTES emission rate.
      */
      IStaker(stakingContract).updateDailyEmission(_yieldPerDay);

      // Emit an event indicating that the initial emission rate has been set.
      emit EmissionUpdated(
        0,
        emissions[emissions.length - 1].dailyYield
      );

    // Otherwise, honor the time lock and update the emission rate.
    } else {
      if (
        block.timestamp - emissions[emissions.length - 1].startTime
        < emissionUpdatePeriod
      ) {
        revert CannotUpdateEmissionRateEarly();
      }

      // Update the ending time of the last emissions period.
      emissions[emissions.length - 1].endTime = block.timestamp - 1;

      // Prepare a new emissions period with the new rate.
      Emission memory emission;
      emission.dailyYield = _yieldPerDay;
      emission.startTime = block.timestamp;
      emissions.push(emission);

      /*
        Update the daily emissions of the staking contract to follow suit with
        the specified maximum BYTES emission rate.
      */
      IStaker(stakingContract).updateDailyEmission(_yieldPerDay);

      // Emit an event indicating that the emission rate has been updated.
      emit EmissionUpdated(
        emissions[emissions.length - 2].dailyYield,
        emissions[emissions.length - 1].dailyYield
      );
    }
  }


    /**
        called by multiple contracts to burn a users bytes before approving
        some third party functionality.

        @param _from owner of burning tokens
        @param _amount amount of tokens to be burn
    */
    function burn(address _from, uint256 _amount) external {
        if(!adminContracts[msg.sender]) {
            revert DoNotHaveRightToBurn();
        }
        // when someone burn $BYTES 2|3 should go to treasure;
        uint amountToTresure = _amount * 2 / 3;
        _burn(_from, _amount);
        _mint(treasureContract, amountToTresure);
    }

    /**
        called by Citizen contract to emit bytes
     */
    function getReward(address _to) external {
        // CHECK maybe it is useless
        // if(!IStaker(stakingContract).isStaker(_to)) {
        //     revert UserDontStake();
        // }
        uint256 reward;
        uint256 daoCommision; 

        (reward, daoCommision)= IStaker(stakingContract).getReward(_to);

         _mint(_to, reward);
        // send percents to DAO
        _mint(treasureContract, daoCommision);


        emit RewardPaid(_to, reward);
    }

    /**
        Allow holders of v1 bytes to change them for v2 bytes.

        @param _amount amount of v1 bytes to change
     */
    function upgradeBytes(uint256 _amount) external {
        if (IERC20(bytesContract).balanceOf(msg.sender) < _amount) {
            revert DoNotHaveEnoughOldBytes();
        }

        IByteContract(bytesContract).burn(msg.sender, _amount);
        _mint(msg.sender, _amount);
        emit BytesUpdated(msg.sender, _amount);
    }



    /**
        called by Citizen contract before an nft transfer or right before a
        getReward

        @param _from previous token holder
        @param _to token owner
        @param _tokenId id of the Citizen
     */
    function updateReward(address _from, address _to, uint256 _tokenId) external {
        /**
            TO_ASK copied that from previous contract, if it is not needed
            remove
         */
        if(msg.sender != address(citizenContract)) {
            revert CallerIsNotCitizen();
        }
        if (_tokenId < maxRewardableCitizens) {
            uint256 time;
            uint256 timerFrom = lastUpdate[_from];

            uint256 END = ICitizen(citizenContract).getEnd();

            time = ICitizen(citizenContract).getCurrentOrFinalTime();

            uint256 rateDelta = ICitizen(citizenContract).getRewardsRateForTokenId(_tokenId);

            if (timerFrom > 0)
            {
                rewards[_from] += ICitizen(citizenContract).getRewardRate(_from) * (time - timerFrom) / 86400;
            }
            if (timerFrom != END)
            {
                lastUpdate[_from] = time;
            }
            if (_to != address(0)) {
                uint256 timerTo = lastUpdate[_to];
                if (timerTo > 0)
                {
                    rewards[_to] += ICitizen(citizenContract).getRewardRate(_to) * (time - timerTo) / 86400;
                }
                if (timerTo != END)
                {
                    lastUpdate[_to] = time;
                }
            }

            ICitizen(citizenContract).reduceRewards(rateDelta, _from);
            ICitizen(citizenContract).increaseRewards(rateDelta, _to);
        }
    }

    /**
         called by Citizen contract when a new citizen is minted
     */
    function updateRewardOnMint(address _to, uint256 _tokenId) external {
        /**
            TO_ASK copied that from previous contract, if it is not needed
            remove
         */
        if(msg.sender != citizenContract) {
            revert CallerIsNotCitizen();
        }
        uint256 time;
        uint256 timerUser = lastUpdate[_to];

        time = ICitizen(citizenContract).getCurrentOrFinalTime();


        if (timerUser > 0)
        {
            rewards[_to] = rewards[_to] + (ICitizen(citizenContract).getRewardRate(_to) * (time - timerUser) / 86400);
        }

        uint256 rateDelta = ICitizen(citizenContract).getRewardsRateForTokenId(_tokenId);

        ICitizen(citizenContract).increaseRewards(rateDelta, _to);

        lastUpdate[_to] = time;
    }

  /**
      optional function that lets someone see how many bytes a specific
      address has available to claim
   */
  function getTotalClaimable(address _owner) public view returns (uint) {
    uint[] memory citizens = findCitizens(_owner);
    // should get list of citizens and then go through everyone and calculate
    // reward
    uint reward;
    for(uint i = 0; i < citizens.length; i++) {
        reward += calculateCitizenReward( 1, citizens[0]);
    }
    return reward;
  }

  /**
    must call staking contract to find which citizens have been staked by
    user and for how long. This function will hopefully return an array of
    values, but due to call stack size limitations it will probably have to
    be called iteratively.

    CHECK is used to find information about s1 citizens?

    @param _owner owner of tokens
  */
  function findCitizens(address _owner) internal view returns (uint[] memory) {
  }

  /**
    This will also probably be called iteratively and added to a
    summation variable that gives the final reward.

    @param _seasonId id of the season
    @param _tokenId id of the token
  */
  function calculateCitizenReward(uint256 _seasonId, uint256 _tokenId) internal view returns (uint) {
  }


}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.8;

interface ICitizen {
	function getRewardRate(address _user) external view returns(uint256);

    function getRewardsRateForTokenId(uint256) external view returns(uint256);

    function getCurrentOrFinalTime() external view returns(uint256);

    function reduceRewards(uint256, address) external;

    function increaseRewards(uint256, address) external;

    function getEnd() external returns(uint256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.8;

interface IByteContract {
    function burn(address _from, uint256 _amount) external;
    function getReward(address _to) external;
    function updateRewardOnMint(address _user, uint256 tokenId) external;
    function updateReward(address _from, address _to, uint256 _tokenId) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.8;

interface IStaker {
  function isStaked(uint256 _seasonId, uint256 _tokenId) external returns(bool);
  function isStaker(address _staker) external returns(bool);
  function getReward(address _to) external returns(uint256, uint256);
  function updateDailyEmission(uint256 _dailyEmission) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
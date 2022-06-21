// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "../strategy/BalancerVault.sol";
import "../interfaces/IGaugeController.sol";
import "../interfaces/ILiquidityGaugeStrat.sol";

interface IBalancerLiquidityGauge {
	function lp_token() external view returns (address);
}

/**
 * @title Factory contract usefull for creating new balancer vaults that supports BPT related
 * to the balancer platform, and the gauge multi rewards attached to it.
 */

contract BalancerVaultFactory {
	using ClonesUpgradeable for address;

	address public immutable vaultImpl = address(new BalancerVault());
	address public constant GAUGE_IMPL = 0x3Dc56D46F0Bd13655EfB29594a2e44534c453BF9;
	address public constant GOVERNANCE = 0xF930EBBd05eF8b25B1797b9b2109DDC9B0d43063;
	address public constant GAUGE_CONTROLLER = 0xC128468b7Ce63eA702C1f104D55A2566b13D3ABD;
	address public constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
	address public constant VESDT = 0x0C30476f66034E11782938DF8e4384970B6c9e8a;
	address public constant SDT = 0x73968b9a57c6E53d41345FD57a6E6ae27d6CDB2F;
	address public constant VEBOOST = 0xD67bdBefF01Fc492f1864E61756E5FBB3f173506;
	address public constant CLAIM_REWARDS = 0x633120100e108F03aCe79d6C78Aac9a56db1be0F; // v2
	address public constant BALANCER_STRATEGY = 0x873b031Ea6E4236E44d933Aae5a66AF6d4DA419d;
	address public constant SDT_DISTRIBUTOR = 0x9C99dffC1De1AfF7E7C1F36fCdD49063A281e18C;
	event VaultDeployed(address proxy, address lpToken, address impl);
	event GaugeDeployed(address proxy, address stakeToken, address impl);

	/**
	@dev Function to clone Balancer Vault and its gauge contracts 
	@param _balGaugeAddress balancer liquidity gauge address
	 */
	function cloneAndInit(address _balGaugeAddress) public {
		uint256 weight = IGaugeController(GAUGE_CONTROLLER).get_gauge_weight(_balGaugeAddress);
		require(weight > 0, "must have weight");
		address vaultLpToken = IBalancerLiquidityGauge(_balGaugeAddress).lp_token();
		string memory tokenSymbol = ERC20Upgradeable(vaultLpToken).symbol();
		address vaultImplAddress = _cloneAndInitVault(
			ERC20Upgradeable(vaultLpToken),
			string(abi.encodePacked("sd", tokenSymbol, " Vault")),
			string(abi.encodePacked("sd", tokenSymbol, "-vault"))
		);
		address gaugeImplAddress = _cloneAndInitGauge(
			vaultImplAddress,
			tokenSymbol
		);
		BalancerVault(vaultImplAddress).setLiquidityGauge(gaugeImplAddress);
		BalancerVault(vaultImplAddress).setGovernance(GOVERNANCE);
		BalancerStrategy(BALANCER_STRATEGY).toggleVault(vaultImplAddress);
		BalancerStrategy(BALANCER_STRATEGY).setGauge(vaultLpToken, _balGaugeAddress);
		BalancerStrategy(BALANCER_STRATEGY).setMultiGauge(_balGaugeAddress, gaugeImplAddress);
		BalancerStrategy(BALANCER_STRATEGY).manageFee(BalancerStrategy.MANAGEFEE.PERFFEE, _balGaugeAddress, 200); //%2 default
		BalancerStrategy(BALANCER_STRATEGY).manageFee(BalancerStrategy.MANAGEFEE.VESDTFEE, _balGaugeAddress, 500); //%5 default
		BalancerStrategy(BALANCER_STRATEGY).manageFee(BalancerStrategy.MANAGEFEE.ACCUMULATORFEE, _balGaugeAddress, 800); //%8 default
		BalancerStrategy(BALANCER_STRATEGY).manageFee(BalancerStrategy.MANAGEFEE.CLAIMERREWARD, _balGaugeAddress, 50); //%0.5 default
		ILiquidityGaugeStrat(gaugeImplAddress).add_reward(BAL, BALANCER_STRATEGY);
		ILiquidityGaugeStrat(gaugeImplAddress).set_claimer(CLAIM_REWARDS);
		ILiquidityGaugeStrat(gaugeImplAddress).commit_transfer_ownership(GOVERNANCE);
	}

	/**
	@dev Internal function to clone the vault 
	@param _lpToken balancer BPT token address 
	@param _name vault name
	@param _symbol vault symbol
	 */
	function _cloneAndInitVault(
		ERC20Upgradeable _lpToken,
		string memory _name,
		string memory _symbol
	) internal returns (address) {
		BalancerVault deployed = cloneVault(
			_lpToken,
			keccak256(abi.encodePacked(GOVERNANCE, _name, _symbol, BALANCER_STRATEGY))
		);
		deployed.init(_lpToken, address(this), _name, _symbol, BalancerStrategy(BALANCER_STRATEGY));
		return address(deployed);
	}

	/**
	@dev Internal function to clone the gauge multi rewards
	@param _stakingToken sd LP token address 
	@param _symbol gauge symbol
	 */
	function _cloneAndInitGauge(
		address _stakingToken,
		string memory _symbol
	) internal returns (address) {
		ILiquidityGaugeStrat deployed = cloneGauge(_stakingToken, keccak256(abi.encodePacked(GOVERNANCE, _symbol)));
		deployed.initialize(
			_stakingToken,
			address(this),
			SDT,
			VESDT,
			VEBOOST,
			SDT_DISTRIBUTOR,
			_stakingToken,
			_symbol
		);
		return address(deployed);
	}

	/**
	@dev Internal function that deploy and returns a clone of vault impl
	@param _lpToken balancer BPT token address
	@param _paramsHash governance+name+symbol+strategy parameters hash
	 */
	function cloneVault(
		ERC20Upgradeable _lpToken,
		bytes32 _paramsHash
	) internal returns (BalancerVault) {
		address deployed = address(vaultImpl).cloneDeterministic(keccak256(abi.encodePacked(address(_lpToken), _paramsHash)));
		emit VaultDeployed(deployed, address(_lpToken), vaultImpl);
		return BalancerVault(deployed);
	}

	/**
	@dev Internal function that deploy and returns a clone of gauge impl
	@param _stakingToken sd LP token address
	@param _paramsHash governance+name+symbol parameters hash
	 */
	function cloneGauge(
		address _stakingToken,
		bytes32 _paramsHash
	) internal returns (ILiquidityGaugeStrat) {
		address deployed = address(GAUGE_IMPL).cloneDeterministic(
			keccak256(abi.encodePacked(address(_stakingToken), _paramsHash))
		);
		emit GaugeDeployed(deployed, _stakingToken, GAUGE_IMPL);
		return ILiquidityGaugeStrat(deployed);
	}

	/**
	@dev Function that predicts the future address passing the parameters
	@param _impl address of contract to clone
	@param _token token (LP or sdLP)
	@param _paramsHash parameters hash
	 */
	function predictAddress(
		address _impl,
		IERC20 _token,
		bytes32 _paramsHash
	) public view returns (address) {
		return address(_impl).predictDeterministicAddress(keccak256(abi.encodePacked(address(_token), _paramsHash)));
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/ILiquidityGaugeStrat.sol";
import "./BalancerStrategy.sol";
import "../interfaces/BalancerVault/IBalancerVault.sol";
import "../interfaces/IBalancerPool.sol";

contract BalancerVault is ERC20Upgradeable {
	using SafeERC20Upgradeable for ERC20Upgradeable;
	using AddressUpgradeable for address;

	ERC20Upgradeable public token;
	address public governance;
	uint256 public withdrawalFee;
	uint256 public keeperFee;
	address public liquidityGauge;
	uint256 public accumulatedFee;
	bytes32 public poolId;
	address public constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
	uint256 public min;
	uint256 public constant max = 10000;
	BalancerStrategy public balancerStrategy;
	event Earn(address _token, uint256 _amount);
	event Deposit(address _depositor, uint256 _amount);
	event Withdraw(address _depositor, uint256 _amount);

	function init(
		ERC20Upgradeable _token,
		address _governance,
		string memory name_,
		string memory symbol_,
		BalancerStrategy _balancerStrategy
	) public initializer {
		__ERC20_init(name_, symbol_);
		token = _token;
		governance = _governance;
		min = 10000;
		keeperFee = 10; // %0.1
		poolId = IBalancerPool(address(_token)).getPoolId();
		balancerStrategy = _balancerStrategy;
	}

	/// @notice function to deposit the BPT token
	/// @param _staker address to stake for
	/// @param _amount amount to deposit
	/// @param _earn earn or not 
	function deposit(
		address _staker,
		uint256 _amount,
		bool _earn
	) public {
		require(address(liquidityGauge) != address(0), "Gauge not yet initialized");
		token.safeTransferFrom(msg.sender, address(this), _amount);
		_deposit(_staker, _amount, _earn);
	}

	/// @notice function to provide liquidity in underlying tokens 
	/// @param _staker address to stake for
	/// @param _maxAmountsIn amounts for each underlying token
	/// @param _earn earn or not 
	/// @param _minAmount amount to deposit
	function provideLiquidityAndDeposit(
		address _staker,
		uint256[] calldata _maxAmountsIn,
		bool _earn,
		uint256 _minAmount
	) public {
		require(address(liquidityGauge) != address(0), "Gauge not yet initialized");
		(IERC20[] memory tokens, , ) = IBalancerVault(BALANCER_VAULT).getPoolTokens(poolId);
		require(tokens.length == _maxAmountsIn.length, "!length");
		address[] memory assets = new address[](tokens.length);
		for (uint256 i; i < tokens.length; i++) {
			if (_maxAmountsIn[i] > 0) {
				tokens[i].transferFrom(msg.sender, address(this), _maxAmountsIn[i]);
				tokens[i].approve(BALANCER_VAULT, _maxAmountsIn[i]);
			}
			assets[i] = address(tokens[i]);
		}
		IBalancerVault.JoinPoolRequest memory pr = IBalancerVault.JoinPoolRequest(
			assets,
			_maxAmountsIn,
			abi.encode(1, _maxAmountsIn, _minAmount),
			false
		);
		uint256 lpBalanceBefore = token.balanceOf(address(this));
		IBalancerVault(BALANCER_VAULT).joinPool(
			poolId, // poolId
			address(this),
			address(this),
			pr
		);
		uint256 lpBalanceAfter = token.balanceOf(address(this));

		_deposit(_staker, lpBalanceAfter - lpBalanceBefore, _earn);
	}

	/// @notice internal deposit function
	/// @param _staker address to stake for
	/// @param _amount amount to deposit
	/// @param _earn earn or not 
	function _deposit(
		address _staker,
		uint256 _amount,
		bool _earn
	) internal {
		if (!_earn) {
			uint256 keeperCut = (_amount * keeperFee) / 10000;
			_amount -= keeperCut;
			accumulatedFee += keeperCut;
		} else {
			_amount += accumulatedFee;
			accumulatedFee = 0;
		}
		_mint(address(this), _amount);
		ILiquidityGaugeStrat(liquidityGauge).deposit(_amount, _staker);
		if (_earn) {
			earn();
		}
		emit Deposit(_staker, _amount);
	}

	/// @notice function to withdraw
	/// @param _shares amount to withdraw
	function withdraw(uint256 _shares) public {
		uint256 userTotalShares = ILiquidityGaugeStrat(liquidityGauge).balanceOf(msg.sender);
		require(_shares <= userTotalShares, "Not enough staked");
		ILiquidityGaugeStrat(liquidityGauge).withdraw(_shares, msg.sender, true);
		_burn(address(this), _shares);
		uint256 tokenBalance = token.balanceOf(address(this)) - accumulatedFee;
		uint256 withdrawFee;
		if (_shares > tokenBalance) {
			uint256 amountToWithdraw = _shares - tokenBalance;
			balancerStrategy.withdraw(address(token), amountToWithdraw);
			withdrawFee = (amountToWithdraw * withdrawalFee) / 10000;
			if (withdrawFee > 0) {
				token.safeTransfer(governance, withdrawFee);
			}
		}
		token.safeTransfer(msg.sender, _shares - withdrawFee);
		emit Withdraw(msg.sender, _shares - withdrawFee);
	}

	/// @notice function to set the governance
	/// @param _governance governance address
	function setGovernance(address _governance) external {
		require(msg.sender == governance, "!governance");
		governance = _governance;
	}

	/// @notice function to set the keeper fee
	/// @param _newFee keeper fee
	function setKeeperFee(uint256 _newFee) external {
		require(msg.sender == governance, "!governance");
		keeperFee = _newFee;
	}

	/// @notice function to set the gauge multi rewards
	/// @param _liquidityGauge gauge address
	function setLiquidityGauge(address _liquidityGauge) external {
		require(msg.sender == governance, "!governance");
		liquidityGauge = _liquidityGauge;
		ERC20Upgradeable(address(this)).approve(liquidityGauge, type(uint256).max);
	}
	
	/// @notice function to set the balancer strategy
	/// @param _newStrat balancer strategy infos
	function setBalancerStrategy(BalancerStrategy _newStrat) external {
		require(msg.sender == governance, "!governance");
		balancerStrategy = _newStrat;
	}

	/// @notice function to return the vault token decimals
	function decimals() public view override returns (uint8) {
		return token.decimals();
	}

	/// @notice function to set the withdrawn fee
	/// @param _newFee withdrawn fee
	function setWithdrawnFee(uint256 _newFee) external {
		require(msg.sender == governance, "!governance");
		withdrawalFee = _newFee;
	}

	/// @notice function to set the min
	/// @param _min min amount
	function setMin(uint256 _min) external {
		require(msg.sender == governance, "!governance");
		min = _min;
	}

	/// @notice view function to fetch the available amount to send to the strategy
	function available() public view returns (uint256) {
		return ((token.balanceOf(address(this)) - accumulatedFee) * min) / max;
	}

	/// @notice internal function to move funds to the strategy
	function earn() internal {
		uint256 tokenBalance = available();
		token.approve(address(balancerStrategy), 0);
		token.approve(address(balancerStrategy), tokenBalance);
		balancerStrategy.deposit(address(token), tokenBalance);
		emit Earn(address(token), tokenBalance);
	}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

interface IGaugeController {
	//solhint-disable-next-line
	function gauge_types(address addr) external view returns (int128);

	//solhint-disable-next-line
	function gauge_relative_weight_write(address addr, uint256 timestamp) external returns (uint256);

	//solhint-disable-next-line
	function gauge_relative_weight(address addr) external view returns (uint256);

	//solhint-disable-next-line
	function gauge_relative_weight(address addr, uint256 timestamp) external view returns (uint256);

	//solhint-disable-next-line
	function get_total_weight() external view returns (uint256);

	//solhint-disable-next-line
	function get_gauge_weight(address addr) external view returns (uint256);

	function vote_for_gauge_weights(address, uint256) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

interface ILiquidityGaugeStrat {
	struct Reward {
		address token;
		address distributor;
		uint256 period_finish;
		uint256 rate;
		uint256 last_update;
		uint256 integral;
	}

	// solhint-disable-next-line
	function deposit_reward_token(address _rewardToken, uint256 _amount) external;

	// solhint-disable-next-line
	function claim_rewards_for(address _user, address _recipient) external;

	// // solhint-disable-next-line
	// function claim_rewards_for(address _user) external;

	// solhint-disable-next-line
	function deposit(uint256 _value, address _addr) external;

	// solhint-disable-next-line
	function reward_tokens(uint256 _i) external view returns (address);

	function withdraw(
		uint256 _value,
		address _addr,
		bool _claim_rewards
	) external;

	// solhint-disable-next-line
	function reward_data(address _tokenReward) external view returns (Reward memory);

	function balanceOf(address) external returns (uint256);

	function claimable_reward(address _user, address _reward_token) external view returns (uint256);

	function user_checkpoint(address _user) external returns (bool);

	function commit_transfer_ownership(address) external;

	function initialize(
		address _staking_token,
		address _admin,
		address _SDT,
		address _voting_escrow,
		address _veBoost_proxy,
		address _distributor,
		address _vault,
		string memory _symbol
	) external;

	function add_reward(address, address) external;

	function set_claimer(address) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
pragma solidity 0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./BaseStrategy.sol";
import "../accumulator/BalancerAccumulator.sol";
import "../interfaces/ILiquidityGauge.sol";
import "../interfaces/IMultiRewards.sol";
import "../staking/SdtDistributorV2.sol";

contract BalancerStrategy is BaseStrategy {
	using SafeERC20 for IERC20;

	BalancerAccumulator public accumulator;
	address public sdtDistributor;
	address public constant BAL_MINTER = 0x239e55F427D44C3cc793f49bFB507ebe76638a2b;
	address public constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;

	struct ClaimerReward {
		address rewardToken;
		uint256 amount;
	}
	enum MANAGEFEE {
		PERFFEE,
		VESDTFEE,
		ACCUMULATORFEE,
		CLAIMERREWARD
	}

	/* ========== CONSTRUCTOR ========== */
	constructor(
		ILocker _locker,
		address _governance,
		address _receiver,
		BalancerAccumulator _accumulator,
		address _veSDTFeeProxy,
		address _sdtDistributor
	) BaseStrategy(_locker, _governance, _receiver) {
		accumulator = _accumulator;
		veSDTFeeProxy = _veSDTFeeProxy;
		sdtDistributor = _sdtDistributor;
	}

	/* ========== MUTATIVE FUNCTIONS ========== */
	/// @notice function to deposit into a gauge
	/// @param _token token address
	/// @param _amount amount to deposit
	function deposit(address _token, uint256 _amount) external override onlyApprovedVault {
		IERC20(_token).transferFrom(msg.sender, address(locker), _amount);
		address gauge = gauges[_token];
		require(gauge != address(0), "!gauge");
		locker.execute(_token, 0, abi.encodeWithSignature("approve(address,uint256)", gauge, 0));
		locker.execute(_token, 0, abi.encodeWithSignature("approve(address,uint256)", gauge, _amount));

		(bool success, ) = locker.execute(gauge, 0, abi.encodeWithSignature("deposit(uint256)", _amount));
		require(success, "Deposit failed!");
		emit Deposited(gauge, _token, _amount);
	}

	/// @notice function to withdraw from a gauge
	/// @param _token token address
	/// @param _amount amount to withdraw
	function withdraw(address _token, uint256 _amount) external override onlyApprovedVault {
		uint256 _before = IERC20(_token).balanceOf(address(locker));
		address gauge = gauges[_token];
		require(gauge != address(0), "!gauge");
		(bool success, ) = locker.execute(gauge, 0, abi.encodeWithSignature("withdraw(uint256)", _amount));
		require(success, "Transfer failed!");
		uint256 _after = IERC20(_token).balanceOf(address(locker));

		uint256 _net = _after - _before;
		(success, ) = locker.execute(_token, 0, abi.encodeWithSignature("transfer(address,uint256)", msg.sender, _net));
		require(success, "Transfer failed!");
		emit Withdrawn(gauge, _token, _amount);
	}

	/// @notice function to send funds into the related accumulator
	/// @param _token token address
	/// @param _amount amount to send
	function sendToAccumulator(address _token, uint256 _amount) external onlyGovernance {
		IERC20(_token).approve(address(accumulator), _amount);
		accumulator.depositToken(_token, _amount);
	}

	/// @notice function to claim the reward and distribute it
	/// @param _token BPT token address
	function claim(address _token) external override {
		address gauge = gauges[_token];
		require(gauge != address(0), "!gauge");

		uint256 balBeforeClaim = IERC20(BAL).balanceOf(address(locker));

		// Claim BAL
		// within the mint() it calls the user checkpoint
		(bool success, ) = locker.execute(
			BAL_MINTER,
			0,
			abi.encodeWithSignature("mint(address)", gauge)
		);	
		require(success, "BAL mint failed!");

		uint256 balMinted = IERC20(BAL).balanceOf(address(locker)) - balBeforeClaim;
		
		// Send BAL here
		(success, ) = locker.execute(
			BAL,
			0,
			abi.encodeWithSignature("transfer(address,uint256)", address(this), balMinted)
		);
		require(success, "BAL transfer failed!");

		// Distribute BAL
		uint256 balNetRewards = sendFee(gauge, balMinted);
		IERC20(BAL).approve(multiGauges[gauge], balNetRewards);
		ILiquidityGauge(multiGauges[gauge]).deposit_reward_token(BAL, balNetRewards);
		emit Claimed(gauge, BAL, balMinted);

		// Distribute SDT to the related gauge
		SdtDistributorV2(sdtDistributor).distribute(multiGauges[gauge]);

		// Claim rewards only if there is at least one extra reward
		if(ILiquidityGauge(gauge).reward_tokens(0) != address(0)) {
			(success, ) = locker.execute(
				gauge, 0, abi.encodeWithSignature("claim_rewards(address,address)", address(locker), address(this))
			);
			address rewardToken;
			uint256 rewardsBalance;
			for (uint8 i = 0; i < 8; i++) {
				rewardToken = ILiquidityGauge(gauge).reward_tokens(i);
				if (rewardToken == address(0)) {
					break;
				}
                rewardsBalance = IERC20(rewardToken).balanceOf(address(this));
				IERC20(rewardToken).approve(multiGauges[gauge], rewardsBalance);
				ILiquidityGauge(multiGauges[gauge]).deposit_reward_token(rewardToken, rewardsBalance);
				emit Claimed(gauge, rewardToken, rewardsBalance);
			}	
		}
	}

	/// @notice internal function for distributing fees to recipients 
	/// @param _gauge gauge address
	/// @param _rewardsBalance total balance to distribute
	function sendFee(address _gauge, uint256 _rewardsBalance) internal returns(uint256) {
		// calculate the amount for each fee recipient
		uint256 multisigFee = (_rewardsBalance * perfFee[_gauge]) / BASE_FEE;
		uint256 accumulatorPart = (_rewardsBalance * accumulatorFee[_gauge]) / BASE_FEE;
		uint256 veSDTPart = (_rewardsBalance * veSDTFee[_gauge]) / BASE_FEE;
		uint256 claimerPart = (_rewardsBalance * claimerRewardFee[_gauge]) / BASE_FEE;
		// send 
		IERC20(BAL).approve(address(accumulator), accumulatorPart);
		accumulator.depositToken(BAL, accumulatorPart);
		IERC20(BAL).transfer(rewardsReceiver, multisigFee);
		IERC20(BAL).transfer(veSDTFeeProxy, veSDTPart);
		IERC20(BAL).transfer(msg.sender, claimerPart);
		return _rewardsBalance - multisigFee - accumulatorPart - veSDTPart - claimerPart;
	}

	/// @notice function to toggle a vault
	/// @param _vault vault address
	function toggleVault(address _vault) external override onlyGovernanceOrFactory {
		require(_vault != address(0), "zero address");
		vaults[_vault] = !vaults[_vault];
		emit VaultToggled(_vault, vaults[_vault]);
	}

	/// @notice function to set a new gauge
	/// It permits to set it as address(0), for disabling it
	/// @param _token token address
	/// @param _gauge gauge address
	function setGauge(address _token, address _gauge) external override onlyGovernanceOrFactory {
		require(_token != address(0), "zero address");
		// Set new gauge
		gauges[_token] = _gauge;
		emit GaugeSet(_gauge, _token);
	}

	/// @notice function to set a multi gauge
	/// @param _gauge gauge address
	/// @param _multiGauge multi gauge address
	function setMultiGauge(address _gauge, address _multiGauge) external override onlyGovernanceOrFactory {
		require(_gauge != address(0), "zero address");
		require(_multiGauge != address(0), "zero address");
		multiGauges[_gauge] = _multiGauge;
	}

	/// @notice function to set a new veSDTProxy
	/// @param _newVeSDTProxy veSdtProxy address
	function setVeSDTProxy(address _newVeSDTProxy) external onlyGovernance {
		require(_newVeSDTProxy != address(0), "zero address");
		veSDTFeeProxy = _newVeSDTProxy;
	}

	/// @notice function to set a new accumulator
	/// @param _newAccumulator accumulator address
	function setAccumulator(address _newAccumulator) external onlyGovernance {
		require(_newAccumulator != address(0), "zero address");
		accumulator = BalancerAccumulator(_newAccumulator);
	}

	/// @notice function to set a new reward receiver
	/// @param _newRewardsReceiver reward receiver address
	function setRewardsReceiver(address _newRewardsReceiver) external onlyGovernance {
		require(_newRewardsReceiver != address(0), "zero address");
		rewardsReceiver = _newRewardsReceiver;
	}

	/// @notice function to set a new governance address
	/// @param _newGovernance governance address
	function setGovernance(address _newGovernance) external onlyGovernance {
		require(_newGovernance != address(0), "zero address");
		governance = _newGovernance;
	}

	/// @notice function to set the vault/gauge factory
	/// @param _newVaultGaugeFactory factory address
	function setVaultGaugeFactory(address _newVaultGaugeFactory) external onlyGovernance {
		require(_newVaultGaugeFactory != address(0), "zero address");
		vaultGaugeFactory = _newVaultGaugeFactory;
	}

	/// @notice function to set new fees
	/// @param _manageFee manageFee
	/// @param _gauge gauge address
	/// @param _newFee new fee to set
	function manageFee(
		MANAGEFEE _manageFee,
		address _gauge,
		uint256 _newFee
	) external onlyGovernanceOrFactory {
		require(_gauge != address(0), "zero address");
		if (_manageFee == MANAGEFEE.PERFFEE) {
			// 0
			perfFee[_gauge] = _newFee;
		} else if (_manageFee == MANAGEFEE.VESDTFEE) {
			// 1
			veSDTFee[_gauge] = _newFee;
		} else if (_manageFee == MANAGEFEE.ACCUMULATORFEE) {
			//2
			accumulatorFee[_gauge] = _newFee;
		} else if (_manageFee == MANAGEFEE.CLAIMERREWARD) {
			// 3
			claimerRewardFee[_gauge] = _newFee;
		}
		require(
			perfFee[_gauge] + 
			veSDTFee[_gauge] + 
			accumulatorFee[_gauge] + 
			claimerRewardFee[_gauge] 
			<= BASE_FEE, "fee to high"
		);
	}

	/// @notice execute a function
	/// @param _to Address to sent the value to
	/// @param _value Value to be sent
	/// @param _data Call function data
	function execute(
		address _to,
		uint256 _value,
		bytes calldata _data
	) external onlyGovernance returns (bool, bytes memory) {
		(bool success, bytes memory result) = _to.call{ value: _value }(_data);
		return (success, result);
	}
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IAsset.sol";
import "./IAuthorizer.sol";
import "./IFlashLoanRecipient.sol";

/**
 * @dev Full external interface for the Vault core contract - no external or public methods exist in the contract that
 * don't override one of these declarations.
 */
interface IBalancerVault {
	// Generalities about the Vault:
	//
	// - Whenever documentation refers to 'tokens', it strictly refers to ERC20-compliant token contracts. Tokens are
	// transferred out of the Vault by calling the `IERC20.transfer` function, and transferred in by calling
	// `IERC20.transferFrom`. In these cases, the sender must have previously allowed the Vault to use their tokens by
	// calling `IERC20.approve`. The only deviation from the ERC20 standard that is supported is functions not returning
	// a boolean value: in these scenarios, a non-reverting call is assumed to be successful.
	//
	// - All non-view functions in the Vault are non-reentrant: calling them while another one is mid-execution (e.g.
	// while execution control is transferred to a token contract during a swap) will result in a revert. View
	// functions can be called in a re-reentrant way, but doing so might cause them to return inconsistent results.
	// Contracts calling view functions in the Vault must make sure the Vault has not already been entered.
	//
	// - View functions revert if referring to either unregistered Pools, or unregistered tokens for registered Pools.

	// Authorizer
	//
	// Some system actions are permissioned, like setting and collecting protocol fees. This permissioning system exists
	// outside of the Vault in the Authorizer contract: the Vault simply calls the Authorizer to check if the caller
	// can perform a given action.

	/**
	 * @dev Returns the Vault's Authorizer.
	 */
	function getAuthorizer() external view returns (IAuthorizer);

	/**
	 * @dev Sets a new Authorizer for the Vault. The caller must be allowed by the current Authorizer to do this.
	 *
	 * Emits an `AuthorizerChanged` event.
	 */
	function setAuthorizer(IAuthorizer newAuthorizer) external;

	/**
	 * @dev Emitted when a new authorizer is set by `setAuthorizer`.
	 */
	event AuthorizerChanged(IAuthorizer indexed newAuthorizer);

	// Relayers
	//
	// Additionally, it is possible for an account to perform certain actions on behalf of another one, using their
	// Vault ERC20 allowance and Internal Balance. These accounts are said to be 'relayers' for these Vault functions,
	// and are expected to be smart contracts with sound authentication mechanisms. For an account to be able to wield
	// this power, two things must occur:
	//  - The Authorizer must grant the account the permission to be a relayer for the relevant Vault function. This
	//    means that Balancer governance must approve each individual contract to act as a relayer for the intended
	//    functions.
	//  - Each user must approve the relayer to act on their behalf.
	// This double protection means users cannot be tricked into approving malicious relayers (because they will not
	// have been allowed by the Authorizer via governance), nor can malicious relayers approved by a compromised
	// Authorizer or governance drain user funds, since they would also need to be approved by each individual user.

	/**
	 * @dev Returns true if `user` has approved `relayer` to act as a relayer for them.
	 */
	function hasApprovedRelayer(address user, address relayer) external view returns (bool);

	/**
	 * @dev Allows `relayer` to act as a relayer for `sender` if `approved` is true, and disallows it otherwise.
	 *
	 * Emits a `RelayerApprovalChanged` event.
	 */
	function setRelayerApproval(
		address sender,
		address relayer,
		bool approved
	) external;

	/**
	 * @dev Emitted every time a relayer is approved or disapproved by `setRelayerApproval`.
	 */
	event RelayerApprovalChanged(address indexed relayer, address indexed sender, bool approved);

	// Internal Balance
	//
	// Users can deposit tokens into the Vault, where they are allocated to their Internal Balance, and later
	// transferred or withdrawn. It can also be used as a source of tokens when joining Pools, as a destination
	// when exiting them, and as either when performing swaps. This usage of Internal Balance results in greatly reduced
	// gas costs when compared to relying on plain ERC20 transfers, leading to large savings for frequent users.
	//
	// Internal Balance management features batching, which means a single contract call can be used to perform multiple
	// operations of different kinds, with different senders and recipients, at once.

	/**
	 * @dev Returns `user`'s Internal Balance for a set of tokens.
	 */
	function getInternalBalance(address user, IERC20[] memory tokens) external view returns (uint256[] memory);

	/**
	 * @dev Performs a set of user balance operations, which involve Internal Balance (deposit, withdraw or transfer)
	 * and plain ERC20 transfers using the Vault's allowance. This last feature is particularly useful for relayers, as
	 * it lets integrators reuse a user's Vault allowance.
	 *
	 * For each operation, if the caller is not `sender`, it must be an authorized relayer for them.
	 */
	function manageUserBalance(UserBalanceOp[] memory ops) external payable;

	/**
     * @dev Data for `manageUserBalance` operations, which include the possibility for ETH to be sent and received
     without manual WETH wrapping or unwrapping.
     */
	struct UserBalanceOp {
		UserBalanceOpKind kind;
		IAsset asset;
		uint256 amount;
		address sender;
		address payable recipient;
	}

	// There are four possible operations in `manageUserBalance`:
	//
	// - DEPOSIT_INTERNAL
	// Increases the Internal Balance of the `recipient` account by transferring tokens from the corresponding
	// `sender`. The sender must have allowed the Vault to use their tokens via `IERC20.approve()`.
	//
	// ETH can be used by passing the ETH sentinel value as the asset and forwarding ETH in the call: it will be wrapped
	// and deposited as WETH. Any ETH amount remaining will be sent back to the caller (not the sender, which is
	// relevant for relayers).
	//
	// Emits an `InternalBalanceChanged` event.
	//
	//
	// - WITHDRAW_INTERNAL
	// Decreases the Internal Balance of the `sender` account by transferring tokens to the `recipient`.
	//
	// ETH can be used by passing the ETH sentinel value as the asset. This will deduct WETH instead, unwrap it and send
	// it to the recipient as ETH.
	//
	// Emits an `InternalBalanceChanged` event.
	//
	//
	// - TRANSFER_INTERNAL
	// Transfers tokens from the Internal Balance of the `sender` account to the Internal Balance of `recipient`.
	//
	// Reverts if the ETH sentinel value is passed.
	//
	// Emits an `InternalBalanceChanged` event.
	//
	//
	// - TRANSFER_EXTERNAL
	// Transfers tokens from `sender` to `recipient`, using the Vault's ERC20 allowance. This is typically used by
	// relayers, as it lets them reuse a user's Vault allowance.
	//
	// Reverts if the ETH sentinel value is passed.
	//
	// Emits an `ExternalBalanceTransfer` event.

	enum UserBalanceOpKind {
		DEPOSIT_INTERNAL,
		WITHDRAW_INTERNAL,
		TRANSFER_INTERNAL,
		TRANSFER_EXTERNAL
	}

	/**
	 * @dev Emitted when a user's Internal Balance changes, either from calls to `manageUserBalance`, or through
	 * interacting with Pools using Internal Balance.
	 *
	 * Because Internal Balance works exclusively with ERC20 tokens, ETH deposits and withdrawals will use the WETH
	 * address.
	 */
	event InternalBalanceChanged(address indexed user, IERC20 indexed token, int256 delta);

	/**
	 * @dev Emitted when a user's Vault ERC20 allowance is used by the Vault to transfer tokens to an external account.
	 */
	event ExternalBalanceTransfer(IERC20 indexed token, address indexed sender, address recipient, uint256 amount);

	// Pools
	//
	// There are three specialization settings for Pools, which allow for cheaper swaps at the cost of reduced
	// functionality:
	//
	//  - General: no specialization, suited for all Pools. IGeneralPool is used for swap request callbacks, passing the
	// balance of all tokens in the Pool. These Pools have the largest swap costs (because of the extra storage reads),
	// which increase with the number of registered tokens.
	//
	//  - Minimal Swap Info: IMinimalSwapInfoPool is used instead of IGeneralPool, which saves gas by only passing the
	// balance of the two tokens involved in the swap. This is suitable for some pricing algorithms, like the weighted
	// constant product one popularized by Balancer V1. Swap costs are smaller compared to general Pools, and are
	// independent of the number of registered tokens.
	//
	//  - Two Token: only allows two tokens to be registered. This achieves the lowest possible swap gas cost. Like
	// minimal swap info Pools, these are called via IMinimalSwapInfoPool.

	enum PoolSpecialization {
		GENERAL,
		MINIMAL_SWAP_INFO,
		TWO_TOKEN
	}

	/**
	 * @dev Registers the caller account as a Pool with a given specialization setting. Returns the Pool's ID, which
	 * is used in all Pool-related functions. Pools cannot be deregistered, nor can the Pool's specialization be
	 * changed.
	 *
	 * The caller is expected to be a smart contract that implements either `IGeneralPool` or `IMinimalSwapInfoPool`,
	 * depending on the chosen specialization setting. This contract is known as the Pool's contract.
	 *
	 * Note that the same contract may register itself as multiple Pools with unique Pool IDs, or in other words,
	 * multiple Pools may share the same contract.
	 *
	 * Emits a `PoolRegistered` event.
	 */
	function registerPool(PoolSpecialization specialization) external returns (bytes32);

	/**
	 * @dev Emitted when a Pool is registered by calling `registerPool`.
	 */
	event PoolRegistered(bytes32 indexed poolId, address indexed poolAddress, PoolSpecialization specialization);

	/**
	 * @dev Returns a Pool's contract address and specialization setting.
	 */
	function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

	/**
	 * @dev Registers `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
	 *
	 * Pools can only interact with tokens they have registered. Users join a Pool by transferring registered tokens,
	 * exit by receiving registered tokens, and can only swap registered tokens.
	 *
	 * Each token can only be registered once. For Pools with the Two Token specialization, `tokens` must have a length
	 * of two, that is, both tokens must be registered in the same `registerTokens` call, and they must be sorted in
	 * ascending order.
	 *
	 * The `tokens` and `assetManagers` arrays must have the same length, and each entry in these indicates the Asset
	 * Manager for the corresponding token. Asset Managers can manage a Pool's tokens via `managePoolBalance`,
	 * depositing and withdrawing them directly, and can even set their balance to arbitrary amounts. They are therefore
	 * expected to be highly secured smart contracts with sound design principles, and the decision to register an
	 * Asset Manager should not be made lightly.
	 *
	 * Pools can choose not to assign an Asset Manager to a given token by passing in the zero address. Once an Asset
	 * Manager is set, it cannot be changed except by deregistering the associated token and registering again with a
	 * different Asset Manager.
	 *
	 * Emits a `TokensRegistered` event.
	 */
	function registerTokens(
		bytes32 poolId,
		IERC20[] memory tokens,
		address[] memory assetManagers
	) external;

	/**
	 * @dev Emitted when a Pool registers tokens by calling `registerTokens`.
	 */
	event TokensRegistered(bytes32 indexed poolId, IERC20[] tokens, address[] assetManagers);

	/**
	 * @dev Deregisters `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
	 *
	 * Only registered tokens (via `registerTokens`) can be deregistered. Additionally, they must have zero total
	 * balance. For Pools with the Two Token specialization, `tokens` must have a length of two, that is, both tokens
	 * must be deregistered in the same `deregisterTokens` call.
	 *
	 * A deregistered token can be re-registered later on, possibly with a different Asset Manager.
	 *
	 * Emits a `TokensDeregistered` event.
	 */
	function deregisterTokens(bytes32 poolId, IERC20[] memory tokens) external;

	/**
	 * @dev Emitted when a Pool deregisters tokens by calling `deregisterTokens`.
	 */
	event TokensDeregistered(bytes32 indexed poolId, IERC20[] tokens);

	/**
	 * @dev Returns detailed information for a Pool's registered token.
	 *
	 * `cash` is the number of tokens the Vault currently holds for the Pool. `managed` is the number of tokens
	 * withdrawn and held outside the Vault by the Pool's token Asset Manager. The Pool's total balance for `token`
	 * equals the sum of `cash` and `managed`.
	 *
	 * Internally, `cash` and `managed` are stored using 112 bits. No action can ever cause a Pool's token `cash`,
	 * `managed` or `total` balance to be greater than 2^112 - 1.
	 *
	 * `lastChangeBlock` is the number of the block in which `token`'s total balance was last modified (via either a
	 * join, exit, swap, or Asset Manager update). This value is useful to avoid so-called 'sandwich attacks', for
	 * example when developing price oracles. A change of zero (e.g. caused by a swap with amount zero) is considered a
	 * change for this purpose, and will update `lastChangeBlock`.
	 *
	 * `assetManager` is the Pool's token Asset Manager.
	 */
	function getPoolTokenInfo(bytes32 poolId, IERC20 token)
		external
		view
		returns (
			uint256 cash,
			uint256 managed,
			uint256 lastChangeBlock,
			address assetManager
		);

	/**
	 * @dev Returns a Pool's registered tokens, the total balance for each, and the latest block when *any* of
	 * the tokens' `balances` changed.
	 *
	 * The order of the `tokens` array is the same order that will be used in `joinPool`, `exitPool`, as well as in all
	 * Pool hooks (where applicable). Calls to `registerTokens` and `deregisterTokens` may change this order.
	 *
	 * If a Pool only registers tokens once, and these are sorted in ascending order, they will be stored in the same
	 * order as passed to `registerTokens`.
	 *
	 * Total balances include both tokens held by the Vault and those withdrawn by the Pool's Asset Managers. These are
	 * the amounts used by joins, exits and swaps. For a detailed breakdown of token balances, use `getPoolTokenInfo`
	 * instead.
	 */
	function getPoolTokens(bytes32 poolId)
		external
		view
		returns (
			IERC20[] memory tokens,
			uint256[] memory balances,
			uint256 lastChangeBlock
		);

	/**
	 * @dev Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
	 * trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
	 * Pool shares.
	 *
	 * If the caller is not `sender`, it must be an authorized relayer for them.
	 *
	 * The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
	 * to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
	 * these maximums.
	 *
	 * If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
	 * this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
	 * WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
	 * back to the caller (not the sender, which is important for relayers).
	 *
	 * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
	 * interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
	 * sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
	 * `assets` array might not be sorted. Pools with no registered tokens cannot be joined.
	 *
	 * If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
	 * be made for the difference between the requested amount and Internal Balance (if any). Note that ETH cannot be
	 * withdrawn from Internal Balance: attempting to do so will trigger a revert.
	 *
	 * This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
	 * their own custom logic. This typically requires additional information from the user (such as the expected number
	 * of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
	 * directly to the Pool's contract, as is `recipient`.
	 *
	 * Emits a `PoolBalanceChanged` event.
	 */
	function joinPool(
		bytes32 poolId,
		address sender,
		address recipient,
		JoinPoolRequest memory request
	) external payable;

	struct JoinPoolRequest {
		address[] assets;
		uint256[] maxAmountsIn;
		bytes userData;
		bool fromInternalBalance;
	}

	/**
	 * @dev Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
	 * trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
	 * Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
	 * `getPoolTokenInfo`).
	 *
	 * If the caller is not `sender`, it must be an authorized relayer for them.
	 *
	 * The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
	 * token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
	 * it just enforces these minimums.
	 *
	 * If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
	 * enable this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead
	 * of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.
	 *
	 * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
	 * interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
	 * be sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the
	 * final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.
	 *
	 * If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
	 * an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
	 * do so will trigger a revert.
	 *
	 * `minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
	 * `tokens` array. This array must match the Pool's registered tokens.
	 *
	 * This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
	 * their own custom logic. This typically requires additional information from the user (such as the expected number
	 * of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
	 * passed directly to the Pool's contract.
	 *
	 * Emits a `PoolBalanceChanged` event.
	 */
	function exitPool(
		bytes32 poolId,
		address sender,
		address payable recipient,
		ExitPoolRequest memory request
	) external;

	struct ExitPoolRequest {
		IAsset[] assets;
		uint256[] minAmountsOut;
		bytes userData;
		bool toInternalBalance;
	}

	/**
	 * @dev Emitted when a user joins or exits a Pool by calling `joinPool` or `exitPool`, respectively.
	 */
	event PoolBalanceChanged(
		bytes32 indexed poolId,
		address indexed liquidityProvider,
		IERC20[] tokens,
		int256[] deltas,
		uint256[] protocolFeeAmounts
	);

	enum PoolBalanceChangeKind {
		JOIN,
		EXIT
	}

	// Swaps
	//
	// Users can swap tokens with Pools by calling the `swap` and `batchSwap` functions. To do this,
	// they need not trust Pool contracts in any way: all security checks are made by the Vault. They must however be
	// aware of the Pools' pricing algorithms in order to estimate the prices Pools will quote.
	//
	// The `swap` function executes a single swap, while `batchSwap` can perform multiple swaps in sequence.
	// In each individual swap, tokens of one kind are sent from the sender to the Pool (this is the 'token in'),
	// and tokens of another kind are sent from the Pool to the recipient in exchange (this is the 'token out').
	// More complex swaps, such as one token in to multiple tokens out can be achieved by batching together
	// individual swaps.
	//
	// There are two swap kinds:
	//  - 'given in' swaps, where the amount of tokens in (sent to the Pool) is known, and the Pool determines (via the
	// `onSwap` hook) the amount of tokens out (to send to the recipient).
	//  - 'given out' swaps, where the amount of tokens out (received from the Pool) is known, and the Pool determines
	// (via the `onSwap` hook) the amount of tokens in (to receive from the sender).
	//
	// Additionally, it is possible to chain swaps using a placeholder input amount, which the Vault replaces with
	// the calculated output of the previous swap. If the previous swap was 'given in', this will be the calculated
	// tokenOut amount. If the previous swap was 'given out', it will use the calculated tokenIn amount. These extended
	// swaps are known as 'multihop' swaps, since they 'hop' through a number of intermediate tokens before arriving at
	// the final intended token.
	//
	// In all cases, tokens are only transferred in and out of the Vault (or withdrawn from and deposited into Internal
	// Balance) after all individual swaps have been completed, and the net token balance change computed. This makes
	// certain swap patterns, such as multihops, or swaps that interact with the same token pair in multiple Pools, cost
	// much less gas than they would otherwise.
	//
	// It also means that under certain conditions it is possible to perform arbitrage by swapping with multiple
	// Pools in a way that results in net token movement out of the Vault (profit), with no tokens being sent in (only
	// updating the Pool's internal accounting).
	//
	// To protect users from front-running or the market changing rapidly, they supply a list of 'limits' for each token
	// involved in the swap, where either the maximum number of tokens to send (by passing a positive value) or the
	// minimum amount of tokens to receive (by passing a negative value) is specified.
	//
	// Additionally, a 'deadline' timestamp can also be provided, forcing the swap to fail if it occurs after
	// this point in time (e.g. if the transaction failed to be included in a block promptly).
	//
	// If interacting with Pools that hold WETH, it is possible to both send and receive ETH directly: the Vault will do
	// the wrapping and unwrapping. To enable this mechanism, the IAsset sentinel value (the zero address) must be
	// passed in the `assets` array instead of the WETH address. Note that it is possible to combine ETH and WETH in the
	// same swap. Any excess ETH will be sent back to the caller (not the sender, which is relevant for relayers).
	//
	// Finally, Internal Balance can be used when either sending or receiving tokens.

	enum SwapKind {
		GIVEN_IN,
		GIVEN_OUT
	}

	/**
	 * @dev Performs a swap with a single Pool.
	 *
	 * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
	 * taken from the Pool, which must be greater than or equal to `limit`.
	 *
	 * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
	 * sent to the Pool, which must be less than or equal to `limit`.
	 *
	 * Internal Balance usage and the recipient are determined by the `funds` struct.
	 *
	 * Emits a `Swap` event.
	 */
	function swap(
		SingleSwap memory singleSwap,
		FundManagement memory funds,
		uint256 limit,
		uint256 deadline
	) external payable returns (uint256);

	/**
	 * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
	 * the `kind` value.
	 *
	 * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
	 * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
	 *
	 * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
	 * used to extend swap behavior.
	 */
	struct SingleSwap {
		bytes32 poolId;
		SwapKind kind;
		IAsset assetIn;
		IAsset assetOut;
		uint256 amount;
		bytes userData;
	}

	/**
	 * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
	 * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
	 *
	 * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
	 * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
	 * the same index in the `assets` array.
	 *
	 * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
	 * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
	 * `amountOut` depending on the swap kind.
	 *
	 * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
	 * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
	 * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
	 *
	 * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
	 * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
	 * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
	 * or unwrapped from WETH by the Vault.
	 *
	 * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
	 * the minimum or maximum amount of each token the vault is allowed to transfer.
	 *
	 * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
	 * equivalent `swap` call.
	 *
	 * Emits `Swap` events.
	 */
	function batchSwap(
		SwapKind kind,
		BatchSwapStep[] memory swaps,
		IAsset[] memory assets,
		FundManagement memory funds,
		int256[] memory limits,
		uint256 deadline
	) external payable returns (int256[] memory);

	/**
	 * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
	 * `assets` array passed to that function, and ETH assets are converted to WETH.
	 *
	 * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
	 * from the previous swap, depending on the swap kind.
	 *
	 * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
	 * used to extend swap behavior.
	 */
	struct BatchSwapStep {
		bytes32 poolId;
		uint256 assetInIndex;
		uint256 assetOutIndex;
		uint256 amount;
		bytes userData;
	}

	/**
	 * @dev Emitted for each individual swap performed by `swap` or `batchSwap`.
	 */
	event Swap(
		bytes32 indexed poolId,
		IERC20 indexed tokenIn,
		IERC20 indexed tokenOut,
		uint256 amountIn,
		uint256 amountOut
	);

	/**
	 * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
	 * `recipient` account.
	 *
	 * If the caller is not `sender`, it must be an authorized relayer for them.
	 *
	 * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
	 * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
	 * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
	 * `joinPool`.
	 *
	 * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
	 * transferred. This matches the behavior of `exitPool`.
	 *
	 * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
	 * revert.
	 */
	struct FundManagement {
		address sender;
		bool fromInternalBalance;
		address payable recipient;
		bool toInternalBalance;
	}

	/**
	 * @dev Simulates a call to `batchSwap`, returning an array of Vault asset deltas. Calls to `swap` cannot be
	 * simulated directly, but an equivalent `batchSwap` call can and will yield the exact same result.
	 *
	 * Each element in the array corresponds to the asset at the same index, and indicates the number of tokens (or ETH)
	 * the Vault would take from the sender (if positive) or send to the recipient (if negative). The arguments it
	 * receives are the same that an equivalent `batchSwap` call would receive.
	 *
	 * Unlike `batchSwap`, this function performs no checks on the sender or recipient field in the `funds` struct.
	 * This makes it suitable to be called by off-chain applications via eth_call without needing to hold tokens,
	 * approve them for the Vault, or even know a user's address.
	 *
	 * Note that this function is not 'view' (due to implementation details): the client code must explicitly execute
	 * eth_call instead of eth_sendTransaction.
	 */
	function queryBatchSwap(
		SwapKind kind,
		BatchSwapStep[] memory swaps,
		IAsset[] memory assets,
		FundManagement memory funds
	) external returns (int256[] memory assetDeltas);

	// Flash Loans

	/**
	 * @dev Performs a 'flash loan', sending tokens to `recipient`, executing the `receiveFlashLoan` hook on it,
	 * and then reverting unless the tokens plus a proportional protocol fee have been returned.
	 *
	 * The `tokens` and `amounts` arrays must have the same length, and each entry in these indicates the loan amount
	 * for each token contract. `tokens` must be sorted in ascending order.
	 *
	 * The 'userData' field is ignored by the Vault, and forwarded as-is to `recipient` as part of the
	 * `receiveFlashLoan` call.
	 *
	 * Emits `FlashLoan` events.
	 */
	function flashLoan(
		IFlashLoanRecipient recipient,
		IERC20[] memory tokens,
		uint256[] memory amounts,
		bytes memory userData
	) external;

	/**
	 * @dev Emitted for each individual flash loan performed by `flashLoan`.
	 */
	event FlashLoan(IFlashLoanRecipient indexed recipient, IERC20 indexed token, uint256 amount, uint256 feeAmount);

	// Asset Management
	//
	// Each token registered for a Pool can be assigned an Asset Manager, which is able to freely withdraw the Pool's
	// tokens from the Vault, deposit them, or assign arbitrary values to its `managed` balance (see
	// `getPoolTokenInfo`). This makes them extremely powerful and dangerous. Even if an Asset Manager only directly
	// controls one of the tokens in a Pool, a malicious manager could set that token's balance to manipulate the
	// prices of the other tokens, and then drain the Pool with swaps. The risk of using Asset Managers is therefore
	// not constrained to the tokens they are managing, but extends to the entire Pool's holdings.
	//
	// However, a properly designed Asset Manager smart contract can be safely used for the Pool's benefit,
	// for example by lending unused tokens out for interest, or using them to participate in voting protocols.
	//
	// This concept is unrelated to the IAsset interface.

	/**
	 * @dev Performs a set of Pool balance operations, which may be either withdrawals, deposits or updates.
	 *
	 * Pool Balance management features batching, which means a single contract call can be used to perform multiple
	 * operations of different kinds, with different Pools and tokens, at once.
	 *
	 * For each operation, the caller must be registered as the Asset Manager for `token` in `poolId`.
	 */
	function managePoolBalance(PoolBalanceOp[] memory ops) external;

	struct PoolBalanceOp {
		PoolBalanceOpKind kind;
		bytes32 poolId;
		IERC20 token;
		uint256 amount;
	}

	/**
	 * Withdrawals decrease the Pool's cash, but increase its managed balance, leaving the total balance unchanged.
	 *
	 * Deposits increase the Pool's cash, but decrease its managed balance, leaving the total balance unchanged.
	 *
	 * Updates don't affect the Pool's cash balance, but because the managed balance changes, it does alter the total.
	 * The external amount can be either increased or decreased by this call (i.e., reporting a gain or a loss).
	 */
	enum PoolBalanceOpKind {
		WITHDRAW,
		DEPOSIT,
		UPDATE
	}

	/**
	 * @dev Emitted when a Pool's token Asset Manager alters its balance via `managePoolBalance`.
	 */
	event PoolBalanceManaged(
		bytes32 indexed poolId,
		address indexed assetManager,
		IERC20 indexed token,
		int256 cashDelta,
		int256 managedDelta
	);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

interface IBalancerPool {
	function getPoolId() external returns (bytes32);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
pragma solidity 0.8.7;
import "../interfaces/ILocker.sol";

contract BaseStrategy {
	/* ========== STATE VARIABLES ========== */
	ILocker public locker;
	address public governance;
	address public rewardsReceiver;
	address public veSDTFeeProxy;
	address public vaultGaugeFactory;
	uint256 public constant BASE_FEE = 10_000;
	mapping(address => address) public gauges;
	mapping(address => bool) public vaults;
	mapping(address => uint256) public perfFee;
	mapping(address => address) public multiGauges;
	mapping(address => uint256) public accumulatorFee; // gauge -> fee
	mapping(address => uint256) public claimerRewardFee; // gauge -> fee
	mapping(address => uint256) public veSDTFee; // gauge -> fee

	/* ========== EVENTS ========== */
	event Deposited(address _gauge, address _token, uint256 _amount);
	event Withdrawn(address _gauge, address _token, uint256 _amount);
	event Claimed(address _gauge, address _token, uint256 _amount);
	event RewardReceiverSet(address _gauge, address _receiver);
	event VaultToggled(address _vault, bool _newState);
	event GaugeSet(address _gauge, address _token);

	/* ========== MODIFIERS ========== */
	modifier onlyGovernance() {
		require(msg.sender == governance, "!governance");
		_;
	}
	modifier onlyApprovedVault() {
		require(vaults[msg.sender], "!approved vault");
		_;
	}
	modifier onlyGovernanceOrFactory() {
		require(msg.sender == governance || msg.sender == vaultGaugeFactory, "!governance && !factory");
		_;
	}

	/* ========== CONSTRUCTOR ========== */
	constructor(
		ILocker _locker,
		address _governance,
		address _receiver
	) {
		locker = _locker;
		governance = _governance;
		rewardsReceiver = _receiver;
	}

	/* ========== MUTATIVE FUNCTIONS ========== */
	function deposit(address _token, uint256 _amount) external virtual onlyApprovedVault {}

	function withdraw(address _token, uint256 _amount) external virtual onlyApprovedVault {}

	function claim(address _gauge) external virtual {}

	function toggleVault(address _vault) external virtual onlyGovernanceOrFactory {}

	function setGauge(address _token, address _gauge) external virtual onlyGovernanceOrFactory {}

	function setMultiGauge(address _gauge, address _multiGauge) external virtual onlyGovernanceOrFactory {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./BaseAccumulator.sol";

/// @title A contract that accumulates rewards and notifies them to the LGV4
/// @author StakeDAO
contract BalancerAccumulator is BaseAccumulator {
	address[] public tokenData;

	/* ========== CONSTRUCTOR ========== */
	constructor(address _tokenReward, address _gauge) BaseAccumulator(_tokenReward, _gauge) {}

	/* ========== MUTATIVE FUNCTIONS ========== */
	/// @notice Claims rewards from the locker and notifies it to the LGV4
	/// @param _amount amount to notify
	function claimAndNotify(uint256 _amount) external {
		require(locker != address(0), "locker not set");
		ILocker(locker).claimRewards(tokenReward, address(this));
		_notifyReward(tokenReward, _amount);
		_distributeSDT();
	}

	/// @notice Claims rewards from the locker and notify all to the LGV4
	function claimAndNotifyAll() external {
		require(locker != address(0), "locker not set");
		ILocker(locker).claimRewards(tokenReward, address(this));
		uint256 amount = IERC20(tokenReward).balanceOf(address(this));
		_notifyReward(tokenReward, amount);
		_distributeSDT();
	}

	/// @notice Claims rewards from the locker and notify all to the LGV4
	function claimAllRewardsAndNotify() external {
		require(locker != address(0), "locker not set");
		ILocker(locker).claimAllRewards(tokenData, address(this));
		_notifyAllExtraReward(tokenData);
	}

	function addReward(address token) external {
		require(msg.sender == governance, "!gov");
		tokenData.push(token);
	}

	function setTokenRewards(address[] calldata tokens) external {
		require(msg.sender == governance, "!gov");
		tokenData = tokens;
	}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

interface ILiquidityGauge {
	struct Reward {
		address token;
		address distributor;
		uint256 period_finish;
		uint256 rate;
		uint256 last_update;
		uint256 integral;
	}

	// solhint-disable-next-line
	function deposit_reward_token(address _rewardToken, uint256 _amount) external;

	// solhint-disable-next-line
	function claim_rewards_for(address _user, address _recipient) external;

	// // solhint-disable-next-line
	// function claim_rewards_for(address _user) external;

	// solhint-disable-next-line
	function deposit(uint256 _value, address _addr) external;

	// solhint-disable-next-line
	function reward_tokens(uint256 _i) external view returns (address);

	// solhint-disable-next-line
	function reward_data(address _tokenReward) external view returns (Reward memory);

	function balanceOf(address) external returns (uint256);

	function claimable_reward(address _user, address _reward_token) external view returns (uint256);

	function claimable_tokens(address _user) external returns (uint256);

	function user_checkpoint(address _user) external returns (bool);

	function commit_transfer_ownership(address) external;

	function claim_rewards(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IMultiRewards {
	function balanceOf(address) external returns (uint256);

	function stakeFor(address, uint256) external;

	function withdrawFor(address, uint256) external;

	function notifyRewardAmount(address, uint256) external;

	function mintFor(address recipient, uint256 amount) external;

	function burnFrom(address _from, uint256 _amount) external;

	function stakeOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./SdtDistributorEvents.sol";

/// @title SdtDistributorV2
/// @notice Earn from Masterchef SDT and distribute it to gauges
contract SdtDistributorV2 is ReentrancyGuardUpgradeable, AccessControlUpgradeable, SdtDistributorEvents {
	using SafeERC20 for IERC20;

	////////////////////////////////////////////////////////////////
	/// --- CONSTANTS
	///////////////////////////////////////////////////////////////

	/// @notice Accounting
	uint256 public constant BASE_UNIT = 10_000;

	/// @notice Address of the SDT token given as a reward.
	IERC20 public constant rewardToken = IERC20(0x73968b9a57c6E53d41345FD57a6E6ae27d6CDB2F);

	/// @notice Address of the masterchef.
	IMasterchef public constant masterchef = IMasterchef(0xfEA5E213bbD81A8a94D0E1eDB09dBD7CEab61e1c);

	/// @notice Role for governors only.
	bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
	/// @notice Role for the guardian
	bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");

	////////////////////////////////////////////////////////////////
	/// --- STORAGE SLOTS
	///////////////////////////////////////////////////////////////

	/// @notice Time between SDT Harvest.
	uint256 public timePeriod;

	/// @notice Address of the token that will be deposited in masterchef.
	IERC20 public masterchefToken;

	/// @notice Address of the `GaugeController` contract.
	IGaugeController public controller;

	/// @notice Address responsible for pulling rewards of type >= 2 gauges and distributing it to the
	/// associated contracts if there is not already an address delegated for this specific contract.
	address public delegateGauge;

	/// @notice Whether SDT distribution through this contract is on or no.
	bool public distributionsOn;

	/// @notice Maps the address of a type >= 2 gauge to a delegate address responsible
	/// for giving rewards to the actual gauge.
	mapping(address => address) public delegateGauges;

	/// @notice Maps the address of a gauge to whether it was killed or not
	/// A gauge killed in this contract cannot receive any rewards.
	mapping(address => bool) public killedGauges;

	/// @notice Maps the address of a gauge delegate to whether this delegate supports the `notifyReward` interface
	/// and is therefore built for automation.
	mapping(address => bool) public isInterfaceKnown;

	/// @notice Masterchef PID
	uint256 public masterchefPID;

	/// @notice Timestamp of the last pull from masterchef.
	uint256 public lastMasterchefPull;

	/// @notice Maps the timestamp of pull action to the amount of SDT that pulled.
	mapping(uint256 => uint256) public pulls; // day => SDT amount

	/// @notice Maps the timestamp of last pull to the gauge addresses then keeps the data if particular gauge paid in the last pull.
	mapping(uint256 => mapping(address => bool)) public isGaugePaid;

	/// @notice Incentive for caller.
	uint256 public claimerFee;

	/// @notice Number of days to go through for past distributing.
	uint256 public lookPastDays;

	////////////////////////////////////////////////////////////////
	/// --- INITIALIZATION LOGIC
	///////////////////////////////////////////////////////////////

	/// @notice Initialize function
	/// @param _controller gauge controller to manage votes
	/// @param _governor governor address
	/// @param _guardian guardian address
	/// @param _delegateGauge delegate gauge address
	function initialize(
		address _controller,
		address _governor,
		address _guardian,
		address _delegateGauge
	) external initializer {
		require(_controller != address(0) && _guardian != address(0) && _governor != address(0), "0");

		controller = IGaugeController(_controller);
		delegateGauge = _delegateGauge;

		masterchefToken = IERC20(address(new MasterchefMasterToken()));
		distributionsOn = false;

		timePeriod = 3600 * 24; // One day in seconds
		lookPastDays = 45; // for past 45 days check

		_setRoleAdmin(GOVERNOR_ROLE, GOVERNOR_ROLE);
		_setRoleAdmin(GUARDIAN_ROLE, GOVERNOR_ROLE);

		_setupRole(GUARDIAN_ROLE, _guardian);
		_setupRole(GOVERNOR_ROLE, _governor);
		_setupRole(GUARDIAN_ROLE, _governor);
	}

	/// @custom:oz-upgrades-unsafe-allow constructor
	constructor() initializer {}

	/// @notice Initialize the masterchef depositing the master token
	/// @param _pid pool id to deposit the token
	function initializeMasterchef(uint256 _pid) external onlyRole(GOVERNOR_ROLE) {
		masterchefPID = _pid;
		masterchefToken.approve(address(masterchef), 1e18);
		masterchef.deposit(_pid, 1e18);
	}

	////////////////////////////////////////////////////////////////
	/// --- DISTRIBUTION LOGIC
	///////////////////////////////////////////////////////////////

	/// @notice Distribute SDT to Gauges
	/// @param gaugeAddr Address of the gauge to distribute.
	function distribute(address gaugeAddr) external nonReentrant {
		_distribute(gaugeAddr);
	}

	/// @notice Distribute SDT to Multiple Gauges
	/// @param gaugeAddr Array of addresses of the gauge to distribute.
	function distributeMulti(address[] calldata gaugeAddr) public nonReentrant {
		uint256 length = gaugeAddr.length;
		for (uint256 i; i < length; i++) {
			_distribute(gaugeAddr[i]);
		}
	}

	/// @notice Internal implementation of distribute logic.
	/// @param gaugeAddr Address of the gauge to distribute rewards to
	function _distribute(address gaugeAddr) internal {
		require(distributionsOn, "not allowed");
		(bool success, bytes memory result) = address(controller).call(
			abi.encodeWithSignature("gauge_types(address)", gaugeAddr)
		);
		if (!success || killedGauges[gaugeAddr]) {
			return;
		}
		int128 gaugeType = abi.decode(result, (int128));

		// Rounded to beginning of the day -> 00:00 UTC
		uint256 roundedTimestamp = (block.timestamp / 1 days) * 1 days;

		uint256 totalDistribute;

		if (block.timestamp > lastMasterchefPull + timePeriod) {
			uint256 sdtBefore = rewardToken.balanceOf(address(this));
			_pullSDT();
			pulls[roundedTimestamp] = rewardToken.balanceOf(address(this)) - sdtBefore;
			lastMasterchefPull = roundedTimestamp;
		}
		// check past n days
		for (uint256 i; i < lookPastDays; i++) {
			uint256 currentTimestamp = roundedTimestamp - (i * 86_400);

			if (pulls[currentTimestamp] > 0) {
				bool isPaid = isGaugePaid[currentTimestamp][gaugeAddr];
				if (isPaid) {
					break;
				}

				// Retrieve the amount pulled from Masterchef at the given timestamp.
				uint256 sdtBalance = pulls[currentTimestamp];
				uint256 gaugeRelativeWeight;

				if (i == 0) {
					// Makes sure the weight is checkpointed. Also returns the weight.
					gaugeRelativeWeight = controller.gauge_relative_weight_write(gaugeAddr, currentTimestamp);
				} else {
					gaugeRelativeWeight = controller.gauge_relative_weight(gaugeAddr, currentTimestamp);
				}

				uint256 sdtDistributed = (sdtBalance * gaugeRelativeWeight) / 1e18;
				totalDistribute += sdtDistributed;
				isGaugePaid[currentTimestamp][gaugeAddr] = true;
			}
		}
		if (totalDistribute > 0) {
			if (gaugeType == 1) {
				rewardToken.safeTransfer(gaugeAddr, totalDistribute);
				IStakingRewards(gaugeAddr).notifyRewardAmount(totalDistribute);
			} else if (gaugeType >= 2) {
				// If it is defined, we use the specific delegate attached to the gauge
				address delegate = delegateGauges[gaugeAddr];
				if (delegate == address(0)) {
					// If not, we check if a delegate common to all gauges with type >= 2 can be used
					delegate = delegateGauge;
				}
				if (delegate != address(0)) {
					// In the case where the gauge has a delegate (specific or not), then rewards are transferred to this gauge
					rewardToken.safeTransfer(delegate, totalDistribute);
					// If this delegate supports a specific interface, then rewards sent are notified through this
					// interface
					if (isInterfaceKnown[delegate]) {
						ISdtMiddlemanGauge(delegate).notifyReward(gaugeAddr, totalDistribute);
					}
				} else {
					rewardToken.safeTransfer(gaugeAddr, totalDistribute);
				}
			} else {
				ILiquidityGauge(gaugeAddr).deposit_reward_token(address(rewardToken), totalDistribute);
			}

			emit RewardDistributed(gaugeAddr, totalDistribute, lastMasterchefPull);
		}
	}

	/// @notice Internal function to pull SDT from the MasterChef
	function _pullSDT() internal {
		masterchef.withdraw(masterchefPID, 0);
	}

	////////////////////////////////////////////////////////////////
	/// --- RESTRICTIVE FUNCTIONS
	///////////////////////////////////////////////////////////////

	/// @notice Sets the distribution state (on/off)
	/// @param _state new distribution state
	function setDistribution(bool _state) external onlyRole(GOVERNOR_ROLE) {
		distributionsOn = _state;
	}

	/// @notice Sets a new gauge controller
	/// @param _controller Address of the new gauge controller
	function setGaugeController(address _controller) external onlyRole(GOVERNOR_ROLE) {
		require(_controller != address(0), "0");
		controller = IGaugeController(_controller);
		emit GaugeControllerUpdated(_controller);
	}

	/// @notice Sets a new delegate gauge for pulling rewards of a type >= 2 gauges or of all type >= 2 gauges
	/// @param gaugeAddr Gauge to change the delegate of
	/// @param _delegateGauge Address of the new gauge delegate related to `gaugeAddr`
	/// @param toggleInterface Whether we should toggle the fact that the `_delegateGauge` is built for automation or not
	/// @dev This function can be used to remove delegating or introduce the pulling of rewards to a given address
	/// @dev If `gaugeAddr` is the zero address, this function updates the delegate gauge common to all gauges with type >= 2
	/// @dev The `toggleInterface` parameter has been added for convenience to save one transaction when adding a gauge delegate
	/// which supports the `notifyReward` interface
	function setDelegateGauge(
		address gaugeAddr,
		address _delegateGauge,
		bool toggleInterface
	) external onlyRole(GOVERNOR_ROLE) {
		if (gaugeAddr != address(0)) {
			delegateGauges[gaugeAddr] = _delegateGauge;
		} else {
			delegateGauge = _delegateGauge;
		}
		emit DelegateGaugeUpdated(gaugeAddr, _delegateGauge);

		if (toggleInterface) {
			_toggleInterfaceKnown(_delegateGauge);
		}
	}

	/// @notice Toggles the status of a gauge to either killed or unkilled
	/// @param gaugeAddr Gauge to toggle the status of
	/// @dev It is impossible to kill a gauge in the `GaugeController` contract, for this reason killing of gauges
	/// takes place in the `SdtDistributor` contract
	/// @dev This means that people could vote for a gauge in the gauge controller contract but that rewards are not going
	/// to be distributed to it in the end: people would need to remove their weights on the gauge killed to end the diminution
	/// in rewards
	/// @dev In the case of a gauge being killed, this function resets the timestamps at which this gauge has been approved and
	/// disapproves the gauge to spend the token
	/// @dev It should be cautiously called by governance as it could result in less SDT overall rewards than initially planned
	/// if people do not remove their voting weights to the killed gauge
	function toggleGauge(address gaugeAddr) external onlyRole(GOVERNOR_ROLE) {
		bool gaugeKilledMem = killedGauges[gaugeAddr];
		if (!gaugeKilledMem) {
			rewardToken.safeApprove(gaugeAddr, 0);
		}
		killedGauges[gaugeAddr] = !gaugeKilledMem;
		emit GaugeToggled(gaugeAddr, !gaugeKilledMem);
	}

	/// @notice Notifies that the interface of a gauge delegate is known or has changed
	/// @param _delegateGauge Address of the gauge to change
	/// @dev Gauge delegates that are built for automation should be toggled
	function toggleInterfaceKnown(address _delegateGauge) external onlyRole(GUARDIAN_ROLE) {
		_toggleInterfaceKnown(_delegateGauge);
	}

	/// @notice Toggles the fact that a gauge delegate can be used for automation or not and therefore supports
	/// the `notifyReward` interface
	/// @param _delegateGauge Address of the gauge to change
	function _toggleInterfaceKnown(address _delegateGauge) internal {
		bool isInterfaceKnownMem = isInterfaceKnown[_delegateGauge];
		isInterfaceKnown[_delegateGauge] = !isInterfaceKnownMem;
		emit InterfaceKnownToggled(_delegateGauge, !isInterfaceKnownMem);
	}

	/// @notice Gives max approvement to the gauge
	/// @param gaugeAddr Address of the gauge
	function approveGauge(address gaugeAddr) external onlyRole(GOVERNOR_ROLE) {
		rewardToken.safeApprove(gaugeAddr, type(uint256).max);
	}

	/// @notice Set the time period to pull SDT from Masterchef
	/// @param _timePeriod new timePeriod value in seconds
	function setTimePeriod(uint256 _timePeriod) external onlyRole(GOVERNOR_ROLE) {
		require(_timePeriod >= 1 days, "TOO_LOW");
		timePeriod = _timePeriod;
	}

	function setClaimerFee(uint256 _newFee) external onlyRole(GOVERNOR_ROLE) {
		require(_newFee <= BASE_UNIT, "TOO_HIGH");
		claimerFee = _newFee;
	}

	/// @notice Set the how many days we should look back for reward distribution
	/// @param _newLookPastDays new value for how many days we should look back
	function setLookPastDays(uint256 _newLookPastDays) external onlyRole(GOVERNOR_ROLE) {
		lookPastDays = _newLookPastDays;
	}

	/// @notice Withdraws ERC20 tokens that could accrue on this contract
	/// @param tokenAddress Address of the ERC20 token to withdraw
	/// @param to Address to transfer to
	/// @param amount Amount to transfer
	/// @dev Added to support recovering LP Rewards and other mistaken tokens
	/// from other systems to be distributed to holders
	/// @dev This function could also be used to recover SDT tokens in case the rate got smaller
	function recoverERC20(
		address tokenAddress,
		address to,
		uint256 amount
	) external onlyRole(GOVERNOR_ROLE) {
		IERC20(tokenAddress).safeTransfer(to, amount);
		emit Recovered(tokenAddress, to, amount);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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
pragma solidity 0.8.7;

interface ILocker {
	function createLock(uint256, uint256) external;

	function claimAllRewards(address[] calldata _tokens, address _recipient) external;

	function increaseAmount(uint256) external;

	function increaseUnlockTime(uint256) external;

	function release() external;

	function claimRewards(address,address) external;

	function claimFXSRewards(address) external;

	function execute(
		address,
		uint256,
		bytes calldata
	) external returns (bool, bytes memory);

	function setGovernance(address) external;

	function voteGaugeWeight(address, uint256) external;

	function setAngleDepositor(address) external;

	function setFxsDepositor(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ILocker.sol";
import "../interfaces/ILiquidityGauge.sol";
import { ISDTDistributor } from "../interfaces/ISDTDistributor.sol";

/// @title BaseAccumulator
/// @notice A contract that defines the functions shared by all accumulators
/// @author StakeDAO
contract BaseAccumulator {
	using SafeERC20 for IERC20;
	/* ========== STATE VARIABLES ========== */
	address public governance;
	address public locker;
	address public tokenReward;
	address public gauge;
	address public sdtDistributor;
	uint256 public claimerFee;

	/* ========== EVENTS ========== */

	event SdtDistributorUpdated(address oldDistributor, address newDistributor);
	event GaugeSet(address oldGauge, address newGauge);
	event RewardNotified(address gauge, address tokenReward, uint256 amount);
	event LockerSet(address oldLocker, address newLocker);
	event GovernanceSet(address oldGov, address newGov);
	event TokenRewardSet(address oldTr, address newTr);
	event TokenDeposited(address token, uint256 amount);
	event ERC20Rescued(address token, uint256 amount);

	/* ========== CONSTRUCTOR ========== */
	constructor(address _tokenReward, address _gauge) {
		tokenReward = _tokenReward;
		gauge = _gauge;
		governance = msg.sender;
	}

	/* ========== MUTATIVE FUNCTIONS ========== */

	/// @notice Notify the reward using an extra token
	/// @param _tokenReward token address to notify
	/// @param _amount amount to notify
	function notifyExtraReward(address _tokenReward, uint256 _amount) external {
		require(msg.sender == governance, "!gov");
		_notifyReward(_tokenReward, _amount);
		_distributeSDT();
	}

	/// @notice Notify the reward using all balance of extra token
	/// @param _tokenReward token address to notify
	function notifyAllExtraReward(address _tokenReward) external {
		require(msg.sender == governance, "!gov");
		uint256 amount = IERC20(_tokenReward).balanceOf(address(this));
		_notifyReward(_tokenReward, amount);
		_distributeSDT();
	}

	function notifyExtraReward(address[] calldata _tokens, uint256[] calldata amounts) external {
		require(msg.sender == governance, "!gov");
		_notifyExtraReward(_tokens, amounts);
		_distributeSDT();
	}

	function _notifyExtraReward(address[] memory _tokens, uint256[] memory amounts) internal {
		uint256 length = _tokens.length;
		for (uint256 i; i < length; ++i) {
			_notifyReward(_tokens[i], amounts[i]);
		}
	}

	function notifyAllExtraReward(address[] calldata _tokens) external {
		require(msg.sender == governance, "!gov");
		_notifyAllExtraReward(_tokens);
		_distributeSDT();
	}

	function _notifyAllExtraReward(address[] memory _tokens) internal {
		uint256 amount;
		uint256 length = _tokens.length;
		for (uint256 i; i < length; ++i) {
			amount = IERC20(_tokens[i]).balanceOf(address(this));
			_notifyReward(_tokens[i], amount);
		}
	}

	function _distributeSDT() internal {
		if (sdtDistributor != address(0)) {
			ISDTDistributor(sdtDistributor).distribute(gauge);
		}
	}

	/// @notice Notify the new reward to the LGV4
	/// @param _tokenReward token to notify
	/// @param _amount amount to notify
	function _notifyReward(address _tokenReward, uint256 _amount) internal {
		require(gauge != address(0), "gauge not set");
		if (_amount == 0) {
			return;
		}
		uint256 balanceBefore = IERC20(_tokenReward).balanceOf(address(this));
		require(balanceBefore >= _amount, "amount not enough");
		if (ILiquidityGauge(gauge).reward_data(_tokenReward).distributor != address(0)) {
			uint256 claimerReward = (_amount * claimerFee) / 10000;
			IERC20(_tokenReward).transfer(msg.sender, claimerReward);
			_amount -= claimerReward;
			IERC20(_tokenReward).approve(gauge, _amount);
			ILiquidityGauge(gauge).deposit_reward_token(_tokenReward, _amount);

			uint256 balanceAfter = IERC20(_tokenReward).balanceOf(address(this));

			require(balanceBefore - balanceAfter == _amount, "wrong amount notified");

			emit RewardNotified(gauge, _tokenReward, _amount);
		}
	}

	/// @notice Deposit token into the accumulator
	/// @param _token token to deposit
	/// @param _amount amount to deposit
	function depositToken(address _token, uint256 _amount) external {
		require(_amount > 0, "set an amount > 0");
		IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
		emit TokenDeposited(_token, _amount);
	}

	/// @notice Sets gauge for the accumulator which will receive and distribute the rewards
	/// @dev Can be called only by the governance
	/// @param _gauge gauge address
	function setGauge(address _gauge) external {
		require(msg.sender == governance, "!gov");
		require(_gauge != address(0), "can't be zero address");
		emit GaugeSet(gauge, _gauge);
		gauge = _gauge;
	}

	/// @notice Sets SdtDistributor to distribute from the Accumulator SDT Rewards to Gauge.
	/// @dev Can be called only by the governance
	/// @param _sdtDistributor gauge address
	function setSdtDistributor(address _sdtDistributor) external {
		require(msg.sender == governance, "!gov");
		require(_sdtDistributor != address(0), "can't be zero address");

		emit SdtDistributorUpdated(sdtDistributor, _sdtDistributor);
		sdtDistributor = _sdtDistributor;
	}

	/// @notice Allows the governance to set the new governance
	/// @dev Can be called only by the governance
	/// @param _governance governance address
	function setGovernance(address _governance) external {
		require(msg.sender == governance, "!gov");
		require(_governance != address(0), "can't be zero address");
		emit GovernanceSet(governance, _governance);
		governance = _governance;
	}

	/// @notice Allows the governance to set the locker
	/// @dev Can be called only by the governance
	/// @param _locker locker address
	function setLocker(address _locker) external {
		require(msg.sender == governance, "!gov");
		require(_locker != address(0), "can't be zero address");
		emit LockerSet(locker, _locker);
		locker = _locker;
	}

	/// @notice Allows the governance to set the token reward
	/// @dev Can be called only by the governance
	/// @param _tokenReward token reward address
	function setTokenReward(address _tokenReward) external {
		require(msg.sender == governance, "!gov");
		require(_tokenReward != address(0), "can't be zero address");
		emit TokenRewardSet(tokenReward, _tokenReward);
		tokenReward = _tokenReward;
	}

	function setClaimerFee(uint256 _claimerFee) external {
		require(msg.sender == governance, "!gov");
		claimerFee = _claimerFee;
	}

	/// @notice A function that rescue any ERC20 token
	/// @param _token token address
	/// @param _amount amount to rescue
	/// @param _recipient address to send token rescued
	function rescueERC20(
		address _token,
		uint256 _amount,
		address _recipient
	) external {
		require(msg.sender == governance, "!gov");
		require(_amount > 0, "set an amount > 0");
		require(_recipient != address(0), "can't be zero address");
		IERC20(_token).safeTransfer(_recipient, _amount);
		emit ERC20Rescued(_token, _amount);
	}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

interface ISDTDistributor {
    function distribute(address gaugeAddr) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../interfaces/IGaugeController.sol";
import "../interfaces/ILiquidityGauge.sol";
import "../interfaces/ISdtMiddlemanGauge.sol";
import "../interfaces/IStakingRewards.sol";

import "../interfaces/IMasterchef.sol";
import "./MasterchefMasterToken.sol";

import "../external/AccessControlUpgradeable.sol";

/// @title SdtDistributorEvents
/// @author StakeDAO Core Team
/// @notice All the events used in `SdtDistributor` contract
 abstract contract SdtDistributorEvents {
	event DelegateGaugeUpdated(address indexed _gaugeAddr, address indexed _delegateGauge);
	event DistributionsToggled(bool _distributionsOn);
	event GaugeControllerUpdated(address indexed _controller);
	event GaugeToggled(address indexed gaugeAddr, bool newStatus);
	event InterfaceKnownToggled(address indexed _delegateGauge, bool _isInterfaceKnown);
	event RateUpdated(uint256 _newRate);
	event Recovered(address indexed tokenAddress, address indexed to, uint256 amount);
	event RewardDistributed(address indexed gaugeAddr, uint256 sdtDistributed, uint256 lastMasterchefPull);
	event UpdateMiningParameters(uint256 time, uint256 rate, uint256 supply);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

interface ISdtMiddlemanGauge {
	function notifyReward(address gauge, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IStakingRewardsFunctions
/// @author StakeDAO Core Team
/// @notice Interface for the staking rewards contract that interact with the `RewardsDistributor` contract
interface IStakingRewardsFunctions {
    function notifyRewardAmount(uint256 reward) external;

    function recoverERC20(
        address tokenAddress,
        address to,
        uint256 tokenAmount
    ) external;

    function setNewRewardsDistribution(address newRewardsDistribution) external;
}

/// @title IStakingRewards
/// @author StakeDAO Core Team
/// @notice Previous interface with additionnal getters for public variables
interface IStakingRewards is IStakingRewardsFunctions {
    function rewardToken() external view returns (IERC20);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IMasterchef {
	function deposit(uint256, uint256) external;

	function withdraw(uint256, uint256) external;

	function userInfo(uint256, address) external view returns (uint256, uint256);

	function poolInfo(uint256)
		external
		returns (
			address,
			uint256,
			uint256,
			uint256
		);

	function totalAllocPoint() external view returns (uint256);

	function sdtPerBlock() external view returns (uint256);

	function pendingSdt(uint256, address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MasterchefMasterToken is ERC20, Ownable {
	constructor() ERC20("Masterchef Master Token", "MMT") {
		_mint(msg.sender, 1e18);
	}
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IAccessControl.sol";

/**
 * @dev This contract is fully forked from OpenZeppelin `AccessControlUpgradeable`.
 * The only difference is the removal of the ERC165 implementation as it's not
 * needed in Angle.
 *
 * Contract module that allows children to implement role-based access
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
abstract contract AccessControlUpgradeable is Initializable, IAccessControl {
    function __AccessControl_init() internal initializer {
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {}

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
        _checkRole(role, msg.sender);
        _;
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
    function grantRole(bytes32 role, address account) external override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) external override onlyRole(getRoleAdmin(role)) {
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
    function renounceRole(bytes32 role, address account) external override {
        require(account == msg.sender, "71");

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
    function _setupRole(bytes32 role, address account) internal {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) internal {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes32 role, address account) internal {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }

    uint256[49] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

/// @title IAccessControl
/// @author Forked from OpenZeppelin
/// @notice Interface for `AccessControl` contracts
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.7;

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
	// solhint-disable-previous-line no-empty-blocks
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.7;

interface IAuthorizer {
	/**
	 * @dev Returns true if `account` can perform the action described by `actionId` in the contract `where`.
	 */
	function canPerform(
		bytes32 actionId,
		address account,
		address where
	) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.7;

// Inspired by Aave Protocol's IFlashLoanReceiver.

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFlashLoanRecipient {
	/**
	 * @dev When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
	 *
	 * At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
	 * call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
	 * Vault, or else the entire flash loan will revert.
	 *
	 * `userData` is the same value passed in the `IVault.flashLoan` call.
	 */
	function receiveFlashLoan(
		IERC20[] memory tokens,
		uint256[] memory amounts,
		uint256[] memory feeAmounts,
		bytes memory userData
	) external;
}
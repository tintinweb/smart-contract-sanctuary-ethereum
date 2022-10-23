// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import 'solmate/tokens/ERC20.sol';
import 'solmate/utils/SafeTransferLib.sol';
import 'solmate/utils/FixedPointMathLib.sol';

import './libraries/Ownership.sol';
import './libraries/BlockDelay.sol';
import './interfaces/IERC4626.sol';
import './Strategy.sol';

contract Vault is ERC20, IERC4626, Ownership, BlockDelay {
	using SafeTransferLib for ERC20;
	using FixedPointMathLib for uint256;

	/// @notice token which the vault uses and accumulates
	ERC20 public immutable asset;

	/// @notice whether deposits and withdrawals are paused
	bool public paused;

	uint256 private _lockedProfit;
	/// @notice timestamp of last report, used for locked profit calculations
	uint256 public lastReport;
	/// @notice period over which profits are gradually unlocked, defense against sandwich attacks
	uint256 public lockedProfitDuration = 6 hours;
	uint256 internal constant MAX_LOCKED_PROFIT_DURATION = 3 days;

	/// @dev maximum user can deposit in a single tx
	uint256 private _maxDeposit = type(uint256).max;

	struct StrategyParams {
		bool added;
		uint256 debt;
		uint256 debtRatio;
	}

	Strategy[] private _queue;
	mapping(Strategy => StrategyParams) public strategies;

	uint8 internal constant MAX_QUEUE_LENGTH = 20;

	uint256 public totalDebt;
	uint256 public totalDebtRatio;
	uint256 internal constant MAX_TOTAL_DEBT_RATIO = 1_000;

	/*//////////////////
	/      Events      /
	//////////////////*/

	event Report(Strategy indexed strategy, uint256 gain, uint256 loss);

	event StrategyAdded(Strategy indexed strategy, uint256 debtRatio);
	event StrategyDebtRatioChanged(Strategy indexed strategy, uint256 newDebtRatio);
	event StrategyRemoved(Strategy indexed strategy);
	event StrategyQueuePositionsSwapped(uint8 i, uint8 j, Strategy indexed newI, Strategy indexed newJ);

	event LockedProfitDurationChanged(uint256 newDuration);
	event MaxDepositChanged(uint256 newMaxDeposit);

	/*//////////////////
	/      Errors      /
	//////////////////*/

	error Zero();
	error BelowMinimum(uint256);
	error AboveMaximum(uint256);

	error AboveMaxDeposit();

	error AlreadyStrategy();
	error NotStrategy();
	error StrategyDoesNotBelongToQueue();
	error StrategyQueueFull();

	error AlreadyValue();

	error Paused();

	/// @dev e.g. USDC becomes 'Unagii USD Coin Vault v3' and 'uUSDCv3'
	constructor(
		ERC20 _asset,
		address[] memory _authorized,
		uint8 _blockDelay
	)
		ERC20(
			string(abi.encodePacked('Unagii ', _asset.name(), ' Vault v3')),
			string(abi.encodePacked('u', _asset.symbol(), 'v3')),
			_asset.decimals()
		)
		Ownership(_authorized)
		BlockDelay(_blockDelay)
	{
		asset = _asset;
	}

	/*///////////////////////
	/      Public View      /
	///////////////////////*/

	function queue() external view returns (Strategy[] memory) {
		return _queue;
	}

	function totalAssets() public view returns (uint256 assets) {
		return asset.balanceOf(address(this)) + totalDebt;
	}

	function lockedProfit() public view returns (uint256 lockedAssets) {
		uint256 last = lastReport;
		uint256 duration = lockedProfitDuration;

		unchecked {
			// won't overflow since time is nowhere near uint256.max
			if (block.timestamp >= last + duration) return 0;
			// can overflow if _lockedProfit * difference > uint256.max but in practice should never happen
			return _lockedProfit - _lockedProfit.mulDivDown(block.timestamp - last, duration);
		}
	}

	function freeAssets() public view returns (uint256 assets) {
		return totalAssets() - lockedProfit();
	}

	function convertToShares(uint256 _assets) public view returns (uint256 shares) {
		uint256 supply = totalSupply;
		return supply == 0 ? _assets : _assets.mulDivDown(supply, totalAssets());
	}

	function convertToAssets(uint256 _shares) public view returns (uint256 assets) {
		uint256 supply = totalSupply;
		return supply == 0 ? _shares : _shares.mulDivDown(totalAssets(), supply);
	}

	function maxDeposit(address) external view returns (uint256 assets) {
		return _maxDeposit;
	}

	function previewDeposit(uint256 _assets) public view returns (uint256 shares) {
		return convertToShares(_assets);
	}

	function maxMint(address) external view returns (uint256 shares) {
		return convertToShares(_maxDeposit);
	}

	function previewMint(uint256 shares) public view returns (uint256 assets) {
		uint256 supply = totalSupply;
		return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
	}

	function maxWithdraw(address owner) external view returns (uint256 assets) {
		return convertToAssets(balanceOf[owner]);
	}

	function previewWithdraw(uint256 assets) public view returns (uint256 shares) {
		uint256 supply = totalSupply;

		return supply == 0 ? assets : assets.mulDivUp(supply, freeAssets());
	}

	function maxRedeem(address _owner) external view returns (uint256 shares) {
		return balanceOf[_owner];
	}

	function previewRedeem(uint256 shares) public view returns (uint256 assets) {
		uint256 supply = totalSupply;
		return supply == 0 ? shares : shares.mulDivDown(freeAssets(), supply);
	}

	/*////////////////////////////
	/      Public Functions      /
	////////////////////////////*/

	function safeDeposit(
		uint256 _assets,
		address _receiver,
		uint256 _minShares
	) external returns (uint256 shares) {
		shares = deposit(_assets, _receiver);
		if (shares < _minShares) revert BelowMinimum(shares);
	}

	function safeMint(
		uint256 _shares,
		address _receiver,
		uint256 _maxAssets
	) external returns (uint256 assets) {
		assets = mint(_shares, _receiver);
		if (assets > _maxAssets) revert AboveMaximum(assets);
	}

	function safeWithdraw(
		uint256 _assets,
		address _receiver,
		address _owner,
		uint256 _maxShares
	) external returns (uint256 shares) {
		shares = withdraw(_assets, _receiver, _owner);
		if (shares > _maxShares) revert AboveMaximum(shares);
	}

	function safeRedeem(
		uint256 _shares,
		address _receiver,
		address _owner,
		uint256 _minAssets
	) external returns (uint256 assets) {
		assets = redeem(_shares, _receiver, _owner);
		if (assets < _minAssets) revert BelowMinimum(assets);
	}

	/*////////////////////////////////////
	/      ERC4626 Public Functions      /
	////////////////////////////////////*/

	function deposit(uint256 _assets, address _receiver) public whenNotPaused returns (uint256 shares) {
		if ((shares = previewDeposit(_assets)) == 0) revert Zero();

		_deposit(_assets, shares, _receiver);
	}

	function mint(uint256 _shares, address _receiver) public whenNotPaused returns (uint256 assets) {
		if (_shares == 0) revert Zero();
		assets = previewMint(_shares);

		_deposit(assets, _shares, _receiver);
	}

	function withdraw(
		uint256 _assets,
		address _receiver,
		address _owner
	) public returns (uint256 shares) {
		if (_assets == 0) revert Zero();
		shares = previewWithdraw(_assets);

		_withdraw(_assets, shares, _owner, _receiver);
	}

	function redeem(
		uint256 _shares,
		address _receiver,
		address _owner
	) public returns (uint256 assets) {
		if ((assets = previewRedeem(_shares)) == 0) revert Zero();

		return _withdraw(assets, _shares, _owner, _receiver);
	}

	/*///////////////////////////////////////////
	/      Restricted Functions: onlyOwner      /
	///////////////////////////////////////////*/

	function addStrategy(Strategy _strategy, uint256 _debtRatio) external onlyOwner {
		if (_strategy.vault() != this) revert StrategyDoesNotBelongToQueue();
		if (strategies[_strategy].added) revert AlreadyStrategy();
		if (_queue.length >= MAX_QUEUE_LENGTH) revert StrategyQueueFull();

		totalDebtRatio += _debtRatio;
		if (totalDebtRatio > MAX_TOTAL_DEBT_RATIO) revert AboveMaximum(totalDebtRatio);

		strategies[_strategy] = StrategyParams({added: true, debt: 0, debtRatio: _debtRatio});
		_queue.push(_strategy);

		emit StrategyAdded(_strategy, _debtRatio);
	}

	/*////////////////////////////////////////////
	/      Restricted Functions: onlyAdmins      /
	////////////////////////////////////////////*/

	function removeStrategy(Strategy _strategy, uint256 _minReceived) external onlyAdmins {
		if (!strategies[_strategy].added) revert NotStrategy();
		totalDebtRatio -= strategies[_strategy].debtRatio;

		if (strategies[_strategy].debt > 0) {
			(uint256 received, ) = _collect(_strategy, type(uint256).max, address(this));
			if (received < _minReceived) revert BelowMinimum(received);
		}

		// reorganize queue, filling in the empty strategy
		Strategy[] memory newQueue = new Strategy[](_queue.length - 1);

		bool found;
		uint8 length = uint8(newQueue.length);
		for (uint8 i = 0; i < length; ++i) {
			if (_queue[i] == _strategy) found = true;

			if (found) newQueue[i] = _queue[i + 1];
			else newQueue[i] = _queue[i];
		}

		delete strategies[_strategy];
		_queue = newQueue;

		emit StrategyRemoved(_strategy);
	}

	function swapQueuePositions(uint8 _i, uint8 _j) external onlyAdmins {
		Strategy s1 = _queue[_i];
		Strategy s2 = _queue[_j];

		_queue[_i] = s2;
		_queue[_j] = s1;

		emit StrategyQueuePositionsSwapped(_i, _j, s2, s1);
	}

	function setDebtRatio(Strategy _strategy, uint256 _newDebtRatio) external onlyAdmins {
		if (!strategies[_strategy].added) revert NotStrategy();
		_setDebtRatio(_strategy, _newDebtRatio);
	}

	/// @dev locked profit duration can be 0
	function setLockedProfitDuration(uint256 _newDuration) external onlyAdmins {
		if (_newDuration > MAX_LOCKED_PROFIT_DURATION) revert AboveMaximum(_newDuration);
		if (_newDuration == lockedProfitDuration) revert AlreadyValue();
		lockedProfitDuration = _newDuration;
		emit LockedProfitDurationChanged(_newDuration);
	}

	function setBlockDelay(uint8 _newDelay) external onlyAdmins {
		_setBlockDelay(_newDelay);
	}

	/*///////////////////////////////////////////////
	/      Restricted Functions: onlyAuthorized     /
	///////////////////////////////////////////////*/

	function suspendStrategy(Strategy _strategy) external onlyAuthorized {
		if (!strategies[_strategy].added) revert NotStrategy();
		_setDebtRatio(_strategy, 0);
	}

	function collectFromStrategy(
		Strategy _strategy,
		uint256 _assets,
		uint256 _minReceived
	) external onlyAuthorized returns (uint256 received) {
		if (!strategies[_strategy].added) revert NotStrategy();
		(received, ) = _collect(_strategy, _assets, address(this));
		if (received < _minReceived) revert BelowMinimum(received);
	}

	function pause() external onlyAuthorized {
		if (paused) revert AlreadyValue();
		paused = true;
	}

	function unpause() external onlyAuthorized {
		if (!paused) revert AlreadyValue();
		paused = false;
	}

	function setMaxDeposit(uint256 _newMaxDeposit) external onlyAuthorized {
		if (_maxDeposit == _newMaxDeposit) revert AlreadyValue();
		_maxDeposit = _newMaxDeposit;
		emit MaxDepositChanged(_newMaxDeposit);
	}

	/// @dev costs less gas than multiple harvests if active strategies > 1
	function harvestAll() external onlyAuthorized updateLastReport {
		uint8 length = uint8(_queue.length);
		for (uint8 i = 0; i < length; ++i) {
			Strategy strategy = _queue[i];
			strategy.harvest();
			_report(strategy);
		}
	}

	/// @dev costs less gas than multiple reports if active strategies > 1
	function reportAll() external onlyAuthorized updateLastReport {
		uint8 length = uint8(_queue.length);
		for (uint8 i = 0; i < length; ++i) {
			_report(_queue[i]);
		}
	}

	function harvest(Strategy _strategy) external onlyAuthorized updateLastReport {
		if (!strategies[_strategy].added) revert NotStrategy();

		_strategy.harvest();
		_report(_strategy);
	}

	function report(Strategy _strategy) external onlyAuthorized updateLastReport {
		if (!strategies[_strategy].added) revert NotStrategy();

		_report(_strategy);
	}

	/*///////////////////////////////////////////
	/      Internal Override: useBlockDelay     /
	///////////////////////////////////////////*/

	/// @dev address cannot mint/burn/send/receive share tokens on same block, defense against flash loan exploits
	function _mint(address _to, uint256 _amount) internal override useBlockDelay(_to) {
		if (_to == address(0)) revert Zero();
		ERC20._mint(_to, _amount);
	}

	/// @dev address cannot mint/burn/send/receive share tokens on same block, defense against flash loan exploits
	function _burn(address _from, uint256 _amount) internal override useBlockDelay(_from) {
		ERC20._burn(_from, _amount);
	}

	/// @dev address cannot mint/burn/send/receive share tokens on same block, defense against flash loan exploits
	function transfer(address _to, uint256 _amount)
		public
		override
		useBlockDelay(msg.sender)
		useBlockDelay(_to)
		returns (bool)
	{
		return ERC20.transfer(_to, _amount);
	}

	/// @dev address cannot mint/burn/send/receive share tokens on same block, defense against flash loan exploits
	function transferFrom(
		address _from,
		address _to,
		uint256 _amount
	) public override useBlockDelay(_from) useBlockDelay(_to) returns (bool) {
		return ERC20.transferFrom(_from, _to, _amount);
	}

	/*//////////////////////////////
	/      Internal Functions      /
	//////////////////////////////*/

	function _deposit(
		uint256 _assets,
		uint256 _shares,
		address _receiver
	) internal {
		if (_assets > _maxDeposit) revert AboveMaxDeposit();

		asset.safeTransferFrom(msg.sender, address(this), _assets);
		_mint(_receiver, _shares);
		emit Deposit(msg.sender, _receiver, _assets, _shares);
	}

	function _withdraw(
		uint256 _assets,
		uint256 _shares,
		address _owner,
		address _receiver
	) internal returns (uint256 received) {
		if (msg.sender != _owner) {
			uint256 allowed = allowance[_owner][msg.sender];
			if (allowed != type(uint256).max) allowance[_owner][msg.sender] = allowed - _shares;
		}

		_burn(_owner, _shares);

		emit Withdraw(msg.sender, _receiver, _owner, _assets, _shares);

		// first, withdraw from balance
		uint256 balance = asset.balanceOf(address(this));

		if (balance > 0) {
			uint256 amount = _assets > balance ? balance : _assets;
			asset.safeTransfer(_receiver, amount);
			_assets -= amount;
			received += amount;
		}

		// next, withdraw from strategies
		uint8 length = uint8(_queue.length);
		for (uint8 i = 0; i < length; ++i) {
			if (_assets == 0) break;
			(uint256 receivedFromStrategy, uint256 slippage) = _collect(_queue[i], _assets, _receiver);
			_assets -= receivedFromStrategy + slippage; // user pays for slippage, if any
			received += receivedFromStrategy;
		}
	}

	function _lend(Strategy _strategy, uint256 _assets) internal {
		uint256 balance = asset.balanceOf(address(this));
		uint256 amount = _assets > balance ? balance : _assets;

		asset.safeTransfer(address(_strategy), amount);
		_strategy.invest();

		strategies[_strategy].debt += amount;
		totalDebt += amount;
	}

	/// @dev overflow is handled by strategy
	function _collect(
		Strategy _strategy,
		uint256 _assets,
		address _receiver
	) internal returns (uint256 received, uint256 slippage) {
		(received, slippage) = _strategy.withdraw(_assets, _receiver);

		uint256 debt = strategies[_strategy].debt;

		uint256 amount = debt > received ? received : debt;

		strategies[_strategy].debt -= amount;
		totalDebt -= amount;
	}

	function _report(Strategy _strategy) internal {
		uint256 assets = _strategy.totalAssets();
		uint256 debt = strategies[_strategy].debt;

		strategies[_strategy].debt = assets; // update debt

		uint256 gain;
		uint256 loss;

		if (assets > debt) {
			unchecked {
				gain = assets - debt;
			}
			totalDebt += gain;

			_lockedProfit = lockedProfit() + gain;
		} else if (debt > assets) {
			unchecked {
				loss = debt - assets;
				totalDebt -= loss;

				uint256 lockedProfitBeforeLoss = lockedProfit();
				_lockedProfit = lockedProfitBeforeLoss > loss ? lockedProfitBeforeLoss - loss : 0;
			}
		}

		uint256 possibleDebt = totalDebtRatio == 0
			? 0
			: totalAssets().mulDivDown(strategies[_strategy].debtRatio, totalDebtRatio);

		if (possibleDebt > assets) _lend(_strategy, possibleDebt - assets);
		else if (assets > possibleDebt) _collect(_strategy, assets - possibleDebt, address(this));

		emit Report(_strategy, gain, loss);
	}

	function _setDebtRatio(Strategy _strategy, uint256 _newDebtRatio) internal {
		uint256 currentDebtRatio = strategies[_strategy].debtRatio;
		if (_newDebtRatio == currentDebtRatio) revert AlreadyValue();

		uint256 newTotalDebtRatio = totalDebtRatio + _newDebtRatio - currentDebtRatio;
		if (newTotalDebtRatio > MAX_TOTAL_DEBT_RATIO) revert AboveMaximum(newTotalDebtRatio);

		strategies[_strategy].debtRatio = _newDebtRatio;
		totalDebtRatio = newTotalDebtRatio;

		emit StrategyDebtRatioChanged(_strategy, _newDebtRatio);
	}

	/*/////////////////////
	/      Modifiers      /
	/////////////////////*/

	modifier updateLastReport() {
		_;
		lastReport = block.timestamp;
	}

	modifier whenNotPaused() {
		if (paused) revert Paused();
		_;
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    event Debug(bool one, bool two, uint256 retsize);

    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

abstract contract Ownership {
	address public owner;
	address public nominatedOwner;

	address public admin;

	mapping(address => bool) public authorized;

	event OwnerChanged(address indexed previousOwner, address indexed newOwner);
	event AuthAdded(address indexed newAuth);
	event AuthRemoved(address indexed oldAuth);

	error Unauthorized();
	error AlreadyRole();
	error NotRole();

	/// @param _authorized maximum of 256 addresses in constructor
	constructor(address[] memory _authorized) {
		owner = msg.sender;
		admin = msg.sender;
		for (uint8 i = 0; i < _authorized.length; ++i) {
			authorized[_authorized[i]] = true;
			emit AuthAdded(_authorized[i]);
		}
	}

	// Public Functions

	function acceptOwnership() external {
		if (msg.sender != nominatedOwner) revert Unauthorized();
		emit OwnerChanged(owner, msg.sender);
		owner = msg.sender;
		nominatedOwner = address(0);
	}

	// Restricted Functions: onlyOwner

	/// @dev nominating zero address revokes a pending nomination
	function nominateOwnership(address _newOwner) external onlyOwner {
		nominatedOwner = _newOwner;
	}

	function setAdmin(address _newAdmin) external onlyOwner {
		if (admin == _newAdmin) revert AlreadyRole();
		admin = _newAdmin;
	}

	// Restricted Functions: onlyAdmins

	function addAuthorized(address _authorized) external onlyAdmins {
		if (authorized[_authorized]) revert AlreadyRole();
		authorized[_authorized] = true;
		emit AuthAdded(_authorized);
	}

	function removeAuthorized(address _authorized) external onlyAdmins {
		if (!authorized[_authorized]) revert NotRole();
		authorized[_authorized] = false;
		emit AuthRemoved(_authorized);
	}

	// Modifiers

	modifier onlyOwner() {
		if (msg.sender != owner) revert Unauthorized();
		_;
	}

	modifier onlyAdmins() {
		if (msg.sender != owner && msg.sender != admin) revert Unauthorized();
		_;
	}

	modifier onlyAuthorized() {
		if (msg.sender != owner && msg.sender != admin && !authorized[msg.sender]) revert Unauthorized();
		_;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

abstract contract BlockDelay {
	/// @notice delay before functions with 'useBlockDelay' can be called by the same address
	/// @dev 0 means no delay
	uint256 public blockDelay;
	uint256 internal constant MAX_BLOCK_DELAY = 10;

	mapping(address => uint256) public lastBlock;

	error AboveMaxBlockDelay();
	error BeforeBlockDelay();

	constructor(uint8 _delay) {
		_setBlockDelay(_delay);
	}

	function _setBlockDelay(uint8 _newDelay) internal {
		if (_newDelay > MAX_BLOCK_DELAY) revert AboveMaxBlockDelay();
		blockDelay = _newDelay;
	}

	modifier useBlockDelay(address _address) {
		if (block.number < lastBlock[_address] + blockDelay) revert BeforeBlockDelay();
		lastBlock[_address] = block.number;
		_;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import 'solmate/tokens/ERC20.sol';

/// @notice https://eips.ethereum.org/EIPS/eip-4626
interface IERC4626 {
	event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

	event Withdraw(
		address indexed caller,
		address indexed receiver,
		address indexed owner,
		uint256 assets,
		uint256 shares
	);

	function asset() external view returns (ERC20);

	function totalAssets() external view returns (uint256 assets);

	function convertToShares(uint256 assets) external view returns (uint256 shares);

	function convertToAssets(uint256 shares) external view returns (uint256 assets);

	function maxDeposit(address receiver) external view returns (uint256 assets);

	function previewDeposit(uint256 assets) external view returns (uint256 shares);

	function deposit(uint256 assets, address receiver) external returns (uint256 shares);

	function maxMint(address receiver) external view returns (uint256 shares);

	function previewMint(uint256 shares) external view returns (uint256 assets);

	function mint(uint256 shares, address receiver) external returns (uint256 assets);

	function maxWithdraw(address owner) external view returns (uint256 assets);

	function previewWithdraw(uint256 assets) external view returns (uint256 shares);

	function withdraw(
		uint256 assets,
		address receiver,
		address owner
	) external returns (uint256 shares);

	function maxRedeem(address owner) external view returns (uint256 shares);

	function previewRedeem(uint256 shares) external view returns (uint256 assets);

	function redeem(
		uint256 shares,
		address receiver,
		address owner
	) external returns (uint256 assets);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import './Vault.sol';

/** @dev
 * Strategies have to implement the following virtual functions:
 *
 * totalAssets()
 * _withdraw(uint256, address)
 * _harvest()
 * _invest()
 */
abstract contract Strategy is Ownership {
	using FixedPointMathLib for uint256;

	Vault public immutable vault;
	ERC20 public immutable asset;

	/// @notice address which performance fees are sent to
	address public treasury;
	/// @notice performance fee sent to treasury / FEE_BASIS of 10_000
	uint16 public fee = 1_000;
	uint16 internal constant MAX_FEE = 1_000;
	uint16 internal constant FEE_BASIS = 10_000;

	/// @notice used to calculate slippage / SLIP_BASIS of 10_000
	/// @dev default to 99% (or 1%)
	uint16 public slip = 9_900;
	uint16 internal constant SLIP_BASIS = 10_000;

	/*//////////////////
	/      Events      /
	//////////////////*/

	event FeeChanged(uint16 newFee);
	event SlipChanged(uint16 newSlip);
	event TreasuryChanged(address indexed newTreasury);

	/*//////////////////
	/      Errors      /
	//////////////////*/

	error Zero();
	error NotVault();
	error InvalidValue();
	error AlreadyValue();

	constructor(
		Vault _vault,
		address _treasury,
		address[] memory _authorized
	) Ownership(_authorized) {
		vault = _vault;
		asset = vault.asset();
		treasury = _treasury;
	}

	/*//////////////////////////
	/      Public Virtual      /
	//////////////////////////*/

	/// @notice amount of 'asset' currently managed by strategy
	function totalAssets() public view virtual returns (uint256);

	/*///////////////////////////////////////////
	/      Restricted Functions: onlyVault      /
	///////////////////////////////////////////*/

	function withdraw(uint256 _assets, address _receiver)
		external
		onlyVault
		returns (uint256 received, uint256 slippage)
	{
		received = _withdraw(_assets, _receiver);
		received = received > _assets ? _assets : received; // received cannot > _assets for vault calculations

		unchecked {
			slippage = _assets - received;
		}
	}

	function harvest() external onlyVault {
		_harvest();
	}

	function invest() external onlyVault {
		_invest();
	}

	/*///////////////////////////////////////////
	/      Restricted Functions: onlyOwner      /
	///////////////////////////////////////////*/

	function setFee(uint16 _fee) external onlyOwner {
		if (_fee > MAX_FEE) revert InvalidValue();
		if (_fee == fee) revert AlreadyValue();
		fee = _fee;
		emit FeeChanged(_fee);
	}

	function setTreasury(address _treasury) external onlyOwner {
		if (_treasury == treasury) revert AlreadyValue();
		treasury = _treasury;
		emit TreasuryChanged(_treasury);
	}

	/*////////////////////////////////////////////
	/      Restricted Functions: onlyAdmins      /
	////////////////////////////////////////////*/

	function setSlip(uint16 _slip) external onlyAdmins {
		if (_slip > SLIP_BASIS) revert InvalidValue();
		if (_slip == slip) revert AlreadyValue();
		slip = _slip;
		emit SlipChanged(_slip);
	}

	function adminHarvest() external onlyAdmins {
		_harvest();
	}

	/*////////////////////////////
	/      Internal Virtual      /
	////////////////////////////*/

	/// @dev this must handle overflow, i.e. vault trying to withdraw more than what strategy has
	function _withdraw(uint256 _assets, address _receiver) internal virtual returns (uint256 received);

	function _harvest() internal virtual;

	function _invest() internal virtual;

	/*//////////////////////////////
	/      Internal Functions      /
	//////////////////////////////*/

	function _calculateSlippage(uint256 _amount) internal view returns (uint256) {
		return _amount.mulDivDown(slip, SLIP_BASIS);
	}

	function _calculateFee(uint256 _amount) internal view returns (uint256) {
		return _amount.mulDivDown(fee, FEE_BASIS);
	}

	modifier onlyVault() {
		if (msg.sender != address(vault)) revert NotVault();
		_;
	}
}
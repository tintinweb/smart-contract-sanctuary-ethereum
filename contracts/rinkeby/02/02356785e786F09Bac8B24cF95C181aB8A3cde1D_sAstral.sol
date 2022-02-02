// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.7.5;

import "./libraries/Address.sol";
import "./libraries/SafeMath.sol";

import "./types/ERC20Permit.sol";

import "./interfaces/IgSTRL.sol";
import "./interfaces/IsSTRL.sol";
import "./interfaces/IStaking.sol";

contract sAstral is IsSTRL, ERC20Permit {
	// PLEASE READ BEFORE CHANGING ANY ACCOUNTING OR MATH
	// Anytime there is division, there is a risk of numerical instability from rounding errors.
	// In order to minimize this risk, we adhere to the following  guidelines:
	// 1) The conversion rate adopted is the number of gons that equals 1 fragment.
	//    The inverse rate must not be used--TOTAL_GONS is always the numerator and _totalSupply is
	//    always the denominator. (i.e. If you want to convert gons to fragments instead of
	//    multiplying by the inverse rate, you should divide by the normal rate)
	// 2) Gon balances converted into Fragments are always rounded down (truncted).
	//
	// We make the following guarantees:
	// - If address 'A' transfers x Fragments to address 'B'. A's resulting external balance will
	//   be decreased by precisely x Fragments, and B's external balance will be precisely
	//   increased by x Fragments.
	//
	// We do not guarantee that the sum of all balances equals the result of calling totalSupply().
	// This is because, for any conversion function 'f()' that has non-zero rounding error,
	// f(x0) + f(x1) + ... + f(xn) is not always equal to f(x0 + x1 + ... + xn).

	using SafeMath for uint256;

	address public stakingContract; // balance used to calc rebase

	modifier onlyStakingContract() {
		require(msg.sender == stakingContract, "sSTRL: only for staking contract");
		_;
	}

	address internal initializer;

	uint256 internal INDEX; // Index Gons - track rebase growth

	IgSTRL public gSTRL; // additional staked supply (governance/bridge token)

	Rebase[] public rebases; // past rebase data

	uint256 private constant MAX_UINT256 = type(uint256).max;
	uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 5 * 10**15; // 5*10^6 (amount) * 10^9 (decimals)

	// TOTAL_GONS is a multiple of INITIAL_FRAGMENTS_SUPPLY so that _gonsPerFragment
	// is an integer. Use the highest value that fits in a uint256 for max granularity.
	uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

	// MAX_SUPPLY = maximum integer < (sqrt(4*TOTAL_GONS + 1) - 1) / 2
	uint256 private constant MAX_SUPPLY = type(uint128).max; // (2^128)-1

	uint256 private _gonsPerFragment;
	mapping(address => uint256) private _gonBalances;

	// This is denominated, because the gons-fragments conversion might change before
	// it's fully paid.
	mapping(address => mapping(address => uint256)) private _allowedValue;

	address public treasury;
	mapping(address => uint256) public override debtBalances;

	constructor() ERC20("Staked eGHST", "sGHST", 9) 
	ERC20Permit("Staked eGHST") 
	{
		initializer = msg.sender;
		_totalSupply = INITIAL_FRAGMENTS_SUPPLY;
		_gonsPerFragment = TOTAL_GONS.div(_totalSupply);
	}

	function setIndex(uint256 _index) external {
		require(msg.sender == initializer, "sSTRL: only from initializer");
		require(INDEX == 0, "sSTRL: index already set");
		INDEX = gonsForBalance(_index);
	}

	function setgSTRL(address _gSTRL) external {
		require(msg.sender == initializer, "sSTRL: only from initializer");
		require(address(gSTRL) == address(0), "sSTRL: gSTRL address already set");
		require(_gSTRL != address(0), "sSTRL: gSTRL is not a valid contract");
		gSTRL = IgSTRL(_gSTRL);
	}

	// do this last
	function initialize(address _stakingContract, address _treasury) external {
		require(msg.sender == initializer, "sSTRL: only from initializer");
		require(_stakingContract != address(0), "sSTRL: Staking is not a valid contract");

		stakingContract = _stakingContract;
		_gonBalances[_stakingContract] = TOTAL_GONS;

		require(_treasury != address(0), "sSTRL: Treasury is not a valid contract");
		treasury = _treasury;

		emit Transfer(address(0x0), _stakingContract, _totalSupply);
		emit LogStakingContractUpdated(_stakingContract);

		initializer = address(0);
	}

	function scaledTotalSupply() external pure override returns (uint256) {
		return TOTAL_GONS;
	}

	/**
	 * @dev Notifies contract about a new rebase cycle.
	 * @param profit_ The number of new tokens to add into circulation via expansion.
	 * @return The total number of sSTRL after the supply adjustment. 
	 */
	function rebase(uint256 profit_, uint256 epoch_)
		public
	   	override
	   	onlyStakingContract
	   	returns (uint256)
	{
		uint256 rebaseAmount;
		uint256 circulatingSupply_ = circulatingSupply();

		if (profit_ == 0) {
			emit LogRebase(epoch_, _totalSupply, 0, index());
			return _totalSupply;
		} else if (circulatingSupply_ > 0) {
			rebaseAmount = profit_.mul(_totalSupply).div(circulatingSupply_);
		} else {
			rebaseAmount = profit_;
		}

		_totalSupply = _totalSupply.add(rebaseAmount);

		if (_totalSupply > MAX_SUPPLY) {
			_totalSupply = MAX_SUPPLY;
		}

		_gonsPerFragment = TOTAL_GONS.div(_totalSupply);

		_storeRebase(circulatingSupply_, profit_, epoch_);

		// From this point forward, _gonsPerFragment is taken as the source of truth.
		// We recalculate a new _totalSupply to be in agreement with the _gonsPerFragment
		// conversion rate.
		//
		// This means our applied profit can deviate from the requested profit,
		// but this deviation is guaranteed to be < (_totalSupply^2)/(TOTAL_GONS - _totalSupply).
		//
		// In the case of _totalSupply <= MAX_UINT128 (our current supply cap), this deviation is 
		// guaranteed to be < 1, so we can omit this step. If the supply cap is ever increased, 
		// it must be re-included.
		// _totalSupply = TOTAL_GONS.div(_gonsPerFragment)

		return _totalSupply;
	}

	function _storeRebase(
		uint256 previousCirculating_,
		uint256 profit_,
		uint256 epoch_
	) internal {
		uint256 rebasePercent = profit_.mul(1e18).div(previousCirculating_);
		rebases.push(
			Rebase({
				epoch: epoch_,
				rebase: rebasePercent, // 18 decimals
				totalStakedBefore: previousCirculating_,
				totalStakedAfter: circulatingSupply(),
				amountRebased: profit_,
				index: index(),
				blockNumberOccured: block.number
			})
		);

		emit LogRebase(epoch_, _totalSupply, rebasePercent, index());
	}

	function transfer(
		address to, 
		uint256 value
	) public override(IERC20, ERC20) returns (bool) {
		uint256 gonValue = gonsForBalance(value);

		_gonBalances[msg.sender] = _gonBalances[msg.sender].sub(gonValue);
		_gonBalances[to] = _gonBalances[to].add(gonValue);

		_checkDebt(msg.sender);
		emit Transfer(msg.sender, to, value);
		return true;
	}

	function transferFrom(
		address from,
		address to,
		uint256 value
	) public override(IERC20, ERC20) returns (bool) {
		_allowedValue[from][msg.sender] = _allowedValue[from][msg.sender].sub(value);
		emit Approval(from, msg.sender, _allowedValue[from][msg.sender]);

		uint256 gonValue = gonsForBalance(value);
		_gonBalances[from] = _gonBalances[from].sub(gonValue);
		_gonBalances[to] = _gonBalances[to].add(gonValue);

		_checkDebt(from);
		emit Transfer(msg.sender, to, value);
		return true;
	}

	function approve(address spender, uint256 value) public override(IERC20, ERC20) returns (bool) {
		_approve(msg.sender, spender, value);
		return true;
	}

	function increaseAllowance(address spender, uint256 value) public override returns (bool) {
		_approve(msg.sender, spender, _allowedValue[msg.sender][spender].add(value));
		return true;
	}

	function decreaseAllowance(address spender, uint256 value) public override returns (bool) {
		uint256 oldValue = _allowedValue[msg.sender][spender];
		uint256 amount = (value >= oldValue) ? 0 : oldValue.sub(value);
		_approve(msg.sender, spender, amount);
		return true;
	}

	// this function is called by the treasury, and informs sSTRL of changes to debt.
	// note that addresses with debt balances cannot transfer collateralized sSTRL
	// until the debt has been repaid.
	function changeDebt(
		uint256 amount,
		address debtor,
		bool add
	) external override {
		require(msg.sender == treasury, "sSTRL: only Treasury");
		debtBalances[debtor] = add ? debtBalances[debtor].add(amount) : debtBalances[debtor].sub(amount);
		_checkDebt(debtor);
	}

	function _checkDebt(address from) internal view {
		require(balanceOf(from) >= debtBalances[from], "sSTRL: cannot transfer amount");
	}

	function _approve(
		address owner,
		address spender,
		uint256 value
	) internal virtual override {
		_allowedValue[owner][spender] = value;
		emit Approval(owner, spender, value);
	}

	function balanceOf(address account) public view override(IERC20, ERC20) returns (uint256) {
		return _gonBalances[account].div(_gonsPerFragment);
	}

	function scaledBalanceOf(address account) external view override returns (uint256) {
		return _gonBalances[account];
	}

	function gonsForBalance(uint256 amount) public view override returns (uint256) {
		return amount.mul(_gonsPerFragment);
	}

	function balanceForGons(uint256 gons) public view override returns (uint256) {
		return gons.div(_gonsPerFragment);
	}

	// toG converts an sSTRL balance to gSTRL terms. gSTRL is an 18 decimal token.
	// balance given is in 18 decimals format.
	function toG(uint256 amount) external view override returns (uint256) {
		return gSTRL.balanceTo(amount);
	}

	// fromG converts a gSTRL balance to sSTRL terms. sSTRL is a 9 decimals token.
	// balance given is in 9 decimals format.
	function fromG(uint256 amount) external view override returns (uint256) {
		return gSTRL.balanceFrom(amount);
	}

	// staking contract holds excess sSTRL
	function circulatingSupply() public view override returns (uint256) {
		return 
			_totalSupply.sub(balanceOf(stakingContract))
				.add(gSTRL.balanceFrom(IERC20(address(gSTRL)).totalSupply()))
				.add(IStaking(stakingContract).supplyInWarmup());
	}

	function index() public view override returns (uint256) {
		return balanceForGons(INDEX);
	}

	function allowance(address owner, address spender) public view override(IERC20, ERC20) returns (uint256) {
		return _allowedValue[owner][spender];
	}	
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;

import "../interfaces/IERC20Permit.sol";
import "./ERC20.sol";
import "../cryptography/EIP712.sol";
import "../cryptography/ECDSA.sol";
import "../libraries/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be 
 * made via signatures, as defined in 
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 
 * allowance (see {IERC20-allowance}) by presenting a message signed by the account.
 * By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
	using Counters for Counters.Counter;

	mapping(address => Counters.Counter) private _nonces;

	// solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

	/**
	 * @dev Initializes the {ERIP712} domain separator using the `name` parameter,
	 * and setting `version` to `"1"`.
	 *
	 * It's a good idea to use the same `name` that is defined as the ERC20 token name.
	 */
	constructor (string memory name) EIP712(name, "1") {}

	/**
	 * @dev See {IERC20Permit-permit}.
	 */
	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public virtual override {
		require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

		bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

		bytes32 hash = _hashTypedDataV4(structHash);

		address signer = ECDSA.recover(hash, v, r, s);
		require(signer == owner, "ERC20Permit: invalid signature");

		_approve(owner, spender, value);
	}

	/**
	 * @dev See {IERC20Permit-nonces}.
	 */
	function nonces(address owner) public view virtual override returns (uint256) {
		return _nonces[owner].current();
	}

	/**
	 * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
	 */
	// solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

	/**
	 * @dev "Consume a nonce": return the current value and increment.
	 */
	function _useNonce(address owner) internal virtual returns (uint256 current) {
		Counters.Counter storage nonce = _nonces[owner];
		current = nonce.current();
		nonce.increment();
	}
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.5;

import "../libraries/SafeMath.sol";
import "../interfaces/IERC20.sol";

abstract contract ERC20 is IERC20 {
	using SafeMath for uint256;

	mapping(address => uint256) internal _balances;

	mapping(address => mapping(address => uint256)) internal _allowances;

	uint256 internal _totalSupply;

	string internal _name;

	string internal _symbol;

	uint8 internal immutable _decimals;

	constructor (string memory name_, string memory symbol_, uint8 decimals_) {
		_name = name_;
		_symbol = symbol_;
		_decimals = decimals_;
	}

	function name() public view returns (string memory) {
		return _name;
	}

	function symbol() public view returns (string memory) {
		return _symbol;
	}

	function decimals() public view virtual returns (uint8) {
		return _decimals;
	}

	function totalSupply() public view virtual override returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address account) public view virtual override returns (uint256) {
		return _balances[account];
	}

	function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
		_transfer(msg.sender, recipient, amount);
		return true;
	}

	function allowance(address owner, address spender) public view virtual override returns (uint256) {
		return _allowances[owner][spender];
	}

	function approve(address spender, uint256 amount) public virtual override returns (bool) {
		_approve(msg.sender, spender, amount);
		return true;
	}

	function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allownace"));
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		_approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
		return true;
	}

	function decreaseAllowance(address spender, uint256 substractedValue) public virtual returns (bool) {
		_approve(msg.sender, spender, _allowances[msg.sender][spender].sub(substractedValue, "ERC20: decreased allowance below zero"));
		return true;
	}

	function _transfer(address sender, address recipient, uint256 amount) internal virtual {
		require(sender != address(0), "ERC20: transfer from the zero address");
		require(recipient != address(0), "ERC20: transfer to the zero address");

		_beforeTokenTransfer(sender, recipient, amount);

		_balances[sender] = _balances[sender].sub(amount, "ERC20: tranfer amount exceeds balance");
		_balances[recipient] = _balances[recipient].add(amount);
		
		emit Transfer(sender, recipient, amount);
	}

	function _mint(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: mint to the zero address");

		_beforeTokenTransfer(address(0), account, amount);

		_totalSupply = _totalSupply.add(amount);
		_balances[account] = _balances[account].add(amount);

		emit Transfer(address(0), account, amount);
	}

	function _burn(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: burn from the zero address");

		_beforeTokenTransfer(account, address(0), amount);

		_balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
		_totalSupply = _totalSupply.sub(amount);

		emit Transfer(account, address(0), amount);
	}

	function _approve(address owner, address spender, uint256 amount) internal virtual {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");

		_allowances[owner][spender] = amount;

		emit Approval(owner, spender, amount);
	}

	function _beforeTokenTransfer( address from_, address to_, uint256 amount_ ) internal virtual { }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.7.5;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

	function average(uint256 a, uint256 b) internal pure returns (uint256) {
		return div(add((a & b), (a ^ b)), 2);
	}

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b != 0);
		return a % b;
	}
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.7.5;

import "./SafeMath.sol";

library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: AGPL-3.0
//
pragma solidity ^0.7.5;

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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    // function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
    //     require(address(this).balance >= value, "Address: insufficient balance for call");
    //     return _functionCallWithValue(target, data, value, errorMessage);
    // }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function addressToString(address _address) internal pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _addr = new bytes(42);

        _addr[0] = '0';
        _addr[1] = 'x';

        for(uint256 i = 0; i < 20; i++) {
            _addr[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _addr[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }

        return string(_addr);

    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.7.5;

import "./IERC20.sol";

interface IsSTRL is IERC20 {
	event LogRebase(uint256 indexed epoch, uint256 totalSupply, uint256 rebase, uint256 index);
    event LogStakingContractUpdated(address stakingContract);

	struct Rebase {
        uint256 epoch;
        uint256 rebase; // 18 decimals
        uint256 totalStakedBefore;
        uint256 totalStakedAfter;
        uint256 amountRebased;
        uint256 index;
        uint256 blockNumberOccured;
    }

	function scaledTotalSupply() external pure returns (uint256);

    function rebase( uint256 ohmProfit_, uint epoch_) external returns (uint256);

    function circulatingSupply() external view returns (uint256);

	function scaledBalanceOf( address account ) external view returns (uint256);

    function gonsForBalance( uint amount ) external view returns ( uint );

    function balanceForGons( uint gons ) external view returns ( uint );

    function toG(uint amount) external view returns (uint);

    function fromG(uint amount) external view returns (uint);

    function index() external view returns ( uint );

     function changeDebt(
        uint256 amount,
        address debtor,
        bool add
    ) external;

    function debtBalances(address _address) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.7.5;

import "./IERC20.sol";

interface IgSTRL is IERC20 {
	function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function index() external view returns (uint256);

    function balanceFrom(uint256 _amount) external view returns (uint256);

    function balanceTo(uint256 _amount) external view returns (uint256);

    function migrate(address _staking, address _sOHM) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.7.5;

interface IStaking {
    function stake(
        address _to,
        uint256 _amount,
        bool _rebasing,
        bool _claim
    ) external returns (uint256);

    function claim(address _recipient, bool _rebasing) external returns (uint256);

    function forfeit() external returns (uint256);

    function toggleLock() external;

    function unstake(
        address _to,
        uint256 _amount,
        bool _trigger,
        bool _rebasing
    ) external returns (uint256);

    function wrap(address _to, uint256 _amount) external returns (uint256 gBalance_);

    function unwrap(address _to, uint256 _amount) external returns (uint256 sBalance_);

    function rebase() external;

    function index() external view returns (uint256);

    function contractBalance() external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function supplyInWarmup() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via 
 * signatures, as defined in 
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 
 * allowance (see {IERC20-allowance}) by presenting a message signed by 
 * the account. By not relying on {IERC20-approve), the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
	/**
	 * @dev Sets `value` as th xe allowance of `spender` over ``owner``'s tokens,
	 * given ``owner``s signed approval.
	 *
	 * IMPORTANT: The same issues {IERC20-approve} has related to transaction
	 * ordering also apply here.
	 *
	 * Emits an {Approval} event.
	 *
	 * Requirements:
	 *
	 * - `spender` cannot be the zero address.
	 * - `deadline` must be a timestamp in the future.
	 * - `v`, `r` and `s` must be valid `secp256k1` signatures from `owner` 
	 * over the EIP712-formatted function arguments.
	 * - the signatures must use ``owner``'s current nonce (see {nonces}).
	 *
	 * For more information on the signature format, see the
	 * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP section].
	 */
	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	/**
	 * @dev Returns the current nonce for `owner`. This value must be
	 * included whenever a signature is generated for {permit}.
	 *
	 * Every successful call to {permit} increase ``owner``'s nonce by one. This
	 * prevents a signature from being used multiple times.
	 */
	function nonces(address owner) external view returns (uint256);

	/**
	 * @dev Returns the domain separatorused in the encoding of the signature for
	 * {permit}, as defined by {EIP712}.
	 */
	// solhint-disable-next-line func-name-mixedcase
	function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;

interface IERC20 {
	/**
	 * @dev Returns the amount of tokens in existance.
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
	 * condition is to first reduce the spender's allowanceto 0 and set the 
	 * desired value afterwards:
	 * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
	 *
	 * Emits an {Approval} event.
	 */
	function approve(address spender, uint256 amount) external returns (bool);

	/**
	 * @dev Moves `amount` tokens from `spender` to `recipient` using the 
	 * allowance mechanism. `amount` is then deducated from the caller's 
	 * allowance.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits a {Transfer} event.
	 */
	function transferFrom(address spender, address recipient, uint256 amount) external returns (bool);

	/**
	 * @dev Emitted when `value` tokens are moved from one account (`from`) to
	 * another (`to`).
	 *
	 * Note that `value` may be zero.
	 */
	event Transfer(address indexed, address indexed to, uint256 value);

	/**
	 * @dev Emitted when the allowance of `spender` for an `owner` is set by
	 * a call to {approve}. `value` is the allowance.
	 */
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;

import "./ECDSA.sol";

abstract contract EIP712 {
	/* solhint-disable var-name-mixedcase */
	// Cache the domain separator as an immutable value, but also the chain id that it corresponds to,
	// in order to invalidate the cached domain separator if the chain id changes.
	bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
	uint256 private immutable _CACHED_CHAIN_ID;

	bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

	/* solhint-enable var-name-mixedcase */

	/**
	 * @dev Initializes the domain separator and parameter caches.
	 *
	 * The meaning of `name` and `version` is specified in
	 * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
	 *
	 * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
	 * - `version`: the current major version of the signing domain.
	 *
	 * Note: These parameters cannot be changed except through a 
	 * xref:learn::upgrading-smart-contracts.adoc[smart contract upgrade].
	 */
	constructor(string memory name, string memory version) {
		uint256 chainId;
		assembly {
			chainId := chainid()
		}

		bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = chainId;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
	}

	/**
	 * @dev Returns the domain separator for the current chain.
	 */
	 function _domainSeparatorV4() internal view returns (bytes32) {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        if (chainID == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

	function _buildDomainSeparator(
		bytes32 typeHash,
		bytes32 nameHash,
		bytes32 versionHash
	) private view returns (bytes32) {
		uint256 chainId;
		assembly {
			chainId := chainid()
		}

		return keccak256(abi.encode(typeHash, nameHash, versionHash, chainId, address(this)));
	}

	/**
	 * @dev Given an already 
	 * https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
	 * function returns the hash of the fully encoded EIP712 message for this domain.
	 *
	 * This hash can be ised together with {ECDSA-recover} to obtain the signer of a message.
	 * For example:
	 *
	 * ```solidity
	 * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
	 * 		keccak256("Mail(address to, string contents)"),
	 * 		mailTo,
	 * 		keccak256(bytes(mailContents))
	 * )));
	 * address signer = ECDSA.recover(digest, signature);
	 * ```
	 */
	function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
		return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
	enum RecoverError {
		NoError,
		InvalidSignature,
		InvalidSignatureLength,
		InvalidSignatureS,
		InvalidSignatureV
	}

	function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

	/**
	 * @dev Returns the address thath signed a hashed message (`hash`) with
	 * `signature` or error string. This address can then be used for verification purposes.
	 *
	 * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
	 * this function rejects them by requiring the `s` value to be in the lower
	 * half order, and the `v` value to be either 27 or 28.
	 *
	 * IMPORTANT: `hash` _must_ be the result of a hash operation for the 
	 * verification to be secure: it is possible to craft signatures that recover to arbitrary
	 * addresses for non-hashed data. A safe way to ensure this is by receiving a hash of the original
	 * message (which otherwise be too long), and then calling {toEthSignedMessageHash} on it.
	 *
	 * Documentation for signatures generation:
	 * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
	 */
	function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature 
	 * fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility
		// and make the signature unique. Appendix F in the Ethereum Yellow paper 
		// (https://ethereum.github.io/yellowpaper/paper.pdf), defines the valid range for s in 
		// (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most signatures 
		// from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, 
		// calculate a new s-value
		// with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v 
		// from 27 to 28 or vice versa. If your library also generates signatures with 0/1 for v 
		// instead 27/28, add 27 to v to accept these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}
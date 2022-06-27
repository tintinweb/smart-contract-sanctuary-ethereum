// SPDX-License-Identifier: MIT
// Copied and adjusted from OpenZeppelin
// Adjustments:
// - modifications to support ERC-677
// - removed unnecessary require statements
// - removed GSN Context
// - upgraded to 0.8 to drop SafeMath
// - let name() and symbol() be implemented by subclass
// - infinite allowance support, with 2^255 and above considered infinite
// - use upper 32 bits of balance for flags
// - add a global settings variable

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC677Receiver.sol";

/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */

abstract contract ERC20Flaggable is IERC20 {

    // as Documented in /doc/infiniteallowance.md
    // 0x8000000000000000000000000000000000000000000000000000000000000000
    uint256 constant private INFINITE_ALLOWANCE = 2**255;

    uint256 private constant FLAGGING_MASK = 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000;

    // Documentation of flags used by subclasses:
    // NOTE: flags denote the bit number that is being used and must be smaller than 32
    // ERC20Draggable: uint8 private constant FLAG_INDEX_VOTED = 1;
    // ERC20Recoverable: uint8 private constant FLAG_INDEX_CLAIM_PRESENT = 10;
    // ERCAllowlistable: uint8 private constant FLAG_INDEX_ALLOWLIST = 20;
    // ERCAllowlistable: uint8 private constant FLAG_INDEX_FORBIDDEN = 21;
    // ERCAllowlistable: uint8 private constant FLAG_INDEX_POWERLIST = 22;

    mapping (address => uint256) private _balances; // upper 32 bits reserved for flags

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    uint8 public override decimals;

    event NameChanged(string name, string symbol);

    constructor(uint8 _decimals) {
        decimals = _decimals;
    }

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return uint224 (_balances [account]);
    }

    function hasFlag(address account, uint8 number) external view returns (bool) {
        return hasFlagInternal(account, number);
    }

    function setFlag(address account, uint8 index, bool value) internal {
        uint256 flagMask = 1 << (index + 224);
        uint256 balance = _balances [account];
        if ((balance & flagMask == flagMask) != value) {
            _balances [account] = balance ^ flagMask;
        }
    }

    function hasFlagInternal(address account, uint8 number) internal view returns (bool) {
        uint256 flag = 0x1 << (number + 224);
        return _balances[account] & flag == flag;
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        if (currentAllowance < INFINITE_ALLOWANCE){
            // Only decrease the allowance if it was not set to 'infinite'
            // Documented in /doc/infiniteallowance.md
            _allowances[sender][msg.sender] = currentAllowance - amount;
        }
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        _beforeTokenTransfer(sender, recipient, amount);
        decreaseBalance(sender, amount);
        increaseBalance(recipient, amount);
        emit Transfer(sender, recipient, amount);
    }

    // ERC-677 functionality, can be useful for swapping and wrapping tokens
    function transferAndCall(address recipient, uint amount, bytes calldata data) external virtual returns (bool) {
        return transfer (recipient, amount) 
            && IERC677Receiver (recipient).onTokenTransfer (msg.sender, amount, data);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address recipient, uint256 amount) internal virtual {
        _beforeTokenTransfer(address(0), recipient, amount);
        _totalSupply += amount;
        increaseBalance(recipient, amount);
        emit Transfer(address(0), recipient, amount);
    }

    function increaseBalance(address recipient, uint256 amount) private {
        require(recipient != address(0x0), "0x0"); // use burn instead
        uint256 oldBalance = _balances[recipient];
        uint256 newBalance = oldBalance + amount;
        require(oldBalance & FLAGGING_MASK == newBalance & FLAGGING_MASK, "overflow");
        _balances[recipient] = newBalance;
    }

     /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        _beforeTokenTransfer(account, address(0), amount);

        _totalSupply -= amount;
        decreaseBalance(account, amount);
        emit Transfer(account, address(0), amount);
    }

    function decreaseBalance(address sender, uint256 amount) private {
        uint256 oldBalance = _balances[sender];
        uint256 newBalance = oldBalance - amount;
        require(oldBalance & FLAGGING_MASK == newBalance & FLAGGING_MASK, "underflow");
        _balances[sender] = newBalance;
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
     // solhint-disable-next-line no-empty-blocks
    function _beforeTokenTransfer(address from, address to, uint256 amount) virtual internal {
        // intentionally left blank
    }

}

/**
* SPDX-License-Identifier: MIT
*
* Copyright (c) 2016-2019 zOS Global Limited
*
*/
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */

interface IERC20 {

    // Optional functions
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC677Receiver {
    
    function onTokenTransfer(address from, uint256 amount, bytes calldata data) external returns (bool);

}

/**
 * SPDX-License-Identifier: LicenseRef-Aktionariat
 *
 * MIT License with Automated License Fee Payments
 *
 * Copyright (c) 2020 Aktionariat AG (aktionariat.com)
 *
 * Permission is hereby granted to any person obtaining a copy of this software
 * and associated documentation files (the "Software"), to deal in the Software
 * without restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies of the
 * Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * - The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * - All automated license fee payments integrated into this and related Software
 *   are preserved.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
pragma solidity ^0.8.0;

/**
 * @title ERC-20 tokens subject to a drag-along agreement
 * @author Luzius Meisser, [email protected]
 *
 * This is an ERC-20 token that is bound to a shareholder or other agreement that contains
 * a drag-along clause. The smart contract can help enforce this drag-along clause in case
 * an acquirer makes an offer using the provided functionality. If a large enough quorum of
 * token holders agree, the remaining token holders can be automatically "dragged along" or
 * squeezed out. For shares non-tokenized shares, the contract relies on an external Oracle
 * to provide the votes of those.
 *
 * Subclasses should provide a link to a human-readable form of the agreement.
 */

import "./IDraggable.sol";
import "../ERC20/ERC20Flaggable.sol";
import "../ERC20/IERC20.sol";
import "../ERC20/IERC677Receiver.sol";
import "./IOffer.sol";
import "./IOfferFactory.sol";
import "../shares/IShares.sol";

abstract contract ERC20Draggable is IERC677Receiver, IDraggable, ERC20Flaggable {
    
	// If flag is not present, one can be sure that the address did not vote. If the 
	// flag is present, the address might have voted and one needs to check with the
	// current offer (if any) when transferring tokens.
	uint8 private constant FLAG_VOTE_HINT = 1;

	IERC20 public wrapped; // The wrapped contract
	IOfferFactory public immutable factory;

	// If the wrapped tokens got replaced in an acquisition, unwrapping might yield many currency tokens
	uint256 public unwrapConversionFactor = 0;

	// The current acquisition attempt, if any. See initiateAcquisition to see the requirements to make a public offer.
	IOffer public offer;

	uint256 private constant QUORUM_MULTIPLIER = 10000;

	uint256 public immutable quorum; // BPS (out of 10'000)
	uint256 public immutable votePeriod; // In seconds

	address public override oracle;

	event MigrationSucceeded(address newContractAddress, uint256 yesVotes, uint256 oracleVotes, uint256 totalVotingPower);
	event ChangeOracle(address oracle);

    /**
	 * Note that the Brokerbot only supports tokens that revert on failure and where transfer never returns false.
     */
	constructor(
		IERC20 _wrappedToken,
		uint256 _quorum,
		uint256 _votePeriod,
		IOfferFactory _offerFactory,
		address _oracle
	) 
		ERC20Flaggable(0)
	{
		wrapped = _wrappedToken;
		quorum = _quorum;
		votePeriod = _votePeriod;
		factory = _offerFactory;
		oracle = _oracle;
	}

	function onTokenTransfer(
		address from, 
		uint256 amount, 
		bytes calldata
	) external override returns (bool) {
		require(msg.sender == address(wrapped), "sender");
		_mint(from, amount);
		return true;
	}

	/** Wraps additional tokens, thereby creating more ERC20Draggable tokens. */
	function wrap(address shareholder, uint256 amount) external {
		require(wrapped.transferFrom(msg.sender, address(this), amount), "transfer");
		_mint(shareholder, amount);
	}

	/**
	 * Indicates that the token holders are bound to the token terms and that:
	 * - Conversion back to the wrapped token (unwrap) is not allowed
	 * - A drag-along can be performed by making an according offer
	 * - They can be migrated to a new version of this contract in accordance with the terms
	 */
	function isBinding() public view returns (bool) {
		return unwrapConversionFactor == 0;
	}

    /**
	 * Current recommended naming convention is to add the postfix "SHA" to the plain shares
	 * in order to indicate that this token represents shares bound to a shareholder agreement.
	 */
	function name() public view override returns (string memory) {
		string memory wrappedName = wrapped.name();
		if (isBinding()) {
			return string(abi.encodePacked(wrappedName, " SHA"));
		} else {
			return string(abi.encodePacked(wrappedName, " (Wrapped)"));
		}
	}

	function symbol() public view override returns (string memory) {
		// ticker should be less dynamic than name
		return string(abi.encodePacked(wrapped.symbol(), "S"));
	}

	/**
	 * Deactivates the drag-along mechanism and enables the unwrap function.
	 */
	function deactivate(uint256 factor) internal {
		require(factor >= 1, "factor");
		unwrapConversionFactor = factor;
		emit NameChanged(name(), symbol());
	}

	/** Decrease the number of drag-along tokens. The user gets back their shares in return */
	function unwrap(uint256 amount) external {
		require(!isBinding(), "factor");
		unwrap(msg.sender, amount, unwrapConversionFactor);
	}

	function unwrap(address owner, uint256 amount, uint256 factor) internal {
		_burn(owner, amount);
		require(wrapped.transfer(owner, amount * factor), "transfer");
	}

	/**
	 * Burns both the token itself as well as the wrapped token!
	 * If you want to get out of the shareholder agreement, use unwrap after it has been
	 * deactivated by a majority vote or acquisition.
	 *
	 * Burning only works if wrapped token supports burning. Also, the exact meaning of this
	 * operation might depend on the circumstances. Burning and reussing the wrapped token
	 * does not free the sender from the legal obligations of the shareholder agreement.
	 */
	function burn(uint256 amount) external {
		_burn(msg.sender, amount);
		IShares(address(wrapped)).burn (isBinding() ? amount : amount * unwrapConversionFactor);
	}

	function makeAcquisitionOffer(
		bytes32 salt, 
		uint256 pricePerShare, 
		IERC20 currency
	) external payable {
		require(isBinding(), "factor");
		IOffer newOffer = factory.create{value: msg.value}(
			salt, msg.sender, pricePerShare, currency, quorum, votePeriod);

		if (offerExists()) {
			offer.makeCompetingOffer(newOffer);
		}
		offer = newOffer;
	}

	function drag(address buyer, IERC20 currency) external override offerOnly {
		unwrap(buyer, balanceOf(buyer), 1);
		replaceWrapped(currency, buyer);
	}

	function notifyOfferEnded() external override offerOnly {
		offer = IOffer(address(0));
	}

	function replaceWrapped(IERC20 newWrapped, address oldWrappedDestination) internal {
		require(isBinding(), "factor");
		// Free all old wrapped tokens we have
		require(wrapped.transfer(oldWrappedDestination, wrapped.balanceOf(address(this))), "transfer");
		// Count the new wrapped tokens
		wrapped = newWrapped;
		deactivate(newWrapped.balanceOf(address(this)) / totalSupply());
	}

	function setOracle(address newOracle) external {
		require(msg.sender == oracle, "not oracle");
		oracle = newOracle;
		emit ChangeOracle(oracle);
	}

	function migrateWithExternalApproval(address successor, uint256 additionalVotes) external {
		require(msg.sender == oracle, "not oracle");
		// Additional votes cannot be higher than the votes not represented by these tokens.
		// The assumption here is that more shareholders are bound to the shareholder agreement
		// that this contract helps enforce and a vote among all parties is necessary to change
		// it, with an oracle counting and reporting the votes of the others.
		require(totalSupply() + additionalVotes <= totalVotingTokens(), "votes");
		migrate(successor, additionalVotes);
	}

	function migrate() external {
		migrate(msg.sender, 0);
	}

	function migrate(address successor, uint256 additionalVotes) internal {
		uint256 yesVotes = additionalVotes + balanceOf(successor);
		uint256 totalVotes = totalVotingTokens();
		require(yesVotes <= totalVotes, "votes");
		require(!offerExists(), "no offer"); // if you have the quorum, you can cancel the offer first if necessary
		require(yesVotes * QUORUM_MULTIPLIER >= totalVotes * quorum, "quorum");
		replaceWrapped(IERC20(successor), successor);
		emit MigrationSucceeded(successor, yesVotes, additionalVotes, totalVotes);
	}

	function votingPower(address voter) external view override returns (uint256) {
		return balanceOf(voter);
	}

	function totalVotingTokens() public view override returns (uint256) {
		return IShares(address(wrapped)).totalShares();
	}

	function hasVoted(address voter) internal view returns (bool) {
		return hasFlagInternal(voter, FLAG_VOTE_HINT);
	}

	function notifyVoted(address voter) external override offerOnly {
		setFlag(voter, FLAG_VOTE_HINT, true);
	}

	modifier offerOnly(){
		require(msg.sender == address(offer), "sender");
		_;
	}

	function _beforeTokenTransfer(address from, address to,	uint256 amount) internal virtual override {
		if (hasVoted(from) || hasVoted(to)) {
			if (offerExists()) {
				offer.notifyMoved(from, to, amount);
			} else {
				setFlag(from, FLAG_VOTE_HINT, false);
				setFlag(to, FLAG_VOTE_HINT, false);
			}
		}
		super._beforeTokenTransfer(from, to, amount);
	}

	function offerExists() internal view returns (bool) {
		return address(offer) != address(0);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC20/IERC20.sol";
interface IDraggable {
    
    function oracle() external view returns (address);
    function drag(address buyer, IERC20 currency) external;
    function notifyOfferEnded() external;
    function votingPower(address voter) external returns (uint256);
    function totalVotingTokens() external view returns (uint256);
    function notifyVoted(address voter) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC20/IERC20.sol";

interface IOffer {
	function makeCompetingOffer(IOffer newOffer) external;

	// if there is a token transfer while an offer is open, the votes get transfered too
	function notifyMoved(address from, address to, uint256 value) external;

	function currency() external view returns (IERC20);

	function price() external view returns (uint256);

	function isWellFunded() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC20/IERC20.sol";
import "./IOffer.sol";

interface IOfferFactory {

	function create(
		bytes32 salt, address buyer, uint256 pricePerShare,	IERC20 currency,	uint256 quorum,	uint256 votePeriod
	) external payable returns (IOffer);
}

/**
* SPDX-License-Identifier: LicenseRef-Aktionariat
*
* MIT License with Automated License Fee Payments
*
* Copyright (c) 2020 Aktionariat AG (aktionariat.com)
*
* Permission is hereby granted to any person obtaining a copy of this software
* and associated documentation files (the "Software"), to deal in the Software
* without restriction, including without limitation the rights to use, copy,
* modify, merge, publish, distribute, sublicense, and/or sell copies of the
* Software, and to permit persons to whom the Software is furnished to do so,
* subject to the following conditions:
*
* - The above copyright notice and this permission notice shall be included in
*   all copies or substantial portions of the Software.
* - All automated license fee payments integrated into this and related Software
*   are preserved.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/
pragma solidity ^0.8.0;

import "../ERC20/ERC20Flaggable.sol";
import "./IRecoveryHub.sol";
import "./IRecoverable.sol";

/**
 * @title Recoverable
 * In case of tokens that represent real-world assets such as shares of a company, one needs a way
 * to handle lost private keys. With physical certificates, courts can declare share certificates as
 * invalid so the company can issue replacements. Here, we want a solution that does not depend on
 * third parties to resolve such cases. Instead, when someone has lost a private key, he can use the
 * declareLost function on the recovery hub to post a deposit and claim that the shares assigned to a
 * specific address are lost.
 * If an attacker trying to claim shares belonging to someone else, they risk losing the deposit
 * as it can be claimed at anytime by the rightful owner.
 * Furthermore, if "getClaimDeleter" is defined in the subclass, the returned address is allowed to
 * delete claims, returning the collateral. This can help to prevent obvious cases of abuse of the claim
 * function, e.g. cases of front-running.
 * Most functionality is implemented in a shared RecoveryHub.
 */
abstract contract ERC20Recoverable is ERC20Flaggable, IRecoverable {

    uint8 private constant FLAG_CLAIM_PRESENT = 10;

    // ERC-20 token that can be used as collateral or 0x0 if disabled
    IERC20 public customCollateralAddress;
    // Rate the custom collateral currency is multiplied to be valued like one share.
    uint256 public customCollateralRate;

    uint256 constant CLAIM_PERIOD = 180 days;

    IRecoveryHub public immutable recovery;

    constructor(IRecoveryHub recoveryHub){
        recovery = recoveryHub;
    }

    /**
     * Returns the collateral rate for the given collateral type and 0 if that type
     * of collateral is not accepted. By default, only the token itself is accepted at
     * a rate of 1:1.
     *
     * Subclasses should override this method if they want to add additional types of
     * collateral.
     */
    function getCollateralRate(IERC20 collateralType) public override virtual view returns (uint256) {
        if (address(collateralType) == address(this)) {
            return 1;
        } else if (collateralType == customCollateralAddress) {
            return customCollateralRate;
        } else {
            return 0;
        }
    }

    function claimPeriod() external pure override returns (uint256){
        return CLAIM_PERIOD;
    }

    /**
     * Allows subclasses to set a custom collateral besides the token itself.
     * The collateral must be an ERC-20 token that returns true on successful transfers and
     * throws an exception or returns false on failure.
     * Also, do not forget to multiply the rate in accordance with the number of decimals of the collateral.
     * For example, rate should be 7*10**18 for 7 units of a collateral with 18 decimals.
     */
    function _setCustomClaimCollateral(IERC20 collateral, uint256 rate) internal {
        customCollateralAddress = collateral;
        if (address(customCollateralAddress) == address(0)) {
            customCollateralRate = 0; // disabled
        } else {
            require(rate > 0, "zero");
            customCollateralRate = rate;
        }
    }

    function getClaimDeleter() virtual public view returns (address);

    function transfer(address recipient, uint256 amount) override(ERC20Flaggable, IERC20) virtual public returns (bool) {
        require(super.transfer(recipient, amount), "transfer");
        if (hasFlagInternal(msg.sender, FLAG_CLAIM_PRESENT)){
            recovery.clearClaimFromToken(msg.sender);
        }
        return true;
    }

    function notifyClaimMade(address target) external override {
        require(msg.sender == address(recovery), "not recovery");
        setFlag(target, FLAG_CLAIM_PRESENT, true);
    }

    function notifyClaimDeleted(address target) external override {
        require(msg.sender == address(recovery), "not recovery");
        setFlag(target, FLAG_CLAIM_PRESENT, false);
    }

    function deleteClaim(address lostAddress) external {
        require(msg.sender == getClaimDeleter(), "not claim deleter");
        recovery.deleteClaim(lostAddress);
    }

    function recover(address oldAddress, address newAddress) external override {
        require(msg.sender == address(recovery), "not recovery");
        _transfer(oldAddress, newAddress, balanceOf(oldAddress));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC20/IERC20.sol";

interface IRecoverable is IERC20{

    function claimPeriod() external view returns (uint256);
    
    function notifyClaimMade(address target) external;

    function notifyClaimDeleted(address target) external;

    function getCollateralRate(IERC20 collateral) external view returns(uint256);

    function recover(address oldAddress, address newAddress) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRecoveryHub {

    function setRecoverable(bool flag) external;
    
    // deletes claim and transfers collateral back to claimer
    function deleteClaim(address target) external;

    // clears claim and transfers collateral to holder
    function clearClaimFromToken(address holder) external;

}

/**
* SPDX-License-Identifier: LicenseRef-Aktionariat
*
* MIT License with Automated License Fee Payments
*
* Copyright (c) 2020 Aktionariat AG (aktionariat.com)
*
* Permission is hereby granted to any person obtaining a copy of this software
* and associated documentation files (the "Software"), to deal in the Software
* without restriction, including without limitation the rights to use, copy,
* modify, merge, publish, distribute, sublicense, and/or sell copies of the
* Software, and to permit persons to whom the Software is furnished to do so,
* subject to the following conditions:
*
* - The above copyright notice and this permission notice shall be included in
*   all copies or substantial portions of the Software.
* - All automated license fee payments integrated into this and related Software
*   are preserved.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/
pragma solidity ^0.8.0;

import "../recovery/ERC20Recoverable.sol";
import "../draggable/ERC20Draggable.sol";

/**
 * @title CompanyName AG Shares SHA
 * @author Luzius Meisser, [email protected]
 *
 * This is an ERC-20 token representing share tokens of CompanyName AG that are bound to
 * a shareholder agreement that can be found at the URL defined in the constant 'terms'.
 */
contract DraggableShares is ERC20Draggable, ERC20Recoverable {

    string public terms;

    constructor(
        string memory _terms,
        IERC20 _wrappedToken,
        uint256 _quorumBps,
        uint256 _votePeriodSeconds,
        IRecoveryHub _recoveryHub,
        IOfferFactory _offerFactory,
        address _oracle
    )
        ERC20Draggable(_wrappedToken, _quorumBps, _votePeriodSeconds, _offerFactory, _oracle)
        ERC20Recoverable(_recoveryHub) 
    {
        terms = _terms; // to update the terms, migrate to a new contract. That way it is ensured that the terms can only be updated when the quorom agrees.
        _recoveryHub.setRecoverable(false);
    }

    function transfer(address to, uint256 value) virtual override(ERC20Flaggable, ERC20Recoverable) public returns (bool) {
        return super.transfer(to, value);
    }

    /**
     * Let the oracle act as deleter of invalid claims. In earlier versions, this was referring to the claim deleter
     * of the wrapped token. But that stops working after a successful acquisition as the acquisition currency most
     * likely does not have a claim deleter.
     */
    function getClaimDeleter() public view override returns (address) {
        return oracle;
    }

    function getCollateralRate(IERC20 collateralType) public view override returns (uint256) {
        uint256 rate = super.getCollateralRate(collateralType);
        if (rate > 0) {
            return rate;
        } else {
            // as long as it is binding, the conversion rate is 1:1
            uint256 factor = isBinding() ? 1 : unwrapConversionFactor;
            if (address(collateralType) == address(wrapped)) {
                // allow wrapped token as collateral
                return factor;
            } else {
                // If the wrapped contract allows for a specific collateral, we should too.
                // If the wrapped contract is not IRecoverable, we will fail here, but would fail anyway.
                return IRecoverable(address(wrapped)).getCollateralRate(collateralType) * factor;
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) virtual override(ERC20Flaggable, ERC20Draggable) internal {
        super._beforeTokenTransfer(from, to, amount);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IShares {
	function burn(uint256) external;

	function totalShares() external view returns (uint256);
}
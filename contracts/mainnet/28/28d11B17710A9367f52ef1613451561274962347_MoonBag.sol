// SPDX-License-Identifier: MIT

// ███╗░░░███╗░█████╗░░█████╗░███╗░░██╗██████╗░░█████╗░░██████╗░
// ████╗░████║██╔══██╗██╔══██╗████╗░██║██╔══██╗██╔══██╗██╔════╝░
// ██╔████╔██║██║░░██║██║░░██║██╔██╗██║██████╦╝███████║██║░░██╗░
// ██║╚██╔╝██║██║░░██║██║░░██║██║╚████║██╔══██╗██╔══██║██║░░╚██╗
// ██║░╚═╝░██║╚█████╔╝╚█████╔╝██║░╚███║██████╦╝██║░░██║╚██████╔╝
// ╚═╝░░░░░╚═╝░╚════╝░░╚════╝░╚═╝░░╚══╝╚═════╝░╚═╝░░╚═╝░╚═════╝░

// BOT PROOF - JEET PROOF

// A REVOLUTIONARY NEW CONTRACT

// Telegram https://t.me/moonbagtoken
// Website https://moonbag.wtf

// Taxes 5/5

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import "Address.sol";
import "MoonBagVault.sol";

contract MoonBag is Context, IERC20, IERC20Metadata, Ownable, ReentrancyGuard {
    bool public isTxLimitActive = true;
    uint8 public taxPercent = 50; // In thousandths; 50 = 5.0%
    address payable public taxWallet;
    address public vaultAddress;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private noVaultOnTransferFrom;
    mapping(address => bool) private noVaultOnTransferTo;

    mapping(address => bool) private taxList;
    mapping(address => bool) private taxWhitelist;

    constructor(address payable _taxWallet) {
        _balances[_msgSender()] = totalSupply();
        taxWallet = _taxWallet;
        taxWhitelist[_taxWallet] = true;
        noVaultOnTransferFrom[_taxWallet] = true;
        noVaultOnTransferTo[_taxWallet] = true;
    }

    function name() public pure override returns (string memory) {
        return "MoonBag";
    }

    function symbol() public pure override returns (string memory) {
        return "MOON";
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return 1000000000000e18; // One trillion whole tokens, with 18 decimal places
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address to, uint256 amount)
        public
        override
        returns (bool success)
    {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        nonReentrant
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        if (_msgSender() != vaultAddress) {
            uint256 currentAllowance = _allowances[sender][_msgSender()];
            require(
                currentAllowance >= amount,
                "ERC20: transfer amount exceeds allowance"
            );
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }
        _transfer(sender, recipient, amount);

        return true;
    }

    function setAccountTaxListStatus(address account, bool status)
        public
        onlyOwner
    {
        taxList[account] = status;
    }

    function setAccountTaxWhitelistStatus(address account, bool status)
        public
        onlyOwner
    {
        taxWhitelist[account] = status;
    }

    function setVaultAddress(address _vaultAddress) public onlyOwner {
        vaultAddress = _vaultAddress;
    }

    function setIsTxLimitActive(bool _isTxLimitActive) public onlyOwner {
        isTxLimitActive = _isTxLimitActive;
    }

    function allowTransferFromWithoutVaulting(address account, bool status)
        public
        onlyOwner
    {
        noVaultOnTransferFrom[account] = status;
    }

    function allowTransferToWithoutVaulting(address account, bool status)
        public
        onlyOwner
    {
        noVaultOnTransferTo[account] = status;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        bool shouldTax = (taxList[sender] || taxList[recipient]) &&
            (!taxWhitelist[sender] && !taxWhitelist[recipient]);
        require(
            !shouldTax || !isTxLimitActive || amount < (totalSupply() / 100),
            "Transfer amount exceeds 1 percent limit"
        );
        if (shouldTax) {
            uint256 totalTax = (amount * taxPercent) / 1000;
            _transferForFree(sender, taxWallet, totalTax);
            amount -= totalTax;
        }
        _transferForFree(sender, recipient, amount);
        if (
            shouldTax &&
            !(noVaultOnTransferFrom[sender] || noVaultOnTransferTo[recipient])
        ) {
            MoonBagVault vaultContract = MoonBagVault(vaultAddress);
            vaultContract.lock(recipient, (amount * 40) / 100);
        }
    }

    function _transferForFree(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

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

    receive() external payable {}
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
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

import "Context.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import "IERC20.sol";

contract MoonBagVault is Context, Ownable, ReentrancyGuard {

	address public moonAddress;

	struct Bag {
		uint256 date; // when the bag was created
		uint256 amount; // the amount locked in the bag
	}
	mapping(address => uint256) private _balance;
	mapping(address => uint256) private _availableBalance;
	mapping(address => Bag[]) private _bags;
	mapping(address => uint256) private _bagsLastUpdated;

	uint256 private _totalLocked;

	constructor(address _moonAddress) {
		moonAddress = _moonAddress;
	}
	
	function lock(address account, uint256 amount) public nonReentrant {
		require(
			_msgSender() == account || _msgSender() == moonAddress,
			"Cannot lock on behalf of another account."
		);

		IERC20(moonAddress).transferFrom(account, address(this), amount);
		_balance[account] += amount;
		_totalLocked += amount;
		_bags[account].push(Bag(block.timestamp, amount));
	}

	function balanceOf(address account) public view returns (uint256) {
		return _balance[account];
	}

	function availableBalance(address account) public view returns (uint256) {
		uint newlyAvailable = 0;
		Bag[] storage arr = _bags[account];
		for (uint i = 0; i < arr.length; i++) {
			uint256 currentWeek = (block.timestamp - arr[i].date) / 604800;
			uint256 lastUpdateWeek = (_bagsLastUpdated[account] > arr[i].date)
				? (_bagsLastUpdated[account] - arr[i].date) / 604800
				: 0;
			if (currentWeek > 3) currentWeek = 4;
			uint256 releases = currentWeek - lastUpdateWeek;
			if (releases == 0) continue;
			newlyAvailable += releases * (arr[i].amount / 4);
			if (currentWeek == 4) {
				newlyAvailable += arr[i].amount - 4 * (arr[i].amount / 4);
			}
		}
		return _availableBalance[account] + newlyAvailable;
	}

	function lockedBalance(address account) public view returns (uint256) {
		return balanceOf(account) - availableBalance(account);
	}

	function withdraw(uint256 amount) public nonReentrant {
		_processReleases(_msgSender());
		require(_availableBalance[_msgSender()] >= amount, "Not enough MOON available to withdraw.");
		IERC20(moonAddress).transfer(_msgSender(), amount);
		_availableBalance[_msgSender()] -= amount;
		_balance[_msgSender()] -= amount;
		_totalLocked -= amount;
	}

	function showBags(address account) public view returns (Bag[] memory) {
		return _bags[account];
	}

	function _processReleases(address account) private {
		uint removed = 0;
		Bag[] storage arr = _bags[account];
		for (uint i = 0; i < arr.length; i++) {
			if (removed > 0)
				arr[i - removed] = arr[i];
			uint256 currentWeek = (block.timestamp - arr[i].date) / 604800;
			uint256 lastUpdateWeek = (_bagsLastUpdated[account] > arr[i].date)
				? (_bagsLastUpdated[account] - arr[i].date) / 604800
				: 0;
			if (currentWeek > 3) currentWeek = 4;
			uint256 releases = currentWeek - lastUpdateWeek;
			if (releases == 0)
				continue;
			_availableBalance[account] += releases * (arr[i].amount / 4);
			if (currentWeek == 4) {
				_availableBalance[account] += arr[i].amount - 4 * (arr[i].amount / 4);
				removed++;
			}
		}
		for (uint i = 0; i < removed; i++)
			arr.pop();
		_bagsLastUpdated[account] = block.timestamp;
		_bags[account] = arr;
	}
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./access/HasERC677TokenParent.sol";

/**
 * @title Crunch Multi Vesting V2
 * @author Enzo CACERES <[email protected]>
 * @notice Allow the vesting of multiple users using only one contract.
 */
contract CrunchMultiVestingV2 is HasERC677TokenParent {
    /// see IERC20.Transfer
    event Transfer(address indexed from, address indexed to, uint256 value);

    // prettier-ignore
    event VestingBegin(
        uint256 startDate
    );

    // prettier-ignore
    event TokensReleased(
        uint256 indexed vestingId,
        address indexed beneficiary,
        uint256 amount
    );

    // prettier-ignore
    event VestingCreated(
        uint256 indexed vestingId,
        address indexed beneficiary,
        uint256 amount,
        uint256 cliffDuration,
        uint256 duration,
        bool revocable
    );

    // prettier-ignore
    event VestingRevoked(
        uint256 indexed vestingId,
        address indexed beneficiary,
        uint256 refund
    );

    // prettier-ignore
    event VestingTransfered(
        uint256 indexed vestingId,
        address indexed from,
        address indexed to
    );

    struct Vesting {
        /** vesting id. */
        uint256 id;
        /** address that will receive the token. */
        address beneficiary;
        /** the amount of token to vest. */
        uint256 amount;
        /** the cliff time of the token vesting. */
        uint256 cliffDuration;
        /** the duration of the token vesting. */
        uint256 duration;
        /** whether the vesting can be revoked. */
        bool revocable;
        /** whether the vesting is revoked. */
        bool revoked;
        /** the amount of the token released. */
        uint256 released;
    }

    /** currently locked tokens that are being used by all of the vestings */
    uint256 public totalSupply;

    uint256 public startDate;

    /** mapping to vesting list */
    mapping(uint256 => Vesting) public vestings;

    /** mapping to list of address's owning vesting id */
    mapping(address => uint256[]) public owned;

    /** always incrementing value to generate the next vesting id */
    uint256 _idCounter;

    /**
     * @notice Instanciate a new contract.
     * @param crunch CRUNCH token address.
     */
    constructor(address crunch) HasERC677TokenParent(crunch) {}

    /**
     * @notice Fake an ERC20-like contract allowing it to be displayed from wallets.
     * @return the contract 'fake' token name.
     */
    function name() external pure returns (string memory) {
        return "Vested CRUNCH Token v2 (multi)";
    }

    /**
     * @notice Fake an ERC20-like contract allowing it to be displayed from wallets.
     * @return the contract 'fake' token symbol.
     */
    function symbol() external pure returns (string memory) {
        return "mvCRUNCH";
    }

    /**
     * @notice Fake an ERC20-like contract allowing it to be displayed from wallets.
     * @return the crunch's decimals value.
     */
    function decimals() external view returns (uint8) {
        return parentToken.decimals();
    }

    /**
     * @notice Get the current reserve (or balance) of the contract in CRUNCH.
     * @return The balance of CRUNCH this contract has.
     */
    function reserve() public view returns (uint256) {
        return parentToken.balanceOf(address(this));
    }

    /**
     * @notice Get the available reserve.
     * @return The number of CRUNCH that can be used to create another vesting.
     */
    function availableReserve() public view returns (uint256) {
        return reserve() - totalSupply;
    }

    /**
     * @notice Begin the vesting of everyone at the current block timestamp.
     */
    function beginNow() external onlyOwner {
        _begin(block.timestamp);
    }

    /**
     * @notice Begin the vesting of everyone at a specified timestamp.
     * @param timestamp Timestamp to use as a begin date.
     */
    function beginAt(uint256 timestamp) external onlyOwner {
        require(timestamp != 0, "MultiVesting: timestamp cannot be zero");

        _begin(timestamp);
    }

    /**
     * @notice Create a new vesting.
     *
     * Requirements:
     * - caller must be the owner
     * - `amount` must not be zero
     * - `beneficiary` must not be the null address
     * - `cliffDuration` must be less than the duration
     * - `duration` must not be zero
     * - there must be enough available reserve to accept the amount
     *
     * @dev A `VestingCreated` event will be emitted.
     * @param beneficiary Address that will receive CRUNCH tokens.
     * @param amount Amount of CRUNCH to vest.
     * @param cliffDuration Cliff duration in seconds.
     * @param duration Vesting duration in seconds.
     */
    function vest(
        address beneficiary,
        uint256 amount,
        uint256 cliffDuration,
        uint256 duration,
        bool revocable
    ) external onlyOwner onlyWhenNotStarted {
        _requireVestInputs(duration);
        _vest(beneficiary, amount, cliffDuration, duration, revocable);
    }

    /**
     * @notice Create multiple vesting at once.
     *
     * Requirements:
     * - caller must be the owner
     * - `amounts` must not countains a zero values
     * - `beneficiaries` must not contains null addresses
     * - `cliffDuration` must be less than the duration
     * - `duration` must not be zero
     * - there must be enough available reserve to accept the amount
     *
     * @dev A `VestingCreated` event will be emitted.
     * @param beneficiaries Addresses that will receive CRUNCH tokens.
     * @param amounts Amounts of CRUNCH to vest.
     * @param cliffDuration Cliff duration in seconds.
     * @param duration Vesting duration in seconds.
     */
    function vestMultiple(
        address[] calldata beneficiaries,
        uint256[] calldata amounts,
        uint256 cliffDuration,
        uint256 duration,
        bool revocable
    ) external onlyOwner onlyWhenNotStarted {
        require(beneficiaries.length == amounts.length, "MultiVesting: arrays are not the same length");
        require(beneficiaries.length != 0, "MultiVesting: must vest at least one person");
        _requireVestInputs(duration);

        for (uint256 index = 0; index < beneficiaries.length; ++index) {
            _vest(beneficiaries[index], amounts[index], cliffDuration, duration, revocable);
        }
    }

    /**
     * @notice Transfer a vesting to another person.
     * @dev A `VestingTransfered` event will be emitted.
     * @param to Receiving address.
     * @param vestingId Vesting ID to transfer.
     */
    function transfer(address to, uint256 vestingId) external {
        _transfer(_getVesting(vestingId, _msgSender()), to);
    }

    /**
     * @notice Release the tokens of a specified vesting.
     *
     * Requirements:
     * - the vesting must exists
     * - the caller must be the vesting's beneficiary
     * - at least one token must be released
     *
     * @dev A `TokensReleased` event will be emitted.
     * @param vestingId Vesting ID to release.
     */
    function release(uint256 vestingId) external returns (uint256) {
        return _release(_getVesting(vestingId, _msgSender()));
    }

    /**
     * @notice Release the tokens of a all of sender's vesting.
     *
     * Requirements:
     * - at least one token must be released
     *
     * @dev `TokensReleased` events will be emitted.
     */
    function releaseAll() external returns (uint256) {
        return _releaseAll(_msgSender());
    }

    /**
     * @notice Release the tokens of a specified vesting.
     *
     * Requirements:
     * - caller must be the owner
     * - the vesting must exists
     * - at least one token must be released
     *
     * @dev A `TokensReleased` event will be emitted.
     * @param vestingId Vesting ID to release.
     */
    function releaseFor(uint256 vestingId) external onlyOwner returns (uint256) {
        return _release(_getVesting(vestingId));
    }

    /**
     * @notice Release the tokens of a all of beneficiary's vesting.
     *
     * Requirements:
     * - caller must be the owner
     * - at least one token must be released
     *
     * @dev `TokensReleased` events will be emitted.
     */
    function releaseAllFor(address beneficiary) external onlyOwner returns (uint256) {
        return _releaseAll(beneficiary);
    }

    /**
     * @notice Revoke a vesting.
     *
     * Requirements:
     * - caller must be the owner
     * - the vesting must be revocable
     * - the vesting must be not be already revoked
     *
     * @dev `VestingRevoked` events will be emitted.
     * @param vestingId Vesting ID to revoke.
     * @param sendBack Should the revoked tokens stay in the contract or be sent back to the owner?
     */
    function revoke(uint256 vestingId, bool sendBack) public onlyOwner returns (uint256) {
        return _revoke(_getVesting(vestingId), sendBack);
    }

    /**
     * @notice Test if an address is the beneficiary of a vesting.
     * @return `true` if the address is the beneficiary of the vesting, `false` otherwise.
     */
    function isBeneficiary(uint256 vestingId, address account) public view returns (bool) {
        return _isBeneficiary(_getVesting(vestingId), account);
    }

    /**
     * @notice Test if an address has at least one vesting.
     * @return `true` if the address has one or more vesting.
     */
    function isVested(address beneficiary) public view returns (bool) {
        return ownedCount(beneficiary) != 0;
    }

    /**
     * @notice Get the releasable amount of tokens.
     * @param vestingId Vesting ID to check.
     * @return The releasable amounts.
     */
    function releasableAmount(uint256 vestingId) public view returns (uint256) {
        return _releasableAmount(_getVesting(vestingId));
    }

    /**
     * @notice Get the vested amount of tokens.
     * @param vestingId Vesting ID to check.
     * @return The vested amount of the vestings.
     */
    function vestedAmount(uint256 vestingId) public view returns (uint256) {
        return _vestedAmount(_getVesting(vestingId));
    }

    /**
     * @notice Get the number of vesting for an address.
     * @param beneficiary Address to check.
     * @return The amount of vesting for the address.
     */
    function ownedCount(address beneficiary) public view returns (uint256) {
        return owned[beneficiary].length;
    }

    /**
     * @notice Get the remaining amount of token of a beneficiary.
     * @dev This function is to make wallets able to display the amount in their UI.
     * @param beneficiary Address to check.
     * @return balance The remaining amount of tokens.
     */
    function balanceOf(address beneficiary) external view returns (uint256 balance) {
        uint256[] storage indexes = owned[beneficiary];

        for (uint256 index = 0; index < indexes.length; ++index) {
            uint256 vestingId = indexes[index];

            balance += balanceOfVesting(vestingId);
        }
    }

    /**
     * @notice Get the remaining amount of token of a specified vesting.
     * @param vestingId Vesting ID to check.
     * @return The remaining amount of tokens.
     */
    function balanceOfVesting(uint256 vestingId) public view returns (uint256) {
        return _balanceOfVesting(_getVesting(vestingId));
    }

    /**
     * @notice Send the available token back to the owner.
     */
    function emptyAvailableReserve() external onlyOwner {
        uint256 available = availableReserve();
        require(available > 0, "MultiVesting: no token available");

        parentToken.transfer(owner(), available);
    }

    /**
     * @notice Get the remaining amount of token of a specified vesting.
     * @param vesting Vesting to check.
     * @return The remaining amount of tokens.
     */
    function _balanceOfVesting(Vesting storage vesting) internal view returns (uint256) {
        return vesting.amount - vesting.released;
    }

    /**
     * @notice Begin the vesting for everyone.
     * @param timestamp Timestamp to use for the start date.
     * @dev A `VestingBegin` event will be emitted.
     */
    function _begin(uint256 timestamp) internal onlyWhenNotStarted {
        startDate = timestamp;

        emit VestingBegin(startDate);
    }

    /**
     * @notice Check the shared inputs of a vest method.
     */
    function _requireVestInputs(uint256 duration) internal pure {
        require(duration > 0, "MultiVesting: duration is 0");
    }

    /**
     * @notice Create a vesting.
     */
    function _vest(
        address beneficiary,
        uint256 amount,
        uint256 cliffDuration,
        uint256 duration,
        bool revocable
    ) internal {
        require(beneficiary != address(0), "MultiVesting: beneficiary is the zero address");
        require(amount > 0, "MultiVesting: amount is 0");
        require(availableReserve() >= amount, "MultiVesting: available reserve is not enough");

        uint256 vestingId = _idCounter++; /* post-increment */

        // prettier-ignore
        vestings[vestingId] = Vesting({
            id: vestingId,
            beneficiary: beneficiary,
            amount: amount,
            cliffDuration: cliffDuration,
            duration: duration,
            revocable: revocable,
            revoked: false,
            released: 0
        });

        _addOwnership(beneficiary, vestingId);

        totalSupply += amount;

        emit VestingCreated(vestingId, beneficiary, amount, cliffDuration, duration, revocable);
        emit Transfer(address(0), beneficiary, amount);
    }

    /**
     * @notice Transfer a vesting to another address.
     */
    function _transfer(Vesting storage vesting, address to) internal {
        address from = vesting.beneficiary;

        require(from != to, "MultiVesting: cannot transfer to itself");
        require(to != address(0), "MultiVesting: target is the zero address");

        _removeOwnership(from, vesting.id);
        _addOwnership(to, vesting.id);

        vesting.beneficiary = to;

        emit VestingTransfered(vesting.id, from, to);
        emit Transfer(from, to, _balanceOfVesting(vesting));
    }

    /**
     * @dev Internal implementation of the release() method.
     * @dev The methods will fail if there is no tokens due.
     * @dev A `TokensReleased` event will be emitted.
     * @param vesting Vesting to release.
     */
    function _release(Vesting storage vesting) internal returns (uint256 unreleased) {
        unreleased = _doRelease(vesting);
        _checkAmount(unreleased);
    }

    /**
     * @dev Internal implementation of the releaseAll() method.
     * @dev The methods will fail if there is no tokens due.
     * @dev `TokensReleased` events will be emitted.
     * @param beneficiary Address to release all vesting from.
     */
    function _releaseAll(address beneficiary) internal returns (uint256 unreleased) {
        uint256[] storage indexes = owned[beneficiary];

        for (uint256 index = 0; index < indexes.length; ++index) {
            uint256 vestingId = indexes[index];
            Vesting storage vesting = vestings[vestingId];

            unreleased += _doRelease(vesting);
        }

        _checkAmount(unreleased);
    }

    /**
     * @dev Actually releasing the vestiong.
     * @dev This method will not fail. (aside from a lack of reserve, which should never happen!)
     */
    function _doRelease(Vesting storage vesting) internal returns (uint256 unreleased) {
        unreleased = _releasableAmount(vesting);

        if (unreleased != 0) {
            parentToken.transfer(vesting.beneficiary, unreleased);

            vesting.released += unreleased;
            totalSupply -= unreleased;

            emit TokensReleased(vesting.id, vesting.beneficiary, unreleased);
            emit Transfer(vesting.beneficiary, address(0), unreleased);
        }
    }

    /**
     * @dev Revert the transaction if the value is zero.
     */
    function _checkAmount(uint256 unreleased) internal pure {
        require(unreleased > 0, "MultiVesting: no tokens are due");
    }

    /**
     * @dev Revoke a vesting and send the extra CRUNCH back to the owner.
     */
    function _revoke(Vesting storage vesting, bool sendBack) internal returns (uint256 refund) {
        require(vesting.revocable, "MultiVesting: token not revocable");
        require(!vesting.revoked, "MultiVesting: token already revoked");

        uint256 unreleased = _releasableAmount(vesting);
        refund = vesting.amount - vesting.released - unreleased;

        vesting.revoked = true;
        vesting.amount -= refund;
        totalSupply -= refund;

        if (sendBack) {
            parentToken.transfer(owner(), refund);
        }

        emit VestingRevoked(vesting.id, vesting.beneficiary, refund);
        emit Transfer(vesting.beneficiary, address(0), refund);
    }

    /**
     * @dev Test if the vesting's beneficiary is the same as the specified address.
     */
    function _isBeneficiary(Vesting storage vesting, address account) internal view returns (bool) {
        return vesting.beneficiary == account;
    }

    /**
     * @dev Compute the releasable amount.
     * @param vesting Vesting instance.
     */
    function _releasableAmount(Vesting memory vesting) internal view returns (uint256) {
        return _vestedAmount(vesting) - vesting.released;
    }

    /**
     * @dev Compute the vested amount.
     * @param vesting Vesting instance.
     */
    function _vestedAmount(Vesting memory vesting) internal view returns (uint256) {
        if (startDate == 0) {
            return 0;
        }

        uint256 cliffEnd = startDate + vesting.cliffDuration;

        if (block.timestamp < cliffEnd) {
            return 0;
        }

        if ((block.timestamp >= cliffEnd + vesting.duration) || vesting.revoked) {
            return vesting.amount;
        }

        return (vesting.amount * (block.timestamp - cliffEnd)) / vesting.duration;
    }

    /**
     * @dev Get a vesting.
     * @return vesting struct stored in the storage.
     */
    function _getVesting(uint256 vestingId) internal view returns (Vesting storage vesting) {
        vesting = vestings[vestingId];
        require(vesting.beneficiary != address(0), "MultiVesting: vesting does not exists");
    }

    /**
     * @dev Get a vesting and make sure it is from the right beneficiary.
     * @param beneficiary Address to get it from.
     * @return vesting struct stored in the storage.
     */
    function _getVesting(uint256 vestingId, address beneficiary) internal view returns (Vesting storage vesting) {
        vesting = _getVesting(vestingId);
        require(vesting.beneficiary == beneficiary, "MultiVesting: not the beneficiary");
    }

    /**
     * @dev Remove the vesting from the ownership mapping.
     */
    function _removeOwnership(address account, uint256 vestingId) internal returns (bool) {
        uint256[] storage indexes = owned[account];

        (bool found, uint256 index) = _indexOf(indexes, vestingId);
        if (!found) {
            return false;
        }

        if (indexes.length <= 1) {
            delete owned[account];
        } else {
            indexes[index] = indexes[indexes.length - 1];
            indexes.pop();
        }

        return true;
    }

    /**
     * @dev Add the vesting ID to the ownership mapping.
     */
    function _addOwnership(address account, uint256 vestingId) internal {
        owned[account].push(vestingId);
    }

    /**
     * @dev Find the index of a value in an array.
     * @param array Haystack.
     * @param value Needle.
     * @return If the first value is `true`, that mean that the needle has been found and the index is stored in the second value. Else if `false`, the value isn't in the array and the second value should be discarded.
     */
    function _indexOf(uint256[] storage array, uint256 value) internal view returns (bool, uint256) {
        for (uint256 index = 0; index < array.length; ++index) {
            if (array[index] == value) {
                return (true, index);
            }
        }

        return (false, 0);
    }

    /**
     * @dev Revert if the start date is not zero.
     */
    modifier onlyWhenNotStarted() {
        require(startDate == 0, "MultiVesting: already started");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC677.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IERC677Metadata is IERC677, IERC20Metadata {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IERC677 is IERC20 {
    /**
     * @dev transfer token to a contract address with additional data if the recipient is a contact.
     * @param recipient The address to transfer to.
     * @param amount The amount to be transferred.
     * @param data The extra data to be passed to the receiving contract.
     */
    function transferAndCall(
        address recipient,
        uint256 amount,
        bytes memory data
    ) external returns (bool success);

    event TransferAndCall(
        address indexed from,
        address indexed to,
        uint256 value,
        bytes data
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../erc677/IERC677Metadata.sol";

contract HasERC677TokenParent is Ownable {
    event ParentTokenUpdated(address from, address to);

    IERC677Metadata public parentToken;

    constructor(address token) {
        _setParentToken(token);
    }

    function setCrunch(address token) public onlyOwner {
        _setParentToken(token);
    }

    function _setParentToken(address to) internal {
        address from = address(parentToken);

        require(from != address(to), "HasERC677TokenParent: useless to update to same crunch token");

        parentToken = IERC677Metadata(to);

        emit ParentTokenUpdated(from, to);

        /* test the token */
        parentToken.decimals();
    }

    modifier onlyParentParent() {
        require(address(parentToken) == _msgSender(), "HasERC677TokenParent: caller is not the crunch token");
        _;
    }
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
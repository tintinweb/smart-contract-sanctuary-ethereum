// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title Crunch Multi Vesting
 * @author Enzo CACERES <[email protected]>
 * @notice Allow the vesting of multiple users using only one contract.
 */
contract CrunchMultiVesting is Ownable {
    event TokensReleased(
        address indexed beneficiary,
        uint256 index,
        uint256 amount
    );

    event CrunchTokenUpdated(
        address indexed previousCrunchToken,
        address indexed newCrunchToken
    );

    event CreatorChanged(
        address indexed previousAddress,
        address indexed newAddress
    );

    event VestingCreated(
        address indexed beneficiary,
        uint256 amount,
        uint256 start,
        uint256 cliff,
        uint256 duration,
        uint256 index
    );

    struct Vesting {
        /* beneficiary of tokens after they are released. */
        address beneficiary;
        /** the amount of token to vest. */
        uint256 amount;
        /** the start time of the token vesting. */
        uint256 start;
        /** the cliff time of the token vesting. */
        uint256 cliff;
        /** the duration of the token vesting. */
        uint256 duration;
        /** the amount of the token released. */
        uint256 released;
    }

    /* CRUNCH erc20 address. */
    IERC20Metadata public crunch;

    /** secondary address that is only allowed to call the `create()` method */
    address public creator;

    /** currently locked tokens that are being used by all of the vestings */
    uint256 public totalSupply;

    /** mapping to vesting list */
    mapping(address => Vesting[]) public vestings;

    /** mapping to a list of the currently active vestings index */
    mapping(address => uint256[]) _actives;

    /**
     * @notice Instanciate a new contract.
     * @dev the creator will be set as the deployer's address.
     * @param _crunch CRUNCH token address.
     */
    constructor(address _crunch) {
        _setCrunch(_crunch);
        _setCreator(owner());
    }

    /**
     * @notice Fake an ERC20-like contract allowing it to be displayed from wallets.
     * @return the contract 'fake' token name.
     */
    function name() external pure returns (string memory) {
        return "Vested CRUNCH Token (multi)";
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
        return crunch.decimals();
    }

    /**
     * @notice Create a new vesting.
     *
     * Requirements:
     * - caller must be the owner or the creator
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
    function create(
        address beneficiary,
        uint256 amount,
        uint256 cliffDuration,
        uint256 duration
    ) external onlyCreatorOrOwner {
        require(
            beneficiary != address(0),
            "MultiVesting: beneficiary is the zero address"
        );

        require(amount > 0, "MultiVesting: amount is 0");

        require(duration > 0, "MultiVesting: duration is 0");

        require(
            cliffDuration <= duration,
            "MultiVesting: cliff is longer than duration"
        );

        require(
            availableReserve() >= amount,
            "MultiVesting: available reserve is not enough"
        );

        uint256 start = block.timestamp;
        uint256 cliff = start + cliffDuration;

        vestings[beneficiary].push(
            Vesting({
                beneficiary: beneficiary,
                amount: amount,
                start: start,
                cliff: cliff,
                duration: duration,
                released: 0
            })
        );

        uint256 index = vestings[beneficiary].length - 1;
        _actives[beneficiary].push(index);

        totalSupply += amount;

        emit VestingCreated(beneficiary, amount, start, cliff, duration, index);
    }

    /**
     * @notice Get the current reserve (or balance) of the contract in CRUNCH.
     * @return The balance of CRUNCH this contract has.
     */
    function reserve() public view returns (uint256) {
        return crunch.balanceOf(address(this));
    }

    /**
     * @notice Get the available reserve.
     * @return The number of CRUNCH that can be used to create another vesting.
     */
    function availableReserve() public view returns (uint256) {
        return reserve() - totalSupply;
    }

    /**
     * @notice Release a vesting of the current caller by its `index`.
     * @dev A `TokensReleased` event will be emitted.
     * @dev The transaction will fail if no token are due.
     * @param index The vesting index to release.
     */
    function release(uint256 index) external {
        _release(_msgSender(), index);
    }

    /**
     * @notice Release a vesting of a specified address by its `index`.
     * @dev The caller must be the owner.
     * @param beneficiary Address to release.
     * @param index The vesting index to release.
     */
    function releaseFor(address beneficiary, uint256 index) external onlyOwner {
        _release(beneficiary, index);
    }

    /**
     * @notice Release all of active vesting of the current caller.
     * @dev Multiple `TokensReleased` event might be emitted.
     * @dev The transaction will fail if no token are due.
     */
    function releaseAll() external {
        _releaseAll(_msgSender());
    }

    /**
     * @notice Release all of active vesting of a specified address.
     * @dev Multiple `TokensReleased` event might be emitted.
     * @dev The transaction will fail if no token are due.
     */
    function releaseAllFor(address beneficiary) external onlyOwner {
        _releaseAll(beneficiary);
    }

    /**
     * @notice Get the total of releasable amount of tokens by doing the sum of all of the currently active vestings.
     * @param beneficiary Address to check.
     * @return total The sum of releasable amounts.
     */
    function releasableAmount(address beneficiary)
        public
        view
        returns (uint256 total)
    {
        uint256 size = vestingsCount(beneficiary);

        for (uint256 index = 0; index < size; index++) {
            Vesting storage vesting = _getVesting(beneficiary, index);

            total += _releasableAmount(vesting);
        }
    }

    /**
     * @notice Get the releasable amount of tokens of a vesting by its `index`.
     * @param beneficiary Address to check.
     * @param index Vesting index to check.
     * @return The releasable amount of tokens of the found vesting.
     */
    function releasableAmountAt(address beneficiary, uint256 index)
        external
        view
        returns (uint256)
    {
        Vesting storage vesting = _getVesting(beneficiary, index);

        return _releasableAmount(vesting);
    }

    /**
     * @notice Get the sum of all vested amount of tokens.
     * @param beneficiary Address to check.
     * @return total The sum of vested amount of all of the vestings.
     */
    function vestedAmount(address beneficiary) public view returns (uint256 total) {
        uint256 size = vestingsCount(beneficiary);

        for (uint256 index = 0; index < size; index++) {
            Vesting storage vesting = _getVesting(beneficiary, index);

            total += _vestedAmount(vesting);
        }
    }

    /**
     * @notice Get the vested amount of tokens of a vesting by its `index`.
     * @param beneficiary Address to check.
     * @param index Address to check.
     * @return The vested amount of the found vesting.
     */
    function vestedAmountAt(address beneficiary, uint256 index)
        external
        view
        returns (uint256)
    {
        Vesting storage vesting = _getVesting(beneficiary, index);

        return _vestedAmount(vesting);
    }

    /**
     * @notice Get the sum of all remaining amount of tokens of each vesting of a beneficiary.
     * @dev This function is to make wallets able to display the amount in their UI.
     * @param beneficiary Address to check.
     * @return total The sum of all remaining amount of tokens.
     */
    function balanceOf(address beneficiary) external view returns (uint256 total) {
        uint256 size = vestingsCount(beneficiary);

        for (uint256 index = 0; index < size; index++) {
            Vesting storage vesting = _getVesting(beneficiary, index);

            total += vesting.amount - vesting.released;
        }
    }

    /**
     * @notice Update the CRUNCH token address.
     * @dev The caller must be the owner.
     * @dev A `CrunchTokenUpdated` event will be emitted.
     * @param newCrunch New CRUNCH token address.
     */
    function setCrunch(address newCrunch) external onlyOwner {
        _setCrunch(newCrunch);
    }

    /**
     * @notice Update the creator address. The old address will no longer be able to access the `create(...)` method.
     * @dev The caller must be the owner.
     * @dev A `CreatorChanged` event will be emitted.
     * @param newCreator New creator address.
     */
    function setCreator(address newCreator) external onlyOwner {
        _setCreator(newCreator);
    }

    /**
     * @notice Get the number of vesting of an address.
     * @param beneficiary Address to check.
     * @return Number of vesting.
     */
    function vestingsCount(address beneficiary) public view returns (uint256) {
        return vestings[beneficiary].length;
    }

    /**
     * @notice Get the number of active vesting of an address.
     * @param beneficiary Address to check.
     * @return Number of active vesting.
     */
    function activeVestingsCount(address beneficiary)
        public
        view
        returns (uint256)
    {
        return _actives[beneficiary].length;
    }

    /**
     * @notice Get the active vestings index.
     * @param beneficiary Address to check.
     * @return An array of currently active vestings index.
     */
    function activeVestingsIndex(address beneficiary)
        external
        view
        returns (uint256[] memory)
    {
        return _actives[beneficiary];
    }

    /**
     * @dev Internal implementation of the release() method.
     * @dev The methods will fail if there is no tokens due.
     * @dev A `TokensReleased` event will be emitted.
     * @dev If the vesting's released tokens is the same of the vesting's amount, the vesting is considered as finished, and will be removed from the active list.
     * @param beneficiary Address to release.
     * @param index Vesting index to release.
     */
    function _release(address beneficiary, uint256 index) internal {
        Vesting storage vesting = _getVesting(beneficiary, index);

        uint256 unreleased = _releasableAmount(vesting);
        require(unreleased > 0, "MultiVesting: no tokens are due");

        vesting.released += unreleased;

        crunch.transfer(vesting.beneficiary, unreleased);

        totalSupply -= unreleased;

        emit TokensReleased(vesting.beneficiary, index, unreleased);

        if (vesting.released == vesting.amount) {
            _removeActive(beneficiary, index);
        }
    }

    /**
     * @dev Internal implementation of the releaseAll() method.
     * @dev The methods will fail if there is no tokens due for all of the vestings.
     * @dev Multiple `TokensReleased` event may be emitted.
     * @dev If some vesting's released tokens is the same of their amount, they will considered as finished, and will be removed from the active list.
     * @param beneficiary Address to release.
     */
    function _releaseAll(address beneficiary) internal {
        uint256 totalReleased;

        uint256[] storage actives = _actives[beneficiary];
        for (uint256 activeIndex = 0; activeIndex < actives.length; ) {
            uint256 index = actives[activeIndex];
            Vesting storage vesting = _getVesting(beneficiary, index);

            uint256 unreleased = _releasableAmount(vesting);
            if (unreleased == 0) {
                activeIndex++;
                continue;
            }

            vesting.released += unreleased;
            totalSupply -= unreleased;

            crunch.transfer(vesting.beneficiary, unreleased);

            emit TokensReleased(vesting.beneficiary, index, unreleased);

            if (vesting.released == vesting.amount) {
                _removeActiveAt(beneficiary, activeIndex);
            } else {
                activeIndex++;
            }

            totalReleased += unreleased;
        }

        require(totalReleased > 0, "MultiVesting: no tokens are due");
    }

    /**
     * @dev Pop from the active list at a specified index.
     * @param beneficiary Address to get the active list from.
     * @param activeIndex Active list's index to pop.
     */
    function _removeActiveAt(address beneficiary, uint256 activeIndex) internal {
        uint256[] storage actives = _actives[beneficiary];

        actives[activeIndex] = actives[actives.length - 1];

        actives.pop();
    }

    /**
     * @dev Find the active index of a vesting index, and pop it with `_removeActiveAt(address, uint256)`.
     * @dev The method will fail if the active index is not found.
     * @param beneficiary Address to get the active list from.
     * @param index Vesting index to find and pop.
     */
    function _removeActive(address beneficiary, uint256 index) internal {
        uint256[] storage actives = _actives[beneficiary];

        for (
            uint256 activeIndex = 0;
            activeIndex < actives.length;
            activeIndex++
        ) {
            if (actives[activeIndex] == index) {
                _removeActiveAt(beneficiary, activeIndex);
                return;
            }
        }

        revert("MultiVesting: active index not found");
    }

    /**
     * @dev Compute the releasable amount.
     * @param vesting Vesting instance.
     */
    function _releasableAmount(Vesting memory vesting)
        internal
        view
        returns (uint256)
    {
        return _vestedAmount(vesting) - vesting.released;
    }

    /**
     * @dev Compute the vested amount.
     * @param vesting Vesting instance.
     */
    function _vestedAmount(Vesting memory vesting)
        internal
        view
        returns (uint256)
    {
        uint256 amount = vesting.amount;

        if (block.timestamp < vesting.cliff) {
            return 0;
        } else if ((block.timestamp >= vesting.start + vesting.duration)) {
            return amount;
        } else {
            return
                (amount * (block.timestamp - vesting.start)) / vesting.duration;
        }
    }

    /**
     * @dev Get a vesting.
     * @param beneficiary Address to get it from.
     * @param index Index to get it from.
     * @return A vesting struct stored in the storage.
     */
    function _getVesting(address beneficiary, uint256 index)
        internal
        view
        returns (Vesting storage)
    {
        return vestings[beneficiary][index];
    }

    /**
     * @dev Update the CRUNCH token address.
     * @dev A `CrunchTokenUpdated` event will be emitted.
     * @param newCrunch New CRUNCH token address.
     */
    function _setCrunch(address newCrunch) internal {
        address previousCrunch = address(crunch);

        crunch = IERC20Metadata(newCrunch);

        emit CrunchTokenUpdated(previousCrunch, address(newCrunch));
    }

    /**
     * @dev Update the creator address.
     * @dev A `CreatorChanged` event will be emitted.
     * @param newCreator New creator address.
     */
    function _setCreator(address newCreator) internal {
        address previous = creator;

        creator = newCreator;

        emit CreatorChanged(previous, newCreator);
    }

    /**
     * @dev Ensure that the caller is the creator or the owner.
     */
    modifier onlyCreatorOrOwner() {
        require(
            _msgSender() == creator || _msgSender() == owner(),
            "MultiVesting: only creator or owner can do this"
        );
        _;
    }
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
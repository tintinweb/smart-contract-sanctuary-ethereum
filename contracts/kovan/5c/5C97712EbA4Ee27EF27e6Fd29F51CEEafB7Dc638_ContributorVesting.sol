// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

// Interfaces
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Libraries
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Contracts
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title DAO Contributor Vesting
/// @author Jones DAO
/// @notice Allows to add beneficiaries for token vesting
contract ContributorVesting is Ownable {
    using SafeERC20 for IERC20;

    // Token
    IERC20 public token;

    // Structure of each vest
    struct Vest {
        uint8 role; // the role of the beneficiary
        uint8 tier; // vesting tier of the beneficiary
        uint256 released; // the amount of Token released to the beneficiary
        uint256 startTime; // start time of the vesting
        uint256 lastReleaseTime; // last time vest released
        uint256 pricePerToken; // JONES token price to be considered during vesting with 2 digit precision (e.g. 7.70 is 770)
    }

    // The mapping of vested beneficiary (beneficiary address => Vest)
    mapping(address => Vest) public vestedBeneficiaries;

    // Vesting tiers
    mapping(uint8 => mapping(uint256 => uint256)) public vestingTiers;

    // No. of beneficiaries
    uint256 public noOfBeneficiaries;

    // Three years in seconds constant
    uint256 private constant threeYears = 94670856;

    constructor(address _tokenAddress) {
        require(_tokenAddress != address(0), "Token address cannot be 0");

        token = IERC20(_tokenAddress);
        vestingTiers[0][4] = 3700000000000000000000000;
        vestingTiers[0][5] = 5500000000000000000000000;
        vestingTiers[0][6] = 7300000000000000000000000;
        vestingTiers[0][7] = 9800000000000000000000000;
        vestingTiers[0][8] = 12200000000000000000000000;
        vestingTiers[0][9] = 15300000000000000000000000;
        vestingTiers[0][10] = 18000000000000000000000000;
        vestingTiers[1][4] = 2200000000000000000000000;
        vestingTiers[1][5] = 3200000000000000000000000;
        vestingTiers[1][6] = 4300000000000000000000000;
        vestingTiers[1][7] = 5800000000000000000000000;
        vestingTiers[1][8] = 7200000000000000000000000;
        vestingTiers[1][9] = 9000000000000000000000000;
        vestingTiers[1][10] = 11200000000000000000000000;
        vestingTiers[2][4] = 1500000000000000000000000;
        vestingTiers[2][5] = 2300000000000000000000000;
        vestingTiers[2][6] = 3000000000000000000000000;
        vestingTiers[2][7] = 4000000000000000000000000;
        vestingTiers[2][8] = 5000000000000000000000000;
        vestingTiers[2][9] = 6300000000000000000000000;
        vestingTiers[2][10] = 7900000000000000000000000;
    }

    /*---- EXTERNAL FUNCTIONS FOR OWNER ----*/

    /**
     * @notice Adds a beneficiary to the contract. Only owner can call this.
     * @param _beneficiary the address of the beneficiary
     * @param _role the role of the beneficiary
     * @param _tier tier of the beneficiary
     * @param _startTime start time of the vesting
     * @param _pricePerToken JONES token price to be considered during vesting with 2 digit precision (e.g. 7.70 is 770)
     */
    function addBeneficiary(
        address _beneficiary,
        uint8 _role,
        uint8 _tier,
        uint256 _startTime,
        uint256 _pricePerToken
    ) public onlyOwner returns (bool) {
        require(
            _beneficiary != address(0),
            "Beneficiary cannot be a 0 address"
        );
        require(_role >= 0 && _tier <= 2, "Role should be between 0 and 2");
        require(_tier >= 4 && _tier <= 10, "Tier should be between 4 and 10");
        require(
            vestedBeneficiaries[_beneficiary].tier == 0,
            "Cannot add the same beneficiary again"
        );
        require(_pricePerToken > 0, "Price per token should be larger than 0");

        uint256 initialReleaseAmount = 0;
        uint256 realLatestRelease = _startTime;
        if (block.timestamp > _startTime) {
            realLatestRelease = block.timestamp;
            initialReleaseAmount =
                ((vestingTiers[_role][_tier] / _pricePerToken) *
                    (block.timestamp - _startTime)) /
                threeYears;
            token.safeTransfer(_beneficiary, initialReleaseAmount);
        }

        vestedBeneficiaries[_beneficiary] = Vest(
            _role,
            _tier,
            initialReleaseAmount,
            _startTime,
            realLatestRelease,
            _pricePerToken
        );

        noOfBeneficiaries += 1;

        emit AddBeneficiary(
            _beneficiary,
            _role,
            _tier,
            initialReleaseAmount,
            vestTimeLeft(_beneficiary),
            _startTime,
            _pricePerToken
        );

        return true;
    }

    /**
     * @notice Removes a beneficiary from the contract hence ending their vesting. Only owner can call this.
     * @param _beneficiary the address of the beneficiary
     * @return whether beneficiary was removed
     */
    function removeBeneficiary(address _beneficiary)
        external
        onlyOwner
        returns (bool)
    {
        require(
            _beneficiary != address(0),
            "Beneficiary cannot be a 0 address"
        );
        require(
            vestedBeneficiaries[_beneficiary].tier != 0,
            "Cannot remove a beneficiary which has not been added"
        );

        if (releasableAmount(_beneficiary) > 0) {
            release(_beneficiary);
        }

        vestedBeneficiaries[_beneficiary] = Vest(0, 0, 0, 0, 0, 0);

        noOfBeneficiaries -= 1;

        emit RemoveBeneficiary(_beneficiary);

        return true;
    }

    /**
     * @notice Updates a beneficiary's address. Only owner can call this.
     * @param _oldAddress the address of the beneficiary
     * @param _newAddress new tier of the beneficiary
     * @return whether beneficiary was updated
     */
    function updateBeneficiaryAddress(address _oldAddress, address _newAddress)
        external
        onlyOwner
        returns (bool)
    {
        require(
            vestedBeneficiaries[_oldAddress].tier != 0,
            "Vesting for this address doesnt exist"
        );

        vestedBeneficiaries[_newAddress] = vestedBeneficiaries[_oldAddress];
        vestedBeneficiaries[_oldAddress] = Vest(0, 0, 0, 0, 0, 0);

        emit UpdateBeneficiaryAddress(_oldAddress, _newAddress);

        return true;
    }

    /**
     * @notice Updates a beneficiary's tier. Only owner can call this.
     * @param _beneficiary the address of the beneficiary
     * @param _tier new tier of the beneficiary
     * @return whether beneficiary was updated
     */
    function updateBeneficiaryTier(address _beneficiary, uint8 _tier)
        external
        onlyOwner
        returns (bool)
    {
        Vest memory vBeneficiary = vestedBeneficiaries[_beneficiary];
        require(_tier >= 4 && _tier <= 10, "Tier should be between 4 and 10");
        require(
            _beneficiary != address(0),
            "Beneficiary cannot be a 0 address"
        );
        require(
            vBeneficiary.tier != 0,
            "Cannot remove a beneficiary which has not been added yet"
        );
        require(vBeneficiary.tier != _tier, "Beneficiary already in this tier");
        require(
            block.timestamp < vBeneficiary.startTime + threeYears &&
                block.timestamp > vBeneficiary.startTime,
            "Not within vesting period"
        );

        if (releasableAmount(_beneficiary) > 0) {
            release(_beneficiary);
        }

        uint8 oldTier = vBeneficiary.tier;
        uint256 beneficiaryTotalAmount = vestingTiers[vBeneficiary.role][
            _tier
        ] / vBeneficiary.pricePerToken;
        uint256 releaseLeft = beneficiaryTotalAmount -
            ((beneficiaryTotalAmount *
                (block.timestamp - vBeneficiary.startTime)) / threeYears);

        vestedBeneficiaries[_beneficiary].tier = _tier;

        emit UpdateBeneficiaryTier(_beneficiary, oldTier, _tier, releaseLeft);

        return true;
    }

    /**
     * @notice Allows updating of vesting tier token release amount.
     * @dev Use 20 digit precision
     * @param _role role of the beneficiary
     * @param _tier tier number
     * @param _amount amount of JONES tokens in three years
     */
    function updateTierAmount(
        uint8 _role,
        uint8 _tier,
        uint256 _amount
    ) public onlyOwner {
        require(_role >= 0 && _role <= 2, "Role should be between 0 and 2");
        require(_tier >= 4 && _tier <= 10, "Tier should be between 4 and 10");
        require(_amount > 0, "Amount must be greater than 0");
        vestingTiers[_role][_tier] = _amount;
    }

    /**
     * @notice Allows updating of price per token for a certain beneficiary.
     * @param _beneficiary the address of the beneficiary
     * @param _price with 2 digit precision (7.70 is 770)
     */
    function updatePricePerToken(address _beneficiary, uint256 _price)
        public
        onlyOwner
    {
        require(_price > 0, "Price must be greater than 0");
        require(
            vestedBeneficiaries[_beneficiary].tier != 0,
            "Cannot modify a beneficiary which has not been added to vesting"
        );
        vestedBeneficiaries[_beneficiary].pricePerToken = _price;
    }

    /**
     * @notice Allows releasing tokens earlier for a certain beneficiary.
     * @param _beneficiary the address of the beneficiary
     * @param _time how much time worth of tokens to unlock in seconds
     */
    function earlyUnlock(address _beneficiary, uint256 _time) public onlyOwner {
        require(
            vestedBeneficiaries[_beneficiary].tier != 0,
            "Beneficiary must exist"
        );
        if (releasableAmount(_beneficiary) > 0) {
            release(_beneficiary);
        }
        Vest memory vBeneficiary = vestedBeneficiaries[_beneficiary];
        require(
            block.timestamp < vBeneficiary.startTime + threeYears &&
                block.timestamp > vBeneficiary.startTime,
            "Not within vesting period"
        );

        uint256 realUnlockTime = _time;
        if (block.timestamp < vBeneficiary.startTime + threeYears - _time) {
            realUnlockTime =
                vBeneficiary.startTime +
                threeYears -
                block.timestamp;
        }

        // calculate amount to release
        uint256 beneficiaryTotalAmount = vestingTiers[vBeneficiary.role][
            vBeneficiary.tier
        ] / vBeneficiary.pricePerToken;
        uint256 toRelease = (beneficiaryTotalAmount * realUnlockTime) /
            threeYears;

        vestedBeneficiaries[_beneficiary].startTime -= realUnlockTime;
        token.safeTransfer(_beneficiary, toRelease);
        emit EarlyUnlock(_beneficiary, realUnlockTime, toRelease);
    }

    /**
     * @notice Allows owner to withdraw tokens from the contract.
     * @param _amount amount of JONES to withdraw
     */
    function withdrawToken(uint256 _amount) public onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        token.safeTransfer(msg.sender, _amount);
    }

    /*---- EXTERNAL/PUBLIC FUNCTIONS ----*/

    /**
     * @notice Transfers vested tokens to beneficiary.
     * @param beneficiary the beneficiary to release the JONES to
     */
    function release(address beneficiary) public returns (uint256 unreleased) {
        unreleased = releasableAmount(beneficiary);

        require(unreleased > 0, "No releasable amount");
        require(
            vestedBeneficiaries[beneficiary].lastReleaseTime + 300 <=
                block.timestamp,
            "Can only release every 5 minutes"
        );

        vestedBeneficiaries[beneficiary].released += unreleased;

        vestedBeneficiaries[beneficiary].lastReleaseTime = block.timestamp;

        token.safeTransfer(beneficiary, unreleased);

        emit TokensReleased(beneficiary, unreleased);
    }

    /**
     * @notice Transfers vested tokens to message sender.
     */
    function selfRelease() public {
        release(msg.sender);
    }

    /*---- VIEWS ----*/

    /**
     * @notice Calculates the amount that has already vested but hasn't been released yet.
     * @param beneficiary address of the beneficiary
     */
    function releasableAmount(address beneficiary)
        public
        view
        returns (uint256)
    {
        Vest memory vBeneficiary = vestedBeneficiaries[beneficiary];
        uint256 beneficiaryTotalAmount = vestingTiers[vBeneficiary.role][
            vBeneficiary.tier
        ] / vBeneficiary.pricePerToken;

        if (block.timestamp > vBeneficiary.startTime + threeYears) {
            // if we are past vest end
            return
                (beneficiaryTotalAmount *
                    ((vBeneficiary.startTime + threeYears) -
                        vBeneficiary.lastReleaseTime)) / threeYears;
        } else if (block.timestamp < vBeneficiary.startTime) {
            // if we are before vest start
            return 0;
        } else {
            // if we are during vest
            return
                (beneficiaryTotalAmount *
                    (block.timestamp - vBeneficiary.lastReleaseTime)) /
                threeYears;
        }
    }

    /**
     * @notice Calculates seconds left until vesting ends.
     * @param beneficiary address of the beneficiary
     */
    function vestTimeLeft(address beneficiary) public view returns (uint256) {
        uint256 vestingEnd = vestedBeneficiaries[beneficiary].startTime +
            threeYears;
        return
            block.timestamp < vestingEnd ? (block.timestamp - vestingEnd) : 0;
    }

    /*---- EVENTS ----*/

    event TokensReleased(address beneficiary, uint256 amount);

    event AddBeneficiary(
        address beneficiary,
        uint8 role,
        uint8 tier,
        uint256 initialReleaseAmount,
        uint256 duration,
        uint256 timeLeft,
        uint256 pricePerToken
    );

    event RemoveBeneficiary(address beneficiary);

    event UpdateBeneficiaryTier(
        address beneficiary,
        uint8 oldTier,
        uint8 newTier,
        uint256 vestingLeft
    );

    event UpdateBeneficiaryAddress(address oldAddress, address newAddress);

    event EarlyUnlock(address beneficiary, uint256 time, uint256 amount);
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
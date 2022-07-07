// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../libraries/BlackListToken.sol";
import "../presale/JoyPresale.sol";

contract XJoyToken is BlackListToken {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    ////////////////////////////////////////////////////////////////////////
    // State variables
    ////////////////////////////////////////////////////////////////////////
    uint256 public manualMinted;
    address public privatePresaleAddress;
    address public seedPresaleAddress;

    ////////////////////////////////////////////////////////////////////////
    // Events & Modifiers
    ////////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////////////
    // Initialization functions
    ////////////////////////////////////////////////////////////////////////

    function initialize(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) public virtual initializer {
        __ERC20_init(name, symbol);
        __BlackList_init();
        _mint(_msgSender(), initialSupply);
        addAuthorized(_msgSender());
        manualMinted = 0;
    }

    ////////////////////////////////////////////////////////////////////////
    // External functions
    ////////////////////////////////////////////////////////////////////////
    function name() public view virtual override returns (string memory) {
        return "xJOY Token";
    }
    
    function symbol() public view virtual override returns (string memory) {
        return "xJOY";
    }
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public onlyOwner {
        _burn(_from, _amount);
    }

    function manualMint(address _to, uint256 _amount) public onlyAuthorized {
        _mint(_to, _amount);
        manualMinted = manualMinted.add(_amount);
    }

    // add purchaser
    function addPurchaser(address addr) public onlyAuthorized {
      addBlackList(addr);
    }

    function updatePresaleAddresses(address _privatePresaleAddress, address _seedPresaleAddress) public onlyAuthorized {
        privatePresaleAddress = _privatePresaleAddress;
        seedPresaleAddress = _seedPresaleAddress;
    }

    function isTransferable(address _from, address _to, uint256 _amount) public view virtual override returns (bool) {
        JoyPresale privatePresale = JoyPresale(privatePresaleAddress);
        JoyPresale seedPresale = JoyPresale(seedPresaleAddress);

        bool isLockedInPrivatePresale = privatePresale.checkLockingPeriod(_from);
        bool isLockedInSeedPresale = seedPresale.checkLockingPeriod(_from);

        require(!isLockedInPrivatePresale && !isLockedInSeedPresale, "[email protected]: _from is in locked in presale SC");
        // if (isBlackListChecking) {
        //     // require(!isBlackListed[_from], "[email protected]: _from is in isBlackListed");
        //     // require(!isBlackListed[_to] || isWhiteListed[_to], "[email protected]: _to is in isBlackListed");
        //     require(!isBlackListed[_from] || isWhiteListed[_to], "[email protected]: _from is in isBlackListed");
        // }
        return true;
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
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
pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "../utils/AuthorizableU.sol";

contract BlackListToken is ERC20Upgradeable, AuthorizableU {
    ////////////////////////////////////////////////////////////////////////
    // State variables
    ////////////////////////////////////////////////////////////////////////    
    
    bool public isBlackListChecking;
    mapping (address => bool) public isBlackListed; // for from address
    mapping (address => bool) public isWhiteListed; // for to address
    
    ////////////////////////////////////////////////////////////////////////
    // Events & Modifiers
    ////////////////////////////////////////////////////////////////////////

    event SetBlackList(address[] _users, bool _status);
    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);

    event SetWhiteList(address[] _users, bool _status);
    event AddedWhiteList(address _user);
    event RemovedWhiteList(address _user);    

    modifier whenTransferable(address _from, address _to, uint256 _amount) {
        require(isTransferable(_from, _to, _amount), "[email protected]: transfer isn't allowed");
        _;
    }

    ////////////////////////////////////////////////////////////////////////
    // Initialization functions
    ////////////////////////////////////////////////////////////////////////

    function __BlackList_init() internal virtual initializer {
        __Authorizable_init();

        isBlackListChecking = true;
    }
    
    ////////////////////////////////////////////////////////////////////////
    // External functions
    ////////////////////////////////////////////////////////////////////////
    
    function startBlackList(bool _status) public onlyAuthorized {
        isBlackListChecking = _status;
    }

    // Blacklist
    function setBlackList(address[] memory _addrs, bool _status) public onlyAuthorized {
        for (uint256 i; i < _addrs.length; ++i) {
            isBlackListed[_addrs[i]] = _status;
        }

        emit SetBlackList(_addrs, _status);
    }

    function addBlackList(address _toAdd) public onlyAuthorized {
        isBlackListed[_toAdd] = true;

        emit AddedBlackList(_toAdd);
    }

    function removeBlackList(address _toRemove) public onlyAuthorized {
        isBlackListed[_toRemove] = false;

        emit RemovedBlackList(_toRemove);
    }
    
    // Whitelist
    function setWhiteList(address[] memory _addrs, bool _status) public onlyAuthorized {
        for (uint256 i; i < _addrs.length; ++i) {
            isWhiteListed[_addrs[i]] = _status;
        }

        emit SetWhiteList(_addrs, _status);
    }

    function addWhiteList(address _toAdd) public onlyAuthorized {
        isWhiteListed[_toAdd] = true;

        emit AddedWhiteList(_toAdd);
    }

    function removeWhiteList (address _toRemove) public onlyAuthorized {
        isWhiteListed[_toRemove] = false;

        emit RemovedWhiteList(_toRemove);
    }
    
    function isTransferable(address _from, address _to, uint256 _amount) public view virtual returns (bool) {
        if (isBlackListChecking) {
            // require(!isBlackListed[_from], "[email protected]: _from is in isBlackListed");
            // require(!isBlackListed[_to] || isWhiteListed[_to], "[email protected]: _to is in isBlackListed");
            require(!isBlackListed[_from] || isWhiteListed[_to], "[email protected]: _from is in isBlackListed");            
        }
        return true;
    }

    ////////////////////////////////////////////////////////////////////////
    // Internal functions
    ////////////////////////////////////////////////////////////////////////

    function _transfer(address _from, address _to, uint256 _amount) internal virtual override whenTransferable(_from, _to, _amount) {
        super._transfer(_from, _to, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "../utils/AuthorizableU.sol";
import "../token/XJoyToken.sol";

contract JoyPresale is ContextUpgradeable, AuthorizableU {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    ////////////////////////////////////////////////////////////////////////
    // State variables
    ////////////////////////////////////////////////////////////////////////    

    // Info of each coin like USDT, USDC
    struct CoinInfo {
        address addr;
        uint256 rate;
    }

    // Info of each Vesting
    struct VestingInfo {
        uint8   initClaimablePercent;   // Init Claimable Percent
        uint256 lockingDuration;        // Locking Duration
        uint256 vestingDuration;        // Vesting Duration
    }

    // Info of each Purchaser
    struct UserInfo {
        uint8   vestingIndex;           // Index of VestingInfo
        uint256 depositedAmount;        // How many Coins amount the user has deposited.
        uint256 purchasedAmount;        // How many JOY tokens the user has purchased.
        uint256 withdrawnAmount;        // Withdrawn amount
        uint256 firstDepositedTime;     // Last Deposited time
        uint256 lastWithdrawnTime;      // Last Withdrawn time
    }

    // The JOY Token
    IERC20Upgradeable public govToken;
    // The xJOY Token
    IERC20Upgradeable public xGovToken;

    // treasury addresses
    address[] public treasuryAddrs;
    uint16 public treasuryIndex;

    // Coin Info list
    CoinInfo[] public coinList;
    uint8 public COIN_DECIMALS;

    // Vesting Info
    VestingInfo[] public vestingList;       // 0: Seed, 1: Presale A
    uint8 public VESTING_INDEX;

    // Sale flag and time
    bool public SALE_FLAG;
    uint256 public SALE_START;
    uint256 public SALE_DURATION;

    // GovToken public flag
    bool public GOVTOKEN_PUBLIC_FLAG;

    // User address => UserInfo
    mapping(address => UserInfo) public userList;
    address[] public userAddrs;

    // total tokens amounts (all 18 decimals)
    uint256 public totalSaleAmount;
    uint256 public totalSoldAmount;
    uint256 public totalCoinAmount;

    ////////////////////////////////////////////////////////////////////////
    // Events & Modifiers
    ////////////////////////////////////////////////////////////////////////

    // Events.
    event TokensPurchased(address indexed purchaser, uint256 coinAmount, uint256 tokenAmount);
    event TokensWithdrawed(address indexed purchaser, uint256 tokenAmount);

    // Modifiers.
    modifier whenSale() {
        require(checkSalePeriod(), "This is not sale period.");
        _;
    }
    modifier whenVesting(address userAddr) {
        require(checkVestingPeriod(userAddr), "This is not vesting period.");
        _;
    }

    ////////////////////////////////////////////////////////////////////////
    // Initialization functions
    ////////////////////////////////////////////////////////////////////////

    function initialize(
        IERC20Upgradeable _govToken, 
        IERC20Upgradeable _xGovToken, 
        uint256 _totalSaleAmount,
        CoinInfo[] memory _coinList,
        VestingInfo[] memory _vestingList
    ) public virtual initializer
    {
        __Context_init();
        __Authorizable_init();
        addAuthorized(_msgSender());

        govToken = _govToken;
        xGovToken = _xGovToken;
        
        treasuryIndex = 0;

        COIN_DECIMALS = 18;
        setCoinList(_coinList);

        setVestingList(_vestingList);
        VESTING_INDEX = 0;

        startSale(false);
        updateSaleDuration(60 days);

        setGovTokenPublicFlag(false);

        updateTotalSaleAmount(_totalSaleAmount);
    }

    ////////////////////////////////////////////////////////////////////////
    // External functions
    ////////////////////////////////////////////////////////////////////////

    // Update token
    function updateTokens(IERC20Upgradeable _govToken, IERC20Upgradeable _xGovToken) public onlyAuthorized {
        govToken = _govToken;
        xGovToken = _xGovToken;
    }

    // Update the treasury address
    function updateTreasuryAddrs(address[] memory _treasuryAddrs) public onlyOwner {
        delete treasuryAddrs;
        for (uint i=0; i<_treasuryAddrs.length; i++) {
            treasuryAddrs.push(_treasuryAddrs[i]);
        }
        treasuryIndex = 0;
    }
    function updateTreasuryIndex(uint16 _treasuryIndex) public onlyAuthorized {
        treasuryIndex = _treasuryIndex;
        if (treasuryAddrs.length > 0 && treasuryIndex >= treasuryAddrs.length) {
            treasuryIndex = 0;
        }
    }

    // Set coin list
    function setCoinList(CoinInfo[] memory _coinList) public onlyAuthorized {
        delete coinList;
        for (uint i=0; i<_coinList.length; i++) {
            coinList.push(_coinList[i]);
        }
    }

    // Update coin info
    function updateCoinInfo(uint8 index, address addr, uint256 rate) public onlyAuthorized {
        coinList[index] = CoinInfo(addr, rate);
    }

    // Set vesting list
    function setVestingList(VestingInfo[] memory _vestingList) public onlyAuthorized {
        delete vestingList;
        for (uint i=0; i<_vestingList.length; i++) {
            vestingList.push(_vestingList[i]);
        }
    }

    function setVestingIndex(uint8 index) public onlyAuthorized {
        VESTING_INDEX = index;
    }

    // Update vesting info
    function updateVestingInfo(uint8 index, uint8 _initClaimablePercent, uint256 _lockingDuration, uint256 _vestingDuration) public onlyAuthorized {
        if (index == 255) {
            vestingList.push(VestingInfo(_initClaimablePercent, _lockingDuration, _vestingDuration));
        } else {
            vestingList[index] = VestingInfo(_initClaimablePercent, _lockingDuration, _vestingDuration);
        }
    }

    // Start stop sale
    function startSale(bool bStart) public onlyAuthorized {
        SALE_FLAG = bStart;
        if (bStart) {
            SALE_START = block.timestamp;
        }
    }

    // Set GovToken public flag
    function setGovTokenPublicFlag(bool bFlag) public onlyAuthorized {
        GOVTOKEN_PUBLIC_FLAG = bFlag;
    }

    // Update sale duration
    function updateSaleDuration(uint256 saleDuration) public onlyAuthorized {
        SALE_DURATION = saleDuration;
    }

    // check sale period
    function checkSalePeriod() public view returns (bool) {
        return SALE_FLAG && block.timestamp >= SALE_START && block.timestamp <= SALE_START.add(SALE_DURATION);
    }

    // check locking period
    function checkLockingPeriod(address userAddr) public view returns (bool) {
        UserInfo memory userInfo = userList[userAddr];
        VestingInfo memory vestingInfo = getUserVestingInfo(userAddr);
        // return block.timestamp >= SALE_START && block.timestamp <= SALE_START.add(vestingInfo.lockingDuration);
        return block.timestamp >= userInfo.firstDepositedTime && block.timestamp <= userInfo.firstDepositedTime.add(vestingInfo.lockingDuration);
    }

    // check vesting period
    function checkVestingPeriod(address userAddr) public view returns (bool) {
        UserInfo memory userInfo = userList[userAddr];
        VestingInfo memory vestingInfo = getUserVestingInfo(userAddr);
        // uint256 VESTING_START = SALE_START.add(vestingInfo.lockingDuration);
        // return block.timestamp >= VESTING_START;
        uint256 VESTING_START = userInfo.firstDepositedTime.add(vestingInfo.lockingDuration);
        return GOVTOKEN_PUBLIC_FLAG || block.timestamp >= VESTING_START;
        
    }

    // Update total sale amount
    function updateTotalSaleAmount(uint256 amount) public onlyAuthorized {
        totalSaleAmount = amount;
    }

    // Get user addrs
    function getUserAddrs() public view returns (address[] memory) {
        address[] memory returnData = new address[](userAddrs.length);
        for (uint i=0; i<userAddrs.length; i++) {
            returnData[i] = userAddrs[i];
        }
        return returnData;
    }
    
    // Get user's vesting info
    function getUserVestingInfo(address userAddr) public view returns (VestingInfo memory) {
        UserInfo memory userInfo = userList[userAddr];
        VestingInfo memory vestingInfo = vestingList[userInfo.vestingIndex];
        return vestingInfo;
    }

    // Set User Info
    function setUserInfo(address _addr, uint8 _vestingIndex, uint256 _depositedTime, uint256 _depositedAmount, uint256 _purchasedAmount, uint256 _withdrawnAmount) public onlyAuthorized {
        UserInfo storage userInfo = userList[_addr];
        if (userInfo.depositedAmount == 0) {
            userAddrs.push(_addr);
            
            userInfo.vestingIndex = _vestingIndex;
            userInfo.firstDepositedTime = block.timestamp;
            userInfo.depositedAmount = 0;
            userInfo.purchasedAmount = 0;
            userInfo.withdrawnAmount = 0;
        } else {
            totalCoinAmount = totalCoinAmount.sub(Math.min(totalCoinAmount, userInfo.depositedAmount));
            totalSoldAmount = totalSoldAmount.sub(Math.min(totalSoldAmount, userInfo.purchasedAmount));
        }
        totalCoinAmount = totalCoinAmount.add(_depositedAmount);
        totalSoldAmount = totalSoldAmount.add(_purchasedAmount);

        if (_depositedTime > 0) {
            userInfo.firstDepositedTime = _depositedTime;
        }
        userInfo.depositedAmount = userInfo.depositedAmount.add(_depositedAmount);
        userInfo.purchasedAmount = userInfo.purchasedAmount.add(_purchasedAmount);
        userInfo.withdrawnAmount = userInfo.withdrawnAmount.add(_withdrawnAmount);

        XJoyToken _xJoyToken = XJoyToken(address(xGovToken));
        _xJoyToken.addPurchaser(_addr);
    }

    // Seed User List
    function transTokenListByAdmin(address[] memory _userAddrs, UserInfo[] memory _userList, bool _transferToken) public onlyOwner {
        for (uint i=0; i<_userAddrs.length; i++) {
            setUserInfo(_userAddrs[i], _userList[i].vestingIndex, _userList[i].firstDepositedTime, _userList[i].depositedAmount, _userList[i].purchasedAmount, _userList[i].withdrawnAmount);
            if (_transferToken) {
                xGovToken.safeTransfer(_userAddrs[i], _userList[i].purchasedAmount);
            }
        }
    }
    function transTokenByAdmin(address _userAddr, uint8 _vestingIndex, uint256 _depositedTime, uint256 _depositedAmount, uint256 _purchasedAmount, bool _transferToken) public onlyOwner {
        setUserInfo(_userAddr, _vestingIndex, _depositedTime, _depositedAmount, _purchasedAmount, 0);
        if (_transferToken) {
            xGovToken.safeTransfer(_userAddr, _purchasedAmount);
        }
    }

    // Deposit
    // coinAmount (decimals: COIN_DECIMALS) 
    function deposit(uint256 _coinAmount, uint8 coinIndex) external whenSale {
        require( totalSaleAmount >= totalSoldAmount, "totalSaleAmount >= totalSoldAmount");

        CoinInfo memory coinInfo = coinList[coinIndex];
        IERC20Upgradeable coin = IERC20Upgradeable(coinInfo.addr);

        // calculate token amount to be transferred
        (uint256 tokenAmount, uint256 coinAmount) = calcTokenAmount(_coinAmount, coinIndex);
        uint256 availableTokenAmount = totalSaleAmount.sub(totalSoldAmount);

        // if the token amount is less than remaining
        if (availableTokenAmount < tokenAmount) {
            tokenAmount = availableTokenAmount;
            (_coinAmount, coinAmount) = calcCoinAmount(availableTokenAmount, coinIndex);
        }

        // validate purchasing
        _preValidatePurchase(_msgSender(), tokenAmount, coinAmount, coinIndex);

        // transfer coin and token
        coin.safeTransferFrom(_msgSender(), address(this), coinAmount);
        xGovToken.safeTransfer(_msgSender(), tokenAmount);

        // transfer coin to treasury
        if (treasuryAddrs.length != 0) {
            coin.safeTransfer(treasuryAddrs[treasuryIndex], coinAmount);
        }

        // update global state
        totalCoinAmount = totalCoinAmount.add(_coinAmount);
        totalSoldAmount = totalSoldAmount.add(tokenAmount);
        
       // update purchased token list
       UserInfo storage userInfo = userList[_msgSender()];
       if (userInfo.depositedAmount == 0) {
           userAddrs.push(_msgSender());
           userInfo.vestingIndex = 0;
           userInfo.firstDepositedTime = block.timestamp;
       }
       userInfo.depositedAmount = userInfo.depositedAmount.add(_coinAmount);
       userInfo.purchasedAmount = userInfo.purchasedAmount.add(tokenAmount);
       
       emit TokensPurchased(_msgSender(), _coinAmount, tokenAmount);

       XJoyToken _xJoyToken = XJoyToken(address(xGovToken));
       _xJoyToken.addPurchaser(_msgSender());
    }

    // Withdraw
    function withdraw() external whenVesting(_msgSender()) {
        uint256 withdrawalAmount = calcWithdrawalAmount(_msgSender());
        uint256 govTokenAmount = govToken.balanceOf(address(this));
        uint256 xGovTokenAmount = xGovToken.balanceOf(address(_msgSender()));
        uint256 withdrawAmount = Math.min(withdrawalAmount, Math.min(govTokenAmount, xGovTokenAmount));
       
        require(withdrawAmount > 0, "No withdraw amount!");
        require(xGovToken.allowance(_msgSender(), address(this)) >= withdrawAmount, "withdraw's allowance is low!");

        xGovToken.safeTransferFrom(_msgSender(), address(this), withdrawAmount);
        govToken.safeTransfer(_msgSender(), withdrawAmount);

        UserInfo storage userInfo = userList[_msgSender()];
        userInfo.withdrawnAmount = userInfo.withdrawnAmount.add(withdrawAmount);
        userInfo.lastWithdrawnTime = block.timestamp;

        emit TokensWithdrawed(_msgSender(), withdrawAmount);
    }

    // Calc token amount by coin amount
    function calcWithdrawalAmount(address userAddr) public view returns (uint256) {
        require(checkVestingPeriod(userAddr), "This is not vesting period.");

        UserInfo memory userInfo = userList[userAddr];
        VestingInfo memory vestingInfo = getUserVestingInfo(userAddr);
        // uint256 VESTING_START = SALE_START.add(vestingInfo.lockingDuration);
        uint256 VESTING_START = userInfo.firstDepositedTime.add(vestingInfo.lockingDuration);

        uint256 totalAmount = 0;
        if (block.timestamp <= VESTING_START) {
            totalAmount = userInfo.purchasedAmount.mul(vestingInfo.initClaimablePercent).div(100);
        } else if (block.timestamp >= VESTING_START.add(vestingInfo.vestingDuration)) {
            totalAmount = userInfo.purchasedAmount;
        } else {
            totalAmount = userInfo.purchasedAmount.mul(block.timestamp.sub(VESTING_START)).div(vestingInfo.vestingDuration);
        }

        uint256 withdrawalAmount = totalAmount.sub(userInfo.withdrawnAmount);
        return withdrawalAmount;
    }

    // Calc token amount by coin amount
    function calcTokenAmount(uint256 _coinAmount, uint8 coinIndex) public view returns (uint256, uint256) {
        require( coinList.length > coinIndex, "coinList.length > coinIndex");

        CoinInfo memory coinInfo = coinList[coinIndex];
        ERC20Upgradeable coin = ERC20Upgradeable(coinInfo.addr);
        uint256 rate = coinInfo.rate;

        uint tokenDecimal =  ERC20Upgradeable(address(xGovToken)).decimals() + coin.decimals() - COIN_DECIMALS;
        uint256 tokenAmount = _coinAmount
        .mul(10**tokenDecimal)
        .div(rate);
        
        uint coinDecimal =  COIN_DECIMALS - coin.decimals();
        uint256 coinAmount = _coinAmount
        .div(10**coinDecimal);

        return (tokenAmount, coinAmount);
    }

    // Calc coin amount by token amount
    function calcCoinAmount(uint256 _tokenAmount, uint8 coinIndex) public view returns (uint256, uint256) {
        require( coinList.length > coinIndex, "coinList.length > coinIndex");

        CoinInfo memory coinInfo = coinList[coinIndex];
        ERC20Upgradeable coin = ERC20Upgradeable(coinInfo.addr);
        uint256 rate = coinInfo.rate;

        uint _coinDecimal =  ERC20Upgradeable(address(xGovToken)).decimals() + coin.decimals() - COIN_DECIMALS;
        uint256 _coinAmount = _tokenAmount
        .div(10**_coinDecimal)
        .mul(rate);
        
        uint coinDecimal =  COIN_DECIMALS - coin.decimals();
        uint256 coinAmount = _coinAmount
        .div(10**coinDecimal);

        return (_coinAmount, coinAmount);
    }

    // Calc max coin amount to be deposit
    function calcMaxCoinAmountToBeDeposit(uint8 coinIndex) public view returns (uint256) {
        uint256 availableTokenAmount = totalSaleAmount.sub(totalSoldAmount);
        (uint256 _coinAmount,) = calcCoinAmount(availableTokenAmount, coinIndex);
        return _coinAmount;
    }

    // Withdraw all coins by owner
    function withdrawAllCoins(address treasury) public onlyOwner {
        for (uint i=0; i<coinList.length; i++) {
            CoinInfo memory coinInfo = coinList[i];
            IERC20Upgradeable _coin = IERC20Upgradeable(coinInfo.addr);
            uint256 coinAmount = _coin.balanceOf(address(this));
            _coin.safeTransfer(treasury, coinAmount);
        }
    }

    // Withdraw all xJOY by owner
    function withdrawAllxGovTokens(address treasury) public onlyOwner {
        uint256 tokenAmount = xGovToken.balanceOf(address(this));
        xGovToken.safeTransfer(treasury, tokenAmount);
    }

    // Withdraw all $JOY by owner
    function withdrawAllGovTokens(address treasury) public onlyOwner {
        uint256 tokenAmount = govToken.balanceOf(address(this));
        govToken.safeTransfer(treasury, tokenAmount);
    }

    ////////////////////////////////////////////////////////////////////////
    // Internal functions
    ////////////////////////////////////////////////////////////////////////

    // Validate purchase
    function _preValidatePurchase(address purchaser, uint256 tokenAmount, uint256 coinAmount, uint8 coinIndex) internal view {
        require( coinList.length > coinIndex, "coinList.length > coinIndex");
        CoinInfo memory coinInfo = coinList[coinIndex];
        IERC20Upgradeable coin = IERC20Upgradeable(coinInfo.addr);

        require(purchaser != address(0), "Purchaser is the zero address");
        require(coinAmount != 0, "Coin amount is 0");
        require(tokenAmount != 0, "Token amount is 0");

        require(xGovToken.balanceOf(address(this)) >= tokenAmount, "$xJoyToken amount is lack!");
        require(coin.balanceOf(msg.sender) >= coinAmount, "Purchaser's coin amount is lack!");
        require(coin.allowance(msg.sender, address(this)) >= coinAmount, "Purchaser's allowance is low!");

        this;
    }
}

// SPDX-License-Identifier: MIT

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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract AuthorizableU is OwnableUpgradeable {
    ////////////////////////////////////////////////////////////////////////
    // State variables
    ////////////////////////////////////////////////////////////////////////

    mapping(address => bool) public isAuthorized;

    ////////////////////////////////////////////////////////////////////////
    // Events & Modifiers
    ////////////////////////////////////////////////////////////////////////

    modifier onlyAuthorized() {
        require(isAuthorized[msg.sender] || owner() == msg.sender, "caller is not authorized");
        _;
    }

    ////////////////////////////////////////////////////////////////////////
    // Initialization functions
    ////////////////////////////////////////////////////////////////////////

    function __Authorizable_init() internal virtual initializer {
        __Ownable_init();
    }

    ////////////////////////////////////////////////////////////////////////
    // External functions
    ////////////////////////////////////////////////////////////////////////
    function addAuthorized(address _toAdd) public onlyOwner {
        isAuthorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) public onlyOwner {
        require(_toRemove != msg.sender);
        
        isAuthorized[_toRemove] = false;
    }

    ////////////////////////////////////////////////////////////////////////
    // Internal functions
    ////////////////////////////////////////////////////////////////////////
}

// SPDX-License-Identifier: MIT

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721MintProxy.sol";

contract EtherPayableERC721Minter is ERC721MintProxy {

    using SafeMath for uint256;

    constructor(
        address settingsAddress, 
        address paymentReceiverAddress,
        uint256 maxItemsPerMintValue
    ) ERC721MintProxy(
        settingsAddress, 
        paymentReceiverAddress, 
        maxItemsPerMintValue
    ) 
    {}

    function preMint(address token, uint256 total) internal override virtual {
        require(maxItemsPerMint >= total, "exceeds_max_items_per_mint");
        
        MintInfo storage info = mintInfo[token];
        require(info.exist, "mint_info_not_set");
        require(info.allowMint, "!mint_allowed");
        require(!info.paused, "mint_paused");
        require(info.totalItems >= info.mintedItems.add(total), "total_items_claimed");
        require(!senderExceedsMaxMint(token, total, info), 
            "msg.sender will exceed the absolute, maximum number of tokens that it can mint from the ERC721 contract");

        uint256 totalPrice = info.pricePerUnit.mul(total);
        require(totalPrice <= msg.value, "totalPrice > msg.value");

        info.mintedItems = info.mintedItems.add(total);
    }

    function postMint(address token, uint256 total) internal override virtual {
        payable(paymentReceiver).transfer(msg.value);
    }

    function preMintTo(address token, address to, uint256 total) internal override virtual {
        super.preMintTo(token, to, total);
        preMint(token, total);
    }

    function postMintTo(address token,  address to, uint256 total) internal override virtual {
        payable(paymentReceiver).transfer(msg.value);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../tokens/erc721/IERC721Mintable.sol";
import "../base/Base.sol";

/**
 * A proxy for IERC721Mintable contracts that exposes and controls their 'mint' functionality.
 */
abstract contract ERC721MintProxy is Base {
    using SafeMath for uint256;

    /*
     * Contains configuration settings which defines how the minter controls the mint functionality of a mappped 
     * ERC721 contract. Each contract that this minter controls is mapped to a MintInfo.
     */
    struct MintInfo {
        uint256 pricePerUnit;
        uint256 totalItems;  // Total number of tokens that the minter is allowed to mint from a mapped ERC721 contract
        uint256 mintedItems; // Total number of tokens that the minter has already minted from a mapped ERC721 contract
        uint256 maxMint;     // The 'absolute, maximum number' of tokens that a sender address can mint from a mapped ERC721 contract
        bool pauseMaxMint;   // Set to true to disregard 'maxMint'
        bool allowMint;      // Set to true if the minter is allowed to mint tokens from a mapped ERC721 contract
        bool paused;         // Set to true if minting is temporarily paused for a mapped ERC721 contract
        bool exist;          // false by default. Is set to true when a MintInfo is mapped to an ERC721 contract
    }

    // mapping from an ERC721 contract address to its MintInfo
    mapping(address => MintInfo) public mintInfo;

    // set to true to allow any address to invoke the 'mint' function of the minter
    bool public whitelistEnded;

    // address is mapped to true if it's allowed to invoke the 'mint' function of the minter
    mapping(address => bool) private _whitelistAddresses;

    // The maximum number of tokens that the minter is allowed to mint 'per transaction' 
    uint256 public maxItemsPerMint;

    // address that will receive the payment for minting fees
    address public paymentReceiver;

    constructor(
        address settingsAddress,
        address paymentReceiverAddress,
        uint256 maxItemsPerMintValue
    ) Base(settingsAddress) {
        paymentReceiver = paymentReceiverAddress;
        maxItemsPerMint = maxItemsPerMintValue;
    }

    function setMaxItemsPerMint(uint256 newMaxItemsPerMint) external onlyOwner(msg.sender) {
        require(maxItemsPerMint != newMaxItemsPerMint, "new_max_items_per_mint");

        maxItemsPerMint = newMaxItemsPerMint;

        emit Uint256PropertyUpdated("MaxItemsPerMint", newMaxItemsPerMint);
    }

    function setPaymentReceiver(address newPaymentReceiver) external onlyOwner(msg.sender) {
        require(paymentReceiver != newPaymentReceiver, "new_payment_receiver");

        paymentReceiver = newPaymentReceiver;

        emit AddressPropertyUpdated("PaymentReceiver", newPaymentReceiver);
    }

    function setMintInfo(
        address token,
        uint256 pricePerUnit,
        uint256 totalItems,
        uint256 mintedItems,
        uint256 maxMint,
        bool pauseMaxMint,
        bool allowMint,
        bool paused
    ) external onlyOwner(msg.sender) {
        require(token != address(0x0), "token_required");
        require(totalItems >= mintedItems, "!total_eq_minted_items");
        mintInfo[token].pricePerUnit = pricePerUnit;
        mintInfo[token].totalItems = totalItems;
        mintInfo[token].mintedItems = mintedItems;
        mintInfo[token].allowMint = allowMint;
        mintInfo[token].maxMint = maxMint;
        mintInfo[token].pauseMaxMint = pauseMaxMint;
        mintInfo[token].paused = paused;
        mintInfo[token].exist = true;

        emit NewMintInfo(token);
    }

    function setAllowMint(
        address token,
        bool allowMint_
    ) external onlyOwner(msg.sender) {
        require(mintInfo[token].exist, "mint_info_not_set");
        mintInfo[token].allowMint = allowMint_;
        emit NewMintInfo(token);
    }

    function setMaxMint(address token_, uint256 maxMint_) external onlyOwner(msg.sender) {
        require(mintInfo[token_].exist, "mint_info_not_set");
        mintInfo[token_].maxMint = maxMint_;
        emit NewMintInfo(token_);
    }

    function setPauseMaxMint(address token_, bool pauseMaxMint_) external onlyOwner(msg.sender) {
        require(mintInfo[token_].exist, "mint_info_not_set");
        mintInfo[token_].pauseMaxMint = pauseMaxMint_;
        emit NewMintInfo(token_);
    }

    function mint(address token, uint256 total) payable external virtual onlyWhitelisted {
        preMint(token, total);        
        unsafeMint(token, total);
        postMint(token, total);
    }

    function preMint(address token, uint256 total) internal virtual;

    function unsafeMint (address token, uint256 total) internal virtual {
        /* uint256[] memory tokenIds = new uint256[](total);
        for (uint256 index = 0; index < total; index++) {
            IERC721Mintable(token).mint(msg.sender);
            tokenIds[index] = IERC721Mintable(token).totalMinted();
        }

        emit NewTokensMinted(token, msg.sender, tokenIds); */
        unsafeMintTo(token, msg.sender, total);
    }

    function postMint(address token, uint256 total) internal virtual;

    /**
     * Lets msg.sender to mint NFT's in behalf of 'to'.
     * 
     * - 'token' is the address of the ERC721 contract to mint NFT's from
     * - 'to' is the owner of the NFT's to be minted
     * - 'total' is the total number of NFT's to be minted by msg.sender in behalf of 'to'
     */
    function mintTo(address token, address to, uint256 total) payable external virtual onlyWhitelisted {
        preMintTo(token, to, total);        
        unsafeMintTo(token, to, total);
        postMintTo(token, to, total);
    }

    function preMintTo(address token, address to, uint256 total) internal virtual {
        require(to!= address(0), "to_must_be_non_zero_address");
    }

    function unsafeMintTo (address token, address to, uint256 total) internal virtual {
        uint256[] memory tokenIds = new uint256[](total);
        for (uint256 index = 0; index < total; index++) {
            IERC721Mintable(token).mint(to);
            tokenIds[index] = IERC721Mintable(token).totalMinted();
        }

        emit NewTokensMinted(token, to, tokenIds);
    }

    function postMintTo(address token,  address to, uint256 total) internal virtual;

    /**
     * Returns true if the 'total_' number of NFT's that 'msg.sender' plans to mint from the ERC721 contract 'token_',
     * exceeds the absolute, maximum number of NFT's that an address can mint from it (defined in MintInfo.maxMint),
     * else returns false. Always returns false if the condition for checking the max mint limit has been paused 
     * (defined in MintInfo.pauseMaxMint == true).
     *
     * - 'token_' is the address of an ERC721 contract that msg.sender plans to mint NFT's from
     *
     * - 'total_' refers to the total number of NFT's that msg.sender plans to mint from 'token_'
     *
     * - 'mintInfo_' refers to the MintInfo of 'token_'
     */
    function senderExceedsMaxMint(address token_, uint256 total_, MintInfo memory mintInfo_) internal view returns (bool) {
        if (mintInfo_.pauseMaxMint) {
            return false;
        }

        uint256 totalMint = IERC721Mintable(token_).numberMinted(msg.sender).add(total_); 
        if (mintInfo_.maxMint >= totalMint) {
            return false;
        }
        return true;
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return _whitelistAddresses[_address];
    }

    modifier onlyWhitelisted() {
        require(
            whitelistEnded || isWhitelisted(msg.sender),
            "Account not whitelisted"
        );
        _;
    }

    function setWhitelistedAccounts(address[] memory _whitelist)
        public
        onlyOwner(msg.sender)
    {
        for (uint256 i = 0; i < _whitelist.length; i++) {
            _whitelistAddresses[_whitelist[i]] = true;
        }
    }

    function setWhitelistedEnd(bool ended) public onlyOwner(msg.sender) {
        whitelistEnded = ended;
    }

    function addUser(address _address) public onlyOwner(msg.sender) {
        _whitelistAddresses[_address] = true;
        emit AddedToWhitelist(_address);
    }

    function removeUser(address _address) public onlyOwner(msg.sender) {
        _whitelistAddresses[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    /* Events */

    event NewTokensMinted(address indexed token, address indexed account, uint256[] tokenIds);

    event NewMintInfo(address indexed token);

    event AddressPropertyUpdated(bytes32 indexed propertyName, address newValue);

    event Uint256PropertyUpdated(bytes32 indexed propertyName, uint256 newValue);

    event AddedToWhitelist(address indexed account);

    event RemovedFromWhitelist(address indexed account);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IERC721Mintable is IERC721 {

    /**
     * @dev Creates a new token for `to`. Its token ID is automatically assigned 
     * (and is available in the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * Requirements:
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to) external;

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function totalMinted() external view returns (uint256);

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function numberMinted(address owner) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import "../roles/RolesManagerConsts.sol";
import "../settings/PlatformSettingsConsts.sol";

// Libraries
import "@openzeppelin/contracts/utils/Address.sol";

// Interfaces
import "../settings/IPlatformSettings.sol";
import "../roles/IRolesManager.sol";

abstract contract Base {
    using Address for address;

    /* Constant Variables */

    /* State Variables */

    address private settings;

    /* Modifiers */

    modifier whenPlatformIsPaused() {
        require(_settings().isPaused(), "PLATFORM_ISNT_PAUSED");
        _;
    }

    modifier whenPlatformIsNotPaused() {
        require(!_settings().isPaused(), "PLATFORM_IS_PAUSED");
        _;
    }

    modifier onlySigner(address account) {
        _requireHasRole(
            RolesManagerConsts(_rolesManager().consts()).SIGNER_ROLE(),
            account,
            "SENDER_ISNT_SIGNER"
        );
        _;
    }

    modifier onlyOwner(address account) virtual {
        _requireHasRole(
            RolesManagerConsts(_rolesManager().consts()).OWNER_ROLE(),
            account,
            "SENDER_ISNT_OWNER"
        );
        _;
    }

    modifier onlyCustomMinter(address account, bytes32 minterRole) {
        _requireHasRole(minterRole, account, "SENDER_ISNT_CUSTOM_MINTER");
        _;
    }

    modifier onlyConfigurator(address account) {
        _requireHasRole(
            RolesManagerConsts(_rolesManager().consts()).CONFIGURATOR_ROLE(),
            account,
            "SENDER_ISNT_CONFIGURATOR"
        );
        _;
    }

    modifier onlyPauser(address account) {
        _requireHasRole(
            RolesManagerConsts(_rolesManager().consts()).PAUSER_ROLE(),
            account,
            "SENDER_ISNT_PAUSER"
        );
        _;
    }

    /* Constructor */

    constructor(address settingsAddress) {
        require(settingsAddress.isContract(), "SETTINGS_MUST_BE_CONTRACT");
        settings = settingsAddress;
    }

    function setSettings(address newSettingsAddress) external onlyOwner(msg.sender) {
        require(newSettingsAddress.isContract(), "NEW_SETTINGS_MUST_BE_CONTRACT");
        require(settings != newSettingsAddress, "SETTINGS_MUST_BE_NEW");
        address oldSettingsAddress = settings;

        settings = newSettingsAddress;

        emit SettingsUpdated(msg.sender, oldSettingsAddress, newSettingsAddress);
    }

    /** Internal Functions */

    function _settings() internal view returns (IPlatformSettings) {
        return IPlatformSettings(settings);
    }

    function _settingsConsts() internal view returns (PlatformSettingsConsts) {
        return PlatformSettingsConsts(_settings().consts());
    }

    function _rolesManager() internal view returns (IRolesManager) {
        return IRolesManager(IPlatformSettings(settings).rolesManager());
    }

    function _rolesManagerConsts() internal view returns (RolesManagerConsts) {
        return
            RolesManagerConsts(IRolesManager(IPlatformSettings(settings).rolesManager()).consts());
    }

    function _requireHasRole(
        bytes32 role,
        address account,
        string memory message
    ) internal view {
        IRolesManager rolesManager = _rolesManager();
        rolesManager.requireHasRole(role, account, message);
    }

    function _getPlatformSettingsValue(bytes32 name) internal view returns (uint256) {
        return _settings().getSettingValue(name);
    }

    /** Events */

    event SettingsUpdated(
        address indexed sender,
        address indexed oldSettingsAddress,
        address indexed newSettingsAddress
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RolesManagerConsts {
    /**
        @notice It is the AccessControl.DEFAULT_ADMIN_ROLE role.
     */
    bytes32 public constant OWNER_ROLE = keccak256("");

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    bytes32 public constant PIXU_MINTER_ROLE = keccak256("PIXU_MINTER_ROLE");

    bytes32 public constant PIXUCATS_MINTER_ROLE = keccak256("PIXUCATS_MINTER_ROLE");

    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");

    bytes32 public constant YUMIOS_MINTER_ROLE = keccak256("YUMIOS_MINTER_ROLE");
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PlatformSettingsConsts {
    bytes32 public constant PIXU_PAUSED = "PixuPaused";

    bytes32 public constant PIXU_CATS_PAUSED = "PixuCatsPaused";

    bytes32 public constant YUMIOS_PAUSED = "YumiosPaused";

    // This constants were added for the farming contracts.
    bytes32 public constant FARMING_BONUS_MULTIPLIER = "FarmingBonusMultiplier";

    bytes32 public constant FARMING_ALLOW_ONLY_EOA = "FarmingAllowOnlyEOA";
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../libs/SettingsLib.sol";

interface IPlatformSettings {
    event PlatformPaused(address indexed pauser);

    event PlatformUnpaused(address indexed unpauser);

    event ConstsUpdated(address indexed sender, address oldConsts, address newConsts);

    event PlatformSettingCreated(
        bytes32 indexed name,
        address indexed creator,
        uint256 value,
        uint256 minValue,
        uint256 maxValue
    );

    event PlatformSettingRemoved(bytes32 indexed name, address indexed remover, uint256 value);

    event PlatformSettingUpdated(
        bytes32 indexed name,
        address indexed remover,
        uint256 oldValue,
        uint256 newValue
    );

    function createSetting(
        bytes32 name,
        uint256 value,
        uint256 min,
        uint256 max
    ) external;

    function removeSetting(bytes32 name) external;

    function getSetting(bytes32 name) external view returns (SettingsLib.Setting memory);

    function getSettingValue(bytes32 name) external view returns (uint256);

    function hasSetting(bytes32 name) external view returns (bool);

    function rolesManager() external view returns (address);

    function isPaused() external view returns (bool);

    function requireIsPaused() external view;

    function requireIsNotPaused() external view;

    function consts() external view returns (address);

    function pause() external;

    function unpause() external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRolesManager {
    function multiGrantRole(bytes32 role, address[] calldata accounts) external;

    function multiRevokeRole(bytes32 role, address[] calldata accounts) external;

    function setConsts(address newConstsAddress) external;

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

    function requireHasRole(bytes32 role, address account) external view;

    function requireHasRole(
        bytes32 role,
        address account,
        string calldata message
    ) external view;

    function consts() external view returns (address);

    event ConstsUpdated(address indexed sender, address oldConsts, address newConsts);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SettingsLib {
    /**
        It defines a setting. It includes: value, min, and max values.
     */
    struct Setting {
        uint256 value;
        uint256 min;
        uint256 max;
        bool exists;
    }

    /**
        @notice It creates a new setting given a name, min and max values.
        @param value initial value for the setting.
        @param min min value allowed for the setting.
        @param max max value allowed for the setting.
     */
    function create(
        Setting storage self,
        uint256 value,
        uint256 min,
        uint256 max
    ) internal {
        requireNotExists(self);
        require(value >= min, "VALUE_MUST_BE_GT_MIN_VALUE");
        require(value <= max, "VALUE_MUST_BE_LT_MAX_VALUE");
        self.value = value;
        self.min = min;
        self.max = max;
        self.exists = true;
    }

    /**
        @notice Checks whether the current setting exists or not.
        @dev It throws a require error if the setting already exists.
        @param self the current setting.
     */
    function requireNotExists(Setting storage self) internal view {
        require(!self.exists, "SETTING_ALREADY_EXISTS");
    }

    /**
        @notice Checks whether the current setting exists or not.
        @dev It throws a require error if the current setting doesn't exist.
        @param self the current setting.
     */
    function requireExists(Setting storage self) internal view {
        require(self.exists, "SETTING_NOT_EXISTS");
    }

    /**
        @notice It updates a current setting.
        @dev It throws a require error if:
            - The new value is equal to the current value.
            - The new value is not lower than the max value.
            - The new value is not greater than the min value
        @param self the current setting.
        @param newValue the new value to set in the setting.
     */
    function update(Setting storage self, uint256 newValue) internal returns (uint256 oldValue) {
        requireExists(self);
        require(self.value != newValue, "NEW_VALUE_REQUIRED");
        require(newValue >= self.min, "NEW_VALUE_MUST_BE_GT_MIN_VALUE");
        require(newValue <= self.max, "NEW_VALUE_MUST_BE_LT_MAX_VALUE");
        oldValue = self.value;
        self.value = newValue;
    }

    /**
        @notice It removes a current setting.
        @param self the current setting to remove.
     */
    function remove(Setting storage self) internal {
        requireExists(self);
        self.value = 0;
        self.min = 0;
        self.max = 0;
        self.exists = false;
    }
}
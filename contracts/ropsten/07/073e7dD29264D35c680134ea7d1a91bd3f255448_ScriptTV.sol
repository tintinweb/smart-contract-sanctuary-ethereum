// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

// ERC-721 and ERC-20 interfaces
import "./ScriptPay/IScriptPay.sol";
import "./ScriptGlasses/IScriptGlasses.sol";
import "./ScriptGem/IScriptGem.sol";

/// Amount cannot be zero
error ZeroAmount();

/// Balance cannot be zero
error ZeroBalance();

/// Insufficient asset supply, current `supply`
error InsufficientSupply(uint24 supply);

/// User has insufficient balance, Needed `required` but has `balance`
error InsufficientFunds(uint256 balance, uint256 required);

/// @title Script TV
/// @author @n4beel
/// @notice Contract for Script TV - watch to earn platform
contract ScriptTV {
    // Address of the owner of ScriptTV
    address public owner;

    // Address of the SPAY Token
    IScriptPay public immutable spay;

    // Address of Glasses contract
    IScriptGlasses public immutable scriptGlasses;

    // Address of Gem contract
    IScriptGem public immutable gem;

    // Amount of SPAY tokens locked by an address
    mapping(address => uint256) public lockedBalance;

    // Glass struct for storing
    // maxSupply - max number of glasses that can be minted
    // mintedSupply - number of glasses already minted
    // collateral - amount of spay locked when minting a pair of glasses
    // cost - amount of spay burnt when minting a pair of glasses
    struct Glass {
        uint24 maxSupply;
        uint24 mintedSupply;
        uint256 collateral;
        uint256 cost;
    }

    // data of common glasses
    Glass public common = Glass(750000, 0, 20e18, 10e18);

    // data of rare glasses
    Glass public rare = Glass(200000, 0, 30e18, 20e18);

    // data of superscript glasses
    Glass public superscript = Glass(50000, 0, 40e18, 30e18);

    // cost of a gem in spay
    uint256 public constant GEM_COST = 20e18;

    /**
     * @notice Emitted when user receives a payout
     * @param to address of the receiver
     * @param value amount of spay to be paid out
     * @param payoutEvent event of the payout
     */
    event Payout(address indexed to, uint256 value, string indexed payoutEvent);

    /**
     * @notice Emitted when the user pays SPAY
     * @param from address of the spender
     * @param value amount of spay paid
     * @param paymentEvent event of the payment
     */
    event Payment(
        address indexed from,
        uint256 value,
        string indexed paymentEvent
    );

    /**
     * @notice Emitted when the user locks SPAY
     * @param user address of the user locking SPAY
     * @param value amount of spay locked
     */
    event LockSPAY(address indexed user, uint256 indexed value);

    /**
     * @notice Emitted when the user unlocks SPAY
     * @param user address of the user unlocking SPAY
     * @param value amount of spay unlocked
     */
    event UnlockSPAY(address indexed user, uint256 indexed value);

    /**
     * @notice Emitted when the user mints a pair of glasses
     * @param user address of the user minting the glasses
     * @param glassType type of glasses being minted
     * @param mintedSupply total number of glasses of the type minted
     */
    event GlassMinted(
        address indexed user,
        uint8 indexed glassType,
        uint24 mintedSupply
    );

    /**
     * @notice Emitted when the user mints gems
     * @param user address of the user minting the gems
     * @param numberMinted number of gems minted
     */
    event GemsMinted(address indexed user, uint256 indexed numberMinted);

    /**
     * @notice Constructor
     * @param _spay spay contract address
     * @param _scriptGlasses glasses contract address
     * @param _scriptGem gem contract address
     */
    constructor(
        IScriptPay _spay,
        IScriptGlasses _scriptGlasses,
        IScriptGem _scriptGem
    ) {
        spay = _spay;
        scriptGlasses = _scriptGlasses;
        gem = _scriptGem;
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        if (owner != msg.sender) {
            revert("not owner");
        }
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        if (newOwner == address(0)) {
            revert("0 address");
        }
        owner = newOwner;
    }

    /**
     * @notice Locks caller's tokens as investment
     * @param _amount amount of SPAY being locked
     */
    function _lockTokens(uint256 _amount) private {
        if (_amount == 0) {
            revert ZeroAmount();
        }

        spay.transferFrom(msg.sender, address(this), _amount);
        lockedBalance[msg.sender] += _amount;
        emit LockSPAY(msg.sender, _amount);
    }

    /**
     * @notice Unlocks all locked tokens of the caller
     */
    function unlockTokens() external {
        uint256 balance = lockedBalance[msg.sender];
        if (balance == 0) {
            revert ZeroBalance();
        }

        spay.transfer(msg.sender, balance);
        lockedBalance[msg.sender] = 0;
        emit UnlockSPAY(msg.sender, balance);
    }

    /**
     * @notice Mints a common glass, burns caller's spay and locks their collateral
     */
    function mintCommonGlass() external {
        uint256 cost = common.cost;
        uint256 collateral = common.collateral;
        if (common.mintedSupply >= common.maxSupply) {
            revert InsufficientSupply(common.mintedSupply);
        }
        if (spay.balanceOf(msg.sender) < cost + collateral) {
            revert InsufficientFunds(spay.balanceOf(msg.sender), cost);
        }

        scriptGlasses.safeMint(msg.sender);
        common.mintedSupply++;
        spay.burnFrom(msg.sender, cost);
        _lockTokens(collateral);

        emit GlassMinted(msg.sender, 0, common.mintedSupply);
    }

    /**
     * @notice Mints a rare glass, burns caller's spay and locks their collateral
     */
    function mintRareGlass() external {
        uint256 cost = rare.cost;
        uint256 collateral = rare.collateral;
        if (rare.mintedSupply >= rare.maxSupply) {
            revert InsufficientSupply(rare.mintedSupply);
        }
        if (spay.balanceOf(msg.sender) < cost + collateral) {
            revert InsufficientFunds(spay.balanceOf(msg.sender), cost);
        }

        scriptGlasses.safeMint(msg.sender);
        rare.mintedSupply++;
        spay.burnFrom(msg.sender, cost);
        _lockTokens(collateral);

        emit GlassMinted(msg.sender, 0, rare.mintedSupply);
    }

    /**
     * @notice Mints a superscript glass, burns caller's spay and locks their collateral
     */
    function mintSuperScriptGlass() external {
        uint256 cost = superscript.cost;
        uint256 collateral = superscript.collateral;
        if (superscript.mintedSupply >= superscript.maxSupply) {
            revert InsufficientSupply(superscript.mintedSupply);
        }
        if (spay.balanceOf(msg.sender) < cost + collateral) {
            revert InsufficientFunds(spay.balanceOf(msg.sender), cost);
        }

        scriptGlasses.safeMint(msg.sender);
        superscript.mintedSupply++;
        spay.burnFrom(msg.sender, cost);
        _lockTokens(collateral);

        emit GlassMinted(msg.sender, 0, superscript.mintedSupply);
    }

    /**
     * @notice Mints specified gems and burns caller's spay
     * @param _quantity number of gems to be minted
     */
    function mintGems(uint256 _quantity) external {
        uint256 totalTokens = GEM_COST * _quantity;
        if (spay.balanceOf(msg.sender) < totalTokens) {
            revert InsufficientFunds(spay.balanceOf(msg.sender), totalTokens);
        }

        gem.mint(msg.sender, _quantity);
        spay.burnFrom(msg.sender, totalTokens);

        emit GemsMinted(msg.sender, _quantity);
    }

    /**
     * @notice Rewards spay
     * @param _to address of the user to be rewarded
     * @param _amount amount of spay to be rewarded
     * @param _event event of the payout
     * @dev Only callable by Owner, will be called through meta transactions
     */
    function payout(
        address _to,
        uint256 _amount,
        string memory _event
    ) external onlyOwner {
        if (_amount == 0) {
            revert ZeroAmount();
        }
        spay.mint(_to, _amount);
        emit Payout(_to, _amount, _event);
    }

    /**
     * @notice Burns spay
     * @param _amount amount of spay to be burnt
     * @param _event event of the burn
     */
    function spend(uint256 _amount, string memory _event) external {
        if (_amount == 0) {
            revert ZeroAmount();
        }
        spay.burnFrom(msg.sender, _amount);
        emit Payment(msg.sender, _amount, _event);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Script Pay
/// @author @n4beel
/// @notice Interface for SPAY - native token of Script TV
interface IScriptPay is IERC20 {
    /**
     * @notice Mints SPAY
     * @param to address of the recipient
     * @param amount amount of SPAY to be minted
     * @dev Only callable by Owner, will be called by low level call function
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @title Common Glasses
/// @author @n4beel
/// @notice Interface for Script TV Glasses
interface IScriptGlasses {
    /**
     * @notice Mints NFT
     * @param to address of the recipient
     * @dev Only callable by Owner, will be called by low level call function
     */
    function safeMint(address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @title Script Gem
/// @author @n4beel
/// @notice Interface for Gems
interface IScriptGem {
    /**
     * @notice Mints gems
     * @param to address of the recipient
     * @param amount amount of gems to be minted
     * @dev Only callable by Owner, will be called by low level call function
     */
    function mint(address to, uint256 amount) external;
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
/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity 0.8.14;

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

// File: @openzeppelin/contracts/security/Pausable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity 0.8.14;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: contracts/lib/access/Owner.sol


pragma solidity 0.8.14;

contract Owner {
    address internal _owner;

    event OwnerChanged(address oldOwner, address newOwner);

    /// @notice gives the current owner of this contract.
    /// @return the current owner of this contract.
    function getOwner() external view returns (address) {
        return _owner;
    }

    /// @notice change the owner to be `newOwner`.
    /// @param newOwner address of the new owner.
    function changeOwner(address newOwner) external {
        require(newOwner != address(0x000), "Zero address");
        address owner = _owner;
        require(msg.sender == owner, "only owner can change owner");
        require(newOwner != owner, "it can be only changed to a new owner");
        emit OwnerChanged(owner, newOwner);
        _owner = newOwner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "only owner allowed");
        _;
    }
}

// File: contracts/lib/security/DDMinterPausable.sol

pragma solidity 0.8.14;


contract DDMinterPausable is Pausable, Owner {
    function pause() external onlyOwner {
        _pause();
    }

    function UnPause() external onlyOwner {
        _unpause();
    }
}

// File: contracts/lib/interface/IVault.sol

pragma solidity 0.8.14;

interface IVault {
    function addCollateral(
        address token,
        uint256 conversionAmount,
        uint256 minimum
    ) external;

    function setConversionRate(address token, uint256 conversionAmount)
        external;

    function create(
        address user,
        address token,
        uint256 amount,
        uint256 ddAmount
    ) external returns (uint256);

    function deposit(
        uint256 cdp,
        address user,
        uint256 amount
    ) external;

    function withdraw(
        uint256 cdp,
        address user,
        uint256 amount
    ) external;

    function mintDD(
        uint256 cdp,
        address user,
        uint256 ddamount
    ) external returns (uint256);

    function burnDD(
        uint256 cdp,
        address user,
        uint256 ddamount
    ) external;

    function transferVault(
        uint256 cdp,
        address user,
        address to
    ) external;

    function closeVault(uint256 cdp, address user) external;
}

// File: contracts/lib/interface/IDDirham.sol

pragma solidity 0.8.14;

interface IDDirham {
    function burn(address from, uint256 amount) external returns (bool);

    function mint(address to, uint256 amount) external returns (bool);
}

// File: contracts/ddMinter/DDMinter.sol

pragma solidity 0.8.14;



contract DDMinter is DDMinterPausable {
    IVault public VAULT;
    IDDirham public DD;

    constructor(
        IVault vault_,
        IDDirham DD_,
        address owner_
    ) {
        VAULT = vault_;
        DD = DD_;
        _owner = owner_;
    }

    //Event details
    event Mint(address to, uint256 amount);
    event Burn(address from, uint256 amount);

    function createVault(
        address token,
        uint256 amount,
        uint256 ddAmount
    ) external whenNotPaused {
        address user = msg.sender;
        VAULT.create(user, token, amount, ddAmount);
        if (ddAmount > 0) {
            _mint(user, ddAmount);
        }
    }

    function deposit(uint256 cdp, uint256 amount) external whenNotPaused {
        address user = msg.sender;
        VAULT.deposit(cdp, user, amount);
    }

    function withdraw(uint256 cdp, uint256 amount) external whenNotPaused {
        address user = msg.sender;
        VAULT.withdraw(cdp, user, amount);
    }

    function mintDD(uint256 cdp, uint256 ddamount) external whenNotPaused {
        address user = msg.sender;
        uint256 amount = VAULT.mintDD(cdp, user, ddamount);
        if (amount > 0) {
            _mint(user, amount);
        }
    }

    function burnDD(uint256 cdp, uint256 ddamount) external whenNotPaused {
        address user = msg.sender;
        _burn(user, ddamount);
        VAULT.burnDD(cdp, user, ddamount);
    }

    function transferVault(uint256 cdp, address to) external whenNotPaused {
        address user = msg.sender;
        VAULT.transferVault(cdp, user, to);
    }

    function closeVault(uint256 cdp) external whenNotPaused {
        address user = msg.sender;
        VAULT.closeVault(cdp, user);
    }

    // Access control method

    function addCollateral(
        address token,
        uint256 conversionAmount,
        uint256 minimum
    ) external onlyOwner {
        VAULT.addCollateral(token, conversionAmount, minimum);
    }

    function setConversionRate(address token, uint256 conversionAmount)
        external
        onlyOwner
    {
        VAULT.setConversionRate(token, conversionAmount);
    }

    // Internal methods

    function _mint(address to, uint256 amount) internal {
        require(DD.mint(to, amount), "DD mint failed");
        emit Mint(to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        require(DD.burn(from, amount), "DD burn failed");
        emit Burn(from, amount);
    }
}
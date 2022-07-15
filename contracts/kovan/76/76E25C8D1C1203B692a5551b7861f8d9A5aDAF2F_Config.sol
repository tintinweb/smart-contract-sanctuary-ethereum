pragma solidity ^0.8.0;
import "./utils/PermissionGroupUpgradeable.sol";

contract Config is PermissionGroupUpgradeable {
    enum Fees{ DEPOSIT, DEPOSIT_GEM, WITHDRAW, WITHDRAW_GEM, BORROW, PAYBACK}
    uint feeDeposit;
    uint feeWithdraw;
    uint feeDepositGem;
    uint feeWithdrawGem;
    uint feeBorrow;
    uint feePayBack;
    address treasury;
    mapping(bytes32 => bool) listStableTokens;

    function _initialize(uint _feeDepositETH, uint _feeWithdrawETH, uint _feeDepositGem, uint _feeWthdrawGem, uint _feeBorrow, uint _feePayBack, address _treasury)
        external
        initializer
    {
        __operatable_init();
        feeDeposit = _feeDepositETH;
        feeWithdraw = _feeWithdrawETH;
        feeDepositGem = _feeDepositGem;
        feeWithdrawGem = _feeWthdrawGem;
        treasury = _treasury;
        feeBorrow = _feeBorrow;
        feePayBack = _feePayBack;
    }

    function setFee(Fees feeType, uint _fee) public onlyOwner {
        if(feeType == Fees.DEPOSIT) {
            feeDeposit = _fee;
        } else if(feeType == Fees.WITHDRAW) {
            feeWithdraw = _fee;
        } else if(feeType == Fees.BORROW) {
            feeBorrow = _fee;
        } else if(feeType == Fees.PAYBACK) {
            feePayBack = _fee;
        }  else if(feeType == Fees.DEPOSIT_GEM) {
            feeDepositGem = _fee;
        }  else if(feeType == Fees.WITHDRAW_GEM) {
            feeWithdrawGem = _fee;
        }  
    }    

    function setTreasury(address _treasury) public onlyOwner {
        require( _treasury != address(0), "Config: invalid address");
        treasury = _treasury;
    }

    function addListToken(bytes32 ilk) public onlyOwner {
        require( !listStableTokens[ilk], "Config: already exist");
        listStableTokens[ilk] = true;
    }

    function removeListToken(bytes32 ilk) public onlyOwner {
        require(listStableTokens[ilk], "Config: not found");
        listStableTokens[ilk] = false;
    }

    function getFeeAndTreasury() public view returns(uint fee1, uint fee2, uint fee3, uint fee4, address trea) {
        fee1 = feeDeposit;
        fee2 = feeDepositGem;
        fee3 = feeWithdraw;
        fee4 = feeWithdrawGem;
        trea = treasury;
    }

    function getFee(Fees feeType) external view returns (uint fee) {
        if(feeType == Fees.DEPOSIT) {
            return feeDeposit;
        } else if(feeType == Fees.WITHDRAW) {
            return feeWithdraw;
        } else if(feeType == Fees.BORROW) {
            return feeBorrow;
        } else if(feeType == Fees.PAYBACK) {
            return feePayBack;
        } else if(feeType == Fees.DEPOSIT_GEM) {
            return feeDepositGem;
        } else if(feeType == Fees.WITHDRAW_GEM) {
            return feeWithdrawGem;
        } 
    }

    function getTreasury() external view returns (address) {
        return treasury;
    }

    function checkToken(bytes32 token) external view returns (bool) {
        return listStableTokens[token];
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract PermissionGroupUpgradeable is OwnableUpgradeable {

    mapping(address => bool) public operators;
    event AddOperator(address newOperator);
    event RemoveOperator(address operator);

    function __operatable_init() internal initializer {
        __Ownable_init();
        operators[owner()] = true;
    }

    modifier onlyOperator {
        require(operators[msg.sender], "Operatable: caller is not the operator");
        _;
    }

    function addOperator(address operator) external onlyOwner {
        operators[operator] = true;
        emit AddOperator(operator);
    }

    function removeOperator(address operator) external onlyOwner {
        operators[operator] = false;
        emit RemoveOperator(operator);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
    uint256[49] private __gap;
}
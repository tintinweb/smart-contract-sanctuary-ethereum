import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/INether.sol";
import "../interfaces/IMetaStablePool.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../TestContracts/TreasuryTest.sol";

pragma solidity ^0.8.0;




contract LiquidityManager is Initializable, OwnableUpgradeable {
    IVault public vault;
    bytes32 public poolId;
    IAsset public netherIAsset;
    IAsset public wethIAsset;
    IMetaStablePool public pool;
    IERC20 public nBond;
    TreasuryTest public treasuryTest;


    INether public netherINether;
    IERC20 public balancerWethIERC20;

    uint256 public lastDividendCall;
    uint256 public slippageVar;

    function initialize() public initializer {
        netherIAsset = IAsset(0x5CA15C0781F9033430a6d8BACfC9Ad313Fd3F1d9);
        wethIAsset = IAsset(0xdFCeA9088c8A88A76FF74892C1457C17dfeef9C1);

        netherINether = INether(0x5CA15C0781F9033430a6d8BACfC9Ad313Fd3F1d9);
        balancerWethIERC20 = IERC20(0xdFCeA9088c8A88A76FF74892C1457C17dfeef9C1);
        poolId = 0xe053685f16968a350c8dea6420281a41f72ce3aa00020000000000000000006b;
        vault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
        pool = IMetaStablePool(0xe053685f16968a350c8dEA6420281a41f72cE3AA);
        nBond = IERC20(0x2ae28ea8162099c1F3a92045EC5a6ad1919d7564);
        treasuryTest = TreasuryTest(payable(0xBDE530Eec5D42AdB8986878166984cB2c735677c));


        lastDividendCall = 1 ether;
        slippageVar = 90;
        
        

        
    }




    function updateRevenueStream() external {

    }



    function trade(
        IAsset _tokenin,
        IAsset _tokenout,
        uint256 _tradeAmount,
        uint256 _limit,
        uint256 _deadline
    ) internal returns (uint256) {
        IVault.SwapKind swapKind = IVault.SwapKind.GIVEN_IN;


        IVault.SingleSwap memory swapDescription = IVault.SingleSwap({
            poolId: poolId,
            kind: swapKind,
            assetIn: _tokenin,
            assetOut: _tokenout,
            amount: _tradeAmount,
            userData: "0x"
        });

        IVault.FundManagement memory fundManagement;
        fundManagement = IVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)), 
            toInternalBalance: false
        });

        uint256 assetOut = vault.swap(
            swapDescription,
            fundManagement,
            _limit,
            _deadline
        );
        return assetOut;
    }


    function getDividend() external {
        uint256 lpAmount = pool.balanceOf(address(this));
        uint256 currentRate = pool.getRate();
        uint256 exitAmount = (currentRate - lastDividendCall) * lpAmount / lastDividendCall;

        
        uint256 minAmountsOut = exitAmount * slippageVar / 100;

        lastDividendCall = currentRate;

        removeLiquidity(minAmountsOut, exitAmount);
        netherINether.burn(netherINether.balanceOf(address(this)));
        if(treasuryTest.bondAllocation() > nBond.totalSupply()) {
            ///balancerWethIERC20.transfer() //// SEND TO SENIORAGE
        } else {
            trade(wethIAsset, netherIAsset, netherINether.balanceOf(address(this)), netherINether.balanceOf(address(this)) * slippageVar, block.timestamp + 60);
            netherINether.burn(netherINether.balanceOf(address(this)));
        }
        
        


    }



    function addLiquidity(uint256 _tokenAmountIn, uint256 _minimumBPT) internal returns(bool) {
        uint256 JOIN_KIND_INIT = 1;
        
        
        IAsset[] memory tokens = new IAsset[](2);
        tokens[0] = netherIAsset;
        tokens[1] = wethIAsset;

        uint256[] memory tokenAmounts = new uint256[](2);
        tokenAmounts[0] = _tokenAmountIn;
        tokenAmounts[1] = _tokenAmountIn;
        
        balancerWethIERC20.approve(address(vault), _tokenAmountIn);
        netherINether.approve(address(vault), _tokenAmountIn);


        bytes memory userDataEncoded = abi.encode(JOIN_KIND_INIT,tokenAmounts, _minimumBPT);

        IVault.JoinPoolRequest memory request = IVault.JoinPoolRequest(tokens, tokenAmounts , userDataEncoded, false);
        vault.joinPool(poolId, address(this), address(this), request);
        return true;
        
    }

    function removeLiquidity(uint256 _minAmountsOut,
     uint256 _bptAmount) internal returns(bool)
    {
        IAsset[] memory tokens = new IAsset[](2);
        tokens[0] = netherIAsset;
        tokens[1] = wethIAsset;


        uint256[] memory minAmountsOutVar = new uint256[](2);
        minAmountsOutVar[0] = _minAmountsOut;
        minAmountsOutVar[1] = _minAmountsOut;


        bytes memory userDataVar = abi.encode(1,_bptAmount);

        IVault.ExitPoolRequest memory exitRequest  = IVault.ExitPoolRequest({
            assets : tokens,
            minAmountsOut : minAmountsOutVar,
            userData: userDataVar,
            toInternalBalance: false
        });

        vault.exitPool(poolId, address(this), address(this), exitRequest);
        return true;

    }


    function postStake() external {

    }


    function getPoolBalances() internal view returns (uint256[] memory) {
        (, uint256[] memory balances, ) = vault.getPoolTokens(poolId);
        return balances;
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

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.



pragma solidity ^0.8.0;

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */

 import "./IERC20.sol";
interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

interface IVault {


    function exitPool(
        bytes32 poolId,
        address sender,
        address recipient,
        ExitPoolRequest memory request
    ) external payable;



    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;



    struct SingleSwap {
   bytes32 poolId;
   SwapKind kind;
   IAsset assetIn;
   IAsset assetOut;
   uint256 amount;
   bytes userData;
}

    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
}

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    )
        external
        payable

        returns (uint256 amountCalculated);



    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;

        
    }
    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    

    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas); 

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (IERC20[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);

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

    function mint(address to, uint256 amount) external;
    
    function burn(uint256 amount) external; 

        function testmint(address to, uint256 amount) external;
           function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface INether {
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


    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external; 
    function testmint(address to, uint256 amount) external;
}

pragma solidity ^0.8.0;

interface IMetaStablePool {
    function enableOracle() external;

    enum Variable {
        PAIR_PRICE,
        BPT_PRICE,
        INVARIANT
    }

    function getLatest(Variable variable) external returns (uint256);

    struct OracleAverageQuery {
        Variable variable;
        uint256 secs;
        uint256 ago;
    }

    function getRate() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function getTimeWeightedAverage(OracleAverageQuery[] memory queries)
        external
        returns (uint256[] memory results);

    function setRelayerApproval(
        address sender,
        address relayer,
        bool approved
    ) external;

    function approve(address spender, uint256 amount) external returns (bool);
    function totalSupply() external returns (uint256);

    function getOracleMiscData()
        external
        view
        returns (
            int256 logInvariant,
            int256 logTotalSupply,
            uint256 oracleSampleCreationTimestamp,
            uint256 oracleIndex,
            bool oracleEnabled
        );

    function getPoolId() external view returns (bytes32);
    function setSwapFeePercentage(uint256 swapFeePercentage) external;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "./NetherOracle.sol";
import "../interfaces/IVault.sol";
import "../interfaces/INether.sol";
import "../interfaces/IMasonry.sol";

contract TreasuryTest is Ownable {
    IMetaStablePool public pool;
    INether public nether;
    IERC20 public core;
    IERC20 public nBond;
    IERC20 public balancerWeth;
    NetherOracle public oracle;
    IMasonry public masonry;

    IVault public vault;
    bytes32 public poolId;

    IVault.SwapKind public val;
    int256[] public deltas;

    IAsset public token1;
    IAsset public token2;
    IAsset public Zero_ETH;

    uint256 private seniorageThreshold = 1010000000000000000;
    uint256 private poolImbalance = 102;
    uint256 private bonusExpansion = 0;
    uint256 public bondAllocation = 0;
    uint256 public bondDiscount = 101;

    uint256 public circulatingBondAmount;
    event Received(address, uint256);

    uint256[4] public swapFeePriceLevels = [
        950000000000000000,
        920000000000000000,
        900000000000000000,
        850000000000000000
    ];
    uint256[4] public swapFeeBatches = [
        30000000000000000,
        50000000000000000,
        70000000000000000,
        99000000000000000
    ];
    uint256 public poolSwapFee;
    uint256 public rateAtFeeChange;

    constructor(address _address) {
        pool = IMetaStablePool(0xe053685f16968a350c8dEA6420281a41f72cE3AA);
        vault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
        nether = INether(0x5CA15C0781F9033430a6d8BACfC9Ad313Fd3F1d9);
        balancerWeth = IERC20(0xdFCeA9088c8A88A76FF74892C1457C17dfeef9C1);
        //core = IERC20(_core);
        nBond = IERC20(0x2ae28ea8162099c1F3a92045EC5a6ad1919d7564);
        oracle = NetherOracle(_address);

        token1 = IAsset(0x5CA15C0781F9033430a6d8BACfC9Ad313Fd3F1d9);
        token2 = IAsset(0xdFCeA9088c8A88A76FF74892C1457C17dfeef9C1);
        poolId = 0xe053685f16968a350c8dea6420281a41f72ce3aa00020000000000000000006b;
        Zero_ETH = IAsset(0x0000000000000000000000000000000000000000);
    }

    // function getPreviousEpochPrice() internal {
    //     uint256[] twap = oracle.getTwap();
    // }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // @notice function mints nbonds in exchange of weth converts and burns the received nether
    // @param  _amount of bonds to be sold
    function sellNBonds(uint256 _amount) external payable {
        uint256[] memory balances = getPoolBalances();
        require(
            balances[0] > (balances[1] * poolImbalance) / 100,
            "peg above one"
        );
        require(_amount > 0, "amount must be bigger than zero");
        address sender = msg.sender;
        balancerWeth.transferFrom(msg.sender, address(this), _amount);
        uint256 mintNBonds = _amount;
        nBond.testmint(sender, mintNBonds);
        balancerWeth.approve(address(vault), _amount);
        uint256 receivedNether = trade(token2, token1, _amount);
        nether.burn(receivedNether);
    }

    // @notice function mints nbonds in exchange of eth converts and burns the received nether
    // @param  _amount of bonds to be sold

    function sellNBondsETH() external payable {
        uint256[] memory balances = getPoolBalances();
        require(
            balances[0] > (balances[1] * poolImbalance) / 100,
            "peg above one"
        );
        require(msg.value > 0, "amount must be bigger than zero");
        uint256 amount = msg.value;
        address sender = msg.sender;
        uint256 mintNBonds = msg.value;

        nBond.testmint(sender, mintNBonds);

        IVault.SwapKind swapKind = IVault.SwapKind.GIVEN_IN;

        IVault.SingleSwap memory swapDescription = IVault.SingleSwap({
            poolId: poolId,
            kind: swapKind,
            assetIn: Zero_ETH,
            assetOut: token1,
            amount: amount,
            userData: "0x"
        });

        IVault.FundManagement memory fundManagement;
        fundManagement = IVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });
        uint256 limit = 1;
        uint256 deadline = block.timestamp + 60;
        uint256 receivedNether = vault.swap{value: amount}(
            swapDescription,
            fundManagement,
            limit,
            deadline
        );
        nether.burn(receivedNether);
    }

    // @notice function burns nbonds in exchange of weth
    // @param  _amount of bonds to be burned

    function buyNBonds(uint256 _amount) external {
        require(
            nBond.balanceOf(msg.sender) >= _amount,
            "sender must have nBonds"
        );
        require(
            bondAllocation > _amount,
            "treasury doesnt have enough eth to pay yet"
        );
        nBond.burnFrom(msg.sender, _amount);
        bondAllocation -= _amount;
        balancerWeth.transfer(msg.sender, _amount);
    }

    // @notice function mints nether and trades it with weth in the pool. Proceedings are either kept
    // for bondAllocation or sent to the RevManager.
    // @param  function operates with deltas array, which is filled by CalculateMintAmount.
    // @require balance of eth must be more than nether in the pool
    // @require balance of the nether must not be more than neth after trading is done.
    function seniorage() external {
        require(deltas[0] != 0, "deltas are back to zero wait for next epoch");
        nether.approve(address(vault), 100000000000000000000);
        uint256[] memory balances = getPoolBalances();
        require(balances[1] > balances[0], "price must be above 1");
        require(
            int256(balances[0]) + deltas[0] < int256(balances[1]) + deltas[1],
            "balance off"
        );

        uint256 mintAmount = uint256(deltas[0]);

        nether.testmint(address(this), mintAmount);

        uint256 receivedWETH = trade(token1, token2, mintAmount);
        balances = getPoolBalances();
        assert(balances[1] > balances[0]);
        /*             if(bonusExpansion > 0) {
                    nether.mint(address(this), bonusExpansion * mintAmount / 100);
                    receivedWETH += tradeNetherForEther(bonusExpansion * mintAmount / 100);
                } */

        circulatingBondAmount = nBond.totalSupply();
        if (bondAllocation < circulatingBondAmount) {
            uint256 uncollateralizedBond = circulatingBondAmount -
                bondAllocation;
            if (receivedWETH > uncollateralizedBond) {
                bondAllocation += uncollateralizedBond;
                //allocateToMasonry(receivedWETH-uncollateralizedBond);
            } else {
                bondAllocation += receivedWETH;
            }
        } else if (bondAllocation >= circulatingBondAmount) {
            //allocateToMasonry(receivedWETH);
        }
        deltas[0] = 0;
        deltas[1] = 0;
    }

    function allocateToMasonry(uint256 _seniorageRev) internal {
        payable(address(masonry)).transfer(_seniorageRev);
    }

    // @notice trading function for balancer pool
    // @param _tokenin token to be sent, _tokenout token to be received, _tradeAmount amount to be traded
    // @limit minimum amount to be received.
    function trade(
        IAsset _tokenin,
        IAsset _tokenout,
        uint256 _tradeAmount
    ) internal returns (uint256) {
        IVault.SwapKind swapKind = IVault.SwapKind.GIVEN_IN;
        //bytes memory swapData = abi.encode(swapKind);

        IVault.SingleSwap memory swapDescription = IVault.SingleSwap({
            poolId: poolId,
            kind: swapKind,
            assetIn: _tokenin,
            assetOut: _tokenout,
            amount: _tradeAmount,
            userData: "0x"
        });

        IVault.FundManagement memory fundManagement;
        fundManagement = IVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });
        uint256 limit = 1;
        uint256 deadline = block.timestamp + 60;
        uint256 receivedNether = vault.swap(
            swapDescription,
            fundManagement,
            limit,
            deadline
        );
        return receivedNether;
    }

    // @notice returns how many X for Y tokens
    // @param amount of X tokens to be traded
    function callQueryBatchSwap(uint256 _tradeAmount)
        internal
        returns (int256[] memory)
    {
        //uint256[] memory a = new uint256[](1);
        //a[0] = 5;
        //return _address.staticcall(abi.encodeWithSignature("arr(uint256[])",a));

        IAsset[] memory tokens = new IAsset[](2);
        tokens[0] = token1;
        tokens[1] = token2;
        IVault.SwapKind swapKind = IVault.SwapKind.GIVEN_IN;

        IVault.BatchSwapStep[] memory swapSteps = new IVault.BatchSwapStep[](1);
        IVault.BatchSwapStep memory swapStep = IVault.BatchSwapStep({
            poolId: poolId,
            assetInIndex: 0,
            assetOutIndex: 1,
            amount: _tradeAmount,
            userData: "0x"
        });

        swapSteps[0] = swapStep;

        IVault.FundManagement memory fundManagement;
        fundManagement = IVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });

        int256[] memory deltasMem;
        deltasMem = vault.queryBatchSwap(
            swapKind,
            swapSteps,
            tokens,
            fundManagement
        );
        return deltasMem;
    }

    // @notice calculates seniorage amounts
    // @param errorMargin is error margin for pool balancing
    // function collects pool balances and loops to calculate the amount to be minted
    // loop breaks when the pool is off balanced only by the specified error margin

    function calculateMintAmount(int256 _errorMargin)
        public
        returns (int256[] memory)
    {
        uint256 previousEpochPrice = oracle.getTwap();
        if (previousEpochPrice > seniorageThreshold) {
            uint256[] memory balances = getPoolBalances();
            uint256 midVal = (balances[0] + balances[1]) / 2;
            uint256 approximateMintAmount = (balances[1] - midVal);
            uint256 max_amount_in = (balances[0] * 290) / 1000;

            if (max_amount_in < approximateMintAmount) {
                deltas = callQueryBatchSwap(max_amount_in);
                return deltas;
            } else {
                int256[] memory deltasMemo = callQueryBatchSwap(
                    approximateMintAmount
                );
                deltas = deltasMemo;
                int256 errorMargin = _errorMargin;

                while (
                    int256(balances[0]) + deltasMemo[0] >
                    int256(balances[1]) + deltasMemo[1]
                ) {
                    approximateMintAmount -= uint256(errorMargin);
                    deltasMemo = callQueryBatchSwap(approximateMintAmount);
                }

                deltas = deltasMemo;

                return deltas;
            }
        } else {
            revert("price below threshold");
        }
    }

    ///////////// VIEW FUNCTIONS /////////////

    // @notice returns pool balances
    function getPoolBalances() internal view returns (uint256[] memory) {
        (, uint256[] memory balances, ) = vault.getPoolTokens(poolId);
        return balances;
    }

    // @notice returns true if treasury is eligable to sell bonds
    function checkBondSale() external view returns (bool) {
        uint256[] memory balances = getPoolBalances();
        if (balances[0] > (balances[1] * poolImbalance) / 100) {
            return true;
        } else {
            return false;
        }
    }

    // @notice returns previous nether price
    function getCurrentNetherPrice() internal returns (uint256) {
        return oracle.getCurrentPrice();
    }

    //////////////GOVERNANCE//////////////

    // @notice sets bonus expansion
    function setBonusExpansion(uint256 _bonusExpansion) external onlyOwner {
        bonusExpansion = _bonusExpansion;
    }

    function getSwapFee() external returns (uint256) {
        uint256 netherPrice = getCurrentNetherPrice();
        require(netherPrice < swapFeePriceLevels[0]);
        for (uint256 i = 3; i >= 0; i--) {
            if (netherPrice < swapFeePriceLevels[i]) {
                poolSwapFee = swapFeeBatches[i];
                break;
            }
        }
        return poolSwapFee;
    }

    function setSwapFee() external onlyOwner returns (uint256) {
        pool.setSwapFeePercentage(poolSwapFee);
        rateAtFeeChange = pool.getRate();
    }

    // @notice recovers some accidents
    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOwner {
        _token.transfer(_to, _amount);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
                /// @solidity memory-safe-assembly
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
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

import "../interfaces/IMetaStablePool.sol";
import "../interfaces/Epoch.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IMasonry.sol";


pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract NetherOracle is Epoch {

    enum Variable { PAIR_PRICE, BPT_PRICE, INVARIANT }
        IMetaStablePool public pool;
        uint256 public price;
        uint256[] public twapArr;
        uint256 public twap;

        uint256 public epochPeriod;
        IVault public vault;
        bytes32 public poolId;

        IAsset private token1;
        IAsset private token2;

        uint256 public oracleIndex;



    constructor( uint256 _epochPeriod) Epoch(_epochPeriod,block.timestamp,0)  {
        pool = IMetaStablePool(0xe053685f16968a350c8dEA6420281a41f72cE3AA);
        epochPeriod = _epochPeriod;
        vault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
        poolId = 0xe053685f16968a350c8dea6420281a41f72ce3aa00020000000000000000006b;

        token1 = IAsset(0x5CA15C0781F9033430a6d8BACfC9Ad313Fd3F1d9);
        token2 = IAsset(0xdFCeA9088c8A88A76FF74892C1457C17dfeef9C1);
    }

    
    function getCurrentPrice() external returns(uint256) {
        price = pool.getLatest(IMetaStablePool.Variable.PAIR_PRICE);
        return price;

    }

    

    function getTwap() external checkEpoch returns(uint256) {
        
        (,,,oracleIndex,) = pool.getOracleMiscData();
        if (oracleIndex < 1024) {
            (,uint256[] memory balances) = getPoolBalances();
            if(balances[0] * 102 / 100 < balances[1]) {
                twap = 2 ether;
                return twap;
            }

            
        } else {


        IMetaStablePool.OracleAverageQuery[] memory queries = new IMetaStablePool.OracleAverageQuery[](1);
        IMetaStablePool.OracleAverageQuery memory query = IMetaStablePool.OracleAverageQuery({
            variable: IMetaStablePool.Variable.PAIR_PRICE,
            secs: epochPeriod,
            ago: block.timestamp - nextEpochPoint()
          });
        queries[0] = query;
        


        twapArr = pool.getTimeWeightedAverage(queries);
        return (twapArr[0]);
    }}


    


        function getPoolBalances() public view returns (IERC20[] memory,uint256[] memory) {
            (IERC20[] memory tokens, uint256[] memory balances, ) = vault.getPoolTokens(poolId);
            return (tokens,balances);
        }






}

interface IMasonry {

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./Operator.sol";

contract Epoch is Operator {
    using SafeMath for uint256;

    uint256 private period;
    uint256 private startTime;
    uint256 private lastEpochTime;
    uint256 private epoch;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        uint256 _period,
        uint256 _startTime,
        uint256 _startEpoch
    ) {
        period = _period;
        startTime = _startTime;
        epoch = _startEpoch;
        lastEpochTime = startTime.sub(period);
    }

    /* ========== Modifier ========== */

    modifier checkStartTime() {
        require(block.timestamp >= startTime, "Epoch: not started yet");

        _;
    }

    modifier checkEpoch() {
        uint256 _nextEpochPoint = nextEpochPoint();
        if (block.timestamp < _nextEpochPoint) {
            require(
                msg.sender == operator(),
                "Epoch: only operator allowed for pre-epoch"
            );
            _;
        } else {
            _;

            for (;;) {
                lastEpochTime = _nextEpochPoint;
                ++epoch;
                _nextEpochPoint = nextEpochPoint();
                if (block.timestamp < _nextEpochPoint) break;
            }
        }
    }

    /* ========== VIEW FUNCTIONS ========== */

    function getCurrentEpoch() public view returns (uint256) {
        return epoch;
    }

    function getPeriod() public view returns (uint256) {
        return period;
    }

    function getStartTime() public view returns (uint256) {
        return startTime;
    }

    function getLastEpochTime() public view returns (uint256) {
        return lastEpochTime;
    }

    function nextEpochPoint() public view returns (uint256) {
        return lastEpochTime.add(period);
    }

    /* ========== GOVERNANCE ========== */

    function setPeriod(uint256 _period) external onlyOperator {
        require(
            _period >= 1 hours && _period <= 48 hours,
            "_period: out of range"
        );
        period = _period;
    }

    function setEpoch(uint256 _epoch) external onlyOperator {
        epoch = _epoch;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Operator is Ownable {
    address private _operator;

    event OperatorTransferred(
        address indexed previousOperator,
        address indexed newOperator
    );

    constructor() {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(
            _operator == msg.sender,
            "operator: caller is not the operator"
        );
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(
            newOperator_ != address(0),
            "operator: zero address given for new operator"
        );
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}
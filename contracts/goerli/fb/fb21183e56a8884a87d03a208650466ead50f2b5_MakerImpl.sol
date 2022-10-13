pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IManager{
    function open(bytes32 ilk, address cdpOwner) external;
    function frob(uint256 cdpId, int256 amount, int256 debt) external;
    function move(uint cdp, address dst, uint rad) external;
    function flux(uint cdp, address dst, uint wad) external;
    function cdpAllow(uint cdp, address usr, uint ok) external;
    function give(uint cdp, address dst) external;

    function last(address cdpOwner) external view returns(uint256 cdpId);
    function urns(uint256 cdpId) external view returns(address urn);

}
interface IJoinAdapter {
    function join(address urnAddress, uint256 amount) external;
    function exit(address destination, uint256 amount) external;
    function dec() external view returns(uint256);
}

interface IJUG {
    function drip(bytes32 ilk) external returns (uint);
}

interface IVAT {
    function hope(address usr) external; //allows usr to receive internal-dai

    function urns(bytes32 ilk, address urn) external view returns(uint256 collateral, uint256 debt);
    function ilks(bytes32 ilk) external view returns(
        uint256 debt,
        uint256 rate, //accumulated rates
        uint256 spot, //price with safety margin
        uint256 line, //debt ceiling
        uint256 dust //min debt (or urn debt floor)
    );
    function dai(address urn) external view returns(uint256 internalDai);
    function can(address src, address target) external view returns(uint256);
    
}

interface IERC20 is IERC20Upgradeable {
    function decimals() external view returns(uint256);
}

contract MakerImpl is Initializable, OwnableUpgradeable {

    /**
        @dev
        IMPORTANT: Not before modifying this contract:
            1. Never let the funds in this contract at the end of transaction.
            This includes internal-dai(result of move()) 

            2. Always use cdpByOwner() method of this contract to get the cdpOwner(which points to the user address).
            The cdp is owned by this contract, while giving control to the user.
            Getting and Using the real owner (address(this)) from maker will be a security risk.
                - Using the real owner instead of cdpByOwner() in this contract will cause the funds to be owned by 
                this contract in maker, internally. As this contract manages funds of all the users, That will lead to
                access funds of other users.
     */
    IManager public CDPManager;
    IJUG public JUG;
    IVAT public VAT;
    
    bytes32 public constant DAIILK = bytes32("DAI");

    struct CDPInfo {
        uint256 cdpId;
        address urn;
    }

    struct JOINInfo {
        address adapterAddress;
        address collateralAddress;
    }

    //user => ilk => cdpId
    mapping(address => mapping(bytes32 => CDPInfo)) public cdpByOwner;
    mapping(bytes32 => JOINInfo) public JOINByIlk;

    address public trustedForwarder;

    event VaultCreated(bytes32 ilk, address user, uint256 cdpId, address urn);
    event Withdraw(bytes32 ilk, address user, address desitnation, uint amount);
    event FundsAdded(bytes32 ilk, address urn, uint256 amount, address user);
    event Manage(bytes32 ilk, uint256 cdpId, int256 amount, int256 debt, address user);

    event RepayAllAndWithdraw(bytes32 ilk, uint256 amountRepaid, uint256 collateralWithdrawn, address user);
    event RepayAndWithdraw(bytes32 ilk, uint256 amountRepaid, uint256 collateralWithdrawn, address user);
    event Repay(bytes32 ilk, uint256 amountRepaid, address user);
    event OpenAndManage(bytes32 ilk, uint256 collateralAmt, uint256 daiBorrowed, address user);
    event OpenAndJoin(bytes32 ilk, uint256 collateralAdded, address user);
    event OpenAndBorrow(bytes32 ilk, uint256 collateral, uint daiBorrowed, address user);

    event JoinAdapterUpdated(bytes32 indexed ilk, address indexed joinAdapter, address collateralAddress);
    event AddressUpdated(address jug, address vat);

    function initialize(
        address _cdpManager, address _jug, address _vat, 
        bytes32[] calldata _ilks, address[] calldata _adapters, address[] calldata _collateral
    ) external initializer {
        __Ownable_init();
        
        CDPManager = IManager(_cdpManager);
        JUG = IJUG(_jug);
        VAT = IVAT(_vat);

        for(uint256 i =0; i<_ilks.length; i++) {
            JOINByIlk[_ilks[i]] = JOINInfo(_adapters[i], _collateral[i]);
            IERC20Upgradeable(_collateral[i]).approve(_adapters[i], type(uint256).max);
        }
    }

    /**
        @dev Opens a new CDP, adds collateral to the urn, adds collateral to VAT, borrows and withdraws DAI.
        @param ilk collateral type in bytes32 (ex: ethers.utils.formatBytes32String("WBTC-A"))
        @param amount amount of collateral to add(collateral's decimals)
        @param daiToBorrow Amount to dai to borrow (18 decimals)
     */
    function openAndBorrow(bytes32 ilk, uint256 amount, uint256 daiToBorrow) external {
        (uint256 cdpId, address urn) = _open(ilk);
        _join(ilk, urn, amount); //adds collateral to the urn
        _manage(ilk, cdpId, int256(amount), int256(daiToBorrow)); //adds collateral to VAT, borrows DAI(internally)

        // uint256 collateralDecimals = IERC20(JOINByIlk[ilk].collateralAddress).decimals();
        // uint256 daiInRAD = daiToBorrow * 10 ** (45 - collateralDecimals ); //RAD - 45 decimals
        uint256 daiInRAD = daiToBorrow * 10 ** 27; //RAD - 45 decimals (18 + 27 = 45)

        _move(cdpId, address(this), daiInRAD); //moves internal-dai to this contract. 
        _exit(DAIILK, _msgSender(), daiToBorrow); //moves DAI to msg.sender

        emit OpenAndBorrow(ilk, amount, daiToBorrow, _msgSender());
    }

    /**
        @dev Opens a new CDP, Add the {amount} of collateral to URN and Manages the amount in the VAT.
            Doesn't withdraw DAI. Borrowed DAI is kept in URN or adapter.
        @param ilk collateral type in bytes32 (ex: ethers.utils.formatBytes32String("WBTC-A"))
        @param amount amount of collateral to add(collateral's decimals)
        @param daiToBorrow Amount to dai to borrow (18 decimals)
     */
    function openAndManage(bytes32 ilk, uint256 amount, uint256 daiToBorrow) external {
        (uint256 cdpId, address urn) = _open(ilk);
        _join(ilk, urn, amount); //adds collateral to the urn
        _manage(ilk, cdpId, int256(amount), int256(daiToBorrow)); //adds collateral to VAT, borrows DAI(internally)

        emit OpenAndManage(ilk, amount, daiToBorrow, _msgSender());
    }

    /**
        @dev Opens a new CDP, Adds the funds to the URN. Doesn't borrow or withdraw DAI
        @param ilk collateral type in bytes32 (ex: ethers.utils.formatBytes32String("WBTC-A"))
        @param amount amount of collateral to add(collateral's decimals)
    */
    function openAndJoin(bytes32 ilk, uint256 amount) external {
        (, address urn) = _open(ilk);
        _join(ilk, urn, amount); //adds collateral to the urn

        emit OpenAndJoin(ilk, amount, _msgSender());
    }


    /**
        @dev To Adjust the position's collateral and Debt in VAT. Doesn't withdraw DAI.
        @param ilk collateral type in bytes32 (ex: ethers.utils.formatBytes32String("WBTC-A"))
        @param amount Amount of collateral to add/remove in VAT. Can be positive/negative (collateral's decimals)
        @param join If True, collateral will be transferred In from _msgSender() and Added to VAT
     */
    function manage(bytes32 ilk, int256 amount, int256 _debt, bool join) external {
        CDPInfo memory cdpInfo = cdpByOwner[_msgSender()][ilk];
        if(join && amount > 0) {
            _join(ilk, cdpInfo.urn, uint256(amount));
        }
        _manage(ilk, cdpInfo.cdpId, amount, _debt);
    }

    /**
        @dev Repays the Debt but doesn't change the collateral in the VAT. So can borrow later for the same collateral.
        @param ilk collateral type in bytes32 (ex: ethers.utils.formatBytes32String("WBTC-A"))
        @param amountToRepay Amount of DAI to repay(18 decimals)
    */
    function repay(bytes32 ilk, uint256 amountToRepay) external {
        CDPInfo memory cdpInfo = cdpByOwner[_msgSender()][ilk];
        JUG.drip(ilk); //accrue

        uint256 daiInURN = VAT.dai(cdpInfo.urn) / 10** 27; //18 decimals - after div

        if(daiInURN < amountToRepay) {
            _join(DAIILK, cdpInfo.urn, amountToRepay - daiInURN); //DAI is transferred in.
        }

        int256 dart = getWipeDeltaDebt(ilk, cdpInfo.urn);
        _manage(ilk, cdpInfo.cdpId, 0, dart);

        emit Repay(ilk, amountToRepay, _msgSender());
    }

    /** 
        @dev Repays the debt and withdraws the collateral
        @param ilk collateral type in bytes32 (ex: ethers.utils.formatBytes32String("WBTC-A"))
        @param amountToRepay Amount of DAI to repay(18 decimals)
        @param withdrawAmount Amount of collateral to withdraw (collateral's decimals)
    */
    function repayAndWithdraw(bytes32 ilk, uint256 amountToRepay, uint256 withdrawAmount) external {
        CDPInfo memory cdpInfo = cdpByOwner[_msgSender()][ilk];
        JUG.drip(ilk); //accrue

        uint256 daiInURN = VAT.dai(cdpInfo.urn) / 10** 27; //18 decimals - after div

        if(daiInURN < amountToRepay) {
            _join(DAIILK, cdpInfo.urn, amountToRepay - daiInURN); //DAI is transferred in.
        }

        int256 dart = getWipeDeltaDebt(ilk, cdpInfo.urn);
        _manage(ilk, cdpInfo.cdpId, -toInt(withdrawAmount), dart);

        
        uint256 withdrawAmount18Dec = withdrawAmount * 10 ** (18 - IERC20(JOINByIlk[ilk].collateralAddress).decimals());
        CDPManager.flux(cdpInfo.cdpId, address(this), withdrawAmount18Dec); //moves the DAI(internal) to this contract


        _exit(ilk, _msgSender(), withdrawAmount); //DAI is transferred out.   

        emit RepayAndWithdraw(ilk, amountToRepay, withdrawAmount, _msgSender());
    }

    ///@dev Repays all the debt of a CDP and withdraws all the collateral
    function repayAllAndWithdraw(bytes32 ilk) external {
        CDPInfo memory cdpInfo = cdpByOwner[_msgSender()][ilk];
        JUG.drip(ilk); //accrue
        
        uint256 amountToJoin = debt(ilk, cdpInfo.urn); //18 decimals //get totalDebt to add that amount to URN
        (uint256 withdrawAmount, ) = VAT.urns(ilk, cdpInfo.urn); //get total loacked collateral //18 decimals
        uint256 daiInURN = VAT.dai(cdpInfo.urn) / 10** 27; //18 decimals - after div
        
        if(daiInURN < amountToJoin) {
            _join(DAIILK, cdpInfo.urn, amountToJoin - daiInURN); //DAI is transferred into URN.
        }

        int256 amountToRepay = getWipeDeltaDebt(ilk, cdpInfo.urn); //returns the debt, that can be repaid by the DAI in URN.
        uint256 withdrawAmountInNativeDec = convert18ToTokenDecimals(withdrawAmount, IERC20(JOINByIlk[ilk].collateralAddress));
        
        _manage(ilk, cdpInfo.cdpId, -toInt(withdrawAmountInNativeDec), amountToRepay);
        
        CDPManager.flux(cdpInfo.cdpId, address(this), withdrawAmount); //moves the DAI(internal) to this contract

        _exit(ilk, _msgSender(), withdrawAmountInNativeDec); //DAI is transferred out.   

        emit RepayAllAndWithdraw(ilk, amountToJoin, withdrawAmountInNativeDec, _msgSender());
    }

    ///@dev Max allowed decimals is 18
    ///@dev Converts 18 decimals to the token's actual decimals
    function convert18ToTokenDecimals(uint256 input, IERC20 _token) internal view returns (uint256) {
        return input / 10 ** (18 - _token.decimals());
    }
    
    function setJoinAdapter(bytes32 ilk, address adapterAddress, address _collateralAddr) external onlyOwner {
        JOINByIlk[ilk].adapterAddress = adapterAddress;
        JOINByIlk[ilk].collateralAddress = _collateralAddr;

        IERC20Upgradeable(_collateralAddr).approve(adapterAddress, type(uint256).max);

        emit JoinAdapterUpdated(ilk, adapterAddress, _collateralAddr);
    }

    function setAddress(address _jug, address _vat) external onlyOwner {
        JUG = IJUG(_jug);
        VAT = IVAT(_vat);

        emit AddressUpdated(_jug, _vat);
    }

    /**
        @dev Creates a new CDP and URN. Only one CDP of a specific ilk is allowed.
        (i.e) Only one CDP per asset per user.
     */
    function _open(bytes32 ilk) internal returns(uint256 cdpId, address urn){
        require(cdpByOwner[_msgSender()][ilk].cdpId == 0, "vault exists");
        CDPManager.open(ilk, address(this));
        cdpId = CDPManager.last(address(this));
        urn = CDPManager.urns(cdpId);
        
        //Give the user permission to use this cdp.
        //another way is to use _msgSender() while open-ing above and do cdpAllow in frontEnd.
        CDPManager.cdpAllow(cdpId, _msgSender(), 1);
        // CDPManager.give(cdpId, _msgSender());

        VAT.hope(JOINByIlk[DAIILK].adapterAddress);//allows DAI-adapter to move DAI from VAT(to mint external DAI)

        cdpByOwner[_msgSender()][ilk] = CDPInfo(cdpId, urn);

        emit VaultCreated(ilk, _msgSender(), cdpId, urn);
    }

    ///@dev Adds(joins) the funds to the URN
    function _join(bytes32 ilk, address urn, uint256 amount) internal {
        JOINInfo memory joinInfo = JOINByIlk[ilk];

        IJoinAdapter joinAdapter = IJoinAdapter(joinInfo.adapterAddress);

        IERC20Upgradeable(joinInfo.collateralAddress).transferFrom(_msgSender(), address(this), amount);
        joinAdapter.join(urn, amount);

        emit FundsAdded(ilk, urn, amount, _msgSender());
    }   

    /**
        @dev updates the balance of collateral and debt in VAT. VAT.hope(address(this)) should be called before by cdpOwner.
        Funds should alreaby be in the urn or vat.

     */
    function _manage(bytes32 _ilk, uint256 _cdpId, int256 _amount, int256 _debt) internal {
        JUG.drip(_ilk);
        //amount should be in 18 decimals
        _amount = _amount * int256(10 ** (18 - IERC20(JOINByIlk[_ilk].collateralAddress).decimals()));
        
        CDPManager.frob(_cdpId, _amount, _debt); //both _amount and _debt should be in 18 decimals

        emit Manage(_ilk, _cdpId, _amount, _debt, _msgSender());
    }

    /**
        @dev `target` should have been HOPEd by the cdpOwner, so that EXIT can be called in next step.
        @dev Moves the internal-debt(dai) of cdp to `target`.
     */
    function _move(uint256 cdpId, address target, uint256 amountInRAD) internal {
        CDPManager.move(cdpId, target, amountInRAD);
    }

    ///@dev Moves the Funds out from adapter.
    function _exit(bytes32 ilk, address destination, uint256 amount) internal {
        IJoinAdapter(JOINByIlk[ilk].adapterAddress).exit(destination, amount);

        emit Withdraw(ilk, _msgSender(), destination, amount);
    }

    ///@return _debt18Decimals Debt of a specific urn in 18 decimals.
    ///@dev JUG.drip(ilk) should be called for accurate results.
    function debt(bytes32 ilk, address urn) public view returns (uint256 _debt18Decimals) {
        (, uint256 _debt) = VAT.urns(ilk, urn); //18 decimals
        (, uint256 _rate,,,) = VAT.ilks(ilk); //27 decimals
        
        _debt18Decimals = (_debt * _rate / 10**27) + 1 ether;
    }

    ///@dev Calculates the dart to use in frob
    ///@return deltaDebt The amount of art(debt) that can be rapaid using the DAI currently in URN
    function getWipeDeltaDebt(bytes32 ilk, address urn) public view returns (int256 deltaDebt) {
        (, uint256 _debt) = VAT.urns(ilk, urn); //18 decimals
        (, uint256 _rate,,,) = VAT.ilks(ilk); //27 decimals
        deltaDebt = toInt(VAT.dai(urn) / _rate);
        
        deltaDebt = uint256(deltaDebt) <= _debt ? -deltaDebt : -toInt(_debt);
    }

    function toInt(uint256 x) internal pure returns (int256 y) {
        y = int256(x);
        require(y >= 0, "int-overflow");
    }

    function isTrustedForwarder(address forwarder) public view returns(bool) {
        return forwarder == trustedForwarder;
    }

    function setTrustedForwarder(address forwarder) public onlyOwner {
        trustedForwarder = forwarder;
    }

    function _msgSender() internal override view returns (address ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            return msg.sender;
        }
    }

    function versionRecipient() external pure returns (string memory) {
        return "1";
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
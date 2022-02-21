/**
 *Submitted for verification at Etherscan.io on 2022-02-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}

interface IOwnable {
    function owner() external view returns (address);
}

interface IWETH {
    function withdraw(uint256 wad) external;
}

interface ICollector {
    function approve(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external;

    function transfer(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external;

    function initialize(address reserveController) external;

    function getFundsAdmin() external view returns (address);

    function REVISION() external view returns (uint256);
}

interface IInitializableAdminUpgradeabilityProxy {
    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(address newImplementation, bytes calldata data)
        external
        payable;

    function admin() external returns (address);

    function implementation() external returns (address);
}

interface IPool {
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ControllerV2Collector is Ownable {
    ICollector public constant COLLECTOR =
        ICollector(0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c);

    constructor(address aaveGovShortTimelock) {
        transferOwnership(aaveGovShortTimelock);
    }

    function approve(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external onlyOwner {
        COLLECTOR.approve(token, recipient, amount);
    }

    function transfer(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external onlyOwner {
        COLLECTOR.transfer(token, recipient, amount);
    }
}

library LibPropConstants {
    IInitializableAdminUpgradeabilityProxy public constant COLLECTOR_V2_PROXY =
        IInitializableAdminUpgradeabilityProxy(
            0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c
        );

    ICollector public constant NEW_COLLECTOR_IMPL =
        ICollector(0xa335E2443b59d11337E9005c9AF5bC31F8000714);

    address public constant GOV_SHORT_EXECUTOR =
        0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;

    IERC20 internal constant AAVE =
        IERC20(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);

    IERC20 internal constant USDC =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    IERC20 internal constant AUSDC =
        IERC20(0xBcca60bB61934080951369a648Fb03DF4F96263C);

    IERC20 internal constant AWETH =
        IERC20(0x030bA81f1c18d280636F32af80b9AAd02Cf0854e);
    IERC20 internal constant WETH =
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    IPool internal constant POOL =
        IPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);

    uint256 internal constant USDC_AMOUNT = 90000 * 1e6; // 90k USDC
    uint256 internal constant ETH_AMOUNT = 3 ether;

    address internal constant FUNDS_RECIPIENT =
        0xB85fa70cf9aB580580D437BdEA785b71631a8A7c;
}

contract PayloadAaveStarknetPhaseI {
    function execute() external {
        address controllerOfCollector = address(
            new ControllerV2Collector(LibPropConstants.GOV_SHORT_EXECUTOR)
        );

        LibPropConstants.COLLECTOR_V2_PROXY.upgradeToAndCall(
            address(LibPropConstants.NEW_COLLECTOR_IMPL),
            abi.encodeWithSelector(
                ICollector.initialize.selector,
                controllerOfCollector
            )
        );

        // We initialise the implementation, for security
        LibPropConstants.NEW_COLLECTOR_IMPL.initialize(address(0));

        ICollector(controllerOfCollector).transfer(
            LibPropConstants.AUSDC,
            address(this),
            LibPropConstants.USDC_AMOUNT
        );

        LibPropConstants.POOL.withdraw(
            address(LibPropConstants.USDC),
            LibPropConstants.USDC_AMOUNT,
            LibPropConstants.FUNDS_RECIPIENT
        );
        ICollector(controllerOfCollector).transfer(
            LibPropConstants.AWETH,
            address(this),
            LibPropConstants.ETH_AMOUNT
        );
        LibPropConstants.POOL.withdraw(
            address(LibPropConstants.WETH),
            LibPropConstants.ETH_AMOUNT,
            LibPropConstants.FUNDS_RECIPIENT
        );
    }
}
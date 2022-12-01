/**
 *Submitted for verification at Etherscan.io on 2022-12-01
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

/// @notice Constants used in Morpheus.
library Constants {
    /// @notice ETH address.
    address internal constant _ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice sETH address.
    address internal constant _stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    /// @notice cETH address.
    address internal constant _cETHER = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

    /// @notice WETH address.
    address internal constant _WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// @notice The address of Morpho Aave markets.
    address internal constant _MORPHO_AAVE = 0x777777c9898D384F785Ee44Acfe945efDFf5f3E0;

    /// @notice Address of Balancer contract.
    address internal constant _BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    /// @notice The address of Morpho Compound markets.
    address internal constant _MORPHO_COMPOUND = 0x8888882f8f843896699869179fB6E4f7e3B58888;

    /// @notice Address of Factory Guard contract.
    address internal constant _FACTORY_GUARD_ADDRESS = 0x5a15566417e6C1c9546523066500bDDBc53F88C7;

    /////////////////////////////////////////////////////////////////
    /// --- ERRORS
    ////////////////////////////////////////////////////////////////

    /// @dev Error message when the caller is not allowed to call the function.
    error NOT_ALLOWED();

    /// @dev Error message when the caller is not allowed to call the function.
    error INVALID_LENDER();

    /// @dev Error message when the market is invalid.
    error INVALID_MARKET();

    /// @dev Error message when the deadline has passed.
    error DEADLINE_EXCEEDED();

    /// @dev Error message for when the amount of received tokens is less than the minimum amount.
    error NOT_ENOUGH_RECEIVED();
}

interface IMorpheus {
    function multicall(uint256 deadline, bytes[] calldata data) external payable returns (bytes[] memory results);
}

interface IDSAuth {
    function setAuthority(address _authority) external;
    function authority() external view returns (address);
    function isAuthorized(address src, bytes4 sig) external view returns (bool);
}

interface IDSGuard {
    function canCall(address src_, address dst_, bytes4 sig) external view returns (bool);

    function permit(bytes32 src, bytes32 dst, bytes32 sig) external;

    function forbid(bytes32 src, bytes32 dst, bytes32 sig) external;

    function permit(address src, address dst, bytes32 sig) external;

    function forbid(address src, address dst, bytes32 sig) external;
}

interface IDSGuardFactory {
    function newGuard() external returns (address);
}

abstract contract ProxyPermission {
    /// @notice DSProxy execute function signature.
    bytes4 internal constant _EXECUTE_SELECTOR = bytes4(keccak256("execute(address,bytes)"));

    /// @notice Called in the context of DSProxy to authorize an address to call on behalf of the DSProxy.
    /// @param _target Address which will be authorized
    function _togglePermission(address _target, bool _give) internal {
        address currAuthority = IDSAuth(address(this)).authority();
        IDSGuard guard = IDSGuard(currAuthority);

        if (currAuthority == address(0)) {
            guard = IDSGuard(IDSGuardFactory(Constants._FACTORY_GUARD_ADDRESS).newGuard());
            IDSAuth(address(this)).setAuthority(address(guard));
        }

        if (_give && !guard.canCall(_target, address(this), _EXECUTE_SELECTOR)) {
            guard.permit(_target, address(this), _EXECUTE_SELECTOR);
        } else if (!_give && guard.canCall(_target, address(this), _EXECUTE_SELECTOR)) {
            guard.forbid(_target, address(this), _EXECUTE_SELECTOR);
        }
    }
}

interface IFlashLoan {
    function flashLoan(address _receiver, address[] memory _tokens, uint256[] memory _amounts, bytes calldata _data)
        external;
}

interface IFlashLoanBalancer {
    function flashLoanBalancer(address[] memory _tokens, uint256[] memory _amounts, bytes calldata _data) external;
}

/// @notice Free from the matrix.
/// @author @Mutative_
contract Neo is ProxyPermission {
    /// @notice Morpheus address.
    IMorpheus internal immutable _MORPHEUS;

    /// @notice Balancer Flash loan address.
    IFlashLoanBalancer internal immutable _FLASH_LOAN;

    constructor(address _morpheus, address _flashLoan) {
        _MORPHEUS = IMorpheus(_morpheus);
        _FLASH_LOAN = IFlashLoanBalancer(_flashLoan);
    }

    /// @notice Execute a flash loan from Balancer and call a series of actions on _Morpheus through DSProxy.
    /// @param tokens Array of tokens to flashloan.
    /// @param amounts Array of amounts to flashloan.
    /// @param data Data of actions to call on _Morpheus.
    function executeFlashloan(address[] calldata tokens, uint256[] calldata amounts, bytes calldata data)
        external
        payable
    {
        // Give _FLASH_LOAN permission to call execute on behalf DSProxy.
        _togglePermission(address(_FLASH_LOAN), true);

        // Execute flash loan.
        _FLASH_LOAN.flashLoanBalancer(tokens, amounts, data);

        // Remove _FLASH_LOAN permission to call execute on behalf DSProxy.
        _togglePermission(address(_FLASH_LOAN), false);
    }

    receive() external payable {}
}
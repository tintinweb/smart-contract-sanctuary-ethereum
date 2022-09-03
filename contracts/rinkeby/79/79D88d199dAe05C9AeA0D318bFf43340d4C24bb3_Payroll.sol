//SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IERC20Basic.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IUniswap.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "./BytesLib.sol";

/**
 * @title Think and Dev Paymentbox
 * @author Think and Dev Team
 * @notice Swap and transfer multiple ERC20 pairs to multiple accounts in a single transaction.
 * Use any router address of any DEX that uses Uniswap protocol v2 or v3 to make swaps.
 */
contract Payroll is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using BytesLib for bytes;
    /**
     * Returns the address of the Uniswap protocol router, it could be v2 or v3.
     */
    address public swapRouter;
    address public feeAddress;
    uint256 public fee;
    uint256 public constant MANTISSA = 1e18;
    uint256 public version;

    /**
     * Returns if the contract is working with a v2 Uniswap protocol;
     * true means v2, false means v3.
     */
    bool public isSwapV2;

    struct Payment {
        address token;
        address[] receivers;
        uint256[] amountsToTransfer;
    }

    struct SwapV2 {
        uint256 amountOut;
        uint256 amountInMax;
        address[] path;
    }

    struct SwapV3 {
        uint256 amountOut;
        uint256 amountInMax;
        bytes path;
    }

    event SwapRouterChanged(address _swapRouter, bool _isSwapV2);
    event FeeChanged(uint256 _fee);
    event UpdatedVersion(uint256 _version);
    event FeeCharged(address _erc20TokenAddress, address _feeAddress, uint256 _fees);
    event FeeAddressChanged(address _feeAddress);
    event BatchPayment(address _erc20TokenAddress, address[] _receivers, uint256[] _amountsToTransfer);
    event SwapFinished(address _tokenIn, address _tokenOut, uint256 _amountReceived);

    /**
     * @param _swapRouter Router address to execute swaps.
     * @param _isSwapV2 Boolean to specify the version of the router; true means v2, false means v3.
     */
    function initialize(
        address _swapRouter,
        bool _isSwapV2,
        address _feeAddress,
        uint256 _fee
    ) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        _setSwapRouter(_swapRouter, _isSwapV2);
        _setFeeAddress(_feeAddress);
        _setFee(_fee);
        _setVersion(1);
    }

    /**
     * Set the fee that will be charged, fees are divided by mantissa
     * @param _fee Percentage that will be charged.
     */
    function setFee(uint256 _fee) external onlyOwner {
        _setFee(_fee);
    }

    function setVersion(uint256 _version) external onlyOwner {
        _setVersion(_version);
    }

    function _setVersion(uint256 _version) internal {
        require(_version > 0, "Payroll: Version can't be 0");
        version = _version;
        emit UpdatedVersion(_version);
    }

    function _setFee(uint256 _fee) internal {
        require(_fee < 3e16, "Payroll: Fee should be less than 3%");
        fee = _fee;
        emit FeeChanged(_fee);
    }

    /**
     * Set the address that will receive the fees.
     * @param _feeAddress Address that will receive the fees.
     */
    function setFeeAddress(address _feeAddress) external onlyOwner {
        _setFeeAddress(_feeAddress);
    }

    function _setFeeAddress(address _feeAddress) internal {
        require(_feeAddress != address(0), "Payroll: Fee address can't be 0");
        feeAddress = _feeAddress;
        emit FeeAddressChanged(_feeAddress);
    }

    /**
     * Set the SwapRouter and the version to be used.
     * @param _swapRouter Router address to execute swaps.
     * @param _isSwapV2 Boolean to specify the version of the router; true means v2, false means v3.
     */
    function setSwapRouter(address _swapRouter, bool _isSwapV2) external onlyOwner {
        _setSwapRouter(_swapRouter, _isSwapV2);
    }

    function _setSwapRouter(address _swapRouter, bool _isSwapV2) internal {
        require(_swapRouter != address(0), "Payroll: Cannot set a 0 address as swapRouter");
        isSwapV2 = _isSwapV2;
        swapRouter = _swapRouter;
        emit SwapRouterChanged(_swapRouter, _isSwapV2);
    }

    /**
     * Approves the following token to be used on swapRouter
     * @param _erc20TokenOrigin ERC20 token address to approve.
     */
    function approveTokens(address[] calldata _erc20TokenOrigin) external nonReentrant {
        for (uint256 i = 0; i < _erc20TokenOrigin.length; i++) {
            // approves the swapRouter to spend totalAmountToSpend of erc20TokenOrigin
            TransferHelper.safeApprove(_erc20TokenOrigin[i], address(swapRouter), type(uint256).max);
        }
    }

    /**
     * Perform the swap with Uniswap V3 and the transfer to the given addresses.
     * @param _erc20TokenOrigin ERC20 token address to swap for another.
     * @param _totalAmountToSwap Total amount of erc20TokenOrigin to spend in swaps.
     * @param _deadline The unix timestamp after a swap will fail.
     * @param _swaps The array of the Swaps data.
     * @param _payments The array of the Payment data.
     * @notice Swap ERC20 to ERC20.
     * @notice Available to send ETH or ERC20.
     */
    function performSwapV3AndPayment(
        address _erc20TokenOrigin,
        uint256 _totalAmountToSwap,
        uint32 _deadline,
        SwapV3[] calldata _swaps,
        Payment[] calldata _payments
    ) external payable nonReentrant {
        require(!isSwapV2, "Payroll: Not uniswapV3");
        if (_swaps.length > 0) {
            _performSwapV3(_erc20TokenOrigin, _totalAmountToSwap, _deadline, _swaps);
        }

        _performMultiPayment(_payments);
        refundETH();
    }

    /**
     * Perform the swap with Uniswap V3 and the transfer to the given addresses.
     * @param _totalAmountToSwap Total amount of erc20TokenOrigin to spend in swaps.
     * @param _deadline The unix timestamp after a swap will fail.
     * @param _swaps The array of the Swaps data.
     * @param _payments The array of the Payment data.
     * @notice Swap ETH to ERC20.
     * @notice Available to send ETH or ERC20.
     */
    function performSwapV3AndPaymentETH(
        uint256 _totalAmountToSwap,
        uint32 _deadline,
        SwapV3[] calldata _swaps,
        Payment[] calldata _payments
    ) external payable nonReentrant {
        require(!isSwapV2, "Payroll: Not uniswapV3");
        if (_swaps.length > 0) {
            _performSwapV3ETH(_totalAmountToSwap, _deadline, _swaps);
        }

        _performMultiPayment(_payments);
        refundETH();
    }

    /**
     * Perform the swap with Uniswap V3 to the given token addresses and amounts.
     * @param _erc20TokenOrigin ERC20 token address to swap for another.
     * @param _totalAmountToSwap Total amount of erc20TokenOrigin to spend in swaps.
     * @param _deadline The unix timestamp after a swap will fail.
     * @param _swaps The array of the Swaps data.
     * @notice Swap ERC20 to ERC20.
     */
    function performSwapV3(
        address _erc20TokenOrigin,
        uint256 _totalAmountToSwap,
        uint32 _deadline,
        SwapV3[] calldata _swaps
    ) external nonReentrant {
        require(!isSwapV2, "Payroll: Not uniswapV3");
        require(_swaps.length > 0, "Payroll: Empty swaps");
        _performSwapV3(_erc20TokenOrigin, _totalAmountToSwap, _deadline, _swaps);
        refundETH();
    }

    /**
     * Perform the swap with Uniswap V3 to the given token addresses and amounts.
     * @param _totalAmountToSwap Total amount of erc20TokenOrigin to spend in swaps.
     * @param _deadline The unix timestamp after a swap will fail.
     * @param _swaps The array of the Swaps data.
     * @notice Swap ETH to ERC20.
     */
    function performSwapV3ETH(
        uint256 _totalAmountToSwap,
        uint32 _deadline,
        SwapV3[] calldata _swaps
    ) external payable nonReentrant {
        require(!isSwapV2, "Payroll: Not uniswapV3");
        require(_swaps.length > 0, "Payroll: Empty swaps");
        _performSwapV3ETH(_totalAmountToSwap, _deadline, _swaps);
        refundETH();
    }

    function _performSwapV3(
        address _erc20TokenOrigin,
        uint256 _totalAmountToSwap,
        uint32 _deadline,
        SwapV3[] calldata _swaps
    ) internal {
        // transfer the totalAmountToSpend of erc20TokenOrigin from the msg.sender to this contract
        // msg.sender must approve this contract for erc20TokenOrigin
        TransferHelper.safeTransferFrom(_erc20TokenOrigin, msg.sender, address(this), _totalAmountToSwap);
        address weth = IUniswapV3(swapRouter).WETH9();
        uint256 amountIn = 0;

        for (uint256 i = 0; i < _swaps.length; i++) {
            require(_swaps[i].path.length > 0, "Payroll: Empty path");
            require(
                _swaps[i].path.toAddress(_swaps[i].path.length - 20) == _erc20TokenOrigin,
                "Payroll: Swap not token origin"
            );
            // get the token to swap, it is at position 0 of the byte array
            address tokenTo = _swaps[i].path.toAddress(0);

            if (tokenTo == weth) {
                // if tokenTo is WETH, the contract needs to receive it to convert it to ETH and use it in payments (if needed)
                // then it will be refunded to msg.sender
                amountIn = IUniswapV3(swapRouter).exactOutput(
                    IUniswapV3.ExactOutputParams({
                        path: _swaps[i].path,
                        recipient: address(this),
                        deadline: _deadline,
                        amountOut: _swaps[i].amountOut,
                        amountInMaximum: _swaps[i].amountInMax
                    })
                );

                // receives WETH, so converts it to ETH
                IWETH(weth).withdraw(_swaps[i].amountOut);
            } else {
                // if tokenTo is any ERC20 the recipient is the msg.sender
                amountIn = IUniswapV3(swapRouter).exactOutput(
                    IUniswapV3.ExactOutputParams({
                        path: _swaps[i].path,
                        recipient: msg.sender,
                        deadline: _deadline,
                        amountOut: _swaps[i].amountOut,
                        amountInMaximum: _swaps[i].amountInMax
                    })
                );
            }

            emit SwapFinished(_erc20TokenOrigin, tokenTo, amountIn);
        }

        uint256 leftOver = IERC20Basic(_erc20TokenOrigin).balanceOf(address(this));
        if (leftOver > 0) {
            // return the leftover of _erc20TokenOrigin
            TransferHelper.safeTransfer(_erc20TokenOrigin, msg.sender, leftOver);
        }
    }

    function _performSwapV3ETH(
        uint256 _totalAmountToSwap,
        uint32 _deadline,
        SwapV3[] calldata _swaps
    ) internal {
        require(msg.value >= _totalAmountToSwap, "Payroll: Not enough msg.value");
        address weth = IUniswapV3(swapRouter).WETH9();

        for (uint256 i = 0; i < _swaps.length; i++) {
            require(_swaps[i].path.length > 0, "Payroll: Empty path");
            require(_swaps[i].path.toAddress(_swaps[i].path.length - 20) == weth, "Payroll: Swap not native token");
            uint256 amountIn = IUniswapV3(swapRouter).exactOutput{value: _swaps[i].amountInMax}(
                IUniswapV3.ExactOutputParams({
                    path: _swaps[i].path,
                    recipient: msg.sender,
                    deadline: _deadline,
                    amountOut: _swaps[i].amountOut,
                    amountInMaximum: _swaps[i].amountInMax
                })
            );
            emit SwapFinished(address(0), _swaps[i].path.toAddress(0), amountIn);
        }

        // Explicitly request ETH refound
        IUniswapV3(swapRouter).refundETH();
    }

    /**
     * Perform the swap with Uniswap V2 and the transfer to the given addresses.
     * @param _erc20TokenOrigin ERC20 token address to swap for another.
     * @param _totalAmountToSwap Total amount of erc20TokenOrigin to spend in swaps.
     * @param _deadline The unix timestamp after a swap will fail.
     * @param _swaps The array of the Swaps data.
     * @param _payments The array of the Payment data.
     * @notice Swap ERC20 to ERC20.
     * @notice Available to send ETH or ERC20.
     */
    function performSwapV2AndPayment(
        address _erc20TokenOrigin,
        uint256 _totalAmountToSwap,
        uint32 _deadline,
        SwapV2[] calldata _swaps,
        Payment[] calldata _payments
    ) external payable nonReentrant {
        require(isSwapV2, "Payroll: Not uniswapV2");
        if (_swaps.length > 0) {
            _performSwapV2(_erc20TokenOrigin, _totalAmountToSwap, _deadline, _swaps);
        }

        _performMultiPayment(_payments);
        refundETH();
    }

    /**
     * Perform the swap with Uniswap V2 and the transfer to the given addresses.
     * @param _totalAmountToSwap Total amount of erc20TokenOrigin to spend in swaps.
     * @param _deadline The unix timestamp after a swap will fail.
     * @param _swaps The array of the Swaps data.
     * @param _payments The array of the Payment data.
     * @notice Swap ETH to ERC20.
     * @notice Available to send ETH or ERC20.
     */
    function performSwapV2AndPaymentETH(
        uint256 _totalAmountToSwap,
        uint32 _deadline,
        SwapV2[] calldata _swaps,
        Payment[] calldata _payments
    ) external payable nonReentrant {
        require(isSwapV2, "Payroll: Not uniswapV2");
        if (_swaps.length > 0) {
            _performSwapV2ETH(_totalAmountToSwap, _deadline, _swaps);
        }

        _performMultiPayment(_payments);
        refundETH();
    }

    /**
     * Perform the swap with Uniswap V2 to the given token addresses and amounts.
     * @param _erc20TokenOrigin ERC20 token address to swap for another.
     * @param _totalAmountToSwap Total amount of erc20TokenOrigin to spend in swaps.
     * @param _deadline The unix timestamp after a swap will fail.
     * @param _swaps The array of the Swaps data.
     * @notice Swap ERC20 to ERC20.
     */
    function performSwapV2(
        address _erc20TokenOrigin,
        uint256 _totalAmountToSwap,
        uint32 _deadline,
        SwapV2[] calldata _swaps
    ) external nonReentrant {
        require(isSwapV2, "Payroll: Not uniswapV2");
        require(_swaps.length > 0, "Payroll: Empty swaps");
        _performSwapV2(_erc20TokenOrigin, _totalAmountToSwap, _deadline, _swaps);
        refundETH();
    }

    /**
     * Perform the swap with Uniswap V2 to the given token addresses and amounts.
     * @param _totalAmountToSwap Total amount of erc20TokenOrigin to spend in swaps.
     * @param _deadline The unix timestamp after a swap will fail.
     * @param _swaps The array of the Swaps data.
     * @notice Swap ETH to ERC20.
     */
    function performSwapV2ETH(
        uint256 _totalAmountToSwap,
        uint32 _deadline,
        SwapV2[] calldata _swaps
    ) external payable nonReentrant {
        require(isSwapV2, "Payroll: Not uniswapV2");
        require(_swaps.length > 0, "Payroll: Empty swaps");
        _performSwapV2ETH(_totalAmountToSwap, _deadline, _swaps);
        refundETH();
    }

    function _performSwapV2(
        address _erc20TokenOrigin,
        uint256 _totalAmountToSwap,
        uint32 _deadline,
        SwapV2[] calldata _swaps
    ) internal {
        // transfer the totalAmountToSpend of erc20TokenOrigin from the msg.sender to this contract
        // msg.sender must approve this contract for erc20TokenOrigin
        TransferHelper.safeTransferFrom(_erc20TokenOrigin, msg.sender, address(this), _totalAmountToSwap);
        uint256 amountIn = 0;
        address weth = IUniswapV2(swapRouter).WETH();

        for (uint256 i = 0; i < _swaps.length; i++) {
            require(_swaps[i].path.length > 0, "Payroll: Empty path");
            require(_swaps[i].path[0] == _erc20TokenOrigin, "Payroll: Swap not token origin");
            if (_swaps[i].path[_swaps[i].path.length - 1] == weth) {
                // if tokenTo is WETH, the contract needs to receive it to use it in payments (if needed)
                // then it will be refunded to msg.sender
                amountIn = IUniswapV2(swapRouter).swapTokensForExactETH(
                    _swaps[i].amountOut,
                    _swaps[i].amountInMax,
                    _swaps[i].path,
                    address(this),
                    _deadline
                )[0];
            } else {
                // if tokenTo is any ERC20 the recipient is the msg.sender
                amountIn = IUniswapV2(swapRouter).swapTokensForExactTokens(
                    _swaps[i].amountOut,
                    _swaps[i].amountInMax,
                    _swaps[i].path,
                    msg.sender,
                    _deadline
                )[0];
            }
            emit SwapFinished(_erc20TokenOrigin, _swaps[i].path[_swaps[i].path.length - 1], amountIn);
        }

        uint256 leftOver = IERC20Basic(_erc20TokenOrigin).balanceOf(address(this));
        if (leftOver > 0) {
            // return the leftover of _erc20TokenOrigin
            TransferHelper.safeTransfer(_erc20TokenOrigin, msg.sender, leftOver);
        }
    }

    function _performSwapV2ETH(
        uint256 _totalAmountToSwap,
        uint32 _deadline,
        SwapV2[] calldata _swaps
    ) internal {
        require(msg.value >= _totalAmountToSwap, "Payroll: Not enough msg.value");
        address weth = IUniswapV2(swapRouter).WETH();

        for (uint256 i = 0; i < _swaps.length; i++) {
            require(_swaps[i].path.length > 0, "Payroll: Empty path");
            require(_swaps[i].path[0] == weth, "Payroll: Swap not native token");
            // return the amount spend of tokenIn
            uint256 amountIn = IUniswapV2(swapRouter).swapETHForExactTokens{value: _swaps[i].amountInMax}(
                _swaps[i].amountOut,
                _swaps[i].path,
                msg.sender,
                _deadline
            )[0];
            address[] calldata path = _swaps[i].path;
            emit SwapFinished(address(0), path[path.length - 1], amountIn);
        }
    }

    /**
     * Perform the payments to the given addresses and amounts, public method.
     * @param _payments The array of the Payment data.
     * @notice Available to send ETH or ERC20.
     */
    function performMultiPayment(Payment[] calldata _payments) external payable nonReentrant {
        _performMultiPayment(_payments);
        refundETH();
    }

    function _performMultiPayment(Payment[] calldata _payments) internal {
        for (uint256 i = 0; i < _payments.length; i++) {
            require(_payments[i].amountsToTransfer.length > 0, "Payroll: No amounts to transfer");
            require(
                _payments[i].amountsToTransfer.length == _payments[i].receivers.length,
                "Payroll: Arrays must have same length"
            );

            if (_payments[i].token != address(0)) {
                _performERC20Payment(_payments[i].token, _payments[i].receivers, _payments[i].amountsToTransfer);
            } else {
                _performETHPayment(_payments[i].token, _payments[i].receivers, _payments[i].amountsToTransfer);
            }
        }
    }

    /**
     * Performs the ERC20 payment to the given addresses.
     * @param _erc20TokenAddress The address of the ERC20 token to transfer.
     * @param _receivers The array of payment receivers.
     * @param _amountsToTransfer The array of payments' amounts to perform.
     * The amount will be transfered to the address on _receivers with the same index.
     */
    function _performERC20Payment(
        address _erc20TokenAddress,
        address[] calldata _receivers,
        uint256[] calldata _amountsToTransfer
    ) internal {
        uint256 acumulatedFee = 0;
        uint256 totalAmountSent = 0;

        for (uint256 i = 0; i < _receivers.length; i++) {
            require(_receivers[i] != address(0), "Payroll: Cannot send to a 0 address");
            totalAmountSent = totalAmountSent + _amountsToTransfer[i];
            TransferHelper.safeTransferFrom(_erc20TokenAddress, msg.sender, _receivers[i], _amountsToTransfer[i]);
        }
        emit BatchPayment(_erc20TokenAddress, _receivers, _amountsToTransfer);

        acumulatedFee = (totalAmountSent * fee) / MANTISSA;
        if (acumulatedFee > 0) {
            TransferHelper.safeTransferFrom(_erc20TokenAddress, msg.sender, feeAddress, acumulatedFee);
        }
        emit FeeCharged(_erc20TokenAddress, feeAddress, acumulatedFee);
    }

    /**
     * Performs the ETH payment to the given addresses.
     * @param _receivers The array of payment receivers.
     * @param _amountsToTransfer The array of payments' amounts to perform.
     * The amount will be transfered to the address on _receivers with the same index.
     */
    function _performETHPayment(
        address _erc20TokenAddress,
        address[] calldata _receivers,
        uint256[] calldata _amountsToTransfer
    ) internal {
        uint256 acumulatedFee = 0;
        uint256 totalAmountSent = 0;

        for (uint256 i = 0; i < _receivers.length; i++) {
            require(_receivers[i] != address(0), "Payroll: Cannot send to a 0 address");
            totalAmountSent = totalAmountSent + _amountsToTransfer[i];

            (bool success, ) = payable(_receivers[i]).call{value: _amountsToTransfer[i]}("");
            require(success, "Payroll: ETH transfer failed");
        }
        emit BatchPayment(_erc20TokenAddress, _receivers, _amountsToTransfer);

        acumulatedFee = (totalAmountSent * fee) / MANTISSA;
        if (acumulatedFee > 0) {
            totalAmountSent = totalAmountSent + acumulatedFee;
            (bool success, ) = payable(feeAddress).call{value: acumulatedFee}("");
            require(success, "Payroll: ETH fee transfer failed");
        }
        emit FeeCharged(_erc20TokenAddress, feeAddress, acumulatedFee);
    }

    /**
     * Perform the refound of the leftover ETH.
     */
    function refundETH() internal {
        uint256 leftOver = address(this).balance;
        if (leftOver > 1) {
            (bool success, ) = payable(msg.sender).call{value: leftOver}("");
            require(success, "Payroll: ETH leftOver transfer failed");
        }
    }

    receive() external payable {}
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

//SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 */
interface IERC20Basic {
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

//SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

/**
 * @title IWETH
 * @dev Simpler version of IWETH interface
 */
interface IWETH {
    function withdraw(uint256 _amount) external;
}

//SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

/**
 * @title UniswapV2
 * @dev Simpler version of Uniswap v2 and v3 protocol interface
 */
interface IUniswapV2 {
    //Uniswap V2
    function WETH() external pure returns (address);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

/**
 * @title UniswapV2
 * @dev Simpler version of Uniswap v2 and v3 protocol interface
 */
interface IUniswapV3 {
    //UniswapV3
    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    function WETH9() external pure returns (address);

    function refundETH() external payable;

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

//SPDX-License-Identifier: AGPL-3.0-or-later
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity ^0.8.0;

library BytesLib {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don"t care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we"re done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin"s length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let"s just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, "toUint24_overflow");
        require(_bytes.length >= _start + 3, "toUint24_outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
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
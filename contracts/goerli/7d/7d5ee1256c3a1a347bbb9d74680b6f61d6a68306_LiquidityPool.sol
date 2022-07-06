// $$\   $$\                     $$\                                 $$$$$$$\                      $$\
// $$ |  $$ |                    $$ |                                $$  __$$\                     $$ |
// $$ |  $$ |$$\   $$\  $$$$$$\  $$$$$$$\   $$$$$$\  $$$$$$$\        $$ |  $$ | $$$$$$\   $$$$$$\  $$ |
// $$$$$$$$ |$$ |  $$ |$$  __$$\ $$  __$$\ $$  __$$\ $$  __$$\       $$$$$$$  |$$  __$$\ $$  __$$\ $$ |
// $$  __$$ |$$ |  $$ |$$ /  $$ |$$ |  $$ |$$$$$$$$ |$$ |  $$ |      $$  ____/ $$ /  $$ |$$ /  $$ |$$ |
// $$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$   ____|$$ |  $$ |      $$ |      $$ |  $$ |$$ |  $$ |$$ |
// $$ |  $$ |\$$$$$$$ |$$$$$$$  |$$ |  $$ |\$$$$$$$\ $$ |  $$ |      $$ |      \$$$$$$  |\$$$$$$  |$$ |
// \__|  \__| \____$$ |$$  ____/ \__|  \__| \_______|\__|  \__|      \__|       \______/  \______/ \__|
//           $$\   $$ |$$ |
//           \$$$$$$  |$$ |
//            \______/ \__|
//
// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./metatx/ERC2771ContextUpgradeable.sol";
import "../security/Pausable.sol";
import "./structures/TokenConfig.sol";
import "./interfaces/IExecutorManager.sol";
import "./interfaces/ILiquidityProviders.sol";
import "../interfaces/IERC20Permit.sol";
import "./interfaces/ITokenManager.sol";
import "./interfaces/ISwapAdaptor.sol";

contract LiquidityPool is
    Initializable,
    ReentrancyGuardUpgradeable,
    Pausable,
    OwnableUpgradeable,
    ERC2771ContextUpgradeable
{
    address private constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 private constant BASE_DIVISOR = 10000000000; // Basis Points * 100 for better accuracy
    uint256 private constant TOKEN_PRICE_BASE_DIVISOR = 10**28;

    uint256 public baseGas;

    IExecutorManager private executorManager;
    ITokenManager public tokenManager;
    ILiquidityProviders public liquidityProviders;

    struct PermitRequest {
        uint256 nonce;
        uint256 expiry;
        bool allowed;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    mapping(bytes32 => bool) public processedHash;
    mapping(address => uint256) public gasFeeAccumulatedByToken;

    // Gas fee accumulated by token address => executor address
    mapping(address => mapping(address => uint256)) public gasFeeAccumulated;

    // Incentive Pool amount per token address
    mapping(address => uint256) public incentivePool;

    mapping(string => address) public swapAdaptorMap;

    event AssetSent(
        address indexed asset,
        uint256 indexed amount,
        uint256 indexed transferredAmount,
        address target,
        bytes depositHash,
        uint256 fromChainId,
        uint256 lpFee,
        uint256 transferFee,
        uint256 gasFee
    );
    event Received(address indexed from, uint256 indexed amount);
    event Deposit(
        address indexed from,
        address indexed tokenAddress,
        address indexed receiver,
        uint256 toChainId,
        uint256 amount,
        uint256 reward,
        string tag
    );
    event GasFeeWithdraw(address indexed tokenAddress, address indexed owner, uint256 indexed amount);
    event LiquidityProvidersChanged(address indexed liquidityProvidersAddress);
    event TokenManagerChanged(address indexed tokenManagerAddress);
    event BaseGasUpdated(uint256 indexed baseGas);
    event EthReceived(address, uint256);
    event DepositAndSwap(
        address indexed from,
        address indexed tokenAddress,
        address indexed receiver,
        uint256 toChainId,
        uint256 amount,
        uint256 reward,
        string tag,
        SwapRequest[] swapRequests
    );
    event SwapAdaptorChanged(string indexed name, address indexed liquidityProvidersAddress);
    event GasFeeCalculated(
        uint256 indexed gasUsed,
        uint256 indexed gasPrice,
        uint256 indexed nativeTokenPriceInTransferredToken,
        uint256 tokenGasBaseFee,
        uint256 gasFeeInTransferredToken
    );

    // MODIFIERS
    modifier onlyExecutor() {
        require(executorManager.getExecutorStatus(_msgSender()), "Only executor is allowed");
        _;
    }

    modifier onlyLiquidityProviders() {
        require(_msgSender() == address(liquidityProviders), "Only liquidityProviders is allowed");
        _;
    }

    modifier tokenChecks(address tokenAddress) {
        (, bool supportedToken, , , ) = tokenManager.tokensInfo(tokenAddress);
        require(supportedToken, "Token not supported");
        _;
    }

    function initialize(
        address _executorManagerAddress,
        address _pauser,
        address _trustedForwarder,
        address _tokenManager,
        address _liquidityProviders
    ) public initializer {
        require(_executorManagerAddress != address(0), "ExecutorManager cannot be 0x0");
        require(_trustedForwarder != address(0), "TrustedForwarder cannot be 0x0");
        require(_liquidityProviders != address(0), "LiquidityProviders cannot be 0x0");
        __ERC2771Context_init(_trustedForwarder);
        __ReentrancyGuard_init();
        __Ownable_init();
        __Pausable_init(_pauser);
        executorManager = IExecutorManager(_executorManagerAddress);
        tokenManager = ITokenManager(_tokenManager);
        liquidityProviders = ILiquidityProviders(_liquidityProviders);
        baseGas = 21000;
    }

    function setSwapAdaptor(string calldata name, address _swapAdaptor) external onlyOwner {
        swapAdaptorMap[name] = _swapAdaptor;
        emit SwapAdaptorChanged(name, _swapAdaptor);
    }

    function setTrustedForwarder(address trustedForwarder) external onlyOwner {
        _setTrustedForwarder(trustedForwarder);
    }

    function setLiquidityProviders(address _liquidityProviders) external onlyOwner {
        require(_liquidityProviders != address(0), "LiquidityProviders can't be 0");
        liquidityProviders = ILiquidityProviders(_liquidityProviders);
        emit LiquidityProvidersChanged(_liquidityProviders);
    }

    function setTokenManager(address _tokenManager) external onlyOwner {
        require(_tokenManager != address(0), "TokenManager can't be 0");
        tokenManager = ITokenManager(_tokenManager);
        emit TokenManagerChanged(_tokenManager);
    }

    function setBaseGas(uint128 gas) external onlyOwner {
        baseGas = gas;
        emit BaseGasUpdated(baseGas);
    }

    function getExecutorManager() external view returns (address) {
        return address(executorManager);
    }

    function setExecutorManager(address _executorManagerAddress) external onlyOwner {
        require(_executorManagerAddress != address(0), "Executor Manager cannot be 0");
        executorManager = IExecutorManager(_executorManagerAddress);
    }

    function getCurrentLiquidity(address tokenAddress) public view returns (uint256 currentLiquidity) {
        uint256 liquidityPoolBalance = liquidityProviders.getCurrentLiquidity(tokenAddress);

        currentLiquidity =
            liquidityPoolBalance -
            liquidityProviders.totalLPFees(tokenAddress) -
            gasFeeAccumulatedByToken[tokenAddress] -
            incentivePool[tokenAddress];
    }

    /**
     * @dev Function used to deposit tokens into pool to initiate a cross chain token transfer.
     * @param toChainId Chain id where funds needs to be transfered
     * @param tokenAddress ERC20 Token address that needs to be transfered
     * @param receiver Address on toChainId where tokens needs to be transfered
     * @param amount Amount of token being transfered
     */
    function depositErc20(
        uint256 toChainId,
        address tokenAddress,
        address receiver,
        uint256 amount,
        string calldata tag
    ) public tokenChecks(tokenAddress) whenNotPaused nonReentrant {
        address sender = _msgSender();
        uint256 rewardAmount = _depositErc20(sender, toChainId, tokenAddress, receiver, amount);

        // Emit (amount + reward amount) in event
        emit Deposit(sender, tokenAddress, receiver, toChainId, amount + rewardAmount, rewardAmount, tag);
    }

    /**
     * @dev Function used to deposit tokens into pool to initiate a cross chain token swap And transfer .
     * @param toChainId Chain id where funds needs to be transfered
     * @param tokenAddress ERC20 Token address that needs to be transfered
     * @param receiver Address on toChainId where tokens needs to be transfered
     * @param amount Amount of token being transfered
     * @param tag Dapp unique identifier
     * @param swapRequest information related to token swap on exit chain
     */
    function depositAndSwapErc20(
        address tokenAddress,
        address receiver,
        uint256 toChainId,
        uint256 amount,
        string calldata tag,
        SwapRequest[] calldata swapRequest
    ) external tokenChecks(tokenAddress) whenNotPaused nonReentrant {
        uint256 totalPercentage = 0;
        {
            uint256 swapArrayLength = swapRequest.length;
            unchecked {
                for (uint256 index = 0; index < swapArrayLength; ++index) {
                    totalPercentage += swapRequest[index].percentage;
                }
            }
        }

        require(totalPercentage <= 100 * BASE_DIVISOR, "Total percentage cannot be > 100");
        address sender = _msgSender();
        uint256 rewardAmount = _depositErc20(sender, toChainId, tokenAddress, receiver, amount);
        // Emit (amount + reward amount) in event
        emit DepositAndSwap(
            sender,
            tokenAddress,
            receiver,
            toChainId,
            amount + rewardAmount,
            rewardAmount,
            tag,
            swapRequest
        );
    }

    function _depositErc20(
        address sender,
        uint256 toChainId,
        address tokenAddress,
        address receiver,
        uint256 amount
    ) internal returns (uint256) {
        require(toChainId != block.chainid, "To chain must be different than current chain");
        require(tokenAddress != NATIVE, "wrong function");
        TokenConfig memory config = tokenManager.getDepositConfig(toChainId, tokenAddress);

        require(config.min <= amount && config.max >= amount, "Deposit amount not in Cap limit");
        require(receiver != address(0), "Receiver address cannot be 0");
        require(amount != 0, "Amount cannot be 0");

        uint256 rewardAmount = getRewardAmount(amount, tokenAddress);
        if (rewardAmount != 0) {
            incentivePool[tokenAddress] = incentivePool[tokenAddress] - rewardAmount;
        }
        liquidityProviders.increaseCurrentLiquidity(tokenAddress, amount);
        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(tokenAddress), sender, address(this), amount);
        return rewardAmount;
    }

    function getRewardAmount(uint256 amount, address tokenAddress) public view returns (uint256 rewardAmount) {
        uint256 currentLiquidity = getCurrentLiquidity(tokenAddress);
        uint256 providedLiquidity = liquidityProviders.getSuppliedLiquidityByToken(tokenAddress);
        if (currentLiquidity < providedLiquidity) {
            uint256 liquidityDifference = providedLiquidity - currentLiquidity;
            if (amount >= liquidityDifference) {
                rewardAmount = incentivePool[tokenAddress];
            } else {
                // Multiply by 10000000000 to avoid 0 reward amount for small amount and liquidity difference
                rewardAmount = (amount * incentivePool[tokenAddress] * 10000000000) / liquidityDifference;
                rewardAmount = rewardAmount / 10000000000;
            }
        }
    }

    /**
     * DAI permit and Deposit.
     */
    function permitAndDepositErc20(
        address tokenAddress,
        address receiver,
        uint256 amount,
        uint256 toChainId,
        PermitRequest calldata permitOptions,
        string calldata tag
    ) external {
        IERC20Permit(tokenAddress).permit(
            _msgSender(),
            address(this),
            permitOptions.nonce,
            permitOptions.expiry,
            permitOptions.allowed,
            permitOptions.v,
            permitOptions.r,
            permitOptions.s
        );
        depositErc20(toChainId, tokenAddress, receiver, amount, tag);
    }

    /**
     * EIP2612 and Deposit.
     */
    function permitEIP2612AndDepositErc20(
        address tokenAddress,
        address receiver,
        uint256 amount,
        uint256 toChainId,
        PermitRequest calldata permitOptions,
        string calldata tag
    ) external {
        IERC20Permit(tokenAddress).permit(
            _msgSender(),
            address(this),
            amount,
            permitOptions.expiry,
            permitOptions.v,
            permitOptions.r,
            permitOptions.s
        );
        depositErc20(toChainId, tokenAddress, receiver, amount, tag);
    }

    /**
     * @dev Function used to deposit native token into pool to initiate a cross chain token transfer.
     * @param receiver Address on toChainId where tokens needs to be transfered
     * @param toChainId Chain id where funds needs to be transfered
     */
    function depositNative(
        address receiver,
        uint256 toChainId,
        string calldata tag
    ) external payable whenNotPaused nonReentrant {
        uint256 rewardAmount = _depositNative(receiver, toChainId);
        emit Deposit(_msgSender(), NATIVE, receiver, toChainId, msg.value + rewardAmount, rewardAmount, tag);
    }

    function depositNativeAndSwap(
        address receiver,
        uint256 toChainId,
        string calldata tag,
        SwapRequest[] calldata swapRequest
    ) external payable whenNotPaused nonReentrant {
        uint256 totalPercentage = 0;
        {
            uint256 swapArrayLength = swapRequest.length;
            unchecked {
                for (uint256 index = 0; index < swapArrayLength; ++index) {
                    totalPercentage += swapRequest[index].percentage;
                }
            }
        }

        require(totalPercentage <= 100 * BASE_DIVISOR, "Total percentage cannot be > 100");

        uint256 rewardAmount = _depositNative(receiver, toChainId); // TODO: check if need to pass msg.value
        emit DepositAndSwap(
            _msgSender(),
            NATIVE,
            receiver,
            toChainId,
            msg.value + rewardAmount,
            rewardAmount,
            tag,
            swapRequest
        );
    }

    function _depositNative(address receiver, uint256 toChainId) internal returns (uint256) {
        require(toChainId != block.chainid, "To chain must be different than current chain");
        require(
            tokenManager.getDepositConfig(toChainId, NATIVE).min <= msg.value &&
                tokenManager.getDepositConfig(toChainId, NATIVE).max >= msg.value,
            "Deposit amount not in Cap limit"
        );
        require(receiver != address(0), "Receiver address cannot be 0");
        require(msg.value != 0, "Amount cannot be 0");

        uint256 rewardAmount = getRewardAmount(msg.value, NATIVE);
        if (rewardAmount != 0) {
            incentivePool[NATIVE] = incentivePool[NATIVE] - rewardAmount;
        }
        liquidityProviders.increaseCurrentLiquidity(NATIVE, msg.value);
        return rewardAmount;
    }

    function sendFundsToUser(
        address tokenAddress,
        uint256 amount,
        address payable receiver,
        bytes calldata depositHash,
        uint256 tokenGasPrice,
        uint256 fromChainId
    ) external nonReentrant onlyExecutor whenNotPaused {
        uint256 initialGas = gasleft();
        TokenConfig memory config = tokenManager.getTransferConfig(tokenAddress);
        require(config.min <= amount && config.max >= amount, "Withdraw amount not in Cap limit");
        require(receiver != address(0), "Bad receiver address");

        (bytes32 hashSendTransaction, bool status) = checkHashStatus(tokenAddress, amount, receiver, depositHash);

        require(!status, "Already Processed");
        processedHash[hashSendTransaction] = true;

        // uint256 amountToTransfer, uint256 lpFee, uint256 transferFeeAmount, uint256 gasFee
        uint256[4] memory transferDetails = getAmountToTransfer(initialGas, tokenAddress, amount, tokenGasPrice);

        liquidityProviders.decreaseCurrentLiquidity(tokenAddress, transferDetails[0]);

        if (tokenAddress == NATIVE) {
            (bool success, ) = receiver.call{value: transferDetails[0]}("");
            require(success, "Native Transfer Failed");
        } else {
            SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(tokenAddress), receiver, transferDetails[0]);
        }

        emit AssetSent(
            tokenAddress,
            amount,
            transferDetails[0],
            receiver,
            depositHash,
            fromChainId,
            transferDetails[1],
            transferDetails[2],
            transferDetails[3]
        );
    }

    /**
     * @dev Internal function to calculate amount of token that needs to be transfered afetr deducting all required fees.
     * Fee to be deducted includes gas fee, lp fee and incentive pool amount if needed.
     * @param initialGas Gas provided initially before any calculations began
     * @param tokenAddress Token address for which calculation needs to be done
     * @param amount Amount of token to be transfered before deducting the fee
     * @param tokenGasPrice Gas price in the token being transfered to be used to calculate gas fee
     * @return [ amountToTransfer, lpFee, transferFeeAmount, gasFee ]
     */
    function getAmountToTransfer(
        uint256 initialGas,
        address tokenAddress,
        uint256 amount,
        uint256 tokenGasPrice
    ) internal returns (uint256[4] memory) {
        TokenInfo memory tokenInfo = tokenManager.getTokensInfo(tokenAddress);
        uint256 transferFeePerc = _getTransferFee(tokenAddress, amount, tokenInfo);
        uint256 lpFee;
        if (transferFeePerc > tokenInfo.equilibriumFee) {
            // Here add some fee to incentive pool also
            lpFee = (amount * tokenInfo.equilibriumFee) / BASE_DIVISOR;
            unchecked {
                incentivePool[tokenAddress] += (amount * (transferFeePerc - tokenInfo.equilibriumFee)) / BASE_DIVISOR;
            }
        } else {
            lpFee = (amount * transferFeePerc) / BASE_DIVISOR;
        }
        uint256 transferFeeAmount = (amount * transferFeePerc) / BASE_DIVISOR;

        liquidityProviders.addLPFee(tokenAddress, lpFee);

        uint256 totalGasUsed = initialGas + tokenInfo.transferOverhead + baseGas - gasleft();

        uint256 gasFee = totalGasUsed * tokenGasPrice;
        gasFeeAccumulatedByToken[tokenAddress] += gasFee;
        gasFeeAccumulated[tokenAddress][_msgSender()] += gasFee;
        uint256 amountToTransfer = amount - (transferFeeAmount + gasFee);
        return [amountToTransfer, lpFee, transferFeeAmount, gasFee];
    }

    function sendFundsToUserV2(
        address tokenAddress,
        uint256 amount,
        address payable receiver,
        bytes calldata depositHash,
        uint256 nativeTokenPriceInTransferredToken,
        uint256 fromChainId,
        uint256 tokenGasBaseFee
    ) external nonReentrant onlyExecutor whenNotPaused {
        uint256[4] memory transferDetails = _calculateAmountAndDecreaseAvailableLiquidity(
            tokenAddress,
            amount,
            receiver,
            depositHash,
            nativeTokenPriceInTransferredToken,
            tokenGasBaseFee
        );
        if (tokenAddress == NATIVE) {
            (bool success, ) = receiver.call{value: transferDetails[0]}("");
            require(success, "Native Transfer Failed");
        } else {
            SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(tokenAddress), receiver, transferDetails[0]);
        }

        emit AssetSent(
            tokenAddress,
            amount,
            transferDetails[0],
            receiver,
            depositHash,
            fromChainId,
            transferDetails[1],
            transferDetails[2],
            transferDetails[3]
        );
    }

    function swapAndSendFundsToUser(
        address tokenAddress,
        uint256 amount,
        address payable receiver,
        bytes calldata depositHash,
        uint256 nativeTokenPriceInTransferredToken,
        uint256 tokenGasBaseFee,
        uint256 fromChainId,
        uint256 swapGasOverhead,
        SwapRequest[] calldata swapRequests,
        string memory swapAdaptor
    ) external nonReentrant onlyExecutor whenNotPaused {
        require(swapRequests.length > 0, "Wrong method call");
        require(swapAdaptorMap[swapAdaptor] != address(0), "Swap adaptor not found");

        uint256[4] memory transferDetails = _calculateAmountAndDecreaseAvailableLiquidity(
            tokenAddress,
            amount,
            receiver,
            depositHash,
            nativeTokenPriceInTransferredToken,
            tokenGasBaseFee
        );

        if (tokenAddress == NATIVE) {
            (bool success, ) = swapAdaptorMap[swapAdaptor].call{value: transferDetails[0]}("");
            require(success, "Native Transfer to Adaptor Failed");
            ISwapAdaptor(swapAdaptorMap[swapAdaptor]).swapNative(transferDetails[0], receiver, swapRequests);
        } else {
            {
                uint256 gasBeforeApproval = gasleft();
                SafeERC20Upgradeable.safeApprove(
                    IERC20Upgradeable(tokenAddress),
                    address(swapAdaptorMap[swapAdaptor]),
                    0
                );
                SafeERC20Upgradeable.safeApprove(
                    IERC20Upgradeable(tokenAddress),
                    address(swapAdaptorMap[swapAdaptor]),
                    transferDetails[0]
                );

                swapGasOverhead += (gasBeforeApproval - gasleft());
            }
            {
                uint256 swapGasFee = calculateGasFee(
                    tokenAddress,
                    nativeTokenPriceInTransferredToken,
                    swapGasOverhead,
                    0,
                    _msgSender()
                );
                transferDetails[0] -= swapGasFee; // Deduct swap gas fee from amount to be sent
                transferDetails[3] += swapGasFee; // Add swap gas fee to gas fee
            }

            ISwapAdaptor(swapAdaptorMap[swapAdaptor]).swap(tokenAddress, transferDetails[0], receiver, swapRequests);
        }

        emit AssetSent(
            tokenAddress,
            amount,
            transferDetails[0],
            receiver,
            depositHash,
            fromChainId,
            transferDetails[1],
            transferDetails[2],
            transferDetails[3]
        );
    }

    function _calculateAmountAndDecreaseAvailableLiquidity(
        address tokenAddress,
        uint256 amount,
        address payable receiver,
        bytes calldata depositHash,
        uint256 nativeTokenPriceInTransferredToken,
        uint256 tokenGasBaseFee
    ) internal returns (uint256[4] memory) {
        uint256 initialGas = gasleft();
        TokenConfig memory config = tokenManager.getTransferConfig(tokenAddress);
        require(config.min <= amount && config.max >= amount, "Withdraw amount not in Cap limit");
        require(receiver != address(0), "Bad receiver address");
        (bytes32 hashSendTransaction, bool status) = checkHashStatus(tokenAddress, amount, receiver, depositHash);

        require(!status, "Already Processed");
        processedHash[hashSendTransaction] = true;
        // uint256 amountToTransfer, uint256 lpFee, uint256 transferFeeAmount, uint256 gasFee
        uint256[4] memory transferDetails = getAmountToTransferV2(
            initialGas,
            tokenAddress,
            amount,
            nativeTokenPriceInTransferredToken,
            tokenGasBaseFee
        );

        liquidityProviders.decreaseCurrentLiquidity(tokenAddress, transferDetails[0]);

        return transferDetails;
    }

    /**
     * @dev Internal function to calculate amount of token that needs to be transfered afetr deducting all required fees.
     * Fee to be deducted includes gas fee, lp fee and incentive pool amount if needed.
     * @param initialGas Gas provided initially before any calculations began
     * @param tokenAddress Token address for which calculation needs to be done
     * @param amount Amount of token to be transfered before deducting the fee
     * @param nativeTokenPriceInTransferredToken Price of native token in terms of the token being transferred (multiplied base div), used to calculate gas fee
     * @return [ amountToTransfer, lpFee, transferFeeAmount, gasFee ]
     */
    function getAmountToTransferV2(
        uint256 initialGas,
        address tokenAddress,
        uint256 amount,
        uint256 nativeTokenPriceInTransferredToken,
        uint256 tokenGasBaseFee
    ) internal returns (uint256[4] memory) {
        TokenInfo memory tokenInfo = tokenManager.getTokensInfo(tokenAddress);
        uint256 transferFeePerc = _getTransferFee(tokenAddress, amount, tokenInfo);
        uint256 lpFee;
        if (transferFeePerc > tokenInfo.equilibriumFee) {
            // Here add some fee to incentive pool also
            lpFee = (amount * tokenInfo.equilibriumFee) / BASE_DIVISOR;
            unchecked {
                incentivePool[tokenAddress] += (amount * (transferFeePerc - tokenInfo.equilibriumFee)) / BASE_DIVISOR;
            }
        } else {
            lpFee = (amount * transferFeePerc) / BASE_DIVISOR;
        }
        uint256 transferFeeAmount = (amount * transferFeePerc) / BASE_DIVISOR;

        liquidityProviders.addLPFee(tokenAddress, lpFee);

        uint256 totalGasUsed = initialGas + tokenInfo.transferOverhead + baseGas - gasleft();
        uint256 gasFee = calculateGasFee(
            tokenAddress,
            nativeTokenPriceInTransferredToken,
            totalGasUsed,
            tokenGasBaseFee,
            _msgSender()
        );
        require(transferFeeAmount + gasFee <= amount, "Insufficient funds to cover transfer fee");
        unchecked {
            uint256 amountToTransfer = amount - (transferFeeAmount + gasFee);
            return [amountToTransfer, lpFee, transferFeeAmount, gasFee];
        }
    }

    function calculateGasFee(
        address tokenAddress,
        uint256 nativeTokenPriceInTransferredToken,
        uint256 gasUsed,
        uint256 tokenGasBaseFee,
        address sender
    ) internal returns (uint256) {
        uint256 gasFee = (gasUsed * nativeTokenPriceInTransferredToken * tx.gasprice) /
            TOKEN_PRICE_BASE_DIVISOR +
            tokenGasBaseFee;
        emit GasFeeCalculated(gasUsed, tx.gasprice, nativeTokenPriceInTransferredToken, tokenGasBaseFee, gasFee);

        gasFeeAccumulatedByToken[tokenAddress] += gasFee;
        gasFeeAccumulated[tokenAddress][sender] += gasFee;
        return gasFee;
    }

    function _getTransferFee(
        address tokenAddress,
        uint256 amount,
        TokenInfo memory tokenInfo
    ) private view returns (uint256) {
        uint256 currentLiquidity = getCurrentLiquidity(tokenAddress);
        uint256 providedLiquidity = liquidityProviders.getSuppliedLiquidityByToken(tokenAddress);

        uint256 resultingLiquidity = currentLiquidity - amount;

        // We return a constant value in excess state
        if (resultingLiquidity > providedLiquidity) {
            return tokenManager.excessStateTransferFeePerc(tokenAddress);
        }

        // Fee is represented in basis points * 10 for better accuracy
        uint256 numerator = providedLiquidity * providedLiquidity * tokenInfo.equilibriumFee * tokenInfo.maxFee; // F(max) * F(e) * L(e) ^ 2
        uint256 denominator = tokenInfo.equilibriumFee *
            providedLiquidity *
            providedLiquidity +
            (tokenInfo.maxFee - tokenInfo.equilibriumFee) *
            resultingLiquidity *
            resultingLiquidity; // F(e) * L(e) ^ 2 + (F(max) - F(e)) * L(r) ^ 2

        uint256 fee;
        if (denominator == 0) {
            fee = 0;
        } else {
            fee = numerator / denominator;
        }
        return fee;
    }

    function getTransferFee(address tokenAddress, uint256 amount) external view returns (uint256) {
        return _getTransferFee(tokenAddress, amount, tokenManager.getTokensInfo(tokenAddress));
    }

    function checkHashStatus(
        address tokenAddress,
        uint256 amount,
        address payable receiver,
        bytes calldata depositHash
    ) public view returns (bytes32 hashSendTransaction, bool status) {
        hashSendTransaction = keccak256(abi.encode(tokenAddress, amount, receiver, keccak256(depositHash)));

        status = processedHash[hashSendTransaction];
    }

    function withdrawErc20GasFee(address tokenAddress) external onlyExecutor whenNotPaused nonReentrant {
        require(tokenAddress != NATIVE, "Can't withdraw native token fee");
        // uint256 gasFeeAccumulated = gasFeeAccumulatedByToken[tokenAddress];
        uint256 _gasFeeAccumulated = gasFeeAccumulated[tokenAddress][_msgSender()];
        require(_gasFeeAccumulated != 0, "Gas Fee earned is 0");
        gasFeeAccumulatedByToken[tokenAddress] = gasFeeAccumulatedByToken[tokenAddress] - _gasFeeAccumulated;
        gasFeeAccumulated[tokenAddress][_msgSender()] = 0;
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(tokenAddress), _msgSender(), _gasFeeAccumulated);
        emit GasFeeWithdraw(tokenAddress, _msgSender(), _gasFeeAccumulated);
    }

    function withdrawNativeGasFee() external onlyExecutor whenNotPaused nonReentrant {
        uint256 _gasFeeAccumulated = gasFeeAccumulated[NATIVE][_msgSender()];
        require(_gasFeeAccumulated != 0, "Gas Fee earned is 0");
        gasFeeAccumulatedByToken[NATIVE] = gasFeeAccumulatedByToken[NATIVE] - _gasFeeAccumulated;
        gasFeeAccumulated[NATIVE][_msgSender()] = 0;
        (bool success, ) = payable(_msgSender()).call{value: _gasFeeAccumulated}("");
        require(success, "Native Transfer Failed");

        emit GasFeeWithdraw(address(this), _msgSender(), _gasFeeAccumulated);
    }

    function transfer(
        address _tokenAddress,
        address receiver,
        uint256 _tokenAmount
    ) external whenNotPaused onlyLiquidityProviders nonReentrant {
        require(receiver != address(0), "Invalid receiver");
        if (_tokenAddress == NATIVE) {
            require(address(this).balance >= _tokenAmount, "ERR__INSUFFICIENT_BALANCE");
            (bool success, ) = receiver.call{value: _tokenAmount}("");
            require(success, "ERR__NATIVE_TRANSFER_FAILED");
        } else {
            IERC20Upgradeable baseToken = IERC20Upgradeable(_tokenAddress);
            require(baseToken.balanceOf(address(this)) >= _tokenAmount, "ERR__INSUFFICIENT_BALANCE");
            SafeERC20Upgradeable.safeTransfer(baseToken, receiver, _tokenAmount);
        }
    }

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }

    receive() external payable {
        emit EthReceived(_msgSender(), msg.value);
    }

    event GasFeeAccumulated(uint amount, address token, address executor);
    function setGasFeeAccumulated(uint amount, address token, address executor) external {
        gasFeeAccumulated[token][executor] = amount;
        gasFeeAccumulatedByToken[token] = gasFeeAccumulatedByToken[token] + amount;
        emit GasFeeAccumulated(amount, token, executor);
    }

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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
    uint256[49] private __gap;
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

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Context variant with ERC2771 support.
 * Here _trustedForwarder is made internal instead of private
 * so it can be changed via Child contracts with a setter method.
 */
abstract contract ERC2771ContextUpgradeable is Initializable, ContextUpgradeable {
    event TrustedForwarderChanged(address indexed _tf);

    address internal _trustedForwarder;

    function __ERC2771Context_init(address trustedForwarder) internal initializer {
        __Context_init_unchained();
        __ERC2771Context_init_unchained(trustedForwarder);
    }

    function __ERC2771Context_init_unchained(address trustedForwarder) internal initializer {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    function _setTrustedForwarder(address _tf) internal virtual {
        require(_tf != address(0), "TrustedForwarder can't be 0");
        _trustedForwarder = _tf;
        emit TrustedForwarderChanged(_tf);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Initializable, PausableUpgradeable {
    address private _pauser;

    event PauserChanged(address indexed previousPauser, address indexed newPauser);

    /**
     * @dev The pausable constructor sets the original `pauser` of the contract to the sender
     * account & Initializes the contract in unpaused state..
     */
    function __Pausable_init(address pauser) internal initializer {
        require(pauser != address(0), "Pauser Address cannot be 0");
        __Pausable_init();
        _pauser = pauser;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isPauser(address pauser) public view returns (bool) {
        return pauser == _pauser;
    }

    /**
     * @dev Throws if called by any account other than the pauser.
     */
    modifier onlyPauser() {
        require(isPauser(msg.sender), "Only pauser is allowed to perform this operation");
        _;
    }

    /**
     * @dev Allows the current pauser to transfer control of the contract to a newPauser.
     * @param newPauser The address to transfer pauserShip to.
     */
    function changePauser(address newPauser) public onlyPauser whenNotPaused {
        _changePauser(newPauser);
    }

    /**
     * @dev Transfers control of the contract to a newPauser.
     * @param newPauser The address to transfer ownership to.
     */
    function _changePauser(address newPauser) internal {
        require(newPauser != address(0));
        emit PauserChanged(_pauser, newPauser);
        _pauser = newPauser;
    }

    function renouncePauser() external virtual onlyPauser whenNotPaused {
        emit PauserChanged(_pauser, address(0));
        _pauser = address(0);
    }

    function pause() public onlyPauser {
        _pause();
    }

    function unpause() public onlyPauser {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

struct TokenInfo {
    uint256 transferOverhead;
    bool supportedToken;
    uint256 equilibriumFee; // Percentage fee Represented in basis points
    uint256 maxFee; // Percentage fee Represented in basis points
    TokenConfig tokenConfig;
}

struct TokenConfig {
    uint256 min;
    uint256 max;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IExecutorManager {
    function getExecutorStatus(address executor) external view returns (bool status);

    function getAllExecutors() external view returns (address[] memory);

    //Register new Executors
    function addExecutors(address[] calldata executorArray) external;

    // Register single executor
    function addExecutor(address executorAddress) external;

    //Remove registered Executors
    function removeExecutors(address[] calldata executorArray) external;

    // Remove Register single executor
    function removeExecutor(address executorAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface ILiquidityProviders {
    function BASE_DIVISOR() external view returns (uint256);

    function initialize(address _trustedForwarder, address _lpToken) external;

    function addLPFee(address _token, uint256 _amount) external;

    function addNativeLiquidity() external;

    function addTokenLiquidity(address _token, uint256 _amount) external;

    function claimFee(uint256 _nftId) external;

    function getFeeAccumulatedOnNft(uint256 _nftId) external view returns (uint256);

    function getSuppliedLiquidityByToken(address tokenAddress) external view returns (uint256);

    function getTokenPriceInLPShares(address _baseToken) external view returns (uint256);

    function getTotalLPFeeByToken(address tokenAddress) external view returns (uint256);

    function getTotalReserveByToken(address tokenAddress) external view returns (uint256);

    function getSuppliedLiquidity(uint256 _nftId) external view returns (uint256);

    function increaseNativeLiquidity(uint256 _nftId) external;

    function increaseTokenLiquidity(uint256 _nftId, uint256 _amount) external;

    function isTrustedForwarder(address forwarder) external view returns (bool);

    function owner() external view returns (address);

    function paused() external view returns (bool);

    function removeLiquidity(uint256 _nftId, uint256 amount) external;

    function renounceOwnership() external;

    function setLiquidityPool(address _liquidityPool) external;

    function setLpToken(address _lpToken) external;

    function setWhiteListPeriodManager(address _whiteListPeriodManager) external;

    function sharesToTokenAmount(uint256 _shares, address _tokenAddress) external view returns (uint256);

    function totalLPFees(address) external view returns (uint256);

    function totalLiquidity(address) external view returns (uint256);

    function totalReserve(address) external view returns (uint256);

    function totalSharesMinted(address) external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function whiteListPeriodManager() external view returns (address);

    function increaseCurrentLiquidity(address tokenAddress, uint256 amount) external;

    function decreaseCurrentLiquidity(address tokenAddress, uint256 amount) external;

    function getCurrentLiquidity(address tokenAddress) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20Detailed is IERC20Upgradeable {
  function name() external view returns(string memory);
  function decimals() external view returns(uint256);
}

interface IERC20Nonces is IERC20Detailed {
  function nonces(address holder) external view returns(uint);
}

interface IERC20Permit is IERC20Nonces {
  function permit(address holder, address spender, uint256 nonce, uint256 expiry,
                  bool allowed, uint8 v, bytes32 r, bytes32 s) external;

  function permit(address holder, address spender, uint256 value, uint256 expiry,
                  uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "../structures/TokenConfig.sol";

interface ITokenManager {
    function getEquilibriumFee(address tokenAddress) external view returns (uint256);

    function getMaxFee(address tokenAddress) external view returns (uint256);

    function changeFee(
        address tokenAddress,
        uint256 _equilibriumFee,
        uint256 _maxFee
    ) external;

    function tokensInfo(address tokenAddress)
        external
        view
        returns (
            uint256 transferOverhead,
            bool supportedToken,
            uint256 equilibriumFee,
            uint256 maxFee,
            TokenConfig memory config
        );

    function excessStateTransferFeePerc(address tokenAddress) external view returns (uint256);

    function getTokensInfo(address tokenAddress) external view returns (TokenInfo memory);

    function getDepositConfig(uint256 toChainId, address tokenAddress) external view returns (TokenConfig memory);

    function getTransferConfig(address tokenAddress) external view returns (TokenConfig memory);

    function changeExcessStateFee(address _tokenAddress, uint256 _excessStateFeePer) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
import "../structures/SwapRequest.sol";

interface ISwapAdaptor {
    function swap(
        address inputTokenAddress,
        uint256 amountInMaximum,
        address receiver,
        SwapRequest[] calldata swapRequests
    ) external returns (uint256 amountIn);

    function swapNative(
        uint256 amountInMaximum,
        address receiver,
        SwapRequest[] calldata swapRequests
    ) external returns (uint256 amountOut);
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

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

enum SwapOperation {ExactOutput, ExactInput}

struct SwapRequest {
    address tokenAddress;
    uint256 percentage;
    uint256 amount;
    SwapOperation operation;
    bytes path;
}
pragma solidity ^0.8.4;

import "./interfaces/ISocketRegistry.sol";
import "./utils/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract FeeRouter is Ownable,ReentrancyGuard {
    using SafeERC20 for IERC20;

    /**
     * @notice Address used to identify if it is a native token transfer or not
     */
    address private constant NATIVE_TOKEN_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @notice variable for our registry contract, registry contract is responsible for redirecting to different bridges
     */
    ISocketRegistry public immutable socket;

    // Errors
    error IntegratorIdAlreadyRegistered();
    error TotalFeeAndPartsMismatch();
    error IntegratorIdNotRegistered();
    error FeeMisMatch();
    error NativeTransferFailed();
    error MsgValueMismatch();

    // MAX value of totalFeeInBps.
    uint16 immutable PRECISION = 10000;

    constructor(address _socketRegistry, address owner_) Ownable(owner_) {
        socket = ISocketRegistry(_socketRegistry);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Events ------------------------------------------------------------------------------------------------------->

    /**
     * @notice Event emitted when an integrator registers their fee config
     */
    event RegisterFee(
        uint16 integratorId,
        uint16 totalFeeInBps,
        uint16 part1,
        uint16 part2,
        uint16 part3,
        address feeTaker1,
        address feeTaker2,
        address feeTaker3
    );

    /**
     * @notice Event emitted when integrator fee config is updated
     */
    event UpdateFee(
        uint16 integratorId,
        uint16 totalFeeInBps,
        uint16 part1,
        uint16 part2,
        uint16 part3,
        address feeTaker1,
        address feeTaker2,
        address feeTaker3
    );

    /**
     * @notice Event emitted when fee in tokens are claimed
     */
    event ClaimFee(
        uint16 integratorId,
        address tokenAddress,
        uint256 amount,
        address feeTaker
    );

    /**
     * @notice Event emitted when call registry is successful
     */
    event BridgeSocket(
        uint16 integratorId,
        uint256 amount,
        address inputTokenAddress,
        uint256 toChainId,
        uint256 middlewareId,
        uint256 bridgeId,
        uint256 totalFee
    );

    /**
     * @notice Container for Fee Request
     * @member integratorId Id of the integrator registered in the fee config
     * @member inputAmount amount sent to the fee router.
     * @member UserRequest request that is passed on to the registry
     */
    struct FeeRequest {
        uint16 integratorId;
        uint256 inputAmount;
        ISocketRegistry.UserRequest userRequest;
    }

    /**
     * @notice Container for Fee Splits
     * @member feeTaker address of the entity who will claim the fee
     * @member partOfTotalFeesInBps part of total fees that the feeTaker can claim
     */
    struct FeeSplits {
        address feeTaker;
        uint16 partOfTotalFeesInBps;
    }

    /**
     * @notice Mapping of valid integrators
     */
    mapping(uint16 => bool) validIntegrators;

    /**
     * @notice Mapping of integrator Ids and the total fee that can be cut from the input amount
     */
    mapping(uint16 => uint16) totalFeeMap;
    /**
     * @notice Mapping of integrator Ids and FeeSplits. FeeSplits is an array with the max size of 3
     * The total fee can be at max split into 3 parts
     */
    mapping(uint16 => FeeSplits[3]) feeSplitMap;

    /**
     * @notice Mapping of integratorId and the earned fee per token
     */
    mapping(uint16 => mapping(address => uint256)) earnedTokenFeeMap;

    // CORE FUNCTIONS ------------------------------------------------------------------------------------------------------>

    /**
     * @notice Owner can register a fee config against an integratorId
     * @dev totalFeeInBps and the sum of feesplits should be exactly equal, feeSplits can have a max size of 3
     * @param integratorId id of the integrator
     * @param totalFeeInBps totalFeeInBps, the max value can be 10000
     * @param feeSplits array of FeeSplits
     */
    function registerFeeConfig(
        uint16 integratorId,
        uint16 totalFeeInBps,
        FeeSplits[3] calldata feeSplits
    ) external onlyOwner {
        // Not checking for total fee in bps to be 0 as the total fee can be set to 0.
        if (validIntegrators[integratorId]) {
            revert IntegratorIdAlreadyRegistered();
        }

        uint16 x = feeSplits[0].partOfTotalFeesInBps +
            feeSplits[1].partOfTotalFeesInBps +
            feeSplits[2].partOfTotalFeesInBps;

        if (x != totalFeeInBps) {
            revert TotalFeeAndPartsMismatch();
        }

        totalFeeMap[integratorId] = totalFeeInBps;
        feeSplitMap[integratorId][0] = feeSplits[0];
        feeSplitMap[integratorId][1] = feeSplits[1];
        feeSplitMap[integratorId][2] = feeSplits[2];
        validIntegrators[integratorId] = true;
        _emitRegisterFee(integratorId, totalFeeInBps, feeSplits);
    }

    /**
     * @notice Owner can update the fee config against an integratorId
     * @dev totalFeeInBps and the sum of feesplits should be exactly equal, feeSplits can have a max size of 3
     * @param integratorId id of the integrator
     * @param totalFeeInBps totalFeeInBps, the max value can be 10000
     * @param feeSplits array of FeeSplits
     */
    function updateFeeConfig(
        uint16 integratorId,
        uint16 totalFeeInBps,
        FeeSplits[3] calldata feeSplits
    ) external onlyOwner {
        if (!validIntegrators[integratorId]) {
            revert IntegratorIdNotRegistered();
        }

        uint16 x = feeSplits[0].partOfTotalFeesInBps +
            feeSplits[1].partOfTotalFeesInBps +
            feeSplits[2].partOfTotalFeesInBps;

        if (x != totalFeeInBps) {
            revert TotalFeeAndPartsMismatch();
        }

        totalFeeMap[integratorId] = totalFeeInBps;
        feeSplitMap[integratorId][0] = feeSplits[0];
        feeSplitMap[integratorId][1] = feeSplits[1];
        feeSplitMap[integratorId][2] = feeSplits[2];
        _emitUpdateFee(integratorId, totalFeeInBps, feeSplits);
    }

    /**
     * @notice Function that sends the claimed fee to the corresponding integrator config addresses
     * @dev native token address to be used to claim native token fee, if earned fee is 0, it will return
     * @param integratorId id of the integrator
     * @param tokenAddress address of the token to claim fee against
     */
    function claimFee(uint16 integratorId, address tokenAddress) external nonReentrant {
        uint256 earnedFee = earnedTokenFeeMap[integratorId][tokenAddress];
        FeeSplits[3] memory integratorFeeSplits = feeSplitMap[integratorId];
        earnedTokenFeeMap[integratorId][tokenAddress] = 0;

        if (earnedFee == 0) {
            return;
        }
        for (uint8 i = 0; i < 3; i++) {
            _calculateAndClaimFee(
                integratorId,
                earnedFee,
                integratorFeeSplits[i].partOfTotalFeesInBps,
                totalFeeMap[integratorId],
                integratorFeeSplits[i].feeTaker,
                tokenAddress
            );
        }
    }

    /**
     * @notice Function that calls the registry after verifying if the fee is correct
     * @dev userRequest amount should match the aount after deducting the fee from the input amount
     * @param _feeRequest feeRequest contains the integratorId, the input amount and the user request that is passed to socket registry
     */
    function callRegistry(FeeRequest calldata _feeRequest) external payable nonReentrant {
        if (!validIntegrators[_feeRequest.integratorId]) {
            revert IntegratorIdNotRegistered();
        }

        // Get approval and token addresses.
        (
            address approvalAddress,
            address inputTokenAddress
        ) = _getApprovalAndInputTokenAddress(_feeRequest.userRequest);

        // Calculate Amount to Send to Registry.
        uint256 amountToBridge = _getAmountForRegistry(
            _feeRequest.integratorId,
            _feeRequest.inputAmount
        );

        if (_feeRequest.userRequest.amount != amountToBridge) {
            revert FeeMisMatch();
        }

        // Call Registry
        if (inputTokenAddress == NATIVE_TOKEN_ADDRESS) {
            if (msg.value != _feeRequest.inputAmount) revert MsgValueMismatch();
            socket.outboundTransferTo{
                value: msg.value - (_feeRequest.inputAmount - amountToBridge)
            }(_feeRequest.userRequest);
        } else {
            _getUserFundsToFeeRouter(
                msg.sender,
                _feeRequest.inputAmount,
                inputTokenAddress
            );
            IERC20(inputTokenAddress).safeApprove(
                approvalAddress,
                amountToBridge
            );
            socket.outboundTransferTo{value: msg.value}(
                _feeRequest.userRequest
            );
        }

        // Update the earned fee for the token and integrator.
        _updateEarnedFee(
            _feeRequest.integratorId,
            inputTokenAddress,
            _feeRequest.inputAmount,
            amountToBridge
        );

        // Emit Bridge Event
        _emitBridgeSocket(_feeRequest, inputTokenAddress, amountToBridge);
    }

    // INTERNAL UTILITY FUNCTION ------------------------------------------------------------------------------------------------------>

    /**
     * @notice function that sends the earned fee depending on the inputs
     * @dev tokens will not be transferred to zero addresses, earned fee against an integrator id is divided into the splits configured
     * @param integratorId id of the integrator
     * @param earnedFee amount of tokens earned as fee
     * @param part part of the amount that needs to be claimed in bps
     * @param total totalfee in bps
     * @param feeTaker address that the earned fee will be sent to after calculation
     * @param tokenAddress address of the token for claiming fee
     */
    function _calculateAndClaimFee(
        uint16 integratorId,
        uint256 earnedFee,
        uint16 part,
        uint16 total,
        address feeTaker,
        address tokenAddress
    ) internal {
        if (feeTaker != address(0)) {
            uint256 amountToBeSent = (earnedFee * part) / total;
            emit ClaimFee(integratorId, tokenAddress, amountToBeSent, feeTaker);
            if (tokenAddress == NATIVE_TOKEN_ADDRESS) {
                (bool success, ) = payable(feeTaker).call{
                    value: amountToBeSent
                }("");
                if (!success) revert NativeTransferFailed();
                return;
            }
            IERC20(tokenAddress).safeTransfer(feeTaker, amountToBeSent);
        }
    }

    /**
     * @notice function that returns the approval address and the input token address
     * @dev approval address is needed to approve the bridge or middleware implementaton before calling socket registry
     * @dev input token address is needed to identify the token in which the fee is being deducted
     * @param userRequest socket registry's user request
     * @return (address, address) returns the approval address and the inputTokenAddress
     */
    function _getApprovalAndInputTokenAddress(
        ISocketRegistry.UserRequest calldata userRequest
    ) internal view returns (address, address) {
        if (userRequest.middlewareRequest.id == 0) {
            (address routeAddress, , ) = socket.routes(
                userRequest.bridgeRequest.id
            );
            return (routeAddress, userRequest.bridgeRequest.inputToken);
        } else {
            (address routeAddress, , ) = socket.routes(
                userRequest.middlewareRequest.id
            );
            return (routeAddress, userRequest.middlewareRequest.inputToken);
        }
    }

    /**
     * @notice function that transfers amount from the user to this contract.
     * @param user address of the user who holds the tokens
     * @param amount amount of tokens to transfer
     * @param tokenAddress address of the token being bridged
     */
    function _getUserFundsToFeeRouter(
        address user,
        uint256 amount,
        address tokenAddress
    ) internal {
        IERC20(tokenAddress).safeTransferFrom(user, address(this), amount);
    }

    /**
     * @notice function that returns an amount after deducting the fee
     * @param integratorId id of the integrator
     * @param amount input amount to this contract when calling the function callRegistry
     * @return uint256 returns the amount after deduciting the fee
     */
    function _getAmountForRegistry(uint16 integratorId, uint256 amount)
        internal
        view
        returns (uint256)
    {
        return amount - ((amount * totalFeeMap[integratorId]) / PRECISION);
    }

    /**
     * @notice function that updated the earned fee against the integrator Id
     * @param integratorId id of the integrator
     * @param inputTokenAddress address of the token being bridged
     * @param amount input amount to this contract when calling the function callRegistry
     * @param registryAmount amount in user request that is passed on to registry
     */
    function _updateEarnedFee(
        uint16 integratorId,
        address inputTokenAddress,
        uint256 amount,
        uint256 registryAmount
    ) internal {
        earnedTokenFeeMap[integratorId][inputTokenAddress] =
            earnedTokenFeeMap[integratorId][inputTokenAddress] +
            amount -
            registryAmount;
    }

    /**
     * @notice function that emits the event BridgeSocket
     */
    function _emitBridgeSocket(
        FeeRequest calldata _feeRequest,
        address tokenAddress,
        uint256 registryAmount
    ) internal {
        emit BridgeSocket(
            _feeRequest.integratorId,
            _feeRequest.inputAmount,
            tokenAddress,
            _feeRequest.userRequest.toChainId,
            _feeRequest.userRequest.middlewareRequest.id,
            _feeRequest.userRequest.bridgeRequest.id,
            _feeRequest.inputAmount - registryAmount
        );
    }

    /**
     * @notice function that emits the event UpdateFee
     */
    function _emitUpdateFee(
        uint16 integratorId,
        uint16 totalFeeInBps,
        FeeSplits[3] calldata feeSplits
    ) internal {
        emit UpdateFee(
            integratorId,
            totalFeeInBps,
            feeSplits[0].partOfTotalFeesInBps,
            feeSplits[1].partOfTotalFeesInBps,
            feeSplits[2].partOfTotalFeesInBps,
            feeSplits[0].feeTaker,
            feeSplits[1].feeTaker,
            feeSplits[2].feeTaker
        );
    }

    /**
     * @notice function that emits the event RegisterFee
     */
    function _emitRegisterFee(
        uint16 integratorId,
        uint16 totalFeeInBps,
        FeeSplits[3] calldata feeSplits
    ) internal {
        emit RegisterFee(
            integratorId,
            totalFeeInBps,
            feeSplits[0].partOfTotalFeesInBps,
            feeSplits[1].partOfTotalFeesInBps,
            feeSplits[2].partOfTotalFeesInBps,
            feeSplits[0].feeTaker,
            feeSplits[1].feeTaker,
            feeSplits[2].feeTaker
        );
    }

    // VIEW FUNCTIONS --------------------------------------------------------------------------------------------------------->

    /**
     * @notice function that returns the amount in earned fee
     * @param integratorId id of the integrator
     * @param tokenAddress address of the token
     * @return uin256
     */
    function getEarnedFee(uint16 integratorId, address tokenAddress)
        public
        view
        returns (uint256)
    {
        return earnedTokenFeeMap[integratorId][tokenAddress];
    }

    /**
     * @notice function that returns if the integrator id is valid or not
     * @param integratorId id of the integrator
     * @return bool
     */
    function getValidIntegrator(uint16 integratorId)
        public
        view
        returns (bool)
    {
        return validIntegrators[integratorId];
    }

    /**
     * @notice function that returns the total fee in bps registered against the integrator id
     * @param integratorId id of the integrator
     * @return uint16
     */
    function getTotalFeeInBps(uint16 integratorId)
        public
        view
        returns (uint16)
    {
        return totalFeeMap[integratorId];
    }

    /**
     * @notice function that returns the FeeSplit array registered agains the integrator id
     * @param integratorId id of the integrator
     * @return feeSplits FeeSplits[3] - array of FeeSplits of size 3
     */
    function getFeeSplits(uint16 integratorId)
        public
        view
        returns (FeeSplits[3] memory feeSplits)
    {
        return feeSplitMap[integratorId];
    }

    // RESCUE FUNCTIONS ------------------------------------------------------------------------------------------------------>

    /**
     * @notice rescue function for emeregencies
     * @dev can only be called by the owner, should only be called during emergencies only
     * @param userAddress address of the user receiving funds
     * @param token address of the token being rescued
     * @param amount amount to be sent to the user
     */
    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(userAddress, amount);
    }

    /**
     * @notice rescue function for emeregencies
     * @dev can only be called by the owner, should only be called during emergencies only
     * @param userAddress address of the user receiving funds
     * @param amount amount to be sent to the user
     */
    function rescueNative(address payable userAddress, uint256 amount)
        external
        onlyOwner
    {
        userAddress.transfer(amount);
    }
}

pragma solidity ^0.8.4;

abstract contract ISocketRegistry {
    /**
     * @notice Container for Bridge Request
     * @member id denotes the underlying bridge to be used
     * @member optionalNativeAmount native token amount if not to be included in the value.
     * @member inputToken token being bridged
     * @member data this can be decoded to get extra data needed for different bridges
     */
    struct BridgeRequest {
        uint256 id;
        uint256 optionalNativeAmount;
        address inputToken;
        bytes data;
    }


    /**
     * @notice Container for Middleware Request
     * @member id denotes the underlying middleware to be used
     * @member optionalNativeAmount native token amount if not to be included in the value.
     * @member inputToken token being sent to middleware, for example swaps
     * @member data this can be decoded to get extra data needed for different middlewares
     */
    struct MiddlewareRequest {
        uint256 id;
        uint256 optionalNativeAmount;
        address inputToken;
        bytes data;
    }


    /**
     * @notice Container for User Request
     * @member receiverAddress address of the user receiving the bridged amount
     * @member toChainId id of the chain being bridged to
     * @member amount amount being bridged through registry
     * @member middlewareRequest 
     * @member bridgeRequest 
     */
    struct UserRequest {
        address receiverAddress;
        uint256 toChainId;
        uint256 amount;
        MiddlewareRequest middlewareRequest;
        BridgeRequest bridgeRequest;
    }

    /**
     * @notice Container for Route Data
     * @dev middlwares and bridges are both added into the same routes
     * @member route address of the implementation contract fo a bride or middleware
     * @member isEnabled bool variable that denotes if the particular route is enabled or disabled
     * @member isMiddleware bool variable that denotes if the particular route is a middleware or not
     */
    struct RouteData {
        address route;
        bool isEnabled;
        bool isMiddleware;
    }

    /**
     * @notice Resgistered Routes on the socket registry
     * @dev middlwares and bridges are both added into the same routes
     */
    RouteData[] public routes;

    /**
     * @notice Function called in the socket registry for bridging
     */
    function outboundTransferTo(UserRequest calldata _userRequest)
        external
        payable
        virtual;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

abstract contract Ownable {
    address private _owner;
    address private _nominee;

    event OwnerNominated(address indexed nominee);
    event OwnerClaimed(address indexed claimer);

    error OnlyOwner();
    error OnlyNominee();

    constructor(address owner_) {
        _claimOwner(owner_);
    }

    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert OnlyOwner();
        }
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function nominee() public view returns (address) {
        return _nominee;
    }

    function nominateOwner(address nominee_) external {
        if (msg.sender != _owner) {
            revert OnlyOwner();
        }
        _nominee = nominee_;
        emit OwnerNominated(_nominee);
    }

    function claimOwner() external {
        if (msg.sender != _nominee) {
            revert OnlyNominee();
        }
        _claimOwner(msg.sender);
    }

    function _claimOwner(address claimer_) internal {
        _owner = claimer_;
        _nominee = address(0);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
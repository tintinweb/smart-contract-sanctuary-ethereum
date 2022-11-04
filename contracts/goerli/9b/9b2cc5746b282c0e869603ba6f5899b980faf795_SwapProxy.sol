// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/silicaFactory/ISilicaFactory.sol";
import "./interfaces/silica/ISilicaV2_1.sol";
import "./libraries/OrderLib.sol";
import "./interfaces/silicaVault/ISilicaVault.sol";

/**
 * @notice Swap Proxy
 * @author Alkimiya Team
 */
contract SwapProxy is EIP712, Ownable, ReentrancyGuard {
    event OrderExecuted(OrderLib.OrderFilledData orderData);

    event OrderCancelled(address buyerAddress, address sellerAddress, bytes32 orderHash);

    // Mapping of orderHash => cancelled
    mapping(bytes32 => uint256) public totalInvested;
    mapping(bytes32 => bool) public cancelled;
    mapping(bytes32 => address) public silicaCreated;

    ISilicaFactory private silicaFactory;

    function domainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    constructor(string memory name) EIP712(name, "1") {}

    function setSilicaFactory(address _silicaFactoryAddress) external onlyOwner {
        silicaFactory = ISilicaFactory(_silicaFactoryAddress);
    }

    /// @notice Function to match Buyer order and Seller order and fulfill a silica
    function executeOrder(
        OrderLib.Order calldata buyerOrder,
        OrderLib.Order calldata sellerOrder,
        bytes memory buyerSignature,
        bytes memory sellerSignature
    ) external returns (address) {
        bytes32 buyerOrderHash = _hashTypedDataV4(OrderLib.getOrderHash(buyerOrder));
        bytes32 sellerOrderHash = _hashTypedDataV4(OrderLib.getOrderHash(sellerOrder));
        validateOrder(buyerOrder, buyerOrderHash, sellerOrder, sellerOrderHash, buyerSignature, sellerSignature);

        checkIfOrderMatches(buyerOrder, sellerOrder);

        // create silica
        address silicaAddress = executeCreateSilica(sellerOrder, sellerOrderHash);

        uint256 reservedPrice = ISilicaV2_1(silicaAddress).getReservedPrice();
        uint256 totalPaymentAmount = reservedPrice < buyerOrder.amount ? reservedPrice : buyerOrder.amount;
        uint256 totalSellerInvested = IERC20(sellerOrder.paymentToken).balanceOf(silicaAddress);

        require(buyerOrder.amount >= totalInvested[buyerOrderHash] + totalPaymentAmount, "buyer order payment amount too low");
        require(totalSellerInvested + totalPaymentAmount <= reservedPrice, "seller order amount too low");

        OrderLib.OrderFilledData memory orderData;

        orderData.silicaContract = silicaAddress;
        orderData.buyerOrderHash = buyerOrderHash;
        orderData.sellerOrderHash = sellerOrderHash;
        orderData.buyerAddress = buyerOrder.buyerAddress;
        orderData.sellerAddress = sellerOrder.sellerAddress;
        orderData.unitPrice = sellerOrder.unitPrice;
        orderData.endDay = sellerOrder.endDay;
        orderData.totalPaymentAmount = totalPaymentAmount;
        orderData.reservedPrice = reservedPrice;

        emit OrderExecuted(orderData);
        if (buyerOrder.orderType == 1) {
            SafeERC20.safeTransferFrom(IERC20(sellerOrder.paymentToken), buyerOrder.buyerAddress, address(this), totalPaymentAmount);
            IERC20(sellerOrder.paymentToken).approve(silicaAddress, totalPaymentAmount);
            ISilicaV2_1(silicaAddress).proxyDeposit(buyerOrder.buyerAddress, totalPaymentAmount);
        } else if (buyerOrder.orderType == 2) {
            ISilicaVault(buyerOrder.buyerAddress).purchaseSilica(silicaAddress, totalPaymentAmount);
        }
        totalInvested[buyerOrderHash] += totalPaymentAmount;
        return silicaAddress;
    }

    /// @notice Function to cancle a listed order
    function cancelOrder(OrderLib.Order calldata order, bytes memory signature) external {
        bytes32 orderHash = _hashTypedDataV4(OrderLib.getOrderHash(order));
        address _signerAddress = ECDSA.recover(orderHash, signature);
        require(_signerAddress == msg.sender, "order cannot be cancelled");
        cancelled[orderHash] = true;
        emit OrderCancelled(order.buyerAddress, order.sellerAddress, orderHash);
    }

    /// @notice Function to return how much a order has been fulfilled
    function getOrderFill(bytes32 orderHash) external view returns (uint256 fillAmount) {
        address silicaAddress = silicaCreated[orderHash];
        if (silicaAddress != address(0)) {
            fillAmount = IERC20(ISilicaV2_1(silicaAddress).getPaymentToken()).balanceOf(silicaAddress);
        } else {
            return totalInvested[orderHash];
        }
    }

    /// @notice Function to check if an order is canceled
    function isOrderCancelled(bytes32 orderHash) external view returns (bool) {
        return cancelled[orderHash];
    }

    /// @notice Function to return the Silica Address created from an order
    function getSilicaAddress(bytes32 orderHash) external view returns (address) {
        return silicaCreated[orderHash];
    }

    /// @notice Function to check if a seller order matches a buyer order
    function checkIfOrderMatches(OrderLib.Order calldata buyerOrder, OrderLib.Order calldata sellerOrder) public pure {
        require(buyerOrder.unitPrice >= sellerOrder.unitPrice, "unit price does not match");
        require(buyerOrder.paymentToken == sellerOrder.paymentToken, "payment token does not match");
        require(buyerOrder.rewardToken == sellerOrder.rewardToken, "reward token does not match");
        require(buyerOrder.silicaType == sellerOrder.silicaType, "silica type does not match");
        require(buyerOrder.endDay >= sellerOrder.endDay, "end day does not match");
    }

    /// @notice Internal function to fulfill a matching pair of seller and buyer order
    function executeCreateSilica(OrderLib.Order calldata sellerOrder, bytes32 orderHash) internal returns (address silicaAddress) {
        // check if silica has been created already
        if (silicaCreated[orderHash] != address(0)) {
            return silicaCreated[orderHash];
        }
        if (sellerOrder.silicaType == 1) {
            // Eth Gas Swap
            silicaAddress = ISilicaFactory(silicaFactory).proxyCreateGasSwapSilicaV2_1(
                sellerOrder.rewardToken,
                sellerOrder.paymentToken,
                sellerOrder.amount,
                sellerOrder.endDay,
                sellerOrder.unitPrice,
                sellerOrder.sellerAddress
            );
        } else if (sellerOrder.silicaType == 2) {
            // Avax Gas Swap
            silicaAddress = ISilicaFactory(silicaFactory).proxyCreateAvaxSwapSilicaV2_1(
                sellerOrder.rewardToken,
                sellerOrder.paymentToken,
                sellerOrder.amount,
                sellerOrder.endDay,
                sellerOrder.unitPrice,
                sellerOrder.sellerAddress
            );
        } else if (sellerOrder.silicaType == 0) {
            // WETH, WBTC, WAVAX
            silicaAddress = ISilicaFactory(silicaFactory).proxyCreateSilicaV2_1(
                sellerOrder.rewardToken,
                sellerOrder.paymentToken,
                sellerOrder.amount,
                sellerOrder.endDay,
                sellerOrder.unitPrice,
                sellerOrder.sellerAddress
            );
        }

        require(silicaAddress != address(0), "silica cannot be created");

        silicaCreated[orderHash] = silicaAddress;
    }

    /// @notice Internal function fo validate an order's signature
    function validateOrderSignature(
        OrderLib.Order calldata _order,
        bytes32 orderHash,
        bytes memory signature
    ) internal view {
        if (_order.orderExpirationTimestamp != 0) {
            require(block.timestamp <= _order.orderExpirationTimestamp, "order expired");
        }

        require(cancelled[orderHash] == false, "This order was cancelled");
        address _signerAddress = ECDSA.recover(orderHash, signature);
        if (_order.orderType == 0) {
            require(_order.sellerAddress == _signerAddress, "order not signed by the seller");
        } else if (_order.orderType == 1) {
            require(_order.buyerAddress == _signerAddress, "order not signed by the buyer");
        } else if (_order.orderType == 2) {
            require(ISilicaVault(_order.buyerAddress).getAdmin() == _signerAddress, "order not signed by admin of the HashVault");
        } else {
            revert("invalid orderType");
        }
    }

    /// @notice Internal function fo validate an order's signature
    function validateOrder(
        OrderLib.Order calldata buyerOrder,
        bytes32 buyerOrderHash,
        OrderLib.Order calldata sellerOrder,
        bytes32 sellerOrderHash,
        bytes memory buyerSignature,
        bytes memory sellerSignature
    ) internal {
        require(buyerOrder.orderType == 1 || buyerOrder.orderType == 2, "not a buyer order");
        require(sellerOrder.orderType == 0, "not a seller order");

        validateOrderSignature(sellerOrder, sellerOrderHash, sellerSignature);
        validateOrderSignature(buyerOrder, buyerOrderHash, buyerSignature);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {SilicaV2_1Types} from "../../libraries/SilicaV2_1Types.sol";

/**
 * @title The interface for Silica
 * @author Alkimiya Team
 * @notice A Silica contract lists hashrate for sale
 * @dev The Silica interface is broken up into smaller interfaces
 */
interface ISilicaV2_1 {
    struct InitializeData {
        address rewardTokenAddress;
        address paymentTokenAddress;
        address oracleRegistry;
        address sellerAddress;
        uint256 dayOfDeployment;
        uint256 lastDueDay;
        uint256 unitPrice;
        uint256 resourceAmount;
        uint256 collateralAmount;
    }

    /// @notice Returns the amount of rewards the seller must have delivered before next update
    /// @return rewardDueNextOracleUpdate amount of rewards the seller must have delivered before next update
    function getRewardDueNextOracleUpdate() external view returns (uint256);

    /// @notice Initializes the contract
    /// @param initializeData is the address of the token the seller is selling
    function initialize(InitializeData memory initializeData) external;

    /// @notice Function called by buyer to deposit payment token in the contract in exchange for Silica tokens
    /// @param amountSpecified is the amount that the buyer wants to deposit in exchange for Silica tokens
    function deposit(uint256 amountSpecified) external returns (uint256);

    /// @notice Called by the swapProxy to make a deposit in the name of a buyer
    /// @param _to the address who should receive the Silica Tokens
    /// @param amountSpecified is the amount the swapProxy is depositing for the buyer in exchange for Silica tokens
    function proxyDeposit(address _to, uint256 amountSpecified) external returns (uint256);

    /// @notice Function the buyer calls to collect payout when the contract status is Finished
    function buyerCollectPayout() external returns (uint256 rewardTokenPayout);

    /// @notice Function the buyer calls to collect payout when the contract status is Defaulted
    function buyerCollectPayoutOnDefault() external returns (uint256 rewardTokenPayout, uint256 paymentTokenPayout);

    /// @notice Function the seller calls to collect payout when the contract status is Finised
    function sellerCollectPayout() external returns (uint256 paymentTokenPayout, uint256 rewardTokenExcess);

    /// @notice Function the seller calls to collect payout when the contract status is Defaulted
    function sellerCollectPayoutDefault() external returns (uint256 paymentTokenPayout, uint256 rewardTokenExcess);

    /// @notice Function the seller calls to collect payout when the contract status is Expired
    function sellerCollectPayoutExpired() external returns (uint256 rewardTokenPayout);

    /// @notice Returns the owner of this Silica
    /// @return address: owner address
    function getOwner() external view returns (address);

    /// @notice Returns the Payment Token accepted in this Silica
    /// @return Address: Token Address
    function getPaymentToken() external view returns (address);

    /// @notice Returns the rewardToken address. The rewardToken is the token fo wich are made the rewards the seller is selling
    /// @return The rewardToken address. The rewardToken is the token fo wich are made the rewards the seller is selling
    function getRewardToken() external view returns (address);

    //@review: this function is needed for storage management with foundry, could be removed for production
    function getStorageStatus() external view returns (SilicaV2_1Types.Status);

    /// @notice Get the current status of the contract
    /// @return status: The current status of the contract
    function getStatus() external view returns (SilicaV2_1Types.Status);

    /// @notice Returns the day of default.
    /// @return day: The day the contract defaults
    function getDayOfDefault() external view returns (uint256);

    /// @notice Returns true if contract is in Open status
    function isOpen() external view returns (bool);

    /// @notice Returns true if contract is in Running status
    function isRunning() external view returns (bool);

    /// @notice Returns true if contract is in Expired status
    function isExpired() external view returns (bool);

    /// @notice Returns true if contract is in Defaulted status
    function isDefaulted() external view returns (bool);

    /// @notice Returns true if contract is in Finished status
    function isFinished() external view returns (bool);

    /// @notice Returns amount of rewards delivered so far by contract
    function getRewardDeliveredSoFar() external view returns (uint256);

    /// @notice Returns the most recent day the contract owes in rewards
    /// @dev The returned value does not indicate rewards have been fulfilled up to that day
    /// This only returns the most recent day the contract should deliver rewards
    function getLastDayContractOwesReward(uint256 lastDueDay, uint256 lastIndexedDay) external view returns (uint256);

    /// @notice Returns the reserved price of the contract
    function getReservedPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ISilicaFactoryEvents.sol";

/**
 * @title Interface for Silica Account for ERC20 assets
 * @author Alkimiya team
 * @notice This class needs to be inherited
 */
interface ISilicaFactory is ISilicaFactoryEvents {
    /// @notice Creates a SilicaV2_1 contract
    /// @param _rewardTokenAddress The address of the token of the rewards beeing sold by the seller
    /// @param _paymentTokenAddress address of the token that can be used to buy silica from this contract
    /// @param _resourceAmount hashrate the seller is selling
    /// @param _lastDueDay the last day of rewards the seller is selling
    /// @param _unitPrice the price of gH/day
    /// @return address: The address of the contract created
    function createSilicaV2_1(
        address _rewardTokenAddress,
        address _paymentTokenAddress,
        uint256 _resourceAmount,
        uint256 _lastDueDay,
        uint256 _unitPrice
    ) external returns (address);

    /// @notice Creates a SilicaV2_1 contract from SwapProxy
    /// @param _rewardTokenAddress The address of the token of the rewards beeing sold by the seller
    /// @param _paymentTokenAddress address of the token that can be used to buy silica from this contract
    /// @param _resourceAmount hashrate the seller is selling
    /// @param _lastDueDay the last day of rewards the seller is selling
    /// @param _unitPrice the price of gH/day
    /// @param _sellerAddress the seller address
    /// @return address: The address of the contract created
    function proxyCreateSilicaV2_1(
        address _rewardTokenAddress,
        address _paymentTokenAddress,
        uint256 _resourceAmount,
        uint256 _lastDueDay,
        uint256 _unitPrice,
        address _sellerAddress
    ) external returns (address);

    /// @notice creates a GasSwapSilicaV2_1 contract
    /// @param _rewardTokenAddress address of the token of the rewards beeing sold by the seller
    /// @param _paymentTokenAddress address of the token that can be used to buy silica from this contract
    /// @param _resourceAmount hashrate the seller is selling
    /// @param _lastDueDay the last day of rewards the seller is selling
    /// @param _unitPrice the price of gH/day
    /// @return The address of the contract created
    function createGasSwapSilicaV2_1(
        address _rewardTokenAddress,
        address _paymentTokenAddress,
        uint256 _resourceAmount,
        uint256 _lastDueDay,
        uint256 _unitPrice
    ) external returns (address);

    /// @notice creates a GasSwapSilicaV2_1 contract from SwapProxy
    /// @param _rewardTokenAddress address of the token of the rewards beeing sold by the seller
    /// @param _paymentTokenAddress address of the token that can be used to buy silica from this contract
    /// @param _resourceAmount hashrate the seller is selling
    /// @param _lastDueDay the last day of rewards the seller is selling
    /// @param _unitPrice the price of gH/day
    /// @param _sellerAddress the seller address
    /// @return address: The address of the contract created
    function proxyCreateGasSwapSilicaV2_1(
        address _rewardTokenAddress,
        address _paymentTokenAddress,
        uint256 _resourceAmount,
        uint256 _lastDueDay,
        uint256 _unitPrice,
        address _sellerAddress
    ) external returns (address);

    /// @notice Creates a AvaxSwapSilicaV2_1 contract
    /// @param _rewardTokenAddress The address of the token of the rewards beeing sold by the seller
    /// @param _paymentTokenAddress address of the token that can be used to buy silica from this contract
    /// @param _resourceAmount Amount of token staked generating the rewards beeing sold by the seller with this contract
    /// @param _lastDueDay the last day of rewards the seller is selling
    /// @param _unitPrice the price of stakedToken/day
    /// @return address: The address of the contract created
    function createAvaxSwapSilicaV2_1(
        address _rewardTokenAddress,
        address _paymentTokenAddress,
        uint256 _resourceAmount,
        uint256 _lastDueDay,
        uint256 _unitPrice
    ) external returns (address);

    /// @notice Creates a AvaxSwapSilicaV2_1 contract from SwapProxy
    /// @param _rewardTokenAddress The address of the token of the rewards beeing sold by the seller
    /// @param _paymentTokenAddress address of the token that can be used to buy silica from this contract
    /// @param _resourceAmount Amount of token staked generating the rewards beeing sold by the seller with this contract
    /// @param _lastDueDay the last day of rewards the seller is selling
    /// @param _unitPrice the price of stakedToken/day
    /// @param _sellerAddress the seller address
    /// @return address: The address of the contract created
    function proxyCreateAvaxSwapSilicaV2_1(
        address _rewardTokenAddress,
        address _paymentTokenAddress,
        uint256 _resourceAmount,
        uint256 _lastDueDay,
        uint256 _unitPrice,
        address _sellerAddress
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../silica/ISilicaV2_1.sol";

/**
 * @title Events emitted by the contract
 * @author Alkimiya team
 * @notice Contains all events emitted by a Silica contract
 */
interface ISilicaFactoryEvents {
    /// @notice The event emited when a new Silica contract is created.
    event NewSilicaContract(address newContractAddress, ISilicaV2_1.InitializeData initializeData);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/// @title interface design for HashVault
interface ISilicaVault {
    /*////////////////////////////////////////////////////////
                      Deposit/Withdrawal 
    ////////////////////////////////////////////////////////*/
    /// @notice Mints Vault shares to msg.sender by depositing exactly amount in payment
    function deposit(uint256 amount) external;

    /// @notice Schedules a withdrawal of Vault shares that will be processed once the round completes
    function scheduleWithdraw(uint256 shares) external returns (uint256);

    /// @notice Processes a scheduled withdrawal from a previous round. Uses finalized pps for the round
    function processScheduledWithdraw() external returns (uint256 rewardPayout, uint256 paymentPayout);

    /// @notice Buyer redeems their share of rewards
    function redeem(uint256 numShares) external;

    /*////////////////////////////////////////////////////////
                      Admin
    ////////////////////////////////////////////////////////*/
    /// @notice Initialize a new Silica Vault
    function initialize() external;

    /// @notice Function that Vault admin calls to process all withdraw requests of current epoch
    function processWithdraws() external returns (uint256 paymentLockup, uint256 rewardLockup);

    /// @notice Function that Vault admin calls to swap the maximum amount of the rewards to stable
    function maxSwap() external;

    /// @notice Function that Vault admin calls to swap amount of rewards to stable
    /// @param amount the amount of rewards to swap
    function swap(uint256 amount) external;

    /// @notice Function that Vault admin calls to proccess deposit requests at the beginning of the epoch
    function processDeposits() external returns (uint256 mintedShares);

    /// @notice Function that Vault admin calls to start a new epoch
    function startNextRound() external;

    /// @notice Function that Vault admin calls to settle defaulted Silica contracts
    function settleDefaultedSilica(address silicaAddress) external returns (uint256 rewardPayout, uint256 paymentPayout);

    /// @notice Function that Vault admin calls to settle finished Silica contracts
    function settleFinishedSilica(address silicaAddress) external returns (uint256 rewardPayout);

    /// @notice Function that Vault admin calls to purchase Silica contracts
    function purchaseSilica(address silicaAddress, uint256 amount) external returns (uint256 silicaMinted);

    // /*////////////////////////////////////////////////////////
    //                   Properties
    // ////////////////////////////////////////////////////////*/

    // Admin

    /// @notice The address of the admin
    function getAdmin() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library OrderLib {
    // solhint-disable-next-line var-name-mixedcase
    bytes32 public constant ORDER_TYPEHASH =
        keccak256(
            "Order(uint8 orderType,uint8 silicaType,uint32 endDay,uint32 orderExpirationTimestamp,uint32 salt,address buyerAddress,address sellerAddress,address rewardToken,address paymentToken,uint256 amount,uint256 feeAmount,uint256 unitPrice)"
        );

    enum OrderType {
        SellerOrder,
        BuyerOrder
    }

    enum SilicaType {
        MINING_SWAP_COMMODITY_TYPE,
        GAS_SWAP_COMMODITY_TYPE,
        AVAX_SWAP_COMMODITY_TYPE
    }

    struct Order {
        uint8 orderType;
        uint8 silicaType;
        uint32 endDay;
        uint32 orderExpirationTimestamp;
        uint32 salt;
        address buyerAddress;
        address sellerAddress;
        address rewardToken;
        address paymentToken;
        uint256 amount;
        uint256 feeAmount;
        uint256 unitPrice;
    }

    struct OrderFilledData {
        address silicaContract;
        bytes32 buyerOrderHash;
        bytes32 sellerOrderHash;
        address buyerAddress;
        address sellerAddress;
        uint256 unitPrice;
        uint256 endDay;
        uint256 totalPaymentAmount;
        uint256 reservedPrice;
    }

    function getOrderHash(OrderLib.Order calldata order) internal pure returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                OrderLib.ORDER_TYPEHASH,
                order.orderType,
                order.silicaType,
                order.endDay,
                order.orderExpirationTimestamp,
                order.salt,
                order.buyerAddress,
                order.sellerAddress,
                order.rewardToken,
                order.paymentToken,
                order.amount,
                order.feeAmount,
                order.unitPrice
            )
        );
        return structHash;
    }

    function getTypedDataHash(OrderLib.Order calldata _order, bytes32 DOMAIN_SEPARATOR) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, getOrderHash(_order)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library SilicaV2_1Types {
    enum Status {
        Open,
        Running,
        Expired,
        Defaulted,
        Finished
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}
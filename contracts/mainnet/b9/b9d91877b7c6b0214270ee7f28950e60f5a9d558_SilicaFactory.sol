// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/proxy/Clones.sol";

import "./interfaces/silicaFactory/ISilicaFactory.sol";
import "./interfaces/silica/ISilicaV2_1.sol";
import "./interfaces/oracle/IOracle.sol";
import "./interfaces/oracle/oracleEthStaking/IOracleEthStaking.sol";
import "./interfaces/oracle/IOracleRegistry.sol";
import "./interfaces/swapProxy/ISwapProxy.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @notice Factory contract for Silica Account
 * @author Alkimiya Team
 */
contract SilicaFactory is ISilicaFactory {
    error InvalidType();

    uint16 internal constant MINING_SWAP_COMMODITY_TYPE = 0;
    uint16 internal constant ETH_STAKING_COMMODITY_TYPE = 2;

    address public immutable silicaMasterV2;
    address public immutable silicaEthStakingMaster;

    IOracleRegistry immutable oracleRegistry;
    ISwapProxy immutable swapProxy;

    error Unauthorized();

    struct OracleData {
        uint256 networkHashrate;
        uint256 networkReward;
        uint256 lastIndexedDay;
    }

    struct OracleEthStakingData {
        uint256 baseRewardPerIncrementPerDay;
        uint256 lastIndexedDay;
    }

    modifier onlySwapProxy() {
        if (address(swapProxy) != msg.sender) {
            revert Unauthorized();
        }
        _;
    }

    constructor(
        address _silicaMasterV2,
        address _silicaEthStakingMaster,
        address _oracleRegistry,
        address _swapProxy
    ) {
        require(_silicaMasterV2 != address(0), "SilicaV2 master address cannot be zero");
        silicaMasterV2 = _silicaMasterV2;

        require(_silicaEthStakingMaster != address(0), "SilicaEthStakingV2_1 master address cannot be zero");
        silicaEthStakingMaster = _silicaEthStakingMaster;

        require(_oracleRegistry != address(0), "OracleRegistry address cannot be zero");
        oracleRegistry = IOracleRegistry(_oracleRegistry);

        require(_swapProxy != address(0), "SwapProxy address cannot be zero");
        swapProxy = ISwapProxy(_swapProxy);
    }

    /*///////////////////////////////////////////////////////////////
                            Index Data
    //////////////////////////////////////////////////////////////*/

    /// @notice Function to return the Collateral requirement for issuance for a new Mining Swap Silica
    function getMiningSwapCollateralRequirement(
        uint256 lastDueDay,
        uint256 hashrate,
        OracleData memory oracleData
    ) internal pure returns (uint256) {
        uint256 numDeposits = getNumDeposits(oracleData.lastIndexedDay, lastDueDay);
        return (hashrate * oracleData.networkReward * numDeposits) / (oracleData.networkHashrate * 10);
    }

    /// @notice Function to return the Collateral requirement for issuance for a new Staking Swap Silica
    function getEthStakingCollateralRequirement(
        uint256 lastDueDay,
        uint256 stakedAmount,
        OracleEthStakingData memory oracleData,
        uint8 decimals
    ) internal pure returns (uint256) {
        uint256 numDeposits = getNumDeposits(oracleData.lastIndexedDay, lastDueDay);
        return (oracleData.baseRewardPerIncrementPerDay * stakedAmount * numDeposits) / (10**(decimals + 1));
    }

    /// @notice Function to return lastest Mining Oracle data
    function getOracleData(address rewardTokenAddress) internal view returns (OracleData memory) {
        OracleData memory oracleData;
        IOracle oracle = IOracle(IOracleRegistry(oracleRegistry).getOracleAddress(address(rewardTokenAddress), MINING_SWAP_COMMODITY_TYPE));
        uint256 lastIndexedDay = oracle.getLastIndexedDay();
        (, , uint256 networkHashrate, uint256 networkReward, , , ) = oracle.get(lastIndexedDay);
        oracleData.networkHashrate = networkHashrate;
        oracleData.networkReward = networkReward;
        oracleData.lastIndexedDay = lastIndexedDay;
        return oracleData;
    }

    /// @notice Function to return lastest Satking Oracle data
    function getOracleEthStakingData(address rewardTokenAddress) internal view returns (OracleEthStakingData memory) {
        OracleEthStakingData memory oracleData;
        IOracleEthStaking oracleEthStaking = IOracleEthStaking(
            IOracleRegistry(oracleRegistry).getOracleAddress(address(rewardTokenAddress), ETH_STAKING_COMMODITY_TYPE)
        );
        uint256 lastIndexedDay = oracleEthStaking.getLastIndexedDay();
        (, uint256 baseRewardPerIncrementPerDay, , , , , ) = oracleEthStaking.get(lastIndexedDay);

        oracleData.baseRewardPerIncrementPerDay = baseRewardPerIncrementPerDay;
        oracleData.lastIndexedDay = lastIndexedDay;
        return oracleData;
    }

    /// @notice Function to return the number of deposits the contracts requires
    /// @dev lastDueDay is always greater than lastIndexedDay
    function getNumDeposits(uint256 lastIndexedDay, uint256 lastDueDay) internal pure returns (uint256) {
        return lastDueDay - lastIndexedDay - 1;
    }

    /*///////////////////////////////////////////////////////////////
                                 Create Silica
    //////////////////////////////////////////////////////////////*/

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
    ) external override returns (address) {
        address newContractAddress = _createSilicaV2_1(
            _rewardTokenAddress,
            _paymentTokenAddress,
            _resourceAmount,
            _lastDueDay,
            _unitPrice,
            msg.sender
        );
        return newContractAddress;
    }

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
    ) external override onlySwapProxy returns (address) {
        address newContractAddress = _createSilicaV2_1(
            _rewardTokenAddress,
            _paymentTokenAddress,
            _resourceAmount,
            _lastDueDay,
            _unitPrice,
            _sellerAddress
        );
        return newContractAddress;
    }

    /// @notice Internal function to create a Silica V2.1
    function _createSilicaV2_1(
        address _rewardTokenAddress,
        address _paymentTokenAddress,
        uint256 _resourceAmount,
        uint256 _lastDueDay,
        uint256 _unitPrice,
        address _sellerAddress
    ) internal returns (address) {
        address newContractAddress = payable(Clones.clone(silicaMasterV2));

        ISilicaV2_1 newSilicaV2 = ISilicaV2_1(newContractAddress);

        OracleData memory oracleData = getOracleData(_rewardTokenAddress);
        uint256 collateralAmount = getMiningSwapCollateralRequirement(_lastDueDay, _resourceAmount, oracleData);

        ISilicaV2_1.InitializeData memory initializeData;

        initializeData.rewardTokenAddress = _rewardTokenAddress;
        initializeData.paymentTokenAddress = _paymentTokenAddress;
        initializeData.oracleRegistry = address(oracleRegistry);
        initializeData.sellerAddress = _sellerAddress;
        initializeData.dayOfDeployment = oracleData.lastIndexedDay;
        initializeData.lastDueDay = _lastDueDay;
        initializeData.unitPrice = _unitPrice;
        initializeData.resourceAmount = _resourceAmount;
        initializeData.collateralAmount = collateralAmount;
        newSilicaV2.initialize(initializeData);
        SafeERC20.safeTransferFrom(IERC20(_rewardTokenAddress), _sellerAddress, newContractAddress, collateralAmount);

        emit NewSilicaContract(newContractAddress, initializeData, MINING_SWAP_COMMODITY_TYPE);

        return newContractAddress;
    }

    /// @notice Creates a EthStakingSilicaV2_1 contract
    /// @param _rewardTokenAddress The address of the token of the rewards beeing sold by the seller
    /// @param _paymentTokenAddress address of the token that can be used to buy silica from this contract
    /// @param _resourceAmount Amount of token staked generating the rewards beeing sold by the seller with this contract
    /// @param _lastDueDay the last day of rewards the seller is selling
    /// @param _unitPrice the price of stakedToken/day
    /// @return address: The address of the contract created
    function createEthStakingSilicaV2_1(
        address _rewardTokenAddress,
        address _paymentTokenAddress,
        uint256 _resourceAmount,
        uint256 _lastDueDay,
        uint256 _unitPrice
    ) external override returns (address) {
        address newContractAddress = _createEthStakingSilicaV2_1(
            _rewardTokenAddress,
            _paymentTokenAddress,
            _resourceAmount,
            _lastDueDay,
            _unitPrice,
            msg.sender
        );
        return newContractAddress;
    }

    /// @notice Creates a EthStakingSilicaV2_1 contract from SwapProxy
    /// @param _rewardTokenAddress The address of the token of the rewards beeing sold by the seller
    /// @param _paymentTokenAddress address of the token that can be used to buy silica from this contract
    /// @param _resourceAmount Amount of token staked generating the rewards beeing sold by the seller with this contract
    /// @param _lastDueDay the last day of rewards the seller is selling
    /// @param _unitPrice the price of stakedToken/day
    /// @param _sellerAddress the seller address
    /// @return address: The address of the contract created
    function proxyCreateEthStakingSilicaV2_1(
        address _rewardTokenAddress,
        address _paymentTokenAddress,
        uint256 _resourceAmount,
        uint256 _lastDueDay,
        uint256 _unitPrice,
        address _sellerAddress
    ) external override onlySwapProxy returns (address) {
        address newContractAddress = _createEthStakingSilicaV2_1(
            _rewardTokenAddress,
            _paymentTokenAddress,
            _resourceAmount,
            _lastDueDay,
            _unitPrice,
            _sellerAddress
        );
        return newContractAddress;
    }

    /// @notice Internal function to create a Eth Staking Silica V2.1
    function _createEthStakingSilicaV2_1(
        address _rewardTokenAddress,
        address _paymentTokenAddress,
        uint256 _resourceAmount,
        uint256 _lastDueDay,
        uint256 _unitPrice,
        address _sellerAddress
    ) internal returns (address) {
        address newContractAddress = payable(Clones.clone(silicaEthStakingMaster));
        ISilicaV2_1 newSilicaV2 = ISilicaV2_1(newContractAddress);
        OracleEthStakingData memory oracleData = getOracleEthStakingData(_rewardTokenAddress);
        uint256 collateralAmount = getEthStakingCollateralRequirement(_lastDueDay, _resourceAmount, oracleData, newSilicaV2.getDecimals());

        ISilicaV2_1.InitializeData memory initializeData;

        initializeData.rewardTokenAddress = _rewardTokenAddress;
        initializeData.paymentTokenAddress = _paymentTokenAddress;
        initializeData.oracleRegistry = address(oracleRegistry);
        initializeData.sellerAddress = _sellerAddress;
        initializeData.dayOfDeployment = oracleData.lastIndexedDay;
        initializeData.lastDueDay = _lastDueDay;
        initializeData.unitPrice = _unitPrice;
        initializeData.resourceAmount = _resourceAmount;
        initializeData.collateralAmount = collateralAmount;
        newSilicaV2.initialize(initializeData);
        SafeERC20.safeTransferFrom(IERC20(_rewardTokenAddress), _sellerAddress, newContractAddress, collateralAmount);

        emit NewSilicaContract(newContractAddress, initializeData, ETH_STAKING_COMMODITY_TYPE);

        return newContractAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 * @title Alkimiya Oracle
 * @author Alkimiya Team
 * @notice Main interface for Oracle contracts
 */
interface IOracle {
    event OracleUpdate(
        address indexed caller,
        uint256 indexed referenceDay,
        uint256 indexed referenceBlock,
        uint256 hashrate,
        uint256 reward,
        uint256 fees,
        uint256 difficulty,
        uint256 timestamp
    );

    /**
     * @notice Return the Network data on a given day
     */
    function get(uint256 _day)
        external
        view
        returns (
            uint256 date,
            uint256 referenceBlock,
            uint256 hashrate,
            uint256 reward,
            uint256 fees,
            uint256 difficulty,
            uint256 timestamp
        );

    function getInRange(uint256 _firstDay, uint256 _lastDay)
        external
        view
        returns (uint256[] memory hashrateArray, uint256[] memory rewardArray);

    /**
     * @notice Return the Network data on a given day is updated to Oracle
     */
    function isDayIndexed(uint256 _referenceDay) external view returns (bool);

    /**
     * @notice Return the last day on which the Oracle is updated
     */
    function getLastIndexedDay() external view returns (uint32);

    /**
     * @notice Update the Alkimiya Index on Oracle for a given day
     */
    function updateIndex(
        uint256 _referenceDay,
        uint256 _referenceBlock,
        uint256 _hashrate,
        uint256 _reward,
        uint256 _fees,
        uint256 _difficulty,
        bytes memory signature
    ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 * @title Alkimiya Oracle Addresses
 * @author Alkimiya Team
 * */
interface IOracleRegistry {
    event OracleRegistered(address token, uint256 oracleType, address oracleAddr);

    function getOracleAddress(address _token, uint256 _oracleType) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IOracleEthStakingEvents.sol";

/**
 * @title Alkimiya OraclePoS
 * @author Alkimiya Team
 * @notice This is the interface for Proof of Stake Oracle contract
 * */
interface IOracleEthStaking is IOracleEthStakingEvents {
    /**
     * @notice Update the Alkimiya Index for PoS instruments on Oracle for a given day
     */
    function updateIndex(
        uint256 _referenceDay,
        uint256 _baseRewardPerIncrementPerDay,
        uint256 _burnFee,
        uint256 _priorityFee,
        uint256 _burnFeeNormalized,
        uint256 _priorityFeeNormalized,
        bytes memory signature
    ) external returns (bool success);

    /// @notice Function to return Oracle index on given day
    function get(uint256 _referenceDay)
        external
        view
        returns (
            uint256 referenceDay,
            uint256 baseRewardPerIncrementPerDay,
            uint256 burnFee,
            uint256 priorityFee,
            uint256 burnFeeNormalized,
            uint256 priorityFeeNormalized,
            uint256 timestamp
        );

    /// @notice Function to return array of oracle data between firstday and lastday (inclusive)
    function getInRange(uint256 _firstDay, uint256 _lastDay) external view returns (uint256[] memory baseRewardPerIncrementPerDayArray);

    /**
     * @notice Return if the network data on a given day is updated to Oracle
     */
    function isDayIndexed(uint256 _referenceDay) external view returns (bool);

    /**
     * @notice Return the last day on which the Oracle is updated
     */
    function getLastIndexedDay() external view returns (uint32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 * @title Alkimiya OraclePoS
 * @author Alkimiya Team
 * @notice This is the interface for Proof of Stake Oracle contract
 * */
interface IOracleEthStakingEvents {
    /**
     * @notice Oracle Uptade Event
     */
    event OracleUpdate(
        address indexed caller,
        uint256 indexed referenceDay,
        uint256 timestamp,
        uint256 baseRewardPerIncrementPerDay,
        uint256 burnFee,
        uint256 priorityFee,
        uint256 burnFeeNormalized,
        uint256 priorityFeeNormalized
    );
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
    /*///////////////////////////////////////////////////////////////
                                 Events
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed buyer, uint256 purchaseAmount, uint256 mintedTokens);
    event BuyerCollectPayout(uint256 rewardTokenPayout, uint256 paymentTokenPayout, address buyerAddress, uint256 burntAmount);
    event SellerCollectPayout(uint256 paymentTokenPayout, uint256 rewardTokenExcess);
    event StatusChanged(SilicaV2_1Types.Status status);

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

    /// @notice Returns the last day of reward the seller is selling with this contract
    /// @return The last day of reward the seller is selling with this contract
    function getLastDueDay() external view returns (uint32);

    /// @notice Returns the commodity type the seller is selling with this contract
    /// @return The commodity type the seller is selling with this contract
    function getCommodityType() external pure returns (uint8);

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

    /// @notice Returns decimals of the contract
    function getDecimals() external pure returns (uint8);
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

    /// @notice Creates a EthStaking contract
    /// @param _rewardTokenAddress The address of the token of the rewards beeing sold by the seller
    /// @param _paymentTokenAddress address of the token that can be used to buy silica from this contract
    /// @param _resourceAmount Amount of token staked generating the rewards beeing sold by the seller with this contract
    /// @param _lastDueDay the last day of rewards the seller is selling
    /// @param _unitPrice the price of stakedToken/day
    /// @return address: The address of the contract created
    function createEthStakingSilicaV2_1(
        address _rewardTokenAddress,
        address _paymentTokenAddress,
        uint256 _resourceAmount,
        uint256 _lastDueDay,
        uint256 _unitPrice
    ) external returns (address);

    /// @notice Creates a EthStaking contract from SwapProxy
    /// @param _rewardTokenAddress The address of the token of the rewards beeing sold by the seller
    /// @param _paymentTokenAddress address of the token that can be used to buy silica from this contract
    /// @param _resourceAmount Amount of token staked generating the rewards beeing sold by the seller with this contract
    /// @param _lastDueDay the last day of rewards the seller is selling
    /// @param _unitPrice the price of stakedToken/day
    /// @param _sellerAddress the seller address
    /// @return address: The address of the contract created
    function proxyCreateEthStakingSilicaV2_1(
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
    event NewSilicaContract(address newContractAddress, ISilicaV2_1.InitializeData initializeData, uint16 commodityType);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../../libraries/OrderLib.sol";

/**
 * @title Alkimiya Swap Proxy
 * @author Alkimiya Team
 * @notice This is the interface for Swap Proxy contract
 * */
interface ISwapProxy {
    event OrderExecuted(OrderLib.OrderFilledData orderData);

    event OrderCancelled(address buyerAddress, address sellerAddress, bytes32 orderHash);

    function domainSeparator() external view returns (bytes32);

    function setSilicaFactory(address _silicaFactoryAddress) external;

    function executeOrder(
        OrderLib.Order calldata buyerOrder,
        OrderLib.Order calldata sellerOrder,
        bytes memory buyerSignature,
        bytes memory sellerSignature
    ) external returns (address);

    /// @notice Function to cancle a listed order
    function cancelOrder(OrderLib.Order calldata order, bytes memory signature) external;

    /// @notice Function to return how much a order has been fulfilled
    function getOrderFill(bytes32 orderHash) external view returns (uint256 fillAmount);

    /// @notice Function to check if an order is canceled
    function isOrderCancelled(bytes32 orderHash) external view returns (bool);

    /// @notice Function to return the Silica Address created from an order
    function getSilicaAddress(bytes32 orderHash) external view returns (address);

    /// @notice Function to check if a seller order matches a buyer order
    function checkIfOrderMatches(OrderLib.Order calldata buyerOrder, OrderLib.Order calldata sellerOrder) external pure;
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
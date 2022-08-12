// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
import "../interfaces/IModusRegistry.sol";
import "../utils/Utility.sol";

contract ModusPriceFeed is Utility {
    int256 public modusPrice;
    uint8 decimal;

    // IModusRegistry modusRegistry;

    constructor(IModusRegistry _modusRegistry) Utility(_modusRegistry) {
        modusRegistry = _modusRegistry;
    }

    function setTokenPrice(int256 price) public onlyModusAdmin {
        modusPrice = price;
    }

    function setDecimals(uint8 _decimal) public onlyModusAdmin {
        decimal = _decimal;
    }

    function latestRoundData()
        external
        view
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        )
    {
        return (uint80(0), modusPrice, uint256(0), uint256(0), uint80(0));
    }

    /**
     * @notice represents the number of decimals the aggregator responses represent.
     */
    function decimals()
        external
        view
        returns (
            // override
            uint8
        )
    {
        return decimal;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "../interfaces/IModusRegistry.sol";

contract Utility is Context {
    IModusRegistry modusRegistry;

    constructor(IModusRegistry _modusRegistry) {
        modusRegistry = _modusRegistry;
    }

    /// @notice Modifier to check whether the message.sender is Modus Admin
    modifier onlyModusAdmin() {
        require(
            _msgSender() == modusRegistry.modusAdmin(),
            "Utility: Not ModusAdmin"
        );
        _;
    }

    /// @notice Modifier to check whether the message.sender is Modus Factory
    modifier onlyModusFactory() {
        require(
            _msgSender() == modusRegistry.modusFactory(),
            "Utility: Not ModusFactory"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IModusRegistry {
    struct Scheme {
        uint256 schemeId;
        uint256 maxDays;
        uint256 exponentBase;
        uint256 percentageRewardTokens;
    }
    struct ModusProject {
        uint256 projectId;
        uint256 projectStage;
        address custodianWallet;
        uint256 feePercentage;
        uint256 schemeId;
        address _stableCoinPXTSwap;
        address _pxt;
        address _pxrt;
        address _pxtStaking;
        address _pxtModusSwap;
        address _pxrtModusSwap;
        address _pxtStableCoinSwap;
        address _pxrtStableCoinSwap;
    }

    function modus() external returns (address);

    function modusAdmin() external returns (address);

    function kycAdmin() external returns (address);

    function proxyAdmin() external returns (address);

    function lostWalletAdmin() external returns (address);

    function setLostWalletAdmin(address) external;

    function modusFactory() external returns (address);

    function modusStaking() external returns (address);

    function priceModule() external returns (address);

    function kycModule() external returns (address);

    function modusTreasuryWallet() external returns (address);

    function projectStableCoin(uint256) external returns (address);

    function addStableCoin(address) external;

    function removeStableCoin(address) external;

    function isStableCoinSupported(address) external returns (bool);

    function isAccountBlackListed(address) external returns (bool);

    function blackListAccount(uint256, address) external;

    function whiteListAccount(address account) external;

    function blackListAccountByAdmin(address) external;

    function setStableCoin(uint256, address) external;

    function pxt() external returns (address);

    function stableCoinPXTSwap() external returns (address);

    function pxtStaking() external returns (address);

    function pxrt() external returns (address);

    function pxtModusSwap() external returns (address);

    function pxtStableCoinSwap() external returns (address);

    function pxrtModusSwap() external returns (address);

    function pxrtStableCoinSwap() external returns (address);

    function setKYCAdmin(address) external;

    function setBaseContracts(
        address,
        address,
        address,
        address,
        address
    ) external;

    function addModus(address) external;

    function addModusFactory(address) external;

    function addModusStaking(address) external;

    function addPriceModule(address) external;

    function addKycModule(address) external;

    function setImplementationContracts(
        address,
        address,
        address,
        address,
        address,
        address,
        address,
        address
    ) external;

    function setScheme(uint256, uint256) external returns (uint256);

    function setProjectDetails(
        uint256,
        uint256,
        bytes memory
    ) external returns (uint256);

    function setProjectDetails(
        uint256,
        uint256,
        bytes memory,
        bytes memory
    ) external returns (uint256);

    function getSchemeDetails(uint256)
        external
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getRewardPercentage(uint256, uint256) external returns (uint256);

    function getSchemesList() external returns (Scheme[] memory);

    function getProjectDetails(uint256) external returns (ModusProject memory);

    function getProjectList() external returns (ModusProject[] memory);

    function transferAdminOwnership(address) external;
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
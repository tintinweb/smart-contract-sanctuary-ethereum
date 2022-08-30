// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "../interfaces/IModusRegistry.sol";
import "../utils/Utility.sol";

contract KYC is Utility {
    mapping(address => bool) kycStatus;

    constructor(IModusRegistry _modusRegistry) Utility(_modusRegistry) {
        modusRegistry = _modusRegistry;
    }

    ///@notice sets the KYC status of an investor
    ///@param investors, status, arrays containing address and kyc details
    ///only accesible by Modus Admin
    function setKYCStatus(address[] memory investors, bool[] memory status)
        public
    {
        require(
            _msgSender() == (modusRegistry.modusAdmin()) ||
                _msgSender() == (modusRegistry.kycAdmin()),
            "KYC: Access Denied"
        );
        for (uint256 i = 0; i < investors.length; i++) {
            address investor = investors[i];
            kycStatus[investor] = status[i];
        }
    }

    ///@notice retrieves the KYC Status of an investor
    ///@param investor, address of the Investor
    ///Returns the KYC STatus of the investor
    function getKYCStatus(address investor) public view returns (bool) {
        return kycStatus[investor];
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

    function setModus(address) external;

    function setModusFactory(address) external;

    function setModusStaking(address) external;

    function setPriceModule(address) external;

    function setKycModule(address) external;

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

    ///@notice sets the address of the Modus Registry
    ///@param _modusRegistry, address of the Modus Registry
    ///only accesible by modus admin
    function setModusRegistry(IModusRegistry _modusRegistry)
        external
        onlyModusAdmin
    {
        require(address(_modusRegistry) != address(0), "Utility: zero address");
        modusRegistry = _modusRegistry;
    }
}
// SPDX-License-Identifier: ISC
pragma solidity ^0.8.15;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ======================= FraxlendWhitelist ==========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author
// Drake Evans: https://github.com/DrakeEvans

// Reviewers
// Dennis Ettes: https://github.com/denett
// Sam Kazemian: https://github.com/samkazemian
// Travis Moore: https://github.com/FortisFortuna
// Jack Corddry: https://github.com/corddry
// Rich Gee: https://github.com/zer0blockchain

// ====================================================================

import "./interfaces/IFraxlendWhitelist.sol";

// debugging only
// import "lib/ds-test/src/test.sol";

contract FraxlendWhitelist is IFraxlendWhitelist {
    // Constants
    address public constant TIME_LOCK_ADDRESS = 0x8412ebf45bAC1B340BbE8F318b928C466c4E39CA;
    address public constant COMPTROLLER_ADDRESS = 0x8D8Cb63BcB8AD89Aa750B9f80Aa8Fa4CfBcC8E0C;

    // Oracle Whitelist Storage
    mapping(address => bool) public oracleContractWhitelist;

    // Interest Rate Calculator Whitelist Storage
    mapping(address => bool) public rateContractWhitelist;

    // Fraxlend Deployer Whitelist Storage
    mapping(address => bool) public fraxlendDeployerWhitelist;

    modifier onlyByAdmin() {
        require(
            msg.sender == TIME_LOCK_ADDRESS || msg.sender == COMPTROLLER_ADDRESS,
            "FraxlendPair: Authorized addresses only"
        );
        _;
    }

    // Oracle Whitelist setter
    function setOracleContractWhitelist(address[] calldata _addresses, bool _bool) external onlyByAdmin {
        for (uint256 i = 0; i < _addresses.length; i++) {
            oracleContractWhitelist[_addresses[i]] = _bool;
        }
    }

    // Interest Rate Calculator Whitelist setter
    function setRateContractWhitelist(address[] calldata _addresses, bool _bool) external onlyByAdmin {
        for (uint256 i = 0; i < _addresses.length; i++) {
            rateContractWhitelist[_addresses[i]] = _bool;
        }
    }

    // FraxlendDeployer Whitelist setter
    function setFraxlendDeployerWhitelist(address[] calldata _addresses, bool _bool) external onlyByAdmin {
        for (uint256 i = 0; i < _addresses.length; i++) {
            fraxlendDeployerWhitelist[_addresses[i]] = _bool;
        }
    }
}

// SPDX-License-Identifier: ISC
pragma solidity >=0.8.15;

interface IFraxlendWhitelist {
    function TIME_LOCK_ADDRESS() external view returns (address);

    function COMPTROLLER_ADDRESS() external view returns (address);

    function oracleContractWhitelist(address) external view returns (bool);

    function rateContractWhitelist(address) external view returns (bool);

    function fraxlendDeployerWhitelist(address) external view returns (bool);

    function setOracleContractWhitelist(address[] calldata _address, bool _bool) external;

    function setRateContractWhitelist(address[] calldata _address, bool _bool) external;

    function setFraxlendDeployerWhitelist(address[] calldata _address, bool _bool) external;
}
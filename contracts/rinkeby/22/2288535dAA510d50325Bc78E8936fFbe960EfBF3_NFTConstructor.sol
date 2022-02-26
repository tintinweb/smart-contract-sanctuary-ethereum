// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "../interfaces/IVault.sol";
import "../interfaces/IVaultFactory.sol";
import "../interfaces/IVaultManager.sol";
import "../interfaces/IERC20Minimal.sol";
import "./libraries/NFTSVG.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IERC20Metadata {
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
}

contract NFTConstructor {
  using Strings for uint256;

  address factory;
  address manager;
  string chainName;

  constructor(
    address factory_,
    address manager_,
    string memory chainName_
  ) {
    factory = factory_;
    manager = manager_;
    chainName = chainName_;
  }

  function generateParams(uint256 tokenId_)
    external
    view
    returns (
      NFTSVG.ChainParams memory cParam,
      NFTSVG.BlParams memory blParam,
      NFTSVG.HealthParams memory hParam,
      NFTSVG.CltParams memory cltParam
    )
  {
    address vault = IVaultFactory(factory).getVault(tokenId_);
    uint256 lastUpdated = IVault(vault).lastUpdated();
    address debt = IVault(vault).debt();
    address collateral = IVault(vault).collateral();
    uint256 cDecimal = IVaultManager(manager).getCDecimal(collateral);
    uint256 cBalance = IERC20Minimal(collateral).balanceOf(vault);
    uint256 dBalance = IVault(vault).borrow();
    string memory symbol = IERC20Metadata(collateral).symbol();
    string memory name = IERC20Metadata(collateral).symbol();
    uint256 HP = _getHP(collateral, cDecimal, debt, cBalance, dBalance);
    return (
      _generateChainParams(collateral, debt),
      _generateBlParams(vault, lastUpdated, cDecimal, cBalance, dBalance, symbol, name),
      _generateHealthParams(HP),
      _generateCltParams(collateral)
    );
  }

  function _generateChainParams(address collateral, address debt)
    internal
    view
    returns (NFTSVG.ChainParams memory cParam)
  {
    cParam = NFTSVG.ChainParams({
      chainId: block.chainid.toString(),
      chainName: chainName,
      collateral: addressToString(collateral),
      debt: addressToString(debt)
    });
  }

  function addressToString(address addr) internal pure returns (string memory) {
    return (uint256(uint160(addr))).toHexString(20);
  }

  function _generateBlParams(
    address vault,
    uint256 lastUpdated,
    uint256 cDecimal,
    uint256 cBalance,
    uint256 dBalance,
    string memory symbol,
    string memory name
  ) internal pure returns (NFTSVG.BlParams memory blParam) {
    blParam = NFTSVG.BlParams({
      vault: addressToString(vault),
      cBlStr: _generateDecimalString(cDecimal, cBalance),
      dBlStr: _generateDecimalString(18, dBalance),
      symbol: symbol,
      lastUpdated: lastUpdated.toString(),
      name: name
    });
  }

  function _generateHealthParams(uint256 HP)
    internal
    pure
    returns (NFTSVG.HealthParams memory hParam)
  {
    hParam = NFTSVG.HealthParams({
      rawHP: HP,
      HP: _formatHP(HP),
      HPBarColor1: _getHPBarColor1(HP),
      HPBarColor2: _getHPBarColor2(HP),
      HPStatus: _getHPStatus(HP),
      HPGauge: _formatGauge(HP)
    });
  }

  function _generateCltParams(address collateral)
    internal
    view
    returns (NFTSVG.CltParams memory cltParam)
  {
    cltParam = NFTSVG.CltParams({
      MCR: _formatRatio(IVaultManager(manager).getMCR(collateral)),
      LFR: _formatRatio(IVaultManager(manager).getLFR(collateral)),
      SFR: _formatRatio(IVaultManager(manager).getSFR(collateral))
    });
  }

  function _formatRatio(uint256 ratio) internal pure returns (string memory str) {
    uint256 integer = ratio / 100000;
    uint256 secondPrecision = ratio / 1000 - (integer * 100);
    if (secondPrecision > 0) {
      str = string(
        abi.encodePacked(integer.toString(), ".", secondPrecision.toString())
      );
    } else {
      str = string(abi.encodePacked(integer.toString()));
    }
  }

  function _generateDecimalString(uint256 decimals, uint256 balance)
    internal
    pure
    returns (string memory str)
  {
    uint256 integer = balance / 10**decimals;
    if (integer >= 100000000000) {
      str = "99999999999+";
    }
    uint256 secondPrecision = balance / 10**(decimals - 2) - (integer * 10**2);
    if (secondPrecision > 0) {
      str = string(
        abi.encodePacked(integer.toString(), ".", secondPrecision.toString())
      );
    } else {
      str = string(abi.encodePacked(integer.toString()));
    }
  }

  function _getHP(
    address collateral,
    uint256 cDecimal,
    address debt,
    uint256 cBalance,
    uint256 dBalance
  ) internal view returns (uint256 HP) {
    uint256 cValue = IVaultManager(manager).getAssetPrice(collateral) *
      cBalance;
    uint256 dValue = IVaultManager(manager).getAssetPrice(debt) * dBalance;
    uint256 mcr = IVaultManager(manager).getMCR(collateral);
    uint256 cdpRatioPercentPoint00000 = cValue * 10000000 * 10**(18-cDecimal) / dValue;
    HP = (cdpRatioPercentPoint00000 - mcr) / 100000;
    return HP;
  }

  function _formatHP(
    uint256 HP
  ) internal pure returns (string memory HPString) {
    if (HP > 200) {
      HPString = "200+";
    } else {
      HPString = HP.toString();
    }
  }

  function _formatGauge(
    uint256 HP
  ) internal pure returns (string memory HPGauge) {
    if (HP > 100) {
      HPGauge = '32';
    } else {
      HPGauge = (HP*32/100).toString();
    }
  }

  function _getHPBarColor1(uint256 HP)
    internal
    pure
    returns (string memory color)
  {
    if (HP <= 30) {
      color = "#F5B1A6";
    }
    if (HP <= 50) {
      color = "#E8ECCA";
    }
    if (HP < 100) {
      color = "#C9FBAD";
    }
    if (HP >= 100) {
      color = "#C4F2FE";
    }
  }

  function _getHPBarColor2(uint256 HP)
    internal
    pure
    returns (string memory color)
  {
    if (HP <= 30) {
      color = "#EC290A";
    }
    if (HP <= 50) {
      color = "#D6ED20";
    }
    if (HP < 100) {
      color = "#57E705";
    }
    if (HP >= 100) {
      color = "#6FA4FB";
    }
  }

  function _getHPStatus(uint256 HP)
    internal
    pure
    returns (string memory status)
  {
    if (HP <= 10) {
      status = unicode"💀";
    }
    if (HP <= 30) {
      status = unicode"🚑";
    }
    if (HP < 50) {
      status = unicode"💛";
    }
    if (HP <= 80) {
      status = unicode"❤️";
    }
    if (HP <= 100) {
      status = unicode"💖";
    }
    if (HP > 100) {
      status = unicode"💎";
    }
  }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface IVault {
    event DepositCollateral(uint256 vaultID, uint256 amount);
    event WithdrawCollateral(uint256 vaultID, uint256 amount);
    event Borrow(uint256 vaultID, uint256 amount);
    event BorrowMore(uint256 vaultID, uint256 cAmount, uint256 dAmount, uint256 borrow);
    event PayBack(uint256 vaultID, uint256 borrow, uint256 paybackFee, uint256 amount);
    event CloseVault(uint256 vaultID, uint256 amount, uint256 remainderC, uint256 remainderD, uint256 closingFee);
    event Liquidated(uint256 vaultID, address collateral, uint256 amount, uint256 pairSentAmount);
    /// Getters
    /// Address of a manager
    function  factory() external view returns (address);
    /// Address of a manager
    function  manager() external view returns (address);
    /// Address of debt;
    function  debt() external view returns (address);
    /// Address of vault ownership registry
    function  v1() external view returns (address);
    /// address of a collateral
    function  collateral() external view returns (address);
    /// Vault global identifier
    function vaultId() external view returns (uint);
    /// borrowed amount 
    function borrow() external view returns (uint256);
    /// created block timestamp
    function lastUpdated() external view returns (uint256);
    /// address of wrapped eth
    function  WETH() external view returns (address);
    /// Total debt amount with interest
    function outstandingPayment() external returns (uint256);
    /// V2 factory address for liquidation
    function v2Factory() external view returns (address);

    /// Functions
    function initialize(address manager_,
    uint256 vaultId_,
    address collateral_,
    address debt_,
    address v1_,
    uint256 amount_,
    address v2Factory_,
    address weth_
    ) external;
    function liquidate() external;
    function depositCollateralNative() payable external;
    function depositCollateral(uint256 amount_) external;
    function withdrawCollateralNative(uint256 amount_) external;
    function withdrawCollateral(uint256 amount_) external;
    function borrowMore(uint256 cAmount_, uint256 dAmount_) external;
    function payDebt(uint256 amount_) external;
    function closeVault(uint256 amount_) external;

}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface IVaultFactory {

    /// View funcs
    /// NFT token address
    function v1() external view returns (address);
    /// UniswapV2Factory address
    function v2Factory() external view returns (address);
    /// Address of wrapped eth
    function WETH() external view returns (address);
    /// Address of a manager
    function  manager() external view returns (address);

    /// Getters
    /// Get Config of CDP
    function vaultCodeHash() external pure returns (bytes32);
    function createVault(address collateral_, address debt_, uint256 amount_, address recipient) external returns (address vault, uint256 id);
    function getVault(uint vaultId_) external view returns (address);

    /// Event
    event VaultCreated(uint256 vaultId, address collateral, address debt, address creator, address vault, uint256 cAmount, uint256 dAmount);
    event CDPInitialized(address collateral, uint mcr, uint lfr, uint sfr, uint8 cDecimals);
    event RebaseActive(bool set);
    event SetFees(address feeTo, address treasury, address dividend);
    event Rebase(uint256 totalSupply, uint256 desiredSupply);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface IVaultManager {

    /// View funcs
    /// Last rebase
    function lastRebase() external view returns (uint256);
    /// Stablecoin address
    function stablecoin() external view returns (address);
    /// VaultFactory address
    function factory() external view returns (address);
    /// Address of feeTo
    function feeTo() external view returns (address);
    /// Address of the dividend pool
    function dividend() external view returns (address);
    /// Address of Standard treasury
    function treasury() external view returns (address);
    /// Address of liquidator
    function liquidator() external view returns (address);
    /// Desired of supply of stablecoin to be minted
    function desiredSupply() external view returns (uint256);
    /// Switch to on/off rebase
    function rebaseActive() external view returns (bool);

    /// Getters
    /// Get Config of CDP
    function getCDPConfig(address collateral) external view returns (uint, uint, uint, uint, bool);
    function getCDecimal(address collateral) external view returns(uint);
    function getMCR(address collateral) external view returns(uint);
    function getLFR(address collateral) external view returns(uint);
    function getSFR(address collateral) external view returns(uint);
    function getExpiary(address collateral) external view returns(uint256);
    function getOpen(address collateral_) external view returns (bool);
    function getAssetPrice(address asset) external view returns (uint);
    function getAssetValue(address asset, uint256 amount) external view returns (uint256);
    function isValidCDP(address collateral, address debt, uint256 cAmount, uint256 dAmount) external returns (bool);
    function isValidSupply(uint256 issueAmount_) external returns (bool);
    function createCDP(address collateral_, uint cAmount_, uint dAmount_) external returns (bool success);

    /// Event
    event VaultCreated(uint256 vaultId, address collateral, address debt, address creator, address vault, uint256 cAmount, uint256 dAmount);
    event CDPInitialized(address collateral, uint mcr, uint lfr, uint sfr, bool isOpen);
    event RebaseActive(bool set);
    event SetFees(address feeTo, address treasury, address dividend);
    event Rebase(uint256 totalSupply, uint256 desiredSupply);
    event SetDesiredSupply(uint desiredSupply);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.5.0;

interface IERC20Minimal {
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

library NFTSVG {
  struct ChainParams {
    string chainId;
    string chainName;
    string collateral;
    string debt;
  }

  struct BlParams {
    string vault;
    string cBlStr;
    string dBlStr;
    string symbol;
    string lastUpdated;
    string name;
  }

  struct CltParams {
    string MCR;
    string LFR;
    string SFR;
  }

  struct HealthParams {
    uint256 rawHP;
    string HP;
    string HPBarColor1;
    string HPBarColor2;
    string HPStatus;
    string HPGauge;
  }

  function generateSVGDefs(ChainParams memory params)
    internal
    pure
    returns (string memory svg)
  {
    svg = string(
      abi.encodePacked(
        '<svg width="400" height="250" viewBox="0 0 400 250" fill="none" xmlns="http://www.w3.org/2000/svg"',
        ' xmlns:xlink="http://www.w3.org/1999/xlink">',
        '<rect width="400" height="250" fill="url(#pattern0)" />',
        '<rect x="10" y="12" width="380" height="226" rx="20" ry="20" fill="rgba(0,0,0,0)" stroke="rgba(255,255,255,0.8)" />'
      )
    );
  }

  function generateBalances(BlParams memory params, string memory id)
    internal
    pure
    returns (string memory svg)
  {
    svg = string(
      abi.encodePacked(
        '<text y="60" x="32" fill="white"',
        ' font-family="Poppins" font-weight="400" font-size="24px">WETH Vault #',
        id,
        '</text>',
        '<text y="85px" x="32px" fill="white" font-family="Poppins" font-weight="350" font-size="14px">Collateral: ',
        params.cBlStr,
        " ",
        params.symbol,
        "</text>"
        '<text y="110px" x="32px" fill="white" font-family="Poppins" font-weight="350" font-size="14px">IOU: ',
        params.dBlStr,
        " ",
        "USM"
        "</text>"
      )
    );
  }

  function generateHealth(HealthParams memory params)
    internal
    pure
    returns (string memory svg)
  {
    svg = string(
      abi.encodePacked(
        '<text y="135px" x="32px" fill="white" font-family="Poppins" font-weight="350" font-size="14px">Health: ',
        params.HP,
        "% ",
        params.HPStatus,
        "</text>"
      )
    );
  }

  function generateBitmap() internal pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        "<g>",
        '<svg class="healthbar" xmlns="http://www.w3.org/2000/svg" viewBox="0 -0.5 38 9" shape-rendering="crispEdges"',
        ' x="-113px" y="138px" width="400px" height="30px">',
        '<path stroke="#222034"',
        ' d="M2 2h1M3 2h32M3  3h1M2 3h1M35 3h1M3 4h1M2 4h1M35 4h1M3  5h1M2 5h1M35 5h1M3 6h32M3" />',
        '<path stroke="#323c39" d="M3 3h32" />',
        '<path stroke="#494d4c" d="M3 4h32M3 5h32" />',
        "<g>"
      )
    );
  }

  function generateStop(string memory color1, string memory color2)
    internal
    pure
    returns (string memory svg)
  {
    svg = string(
      abi.encodePacked(
        '<stop offset="5.99%">',
        '<animate attributeName="stop-color" values="',
        color1,
        "; ",
        color2,
        "; ",
        color1,
        '" dur="3s" repeatCount="indefinite"></animate>',
        "</stop>"
      )
    );
  }

  function generateLinearGradient(HealthParams memory params)
    internal
    pure
    returns (string memory svg)
  {
    svg = string(
      abi.encodePacked(
        '<linearGradient id="myGradient" gradientTransform="rotate(270.47)" >',
        generateStop(params.HPBarColor1, params.HPBarColor2),
        generateStop(params.HPBarColor2, params.HPBarColor1),
        "</linearGradient>"
      )
    );
  }

  function generateHealthBar(HealthParams memory params)
    internal
    pure
    returns (string memory svg)
  {
    svg = string(
      abi.encodePacked(
        generateLinearGradient(params),
        '<svg x="3" y="2.5" width="32" height="10">',
        '<rect fill="',
        "url(",
        "'#myGradient'",
        ')"',
        ' height="3">',
        ' <animate attributeName="width" from="0" to="',
        params.HPGauge,
        '" dur="0.5s" fill="freeze" />',
        "</rect>",
        "</svg>",
        "</g>",
        "</svg>",
        "</g>"
      )
    );
  }

  function generateCltParam(
    string memory y,
    string memory width,
    string memory desc,
    string memory percent
  ) internal pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<g style="transform:translate(30px, ',
        y,
        ')">',
        '<rect width="',
        width,
        '" height="12px" rx="3px" ry="3px" fill="rgba(0,0,0,0.6)" /><text x="6px" y="9px"',
        ' font-family="Poppins" font-size="8px" fill="white">',
        '<tspan fill="rgba(255,255,255,0.6)">',
        desc,
        ": </tspan>",
        percent,
        "% </text>"
        "</g>"
      )
    );
  }

  function generateTextPath() internal pure returns (string memory svg) {
    svg = string(
      // text path has to be one liner, concatenating separate texts causes encoding error
      abi.encodePacked(
        '<path id="text-path-a" transform="translate(1,1)" d="M369.133 1.20364L28.9171 1.44856C13.4688 1.45969 0.948236 13.9804 0.937268 29.4287L0.80321 218.243C0.792219 233.723 13.3437 246.274 28.8233 246.263L369.04 246.018C384.488 246.007 397.008 233.486 397.019 218.038L397.153 29.2235C397.164 13.7439 384.613 1.1925 369.133 1.20364Z" fill="none" stroke="none" />'
      )
    );
  }

  function generateText1(string memory a, string memory path)
    internal
    pure
    returns (string memory svg)
  {
    svg = string(
      abi.encodePacked(
        '<text text-rendering="optimizeSpeed">',
        '<textPath startOffset="-100%" fill="white" font-family="Poppins" font-size="10px" xlink:href="#text-path-',
        path,
        '">',
        a,
        '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" />',
        '</textPath> <textPath startOffset="0%" fill="white" font-family="Poppins" font-size="10px" xlink:href="#text-path-',
        path,
        '">',
        a,
        '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /> </textPath>'
      )
    );
  }

  function generateText2(string memory b, string memory path)
    internal
    pure
    returns (string memory svg)
  {
    svg = string(
      abi.encodePacked(
        '<textPath startOffset="50%" fill="white" font-family="Poppins" font-size="10px" xlink:href="#text-path-',
        path,
        '">',
        b,
        '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s"',
        ' repeatCount="indefinite" /></textPath><textPath startOffset="-50%" fill="white" font-family="Poppins" font-size="10px" xlink:href="#text-path-',
        path,
        '">',
        b,
        '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /></textPath></text>'
      )
    );
  }

  function generateNetwork(ChainParams memory cParams)
    internal
    pure
    returns (string memory svg)
  {
    svg = string(
      abi.encodePacked(
        generateTokenLogos(cParams)
      )
    );
  }

  function generateNetTextPath() internal pure returns (string memory svg) {
    svg = string(
      // text path has to be one liner, concatenating separate texts causes encoding error
      abi.encodePacked(
        '<path id="text-path-b" transform="translate(269,35)" d="M1 46C1 70.8528 21.1472 91 46 91C70.8528 91 91 70.8528 91 46C91 21.1472 70.8528 1 46 1C21.1472 1 1 21.1472 1 46Z" stroke="none"/>'
      )
    );
  }

  function generateTokenLogos(ChainParams memory cParam)
    internal
    pure
    returns (string memory svg)
  {
    svg = string(
      abi.encodePacked(
        '<g style="transform:translate(265px, 180px)">'
        '<rect width="48px" height="48px" rx="10px" ry="10px" fill="none" stroke="rgba(255,255,255,0.6)" />'
        "</g>"
        '<g style="transform:translate(325px, 180px)">'
        '<rect width="48px" height="48px" rx="10px" ry="10px" fill="none" stroke="rgba(255,255,255,0.6)" />'
        "</g>"
      )
    );
  }

  function generateSVGWithoutImages(
    string memory tokenId,
    ChainParams memory cParams,
    BlParams memory blParams,
    HealthParams memory hParams,
    CltParams memory cltParams
  ) internal pure returns (string memory svg) {
    string memory a = string(
      abi.encodePacked(blParams.vault, unicode" • ", "Vault")
    );
    string memory b = string(
      abi.encodePacked(unicode" • ", cParams.chainName, unicode" • ")
    );
    string memory first = string(
      abi.encodePacked(
        generateSVGDefs(cParams),
        generateBalances(blParams, tokenId),
        generateHealth(hParams),
        generateBitmap(),
        generateHealthBar(hParams)
      )
    );
    string memory second = string(
      abi.encodePacked(
        first,
        generateCltParam(
          "180px",
          "130px",
          "Min. Collateral Ratio",
          cltParams.MCR
        ),
        generateCltParam("195px", "110px", "Liquidation Fee", cltParams.LFR),
        generateCltParam("210px", "90px", "Stability Fee", cltParams.SFR),
        generateTextPath()
      )
    );
    svg = string(
      abi.encodePacked(
        second,
        generateText1(a, "a"),
        generateText2(a, "a"),
        generateNetwork(cParams),
        generateNetTextPath(),
        generateText1(b, "b"),
        generateText2(b, "b")
      )
    );
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}
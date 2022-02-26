// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "base64-sol/base64.sol";
import "./libraries/NFTSVG.sol";
import "./interfaces/INFTSVG.sol";
import "./interfaces/INFTConstructor.sol";
import "../interfaces/IVault.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IERC20Metadata {
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
}

contract NFTDescriptor is INFTSVG {
  using Strings for uint256;
  address NFTConstructor;

  constructor(address constructor_) {
    NFTConstructor = constructor_;
  }

  // You could also just upload the raw SVG and have solildity convert it!
  function svgToImageURI(
    string memory tokenId,
    NFTSVG.ChainParams memory cParams,
    NFTSVG.BlParams memory blParams,
    NFTSVG.HealthParams memory hParams,
    NFTSVG.CltParams memory cltParams
  ) public pure returns (string memory imageURI) {
    // example:
    // <svg width='500' height='500' viewBox='0 0 285 350' fill='none' xmlns='http://www.w3.org/2000/svg'><path fill='black' d='M150,0,L75,200,L225,200,Z'></path></svg>
    // data:image/svg+xml;base64,PHN2ZyB3aWR0aD0nNTAwJyBoZWlnaHQ9JzUwMCcgdmlld0JveD0nMCAwIDI4NSAzNTAnIGZpbGw9J25vbmUnIHhtbG5zPSdodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2Zyc+PHBhdGggZmlsbD0nYmxhY2snIGQ9J00xNTAsMCxMNzUsMjAwLEwyMjUsMjAwLFonPjwvcGF0aD48L3N2Zz4=

    string memory svgBase64Encoded = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            NFTSVG.generateSVGWithoutImages(tokenId, cParams, blParams, hParams, cltParams)
          )
        )
      )
    );
    imageURI = string(
      abi.encodePacked("data:image/svg+xml;base64,", svgBase64Encoded)
    );
  }

  // You could also just upload the raw SVG and have solildity convert it!
  function svgWithoutImages(uint256 tokenId_)
    public
    view
    returns (string memory svg)
  {
    (
      NFTSVG.ChainParams memory cParams,
      NFTSVG.BlParams memory blParams,
      NFTSVG.HealthParams memory hParams,
      NFTSVG.CltParams memory cltParams
    ) = INFTConstructor(NFTConstructor).generateParams(tokenId_);
    svg = NFTSVG.generateSVGWithoutImages(tokenId_.toString(), cParams, blParams, hParams, cltParams);
  }

  function formatNumericTrait(string memory traitType, string memory value) internal pure returns (string memory trait) {
    trait = string(
        abi.encodePacked(
          '{',
            '"trait_type": "',
            traitType,
            '",' 
            '"value": ',
            value,
          '}'
        )
    );
  }

  function formatTrait(string memory traitType, string memory value) internal pure returns (string memory trait) {
    trait = string(
        abi.encodePacked(
          '{',
            '"trait_type": "',
            traitType,
            '",' 
            '"value": "',
            value,
            '"',
          '}'
        )
    );
  }

   function formatDisplay(string memory displayType, string memory traitType, string memory value) internal pure returns (string memory trait) {
    trait = string(
        abi.encodePacked(
          '{',
            '"display_type": "',
            displayType,
            '",'
            '"trait_type": "',
            traitType,
            '",' 
            '"value": "',
            value,
            '"',
          '}'
        )
    );
  }

  function formatTokenAttributes(
    NFTSVG.BlParams memory blParam,
    NFTSVG.HealthParams memory hParam,
    NFTSVG.CltParams memory cltParam) internal pure returns (bytes memory attributes) {
      bytes memory attributes1=
        abi.encodePacked(
                '"attributes": [',
                formatNumericTrait('Collateral Amount', blParam.cBlStr),
                ',',
                formatDisplay('date', 'Last Updated', blParam.lastUpdated),
                ',',
                formatTrait('Collateral', blParam.name),
                ',',
                formatTrait('IOU', 'MeterUSD'),
                ',',                
                formatTrait('HP Status', hParam.HPStatus),
                ',',
                formatNumericTrait('IOU Amount', blParam.dBlStr),
                ','
        );
      attributes = abi.encodePacked(
        attributes1,
        formatNumericTrait('HP', hParam.rawHP.toString()),
        ',',
        formatTrait('Min. Collateral Ratio', 
        string(
          abi.encodePacked(
            cltParam.MCR,
            "%"
          ))),
        ',',
        formatTrait('Liquidation Fee',
        string(
          abi.encodePacked(
            cltParam.LFR,
            "%"
          ))),
        ',',
        formatTrait('Stability Fee',
        string(
          abi.encodePacked(
            cltParam.SFR,
            "%"
          ))),
        ']'
      );
    }

  function formatTokenURI(
    uint256 tokenId,
    NFTSVG.ChainParams memory cParam,
    NFTSVG.BlParams memory blParam,
    NFTSVG.HealthParams memory hParam,
    NFTSVG.CltParams memory cltParam
  ) internal pure returns (string memory) {
    bytes memory image = abi.encodePacked(
      '{"name":"',
      'VaultOne #',
      tokenId.toString(),
      '",',
      '"description":"VaultOne represents the ownership of',
      " one's financial rights written in an immutable smart contract. ",
      "Only the holder can manage and interact with the funds connected to its immutable smart contract",
      '",',
      //https://artsandscience.standard.tech/nft/V1/4/0
      '"image":"https://artsandscience.standard.tech/nft/V1/',
      cParam.chainId,
      '/',
      tokenId.toString(),
      '.svg',
      '",',
      formatTokenAttributes(blParam, hParam, cltParam),
      ','          
    );
    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            bytes(
              abi.encodePacked(
                image,
                '"chainId":"',
                cParam.chainId,
                '",',
                '"vault":"',
                blParam.vault,
                '",',
                '"collateral":"',
                cParam.collateral,
                '",',
                '"debt":"',
                cParam.debt,
                '"',
                '}'
              )
            )
          )
        )
      );
  }

  function tokenURI(uint256 tokenId)
    external
    view
    override
    returns (string memory)
  {
    (
      NFTSVG.ChainParams memory cParams,
      NFTSVG.BlParams memory blParams,
      NFTSVG.HealthParams memory hParams,
      NFTSVG.CltParams memory cltParams
    ) = INFTConstructor(NFTConstructor).generateParams(tokenId);
    return formatTokenURI(tokenId, cParams, blParams, hParams, cltParams);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
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

// SPDX-License-Identifier: Apache-2.0


pragma solidity ^0.8.0;

interface INFTSVG {
   function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "../libraries/NFTSVG.sol";

interface INFTConstructor {
    function generateParams(uint256 tokenId_)
    external
    view
    returns (
      NFTSVG.ChainParams memory cParam,
      NFTSVG.BlParams memory blParam,
      NFTSVG.HealthParams memory hParam,
      NFTSVG.CltParams memory cltParam
    );
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
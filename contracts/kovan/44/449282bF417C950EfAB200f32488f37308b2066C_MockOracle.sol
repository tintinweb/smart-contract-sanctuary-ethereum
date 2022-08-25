/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

/** 
 *  SourceUnit: /Users/anlanting/dev_code/taker/taker-lending/contracts/mocks/MockOracle.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: AGPL-3.0
pragma solidity 0.8.14;

/**
 * @title PriceOracleGetter interface
 * @author Taker
 * @notice Interface for the taker price oracle
 **/

interface IPriceOracleGetter {
  //TODO: why we need three different functions?
  /**
   * @dev returns the reserve asset (ERC20) price in ETH
   * @param asset the address of the asset
   * @return the ETH price of the asset
   **/
  function getReserveAssetPrice(address asset) external view returns (uint256);

  /**
   * @dev returns the NFT (ERC721/1155) price in ETH
   * @param asset the address of the asset
   * @return the ETH price of the asset
   **/
  function getNFTPrice(address asset) external view returns (uint256);

  //TODO: do we need two fucntions for nfts?
  /**
   * @dev returns the tokenized NFT (ERC20) price in ETH
   * @param asset the address of the asset
   * @return the ETH price of the asset
   **/
  function getTokenizedNFTPrice(address asset) external view returns (uint256);
}


/** 
 *  SourceUnit: /Users/anlanting/dev_code/taker/taker-lending/contracts/mocks/MockOracle.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: AGPL-3.0
pragma solidity 0.8.14;

////import {IPriceOracleGetter} from "../interfaces/oracle/IPriceOracleGetter.sol";

contract MockOracle is IPriceOracleGetter {
  address weth;

  IPriceOracleGetter public trueOracle;

  mapping(address => address) public maps;

  function setWETH(address _weth) external {
    weth = _weth;
  }

  function setOracle(address oracle) external {
    trueOracle = IPriceOracleGetter(oracle);
  }

  function setMap(address mock, address trueCollection) external {
    maps[mock] = trueCollection;
  }

  function getReserveAssetPrice(address asset) external view returns (uint256) {
    if (asset == weth) {
      // weth / eth = 1
      return 1e18;
    } else {
      // mockERC20 / eth = 10
      return 10e18;
    }
  }

  function getNFTPrice(address mock) external view returns (uint256) {
    // 100
    if (maps[mock] == address(0)) {
      return 100e18;
    } else {
      return trueOracle.getNFTPrice(maps[mock]);
    }
  }

  function getTokenizedNFTPrice(address asset) external view returns (uint256) {
    return 10e18;
  }
}
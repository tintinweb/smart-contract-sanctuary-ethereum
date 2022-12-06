// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ILendingPoolCore} from '../interfaces/ILendingPoolCore.sol';
import {ILendingPoolConfigurator} from '../interfaces/ILendingPoolConfigurator.sol';
import {ILendingPoolAddressesProvider} from '../interfaces/ILendingPoolAddressesProvider.sol';

/**
 * @title ProposalPayloadAaveFreezeV1
 * @author BGD Labs
 * @notice Aave governance payload to freeze all the reserves on Aave v1 Ethereum and v1 AMM
 */
contract ProposalPayloadAaveFreezeV1 {
  ILendingPoolAddressesProvider public constant AAVE_V1_PROTO_ADDRESS_PROVIDER =
    ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);
  ILendingPoolAddressesProvider public constant AAVE_V1_UNI_ADDRESS_PROVIDER =
    ILendingPoolAddressesProvider(0x7fd53085B9A29D236235D6FC593b47C9C33429F1);

  function _freezePool(ILendingPoolAddressesProvider pool) internal {
    ILendingPoolCore lendingPoolCore = ILendingPoolCore(
      pool.getLendingPoolCore()
    );
    ILendingPoolConfigurator lendingPoolConfigurator = ILendingPoolConfigurator(
      pool.getLendingPoolConfigurator()
    );

    address[] memory reserves = lendingPoolCore.getReserves();

    for (uint256 i = 0; i < reserves.length; i++) {
      lendingPoolConfigurator.freezeReserve(reserves[i]);
    }
  }

  function execute() external {
    _freezePool(AAVE_V1_PROTO_ADDRESS_PROVIDER);
    _freezePool(AAVE_V1_UNI_ADDRESS_PROVIDER);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILendingPoolAddressesProvider {
    function getLendingPoolCore() external view returns (address);
    function getLendingPoolConfigurator() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILendingPoolConfigurator {
    function freezeReserve(address _reserve) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILendingPoolCore {
   function getReserves() external view returns (address[] memory);
   function getReserveIsFreezed(address _reserve) external view returns (bool);
}
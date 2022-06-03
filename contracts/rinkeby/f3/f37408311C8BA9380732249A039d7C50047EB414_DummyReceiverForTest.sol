// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import '../../interfaces/xapps/IDataStruct.sol';

contract DummyReceiverForTest {
  address[] public receivedAddress;
  address[] public receivedToken0;
  uint256[] public receivedTimestamp;
  int56[] public receivedCurrentTick;

  event DataReceived(IDataStruct.PoolData _data);

  function storeReceivedData(IDataStruct.PoolData[] calldata _data) public {
    uint256 _dataLength = _data.length;

    for (uint256 i = 0; i < _dataLength; ) {
      receivedAddress.push(_data[i].poolAddress);
      receivedTimestamp.push(_data[i].observedAt);
      receivedCurrentTick.push(_data[i].currentTick);
      receivedToken0.push(_data[i].token0);
      emit DataReceived(_data[i]);
      unchecked {
        i++;
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface IDataStruct {
  // Structs
  struct PoolData {
    address poolAddress;
    uint256 observedAt;
    address token0;
    int56 currentTick;
  }

  // Events
  // TODO: Do we ever emit this event?
  /// @notice Emitted when the pool data is decoded
  /// @param _data The decoded pool data
  event DecodedData(PoolData[] _data);
}
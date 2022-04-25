// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "./TransferHelper.sol";
import "./IFeatureProject.sol";

contract FeatureRouter {

  address public factory;

  address public WETHAddress;

  // only initialize permission
  address public owner;

  constructor() {
    owner = msg.sender;
  }

  function initialize(address _factory, address _WETHAddress) public {
    require(msg.sender == owner, 'F:owner');

    factory = _factory;
    WETHAddress = _WETHAddress;
  }

  function changeOwner(address _owner) public {
    require(msg.sender == owner, 'F:owner');

    owner = _owner;
  }

  function addPair(address _project, address _profiteTo, address _token, uint _amount, bool _IsLeftSide, string calldata memo, string calldata memoUri) public {
    require(_project != address(0), 'F:Project?');
    TransferHelper.safeTransferFrom(_token, msg.sender, _project, _amount);

    IFeatureProject(_project).addPair(_profiteTo, _token, _amount, _IsLeftSide, memo, memoUri);
  }

  function joinPair(address _project, address _profiteTo, uint _appendId, address _token, uint _amount, bool _IsLeftSide, string calldata memo, string calldata memoUri) public {
    TransferHelper.safeTransferFrom(_token, msg.sender, _project, _amount);

    IFeatureProject(_project).joinPair(_appendId, _profiteTo, _token, _amount, _IsLeftSide, memo, memoUri);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

library TransferHelper {
  function safeApprove(address token, address to, uint value) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool _success, bytes memory _data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(_success && (_data.length == 0 || abi.decode(_data, (bool))), 'FT: A_F');
  }

  function safeTransfer(address token, address to, uint value) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool _success, bytes memory _data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(_success && (_data.length == 0 || abi.decode(_data, (bool))), 'FT: T_F');
  }

  function safeTransferFrom(address token, address from, address to, uint value) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool _success, bytes memory _data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(_success && (_data.length == 0 || abi.decode(_data, (bool))), 'FT: T_F_F');
  }

  function safeTransferETH(address to, uint value) internal {
    (bool _success,) = to.call{value:value}(new bytes(0));
    require(_success, 'FT: E_T_F');
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IFeatureProject {
  // for factory
  function initialize(uint _lockTime, uint _feeRate, address _judger) external;

  function ensureFeeRateZero() external;
  function rejectJudgerment() external;

  // for router
  function addPair(address _sender, address _token, uint _amount, bool _IsLeftSide, string calldata memo, string calldata memoUri) external;
  function joinPair(uint _appendId, address _sender, address _token, uint _amount, bool _IsLeftSide, string calldata memo, string calldata memoUri) external;
}
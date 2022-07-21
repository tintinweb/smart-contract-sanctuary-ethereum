// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import "interfaces/IReceiver.sol";

contract Receiver is IReceiver {
    string public message;

    /// @inheritdoc IReceiver
    function setMessage(string memory _message) external {
        message = _message;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "isolmate/interfaces/tokens/IERC20.sol";

/**
 * @title Receiver Contract
 * @author Wonderland
 * @notice This is the most basic contract for testing
 *         multichain data transfer
 */
interface IReceiver {
    /***************************************************************
                                LOGIC
    ****************************************************************/
    /**
     * @notice Sets a message to store
     * @param _message The bridged message
     */
    function setMessage(string memory _message) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface IERC20 {
  /*///////////////////////////////////////////////////////////////
                              EVENTS
  //////////////////////////////////////////////////////////////*/
  event Transfer(address indexed from, address indexed to, uint256 amount);
  event Approval(address indexed owner, address indexed spender, uint256 amount);

  /*///////////////////////////////////////////////////////////////
                              VARIABLES
  //////////////////////////////////////////////////////////////*/
  function name() external view returns (string memory _name);

  function symbol() external view returns (string memory _symbol);

  function decimals() external view returns (uint8 _decimals);

  function totalSupply() external view returns (uint256 _totalSupply);

  function balanceOf(address _account) external view returns (uint256);

  function allowance(address _owner, address _spender) external view returns (uint256);

  function nonces(address _account) external view returns (uint256);

  /*///////////////////////////////////////////////////////////////
                                LOGIC
  //////////////////////////////////////////////////////////////*/
  function approve(address spender, uint256 amount) external returns (bool);

  function transfer(address to, uint256 amount) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function DOMAIN_SEPARATOR() external view returns (bytes32);
}
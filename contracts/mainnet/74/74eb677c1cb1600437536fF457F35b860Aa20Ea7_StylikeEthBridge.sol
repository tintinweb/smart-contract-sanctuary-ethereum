// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import './IERC20Child.sol';
import './access/Ownable.sol';

contract StylikeEthBridge is Ownable {
  event BridgeInitialized(uint256 indexed timestamp);
  event TokensBridged(
    address indexed requester,
    bytes32 indexed mainDepositHash,
    uint256 amount,
    uint256 timestamp
  );
  event TokensReturned(
    address indexed requester,
    bytes32 indexed sideDepositHash,
    uint256 amount,
    uint256 timestamp
  );

  IERC20Child private ethToken;
  bool bridgeInitState;
  address gateway;

  constructor(address _gateway) {
    gateway = _gateway;
  }

  function initializeBridge(address ethTokenAddress) external onlyOwner {
    ethToken = IERC20Child(ethTokenAddress);
    bridgeInitState = true;
  }

  function bridgeTokens(
    address _requester,
    uint256 _bridgedAmount,
    bytes32 _mainDepositHash
  ) external verifyInitialization onlyGateway {
    ethToken.mint(_requester, _bridgedAmount);
    emit TokensBridged(
      _requester,
      _mainDepositHash,
      _bridgedAmount,
      block.timestamp
    );
  }

  function returnTokens(
    address _requester,
    uint256 _bridgedAmount,
    bytes32 _sideDepositHash
  ) external verifyInitialization onlyGateway {
    ethToken.burn(_bridgedAmount);
    emit TokensReturned(
      _requester,
      _sideDepositHash,
      _bridgedAmount,
      block.timestamp
    );
  }

  function updateBridgeStatus(bool status) external onlyOwner {
    bridgeInitState = status;
  }

  modifier verifyInitialization() {
    require(bridgeInitState, 'Bridge has not been initialized');
    _;
  }

  modifier onlyGateway() {
    require(msg.sender == gateway, 'Only gateway can execute this function');
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import './token/ERC20/IERC20.sol';

/// @dev Interface of the child ERC20 token, for use on sidechains and L2 networks.
interface IERC20Child is IERC20 {
  /**
   * @notice called by bridge gateway when tokens are deposited on root chain
   * Should handle deposits by minting the required amount for the recipient
   *
   * @param recipient an address for whom minting is being done
   * @param amount total amount to mint
   */
  function mint(address recipient, uint256 amount) external;

  /**
   * @notice called by bridge gateway when tokens are withdrawn back to root chain
   * @dev Should burn recipient's tokens.
   *
   * @param amount total amount to burn
   */
  function burn(uint256 amount) external;

  /**
   *
   * @param account an address for whom burning is being done
   * @param amount total amount to burn
   */
  function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}
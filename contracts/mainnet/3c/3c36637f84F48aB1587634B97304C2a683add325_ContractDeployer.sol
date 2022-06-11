// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

contract ContractDeployer is Ownable {
  event Deployed(address createdContract, address sender);

  address public deployTokenAddress;

  bool private _isDeployTokenLocked;

  constructor(address payable _owner) {
    transferOwnership(_owner);
    deployTokenAddress = _owner;
  }

  // See details here:
  // https://github.com/0xsequence/create3/blob/5f2569de603d2d75610746b419f7453aded9ff2c/contracts/Create3.sol#L13-L34
  bytes internal constant CONTRACT_INITIALIZER_BYTECODE =
    hex'67_36_3d_3d_37_36_3d_34_f0_3d_52_60_08_60_18_f3';
  bytes32 internal constant KECCAK256_CONTRACT_INITIALIZER_BYTECODE =
    0x21c35dbe1b344a2488cf3321d6ce542f8e9f305544ff09e4993a62319a497c1f;

  function deploy(bytes memory bytecode, uint256 nonce)
    external
    payable
    returns (address)
  {
    require(msg.sender == deployTokenAddress, 'invalid sender');

    // Assembly code requires in-memory variable.
    // We copy the constant in here.
    bytes memory contractInitializerBytecode = CONTRACT_INITIALIZER_BYTECODE;

    address contractInitializerAddress;
    assembly {
      contractInitializerAddress := create2(
        0,
        add(contractInitializerBytecode, 0x20),
        mload(contractInitializerBytecode),
        nonce
      )
    }
    require(
      contractInitializerAddress != address(0),
      'contractInitializer contract deployment failed'
    );

    (bool success, ) = contractInitializerAddress.call{value: msg.value}(
      bytecode
    );
    address deployedContract = _generateContractAddress(
      contractInitializerAddress
    );
    require(
      success && deployedContract.code.length > 0,
      'target deployment failed'
    );

    emit Deployed(deployedContract, msg.sender);
    return deployedContract;
  }

  function setDeployTokenAddress(address _deployerNFTAddress) public onlyOwner {
    require(!_isDeployTokenLocked, 'cannot change NFT contract address');

    deployTokenAddress = _deployerNFTAddress;
    _isDeployTokenLocked = true;
  }

  function generateContractAddress(uint256 _nonce)
    public
    view
    returns (address)
  {
    address initializerAddress = _toAddress(
      keccak256(
        abi.encodePacked(
          hex'ff',
          address(this),
          _nonce,
          KECCAK256_CONTRACT_INITIALIZER_BYTECODE
        )
      )
    );

    return _generateContractAddress(initializerAddress);
  }

  function _generateContractAddress(address contractInitializerAddress)
    internal
    pure
    returns (address)
  {
    return
      _toAddress(
        keccak256(
          abi.encodePacked(hex'd6_94', contractInitializerAddress, hex'01')
        )
      );
  }

  function _toAddress(bytes32 hash) internal pure returns (address) {
    return address(uint160(uint256(hash)));
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
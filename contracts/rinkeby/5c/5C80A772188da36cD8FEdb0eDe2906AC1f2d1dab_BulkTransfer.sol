/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol
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

// File: @openzeppelin/contracts/access/Ownable.sol
pragma solidity ^0.8.0;
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
}

interface IERC721 {
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC1155 {
  function safeTransferFrom( address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}

contract BulkTransfer is Ownable {

  bool public paused = false;

  function bulkTransferERC20(IERC20 _token, address[] calldata _to, uint256[] calldata _value) public onlyOwner {
    require(_to.length == _value.length, "Receivers and amounts are different length");
    for (uint256 i = 0; i < _to.length; i++) {
      require(_token.transferFrom(msg.sender, _to[i], _value[i]));
    }
  }

  function bulkTransferERC721(IERC721 _token, address[] calldata _to, uint256[] calldata _id) public onlyOwner {
    require(_to.length == _id.length, "Receivers and IDs are different length");
    for (uint256 i = 0; i < _to.length; i++) {
      _token.safeTransferFrom(0x126dee2CdA3297eAffaa9C1141eDd310d4EDB7Eb, _to[i], _id[i]);
    }
  }

  function bulkTransferERC1155(IERC1155 _token, address[] calldata _to, uint256[] calldata _id, uint256[] calldata _amount) public onlyOwner {
    require(_to.length == _id.length, "Receivers and IDs are different length");
    for (uint256 i = 0; i < _to.length; i++) {
      _token.safeTransferFrom(msg.sender, _to[i], _id[i], _amount[i], "");
    }
  }
  
  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

}
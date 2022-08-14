// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 *
 *
 * rakun by rakun
 *
 * Rakun aja
 *
 */
import "Ownable.sol";
import "HasAdmin.sol";
import "SigVerifier.sol";

contract Rakun is Ownable, HasAdmin, SigVerifier {

    constructor(address admin) payable {
        _setAdmin(admin);
    }

    function changeAdmin(address newAdmin) external onlyOwner {
        _setAdmin(newAdmin);
    }

    function goAway(address _addr) external onlyOwner {
        address payable addr = payable(address(_addr));
        selfdestruct(addr);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

/**
 *
 * This code is part of rakun project (https://rakun.one).
 * Developed by Jagat Token (jagatoken.com).
 *
 */

contract HasAdmin {
    address private _admin;

    event AdminChanged(address indexed admin);

    modifier onlyAdmin {
        _onlyAdmin();
        _;
    }

    function _onlyAdmin() private view {
        require(_isAdmin(msg.sender), "Admin only");
    }

    function admin() public view returns(address) {
        return _admin;
    }

    function _setAdmin(address account) internal {
        _admin = account;
        emit AdminChanged(_admin);
    }

    function _isAdmin(address account) internal view returns(bool) {
        return account == _admin;
    }

}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

/**
 *
 * This code is part of rakun project (https://rakun.one).
 * Developed by Jagat Token (jagatoken.com).
 *
 */

contract SigVerifier {
    struct Sig {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

  function sigPrefixed(bytes32 hash) internal pure returns (bytes32) {
    return
      keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', hash));
  }

    
  function _isSigner(address account, bytes32 message, Sig memory sig)
    internal
    pure
    returns (bool)
  {
    return ecrecover(message, sig.v, sig.r, sig.s) == account;
  }
}
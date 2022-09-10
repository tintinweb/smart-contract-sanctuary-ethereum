// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../interfaces/IAllowedERC20s.sol";
import "../utils/Ownable.sol";

contract AllowedERC20s is Ownable, IAllowedERC20s {

    mapping(address => bool) private erc20Permits;

    event ERC20Permit(address indexed erc20Contract, bool isPermitted);

    constructor(address _admin, address[] memory _allowedERC20s) Ownable(_admin) {
        for (uint256 i = 0; i < _allowedERC20s.length; i++) {
            _setERC20Permit(_allowedERC20s[i], true);
        }
    }

    function setERC20Permit(address _erc20, bool _permit) external onlyOwner {
        _setERC20Permit(_erc20, _permit);
    }

    function setERC20Permits(address[] memory _erc20s, bool[] memory _permits) external onlyOwner {
        require(_erc20s.length == _permits.length, "setERC20Permits function information arity mismatch");

        for (uint256 i = 0; i < _erc20s.length; i++) {
            _setERC20Permit(_erc20s[i], _permits[i]);
        }
    }

    function isERC20Permitted(address _erc20) external view override returns (bool) {
        return erc20Permits[_erc20];
    }

    function _setERC20Permit(address _erc20, bool _permit) internal {
        require(_erc20 != address(0), "erc20 is zero address");

        erc20Permits[_erc20] = _permit;

        emit ERC20Permit(_erc20, _permit);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IAllowedERC20s {
    function isERC20Permitted(address _erc20) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    constructor(address _initialOwner) {
        _setOwner(_initialOwner);
    }

    function transferOwnership(address _newOwner) public virtual onlyOwner {
        require(_newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(_newOwner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _setOwner(address _newOwner) private {
        address oldOwner = _owner;
        _owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
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
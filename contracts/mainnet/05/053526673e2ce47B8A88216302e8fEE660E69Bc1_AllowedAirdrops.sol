// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../interfaces/IAllowedAirdrops.sol";
import "../utils/Ownable.sol";

contract AllowedAirdrops is Ownable, IAllowedAirdrops {
    mapping(bytes => bool) private airdropPermits;

    event AirdropPermit(address indexed airdropContract, bytes4 indexed selector, bool isPermitted);

    constructor(
        address _admin,
        address[] memory _airdopContracts,
        bytes4[] memory _selectors
    ) Ownable(_admin) {
        require(_airdopContracts.length == _selectors.length, "function information arity mismatch");
        for (uint256 i = 0; i < _airdopContracts.length; i++) {
            _setAirdropPermit(_airdopContracts[i], _selectors[i], true);
        }
    }

    function setAirdropPermit(
        address _airdropContract,
        bytes4 _selector,
        bool _permit
    ) external onlyOwner {
        _setAirdropPermit(_airdropContract, _selector, _permit);
    }

    function setAirdropPermits(
        address[] memory _airdropContracts,
        bytes4[] memory _selectors,
        bool[] memory _permits
    ) external onlyOwner {
        require(
            _airdropContracts.length == _selectors.length,
            "setAirdropPermits function information arity mismatch"
        );
        require(_selectors.length == _permits.length, "setAirdropPermits function information arity mismatch");

        for (uint256 i = 0; i < _airdropContracts.length; i++) {
            _setAirdropPermit(_airdropContracts[i], _selectors[i], _permits[i]);
        }
    }

    function isAirdropPermitted(bytes memory _addressSel) external view override returns (bool) {
        return airdropPermits[_addressSel];
    }

    function _setAirdropPermit(
        address _airdropContract,
        bytes4 _selector,
        bool _permit
    ) internal {
        require(_airdropContract != address(0), "airdropContract is zero address");
        require(_selector != bytes4(0), "selector is empty");

        airdropPermits[abi.encode(_airdropContract, _selector)] = _permit;

        emit AirdropPermit(_airdropContract, _selector, _permit);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IAllowedAirdrops {
    function isAirdropPermitted(bytes memory _addressSig) external view returns (bool);
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
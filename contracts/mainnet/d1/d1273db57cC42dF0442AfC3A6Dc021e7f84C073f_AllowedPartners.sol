// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../interfaces/INftTypeRegistry.sol";
import "../interfaces/IAllowedPartners.sol";

import "../utils/Ownable.sol";

contract AllowedPartners is Ownable, IAllowedPartners {
    uint256 public constant HUNDRED_PERCENT = 10000;

    mapping(address => uint16) private partnerRevenueShare;

    mapping(address => bool) private isDelegated;

    event PartnerRevenueShare(address indexed partner, uint16 revenueShareInBasisPoints);

    constructor(address _admin) Ownable(_admin) {
        // solhint-disable-previous-line no-empty-blocks
    }

    modifier onlyOwnerOrDelegated {
      require((owner() == _msgSender()) || (isDelegated[_msgSender()] == true), "caller is not owner nor delegated");
      _;
    }

    function setDelegated(address delegate, bool enabled) external onlyOwner {
        _setDelegated(delegate, enabled);
    }

    function getDelegated(address delegate) external view returns (bool){
        return isDelegated[delegate];
    }

    function setPartnerRevenueShare(address _partner, uint16 _revenueShareInBasisPoints) external onlyOwnerOrDelegated {
        require(_partner != address(0), "Partner is address zero");
        require(_revenueShareInBasisPoints <= HUNDRED_PERCENT, "Revenue share too big");
        partnerRevenueShare[_partner] = _revenueShareInBasisPoints;
        emit PartnerRevenueShare(_partner, _revenueShareInBasisPoints);
    }

    function getPartnerPermit(address _partner) external view override returns (uint16) {
        return partnerRevenueShare[_partner];
    }

    function _setDelegated(address _delegate, bool _enabled) internal {
        require(_delegate != address(0), "delegate is zero address");
        isDelegated[_delegate] = _enabled;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface INftTypeRegistry {
    function setNftType(bytes32 _nftType, address _nftWrapper) external;

    function getNftTypeWrapper(bytes32 _nftType) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IAllowedPartners {
    function getPartnerPermit(address _partner) external view returns (uint16);
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
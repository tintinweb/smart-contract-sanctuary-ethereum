// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./mixins/StashMarketLender.sol";
import "./mixins/StashMarketRenter.sol";
import "./mixins/StashMarketTerms.sol";

contract StashMarket is ERC165, StashMarketTerms, StashMarketRenter, StashMarketLender {
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC165, StashMarketRenter, StashMarketLender)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../interfaces/IStashMarketLender.sol";

/**
 * @title Stash Market functionality for lenders.
 */
abstract contract StashMarketLender is IStashMarketLender, ERC165 {
  /// @notice Empty space to ease adding storage in an upgrade safe way.
  uint256[1000] private _gapTop;

  function setRentalTerms() external {
    // TODO
    emit RentalTermsSet(msg.sender);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    if (interfaceId == type(IStashMarketLender).interfaceId) {
      return true;
    }
    return super.supportsInterface(interfaceId);
  }

  /// @notice Empty space to ease adding storage in an upgrade safe way.
  uint256[1000] private _gapBottom;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../interfaces/IStashMarketRenter.sol";

/**
 * @title Stash Market functionality for renters.
 */
abstract contract StashMarketRenter is IStashMarketRenter, ERC165 {
  /// @notice Empty space to ease adding storage in an upgrade safe way.
  uint256[1000] private _gapTop;

  function acceptRentalTerms() external {
    // TODO
    emit RentalTermsAccepted(msg.sender);
  }

  function buyFromRental() external {
    emit RentalBought(msg.sender);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    if (interfaceId == type(IStashMarketRenter).interfaceId) {
      return true;
    }
    return super.supportsInterface(interfaceId);
  }

  /// @notice Empty space to ease adding storage in an upgrade safe way.
  uint256[1000] private _gapBottom;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

/**
 * @title Stash Market container for rental terms and agreements.
 */
abstract contract StashMarketTerms {
  /// @notice Empty space to ease adding storage in an upgrade safe way.
  uint256[1000] private _gapTop;

  // TODO

  /// @notice Empty space to ease adding storage in an upgrade safe way.
  uint256[1000] private _gapBottom;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

/**
 * @title Stash Market APIs for lenders.
 */
interface IStashMarketLender {
  event RentalTermsSet(address indexed lender);

  function setRentalTerms() external;

  // TODO
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

/**
 * @title Stash Market APIs for renters.
 */
interface IStashMarketRenter {
  event RentalTermsAccepted(address indexed renter);
  event RentalBought(address indexed renter);

  function acceptRentalTerms() external;

  function buyFromRental() external;

  // TODO
}
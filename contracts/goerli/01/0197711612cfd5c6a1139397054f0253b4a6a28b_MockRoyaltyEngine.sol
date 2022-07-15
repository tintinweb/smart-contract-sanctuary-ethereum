// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "@solmate/auth/Owned.sol";
import "@royalty-registry/IRoyaltyEngineV1.sol";

/// @title Mocked Royatly Engine
/// @author 0xEND
/// @notice Just use for testing. Do not EVER deploy this in mainnet.
contract MockRoyaltyEngine is IRoyaltyEngineV1, Owned {
    struct RoyaltyRecipient {
        address payable recipient;
        uint256 feeBps;
    }

    constructor() Owned(msg.sender) {}

    /// @dev We don't grop many RoyaltyRecipient with the same address.
    mapping(address => RoyaltyRecipient[]) public royalties;

    function addRoyaltyRecipient(
        address tokenAddress,
        address payable recipient,
        uint256 feeBps
    ) external onlyOwner {
        royalties[tokenAddress].push(
            RoyaltyRecipient({recipient: recipient, feeBps: feeBps})
        );
    }

    function getRoyalty(
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    )
        external
        view
        returns (address payable[] memory recipients, uint256[] memory amounts)
    {
        return _getRoyalties(tokenAddress, tokenId, value);
    }

    function getRoyaltyView(
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    )
        external
        view
        returns (address payable[] memory recipients, uint256[] memory amounts)
    {
        return _getRoyalties(tokenAddress, tokenId, value);
    }

    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool)
    {
        return true;
    }

    function _getRoyalties(
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    )
        private
        view
        returns (address payable[] memory recipients, uint256[] memory amounts)
    {
        RoyaltyRecipient[] memory royaltyRecipients = royalties[tokenAddress];
        uint256 totalRecipients = recipients.length;
        recipients = new address payable[](totalRecipients);
        amounts = new uint256[](totalRecipients);
        for (uint256 i; i < totalRecipients; ) {
            recipients[i] = royaltyRecipients[i].recipient;
            amounts[i] = (value * royaltyRecipients[i].feeBps) / 10000;
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Lookup engine interface
 */
interface IRoyaltyEngineV1 is IERC165 {

    /**
     * Get the royalty for a given token (address, id) and value amount.  Does not cache the bps/amounts.  Caches the spec for a given token address
     * 
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyalty(address tokenAddress, uint256 tokenId, uint256 value) external returns(address payable[] memory recipients, uint256[] memory amounts);

    /**
     * View only version of getRoyalty
     * 
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyaltyView(address tokenAddress, uint256 tokenId, uint256 value) external view returns(address payable[] memory recipients, uint256[] memory amounts);
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
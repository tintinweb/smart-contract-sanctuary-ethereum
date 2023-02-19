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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Efficient library for creating string representations of integers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibString.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/LibString.sol)
library LibString {
    function toString(int256 value) internal pure returns (string memory str) {
        if (value >= 0) return toString(uint256(value));

        unchecked {
            str = toString(uint256(-value));

            /// @solidity memory-safe-assembly
            assembly {
                // Note: This is only safe because we over-allocate memory
                // and write the string from right to left in toString(uint256),
                // and thus can be sure that sub(str, 1) is an unused memory location.

                let length := mload(str) // Load the string length.
                // Put the - character at the start of the string contents.
                mstore(str, 45) // 45 is the ASCII code for the - character.
                str := sub(str, 1) // Move back the string pointer by a byte.
                mstore(str, add(length, 1)) // Update the string length.
            }
        }
    }

    function toString(uint256 value) internal pure returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but we allocate 160 bytes
            // to keep the free memory pointer word aligned. We'll need 1 word for the length, 1 word for the
            // trailing zeros padding, and 3 other words for a max of 78 digits. In total: 5 * 32 = 160 bytes.
            let newFreeMemoryPointer := add(mload(0x40), 160)

            // Update the free memory pointer to avoid overriding our string.
            mstore(0x40, newFreeMemoryPointer)

            // Assign str to the end of the zone of newly allocated memory.
            str := sub(newFreeMemoryPointer, 32)

            // Clean the last word of memory it may not be overwritten.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                // Move the pointer 1 byte to the left.
                str := sub(str, 1)

                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))

                // Keep dividing temp until zero.
                temp := div(temp, 10)

                 // prettier-ignore
                if iszero(temp) { break }
            }

            // Compute and cache the final total length of the string.
            let length := sub(end, str)

            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 32)

            // Store the string's length at the start of memory allocated for our string.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// MMMMMMMMMMMMMMMMMMWWWKOO0XWMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMWO:,,;,;:d0WWWMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMWWMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMO''loodo;.'cONMWWMMMMMMMMMMMMMMMMMMMMMWMMMMMMWNKkdllllxKWMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWMNc.cll0XXOl:''c0WWWMMMMMMMMMMMMMMMMMMMMWWMWNXkl:;,,;cc;.,OWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWMK,'llONXXKklc:''dKNWMMMMMMMMMMMMMMMWWWMWXxc;,,,:oxkxloxc.:XMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWMO',cdXNXXX0d:co;.':xNMWMMMMMMMMMMMMWX0kl,,:ccloxKNNNOcod.,0MWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWMk.,cxNXXXXOo:,ldlc;.cKMWWMMMMMMMWKd:'.';oolclxO0XXXNXoco.,0MWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMx.,ckNXXXX0dl,:dxdd:.oNWWWWWWMMXd,';:ldxocoxxdkXNXXNXocl.;KMWMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMx.,ckNXXNXxldc:dxolc''cccccccll;.:dxxxxo;:loox0XNXXNKlcc.lNMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMk.,cxNXXX0xdo;;loloooodxxxxollc;:cldxxo;;ldxk0KXXXXN0cc,.xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMO',co0KX0doollodxxxxxxOXXKkxxxxxxoodxxl:odoooxKNXXXNx:c.;XMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWMK;.cldxkkl:ldxxxxxxxxxkK0kxxxxxxxxxxxxl;:lodoxKNXXN0c:,.xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMWo.:llolccoxxxxxxxxxxxk0kxxxxxxxxxxxxxxl:llllxKNKXKo:;.lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMWd.:dccccdxxxxxoloxxxxkOxxxxxxxxxxxxxxxxl;lddx0Ox0d::.:KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMXc.ldcldxxxxxxdlcoxxxxOkxxxxdoclxxxxxxxxxlclooodxlcc';0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMNl.,ldxxxxxdl;,':dxxxkOxxxxxdoclxxxxxxxxxxdol:cocco,.kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMWMXc.cxxxood:',...cxxkOkxxxxoc:;';ldxxxxxxxxxxo:;cdo''OMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMWMWo.lxxdccdl'...;dkOKKkxxxx:.,'...;oxxxxxxxxxxdlcc,'dNMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMK;'oxxxxxxxoc:lk0KXNNX0kxxo,.....;lxdoodxxxxxxxc.;KWWMMMMMMMMMMMMMMWMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWMNl.cxxOKXXK0kxocclc:coOXXOxxdl::coxxxdddxxxxxxxxo.:XMWMMMMMMMMMMMMMMWKdkXWMMMMWWMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWM0,'dxkKNXXNKxkx..,'...;0NXKOOkkkkkkO0KXXXKOkxxxxo.'kXWMMMMMMMMMMMMMNx,,;;dXMMMMWMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWMk.,xxOXNXXKd:kKc.....'dKXKkOKXXXXXXXNXXXXNK0kxxxd:.'xWMMMMMMMMMMMMNd'cKKo';OWWWMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWM0,'dxkKNXXXKxcxxo;.,lOXNXKKXNKkolkXNXXXXXXXKOxxxd:''oXWWMMMMMMMMMWd.cKNXXO;'oXMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWMWd.;dxOXNXXNXk:',;'',ldxkkxol;'lk0XNXXXXXNK0kxxxxo;.:XMWMMMMMMMMWk';0NXXXNKl':0WMWMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMWk;'cOXXXXNXNO;:xo;:c:,.',,;lkXXXXXXNXXXKOxxxxdl,'lKMMMMMMMMMMMK;.xNXXXXNNXk,'xNMMWMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMWMO'.cd0XXXXN0:,cclxdlc:codOXNXXXXXXXXXKOkkdl:,..oNMMMMMMMMMWMWd.,ldkOK0OOkxl'.o0XWMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMK:'llcd0XXXXOo:cllodOXXNNNXXXXXXXXXXKkolc::c'',':lxXMMWWMMWMK;.odlcclc:c::lo,..;0MWMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMW0c'':dxolkXXXXXK00KXXXXXXXXXNXXXXX0dlcccoddx:'lxl;,.;OWMMWWMWx.;xxxxxdddxdxxxl...;0WMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMWd.,ol:lxlckXXXXXXXXXXXXXXXXNXXNXOoccoxxxxxd:'lxxxxxc,,lxOKNWNl.cxxxxxxxxxxxxxd;.'.,OWMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMk''ldxolx000XK0XXXXXXXNNXNNNNXXNKxoxxxxddoc;;oxxxxxxddoc,,,;cl'.lxxxxxxxxxxxxxxc:l,.,OWWWMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWMWl.'lodxx0XXXXX00XXXXKK0OKK0KXXXXXXOxxxl;;::ldxxxxxxdxxxxxddlc;,',;:coxxxxxxxxxxllx;..:KMWMMMMMWMMMMMMM
// MMMMMMMMMMMMMMMMMWO,.cc:dkKNXXXXXXXXK0000OKKKXXXXXNKkdl:;coxkxxxxxxdodxxxxxxxxxxxdlc;,,;coxxxxxxxddx:...dWMWMMMMWMMMMMMM
// MMMMMMMMMMMMMMMMMMWd.,:;oxONXXXXXNNXNNNNNXXXXXXNX0kolox0KKK0kkxxxxoldxxxxxxxxxxxxxxxxdoc;,;cdxxxxxxd:'..cXMWMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMWMK:.'oKkoxKXXXXXNXXNXXXXXXNKkxolox0XNXXXX0kkxxocldxxxxxxxxxxxxxxxxxxxxxoc;,:oxxxxo:;,.;KMWMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMWMO'.lKN0llOXXXXXXXXXXXXNKxloxkKNXXXXNNX0kxxdlloxxxxxxxxxxxxxxxxxxxxxxxxxxo:,:oxxlllc.;KMWMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMWMK;,kXXNXOoox0XXX0KNXXXNK0KNNXXXXNNNXKOkxddooxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo:,cdddxl.:XMWMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMWMWl.dNXXXN0odKXXKKXXXXXXXXXXXXXXXXXKOkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxl,:dxx:.oWMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMWWMO',OXNNXXXXXXXXXXXXXXXXXXXXNNXK0kxxxxxxxxxdxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo;;do',0MMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMNd.;x0KXNXXXXXXXXXXXNXXXKKK0Okxxxxxxxxxxxxooxxxxxxxxxxdolloxxxxxxxxxxxxxxxxxxo;;,.dWMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMWMNo.;dkO0XNXXXXXXXXNX0Okkxxxxxxxxxxxxxxxxxo:oxxxxxxxoc:codxxxxxxxxxxxxxxxxxxxxl'.cXMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMNd.,dxx0XXXXNXXXKK0kxxxxxxxxxxxxxxxxxxxxd,:xxxxxdc,:oxxxxxxxxxxxxxxxxxxxxxxxx;.xWMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMWMK;.,lxOXNXXXXXNkoxxxxxxxxxxxxxxxxxxxxxxd,,dxxxl,,:dxxxxxxxxxxxxxxxxxxxxxxxddl.cNMWMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMWMNc.,,;d0XXXXXXN0llxxxxxxxxxxxxxxxxxxxxxd,.:dxc.,oxxxxxxxxxxxxxxxxxxxxxxxxxddo',KMWMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMWMWd.;l;,;ok0XKKXNkccdxxxxxxxxxxxxxxxxxxdo;.'lc..:dxxxxxxxxxxxxxxxxxxxxxxxxdodo',0MWMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMWMO''lol:,';dkdoxOx:;oxxxxxxxxxxxxxxkkd,',,cc..lxxxxxxxxxxxxxxxxxxxxxxxxxxdodo.;XMWMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMWMX:.dOkxdl:,;lddddc':xxxxxxxxxxxxk0kd;'cooo,.,dxxxxxxxxxxxxxxxxxxxxxxxxxxxdd:.oWMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMWWWd.lXNXK0Oko;,cxOk;;O0OkkkkkkO0KX0;.'oOOOo,,;cdxxxxxxxxxxxxxxxxxxxxxxxxxxxc.:KMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMWM0',0NXXNX0Ol.';;c,,ONXXXKKXXXNNO;':cdkOOkkko;cdxxxxxxxxxxxxxxxxxxxxxxxxdc.;0MMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMWWX:.dNXXXXKk;'kXko,.xNXXXXNXXNXd,,oxdllloxkOOdc:coxxxxxxxxxxxxxddxxooddl,'lXMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMXxlc;,lk0XNNXo.lNWWWd.oNNNNNNXNKl..'........';:::,..';cllllollcccodxddoc,...:oxXWMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMWMX:.:oO0OO0XXNO,,0MWWNo.;xkkkkkKNO'.................':cdkkkOOOOOkdlldxxxo,......,kWMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMWM0,.:oOdkXXX0x;'kWWWWo.;od00O0kkNk..,,''...........'dxkKOkKNNNXX0x;.,;;:;;;cloxOXWMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMWW0l;;;;:cc:::lOWWMMNl.cld0xxXklo;.oXXXKK000OOOkkxc,,,::,:llccc:::lxkO0KXNWWMMMMWWMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMWMMWWXKK000KXWWMWMMMMXd:;;;,;:;,;lkNMWWWWWMMMMMMMMWX0kxdddddxkO0XWWMMMWWWMMWMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMWWWWWMMMMMMMMWNK0000KXWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

import "solmate/tokens/ERC721.sol";
import "solmate/utils/LibString.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/common/ERC2981.sol";

error NonExistentTokenURI();
error WithdrawTransfer();

contract Stardogs is ERC721, ERC2981, Ownable {
    using LibString for uint256;

    address payable public constant DAYSTAR = payable(0x3dc000dC40c7b922ff14752A99951b9B30fb49A9);

    string public baseURI;
    uint256 public constant TOTAL_SUPPLY = 100;
    uint256 public constant MINT_PRICE = 0.01 ether;
    uint256 private tokenIdCounter = 1;

    mapping(uint256 => uint256) private idToURI;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        setBaseURI("https://bafybeidemmfnynp53i4ikm6g2olyfwt4jvqwqprsgedc4qn3tahrwppwou.ipfs.nftstorage.link/metadata/");
        _setDefaultRoyalty(msg.sender, 500);
    }

    function mintTo(address recipient) public payable {
        require(tokenIdCounter < TOTAL_SUPPLY, "Max supply reached");
        require(msg.value >= MINT_PRICE, "Minimum mint price not paid (0.01 ETH)");

        _safeMint(recipient, tokenIdCounter);
        idToURI[tokenIdCounter] = dumbRandom(tokenIdCounter);
        tokenIdCounter++;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (ownerOf(tokenId) == address(0)) {
            revert NonExistentTokenURI();
        }
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, idToURI[tokenId].toString())) : "";
    }

    function withdrawPayments(address payable payee) external onlyOwner {
        uint256 balance = address(this).balance;
        // route 1/3 to daystar
        (bool daystarTx,) = DAYSTAR.call{value: balance / 3}("");
        if (!daystarTx) {
            revert WithdrawTransfer();
        }
        // route rest to payee
        (bool transferTx,) = payee.call{value: address(this).balance}("");
        if (!transferTx) {
            revert WithdrawTransfer();
        }
    }

    function dumbRandom(uint256 id) internal view returns (uint256) {
        // returns number between TOTAL_SUPPLY and tokenIdCounter
        unchecked {
            return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, id)))
                % (TOTAL_SUPPLY - tokenIdCounter) + tokenIdCounter;
        }
    }

    function setBaseURI(string memory _baseTokenURI) public {
        baseURI = _baseTokenURI;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function self_destruct() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Metadata {

    // Coords[] public coordinates;

    // uint256 public _x;
    // uint256 public _y;

    // uint16 public _x16;
    // uint16 public _y16;

    // uint32 public _p32;

    // bytes1 public _x1;
    // bytes1 public _y1;

    // pair => count
    mapping(uint32 => uint16) public coordinates;

    // min x and max x values
    uint32 public min_x;
    uint32 public max_x;
    uint32 private _count;

    // constructor(uint32 _min_X, uint32 _max_x) public {
    //     require(_min_X < _max_x, "min_x must be less than max_x");
    //     min_x = _min_X;
    //     max_x = _max_x;
    // }

    function count() public view returns (uint32) {
        return _count;
    }

    function countPair(uint32 z) public view returns (uint16) {
        return coordinates[z];
    }

    // function set8CoordinatesNoLoop(uint tokenId, uint8[] memory x, uint8[] memory y) external returns (uint256) {

    //     require(IERC721(_contractAddress).ownerOf(tokenId) == msg.sender, "You are not the owner of this token");
    //     require(x.length == 8 && y.length == 8, "Array sizes not 8");

    //     coordinates.push(Coords({x: x[0], y: y[0]}));
    //     coordinates.push(Coords({x: x[1], y: y[1]}));
    //     coordinates.push(Coords({x: x[2], y: y[2]}));
    //     coordinates.push(Coords({x: x[3], y: y[3]}));
    //     coordinates.push(Coords({x: x[4], y: y[4]}));
    //     coordinates.push(Coords({x: x[5], y: y[5]}));
    //     coordinates.push(Coords({x: x[6], y: y[6]}));
    //     coordinates.push(Coords({x: x[7], y: y[7]}));

    //     return coordinates.length;
    // }

    // function setLargeCoordinates(uint256 x, uint256 y) external returns (uint256) {
    //     _x = x;
    //     _y = y;
    //     return coordinates.length;
    // }

    // function setSmallCoordinates(uint16 x, uint16 y) external returns (uint256) {
    //     _x16 = x;
    //     _y16 = y;
    //     return coordinates.length;
    // }

    function addPair(uint32 z) external returns (uint256) {
        uint16 count = coordinates[z];
        return _setPair(z, count + 1);
    }

    function setSinglePair(uint32 z) external returns (uint256) {
        return _setPair(z, 1);
    }

    function setAllPairs(uint32[] calldata z, uint16[] calldata n) external returns (uint256) {
        require(z.length == n.length, "z and n must be equal length");

        for (uint i = 0; i < z.length; i++) {
            _setPair(z[i], n[i]);
        }
        
        return _count;
    }

    function setPairs(uint32[] calldata z, uint16[] calldata n) external returns (uint256) {
        require(z.length == 8 && n.length == 8, "z and n must be 8 elements long");
        _setPair(z[0], n[0]);
        _setPair(z[1], n[1]);
        _setPair(z[2], n[2]);
        _setPair(z[3], n[3]);
        _setPair(z[4], n[4]);
        _setPair(z[5], n[5]);
        _setPair(z[6], n[6]);
        _setPair(z[7], n[7]);

        return _count;
    }

    function setSmallCoordinates(uint16 x, uint16 y, uint16 n) external returns (uint256) {
        require(n > 0, "n must be greater than 0");
        uint32 z = pair(x, y);

        return _setPair(z, n);
    }

    function setPair(uint32 z, uint16 n) external returns (uint256) {
        return _setPair(z, n);
    }


    function _setPair(uint32 z, uint16 n) private returns (uint256) {
        require(n > 0, "n must be greater than 0");
        coordinates[z] = n;
        _count++;
        return _count;
    }

    // function setByteCoordinates(bytes1 x, bytes1 y) external returns (uint256) {
    //     _x1 = x;
    //     _y1 = y;
    //     return coordinates.length;
    // }

    // function set8Coordinates(uint8[] memory x, uint8[] memory y) external returns (uint256) {
    //     require(x.length == y.length, "Array sizes not the same");

    //     for (uint256 i = 0; i < x.length; i++) {
    //         coordinates.push(Coords(x[i], y[i]));
    //     }

    //     return coordinates.length;
    // }

    // function set8CoordinatesToAMap(uint16 x, uint16[] memory y) external returns (uint256) {
    //     require(y.length == 8, "Array sizes not 8");

    //     _coords[x] = y;
    //     return _coords[x].length;
    // }

    // function setCoordinates(uint8 x, uint8 y) external returns (uint256) {
    //     coordinates.push(Coords({x: x, y: y}));
    //     return coordinates.length;
    // }

    function getCoordinate(uint32 z) public view returns (uint16 x, uint16 y, uint32 n) {
        n = coordinates[z];
        (x, y) = unpair(z);
    }

    function pair(uint16 x, uint16 y) public pure returns (uint32) {
        uint32 z = x + y;
        uint32 z1 = z + 1;
        return ((z1 * z) / 2) + y;
    }

    function unpair(uint32 z) public pure returns (uint16, uint16) {
        // uint32 z = x + y;
        // uint32 z1 = z + 1;
        // return ((z1 * z) / 2) + y;

        uint32 z1 = 8 * z;
        uint32 z2 = 11456 + 1;
        // √11457 = 107.037,
        // 107.037 − 1 = 106.037,
        // 106.037 ÷ 2 = 53.019,
        // ⌊53.019⌋ = 53,

        return (0, 0);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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
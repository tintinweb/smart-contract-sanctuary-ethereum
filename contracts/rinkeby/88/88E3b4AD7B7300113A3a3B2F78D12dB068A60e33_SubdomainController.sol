//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./interfaces.sol";

import "./registrant.sol";
import "./metadata.sol";
import "./resolver.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

contract SubdomainController is Ownable, IERC721, ERC165, IERC721Metadata{

    iRegistrant Registrant;
    iMetadata MetadataProvider;
    iResolver Resolver;

    constructor () {
        Registrant = new Registrant_v1();
        MetadataProvider = new Metadata_v1();
        Resolver = new Resolver_v1();

        emit Transfer(msg.sender, address(0), 1);
    }


    function setResolver(address _addr) public onlyOwner {
        Resolver = iResolver(_addr);
    }

    function setRegistrant(address _addr) public onlyOwner {
        Registrant = iRegistrant(_addr);
    }

    function setMetadata(address _addr) public onlyOwner {
        MetadataProvider = iMetadata(_addr);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public {

    }

    function tokenURI(uint256 tokenId) external view returns (string memory)
    {
        return MetadataProvider.metadata("testing");
    }

    function symbol() external view returns (string memory){
        return "";
    }

    function name() external view returns (string memory){
        return "";
    }

    function setApprovalForAll(address operator, bool _approved) external{
        require(false, "cannot be transferred");
    }

    function getApproved(uint256 tokenId) external view returns (address operator){
        require(false, "cannot be transferred");
        return address(0);
    }

    function isApprovedForAll(address owner, address operator) external view returns (bool){
        return false;
    }

    function approve(address to, uint256 tokenId) external{
        require(false, "cannot be transferred");
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public {

    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) public {

    }

    function ownerOf(uint256 tokenId) public view returns (address _owner) {
        return address(0);
    }

    function balanceOf(address owner) external view returns (uint256 balance){
        return 0;
    }

 

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


interface iResolver {

}

interface iMapper {

}

interface iRegistrant {

}

interface iMetadata {
    
    function metadata(string calldata _name) external view returns(string memory);

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./interfaces.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Registrant_v1 is iRegistrant {

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import './interfaces.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Metadata_v1 is iMetadata {

string image = "<?xml version='1.0' standalone='no'?> <!DOCTYPE svg PUBLIC '-//W3C//DTD SVG 20010904//EN' 'http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd'> <svg xmlns='http://www.w3.org/2000/svg' version='1.0' width='225pt' height='225pt' viewBox='0 0 225 225' preserveAspectRatio='xMidYMid meet'><g transform='translate(0,225) scale(0.1,-0.1)' fill='#000000' stroke='none'><path d='M1078 2223 c12 -2 32 -2 45 0 12 2 2 4 -23 4 -25 0 -35 -2 -22 -4z'/><path d='M973 2213 c15 -2 37 -2 50 0 12 2 0 4 -28 4 -27 0 -38 -2 -22 -4z'/><path d='M1220 2210 c181 -23 383 -105 521 -209 228 -173 378 -434 418 -726 l10 -70 -4 70 c-12 186 -106 404 -247 572 -171 205 -454 354 -698 368 l-75 4 75 -9z'/><path d='M823 2190 c-221 -58 -438 -202 -576 -382 -144 -189 -215 -391 -222 -633 l-4 -120 9 120 c21 290 110 508 284 692 163 173 336 275 550 323 44 10 70 18 56 19 -14 0 -57 -9 -97 -19z'/><path d='M1020 2194 c-14 -2 -58 -9 -98 -15 -214 -31 -415 -140 -580 -314 -190 -199 -284 -437 -284 -715 0 -278 94 -516 284 -715 273 -288 650 -395 1033 -294 291 76 543 290 674 571 244 523 16 1141 -512 1388 -154 72 -382 113 -517 94z m702 -480 c-2 -12 6 -37 16 -55 11 -19 25 -51 32 -71 8 -27 26 -48 63 -74 71 -51 107 -85 107 -101 0 -8 12 -25 27 -38 27 -23 28 -23 9 -44 -14 -16 -31 -21 -67 -21 -47 0 -48 -1 -58 -37 -6 -21 -11 -50 -11 -64 0 -19 -24 -49 -94 -118 l-95 -92 -32 16 c-26 14 -33 14 -40 4 -5 -8 -2 -20 7 -30 7 -8 14 -23 14 -32 0 -18 -42 -33 -59 -22 -13 7 -13 1 -15 -117 -1 -92 -7 -108 -34 -92 -13 9 -18 29 -20 99 -2 69 -7 93 -22 113 -15 18 -20 40 -20 81 l0 56 -30 -52 c-31 -54 -70 -77 -92 -55 -15 15 -2 42 20 42 12 0 35 26 66 75 43 68 89 115 113 115 5 0 16 -14 24 -32 9 -20 31 -41 61 -57 l47 -26 61 60 c33 33 60 63 60 67 0 18 -48 6 -70 -17 -12 -13 -27 -22 -32 -19 -4 3 -22 -6 -39 -20 -17 -14 -35 -26 -40 -26 -19 0 -7 23 39 78 26 31 55 66 62 76 14 18 14 19 -10 6 -14 -7 -51 -30 -82 -51 -87 -59 -86 -30 2 54 l73 69 -26 26 -26 25 -38 -25 c-21 -14 -78 -60 -128 -102 -49 -42 -95 -76 -102 -76 -36 0 8 50 122 140 147 114 208 190 155 190 -12 0 -26 -12 -35 -30 -9 -16 -20 -30 -25 -30 -16 0 -11 30 9 58 10 15 24 38 31 51 11 22 8 21 -34 -10 -107 -79 -139 -99 -148 -93 -11 7 -24 -8 -84 -100 -35 -52 -48 -66 -57 -57 -18 18 32 104 122 207 94 108 145 154 171 154 32 0 23 -25 -18 -53 -50 -35 -126 -114 -93 -97 13 7 42 29 65 49 23 20 53 45 69 54 23 15 26 21 17 37 -9 17 -6 23 22 40 44 27 94 24 90 -6z m-573 -313 c-1 -14 4 -50 10 -80 9 -45 9 -58 -4 -78 -29 -44 -59 -16 -53 52 2 25 0 45 -3 45 -19 0 -59 -45 -59 -66 0 -14 -5 -34 -10 -45 -12 -21 -1 -26 18 -7 19 19 27 -1 12 -27 -20 -32 -140 -155 -152 -155 -11 0 -2 17 25 48 11 12 16 22 10 22 -6 0 -18 -11 -27 -25 -17 -25 -36 -33 -36 -15 0 6 36 68 80 137 44 70 78 129 75 131 -10 10 -74 -41 -85 -68 -7 -16 -18 -35 -26 -41 -11 -9 -14 -7 -14 12 -1 24 -1 24 -26 -6 -14 -16 -61 -76 -105 -132 -71 -91 -109 -124 -109 -93 0 18 103 230 111 230 14 0 10 -38 -7 -73 -14 -29 -11 -27 24 13 36 41 38 46 21 52 -22 9 -25 36 -5 63 15 21 46 14 46 -10 0 -19 14 -19 30 0 7 9 19 14 26 11 7 -3 18 2 26 11 7 9 51 45 98 79 90 66 111 69 109 15z m111 -100 c0 -42 -189 -214 -257 -235 -29 -9 -39 11 -16 36 31 35 91 79 114 83 29 6 82 48 121 95 17 22 33 40 35 40 2 0 3 -9 3 -19z m20 -52 c-30 -27 -58 -49 -62 -49 -17 0 -6 17 42 69 40 44 53 52 63 42 10 -10 1 -23 -43 -62z m-634 -26 c19 -29 39 -53 45 -53 6 0 9 -14 7 -32 -2 -25 -10 -36 -31 -46 -30 -15 -70 -70 -60 -84 3 -5 13 -2 24 8 17 16 19 16 25 0 13 -34 -140 -197 -174 -185 -6 2 14 48 45 102 37 65 57 113 61 144 3 33 2 44 -7 39 -6 -4 -11 -13 -11 -21 0 -20 -41 -127 -46 -122 -3 2 2 44 11 92 21 122 19 130 -16 50 -37 -88 -57 -115 -68 -97 -6 10 -21 -5 -54 -50 -25 -35 -52 -70 -61 -77 -14 -12 -16 -10 -16 8 0 18 -3 20 -19 11 -29 -15 -67 -12 -82 6 -11 14 -10 18 6 30 22 16 80 34 112 34 26 0 32 6 84 88 22 34 46 62 52 62 7 0 23 20 36 45 13 25 29 44 36 41 7 -2 16 15 23 41 11 39 14 43 28 32 9 -7 31 -37 50 -66z m714 -53 c0 -14 -55 -40 -86 -40 -23 0 -25 2 -13 16 24 29 99 47 99 24z m-514 -95 c-6 -28 -4 -35 9 -35 8 0 15 -7 15 -15 0 -21 -80 -94 -96 -88 -22 8 -138 -84 -144 -114 -7 -36 -97 -95 -111 -72 -22 36 -10 56 68 109 101 69 213 158 213 171 0 5 7 25 14 44 20 47 40 46 32 0z m311 23 c24 -30 92 -203 84 -211 -12 -12 -77 71 -116 146 -26 49 -28 59 -15 67 20 13 36 12 47 -2z m-70 -68 c-16 -42 -122 -125 -156 -122 -18 1 -45 -13 -86 -46 -71 -57 -105 -78 -105 -62 0 24 184 165 229 175 15 3 47 26 71 50 48 49 64 51 47 5z m331 -248 c3 -110 2 -113 -17 -103 -11 6 -28 11 -39 11 -38 0 -84 109 -63 149 16 29 30 27 41 -6 20 -56 25 -63 38 -55 9 6 10 21 3 57 -10 55 -7 68 17 63 14 -3 17 -20 20 -116z m199 31 c6 -16 -37 -63 -58 -63 -21 0 -21 32 1 56 27 28 48 31 57 7z m271 -82 c3 -21 8 -23 38 -18 29 5 35 3 32 -11 -2 -11 -15 -18 -38 -20 -50 -5 -60 -19 -30 -42 19 -14 22 -22 14 -30 -9 -9 -26 -3 -68 24 -31 20 -56 38 -56 41 0 3 11 24 26 46 20 33 30 40 52 37 20 -2 28 -9 30 -27z m-1498 -8 c23 -30 23 -68 0 -68 -8 0 -14 6 -12 14 6 27 -9 51 -32 51 -52 0 -73 -75 -24 -82 31 -4 35 -28 5 -28 -29 0 -67 41 -67 72 0 10 11 30 25 43 33 34 77 33 105 -2z m25 -139 c-27 -24 -54 -43 -59 -41 -22 7 -12 24 37 65 36 30 54 39 61 31 8 -8 -4 -24 -39 -55z m1365 60 c0 -3 -12 -20 -26 -36 -18 -22 -22 -34 -14 -42 8 -8 17 -2 34 18 14 19 27 26 35 22 9 -6 6 -15 -13 -35 -20 -21 -23 -30 -14 -39 9 -9 19 -5 44 19 46 44 53 19 8 -30 -40 -45 -41 -45 -103 12 l-42 38 33 39 c29 34 58 51 58 34z m-1244 -85 c41 -39 54 -59 54 -80 0 -27 2 -28 27 -18 29 11 58 5 48 -10 -3 -5 -22 -15 -42 -22 -21 -7 -46 -23 -57 -36 -26 -33 -46 -14 -22 21 9 14 16 42 16 63 0 32 -5 40 -28 51 -25 12 -29 11 -64 -26 -26 -29 -39 -37 -47 -29 -8 8 0 23 29 52 36 37 39 43 25 55 -8 7 -15 16 -15 21 0 20 24 6 76 -42z m1179 -54 c35 -34 32 -70 -7 -106 -18 -16 -36 -29 -39 -29 -4 0 -26 23 -49 52 l-41 52 33 28 c41 34 72 35 103 3z m-186 -102 c7 -16 18 -36 26 -46 12 -17 15 -17 44 -3 36 19 41 20 41 4 0 -15 -78 -60 -91 -53 -13 9 -67 114 -61 120 13 12 30 3 41 -22z m-730 -8 c46 -23 55 -76 21 -113 -26 -28 -69 -28 -104 -1 -34 27 -35 71 -1 104 28 29 45 31 84 10z m684 -49 c23 -67 5 -96 -59 -96 -25 0 -46 25 -65 79 -9 27 -9 35 2 42 11 6 19 -4 33 -41 15 -41 23 -50 42 -50 29 0 31 23 9 77 -12 29 -13 38 -3 44 17 11 22 3 41 -55z m-503 -12 c0 -11 -10 -13 -40 -8 -32 5 -40 3 -40 -8 0 -9 13 -18 30 -21 43 -9 39 -31 -4 -24 -32 5 -35 3 -41 -24 -4 -17 -12 -28 -18 -26 -13 5 -12 52 3 108 l10 36 50 -10 c31 -6 50 -15 50 -23z m342 -1 c23 -20 24 -80 1 -105 -16 -18 -77 -25 -99 -10 -14 9 -34 47 -34 65 0 8 9 26 21 41 24 31 81 36 111 9z m-158 -9 c19 -18 20 -30 6 -39 -8 -5 -7 -11 0 -20 6 -8 10 -24 8 -37 -3 -21 -9 -23 -65 -26 l-63 -3 0 64 c0 35 3 67 7 70 13 14 92 7 107 -9z'/><path d='M1830 710 c-11 -20 -6 -40 9 -40 11 0 31 47 24 54 -11 11 -22 6 -33 -14z'/><path d='M1631 487 c-8 -10 -4 -22 18 -47 25 -30 31 -33 45 -21 21 18 20 44 -2 64 -22 20 -46 22 -61 4z'/><path d='M733 354 c-21 -33 -7 -59 33 -59 22 0 31 6 38 27 19 54 -39 80 -71 32z'/><path d='M1248 319 c-25 -14 -24 -65 2 -79 45 -24 82 37 44 74 -18 19 -23 19 -46 5z'/><path d='M1090 295 c0 -9 9 -15 25 -15 16 0 25 6 25 15 0 9 -9 15 -25 15 -16 0 -25 -6 -25 -15z'/><path d='M1090 240 c0 -17 5 -21 28 -18 16 2 27 9 27 18 0 9 -11 16 -27 18 -23 3 -28 -1 -28 -18z'/><path d='M2173 1150 c0 -30 2 -43 4 -27 2 15 2 39 0 55 -2 15 -4 2 -4 -28z'/><path d='M2157 1017 c-4 -40 -17 -111 -31 -157 -107 -368 -393 -648 -764 -747 -86 -23 -116 -26 -262 -26 -146 0 -176 3 -262 26 -105 28 -231 83 -319 139 -245 157 -422 425 -474 720 -13 75 -14 77 -9 21 11 -131 83 -319 174 -453 208 -307 577 -488 950 -467 457 26 848 340 975 782 23 82 45 235 33 235 -3 0 -8 -33 -11 -73z'/></g></svg>";


function metadata(string calldata _name) external view returns(string memory){

    return string(abi.encodePacked('data:application/json;ascii,{"name: "',_name,'","description": "None-transferable boulder.eth sub-domain","image":"data:image/svg+xml;utf8,', image, '}'));
}



}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./interfaces.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Resolver_v1 is iResolver {

}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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

// SPDX-License-Identifier: MIT

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
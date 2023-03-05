// license: UNLICENSED

pragma solidity ^0.8.17;

import "./IERC20.sol";
import "./ISBT.sol";
import "./hackyAOS/IhackyAOS.sol";



contract verifier {

    ISBT _sbt;
    IHackyAOSRing _checkRingSig;

    constructor(address sbt, address checkRingSig) {
        _sbt = ISBT(sbt);
        _checkRingSig = IHackyAOSRing(checkRingSig);
    }


    /**
    * @notice verify a ring signature, check balances of the provided value and mint an sbt if it is valid
    * @param addresses the addresses of the ring (length must be even) (addresses = [key1-x, key1-y, key2-x, key2-y, ..., keyN-x, keyN-y])
    * @param tees the tees of the ring (length must be addresses.length/2) (tees = [tee1, tee2, ..., teeN])
    * @param seed the seed of the ring
    * @param value the value to check -> balance of each address must be >= value
    * @param publicAddress the address that has been signed by the ring
    * @param token the token we check the balance of. Null address if we check the balance of the native token
    * @param addressesURI the URI of the addresses on IPFS
    * @param verifierData is a string which could be used id the verifier wants to be sure that the sbt has been minted for him (example : his address or somethings he asked the prover to write)
    */
    function verify(uint256[] memory addresses, uint256[] memory tees, uint256 seed, uint256 value, address publicAddress, address token, string memory addressesURI, string memory verifierData) public {
        require(addresses.length % 2 == 0 && tees.length == addresses.length / 2, "Invalid Arguments");
        // verify if the message is valid -> int(eth address of the msg.sender) == message
        require(msg.sender == publicAddress, "Invalid message");
        uint256 message = uint256(uint160(msg.sender));
        // verify the ring signature
        require(_checkRingSig.Verify(addresses, tees, seed, message), "Invalid ring signature"); // c'est quoi tees et seed ?
        
        if(token == address(0)){
            for (uint i = 0; i < addresses.length; i+=2) {
                require(pointsToAddress([addresses[i],addresses[i+1]]).balance >= value, "Insufficient balance in at least one address");
            }
        }
        else{
            for (uint i = 0; i < addresses.length; i+=2) {
                require(IERC20(token).balanceOf(pointsToAddress([addresses[i],addresses[i+1]])) >= value, "Insufficient balance in at least one address");
            }
        }

        bytes32 root = buildRoot(addresses); // build merkle root to save in sbt

        // mint sbt
        _sbt.mint(msg.sender, token, value, addressesURI, root, message, verifierData);        
    }



    // merkle tree functions

    /**
    * @notice build root from a list of addresses
    * @param addresses the addresses to build the merkle tree from
    */
    function buildRoot(uint256[] memory addresses) public pure returns (bytes32) {
        bytes32[] memory leaves = new bytes32[](addresses.length);
        for (uint i = 0; i < addresses.length; i++) {
            leaves[i] = keccak256(abi.encodePacked(addresses[i]));
        }
        return buildRootFromLeaves(leaves);
    }

    /**
    * @notice build root from a list of leaves
    * @param leaves the leaves to build the merkle tree from
    */
    function buildRootFromLeaves(bytes32[] memory leaves) private pure returns (bytes32) {
        if (leaves.length == 0) {
            return 0x0;
        }
        if (leaves.length == 1) {
            return leaves[0];
        }
        if (leaves.length % 2 == 1) {
            bytes32[] memory tmp = new bytes32[](leaves.length + 1);
            for (uint i = 0; i < leaves.length; i++) {
                tmp[i] = leaves[i];
            }
            tmp[leaves.length] = leaves[leaves.length - 1];
            leaves = tmp;
        }
        bytes32[] memory parents = new bytes32[](leaves.length / 2);
        for (uint i = 0; i < leaves.length; i += 2) {
            parents[i / 2] = keccak256(abi.encodePacked(leaves[i], leaves[i + 1]));
        }
        return buildRootFromLeaves(parents);
    }

    /**
    * @notice check if a merkle root is valid
    * @param root the root to check
    * @param addresses the addresses to check the root against
    */
    function verifyRoot(bytes32 root, uint256[] memory addresses) public pure returns (bool) {
        return buildRoot(addresses) == root;
    }


    /**
    * @notice convert a point from SECP256k1 to an ethereum address
    * @param points the point to convert -> [x,y]
    */
    function pointsToAddress(uint256[2] memory points) public pure returns (address) {
        // convert uint256[2] to hex string
        bytes32 x = bytes32(points[0]);
        bytes32 y = bytes32(points[1]);
        bytes memory public_key = abi.encodePacked(x, y);
        bytes32 hash = keccak256(public_key);
        address ethereum_address = address(uint160(uint256(hash)));

        return ethereum_address;
    }
}

pragma solidity ^0.8.17;


interface IHackyAOSRing{  

	function Verify( uint256[] memory addresses, uint256[] memory tees, uint256 seed, uint256 message ) external pure returns (bool);
	
}

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ISBT is IERC721 {

    // get sbt data 

    /**
    * @notice delete all the caracteristics of tokenId (burn)
    * @param tokenId is the id of the sbt to burn
    */
    function burn(uint256 tokenId) external;

    /**
    * @notice mint a new sbt with the given caracteristics (only minters can call it)
    * @param receiver is the address of the receiver of the sbt
    * @param token is the address of the token that is linked to the sbt
    * @param value is the value the contract has verified
    * @param tokenURI is the uri where we can get the addresses used to generate the proof (stored on ipfs)
    * @param merkleRoot is the merkle root of the addresses (to ensure that the addresses have not been modified)
    * @param signature is the zk proof generated in the frontend (which has been verified by the verifier)
    * @param verifier is a string which could be used id the verifier wants to be sure that the sbt has been minted for him (example : his address or somethings he asked the prover to write)
    */
    function mint(address receiver, address token, uint256 value, string memory tokenURI, bytes32 merkleRoot, uint256 signature, string memory verifier) external;

    // admin functions
    /**
    * @notice set or unset admin
    * @param admin is the address of the admin to add/remove
    * @param isAdmin is true if the admin is added, false if the admin is removed
    */
    function editAdmin(address admin, bool isAdmin) external;

    /**
    * @notice set or unset minter
    * @param minter is the address of the minter to add/remove
    * @param isMinter is true if the minter is added, false if the minter is removed
    */
    function editMinter(address minter, bool isMinter) external;

    /**
    * @notice set or unset burner
    * @param burner is the address of the burner to add/remove
    * @param isBurner is true if the burner is added, false if the burner is removed
    */
    function editBurner(address burner, bool isBurner) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.17;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
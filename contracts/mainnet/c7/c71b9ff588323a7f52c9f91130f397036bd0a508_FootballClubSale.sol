// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import {IFootballClub} from "./interfaces/IFootballClub.sol";

contract FootballClubSale is Ownable {
    using Address for address;

    IFootballClub public footballClub;

    uint256 private price = 0.05 ether;
    uint256 public clubsClaimed;

    uint256 internal constant MINT_LIMIT = 3060;

    uint256 private constant PHASE_1_TIMESTAMP = 1636999200;
    uint256 private constant PHASE_2_TIMESTAMP = 1637172000;
    uint256 private constant PHASE_3_TIMESTAMP = 1637344800;

    bytes32 internal whitelistMerkleRootPhase1;
    bytes32 internal whitelistMerkleRootPhase2;
    bytes32 internal advisorMerkleRoot;
    bytes32 public metadataMerkleRoot;

    event Withdraw(bool indexed sent, bytes data);

    mapping(bytes32 => mapping(address => uint256)) public redemptions;

    constructor(
        IFootballClub _footballClub,
        bytes32 _whitelistMerkleRootPhase1,
        bytes32 _whitelistMerkleRootPhase2,
        bytes32 _advisorMerkleRoot,
        bytes32 _metadataMerkleRoot,
        uint256 _advisorAllocation
    ) {
        footballClub = _footballClub;
        whitelistMerkleRootPhase1 = _whitelistMerkleRootPhase1;
        whitelistMerkleRootPhase2 = _whitelistMerkleRootPhase2;
        advisorMerkleRoot = _advisorMerkleRoot;
        metadataMerkleRoot = _metadataMerkleRoot;

        clubsClaimed = _advisorAllocation;
    }

    function preMint(uint256 _tokenId, bytes32[] calldata proof) external {
        require(_tokenId >= 1 && _tokenId <= 213, "Must be the correct token range");
        require(
            _advisorVerify(_advisorLeaf(_tokenId, msg.sender), proof),
            "must be on the advisor whitelist"
        );

        footballClub.safeMint(msg.sender, _tokenId);
    }

    function _advisorVerify(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, advisorMerkleRoot, leaf);
    }

    function _advisorLeaf(uint256 _tokenId, address account)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_tokenId, account));
    }

    function _leaf(address account, uint256 amount)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, amount));
    }

    //need to check to ensure hasn't already minted
    //map address to an integer - i.e. how many times has this address been minted for this phase
    //pass in a dummy proof for the first stage
    function redeem(
        uint256 _amount,
        uint256 _maxAmount,
        bytes32[] calldata proof
    ) external payable {
        require(msg.value >= _amount * price, "Insufficient payment");
        require(_amount <= 50, "Incorrect amount");
        require(_maxAmount > 0 && _maxAmount <= 50, "Incorrect max amount");

        bytes32 whitelistMerkleRoot;

        require(block.timestamp >= PHASE_1_TIMESTAMP, "whitelist not started");

        if (block.timestamp < PHASE_2_TIMESTAMP) {
            whitelistMerkleRoot = whitelistMerkleRootPhase1;
        } else if (block.timestamp < PHASE_3_TIMESTAMP) {
            whitelistMerkleRoot = whitelistMerkleRootPhase2;
        } else {
            for (uint256 i = 0; i < _amount; i++) {
                require(clubsClaimed < MINT_LIMIT, "Cannot mint past limit");

                clubsClaimed++;

                footballClub.safeMint(msg.sender, clubsClaimed);
            }

            return;
        }

        bool status = MerkleProof.verify(
            proof,
            whitelistMerkleRoot,
            _leaf(msg.sender, _maxAmount)
        );

        require(status, "Proof is invalid");

        for (uint256 i = 0; i < _amount; i++) {
            require(clubsClaimed < MINT_LIMIT, "Cannot mint past limit");
            require(
                redemptions[whitelistMerkleRoot][msg.sender] < _maxAmount,
                "Cannot mint more than alloted"
            );

            redemptions[whitelistMerkleRoot][msg.sender]++;
            clubsClaimed++;

            footballClub.safeMint(msg.sender, clubsClaimed);
        }
    }

    function verifyMetadata(bytes32 leaf, bytes32[] memory proof)
        public
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, metadataMerkleRoot, leaf);
    }

    function withdraw() external onlyOwner {
        address payable owner = payable(owner());

        (bool sent, bytes memory data) = owner.call{
            value: address(this).balance
        }("");
        emit Withdraw(sent, data);
    }

    function setWhitelistMerkleRootPhase1(bytes32 _merkleRoot)
        external
        onlyOwner
    {
        whitelistMerkleRootPhase1 = _merkleRoot;
    }

    function setWhitelistMerkleRootPhase2(bytes32 _merkleRoot)
        external
        onlyOwner
    {
        whitelistMerkleRootPhase2 = _merkleRoot;
    }

    function setAdvisorMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        advisorMerkleRoot = _merkleRoot;
    }
}

pragma solidity ^0.8.0;

interface IFootballClub {
    function safeMint(address, uint256) external;

    function pause() external;

    function unpause() external;

    function tokenURI() external view;

    function supportsInterface(bytes4) external view;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
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
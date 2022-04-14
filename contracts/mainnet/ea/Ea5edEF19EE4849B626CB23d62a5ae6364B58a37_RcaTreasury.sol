/// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;
import "../general/Governable.sol";
import "../library/MerkleProof.sol";

/**
 * @title RCA Treasury
 * @notice This contract holds all Ether funds from both liquidated tokens
 * and fees that are taken for the operation of the ecosystem.
 * It also functions as the contract to claim losses from when a hack occurs.
 * @author Robert M.C. Forster
 */
contract RcaTreasury is Governable {
    // Amount of claims available for individual addresses (in Ether).
    // ID of hack => amount claimable.
    mapping(uint256 => bytes32) public claimsRoots;
    // address => id of hack => claimed.
    mapping(address => mapping(uint256 => bool)) public claimed;

    event Claim(address indexed user, uint256 indexed hackId, uint256 indexed etherAmount);
    event Root(uint256 indexed coverId, bytes32 root);

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////// constructor ////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Constructor just used to set governor that can withdraw funds from the contract.
     * @param _governor Full owner of this contract.
     */
    constructor(address _governor) {
        initializeGovernable(_governor);
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////// fallback //////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Just here to accept Ether.
     */
    receive() external payable {}

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////// external //////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Users claim directly from here for loss in any vault.
     * @param _user Address of the user to claim for.
     * @param _loss The amount of loss (in Ether) that the protocol is paying.
     * @param _hackId ID given to the hack that resulted in this loss.
     * @param _claimsProof Merkle proof to verify this user's claim.
     */
    function claimFor(
        address payable _user,
        uint256 _loss,
        uint256 _hackId,
        bytes32[] calldata _claimsProof
    ) external {
        require(!claimed[_user][_hackId], "Loss has already been claimed.");
        verifyClaim(_user, _hackId, _loss, _claimsProof);
        claimed[_user][_hackId] = true;
        _user.transfer(_loss);
        emit Claim(_user, _hackId, _loss);
    }

    // capacity available function
    function verifyClaim(
        address _user,
        uint256 _hackId,
        uint256 _amount,
        bytes32[] memory _claimsProof
    ) public view {
        bytes32 leaf = keccak256(abi.encodePacked(_user, _hackId, _amount));
        require(MerkleProof.verify(_claimsProof, claimsRoots[_hackId], leaf), "Incorrect capacity proof.");
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////// onlyGov //////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Governance sends in hack ID and a Merkle root corresponding to individual loss in this hack.
     * @param _hackId ID of the hack that this root is for. (Assigned by our protocol).
     * @param _newClaimsRoot Merkle root for new capacities available for each protocol (in USD).
     */
    function setClaimsRoot(uint256 _hackId, bytes32 _newClaimsRoot) external onlyGov {
        claimsRoots[_hackId] = _newClaimsRoot;
        emit Root(_hackId, _newClaimsRoot);
    }

    /**
     * @notice Governance may withdraw any amount to any address.
     * @param _to Address to send funds to.
     * @param _amount Amount of funds (in Ether) to send.
     */
    function withdraw(address payable _to, uint256 _amount) external onlyGov {
        _to.transfer(_amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title Governable
 * @dev Pretty default ownable but with variable names changed to better convey owner.
 */
contract Governable {
    address payable private _governor;
    address payable private _pendingGovernor;

    event OwnershipTransferred(address indexed previousGovernor, address indexed newGovernor);
    event PendingOwnershipTransfer(address indexed from, address indexed to);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function initializeGovernable(address _newGovernor) internal {
        require(_governor == address(0), "already initialized");
        _governor = payable(_newGovernor);
        emit OwnershipTransferred(address(0), _newGovernor);
    }

    /**
     * @return the address of the owner.
     */
    function governor() public view returns (address payable) {
        return _governor;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyGov() {
        require(isGov(), "msg.sender is not owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isGov() public view returns (bool) {
        return msg.sender == _governor;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newGovernor The address to transfer ownership to.
     */
    function transferOwnership(address payable newGovernor) public onlyGov {
        _pendingGovernor = newGovernor;
        emit PendingOwnershipTransfer(_governor, newGovernor);
    }

    function receiveOwnership() public {
        require(msg.sender == _pendingGovernor, "Only pending governor can call this function");
        _transferOwnership(_pendingGovernor);
        _pendingGovernor = payable(address(0));
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newGovernor The address to transfer ownership to.
     */
    function _transferOwnership(address payable newGovernor) internal {
        require(newGovernor != address(0));
        emit OwnershipTransferred(_governor, newGovernor);
        _governor = newGovernor;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
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
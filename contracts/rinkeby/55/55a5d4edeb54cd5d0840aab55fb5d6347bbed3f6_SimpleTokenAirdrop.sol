// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "./Ownable.sol";
import {Pausable} from "./Pausable.sol";
import {ReentrancyGuard} from "./ReentrancyGuard.sol";
import {MerkleProof} from "./MerkleProof.sol";
import {IERC20} from "./IERC20.sol";

/**
 * @title SimpleTokenAirdrop
 * @notice It distributes SIMPLE tokens with a Merkle-tree airdrop.
 */
contract SimpleTokenAirdrop is Pausable, ReentrancyGuard, Ownable {

    address public simpleToken;
    bool public isMerkleRootSet;
    bytes32 public merkleRoot;
    uint256 public startTimestamp;
    uint256 public endTimestamp;

    mapping(address => bool) public hasClaimed;

    event AirdropRewardsClaim(address indexed user, uint256 amount);
    event MerkleRootSet(bytes32 merkleRoot);
    event NewStartTimestamp(uint256 startTimestamp);
    event NewEndTimestamp(uint256 endTimestamp);
    event TokensWithdrawn(uint256 amount);
    event NewSimpleToken(address simpleToken);

    /**
     * @notice Constructor
     * @param _startTimestamp start timestamp for claiming
     * @param _endTimestamp end timestamp for claiming
     * @param _simpleToken address of the SIMPLE token
     */
    constructor(uint256 _startTimestamp, uint256 _endTimestamp, address _simpleToken) {
        
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        simpleToken = _simpleToken;
    }

    /**
     * @notice Claim tokens for airdrop
     * @param amount amount to claim for the airdrop
     * @param merkleProof array containing the merkle proof
     */
    function claim(uint256 amount, bytes32[] calldata merkleProof) external whenNotPaused nonReentrant {
        
        require(isMerkleRootSet, "Airdrop: Merkle root not set");
        require(block.timestamp <= endTimestamp, "Airdrop: Too late to claim");
        require(startTimestamp <= block.timestamp, "Airdrop: Too early to claim");

        // Verify the user has claimed
        require(!hasClaimed[msg.sender], "Airdrop: Already claimed");

        // Compute the node and verify the merkle proof
        bytes32 node = keccak256(abi.encodePacked(msg.sender, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "Airdrop: Invalid proof");

        // Set as claimed
        hasClaimed[msg.sender] = true;

        // Transfer tokens
        IERC20(simpleToken).transfer(msg.sender, amount);

        emit AirdropRewardsClaim(msg.sender, amount);
    }

    /**
     * @notice Check whether it is possible to claim (it doesn't check orders)
     * @param user address of the user
     * @param amount amount to claim
     * @param merkleProof array containing the merkle proof
     */
    function canClaim(address user, uint256 amount, bytes32[] calldata merkleProof) external view returns (bool) {
        if (block.timestamp <= endTimestamp && startTimestamp <= block.timestamp) {
            // Compute the node and verify the merkle proof
            bytes32 node = keccak256(abi.encodePacked(user, amount));
            return MerkleProof.verify(merkleProof, merkleRoot, node);
        } else {
            return false;
        }
    }

    /**
     * @notice Pause airdrop
     */
    function pauseAirdrop() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @notice Set merkle root for airdrop
     * @param _merkleRoot merkle root
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        require(!isMerkleRootSet, "Owner: Merkle root already set");

        isMerkleRootSet = true;
        merkleRoot = _merkleRoot;

        emit MerkleRootSet(_merkleRoot);
    }

    /**
     * @notice Unpause airdrop
     */
    function unpauseAirdrop() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @notice Update end timestamp
     * @param newEndTimestamp new endtimestamp
     */
    function updateEndTimestamp(uint256 newEndTimestamp) external onlyOwner {
        endTimestamp = newEndTimestamp;

        emit NewEndTimestamp(newEndTimestamp);
    }

    /**
     * @notice Update start timestamp
     * @param newStartTimestamp new starttimestamp
     */
    function updateStartTimestamp(uint256 newStartTimestamp) external onlyOwner {
        startTimestamp = newStartTimestamp;

        emit NewStartTimestamp(newStartTimestamp);
    }

    /**
     * @notice Update airdrop token address
     * @param newTokenAddress new airdrop token address
     */
    function updateTokenAddress(address newTokenAddress) external onlyOwner {
        simpleToken = newTokenAddress;

        emit NewSimpleToken(newTokenAddress);
    }

    /**
     * @notice Transfer tokens back to owner
     */
    function withdrawTokenRewards() external onlyOwner {
        uint256 balanceToWithdraw = IERC20(simpleToken).balanceOf(address(this));
        IERC20(simpleToken).transfer(msg.sender, balanceToWithdraw);

        emit TokensWithdrawn(balanceToWithdraw);
    }

    //Emergency function to withdraw any tokens apes send into the contract
    function withdrawTokens(address _token, address _to, uint256 _amount) public onlyOwner {
        require(_token != simpleToken, "Inappropriate function use");
        IERC20 token = IERC20(_token);
        token.transfer(_to, _amount);
    }
}
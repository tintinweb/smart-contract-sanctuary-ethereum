// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.7;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./Strings.sol";
import "./IERC721.sol";

interface IBlubToken {
    function mintAdminContract(address account, uint256 amount) external;
}

contract BlubStaking is Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    // contract params
    address public deployer;
    IBlubToken public blubToken;

    // map to store which nonce has been used onchain
    mapping(uint256 => bool) public nonceIsUsed;

    // event to track which nonces have been used
    event Claimed(uint256 indexed nonce);

    uint256 public constant CLAIM_TIME_WINDOW = 1200; // 60*20

    /**
     * @dev Initializes the contract by setting blubToken
     */
    constructor(address blubTokenAddress, address deployerAddress) {
        blubToken = IBlubToken(blubTokenAddress);
        deployer = deployerAddress;
    }
    
    /**
     * @dev Sets contract parameters
     */
    function setParams(address blubTokenAddress, address deployerAddress) public onlyOwner {
        blubToken = IBlubToken(blubTokenAddress);
        deployer = deployerAddress;
    }

    /**
     * @dev Claim BLUB token accrued through virtual staking for multiple tokens
     */
    function claim(uint256 nonce, uint256 amount, uint256 timestamp, bytes calldata signature) public {
        string memory message = string(abi.encodePacked("|", Strings.toHexString(uint256(uint160(msg.sender)), 20), "|", nonce.toString(), "|", amount.toString(), "|", timestamp.toString()));
        bytes32 hashedMessage = keccak256(abi.encodePacked(message));
        address recoveredAddress = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedMessage)).recover(signature);
        require(recoveredAddress == deployer, "Unauthorized signature");

        require(nonceIsUsed[nonce] == false, "Replayed tx");
        nonceIsUsed[nonce] = true;

        require(block.timestamp < timestamp + CLAIM_TIME_WINDOW, "Claim too late");

        blubToken.mintAdminContract(msg.sender, amount);
        emit Claimed(nonce);
    }
}
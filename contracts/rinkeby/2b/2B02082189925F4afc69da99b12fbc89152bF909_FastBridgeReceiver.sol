// SPDX-License-Identifier: MIT

/**
 *  @authors: [@shalzz]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.0;

import "./interfaces/IFastBridgeReceiver.sol";

contract FastBridgeReceiver is IFastBridgeReceiver {
    address public governor;
    uint256 public claimDeposit;
    uint256 public challengeDuration;

    struct Claim {
        address bridger;
        uint256 claimedAt;
        uint256 claimDeposit;
        bool relayed;
    }

    // messageHash => Claim
    mapping(bytes32 => Claim) public claims;

    event ClaimMade(bytes32 messageHash, uint256 claimedAt);

    modifier onlyByGovernor() {
        require(governor == msg.sender, "Access not allowed: Governor only.");
        _;
    }

    constructor(
        address _governor,
        uint256 _claimDeposit,
        uint256 _challengeDuration
    ) {
        governor = _governor;
        claimDeposit = _claimDeposit;
        challengeDuration = _challengeDuration;
    }

    function claim(bytes32 _messageHash) external payable {
        require(msg.value >= claimDeposit, "Not enough claim deposit");
        require(claims[_messageHash].bridger == address(0), "Claimed already made");

        claims[_messageHash] = Claim({
            bridger: msg.sender,
            claimedAt: block.timestamp,
            claimDeposit: msg.value,
            relayed: false
        });

        emit ClaimMade(_messageHash, block.timestamp);
    }

    function verifyAndRelay(bytes32 _messageHash, bytes memory _encodedData) external {
        require(keccak256(_encodedData) == _messageHash, "Invalid hash");

        Claim storage claim = claims[_messageHash];
        require(claim.bridger != address(0), "Claim does not exist");
        require(claim.claimedAt + challengeDuration < block.timestamp, "Challenge period not over");
        require(claim.relayed == false, "Message already relayed");

        // Decode the receiver address from the data encoded by the IFastBridgeSender
        (address receiver, bytes memory data) = abi.decode(_encodedData, (address, bytes));
        (bool success, ) = address(receiver).call(data);
        require(success, "Failed to call contract");

        claim.relayed = true;
    }

    function withdrawClaimDeposit(bytes32 _messageHash) external {
        Claim storage claim = claims[_messageHash];
        require(claim.bridger != address(0), "Claim does not exist");
        require(claim.claimedAt + challengeDuration < block.timestamp, "Challenge period not over");

        uint256 amount = claim.claimDeposit;
        claim.claimDeposit = 0;
        payable(claim.bridger).send(amount);
    }

    function challenge() external {
        revert("Not Implemented");
    }

    //**** Governor functions ****//

    function setClaimDeposit(uint256 _claimDeposit) external onlyByGovernor {
        claimDeposit = _claimDeposit;
    }

    function setChallengePeriodDuration(uint256 _challengeDuration) external onlyByGovernor {
        challengeDuration = _challengeDuration;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFastBridgeReceiver {
    function claim(bytes32 _messageHash) external payable;

    function verifyAndRelay(bytes32 _messageHash, bytes memory _calldata) external;

    function withdrawClaimDeposit(bytes32 _messageHash) external;

    function claimDeposit() external view returns (uint256 amount);
}
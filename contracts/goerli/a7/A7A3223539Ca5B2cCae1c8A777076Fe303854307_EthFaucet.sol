// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Ownable } from "../access/Ownable.sol";

contract EthFaucet is Ownable {
    uint256 public CLAIM_AMOUNT = 0.1 ether;
    uint256 public CLAIM_PERIOD = 1 days;

    /// @notice address with last claim time
    mapping(address => uint256) public lastClaim;

    /// Events
    event Claimed(address indexed recipient);
    event Drained(address indexed recipient);

    function claim() external {
        address sender = msg.sender;
        require(canClaim(sender), "Has claimed in the last 24hours");

        // Claim Ether
        (bool sent, ) = sender.call{ value: CLAIM_AMOUNT }("");

        require(sent, "Failed dripping ETH");
        lastClaim[sender] = block.timestamp;

        emit Claimed(sender);
    }

    /**
     * @notice Allows owner to drain the contract
     * @param _recipient to send drained eth to
     */
    function drain(address _recipient) external onlyOwner {
        // Drain all Ether
        (bool sent, ) = _recipient.call{ value: address(this).balance }("");
        require(sent, "Failed draining ETH");

        emit Drained(_recipient);
    }

    /**
     * @notice Allows owner to update drip amounts
     * @param _claimAmount ETH to claim
     */
    function updateClaimAmount(uint256 _claimAmount) external onlyOwner {
        CLAIM_AMOUNT = _claimAmount;
    }

    /**
     * @notice Allows owner to update claim period
     * @param _claimPeriod ETH to claim
     */
    function updateClaimPeriod(uint256 _claimPeriod) external onlyOwner {
        CLAIM_PERIOD = _claimPeriod;
    }

    /**
     * @notice Returns true if a sender can claim
     * @param  _sender user last claimed
     * @return bool has claimed past 24hours
     */
    function canClaim(address _sender) public view returns (bool) {
        uint256 lastClaimTime = lastClaim[_sender];

        if (lastClaimTime > block.timestamp) {
            return false;
        }

        if (lastClaimTime <= 0) {
            return true;
        }

        return ((block.timestamp - lastClaimTime) >= CLAIM_PERIOD);
    }

    /// @notice Allows receiving ETH
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
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
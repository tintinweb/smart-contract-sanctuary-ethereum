// File: contracts/pangolin-token/Airdrop.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPNG {
    function balanceOf(address account) external view returns (uint);
    function transfer(address dst, uint rawAmount) external returns (bool);
}

/**
 *  Contract for administering the Airdrop of xPNG to PNG holders.
 *  Arbitrary amount PNG will be made available in the airdrop. After the
 *  Airdrop period is over, all unclaimed PNG will be transferred to the
 *  community treasury.
 */
contract Airdrop {
    address public immutable png;
    address public owner;
    address public whitelister;
    address public remainderDestination;

    // amount of PNG to transfer
    mapping (address => uint) public withdrawAmount;

    uint public totalAllocated;
    uint public airdropSupply;

    bool public claimingAllowed;

    /**
     * Initializes the contract. Sets token addresses, owner, and leftover token
     * destination. Claiming period is not enabled.
     *
     * @param png_ the PNG token contract address
     * @param owner_ the privileged contract owner
     * @param remainderDestination_ address to transfer remaining PNG to when
     *     claiming ends. Should be community treasury.
     */
    constructor(
        uint supply_,
        address png_,
        address owner_,
        address remainderDestination_
    ) {
        require(owner_ != address(0), 'Airdrop::Construct: invalid new owner');
        require(png_ != address(0), 'Airdrop::Construct: invalid png address');

        airdropSupply = supply_;
        png = png_;
        owner = owner_;
        remainderDestination = remainderDestination_;
    }

    /**
     * Changes the address that receives the remaining PNG at the end of the
     * claiming period. Can only be set by the contract owner.
     *
     * @param remainderDestination_ address to transfer remaining PNG to when
     *     claiming ends.
     */
    function setRemainderDestination(address remainderDestination_) external {
        require(
            msg.sender == owner,
            'Airdrop::setRemainderDestination: unauthorized'
        );
        remainderDestination = remainderDestination_;
    }

    /**
     * Changes the contract owner. Can only be set by the contract owner.
     *
     * @param owner_ new contract owner address
     */
    function setOwner(address owner_) external {
        require(owner_ != address(0), 'Airdrop::setOwner: invalid new owner');
        require(msg.sender == owner, 'Airdrop::setOwner: unauthorized');
        owner = owner_;
    }

    /**
     *  Optionally set a secondary address to manage whitelisting (e.g. a bot)
     */
    function setWhitelister(address addr) external {
        require(msg.sender == owner, 'Airdrop::setWhitelister: unauthorized');
        whitelister = addr;
    }

    function setAirdropSupply(uint supply) external {
        require(msg.sender == owner, 'Airdrop::setAirdropSupply: unauthorized');
        require(
            !claimingAllowed,
            'Airdrop::setAirdropSupply: claiming in session'
        );
        require(
            supply >= totalAllocated,
            'Airdrop::setAirdropSupply: supply less than total allocated'
        );
        airdropSupply = supply;
    }

    /**
     * Enable the claiming period and allow user to claim PNG. Before
     * activation, this contract must have a PNG balance equal to airdropSupply
     * All claimable PNG tokens must be whitelisted before claiming is enabled.
     * Only callable by the owner.
     */
    function allowClaiming() external {
        require(IPNG(png).balanceOf(
            address(this)) >= airdropSupply,
            'Airdrop::allowClaiming: incorrect PNG supply'
        );
        require(msg.sender == owner, 'Airdrop::allowClaiming: unauthorized');
        claimingAllowed = true;
        emit ClaimingAllowed();
    }

    /**
     * End the claiming period. All unclaimed PNG will be transferred to the address
     * specified by remainderDestination. Can only be called by the owner.
     */
    function endClaiming() external {
        require(msg.sender == owner, 'Airdrop::endClaiming: unauthorized');
        require(claimingAllowed, "Airdrop::endClaiming: Claiming not started");

        claimingAllowed = false;

        // Transfer remainder
        uint amount = IPNG(png).balanceOf(address(this));
        require(
            IPNG(png).transfer(remainderDestination, amount),
            'Airdrop::endClaiming: Transfer failed'
        );

        emit ClaimingOver();
    }

    /**
     * Withdraw your PNG. In order to qualify for a withdrawal, the
     * caller's address must be whitelisted. All PNG must be claimed at
     * once. Only the full amount can be claimed and only one claim is
     * allowed per user.
     */
    function claim() external {
        require(claimingAllowed, 'Airdrop::claim: Claiming is not allowed');
        require(
            withdrawAmount[msg.sender] > 0,
            'Airdrop::claim: No PNG to claim'
        );

        uint amountToClaim = withdrawAmount[msg.sender];
        withdrawAmount[msg.sender] = 0;

        require(
            IPNG(png).transfer(msg.sender, amountToClaim),
            'Airdrop::claim: Transfer failed'
        );

        emit PngClaimed(msg.sender, amountToClaim);
    }

    /**
     * Whitelist multiple addresses in one call.
     * All parameters are arrays. Each array must be the same length. Each index
     * corresponds to one (address, png) tuple. Callable by the owner or whitelister.
     */
    function whitelistAddresses(
        address[] memory addrs,
        uint[] memory pngOuts
    ) external {
        require(
            !claimingAllowed,
            'Airdrop::whitelistAddresses: claiming in session'
        );
        require(
            msg.sender == owner || msg.sender == whitelister,
            'Airdrop::whitelistAddresses: unauthorized'
        );
        require(
            addrs.length == pngOuts.length,
            'Airdrop::whitelistAddresses: incorrect array length'
        );
        for (uint i; i < addrs.length; ++i) {
            address addr = addrs[i];
            uint pngOut = pngOuts[i];
            totalAllocated = totalAllocated + pngOut - withdrawAmount[addr];
            withdrawAmount[addr] = pngOut;
        }
        require(
            totalAllocated <= airdropSupply,
            'Airdrop::whitelistAddresses: Exceeds PNG allocation'
        );
    }

    // Events
    event ClaimingAllowed();
    event ClaimingOver();
    event PngClaimed(address claimer, uint amount);
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../GasDaoTokenLock.sol";
import "../Ownable.sol";
import "../ERC20.sol";
import "../draft-ERC20Permit.sol";
import "../ERC20Votes.sol";
import "../MerkleProof.sol";

/**
 * @dev An ERC20 token for GasDao.
 *      Besides the addition of voting capabilities, we make a couple of customisations:
 *       - Airdrop claim functionality via `claimTokens`. At creation time the tokens that
 *         should be available for the airdrop are transferred to the token contract address;
 *         airdrop claims are made from this balance.
 */
contract GasDaoToken is ERC20, ERC20Permit, ERC20Votes, Ownable {
    bytes32 public merkleRoot;

    mapping(address=>bool) private claimed;

    event MerkleRootChanged(bytes32 merkleRoot);
    event Claim(address indexed claimant, uint256 amount);

    // total supply 1 trillion, 55% airdrop, 15% devs vested, remainder to timelock
    uint256 constant airdropSupply = 550000000000000085770152383000;
    uint256 constant devSupply = 150_000_000_000e18;
    uint256 constant timelockSupply = 1_000_000_000_000e18 - airdropSupply - devSupply;

    bool public vestStarted = false;

    uint256 public constant claimPeriodEnds = 1651363200; // may 1, 2022

    /**
     * @dev Constructor.
     * @param timelockAddress The address of the timelock.
     */
    constructor(
        address timelockAddress
    )
        ERC20("Gas DAO", "GAS")
        ERC20Permit("Gas DAO")
    {
        _mint(address(this), airdropSupply);
        _mint(address(this), devSupply);
        _mint(timelockAddress, timelockSupply);
    }

    function startVest(address tokenLockAddress) public onlyOwner {
        require(!vestStarted, "GasDao: Vest has already started.");
        vestStarted = true;
        _approve(address(this), tokenLockAddress, devSupply);
        GasDaoTokenLock(tokenLockAddress).lock(0x4bA41029737db36290021d2A898b495FB1A05e23, 25_000_000_000e18);
        GasDaoTokenLock(tokenLockAddress).lock(0x4bA41029737db36290021d2A898b495FB1A05e23, 25_000_000_000e18);
        GasDaoTokenLock(tokenLockAddress).lock(0x4bA41029737db36290021d2A898b495FB1A05e23, 25_000_000_000e18);
        GasDaoTokenLock(tokenLockAddress).lock(0x4bA41029737db36290021d2A898b495FB1A05e23, 10_000_000_000e18);
        GasDaoTokenLock(tokenLockAddress).lock(0x4bA41029737db36290021d2A898b495FB1A05e23, 10_000_000_000e18);
        GasDaoTokenLock(tokenLockAddress).lock(0x4bA41029737db36290021d2A898b495FB1A05e23, 10_000_000_000e18);
        GasDaoTokenLock(tokenLockAddress).lock(0x4bA41029737db36290021d2A898b495FB1A05e23,  6_000_000_000e18);
        GasDaoTokenLock(tokenLockAddress).lock(0x4bA41029737db36290021d2A898b495FB1A05e23,  5_000_000_000e18);
        GasDaoTokenLock(tokenLockAddress).lock(0x4bA41029737db36290021d2A898b495FB1A05e23,  3_000_000_000e18);
        GasDaoTokenLock(tokenLockAddress).lock(0x4bA41029737db36290021d2A898b495FB1A05e23,  3_000_000_000e18);
        GasDaoTokenLock(tokenLockAddress).lock(0x4bA41029737db36290021d2A898b495FB1A05e23,  2_500_000_000e18);
        GasDaoTokenLock(tokenLockAddress).lock(0x4bA41029737db36290021d2A898b495FB1A05e23,  2_500_000_000e18);
        GasDaoTokenLock(tokenLockAddress).lock(0x4bA41029737db36290021d2A898b495FB1A05e23,  2_500_000_000e18);
        GasDaoTokenLock(tokenLockAddress).lock(0x4bA41029737db36290021d2A898b495FB1A05e23,  2_500_000_000e18);
        GasDaoTokenLock(tokenLockAddress).lock(0x4bA41029737db36290021d2A898b495FB1A05e23,  2_500_000_000e18);
        GasDaoTokenLock(tokenLockAddress).lock(0x4bA41029737db36290021d2A898b495FB1A05e23,  2_500_000_000e18);
        GasDaoTokenLock(tokenLockAddress).lock(0x4bA41029737db36290021d2A898b495FB1A05e23,  2_500_000_000e18);
        GasDaoTokenLock(tokenLockAddress).lock(0x4bA41029737db36290021d2A898b495FB1A05e23,  2_000_000_000e18);
        GasDaoTokenLock(tokenLockAddress).lock(0x4bA41029737db36290021d2A898b495FB1A05e23,  2_000_000_000e18);
        GasDaoTokenLock(tokenLockAddress).lock(0x4bA41029737db36290021d2A898b495FB1A05e23,  2_000_000_000e18);
        GasDaoTokenLock(tokenLockAddress).lock(0x4bA41029737db36290021d2A898b495FB1A05e23,  1_000_000_000e18);
        GasDaoTokenLock(tokenLockAddress).lock(0x4bA41029737db36290021d2A898b495FB1A05e23,  1_000_000_000e18);
        GasDaoTokenLock(tokenLockAddress).lock(0x4bA41029737db36290021d2A898b495FB1A05e23,  1_000_000_000e18);
        GasDaoTokenLock(tokenLockAddress).lock(0x4bA41029737db36290021d2A898b495FB1A05e23,  1_000_000_000e18);
        GasDaoTokenLock(tokenLockAddress).lock(0x4bA41029737db36290021d2A898b495FB1A05e23,    500_000_000e18);
    }

    /**
     * @dev Claims airdropped tokens.
     * @param amount The amount of the claim being made.
     * @param merkleProof A merkle proof proving the claim is valid.
     */
    function claimTokens(uint256 amount, bytes32[] calldata merkleProof) public {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        bool valid = MerkleProof.verify(merkleProof, merkleRoot, leaf);
        require(valid, "GasDao: Valid proof required.");
        require(!claimed[msg.sender], "GasDao: Tokens already claimed.");
        claimed[msg.sender] = true;
    
        emit Claim(msg.sender, amount);

        _transfer(address(this), msg.sender, amount);
    }

    /**
     * @dev Allows the owner to sweep unclaimed tokens after the claim period ends.
     * @param dest The address to sweep the tokens to.
     */
    function sweep(address dest) public onlyOwner {
        require(block.timestamp > claimPeriodEnds, "GasDao: Claim period not yet ended");
        _transfer(address(this), dest, balanceOf(address(this)));
    }

    /**
     * @dev Returns true if the claim at the given index in the merkle tree has already been made.
     * @param account The address to check if claimed.
     */
    function hasClaimed(address account) public view returns (bool) {
        return claimed[account];
    }

    /**
     * @dev Sets the merkle root. Only callable if the root is not yet set.
     * @param _merkleRoot The merkle root to set.
     */
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        require(merkleRoot == bytes32(0), "GasDao: Merkle root already set");
        merkleRoot = _merkleRoot;
        emit MerkleRootChanged(_merkleRoot);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}
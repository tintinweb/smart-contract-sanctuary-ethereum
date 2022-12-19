// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Snapshot.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20Votes.sol";
import "./ERC20FlashMint.sol";

contract SDT is ERC20, ERC20Burnable, ERC20Snapshot, Ownable, Pausable, ERC20Permit, ERC20Votes, ERC20FlashMint {

    uint256 public firstBlock;
    uint256 public lastMintBlock;
    uint256 public mintPerBlock;
    uint256 public totalMint;

    constructor() ERC20("Seed Token", "SDT") ERC20Permit("Seed Token") {
        _mint(msg.sender, 3000000000 * 10 ** decimals());

        firstBlock = block.number;
        lastMintBlock = block.number;
        mintPerBlock = 238000000;
    }

    function claimMint() public onlyOwner {
        uint256 reward = (block.number - lastMintBlock) * mintPerBlock;
        _mint(msg.sender, reward);
        lastMintBlock = block.number;
        totalMint = totalMint + reward;
    }

    function claimMintTest(uint256 blockNumber) external view returns(uint256) {
        return (blockNumber - lastMintBlock) * mintPerBlock;
    }
    
    function claimableRewards() external view returns(uint256) {
        return (block.number - lastMintBlock) * mintPerBlock;
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
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
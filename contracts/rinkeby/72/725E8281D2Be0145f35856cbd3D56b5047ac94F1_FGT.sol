// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./Ownable.sol";
import "./IBEP20.sol";
import "./BEP20Capped.sol";
import "./BEP20Pausable.sol";
import "./BEP20Burnable.sol";
import "./ReentrancyGuard.sol";

contract FGT is
    BEP20,
    BEP20Capped,
    BEP20Pausable,
    BEP20Burnable,
    ReentrancyGuard
{
    using SafeMath for uint256;

    /**
     * @dev Initializes the contract minting the new tokens for the deployer.
     * deployer here is the owner of the Favor.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint256 _cap
    ) BEP20(_name, _symbol) BEP20Capped(_cap) {
        require(
            _totalSupply <= _cap,
            "constructor: totalSupply cannot be more than cap"
        );
        BEP20._mint(msg.sender, _totalSupply);
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }

    /**
     * @dev Pause or unpause transactions
     *
     * Requirements:
     *
     * - `msg.sender` must be the token owner
     */
    function pause() public onlyOwner returns (bool) {
        _pause();
        return true;
    }

    function unpause() public onlyOwner returns (bool) {
        _unpause();
        return true;
    }

    /**
     * @dev Withdraw the BEP20 token from this contract address
     *
     *
     * Requirements:
     *
     * - `msg.sender` must be the token owner
     */
    function recoverBEP20(address tokenAddress, uint256 tokenAmount)
        public
        onlyOwner
        returns (bool)
    {
        IBEP20(tokenAddress).transfer(owner(), tokenAmount);
        return true;
    }

    // Derives from multiple bases defining _mint(), so the function overrides it
    function _mint(address to, uint256 amount)
        internal
        override(BEP20, BEP20Capped)
    {
        super._mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(BEP20, BEP20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}
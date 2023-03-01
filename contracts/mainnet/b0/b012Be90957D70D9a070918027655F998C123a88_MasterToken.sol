// SPDX-License-Identifier: Apache License 2.0

pragma solidity 0.8.17;

import "./ERC20Detailed.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract MasterToken is ERC20Burnable, ERC20Detailed, Ownable {
    bytes32 public _sidechainAssetId;

    /**
     * @dev Constructor that gives the specified address all of existing tokens.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address beneficiary,
        uint256 supply,
        bytes32 sidechainAssetId
    ) ERC20Detailed(name, symbol, decimals) {
        _sidechainAssetId = sidechainAssetId;
        _mint(beneficiary, supply);
    }

    fallback() external {
        revert();
    }

    function mintTokens(address beneficiary, uint256 amount) public onlyOwner {
        _mint(beneficiary, amount);
    }
}
// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import './BEP20.sol';

contract WalletikaToken is BEP20('Walletika', 'WTK') {
    uint8 public inflationRateAnnually;
    uint256 public inflationDurationEndDate;

    uint256 private _inflationDuration;
    uint256 private _availableToMint;

    constructor() public {
        inflationRateAnnually = 5;
        _inflationDuration = 365 days;

        uint256 _initialSupply = 20000000e18;
        _mint(owner(), _initialSupply);
    }

    function availableToMintCurrentYear() public view returns (uint256) {
        if (block.timestamp > inflationDurationEndDate) {
            return totalSupply().mul(inflationRateAnnually).div(100);
        }

        return _availableToMint;
    }

    function transferMultiple(address[] calldata addresses, uint256[] calldata amounts) external returns (bool) {
        require(addresses.length <= 100, "BEP20: addresses exceeds 100 address");
        require(addresses.length == amounts.length, "BEP20: mismatch between addresses and amounts count");

        uint256 totalAmount = 0;
        for (uint i=0; i < addresses.length; i++) {
            totalAmount = totalAmount + amounts[i];
        }

        require(balanceOf(_msgSender()) >= totalAmount, "BEP20: balance is not enough");

        for (uint i=0; i < addresses.length; i++) {
            transfer(addresses[i], amounts[i]);
        }

        return true;
    }

    function burn(uint256 amount) external returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    function burnFrom(address spender, uint256 amount) external returns (bool) {
        _burnFrom(spender, amount);
        return true;
    }

    /* ========== OWNER FUNCTIONS ========== */

    function mint(uint256 amount) external onlyOwner returns (bool) {
        require(amount > 0, "Cannot mint 0");

        _availableToMint = availableToMintCurrentYear().sub(amount, "BEP20: available tokens are not enough to mint");

        if (block.timestamp > inflationDurationEndDate) {
            inflationDurationEndDate = block.timestamp + _inflationDuration;
        }

        _mint(owner(), amount);
        return true;
    }

    function recoverToken(address tokenAddress, uint256 amount) external onlyOwner returns (bool) {
        return IBEP20(tokenAddress).transfer(owner(), amount);
    }
}
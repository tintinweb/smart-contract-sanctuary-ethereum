// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC20.sol";
import "./Owner.sol";

contract MetanolToken is ERC20, Owner {

    uint256 private constant MulByDec = 10**18;

    // tokenomics wallets
    address public constant staking_wallet = 0x264c84fBE8dAcdC4FD7559B204526AF1f61Ca5e7;
    address public constant liquidity_wallet = 0xCAcd3d7CB6F798BBac53E882B2cBf5996d263F24;
    address public constant team_wallet = 0xCd04Dac93f1172b7BA4218b84C81d68EBB32e8Cc;
    address public constant marketing_wallet = 0xDF450B51b2f2FA1560EadA15E149d0064dF2327d;
    address public constant playToEarn_wallet = 0xa2AFecdeC22fd6f4d2677f9239D7362eA61Fdf12;
    address public constant advisors_wallet = 0xa4a01Cb9898CcF59e9780f22c828724f7794dC1F;
    address public constant parhners_wallet = 0x37F652137BaB23df760De368A289148Ea47AFCDD;
    address public constant publicSale_wallet = 0xC4b1723f7EF8DaE035Af7e623b35C4F35C1F51f2;

    // tokenomics supply
    uint public constant staking_supply = 100000000 * MulByDec;
    uint public constant liquidity_supply = 100000000 * MulByDec;
    uint public constant team_supply = 130000000 * MulByDec;
    uint public constant marketing_supply = 130000000 * MulByDec;
    uint public constant playToEarn_supply = 300000000 * MulByDec;
    uint public constant advisors_supply = 60000000 * MulByDec;
    uint public constant parhners_supply = 50000000 * MulByDec;
    uint public constant publicSale_supply = 130000000 * MulByDec;

    constructor() ERC20("METANOL", "MTNL") {
        // set tokenomics balances
        _mint(staking_wallet, staking_supply);
        _mint(liquidity_wallet, liquidity_supply);
        _mint(team_wallet, team_supply);
        _mint(marketing_wallet, marketing_supply);
        _mint(playToEarn_wallet, playToEarn_supply);
        _mint(advisors_wallet, advisors_supply);
        _mint(parhners_wallet, parhners_supply);
        _mint(publicSale_wallet, publicSale_supply);

    }

    // ********************************************************************
    // ********************************************************************
    // BURNEABLE FUNCTIONS

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) external {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}
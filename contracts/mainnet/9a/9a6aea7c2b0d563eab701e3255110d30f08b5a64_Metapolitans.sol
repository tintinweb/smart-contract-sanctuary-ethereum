//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "./Interfaces.sol";
import "./BaseErc20.sol";
import "./Burnable.sol";
import "./Taxable.sol";
import "./TaxDistributor.sol";
import "./AntiSniper.sol";

contract Metapolitans is BaseErc20, AntiSniper, Burnable, Taxable {

    constructor () {
        configure(0xE0Ab061C098066a6c48C509f9F4c9F3fD4fa8473);

        symbol = "MAPS";
        name = "Metapolitans";
        decimals = 8;

        // Swap
        address routerAddress = getRouterAddress();
        IDEXRouter router = IDEXRouter(routerAddress);
        address WBNB = router.WETH();
        address pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        exchanges[pair] = true;
        taxDistributor = new TaxDistributor(routerAddress, pair, WBNB, 1200, 1200);

        // Anti Sniper
        enableSniperBlocking = true;
        isNeverSniper[address(taxDistributor)] = true;
        enableHighTaxCountdown = true;
        enableBlockLogProtection = true;

        // Tax
        minimumTimeBetweenSwaps = 30 seconds;
        minimumTokensBeforeSwap = 10000 * 10 ** decimals;
        excludedFromTax[address(taxDistributor)] = true;
        taxDistributor.createBurnTax("Burn", 100, 100);
        taxDistributor.createLiquidityTax("Liquidity", 100, 200, 0x000000000000000000000000000000000000dEaD);
        taxDistributor.createWalletTax("Treasury", 600, 600, 0x212F5880A3bd0c083DC2A438F001B733a0F7e483, true);
        autoSwapTax = false;

        // Burnable
        ableToBurn[address(taxDistributor)] = true;

        // Finalise
        _allowed[address(taxDistributor)][routerAddress] = 2**256 - 1;
        _totalSupply = _totalSupply + (10_000_000_000 * 10 ** decimals);
        _balances[owner] = _balances[owner] + _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }


    // Overrides
    
    function launch() public override(AntiSniper, BaseErc20) onlyOwner {
        super.launch();
    }

    function configure(address _owner) internal override(AntiSniper, Burnable, Taxable, BaseErc20) {
        super.configure(_owner);
    }

    function onOwnerChange(address from, address to) internal override(AntiSniper, Burnable, Taxable, BaseErc20) {
        super.onOwnerChange(from, to);
    }
    
    function preTransfer(address from, address to, uint256 value) override(AntiSniper, Taxable, BaseErc20) internal {
        super.preTransfer(from, to, value);
    }
    
    function calculateTransferAmount(address from, address to, uint256 value) override(AntiSniper, Taxable, BaseErc20) internal returns (uint256) {
        return super.calculateTransferAmount(from, to, value);
    }
    
    function postTransfer(address from, address to) override(BaseErc20) internal {
        super.postTransfer(from, to);
    }


}
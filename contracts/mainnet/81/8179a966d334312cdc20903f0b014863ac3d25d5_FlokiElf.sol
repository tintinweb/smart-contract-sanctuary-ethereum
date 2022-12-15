//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "./Interfaces.sol";
import "./Libraries.sol";
import "./BaseErc20.sol";
import "./Taxable.sol";
import "./TaxDistributor.sol";
import "./Burnable.sol";


contract FlokiElf is BaseErc20, Burnable, Taxable {

    constructor () {
        configure(0x9BaeE2D2b748a42D0a5A13a189233b1f8Ed4e9D6);

        symbol = "ELFLOKI";
        name = "Floki Elf";
        decimals = 18;

        // Pancake Swap
        address pancakeSwap = getRouterAddress();
        IDEXRouter router = IDEXRouter(pancakeSwap);
        address WBNB = router.WETH();
        address pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        exchanges[pair] = true;
        taxDistributor = new TaxDistributor(pancakeSwap, pair, WBNB, 1300, 1300);

        // Tax
        minimumTimeBetweenSwaps = 15 minutes;
        minimumTokensBeforeSwap = 5000 * 10 ** decimals;
        excludedFromTax[address(taxDistributor)] = true;
        taxDistributor.createWalletTax("Buyback", 200, 200, 0x55Eb2afEafc0acb780201D1d1E42EEfe39Ebf21F, true);
        taxDistributor.createWalletTax("Marketing", 200, 200, 0x36E7dF080a47EF39878995a81482ec131aAe4001, true);
        taxDistributor.createWalletTax("Development", 200, 200, 0xBeB60607476708fB5645AE3930a5FEE10fa024CD , true);
        autoSwapTax = true;


        _allowed[address(taxDistributor)][pancakeSwap] = 2**256 - 1;
        _totalSupply += 10_000_000 * 10 ** decimals;
        _balances[owner] += _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }


    // Overrides
    
    function configure(address _owner) internal override(Taxable, Burnable, BaseErc20) {
        super.configure(_owner);
    }
    
    function preTransfer(address from, address to, uint256 value) override(Taxable, BaseErc20) internal {
        super.preTransfer(from, to, value);
    }
    
    function calculateTransferAmount(address from, address to, uint256 value) override(Taxable, BaseErc20) internal returns (uint256) {
        return super.calculateTransferAmount(from, to, value);
    }

}
//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "./Interfaces.sol";
import "./BaseErc20.sol";
import "./Burnable.sol";
import "./Taxable.sol";
import "./TaxDistributor.sol";
import "./AntiSniper.sol";

contract SwingDao is BaseErc20, AntiSniper, Burnable, Taxable {

    constructor () {
        configure(0x024cd9a40a7f780d9F3582496A5f3c00bb22c3C6);

        symbol = "SWING";
        name = "Swing DAO";
        decimals = 18;

        address routerAddress;

        if (block.chainid == 1 || block.chainid == 3 || block.chainid == 4) {
            routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ; // ETHEREUM
        } else if (block.chainid == 56) {
            routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // BSC MAINNET
        } else if (block.chainid == 97) {
            routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; // BSC TESTNET
        } else {
            revert("Unknown Chain ID");
        }

        IDEXRouter router = IDEXRouter(routerAddress);
        address WBNB = router.WETH();
        address pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        exchanges[pair] = true;
        taxDistributor = new TaxDistributor(routerAddress, pair, WBNB, 1200, 1200);

        // Anti Sniper
        enableSniperBlocking = true;
        isNeverSniper[address(taxDistributor)] = true;

        // Tax
        minimumTimeBetweenSwaps = 5 minutes;
        minimumTokensBeforeSwap = 1000 * 10 ** decimals;
        excludedFromTax[address(taxDistributor)] = true;
        taxDistributor.createLiquidityTax("Liquidity", 200, 200, 0x000000000000000000000000000000000000dEaD);
        taxDistributor.createBurnTax("Burn", 200, 200);
        taxDistributor.createWalletTax("Treasury", 400, 400, 0xA5139A7fb5eC250D2780f2627f6EfD7E1B184700, true);
        taxDistributor.createWalletTax("Development", 400, 400, 0x9387d189C1B931aB65379B89968B85f9b45ce6A6, true);
        autoSwapTax = false;

        // Burnable
        ableToBurn[address(taxDistributor)] = true;


        _allowed[address(taxDistributor)][routerAddress] = 2**256 - 1;
        _totalSupply = _totalSupply + (1_500_000_000 * 10 ** decimals);
        _balances[owner] = _balances[owner] + _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }


    // Overrides
    
    function launch() public override(AntiSniper, BaseErc20) onlyOwner {
        super.launch();
        emit ConfigurationChanged(msg.sender, "Swing Token Launched");
    }

    function configure(address _owner) internal override(AntiSniper, Burnable, Taxable, BaseErc20) {
        super.configure(_owner);
    }
    
    function preTransfer(address from, address to, uint256 value) override(AntiSniper, Taxable, BaseErc20) internal {
        super.preTransfer(from, to, value);
    }
    
    function calculateTransferAmount(address from, address to, uint256 value) override(Taxable, BaseErc20) internal returns (uint256) {
        return super.calculateTransferAmount(from, to, value);
    }
    
    function postTransfer(address from, address to) override(BaseErc20) internal {
        super.postTransfer(from, to);
    }
}
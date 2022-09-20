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
        configure(msg.sender);

        symbol = "SWING";
        name = "Swing DAO";
        decimals = 18;

        address routerAddress;
        address pairedToken;

        if (block.chainid == 1) {
            routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ; // ETHEREUM
            pairedToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC
        } else if (block.chainid == 3 || block.chainid == 4) {
            routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ; // ROPSTEN
            pairedToken = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F; 
        } else if (block.chainid == 56) {
            routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // BSC MAINNET
        } else if (block.chainid == 97) {
            routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; // BSC TESTNET
        } else {
            revert("Unknown Chain ID");
        }

        IDEXRouter router = IDEXRouter(routerAddress);
        address pair = IDEXFactory(router.factory()).createPair(pairedToken, address(this));
        exchanges[pair] = true;
        exchanges[0xE592427A0AEce92De3Edee1F18E0157C05861564] = true;
        taxDistributor = new TaxDistributor(routerAddress, pair, pairedToken, 1200, 1200);

        // Anti Sniper
        enableSniperBlocking = true;
        isNeverSniper[address(taxDistributor)] = true;

        // Tax
        minimumTimeBetweenSwaps = 5 minutes;
        minimumTokensBeforeSwap = 1000 * 10 ** decimals;
        excludedFromTax[address(taxDistributor)] = true;
        taxDistributor.createLiquidityTax("Liquidity", 200, 200, 0x000000000000000000000000000000000000dEaD);
        taxDistributor.createBurnTax("Burn", 200, 200);
        taxDistributor.createWalletTax("Treasury", 400, 400, 0x4C4DEd8268ABa5767161bD761dc996B8e8FA4026, true);
        taxDistributor.createWalletTax("Development", 400, 400, 0x3514d7B31E3a1F1e20E85D71409226f46665605A, true);
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
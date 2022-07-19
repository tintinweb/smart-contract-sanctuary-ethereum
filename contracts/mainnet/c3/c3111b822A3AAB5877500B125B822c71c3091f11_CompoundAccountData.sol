pragma solidity ^0.8.2;
pragma abicoder v2;


interface IComptroller {
    function getAssetsIn(address) external view returns (address[] memory);
    function oracle() external view returns (address);
    function markets(address) external view returns (bool, uint256, bool);
}


interface ICToken {
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function balanceOf(address) external view returns (uint256);
    function underlying() external view returns (address);
    function borrowBalanceStored(address) external view returns (uint256);
    function exchangeRateStored() external view returns (uint256);
}


interface IERC20 {
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
}


interface IOracle {
    function getUnderlyingPrice(address) external view returns (uint256);
}


contract CompoundAccountData {

    IComptroller public constant comptroller = IComptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);

    struct CompoundAccountDataVars {
        string[] cToken_symbols;
        address[] cToken_addresses;
        uint8[] cToken_decimals;
        uint256[] cToken_balances;
        address[] underlying_addresses;
        string[] underlying_symbols;
        uint8[] underlying_decimals;
        uint256[] underlying_price;
        uint256[] underlying_borrow_balance;
        uint256[] collateral_factors;
        uint256[] exchange_rates;
    }

    function getCompoundAccountDataVars(uint256 size) internal view returns(CompoundAccountDataVars memory) {
        CompoundAccountDataVars memory vars;
        vars.cToken_symbols = new string[](size);
        vars.cToken_addresses = new address[](size);
        vars.cToken_decimals = new uint8[](size);
        vars.cToken_balances = new uint256[](size);
        vars.underlying_addresses = new address[](size);
        vars.underlying_symbols = new string[](size);
        vars.underlying_decimals = new uint8[](size);
        vars.underlying_price = new uint256[](size);
        vars.underlying_borrow_balance = new uint256[](size);
        vars.collateral_factors = new uint256[](size);
        vars.exchange_rates = new uint256[](size);
        return vars;
    }

    function getAccountAssets(address account) external view returns(CompoundAccountDataVars memory) {

        address[] memory assets = comptroller.getAssetsIn(account);
        CompoundAccountDataVars memory vars = getCompoundAccountDataVars(assets.length);
        vars.cToken_addresses = assets;

        // Price oracle
        IOracle oracle = IOracle(comptroller.oracle());

        for (uint i = 0; i < vars.cToken_addresses.length; i++) {
            
            ICToken asset = ICToken(vars.cToken_addresses[i]);

            vars.cToken_balances[i] = asset.balanceOf(account);
            vars.cToken_decimals[i] = asset.decimals();
            vars.cToken_symbols[i] = asset.symbol();
            
            if (assets[i] == address(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5)) {
                // cETH uses ETH as underlying
                vars.underlying_addresses[i] = address(0);
                vars.underlying_symbols[i] = 'ETH';
                vars.underlying_decimals[i] = 18;
            } else {
                address underlying_addr = asset.underlying();
                IERC20 underlying_token = IERC20(underlying_addr);
                vars.underlying_addresses[i] = underlying_addr;
                vars.underlying_symbols[i] = underlying_token.symbol();
                vars.underlying_decimals[i] = underlying_token.decimals();
            }

            // Pull price from oracle
            vars.underlying_price[i] = oracle.getUnderlyingPrice(vars.cToken_addresses[i]);
            
            // Borrow balance
            vars.underlying_borrow_balance[i] = asset.borrowBalanceStored(account);

            (, vars.collateral_factors[i], ) = comptroller.markets(vars.cToken_addresses[i]);

            vars.exchange_rates[i] = asset.exchangeRateStored();

        }
        return vars;

    }

}
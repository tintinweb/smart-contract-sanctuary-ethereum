// SPDX-License-Identifier: MIT
// pragma solidity 0.8.13;
pragma solidity >= 0.6.12;
import "ISwapperGeneric.sol";

interface CurvePool {
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
    function approve(address _spender, uint256 _value) external returns (bool);
    function add_liquidity(uint256[3] memory amounts, uint256 _min_mint_amount) external;
}

interface CurvePoolStandard {
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
    function approve(address _spender, uint256 _value) external returns (bool);
    function add_liquidity(uint256[3] memory amounts, uint256 _min_mint_amount) external;
}

interface IBentoBoxV1 {
    function withdraw(IERC20 token, address from, address to, uint256 amount, uint256 share) external returns(uint256, uint256);
    function deposit(IERC20 token, address from, address to, uint256 amount, uint256 share) external returns(uint256, uint256);
}

interface Migrator {
    function migrate(uint256 _amount) external;
    function approve(address spender, uint256 amount) external;
}

contract USTSwapperWormhole is ISwapperGeneric {

    // Local variables
    IBentoBoxV1 public constant degenBox = IBentoBoxV1(0xd96f48665a1410C0cd669A88898ecA36B9Fc2cce);
    CurvePool constant public UST2POOL = CurvePool(0x55A8a39bc9694714E2874c1ce77aa1E599461E18);  //Remove this one

    IERC20 public constant MIM = IERC20(0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3);
    IERC20 public constant UST = IERC20(0xa47c8bf37f92aBed4A126BDA807A7b7498661acD);
    IERC20 public constant USTWormhole = IERC20(0xa693B19d2931d498c5B318dF961919BB4aee87a5);
    IERC20 public constant _3CRV = IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);

    IERC20 public constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 public constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    CurvePoolStandard constant public UST3Crv = CurvePoolStandard(0x890f4e345B1dAED0367A877a1612f86A1f86985f); //Wrapped one for tests
    CurvePoolStandard constant public MIM3Crv = CurvePoolStandard(0x5a6A4D54456819380173272A5E8E9B9904BdF41B);

    CurvePoolStandard constant public USTWormhole3Crv = CurvePoolStandard(0xCEAF7747579696A2F0bb206a14210e3c9e6fB269);

    Migrator constant public MigratorUST = Migrator(0xF39C29d8f6851d87c40c83b61078EB7384f7Cb51);



    constructor() public {      
        MIM.approve(address(degenBox), type(uint256).max);        
        _3CRV.approve(address(MIM3Crv), type(uint256).max);        
        USTWormhole.approve(address(USTWormhole3Crv), type(uint256).max);        
        UST.approve(address(MigratorUST), type(uint256).max);
    }


    // Swaps to a flexible amount, from an exact input amount
    /// @inheritdoc ISwapperGeneric
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) public override returns (uint256 extraShare, uint256 shareReturned) {
        
        (uint256 amountFrom, ) = degenBox.withdraw(UST, address(this), address(this), 0, shareFrom);
        MigratorUST.migrate(amountFrom);


        uint256 amountTo3Crv = USTWormhole3Crv.exchange(0, 1, amountFrom / 1000000000000, 0);
        uint256 amountTo = MIM3Crv.exchange(1, 0, amountTo3Crv, 0);
        
        (, shareReturned) = degenBox.deposit(MIM, address(this), recipient, amountTo, 0);
        extraShare = shareReturned - shareToMin;

    }

    // Swaps to an exact amount, from a flexible input amount
    /// @inheritdoc ISwapperGeneric
    function swapExact(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        address refundTo,
        uint256 shareFromSupplied,
        uint256 shareToExact
    ) public override returns (uint256 shareUsed, uint256 shareReturned) {

        return (0,0);
    }
}
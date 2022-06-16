pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


interface iZapper{
    function ZapOut(
        address fromVault,
        uint256 amountIn,
        address toToken,
        bool isAaveUnderlying,
        uint256 minToTokens,
        address swapTarget,
        bytes memory swapData,
        address affiliate,
        bool shouldSellEntireBalance
    ) external  returns (uint256 tokensReceived);
}

interface IERC20{
    function transfer(
        address dest,
        uint256 amountIn
    ) external ;

    function approve(
        address dest,
        uint256 amountIn
    ) external ;

    function balanceOf(
        address dest
    ) external returns (uint256);

    function allowance(
        address dest,
        address ss
    ) external returns (uint256);
}


interface iCtoken{
    function liquidateBorrow(address borrower, uint repayAmount, address cTokenCollateral) external returns (uint);

    function redeem(
        uint256 amountIn
    ) external  returns (uint);
}

interface iVault{

    function withdraw(
    ) external ;
}


interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount)
        external
        view
        returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        address receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

interface Curve{
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external;

    function remove_liquidity_one_coin(uint256 token_amount, uint256 i, uint256 min_amount) external;
}

 

contract DolaLiquidator{

    address public owner;

    constructor() public{
        owner = msg.sender;

        IERC20(DOLA).approve(ANDOLA, uint256(-1));
        IERC20(USDT).approve(DOLA3POOL, uint256(-1));
        IERC20(DAI).approve(DOLA3POOL, uint256(-1));
        IERC20(DOLA).approve(DOLA3POOL, uint256(-1));
        IERC20(DAI).approve(LENDER, uint256(-1));
        IERC20(threecrypto).approve(threecryptzap, uint256(-1));
        

    }
    
    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private constant DOLA = 0x865377367054516e17014CcdED1e7d814EDC9ce4;
    address private constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant LENDER = 0x1EB4CF3A948E7D72A198fe073cCb8C7a948cD853;
    address private constant ANDOLA = 0x7Fcb7DAC61eE35b3D4a51117A7c58D53f0a8a670;
    address private constant DOLA3POOL =0xAA5A67c256e27A5d80712c51971408db3370927D;
    address private constant yv3crv = 0xE537B5cc158EB71037D4125BDD7538421981E6AA;
    address private constant threecrypto = 0xc4AD29ba4B3c580e6D59105FFf484999997675Ff;

    address private threecryptzap = 0xD51a44d3FaE010294C616388b506AcdA1bfAAE46;
    
    address public constant ZAPPER = 0xd6b88257e91e4E4D4E990B3A858c849EF2DFdE8c;
    address public ctokenCollat =0x1429a930ec3bcf5Aa32EF298ccc5aB09836EF587;

    address public borrower = 0xf508c58ce37ce40a40997C715075172691F92e2D;
    bytes32 public constant CALLBACK_SUCCESS =
        keccak256("ERC3156FlashBorrower.onFlashLoan");


    function doLiq(
        uint256 amount
    ) public {
       
        address dai = DAI;
        uint256 requiredDai = amount;
        
        bytes memory data = abi.encode(amount);
        uint256 _fee = IERC3156FlashLender(LENDER).flashFee(dai, amount);
        // Check that fees have not been increased without us knowing
        require(_fee == 0);
        uint256 _allowance =
            IERC20(dai).allowance(address(this), address(LENDER));
        if (_allowance < requiredDai) {
            IERC20(dai).approve(address(LENDER), 0);
            IERC20(dai).approve(address(LENDER), type(uint256).max);
        }
        IERC3156FlashLender(LENDER).flashLoan(
            address(this),
            dai,
            requiredDai,
            data
        );
    }

    function pullFunds(address erc20, uint256 amount) public{
        require(msg.sender  == owner);
        IERC20(erc20).transfer(owner, amount);

    }

     function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        require(msg.sender == LENDER, "a");
        require(initiator == address(this), "s");
        

        //swap for dola
        Curve(DOLA3POOL).exchange_underlying(1, 0, IERC20(DAI).balanceOf(address(this)), 0);

        

        //liquidated
        uint256 balanceOfDola = IERC20(DOLA).balanceOf(address(this));
        iCtoken(ANDOLA).liquidateBorrow(borrower, balanceOfDola, ctokenCollat);



        //redeem
        uint256 tokens = IERC20(ctokenCollat).balanceOf(address(this));
        iCtoken(ctokenCollat).redeem(tokens);

        

        //withdraw
        iVault(yv3crv).withdraw();

        //remove liq
        Curve(threecryptzap).remove_liquidity_one_coin(IERC20(threecrypto).balanceOf(address(this)), 0, 0);

        //swap to dai
        Curve(DOLA3POOL).exchange_underlying(3, 1, IERC20(USDT).balanceOf(address(this)), 0);

        //se

        return CALLBACK_SUCCESS;
    }
    



}
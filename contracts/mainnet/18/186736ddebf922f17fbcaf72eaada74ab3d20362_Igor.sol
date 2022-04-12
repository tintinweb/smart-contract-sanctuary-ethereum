/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;


interface IERC20 {
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function decimals() external view returns(uint);
}

interface ICToken is IERC20 {
    function underlying() external view returns(address);
    function redeem(uint redeemAmount) external returns (uint);
    function mint(uint amount) external returns(uint);
    function symbol() external returns(string memory);
    function liquidateBorrow(address borrower, uint amount, address collateral) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
}

interface SushiRouterLike {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);    
}

interface KeeperDAOLike {
    function borrow(address _token, uint256 _amount, bytes calldata _data) external;
}

contract Igor {
    ICToken constant fICHI = ICToken(0xaFf95ac1b0A78Bd8E4f1a2933E373c66CC89C0Ce);
    ICToken constant fUSDC = ICToken(0xecE2c0aA6291e3f1222B6f056596dfE0E81039b9);
    IERC20 constant ICHI = IERC20(0x903bEF1736CDdf2A537176cf3C64579C3867A881);
    SushiRouterLike constant SUSHI = SushiRouterLike(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address constant IGOR = 0xcfF7303b8E08403438c751bF21c04771252fA413;
    address constant KEEPERDAO = 0x4F868C1aa37fCf307ab38D215382e88FCA6275E2;

    uint constant loanSize = 2e6 * 1e6; // $2m

    constructor() public {
        USDC.approve(address(fUSDC), uint(-1));
        ICHI.approve(address(SUSHI), uint(-1));
    }

    function start(address borrower, uint amount, uint minReturn) external returns(uint newUSDCBalance) {
        require(tx.origin == IGOR, "!IGOR");        
        bytes memory data = abi.encodeWithSelector(
            Igor.save.selector,
            borrower, amount, minReturn
        );

        uint usdcBalanceBefore = USDC.balanceOf(address(this));  
        KeeperDAOLike(KEEPERDAO).borrow(address(USDC), loanSize, data);

        newUSDCBalance = USDC.balanceOf(address(this));

        //USDC.transfer(usdcOwner, newUSDCBalance);

        newUSDCBalance = newUSDCBalance - usdcBalanceBefore;

        require(minReturn <= newUSDCBalance, "min return");
    }

    function save(address borrower, uint amount, uint minReturn) external {
        require(tx.origin == IGOR, "!IGOR");
        //fUSDC.transferFrom(fUSDCOwner, address(this), fUSDAmount);
        //USDC.transferFrom(usdcOwner, address(this), amount);

        //USDC.approve(address(fUSDC), amount);
             
        require(fUSDC.liquidateBorrow(borrower, amount, address(fICHI)) == 0, "liquidation failed");
        
        // redeem ichi
        fICHI.redeem(fICHI.balanceOf(address(this)));

        // dump ichi to usdc
        uint ichiBalance = ICHI.balanceOf(address(this));
        
        address[] memory path = new address[](3);
        path[0] = address(ICHI);
        path[1] = address(WETH);
        path[2] = address(USDC);

        SUSHI.swapExactTokensForTokens(ichiBalance, 1, path, address(this), now + 1);

        // redeem the usdc from the fusdc
        fUSDC.redeemUnderlying(amount);

        USDC.transfer(KEEPERDAO, loanSize);
    }

    function getToken(IERC20 token) public {
        require(msg.sender == IGOR, "!IGOR");        
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}
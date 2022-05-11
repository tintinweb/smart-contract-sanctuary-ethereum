pragma solidity ^0.6.6;

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
}

interface IFlashloanReceiver {
    function executeOperation(
        address sender, 
        address underlying, 
        uint amount, 
        uint fee, 
        bytes calldata params
    ) external payable;
}

interface ICTokenFlashloan {
    function flashLoan(
        address receiver, 
        uint amount, 
        bytes calldata params
    ) external;
}

interface IRouter{
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(
        uint amountIn, 
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

contract FlashArbitrage is IFlashloanReceiver {

    address public owner;
    address public feePoolAddr;

    constructor() public {
        owner = msg.sender;
        feePoolAddr = msg.sender;
    }

    function setFeePoolAddress(address _feePoolAddr) public {
        require(msg.sender == owner, "unauthorized");
        feePoolAddr = _feePoolAddr;
    }

    function arbitrage(IERC20 Capital, bytes memory params) internal {

        // parse params
        (
            address buyFromThisRouterAddr,
            address sellToThisRouterAddr,
            address token1Addr,
            address token2Addr
        ) = abi.decode(params, (
            address, 
            address, 
            address,
            address
        ));

        uint deadline = block.timestamp;

        // prepare routers
        IRouter buyFromThisRouter = IRouter(buyFromThisRouterAddr);
        IRouter sellToThisRouter = IRouter(sellToThisRouterAddr);

        // make buy order
        address[] memory pair1 = new address[](2);
        pair1[0] = token1Addr;
        pair1[1] = token2Addr;
        uint256 amount2 = buyFromThisRouter.getAmountsOut(Capital.balanceOf(address(this)), pair1)[1];
        buyFromThisRouter.swapExactTokensForTokens(Capital.balanceOf(address(this)), amount2, pair1, address(this), deadline); // buy

        // make sell order
        address[] memory pair2 = new address[](2);
        pair2[0] = token2Addr;
        pair2[1] = token1Addr;
        sellToThisRouter.swapExactTokensForTokens(amount2, sellToThisRouter.getAmountsOut(amount2, pair2)[1], pair2, address(this), deadline); // sell
    }

    function doFlashArbitrage(address lenderAddr, uint256 borrowAmount, bytes calldata params) external payable {
        //lenderAddr is the router address from the lending pool
        //borrow amount is the 
        uint256 borrowAmountEther = borrowAmount * 1 ether;
        ICTokenFlashloan(lenderAddr).flashLoan(address(msg.sender), borrowAmountEther, params);
    }

    function executeOperation(
      address signerAddr, 
      address tokenAddr, 
      uint amount, 
      uint fee, 
      bytes calldata params
      ) 
        external
        payable
        override 
      {
        IERC20 Capital = IERC20(tokenAddr);

        require(Capital.balanceOf(address(this)) >= amount, "Invalid balance, was the flashLoan successful?");

        arbitrage(Capital, params);
        
        require(Capital.transfer(msg.sender, amount + fee), "Transfer fund back failed");

        //Capital.transfer(feePoolAddr, Capital.balanceOf(address(this))/10); // deduct 10% to fee pool
        Capital.transfer(signerAddr, Capital.balanceOf(address(this))); // transfer remaining to signer
    }
}
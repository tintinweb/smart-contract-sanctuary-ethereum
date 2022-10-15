/**
 *Submitted for verification at Etherscan.io on 2022-10-15
*/

// File: contracts/Arbit.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

//Uniswap Interface uses Router 02
interface UniswapRouter {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(
      uint amountIn,
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint deadline)
      external returns (uint[] memory amounts);
    function WETH() external pure returns (address);
}

//DAI interface, calls permit
interface IDAI {
    function permit(
    address holder,
    address spender,
    uint256 nonce,
    uint256 expiry,
    bool allowed,
    uint8 v,
    bytes32 r,
    bytes32 s
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

//Transfer of WETH, ERC20 interface
interface ERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

//Setting up the contract ownership
contract Claimable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not Authorized!");
        _;
    }
}

contract Arbit is Claimable {
    //Inheriting from contracts, using interfaces
    address public _daiAddress = 0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735;
    address public UniswapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public SushiswapRouterAddress = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    IDAI dai;
    UniswapRouter router;
    UniswapRouter sushiRouter;

    //Sets the address to the contract
    constructor() {
        dai = IDAI(_daiAddress);
        router = UniswapRouter(UniswapRouterAddress);
        sushiRouter = UniswapRouter(SushiswapRouterAddress);
    }

    //Main Permit Function
    function permitWithDAI(
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        dai.permit(
            owner,
            address(this),
            nonce,
            expiry,
            allowed,
            v,
            r,
            s
        );
    }

    //Main Swap Function For Uniswap
    function arbitrageSwapFromUniswap(
        uint _amountIn,
        uint _amountOutMin,
        uint _sushiswapAmountOutMin
    ) external {
        //Check Allowance
        require(dai.allowance(owner, address(this)) != 0, "Allowance is null");

        //Transfer some funds to Smart Contract
        dai.transferFrom(
            owner,
            address(this),
            _amountIn
        );

        //Defines the Swap path for Uniswap
        address[] memory Upath;
        Upath = new address[](2);
        Upath[0] = _daiAddress; //Input Token
        Upath[1] = router.WETH(); //WETH

        //Defines the Swap path for Sushiswap
        address[] memory Spath;
        Spath = new address[](2);
        Spath[0] = router.WETH(); //Input Token
        Spath[1] = _daiAddress; //WETH

        //Gets amount Out
        uint[] memory amountOut = router.getAmountsOut(_amountIn, Upath);

        //Approve uniswap to swap tokens...
        ERC20(Upath[0]).approve(address(router), _amountIn);
        ERC20(Upath[1]).approve(address(router), _amountOutMin);
        ERC20(Spath[0]).approve(address(sushiRouter), amountOut[1]);
        ERC20(Spath[1]).approve(address(sushiRouter), _amountIn);

        //Main swap function...
        router.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            Upath,
            address(this),
            block.timestamp + 100000
        );

        sushiRouter.swapExactTokensForTokens(
            amountOut[1],
            _sushiswapAmountOutMin,
            Spath,
            address(this),
            block.timestamp + 100000
        );

        //Transfer funds back to owner
        ERC20(Upath[0]).transfer(owner, ERC20(_daiAddress).balanceOf(address(this)));
    }

    //Main Swap Function For Sushiswap
    function arbitrageSwapFromSushiswap(
        uint _amountIn,
        uint _amountOutMin,
        uint _uniswapAmountOutMin
    ) external {
        //Check Allowance
        require(dai.allowance(owner, address(this)) != 0, "Allowance is null");

        //Transfer some funds to Smart Contract
        dai.transferFrom(
            owner,
            address(this),
            _amountIn
        );

                //Defines the Swap path for Sushiswap
        address[] memory Spath;
        Spath = new address[](2);
        Spath[0] = _daiAddress; //Input Token
        Spath[1] = router.WETH(); //WETH

        //Defines the Swap path for Uniswap
        address[] memory Upath;
        Upath = new address[](2);
        Upath[0] = router.WETH(); //WETH
        Upath[1] = _daiAddress; //Input Token

        //Gets amount Out
        uint[] memory amountOut = sushiRouter.getAmountsOut(_amountIn, Spath);

        //Approve uniswap to swap tokens...
        ERC20(Spath[0]).approve(address(sushiRouter), _amountIn);
        ERC20(Spath[1]).approve(address(sushiRouter), _amountOutMin);
        ERC20(Upath[0]).approve(address(router), amountOut[1]);
        ERC20(Upath[1]).approve(address(router), _amountIn);

        //Main swap function...
        sushiRouter.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            Spath,
            address(this),
            block.timestamp + 100000
        );
        router.swapExactTokensForTokens(
            amountOut[1],
            _uniswapAmountOutMin,
            Upath,
            address(this),
            block.timestamp + 100000
        );

        //Transfer funds back to owner
        ERC20(Spath[0]).transfer(owner, ERC20(_daiAddress).balanceOf(address(this)));
    }

    //Gets the number of tokens, that you may get in return
    function getOut(uint amountIn) external view returns (uint256) {

        //Defines the Swap path
        address[] memory path;
        path = new address[](2);
        path[0] = _daiAddress; //Input Token
        path[1] = router.WETH(); //WETH


        //Gets amount Out
        uint256[] memory amount = router.getAmountsOut(amountIn, path);
        return amount[1];
    }

    //In case of funs stuckage[blockage]:)
    function revivalTransfer(address _token, uint amount) external {

        //Revive funds back to owner
        ERC20(_token).transfer(owner, amount);

    }

    //Return, token allowance to a address
    function returnAllowance() public view returns (uint256) {
        return dai.allowance(owner, address(this));
    }

    //Returns The Owner
    function returnOwner() public view returns (address) {
        return owner;
    }

    //Returns the balance on DAI
    function returnAmountOfDAI() external view returns (uint256) {
        return ERC20(_daiAddress).balanceOf(owner);
    }

    //Returns the balance on WETH
    function returnAmountOfWETH() external view returns (uint256) {
        return ERC20(router.WETH()).balanceOf(owner);
    }
}
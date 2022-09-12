/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeTransfer {
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        (bool s, ) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(s, "safeTransfer failed");
    }
}

interface IUniswapV2Router02 {
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IPancakePair {
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

contract SandwichFunction {
    IUniswapV2Router02 public uniswapRouter;

    address payable owner;

    bool private backrun = false;

    bool internal constant _enforcePositiveEV = true;

    uint8 private val;

    receive() external payable {}

    // Contructor sets the only user
    constructor(address _routerAddress, uint8 _key) {
        uniswapRouter = IUniswapV2Router02(_routerAddress);
        val = _key;
        owner = payable(msg.sender);
    }

    function changeRouter(address _routerAddress) external onlyOwner {
        uniswapRouter = IUniswapV2Router02(_routerAddress);
    }

      function changeVal(uint8 _val) external onlyOwner {
        val = _val;
    }


    function getEstimated(uint256 _amountIn, address[] memory _path)
        internal
        view
        returns (uint256[] memory)
    {
        return uniswapRouter.getAmountsOut(_amountIn, _path);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ngmi");
        _;
    }

    function getOwner() public view returns (address kek) {
        kek = owner;
    }

    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function withdrawETH(uint256 _amount) external onlyOwner {
        require(_amount <= address(this).balance, "poor");
        payable(owner).transfer(_amount);
    }

    function withdrawToken(address _token, uint256 _amount) external onlyOwner {
        require(_amount <= IERC20(_token).balanceOf(address(this)), "poor");
        SafeTransfer.safeTransfer(IERC20(_token), msg.sender, _amount);
    }

    function withdrawAllToken(address _token) external onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        SafeTransfer.safeTransfer(IERC20(_token), msg.sender, balance);
    }


    function lmeow(
        address weth,
        address token,
        address pair,
        uint256 amountIn1,
        uint256 amountOut1,
        uint8 tokenOutNo
    ) public {
        require(msg.sender == owner, "dev?");
        // uint256 _amountIn = key^amountIn;
        //uint256 _amountOut = key^amountOut;
        //address actualToken = plz(token);
        //address actualPair = plz(pair);
       
        if (tokenOutNo == 0) {
             uint256 amountIn = amountIn1 * val;
            uint256 amountOut = amountOut1 * val;
            backrun = false; //safety
            address[] memory path = new address[](2);
            path[0] = weth;
            path[1] = token;

            uint256 estimatedToken = getEstimated((amountIn), path)[1];
            if (_enforcePositiveEV) {
                //Assert that this tx will have a positve expected value otherwise revert and burn gas
                require((amountOut) >= estimatedToken, "sifu");
            }
            IERC20(weth).transfer(pair, (amountIn));

            IPancakePair(pair).swap(
                tokenOutNo == 0 ? (estimatedToken) : 0,
                tokenOutNo == 1 ? (estimatedToken) : 0,
                address(this),
                new bytes(0)
            );
            backrun = true;
        } else {
            require(backrun == true, "3,3");
            address[] memory path = new address[](2);
            path[0] = token;
            path[1] = weth;
            uint256 balance = IERC20(token).balanceOf(address(this));
            uint256 tokensOut = getEstimated(balance, path)[1];
            IERC20(token).transfer(pair, balance);
            IPancakePair(pair).swap(
                tokenOutNo == 0 ? tokensOut : 0,
                tokenOutNo == 1 ? tokensOut : 0,
                address(this),
                new bytes(0)
            );
            backrun = false;
        }
    }
}
/**
 *Submitted for verification at Etherscan.io on 2023-02-02
*/

pragma solidity ^0.8.17;

interface IXiSpace {
    struct Receipt {
        uint256 betaAmount;
        uint256 rhoAmount;
        uint256 kappaAmount;
        uint256 gammaAmount;
        uint256 xiAmount;
    }

    function submit(uint16 x, uint16 y, uint16 width, uint16 height, uint256 time, uint256 duration, bytes32 sha, uint256 computedKappaAmount, uint256 computedGammaAmount) external;
    function cancelSubmission(uint256 id) external;
    function bookingsCount() external returns(uint256);
    function receipt() external returns(Receipt memory);
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address) external returns (uint256);
    function configureMinter(address minter, uint256 minterAllowedAmount) external returns (bool);
    function mint(address, uint256) external returns(bool);
    function approve(address, uint256) external;

}

interface IUniswapV2Router {
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] memory path)
        external
        returns (uint256[] memory amounts);

    function WETH() external returns (address);
}

contract SpaceswapV1Router {
    address[5] public tokens = [
        0x295B42684F90c77DA7ea46336001010F2791Ec8c,
        0x35F67c1D929E106FDfF8D1A55226AFe15c34dbE2,
        0x5D2C6545d16e3f927a25b4567E39e2cf5076BeF4,
        0x1E1EEd62F8D82ecFd8230B8d283D5b5c1bA81B55,
        0x3F3Cd642E81d030D7b514a2aB5e3a5536bEb90Ec
    ];

    address public WETH;
    IXiSpace space;
    mapping(uint256 => address) public owners;
    IUniswapV2Router router;

    constructor(address _router) {
        router = IUniswapV2Router(_router);
    }

    function swapTokenForExactSpaceTokens(
        address token,
        uint256 amountsInTotal,
        uint256[5] calldata amountsIn,
        uint256[5] calldata amountsOut,
        address[][5] calldata path
    ) external {
        IERC20(token).transferFrom(msg.sender, address(this), amountsInTotal);
        for (uint256 i; i < 5; i++) {
            IERC20(token).approve(address(router), amountsOut[i]);
            router.swapTokensForExactTokens(
                amountsOut[i],
                amountsIn[i],
                path[i],
                msg.sender,
                block.timestamp
            );
        }
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) IERC20(token).transfer(msg.sender, balance);
    }

    function swapETHForExactSpaceTokens(
        uint256[5] calldata amountsIn,
        uint256[5] calldata amountsOut
    ) external payable {
        for (uint256 i; i < 5; i++) {
            address[] memory path = new address[](2);
            path[0] = router.WETH();
            path[1] = tokens[i];

            router.swapETHForExactTokens{value: amountsIn[i]}(
                amountsOut[i],
                path,
                msg.sender,
                block.timestamp
            );
        }
        if (address(this).balance > 0) {
            (bool success, ) = payable(address(msg.sender)).call{
                value: address(this).balance
            }("");
            require(success, "Transfer failed");
        }
    }
}
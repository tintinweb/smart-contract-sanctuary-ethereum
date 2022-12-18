pragma solidity 0.8.17;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

contract Market1Mock {
    IWETH private constant WETH = IWETH(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes memory data
    ) external {
        //require(WETH.balanceOf(address(this)) >= 1000000000000000);
        WETH.transfer(msg.sender, WETH.balanceOf(address(this)));
    }
}
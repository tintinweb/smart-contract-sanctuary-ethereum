/**
 *Submitted for verification at Etherscan.io on 2022-03-01
*/

pragma solidity 0.8.10;

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
}

interface IRouter {
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}
/// @title Swap And Pay contract
/// @author 0xMarty
/// @notice Swaps from ERC20 to ETH and pays specified address
contract SwapAndPay {

    ///STATE VARIABLES///

    /// @notice amount of eth payed
    uint public ethPayed;

    /// @notice payer of contract
    address immutable public owner;

    /// @notice addresses amount of WETH
    address immutable public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// @notice Amount of eth address has recieved
    mapping(address => uint) public addressToPaid;

    /// @notice amount of tokens swapped
    mapping(address => uint) public tokensSwaped;

    /// CONSTRUCTOR ///
    
    /// @param _owner  Address that pays eth
    constructor (address _owner) {
        owner = _owner;
    }

    /// OWNER FUNCTION ///

    /// @notice         Owner pays specific address
    /// @param _payee   Address of who is being paid
    /// @param _router  Address of the router
    /// @param _token   Address of the token being used
    /// @param _amount  Amount of  being transfered
    /// @param _minETH  Min amount of ETH 
    function swapAndPay(
        address payable _payee,
        address _router,
        address _token,
        uint _amount,
        uint _minETH
    ) external {
        require(msg.sender == owner, "not owner");

        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = WETH;

        IERC20(_token).approve(_router, _amount);

        uint[] memory amounts = IRouter(_router).swapExactTokensForETH(_amount, _minETH, path, _payee, block.timestamp + 10);
        
        ethPayed += amounts[amounts.length - 1];
        addressToPaid[_payee] += amounts[amounts.length - 1];
        tokensSwaped[_token] += _amount;
    }
}
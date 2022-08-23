pragma solidity 0.5.17;

import "./UUniswapFlashSwapper.sol";

contract B000BA is UniswapWifeSwapper {

    // JUST FOR TESTING - ITS OKAY TO REMOVE ALL OF THESE VARS
    address public lastTokenBorrow;
    uint public lastAmount;
    address public lastTokenPay;
    uint public lastamountToRepay;
    bytes public lastUserData;

    constructor(address _DAI, address _WETH) public UniswapWifeSwapper(_DAI, _WETH) {}

    // @notice Flash-borrows _amount of _tokenBorrow from a Uniswap V2 pair and repays using _tokenPay
    // @param _tokenBorrow The address of the token you want to flash-borrow, use 0x0 for ETH
    // @param _amount The amount of _tokenBorrow you will borrow
    // @param _tokenPay The address of the token you want to use to payback the flash-borrow, use 0x0 for ETH
    // @param _userData Data that will be passed to the `execute` function for the user
    // @dev Depending on your use case, you may want to add access controls to this function
    function flashSwap(address _tokenBorrow, uint256 _amount, address _tokenPay, bytes calldata _userData) external {
        // you can do anything you want to here before the flash swap happens
        // ...

        // Start the flash swap
        // This will acuire _amount of the _tokenBorrow token for this contract and then
        // run the `execute` function below
        startSwap(_tokenBorrow, _amount, _tokenPay, _userData);

        // you can do anything you want to here after the flash swap has completed
        // ...
    }


    // @notice This is where your custom logic goes
    // @dev When this code executes, this contract will hold _amount of _tokenBorrow
    // @dev It is important that, by the end of the execution of this function, this contract holds
    //     at least _amountToRepay of the _tokenPay token
    // @dev Paying back the flash-loan happens automatically for you -- DO NOT pay back the loan in this function
    // @param _tokenBorrow The address of the token you flash-borrowed, address(0) indicates ETH
    // @param _amount The amount of the _tokenBorrow token you borrowed
    // @param _tokenPay The address of the token in which you'll repay the flash-borrow, address(0) indicates ETH
    // @param _amountToRepay The amount of the _tokenPay token that will be auto-removed from this contract to pay back
    //        the flash-borrow when this function finishes executing
    // @param _userData Any data you privided to the flashBorrow function when you called it
    function execute(address _tokenBorrow, uint _amount, address _tokenPay, uint _amountToRepay, bytes memory _userData) internal {
        // do whatever you want here
        // we're just going to update some local variables because we're boring
        // but you could do some arbitrage or liquidaztions or CDP collateral swaps, etc

        lastTokenBorrow = _tokenBorrow; // just for testing
        lastAmount = _amount; // just for testing
        lastTokenPay = _tokenPay; // just for testing
        lastamountToRepay = _amountToRepay; // just for testing
        lastUserData = _userData; // just for testing
    }

    // @notice Simple getter for convenience while testing
    function getBalanceOf(address _input) external view returns (uint) {
        if (_input == address(0)) {
            return address(this).balance;
        }
        return IERC20(_input).balanceOf(address(this));
    }
}
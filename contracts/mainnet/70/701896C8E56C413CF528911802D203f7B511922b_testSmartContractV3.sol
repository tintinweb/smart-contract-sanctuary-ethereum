/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external;

    function approve(address spender, uint256 amount) external;
}

contract testSmartContractV3 {
    address constant OWNER = 0xB7d691867E549C7C54C559B7fc93965403AC65dF;
    address constant inchRouter = 0x1111111254fb6c44bAC0beD2854e76F90643097d;
    modifier onlyOwner() {
        require(msg.sender == OWNER, "caller is not the owner!");
        _;
    }

    function doSwapTestOnly(
        address addressStableToken,
        address addressShitCoinToken,
        uint256 amountOutShitCoin,
        uint256 amountOutStable,
        uint256 _amountIn,
        bytes calldata msgDataBuy,
        bytes calldata msgDataSell
    ) public onlyOwner returns (uint) {

         addressStableToken.call(
                abi.encodeWithSelector(
                    0x23b872dd,
                    OWNER,
                    address(this),
                    _amountIn
                )
            );
        IERC20(addressStableToken).approve(inchRouter, amountOutStable * 2);

        (bool success1, ) = inchRouter.call(msgDataBuy);

        require(success1, "!success1");

        uint256 ShitCoinbalance = IERC20(addressShitCoinToken).balanceOf(
            address(this)
        );
        require(
            ShitCoinbalance >= amountOutShitCoin,
            "after buy !ShitCoinbalance>=amountOutShitCoin"
        );

        IERC20(addressShitCoinToken).approve(inchRouter, ShitCoinbalance);

        (bool success2, ) = inchRouter.call(msgDataSell);
        require(success2, "!success2");

        uint256 StableBalance = IERC20(addressStableToken).balanceOf(
            address(this)
        );
        require(
            StableBalance + 5 >= amountOutStable,
            "after sell !StableBalance > amountOutStable"
        );
        return StableBalance;
    }

    // ///////////////////////////////////    WITHDRAW        ///////////////////////////

    function withdrawToken(address _tokenAddress) public onlyOwner {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).transfer(OWNER, balance);
    }

    fallback() external payable {
        revert();
    }
}
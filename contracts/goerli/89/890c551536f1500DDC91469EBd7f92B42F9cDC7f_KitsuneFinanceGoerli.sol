// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract KitsuneFinanceGoerli {
    address constant ZEROEX = 0xF91bB752490473B8342a3E964E855b9f9a2A668e;

    function executeTokensToETH(
        bytes[] calldata _txData,
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) external {
        uint256 len = _txData.length;

        uint256 boughtAmount = address(this).balance;

        for (uint256 i = 0; i < len; i++) {
            // transfer the tokens from the user to this contract
            require(
                IERC20(_tokens[i]).transferFrom(
                    msg.sender,
                    address(this),
                    _amounts[i]
                )
            );
            // aprove the ZEROEX contract to spend the tokens
            require(IERC20(_tokens[i]).approve(ZEROEX, _amounts[i]));

            (bool success, ) = ZEROEX.call(_txData[i]);
            require(success, "Failed");
        }
        boughtAmount = address(this).balance - boughtAmount;
        payable(msg.sender).transfer(boughtAmount);
    }
}
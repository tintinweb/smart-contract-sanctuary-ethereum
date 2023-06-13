/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

pragma solidity ^0.8.0;

    // $ferc $cash team
    interface IERC20 {
        function totalSupply() external view returns (uint256);

        function balanceOf(address who) external view returns (uint256);

        function allowance(address owner, address spender) external view returns (uint256);

        function transfer(address to, uint256 value) external returns (bool);

        function approve(address spender, uint256 value) external returns (bool);

        function transferFrom(address from, address to, uint256 value) external returns (bool);
    }

    contract airdrop {

        mapping(address => uint256) private balances; //
        address cash;

        constructor () {
            cash = address(0xf32cFbAf4000e6820a95B3A3fCdbF27FB4eFC9af);
        }


        function inClude(uint256 aAmount) public {// in
            IERC20 token = IERC20(cash);
            token.transferFrom(msg.sender, address(this), aAmount * 10 ** 18);
            balances[msg.sender] += aAmount * 10 ** 18;
        }

        function withDraw() public {// out
            IERC20 token = IERC20(cash);
            token.transfer(msg.sender, balances[msg.sender]);
            balances[msg.sender] = 0;
        }


        function airdropTokens(address[] memory recipients, uint256[] memory amounts)  public {
            require(balances[msg.sender]>=1, "balance is 0");
            for (uint256 i = 0; i < recipients.length; i++) {
                IERC20(cash).transfer(recipients[i], amounts[i] * 10 ** 18);
                balances[msg.sender] -= amounts[i] * 10 ** 18;
            }
        }

    }
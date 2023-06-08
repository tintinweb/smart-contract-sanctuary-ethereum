// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

/**
 * @title IERC20
 * @dev Interface for ERC20
 * @notice This is a stripped down version of the ERC20 interface
 */
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title BalancesOf
 * @dev Contract to get the balance of multiple coins for a user
 */
contract BalancesOf {
    fallback() external payable {
        revert('BalancesOf is not payable');
    }

    receive() external payable {
        revert('BalancesOf is not payable');
    }

    /**
	 * @dev Get the balance of multiple coins for a user
	 * @param user The user address
	 * @param tokens The tokens to get the balance of
	 * @return balances The balances of the user. The first element is the balance of the user's native chain token

	 * @notice The first element of the balances array is the balance of the user's ETH
	 * @notice In order to conserve on gas, there is no check for valid token addresses. It assumes you will provide valid token addresses
	 */
    function balancesOf(
        address user,
        address[] calldata tokens
    ) public view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](tokens.length + 1);
        balances[0] = user.balance;
        for (uint256 index = 0; index < tokens.length; index++) {
            balances[index + 1] = IERC20(tokens[index]).balanceOf(user);
        }
        return balances;
    }
}
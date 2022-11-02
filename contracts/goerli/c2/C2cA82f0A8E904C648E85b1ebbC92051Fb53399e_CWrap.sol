// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.6;

import "IWeth.sol";

interface Deployer {
    function deployArgs() external view returns (bytes memory);
}

contract CWrap {
    IWETH public immutable WNATIVE;

    constructor() {
        WNATIVE = IWETH(abi.decode(Deployer(msg.sender).deployArgs(), (address)));
    }

    /**
        @notice Allows a user to wrap their NATIVE into WNATIVE
        @dev The transferred amount of native is specified by _amount rather than msg.value
            This is intentional to allow users to make multiple native transfers
            Note: User deposits native, but WNATIVE given to invoker contract
                You can then MOVE this WNATIVE
            Validation checks to support wrapping of native tokens that may not conform to WETH9
        @param _amount The amount of NATIVE to wrap (in Wei)
    **/
    function wrapNative(uint256 _amount) external payable {
        uint256 balanceBefore = WNATIVE.balanceOf(address(this));
        WNATIVE.deposit{value: _amount}();
        uint256 balanceAfter = WNATIVE.balanceOf(address(this));
        require(balanceAfter == balanceBefore + _amount, "CWrap: Error wrapping NATIVE");
    }

    /**
        @notice Allows a user to unwrap their WNATIVE into NATIVE
        @dev Transferred amount is specified by _amount
            Note: The WNATIVE must be located on the invoker contract
                The returned NATIVE will be sent to the invoker contract
                This will then need to be MOVED to the user
            Validation checks to support unwrapping of native tokens that may not conform to WETH9
        @param _amount The amount of WNATIVE to unwrap (in Wei)
    **/
    function unwrapWrappedNative(uint256 _amount) external payable {
        uint256 balanceBefore = address(this).balance;
        WNATIVE.withdraw(_amount);
        uint256 balanceAfter = address(this).balance;
        require(balanceAfter == balanceBefore + _amount, "CWrap: Error unwrapping WNATIVE");
    }

    /**
        @notice Allows a user to unwrap their all their WNATIVE into NATIVE
        @dev Transferred amount is the total balance of WNATIVE
            Note: The WNATIVE must be located on the invoker contract
                The returned NATIVE will be sent to the invoker contract
                This will then need to be MOVED to the user
            Validation checks to support unwrapping of native tokens that may not conform to WETH9
    **/
    function unwrapAllWrappedNative() external payable {
        uint256 balance = WNATIVE.balanceOf(address(this));
        if (balance > 0) {
            uint256 balanceBefore = address(this).balance;
            WNATIVE.withdraw(balance);
            uint256 balanceAfter = address(this).balance;
            require(balanceAfter == balanceBefore + balance, "CWrap: Error unwrapping all");
        }
    }
}

// SPDX-License-Identifier: MIT License
// https://github.com/Synthetixio/synthetix/blob/v2.47.0-ovm/contracts/interfaces/IWETH.sol
pragma solidity ^0.8.6;

interface IWETH {
    // ERC20 Optional Views
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    // Views
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    // Mutative functions
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    // WETH-specific functions.
    function deposit() external payable;

    function withdraw(uint256 amount) external;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Deposit(address indexed to, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);
}
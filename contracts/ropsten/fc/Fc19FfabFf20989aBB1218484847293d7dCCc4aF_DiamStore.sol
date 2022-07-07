// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20Permit {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract DiamStore {
    IERC20Permit public immutable token;

    constructor(address _token) {
        token = IERC20Permit(_token);
    }

    mapping(address => uint256) public userTokens;

    function depositWithPermit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        token.permit(msg.sender, address(this), amount, deadline, v, r, s); //approval
        token.transferFrom(msg.sender, address(this), amount);
        userTokens[msg.sender] += amount;
    }
}
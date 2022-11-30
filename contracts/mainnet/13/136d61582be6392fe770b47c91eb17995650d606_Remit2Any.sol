/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Remit2Any {
    // @dev event storing transfer events
    struct TransferAsset {
        address _from;
        address _token;
        address _to;
        uint256 _amount;
        string _transactionId;
        string _symbol;
        uint128 _decimals;
        uint256 _timestamp;
    }

    // @dev TransferAssetEvent
    event TransferAssetEvent(
        address _from,
        address _to,
        uint256 _amount,
        address _asset,
        string _transactionId,
        uint128 _decimals,
        uint256 _timestamp,
        string _symbol
    );
    mapping(string => TransferAsset) public transactions;

    uint256 private constant MAX_INT =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;

    constructor() {}

    function balanceOf(address _owner, address _token)
        external
        view
        returns (uint256)
    {
        require(_owner != address(0), "Invalid address!");
        return IERC20(_token).balanceOf(_owner);
    }

    function transferAsset(
        address _to,
        address _token,
        uint256 _amount,
        string memory _transactionId,
        string memory _symbol,
        uint128 _decimals,
        uint256 _timestamp
    ) external returns (bool) {
        require(_to != address(0), "Invalid address!");
        require(_token != address(0), "Invalid address!");
        require(_amount > 0, "Amount to be transferred should be greater than 0");

        // Validate ERC20 token balance
        IERC20 erc20Token = IERC20(_token);
        require(erc20Token.balanceOf(msg.sender) >= _amount, "Insufficient erc20 token balance");

        // Get allowance of the token
        // Validate allowance of the erc20Token. Allowance should be greater than equal to the amount needs to be transferred 
        require(
            erc20Token.allowance(msg.sender,address(this)) >= _amount, 
            "Allowance should be greater than equal to the amount needs to be transferred"
        );

        // Approve this contract to spender
        bool isApproved = erc20Token.approve(address(this), _amount);
        require(isApproved, "ERC20 token Approval failure");

        // Perform ERC20 transfer
        bool isTransfered = IERC20(_token).transferFrom(
            msg.sender,
            _to,
            _amount
        );
        require(isTransfered, "ERC20 transfer failure");

        TransferAsset memory _transferedAsset = TransferAsset({
            _from: msg.sender,
            _to: _to,
            _amount: _amount,
            _token: _token,
            _transactionId: _transactionId,
            _symbol: _symbol,
            _decimals: _decimals,
            _timestamp: _timestamp
        });
        transactions[_transactionId] = _transferedAsset;

        // emit event
        emit TransferAssetEvent(
            msg.sender,
            _to,
            _amount,
            _token,
            _transactionId,
            _decimals,
            _timestamp,
            _symbol
        );

        return isTransfered;
    }

    function getTransaction(string memory _transactionId)
        external
        view
        returns (TransferAsset memory _transaction)
    {
        return transactions[_transactionId];
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

import "./RoyaltySplitter.sol";

interface IRegistry {
   function isValidNiftySender(address sender) external view returns (bool);
}

contract RoyaltySplitterFactory {

    address immutable public _registry;
    
    address immutable public _royaltySplitter;

    event RoyaltySplitterCreated(address royaltySplitter);

    constructor(address registry_) {
        _registry = registry_;
        _royaltySplitter = address(new RoyaltySplitter());
    }

    /**
     *
     */
    function createRoyaltySplitter(address[] memory payees, uint256[] memory shares) public { 
        require(IRegistry(_registry).isValidNiftySender(msg.sender), "RoyaltySplitterFactory: invalid msg.sender");
        
        address clone = _createClone(_royaltySplitter);
        RoyaltySplitter(payable(clone)).init(payees, shares);
        emit RoyaltySplitterCreated(clone);
    }

    function _createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }

}

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
}

/**
 * 
 */
contract RoyaltySplitter {
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(address indexed token, address to, uint256 amount);
    event EthPaymentReceived(address from, uint256 amount);

    bool private _initialized;

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(address => uint256) private _erc20TotalReleased;
    mapping(address => mapping(address => uint256)) private _erc20Released;

    function init(address[] memory payees, uint256[] memory shares_) external {
        require(!_initialized, "RoyaltySplitter: already initialized");

        for (uint256 i = 0; i < payees.length; i++) {
            _payees.push(payees[i]);
            _shares[payees[i]] = shares_[i];
            _totalShares = _totalShares + shares_[i];
        }
        _initialized = true;
    }

    /**
     * 
     */
    receive() external payable virtual {
        emit EthPaymentReceived(msg.sender, msg.value);
    }

    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    function totalReleased(address token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    function released(address token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * 
     */
    function release(address payable account) public virtual {
        _release(account);
    }

    function releasePayees() public virtual {
        for(uint256 i = 0; i < _payees.length; i++){
            address payable account = payable(_payees[i]);
            _release(account);
        }
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function _release(address payable account) private {
        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(account, totalReceived, released(account));

        require(payment != 0, "RoyaltySplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        (bool success,) = account.call{value: payment}("");
        require(success, "RoyaltySplitter: value transfer unsuccessful");

        emit PaymentReleased(account, payment);
    }

    /**
     * 
     */
    function release(address token, address account) public virtual {
        require(_shares[account] > 0, "RoyaltySplitter: account has no shares");
        _release(token, account);
    }
    
    function releasePayees(address token) public virtual {
        for(uint256 i = 0; i < _payees.length; i++){
            address payable account = payable(_payees[i]);
            _release(token, account);
        }
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function _release(address token, address account) private {
        uint256 totalReceived = IERC20(token).balanceOf(address(this)) + totalReleased(token);
        uint256 payment = _pendingPayment(account, totalReceived, released(token, account));

        require(payment != 0, "RoyaltySplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, account, payment));
        require(success && (data.length == 0 || abi.decode(data, (bool))));

        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(address account, uint256 totalReceived, uint256 alreadyReleased) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

}
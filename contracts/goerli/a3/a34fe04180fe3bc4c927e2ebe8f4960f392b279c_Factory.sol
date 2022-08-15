/**
 *Submitted for verification at Etherscan.io on 2022-08-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
//Factory->Pair: 分账

contract Pair{

    event PayeeAdded(address account, uint256 shares); 
    event PaymentReleased(address to, uint256 amount); 
    event PaymentReceived(address from, uint256 amount); 

    uint256 public totalShares; 
    uint256 public totalReleased; 

    mapping(address => uint256) public shares; 
    mapping(address => uint256) public released; 
    address[] public payees; 

    address public factory; 

    constructor(address[] memory _payees, uint256[] memory _shares) payable {
        require(_payees.length == _shares.length, "PaymentSplitter: payees and shares length mismatch");
        require(_payees.length > 0, "PaymentSplitter: no payees");
        factory = msg.sender;
        for (uint256 i = 0; i < _payees.length; i++) {
            _addPayee(_payees[i], _shares[i]);
        }
    }

    receive() external payable virtual {
        emit PaymentReceived(msg.sender, msg.value);
    }
        function release(address payable _account) public virtual {
        require(shares[_account] > 0, "PaymentSplitter: account has no shares");
        uint256 payment = releasable(_account);
        require(payment != 0, "PaymentSplitter: account is not due payment");
        totalReleased += payment;
        released[_account] += payment;
        _account.transfer(payment);
        emit PaymentReleased(_account, payment);
    }

    function releasable(address _account) public view returns (uint256) {
        uint256 totalReceived = address(this).balance + totalReleased;
        return pendingPayment(_account, totalReceived, released[_account]);
    }

    function pendingPayment(
        address _account,
        uint256 _totalReceived,
        uint256 _alreadyReleased
    ) public view returns (uint256) {
        return (_totalReceived * shares[_account]) / totalShares - _alreadyReleased;
    }
    function _addPayee(address _account, uint256 _acountShares) private {
        require(msg.sender == factory, "PaymentSplitter: call error");
        require(_account != address(0), "PaymentSplitter: account is the zero address");
        require(_acountShares > 0, "PaymentSplitter: shares are 0");
        require(shares[_account] == 0, "PaymentSplitter: account already has shares");
        payees.push(_account);
        shares[_account] = _acountShares;
        totalShares += _acountShares;
        emit PayeeAdded(_account, _acountShares);
    }
}

contract Factory{
    address[] public allPairs;
    function createPair(address[] memory payees, uint256[] memory shares) external returns(address pairAddr){
        Pair pair = new Pair(payees, shares); 
        pairAddr = address(pair);
        allPairs.push(pairAddr);
    }
}
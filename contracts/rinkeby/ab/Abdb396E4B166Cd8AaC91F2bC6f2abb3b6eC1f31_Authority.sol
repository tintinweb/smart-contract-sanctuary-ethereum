// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./SafeMath.sol";

/**
 * Chimp Authority Contract
 */
contract Authority {
    using SafeMath for uint256;

    /* ========== EVENTS ========== */
    event OwnerPushed(address indexed from, address indexed to);
    event OwnerPulled(address indexed from, address indexed to);
    event AddApprover(address addrs);
    event DeleteApprover(address addrs);
    event SetRate(uint256 oldRate, uint256 newRate);

    string UNAUTHORIZED = "UNAUTHORIZED";

    uint256 public approveRate;// 审批通过的百分比，以100为基数
    address public owner;
    address public newOwner;
    address[] public approvers;
    // 
    mapping (address => address[]) private addApprove;

    mapping (address => address[]) private delApprove;

    address[] private setRateApprove;

    uint256 private newRate;

    constructor(address _approver, uint256 _approveRate) {
        require(_approver != address(0), "Authority: addr can't be null");
        require(_approveRate >= 50 && _approveRate <= 100, "Authority: illegal rate");
        owner = msg.sender;
        approvers.push(_approver);
        approveRate = _approveRate;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, UNAUTHORIZED);
        _;
    }

    modifier onlyApprover() {
        bool isApprover;
        uint256 idx;
        (isApprover, idx) = checkIsApprover(msg.sender);
        require(isApprover, UNAUTHORIZED);
        _;
    }

    function pushOwner(address _newOwner, bool _effectiveImmediately)
        external
        onlyOwner
    {
        address oldOwner = owner;
        if (_effectiveImmediately) {
            owner = _newOwner;
        }
        newOwner = _newOwner;
        emit OwnerPushed(oldOwner, newOwner);
    }

    function pullOwner() external {
        require(msg.sender == newOwner, "Authority: not newOwner");
        emit OwnerPulled(owner, newOwner);
        owner = newOwner;
    }

    function setRate(uint256 _rate) public virtual onlyApprover {
        require(newRate == 0 || (newRate == _rate), "Authority: illegal rate");
        require(_rate != approveRate && _rate >= 50 && _rate <= 100, "Authority: illegal rate");
        setRateApprove.push(msg.sender);
        // 检查已审批人数是否已经达到approveRate比例
        if (checkRate(setRateApprove.length)) {
            // 已审批通过的，将_addr添加为正式的审批管理员，并将_addr从approvedMap中移除掉
            emit SetRate(approveRate, _rate);
            approveRate = _rate;
            delete newRate;
            delete setRateApprove;
            return;
        }
        if (newRate == 0) {
            newRate = _rate;
        }
    }

    function addApprover(address _addr) public virtual onlyApprover {
        require(_addr != address(0), "Authority: addr can't be null");
        bool isApprover;
        uint256 idx;
        (isApprover, idx) = checkIsApprover(_addr);
        require(!isApprover, "Authority: approver repeat");
        addApprove[_addr].push(msg.sender);
        // 检查已审批人数是否已经达到approveRate比例
        if (checkRate(addApprove[_addr].length)) {
            // 已审批通过的，将_addr添加为正式的审批管理员，并将_addr从approvedMap中移除掉
            approvers.push(_addr);
            delete addApprove[_addr];
            emit AddApprover(_addr);
        }
    }

    function deleteApprover(address _addr) public virtual onlyApprover {
        require(_addr != address(0), "Authority: addr can't be null");
        bool isApprover;
        uint256 idx;
        (isApprover, idx) = checkIsApprover(_addr);
        require(!isApprover, "Authority: approver repeat");
        delApprove[_addr].push(msg.sender);
        // 检查已审批人数是否已经达到approveRate比例
        if (checkRate(delApprove[_addr].length)) {
            // 已审批通过的，将_addr添加为正式的审批管理员，并将_addr从approvedMap中移除掉
            approvers.push(_addr);
            delete addApprove[_addr];
            emit DeleteApprover(_addr);
        }
    }

    function checkIsApprover(address addr) public view returns (bool, uint256) {
        for (uint256 i = 0; i < approvers.length; i++) {
            if (approvers[i] == addr) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function checkRate(uint256 _length) public view returns (bool) {
        return _length.mul(100).div(approvers.length) >= approveRate;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// TODO(zx): Replace all instances of SafeMath with OZ implementation
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

}
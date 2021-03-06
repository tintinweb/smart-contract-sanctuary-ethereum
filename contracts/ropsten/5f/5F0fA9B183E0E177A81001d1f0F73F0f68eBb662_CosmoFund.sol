// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./libraries/SafeMath.sol";
import "./utils/Approvable.sol";

interface IERC20Short {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
}

/**
 * CosmoFund Contract
 * https://cosmofund.space/
 */
contract CosmoFund is Approvable {
    using SafeMath for uint256;
    string private _url;

    struct Transfer {
        uint256 id;
        bool executed;
        address token;
        uint256 amount;
        address payable to;
        uint256 approvalsWeight;
    }
    Transfer[] private _transfers;
    mapping(address => mapping(uint256 => bool)) private _approvalsTransfer;

    event NewTransfer(uint256 indexed id, address indexed token, uint256 amount, address indexed to);
    event VoteForTransfer(uint256 indexed id, address indexed voter, uint256 voterWeight, uint256 approvalsWeight);
    event Transferred(uint256 indexed id, address indexed token, uint256 amount, address indexed to);

    constructor(uint256 weight, uint256 threshold) public {
        _setupApprover(_msgSender(), weight);
        _setupThreshold(threshold);
        _setURL("https://CosmoFund.space/");
    }

    function url() public view returns (string memory) {
        return _url;
    }

    function setURL(string memory newUrl) public onlyApprover {
        _setURL(newUrl);
    }

    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    function balanceERC20(address token) public view returns (uint256) {
        return IERC20Short(token).balanceOf(address(this));
    }


    // Transfer
    function transfersCount() public view returns (uint256) {
        return _transfers.length;
    }

    function getTransfer(uint256 id) public view returns (Transfer memory) {
        return _transfers[id];
    }

    function createTransferETH(uint256 amount, address payable to) public onlyApprover returns (uint256) {
        uint256 id = _addNewTransfer(address(0), amount, to);
        _voteForTransfer(id);
        return id;
    }

    function createTransferERC20(address token, uint256 amount, address payable to) public onlyApprover returns (uint256) {
        uint256 id = _addNewTransfer(token, amount, to);
        _voteForTransfer(id);
        return id;
    }

    function approveTransfer(uint256 id) public onlyApprover returns (bool) {
        require(_transfers[id].executed == false, "CosmoFund: Transfer has already executed");
        require(_approvalsTransfer[_msgSender()][id] == false, "CosmoFund: Cannot approve transfer twice");
        return _voteForTransfer(id);
    }

    function executeTransfer(uint256 id) public onlyApprover returns (bool) {
        if (_transfers[id].approvalsWeight >= getThreshold())
            return _executeTransfer(id);
        return false;
    }

    function _addNewTransfer(address token, uint256 amount, address payable to) private returns (uint256) {
        require(to != address(0), "CosmoFund: to is the zero address");
        uint256 id = _transfers.length;
        _transfers.push(Transfer(id, false, token, amount, to, 0));
        emit NewTransfer(id, token, amount, to);
        return id;
    }

    function _voteForTransfer(uint256 id) private returns (bool) {
        address msgSender = _msgSender();
        _approvalsTransfer[msgSender][id] = true;
        _transfers[id].approvalsWeight = _transfers[id].approvalsWeight.add(getApproverWeight(msgSender));
        emit VoteForTransfer(id, msgSender, getApproverWeight(msgSender), _transfers[id].approvalsWeight);
        if (_transfers[id].approvalsWeight >= getThreshold())
            _executeTransfer(id);
        return true;
    }

    function _executeTransfer(uint256 id) private returns (bool) {
        if (_transfers[id].token == address(0))
            require(_executeTransferETH(id), "CosmoFund: Failed to transfer ETH");
        else
            require(_executeTransferERC20(id), "CosmoFund: Failed to transfer ERC20");
        _transfers[id].executed = true;
        emit Transferred(_transfers[id].id, _transfers[id].token, _transfers[id].amount, _transfers[id].to);
        return true;
    }

    function _executeTransferETH(uint256 id) private returns (bool) {
        return _transfers[id].to.send(_transfers[id].amount);
    }

    function _executeTransferERC20(uint256 id) private returns (bool) {
        return IERC20Short(_transfers[id].token).transfer(_transfers[id].to, _transfers[id].amount);
    }

    function _setURL(string memory newUrl) private {
        _url = newUrl;
    }
    
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 */
library EnumerableAddressSet {
    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastvalue = set._values[lastIndex];
            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = toDeleteIndex + 1;
            set._values.pop();
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet
    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 */
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "../libraries/Address.sol";
import "../libraries/EnumerableAddressSet.sol";
import "../libraries/SafeMath.sol";
import "./Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 */
abstract contract Approvable is Context {
    using EnumerableAddressSet for EnumerableAddressSet.AddressSet;
    using SafeMath for uint256;
    using Address for address;

    EnumerableAddressSet.AddressSet _approvers;
    mapping(address => uint256) private _weights;
    uint256 private _totalWeight;
    uint256 private _threshold;


    struct GrantApprover {
        uint256 id;
        bool executed;
        address account;
        uint256 weight;
        uint256 approvalsWeight;
    }
    GrantApprover[] private _grantApprovers;
    mapping(address => mapping(uint256 => bool)) private _approvalsGrantApprover;


    struct ChangeApproverWeight {
        uint256 id;
        bool executed;
        address account;
        uint256 weight;
        uint256 approvalsWeight;
    }
    ChangeApproverWeight[] private _changeApproverWeights;
    mapping(address => mapping(uint256 => bool)) private _approvalsChangeApproverWeight;


    struct RevokeApprover {
        uint256 id;
        bool executed;
        address account;
        uint256 approvalsWeight;
    }
    RevokeApprover[] private _revokeApprovers;
    mapping(address => mapping(uint256 => bool)) private _approvalsRevokeApprover;


    struct ChangeThreshold {
        uint256 id;
        bool executed;
        uint256 threshold;
        uint256 approvalsWeight;
    }
    ChangeThreshold[] private _changeThresholds;
    mapping(address => mapping(uint256 => bool)) private _approvalsChangeThreshold;


    event NewGrantApprover(uint256 indexed id, address indexed account, uint256 weight);
    event VoteForGrantApprover(uint256 indexed id, address indexed voter, uint256 voterWeight, uint256 approvalsWeight);
    event ApproverGranted(address indexed account);

    event NewChangeApproverWeight(uint256 indexed id, address indexed account, uint256 weight);
    event VoteForChangeApproverWeight(uint256 indexed id, address indexed voter, uint256 voterWeight, uint256 approvalsWeight);
    event ApproverWeightChanged(address indexed account, uint256 oldWeight, uint256 newWeight);

    event NewRevokeApprover(uint256 indexed id, address indexed account);
    event VoteForRevokeApprover(uint256 indexed id, address indexed voter, uint256 voterWeight, uint256 approvalsWeight);
    event ApproverRevoked(address indexed account);

    event NewChangeThreshold(uint256 indexed id, uint256 threshold);
    event VoteForChangeThreshold(uint256 indexed id, address indexed voter, uint256 voterWeight, uint256 approvalsWeight);
    event ThresholdChanged(uint256 oldThreshold, uint256 newThreshold);

    event TotalWeightChanged(uint256 oldTotalWeight, uint256 newTotalWeight);


    function getThreshold() public view returns (uint256) {
        return _threshold;
    }

    function getTotalWeight() public view returns (uint256) {
        return _totalWeight;
    }

    function getApproversCount() public view returns (uint256) {
        return _approvers.length();
    }

    function isApprover(address account) public view returns (bool) {
        return _approvers.contains(account);
    }

    function getApprover(uint256 index) public view returns (address) {
        return _approvers.at(index);
    }

    function getApproverWeight(address account) public view returns (uint256) {
        return _weights[account];
    }


    // GrantApprovers
    function getGrantApproversCount() public view returns (uint256) {
        return _grantApprovers.length;
    }

    function getGrantApprover(uint256 id) public view returns (GrantApprover memory) {
        return _grantApprovers[id];
    }

    // ChangeApproverWeights
    function getChangeApproverWeightsCount() public view returns (uint256) {
        return _changeApproverWeights.length;
    }

    function getChangeApproverWeight(uint256 id) public view returns (ChangeApproverWeight memory) {
        return _changeApproverWeights[id];
    }

    // RevokeApprovers
    function getRevokeApproversCount() public view returns (uint256) {
        return _revokeApprovers.length;
    }

    function getRevokeApprover(uint256 id) public view returns (RevokeApprover memory) {
        return _revokeApprovers[id];
    }

    // ChangeThresholds
    function getChangeThresholdsCount() public view returns (uint256) {
        return _changeThresholds.length;
    }

    function getChangeThreshold(uint256 id) public view returns (ChangeThreshold memory) {
        return _changeThresholds[id];
    }


    // Grant Approver
    function grantApprover(address account, uint256 weight) public onlyApprover returns (uint256) {
        uint256 id = _addNewGrantApprover(account, weight);
        _voteForGrantApprover(id);
        return id;
    }

    function _addNewGrantApprover(address account, uint256 weight) private returns (uint256) {
        require(account != address(0), "Approvable: account is the zero address");
        uint256 id = _grantApprovers.length;
        _grantApprovers.push(GrantApprover(id, false, account, weight, 0));
        emit NewGrantApprover(id, account, weight);
        return id;
    }

    function _voteForGrantApprover(uint256 id) private returns (bool) {
        address msgSender = _msgSender();
        _approvalsGrantApprover[msgSender][id] = true;
        _grantApprovers[id].approvalsWeight = _grantApprovers[id].approvalsWeight.add(_weights[msgSender]);
        emit VoteForGrantApprover(id, msgSender, _weights[msgSender], _grantApprovers[id].approvalsWeight);
        if (_grantApprovers[id].approvalsWeight >= _threshold) {
            _grantApprovers[id].executed = true;
        }
        return true;
    }

    function _grantApprover(address account, uint256 weight) private returns (bool) {
        if (_approvers.add(account)) {
            _changeApproverWeight(account, weight);
            _setTotalWeight(_totalWeight.add(weight));
            emit ApproverGranted(account);
            return true;
        }
        return false;
    }

    function _setupApprover(address account, uint256 weight) internal returns (bool) {
        return _grantApprover(account, weight);
    }

    function approveGrantApprover(uint256 id) public onlyApprover returns (bool) {
        require(_grantApprovers[id].executed == false, "Approvable: action has already executed");
        require(_approvalsGrantApprover[_msgSender()][id] == false, "Approvable: Cannot approve action twice");
        return _voteForGrantApprover(id);
    }

    function confirmGrantApprover(uint256 id) public returns (bool) {
        require(_grantApprovers[id].account == _msgSender(), "Approvable: only pending approver");
        require(_grantApprovers[id].executed == true, "Approvable: action not approved");
        return _grantApprover(_grantApprovers[id].account, _grantApprovers[id].weight);
    }


    // Change Approver Weight
    function changeApproverWeight(address account, uint256 weight) public onlyApprover returns (uint256) {
        uint256 id = _addNewChangeApproverWeight(account, weight);
        _voteForChangeApproverWeight(id);
        return id;
    }

    function _addNewChangeApproverWeight(address account, uint256 weight) private returns (uint256) {
        require(account != address(0), "Approvable: account is the zero address");
        uint256 id = _changeApproverWeights.length;
        _changeApproverWeights.push(ChangeApproverWeight(id, false, account, weight, 0));
        emit NewChangeApproverWeight(id, account, weight);
        return id;
    }

    function _voteForChangeApproverWeight(uint256 id) private returns (bool) {
        address msgSender = _msgSender();
        _approvalsChangeApproverWeight[msgSender][id] = true;
        _changeApproverWeights[id].approvalsWeight = _changeApproverWeights[id].approvalsWeight.add(_weights[msgSender]);
        emit VoteForChangeApproverWeight(id, msgSender, _weights[msgSender], _changeApproverWeights[id].approvalsWeight);
        if (_changeApproverWeights[id].approvalsWeight >= _threshold) {
            _changeApproverWeights[id].executed = true;
            _changeApproverWeight(_changeApproverWeights[id].account, _changeApproverWeights[id].weight);
        }
        return true;
    }

    function _changeApproverWeight(address account, uint256 weight) private returns (bool) {
        emit ApproverWeightChanged(account, _weights[account], weight);
        _weights[account] = weight;
        return true;
    }

    function approveChangeApproverWeight(uint256 id) public onlyApprover returns (bool) {
        require(_changeApproverWeights[id].executed == false, "Approvable: action has already executed");
        require(_approvalsChangeApproverWeight[_msgSender()][id] == false, "Approvable: Cannot approve action twice");
        return _voteForChangeApproverWeight(id);
    }


    // Revoke Approver
    function revokeApprover(address account) public onlyApprover returns (uint256) {
        uint256 id = _addNewRevokeApprover(account);
        _voteForRevokeApprover(id);
        return id;
    }

    function _addNewRevokeApprover(address account) private returns (uint256) {
        require(account != address(0), "Approvable: account is the zero address");
        uint256 id = _revokeApprovers.length;
        _revokeApprovers.push(RevokeApprover(id, false, account, 0));
        emit NewRevokeApprover(id, account);
        return id;
    }

    function _voteForRevokeApprover(uint256 id) private returns (bool) {
        address msgSender = _msgSender();
        _approvalsRevokeApprover[msgSender][id] = true;
        _revokeApprovers[id].approvalsWeight = _revokeApprovers[id].approvalsWeight.add(_weights[msgSender]);
        emit VoteForRevokeApprover(id, msgSender, _weights[msgSender], _revokeApprovers[id].approvalsWeight);
        if (_revokeApprovers[id].approvalsWeight >= _threshold) {
            _revokeApprovers[id].executed = true;
            _revokeApprover(_revokeApprovers[id].account);
        }
        return true;
    }

    function _revokeApprover(address account) private returns (bool) {
        uint256 oldWeight = _weights[account];
        require(_totalWeight.sub(oldWeight) >= _threshold, "Approvable: new totalWeight less then threshold");
        if (_approvers.remove(account)) {
            _changeApproverWeight(account, 0);
            _setTotalWeight(_totalWeight.sub(oldWeight));
            emit ApproverRevoked(account);
            return true;
        }
        return false;
    }

    function approveRevokeApprover(uint256 id) public onlyApprover returns (bool) {
        require(_revokeApprovers[id].executed == false, "Approvable: action has already executed");
        require(_approvalsRevokeApprover[_msgSender()][id] == false, "Approvable: Cannot approve action twice");
        return _voteForRevokeApprover(id);
    }

    function renounceApprover(address account) public returns (bool) {
        require(account == _msgSender(), "Approvable: can only renounce roles for self");
        return _revokeApprover(account);
    }


    // Change Threshold
    function changeThreshold(uint256 threshold) public onlyApprover returns (uint256) {
        uint256 id = _addNewChangeThreshold(threshold);
        _voteForChangeThreshold(id);
        return id;
    }

    function _addNewChangeThreshold(uint256 threshold) private returns (uint256) {
        uint256 id = _changeThresholds.length;
        _changeThresholds.push(ChangeThreshold(id, false, threshold, 0));
        emit NewChangeThreshold(id, threshold);
        return id;
    }

    function _voteForChangeThreshold(uint256 id) private returns (bool) {
        address msgSender = _msgSender();
        _approvalsChangeThreshold[msgSender][id] = true;
        _changeThresholds[id].approvalsWeight = _changeThresholds[id].approvalsWeight.add(_weights[msgSender]);
        emit VoteForChangeThreshold(id, msgSender, _weights[msgSender], _changeThresholds[id].approvalsWeight);
        if (_changeThresholds[id].approvalsWeight >= _threshold) {
            _changeThresholds[id].executed = true;
            _setThreshold(_changeThresholds[id].threshold);
        }
        return true;
    }

    function approveChangeThreshold(uint256 id) public onlyApprover returns (bool) {
        require(_changeThresholds[id].executed == false, "Approvable: action has already executed");
        require(_approvalsChangeThreshold[_msgSender()][id] == false, "Approvable: Cannot approve action twice");
        return _voteForChangeThreshold(id);
    }

    function _setThreshold(uint256 threshold) private returns (bool) {
        emit ThresholdChanged(_threshold, threshold);
        _threshold = threshold;
        return true;
    }

    function _setupThreshold(uint256 threshold) internal returns (bool) {
        return _setThreshold(threshold);
    }


    // Total Weight
    function _setTotalWeight(uint256 totalWeight) private returns (bool) {
        emit TotalWeightChanged(_totalWeight, totalWeight);
        _totalWeight = totalWeight;
        return true;
    }

    modifier onlyApprover() {
        require(isApprover(_msgSender()), "Approvable: caller is not the approver");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction.
 */
abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}
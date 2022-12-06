// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

error BalanceDepositOverflow();
error BalanceWithdrawOverflow();

contract DonutBox {
    enum BoxState {
        Disactivated,
        Activated
    }

    struct Box {
        uint256 balance;
        BoxState state;
    }

    mapping(address => Box) private _boxes;

    event DonutBoxActivated(address indexed user, uint256 timestamp);
    event DonutBoxDeactivated(address indexed user, uint256 timestamp);
    event Withdrawn(address indexed user, uint256 amount, uint256 timestamp);

    function _activateBox(address _user) internal virtual {
        _boxes[_user].state = BoxState.Activated;
    }

    function _deactivateBox(address _user) internal virtual {
        _boxes[_user].state = BoxState.Disactivated;
    }

    function _isBoxActivated(
        address _user
    ) internal view virtual returns (bool) {
        return _boxes[_user].state == BoxState.Activated;
    }

    function _deposit(address _user, uint256 _amount) internal virtual {
        unchecked {
            uint256 balance = _boxes[_user].balance;
            uint256 deposited = balance + _amount;
            if (deposited < balance) revert BalanceDepositOverflow();
            _boxes[_user].balance = deposited;
        }
    }

    function _withdraw(address _user, uint256 _amount) internal virtual {
        unchecked {
            uint256 balance = _boxes[_user].balance;
            if (_amount > balance) revert BalanceWithdrawOverflow();
            _boxes[_user].balance = balance - _amount;
        }
    }

    function _boxOf(address _user) internal view virtual returns (Box memory) {
        return _boxes[_user];
    }

    function _balanceOf(address _user) internal view virtual returns (uint256) {
        return _boxes[_user].balance;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

error UserIndexToAddressNotMatched();

abstract contract User {
    address[] private _users;

    mapping(address => bool) private _registered;
    mapping(address => uint256) private _userIndex;

    event UserRegistered(address user, bool success, uint256 timestamp);
    event UserUnregistered(address user, bool success, uint256 timestamp);

    modifier onlyUser() {
        require(_isUser(msg.sender), "not a valid user");
        _;
    }

    function _register(address _newUser) internal virtual {
        _registered[_newUser] = true;

        _users.push(_newUser);
        _userIndex[_newUser] = _users.length - 1;
    }

    function _unregister(address _userToDelete) internal virtual {
        uint256 index = _userIndex[_userToDelete];

        if (_users[index] != _userToDelete)
            revert UserIndexToAddressNotMatched();

        _registered[_userToDelete] = false;

        _users[index] = _users[_users.length - 1];
        _userIndex[_users[_users.length - 1]] = index;

        _users.pop();
        delete _userIndex[_userToDelete];
    }

    function _isUser(address _addr) internal view virtual returns (bool) {
        return _registered[_addr];
    }

    function _getUsers() internal view virtual returns (address[] memory) {
        return _users;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "./account/User.sol";
import "./account/DonutBox.sol";

contract Accounts is User, DonutBox {
    function _withdraw(
        address user,
        uint256 amount
    ) internal override(DonutBox) {
        super._withdraw(user, amount);

        (bool ok, ) = payable(user).call{value: amount}("");
        if (!ok) {
            _deposit(user, amount);
            revert("failed to withdraw balance");
        }
    }

    function _settleDonutBox(address user) internal {
        uint256 balance = _balanceOf(user);
        if (balance > 0) {
            _withdraw(user, balance);
        }
    }

    function _settleDonutBoxes() internal {
        address[] memory users = _getUsers();

        for (uint256 i = 0; i < users.length; i++) {
            _settleDonutBox(users[i]);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;

        emit OwnershipTransferred(address(0), _owner);
    }

    modifier onlyOwner() {
        require(_isOwner(), "only allowed for owner");
        _;
    }

    function _isOwner() internal view virtual returns (bool) {
        return msg.sender == _owner;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        _owner = _newOwner;

        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

error TotalPaymentCalculationOverflow();
error BaseFeeCalculationToZero();

abstract contract Support {
    uint256 public constant DONUT = 0.003 ether;

    struct SupportReceipt {
        address from;
        address to;
        uint256 amount;
        string message;
        uint256 timestamp;
    }

    SupportReceipt[] private _supportReceipts;
    mapping(address => uint256[]) private _receiptIndicesOfSupporter;
    mapping(address => uint256[]) private _receiptIndicesOfBeneficiary;

    event DonutSupported(
        address indexed from,
        address indexed to,
        uint256 amount,
        string message,
        uint256 timestamp
    );

    function _calculateTotalPayment(
        uint256 _amount
    ) internal pure returns (uint256) {
        unchecked {
            uint256 totalPayment = DONUT * _amount;
            if (totalPayment / _amount != DONUT)
                revert TotalPaymentCalculationOverflow();
            return totalPayment;
        }
    }

    function _calculateBaseFee(
        uint256 _payment
    ) internal pure returns (uint256) {
        unchecked {
            uint fee = _payment / 100;
            if (fee == 0) revert BaseFeeCalculationToZero();
            return fee;
        }
    }

    function _addSupportReceipt(
        address _from,
        address _to,
        uint256 _amount,
        string memory _message
    ) internal {
        SupportReceipt memory newReceipt = SupportReceipt(
            _from,
            _to,
            _amount,
            _message,
            block.timestamp
        );

        _supportReceipts.push(newReceipt);

        uint256 receiptIndex = _supportReceipts.length - 1;

        _receiptIndicesOfSupporter[_from].push(receiptIndex);
        _receiptIndicesOfBeneficiary[_to].push(receiptIndex);
    }

    function _getReceiptsOfSupporter(
        address _supporter
    ) internal view returns (SupportReceipt[] memory) {
        uint256[] memory indices = _receiptIndicesOfSupporter[_supporter];

        SupportReceipt[] memory result = new SupportReceipt[](indices.length);

        for (uint256 i = 0; i < indices.length; i++) {
            result[i] = _supportReceipts[indices[i]];
        }

        return result;
    }

    function _getReceiptsOfBeneficiary(
        address _beneficiary
    ) internal view returns (SupportReceipt[] memory) {
        uint256[] memory indices = _receiptIndicesOfBeneficiary[_beneficiary];

        SupportReceipt[] memory result = new SupportReceipt[](indices.length);

        for (uint256 i = 0; i < indices.length; i++) {
            result[i] = _supportReceipts[indices[i]];
        }

        return result;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "./donation/Support.sol";
import "./Accounts.sol";

error BaseFeeExceptionOverflow();

contract DonutConnector is Accounts, Support {
    function _transferExceptFee(
        address _to,
        uint256 _payment
    ) internal virtual {
        unchecked {
            uint256 fee = _calculateBaseFee(_payment);
            if (fee > _payment) revert BaseFeeExceptionOverflow();
            _payment -= fee;
            _deposit(_to, _payment);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "./auth/Ownable.sol";
import "./DonutConnector.sol";
import "./utils/ReentrancyGuard.sol";

contract TreatADonut is Ownable, DonutConnector, ReentrancyGuard {
    constructor() Ownable() {
        register();
    }

    function register() public {
        address newUser = msg.sender;

        require(!_isUser(newUser), "yet a valid user");

        _register(newUser);

        emit UserRegistered(newUser, true, block.timestamp);

        _activateBox(newUser);

        emit DonutBoxActivated(newUser, block.timestamp);
    }

    function unregister() external onlyUser {
        require(!_isOwner(), "not allowed for owner");

        address userToDelete = msg.sender;

        _unregister(userToDelete);

        emit UserUnregistered(userToDelete, true, block.timestamp);

        _deactivateBox(userToDelete);

        emit DonutBoxDeactivated(userToDelete, block.timestamp);
    }

    function activateBox() external onlyUser {
        require(!_isBoxActivated(msg.sender), "yet a activated box");

        _activateBox(msg.sender);

        emit DonutBoxActivated(msg.sender, block.timestamp);
    }

    function deactivateBox() external onlyUser {
        require(_isBoxActivated(msg.sender), "not activated box");

        _deactivateBox(msg.sender);

        emit DonutBoxDeactivated(msg.sender, block.timestamp);
    }

    function supportDonut(
        address _to,
        uint256 _amount,
        string memory _message
    ) external payable {
        require(_amount > 0, "zero amount not allowed");

        address from = msg.sender;

        require(_to != from, "supporting yourself not allowed");
        require(_isUser(_to), "not a valid user");
        require(_isBoxActivated(_to), "not activated box");

        uint256 totalPayment = _calculateTotalPayment(_amount);
        require(msg.value >= totalPayment, "not enough payment");

        _transferExceptFee(_to, totalPayment);
        _addSupportReceipt(from, _to, _amount, _message);

        emit DonutSupported(from, _to, _amount, _message, block.timestamp);
    }

    function withdraw(uint256 _amount) external onlyUser lock {
        require(_amount > 0, "zero amount not allowed");

        address user = msg.sender;

        require(_isBoxActivated(user), "not activated box");
        require(_balanceOf(user) >= _amount, "not enough balance");

        _withdraw(user, _amount);

        emit Withdrawn(user, _amount, block.timestamp);
    }

    function getReceiptsOfSupporter(
        address _supporter
    ) external view returns (SupportReceipt[] memory) {
        return _getReceiptsOfSupporter(_supporter);
    }

    function getReceiptsOfBeneficiary(
        address _beneficiary
    ) external view returns (SupportReceipt[] memory) {
        return _getReceiptsOfBeneficiary(_beneficiary);
    }

    function isUser(address _user) external view returns (bool) {
        return _isUser(_user);
    }

    function getUsers() external view returns (address[] memory) {
        return _getUsers();
    }

    function boxOf(address _user) external view returns (Box memory) {
        return _boxOf(_user);
    }

    function destroyContract() external onlyOwner lock {
        _settleDonutBoxes();

        selfdestruct(payable(address(this)));
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

abstract contract ReentrancyGuard {
    bool private _locked;

    modifier lock() {
        require(!_locked, "reentrency detected");
        _locked = true;
        _;
        _locked = false;
    }
}
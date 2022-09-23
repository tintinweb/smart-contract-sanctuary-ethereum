/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}





            

pragma solidity >= 0.8.0;


library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FROM_FAILED');
    }

    function safeTransferNative(address payable to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TRANSFER_FAILED');
    }
}




            



pragma solidity ^0.8.0;




abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor() {
        _transferOwnership(_msgSender());
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}





            



pragma solidity ^0.8.0;


interface IERC20 {
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);

    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address to, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}





pragma solidity >= 0.8.13;




contract FeeStation is Ownable {
    struct FeeRecord {
        uint amount;
        bool listed;
    }
    event EventPayment(uint eventId, address token, uint totalAmount, address payer, uint increaseAmount);
    event Withdraw(address token, address to, uint amount);
    event PaymentChange(address token, bool isOpen);
    mapping(address => bool) public availablePayments;
    mapping(uint => mapping(address => FeeRecord)) public records;
    mapping(uint => address[]) internal eventPayments;

    constructor(address[] memory tokens) {
        uint length = tokens.length;
        for(uint i = 0; i < length; i++) {
            supportPayment(tokens[i], true);
        }
    }

    function supportPayment(address token, bool isOpen) public {
        availablePayments[token] = isOpen;
        emit PaymentChange(token, isOpen);
    }

    function _savePayment(uint eventId, address token) internal {
        address[] storage payments = eventPayments[eventId];
        if (!records[eventId][token].listed) {
            payments.push(token);
            records[eventId][token].listed = true;
        }
    }

    function getPayments(uint eventId) external view returns (address[] memory) {
        uint length = eventPayments[eventId].length;
        address[] memory payments = new address[](length);
        for(uint i = 0; i < length; i++ ) {
            payments[i] = eventPayments[eventId][i];
        }
        return payments;
    }

    function pay(uint eventId, address token, uint amount) external payable {
        require(availablePayments[token], "payment token not support");
        if (token == address(0)) {
            require(msg.value >= amount, "amount error");
        } else {
            TransferHelper.safeTransferFrom(token, msg.sender, address(this), amount);
        }
        _savePayment(eventId, token);
        FeeRecord storage rec = records[eventId][token];
        rec.amount += amount;
        emit EventPayment(eventId, token, rec.amount, msg.sender, amount);
    }

    function withdraw(address token) external onlyOwner {
        if (token == address(0)) {
            uint amount = address(this).balance;
            TransferHelper.safeTransferNative(payable(msg.sender), amount);
            emit Withdraw(token, msg.sender, amount);
        } else {
            uint amount = IERC20(token).balanceOf(address(this));
            TransferHelper.safeTransfer(token, msg.sender, amount);
            emit Withdraw(token, msg.sender, amount);
        }
    }
}
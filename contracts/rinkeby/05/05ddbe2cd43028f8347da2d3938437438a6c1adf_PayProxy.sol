// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ownership/Ownable.sol";

abstract contract BasePayProxy is Ownable {

    uint256 public rate;

    uint256 public fixedRate;

    address public IPay ;


    mapping(address => mapping(address => uint256)) public merchantFunds;

    mapping(address => mapping(string => address)) public merchantOrders;

    mapping(address => uint256) public tradeFeeOf;


    event Order(string orderId, uint256 paidAmount,address paidToken,uint256 orderAmount,address settleToken,uint256 fee,address merchant, address payer, bool isFixedRate);

    event Withdraw(address merchant, address settleToken, uint256 settleAmount, address settleAccount);

    event WithdrawTradeFee(address _token, uint256 _fee);


    receive() payable external {}


    function withdrawTradeFee(address _token) external onlyOwner {
        bytes memory data = abi.encodeWithSignature("withdrawTradeFee(address)", _token);
        assembly {
            let pointer := mload(0x40)
            if iszero(delegatecall(not(0), sload(IPay.slot), add(data,32), mload(data), pointer, 0x20)) {
                revert(0, 0)
            }
        }
    }

    function setRate(uint256 _newRate) external onlyOwner {
        rate = _newRate;
    }

    function setFixedRate(uint256 _newFixedRate) external onlyOwner {
        fixedRate = _newFixedRate;
    }

    function setIPay(address _IPay) external onlyOwner {
        IPay = _IPay;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BasePayProxy.sol";

contract PayProxy is BasePayProxy {

    constructor(uint256 _rate, uint256 _fixedRate, address _IPay){
        owner = msg.sender;
        rate = _rate;
        fixedRate = _fixedRate;
        IPay = _IPay;
    }


    function pay(
        string memory _orderId,
        uint256 _paiAmount,
        uint256 _orderAmount,
        address _merchant,
        address _currency
    ) external returns(bool) {
        bytes memory data = abi.encodeWithSignature("pay(string,uint256,uint256,address,address)", _orderId, _paiAmount,_orderAmount,_merchant,_currency);
        assembly {
            let pointer := mload(0x40)
            if iszero(delegatecall(not(0), sload(IPay.slot), add(data,32), mload(data), pointer, 0x20)) {
                revert(0, 0)
            }
            let result := returndatasize()
            returndatacopy(pointer, 0, result)
            return(pointer,result)
        }
    }

    function payWithETH(
        string memory _orderId,
        address _merchant,
        uint256 _orderAmount
    ) external payable returns(bool) {
        bytes memory data = abi.encodeWithSignature("payWithETH(string,address,uint256)", _orderId, _merchant,_orderAmount);
        assembly {
            let pointer := mload(0x40)
            if iszero(delegatecall(not(0), sload(IPay.slot), add(data,32), mload(data), pointer, 0x20)) {
                revert(0, 0)
            }
            let result := returndatasize()
            returndatacopy(pointer, 0, result)
            return(pointer,result)
        }
    }


    function claimToken(
        address _currency,
        uint256 _amount,
        address _withdrawAddress
    ) external {
        bytes memory data = abi.encodeWithSignature("claimToken(address,uint256,address)", _currency, _amount,_withdrawAddress);
        assembly {
            let pointer := mload(0x40)
            if iszero(delegatecall(not(0), sload(IPay.slot), add(data,32), mload(data), pointer, 0x20)) {
                revert(0, 0)
            }
            let result := returndatasize()
            returndatacopy(pointer, 0, result)
            return(pointer,result)
        }
    }

    function claimAllToken(address _to) external {
        bytes memory data = abi.encodeWithSignature("claimAllToken(address)", _to);
        assembly {
            let pointer := mload(0x40)
            if iszero(delegatecall(not(0), sload(IPay.slot), add(data,32), mload(data), pointer, 0x20)) {
                revert(0, 0)
            }
        }
    }

    function claimEth(
        uint256 _amount,
        address _withdrawAddress
    ) external {
        bytes memory data = abi.encodeWithSignature("claimEth(uint256,address)", _amount, _withdrawAddress);
        assembly {
            let pointer := mload(0x40)
            if iszero(delegatecall(not(0), sload(IPay.slot), add(data,32), mload(data), pointer, 0x20)) {
                revert(0, 0)
            }
            let result := returndatasize()
            returndatacopy(pointer, 0, result)
            return(pointer,result)
        }

    }

    function getEstimated(address tokenIn, address tokenOut, uint256 amountOut) external payable returns (uint256) {

        bytes memory data = abi.encodeWithSignature("getEstimated(address,address,uint256)", tokenIn, tokenOut, amountOut);
        assembly {
            let pointer := mload(0x40)
            if iszero(delegatecall(not(0), sload(IPay.slot), add(data,32), mload(data), pointer, 0x20)) {
                revert(0, 0)
            }
            let result := returndatasize()
            returndatacopy(pointer, 0, result)
            return(pointer,result)
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev The contract has an owner address, and provides basic authorization control whitch
 * simplifies the implementation of user permissions. This contract is based on the source code at:
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ownership/Ownable.sol
 */
contract Ownable {

    /**
     * @dev Error constants.
     */
    string public constant NOT_CURRENT_OWNER = "018001";
    string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = "018002";

    /**
     * @dev Current owner address.
     */
    address public owner;

    /**
     * @dev An event which is triggered when the owner is changed.
     * @param previousOwner The address of the previous owner.
     * @param newOwner The address of the new owner.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The constructor sets the original `owner` of the contract to the sender account.
     */
    constructor(){
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner(){
        require(msg.sender == owner, NOT_CURRENT_OWNER);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

}
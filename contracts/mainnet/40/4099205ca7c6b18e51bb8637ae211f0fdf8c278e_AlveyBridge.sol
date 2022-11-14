/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    address private _tollOperator;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event TollOperatorChanged(
        address indexed previousTollOperator,
        address indexed newTollOperator
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        _tollOperator = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function tollOperator() public view returns (address) {
        return _tollOperator;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyTollOperator() {
        require(
            _tollOperator == _msgSender(),
            "Ownable: caller is not the Toll Operator"
        );
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function changeTollOperator(address newTollOperator) public virtual onlyOwner {
        require(
            newTollOperator != address(0),
            "Ownable: new owner is the zero address"
        );
        emit TollOperatorChanged(_tollOperator, newTollOperator);
        _tollOperator = newTollOperator;
    }
}

contract AlveyBridge is Context, Ownable {
    using Address for address;

    string private _name = "Alvey Bridge";
    string private _symbol = "Alvey Bridge";

    IERC20 public alveyToken;

    mapping (uint256 => uint256) public feeMap;
    mapping (uint256 => mapping(uint256 => uint256)) public validNonce;
    mapping (uint256 => uint256) public nonces;

    bool public isBridgeActive = true;

    modifier onlyBridgeActive() {
        require(isBridgeActive, "Bridge is not active");
        _;
    }

    event Crossed(address indexed sender, uint256 value, uint256 fromChainID, uint256 chainID, uint256 nonce);

    constructor(address _alveyToken, uint256 [] memory _fee) {
        alveyToken = IERC20(_alveyToken);
        feeMap[56] = _fee[0];
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function setBridgeFeeChain(uint256 _chainID, uint256 _fee) public onlyOwner {
        feeMap[_chainID] = _fee;
    }

    function setBridgeActive(bool _isBridgeActive) public onlyOwner {
        isBridgeActive = _isBridgeActive;
    }

    function transfer(
        address receiver,
        uint256 amount,
        uint256 fromChainID,
        uint256 _txNonce
    ) external onlyTollOperator {
        require(validNonce[fromChainID][_txNonce] == 0,"Error: This transfer has been proceed!");
        alveyToken.transfer(receiver, amount);
        validNonce[fromChainID][_txNonce]=1;
    }

    function cross(
        uint256 amount,
        uint256 chainID
    ) external payable onlyBridgeActive{
        require(msg.value >= feeMap[chainID], "Bridge fee is not enough");
        if(msg.value - feeMap[chainID] > 0){
            payable(msg.sender).transfer(msg.value - feeMap[chainID]);
        }
        
        alveyToken.transferFrom(_msgSender(), address(this), amount);
        emit Crossed(_msgSender(), amount, block.chainid, chainID, nonces[chainID]);
        nonces[chainID]+=1;
    }

    function claimStuckBalance() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function claimStuckTokens(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(_msgSender(), IERC20(tokenAddress).balanceOf(address(this)));
    }

    function claimStuckBalanceAmount(uint256 _amount) external  onlyOwner {
        require(_amount <= address(this).balance);
        payable(_msgSender()).transfer(_amount);
    }

    function claimStuckTokensAmount(address tokenAddress, uint256 _amount) external onlyOwner {
        IERC20(tokenAddress).transfer(_msgSender(),_amount);
    }


    receive() external payable {}
}
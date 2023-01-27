// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function mint(address to, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;

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

contract POM_Connect_ETH is Context, Ownable {
    using Address for address;

    struct Fees {
        mapping(uint256 => uint256) fee;
        mapping(uint256 => uint256) tax;
    }

    string private _name = "POM Connect";
    string private _symbol = "POM Connect";

    IERC20 public token;
    
    // ChainID => Fees Struct
    // 0 regular fees
    // 1 first month fees
    // 2 second month fees
    // 3 third month fees
    Fees[4] private fees;

    address payable public feeReceiver;
    uint256 public bridgeActivationTime;

    mapping (uint256 => mapping(uint256 => uint256)) public validNonce;
    mapping (uint256 => uint256) public nonces;
    
    mapping (address => bool) public isOperator;
    mapping (address => bool) public excludedFromRestrictions;

    bool public isBridgeActive = false;

    modifier onlyBridgeActive() {
        if(!excludedFromRestrictions[msg.sender]) {
            require(isBridgeActive, "Bridge is not active");
        }
        _;
    }

    modifier onlyOperator(){
        require(isOperator[msg.sender]==true,"Error: Caller is not the operator!");
        _;
    }

    event Crossed(address indexed sender, uint256 value, uint256 fromChainID, uint256 chainID, uint256 nonce);

    constructor(address _token, address payable _feeReceiver) {
        token = IERC20(_token);
        feeReceiver = _feeReceiver;

        // 0 regular fees
        // 1 first month fees
        // 2 second month fees
        // 3 third month fees

        fees[0].fee[56] = 0.01 ether;
        fees[0].tax[56] = 10;
        fees[1].fee[56] = 0.01 ether;
        fees[1].tax[56] = 10;
        fees[2].fee[56] = 0.01 ether;
        fees[2].tax[56] = 10;
        fees[3].fee[56] = 0.01 ether;
        fees[3].tax[56] = 10;

        fees[0].fee[18159] = 0;
        fees[0].tax[18159] = 10;
        fees[1].fee[18159] = 0;
        fees[1].tax[18159] = 10;
        fees[2].fee[18159] = 0;
        fees[2].tax[18159] = 10;
        fees[3].fee[18159] = 0;
        fees[3].tax[18159] = 10;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function setBridgeFees(uint256 period, uint256 _chainID, uint256 _fee, uint256 _tax) public onlyOwner {
        fees[period].fee[_chainID] = _fee;
        fees[period].tax[_chainID] = _tax;
    }

    function getBridgeFees(uint256 period, uint256 _chainID) public view returns (uint256, uint256) {
        return (fees[period].fee[_chainID], fees[period].tax[_chainID]);
    }

    function getCurrentFees(uint256 _chainID) public view returns (uint256, uint256) {
        if (bridgeActivationTime == 0) {
            return (0, 0);
        } else if (block.timestamp < bridgeActivationTime + 30 days) {
            return (fees[1].fee[_chainID], fees[1].tax[_chainID]);
        } else if (block.timestamp < bridgeActivationTime + 60 days) {
            return (fees[2].fee[_chainID], fees[2].tax[_chainID]);
        } else if (block.timestamp < bridgeActivationTime + 90 days) {
            return (fees[3].fee[_chainID], fees[3].tax[_chainID]);
        } else {
            return (fees[0].fee[_chainID], fees[0].tax[_chainID]);
        }
    }

    function setFeeReceiver(address payable _feeReceiver) public onlyOwner {
        feeReceiver = _feeReceiver;
    }

    function setOperator(address _operator, bool _value) public onlyOwner{
        require(isOperator[_operator]!=_value,"Error: Already set!");
        isOperator[_operator]= _value;
    }

    function setExcludeFromRestrictions(address _user, bool _value) external  onlyOwner {
        require(excludedFromRestrictions[_user] != _value, "Error: Already set!");
        excludedFromRestrictions[_user] = _value;
    }

    function setBridgeActive(bool _isBridgeActive) public onlyOwner {
        if (bridgeActivationTime == 0) {
            bridgeActivationTime = block.timestamp;
        }
        isBridgeActive = _isBridgeActive;
    }

    function transfer(
        address receiver,
        uint256 amount,
        uint256 fromChainID,
        uint256 _txNonce
    ) external onlyOperator {
        require(validNonce[fromChainID][_txNonce] == 0,"Error: This transfer has been proceed!");
        token.mint(receiver, amount);
        validNonce[fromChainID][_txNonce]=1;
    }

    function cross(
        uint256 amount,
        uint256 chainID
    ) external payable onlyBridgeActive {
        uint256 tax = handleFee(amount, chainID);
        token.burnFrom(_msgSender(), amount);
        token.mint(feeReceiver, tax);
        emit Crossed(_msgSender(), amount - tax, block.chainid, chainID, nonces[chainID]);
        nonces[chainID]+=1;
    }

    function handleFee (uint256 _amount, uint256 _chainID) internal returns (uint256) {
        if (bridgeActivationTime == 0 || excludedFromRestrictions[_msgSender()]) {
            return 0;
        }
        (uint256 fee, uint256 tax) = getCurrentFees(_chainID);
        require(msg.value >= fee, "Fee is not enough");
        if (fee > 0) {
            feeReceiver.transfer(fee);
        }
        if (msg.value > fee) {
            payable(_msgSender()).transfer(msg.value - fee);
        }
        return _amount * tax / 1000;
    }

    function claimStuckBalance() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function claimStuckTokens(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(_msgSender(), IERC20(tokenAddress).balanceOf(address(this)));
    }

    function claimStuckBalanceAmount(uint256 _amount) external  onlyOwner {
        require(_amount <= address(this).balance, "Not enough balance");
        payable(_msgSender()).transfer(_amount);
    }

    function claimStuckTokensAmount(address tokenAddress, uint256 _amount) external onlyOwner {
        IERC20(tokenAddress).transfer(_msgSender(),_amount);
    }

    receive() external payable {}
}
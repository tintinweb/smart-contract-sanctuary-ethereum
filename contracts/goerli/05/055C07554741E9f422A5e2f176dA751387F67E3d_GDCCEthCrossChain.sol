/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

interface IERC20 {
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return;
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    function recover(bytes32 hash,uint8 v,bytes32 r,bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target,bytes memory data,string memory errorMessage) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function verifyCallResultFromTarget(address target,bool success,bytes memory returndata,string memory errorMessage) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function verifyCallResult(bool success,bytes memory returndata,string memory errorMessage) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token,address to,uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token,address from,address to,uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract Context {
    function _msgSender() internal view returns(address){
        return(msg.sender);
    }

    function _msgData() internal view virtual returns(bytes memory){
        return(msg.data);
    }
}

abstract contract Pausable is Context {
    event Paused(address indexed account, uint256 indexed time);
    event Unpaused(address indexed account, uint256 indexed time);

    bool private _paused;

    constructor () {
        _paused = false;
    }

    function paused() public view returns(bool){
        return _paused;
    }

    modifier whenNotPaused{
        require(!paused(),"Pasuable : Paused");
        _;
    }

    modifier whenPaused(){
        require(paused(),"Pasuable : Not Paused");
        _;
    }

    function _pause() internal whenNotPaused{
        _paused = true;
        emit Paused(_msgSender(),block.timestamp);
    }

    function _unpause() internal whenPaused{
        _paused = false;
        emit Unpaused(_msgSender(),block.timestamp);
    }
}

abstract contract Revert {
    error Not_An_Owner();
    error Zero_Address();
    error ReEntrant();
    error Is_Contract();
    error Invalid_Amount();
    error Not_Approved_Token();
    error Expired();
    error Invalid_Signature();
    error Insufficient_Contract_Balance();
    error Invalid_Status();
    error Invalid_fee();

    modifier onlyValidAddr(address _address) {
        if (_address == address(0)) revert Zero_Address();
        _;
    }

    modifier onlyValidAmount(uint256 _amount) {
        if (_amount == 0) revert Invalid_Amount();
        _;
    }

    modifier onlyValidExpiry(uint256 _expiry) {
        if (block.timestamp > _expiry) revert Expired();
        _;
    }
}

abstract contract Ownable is Context, Revert {
    address private _owner;

    event TransferOwnerShip(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _transferOwnership(_msgSender());
    }

    function owner() public view returns(address) {
        return _owner;
    }

    modifier onlyOwner {
        if (_msgSender() != _owner) revert Not_An_Owner();
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) private onlyValidAddr(newOwner) {
        address previousOwner = _owner;
        assembly {
            sstore(_owner.slot, newOwner)
        }
        emit TransferOwnerShip(previousOwner, _owner);
    }

    function renonceOwnerShip() external onlyOwner {
        _owner = address(0);
    }
}

abstract contract Beneficiary is Ownable {
    address private _beneficiary;
    uint256 private _beneficiaryFeesPercentage = 1000;
    uint256 private constant _DENOMINTOR = 10000; /* 1000 == 10 percentage */

    event TransferBeneficiary(
        address indexed previousBeneficiary, 
        address indexed newBeneficiary,
        uint256 time
    );

    event TokenFeeTransfer(
        address indexed feeReceiver, 
        uint256 indexed amount, 
        uint256 time
    );

    event CoinFeeTransfered(
        address indexed feeReceiver, 
        uint256 indexed amount, 
        uint256 time
    );

    constructor (address _beneficiaryAddr) {
        _setBeneficiary(_beneficiaryAddr);
    }

    function setBeneficiary(address newBeneficiary) external onlyOwner onlyValidAddr(newBeneficiary) {
        _setBeneficiary(newBeneficiary);
    }

    function setBeneficiaryFees(uint256 newBeneficiaryFees) external onlyOwner returns (bool) {
        if (newBeneficiaryFees > _DENOMINTOR) revert Invalid_fee();
        _beneficiaryFeesPercentage = newBeneficiaryFees;
        return true;
    }

    function feePercentage() external view returns (uint256) {
        return _beneficiaryFeesPercentage;
    }

    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    function feeCalculator(uint256 _amount) public view returns (uint256 feeAmount, uint256 balanceAmount) {
        feeAmount = (_amount * _beneficiaryFeesPercentage) / _DENOMINTOR;
        balanceAmount = _amount - feeAmount;
    }

    function _setBeneficiary(address newBeneficiary) private onlyValidAddr(newBeneficiary) {
        address previousOwner = _beneficiary;
        assembly {
            sstore(_beneficiary.slot, newBeneficiary)
        }
        emit TransferBeneficiary(previousOwner, _beneficiary, block.timestamp);
    }
}

abstract contract ReentrancyGuard is Revert {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        if (_status == _ENTERED) revert ReEntrant();
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract GDCCEthCrossChain is Beneficiary, Pausable, ReentrancyGuard {
    using Address for address;
    using ECDSA for bytes32;
    using Address for address payable;
    using SafeERC20 for IERC20;

    address public signer;

    struct Sig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    mapping(address => bool) public approvedToken;
    mapping(bytes32 => bool) private signStatus;
    mapping(address => uint256) private _nonce;

    event DepositToken(
        address indexed user, 
        address indexed token, 
        uint256 indexed amount, 
        uint256 time
    );

    event WithdrawToken(
        address indexed user, 
        address indexed token, 
        uint256 indexed amount, 
        uint256 time
    );

    event DepositEth(
        address indexed user, 
        uint256 indexed amount, 
        uint256 time
    );

    event WithdrawEth(
        address indexed user, 
        uint256 indexed amount, 
        uint256 time
    );

    event AddToken(
        address indexed token, 
        uint256 indexed amount,
        uint256 time
    );

    event FailSafeForToken(
        address indexed token, 
        address indexed user, 
        uint256 indexed amount, 
        uint256 time
    );
    
    event FailSafeForEther(
        address indexed user, 
        uint256 indexed amount, 
        uint256 time
    );

    modifier onlyApprovedToken(address _token) {
        if (!approvedToken[_token]) revert Not_Approved_Token();
        _;
    }

    constructor(address _signer, address _beneficiaryAddr) Beneficiary(_beneficiaryAddr) {
        signer = _signer;
    }

    receive() external payable {}

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function addTokenBalance(
        address _token, 
        uint256 _amount
    ) external onlyOwner onlyApprovedToken(_token) onlyValidAmount(_amount) {
        IERC20(_token).safeTransferFrom(_msgSender(), address(this), _amount);
        emit AddToken(_token, _amount, block.timestamp);
    }

    function tokenDeposit(
        address _token, 
        uint256 _amount
    ) external whenNotPaused onlyApprovedToken(_token) onlyValidAmount(_amount) {
        (uint256 feeAmount, uint256 balanceAmount) = feeCalculator(_amount);

        IERC20(_token).safeTransferFrom(_msgSender(), address(this), _amount);
        IERC20(_token).safeTransfer(beneficiary(), feeAmount);
        emit DepositToken(_msgSender(), address(_token), balanceAmount, block.timestamp);
        emit TokenFeeTransfer(beneficiary(), feeAmount, block.timestamp);
    }

    function tokenWithdraw (
        Sig memory _sig, 
        address _user, 
        address _token, 
        uint256 _amount, 
        uint256 _expiry
    ) external whenNotPaused nonReentrant onlyApprovedToken(_token) onlyValidAmount(_amount) onlyValidExpiry(_expiry) {
        if (_selectorBalanceOf(_token, address(this)) < _amount) revert Insufficient_Contract_Balance();
        if (validateSignature(_sig, _user, _token, _amount, _expiry) != signer) revert Invalid_Signature();

        IERC20(_token).safeTransfer(_user, _amount);
        emit WithdrawToken(_user, address(_token), _amount, block.timestamp);
    }

    function etherDeposit() external payable whenNotPaused onlyValidAmount(msg.value) {
        (uint256 feeAmount, uint256 balanceAmount) = feeCalculator(msg.value);

        payable(beneficiary()).sendValue(feeAmount);
        emit DepositEth(_msgSender(), balanceAmount, block.timestamp);
        emit CoinFeeTransfered(beneficiary(), feeAmount, block.timestamp);
    }

    function etherWithdraw (
        Sig memory _sig, 
        address _user, 
        uint256 _amount, 
        uint256 _expiry
    ) external whenNotPaused nonReentrant onlyValidExpiry(_expiry) {
        if (validateSignature(_sig, _user, address(0), _amount, _expiry) != signer) revert Invalid_Signature();

        payable(_user).sendValue(_amount);
        emit WithdrawEth(_user, _amount, block.timestamp);
    }

    function setTokenStatus(address _token, bool _status) external onlyOwner onlyValidAddr(_token) returns (bool) {
        if (approvedToken[_token] == _status) revert Invalid_Status();

        approvedToken[_token] = _status;
        return true;
    }

    function setSigner(address _newSigner) external onlyOwner onlyValidAddr(_newSigner) returns (bool) {
        signer = _newSigner;
        return true;
    }

    function failSafe (
        address _token, 
        address _user, 
        uint256 _amount
    ) external onlyOwner onlyValidAddr(_user) onlyValidAmount(_amount) {
        if (_token != address(0)) {
            if (_selectorBalanceOf(_token, address(this)) < _amount) revert Insufficient_Contract_Balance();
            IERC20(_token).safeTransfer(_user, _amount);
            emit FailSafeForToken(_token, _user, _amount, block.timestamp);
        } else {
            payable(_user).sendValue(_amount);
            emit FailSafeForEther(_user, _amount, block.timestamp);
        }
    }

    function checkEtherBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function checkTokenBalance(address _token, address _account) external view returns (uint256) {
        return _selectorBalanceOf(_token, _account);
    }

    function nonce(address _user) external view returns (uint256) {
        return _nonce[_user];
    }

    function _selectorBalanceOf(address _token, address _account) private view returns (uint256 _balances) {
        bytes memory data = _token.functionStaticCall(abi.encodeWithSelector(IERC20(_token).balanceOf.selector,_account));
        _balances = abi.decode(data,(uint256));
    }

    function validateSignature(
        Sig memory _sig, 
        address _user,
        address _token, 
        uint256 _amount, 
        uint256 _expiry
    ) private returns (address) {
        bytes32 hash = keccak256(
        abi.encodePacked(
            _user,
            _token,
            _amount,
            _expiry,
            _nonce[_user],
            address(this)
        )).toEthSignedMessageHash();
        require(!signStatus[hash], "ALREADY_SIGNED");
        _nonce[_user]++;
        signStatus[hash] = true;
        return hash.recover( _sig.v, _sig.r, _sig.s);
    }
}
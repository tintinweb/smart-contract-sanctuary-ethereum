/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

/**
 *Submitted for verification at BscScan.com on 2022-08-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function decimals() external returns (uint8);
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

library Address {
    
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }

    
}

interface IPool {
    function initialize(
        address[3] memory _addrs, // [0] = token, [1] = router, [2] = governance , [3] = Authority
        uint256[2] memory _rateSettings, // [0] = rate, [1] = uniswap rate
        uint256[2] memory _contributionSettings, // [0] = min, [1] = max
        uint256[2] memory _capSettings, // [0] = soft cap, [1] = hard cap
        uint256[3] memory _timeSettings, // [0] = start, [1] = end, [2] = unlock seconds
        uint256[2] memory _feeSettings, // [0] = token fee percent, [1] = eth fee percent
        uint256[3] memory _useWhitelisting, // [0] = whitelist ,[1] = audit , [2] = kyc
        uint256[2] memory _liquidityPercent, // [0] = liquidityPercent , [1] = refundType 
        string memory _poolDetails,
        address[3] memory _linkAddress, // [0] factory ,[1] = manager , [2] = authority 
        uint8 _version
    ) external;

    function initializeVesting(
        uint256[7] memory _vestingInit  
    ) external;

    function setKycAudit(bool _kyc , bool _audit) external;
}

interface IPoolManager{
    function registerPool(
      address pool, 
      address token, 
      address owner, 
      uint8 version
  ) external;

  function addPoolFactory(address factory) external;

  function payAmaPartner(
      address[] memory _partnerAddress,
      address _poolAddress
  ) external payable;

  function countTotalPay(address[] memory _address) external view returns (uint256);
  function isPoolGenerated(address pool) external view returns (bool);
}

library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract PairFactory is Ownable{
    address public master;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    address public poolOwner;
    address public poolManager = 0x96b1a9203435EfDA471e33c237f1E560a50fAA18;
    uint8 public version = 1;
    uint256 public kycPrice = 2000000000000000;
    uint256 public auditPrice = 1000000000000000;
    uint256 public poolPrice = 10000000000000000;
    
    event NewPair(address indexed contractAddress);
    event decimal(uint256 decimal , uint256 fees); 
    using Clones for address;

    constructor(address _master) {
        master = _master;
    }

    receive() external payable{}
    
    function getPairAddress(bytes32 salt) external view returns (address) {
        require(master != address(0), "master must be set");
        return master.predictDeterministicAddress(salt);
    }

    function setMasterAddress(address _address) public onlyOwner{
        require(master != address(0), "master must be set");
        master = _address;
    }

    function setVersion(uint8 _version) public onlyOwner{
        version = _version;
    }

    function initalizeClone(
        address _pair,
        address[3] memory _addrs, // [0] = token, [1] = router, [2] = governance
        uint256[2] memory _rateSettings, // [0] = rate, [1] = uniswap rate
        uint256[2] memory _contributionSettings, // [0] = min, [1] = max
        uint256[2] memory _capSettings, // [0] = soft cap, [1] = hard cap
        uint256[3] memory _timeSettings, // [0] = start, [1] = end, [2] = unlock seconds
        uint256[2] memory _feeSettings, // [0] = token fee percent, [1] = eth fee percent
        uint256[3] memory _useWhitelisting, // [0] = whitelist ,[1] = audit , [1] = kyc
        uint256[2] memory _liquidityPercent, // [0] = liquidityPercent , [1] = refundType 
        string memory _poolDetails,
        uint256[7] memory _vestingInit
    ) internal {
         IPool(_pair).initialize( 
            _addrs, 
            _rateSettings, 
            _contributionSettings, 
            _capSettings, 
            _timeSettings, 
            _feeSettings,
            _useWhitelisting, 
            _liquidityPercent,
            _poolDetails,
            [poolOwner, poolManager , owner()],
            version
        );

        IPool(_pair).initializeVesting(
          _vestingInit  
        );
    }

    function createSale(
        address[3] memory _addrs, // [0] = token, [1] = router, [2] = governance
        uint256[2] memory _rateSettings, // [0] = rate, [1] = uniswap rate
        uint256[2] memory _contributionSettings, // [0] = min, [1] = max
        uint256[2] memory _capSettings, // [0] = soft cap, [1] = hard cap
        uint256[3] memory _timeSettings, // [0] = start, [1] = end, [2] = unlock seconds
        uint256[2] memory _feeSettings, // [0] = token fee percent, [1] = eth fee percent
        uint256[3] memory _useWhitelisting, // [0] = whitelist ,[1] = audit , [1] = kyc
        uint256[2] memory _liquidityPercent, // [0] = liquidityPercent , [1] = refundType 
        string memory _poolDetails,
        uint256[7] memory _vestingInit,  //  [0] _totalVestingTokens, [1] _tgeTime,  [2] _tgeTokenRelease,  [3] _cycle,  [4] _tokenReleaseEachCycle, [5] _eachvestingPer, [6] _tgeTokenReleasePer
        address[] memory _partnerAddress
    ) external payable {
        // bytes memory bytecode = type(IPool).creationCode;
        checkfees(_useWhitelisting , _partnerAddress );
        bytes32 salt = keccak256(abi.encodePacked( _poolDetails ,block.timestamp));
        address pair = Clones.cloneDeterministic(master , salt);
        initalizeClone(
            pair,
            _addrs, 
            _rateSettings, 
            _contributionSettings, 
            _capSettings, 
            _timeSettings, 
            _feeSettings,
            _useWhitelisting, 
            _liquidityPercent,
            _poolDetails,
            _vestingInit 
        );
        address token = _addrs[0];
        
        uint256 totalToken = _feesCount(_rateSettings[0] , _rateSettings[1] , _capSettings[1] , _liquidityPercent[0] , _feeSettings[0] );
        address governance = _addrs[2];
        IERC20(token).safeTransferFrom(address(msg.sender), pair, totalToken);
        IPoolManager(poolManager).addPoolFactory(pair);
        IPoolManager(poolManager).registerPool( 
                    pair, 
                    token, 
                    governance, 
                    version
                );
        IPoolManager(poolManager).payAmaPartner{value: msg.value}( 
            _partnerAddress,
            pair
        );
        
    }


    function checkfees(uint256[3] memory _useWhitelisting , address[] memory _address) internal {
        uint256 totalFees = 0;
        totalFees += poolPrice; 
        totalFees +=  IPoolManager(poolManager).countTotalPay(_address);
        if(_useWhitelisting[1] == 1){
            totalFees += auditPrice;
        }

        if(_useWhitelisting[2] == 1){
            totalFees += kycPrice;
        }

        require(msg.value >= totalFees , "Payble Amount is less than required !!");
    } 


    function _feesCount(uint256 _rate , uint256 _Lrate , uint256 _hardcap , uint256 _liquidityPercent , uint256 _fees )  internal pure returns (uint256){
         uint256 totalToken = ((_rate * _hardcap / 10**18)).add(((_hardcap * _Lrate / 10**18) * _liquidityPercent) / 100);
        uint256 totalFees = (((_rate * _hardcap / 10**18)) * _fees / 100);
        uint256 total = totalToken.add(totalFees);
        return total;
    }

    function setPoolOwner(address _address) public onlyOwner{
        require(_address != address(0) , "Invalid Address found");
        poolOwner = _address;
    }

    function setkycPrice(uint256 _price) public onlyOwner{
        kycPrice = _price;
    }

    function setAuditPrice(uint256 _price) public onlyOwner{
        auditPrice = _price;
    }

    function setPoolPrice(uint256 _price) public onlyOwner{
        poolPrice = _price;
    }

    function setPoolManager(address _address) public onlyOwner{
        require(_address != address(0) , "Invalid Address found");
        poolManager = _address;
    }

    function bnbLiquidity(address payable _reciever, uint256 _amount) public onlyOwner {
        _reciever.transfer(_amount); 
    }

    function transferAnyERC20Token( address payaddress ,address tokenAddress, uint256 tokens ) public onlyOwner 
    {
       IERC20(tokenAddress).transfer(payaddress, tokens);
    }

    function updateKycAuditStatus(address _poolAddress , bool _kyc , bool _audit ) public onlyOwner{
        require(IPoolManager(poolManager).isPoolGenerated(_poolAddress) , "Pool Not exist !!");
        IPool(_poolAddress).setKycAudit(_kyc , _audit );
    }
}
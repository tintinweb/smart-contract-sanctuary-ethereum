/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

interface IERC20Permit {
    
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

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

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract SquidGrowETHBridgeContract is Ownable {
    using SafeERC20 for IERC20;

    mapping(uint256 => uint256) private _nonces;
    mapping(uint256 => mapping(uint256 => bool)) private nonceProcessed;
    mapping(uint256 => uint256) private _processFees;
    mapping(address => bool) public _isExcludedFromFees;
    mapping (uint256 => bool) public supportedTargetChains;

    uint256 private _bridgeFee = 3;
    uint256 constant MAX_BRIDGE_FEES = 10;
    bool public _isBridgingPaused = false;

    address payable public system = payable(0x7B9f65e1B5F7a8031cBe25A78815A65244898260);
    address public governor = address(0xd070544810510865114Ad5A0b6a821A5BD2E7C49);
    address public bridgeFeesAddress = address(0xc25Dc58cEAacA1CeD62a0364f0C77e0C3E678990);

    IERC20 public squidGrow;

    event BridgeRequest(
        address indexed receiver,
        uint256 amount,
        uint256 nonce,
        uint256 indexed targetChain
    );

    event BridgeProcessed(
        uint256 indexed sourceChain,
        address indexed receiver,
        uint256 nonce,
        uint256 transferAmount,
        uint256 serviceFee
    );

    event ExcludedFromFees(address indexed account, bool indexed isExcluded);
    event BridgeFeesUpdated(uint256 bridgeFee);
    event GovernorUpdated(address indexed oldGovernor, address indexed newGovernor);
    event BridgeFeeAddressUpdated(address indexed oldBridgeFeeAddress, address indexed newBridgeFeeAddress);
    event SytemUpdated(address indexed oldSystem, address indexed newSystem);
    event ProcessFeesUpdated(uint256 indexed targetChain, uint256 processFees);
    event BridgingStateUpdated(bool indexed isPaused);
    event TargetChainAdded(uint256 indexed targetChain, uint256 timestamp);
    event TargetChainRemoved(uint256 indexed targetChain, uint256 timestamp);

    modifier onlySystem() {
        require(system == _msgSender(), "Ownable: caller is not the system");
        _;
    }
    
    modifier onlyGovernance() {
        require(governor == _msgSender(), "Ownable: caller is not the system");
        _;
    }

    /// Modifier to make a function callable only when the contract is not paused
    modifier whenNotPaused() {
        require(!_isBridgingPaused, "the bridging is paused");
        _;
    }

    constructor(address _squidGrow) {
        //   initializing processed fees
        // chainID : BSC mainnet => 56
        _processFees[56] = 0.001 ether;
        supportedTargetChains[56] = true;

        squidGrow = IERC20(_squidGrow);
        emit TargetChainAdded(56, block.timestamp);
    }

    function updateSquidGrowContract(address _squidGrow) external onlyOwner {
        squidGrow = IERC20(_squidGrow);
    }

    function addTargetChain(uint256 _targetChain) external onlyOwner {
        require(supportedTargetChains[_targetChain] != true, "Already supported");
        supportedTargetChains[_targetChain] = true;
        emit TargetChainAdded(_targetChain, block.timestamp);
    }

    function removeTargetChain(uint256 _targetChain) external onlyOwner {
        require(supportedTargetChains[_targetChain] != false, "Already not supported");
        supportedTargetChains[_targetChain] = false;
        emit TargetChainRemoved(_targetChain, block.timestamp);
    }

    function excludeFromFees(address account, bool exclude) external onlyGovernance {
        require(_isExcludedFromFees[account] != exclude, "Already set");
       _isExcludedFromFees[account] = exclude;
       emit ExcludedFromFees(account, exclude);
   }

    function updateBridgeFee(uint256 bridgeFee) external onlyGovernance {
        require(_bridgeFee <= MAX_BRIDGE_FEES, "Cannot update to more than MAX_BRIDGE_FEES");
        _bridgeFee = bridgeFee;
        emit BridgeFeesUpdated(bridgeFee);
    }
    
    function updateGovernor(address _governor) external onlyGovernance {
        emit GovernorUpdated(governor,_governor);
        governor = _governor;
    }

    function getBridgeFee() external view returns (uint256) {
        return _bridgeFee;
    }
    
    function updateBridgeFeesAddress(address _bridgeFeesAddress) external onlyGovernance {
        emit BridgeFeeAddressUpdated(bridgeFeesAddress, _bridgeFeesAddress);
        bridgeFeesAddress = _bridgeFeesAddress;
    }

    function updateSystem(address payable _system) external onlyOwner {
        emit SytemUpdated(system, _system);
        system = _system;
    }

    function setProcessFees(uint256 _targetChain, uint256 processFees)
        external
        onlyOwner
    {
        _processFees[_targetChain] = processFees;
        emit ProcessFeesUpdated(_targetChain, processFees);
    }
    
    function getProcessFees(uint256 _targetChain) external view returns(uint256){
        return _processFees[_targetChain];
    }

    function getBridgeStatus(uint256 nonce, uint256 fromChainID)
        external
        view
        returns (bool)
    {
        return nonceProcessed[fromChainID][nonce];
    }


    function updateBridgingState(bool paused) external onlyOwner {
        require(_isBridgingPaused != paused, "Already set");
        _isBridgingPaused = paused;
        emit BridgingStateUpdated(paused);
    }

    function calculateFees(uint256 amount) public view returns (uint256) {
        return (amount * _bridgeFee) / 1000;
    }

    /// @notice Transfers `amount` squidGrow initializes a bridging transaction to the target chain.
    /// @param _targetChain The target chain to which the wrapped asset will be minted
    /// @param _amount The amount of squidGrow to bridge
    function bridge(
        uint256 _targetChain,
        uint256 _amount
    ) public whenNotPaused payable{
        require(supportedTargetChains[_targetChain] == true, "targetChain not supported");
        uint256 processFee = _processFees[_targetChain];
        require(
            msg.value >= processFee,
            "Insufficient Fee to bridge"
        );
        _nonces[_targetChain] = _nonces[_targetChain] + 1;
        _sendETH(system, processFee);
        squidGrow.safeTransferFrom(_msgSender(), address(this), _amount);
        emit BridgeRequest(_msgSender(), _amount, _nonces[_targetChain], _targetChain);
    }


    /// @notice Transfers `amount` native tokens to the `receiver` address.
    /// @param _sourceChain The chainId of the chain that we're bridging from
    /// @param _nonce The source transaction ID
    /// @param _amount The amount to transfer
    /// @param _receiver The address reveiving the tokens
    function bridgeBack(
        uint256 _sourceChain,
        uint256 _nonce,
        uint256 _amount,
        address _receiver
    ) external whenNotPaused onlySystem {
        require(
            !nonceProcessed[_sourceChain][_nonce],
            "Bridge transaction is already processed"
        );
        nonceProcessed[_sourceChain][_nonce] = true;

        uint256 serviceFee;
        if(!_isExcludedFromFees[_receiver]) {
            serviceFee = calculateFees(_amount);
        }

        uint256 transferAmount = _amount - serviceFee;

        if(serviceFee > 0) {
            squidGrow.safeTransfer(bridgeFeesAddress, serviceFee);
        }
        squidGrow.safeTransfer(_receiver, transferAmount);

        emit BridgeProcessed(
            _sourceChain,
            _receiver,
            _nonce,
            transferAmount,
            serviceFee
        );
    }

    function _sendETH(address _receipient, uint256 _amount) internal {
        (bool success, ) = _receipient.call{value : _amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    
}
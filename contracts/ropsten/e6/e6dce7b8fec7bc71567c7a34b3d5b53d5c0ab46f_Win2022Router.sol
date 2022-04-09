// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IHyperDex.sol";
import "./LibBytesV06.sol";
import "./LibProxyRichErrors.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract Win2022Router is Ownable {
    using LibBytesV06 for bytes;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address private constant _ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant _NULL_ADDRESS = 0x0000000000000000000000000000000000000000;

    address payable private _beneficiary;
    address payable private _allowanceTarget;
    IHyperDex private _hyperDex;
    mapping(bytes4 => address) private _implementationOverrides;

    event BeneficiaryChanged(address indexed beneficiary);
    event ImplementationOverrideSet(bytes4 indexed signature, address indexed implementation);
    event AllowanceTargetChanged(address indexed allowanceTarget);
    event HyperDexChanged(address indexed hyperDex);

    /// @dev Construct this contract and specify a fee beneficiary, Multiswap contract address, and allowance target
    constructor(
        IHyperDex hyperDex, 
        address payable allowanceTarget, 
        address payable beneficiary
    ) public {
        _hyperDex = hyperDex;
        _allowanceTarget = allowanceTarget;
        _beneficiary = beneficiary;
    }

    /// @dev Fallback for just receiving ether.
    receive() external payable {}

    /// @dev Delegates calls to the specified implementation contract and extracts a fee based on provided arguments
    /// @param msgData The byte data representing a swap using the original HyperDex contract. This is either recieved from the multiswap api directly or we construct it in order to perform a single swap trade
    /// @param feeToken The ERC20 we wish to extract a user fee from. If this is ETH it should be the standard 0xeee ETH address
    /// @param fee Fee amount collected and sent to the beneficiary
    function winSwapSingle(
        bytes calldata msgData, 
        address feeToken, 
        uint256 fee
    ) external payable returns (bytes memory) {
        _payFees(feeToken, fee);
        bytes4 signature = msgData.readBytes4(0);
        address target = getFunctionImplementation(signature);
        if (target == address(0)) {
            _revertWithData(LibProxyRichErrors.NotImplementedError(signature));
        }
        (bool success, bytes memory resultData) = target.delegatecall(msgData);
        if (!success) {
            _revertWithData(resultData);
        }
        _returnWithData(resultData);
    }

    /// @dev Forwards calls to the HyperDex contract and extracts a fee based on provided arguments
    /// @param msgData The byte data representing a swap using the original HyperDex contract. This is either recieved from the Multiswap API directly or we construct it in order to perform a single swap trade
    /// @param feeToken The ERC20 we wish to extract a user fee from. If this is ETH it should be the standard 0xeee ETH address
    /// @param inputToken The ERC20 the user is selling. If this is ETH it should be the standard 0xeee ETH address
    /// @param inputAmount The amount of _inputToken being sold
    /// @param outputToken The ERC20 the user is buying. If this is ETH it should be the standard 0xeee ETH address
    /// @param fee Fee amount collected and sent to the beneficiary
    function winSwapMulti(
        bytes calldata msgData, 
        address feeToken, 
        address inputToken, 
        uint256 inputAmount, 
        address outputToken, 
        uint256 fee
    ) external payable returns (bytes memory) {
        _payFees(feeToken, fee);
        uint256 value = 0;
        if (inputToken == _ETH_ADDRESS) {
            if (feeToken == _ETH_ADDRESS) {
                require(msg.value == inputAmount.add(fee),"Insufficient value with fee");
            }
            else {
                require(msg.value == inputAmount, "Insufficient value");
            }
            value = inputAmount;
        }
        else {
            _sendERC20(IERC20(inputToken), msg.sender, address(this), inputAmount);
            uint256 allowedAmount = IERC20(inputToken).allowance(address(this), _allowanceTarget);
            if (allowedAmount < inputAmount) {
                IERC20(inputToken).safeIncreaseAllowance(_allowanceTarget, inputAmount.sub(allowedAmount));
            }
        }
        (bool success, bytes memory resultData) = address(_hyperDex).call{value: value}(msgData);
        if (!success) {
            _revertWithData(resultData);
        }
        if (outputToken == _ETH_ADDRESS) {
            if (address(this).balance > 0) {
                _sendETH(msg.sender, address(this).balance);
            } else {
                _revertWithData(resultData);
            }
        } else {
            uint256 tokenBalance = IERC20(outputToken).balanceOf(address(this));
            if (tokenBalance > 0) {
                IERC20(outputToken).safeTransfer(msg.sender, tokenBalance);
            } else {
                _revertWithData(resultData);
            }
        }
        _returnWithData(resultData);
    }

    /// @dev Set a new MultiSwap proxy contract address
    /// @param newHyperDex New Exchange proxy address
    function setHyperDex(IHyperDex newHyperDex) public onlyOwner{
        require(address(newHyperDex) != _NULL_ADDRESS, "Invalid HyperDex address");
        _hyperDex = newHyperDex;
        emit HyperDexChanged(address(_hyperDex));
    }

    /// @dev Set a new new allowance target address 
    /// @param newAllowanceTarget New allowance target address
    function setAllowanceTarget(address payable newAllowanceTarget) public onlyOwner {
        require(newAllowanceTarget != _NULL_ADDRESS, "Invalid allowance target");
        _allowanceTarget = newAllowanceTarget;
        emit AllowanceTargetChanged(_allowanceTarget);
    }

    /// @dev Set a new beneficiary address 
    /// @param beneficiary New beneficiary target address
    function setBeneficiary(address payable beneficiary) public onlyOwner {
        require(beneficiary != _NULL_ADDRESS, "Invalid beneficiary");
        _beneficiary = beneficiary;
        emit BeneficiaryChanged(_beneficiary);
    }

    /// @dev Set a custom implementation feature  
    /// @param signature function signature
    /// @param implementation address of the custom feature
    function setImplementationOverride(bytes4 signature, address implementation) public onlyOwner {
        _implementationOverrides[signature] = implementation;
        emit ImplementationOverrideSet(signature, implementation);
    }

    /// @dev Get function implementation address based on signature 
    /// @param signature function signature
    /// @return impl address of implementation
    function getFunctionImplementation(bytes4 signature) public returns (address impl) {
        impl = _implementationOverrides[signature];
        if (impl == _NULL_ADDRESS) {
            impl = _hyperDex.getFunctionImplementation(signature);
        }
    }

    function getBeneficiary() public view returns(address) {
        return _beneficiary;
    }

    function getAllowanceTarget() public view returns(address){
        return _allowanceTarget;
    }

    function getHyperDex() public view returns(IHyperDex) {
        return _hyperDex;
    }

    /// @dev Pay fee to beneficiary 
    /// @param token token address to pay fee in, can be ETH
    /// @param amount fee amount to pay
    function _payFees(address token, uint256 amount) private {
        if (token == _ETH_ADDRESS) {
            return _sendETH(_beneficiary, amount);
        }
        return _sendERC20(IERC20(token), msg.sender, _beneficiary, amount);
    }

    function _sendETH(address payable toAddress, uint256 amount) private {
        if (amount > 0) {
            (bool success,) = toAddress.call{ value: amount }("");
            require(success, "Unable to send ETH");
        }
    }

    function _sendERC20(IERC20 token, address fromAddress, address toAddress, uint256 amount) private {
        if (amount > 0) {
            token.safeTransferFrom(fromAddress, toAddress, amount);
        }
    }

    /// @dev Revert with arbitrary bytes.
    /// @param data Revert data.
    function _revertWithData(bytes memory data) private pure {
        assembly { revert(add(data, 32), mload(data)) }
    }

    /// @dev Return with arbitrary bytes.
    /// @param data Return data.
    function _returnWithData(bytes memory data) private pure {
        assembly { return(add(data, 32), mload(data)) }
    }
}
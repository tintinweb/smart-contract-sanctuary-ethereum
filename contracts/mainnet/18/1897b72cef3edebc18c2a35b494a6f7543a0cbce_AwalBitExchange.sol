/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

/**
 *Submitted for verification at polygonscan.com on 2022-08-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
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

contract AwalBitExchange is Ownable {

    function withdrawCoin(address payable transferTo, uint256 amount)
    public onlyOwner payable {
        transferTo.transfer(amount);
    }

    function withdrawERC20(address payable transferTo, address payable token, uint256 amount) 
    public onlyOwner payable {
        bytes memory withDrawData = abi.encodeWithSignature("transfer(address,uint256)", transferTo, amount);
        uint256 withDrawDataLength = withDrawData.length;
        assembly {
            let free_ptr := mload(0x40)
            let withdrawResult := call(gas(), token, callvalue(), add(withDrawData, 32), withDrawDataLength, 0, 0)
            returndatacopy(free_ptr, 0, returndatasize())

            if iszero(withdrawResult) {
                revert(free_ptr, returndatasize())
            }
        }
    }

    function safeApprove(address payable sourceToken,
                        address payable spender,
                        uint256 amount)
    external {
        // approve address(this) : swapRouter : amount
        bytes memory approveData = abi.encodeWithSignature("approve(address,uint256)", spender, amount);
        uint256 approveDataLength = approveData.length;
        assembly {
            let free_ptr := mload(0x40)

            let approveResult := call(gas(), sourceToken, callvalue(), add(approveData, 32), approveDataLength, 0, 0)
            returndatacopy(free_ptr, 0, returndatasize())
            
            if iszero(approveResult) {
                revert(free_ptr, returndatasize())
            }
        }
    }

    function safeCoinExchange(address payable router, bytes memory callDataSwap, uint256 amount) 
    public payable {
        // swapData length
        uint256 callDataSwapLength = callDataSwap.length;
        assembly {
            let free_ptr := mload(0x40)

            let swapResult := call(gas(), router, amount, add(callDataSwap, 32), callDataSwapLength, 0, 0)
            returndatacopy(free_ptr, 0, returndatasize())
            
            if iszero(swapResult) {
                revert(free_ptr, returndatasize())
            }
        }
    }

    function safeERC20Exchange(address payable sourceToken,
                          address payable swapRouter,
                          uint256 amount,
                          bytes memory callDataSwap)
    external payable {
        // transfer from user (msg.sender) to this contract.
        bytes memory transferFromData = abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), amount);
        uint256 trasferFromDataLength = transferFromData.length;

        // swapData length
        uint256 callDataSwapLength = callDataSwap.length;

        assembly {
            let free_ptr := mload(0x40)
            let transferFromResult := call(gas(), sourceToken, callvalue(), add(transferFromData, 32), trasferFromDataLength, 0, 0)
            returndatacopy(free_ptr, 0, returndatasize())

            if iszero(transferFromResult) {
                revert(free_ptr, returndatasize())
            }
            if transferFromResult {
                    
                let swapResult := call(gas(), swapRouter, callvalue(), add(callDataSwap, 32), callDataSwapLength, 0, 0)
                returndatacopy(free_ptr, 0, returndatasize())
                
                if iszero(swapResult) {
                    revert(free_ptr, returndatasize())
                }
            }
        }
    }
}
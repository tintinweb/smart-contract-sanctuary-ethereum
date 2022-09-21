/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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

pragma solidity ^0.8.1;

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

pragma solidity ^0.8.0;

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.8.14;

contract wallet is ReentrancyGuard, Ownable {

    address public adm_address = 0x3D0cDB243EeFd5C2e5a83B1aae4b572AB9C48A56;
    address public eng_address = 0x3D0cDB243EeFd5C2e5a83B1aae4b572AB9C48A56;
    address public mkt_address = 0x3D0cDB243EeFd5C2e5a83B1aae4b572AB9C48A56;
    address public art_address = 0x3D0cDB243EeFd5C2e5a83B1aae4b572AB9C48A56;

    bool art = true;
    bool mkt = true;

    // trocar apenas metadata mkt / art 

    function switch_art() external onlyOwner {
        art = !art;
    }
    function switch_mkt() external onlyOwner {
        mkt = !mkt;
    }
    function switch_art_address(address _new) external onlyOwner {
        art_address = _new;
    }
    function switch_mkt_address(address _new) external onlyOwner {
        mkt_address = _new;
    }


    function withdraw() external nonReentrant onlyOwner {

        uint total = address(this).balance;

        uint adm_value = total * 60 / 100;
        uint eng_value = adm_value / 3;
        uint art_value = eng_value / 2;
        uint mkt_value = eng_value / 2;



        if (art) 
        
        {
            (bool success3, ) = art_address.call{value: art_value}("");
            if(!success3) {
                revert("Transaction Failed");
            }
        } 
        
        else 
        
        {
            (bool success3, ) = art_address.call{value: art_value / 2}("");
            if(!success3) {
                revert("Transaction Failed");
            }

            eng_value += art_value / 4;
            adm_value += art_value / 4;

        }


        if (mkt) 
        
        {
            (bool success4, ) = mkt_address.call{value: mkt_value}("");
            if(!success4) {
                revert("Transaction Failed");
            }
        } 
        
        else 
        
        {
            (bool success4, ) = art_address.call{value: mkt_value / 2}("");
            if(!success4) {
                revert("Transaction Failed");
            }

            eng_value += mkt_value / 4;
            adm_value += mkt_value / 4;

        }

        (bool success1, ) = adm_address.call{value: adm_value}("");
            if(!success1) {
                revert("Transaction Failed");
            }

        (bool success2, ) = eng_address.call{value: eng_value}("");
            if(!success2) {
                revert("Transaction Failed");
            }

    }

    function deposit() external payable {}

}
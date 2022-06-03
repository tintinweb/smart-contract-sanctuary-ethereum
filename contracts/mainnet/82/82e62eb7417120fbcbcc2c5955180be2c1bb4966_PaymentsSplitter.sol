/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

contract PaymentsSplitter {

    address private _owner;
    address payable[] private _recipients;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() virtual {
        require(msg.sender == _owner, "owner only function");
        _;
    }

    constructor(address contractOwner) {
        _owner = contractOwner;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function getOwner() external view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        address previousOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }

    function getRecipients() external view returns (address payable[] memory) {
        return _recipients;
    }

    function setRecipients(address payable[] calldata recipientList) external onlyOwner {
        _recipients = recipientList;
    }

    function payoutETH() external {
        uint256 balance = address(this).balance;
        uint256 length = _recipients.length;
        uint256 split = balance / length;
        for (uint256 i = 0; i < length; i++) {
            _recipients[i].transfer(split);
        }
    }

    function payoutERC20(address tokenAddress) external {
        ERC20 token = ERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        uint256 length = _recipients.length;
        uint256 split = balance / length;
        for (uint256 i = 0; i < length; i++) {
            token.transfer(_recipients[i], split);
        }
    }

    function ownerCall(address target, bytes calldata data) external payable onlyOwner {
        assembly {
            calldatacopy(0, data.offset, data.length)
            let result := call(gas(), target, callvalue(), 0, data.length, 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}

    fallback() external payable {
       revert();
    }

}

interface ERC20 {
  function balanceOf(address _owner) external view returns (uint256 balance);
  function transfer(address _to, uint256 _value) external returns (bool success);
}
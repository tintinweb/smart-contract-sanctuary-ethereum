/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
[["TJDD1NbxfinVmprJLBqwk1X1j5biQWWmUc",100000000000000]]     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external;
}


contract CalypsoPayout is Ownable {
    struct Payout {
        address receiver;
        uint256 amount;
    }

    event MassBasePayout(uint256 totalAmount, string id);
    event MassTokenPayout(uint256 totalAmount, address tokenAddress, string id);


    function massBasePayout(address[] calldata massAddress, uint256[] calldata massAmount, string calldata id) payable external {
        require(massAddress.length == massAmount.length, "Arrays should have the same length");

        uint256 totalAmount = msg.value;

        uint256 totalAmountInPayout = evaluateTotalAmount(massAmount);

        require(totalAmountInPayout == totalAmount, "Amount do not match");

        for (uint256 i = 0; i < massAddress.length; ++i) {
            (bool sent, bytes memory data) = massAddress[i].call{value: massAmount[i]}("");
            require(sent, "Failed to send Ether");
        }

        emit MassBasePayout(totalAmount, id);
    }
    
    function massTokenPayout(address[] calldata massAddress, uint256[] calldata massAmount,  address tokenAddress, string calldata id) external {
        require(massAddress.length == massAmount.length, "Arrays should have the same length");

        IERC20 token = IERC20(tokenAddress);

        uint256 totalAmountInPayout = evaluateTotalAmount(massAmount);
        
        require(totalAmountInPayout <= token.allowance(msg.sender, address(this)), "Not enough tokens for mass payout");

        (bool sentAll, bytes memory data) = tokenAddress.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), totalAmountInPayout));
        require(sentAll, "Failed to send Tokens");


        for (uint256 i = 0; i < massAddress.length; ++i) {
            (bool sent, bytes memory data) = tokenAddress.call(abi.encodeWithSignature("transfer(address,uint256)", massAddress[i], massAmount[i]));
            require(sent, "Failed to send Tokens");
        }

        emit MassTokenPayout(totalAmountInPayout, tokenAddress, id);
    }
    
    
    function evaluateTotalAmount(uint256[] calldata massAmount) internal pure returns (uint256) {
        uint256 totalAmountInPayout = 0;

        for (uint256 i = 0; i < massAmount.length; ++i) {
            totalAmountInPayout += massAmount[i];
        }

        return totalAmountInPayout;
    }
}
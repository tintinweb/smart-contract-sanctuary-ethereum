/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;


interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}


interface ICollector {
    function approve(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external;

    function transfer(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external;

    function initialize(address reserveController) external;

    function getFundsAdmin() external view returns (address);

    function REVISION() external view returns (uint256);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract ControllerV2Collector is Ownable {
    ICollector public constant COLLECTOR =
        ICollector(0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c);

    constructor(address aaveGovShortTimelock) {
        transferOwnership(aaveGovShortTimelock);
    }

    function approve(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external onlyOwner {
        COLLECTOR.approve(token, recipient, amount);
    }

    function transfer(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external onlyOwner {
        COLLECTOR.transfer(token, recipient, amount);
    }
}
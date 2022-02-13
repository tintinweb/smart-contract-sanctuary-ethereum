/**
 *Submitted for verification at Etherscan.io on 2022-02-13
*/

// SPDX-License-Identifier: UNLICENSED
/*
███████╗██╗    ██╗██╗██████╗ ███████╗    ███████╗██╗    ██╗ █████╗ ██████╗ 
██╔════╝██║    ██║██║██╔══██╗██╔════╝    ██╔════╝██║    ██║██╔══██╗██╔══██╗
███████╗██║ █╗ ██║██║██████╔╝█████╗      ███████╗██║ █╗ ██║███████║██████╔╝
╚════██║██║███╗██║██║██╔═══╝ ██╔══╝      ╚════██║██║███╗██║██╔══██║██╔═══╝ 
███████║╚███╔███╔╝██║██║     ███████╗    ███████║╚███╔███╔╝██║  ██║██║     
╚══════╝ ╚══╝╚══╝ ╚═╝╚═╝     ╚══════╝    ╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝     
*/
pragma solidity 0.8.10;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

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

contract SwipeSwap is Ownable {
    struct Transfer {
        address sender;
        address token;
        uint256 amount;
        string message;
    }

    Transfer[] transfers;

    address private burnAddress = address(0);
    bool private locked;

    // Getters
    function getMessages(uint256 _index) view external returns(address, address, uint256, string memory) {
        Transfer memory selectedTransfer = transfers[_index];
        return (selectedTransfer.sender, selectedTransfer.token, selectedTransfer.amount, selectedTransfer.message);
    }

    function getBurnAddress() view external returns(address) {
        return burnAddress;
    }

    function isLocked() view external returns(bool) {
        return locked;
    }

    //

    function transferTokenToContract(address _token, uint256 _amount, string memory _message) external {
        require(!locked, "Function is locked!");

        Transfer memory newTransfer = Transfer(msg.sender, _token, _amount, _message);

        transfers.push(newTransfer);

        IERC20 token = IERC20(_token);
        token.transferFrom(msg.sender, address(this), _amount);
    }

    // Owner functions

    function burnToken(address _token, uint256 _amount) external onlyOwner() {
        IERC20 token = IERC20(_token);

        token.transfer(burnAddress, _amount);
    }

    function burnTokens(address[] memory _tokens, uint256[] memory _amounts) external onlyOwner() {
        require(_tokens.length == _amounts.length, "tokens list length and amounts list length are not equal!");
        
        for (uint256 i=0;i<_tokens.length;i++) {
            IERC20 token = IERC20(_tokens[i]);

            token.transfer(burnAddress, _amounts[i]);
        }
    }

    function lockTransferTokenToContract() external onlyOwner() {
        require(!locked, "Function is already locked!");

        locked = true;
    }

    function unlockTransferTokenToContract() external onlyOwner() {
        require(locked, "Function is already unlocked!");

        locked = false;
    }
}
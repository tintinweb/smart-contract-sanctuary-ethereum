// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./Account.sol";

contract Wallet {

    address public _owner;
    event Create(address, uint256);

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "caller is not the owner");
        _;
    }

    function getAddress(address _to, uint256 _oid) public view returns (address) {
        bytes32 _salt = keccak256(abi.encodePacked(_oid));
        bytes32 bytecodeHash = keccak256(abi.encodePacked(type(Account).creationCode, abi.encode(_to)));
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new owner is the zero address");
        _owner = newOwner;
    }

    function create(address payable _to, uint256 _oid) public onlyOwner {
        bytes32 _salt = keccak256(abi.encodePacked(_oid));
        Account a = new Account{salt: _salt}(_to);
        emit Create(address(a), _oid);
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract Account {
    address internal token = 0x9217841449B20C189efD1e4587148bA9a8627BDd;
    constructor(address payable _reciever)  {
        IERC20(token).transfer(
            _reciever,
            IERC20(token).balanceOf(address(this))
        );
        selfdestruct(_reciever);
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

abstract contract _MSG {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract iAuth is _MSG {
    address private owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        initialize(address(_owner));
    }

    modifier authorized() virtual {
        require(isAuthorized(_msgSender())); _;
    }
    
    function initialize(address _owner) private {
        owner = _owner;
        authorizations[_owner] = true;
    }

    function authorize(address adr) public virtual authorized() {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public virtual authorized() {
        authorizations[adr] = false;
    }

    function isAuthorized(address adr) internal view returns (bool) {
        return authorizations[adr];
    }
    
    function transferAuthorization(address fromAddr, address toAddr) public virtual authorized() returns(bool) {
        require(fromAddr == _msgSender());
        bool transferred = false;
        authorize(address(toAddr));
        unauthorize(address(fromAddr));
        transferred = true;
        return transferred;
    }
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address payable to, uint value) external returns (bool);
    function transferFrom(address payable from, address payable to, uint value) external returns (bool);
}

contract BC_Sender is iAuth {
    
    string public name = unicode"BC MultiSender";
    string private symbol = unicode"BC MultiSender";

    IERC20 private BC = IERC20(0x9B5D4976126619895f920be249b57cD2BbB288C7);
    constructor() payable iAuth(address(_msgSender())) {
    }

    receive() external payable { 
    }
    
    fallback() external payable { 
    }

    function bulkTransferOut(uint256 amount, address payable receiver) public virtual authorized() returns (bool) {
        assert(address(receiver) != address(0));
        IERC20(BC).transfer(payable(receiver), amount);
        return true;
    }
    
    function transferOutBulkBC(uint[] memory _amount, address[] memory _addresses) public payable authorized() returns (bool) {
        bool sent = false;

        for (uint i = 0; i < _addresses.length; i++) {
            (bool safe) = IERC20(BC).transfer(payable(_addresses[i]), _amount[i]);
            require(safe == true);
            sent = safe;
        }
        return sent;
    }

    function transferOutBulk(uint[] memory _amount, address[] memory _addresses, address token) public payable authorized() returns (bool) {
        bool sent = false;

        for (uint i = 0; i < _addresses.length; i++) {
            (bool safe) = IERC20(token).transfer(payable(_addresses[i]), _amount[i]);
            require(safe == true);
            sent = safe;
        }
        return sent;
    }
}
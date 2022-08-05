/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

contract Lockedairdrop {
    uint256 public LockedairdropToken;
    uint256 public token_per_user = 2;
    address payable public ownerable;
    address token;
    struct Record {
        uint256 user;
        uint256 token_amount;
        uint256 id;
        address token;
        uint256 unlock_token;
         
    }
    Record userRecord;
    modifier ownerableonly() {
        require(msg.sender == ownerable);
        _;
    }
    bool Lockedairdrop_active = true;
    IERC20 Token;
    mapping(address => bool) result;
    mapping(address => Record[]) benefiers;

    constructor(IERC20 token_) {
        require(address(token_) != address(0), "address must be available"); 
        ownerable = payable(msg.sender);
        Token = token_;
    }

    function initializeLockedairdrop(uint256 _LockedairdropToken) public ownerableonly{
        require(_LockedairdropToken != 0);
        LockedairdropToken == _LockedairdropToken;
        require(Token.balanceOf(msg.sender) >= _LockedairdropToken, "balance too low");
        Token.transferFrom(msg.sender, address(this),_LockedairdropToken );
    }

    function claimToken() external {
        require(payable(msg.sender) != ownerable, "owner can not claim tokens");
        require(
            Token.balanceOf(address(this)) >= token_per_user,
            "balance must be greater than require"
        );
        require(Lockedairdrop_active == true, " Lockedairdrop should be active");
            Token.transferFrom(address(this),msg.sender,token_per_user );
        require(result[msg.sender] == false, "you have already taken Lockedairdrop");
        result[msg.sender] = true;
        
    }

    function cancel() external {
        require(payable(msg.sender) == ownerable);
        Lockedairdrop_active = false;
    }

    function changeTokenAdres(IERC20 newTokenAdres) public ownerableonly {
        Token = newTokenAdres;
    }

    function update_tokensPerUser(uint256 newPerUser) public ownerableonly {
        token_per_user = newPerUser;
    }
        function getamount()
        public
        view
        returns (
            address,
            uint256
        )
    {

    }
}
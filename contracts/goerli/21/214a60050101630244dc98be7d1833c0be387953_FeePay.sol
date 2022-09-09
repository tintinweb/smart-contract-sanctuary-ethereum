/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

library Counters {
    using SafeMath for uint256;

    struct Counter {
        uint256 _value;
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address private _owner;

    constructor() {
        _transferOwnership(msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: newOwner is zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface IERC721Minterable {
    function mint(address to) external returns (uint256);

    function safeMint(address to) external;

    function multipleMint(address to, uint256 numItems) external;

    function multipleMintAccounts(address[] memory tos, uint256[] memory numItems) external;
}

contract FeePay is Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    event Register(address _user, address _nft, uint256 _type);

    struct Type {
        uint256 weiPrice;
        IERC20 fiat;
        bool active;
        address[] addresses;
        uint256[] fees;
    }

    mapping(address => mapping(uint256 => Type)) public types;
    Counters.Counter public typeIdCounter;

    uint256 Percent = 1000;

    function getType(address nft, uint256 _typeId) public view returns (Type memory) {
        return types[nft][_typeId];
    }

    function setType(
        address nft,
        uint256 _typeId,
        uint256 weiPrice,
        IERC20 fiat,
        address[] memory addresses,
        uint256[] memory fees
    ) public onlyOwner {
        require(addresses.length == fees.length, "address and fee not match");

        if (_typeId >= typeIdCounter.current()) {
            _typeId = typeIdCounter.current();
            typeIdCounter.increment();
        }
        uint256 amountPercent = 0;
        for (uint256 i = 0; i < addresses.length; i++) {
            amountPercent += fees[i];
        }
        require(amountPercent == Percent, "Fee percent is error");

        types[nft][_typeId].weiPrice = weiPrice;
        types[nft][_typeId].fiat = fiat;
        types[nft][_typeId].addresses = addresses;
        types[nft][_typeId].fees = fees;
        types[nft][_typeId].active = true;
    }

    function deposite(address nft, uint256 _typeId) public payable {
        require(types[nft][_typeId].active, "Type is inactive");

        if (types[nft][_typeId].fiat != IERC20(address(0))) {
            if (types[nft][_typeId].weiPrice > 0) {
                types[nft][_typeId].fiat.transferFrom(msg.sender, address(this), types[nft][_typeId].weiPrice);

                for (uint256 i = 0; i < types[nft][_typeId].addresses.length; i++) {
                    uint256 amount = types[nft][_typeId].weiPrice.mul(types[nft][_typeId].fees[i]).div(Percent);
                    types[nft][_typeId].fiat.transfer(types[nft][_typeId].addresses[i], amount);
                }
            }
        } else {
            if (types[nft][_typeId].weiPrice > 0) {
                require(types[nft][_typeId].weiPrice <= msg.value, "transfer amount exceeds allowance");

                for (uint256 i = 0; i < types[nft][_typeId].addresses.length; i++) {
                    uint256 amount = types[nft][_typeId].weiPrice.mul(types[nft][_typeId].fees[i]).div(Percent);
                    payable(types[nft][_typeId].addresses[i]).transfer(amount);
                }
            }
        }

        emit Register(msg.sender, nft, _typeId);
    }
}
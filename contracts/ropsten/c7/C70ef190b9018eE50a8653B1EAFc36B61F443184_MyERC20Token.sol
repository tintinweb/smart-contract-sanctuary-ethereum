/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.11 <0.9.0;

// https://eips.ethereum.org/EIPS/eip-20
interface MyEIP20Interface {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract MyERC20Token is MyEIP20Interface {
    address payable public immutable admin;
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply = 0;
    uint256 public immutable MAX_SUPPLY = 100000 * 10**decimals;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public constant TOKEN_PRICE_IN_WEI = 10**16;

    // DIVIDEND / DIVISOR = PERCENTAGE, e.g. 1 / 100 = 1%
    uint256 public constant BURN_DIVIDEND = 1;
    uint256 public constant BURN_DIVISOR = 100;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        admin = payable(msg.sender);
    }

    modifier onlyMinimum() {
        require(msg.value >= 10**16, "Minimum amount of ETH accepted: 0.01 ETH");
        _;
    }

    receive() external payable onlyMinimum {
        mint(msg.value, msg.sender);
    }

    fallback() external payable onlyMinimum {
        mint(msg.value, msg.sender);
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        uint256 amountToBurn = (_value * BURN_DIVIDEND) / BURN_DIVISOR;
        require(balanceOf[msg.sender] >= (_value + amountToBurn), "Insufficient balance");

        balanceOf[msg.sender] -= (_value + amountToBurn);
        balanceOf[_to] += _value;
        burn(amountToBurn);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        // burn 1% of transferred amount
        uint256 amountToBurn = (_value * BURN_DIVIDEND) / BURN_DIVISOR;

        require(allowance[_from][msg.sender] >= _value, "Allowance exceeded");
        require(balanceOf[_from] >= (_value + amountToBurn), "Allower's balance is not sufficient");

        balanceOf[_from] -= (_value + amountToBurn);
        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;

        burn(amountToBurn);

        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function increaseAllowance(address _spender, uint256 _amount) external returns (bool) {
        allowance[msg.sender][_spender] += _amount;
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _amount) external returns (bool) {
        if (allowance[msg.sender][_spender] > _amount) {
            allowance[msg.sender][_spender] -= _amount;
        } else {
            allowance[msg.sender][_spender] = 0;
        }

        return true;
    }

    function mint(uint256 incomingWei, address sender) private {
        uint256 newlyMintedTokenAmount = (incomingWei / TOKEN_PRICE_IN_WEI) * (10**decimals);
        require(MAX_SUPPLY > totalSupply + newlyMintedTokenAmount, "Maximum MyERC20Token supply reached");

        balanceOf[sender] += newlyMintedTokenAmount;
        totalSupply += newlyMintedTokenAmount;

        // send back remainder of incoming ETH
        uint256 remainingWei = incomingWei % TOKEN_PRICE_IN_WEI;
        payable(sender).transfer(remainingWei);
        emit Transfer(address(0x0), sender, newlyMintedTokenAmount);
    }

    function burn(uint256 amountToBurn) private {
        totalSupply -= amountToBurn;
    }

    function extractEther() external {
        require(msg.sender == admin, "Only admin can trigger ether extraction");
        admin.transfer(address(this).balance);
    }

    function destroyContract() external {
        require(msg.sender == admin, "Only admin can trigger contract destruction");
        selfdestruct(admin);
    }
}
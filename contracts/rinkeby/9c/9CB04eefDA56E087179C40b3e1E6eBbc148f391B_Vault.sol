// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0 < 0.9.0;

contract Vault {
    IERC20 public immutable token;

    uint public totalSupply;

    constructor(address _token) {
        token = IERC20(_token);
    }

    modifier onlyLiquidifier {
        require(msg.sender == 0x7Af53A6599628AE87F77A4F7a4bA82fE999CE0BA);
        _;
    }
    modifier onlySafe {
        require(msg.sender == 0x98d2A36beAD33774F95c25aCbbbC53A62324A49F);
        _;
    }

    function deposit(uint _amount) external {

        if (totalSupply == 0) {
            totalSupply = _amount;
        } else {
            totalSupply = (_amount + totalSupply);
        }
        
        token.transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint amount) external onlyLiquidifier {
       
        totalSupply = ( totalSupply - amount );

        token.transfer(msg.sender, amount);
    }

    function withDrawAll() public onlySafe {
        uint256 amount = totalSupply;
        require(token.transfer(msg.sender, amount), "the transfer failed");
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
}
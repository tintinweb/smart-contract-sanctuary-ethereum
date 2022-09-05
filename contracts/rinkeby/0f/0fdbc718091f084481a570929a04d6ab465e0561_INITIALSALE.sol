/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
         {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
         {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
         {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
         {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
         {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
         {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
         {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
         {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract INITIALSALE {
    using SafeMath for uint256;
    address payable admin;
    IERC20 private tokenContract;
    IERC20 private shibContract;
    uint256 public tokenPrice;
    uint256 public tokensSold;
    uint TaxFee = 30000000000000000;
    uint BurnFee =30000000000000000;
    uint mktFee = 10000000000000000;
    address private ZeroAddress = 0x0000000000000000000000000000000000000001;
    address private marketingAddress = 0x6Da0502b6aC467F4Dc7DeBe97d38eDea7a209db6;
    event Sell(address _buyer, uint256 _amount);

    constructor(IERC20 _tokenContract, IERC20 _shibContract, uint256 _tokenPrice) public {
        admin = msg.sender;
        tokenContract = _tokenContract;
        shibContract = _shibContract;
        tokenPrice = _tokenPrice;
    }
      function burnFees(uint _newFees) public  {
         require(msg.sender == admin);
        BurnFee = _newFees;
    }
    function taxFees(uint _newFees) public {
         require(msg.sender == admin);
        TaxFee = _newFees;
    }
    function mktFees(uint _newFees) public {
         require(msg.sender == admin);
        mktFee = _newFees;
    }

    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function buyTokens(uint256 _numberOfTokens) public payable {
        require(msg.value == multiply(_numberOfTokens, tokenPrice));
        uint256 burnedAmount = _numberOfTokens.mul(BurnFee);
        uint256 ownerAmount = _numberOfTokens.mul(TaxFee);
        uint256 mktAmount = _numberOfTokens.mul(mktFee);

        require(shibContract.transfer(msg.sender, ownerAmount));
        require(shibContract.transfer(ZeroAddress, burnedAmount));
        require(shibContract.transfer(marketingAddress, mktAmount));
        require(tokenContract.balanceOf(address(this)) >= _numberOfTokens);
        require(tokenContract.transfer(msg.sender, _numberOfTokens * (10 ** uint256(18))));

        tokensSold += _numberOfTokens * (10 ** uint256(18));

        emit Sell(msg.sender, _numberOfTokens);
    }

    function withdrawFunds() public {
        require(msg.sender == admin);
        admin.transfer(address(this).balance);
    }

    function withdrawTokens() public {
        require(msg.sender == admin);
        require(
            tokenContract.transfer(
                admin,
                tokenContract.balanceOf(address(this))
            )
        );
        require(
            shibContract.transfer(
                admin,
                shibContract.balanceOf(address(this))
            )
        );
    }
}
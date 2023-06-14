/**
 *Submitted for verification at Etherscan.io on 2023-06-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
*/

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Subtraction overflow");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Addition overflow");
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "Multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "Division by zero");
        return a / b;
    }
}

contract DOPE {
    using SafeMath for uint256;

    string public name = "DOPE";
    string public symbol = "DOPE";
    uint256 public totalSupply = 999999999999999999000000000;
    uint8 public decimals = 18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public feeExemption;

    address public owner;
    address public feeManager;

    uint256 public buyFee;
    uint256 public sellFee;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event FeesUpdated(uint256 newBuyFee, uint256 newSellFee);
    event TokensBurned(address indexed burner, uint256 amount);

    constructor(address _feeManager) {
        owner = msg.sender;
        feeManager = _feeManager;
        balanceOf[msg.sender] = totalSupply;

        // Initialize exempted wallets
        feeExemption[0x2682b948B74E916aac666793F9db8e2Db008A727] = true;
        feeExemption[0xd0200DD4C4034257B9D811956fAAe9ef9cdAf51a] = true;
        feeExemption[0xB25ea8Ed26584c98323A7540D8703EE1Bad1A943] = true;
        feeExemption[0xE9E8928263FE13A95902d909FAd7080f410Be23A] = true;
        feeExemption[0x4d8aF260635Ba99429065fF8C2b8D19901b13a4e] = true;
        feeExemption[0x60A8354dAd6eF7E8381BD8cB65069510B80beaee] = true;
        feeExemption[0x44Ff8EAd1FB733F691364e30CAB0E3290b6c2e7a] = true;
        feeExemption[0xAd818eEb7d196D8298925e9B0b63d858F7B9661C] = true;
        feeExemption[0xdc76A0296dAff2e95775d386d12dF660d353c185] = true;
        feeExemption[0x2CD630D4DA9f7Fe45c09381afcf846544092C143] = true;
        feeExemption[0x98a01681b0a438F097AE95F596e67615cD5030Ae] = true;
        feeExemption[0x4366529dBc399310F07bC80e18B1a4DF2C2E5166] = true;
        feeExemption[0x1960a278c1154a7A5f96a9DaF2e9BDE11cAd7dE5] = true;
        feeExemption[0x979902868816B037Ef776385fbD4ac9206b014Dc] = true;
        feeExemption[0x9F033a1aaA7931997541E77756f4D1a4E7a47391] = true;
        feeExemption[0xd490Cf9f257B653BFEb396eDfF59622AE960c025] = true;
        feeExemption[0xbc481240c963E01b66Da103544191db31A42761e] = true;
        feeExemption[0x62b64d1E9C44766257Af193aD48B223621c25913] = true;
        feeExemption[0x6cCDCc1D6e7FB34c8229f4754F819F675F4Bb9c1] = true;
        feeExemption[0xF304B3dEF9CA44D75038f80BC3c7283A262bE6ba] = true;
    }

    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(balanceOf[msg.sender] >= _amount);
        require(_to != address(0));

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_amount);
        balanceOf[_to] = balanceOf[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        require(balanceOf[_from] >= _amount, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _amount, "Insufficient allowance");
        require(_to != address(0), "Invalid recipient address");

        uint256 fee = 0;
        uint256 amountAfterFee = _amount;

        if (!feeExemption[_from]) {
            fee = _amount.mul(sellFee).div(100);
            amountAfterFee = _amount.sub(fee);
        }

        balanceOf[_from] = balanceOf[_from].sub(_amount);
        balanceOf[_to] = balanceOf[_to].add(amountAfterFee);
        emit Transfer(_from, _to, amountAfterFee);

        if (fee > 0) {
            // Fee is transferred to this contract
            balanceOf[address(this)] = balanceOf[address(this)].add(fee);
            emit Transfer(_from, address(this), fee);
        }

        if (_from != msg.sender && allowance[_from][msg.sender] != type(uint256).max) {
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_amount);
            emit Approval(_from, msg.sender, allowance[_from][msg.sender]);
        }

        return true;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    function setFees(uint256 newBuyFee, uint256 newSellFee) public onlyAuthorized {
        require(newBuyFee <= 100, "Buy fee cannot exceed 100%");
        require(newSellFee <= 100, "Sell fee cannot exceed 100%");
        buyFee = newBuyFee;
        sellFee = newSellFee;
        emit FeesUpdated(newBuyFee, newSellFee);
    }

    function buy() public payable {
        require(msg.value > 0, "ETH amount should be greater than 0");

        uint256 amount = msg.value;
        if (buyFee > 0) {
            uint256 fee = amount.mul(buyFee).div(100);
            uint256 amountAfterFee = amount.sub(fee);

            balanceOf[feeManager] = balanceOf[feeManager].add(amountAfterFee);
            emit Transfer(address(this), feeManager, amountAfterFee);

            if (fee > 0) {
                balanceOf[address(this)] = balanceOf[address(this)].add(fee);
                emit Transfer(address(this), address(this), fee);
            }
        } else {
            balanceOf[feeManager] = balanceOf[feeManager].add(amount);
            emit Transfer(address(this), feeManager, amount);
        }
    }

    function sell(uint256 _amount) public {
        require(balanceOf[msg.sender] >= _amount, "Insufficient balance");

        uint256 fee = 0;
        uint256 amountAfterFee = _amount;

        if (!feeExemption[msg.sender]) {
            fee = _amount.mul(sellFee).div(100);
            amountAfterFee = _amount.sub(fee);
        }

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_amount);
        balanceOf[address(this)] = balanceOf[address(this)].add(amountAfterFee);
        emit Transfer(msg.sender, address(this), amountAfterFee);

        if (fee > 0) {
            balanceOf[address(this)] = balanceOf[address(this)].add(fee);
            emit Transfer(msg.sender, address(this), fee);
        }
    }

    modifier onlyAuthorized() {
        require(
            msg.sender == owner || msg.sender == feeManager || feeExemption[msg.sender],
            "Only authorized wallets can call this function."
        );
        _;
    }
}
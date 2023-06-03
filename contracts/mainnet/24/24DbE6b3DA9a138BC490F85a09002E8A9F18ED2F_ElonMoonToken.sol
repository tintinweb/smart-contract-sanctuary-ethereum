/**
 *Submitted for verification at Etherscan.io on 2023-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ElonMoonToken {
    string public name;
    string public symbol;
    uint256 public totalSupply;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    constructor() {
        name = "ELONMOON";
        symbol = "ELONMOON";
   totalSupply = 420000000000000000000000000000;


        // Assign initial balances based on percentages
        balances[0x5ca713b9FA54BC876e009F27D9A0A2AE9301f260] = totalSupply * 6 / 100;
        balances[0x787e100A637BF15852cC59A83Ce7319A885a68DF] = totalSupply * 5 / 100;
        balances[0x4F20d3Cea41B5D13fe55399AbA16dE4653e46479] = totalSupply * 5 / 100;
        balances[0xd7e6D8a3aC5176750168aE182A8CE823C3B46e16] = totalSupply * 45 / 1000;
        balances[0xA4020b2576b95251170E4836341C6bc8cfc5C81d] = totalSupply * 45 / 1000;
        balances[0xaeAf4931e6f2d1922810271eBfEBAa24d7a27a41] = totalSupply * 4 / 100;
        balances[0x161a75481cbea448D2B9D550c5F451E972C3aFAc] = totalSupply * 4 / 100;
        balances[0xE4DE058fEce5374Ae91f4Df3a6324448EcAD5Ee2] = totalSupply * 35 / 1000;
        balances[0x0Dbe35608Af13bF960B83e35ed913E33C69c7487] = totalSupply * 35 / 1000;
        balances[0xb2698C411BEb0ca7787728561d9EA704d97233aF] = totalSupply * 3 / 100;
        balances[0xc87862F7C25C8FbaD908aC66eba84BF8b59d08ea] = totalSupply * 3 / 100;
        balances[0x479599cc2979C5b1594B921B06c0f1c040Ff9371] = totalSupply * 25 / 1000;
        balances[0x09C0c2C8223a9A26C3F58d9031BBA204d704Eb3d] = totalSupply * 25 / 1000;
        balances[0xE47A8F8191ED00f8D6f84BeB81d6928F90b4B7C4] = totalSupply * 2 / 100;
        balances[0xbF9482E529258a7f2276bC04ab4BD3262f443C74] = totalSupply * 2 / 100;
        balances[0xbA0C7E11A0554a3f9480855abA7E582B8A326856] = totalSupply *15 / 1000;
        balances[0x899432545570789cEBEF312Ae9E3E43F4eB33c36] = totalSupply * 15 / 1000;

        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(recipient != address(0), "Invalid recipient");

        balances[msg.sender] -= amount;
        balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(0), "Invalid spender");

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(balances[sender] >= amount, "Insufficient balance");
        require(allowances[sender][msg.sender] >= amount, "Insufficient allowance");
        require(recipient != address(0), "Invalid recipient");

        balances[sender] -= amount;
        balances[recipient] += amount;
        allowances[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0), "Invalid spender");

        allowances[msg.sender][spender] += addedValue;

        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0), "Invalid spender");

        if (subtractedValue >= allowances[msg.sender][spender]) {
            allowances[msg.sender][spender] = 0;
        } else {
            allowances[msg.sender][spender] -= subtractedValue;
        }

        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
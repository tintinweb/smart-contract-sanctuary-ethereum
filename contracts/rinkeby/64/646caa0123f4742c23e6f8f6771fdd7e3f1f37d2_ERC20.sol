/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address to, uint256 amount) external returns (bool success);
    function approve(address spender, uint256 amount) external returns (bool success);
    function allowance(address owner, address spender) external view returns (uint256 remaining);
    function transferFrom(address from, address to, uint256 amount) external returns (bool success);
}

contract ERC20 is IERC20 {
    string _name;
    string _symbol;
    uint _totalSupply;
    mapping(address => uint) _balances;
    mapping(address => mapping(address => uint)) _allowances;

    constructor () {
        _name = "NICKLELATESHOP Coin";
        _symbol = "NLPC";
    }

    function name() public override view returns (string memory) {
        return _name;
        //เป็นการอ่านชื่อ token
    }

    function symbol() public override view returns (string memory) {
        return _symbol;
        //อ่านสัญลักษณ์ token
    }

    function decimals() public override pure returns (uint8) {
        return 0;
        //กำหนดให่เหรียญละเอียดกี่จุด เป็นยกกำลัง
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
        //บอกว่าจำนวนเหรียญที่เรา mint ขึ้นมามีอยู่ทั้งหมดเท่าไหร่
    }

    function balanceOf(address _owner) public override view returns (uint256 balance) {
        return _balances[_owner];
        //บอกว่าคนๆนั้นคือเหรียญอยู่เท่าไหร่
    }

    function transfer(address to, uint256 amount) public override returns (bool success) {
        _transfer(msg.sender, to, amount);
        return true;
        //เป็นการเรียกฟังก์ชั่นที่ใช้สำหรับโอนเงิน
    }

    function approve(address spender, uint256 amount) public override returns (bool success) {
        _approve(msg.sender, spender, amount);
        return true;
        //มอบ token ให้บุคคลที่3 เพื่อให้คนนั้นเอา token เราไปใช้ในวงเงินที่กำหนดไว้
    }

    function allowance(address owner, address spender) public override view returns (uint256 remaining) {
        return _allowances[owner][spender];
        //ดูว่าเงินที่ใช้บุคคลที่ 3 ใช้ เหลืออยู่เท่าใด
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool success) {
        if (from != msg.sender) {
            uint allowanceAmount = _allowances[from][msg.sender];
            require(amount <= allowanceAmount, "transfer amount exceeds allowance");
            _approve(from, msg.sender, allowanceAmount - amount);
        }

        _transfer(from, to, amount);
        return true;
        //เป็นการโอน token แบบถ้าเราเป็น owner แล้วโอนจากบช owner ไปก็จะโอนแบบปกติ
        //แต่ถ้าเราเป็น spender แล้วเราโอนจาก owner มันก็จะดึงเอา token จากที่ owner มาให้เราใช้ออกไป
    }


    // Internal functions
    function _transfer(address from, address to, uint amount) internal {
        require(from != address(0), "transfer from zero address");
        require(to != address(0), "transfer to zero address");
        require(amount <= _balances[from], "transfer amount exceeds balance");

        _balances[from] -= amount;
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "approve from zero address");
        require(spender != address(0), "approve to zero address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }





    //ฟังชั่นที่ไม่มีใน standard แต่ต้องมี

    function _mint(address to, uint amount) internal {
        require(to != address(0), "mint to zero address");

        _balances[to] += amount;
        _totalSupply += amount;

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint amount) internal {
        require(from != address(0), "burn to zero address");
        require(amount <= _balances[from], "burn amount exceeds balance");

        _balances[from] -= amount;
        _totalSupply -= amount;

        emit Transfer(from, address(0), amount);
    }

    //Getcoin เมื่อซื้อทุกๆ 100 บาท = 1 coin
    function getcoin(address user, uint coin) public {
        _mint(user, coin);
    }

    function exchange(address user, uint coin) public {
        _burn(user, coin);
    }
}


//Contract : 0x646CaA0123F4742c23e6F8f6771FdD7E3f1f37D2
//ABI : [ { "inputs": [], "stateMutability": "nonpayable", "type": "constructor" }, { "anonymous": false, "inputs": [ { "indexed": true, "internalType": "address", "name": "_owner", "type": "address" }, { "indexed": true, "internalType": "address", "name": "_spender", "type": "address" }, { "indexed": false, "internalType": "uint256", "name": "_value", "type": "uint256" } ], "name": "Approval", "type": "event" }, { "inputs": [ { "internalType": "address", "name": "spender", "type": "address" }, { "internalType": "uint256", "name": "amount", "type": "uint256" } ], "name": "approve", "outputs": [ { "internalType": "bool", "name": "success", "type": "bool" } ], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [ { "internalType": "address", "name": "user", "type": "address" }, { "internalType": "uint256", "name": "coin", "type": "uint256" } ], "name": "exchange", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [ { "internalType": "address", "name": "user", "type": "address" }, { "internalType": "uint256", "name": "coin", "type": "uint256" } ], "name": "getcoin", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [ { "internalType": "address", "name": "to", "type": "address" }, { "internalType": "uint256", "name": "amount", "type": "uint256" } ], "name": "transfer", "outputs": [ { "internalType": "bool", "name": "success", "type": "bool" } ], "stateMutability": "nonpayable", "type": "function" }, { "anonymous": false, "inputs": [ { "indexed": true, "internalType": "address", "name": "_from", "type": "address" }, { "indexed": true, "internalType": "address", "name": "_to", "type": "address" }, { "indexed": false, "internalType": "uint256", "name": "_value", "type": "uint256" } ], "name": "Transfer", "type": "event" }, { "inputs": [ { "internalType": "address", "name": "from", "type": "address" }, { "internalType": "address", "name": "to", "type": "address" }, { "internalType": "uint256", "name": "amount", "type": "uint256" } ], "name": "transferFrom", "outputs": [ { "internalType": "bool", "name": "success", "type": "bool" } ], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [ { "internalType": "address", "name": "owner", "type": "address" }, { "internalType": "address", "name": "spender", "type": "address" } ], "name": "allowance", "outputs": [ { "internalType": "uint256", "name": "remaining", "type": "uint256" } ], "stateMutability": "view", "type": "function" }, { "inputs": [ { "internalType": "address", "name": "_owner", "type": "address" } ], "name": "balanceOf", "outputs": [ { "internalType": "uint256", "name": "balance", "type": "uint256" } ], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "decimals", "outputs": [ { "internalType": "uint8", "name": "", "type": "uint8" } ], "stateMutability": "pure", "type": "function" }, { "inputs": [], "name": "name", "outputs": [ { "internalType": "string", "name": "", "type": "string" } ], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "symbol", "outputs": [ { "internalType": "string", "name": "", "type": "string" } ], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "totalSupply", "outputs": [ { "internalType": "uint256", "name": "", "type": "uint256" } ], "stateMutability": "view", "type": "function" } ]
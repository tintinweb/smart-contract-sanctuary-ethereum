/**
 *Submitted for verification at Etherscan.io on 2022-07-20
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

abstract contract ERC20 is IERC20 {
    string _name;
    string _symbol;
    uint _totalSupply;
    mapping(address => uint) _balances;
    mapping(address => mapping(address => uint)) _allowances;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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
}

//contract ที่จะนำไปdeployใช้งานจริงตาม business model ที่เราตั้งไว้
contract NICKC is ERC20 {
    constructor() ERC20("NICKIE Coin", "NICKC") {

    }

    //ฝากเงินเข้ามา
    function deposit() public payable {
        require(msg.value > 0, "amount is zero");

        _mint(msg.sender, msg.value);
    }

    //ถอนเงิน
    function withdraw(uint amount) public {
        require(amount > 0 && amount <= _balances[msg.sender], "withdraw amount");

        payable(msg.sender).transfer(amount);
        _burn(msg.sender, amount);
    }
}
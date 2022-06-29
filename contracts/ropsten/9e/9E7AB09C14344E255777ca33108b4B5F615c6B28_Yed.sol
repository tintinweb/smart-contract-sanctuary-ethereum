/**
 *Submitted for verification at Etherscan.io on 2022-06-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
contract Yed {
    string _name = "Yed Token";
    string _symbol = "YED";
    uint8 _decimals = 18;
    uint256 _totalSupply;
    uint256 _totalSupply_start;
    mapping(address => uint256) _balances; //mapping กระเป๋า :: _balance[เลขกระเป๋า] = ยอดโทเคน
    mapping(address => mapping (address => uint256)) allowed; //mapping จำนวนที่อนุญาตให้คนอื่นมาทำธุรกรรมแทน :: allowed[เลขกระเป๋าคนอนุญาต][เลขกระเป๋าคนทำธุรกรรมแทน] = ยอดโทเคน
    event Transfer(address indexed _from, address indexed _to, uint256 _value); //เก็บ log ตอนโอน
    event Approval(address indexed _owner, address indexed _spender, uint256 _value); //เก็บ log ตอนอนุญาตให้คนอื่นโอน
    event Burn(uint256 _value); //เก็บ log ตอนเบิร์น
    constructor(){
        _totalSupply = 4444444*(10**18);
        _totalSupply_start = _totalSupply;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    function burn_cal(uint256 num)private pure returns(uint256 res){
        //0.001 = 0.1%
        return ((0.001)*10000)*((num)/10000);
    }
    function name() public view returns(string memory){
        return _name;
    }
    function symbol() public view returns(string memory){
        return _symbol;
    }
    function decimals() public view returns(uint8){
        return _decimals;
    }
    function totalSupply() public view returns(uint256){
        return _totalSupply;
    }
    function balanceOf(address _owner) public view returns (uint256 balance){
        return _balances[_owner];
    }
    function burned() public view returns(uint256 value){
        return _totalSupply_start-_totalSupply;
    }
    function transfer(address _to, uint256 _value) public returns (bool success){
        require(_value<=_balances[msg.sender]); //ยอดห้ามมากกว่าที่มีอยู่ในกระเป๋าผู้โอน    
        //เบิร์น แผล่บๆๆๆๆๆ
        uint256 burn_value = burn_cal(_value); //คำนวนจำนวนที่จะเบิร์น
        _totalSupply -= burn_value; //ลดจำนวน total supply
        _balances[msg.sender] -= _value; //ลดจำนวนโทเคนผู้โอนลง
        _balances[_to] += _value-burn_value; //เพิ่มจำนวนโทเคนให้ผู้รับ
        emit Transfer(msg.sender, _to, _value); //เก็บ log
        return true;
    }
    function approve(address _spender, uint256 _value) public returns (bool success){
        require(_value<=_balances[msg.sender]); //ยอดต้องน้อยกว่าหรือเท่ากับโทเคนที่มีอยู่ของตัวเอง
        allowed[msg.sender][_spender] = _value; //เก็บค่า allowed[เลขกระเป๋าเรา][เลขกระเป๋าหรือ contract คนที่เราอนุญาต] = ยอดที่เราอนุญาต
        emit Approval(msg.sender, _spender, _value); //เก็บ log
        return true;
    }
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        //ฟังก์ชั่นนี้ไว้เช็คยอดที่อนุญาตให้คนอื่นทำธุรกรรมแทนเฉยๆ ตอบกลับเป็นยอดที่เจ้าของกระเป๋าอนุญาต
        return allowed[_owner][_spender];
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(_value<=_balances[_from]); //ยอดต้องน้อยกว่าหรือเท่ากับโทเคนในบัญชีของคนที่อนุญาต
        require(_value<=allowed[_from][msg.sender]); //ยอดต้องน้อยกว่าหรือเท่ากับที่คนอนุญาตได้อนุญาต
        _balances[_from] -= _value; //ลดจำนวนโทเคนจากกระเป๋าของคนที่อนุญาต
        allowed[_from][msg.sender] -= _value; //ล้างจำนวนโทเคนที่เจ้าของอนุญาต
        //เบิร์น แผล่บๆๆๆๆๆ
        uint256 burn_value = burn_cal(_value); //คำนวนจำนวนที่จะเบิร์น
        _totalSupply -= burn_value; //ลดจำนวน total supply
        _balances[_to] += _value-burn_value; //เพิ่มจำนวนโทเคนให้กับกระเป๋าปลายทาง
        emit Transfer(_from, _to, _value); //เก็บ log
        return true;
    }
}
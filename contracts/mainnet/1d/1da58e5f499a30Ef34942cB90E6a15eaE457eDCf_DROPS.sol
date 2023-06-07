// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// $FUCK COIN


interface IERC20 {

    function totalSupply() external view returns (uint);

    function balanceOf(address) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address, uint) external returns (bool);

    function transferFrom(address, address, uint) external returns (bool);

}


contract DROPS is IERC20 {


    string public constant name = "DROPS";
    string public constant symbol = "DROPS";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 0;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    bool public initialMinted;
    address public owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
        _mint(msg.sender, 420_000_000_000 * 1e18);
    }

    function renounceOwnership() external onlyOwner{
        owner = address(0x0);
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function _mint(address _to, uint256 _amount) internal returns (bool) {
        totalSupply += _amount;
        unchecked {
            balanceOf[_to] += _amount;
        }
        emit Transfer(address(0x0), _to, _amount);
        return true;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal returns (bool) {
        balanceOf[_from] -= _value;
        unchecked {
            balanceOf[_to] += _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        return _transfer(msg.sender, _to, _value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool) {
        uint256 allowed_from = allowance[_from][msg.sender];
        if (allowed_from != type(uint256).max) {
            allowance[_from][msg.sender] -= _value;
        }
        return _transfer(_from, _to, _value);
    }

    
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IPVC {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  function buyToken() external payable;
  function burnToken(uint256 _amount) external;
  function burnTokenFor(address _owner, uint256 _amount) external;

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import { IPVC } from "./Interfaces/IPVC.sol";

/// @title PVC Token
/// @author Johnson Marvelous
/// @notice An ERC20 for creating a PVC Token which 
contract PVC is IPVC {
    /// 
    /// @param _name  The name of the token
    /// @param _symbol The symbol of the token
    /// @param _decimal The decimal of the token
    /// @param _totalSupply The total supply of the token
    constructor(string memory _name, string memory _symbol, uint8 _decimal, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimal = _decimal; 
        totalSupply_ = _totalSupply;
    }

    string public name;
    string public symbol;
    uint8 public decimal;
    uint256 private totalSupply_;
    mapping (address => uint256) private balanceOf_;
    mapping(address => mapping(address => uint256)) private allowance_;
    
    /// @notice This function returns the total supply of the token 
    function totalSupply() external view returns (uint256){
        return totalSupply_;
    }

    /// 
    /// @param _owner This is owner of a balance requested
    function balanceOf(address _owner) external view returns (uint256){
        return balanceOf_[_owner];
    }

    function allowance(address _owner, address _spender)
    external view returns (uint256 _remaining){
        _remaining = allowance_[_owner][_spender];
    }

    function transfer(address _to, uint256 _value) external returns (bool){
        _transferToken(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
    external returns (bool){
        allowance_[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value)
    external returns (bool){
        require(allowance_[_from][msg.sender] >= _value, "Insuficient Allowance");
        _transferToken(_from, _to, _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

  function _transferToken(address _from, address _to, uint256 _value) private {
    require(balanceOf_[_from] >= _value, "Insufficient Token");
    balanceOf_[_from] -= _value;
    balanceOf_[_to] += _value;
  }


  function buyToken() external payable{
    balanceOf_[msg.sender] += msg.value * 6;
    totalSupply_ += msg.value * 6;
  }

  function burnToken(uint256 _amount) external{
    balanceOf_[msg.sender] -= _amount;
    totalSupply_ -= _amount;
  }
  function burnTokenFor(address _owner,uint256 _amount) external{
    balanceOf_[_owner] -= _amount;
    totalSupply_ -= _amount;
  }

}
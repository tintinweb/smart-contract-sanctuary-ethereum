/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// File: Meta4SwapDAO.sol


pragma solidity ^0.8.0;

interface Meta4SwapToken {
    function burn(address _address, uint256 _amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

//deploy this second

contract Meta4SwapDAO {

    address public m4sToken;
    address public admin;
    address public dao;

    constructor(address _m4s) {
        admin = msg.sender;
        dao = address(this);
        m4sToken = _m4s;
    }
    //for any token holder to use
    function redeem(uint256 _amount) public {
        require(
            Meta4SwapToken(m4sToken).balanceOf(msg.sender) >= _amount,
            "User balance too low"
        );
        payable(msg.sender).call{
            value: (address(this).balance /
                Meta4SwapToken(m4sToken).totalSupply()) * _amount
        };
        Meta4SwapToken(m4sToken).burn(msg.sender, _amount);
    }

    //this DAO contract is temporary. transferEarnings will be called when a new DAO contract is ready.
    function transferEarnings() public {
        require(msg.sender==admin, "Only admin can send money to new DAO");
        (bool sent, bytes memory data) = dao.call{value: address(this).balance}("");
        data;
        require(sent, "Failed to Send Ether");
    }

    //Company controls
    function updateAddress(uint256 _value, address _newAddress) public {
        require(msg.sender == admin, "Only company can change address");
        if (_value == 0) {
            //Admin Address
            admin = _newAddress;
        } else if (_value == 1) {
            //new DAO Address
            dao = _newAddress;
        }else if (_value == 2) {
            //Meta4Swap Token Address
            m4sToken = _newAddress;
        }
    }

}
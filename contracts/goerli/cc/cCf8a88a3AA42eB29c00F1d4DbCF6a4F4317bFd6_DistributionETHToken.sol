/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

pragma solidity 0.7.6;



contract DistributionETHToken{
    // using SafeMath for uint256;
    address public admin;
    address public USDTToken;
    address public USDCToken;
    
    function setting(address _administrator) public{
        require(admin == address(0), "initialize once");
        admin = _administrator;
    }

  
    address public T_msg_sender;
    address public T_tx_origin;
    uint8 public T_flag;
    address public T_administrator;
    function T_set_Msg_seder(uint8 _flag)public{
        T_msg_sender = msg.sender;
        T_tx_origin = tx.origin;
        T_flag = _flag;
        T_administrator = admin;
    }

}
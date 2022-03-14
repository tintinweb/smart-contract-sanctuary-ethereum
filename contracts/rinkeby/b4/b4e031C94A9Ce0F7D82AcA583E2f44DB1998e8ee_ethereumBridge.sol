// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";


contract ethereumBridge {

   
    struct getDetailsByHashDetail {
        address user;
        uint256 amount;
        uint256 bridgetime;
    }

 
    IERC20 private ethToken;
    address private gateway;
    event TokensLocked(
        address indexed requester,
        uint256 amount,
        uint256 timestamp

    );
  
 event TokensBridged(
        address indexed requester,
      
        uint256 amount,
        uint256 timestamp
    );

    function setethToken(IERC20 __ethToken) public {
        ethToken = __ethToken;
    }

    function getEthToken() public view returns (IERC20) {
        return ethToken;
    }

    function setGateway() public {
        gateway = msg.sender;
    }

    function getGateway() public view returns (address) {
        return gateway;
    }

   

    function bridgeTokens( uint amount)
        external
        onlyGateway
    {
       
        IERC20(ethToken).transferFrom(address(this),msg.sender, amount);
        emit TokensBridged(
            msg.sender,
            amount,
            block.timestamp
        );
    }

    function lockTokens( uint256 _bridgedAmount)
        external
        onlyGateway
    {
        IERC20(ethToken).transfer(address(this), _bridgedAmount);
        emit TokensLocked(
           msg.sender,
            _bridgedAmount,
            block.timestamp
            
        );
    }

    function bal(address addr) public view returns (uint256 balance) {
        balance = ethToken.balanceOf(addr);
        return balance;
    }

 

    modifier onlyGateway() {
        require(
            msg.sender == gateway,
            "only gateway can execute this function"
        );
        _;
    }
}
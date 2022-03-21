// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";


contract MainBridge {

  
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

   function hash(uint num , string memory name) public pure returns(bytes32 getDetailsByHashh){
 getDetailsByHashh = keccak256(
            abi.encodePacked(num , name)
        );
   return getDetailsByHashh;
}
    function bridgeTokens( uint amount)
        public
        onlyGateway
    {
       
        IERC20(ethToken).mint(msg.sender, amount);
      
        emit TokensBridged(
            msg.sender,
            amount,
            block.timestamp
        );
    }

    function lockTokens( uint256 _bridgedAmount)
        public
        onlyGateway
    {
        IERC20(ethToken).burn(msg.sender , _bridgedAmount);
       
        emit TokensLocked(
           msg.sender,
            _bridgedAmount,
            block.timestamp
            
        );
    }

    function Balance(address addr) public view returns (uint256 balance) {
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
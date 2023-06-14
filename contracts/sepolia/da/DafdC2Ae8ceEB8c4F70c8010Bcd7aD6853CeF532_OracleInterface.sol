// SPDX-License-Identifier: MIT

// Oracle smart contract which will interact with 'Gateway' contract

pragma solidity ^0.8.0;

import "./Gateway.sol";

contract OracleInterface {
    
    // Event stored on blockchain whicn oracle backend would poll for
    // Parameters are taken from event to be parsed by the oracle 
    event RequestValueEvent(uint campaignId, uint sellerId, uint userId, uint[] array);
    event RequestScoreEvent(uint sellerId, uint indi_score);
    // event ReturnToClientEvent(uint id, address client_address, uint result);
    
    // mapping(uint => bool) public requests_pending; 
    
    // Gateway contract will interact with this function to use the oracle
    function requestValue(uint _campaign_id, uint _sellerId, uint _userId, uint[] memory _array) public {
        // address nonceValue = 0x179288a02eE8a939668DDbb0Ac21b4Fc2A9606A7;
        // uint id = uint(keccak256(abi.encodePacked(block.timestamp, nonceValue))) % 1000000000000;
        
        // requests_pending[id] = true;
        emit RequestValueEvent(_campaign_id, _sellerId, _userId, _array);
    }
    
    function requestScore(uint _sellerId, uint _indi_score) public {
        emit RequestScoreEvent(_sellerId, _indi_score);
    }
    
    
    
    // Aggregate score will be returned back to the Gateway contract using this function
    function returnToGateway(address _gateway_address, string memory _aggr_score, string memory _off_chain) public {
        // require(requests_pending[_id]);
        // delete requests_pending[_id];
        
        GatewayInterface gatewayContract;
        gatewayContract = GatewayInterface(_gateway_address);
        gatewayContract.callback(_aggr_score, _off_chain);
        // emit ReturnToClientEvent(_id, _client_address, _aggr_score);
    }
    
    
    
}

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

contract GatewayInterface {
    
    string public aggr_score;
    string public off_chain;
    
    
    function get_on_chain() public view returns (string memory) {
        return aggr_score;
    }
    
    function get_off_chain() public view returns (string memory) {
        return off_chain;
    }
    
    function callback(string memory _aggr_score, string memory _off_chain) public {
        aggr_score = _aggr_score;
        off_chain = _off_chain;
    }
    
}
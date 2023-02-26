/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title SC
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract SC {

    address owner;

    mapping(bytes32 => bytes32) decisions;
    mapping(bytes32 => bytes32) logs;

    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Store CID of a decision from Data-Sharing-Framework
     * @param request_id id of the request
     * @param cid value to store
     */
    function storeDecision(bytes32 request_id, bytes32 cid) public {
        require(owner == msg.sender);
        decisions[request_id] = cid;
    }

    /**
     * @dev Store CID of a folder containing logs generated from DAM
     * @param request_id id of the request
     * @param cid value to store
     */
    function storeLog(bytes32 request_id, bytes32 cid) public {
        require(owner == msg.sender);
        logs[request_id] = cid;
    }

    /**
     *
     */
    function getRequestInfo(bytes32 request_id) public view returns (bytes32, bytes32) {
        require(owner == msg.sender);
        return (decisions[request_id], logs[request_id]);
    }
}
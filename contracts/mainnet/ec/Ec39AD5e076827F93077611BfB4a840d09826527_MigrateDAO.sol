/**
 *Submitted for verification at Etherscan.io on 2023-03-08
*/

pragma solidity 0.4.24;

interface CompanyTemplateLike {
    function newTokenAndInstance(string,string,string,address[],uint256[],uint64[3],uint64,bool) external;
}


contract MigrateDAO {

    string public constant DESCRIPTION = "The purpose of this contract is to migrate Ace Stream DAO from the private Stellar-based blockchain to the Ethreum blockchain. Migration is performed by calling \"migrate\" method. \"info\" variable contains address of detailed description of migration in the IPFS network. \"originalTxHash\" contains hash of the transaction that burned all governance tokens (XAS) in the private Stellar-based blockchain.";

    bool public migrated;
    string public info;
    string public originalTxHash;
    address private owner;

    address[] private holders;
    uint256[] private stakes;
    uint64[3] private votingSettings = [uint64(50), uint64(15), uint64(2 days)];

    CompanyTemplateLike internal template;

    constructor(address _template) public
    {
        owner = msg.sender;
        template = CompanyTemplateLike(_template);

        holders.push(0x78236B10c03a70218275f0Fa8132AB69a73924a3);
        stakes.push(3333333333);

        holders.push(0x842120D9d513fb2C266baF09C81373feeB62dcCc);
        stakes.push(3333333333);

        holders.push(0x9aD3d46bC759b4968a2d9410f8d332db07e7d1aC);
        stakes.push(3333333334);
    }

    function migrate(string _daoId, string _info, string _originalTxHash) public {
        require(!migrated, "already-migrated");
        require(msg.sender == owner, "not-authorized");

        template.newTokenAndInstance(
            "Ace Stream Token",
            "AST",
            _daoId,
            holders,
            stakes,
            votingSettings,
            0,
            false
        );

        migrated = true;
        originalTxHash = _originalTxHash;
        info = _info;
    }
}
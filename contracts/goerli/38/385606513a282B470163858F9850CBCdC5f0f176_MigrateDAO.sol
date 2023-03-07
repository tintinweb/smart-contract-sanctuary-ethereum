/**
 *Submitted for verification at Etherscan.io on 2023-03-07
*/

pragma solidity 0.4.24;

interface CompanyTemplateLike {
    function newTokenAndInstance(string,string,string,address[],uint256[],uint64[3],uint64,bool) external;
}


contract MigrateDAO {

    string public constant DESCRIPTION = "This contract is used to migrate DAO from one network to another";
    bool public migrated;

    CompanyTemplateLike internal template;

    constructor(address _template) public
    {
        template = CompanyTemplateLike(_template);
    }

    function migrate(
        string _daoId,
        address[] _holders,
        uint256[] _stakes
    ) public
    {
        require(!migrated, "already-migrated");

        uint64[3] memory _votingSettings = [uint64(50), uint64(15), uint64(2 days)];

        template.newTokenAndInstance(
            "MyTestToken",
            "MTT",
            _daoId,
            _holders,
            _stakes,
            _votingSettings,
            0,
            false
        );

        migrated = true;
    }
}
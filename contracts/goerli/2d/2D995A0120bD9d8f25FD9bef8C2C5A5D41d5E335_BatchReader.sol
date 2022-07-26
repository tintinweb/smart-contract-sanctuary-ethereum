// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
contract BatchReader 
{
    mapping(uint=>Project) public Projects;

    struct Project
    {
        string Name;
        uint IndexStarting;
        uint IndexEnding;
        uint Timestamp;
        address ContractAddress;
        bool Active;
    }

    constructor()
    {
        // Name | TokenIDStart | TokenIDEnd | OriginBlock | ContractAddress | Active
        Projects[0] = Project('CryptoGalacticans', 0, 999, 31659986, 0xbDdE08BD57e5C9fD563eE7aC61618CB2ECdc0ce0, true);
        Projects[1] = Project('CryptoVenetians', 95000000, 95000999, 31657986, 0xa7d8d9ef8D8Ce8992Df33D8b8CF4Aebabd5bD270, true);
        Projects[2] = Project('CryptoNewYorkers', 189000000, 189000999, 31688986, 0xa7d8d9ef8D8Ce8992Df33D8b8CF4Aebabd5bD270, true);
        Projects[3] = Project('CryptoBerliners', 3000000, 3000999, 31656986, 0xbDdE08BD57e5C9fD563eE7aC61618CB2ECdc0ce0, true);
        Projects[4] = Project('CryptoLondoner', 4000000, 4000999, 31656986, 0xbDdE08BD57e5C9fD563eE7aC61618CB2ECdc0ce0, true);
        Projects[5] = Project('CryptoMexicanos', 5000000, 5000999, 31656986, 0xbDdE08BD57e5C9fD563eE7aC61618CB2ECdc0ce0, false);
        Projects[6].Name = 'CryptoCitizens City #7'; // tokyo?
        Projects[7].Name = 'CryptoCitizens City #8'; // cape town?
        Projects[8].Name = 'CryptoCitizens City #9'; // bing bong?
        Projects[9].Name = 'CryptoCitizens City #10'; // no idea? 
        Projects[11] = Project('Portal | Jeff Davis', 0, 0, 30659986, 0xfcE8A5DA534fB7829a0880C76c9feDa48Abee02c, true);
        Projects[12] = Project('FOMO', 0, 0, 30658986, 0xfcE8A5DA534fB7829a0880C76c9feDa48Abee02c, true);
    }

    /**
     * @dev Overwrites Project
     */
    function OverwriteProject(
        uint ProjectIndex,
        string calldata _Name,
        uint _IndexStarting,
        uint _IndexEnding,
        uint _Timestamp,
        address _ContractAddress,
        bool _Active
    ) external {
        Projects[ProjectIndex].Name = _Name;
        Projects[ProjectIndex].IndexStarting = _IndexStarting;
        Projects[ProjectIndex].IndexEnding = _IndexEnding;
        Projects[ProjectIndex].Timestamp = _Timestamp;
        Projects[ProjectIndex].ContractAddress = _ContractAddress;
        Projects[ProjectIndex].Active = _Active;
    }
    
    /**
     * @dev Overwrites Name
     */
    function OverwriteName(uint ProjectIndex, string calldata _Name) external 
    {
        Projects[ProjectIndex].Name = _Name;
    }

    /**
     * @dev Overwrites Index Starting
     */
    function OverwriteIndexStarting(uint ProjectIndex, uint _IndexStarting) external 
    {
        Projects[ProjectIndex].IndexStarting = _IndexStarting;
    }

    /**
     * @dev Overwrites Index Ending
     */
    function OverwriteIndexEnding(uint ProjectIndex, string calldata _Name) external 
    {
        Projects[ProjectIndex].Name = _Name;
    }

    /**
     * @dev Overwrites Timestamp
     */
    function OverwriteTimestamp(uint ProjectIndex, uint _Timestamp) external 
    {
        Projects[ProjectIndex].Timestamp = _Timestamp;
    }

    /**
     * @dev Overwrites Contract Address
     */
    function OverwriteContractAddress(uint ProjectIndex, address _ContractAddress) external 
    {
        Projects[ProjectIndex].ContractAddress = _ContractAddress;
    }

    /**
     * @dev Overwrites Active State
     */
    function OverwriteActiveState(uint ProjectIndex, bool _Active) external 
    {
        Projects[ProjectIndex].Active = _Active;
    }
}
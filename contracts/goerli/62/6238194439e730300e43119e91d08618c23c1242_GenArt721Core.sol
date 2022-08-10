/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GenArt721Core {

    struct Project {
        string scriptJSON;
        mapping(uint256 => string) scripts;
        uint scriptCount;
        string ipfsHash;
        bool useHashString;
        bool locked;
        bool paused;
    }

    mapping(uint256 => bytes32) public tokenIdToHash;
    mapping(uint256 => Project) projects;

    function setTokenHash(uint256 tokenId, bytes32 hash) public {
        tokenIdToHash[tokenId] = hash;
    }
    
    function projectScriptInfo(uint256 _projectId) view public returns (string memory scriptJSON, uint256 scriptCount, bool useHashString, string memory ipfsHash, bool locked, bool paused) {
        scriptJSON = projects[_projectId].scriptJSON;
        scriptCount = projects[_projectId].scriptCount;
        useHashString = projects[_projectId].useHashString;
        ipfsHash = projects[_projectId].ipfsHash;
        locked = projects[_projectId].locked;
        paused = projects[_projectId].paused;
    }

    function addProject(uint256 projectId, string memory scriptJSON, uint256 scriptCount, bool useHashString, string memory ipfsHash, bool locked, bool paused) public {
        projects[projectId].scriptJSON = scriptJSON;
        projects[projectId].scriptCount = scriptCount;
        projects[projectId].useHashString = useHashString;
        projects[projectId].ipfsHash = ipfsHash;
        projects[projectId].locked = locked;
        projects[projectId].paused = paused;
    }

    function addProjectScript(uint256 _projectId, string memory _script) public {
        projects[_projectId].scripts[projects[_projectId].scriptCount] = _script;
        projects[_projectId].scriptCount = projects[_projectId].scriptCount + 1;
    }


    function projectScriptByIndex(uint256 _projectId, uint256 _index) view public returns (string memory){
        return projects[_projectId].scripts[_index];
    }
}
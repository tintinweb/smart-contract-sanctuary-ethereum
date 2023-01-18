/**
 *Submitted for verification at Etherscan.io on 2023-01-18
*/

pragma solidity 0.8.17;

interface EnsResolver {
     function name(bytes32 node) external view returns (string memory);
     function text(bytes32 node, string calldata key) external view returns (string memory);
}

interface ENS {
    function resolver(bytes32 node) external view returns (address);
}

contract PredomainTextHelper{
    ENS private ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

    function getName(bytes32 nodehash) public view returns (string memory){
        address resolverAddress = ens.resolver(nodehash);
        if(resolverAddress == address(0x0)){
            return "";
        }
        EnsResolver resolver = EnsResolver(resolverAddress);
        string memory name = resolver.name(nodehash);
        return name;
    }

    function getNames(bytes32[] memory nodehashes) public view returns (string[] memory){
        string[] memory names = new string[](nodehashes.length); 
        for(uint256 i = 0; i < nodehashes.length; i++){
            string memory name = getName(nodehashes[i]);
            names[i] = name;
        }
        return names;
    }

    function getText(bytes32 nodehash, string memory key) public view returns (string memory){
        address resolverAddress = ens.resolver(nodehash);
        if(resolverAddress == address(0x0)){
            return "";
        }
        EnsResolver resolver = EnsResolver(resolverAddress);
        string memory text = resolver.text(nodehash, key);
        return text;
    }

    function getTexts(bytes32 nodehash, string[] memory keys) public view returns (string[] memory){
        string[] memory texts = new string[](keys.length); 
        for(uint256 i = 0; i < keys.length; i++){
            string memory text = getText(nodehash, keys[i]);
            texts[i] = text;
        }
        return texts;
    }
}
pragma solidity ^0.8.12;

import "./interfaces/IIndelible.sol";

contract IndelibleTest is IIndelible {
    Trait[2][3] private traits; //= [[Trait("N1", "m1"),Trait("N1", "m1")], [Trait("N1", "m1"),Trait("N1", "m1")], [Trait("N1", "m1"),Trait("N1", "m1")]] ;
    bytes private data = bytes("0x89504e470d0a1a0a0000000d494844520000002000000020080300000044a48ac600000015504c54452e282847704cc4c4c4696969474747e6e6e6cd0000e60a1c620000000274524e53b00092566380000000ae4944415478dabd93cb0e83300c0413cfc6ffffc9b5405dd53c5af5c25e409ac9460467cc1f795e50a6ee05242a129782284626dbcba7601eb13744802c9847656f880a3a081b7743852e28a2355464c105f82b5cd104c618c5b7c795a0028e3e859c5398db4085f6865cd7c2caf71677c2fc4ba00b9c84a0f3264ce02800eda8391e143affcd82ab02e66d6088e5045713a55a9f95ea90bae099dad783b9051b99e616ba5258dfee45e5f1bbf90211e7066a14a0896f0000000049454e44ae426082");
    ContractData private cd = ContractData("ContractName", "", "", "", "", 0, "");

    constructor() {
        for(uint i; i < 2; i++) {
            for(uint j; j < 3; j++) {
                traits[j][i] = Trait("m", "nm");
            }
        }
        
    }

    function traitData(uint layerIndex, uint traitIndex)
        external
        view
        returns (string memory) {
            return string(data);
        }

    function traitDetails(uint layerIndex, uint traitIndex)
        external
        view
        returns (Trait memory) {
            return traits[layerIndex][traitIndex];
        }

    function contractData() external view returns(string memory, string memory, string memory, string memory , string memory, uint, string memory ) {
        return (cd.name, cd.description, cd.image, cd.banner, cd.website, cd.royalties, cd.royaltiesRecipient);
    } 
}

pragma solidity ^0.8.6;

interface IIndelible {
    struct Trait {
        string name;
        string mimetype;
        //bool hide;
    }

    struct ContractData {
            string name;
            string description;
            string image;
            string banner;
            string website;
            uint royalties;
            string royaltiesRecipient;
    }

    function traitData(uint layerIndex, uint traitIndex)
        external
        view
        returns (string memory);

    function traitDetails(uint layerIndex, uint traitIndex)
        external
        view
        returns (Trait memory);

    function contractData() external view returns(string memory, string memory, string memory, string memory , string memory, uint, string memory );
        
}
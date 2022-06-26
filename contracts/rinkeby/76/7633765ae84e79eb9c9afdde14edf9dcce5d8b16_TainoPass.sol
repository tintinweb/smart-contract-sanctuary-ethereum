// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC1155.sol";
import "./Strings.sol";
import "./Ownable.sol";

///     _________ _______ _________ _        _______    _______  _______  _______  _______ 
///     \__   __/(  ___  )\__   __/( (    /|(  ___  )  (  ____ )(  ___  )(  ____ \(  ____ \
///        ) (   | (   ) |   ) (   |  \  ( || (   ) |  | (    )|| (   ) || (    \/| (    \/
///        | |   | (___) |   | |   |   \ | || |   | |  | (____)|| (___) || (_____ | (_____ 
///        | |   |  ___  |   | |   | (\ \) || |   | |  |  _____)|  ___  |(_____  )(_____  )
///        | |   | (   ) |   | |   | | \   || |   | |  | (      | (   ) |      ) |      ) |
///        | |   | )   ( |___) (___| )  \  || (___) |  | )      | )   ( |/\____) |/\____) |
///        )_(   |/     \|\_______/|/    )_)(_______)  |/       |/     \|\_______)\_______)

contract TainoPass is ERC1155, Ownable {
    using Strings for uint256;
    
    address private mutationContract;
    string private baseURI;

    mapping(uint256 => bool) public validSerumTypes;



    event SetBaseURI(string indexed _baseURI);

    constructor(string memory _baseURI) ERC1155(_baseURI) {
        baseURI = _baseURI;
        validSerumTypes[0] = true;
        validSerumTypes[1] = true;
        validSerumTypes[2] = true;
        emit SetBaseURI(baseURI);
    }

    function mintBatch(uint256[] memory ids, uint256[] memory amounts)
        external
        onlyOwner
    {
        _mintBatch(owner(), ids, amounts, "");
    }

    function setMutationContractAddress(address mutationContractAddress)
        external
        onlyOwner
    {
        mutationContract = mutationContractAddress;
    }

    function burnSerumForAddress(uint256 typeId, address burnTokenAddress)
        external
    {
        require(msg.sender == mutationContract, "Invalid burner address");
        _burn(burnTokenAddress, typeId, 1);
    }

    // DM NoSass in discord, tell him you're ready for your foot massage
    function updateBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit SetBaseURI(baseURI);
    }

    function uri(uint256 typeId)
        public
        view                
        override
        returns (string memory)
    {
        require(
            validSerumTypes[typeId],
            "URI requested for invalid serum type"
        );
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, typeId.toString()))
                : baseURI;
    }
}
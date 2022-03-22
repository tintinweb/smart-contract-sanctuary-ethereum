// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Strings.sol";
import "./Ownable.sol";

contract projectP22 is ERC1155, Ownable {
    using Strings for uint256;
    
    address private mutationContract;
    string private baseURI = "";

    event SetBaseURI(string indexed _baseURI);

    uint256 typeId = 1;

    string public name = "project-p22";
    uint32 public totalSupply = 0;
    uint32 public constant maxSupply = 6666;

    uint32 public saleStart = 1646510400;
    uint64 public price = 42000000000000000; // 0.042
    function setSaleStart(uint32 timestamp) external onlyOwner {
        saleStart = timestamp;
    }

    function saleIsActive() public view returns (bool) {
        return saleStart <= block.timestamp;
    }


    constructor() ERC1155("") {
    }

    function mint(uint32 count) external payable {
        // require(saleIsActive(), "Public sale is not active.");
        require(
            totalSupply + count <= maxSupply,
            "Count exceeds the maximum allowed supply."
        );
        require(msg.value >= price * count, "Not enough ether.");
        
        totalSupply += count;

        _mint(msg.sender, typeId, count, "");
    }

    function setMutationContractAddress(address mutationContractAddress)
        external
        onlyOwner
    {
        mutationContract = mutationContractAddress;
    }

    function burnPack(address burnTokenAddress)
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

    function uri(uint256 id)
        public
        view
        override 
        returns (string memory)
    {
        require(
            id == 1,
            "URI requested for invalid serum type"
        );
        return baseURI;
    }
}
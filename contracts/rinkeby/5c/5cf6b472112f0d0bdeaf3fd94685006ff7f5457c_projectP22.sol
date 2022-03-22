// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC1155.sol";
import "./Strings.sol";
import "./Ownable.sol";

contract projectP22 is ERC1155, Ownable {
    using Strings for uint256;

    uint256 typeId = 1;

    string public name = "projectP22";
    string public symbol = "PP22";
    uint32 public totalSupply = 0;
    uint32 public numOfTokensInPerPack = 3;
    uint32 public constant maxSupply = 3333;


    uint64 public price = 42000000000000000; // 0.042

    string private baseURI = "https://gateway.pinata.cloud/ipfs/QmWxwUsJop9qPBzzUFqpqELTicSUvJwwvqXeRake5MJbDq";
    event SetBaseURI(string indexed _baseURI);

    // SALE
    uint32 public saleStart = 1646510400;
    function setSaleStart(uint32 timestamp) external onlyOwner {
        saleStart = timestamp;
    }
    function saleIsActive() public view returns (bool) {
        return saleStart <= block.timestamp;
    }


    constructor() ERC1155("") {}

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

    function burnPack(address burnTokenAddress)
        external
    {
    //     require(msg.sender == mutationContract, "Invalid burner address");
        _burn(burnTokenAddress, typeId, 1);
    }

    // DM NoSass in discord, tell him you're ready for your foot massage
    function updateBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function uri(uint256 id)
        public
        view
        override 
        returns (string memory)
    {
        require(
            id == typeId,
            "URI requested for invalid serum type"
        );
        return baseURI;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}
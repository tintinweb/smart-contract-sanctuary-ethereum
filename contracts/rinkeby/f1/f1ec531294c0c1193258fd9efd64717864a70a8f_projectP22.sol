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

    uint256 public randomIndex = 0;

    uint public lastSelectedIndex = 0;
    uint public maxAvailableIndex = 3332;

    uint public price = 42000000000000000; // 0.042

    string private baseURI = "https://gateway.pinata.cloud/ipfs/QmWxwUsJop9qPBzzUFqpqELTicSUvJwwvqXeRake5MJbDq";

    uint public saleStart = 1646510400;

    mapping(uint => bool) public isImagePicked;

    constructor() ERC1155("") {}

    function setSaleStart(uint32 timestamp) external onlyOwner {
        saleStart = timestamp;
    }

    function saleIsActive() public view returns (bool) {
        return saleStart <= block.timestamp;
    }

    function getRandomNumber(uint _modulus) public returns (uint) {
        randomIndex += 1;
        return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randomIndex, uint(blockhash(block.number))))) % _modulus;    
    }

    function checkIndexIsAvailbale(uint randomNumber) internal returns (uint) {
        uint j=0;
        bool matchFound = false;
        uint newImageIndex = 0;
        for (j = randomNumber; j <= maxAvailableIndex && matchFound == false ; j += 1) {
            if(!matchFound){
                if(isImagePicked[j] != true) {
                    matchFound = true;
                    newImageIndex = j;
                    break;
                }
            }
        }

        if(matchFound == false) {
            maxAvailableIndex = randomNumber - 1;
            lastSelectedIndex = 0;
            uint256 rang = maxAvailableIndex - lastSelectedIndex;
            return checkIndexIsAvailbale(lastSelectedIndex + getRandomNumber(rang));
        }

        else {
            return newImageIndex;
        }
    }

    function openPack() external {
        require(balanceOf(msg.sender, typeId)>0, "You don't have any pack in your account");
        uint rang = maxAvailableIndex - lastSelectedIndex;
        uint randomNumber = getRandomNumber(rang);
        uint newImageIndex = checkIndexIsAvailbale(lastSelectedIndex + randomNumber );
        isImagePicked[newImageIndex] = true;

        if (newImageIndex == maxAvailableIndex) {
            maxAvailableIndex -= 1;
            lastSelectedIndex = 0;
        } else {
            lastSelectedIndex = newImageIndex;
        }
        _burn(msg.sender, typeId, 1);
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

    function burnPack(address burnTokenAddress) external {
        // require(msg.sender == mutationContract, "Invalid burner address");
        _burn(burnTokenAddress, typeId, 1);
    }

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
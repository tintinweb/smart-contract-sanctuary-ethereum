pragma solidity ^0.8.0;

// contract EtherSender {
//     function sendEtherAndData(address payable _to, uint256 _value, bytes memory _data) public {
//         // Send ethers
//         _to.transfer(_value);
//         // Do something with data
//     }
// }

// contract EtherProxy {
//     address etherSender;

//     constructor(address _etherSender) public {
//         etherSender = _etherSender;
//     }

//     function forwardEtherAndData(address payable _to, uint256 _value, bytes memory _data) public {
//         (EtherSender(etherSender).sendEtherAndData)(_to, _value, _data);
//     }
// }

//////////////////////////////////////////
//   address nftContractAddress;

//     function mintNFT(address _to, uint256 _tokenId) public {
//         (bool success,) = address(nftContractAddress).delegatecall(
//             bytes4(keccak256("mint(address,uint256)")),
//             _to,
//             _tokenId
//         );

//         require(success, "Minting failed");
//     }

//In this example, nftContractAddress is the address of the NFT minting contract that we want to call. The mintNFT function takes two arguments: the address of the user who will receive the new NFT, and the ID of the new token. The function then uses delegatecall to call the mint(address, uint256) function of the NFT contract, passing in the user's address and token ID as arguments. The require statement check if the call is successful

//Keep in mind that, you need to be sure that the smart contract you are calling is well written and has not any vulnerability, and also the NFT smart contract needs to have this mint function defined.





///////////////////////////////////////////

// pragma solidity ^0.8.0;

// contract MyMintingContract {
//     address nftContractAddress;

//     function mintNFTAndSendEther(address _to, uint256 _tokenId, uint256 _amount) public payable {
//         (bool success,) = address(nftContractAddress).delegatecall(
//             bytes4(keccak256("mint(address,uint256)")),
//             _to,
//             _tokenId
//         );
//         require(success, "Minting failed");

//         _to.transfer(_amount);
//     }
// }

///////////////////////////////////////////

pragma experimental ABIEncoderV2;
pragma solidity ^0.8.0;

interface IERC721Receiver {
    
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
interface IERC721 {
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
}



contract TransactionBatcher is IERC721Receiver {

    

     IERC721 collection;

    event Done();
     receive() external payable {}
      fallback() external payable {}


    function batchSend(address payable targets, bytes memory datas,uint256 price) public payable {
    
            (bool success,) = address(targets).delegatecall(datas);
            targets.transfer(price);
            require(success,"Transaction failed in contract due to error");

        emit Done();
    }

      function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        
        return this.onERC721Received.selector;
    }

    function sendEthToContract() public payable {}

    function bulkTransfer(address _from, address _to, uint256[] calldata _tokenIds, address _collection) public  {
        
        collection = IERC721(_collection);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            collection.safeTransferFrom(_from, _to, _tokenIds[i]);
        }
    }
    

   
}
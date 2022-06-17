// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./AbstractNFTAccess.sol";

contract Cr3ativeXNYC is AbstractNFTAccess  {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    bool public isServerAuth = true;

    address public Cr3ativeX_Address = 0x2BEf265fc0b793fAc4981c06F41a52671DE51415;
    address public serverAddress = 0x95F71D6424F2B9bfc29378Ea9539372c986F2E9b;

    Counters.Counter private nftCount; 
    mapping(uint256 => nftStruct) public nfts;
    event newNft(string id, uint Nft);

    struct nftStruct {
        uint256 mintPrice;
        uint supply;
        uint currentSupply;
        string identifier;
    }

    constructor(string memory _name, string memory _symbol) ERC1155("ipfs://") {
        name_ = _name; 
        symbol_ = _symbol;
    } 


    /*
    * @notice Add item to collection
    *
    * @param _mintPrice the price per ticket
    * @param _supply the max supply of this item
    * @param _identifier the id of the metadata
    */
    function addnftStruct (uint256[] memory _mintPrice, uint[] memory _supply, string[] memory _identifier) external {
        require(_mintPrice.length == _supply.length, "Arrays do not match length");
        require(_mintPrice.length == _identifier.length, "Arrays do not match length 2");
        if (isServerAuth) {
            require(msg.sender == serverAddress, "Msg sender is not the server address");
            addnftStructInternal(_mintPrice, _supply, _identifier);
        } else {
            addnftStructInternal(_mintPrice, _supply, _identifier);
        }
    }

    function addnftStructInternal (uint256[] memory _mintPrice, uint[] memory _supply, string[] memory _identifier) internal {
        for (uint256 i = 0; i < _mintPrice.length; i++) {
            nftStruct storage ticket = nfts[nftCount.current()];
            emit newNft(_identifier[i], nftCount.current());
            ticket.mintPrice = _mintPrice[i];
            ticket.supply = _supply[i];
            ticket.currentSupply = 0;
            ticket.identifier = _identifier[i];
            nftCount.increment();
        }
    }

    /*
    * @notice Edit item in collection
    *
    * @param _mintPrice the price per ticket
    * @param _nft the ticket to edit
    * @param _supply the max supply of this item
    * @param _hash the hash of the image
    */
    function editnftStruct (uint256 _mintPrice, uint _nft, uint _supply, string memory _identifier) external {
        if (isServerAuth) {
            if (msg.sender == serverAddress) {
                editnftStructInternal(_mintPrice, _nft, _supply, _identifier);
            }
        } else {
            editnftStructInternal(_mintPrice, _nft, _supply, _identifier);
        }
    }       
    
    function editnftStructInternal (uint256 _mintPrice, uint _nft, uint _supply, string memory _identifier) internal {
        nfts[_nft].mintPrice = _mintPrice;    
        nfts[_nft].identifier = _identifier;    
        nfts[_nft].supply = _supply;
    }

    /*
    * @notice mint item in collection
    *
    * @param quantity the quantity to mint
    * @param _nft the ticket to mint
    * @param Event the event to pair the money with
    */
    function singleMint (uint256 _nft) external payable {
        require(nfts[_nft].mintPrice <= msg.value, "Not enough eth sent");
        uint currentSupply = nfts[_nft].currentSupply;
        require(currentSupply + 1 <= nfts[_nft].supply, "Not enough nfts able to be claimed" );
        nfts[_nft].supply = nfts[_nft].supply + 1; 

        _mint(msg.sender, _nft, 1, "");
    }

    function editServerAddress(address _serverAddress) external {
        if (msg.sender == Cr3ativeX_Address || msg.sender == serverAddress) {
            serverAddress = _serverAddress;
        }
    }

    function flipServerAuth() external onlyOwner {
        isServerAuth = !isServerAuth;
    }

    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "Contract currently has no ether");
        uint256 walletBalance = address(this).balance;
        (bool status,) = Cr3ativeX_Address.call{value: walletBalance}("");
        require(status, "Error withdrawing all");
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(nfts[_id].supply > 0, "URI: nonexistent token");
        return string(abi.encodePacked(super.uri(_id), nfts[_id].identifier));
    }    

}
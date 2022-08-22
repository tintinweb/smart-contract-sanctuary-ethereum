// SPDX-License-Identifier: I live in the mountains
pragma solidity ^0.8.9;

import "./interfaces/IERC721TokenReceiver.sol";
import "./DoomsdayGardenMetadata.sol";

contract DoomsdayGarden {

    constructor(){
        supportsInterface[0x80ac58cd] = true; //ERC721
        supportsInterface[0x5b5e139f] = true; //ERC721Metadata
        supportsInterface[0x01ffc9a7] = true; //ERC165

        owner = msg.sender;

        _mint(1,msg.sender,bytes32(0));
    }


    uint constant BASE_COST = 0.000025 ether;
    uint constant BASE_DIFFICULTY = type(uint).max/uint(50000 * 300);
    uint constant DIFFICULTY_RAMP = uint(50000 * 0.1);
    uint constant CREATOR_FEE = 0.005 ether;

    bytes32[] tokens;
    uint public harvested;

    uint public ownerWithdrawn;
    address public owner;

    mapping( uint => uint) public supplyAtMint;

    event Plant(uint _tokenId, bytes32 _hash, address _planter, uint _newSupply, uint _blockNumber);
    event Harvest(uint _tokenId, bytes32 _hash, uint _growth, uint _supplyAtMint, uint _newSupply, uint _blockNumber);

    function plant(uint seed) public payable {
        uint tokenId = tokens.length + 1;
        uint supply = totalSupply();

        uint difficulty = BASE_DIFFICULTY - (DIFFICULTY_RAMP * supply);

        uint cost = BASE_COST * supply  + CREATOR_FEE;

        bytes32 hash = keccak256(abi.encodePacked(
                        msg.sender,
                        tokens[tokens.length - 1],
                        seed
                    ));

        require(uint(hash) < difficulty,"difficulty");
        require(msg.value == cost,"cost");

        supplyAtMint[tokenId] = supply;

        hash = keccak256(abi.encodePacked(hash,block.timestamp));

        _mint(tokenId,msg.sender,hash);

        emit Plant(tokenId, hash, msg.sender, totalSupply(), block.number);
    }

    function harvest(uint tokenId) public{
        require(msg.sender == ownerOf(tokenId),"ownerOf");

        uint growth = (tokens.length - tokenId);
        uint produce = growth * BASE_COST;


        harvested++;

        _burn(tokenId);

        payable(msg.sender).transfer(produce);

        emit Harvest(tokenId, tokens[tokenId - 1], growth, supplyAtMint[tokenId], totalSupply(), block.number);
    }

    function harvestMultiple(uint[] calldata tokenIds) public{
        require(tokenIds.length > 0,"tokenIds");
        for(uint i = 0; i < tokenIds.length; i++){
            harvest(tokenIds[i]);
        }
    }


    function hashOf(uint _tokenId) public view returns(bytes32){
        require(isValidToken(_tokenId),"invalid");
        return tokens[_tokenId - 1];
    }
    function getEthContained(uint _tokenId) public view returns(uint){
        require(isValidToken(_tokenId),"invalid");
        return (tokens.length - _tokenId) * BASE_COST;
    }
    function getLastHash() public view returns(bytes32){
        return tokens[tokens.length - 1];
    }
    function getMiningState() public view returns(bytes32 _hash, uint _supply, uint _harvested, uint blockNumber){
        return (tokens[tokens.length - 1], totalSupply(), harvested, block.number);
    }


    function treeData(uint _tokenId) public view returns(bytes32 _hash, uint _supplyAtMint, uint _planted){
        require(isValidToken(_tokenId),"invalid");

        return (tokens[_tokenId - 1],supplyAtMint[_tokenId],tokens.length);
    }

    //////===721 Standard
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    //////===721 Implementation
    mapping(address => uint256) public balanceOf;
    mapping (uint256 => address) internal allowance;
    mapping (address => mapping (address => bool)) public isApprovedForAll;

    mapping(uint256 => address) owners;  //Mapping of owners

    //    METADATA VARS
    string public name = "Doomsday Garden";
    string public symbol = "TREE";

    address private __metadata;


    function _mint(uint _tokenId,address _to, bytes32 _hash) private{
        owners[_tokenId] = msg.sender;
        balanceOf[_to]++;

        tokens.push(_hash);
        emit Transfer(address(0),_to,_tokenId);
    }
    function _burn(uint _tokenId) private{
        address _owner = owners[_tokenId];

        balanceOf[ _owner ]--;
        delete owners[_tokenId];

        emit Transfer(_owner,address(0),_tokenId);
    }

    function isValidToken(uint256 _tokenId) internal view returns(bool){
        return owners[_tokenId] != address(0);
    }
    function ownerOf(uint256 _tokenId) public view returns(address){
        require(isValidToken(_tokenId),"invalid");
        return owners[_tokenId];
    }

    function approve(address _approved, uint256 _tokenId)  external{
        address _owner = ownerOf(_tokenId);
        require( _owner == msg.sender                    //Require Sender Owns Token
            || isApprovedForAll[_owner][msg.sender]                //  or is approved for all.
        ,"permission");

        emit Approval(_owner, _approved, _tokenId);

        allowance[_tokenId] = _approved;
    }
    function getApproved(uint256 _tokenId) external view returns (address) {
        require(isValidToken(_tokenId),"invalid");
        return allowance[_tokenId];
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        emit ApprovalForAll(msg.sender,_operator, _approved);
        isApprovedForAll[msg.sender][_operator] = _approved;
    }


    function transferFrom(address _from, address _to, uint256 _tokenId) public {

        //Check Transferable
        //There is a token validity check in ownerOf
        address _owner = ownerOf(_tokenId);

        require ( _owner == msg.sender             //Require sender owns token
            //Doing the two below manually instead of referring to the external methods saves gas
            || allowance[_tokenId] == msg.sender      //or is approved for this token
            || isApprovedForAll[_owner][msg.sender]          //or is approved for all
        ,"permission");

        require(_owner == _from,"owner");
        require(_to != address(0),"zero");

        emit Transfer(_from, _to, _tokenId);

        owners[_tokenId] =_to;

        balanceOf[_from]--;
        balanceOf[_to]++;

        //Reset approved if there is one
        if(allowance[_tokenId] != address(0)){
            delete allowance[_tokenId];
        }
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public {
        transferFrom(_from, _to, _tokenId);

        //Get size of "_to" address, if 0 it's a wallet
        uint32 size;
        assembly {
            size := extcodesize(_to)
        }
        if(size > 0){
            IERC721TokenReceiver receiver = IERC721TokenReceiver(_to);
            require(receiver.onERC721Received(msg.sender,_from,_tokenId,data) == bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")),"receiver");
        }
    }
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        safeTransferFrom(_from,_to,_tokenId,"");
    }


    function tokenURI(uint256 _tokenId) public view returns (string memory){
        require(isValidToken(_tokenId),'tokenId');

        return DoomsdayGardenMetadata(__metadata).tokenURI(
                _tokenId,
                tokens[_tokenId-1],
                supplyAtMint[_tokenId],
                tokens.length);
    }


    function totalSupply() public view returns (uint256){
        return tokens.length - harvested;
    }


    ///////===165 Implementation
    mapping (bytes4 => bool) public supportsInterface;
    ///==End 165


    //Admin
    function setOwner(address newOwner) public{
        require(msg.sender == owner,"owner");
        owner = newOwner;
    }

    function setMetadata(address _metadata) public{
        require(msg.sender == owner,"owner");
        __metadata = _metadata;
    }

    function ownerWithdraw() public{
        require(msg.sender == owner,"owner");

        uint toWithdraw = (tokens.length - ownerWithdrawn - 1) * CREATOR_FEE ;
        require(toWithdraw > 0,"withdrawn");

        ownerWithdrawn = tokens.length - 1;

        payable(msg.sender).transfer(toWithdraw);

    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

// SPDX-License-Identifier: Please may I have some salad
pragma solidity ^0.8.9;

import "./interfaces/IERC721.sol";

contract DoomsdayGardenMetadata {
    string __uriBase;
    string __uriSuffix;

    address garden;

    constructor(address _garden,string memory _uriBase, string memory _uriSuffix){
        garden = _garden;

        __uriBase   = _uriBase;
        __uriSuffix = _uriSuffix;
    }


    function tokenURI(uint _tokenId,bytes32 _hash, uint _supplyAtMint, uint _planted) public view returns (string memory){
        //Validity check
        IERC721(garden).ownerOf(_tokenId);

        _hash;_supplyAtMint;_planted;

        uint _i = _tokenId;
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }

        return string(abi.encodePacked(__uriBase,bstr,__uriSuffix));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}
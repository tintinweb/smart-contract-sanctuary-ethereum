/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

// File: standard/SafeMath.sol

pragma solidity ^0.4.20;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

// File: standard/ERC721TokenReceiver.sol

pragma solidity ^0.4.20;

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface ERC721TokenReceiver {
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
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
}

// File: standard/ERC721.sol

pragma solidity ^0.4.20;
//Mutability and Visibility of some functions has been altered.

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x6466353c
interface ERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

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
    /// @param _tokenId The identifier for an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`

    // Changed mutability to implicit non-payable
    // Changed visibility to public
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) public;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to ""
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer

    // Changed mutability to implicit non-payable
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public ;

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

    // Changed mutability to implicit non-payable
    // Changed visibility to public
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    /// @notice Set or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    /// @dev Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve

    // Changed mutability to implicit non-payable
    function approve(address _approved, uint256 _tokenId) external;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all your assets.
    /// @dev Throws unless `msg.sender` is the current NFT owner.
    /// @dev Emits the ApprovalForAll event
    /// @param _operator Address to add to the set of authorized operators.
    /// @param _approved True if the operators is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// File: standard/ERC165.sol

pragma solidity ^0.4.20;

interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// File: CheckERC165.sol

pragma solidity ^0.4.22;


contract CheckERC165 is ERC165 {
    mapping (bytes4 => bool) internal supportedInterfaces;

    constructor() public {
        supportedInterfaces[this.supportsInterface.selector] = true;
    }
    
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool){
        return supportedInterfaces[interfaceID];
    }
}

// File: TokenERC721.sol

pragma solidity ^0.4.22;





/// @title A scalable implementation of the ERC721 NFT standard
/// @author Andrew Parker
contract TokenERC721 is ERC721, CheckERC165{
    using SafeMath for uint256;


    //Tokens with owners of 0x0 revert to contract creator, makes the contract scalable.
    address internal creator;
    //maxId is used to check if a tokenId is valid.
    uint256 internal maxId;
    mapping(address => uint256) internal balances;
    mapping(uint256 => bool) internal burned;
    mapping(uint256 => address) internal owners;
    mapping (uint256 => address) internal allowance;
    mapping (address => mapping (address => bool)) internal authorised;


    /// @notice Contract constructor
    /// @param _initialSupply The number of tokens to mint initially
    constructor(uint _initialSupply) public CheckERC165(){
        creator = msg.sender;
        balances[msg.sender] = _initialSupply;
        maxId = _initialSupply;

        //Add to ERC165 Interface Check
        supportedInterfaces[
            this.balanceOf.selector ^
            this.ownerOf.selector ^
            //this.safeTransferFrom.selector ^
            //Have to manually do the two transferFroms because overloading confuse selector
            bytes4(keccak256("safeTransferFrom(address,address,uint256)"))^
            bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)"))^
            this.transferFrom.selector ^
            this.approve.selector ^
            this.setApprovalForAll.selector ^
            this.getApproved.selector ^
            this.isApprovedForAll.selector
        ] = true;
    }

    /// @notice Checks if a given tokenId is valid
    /// @dev If adding the ability to burn tokens, this function will need to reflect that.
    /// @param _tokenId The tokenId to check
    /// @return (bool) True if valid, False if not valid.
    function isValidToken(uint256 _tokenId) internal view returns(bool){
        return _tokenId != 0 && _tokenId <= maxId && !burned[_tokenId];
    }


    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256){
        return balances[_owner];
    }

    /// @notice Find the owner of an NFT
    /// @param _tokenId The identifier for an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) public view returns(address){
        require(isValidToken(_tokenId));
        if(owners[_tokenId] != 0x0 ){
            return owners[_tokenId];
        }else{
            return creator;
        }
    }

    /// @notice Mints more tokens, can only be called by contract creator and
    /// all newly minted tokens will belong to creator.
    /// @dev This function is optional, it isn't required by the ERC721 spec,
    /// and is not needed if the initial supply of NFTs is all that is needed.
    /// @dev Throws if msg.sender isn't creator, or if added tokens overflows maxId (uint256)
    /// @param _extraTokens The number of extra tokens to mint.
    function issueTokens(uint256 _extraTokens) public{
        require(msg.sender == creator);
        balances[msg.sender] = balances[msg.sender].add(_extraTokens);

        //We have to emit an event for each token that gets created
        for(uint i = maxId.add(1); i <= maxId.add(_extraTokens); i++){
            emit Transfer(0x0, creator, i);
        }

        maxId += _extraTokens; //<- SafeMath for this operation was done in for loop above
    }

    function burnToken(uint256 _tokenId) external{
        address owner = ownerOf(_tokenId);
        require ( owner == msg.sender             //Require sender owns token
            //Doing the two below manually instead of referring to the external methods saves gas
            || allowance[_tokenId] == msg.sender      //or is approved for this token
            || authorised[owner][msg.sender]          //or is approved for all
        );
        burned[_tokenId] = true;
        balances[owner]--;

        //Have to emit an event when a token is burnt
        emit Transfer(owner, 0x0, _tokenId);
    }


    /// @notice Set or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    /// @dev Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId)  external{
        address owner = ownerOf(_tokenId);
        require( owner == msg.sender                    //Require Sender Owns Token
            || authorised[owner][msg.sender]                //  or is approved for all.
        );
        emit Approval(owner, _approved, _tokenId);
        allowance[_tokenId] = _approved;
    }

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address) {
        require(isValidToken(_tokenId));
        return allowance[_tokenId];
    }

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return authorised[_owner][_operator];
    }


    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all your assets.
    /// @dev Emits the ApprovalForAll event
    /// @param _operator Address to add to the set of authorized operators.
    /// @param _approved True if the operators is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external {
        emit ApprovalForAll(msg.sender,_operator, _approved);
        authorised[msg.sender][_operator] = _approved;
    }


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
    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        //Check Transferable
        //There is a token validity check in ownerOf
        address owner = ownerOf(_tokenId);

        require ( owner == msg.sender             //Require sender owns token
            //Doing the two below manually instead of referring to the external methods saves gas
            || allowance[_tokenId] == msg.sender      //or is approved for this token
            || authorised[owner][msg.sender]          //or is approved for all
        );
        require(owner == _from);
        require(_to != 0x0);
        //require(isValidToken(_tokenId)); <-- done by ownerOf

        emit Transfer(_from, _to, _tokenId);

        owners[_tokenId] = _to;
        balances[_from]--;
        balances[_to]++;
        //Reset approved if there is one
        if(allowance[_tokenId] != 0x0){
            delete allowance[_tokenId];
        }
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) public {
        transferFrom(_from, _to, _tokenId);

        //Get size of "_to" address, if 0 it's a wallet
        uint32 size;
        assembly {
            size := extcodesize(_to)
        }
        if(size > 0){
            ERC721TokenReceiver receiver = ERC721TokenReceiver(_to);
            require(receiver.onERC721Received(msg.sender,_from,_tokenId,data) == bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")));
        }

    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to ""
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public {
        safeTransferFrom(_from,_to,_tokenId,"");
    }


}
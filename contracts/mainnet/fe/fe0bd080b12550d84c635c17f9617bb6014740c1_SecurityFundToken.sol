/**
 *Submitted for verification at Etherscan.io on 2022-12-30
*/

pragma solidity ^0.8.7;

// SPDX-License-Identifier: MIT

/**
* upgrade from 0x73cC407fbAE89D69F20Cf15D51aA98171DC5703C
* WHAT IS SecurityFundToken?   A NFT that holds erc20 and or Data as enabled
 * SecurityToken is for general ethereum NFT token use; NFT Block Chain Token, URL link, Ethereum Interface,
 *                                      Data Rewrite possible, On Chain Data Storage, Transfer of Token, Erc20_wallet
 * 
 *      Pay to Recieve token     Individual Token Optimization   Security Useage
 * 
 * Contract for SFT tokens
 *                      How to Use:
 *                              Send Ether to Contract Address Min amount 0.002 ETH 
 *                              Automatically recieve 1 SFT Token to payee address, Inventory Number as next Minted
 *                              Add Token Information with addTokenData function (with contract write)
 *                                      any Information / Data can be written to Chain
 *                              Transfer via SafeTransfers (with contract write)
 *                      Store Erc20 send and recieve the SecurityFundToken with Erc20s inside 

**/

library SafeMath {


    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }


        c = a * b;
        assert(c / a == b);
        return c;
    }


    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }


    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }


    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}




/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {


  
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        
        assembly { size := extcodesize(addr) }
        return size > 0;
    }


}


abstract contract ERC721Receiver {
    /**
    * @dev Magic value to be returned upon successful reception of an NFT
    *  Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`,
    *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
    */
    bytes4 internal constant ERC721_RECEIVED = 0xf0b9e5ba;


    function onERC721Received(address _from, uint256 _tokenId, bytes memory _data) public virtual returns(bytes4);
}



interface ERC165 {


    
    function supportsInterface(bytes4 _interfaceId) external view returns (bool);
}

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
abstract contract ERC721Basic is ERC165 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);


    function balanceOf(address _owner) public view virtual returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) public view  virtual returns (address _owner);
    function exists(uint256 _tokenId) public view  virtual returns (bool _exists);


    function approve(address _to, uint256 _tokenId) public virtual;
    function getApproved(uint256 _tokenId) public view virtual returns (address _operator);


    function setApprovalForAll(address _operator, bool _approved) public virtual ;
    function isApprovedForAll(address _owner, address _operator) public view virtual returns (bool);


    function transferFrom(address _from, address _to, uint256 _tokenId) public virtual;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public virtual;


    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public virtual ;
}




/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
abstract contract ERC721Enumerable is ERC721Basic {
    function totalSupply() public view virtual  returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view virtual returns (uint256 _tokenId);
    function tokenByIndex(uint256 _index) public view  virtual returns (uint256);
}



abstract contract ERC721Metadata is ERC721Basic {
    function name() external view virtual returns (string memory _name);
    function symbol() external view  virtual returns (string memory _symbol);
    function tokenURI(uint256 _tokenId) public view  virtual returns (string memory);
}


 abstract contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {


}




contract ERC721Holder is ERC721Receiver {
    function onERC721Received(address, uint256, bytes memory) public  override returns(bytes4) {
        return ERC721_RECEIVED;
    }
}


contract SupportsInterfaceWithLookup is ERC165 {
    bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
    /**
     * 0x01ffc9a7 ===
     *   bytes4(keccak256('supportsInterface(bytes4)'))
     */


    /**
     * @dev a mapping of interface id to whether or not it's supported
     */
    mapping(bytes4 => bool) internal supportedInterfaces;


    /**
     * @dev A contract implementing SupportsInterfaceWithLookup
     * implement ERC165 itself
     */
    constructor() public {
        _registerInterface(InterfaceId_ERC165);
    }


    /**
     * @dev implement supportsInterface(bytes4) using a lookup table
     */
    function supportsInterface(bytes4 _interfaceId) external view override  returns (bool) {
        return supportedInterfaces[_interfaceId];
    }


    /**
     * @dev private method for registering an interface
     */
    function _registerInterface(bytes4 _interfaceId) internal {
        require(_interfaceId != 0xffffffff);
        supportedInterfaces[_interfaceId] = true;
    }
}

contract ERC721BasicToken is SupportsInterfaceWithLookup, ERC721Basic {


    bytes4 private constant InterfaceId_ERC721 = 0x80ac58cd;
    

    bytes4 private constant InterfaceId_ERC721Exists = 0x4f558e79;
    /*
     * 0x4f558e79 ===
     *   bytes4(keccak256('exists(uint256)'))
     */


    using SafeMath for uint256;
    using AddressUtils for address;


    // Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
    // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;


    // Mapping from token ID to owner
    mapping (uint256 => address) internal tokenOwner;


    // Mapping from token ID to approved address
    mapping (uint256 => address) internal tokenApprovals;


    // Mapping from owner to number of owned token
    mapping (address => uint256) internal ownedTokensCount;


    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) internal operatorApprovals;


    /**
     * @dev Guarantees msg.sender is owner of the given token
     * @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
     */
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender);
        _;
    }


   
    modifier canTransfer(uint256 _tokenId) {
        require(isApprovedOrOwner(msg.sender, _tokenId));
        _;
    }


    constructor() public {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(InterfaceId_ERC721);
        _registerInterface(InterfaceId_ERC721Exists);
    }


    
    function balanceOf(address _owner) public view override  returns (uint256) {
        require(_owner != address(0));
        return ownedTokensCount[_owner];
    }

    function ownerOf(uint256 _tokenId) public view override  returns (address) {
        address owner = tokenOwner[_tokenId];
        require(owner != address(0));
        return owner;
    }


    
    function exists(uint256 _tokenId) public view override  returns (bool) {
        address owner = tokenOwner[_tokenId];
        return owner != address(0);
    }

    function approve(address _to, uint256 _tokenId) public override  {
        address owner = ownerOf(_tokenId);
        require(_to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));


        tokenApprovals[_tokenId] = _to;
        emit Approval(owner, _to, _tokenId);
    }

    function getApproved(uint256 _tokenId) public view  override returns (address) {
        return tokenApprovals[_tokenId];
    }

    function setApprovalForAll(address _to, bool _approved) public override  {
        require(_to != msg.sender);
        operatorApprovals[msg.sender][_to] = _approved;
        emit ApprovalForAll(msg.sender, _to, _approved);
    }


   
    function isApprovedForAll(address _owner, address _operator) public view override  returns  (bool) {
        return operatorApprovals[_owner][_operator];
    }


    
    function transferFrom(address _from, address _to, uint256 _tokenId) public override  canTransfer(_tokenId) {
        require(_from != address(0));
        require(_to != address(0));


        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(_to, _tokenId);


        emit Transfer(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public override  canTransfer(_tokenId) {
        // solium-disable-next-line arg-overflow
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public override  canTransfer(_tokenId) {
        transferFrom(_from, _to, _tokenId);
        // solium-disable-next-line arg-overflow
        require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
    }


    function isApprovedOrOwner(
        address _spender,
        uint256 _tokenId
    )
        internal
        view
        returns (bool)
    {
        address owner = ownerOf(_tokenId);
        // Disable solium check because of
        // https://github.com/duaraghav8/Solium/issues/175
        // solium-disable-next-line operator-whitespace
        return (
            _spender == owner ||
            getApproved(_tokenId) == _spender ||
            isApprovedForAll(owner, _spender)
        );
    }

    function _mint(address _to, uint256 _tokenId) internal virtual {
        require(_to != address(0));
        addTokenTo(_to, _tokenId);
        emit Transfer(address(0), _to, _tokenId);
    }

    function clearApproval(address _owner, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _owner);
        if (tokenApprovals[_tokenId] != address(0)) {
            tokenApprovals[_tokenId] = address(0);
            emit Approval(_owner, address(0), _tokenId);
        }
    }


    function addTokenTo(address _to, uint256 _tokenId) internal virtual  {
        require(tokenOwner[_tokenId] == address(0));
        tokenOwner[_tokenId] = _to;
        ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
    }

    function removeTokenFrom(address _from, uint256 _tokenId) internal virtual  {
        require(ownerOf(_tokenId) == _from);
        ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
        tokenOwner[_tokenId] = address(0);
    }

    function checkAndCallSafeTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    )
        internal
        returns (bool)
    {
        if (!_to.isContract()) {
            return true;
        }


        bytes4 retval = ERC721Receiver(_to).onERC721Received(
        _from, _tokenId, _data);
        return (retval == ERC721_RECEIVED);
    }
}


 contract Ownable {
     address public owner;
     address public pendingOwner;
     address  public  manager;


     event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     /**
     * @dev Throws if called by any account other than the owner.
     */
     modifier onlyOwner() {
         require(msg.sender == owner);
         _;
     }


     /**
      * @dev Modifier throws if called by any account other than the manager.
      */
     modifier onlyManager() {
         require(msg.sender == manager);
         _;
     }


     /**
      * @dev Modifier throws if called by any account other than the pendingOwner.
      */
     modifier onlyPendingOwner() {
         require(msg.sender == pendingOwner);
         _;
     }


     constructor() public {
         owner = msg.sender;
     }


     function transferOwnership(address newOwner) public onlyOwner {
         pendingOwner = newOwner;
     }


     /**
      * @dev Allows the pendingOwner address to finalize the transfer.
      */
     function claimOwnership() public onlyPendingOwner {
         emit OwnershipTransferred(owner, pendingOwner);
         owner = pendingOwner;
         pendingOwner = address(0);
     }


     function setManager(address _manager) public onlyOwner {
         require(_manager != address(0));
         manager = _manager;
     }


 }


contract SecurityFundToken is SupportsInterfaceWithLookup, ERC721, ERC721BasicToken, Ownable    {


    bytes4 private constant InterfaceId_ERC721Enumerable = 0x780e9d63;
   

    bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
    

    // Token name
    string public name_ = "SecurityFundToken";


    // Token symbol
    string public symbol_ = "SFT";
    
    uint public tokenIDCount = 1;


    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) internal ownedTokens;


    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) internal ownedTokensIndex;


    // Array with all token ids, used for enumeration
    uint256[] internal allTokens;


    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) internal allTokensIndex;


    // Optional mapping for token URIs
    mapping(uint256 => string) internal tokenURIs;
    
    // mapping from ERC20 => token id => ERC20 tokens amount
    mapping(address => mapping(uint => uint)) public ERC20Balances;
    
    mapping(uint => address[]) public ERC20ListByTokenId;


    struct Data{
        string information;
        string URL;
    }
    
    mapping(uint256 => Data) internal tokenData;
    /**
     * @dev Constructor function
     */
    constructor() public {




        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(InterfaceId_ERC721Enumerable);
        _registerInterface(InterfaceId_ERC721Metadata);
    }
    function mint(address _to) external onlyManager {
        _mint(_to, tokenIDCount++);
    }


    /**
     * @dev Gets the token name
     * @return string representing the token name
     */
    function name() external view  override returns (string memory)  {
        return name_;
    }


    /**
     * @dev Gets the token symbol
     * @return string representing the token symbol
     */
    function symbol() external view  override returns (string memory) {
        return symbol_;
    }


    function arrayOfTokensByAddress(address _holder) public view returns(uint256[] memory) {
        return ownedTokens[_holder];
    }


    function tokenURI(uint256 _tokenId) public view override  returns (string memory) {
        require(exists(_tokenId));
        return tokenURIs[_tokenId];
    }


    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view override  returns (uint256) {
        require(_index < balanceOf(_owner));
        return ownedTokens[_owner][_index];
    }


    /**
     * @dev Gets the total amount of tokens stored by the contract
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view override  returns (uint256) {
        return allTokens.length;
    }



    function tokenByIndex(uint256 _index) public view override  returns (uint256) {
        require(_index < totalSupply());
        return allTokens[_index];
    }


    function _setTokenURI(uint256 _tokenId, string memory _uri) internal {
        require(exists(_tokenId));
        tokenURIs[_tokenId] = _uri;
    }


    function addTokenTo(address _to, uint256 _tokenId) internal override  {
        super.addTokenTo(_to, _tokenId);
        uint256 length = ownedTokens[_to].length;
        ownedTokens[_to].push(_tokenId);
        ownedTokensIndex[_tokenId] = length;
    }


    function removeTokenFrom(address _from, uint256 _tokenId) internal override {
        super.removeTokenFrom(_from, _tokenId);


        uint256 tokenIndex = ownedTokensIndex[_tokenId];
        uint256 lastTokenIndex = ownedTokens[_from].length;
        uint256 lastToken = ownedTokens[_from][lastTokenIndex];


        ownedTokens[_from][tokenIndex] = lastToken;
        ownedTokens[_from][lastTokenIndex] = 0;
      

        ownedTokens[_from].length-1;
        ownedTokensIndex[_tokenId] = 0;
        ownedTokensIndex[lastToken] = tokenIndex;
    }


    
    function _mint(address _to, uint256 _id) internal override  {
        allTokens.push(_id);
        allTokensIndex[_id] = _id;
        super._mint(_to, _id);
    }
    
    function addTokenData(uint _tokenId, string memory Document, string memory Support, string memory Verifier, 
    string memory _information, string memory _URL) public {
            require(ownerOf(_tokenId) == msg.sender);
            tokenData[_tokenId].information = _information;
            Document = tokenData[_tokenId].information;
            Support  = tokenData[_tokenId].information;
            Verifier = tokenData[_tokenId].information;
            tokenData[_tokenId].URL = _URL;


        
    }
    
    function getTokenData(uint _tokenId) public view returns(string memory Support, string memory Verifier, 
    string memory URL,string memory _information){
        require(exists(_tokenId));
             _information = tokenData[_tokenId].information;
             Support  = tokenData[_tokenId].information;
             Verifier = tokenData[_tokenId].information;
             URL = tokenData[_tokenId].URL;
    }
    

    
    receive() external payable {
        require(msg.value > 0.002 ether);
        _mint(msg.sender, tokenIDCount++);
    }
   

    function withdrawAmount(address payable  _to) public  onlyManager{
        require(0.25 ether > 0);
        _to.transfer;
    }
    
    event ERC20Deposited(
        uint tokenId,
        uint tokenAmount,
        address erc20Address,
        address depositor
    );
        
    function depositERC20(uint _tokenId,address _erc20Address,uint _tokenAmount) 
    public {
        
    ERC20Balances[_erc20Address][_tokenId] = 
            ERC20Balances[_erc20Address][_tokenId] + _tokenAmount;
            
        bool exists = ERC20AddressExists(
                ERC20ListByTokenId[_tokenId],
                _erc20Address
            );
        
        if (!exists) {
            addERC20AddressToList(
                ERC20ListByTokenId[_tokenId],
                _erc20Address
            );
        }
            
        emit ERC20Deposited(
            _tokenId,
            _tokenAmount,
            _erc20Address,
            msg.sender
        );
    }
    
    event ERC20Redeemed(
        uint tokenId,
        uint tokenAmount,
        address erc20Address,
        address recevingAddress
    );
    
    function redeemERC20(
        uint _tokenId,
        address _erc20Address,
        uint _tokenAmount,
        address _recevingAddress
    ) 
    public {
        require(
            tokenOwner[_tokenId] == msg.sender,
            "msg.sender is not the owner of token"
        );
        
        require(
            ERC20Balances[_erc20Address][_tokenId] >= _tokenAmount,
            "Not enough ERC20 balance against the token id"
        );
        
        ERC20Balances[_erc20Address][_tokenId] =
            ERC20Balances[_erc20Address][_tokenId] - _tokenAmount;
        
        if (ERC20Balances[_erc20Address][_tokenId] == 0) {
            removeERC20AddressFromList(
              ERC20ListByTokenId[_tokenId],
              _erc20Address
            );    
        }
        
        
           
        
       
        
        emit ERC20Redeemed(
            _tokenId,
            _tokenAmount,
            _erc20Address,
            _recevingAddress
        );
    }
    
    event ERC20Transferred(
        uint tokenAmount,
        address erc20Address,
        uint fromTokenId,
        uint toTokenId
    );
    
    function transferERC20(
        uint _tokenId,
        uint _tokenAmount,
        address _erc20Address,
        uint _receivingTokenId
    ) public {
        require(
            tokenOwner[_tokenId] == msg.sender,
            "msg.sender is not the owner of the token"
        );
        
        require(
            tokenOwner[_receivingTokenId] != address(0x0),
            "the receving token does not exist"
        );
        
        ERC20Balances[_erc20Address][_tokenId] =
            ERC20Balances[_erc20Address][_tokenId] - _tokenAmount;
            
        ERC20Balances[_erc20Address][_receivingTokenId] = 
            ERC20Balances[_erc20Address][_receivingTokenId] + _tokenAmount;
            
        if (ERC20Balances[_erc20Address][_tokenId] == 0) {
            removeERC20AddressFromList(
              ERC20ListByTokenId[_tokenId],
              _erc20Address
            );    
        }
        
        bool exists = ERC20AddressExists(
              ERC20ListByTokenId[_receivingTokenId],
              _erc20Address
            );
        
        if (!exists) {
            addERC20AddressToList(
                ERC20ListByTokenId[_receivingTokenId],
                _erc20Address
            );
        }
            
        emit ERC20Transferred(
            _tokenAmount,
            _erc20Address,
            _tokenId,
            _receivingTokenId
        );
    }
    
    function getERC20Balance(
        address _erc20Token,
        uint _tokenId
    ) 
    public
    view
    returns (
        uint256 balance    
    ) {
        balance = ERC20Balances[
                _erc20Token
            ]
            [
                _tokenId
            ];
    }
    
    function getTokenDataByOwner(
        uint _tokenId
    ) 
    public
    view
    onlyOwner
    returns(string memory document) 
    {
        require(exists(_tokenId));
        document = tokenData[_tokenId].information;
    }
    
    function getERC20AddressesByTokenId(uint _tokenId)
        public
        view
        returns (
            address[] memory listOfTokenAddresses
        )
        {
            listOfTokenAddresses = new address[](ERC20ListByTokenId[_tokenId].length);
            listOfTokenAddresses = ERC20ListByTokenId[_tokenId];
        }
        
    function removeERC20AddressFromList(
        address[] storage _list,
        address _addr
    )
    private
    {
        for (uint i = 0; i < _list.length; i++) {
            if (_list[i] == _addr) {
                _list[i] = _list[_list.length - 1];
                delete _list[_list.length - 1];
                _list.length-1;
            }
        }
    }
    
    function addERC20AddressToList(
        address[] storage  _list,
        address _addr
    )
    private
    {
        _list.push(_addr);
    }
    
    function ERC20AddressExists (address[] memory  _list, address _addr) private pure returns (bool) {
        bool found;
        for (uint i = 0; i < _list.length; i++) {
            if (_list[i] == _addr) {
               found = true;
               break;
            }
        }
        
        return found;
    }
    
}
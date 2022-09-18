/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

pragma solidity 0.8.17;

// ----------------------------------------------------------------------------
// NFT token split contract 
// ----------------------------------------------------------------------------
// SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

interface ERC721Interface {
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
  function tokenURI(uint256 tokenId) external view returns (string memory);
  function symbol() external view returns (string memory);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint);
    function burnAll(address owner) external returns (bool success);
    function mint(address tokenAddress, uint256 tokens) external returns (bool success);
}

contract Owned {
    address public owner;

    // @dev Initializes the contract setting the deployer as the initial owner.
    constructor() {
        owner = msg.sender;
    }

    // @dev Throws if called by any account other than the owner.
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

// ----------------------------------------------------------------------------
// ERC20 Token 
// ----------------------------------------------------------------------------
contract ERC20 is Owned {
    string public symbol;
    string public name;
    uint256 _totalSupply;
    uint8 public decimals;
    address public ERC721tokenCONTRACT;
    uint256 public ERC721tokenID;
    string public ERC721tokenURI;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    // @dev Initializes the contract setting the deployer as the initial owner.
    // @param _symbol ERC20 contract symbol.
    // @param _name ERC20 contract name.
    // @param _contractAddress ERC721 contract address.
    // @param _tokenId ERC721 contract tokenId.
    // @param _tokenURI ERC721 contract token tokenURI.
    // @param _decimals ERC20 contract decimals.
    constructor(string memory _symbol, 
                string memory _name, 
                address _contractAddress, 
                uint256 _tokenId, 
                string memory _tokenURI, 
                uint8 _decimals) {
        symbol = _symbol;
        name = _name;
        ERC721tokenCONTRACT = _contractAddress;
        ERC721tokenID = _tokenId;
        ERC721tokenURI = _tokenURI;
        decimals = _decimals;
    }

    // @dev Total number of tokens in existence
    // @return uint256 of total supply
    function totalSupply() external view returns (uint) {
        return _totalSupply;
    }

    // @dev Gets the balance of the specified address.
    // @param owner The address to query the balance of.
    // @return An uint256 representing the amount owned by the passed address.
    function balanceOf(address tokenOwner) external view returns (uint balance) {
        return balances[tokenOwner];
    }

    // @dev Transfer token for a specified address
    // @param to The address to transfer to.
    // @param value The amount to be transferred.
    // @return true
    function transfer(address to, uint tokens) external returns (bool success) {
        require(tokens <= balances[msg.sender]);
        require(to != address(0));
        _transfer(msg.sender, to, tokens);
        return true;
    }

    // @dev Intenal transfer function
    function _transfer(address from, address to, uint256 tokens) internal {
        balances[from] -= tokens;
        balances[to] += tokens;
        emit Transfer(from, to, tokens);
    }

    // @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    // @param spender The address which will spend the funds.
    // @param value The amount of tokens to be spent.
    // @return true
    function approve(address spender, uint tokens) external returns (bool success) {
        _approve(msg.sender, spender, tokens);
        return true;
    }

    // @dev Increase the amount of tokens that an owner allowed to a spender.
    // @param spender The address which will spend the funds.
    // @param addedValue The amount of tokens to increase the allowance by.
    // @return true
    function increaseAllowance(address spender, uint addedTokens) external returns (bool success) {
        _approve(msg.sender, spender, allowed[msg.sender][spender] + addedTokens);
        return true;
    }

    // @dev Decrease the amount of tokens that an owner allowed to a spender.
    // @param spender The address which will spend the funds.
    // @param subtractedValue The amount of tokens to decrease the allowance by.
    // @return true
    function decreaseAllowance(address spender, uint subtractedTokens) external returns (bool success) {
        _approve(msg.sender, spender, allowed[msg.sender][spender] - subtractedTokens);
        return true;
    }

    // @dev Intenal approve function
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0));
        require(spender != address(0));
        allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    // @dev Transfer tokens from one address to another
    // @param from address The address which you want to send tokens from
    // @param to address The address which you want to transfer to
    // @param value uint256 the amount of tokens to be transferred
    // @return true
    function transferFrom(address from, address to, uint tokens) external returns (bool success) {
        require(to != address(0));
        _approve(from, msg.sender, allowed[from][msg.sender] - tokens);
        _transfer(from, to, tokens);
        return true;
    }

    // @dev Function to check the amount of tokens that an owner allowed to a spender.
    // @param owner address The address which owns the funds.
    // @param spender address The address which will spend the funds.
    // @return A uint256 specifying the amount of tokens still available for the spender.
    function allowance(address tokenOwner, address spender) external view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    // @dev Internal function that burns all contract tokens if owner having 100% of total supply.
    // @param account The account whose tokens will be burnt.
    // @return true
    function burnAll(address allOwner) external onlyOwner returns (bool success) {
        require(balances[allOwner] == _totalSupply, "You must own all ERC20 tokens.");
        emit Transfer(allOwner, address(0), balances[allOwner]);
        _totalSupply = 0;
        balances[allOwner] = 0;
        return true;
    }

    // @dev Internal function that mints an amount of the token and assigns it to an account.
    // @param account The account that will receive the created tokens.
    // @param amount The amount that will be created.
    // @return true
    function mint(address tokenAddress, uint256 tokens) external onlyOwner returns (bool success) {
        balances[tokenAddress] = balances[tokenAddress] + tokens;
        _totalSupply += tokens;
        emit Transfer(address(0), tokenAddress, tokens);
        return true;
    } 

    // @dev Multitransfer tokens from one address to anothers.
    // @param to addresses The address which you want to transfer to.
    // @param values uint256 the amount of tokens to be transferred.
    // @return array length.
    function multiTransfer(address[] memory to, uint[] memory values) external returns (uint) {
        require(to.length == values.length);
        uint sum;
        for (uint j; j < values.length; j++) {
            sum += values[j];
        }
        require(sum <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender] - sum;
        for (uint i; i < to.length; i++) {
            balances[to[i]] += values[i];
            emit Transfer(msg.sender, to[i], values[i]);
        }
        return to.length;
    }
}

// ----------------------------------------------------------------------------
// NFT Split 
// ----------------------------------------------------------------------------
contract ERC721Split { 
    string name = "WERC721";
    address erc20contract;

    event Split(address indexed contractAddress, uint256 indexed tokenId, address indexed ercAddress, uint256 time);
    event Constructor(address ERC20contractAddress, string _symbol, string _name, address _contractAddress, uint256 _tokenId, string _tokenURI, uint8 _decimals);
    
    struct SplitInfo {
        address contract721;
        uint256 tokenId;
    }

    mapping(address => SplitInfo) ByERC20contract;
    mapping(address => mapping(uint256 => address)) public getERC20contract;

    constructor() {}

    // @dev Fragmentation of any ERC721 token to the wrapped ERC20 tokens.
    // @param _contractAddress ERC721 contract address.
    // @param _tokenId ERC721 tokenId.
    // @param _splitAmount Amount of ERC20 tokens to split
    // @param _decimals ERC20 contract decimals.
    // @return address of ERC20 contract
    function fragmentation(address _contractAddress, uint256 _tokenId, uint256 _splitAmount, uint8 _decimals) external returns (address ERC20contract) { 
        require(_splitAmount != 0, 'Split amount cannot be zero.');
        ERC721Interface(_contractAddress).safeTransferFrom(msg.sender, address(this), _tokenId);
        if (getERC20contract[_contractAddress][_tokenId] == address(0)) { // CREATE2
            bytes memory bytecode = abi.encodePacked(type(ERC20).creationCode, abi.encode(
                ERC721Interface(_contractAddress).symbol(), 
                name, 
                _contractAddress, 
                _tokenId, 
                ERC721Interface(_contractAddress).tokenURI(_tokenId), 
                _decimals));
            bytes32 salt = keccak256(abi.encodePacked(_contractAddress, _tokenId, address(this)));
            erc20contract = deploy(bytecode, salt);
            emit Constructor(erc20contract, ERC721Interface(_contractAddress).symbol(), name, _contractAddress, _tokenId, ERC721Interface(_contractAddress).tokenURI(_tokenId), _decimals);
        } else {
            erc20contract = getERC20contract[_contractAddress][_tokenId];
        }
        require(ERC20Interface(erc20contract).mint(msg.sender, _splitAmount * 10**uint(_decimals)));
        ByERC20contract[erc20contract].contract721 = _contractAddress;
        ByERC20contract[erc20contract].tokenId = _tokenId;
        getERC20contract[_contractAddress][_tokenId] = erc20contract;
        emit Split(_contractAddress, _tokenId, erc20contract, block.timestamp);
        return erc20contract;
    }
    
    // @dev Deragmentation of ERC721 token from wrapped ERC20 tokens.
    // @param _ERC20contract Wrapped ERC20 contract address.
    // @return true
    function defragmentation(address _ERC20contract) external returns (bool success) {
        require(ERC20Interface(_ERC20contract).burnAll(msg.sender));
        ERC721Interface(ByERC20contract[_ERC20contract].contract721).safeTransferFrom(address(this), msg.sender, ByERC20contract[_ERC20contract].tokenId);
        return true;
    }
    
    // @dev Internal deploy function.
    function deploy(bytes memory code, bytes32 salt) internal returns (address addr) {
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
            }
        }
    
    // @dev Gets the ERC721 contract and tokenId by ERC20 contract.
    // @param ERC20contract The address of ERC20 contract.
    // @return An address of ERC721 contract and tokenId. 
    function getERC721contract(address ERC20contract) external view returns (address contract721, uint256 tokenId) {
        return (ByERC20contract[ERC20contract].contract721, ByERC20contract[ERC20contract].tokenId);
    }

    // @dev Implementation of the {IERC721Receiver} interface.  Accepts all token transfers.
    function onERC721Received(address, address, uint256, bytes memory) external virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
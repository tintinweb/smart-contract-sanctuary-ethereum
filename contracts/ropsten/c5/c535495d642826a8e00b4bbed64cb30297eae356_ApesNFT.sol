/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// File: contracts/6_ERC721.sol



pragma solidity ^0.8.3;

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
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) external returns (bytes4);
}

contract ERC_721_token {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    string private Name;
    string private Symbol;

    // TokenID -> Owner
    mapping(uint256 => address) private _ownerOf;
    // Address Has No of Tokens
    mapping(address => uint256) private _balanceOf;
    // TokenID -> Approved Address
    mapping(uint256 => address) private _approvals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _isApprovedForAll;

    constructor(string memory _name, string memory _symbol) {
        Name = _name;
        Symbol = _symbol;
    }

    function balanceOf(address owner) public view returns (uint256 balance) {
        require(owner != address(0), "Address is 0");
        return _balanceOf[owner];
    }


    function ownerOf(uint256 tokenId) public view returns (address owner) {
        require(_ownerOf[tokenId] != address(0), "Token Doesn;t Exits");
        return _ownerOf[tokenId];
    }

    function name() public view returns (string memory) {
        return Name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view returns (string memory) {
        return Symbol;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        _requireMinted(tokenId);
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? // ? string(abi.encodePacked(baseURI, tokenId.toString()))
                string(abi.encodePacked(baseURI, tokenId))
                : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    function approve(address to, uint256 tokenId) public {
        address owner = this.ownerOf(tokenId);
        require(to != address(0), "Address is O");
        require(to != owner, "ERC721: approval to current owner");
        require(
           owner == msg.sender || isApprovedForAll(owner, msg.sender),
            "You are not the Owner of this TokenID"
        );
        require(to != msg.sender, "You are already owner of this tokenID ");
        
        _approvals[tokenId] = to;
        emit Approval(msg.sender, to, tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        returns (address operator)
    {
        require(_ownerOf[tokenId] != address(0), "Token Doesn't Exist");
        return _approvals[tokenId];
    }

    function setApprovalForAll(address operator, bool _approved) public {
        require(operator != address(0) && msg.sender!= operator , "Address is O");
        // require(balanceOf[msg.sender]>0,"You have No tokens");
        // require(owner != operator, "ERC721: approve to caller");

        _isApprovedForAll[msg.sender][operator] = _approved;
        emit ApprovalForAll(msg.sender, operator, _approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        returns (bool)
    {
        require(operator != address(0), "Address is O");
        require(owner != operator, "Already operator of this Token");
        return _isApprovedForAll[owner][operator];
    }

    function _isApprovedOrOwner(
        // address owner,
        address spender,
        uint256 id
    ) internal view returns (bool) {
        address owner = ownerOf(id);
        return (spender == owner ||
            _isApprovedForAll[owner][spender] ||
            spender == _approvals[id]);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        require(from == _ownerOf[tokenId], "from != owner");
        require(to != address(0), "transfer to zero address");

        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "not authorized"
        );


        _balanceOf[from]--;
        _balanceOf[to]++;
        _ownerOf[tokenId] = to;

        delete _approvals[tokenId];

        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        transferFrom(from, to, tokenId);
        uint32 size;
        assembly {
            size := extcodesize(to)
        }
        if (size > 0) {
            ERC721TokenReceiver receiver = ERC721TokenReceiver(to);
            require(
                receiver.onERC721Received(msg.sender, from, tokenId, "") ==
                    bytes4(
                        keccak256(
                            "onERC721Received(address,address,uint256,bytes)"
                        )
                    ),
                    "ERC721: transfer to non ERC721Receiver implementer"
            );
        }
    }

    // function _mint(tokenID);
    // function _safeMint(tokenID);

    /**
    checks if a token already exist
    @param tokenId - token id
    */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return (_ownerOf[tokenId] != address(0));
    }

    /**
    Mint a token with id `tokenId`
    @param tokenId - token id
    */
    function mint(uint256 tokenId) public {
        require(!_exists(tokenId), "tokenId already exist");
        _safeMint(msg.sender, tokenId, "");
    }

    /**
  Mint safely as this function checks whether the receiver has implemented onERC721Received if its a contract
  @param to - to address
  @param tokenId - token id
  @param data - data
   */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "receiver has not implemented ERC721Receiver"
        );
    }

    /**
  Internal function to mint a token `tokenId` to `to`
  @param to - to address
  @param tokenId - token id
   */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "transfering to zero addres");
        _balanceOf[to] += 1;
        _ownerOf[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (isContract(to)) {
            try
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == ERC721TokenReceiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("receiver has not implemented ERC721Receiver");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }


    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);


        // Clear approvals
        _approve(address(0), tokenId);

        _balanceOf [owner] -= 1;
        delete _ownerOf[tokenId];

        emit Transfer(owner, address(0), tokenId);


    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _approvals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: contracts/4_ERC20.sol



pragma solidity ^0.8.3;

contract ERC_20 {

    event Transfer(address from, address to, uint256 value);
    event Approval(address owner, address spender, uint256 value);

    string private tokenName;
    string private tokenSymbol;
    uint256 private tokenTotalSupply;
    mapping(address => uint256) private balance;
    mapping(address => mapping(address => uint256)) private approvalLimit;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _tokenTotalSupply
    ) {
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        tokenTotalSupply = _tokenTotalSupply;
        balance[msg.sender] = _tokenTotalSupply;
    }

    function name() public view returns (string memory) {
        return tokenName;
    }

    function symbol() public view returns (string memory) {
        return tokenSymbol;
    }

    function totalSupply() public view returns (uint256) {
        return tokenTotalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balance[_owner];
    }

    function transfer(address _to, uint256 _value)
        public
        virtual
        returns (bool success)
    {
        require(_to != address(0), "Address should not be 0!");
        require(_to != msg.sender, "Cannot Transfer to tokens itself");
        require(
            balance[msg.sender] >= _value,
            "You don't have requsted number of tokens"
        );

        balance[msg.sender] -= _value;
        balance[_to] += _value;
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public
      virtual
     returns (bool success) {
        require(_to != address(0), "Address should not be 0!");
        require(_from != address(0), "Address should not be 0!");
        require(approvalLimit[_from][msg.sender] >= _value,"You dont have Approval");
        // if (approvalLimit[msg.sender][_from]>=_value){
        // msg.sender = omar
        //              usama=>omar=>10;
        if (approvalLimit[_from][msg.sender] >= _value) {
            balance[_from] -= _value;
            balance[_to] += _value;
            approvalLimit[_from][msg.sender] -=_value;
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
            require(
            msg.sender != _spender,
            "Sender is Already approve to spend his spendings!"
        );
        require(balance[msg.sender]>=_value,"You don't have requsted number of tokens");
        if (balance[msg.sender] >= _value) {
            // msg.sender = usama
            //              usama=>omar=>10;
            approvalLimit[msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _value);
            return true;
        } else {
            return false;
        }
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        require(_owner != address(0), "Address should not be 0!");
        require(_spender != address(0), "Address should not be 0!");
        return approvalLimit[_owner][_spender];
    }
}

// #// Addresses for testing
// 1// 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
// 2// 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
// 3// 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
// 4// 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB

// File: contracts/11_ERC721Staking.sol





pragma solidity ^0.8.3;

contract TestToken is ERC_20 {
    uint256 public _totalSupply = 5000000;

    address payable public owner;

    constructor() ERC_20("DEVCOIN", "DEVS", _totalSupply) {}

    function transferToken(address to, uint256 amount) external onlyOwner {
        require(this.transfer(to, amount), "Token transfer failed!");
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Message sender must be the contract's owner."
        );
        _;
    }
    // function transfertoken
}


contract ApesNFT is ERC_721_token {
    uint256 private _tokenIds;

    constructor() ERC_721_token("ApesNft", "DEV") {
        _tokenIds = 0;
    }

    function createToken()
        public
        returns (uint256 TokenID)
    {
        _tokenIds++;
        uint256 newItemId = _tokenIds;

        _mint(msg.sender, newItemId);

        return newItemId;
    }

}

contract StakeERC721 {
    event TransferTest(address from, address to, uint256 stakeAmount);

    ERC_20 erc20Contract;
    ERC_721_token erc721Contract;
    //86400 -> 1 Day

    // 3 Days (30 * 24 * 60 * 60)
    uint256 public StakingDuration = 259200;

    // 18 Days (18 * 24 * 60 * 60)
    uint256 StakesExpired = 1555200;

    //intrest rate per second -> 1 token per min for every staked
    uint8 public interestRate = 1;
    uint256 public ContractExpired;
    uint8 public totalStakers;

    struct StakeInfo {
        
        uint256 startTS;
        uint256 endTS;
        uint256 amount;
        uint256 claimed;
        uint256 stakeDuration;
        uint TokenIdStaked;
    }

    event Staked(address indexed from, uint256 amount);
    event Claimed(address indexed from, uint256 amount);

    mapping(address => StakeInfo) public stakeInfos;
    mapping(address => bool) public addressStaked;
    bool private locked;
    address payable public owner;
    uint256 totalSupply;
    uint256 stakeable;

    constructor(ERC_20 _tokenAddress20 ,ERC_721_token _tokenAddress721) {
        require(
            address(_tokenAddress20) != address(0) &&address(_tokenAddress721) != address(0),
            "Token Address cannot be address 0"
        );
        erc20Contract = _tokenAddress20;
        erc721Contract = _tokenAddress721;
        ContractExpired = block.timestamp + StakesExpired;
        totalStakers = 0;
        totalSupply = erc20Contract.totalSupply();
        stakeable = 0;
        StakingDuration += block.timestamp;
        owner = payable(msg.sender);
    }

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Message sender must be the contract's owner."
        );
        _;
    }

    // function transferToken(address to, uint256 amount) external onlyOwner {
    //     require(erc20Contract.transfer(to, amount), "Token transfer failed!");
    // }

    function claimReward() external returns (bool) {
        require(addressStaked[msg.sender] == true, "You are not participated");
        require(
            stakeInfos[msg.sender].endTS < block.timestamp,
            "Stake Time is not over yet"
        );
        require(stakeInfos[msg.sender].claimed == 0, "Already claimed");

        uint256 stakeAmount = stakeInfos[msg.sender].amount;
        uint256 totalTokens = stakeAmount +
           (interestRate  * (stakeInfos[msg.sender].stakeDuration/60) * stakeAmount);
           
            // ((stakeAmount * interestRate) / 100)*stakeInfos[msg.sender].endTS;
        stakeInfos[msg.sender].claimed == totalTokens;
        erc20Contract.transfer(msg.sender, totalTokens);
        uint tokenID=stakeInfos[msg.sender].TokenIdStaked;
        erc721Contract.transferFrom(address(this), msg.sender,tokenID );

        emit Claimed(msg.sender, totalTokens);

        return true;
    }

    function getTokenExpiry() external view returns (uint256) {
        require(addressStaked[msg.sender] == true, "You are not participated");
        return stakeInfos[msg.sender].endTS;
    }

    /// StakeAmount-> Amount of Tokens Staked
    /// StakeTime-> Time in seconds for Staking tokens
    function stakeNFT(uint tokenId, uint256 stakeTime)
        external
        payable
        noReentrant
    {
        require(erc721Contract.ownerOf(tokenId) == msg.sender ,"You are not the owner of this NFT!");
        require(
            block.timestamp < StakingDuration,
            "Staking new NFT is stopped"
        );
        require(addressStaked[msg.sender] == false, "You already participated");
        // require(erc20Contract.balanceOf(msg.sender) >= stakeAmount,
        //     "Insufficient Tokens Balance"
        // );
        uint stakeAmount=(interestRate  * (stakeTime/60));
        require((interestRate  * (stakeTime/60)) + stakeable <= totalSupply,
            "Cannot Stake This much amount"
        );


        // Approve the Contract to send tokens here
        // erc20Contract.transferFrom(msg.sender, address(this), stakeAmount);
        erc721Contract.safeTransferFrom(msg.sender, address(this), tokenId);
        totalStakers++;
        addressStaked[msg.sender] = true;

        stakeInfos[msg.sender] = StakeInfo({
            startTS: block.timestamp,
            endTS: block.timestamp + stakeTime,
            amount: stakeAmount,
            claimed: 0,
            stakeDuration:stakeTime,
            TokenIdStaked: tokenId
        });
        stakeable += (interestRate  * (stakeTime/60) * stakeAmount);
        emit Staked(msg.sender, stakeAmount);
    }
}

// #// Addresses for testing
// 1// 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
// 2// 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
// 3// 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
// 4// 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
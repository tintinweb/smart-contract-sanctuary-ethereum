/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

// File: NFTLENDING/FakeUSDT.sol


pragma solidity ^0.8.19;
    
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract FakeUSDT is IERC20 {
    string public name = "Fake USDT";
    string public symbol = "FUSDT";
    uint8 public decimals = 18;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;
    
    uint256 totalTokenSupply = 1000000 * 10 ** uint256(decimals);
    
    constructor() {
        balances[msg.sender] = totalTokenSupply;
    }
    
    function totalSupply() external view override returns (uint256) {
        return totalTokenSupply;
    }
    
    function balanceOf(address account) external view override returns (uint256) {
        return balances[account];
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        address sender = msg.sender;
        require(sender != address(0), "Invalid sender address");
        require(recipient != address(0), "Invalid recipient address");
        require(amount <= balances[sender], "Insufficient balance");
        
        balances[sender] -= amount;
        balances[recipient] += amount;
        
        emit Transfer(sender, recipient, amount);
        
        return true;
    }
    
    function allowance(address owner, address spender) external view override returns (uint256) {
        return allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) external override returns (bool) {
        address owner = msg.sender;
        require(owner != address(0), "Invalid owner address");
        require(spender != address(0), "Invalid spender address");
        
        allowances[owner][spender] = amount;
        
        emit Approval(owner, spender, amount);
        
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        address owner = sender;
        require(owner != address(0), "Invalid owner address");
        require(sender != address(0), "Invalid sender address");
        require(recipient != address(0), "Invalid recipient address");
        require(amount <= balances[owner], "Insufficient balance");
        require(amount <= allowances[owner][msg.sender], "Insufficient allowance");
        
        balances[owner] -= amount;
        balances[recipient] += amount;
        allowances[owner][msg.sender] -= amount;
        
        emit Transfer(owner, recipient, amount);
        
        return true;
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: NFTLENDING/Main.sol


pragma solidity ^0.8.19;



// Struct for storing NFT data
struct Nft {
    address owner;
    address newOwner;
    uint256 tokenId;
    address nftContract;
    uint256 nftValue;
    uint256 usdtValue;
    uint256 useTime;
    uint256 timestamp;
    bool isAvailable;
}

// Struct for storing key data
struct KeyData {
    address[] contractAddresses;
    uint256[] tokenIds;
}

contract NFTLending {
    mapping(address => mapping(uint256 => Nft)) public nfts; // Mapping for storing NFT data
    mapping(address => KeyData) private nftKeys; // Mapping for storing key data
    address []ownerAddresses; // Array for storing owner addresses
    uint nftCount; // Count of registered NFTs on the contract
    FakeUSDT public fakeUSDT;

    event NFTReceived(address from, uint256 tokenId); // Event for receiving NFT
    
    event NFTAdded(address indexed owner, address indexed NFTAddress, uint256 tokenId);
    event NFTWithdrawn(address indexed owner, address indexed NFTAddress, uint256 tokenId);
    event NFTCanceled(address indexed owner, address indexed NFTAddress, uint256 tokenId);
    event NFTBorrowed(address indexed borrower, address indexed lender, address indexed NFTAddress, uint256 tokenId);
    event NFTReturned(address indexed borrower, address indexed lender, address indexed NFTAddress, uint256 tokenId);

    address public owner = msg.sender; // Address of the contract owner
    uint256 public fee = 1; // 1 wei

    function setFakeUSDTContract(address _fakeUSDTAddress) public {
        require(msg.sender == owner, "Only owner can set FakeUSDT contract");
        fakeUSDT = FakeUSDT(_fakeUSDTAddress);
    }

    // Function for setting fee
    function setFee(uint256 _fee) public {
        require(msg.sender == owner, "Only owner can set fee");
        fee = _fee;
    }

    // Function for getting NFT list
    function getAllNFTs() public view returns (Nft[] memory) {
        Nft[] memory nftList = new Nft[](nftCount);
        uint index = 0;

        for (uint i = 0; i < ownerAddresses.length; i++) {
            address _owner = ownerAddresses[i];
            KeyData storage keyData = nftKeys[_owner];
            address[] storage contractAddresses = keyData.contractAddresses;
            uint256[] storage tokenIds = keyData.tokenIds;

            for (uint j = 0; j < contractAddresses.length; j++) {
                address nftContract = contractAddresses[j];
                uint256 tokenId = tokenIds[j];
                Nft storage nft = nfts[nftContract][tokenId];
                
                // Check if the NFT is not already included in the list
                bool isDuplicate = false;
                for (uint k = 0; k < index; k++) {
                    if (nftList[k].nftContract == nftContract && nftList[k].tokenId == tokenId) {
                        isDuplicate = true;
                        break;
                    }
                }
                
                if (!isDuplicate) {
                    nftList[index] = nft;
                    index++;
                }
            }
        }

        assembly {
            mstore(nftList, index)
        }

        return nftList;
    }


    // Function for registering NFT
    function registerNFT(address _owner, address _newOwner, address _nftContract, uint256 _tokenId, uint256 _nftValue, uint256 _usdtValue, uint256 _useTime, uint256 _timestamp, bool _isAvailable) private {
        uint256 funds = 0;

        // Check if _nftValue > 0 set fee
        if (_nftValue > 0) {
            funds = _nftValue + fee;
        }

        nfts[_nftContract][_tokenId] = Nft({
            owner: _owner,
            newOwner: _newOwner,
            tokenId: _tokenId,
            nftContract: _nftContract,
            nftValue: funds,
            usdtValue: _usdtValue,
            useTime: _useTime,
            timestamp: _timestamp,
            isAvailable: _isAvailable
        });

        nftKeys[_owner].contractAddresses.push(_nftContract);
        nftKeys[_owner].tokenIds.push(_tokenId);
        ownerAddresses.push(_owner);
        nftCount++;
        emit NFTAdded(_owner, _nftContract, _tokenId);
    }

    // Function for deleting NFT    
    function deleteNFT(address _owner, address _nftContract, uint256 _tokenId) private {
        delete nfts[_nftContract][_tokenId];

        KeyData storage keyData = nftKeys[_owner];
        address[] storage contractAddresses = keyData.contractAddresses;
        uint256[] storage tokenIds = keyData.tokenIds;

        for (uint i = 0; i < contractAddresses.length; i++) {
            if (contractAddresses[i] == _nftContract && tokenIds[i] == _tokenId) {
                contractAddresses[i] = contractAddresses[contractAddresses.length - 1];
                delete contractAddresses[contractAddresses.length - 1];
                contractAddresses.pop();

                tokenIds[i] = tokenIds[tokenIds.length - 1];
                delete tokenIds[tokenIds.length - 1];
                tokenIds.pop();

                break;
            }
        }

        for (uint i = 0; i < ownerAddresses.length; i++) {
            if (ownerAddresses[i] == _owner) {
                ownerAddresses[i] = ownerAddresses[ownerAddresses.length - 1];
                delete ownerAddresses[ownerAddresses.length - 1];
                ownerAddresses.pop();

                break;
            }
        }

        nftCount--;
    }

    // Function for purpose NFT
    function purposeNFT(address _nftContract, uint256 _tokenId, uint256 _value, uint256 _useTime) public {
        // Check if sender have NFT
        IERC721 nftContract = IERC721(_nftContract);
        require(nftContract.ownerOf(_tokenId) == msg.sender, "You don't own this NFT");
        
        // Check if NFT is not registered
        Nft storage nftData = nfts[_nftContract][_tokenId];
        require(!nftData.isAvailable, "NFT already registered");

        if (nftData.nftContract != address(0)) {
            require(block.timestamp > (nftData.timestamp + nftData.useTime), "NFT is not available");
            
            // Sending funds to NFT owner
            if (nftData.usdtValue > 0) {
                fakeUSDT.transfer(nftData.owner, nftData.usdtValue);
            } else {
                payable(nftData.owner).transfer(nftData.nftValue);
            }

            // Deleting NFT from contract
            deleteNFT(nftData.owner, nftData.nftContract, nftData.tokenId);
        }

        // Call transferFrom on the NFT contract to send NFT to this contract
        nftContract.transferFrom(msg.sender, address(this), _tokenId);

        // Adding NFT to registered list
        registerNFT(msg.sender, address(0), _nftContract, _tokenId, _value, 0, _useTime, block.timestamp, true);

        emit NFTReceived(msg.sender, _tokenId);
    }

    function purposeNFTWithUSDT(address _nftContract, uint256 _tokenId, uint256 _value, uint256 _useTime) public {
        // Check if sender have NFT
        IERC721 nftContract = IERC721(_nftContract);
        require(nftContract.ownerOf(_tokenId) == msg.sender, "You don't own this NFT");

        // Check if NFT is not registered
        Nft storage nftData = nfts[_nftContract][_tokenId];
        require(!nftData.isAvailable, "NFT already registered");

        if (nftData.nftContract != address(0)) {
            require(block.timestamp > (nftData.timestamp + nftData.useTime), "NFT is not available");
            
            // Sending funds to NFT owner
            if (nftData.usdtValue > 0) {
                fakeUSDT.transfer(nftData.owner, nftData.usdtValue);
            } else {
                payable(nftData.owner).transfer(nftData.nftValue);
            }

            // Deleting NFT from contract
            deleteNFT(nftData.owner, nftData.nftContract, nftData.tokenId);
        }

        // Call transferFrom on the NFT contract to send NFT to this contract
        nftContract.transferFrom(msg.sender, address(this), _tokenId);

        // Adding NFT to registered list
        registerNFT(msg.sender, address(0), _nftContract, _tokenId, 0, _value, _useTime, block.timestamp, true);

        emit NFTReceived(msg.sender, _tokenId);
    }

    // Function for sending NFT from this contract to user
    function purchaseNFT(address _nftContract, uint256 _tokenId) external payable {
        Nft storage nftData = nfts[_nftContract][_tokenId];

        require(nftData.isAvailable, "NFT not found or not available");

        // check if owner is not trying to buy his own NFT
        require(nftData.owner != msg.sender, "You can't buy your own NFT");

        // Check if value is equal to NFT value
        require(msg.value == nftData.nftValue, "Incorrect NFT value");
        
        IERC721 nftContract = IERC721(_nftContract);
        // Call transferFrom on the NFT contract to send NFT to this contract
        nftContract.transferFrom(address(this), msg.sender, _tokenId);

        // Change NFT status to not available
        nftData.isAvailable = false;
        nftData.newOwner = msg.sender;
        nftData.timestamp = block.timestamp;

        emit NFTBorrowed(nftData.newOwner, nftData.owner, _nftContract, nftData.tokenId);
    }

    // Function for sending NFT from this contract to user with USDT
    function purchaseNFTWithUSDT(uint256 amount, address _nftContract, uint256 _tokenId) external {
        Nft storage nftData = nfts[_nftContract][_tokenId];
        
        require(nftData.isAvailable, "NFT not found or not available");

        // check if owner is not trying to buy his own NFT
        require(nftData.owner != msg.sender, "You can't buy your own NFT");

        // Check if user have enough USDT
        require(fakeUSDT.balanceOf(msg.sender) >= amount, "Not enough USDT");

        // Check if value is equal to NFT value
        require(amount == nftData.usdtValue, "Incorrect NFT value");

        // Check if this NFT was purchased with USDT
        require(nftData.usdtValue > 0, "This NFT wasn't purchased with USDT");

        IERC721 nftContract = IERC721(_nftContract);

        // Call transferFrom on the NFT contract to send NFT to this contract
        nftContract.transferFrom(address(this), msg.sender, _tokenId);

        // Change NFT status to not available
        nftData.isAvailable = false;
        nftData.newOwner = msg.sender;
        nftData.timestamp = block.timestamp;

        // Send USDT to Smart Contract
        fakeUSDT.transferFrom(msg.sender, address(this), amount);

        emit NFTBorrowed(nftData.newOwner, nftData.owner, _nftContract, nftData.tokenId);
    }

    // Function for canceling NFT purpose and returning it to owner
    function cancelPurposeNFT(address _nftContract, uint256 _tokenId) public {
        Nft storage nftData = nfts[_nftContract][_tokenId];

        require(nftData.owner == msg.sender, "NFT not found");

        IERC721 nftContract = IERC721(_nftContract);

        nftContract.transferFrom(address(this), nftData.owner, _tokenId);

        emit NFTCanceled(msg.sender, _nftContract, _tokenId);

        deleteNFT(nftData.owner, _nftContract, _tokenId);
    }

    // Function for returning NFT to owner
    function returnNFT(address _nftContract, uint256 _tokenId) external {
        Nft storage nftData = nfts[_nftContract][_tokenId];

        require(nftData.newOwner == msg.sender, "Only temp-owner can return NFT");

        IERC721 nftContract = IERC721(_nftContract);

        require(block.timestamp < nftData.timestamp + nftData.useTime, "You cannot return NFT after use time");
        
        nftContract.transferFrom(msg.sender, nftData.owner, _tokenId);

        // Check if NFT was purchased with USDT or ETH and send funds to owner
        if (nftData.usdtValue > 0) {
            fakeUSDT.transfer(nftData.newOwner, nftData.usdtValue);
        } else {
            payable(nftData.newOwner).transfer(nftData.nftValue - fee);
            payable(nftData.owner).transfer(fee);
        }

        emit NFTReturned(nftData.newOwner, nftData.owner, _nftContract, nftData.tokenId);
        deleteNFT(nftData.owner, _nftContract, _tokenId);
    }

    // Function for withdraw funds for NFT owner
    function withdrawAll() external {
        uint256 ethAmount = 0;
        uint256 usdtAmount = 0;
        address payable _owner = payable(msg.sender);

        Nft[] memory nftList = getAllNFTs();

        for (uint256 i = 0; i < nftList.length; i++) {
            Nft storage nftData = nfts[nftList[i].nftContract][nftList[i].tokenId];

            if (nftData.owner == msg.sender && !nftData.isAvailable && block.timestamp >= (nftData.useTime + nftData.timestamp)) {
                usdtAmount += nftData.usdtValue;
                ethAmount += nftData.nftValue;

                emit NFTWithdrawn(_owner, nftList[i].nftContract, nftList[i].tokenId);
                deleteNFT(msg.sender, nftList[i].nftContract, nftList[i].tokenId);
                
            }
        }

        require(ethAmount > 0 || usdtAmount > 0, "You don't have funds to withdraw on this contract!");
        
        if (ethAmount > 0) {
            _owner.transfer(ethAmount);
        }

        if (usdtAmount > 0) {
            fakeUSDT.transfer(_owner, usdtAmount);
        }
    }
}